class TopicRelation < ApplicationRecord
  belongs_to :parent, class_name: "Topic"
  belongs_to :child, class_name: "Topic"

  validates_uniqueness_of :parent_id, scope: [:child_id]

  scope :direct, -> { where(direct: true) }
  scope :distant, -> { where(direct: false) }

  def distant?
    !direct?
  end
end
