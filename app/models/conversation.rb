class Conversation < ApplicationRecord
  belongs_to :user
  has_many :messages, dependent: :destroy, inverse_of: :conversation

  scope :ordered, -> { order(updated_at: :desc) }

  validates :title, presence: true, length: { maximum: 200 }

  def title_or_default
    title.presence || "New chat"
  end
end
