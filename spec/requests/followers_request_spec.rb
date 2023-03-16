require "rails_helper"

base_url = "/followers"
RSpec.describe base_url, type: :request do
  let(:user_subject) { FactoryBot.create(:user, username: "OTHer-name") }

end
