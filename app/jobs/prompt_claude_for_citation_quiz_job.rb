class PromptClaudeForCitationQuizJob < ApplicationJob
  sidekiq_options retry: false
  SKIP_JOB = ENV["SKIP_CREATE_CITATION_QUIZ"].present?
  QUIZ_PROMPT = ENV["CLAUDE_QUIZ_PROMPT"].freeze
  REDLOCK_KEY = "Claude-#{Rails.env.slice(0, 3)}"

  def self.enqueue_for_citation?(citation)
    QUIZ_PROMPT.present? && citation.present? && citation.citation_text.present? &&
      citation.quizzes.none?
  end

  def self.enqueue_for_quiz?(quiz)
    quiz.present? && quiz.pending? && quiz.input_text.blank? &&
      quiz.prompt_text.present?
  end

  def self.redis_url
    ConvusReviews::Application.config.redis_default_url
  end

  # May use get_remaining_ttl to calculate sometime
  def requeue_delay
    39.seconds
  end

  def lock_duration_ms
    (5.minutes * 1000).to_i
  end

  def quiz_prompt(citation, quiz = nil)
    if quiz.present?
      quiz.prompt_full_text
    else
      "#{QUIZ_PROMPT}\n\nArticle: #{citation.citation_text}"
    end
  end

  # args: [citation_id, quiz_id = nil]
  def perform(args)
    return if SKIP_JOB
    citation_id, quiz_id = *args
    if quiz_id.present?
      quiz = Quiz.find(quiz_id)
      return unless self.class.enqueue_for_quiz?(quiz)
      citation = quiz.citation
    else
      citation = Citation.find(citation_id)
      return unless self.class.enqueue_for_citation?(citation)
    end

    lock_manager = Redlock::Client.new([self.class.redis_url])
    redlock = lock_manager.lock(REDLOCK_KEY, lock_duration_ms)
    unless redlock
      return self.class.perform_in(requeue_delay, citation_id, quiz_id)
    end

    begin
      claude_response = ClaudeIntegration.new.completion_for_prompt(quiz_prompt(citation, quiz), quiz.prompt_params)

      if quiz.present?
        if quiz.update(input_text: claude_response)
          QuizParseAndCreateQuestionsJob.perform_async(quiz_id)
        else
          raise quiz.errors.full_messages
        end
      else
        Quiz.create!(citation: citation,
          source: :claude_integration,
          kind: :citation_quiz,
          prompt_text: QUIZ_PROMPT,
          input_text: claude_response)
      end
    rescue Faraday::TimeoutError
      self.class.perform_async(requeue_delay, citation_id)
    ensure
      lock_manager.unlock(redlock)
    end
  end
end
