module Billetto
  class EventImporter
    Result = Struct.new(:created, :updated, :skipped)

    def initialize(client: Billetto::Client.new)
      @client = client
    end

    def call(limit: Billetto::Client::MAX_LIMIT)
      result = Result.new(0, 0, 0)

      @client.public_events(limit: limit).each do |payload|
        import(payload, result)
      end

      Rails.logger.info("[billetto] created=#{result.created} updated=#{result.updated} skipped=#{result.skipped}")
      result
    end

    private

    def import(payload, result)
      attributes = attributes_from(payload)
      event = Event.find_or_initialize_by(billetto_id: attributes[:billetto_id])
      was_new = event.new_record?

      event.assign_attributes(attributes)

      unless event.save
        Rails.logger.warn("[billetto] skipped #{attributes[:billetto_id]}: #{event.errors.full_messages.to_sentence}")
        return result.skipped += 1
      end

      was_new ? result.created += 1 : result.updated += 1
    end

    def attributes_from(payload)
      organiser = payload["organiser"] || payload["organizer"] || {}
      category = payload["categorization"] || payload["categorisation"] || {}

      {
        billetto_id: payload["id"].to_s,
        title: payload["title"],
        description: payload["description"],
        url: payload["url"],
        image_url: payload["image_link"],
        starts_at: parse_time(payload["startdate"]),
        ends_at: parse_time(payload["enddate"]),
        city: payload.dig("location", "city"),
        organiser_name: organiser["name"],
        category: category["category"]
      }
    end

    def parse_time(value)
      Time.zone.parse(value.to_s)
    end
  end
end
