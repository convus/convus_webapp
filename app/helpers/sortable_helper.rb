# frozen_string_literal: true

# App-specific extensions to Binxtils::SortableHelper
module SortableHelper
  include Binxtils::SortableHelper

  # Add app-specific search keys to the base set
  def default_search_keys
    super + [:user, :filters, {search_topics: []}]
  end

  # Override sortable to use **kwargs (required for Ruby 4.0 keyword argument separation)
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
end
