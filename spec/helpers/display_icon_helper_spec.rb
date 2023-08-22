# frozen_string_literal: true

require "rails_helper"

RSpec.describe DisplayIconHelper, type: :helper do
  describe "agreement_display" do
    before { @sortable_params = {} }

    it "returns nil" do
      expect(agreement_display("")).to be_nil
    end
    context "neutral" do
      it "returns -" do
        expect(agreement_display(:neutral)).to be_blank
      end
    end
    context "agree" do
      let(:target) { "<span title=\"Agree\"><img class=\"w-4 inline-block\" src=\"/images/icons/agree_icon.svg\" /></span>" }
      it "returns -" do
        expect(agreement_display(:agree)).to eq target
      end
      context "link" do
        let(:target) { "<a title=\"Agree\" href=\"/ratings?search_agree=true&amp;search_disagree=false\"><img class=\"w-4 inline-block\" src=\"/images/icons/agree_icon.svg\" /></a>" }
        let(:bp) { {controller: "ratings", action: "index"} }
        it "returns with link" do
          expect(agreement_display("agree", link: bp)).to eq target
          expect(agreement_display(:agree, link: bp.merge(search_agree: false, search_disagree: true))).to eq target
          expect(agreement_display("agree", link: bp.merge(search_disagree: false))).to eq target
          expect(agreement_display(:agree, link: bp.merge(search_disagree: true, search_agree: false))).to eq target
          # Same result if search_agreement == disagree
          @search_agreement = :disagree
          expect(agreement_display("agree", link: bp)).to eq target
        end
        # context "link: true" do
        #   # TODO: need to stub current route I think? Not sure exactly what to do to make
        #   # url_for() correctly pull the current controller_name and action_name in tests
        #   it "returns with link" do
        #     expect(agreement_display(:agree, link: true)).to eq target
        #   end
        # end
        context "matching search_agreement" do
          let(:target) { "<a title=\"Agree\" href=\"/ratings\"><img class=\"w-4 inline-block\" src=\"/images/icons/agree_icon.svg\" /></a>" }
          before { @search_agreement = :agree }
          it "returns with link with no agreement params" do
            expect(agreement_display("agree", link: bp)).to eq target
            expect(agreement_display(:agree, link: bp.merge(search_agree: true))).to eq target
          end
        end
      end
    end
  end

  describe "quality_display" do
    it "returns nil" do
      expect(quality_display("")).to be_nil
    end
    context "neutral" do
      it "returns -" do
        expect(quality_display("quality_med")).to be_nil
      end
    end
    context "agree" do
      let(:target) { "<span title=\"High Quality\"><img class=\"w-4 inline-block\" src=\"/images/icons/quality_high_icon.svg\" /></span>" }
      it "returns -" do
        expect(quality_display(:quality_high)).to eq target
      end
    end
  end
end
