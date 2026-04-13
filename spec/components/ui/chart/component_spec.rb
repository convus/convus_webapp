# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Chart::Component, type: :component do
  let(:time_range) { 1.week.ago..Time.current }
  let(:instance) { described_class.new(series: [{name: "Test", data: {}}], time_range:) }

  it "renders with default colors" do
    component = render_inline(instance)
    script_content = component.css("script").text
    expect(script_content).to be_present
    described_class::COLORS.each do |color|
      expect(script_content).to include(color)
    end
  end

  context "with custom colors" do
    let(:custom_colors) { %w[#111111 #222222] }
    let(:instance) { described_class.new(series: [{name: "Test", data: {}}], time_range:, colors: custom_colors) }
    it "renders with custom colors" do
      script_content = render_inline(instance).css("script").text
      custom_colors.each { |color| expect(script_content).to include(color) }
      expect(script_content).not_to include(described_class::COLORS.last)
    end
  end

  describe "group_by_method" do
    context "hourly" do
      it "returns group_by_minute" do
        expect(described_class.send(:group_by_method, (Time.current - 1.hour)..Time.current)).to eq :group_by_minute
      end
    end
    context "daily" do
      it "returns group_by_hour" do
        expect(described_class.send(:group_by_method, (Time.current - 1.day)..Time.current)).to eq :group_by_hour
      end
    end
    context "weekly" do
      it "returns group_by_day" do
        expect(described_class.send(:group_by_method, (Time.current - 6.days)..Time.current)).to eq :group_by_day
      end
    end
    context "6 months" do
      it "returns group_by_week" do
        expect(described_class.send(:group_by_method, (Time.current - 6.months)..Time.current)).to eq :group_by_week
      end
    end
    context "2 years" do
      it "returns group_by_month" do
        expect(described_class.send(:group_by_method, (Time.current - 2.years)..Time.current)).to eq :group_by_month
      end
    end
  end

  describe "group_by_format" do
    let(:end_time) { Time.at(1578268910) } # 2020-01-06 00:01:38 UTC
    let(:format_time_range) { start_time..end_time }
    context "1 hour" do
      let(:start_time) { end_time - 1.hour }
      it "is hour:minute pm" do
        expect(end_time.in_time_zone("America/New_York").strftime(described_class.send(:group_by_format, format_time_range))).to eq " 7:01 PM"
      end
    end
    context "2 days" do
      let(:start_time) { end_time - 47.hours }
      it "is weekday hour pm" do
        expect(end_time.in_time_zone("America/New_York").strftime(described_class.send(:group_by_format, format_time_range))).to eq "Sun 7 PM"
      end
    end
    context "6 days" do
      let(:start_time) { end_time - 6.days }
      it "is weekday date" do
        expect(end_time.in_time_zone("America/New_York").strftime(described_class.send(:group_by_format, format_time_range))).to eq "Sun 1-5"
      end
    end
    context "10 days" do
      let(:start_time) { end_time - 10.days }
      it "is date" do
        expect(end_time.in_time_zone("America/New_York").strftime(described_class.send(:group_by_format, format_time_range))).to eq "2020-1-5"
      end
    end
    context "13 months" do
      let(:start_time) { end_time - 13.months }
      it "is year-month" do
        expect(end_time.strftime(described_class.send(:group_by_format, format_time_range))).to eq "2020-1"
      end
    end
  end
end
