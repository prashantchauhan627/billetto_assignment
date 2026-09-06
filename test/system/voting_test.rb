require "application_system_test_case"

# Drives the real pages and buttons. Clerk's hosted sign-in lives on their
# domain and can't be driven reliably from a headless browser, so the session is
# stubbed at the controller boundary; everything below it is the real app.
class VotingTest < ApplicationSystemTestCase
  setup {
    @event = create_event(title: "Langbordkoncerter")
  }

  test "a signed-out visitor is offered sign-in and no vote buttons" do
    sign_out

    visit root_path

    assert_text "Langbordkoncerter"
    assert_link "Sign in"
    assert_no_button "Upvote"
    assert_no_button "Downvote"
  end

  test "a signed-in user can upvote and see the count change" do
    sign_in_as "user_42"

    visit root_path
    assert_text "0 up / 0 down"

    click_button "Upvote"

    assert_text "1 up / 0 down"
  end

  test "changing your mind moves the count instead of adding to it" do
    sign_in_as "user_42"

    visit root_path
    click_button "Upvote"
    assert_text "1 up / 0 down"

    click_button "Downvote"

    assert_text "0 up / 1 down"
  end

  test "a signed-in user sees their id and can sign out" do
    sign_in_as "user_42"

    visit root_path

    assert_text "Signed in as user_42"
    assert_link "Sign out"
  end
end
