class MeetingRequest < ActiveRecord::Base
  has_many :tags, as: :tagable
  has_many :concepts, through: :tags
  validates :content, presence: true
  validates :title, presence: true, length: { maximum: 100 }
  validates :contact_info, presence: true
end