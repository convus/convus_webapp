require "rails_helper"

RSpec.describe Quiz, type: :model do
  describe "update_status_of_replaced_quizzes" do
    let(:quiz) { FactoryBot.create(:quiz, input_text: " ") }
    let(:citation) { quiz.citation }
    let(:quiz2) { FactoryBot.create(:quiz, citation: citation) }
    it "updates all the previous quizzes" do
      expect(quiz).to be_valid
      expect(quiz.status).to eq "pending"
      expect(quiz.version).to eq 1
      expect(quiz.source).to eq "admin_entry"
      expect(quiz.kind).to eq "citation_quiz"
      expect(quiz.input_text_format).to eq "claude_initial"
      expect(quiz.input_text).to be_nil
      expect(quiz.current?).to be_truthy
      expect(quiz.associated_quizzes_current&.id).to eq quiz.id

      expect(quiz2.status).to eq "pending"
      expect(quiz2.version).to eq 2
      expect(quiz2.source).to eq "admin_entry"
      expect(quiz2.kind).to eq "citation_quiz"

      quiz.reload
      expect(quiz.status).to eq "replaced"
      expect(quiz.version).to eq 1
      expect(quiz.associated_quizzes_current&.id).to eq quiz2.id
    end
  end
end
