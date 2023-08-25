class ClaudeIntegration
  API_KEY = ENV["ANTHROPIC_KEY"]

  def format_prompt(str)
    "\n\nHuman: #{str}\n\nAssistant:"
  end

  def completion_for_prompt(prompt)
    result = request_completion(format_prompt(prompt))
    result["completion"] || result
  end

  def request_completion(formatted_prompt)
    response = connection.post("/v1/complete") do |req|
      req.body = {
        model: "claude-2",
        prompt: formatted_prompt,
        max_tokens_to_sample: 2000,
        stream: false
      }.to_json
    end
    JSON.parse(response.body)
  end

  def connection
    @connection ||= Faraday.new(url: "https://api.anthropic.com/") do |conn|
      conn.headers["Content-Type"] = "application/json"
      conn.headers["anthropic-version"] = "2023-06-01"
      conn.headers["x-api-key"] = API_KEY
      conn.options.timeout = 120
      conn.adapter Faraday.default_adapter
    end
  end
end
