require 'test_helper'

class MonitoredResourcesControllerTest < ActionController::TestCase
  test "should get list" do
    get :list
    assert_response :success
  end

  test "should get new" do
    get :new
    assert_response :success
  end

end
