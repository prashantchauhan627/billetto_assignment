require "test_helper"

# The sign-in and sign-out links are built from the Clerk base URL, so a missing
# or wrong value renders a relative path to a route that does not exist. The link
# still appears, which is why the system tests do not catch it: they assert the
# link's text, not where it points.
class ClerkAuthenticationTest < ActionDispatch::IntegrationTest
  test "the sign-in link points at the configured Clerk base url" do
    sign_out
    get root_path

    assert_equal "#{clerk_base_url}/sign-in", link_href("Sign in").split("?").first
  end

  test "the sign-out link points at the configured Clerk base url" do
    sign_in_as "user_42"
    get root_path

    assert_equal "#{clerk_base_url}/sign-out", link_href("Sign out").split("?").first
  end

  test "the links send the user back to the app afterwards" do
    sign_out
    get root_path

    assert_includes link_href("Sign in"), "redirect_url=#{CGI.escape(root_url)}"
  end

  private

  # Resolved through the app rather than re-read here, so this follows however
  # the concern sources the value.
  def clerk_base_url
    url = ApplicationController.new.clerk_base_url
    assert url.present?,
      "Set CLERK_BASE_URL, or clerk.clerk_base_url in credentials (see README)"
    url
  end

  def link_href(text)
    link = css_select("a").find { |a| a.text.strip == text }
    assert link, "expected a #{text.inspect} link on the page"

    href = link["href"]
    assert href.start_with?("https://"), "#{text.inspect} must be absolute, got #{href.inspect}"
    href
  end
end
