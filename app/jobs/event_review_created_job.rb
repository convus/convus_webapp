# Using activejob is slow, use sidekiq
class ApplicationJob
  include Sidekiq::Worker
  sidekiq_options queue: "default"
  sidekiq_options backtrace: true
end
