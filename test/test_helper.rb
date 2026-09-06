ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

WebMock.disable_net_connect!(allow_localhost: true)

# Clerk's middleware is not mounted in test (see config/initializers/clerk.rb),
# so this stands in for the proxy it would otherwise leave in request.env.
# Tests exercise the real controllers, views and buttons; only the identity
# Clerk hands us is stubbed.
module ClerkAuthSession
  mattr_accessor :user_id, default: nil

  def current_user_id
    ClerkAuthSession.user_id
  end
end
ApplicationController.prepend(ClerkAuthSession)

class ActiveSupport::TestCase
  parallelize(workers: 1)
  teardown { ClerkAuthSession.user_id = nil }

  def sign_in_as(user_id) = ClerkAuthSession.user_id = user_id
  def sign_out = ClerkAuthSession.user_id = nil

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
