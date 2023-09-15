class AddSubjectSourceToQuizzes < ActiveRecord::Migration[7.0]
  def change
    add_column :quizzes, :subject_source, :integer
    remove_column :quizzes, :subject_set_manually, :boolean
  end
end
