require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  def test_roles
    u = User.new :role => 'reader'
    assert  u.has_role?(:reader)
    assert !u.has_role?(:annotator)
    assert !u.has_role?(:reviewer)
    assert !u.has_role?(:administrator)

    u = User.new :role => 'annotator'
    assert  u.has_role?(:reader)
    assert  u.has_role?(:annotator)
    assert !u.has_role?(:reviewer)
    assert !u.has_role?(:administrator)

    u = User.new :role => 'reviewer'
    assert  u.has_role?(:reader)
    assert  u.has_role?(:annotator)
    assert  u.has_role?(:reviewer)
    assert !u.has_role?(:administrator)

    u = User.new :role => 'administrator'
    assert  u.has_role?(:reader)
    assert  u.has_role?(:annotator)
    assert  u.has_role?(:reviewer)
    assert  u.has_role?(:administrator)
  end
end
