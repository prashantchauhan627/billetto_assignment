require "test_helper"

module Billetto
  class EventImporterTest < ActiveSupport::TestCase
    URL = "https://billetto.dk/api/v3/public/events"

    setup do
      stub_request(:get, URL)
        .with(query: hash_including({}))
        .to_return(
          status: 200,
          body: file_fixture("public_events.json").read,
          headers: { "Content-Type" => "application/json" }
        )

      @importer = Billetto::EventImporter.new(client: Billetto::Client.new(api_key: "k", api_secret: "s"))
    end

    test "imports events and skips the invalid one" do
      result = @importer.call

      assert_equal 2, result.created
      assert_equal 1, result.skipped
      assert_equal 2, Event.count
    end

    test "maps the payload onto the model" do
      @importer.call
      event = Event.find_by!(billetto_id: "1985162")

      assert_equal "Comedy Værkstedet", event.title
      assert_equal "Aarhus C", event.city
      assert_equal "Aarhus Comedy Club", event.organiser_name
      assert_equal "performing_arts", event.category
    end

    # Running the import twice must not duplicate anything, which is what makes
    # it safe to schedule.
    test "re-running updates instead of duplicating" do
      @importer.call
      result = @importer.call

      assert_equal 0, result.created
      assert_equal 2, result.updated
      assert_equal 2, Event.count
    end

    test "raises our own error when the API fails" do
      stub_request(:get, URL).with(query: hash_including({})).to_return(status: 401, body: "{}")

      assert_raises(Billetto::Client::RequestFailed) { @importer.call }
    end
  end
end
