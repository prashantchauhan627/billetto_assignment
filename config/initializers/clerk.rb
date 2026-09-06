secret_key = Rails.application.credentials.dig(:clerk, :secret_key)
publishable_key = Rails.application.credentials.dig(:clerk, :publishable_key)

if secret_key.present? && publishable_key.present?
  Clerk.configure do |config|
    config.secret_key = secret_key
    config.publishable_key = publishable_key
  end

  # Not mounted in test: the middleware runs Clerk's dev handshake and would
  # 307-redirect every request to Clerk's API before it reached a controller.
  # Tests set the signed-in user directly instead (see test/test_helper.rb).
  Rails.application.config.middleware.use(Clerk::Rack::Middleware) unless Rails.env.test?
end
