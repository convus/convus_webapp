require "rails_helper"

base_url = "/admin/quizzes"
RSpec.describe base_url, type: :request do
  let(:quiz) { FactoryBot.create(:quiz) }
  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to new_user_session_path
      expect(session[:user_return_to]).to eq "/admin/quizzes"
    end

    context "signed in" do
      include_context :logged_in_as_user
      it "flash errors" do
        get base_url
        expect(response).to redirect_to root_url
        expect(flash[:error]).to be_present
      end
    end
  end

  context "signed in as admin" do
    include_context :logged_in_as_admin
    describe "index" do
      it "renders" do
        expect(quiz).to be_valid
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/quizzes/index")
        expect(assigns(:quizzes).pluck(:id)).to eq([quiz.id])
      end
    end

    describe "new" do
      it "renders" do
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/quizzes/new")
      end
    end

    describe "create" do
      let!(:parent) { FactoryBot.create(:quiz, name: "Something") }
      let(:valid_params) { {name: "name", parents_string: "something"} }
      it "creates" do
        post base_url, params: {quiz: valid_params}
        expect(flash[:success]).to be_present
        new_quiz = Quiz.last
      end
    end

    describe "edit" do
      it "renders" do
        get "#{base_url}/#{quiz.id}/edit"
        expect(response.code).to eq "200"
        expect(assigns(:quiz)&.id).to eq quiz.id
        expect(response).to render_template("admin/quizzes/edit")
      end
      context "id: citation slug" do
        let(:citation) { quiz.citation }
        it "renders" do
          get "#{base_url}/#{quiz.citation.slug}/edit"
          expect(response.code).to eq "200"
          expect(assigns(:quiz)&.id).to eq quiz.id
          expect(response).to render_template("admin/quizzes/edit")
        end
      end
    end

    describe "update" do
      it "updates" do
        patch "#{base_url}/#{quiz.id}", params: {quiz: {}}
        expect(flash[:success]).to be_present
      end
    end
  end
end
