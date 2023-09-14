require "rails_helper"

RSpec.describe Quiz, type: :model do
  describe "factory" do
    let(:quiz) { FactoryBot.create(:quiz, :with_question_and_answer) }
    it "is valid" do
      expect(quiz).to be_valid
      expect(quiz.quiz_questions.count).to eq 1
      expect(quiz.quiz_question_answers.count).to eq 1
      expect(quiz.quiz_question_answers.correct.count).to eq 1
    end
  end
  describe "update_status_of_replaced_quizzes" do
    let(:quiz) { FactoryBot.create(:quiz, input_text: " ") }
    let(:citation) { quiz.citation }
    let(:quiz2) { FactoryBot.create(:quiz, citation: citation) }
    it "updates all the previous quizzes" do
      expect(quiz).to be_valid
      expect(quiz.status).to eq "pending"
      expect(quiz.version).to eq 1
      expect(quiz.source).to eq "admin_entry"
      expect(quiz.source_humanized).to eq "Admin entry"
      expect(quiz.kind).to eq "citation_quiz"
      expect(quiz.kind_humanized).to eq "Citation quiz"
      expect(quiz.input_text_format).to eq "claude_second"
      expect(quiz.input_text).to be_nil
      expect(quiz.current?).to be_truthy
      expect(quiz.associated_quizzes_current&.id).to eq quiz.id

      expect(quiz2.status).to eq "pending"
      expect(quiz2.version).to eq 2
      expect(quiz2.source).to eq "admin_entry"
      expect(quiz2.kind).to eq "citation_quiz"
      expect(quiz2.associated_quizzes_current&.id).to eq quiz2.id

      quiz.reload
      expect(quiz.status).to eq "pending"
      expect(quiz.version).to eq 1
      expect(quiz.associated_quizzes_current&.id).to eq quiz2.id
      expect(citation.quiz_active&.id).to be_blank
    end
    context "quiz active" do
      before { quiz.update(status: "active") }
      it "citation returns quiz_active" do
        expect(quiz2.status).to eq "pending"
        expect(quiz2.version).to eq 2
        expect(quiz2.source).to eq "admin_entry"
        expect(quiz2.kind).to eq "citation_quiz"

        quiz.reload
        expect(quiz.status).to eq "active"
        expect(quiz.version).to eq 1
        expect(quiz.associated_quizzes_current&.id).to eq quiz2.id
        expect(citation.quiz_active&.id).to eq quiz.id
      end
    end
  end

  describe "topics and subject" do
    let(:topic) { FactoryBot.create(:topic, name: "Environment") }
    let(:citation_topic) { FactoryBot.create(:citation_topic, topic: topic) }
    let(:citation) { citation_topic.citation }
    let(:quiz) { FactoryBot.create(:quiz, citation: citation) }
    it "uses citation_topic association" do
      expect(citation.reload.subject).to be_nil
      citation.update(updated_at: Time.current)
      expect(citation.reload.subject).to be_nil
      expect(citation.manually_updated_attributes).to eq([])
      expect(quiz.topics.pluck(:id)).to eq([topic.id])
      expect(Quiz.matching_topics(topic).pluck(:id)).to eq([quiz.id])

      quiz.update(subject: "Specific Environment")
      # Citation subject is updated in QuizParseAndCreateQuestionsJob
      expect(citation.reload.subject).to be_nil
    end
  end
end
