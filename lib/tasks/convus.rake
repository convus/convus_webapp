desc "Update review topics, if their status is incorrect. Run on cron"
task update_review_topics: :environment do
  TopicReview.incorrect_status.each { |t| t.update(updated_at: Time.current) }
end
