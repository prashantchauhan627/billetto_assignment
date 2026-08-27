class UpdateVoteCount
  def call(event)
    data = event.data.symbolize_keys
    event_id = data.fetch(:event_id)
    user_id = data.fetch(:user_id)
    direction = event.is_a?(EventUpvoted) ? "up" : "down"

    ApplicationRecord.transaction do
      counter = VoteCount.lock.find_or_create_by!(event_id: event_id)
      previous = counter.votes_by_user[user_id]

      return if previous == direction

      counter.upvotes -= 1 if previous == "up"
      counter.downvotes -= 1 if previous == "down"
      counter.upvotes += 1 if direction == "up"
      counter.downvotes += 1 if direction == "down"

      counter.votes_by_user = counter.votes_by_user.merge(user_id => direction)
      counter.save!
    end
  end
end
