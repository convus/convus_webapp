class CreateQuizQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :quiz_questions do |t|
      t.references :quiz, foreign_key: true

      t.integer :list_order, default: 0

      t.text :text

      t.timestamps
    end
  end
end
