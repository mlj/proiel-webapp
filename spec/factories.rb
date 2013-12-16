FactoryGirl.define do
  factory :lemma do |f|
    f.lemma "sum"
    f.language_tag "lat"
    f.part_of_speech_tag "V-"
  end
end

FactoryGirl.define do
  factory :user do |f|
    f.login "donald"
    f.email "x@x.com"
    f.password "daisyduck"
    f.password_confirmation "daisyduck"
    f.first_name { Faker::Name.first_name }
    f.last_name { Faker::Name.last_name }
    f.role "reader"
    f.confirmed_at Time.now
  end

#  factory :confirmed_user, :parent => :user do
#    after_create { |user| user.confirm! }
#  end
end
