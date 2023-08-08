require "test_helper"

class QueryTest < ActionDispatch::IntegrationTest
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

  test "600: Configuration Query" do
    form_data = {
      q: "config"
    }

    get micropub_url, headers: @headers, params: form_data

    assert_response 200
  end

  test "601: Syndication Endpoint Query" do
    form_data = {
      q: "syndicate-to"
    }

    get micropub_url, headers: @headers, params: form_data

    assert_response 200

    expected_response = {
      "syndicate-to" => []
    }
    assert_equal expected_response, JSON.parse(response.body)
  end

  test "602: Source Query (All Properties)" do
    form_data = {
      q: "source",
      url: entry_url(entries(:with_categories))
    }

    get micropub_url, headers: @headers, params: form_data

    assert_response 200

    expected_response = {
      "type" => [ "h-entry" ],
      "properties" => {
        "content" => [ "This is the content" ],
        "category" => [ "test1", "test2" ],
        "photo" => []
      }
    }
    assert_equal expected_response, JSON.parse(response.body)
  end

  test "603: Source Query (Specific Properties)" do
    form_data = {
      q: "source",
      properties: [ "content", "category" ],
      url: entry_url(entries(:with_categories))
    }

    get micropub_url, headers: @headers, params: form_data

    assert_response 200
    
    expected_response = {
      "properties" => {
        "content" => [ "This is the content" ],
        "category" => [ "test1", "test2" ]
      }
    }
    assert_equal expected_response, JSON.parse(response.body)
  end
end
