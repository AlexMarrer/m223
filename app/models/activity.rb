class Activity < ApplicationRecord
  belongs_to :actor, class_name: "User"
  belongs_to :concert

  # The action names are fixed in docs/datenmodell.md. Storno and Absage stay apart, as the
  # disambiguation in docs/spec/PROJECT.md requires — there is no bare "cancelled".
  enum :action, { registered: "registered", cancelled_registration: "cancelled_registration",
                  published: "published", updated: "updated",
                  cancelled_concert: "cancelled_concert" },
       validate: true

  # Old and new values of a changed concert: {"capacity" => {"old" => 100, "new" => 80}}.
  # The feed is the only reader, so JSON in the existing text column is enough.
  serialize :details, type: Hash, coder: JSON
end
