class AddClaudeParamsToQuiz < ActiveRecord::Migration[7.0]
  def change
    add_column :quizzes, :prompt_params, :jsonb, default: {}
  end
end
