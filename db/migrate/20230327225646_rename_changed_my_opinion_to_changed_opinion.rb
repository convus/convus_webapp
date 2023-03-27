class RenameChangedMyOpinionToChangedOpinion < ActiveRecord::Migration[7.0]
  def change
    rename_column :ratings, :changed_my_opinion, :changed_opinion
    rename_column :ratings, :did_not_understand, :not_understood
  end
end
