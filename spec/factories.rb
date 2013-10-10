FactoryGirl.define do
  factory :user do
    name     "Superman"
    email    "contact@superman.info"
    password "12345678"
    password_confirmation "12345678"
  end
end