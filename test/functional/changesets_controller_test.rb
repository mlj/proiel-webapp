require File.dirname(__FILE__) + '/../test_helper'

class ChangesetsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:changesets)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_changeset
    assert_difference('Changeset.count') do
      post :create, :changeset => { }
    end

    assert_redirected_to changeset_path(assigns(:changeset))
  end

  def test_should_show_changeset
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_changeset
    put :update, :id => 1, :changeset => { }
    assert_redirected_to changeset_path(assigns(:changeset))
  end

  def test_should_destroy_changeset
    assert_difference('Changeset.count', -1) do
      delete :destroy, :id => 1
    end

    assert_redirected_to changesets_path
  end
end
