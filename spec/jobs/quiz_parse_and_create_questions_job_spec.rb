# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuizParseAndCreateQuestionsJob, type: :job do
  let(:instance) { described_class.new }
  let(:input_text) { "Some example text" }
  let(:citation) { FactoryBot.create(:citation) }
  let(:quiz) { FactoryBot.create(:quiz, input_text: input_text, citation: citation) }
  let(:input_text) { nil }

  describe "#perform" do
    let!(:previous_quiz) { FactoryBot.create(:quiz, citation: citation, status: :active) }
    context "quiz status is not pending" do
      before { quiz.update(status: :active) }

      it "returns early" do
        expect(quiz.reload.version).to eq 2
        instance.perform(quiz.id)
        quiz.reload
        expect(quiz.status).to eq "active"
        expect(quiz.quiz_questions.count).to eq 0
        expect(quiz.input_text_parse_error)
        # previous quiz status isn't updated
        expect(previous_quiz.reload.status).to eq "active"
      end
    end

    context "blank input_text" do
      it "adds a parse error" do
        instance.perform(quiz.id)
        quiz.reload
        expect(quiz.input_text_parse_error).to eq "No input_text"
        expect(quiz.status).to eq "parse_errored"
        # previous quiz status isn't updated
        expect(previous_quiz.reload.status).to eq "active"
      end
    end
  end
end
