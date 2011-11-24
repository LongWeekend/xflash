require 'test_helper'

class ParseExceptionsControllerTest < ActionController::TestCase
  setup do
    @parse_exception = parse_exceptions(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:parse_exceptions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create parse_exception" do
    assert_difference('ParseException.count') do
      post :create, :parse_exception => @parse_exception.attributes
    end

    assert_redirected_to parse_exception_path(assigns(:parse_exception))
  end

  test "should show parse_exception" do
    get :show, :id => @parse_exception.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @parse_exception.to_param
    assert_response :success
  end

  test "should update parse_exception" do
    put :update, :id => @parse_exception.to_param, :parse_exception => @parse_exception.attributes
    assert_redirected_to parse_exception_path(assigns(:parse_exception))
  end

  test "should destroy parse_exception" do
    assert_difference('ParseException.count', -1) do
      delete :destroy, :id => @parse_exception.to_param
    end

    assert_redirected_to parse_exceptions_path
  end
end
