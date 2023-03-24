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

ActiveRecord::Schema[7.0].define(version: 2023_03_23_185418) do
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

  create_table "review_topics", force: :cascade do |t|
    t.bigint "review_id"
    t.bigint "topic_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_id"], name: "index_review_topics_on_review_id"
    t.index ["topic_id"], name: "index_review_topics_on_topic_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "citation_id"
    t.text "submitted_url"
    t.text "citation_title"
    t.integer "agreement", default: 0
    t.integer "quality", default: 0
    t.boolean "changed_my_opinion", default: false, null: false
    t.boolean "significant_factual_error"
    t.text "error_quotes"
    t.text "topics_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "source"
    t.string "timezone"
    t.date "created_date"
    t.boolean "learned_something", default: false
    t.boolean "did_not_understand", default: false
    t.index ["citation_id"], name: "index_reviews_on_citation_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "topic_investigation_votes", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "topic_investigation_id"
    t.bigint "review_id"
    t.boolean "manual_rank", default: false
    t.integer "vote_score"
    t.boolean "recommended", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_id"], name: "index_topic_investigation_votes_on_review_id"
    t.index ["topic_investigation_id"], name: "index_topic_investigation_votes_on_topic_investigation_id"
    t.index ["user_id"], name: "index_topic_investigation_votes_on_user_id"
  end

  create_table "topic_investigations", force: :cascade do |t|
    t.bigint "topic_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.integer "status"
    t.string "topic_name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["topic_id"], name: "index_topic_investigations_on_topic_id"
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
