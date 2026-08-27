class ApplicationController < ActionController::Base
  include ClerkAuthentication
  before_action :strip_clerk_handshake

  allow_browser versions: :modern

  private

  def strip_clerk_handshake
    return if params[:__clerk_handshake].blank?
    redirect_to url_for(request.query_parameters.except("__clerk_handshake").merge(only_path: true))
  end
end
