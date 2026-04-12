class DropQuizTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :quiz_question_responses, if_exists: true
    drop_table :quiz_question_answers, if_exists: true
    drop_table :quiz_questions, if_exists: true
    drop_table :quiz_responses, if_exists: true
    drop_table :quizzes, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
