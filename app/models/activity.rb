class Activity < ApplicationRecord
  belongs_to :actor, class_name: "User"
  belongs_to :concert

  validates :action, presence: true
end
