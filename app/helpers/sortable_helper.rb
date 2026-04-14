# frozen_string_literal: true

module SortableHelper
  DEFAULT_SEARCH_KEYS = [
    :direction, :sort, # sorting params
    :period, :start_time, :end_time, :render_chart, # Time period params
    :user_id, :query, :per_page # General search params
  ].freeze

  def sortable_search_params?(except: [])
    except_keys = %i[direction sort period per_page] + except
    s_params = sortable_search_params.except(*except_keys).values.reject(&:blank?).any?

    return true if s_params
    return false if except.map(&:to_s).include?("period")

    params[:period].present? && params[:period] != "all"
  end

  def sortable_search_params
    return @sortable_search_params if defined?(@sortable_search_params)

    search_param_keys = params.keys.select { |k| k.to_s.start_with?("search_") }
    @sortable_search_params = params.permit(*(DEFAULT_SEARCH_KEYS | search_param_keys))
  end

  private

  # This is a separate method purely for testing purposes, so it can be stubbed
  def sortable_url(sort, direction)
    url_for(sortable_search_params.merge(sort:, direction:))
  end
end
