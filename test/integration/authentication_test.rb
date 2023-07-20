require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  # Tests based on https://micropub.rocks/server-tests/

  setup do
    stub_request(:get, Rails.configuration.token_endpoint)
      .to_return(
        status: 200,
        body: {
          "me": Rails.configuration.url,
          "client_id": "https://micropublish.net",
          "scope": "post",
          "issued_at": 1399155608,
          "nonce": 501884823
        }.to_json
      )
  end

  test "800 accept access token in HTTP header" do
    headers = {
      "Authorization" => "Bearer XXX"
    }

    params = {
      h: "entry",
      content: "Testing accepting access token in HTTP Authorization header"
    }

    post micropub_url, headers: headers, params: params

    assert_response 201 || 202
    assert_includes response.headers, "Location"
  end

  test "801 accept access token in POST body" do
    params = {
      h: "entry",
      content: "Testing accepting access token in HTTP Authorization header",
      access_token: "xxx"
    }

    post micropub_url, params: params

    assert_response 201 || 202
    assert_includes response.headers, "Location"
  end

  test "803 rejects unauthenticated requests" do
    params = {
      h: "entry",
      content: "Testing accepting access token in HTTP Authorization header"
    }

    post micropub_url, headers: headers, params: params

    assert_response 401
  end

  test "804 rejects unauthorized access tokens" do
    stub_request(:get, Rails.configuration.token_endpoint)
      .to_return(
        status: 400,
        body: {
          error: "unauthorized",
          error_description: "The token provided was malformed"
        }.to_json
      )

    headers = {
      "Authorization" => "Bearer XXX"
    }

    params = {
      h: "entry",
      content: "Testing accepting access token in HTTP Authorization header"
    }

    post micropub_url, headers: headers, params: params

    assert_response 401
  end

  test "805 rejects multiple authentication methods" do
    headers = {
      "Authorization" => "Bearer XXX"
    }

    params = {
      h: "entry",
      content: "Testing accepting access token in HTTP Authorization header and POST body. This should not create a post",
      access_token: "XXX"
    }

    post micropub_url, headers: headers, params: params

    assert_response 400
  end
end
