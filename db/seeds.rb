# Seed accounts for development. Idempotent: running db:seed repeatedly changes nothing.
#
# The password can be overridden with SEED_PASSWORD. It must have at least 12 characters.

password = ENV.fetch("SEED_PASSWORD", "eventdesk2026!")

[
  { name: "Adrian Administrator", email_address: "admin@eventdesk.test", role: :admin },
  { name: "Olivia Organisatorin", email_address: "organisator@eventdesk.test", role: :organizer },
  { name: "Tim Teilnehmer",       email_address: "teilnehmer@eventdesk.test", role: :user }
].each do |attributes|
  user = User.find_or_initialize_by(email_address: attributes[:email_address])
  next if user.persisted?

  user.update!(attributes.merge(password: password, password_confirmation: password))
  puts "Created #{user.role}: #{user.email_address}"
end

# Concerts for the manual walkthrough, one per status. Idempotent as well: a title that already
# exists is left as it is, including whatever was registered for it.
organizer = User.find_by!(email_address: "organisator@eventdesk.test")
first_evening = 3.weeks.from_now.change(hour: 20, min: 0, sec: 0)

[
  {
    title: "Klavierabend im Kulturhaus",
    status: :draft,
    capacity: 40,
    starts_at: first_evening
  },
  {
    title: "Jazz Night",
    status: :published,
    capacity: 2,
    starts_at: first_evening + 1.week,
    description: "Ein Abend mit Standards und eigenen Stücken.",
    setlist: "Autumn Leaves\nBlue in Green\nSo What",
    playlist_url: "https://example.com/playlist/jazz-night"
  },
  {
    title: "Chorkonzert in der Stadtkirche",
    status: :cancelled,
    capacity: 120,
    starts_at: first_evening + 2.weeks,
    description: "Geistliche Chormusik aus vier Jahrhunderten.",
    setlist: "Ave verum corpus\nLocus iste"
  }
].each do |attributes|
  concert = Concert.find_or_initialize_by(title: attributes[:title])
  next if concert.persisted?

  concert.update!(attributes.merge(creator: organizer, ends_at: attributes[:starts_at] + 2.hours))
  puts "Created #{concert.status} concert: #{concert.title}"
end
