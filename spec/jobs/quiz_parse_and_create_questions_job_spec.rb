# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuizParseAndCreateQuestionsJob, type: :job do
  let(:instance) { described_class.new }
  let(:input_text) { "Some example text" }
  let(:time) { Time.at(1684698531) } # 2023-05-21 12:48
  let(:citation) { FactoryBot.create(:citation, published_updated_at: time, subject: "Citation initial subject") }
  let(:quiz) do
    FactoryBot.create(:quiz,
      input_text: input_text,
      citation: citation,
      source: source,
      subject: "Quiz initial subject",
      subject_source: nil)
  end
  let(:source) { :claude_integration }
  let(:input_text) { nil }

  describe "#perform" do
    let!(:previous_quiz) { FactoryBot.create(:quiz, citation: citation, status: :active) }
    context "quiz status: active" do
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

    context "invalid input_text" do
      let(:input_text) { "Something or other" }
      it "adds a parse error" do
        instance.perform(quiz.id)
        quiz.reload
        expect(quiz.input_text_parse_error).to match(/unable to parse/i)
        expect(quiz.status).to eq "parse_errored"
        # previous quiz status isn't updated
        expect(previous_quiz.reload.status).to eq "active"
      end
    end

    context "valid quiz" do
      let(:quiz_input_text) { "Here is a summary of the key events from the article in a chronological true/false format with questions:\nStep 1:\nQuestion: Question One\nTrue option: Something True\nFalse option: Something false\nStep 2:  \nQuestion: Question two\nTrue option: Something 2 True\nFalse option: Something 2 false\n\n" }
      let(:input_text) { quiz_input_text }
      let(:target) do
        [
          {
            question: "Question One",
            correct: ["Something True"],
            incorrect: ["Something false"]
          }, {
            question: "Question two",
            correct: ["Something 2 True"],
            incorrect: ["Something 2 false"]
          }
        ]
      end

      def expect_target_questions_created(quiz)
        expect(described_class.parsed_quiz_text(quiz)).to eq target
        instance.perform(quiz.id)
        quiz.reload
        expect(quiz.input_text_parse_error).to be_nil

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
        expect(previous_quiz.subject).to eq "Citation initial subject"
      end

      it "creates questions and answers" do
        expect(citation.reload.subject).to eq "Citation initial subject"
        expect(quiz.reload.subject).to eq "Quiz initial subject"

        expect_target_questions_created(quiz)
        expect(quiz.status).to eq "active"

        expect(described_class.parsed_subject_text(quiz)).to be_nil
        expect(quiz.subject).to eq "Quiz initial subject"
        expect(quiz.subject_source).to eq "subject_inherited"
        expect(citation.reload.subject).to eq "Citation initial subject"
        expect(citation.manually_updated_attributes).to eq([])
      end

      context "quiz status: disabled" do
        before { quiz.update(status: :disabled) }
        it "creates questions and answers, doesn't update status" do
          expect_target_questions_created(quiz)
          expect(quiz.status).to eq "disabled"
          expect(quiz.subject).to eq "Quiz initial subject"
        end
      end

      describe "input_text includes subject" do
        let(:subject_text) { "A special event on 2023-09-12" }
        let(:input_text) { quiz_input_text + "\n\n---\n\nThe subject of the article is: #{subject_text}" }
        it "updates the quiz and citation subjects" do
          expect(described_class.parsed_subject_text(quiz)).to eq subject_text
          expect_target_questions_created(quiz)

          expect(quiz.status).to eq "active"
          expect(quiz.subject).to eq subject_text
          expect(quiz.subject_source).to eq "subject_claude_integration"
          expect(citation.reload.subject).to eq subject_text
          expect(citation.manually_updated_attributes).to eq([])
          expect(citation.reload.manually_updated_subject?).to be_falsey
        end
        context "citation manually_updated_subject" do
          before { citation.update(manually_updated_attributes: ["subject"]) }
          it "doesn't update the citation subject" do
            expect(citation.reload.manually_updated_subject?).to be_truthy
            expect(quiz.reload.source).to eq "claude_integration"
            expect(quiz.subject_source).to eq "subject_admin_citation_entry"
            expect(quiz.subject).to eq "Citation initial subject"
            expect(described_class.parsed_subject_text(quiz)).to eq subject_text

            expect_target_questions_created(quiz)

            expect(quiz.status).to eq "active"
            expect(quiz.subject).to eq "Citation initial subject"
            expect(quiz.subject_source).to eq "subject_admin_citation_entry"
            expect(citation.reload.subject).to eq "Citation initial subject"
            expect(citation.manually_updated_attributes).to eq(["subject"])
          end
        end
        context "admin_entry" do
          let(:source) { :admin_entry }
          it "updates the citation subject, doesn't update with parsed subject" do
            expect(quiz.reload.source).to eq "admin_entry"
            expect(quiz.subject_source).to eq "subject_admin_entry"
            expect(citation.reload.manually_updated_subject?).to be_falsey
            expect(described_class.parsed_subject_text(quiz)).to eq subject_text

            expect_target_questions_created(quiz)

            expect(quiz.status).to eq "active"
            expect(quiz.subject).to eq "Quiz initial subject"
            expect(quiz.subject_source).to eq "subject_admin_entry"
            expect(citation.reload.subject).to eq "Quiz initial subject"
            expect(citation.manually_updated_attributes).to eq([])
          end
        end
      end
    end
  end

  describe "create_questions_and_answers" do
    let(:parsed_question) { {question: "Question One", correct: ["Something True"], incorrect: ["Something false"]} }
    it "creates a quiz_question and answer" do
      expect(quiz.reload.quiz_questions.count).to eq 0
      instance.create_question_and_answers(quiz, parsed_question, 1)

      expect(quiz.reload.quiz_questions.count).to eq 1
      expect(quiz.quiz_questions.first.text).to eq "Question One"
      expect(quiz.quiz_question_answers.count).to eq 2
      expect(quiz.quiz_question_answers.pluck(:text)).to match_array(["Something True", "Something false"])
    end
    context "no incorrect answer" do
      let(:parsed_question) { {question: "Question One", correct: ["Something True"], incorrect: []} }
      it "doesn't create a quiz question and answer" do
        expect(quiz.reload.quiz_questions.count).to eq 0
        instance.create_question_and_answers(quiz, parsed_question, 1)

        expect(quiz.reload.quiz_questions.count).to eq 0
      end
    end
  end
end
