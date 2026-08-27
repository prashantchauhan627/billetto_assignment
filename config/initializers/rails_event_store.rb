Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new(
    repository: RubyEventStore::ActiveRecord::EventRepository.new(serializer: JSON)
  )

  Rails.configuration.event_store.subscribe(
    UpdateVoteCount.new,
    to: [ EventUpvoted, EventDownvoted ]
  )
end
