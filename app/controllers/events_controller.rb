class EventsController < ApplicationController
  def index
    @events = Event.upcoming.includes(:vote_count).limit(50)
  end
end
