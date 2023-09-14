class PromptClaudeForCitationQuizJob < ApplicationJob
  sidekiq_options retry: false
  SKIP_JOB = ENV["SKIP_CREATE_CITATION_QUIZ"].present?
  QUIZ_PROMPT = ENV["CLAUDE_QUIZ_PROMPT"].freeze
  SUBJECT_PROMPT = ENV["CLAUDE_SUBJECT_PROMPT"].freeze

  def self.enqueue_for_citation?(citation)
    QUIZ_PROMPT.present? && citation.present? && citation.citation_text.present? &&
      citation.quizzes.none?
  end

  def self.enqueue_for_quiz?(quiz)
    quiz.present? && quiz.pending? && quiz.input_text.blank? &&
      quiz.prompt_text.present?
  end

  # May use get_remaining_ttl to calculate sometime
  def requeue_delay
    39.seconds
  end

  def lock_duration_ms
    (10.minutes * 1000).to_i
  end

  def quiz_prompt_text(quiz = nil)
    return quiz.prompt_text if quiz.present?

    [QUIZ_PROMPT, SUBJECT_PROMPT].reject(&:blank?).join("\n\n---\n\n")
  end

  def quiz_prompt_full_texts(citation, prompt_text)
    ClaudeParser::SecondPrompt.quiz_prompt_full_texts(prompt_text, citation)
  end

  # args: {citation_id:, quiz_id:, summary_migration:}
  def perform(args)
    return if SKIP_JOB
    citation_id = args["citation_id"]
    quiz_id = args["quiz_id"]
    if quiz_id.present?
      quiz = Quiz.find(quiz_id)
      return unless self.class.enqueue_for_quiz?(quiz)
      citation = quiz.citation
    else
      citation = Citation.find(citation_id)
      return unless self.class.enqueue_for_citation?(citation)
    end

    # Check for lock
    lock_manager = ClaudeIntegration.new_lock
    redlock = lock_manager.lock(ClaudeIntegration::REDLOCK_KEY, lock_duration_ms)
    return self.class.perform_in(requeue_delay, args) unless redlock

    begin
      prompt_text = quiz_prompt_text(quiz)
      quiz ||= Quiz.create!(citation: citation,
        source: :claude_integration,
        kind: :citation_quiz,
        prompt_text: prompt_text)

      # Prompt Claude and update the quiz
      quiz_prompt_full_texts(citation, prompt_text).each do |ptext|
        claude_response = ClaudeIntegration.new.completion_for_prompt(ptext, quiz&.prompt_params)
        new_text = [quiz.input_text, claude_response].reject(&:blank?).join("\n\n---\n\n")

        quiz.update!(input_text: new_text.strip)
      end
      # Enqueue parsing after creating everything
      QuizParseAndCreateQuestionsJob.perform_async(quiz.id)
    rescue Faraday::TimeoutError
      self.class.perform_async(requeue_delay, args)
    ensure
      lock_manager.unlock(redlock)
    end
  end
end
