class SirsiMetadata < Metadata
   include Publishable

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   has_and_belongs_to_many :components, join_table: :sirsi_metadata_components

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates :use_right, presence: true
   validates :desc_metadata, presence: false
   validates :external_system, presence: false
   validates :external_uri, presence: false
   validates :title, presence: true
   validates :creator_death_date, inclusion: { in: 1200..Date.today.year,
      :message => 'must be a 4 digit year.', allow_blank: true
   }

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------
   before_save do
      if self.availability_policy_id.blank?
         pub_info = Virgo.get_marc_publication_info(self.catalog_key)
         if !pub_info[:year].blank? && pub_info[:year].to_i < 1923
            self.availability_policy_id = 1 # PUBLIC
         end
      end
      self.is_personal_item = false if self.is_personal_item.blank?
   end

   before_destroy :destroyable?
   def destroyable?
      if self.components.size > 0
         errors[:base] << "cannot delete Sirsi metadata that is associated with components"
         return false
      end
      return true
   end

   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------

   def get_full_metadata
      begin
         return Virgo.external_lookup(self.catalog_key, self.barcode)
      rescue Exception => e
         Rails.logger.error("Unable to retrieve external metadata: #{e.to_s}")
         return nil
      end
   end

   def location
      virgo_meta = self.get_full_metadata
      if virgo_meta.nil?
         return "Data is unavaileble; metadata record may be invalid"
      end
      return virgo_meta[:location]
   end

   def url_fragment
      return "sirsi_metadata"
   end

   # Although many Bibl records have citations provided through the MARC record, many do not
   # (especially those which lack a MARC record or are otherwise not cataloged in VIRGO).  As
   # a result, this method will impose some general order on the act of creating citations where
   # needed and rely upon the canonical citation when present.
   def get_citation
      sirsi_meta =  Virgo.external_lookup(self.catalog_key, self.barcode)
      if sirsi_meta[:citation]
         return sirsi_meta[:citation]
      else
         citation = ""
         citation << "#{self.title.gsub(/.\z/, '')}.  " if self.title
         citation << "#{self.call_number}.  " if self.call_number
         if sirsi_meta[:location]
            begin
               citation << "#{LOCATION_HASH.fetch(sirsi_meta[:location])}"
            rescue
               citation << "Special Collections, University of Virginia, Charlottesville, VA"
            end
         else
            citation << "Special Collections, University of Virginia, Charlottesville, VA"
         end
         return citation
      end
   end

   # Create and manage a Hash that contains the SIRSI location codes and their human readable values for citation purposes
   LOCATION_HASH = {
      "ALD-STKS" => "Alderman Library, University of Virginia, Charlottesville, VA.",
      "ASTRO-STKS" => "Astronomy Library, University of Virginia, Charlottesville, VA.",
      "BARR-STKS" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "CABELJR" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
      "DEC-IND-RM" => "Albert H. Small Declaration of Independence Collection, Special Collections, University of Virginia, Charlottesville, VA.",
      "FA-FOLIO" => "Fiske Kimball Fine Arts Library, University of Virginia, Charlottesville, VA.",
      "FA-OVERSIZE" => "Fiske Kimball Fine Arts Library, University of Virginia, Charlottesville, VA.",
      "FA-STKS" => "Fiske Kimball Fine Arts Library, University of Virginia, Charlottesville, VA.",
      "GEOSTAT" => "Alderman Library, University of Virginia, Charlottesville, VA.",
      "HS-CABELJR" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
      "HS-RAREOVS" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
      "HS-RARESHL" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
      "HS-RAREVLT" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
      "IVY-BOOK" => "Ivy Annex, University of Virginia, Charlottesville, VA.",
      "IVY-STKS" => "Ivy Annex, University of Virginia, Charlottesville, VA.",
      "IVYANNEX" => "Ivy Annex, University of Virginia, Charlottesville, VA." ,
      "LAW-IVY" => "Law Library, University of Virginia, Charlottesville, VA.",
      "MCGR-VLTFF" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
      "RAREOVS" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
      "RARESHL" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
      "RAREVLT" => "Health Sciences Library, University of Virginia, Charlottesville, VA.",
      "SC-ARCHV" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-ARCHV-X" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-BARR-F" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-BARR-FF" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-BARR-M" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-BARR-RM" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-BARR-ST" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-BARR-X" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-BARR-XF" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-BARR-XZ" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-BARRXFF" => "Clifton Waller Barrett Library of American Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-GARN-F" => "Garnett Family Library, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-GARN-RM" => "Garnett Family Library, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-IVY" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-MCGR-F" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-MCGR-FF" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-MCGR-RM" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-MCGR-ST" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-MCGR-X" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-MCGR-XF" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-MCGR-XZ" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-MCGRXFF" => "Tracy W. McGregor Library of American History, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-REF" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-REF-F" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-SCOTT" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-SCOTT-F" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-SCOTT-M" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-SCOTT-X" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-SCOTTFF" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-SCOTTXF" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-SCOTTXZ" => "Marion duPont Scott Sporting Collection, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-STKS" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-STKS-D" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-STKS-EF" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-STKS-F" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-STKS-FF" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-STKS-M" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-STKS-X" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-STKS-XF" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-STKS-XZ" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-STKSXFF" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-TATUM" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-TATUM-F" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-TATUM-M" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-TATUM-X" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-TATUMFF" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-TATUMXF" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SC-TATUMXZ" => "Marvin Tatum Collection of Contemporary Literature, Special Collections, University of Virginia, Charlottesville, VA.",
      "SPEC-COLL" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "STACKS" => "Special Collections, University of Virginia, Charlottesville, VA.",
      "Reading Room" => "Special Collection, University of Virginia, Charlottesville, VA."
   }
end
