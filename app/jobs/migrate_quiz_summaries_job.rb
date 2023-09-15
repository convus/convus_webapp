# Lazy copy of PromptClaudeForCitationQuizJob
class MigrateQuizSummariesJob < ApplicationJob
  sidekiq_options retry: false

  def self.enqueue_for_quiz?(quiz)
    return false if quiz.blank?
    quiz.citation.quizzes.claude_second.active.none?
  end

  def requeue_delay
    31.seconds
  end

  def lock_duration_ms
    (5.minutes * 1000).to_i
  end

  def prompt_text(quiz, subject_prompt = nil)
    subject_prompt ||= PromptClaudeForCitationQuizJob::SUBJECT_PROMPT
    prompt_text = quiz.prompt_text
    prompt_text += "\n\nArticle: [ARTICLE_TEXT]" unless prompt_text.match?("[ARTICLE_TEXT]")
    prompt_text + "\n\n---\n\n#{subject_prompt}"
  end

  def subject_prompt_full_text(quiz)
    ClaudeParser::SecondPrompt.quiz_prompt_full_texts(quiz.prompt_text, quiz.citation).last
  end

  def perform(quiz_id, subject_prompt = nil)
    return if PromptClaudeForCitationQuizJob::SKIP_JOB
    quiz = Quiz.find(quiz_id)
    return unless self.class.enqueue_for_quiz?(quiz)
    citation = quiz.citation

    # Check for lock
    lock_manager = ClaudeIntegration.new_lock
    redlock = lock_manager.lock(ClaudeIntegration::REDLOCK_KEY, lock_duration_ms)
    return self.class.perform_in(requeue_delay, args) unless redlock

    begin
      new_quiz ||= Quiz.create(citation: citation,
        source: :claude_integration,
        kind: :citation_quiz,
        input_text: quiz.input_text.split("\n---\n").first,
        prompt_text: prompt_text(quiz, subject_prompt),
        prompt_params: {temperature: 1})

      # Prompt Claude and update the quiz
      claude_response = ClaudeIntegration.new.completion_for_prompt(subject_prompt_full_text(new_quiz), new_quiz.prompt_params)
      new_text = [new_quiz.input_text, claude_response].reject(&:blank?).join("\n\n---\n\n")
      new_quiz.update!(input_text: new_text.strip)

      # Enqueue parsing after creating everything
      QuizParseAndCreateQuestionsJob.perform_async(new_quiz.id)
    rescue Faraday::TimeoutError
      self.class.perform_async(requeue_delay, args)
    ensure
      lock_manager.unlock(redlock)
    end
  end
end
