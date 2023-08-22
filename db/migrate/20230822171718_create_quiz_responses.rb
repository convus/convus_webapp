class CreateQuizResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :quiz_responses do |t|
      t.references :quiz, foreign_key: true
      t.references :user, foreign_key: true
      t.references :citation, foreign_key: true

      t.integer :status, default: 0

      t.integer :question_count
      t.integer :correct_count
      t.integer :incorrect_count

      t.timestamps
    end
  end
end
