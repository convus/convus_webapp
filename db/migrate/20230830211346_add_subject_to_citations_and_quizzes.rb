class AddSubjectToCitationsAndQuizzes < ActiveRecord::Migration[7.0]
  def change
    add_column :citations, :subject, :string
    add_column :quizzes, :subject, :string
    add_column :quizzes, :subject_set_manually, :boolean, default: false
  end
end
