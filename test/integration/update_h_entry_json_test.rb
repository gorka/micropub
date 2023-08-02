require "test_helper"

class UpdateHEntryJsonTest < ActionDispatch::IntegrationTest
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

    @headers = {
      "Authorization" => "Bearer XXX",
      "Content-Type" => "application/json"
    }
  end

  test "400: Replace a property" do
    json_data = {
      action: "update",
      url: entry_url(entries(:with_category)),
      replace: {
        content: [ "This is the updated text. If you can see this you passed the test!" ]
      }
    }.to_json

    post micropub_url, headers: @headers, params: json_data

    assert_response 204

    get response.headers["Location"]

    assert_select "div.e-content", "This is the updated text. If you can see this you passed the test!"
  end

  test "401: Add a value to an existing property" do
    json_data = {
      action: "update",
      url: entry_url(entries(:with_category)),
      add: {
        category: [ "test2" ]
      }
    }.to_json

    post micropub_url, headers: @headers, params: json_data

    assert_response 204

    get response.headers["Location"]

    assert_select ".p-category", 2
    assert_select ".p-category", "test2"
  end

  test "402: Add a value to a non-existent property" do
    json_data = {
      action: "update",
      url: entry_url(entries(:without_categories)),
      add: {
        category: ["test1"]
      }
    }.to_json

    post micropub_url, headers: @headers, params: json_data

    assert_response 204

    get response.headers["Location"]

    assert_select ".p-category", 1
    assert_select ".p-category", "test1"
  end

  test "403: Remove a value from a property" do
    json_data = {
      action: "update",
      url: entry_url(entries(:with_categories)),
      delete: {
        category: [ "test2" ]
      }
    }.to_json

    post micropub_url, headers: @headers, params: json_data

    assert_response 204

    get response.headers["Location"]

    assert_select ".p-category", 1
    assert_select ".p-category", "test1"
  end

  test "404: Remove a property" do
    json_data = {
      action: "update",
      url: entry_url(entries(:with_categories)),
      delete: [
        "category"
      ]
    }.to_json

    post micropub_url, headers: @headers, params: json_data

    assert_response 204

    get response.headers["Location"]

    assert_select ".p-category", 0
  end

  test "405: Reject the request if operation is not an array" do
    json_data = {
      action: "update",
      url: entry_url(entries(:with_categories)),
      replace: "This is not a valid update request."
    }.to_json

    post micropub_url, headers: @headers, params: json_data

    assert_response 400
  end
end
