# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuizParseAndCreateQuestionsJob, type: :job do
  let(:instance) { described_class.new }
  let(:input_text) { "Some example text" }
  let(:quiz) { FactoryBot.create(:quiz, input_text: input_text) }

  describe "#perform" do


  end

  describe "#parse_quiz_questions" do
    it "raises parser error" do
      expect {
        instance.parse_quiz_questions(quiz)
      }.to raise_error(/true and false/)
    end

    context "valid single question claude_initial response" do
      let(:input_text) { "Here is a 3-step chronological summary of the key events in the article, with one true and one false option at each step:\n\nStep 1:\n\nTrue: Something true. \n\nFalse: Something False." }
      let(:target) { {correct: ["Something true."], incorrect: ["Something false."]} }
      it "returns the questions" do
        result = instance.parse_quiz_questions(quiz)
        expect(result.count).to eq 1
        expect_hashes_to_match(result.first, target)
      end
    end

    context "valid multiple question claude_initial response" do
    end
  end
end
