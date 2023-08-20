FactoryBot.define do
  factory :quiz do
    citation { FactoryBot.create(:citation) }
    kind { :citation_quiz }
    source { :admin_entry }
  end
end
