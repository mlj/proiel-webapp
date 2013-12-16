FactoryGirl.define do
  factory :lemma do |f|
    f.lemma "sum"
    f.language_tag "lat"
    f.part_of_speech_tag "V-"
  end
end

FactoryGirl.define do
  factory :user do |f|
    f.login 'happylinguist'
    f.email 'happy@linguist.edu'
    f.password 'silly_password'
    f.password_confirmation 'silly_password'
    f.first_name 'Happy'
    f.last_name 'Linguist'
    f.role 'reader'
    f.confirmed_at Time.new("2014-01-01 08:00:00 +0000")
  end

#  factory :confirmed_user, :parent => :user do
#    after_create { |user| user.confirm! }
#  end
end
