require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "requires a title and a start date" do
    event = Event.new(billetto_id: "1")

    assert_not event.valid?
    assert_includes event.errors[:title], "can't be blank"
    assert_includes event.errors[:starts_at], "can't be blank"
  end

  test "will not store the same Billetto event twice" do
    create_event(billetto_id: "dup")
    duplicate = Event.new(billetto_id: "dup", title: "Copy", starts_at: 1.day.from_now)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:billetto_id], "has already been taken"
  end

  test "reports zero votes before anybody has voted" do
    event = create_event

    assert_equal 0, event.upvotes
    assert_equal 0, event.downvotes
  end
end
