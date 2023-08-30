class ClaudeIntegration
  API_KEY = ENV["ANTHROPIC_KEY"]

  DEFAULT_PARAMS = {
    model: "claude-2",
    max_tokens_to_sample: 2000,
    stream: false
  }.freeze

  def format_prompt(str)
    "\n\nHuman: #{str}\n\nAssistant:"
  end

  def completion_for_prompt(prompt, claude_params = {})
    result = request_completion(format_prompt(prompt), claude_params)
    result["completion"] || result
  end

  def request_completion(formatted_prompt, claude_params = {})
    response = connection.post("/v1/complete") do |req|
      req.body = DEFAULT_PARAMS.merge(claude_params)
        .merge(prompt: formatted_prompt).to_json
    end
    JSON.parse(response.body)
  end

  def connection
    @connection ||= Faraday.new(url: "https://api.anthropic.com/") do |conn|
      conn.headers["Content-Type"] = "application/json"
      conn.headers["anthropic-version"] = "2023-06-01"
      conn.headers["x-api-key"] = API_KEY
      conn.options.timeout = 180
      conn.adapter Faraday.default_adapter
    end
  end
end
