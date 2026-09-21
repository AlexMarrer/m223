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
