class KbViewing < ApplicationRecord
  self.table_name = 'viewings'
  belongs_to :viewed, polymorphic: true
  belongs_to :viewer, class_name: 'User', optional: true
end
