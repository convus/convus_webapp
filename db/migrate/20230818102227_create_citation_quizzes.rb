class CreateCitationQuizzes < ActiveRecord::Migration[7.0]
  def change
    create_table :citation_quizzes do |t|
      t.references :citation, foreign_key: true
      t.boolean :replaced, null: false, default: false
      t.text :prompt


      t.timestamps
    end
  end
end
