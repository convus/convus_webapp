# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_05_01_163602) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "citation_topics", force: :cascade do |t|
    t.bigint "citation_id"
    t.bigint "topic_id"
    t.boolean "orphaned", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["citation_id"], name: "index_citation_topics_on_citation_id"
    t.index ["topic_id"], name: "index_citation_topics_on_topic_id"
  end

  create_table "citations", force: :cascade do |t|
    t.text "url"
    t.text "title"
    t.jsonb "url_components_json"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "publisher_id"
    t.text "authors"
    t.datetime "published_at"
    t.datetime "published_updated_at"
    t.integer "wordcount"
    t.text "description"
    t.text "canonical_url"
    t.index ["publisher_id"], name: "index_citations_on_publisher_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "user_id"
    t.string "target_type"
    t.bigint "target_id"
    t.integer "kind"
    t.date "created_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["target_type", "target_id"], name: "index_events_on_target"
    t.index ["user_id"], name: "index_events_on_user_id"
  end

  create_table "kudos_event_kinds", force: :cascade do |t|
    t.string "name"
    t.integer "period"
    t.integer "max_per_period"
    t.integer "total_kudos"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "kudos_events", force: :cascade do |t|
    t.bigint "event_id"
    t.bigint "user_id"
    t.bigint "kudos_event_kind_id"
    t.integer "potential_kudos"
    t.integer "total_kudos"
    t.date "created_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_kudos_events_on_event_id"
    t.index ["kudos_event_kind_id"], name: "index_kudos_events_on_kudos_event_kind_id"
    t.index ["user_id"], name: "index_kudos_events_on_user_id"
  end

  create_table "publishers", force: :cascade do |t|
    t.string "domain"
    t.string "name"
    t.boolean "remove_query", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "base_word_count"
  end

  create_table "rating_topics", force: :cascade do |t|
    t.bigint "rating_id"
    t.bigint "topic_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rating_id"], name: "index_rating_topics_on_rating_id"
    t.index ["topic_id"], name: "index_rating_topics_on_topic_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "citation_id"
    t.text "submitted_url"
    t.text "citation_title"
    t.integer "agreement", default: 0
    t.integer "quality", default: 0
    t.boolean "changed_opinion", default: false, null: false
    t.boolean "significant_factual_error"
    t.text "error_quotes"
    t.text "topics_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source"
    t.string "timezone"
    t.date "created_date"
    t.boolean "learned_something", default: false
    t.boolean "not_understood", default: false
    t.text "display_name"
    t.boolean "account_public", default: false
    t.jsonb "citation_metadata"
    t.boolean "not_finished", default: false
    t.datetime "metadata_at"
    t.index ["citation_id"], name: "index_ratings_on_citation_id"
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "topic_relations", force: :cascade do |t|
    t.bigint "parent_id"
    t.bigint "child_id"
    t.boolean "direct", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id"], name: "index_topic_relations_on_child_id"
    t.index ["parent_id"], name: "index_topic_relations_on_parent_id"
  end

  create_table "topic_review_citations", force: :cascade do |t|
    t.bigint "topic_review_id"
    t.bigint "citation_id"
    t.bigint "citation_topic_id"
    t.integer "vote_score"
    t.integer "vote_score_manual"
    t.integer "rank"
    t.string "display_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["citation_id"], name: "index_topic_review_citations_on_citation_id"
    t.index ["citation_topic_id"], name: "index_topic_review_citations_on_citation_topic_id"
    t.index ["topic_review_id"], name: "index_topic_review_citations_on_topic_review_id"
  end

  create_table "topic_review_votes", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "topic_review_id"
    t.bigint "rating_id"
    t.boolean "manual_score", default: false
    t.integer "vote_score"
    t.integer "rank"
    t.datetime "rating_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "topic_review_citation_id"
    t.index ["rating_id"], name: "index_topic_review_votes_on_rating_id"
    t.index ["topic_review_citation_id"], name: "index_topic_review_votes_on_topic_review_citation_id"
    t.index ["topic_review_id"], name: "index_topic_review_votes_on_topic_review_id"
    t.index ["user_id"], name: "index_topic_review_votes_on_user_id"
  end

  create_table "topic_reviews", force: :cascade do |t|
    t.bigint "topic_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer "status"
    t.string "topic_name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_topic_reviews_on_topic_id"
  end

  create_table "topics", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.boolean "orphaned", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "previous_slug"
  end

  create_table "user_followings", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "following_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "approved", default: false
    t.index ["following_id"], name: "index_user_followings_on_following_id"
    t.index ["user_id"], name: "index_user_followings_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "role"
    t.string "username"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "api_token"
    t.text "about"
    t.string "username_slug"
    t.integer "total_kudos"
    t.boolean "account_private", default: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

end
