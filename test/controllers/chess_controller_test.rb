require "test_helper"

class ChessControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get chess_show_url
    assert_response :success
  end
end
