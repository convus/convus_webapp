class ClaudeIntegration
  API_KEY = ENV["ANTHROPIC_KEY"]

  def get_quiz_response(prompt)
    "xxxx"
  end

  # v1/complete
  def connection
    @connection ||= Faraday.new(url: "https://api.anthropic.com/") do |conn|
      conn.headers["Content-Type"] = "application/json"
      conn.headers["anthropic-version"] = "2023-06-01"
      conn.headers["x-api-key"] = API_KEY
      conn.adapter Faraday.default_adapter
    end
  end
end
