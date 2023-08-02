require "test_helper"

class DeleteHEntryJsonTest < ActionDispatch::IntegrationTest
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

  test "501: Delete a post" do
    json_data = {
      action: "delete",
      url: entry_url(entries(:with_category))
    }.to_json

    assert_difference "Entry.count", -1 do
      post micropub_url, headers: @headers, params: json_data
    end
  end
end
