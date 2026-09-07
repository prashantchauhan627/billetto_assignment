# Clerk's Rack middleware verifies the session and leaves a proxy in the Rack
# env, so this only has to read the user id off it.
module ClerkAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user_id, :signed_in?, :clerk_sign_in_url, :clerk_sign_out_url
  end

  def current_user_id
    @current_user_id ||= request.env["clerk"]&.user_id
  end

  def signed_in?
    current_user_id.present?
  end

  def require_login!
    redirect_to root_path, alert: "Please sign in to vote." unless signed_in?
  end

  def clerk_base_url
    ENV.fetch("CLERK_BASE_URL") { Rails.application.credentials.dig(:clerk, :clerk_base_url) }
  end

  def clerk_sign_in_url  = "#{clerk_base_url}/sign-in?redirect_url=#{CGI.escape(root_url)}"
  def clerk_sign_out_url = "#{clerk_base_url}/sign-out?redirect_url=#{CGI.escape(root_url)}"
end
