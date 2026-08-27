ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

WebMock.disable_net_connect!(allow_localhost: true)

class ActiveSupport::TestCase
  parallelize(workers: 1)

  def event_store
    Rails.configuration.event_store
  end

  def create_event(**overrides)
    Event.create!(
      {
        billetto_id: SecureRandom.hex(4),
        title: "Comedy Værkstedet",
        starts_at: 2.weeks.from_now
      }.merge(overrides)
    )
  end
end
