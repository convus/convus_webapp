desc "Update review topics, if their status is incorrect. Run on cron"
task update_review_topics: :environment do
  TopicReview.update_incorrect_statuses!
end
