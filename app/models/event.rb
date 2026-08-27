class Event < ApplicationRecord
  has_one :vote_count, dependent: :destroy

  validates :billetto_id, presence: true, uniqueness: true
  validates :title, presence: true
  validates :starts_at, presence: true

  scope :upcoming, -> { where("starts_at >= ?", Time.current).order(:starts_at) }

  def upvotes
    vote_count&.upvotes.to_i
  end

  def downvotes
    vote_count&.downvotes.to_i
  end
end
