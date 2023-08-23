class CreateCitationQuizJob < ApplicationJob
  sidekiq_options retry: false
  SKIP_JOB = ENV["SKIP_CREATE_CITATION_QUIZ"].present?
  QUIZ_PROMPT = ENV["CLAUDE_QUIZ_PROMPT"].freeze

  def self.enqueue_for_citation?(citation)
    QUIZ_PROMPT.present? && citation.citation_text.present? && citation.quizzes.none?
  end

  def quiz_prompt(citation)
    "#{QUIZ_PROMPT}\n\nArticle text: #{citation.citation_text}"
  end

  def perform(citation_id)
    return if SKIP_JOB
    citation = Citation.find(citation_id)
    return unless self.class.enqueue_for_citation?(citation)

    claude_response = ClaudeIntegration.new.completion_for_prompt(quiz_prompt(citation))

    Quiz.create!(citation: citation,
      source: :claude_integration,
      kind: :citation_quiz,
      prompt_text: QUIZ_PROMPT,
      input_text: claude_response)
  end
end
