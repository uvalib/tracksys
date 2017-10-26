class MasterFileLocation < ApplicationRecord
   belongs_to :master_file
   belongs_to :location
end
