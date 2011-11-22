require 'test_helper'

class TagMatchingResolutionsControllerTest < ActionController::TestCase
  setup do
    @tag_matching_resolution = tag_matching_resolutions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tag_matching_resolutions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tag_matching_resolution" do
    assert_difference('TagMatchingResolution.count') do
      post :create, :tag_matching_resolution => @tag_matching_resolution.attributes
    end

    assert_redirected_to tag_matching_resolution_path(assigns(:tag_matching_resolution))
  end

  test "should show tag_matching_resolution" do
    get :show, :id => @tag_matching_resolution.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @tag_matching_resolution.to_param
    assert_response :success
  end

  test "should update tag_matching_resolution" do
    put :update, :id => @tag_matching_resolution.to_param, :tag_matching_resolution => @tag_matching_resolution.attributes
    assert_redirected_to tag_matching_resolution_path(assigns(:tag_matching_resolution))
  end

  test "should destroy tag_matching_resolution" do
    assert_difference('TagMatchingResolution.count', -1) do
      delete :destroy, :id => @tag_matching_resolution.to_param
    end

    assert_redirected_to tag_matching_resolutions_path
  end
end
