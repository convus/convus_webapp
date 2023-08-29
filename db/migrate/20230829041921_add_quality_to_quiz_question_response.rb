class AddQualityToQuizQuestionResponse < ActiveRecord::Migration[7.0]
  def change
    add_column :quiz_question_responses, :quality, :integer, default: 0
  end
end
