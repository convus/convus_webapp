# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminHelper, type: :helper do
  describe "missing_meta_count" do
    let(:citation) { Citation.new }
    it "is full count" do
      expect(missing_meta_count(citation)).to eq("<span class=\"text-error\">6</span>")
    end
    context "attrs" do
      let(:citation) { Citation.new(authors: "dddd", description: "fff", word_count: 222, published_at: Time.current) }
      it "is less" do
        expect(missing_meta_count(citation)).to eq("<span class=\"text-success\">2</span>")
      end
    end
  end
end
