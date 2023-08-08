require "test_helper"

class CreateHEntryJsonFormEncodedMultipartTest < ActionDispatch::IntegrationTest
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

  test "300: Create an h-entry with a photo" do
    form_data = {
      h: "entry",
      content: "Nice sunset tonight",
      photo: fixture_file_upload("baphomet.jpg", "image/jpeg")
    }

    post micropub_url, headers: @headers, params: form_data

    assert_response 201
    assert_includes response.headers, "Location"

    get response.headers["Location"]

    assert_select "div.h-entry"
    assert_select "time.dt-published"
    assert_select "div.e-content", "Nice sunset tonight"
    assert_select "img.u-photo[src*=\"baphomet.jpg\"]"
  end

  test "301: Create an h-entry with two photos" do
    form_data = {
      h: "entry",
      content: "Nice sunset tonight",
      photo: [
        fixture_file_upload("baphomet.jpg"),
        fixture_file_upload("cthulhu.jpeg")
      ]
    }

    post micropub_url, headers: @headers, params: form_data

    assert_response 201
    assert_includes response.headers, "Location"

    get response.headers["Location"]

    assert_select "div.h-entry"
    assert_select "time.dt-published"
    assert_select "div.e-content", "Nice sunset tonight"
    assert_select "img.u-photo[src*=\"baphomet.jpg\"]"
    assert_select "img.u-photo[src*=\"cthulhu.jpeg\"]"
  end
end
