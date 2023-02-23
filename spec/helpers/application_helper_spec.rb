# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "agreement_display" do
    it "returns nil" do
      expect(agreement_display("")).to be_nil
    end
    context "neutral" do
      let(:target) { "<span class=\"less-strong\">-</span>"}
      it "returns -" do
        expect(agreement_display(:neutral)).to eq target
      end
    end
    context "agree" do
      let(:target) { "<span>agree</span>"}
      it "returns -" do
        expect(agreement_display(:agree)).to eq target
      end
    end
  end

  describe "quality_display" do
    it "returns nil" do
      expect(quality_display("")).to be_nil
    end
    context "neutral" do
      let(:target) { "<span class=\"less-strong\">-</span>"}
      it "returns -" do
        expect(quality_display("quality_med")).to eq target
      end
    end
    context "agree" do
      let(:target) { "<span>high</span>"}
      it "returns -" do
        expect(quality_display(:quality_high)).to eq target
      end
    end
  end
end
