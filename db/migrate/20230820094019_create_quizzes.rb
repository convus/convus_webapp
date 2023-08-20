class CreateQuizzes < ActiveRecord::Migration[7.0]
  def change
    create_table :quizzes do |t|
      t.integer :source
      t.integer :status, default: 0

      t.integer :kind
      t.references :citation, foreign_key: true

      t.integer :version

      t.text :input_text
      t.integer :input_text_format

      t.timestamps
    end
  end
end
