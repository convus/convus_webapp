# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuizParseAndCreateQuestionsJob, type: :job do
  let(:instance) { described_class.new }
  let(:input_text) { "Some example text" }
  let(:time) { Time.at(1684698531) } # 2023-05-21 12:48
  let(:citation) { FactoryBot.create(:citation, published_updated_at: time) }
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

    context "valid quiz" do
      let(:input_text) { "Here is a summary of the key events from the article in a chronological true/false format with questions:\nStep 1:\nQuestion: Question One\nTrue option: Something True\nFalse option: Something false\nStep 2:  \nQuestion: Question two\nTrue option: Something 2 True\nFalse option: Something 2 false\n\n" }
      let(:target) do
        [
          {
            question: "According to <u>#{citation.publisher.name}</u> <span class=\"convertTime withPreposition\">#{time.to_i}</span>, Question One",
            correct: ["Something True"],
            incorrect: ["Something false"]
          }, {
            question: "Question two",
            correct: ["Something 2 True"],
            incorrect: ["Something 2 false"]
          }
        ]
      end
      it "creates questions and answers" do
        expect(described_class.parsed_input_text(quiz)).to eq target
        instance.perform(quiz.id)
        quiz.reload
        expect(quiz.input_text_parse_error).to be_nil
        expect(quiz.status).to eq "active"

        expect(quiz.quiz_questions.count).to eq 2
        quiz_question1 = quiz.quiz_questions.list_order.first
        expect(quiz_question1.text).to eq target.first[:question]
        expect(quiz_question1.list_order).to eq 1
        expect(quiz_question1.quiz_question_answers.count).to eq 2
        quiz_question1_answer_correct = quiz_question1.quiz_question_answers.correct.first
        expect(quiz_question1_answer_correct.text).to eq target.first[:correct].first
        quiz_question1_answer_incorrect = quiz_question1.quiz_question_answers.incorrect.first
        expect(quiz_question1_answer_incorrect.text).to eq target.first[:incorrect].first

        quiz_question2 = quiz.quiz_questions.list_order.second
        expect(quiz_question2.text).to eq target.second[:question]
        expect(quiz_question2.list_order).to eq 2
        expect(quiz_question2.quiz_question_answers.count).to eq 2
        quiz_question2_answer_correct = quiz_question2.quiz_question_answers.correct.first
        expect(quiz_question2_answer_correct.text).to eq target.second[:correct].first
        quiz_question2_answer_incorrect = quiz_question2.quiz_question_answers.incorrect.first
        expect(quiz_question2_answer_incorrect.text).to eq target.second[:incorrect].first

        # previous quiz status isn't updated
        expect(previous_quiz.reload.status).to eq "replaced"
      end
    end
  end
end
