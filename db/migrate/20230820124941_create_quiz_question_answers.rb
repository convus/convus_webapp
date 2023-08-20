class CreateQuizQuestionAnswers < ActiveRecord::Migration[7.0]
  def change
    create_table :quiz_question_answers do |t|
      t.references :quiz_question, foreign_key: true

      t.integer :list_order, default: 0

      t.text :text

      t.boolean :correct, default: false, nil: false

      t.timestamps
    end
  end
end
