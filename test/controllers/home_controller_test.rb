require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "show renders for an authenticated user" do
    user = users(:one)
    sign_in_as(user)

    get root_path

    assert_response :success
    assert_select "h1", /#{user.name}/
  end

  test "show redirects an unauthenticated visitor to the login screen" do
    get root_path

    assert_redirected_to new_session_path
  end

  test "login after a rejected request returns to the requested page" do
    get root_path
    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:one).email_address, password: "password123456" }

    assert_redirected_to root_url
  end
end
