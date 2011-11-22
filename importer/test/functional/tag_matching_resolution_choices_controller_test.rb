require 'test_helper'

class TagMatchingResolutionChoicesControllerTest < ActionController::TestCase
  setup do
    @tag_matching_resolution_choice = tag_matching_resolution_choices(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tag_matching_resolution_choices)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tag_matching_resolution_choice" do
    assert_difference('TagMatchingResolutionChoice.count') do
      post :create, :tag_matching_resolution_choice => @tag_matching_resolution_choice.attributes
    end

    assert_redirected_to tag_matching_resolution_choice_path(assigns(:tag_matching_resolution_choice))
  end

  test "should show tag_matching_resolution_choice" do
    get :show, :id => @tag_matching_resolution_choice.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @tag_matching_resolution_choice.to_param
    assert_response :success
  end

  test "should update tag_matching_resolution_choice" do
    put :update, :id => @tag_matching_resolution_choice.to_param, :tag_matching_resolution_choice => @tag_matching_resolution_choice.attributes
    assert_redirected_to tag_matching_resolution_choice_path(assigns(:tag_matching_resolution_choice))
  end

  test "should destroy tag_matching_resolution_choice" do
    assert_difference('TagMatchingResolutionChoice.count', -1) do
      delete :destroy, :id => @tag_matching_resolution_choice.to_param
    end

    assert_redirected_to tag_matching_resolution_choices_path
  end
end
