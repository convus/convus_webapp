# frozen_string_literal: true

module SetPeriod
  extend ActiveSupport::Concern

  PERIOD_TYPES = %w[hour day month year week all next_week next_month].freeze

  included do
    helper_method :set_period
  end

  def set_period
    set_timezone
    @render_chart = params[:render_chart].present?
    if params[:start_time].present? && params[:end_time].present?
      @start_time = Binxtils::TimeParser.parse(params[:start_time], @timezone)
      @end_time = Binxtils::TimeParser.parse(params[:end_time], @timezone)
      @period = "custom"
    elsif params[:search_at].present?
      search_at = Binxtils::TimeParser.parse(params[:search_at], @timezone)
      offset = (params[:search_at_offset] || 10).to_i.minutes
      @start_time = search_at - offset
      @end_time = search_at + offset
      @period = "custom"
    else
      @period = PERIOD_TYPES.include?(params[:period]) ? params[:period] : default_period
      set_time_range_from_period
    end
    @time_range = @start_time..@end_time
    @per_page = params[:per_page] || 25
  end

  def controller_namespace
    @controller_namespace ||= (self.class.module_parent.name != "Object") ? self.class.module_parent.name.downcase : nil
  end

  private

  def set_time_range_from_period
    case @period
    when "hour"
      @start_time = Time.current - 1.hour
    when "day"
      @start_time = Time.current - 1.day
    when "month"
      @start_time = Time.current - 30.days
    when "year"
      @start_time = Time.current - 1.year
    when "week"
      @start_time = Time.current - 7.days
    when "next_week"
      @start_time = Time.current
      @end_time = Time.current + 7.days
    when "next_month"
      @start_time = Time.current
      @end_time = Time.current + 30.days
    when "all"
      @start_time = earliest_period_date
    end
    @end_time ||= latest_period_date
    @start_time ||= earliest_period_date
  end

  def default_period
    "all"
  end

  def latest_period_date
    Time.current
  end

  def earliest_period_date
    Time.at(1672560000) # 2023-01-01
  end

  def set_timezone
    if params[:timezone].present?
      @timezone = Binxtils::TimeZoneParser.parse(params[:timezone])
      session[:timezone] = @timezone&.name
    elsif session[:timezone].present?
      @timezone = Binxtils::TimeZoneParser.parse(session[:timezone])
    end
  end
end
