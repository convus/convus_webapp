class TopicRelation < ApplicationRecord
  belongs_to :parent, class_name: "Topic"
  belongs_to :child, class_name: "Topic"

  validates_uniqueness_of :parent_id, scope: [:child_id], allow_nil: false
  validate :not_self_relation

  scope :direct, -> { where(direct: true) }
  scope :distant, -> { where(direct: false) }

  def distant?
    !direct?
  end

  def not_self_relation
    return true if parent_id != child_id
    errors.add(:parent_id, "can't be a self relation")
  end
end
