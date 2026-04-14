# frozen_string_literal: true

module SortableTable
  extend ActiveSupport::Concern

  SORT_DIRECTIONS = %w[asc desc].freeze

  included do
    helper_method :sort_column, :sort_direction, :default_column, :default_direction
  end

  def sort_column
    sortable_columns.include?(params[:sort]) ? params[:sort] : default_column
  end

  def sort_direction
    SORT_DIRECTIONS.include?(params[:direction]) ? params[:direction] : default_direction
  end

  def default_direction
    "desc"
  end

  def default_column
    sortable_columns&.first
  end
end
