class Message < ApplicationRecord
  belongs_to :conversation

  ROLE_USER = "user"
  ROLE_ASSISTANT = "assistant"
  ROLES = [ROLE_USER, ROLE_ASSISTANT].freeze

  validates :role, inclusion: { in: ROLES }
  validates :content, presence: true, length: { maximum: 50_000 }

  scope :ordered, -> { order(:created_at, :id) }
end
