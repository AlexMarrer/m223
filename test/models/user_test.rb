require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "downcases and strips unconfirmed_email" do
    user = User.new(unconfirmed_email: " NEW@EXAMPLE.COM ")
    assert_equal("new@example.com", user.unconfirmed_email)
  end

  test "is valid with name, email address and a long enough password" do
    assert build_user.valid?
  end

  test "requires a name" do
    user = build_user(name: "")
    assert_not user.valid?
    assert_includes user.errors.attribute_names, :name
  end

  test "requires a unique email address" do
    user = build_user(email_address: users(:one).email_address)
    assert_not user.valid?
    assert_includes user.errors.attribute_names, :email_address
  end

  test "compares email addresses after normalization" do
    user = build_user(email_address: " #{users(:one).email_address.upcase} ")
    assert_not user.valid?
  end

  test "enforces email uniqueness in the database" do
    assert_raises ActiveRecord::RecordNotUnique do
      User.insert!({
        name: "Doppelgaenger",
        email_address: users(:one).email_address,
        password_digest: "x",
        role: "user"
      })
    end
  end

  test "requires a password of at least 12 characters" do
    user = build_user(password: "kurz", password_confirmation: "kurz")
    assert_not user.valid?
    assert_includes user.errors.attribute_names, :password
  end

  test "allows saving without touching the password" do
    user = users(:one)
    user.name = "Neuer Name"
    assert user.valid?
  end

  test "never stores the password in plain text" do
    user = build_user
    user.save!
    assert_not_equal "passwort1234567", user.password_digest
    assert user.authenticate("passwort1234567")
  end

  test "defaults to role user" do
    assert_equal "user", build_user.role
    assert build_user.user?
  end

  test "supports all three roles" do
    assert_equal %w[user organizer admin], User.roles.keys
    assert users(:organizer).organizer?
    assert users(:admin).admin?
  end

  test "rejects an unsupported role" do
    user = build_user(role: "superuser")
    assert_not user.valid?
    assert_includes user.errors.attribute_names, :role
  end

  test "rejects an unsupported role in the database" do
    assert_raises ActiveRecord::StatementInvalid do
      User.insert!({
        name: "Rollenlos",
        email_address: "role@example.com",
        password_digest: "x",
        role: "superuser"
      })
    end
  end

  test "has created concerts, registrations and activities" do
    admin = users(:admin)
    concert = Concert.create!(concert_attributes(creator: admin))
    registration = Registration.create!(user: users(:one), concert: concert)
    activity = Activity.create!(actor: admin, concert: concert, action: "published")

    assert_includes admin.created_concerts, concert
    assert_includes users(:one).registrations, registration
    assert_includes users(:one).concerts, concert
    assert_includes admin.activities, activity
  end

  private
    def build_user(**attributes)
      User.new({
        name: "Neue Benutzerin",
        email_address: "neu@example.com",
        password: "passwort1234567",
        password_confirmation: "passwort1234567"
      }.merge(attributes))
    end
end
