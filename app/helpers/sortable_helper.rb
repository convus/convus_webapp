# frozen_string_literal: true

module SortableHelper
  DEFAULT_SEARCH_KEYS = [
    :direction, :sort, # sorting params
    :period, :start_time, :end_time, :render_chart, # Time period params
    :user_id, :query, :per_page, # General search params
    :user, :filters, {search_topics: []} # App-specific search params
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

  def sortable(column, title = nil, **html_options)
    title ||= column.to_s.gsub(/_(id|at)\z/, "").titleize
    render_sortable = !html_options.delete(:skip_sortable)
    css_class = html_options.delete(:class) || ""

    if !render_sortable
      content_tag(:span, title, class: "sortable-link #{css_class}")
    else
      current_sort = respond_to?(:sort_column) ? sort_column : nil
      current_direction = respond_to?(:sort_direction) ? sort_direction : "desc"
      direction = (column.to_s == current_sort && current_direction == "asc") ? "desc" : "asc"
      arrow = if column.to_s == current_sort
        (current_direction == "asc") ? " ↑" : " ↓"
      end
      link_to("#{title}#{arrow}".html_safe,
        url_for(sortable_search_params.merge(sort: column, direction: direction)),
        class: "sortable-link #{css_class}",
        **html_options)
    end
  end

  def humanized_time_range_column(time_range_column, return_value_for_all: false)
    return return_value_for_all if time_range_column == "created_at"
    time_range_column.to_s.gsub(/_at\z/, "").humanize.downcase
  end

  def humanized_time_range(time_range)
    return "" unless time_range.present?
    start_html = content_tag(:span, time_range.first.to_i, class: "localizeTime")
    end_html = content_tag(:span, time_range.last.to_i, class: "localizeTime")
    " #{start_html} - #{end_html}".html_safe
  end

  private

  # This is a separate method purely for testing purposes, so it can be stubbed
  def sortable_url(sort, direction)
    url_for(sortable_search_params.merge(sort:, direction:))
  end
end
