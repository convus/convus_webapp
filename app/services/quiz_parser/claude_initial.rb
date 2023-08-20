class QuizParser::ClaudeInitial
  PROMPT = (ENV["CLAUDE_INITIAL_PROMPT"] || "").freeze
end
