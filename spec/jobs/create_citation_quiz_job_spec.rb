# frozen_string_literal: true

require "rails_helper"

RSpec.describe CreateCitationQuizJob, type: :job do
  let(:instance) { described_class.new }
  let(:citation) { FactoryBot.create(:citation, citation_text: citation_text) }
  let(:citation_text) { "some text" }

  describe "#perform" do
    before { stub_const("CreateCitationQuizJob::QUIZ_PROMPT", prompt_text) }
    let(:prompt_text) { "example" }

    it "creates a new quiz" do
      allow_any_instance_of(ClaudeIntegration).to receive(:get_quiz_response) { "response text" }
      expect(citation.quizzes.count).to eq 0
      expect {
        instance.perform(citation.id)
      }.to change(Quiz, :count).by 1

      quiz = Quiz.last
      expect(quiz.citation_id).to eq citation.id
      expect(quiz.source).to eq "claude_integration"
      expect(quiz.kind).to eq "citation_quiz"
      expect(quiz.prompt_text).to eq prompt_text
      expect(quiz.input_text).to eq "response text"
    end
  end
end
