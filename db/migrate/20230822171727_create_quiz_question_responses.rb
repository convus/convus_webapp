class CreateQuizQuestionResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :quiz_question_responses do |t|
      t.references :quiz_response, foreign_key: true
      t.references :quiz_question, foreign_key: true
      t.references :quiz_question_answer, foreign_key: true

      t.boolean :correct

      t.timestamps
    end
  end
end
