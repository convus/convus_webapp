module ListOrdered
  extend ActiveSupport::Concern

  included do
    scope :list_order, -> { order(:list_order) }
  end
end
