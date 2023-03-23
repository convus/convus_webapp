require "rails_helper"

base_url = "/admin/topic_investigations"
RSpec.describe base_url, type: :request do
  let(:topic_investigation) { FactoryBot.create(:topic_investigation) }
  let(:start_at) { (Time.current - 1.day) }
  let(:end_at) { (Time.current + 1.day) }
  let(:valid_params) do
    {
      topic_name: "Example topic",
      start_at_in_zone: form_formatted(start_at),
      end_at_in_zone: form_formatted(end_at),
      timezone: "America/Bogota"
    }
  end

  def form_formatted(time)
    return "" if time.blank?
    time.strftime("%Y-%m-%dT%H:%M")
  end

  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to new_user_registration_path
      expect(session[:user_return_to]).to eq "/admin/topic_investigations"
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
        expect(topic_investigation).to be_present
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/topic_investigations/index")
        expect(assigns(:topic_investigations).pluck(:id)).to eq([topic_investigation.id])
        # test out alphabetical sort
        get "#{base_url}?sort=name"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/topic_investigations/index")
        expect(assigns(:topic_investigations).pluck(:id)).to eq([topic_investigation.id])
      end
    end

    describe "new" do
      it "renders" do
        get "#{base_url}/new"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/topic_investigations/new")
      end
    end

    describe "create" do
      it "creates" do
        expect {
          post base_url, params: {topic_investigation: valid_params}
        }.to change(TopicInvestigation, :count).by 1
        topic_investigation = TopicInvestigation.last
        expect(topic_investigation.topic_name).to eq "Example topic"
        expect(Time.zone.name).to eq "America/Los_Angeles"
        zone_difference = Time.current.utc_offset - TranzitoUtils::TimeParser.parse_timezone(valid_params[:timezone]).utc_offset
        # TODO: this will fail when DST changes
        expect(zone_difference).to eq(-7200)
        expect(topic_investigation.start_at.to_i).to be_within(60).of(start_at.to_i + zone_difference)
        expect(topic_investigation.end_at.to_i).to be_within(60).of(end_at.to_i + zone_difference)
      end
    end

    describe "edit" do
      it "renders" do
        get "#{base_url}/#{topic_investigation.to_param}/edit"
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/topic_investigations/edit")
      end
    end

    describe "update" do
      it "updates" do
        expect(topic_investigation).to be_valid
        expect(topic_investigation.status).to eq "pending"
        patch "#{base_url}/#{topic_investigation.id}", params: {topic_investigation: valid_params}
        expect(flash[:success]).to be_present
        expect(topic_investigation.reload.topic_name).to eq "Example topic"
        expect(topic_investigation.status).to eq "active"
      end
    end

    describe "destroy" do
      it "destroys" do
        expect(topic_investigation).to be_present
        expect {
          delete "#{base_url}/#{topic_investigation.to_param}"
        }.to change(TopicInvestigation, :count).by(-1)
        expect(flash[:success]).to be_present
      end
    end
  end
end
