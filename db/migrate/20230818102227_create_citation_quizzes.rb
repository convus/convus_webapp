class CreateCitationQuizzes < ActiveRecord::Migration[7.0]
  def change
    create_table :citation_quizzes do |t|
      t.references :citation, foreign_key: true
      t.text :prompt

      t.integer :status, default: 0

      t.timestamps
    end
  end
end
