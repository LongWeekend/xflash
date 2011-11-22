require 'test_helper'

class TagMatchingExceptionsControllerTest < ActionController::TestCase
  setup do
    @tag_matching_exception = tag_matching_exceptions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tag_matching_exceptions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tag_matching_exception" do
    assert_difference('TagMatchingException.count') do
      post :create, :tag_matching_exception => @tag_matching_exception.attributes
    end

    assert_redirected_to tag_matching_exception_path(assigns(:tag_matching_exception))
  end

  test "should show tag_matching_exception" do
    get :show, :id => @tag_matching_exception.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @tag_matching_exception.to_param
    assert_response :success
  end

  test "should update tag_matching_exception" do
    put :update, :id => @tag_matching_exception.to_param, :tag_matching_exception => @tag_matching_exception.attributes
    assert_redirected_to tag_matching_exception_path(assigns(:tag_matching_exception))
  end

  test "should destroy tag_matching_exception" do
    assert_difference('TagMatchingException.count', -1) do
      delete :destroy, :id => @tag_matching_exception.to_param
    end

    assert_redirected_to tag_matching_exceptions_path
  end
end
