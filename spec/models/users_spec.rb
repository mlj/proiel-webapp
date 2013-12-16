require "spec_helper"

describe User do
  it "has a valid factory" do
    FactoryGirl.create(:user).should be_valid
  end

  it "is invalid without login" do
    FactoryGirl.build(:user, login: nil).should_not be_valid
  end

  it "is invalid without email" do
    FactoryGirl.build(:user, email: nil).should_not be_valid
  end

  it "is invalid without first name or last name" do
    FactoryGirl.build(:user, first_name: nil).should_not be_valid
    FactoryGirl.build(:user, last_name: nil).should_not be_valid
  end

  it "has one or more roles" do
    u = FactoryGirl.create(:user, role: 'reader')
    u.has_role?(:reader).should be_true
    u.has_role?(:annotator).should be_false
    u.has_role?(:reviewer).should be_false
    u.has_role?(:administrator).should be_false

    u.update_attributes!(role: 'annotator')
    u.has_role?(:reader).should be_true
    u.has_role?(:annotator).should be_true
    u.has_role?(:reviewer).should be_false
    u.has_role?(:administrator).should be_false

    u.update_attributes!(role: 'reviewer')
    u.has_role?(:reader).should be_true
    u.has_role?(:annotator).should be_true
    u.has_role?(:reviewer).should be_true
    u.has_role?(:administrator).should be_false

    u.update_attributes!(role: 'administrator')
    u.has_role?(:reader).should be_true
    u.has_role?(:annotator).should be_true
    u.has_role?(:reviewer).should be_true
    u.has_role?(:administrator).should be_true
  end
end
