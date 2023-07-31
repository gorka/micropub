require "test_helper"

class CreateHEntryJsonTest < ActionDispatch::IntegrationTest
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

  test "200: Create an h-entry post (JSON)" do
    headers = {
      "Authorization" => "Bearer XXX",
      "Content-Type" => "application/json"
    }

    json_data = {
      type: [ "h-entry" ],
      properties: {
        content: [ "Micropub test of creating an h-entry with a JSON request" ]
      }
    }.to_json

    post micropub_url, headers: headers, params: json_data

    assert_response 201 || 202
    assert_includes response.headers, "Location"

    get response.headers["Location"]

    assert_select "div.h-entry"
    assert_select "time.dt-published"
    assert_select "div.e-content", "Micropub test of creating an h-entry with a JSON request"
  end

  test "201: Create an h-entry post with multiple categories (JSON)" do
    headers = {
      "Authorization" => "Bearer XXX",
      "Content-Type" => "application/json"
    }
    
    json_data = {
      type: [ "h-entry" ],
      properties: {
        content: [ "Micropub test of creating an h-entry with a JSON request containing multiple categories. This post should have two categories, test1 and test2." ],
        category: [ "test1", "test2" ]
      }
    }.to_json

    post micropub_url, headers: headers, params: json_data

    assert_response 201 || 202
    assert_includes response.headers, "Location"

    get response.headers["Location"]

    assert_select "div.h-entry"
    assert_select "time.dt-published"
    assert_select "div.e-content", "Micropub test of creating an h-entry with a JSON request containing multiple categories. This post should have two categories, test1 and test2."
    assert_select ".p-category", "test1"
    assert_select ".p-category", "test2"
  end

  test "202: Create an h-entry with HTML content (JSON)" do
    headers = {
      "Authorization" => "Bearer XXX",
      "Content-Type" => "application/json"
    }

    json_data = {
      type: [ "h-entry" ],
      properties: {
        content: [{
          html: "<p>This post has <b>bold</b> and <i>italic</i> text.</p>"
        }]
      }
    }.to_json

    post micropub_url, headers: headers, params: json_data

    assert_response 201 || 202
    assert_includes response.headers, "Location"

    get response.headers["Location"]

    assert_select "div.h-entry"
    assert_select "time.dt-published"
    assert_select "div.e-content", "This post has bold and italic text."
  end

  test "203: Create an h-entry with a photo referenced by URL (JSON)" do
    headers = {
      "Authorization" => "Bearer XXX",
      "Content-Type" => "application/json"
    }

    json_data = {
      type: [ "h-entry" ],
      properties: {
        content: [ "Micropub test of creating a photo referenced by URL. This post should include a photo of a sunset." ],
        photo: [ "https://micropub.rocks/media/sunset.jpg" ]
      }
    }.to_json

    post micropub_url, headers: headers, params: json_data

    assert_response 201 || 202
    assert_includes response.headers, "Location"

    get response.headers["Location"]

    assert_select "div.h-entry"
    assert_select "time.dt-published"
    assert_select "div.e-content", "Micropub test of creating a photo referenced by URL. This post should include a photo of a sunset."
    assert_select "img.u-photo[src=\"https://micropub.rocks/media/sunset.jpg\"]"
  end

  test "204: Create an h-entry post with a nested object (JSON)" do
    skip "unsupported"
  end

  test "205: Create an h-entry post with a photo with alt text (JSON)" do
    headers = {
      "Authorization" => "Bearer XXX",
      "Content-Type" => "application/json"
    }

    json_data = {
      type: [ "h-entry" ],
      properties: {
        content: [ "Micropub test of creating a photo referenced by URL with alt text. This post should include a photo of a sunset." ],
        photo: [
          {
            value: "https://micropub.rocks/media/sunset.jpg",
            alt: "Photo of a sunset"
          }
        ]
      }
    }.to_json

    post micropub_url, headers: headers, params: json_data

    assert_response 201 || 202
    assert_includes response.headers, "Location"

    get response.headers["Location"]

    assert_select "div.h-entry"
    assert_select "time.dt-published"
    assert_select "div.e-content", "Micropub test of creating a photo referenced by URL with alt text. This post should include a photo of a sunset."
    assert_select "img.u-photo[src=\"https://micropub.rocks/media/sunset.jpg\"][alt=\"Photo of a sunset\"]"
  end

  test "206: Create an h-entry with multiple photos referenced by URL (JSON)" do
    headers = {
      "Authorization" => "Bearer XXX",
      "Content-Type" => "application/json"
    }

    json_data = {
      type: [ "h-entry" ],
      properties: {
        content: [ "Micropub test of creating multiple photos referenced by URL. This post should include a photo of a city at night." ],
        photo: [
          "https://micropub.rocks/media/sunset.jpg",
          "https://micropub.rocks/media/city-at-night.jpg"
        ]
      }
    }.to_json

    post micropub_url, headers: headers, params: json_data

    assert_response 201 || 202
    assert_includes response.headers, "Location"

    get response.headers["Location"]

    assert_select "div.h-entry"
    assert_select "time.dt-published"
    assert_select "div.e-content", "Micropub test of creating multiple photos referenced by URL. This post should include a photo of a city at night."
    assert_select "img.u-photo[src=\"https://micropub.rocks/media/sunset.jpg\"]", 1
    assert_select "img.u-photo[src=\"https://micropub.rocks/media/city-at-night.jpg\"]", 1
  end
end
