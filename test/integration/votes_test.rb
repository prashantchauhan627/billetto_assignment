require "test_helper"

class VotesTest < ActionDispatch::IntegrationTest
  setup {
    @event = create_event
  }

  test "a signed-out visitor cannot vote" do
    sign_out

    post event_votes_path(@event, direction: "up")

    assert_redirected_to root_path
    assert_equal "Please sign in to vote.", flash[:alert]
    assert_equal 0, votes_recorded, "a guest must not write to the event stream"
    assert_nil VoteCount.find_by(event_id: @event.id)
  end

  test "a signed-in user can vote" do
    sign_in_as "user_42"

    post event_votes_path(@event, direction: "up")

    assert_redirected_to root_path
    assert_equal 1, votes_recorded
    assert_equal 1, @event.reload.upvotes
  end

  test "the vote is recorded against the user who cast it" do
    sign_in_as "user_42"

    post event_votes_path(@event, direction: "down")

    recorded = event_store.read.stream(stream_name).first
    assert_equal "EventDownvoted", recorded.event_type
    assert_equal "user_42", recorded.data.symbolize_keys.fetch(:user_id)
  end

  test "signing out again blocks further voting" do
    sign_in_as "user_42"
    post event_votes_path(@event, direction: "up")

    sign_out
    post event_votes_path(@event, direction: "up")

    assert_redirected_to root_path
    assert_equal 1, votes_recorded, "only the signed-in vote should exist"
  end

  private

  def stream_name = "Event$#{@event.id}"
  def votes_recorded = event_store.read.stream(stream_name).count
end
