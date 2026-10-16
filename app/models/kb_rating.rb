class KbRating < ApplicationRecord
  self.table_name = 'ratings'
  belongs_to :rated, polymorphic: true
  validates :rating, inclusion: {in: 1..5}, numericality: {only_integer: true}
end
