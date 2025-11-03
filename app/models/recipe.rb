class Recipe < ApplicationRecord
  belongs_to :user
  has_rich_text :instructions

  validates :title, presence: true, uniqueness: true
end
