namespace :billetto do
  desc "Import public events from the Billetto API"
  task :import, [ :limit ] => :environment do |_task, args|
    limit = (args[:limit] || Billetto::Client::MAX_LIMIT).to_i
    result = Billetto::EventImporter.new.call(limit: limit)

    puts "created=#{result.created} updated=#{result.updated} skipped=#{result.skipped}"
  rescue Billetto::Client::Error => e
    abort("Import failed: #{e.message}")
  end
end

namespace :vote_counts do
  desc "Rebuild vote counts from the event store"
  task rebuild: :environment do
    VoteCount.delete_all
    subscriber = UpdateVoteCount.new
    count = 0

    Rails.configuration.event_store.read.each do |event|
      next unless event.is_a?(EventUpvoted) || event.is_a?(EventDownvoted)

      subscriber.call(event)
      count += 1
    end

    puts "rebuilt from #{count} vote events"
  end
end
