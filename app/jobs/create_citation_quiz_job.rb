class CreateCitationQuizJob < ApplicationJob
  sidekiq_options retry: false
  SKIP_JOB = ENV["SKIP_CREATE_CITATION_QUIZ"].present?
  QUIZ_PROMPT = ENV["CLAUDE_QUIZ_PROMPT"].freeze
  REDLOCK_KEY = "Claude-#{Rails.env.slice(0, 3)}"

  def self.enqueue_for_citation?(citation)
    QUIZ_PROMPT.present? && citation.citation_text.present? && citation.quizzes.none?
  end

  def self.redis_url
    ConvusReviews::Application.config.redis_default_url
  end

  # May use get_remaining_ttl to calculate sometime
  def requeue_delay
    50.seconds
  end

  def lock_duration_ms
    (5.minutes * 1000).to_i
  end

  def quiz_prompt(citation)
    "#{QUIZ_PROMPT}\n\nArticle text: #{citation.citation_text}"
  end

  def perform(citation_id)
    return if SKIP_JOB
    lock_manager = Redlock::Client.new([self.class.redis_url])
    citation = Citation.find(citation_id)
    return unless self.class.enqueue_for_citation?(citation)
    redlock = lock_manager.lock(REDLOCK_KEY, lock_duration_ms)
    unless redlock
      return CreateCitationQuizJob.perform_in(requeue_delay)
      # time_remaining = lock_manager.get_remaining_ttl_for_resource(REDLOCK_KEY) || 0
      # message = "Locked: Jobs - #{self.class.jobs_count}. remaining time: #{time_remaining} (#{lock_duration_ms - time_remaining} since locked)"
      # raise message
    end
    begin
      claude_response = ClaudeIntegration.new.completion_for_prompt(quiz_prompt(citation))

      Quiz.create!(citation: citation,
        source: :claude_integration,
        kind: :citation_quiz,
        prompt_text: QUIZ_PROMPT,
        input_text: claude_response)
    ensure
      lock_manager.unlock(redlock)
    end
  end
end
