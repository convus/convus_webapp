# frozen_string_literal: true

require "rails_helper"

RSpec.describe QuizHelper, type: :helper do
  let(:quiz) { FactoryBot.create(:quiz, input_text: input_text, citation: citation) }
  let(:publisher) { FactoryBot.create(:publisher, name: "a Publisher") }
  let(:citation) { FactoryBot.create(:citation, publisher: publisher, created_at: time) }
  let(:time) { Time.at(1657071309) } # 2022-07-05 18:35:09
  let(:time_el) { "<span class=\"convertTime withPreposition\">#{time.to_i}</span>" }
  let(:input_text) { nil }

  describe "quiz_title_display" do
    context "with subject" do
      let(:target) do
        "<span>Cool stuff, from<span class=\"no-underline\"> </span><span class=\"decoration-publisher\">a Publisher</span>" \
        "<span class=\"no-underline\"> </span>#{time_el}</span>"
      end
      it "responds with text" do
        quiz.subject = "Cool stuff"
        expect(citation.reload.published_updated_at_with_fallback).to be_within(1).of time
        expect(citation.authors).to be_empty
        expect(quiz_title_display(quiz)).to eq target
      end
    end

    context "with no author" do
      let(:target) do
        "<span>an article, from<span class=\"no-underline\"> </span><span class=\"decoration-publisher\">a Publisher</span>" \
        "<span class=\"no-underline\"> </span>#{time_el}</span>"
      end
      it "responds with text" do
        expect(citation.reload.published_updated_at_with_fallback).to be_within(1).of time
        expect(citation.authors).to be_empty
        expect(quiz_title_display(quiz)).to eq target
      end
    end

    context "with one author" do
      let(:citation) { FactoryBot.create(:citation, publisher: publisher, authors: ["Sally"], published_updated_at: time) }
      let(:target) do
        "<span>an article, from <em>Sally</em> in<span class=\"no-underline\"> </span><span class=\"decoration-publisher\">a Publisher</span>" \
        "<span class=\"no-underline\"> </span>#{time_el}</span>" \
      end
      it "responds with text" do
        expect(quiz_title_display(quiz)).to eq target
      end
    end
  end
end
