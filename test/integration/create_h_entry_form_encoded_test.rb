require "test_helper"

class CreateHEntryJsonFormEncodedTest < ActionDispatch::IntegrationTest
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
      "Authorization" => "Bearer XXX"
    }
  end

  test "100: Create an h-entry post" do
    form_data = "h=entry&content=Micropub+test+of+creating+a+basic+h-entry"

    post micropub_url, headers: @headers, params: form_data

    assert_response 201
    assert_includes response.headers, "Location"

    get response.headers["Location"]

    assert_select "div.h-entry"
    assert_select "time.dt-published"
    assert_select "div.e-content", "Micropub test of creating a basic h-entry"
  end
end
