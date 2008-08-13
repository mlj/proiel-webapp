require File.dirname(__FILE__) + '/../test_helper'

class AnnouncementsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:announcements)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_announcement
    assert_difference('Announcement.count') do
      post :create, :announcement => { }
    end

    assert_redirected_to announcement_path(assigns(:announcement))
  end

  def test_should_show_announcement
    get :show, :id => 1
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => 1
    assert_response :success
  end

  def test_should_update_announcement
    put :update, :id => 1, :announcement => { }
    assert_redirected_to announcement_path(assigns(:announcement))
  end

  def test_should_destroy_announcement
    assert_difference('Announcement.count', -1) do
      delete :destroy, :id => 1
    end

    assert_redirected_to announcements_path
  end
end
