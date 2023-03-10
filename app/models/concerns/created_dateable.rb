module CreatedDateable
  extend ActiveSupport::Concern

  class_methods do
    def date_in_timezone(time = nil, timezone = nil)
      time ||= Time.current
      return time.to_date if timezone.blank?
      tz = TranzitoUtils::TimeParser.parse_timezone(timezone)
      time.in_time_zone(tz).to_date
    end

    def created_today(passed_timezone = nil)
      date = date_in_timezone(Time.current, passed_timezone)
      where(created_date: date)
    end

    def created_yesterday(passed_timezone = nil)
      date = date_in_timezone(Time.current, passed_timezone)
      where(created_date: date - 1.day)
    end
  end
end
