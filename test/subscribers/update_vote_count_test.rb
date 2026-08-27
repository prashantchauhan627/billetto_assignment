require "test_helper"

class UpdateVoteCountTest < ActiveSupport::TestCase
  setup { @event = create_event }

  test "publishing an upvote updates the count through the subscriber" do
    publish(EventUpvoted, "user_1")

    assert_equal 1, @event.reload.upvotes
  end

  test "counts each user once" do
    publish(EventUpvoted, "user_1")
    publish(EventUpvoted, "user_1")

    assert_equal 1, @event.reload.upvotes
  end

  test "changing a vote moves the count instead of adding to it" do
    publish(EventUpvoted, "user_1")
    publish(EventDownvoted, "user_1")

    assert_equal 0, @event.reload.upvotes
    assert_equal 1, @event.reload.downvotes
  end

  test "the votes are readable back from the stream" do
    publish(EventUpvoted, "user_1")
    publish(EventUpvoted, "user_2")

    assert_equal 2, event_store.read.stream("Event$#{@event.id}").count
  end

  test "counts rebuilt from the stream match the live ones" do
    publish(EventUpvoted, "user_1")
    publish(EventUpvoted, "user_2")
    publish(EventDownvoted, "user_1")

    live_up = @event.reload.upvotes
    live_down = @event.reload.downvotes

    # What `bin/rails vote_counts:rebuild` does: throw the read model away and
    # replay. Replayed events are deserialized, so this covers the path the
    # subscriber tests above never touch.
    VoteCount.delete_all
    subscriber = UpdateVoteCount.new
    event_store.read.each { |e| subscriber.call(e) }

    assert_equal live_up, @event.reload.upvotes
    assert_equal live_down, @event.reload.downvotes
    assert_equal 1, @event.reload.downvotes
  end

  private

  def publish(klass, user_id)
    event_store.publish(
      klass.new(data: { event_id: @event.id, user_id: user_id, voted_at: Time.current.iso8601 }),
      stream_name: "Event$#{@event.id}"
    )
  end
end
