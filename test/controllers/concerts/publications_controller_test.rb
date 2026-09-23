require "test_helper"

class Concerts::PublicationsControllerTest < ActionDispatch::IntegrationTest
  test "an organizer publishes a complete draft" do
    concert = Concert.create!(concert_attributes(description: "Beschreibung", setlist: "Song"))
    sign_in_as users(:organizer)

    post concert_publication_path(concert)

    assert_redirected_to concert_url(concert)
    assert concert.reload.published?
  end

  test "publishing without a description or setlist is rejected on the edit screen" do
    concert = Concert.create!(concert_attributes)
    sign_in_as users(:organizer)

    post concert_publication_path(concert)

    assert_response :unprocessable_content
    assert_select ".form-errors__item"
    assert concert.reload.draft?
  end

  test "a participant may not publish" do
    concert = Concert.create!(concert_attributes(description: "Beschreibung", setlist: "Song"))
    sign_in_as users(:one)

    post concert_publication_path(concert)

    assert_redirected_to root_url
    assert_equal I18n.t("authorization.denied"), flash[:alert]
    assert concert.reload.draft?
  end
end
