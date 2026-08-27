class VotesController < ApplicationController
  before_action :require_login!

  def create
    event = Event.find(params[:event_id])
    action = action_class.new(data: { event_id: event.id, user_id: current_user_id, voted_at: Time.current.iso8601 })

    Rails.configuration.event_store.publish(action, stream_name: "Event$#{event.id}")

    redirect_to root_path, notice: "Thanks for voting."
  end

  private

  def action_class
    params[:direction] == "down" ? EventDownvoted : EventUpvoted
  end
end
