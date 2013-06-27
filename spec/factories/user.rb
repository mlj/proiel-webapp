FactoryGirl.define do
  factory :user do |f|
    f.login "donald"
    f.email "x@x.com"
    f.password "daisyduck"
    f.password_confirmation "daisyduck"
    f.last_name "Duck"
    f.first_name "Donald"
    f.role "reader"
    f.confirmed_at Time.now
  end

#  factory :confirmed_user, :parent => :user do
#    after_create { |user| user.confirm! }
#  end
end
