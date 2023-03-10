class ShareFormatter
  def self.share_user(user, timezone = nil)
    ["#{user.total_kudos_today(timezone)} kudos tday, ",
     "#{user.total_kudos_yesterday(timezone)} yday\n\n",
     Rails.application.routes.url_helpers.u_url(user.to_param)]
     .join("")
  end
end
