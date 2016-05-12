require 'fileutils'

namespace :rights do
   desc "Clear use rights table"
   task :clear  => :environment do
      ActiveRecord::Base.connection.execute("TRUNCATE TABLE use_rights")
   end

   desc "Populate use rights"
   task :populate  => :environment do
      UseRight.create([
         { :name => 'No Known Copyright' },
         { :name => 'In Copyright' },
         { :name => 'In Copyright Educational Use Permitted' },
         { :name => 'In Copyright Non-Commercial Use Permitted' },
         { :name => 'No Copyright' },
         { :name => 'No Copyright Non-Commercial Use Only' },
         { :name => 'No Copyright Contractual Restrictions' },
         { :name => 'No Copyright Other Known Legal Restrictions' },
         { :name => 'No Copyright United States' },
         { :name => 'All CC Licenses' }])
   end
end
