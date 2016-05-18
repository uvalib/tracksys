require 'fileutils'

namespace :rights do

   desc "initialize all bibls to CNE"
   task :init_cne  => :environment do
      cne = UseRight.find_by(name: "Copyright Not Evaluated")
      puts "Update all bibls with no right statement to #{cne.name}..."
      ActiveRecord::Base.connection.execute("update bibls set use_right_id=#{cne.id} where use_right_id is null")
      puts "DONE"
   end

   desc "Mark all pre-1923 content as NKC"
   task :nkc  => :environment do
      # tests = ['192-?','17--?','1871.0', 'between 1984 and 2005], c1984', '1937 or 1938','12 July 1493',
      #          '1867-1873', 'c1991', 'MDCCXX','M. DC. LXXIV. [1674] Avec privilege du Roy',
      #          ' 23 x 32 cm. on sheet 29 x 33 cm', 'Febry. 13th, 1755','1845-52','1892-']
      # tests.each do |raw_year|
      nkc = UseRight.find_by(name: "No Known Copyright")

      # for all bibl with no year, pull the MARC and look at field 260
      Bibl.where.not(year: nil).find_each do |bibl|
         # check MARC record
      end

      # check bibls with year data
      Bibl.where.not(year: nil).find_each do |bibl|
         puts "====> Raw [#{bibl.year}]"
         year = bibl.year.strip

         # first... see if rails can parse it
         begin
            # convert to date obj, then to year-only string.
            # make sure the resultant year is contained in the original string
            test = year.to_date.strftime("%Y")
            raise "Invalid" if year.index(test).nil?
            year = test
         rescue Exception=>e
            # if rails cant parse, it will raise an exception
            # next, look for stuff like 1871.0
            if !year.match(/^\d{4}.0/).nil?
               year = year.split(".")[0]
            else
               if !year.match(/^\d{2}--/).nil?
                  # only century know
                  year = "#{year[0...2]}99"
               elsif !year.match(/^\d{3}-/).nil?
                  # only decade known
                  year = "#{year[0...3]}9"
               elsif !year.match(/^\d{4}\s*-\s*\d{4}/).nil?
                  # range of years separated by dash
                  year = year.split("-")[1].strip
               elsif !year.match(/^\d{4}\s*-\s*\d{2}/).nil?
                  # range of years separated by dash; only 2 digits listed after dash
                  bits = year.split("-")
                  year = "#{bits[0].strip[0...2]}#{bits[1].strip}"
               else
                  # mess. just strip out non-number/non-space and see if anything looks like a year
                  year = year.gsub(/[^0-9 ]/i, '').gsub(/\s+/, ' ')
                  latest = 0
                  year.split(" ").each do |bit|
                     bit.strip!
                     if bit.length == 4
                        latest = bit.to_i if bit.to_i > latest
                     end
                  end
                  year = ""
                  year = latest.to_s if latest > 0
               end
            end
         end

         if !year.blank?
            if year.to_i < 1923
               puts "*** NKC"
               bibl.update_attribute(:use_right_id, nkc.id)
            end
         else
            puts "Unable to identify year"
            #bibl = Virgo.external_lookup(params[:catalog_key], params[:barcode])
         end
      end
   end

   desc "Populate use rights"
   task :populate  => :environment do
      UseRight.create([
         { :name => 'Copyright Not Evaluated' },
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
