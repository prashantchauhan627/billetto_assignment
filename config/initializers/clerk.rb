secret_key = Rails.application.credentials.dig(:clerk, :secret_key)
publishable_key = Rails.application.credentials.dig(:clerk, :publishable_key)

if secret_key.present? && publishable_key.present?
  Clerk.configure do |config|
    config.secret_key = secret_key
    config.publishable_key = publishable_key
  end

  Rails.application.config.middleware.use(Clerk::Rack::Middleware)
end
