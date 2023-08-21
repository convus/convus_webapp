# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuizParseAndCreateQuestionsJob, type: :job do
  let(:instance) { described_class.new }
  let(:input_text) { "Some example text" }
  let(:quiz) { FactoryBot.create(:quiz, input_text: input_text) }

  describe "#perform" do
    context "quiz status is not pending" do
      before do
        quiz.update(status: :active)
      end

      it "returns early" do
        expect(instance).not_to receive(:parse_quiz_questions)
        instance.perform(quiz.id)
        quiz.reload
        expect(quiz.)
      end
    end

    context "quiz status is pending" do
      before do
        quiz.update(status: :pending)
      end

      it "calls parse_quiz_questions" do
        expect(instance).to receive(:parse_quiz_questions).with(quiz)
        instance.perform(quiz.id)
      end
    end
  end
end
