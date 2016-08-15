# == Schema Information
#
# Table name: metadata
#
#  id                     :integer          not null, primary key
#  is_approved            :boolean          default(FALSE), not null
#  is_personal_item       :boolean          default(FALSE), not null
#  resource_type          :string(255)
#  genre                  :string(255)
#  is_manuscript          :boolean          default(FALSE), not null
#  is_collection          :boolean          default(FALSE), not null
#  title                  :text(65535)
#  creator_name           :string(255)
#  catalog_key            :string(255)
#  barcode                :string(255)
#  call_number            :string(255)
#  pid                    :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  is_in_catalog          :boolean          default(FALSE), not null
#  exemplar               :string(255)
#  parent_bibl_id         :integer          default(0), not null
#  desc_metadata          :text(65535)
#  discoverability        :boolean          default(TRUE)
#  indexing_scenario_id   :integer
#  date_dl_ingest         :datetime
#  date_dl_update         :datetime
#  units_count            :integer          default(0)
#  availability_policy_id :integer
#  use_right_id           :integer
#  dpla                   :boolean          default(FALSE)
#  collection_facet       :string(255)
#  type                   :string(255)      default("SirsiMetadata")
#  xml_schema             :string(255)
#  external_attributes    :text(65535)
#

class SirsiMetadata < Metadata
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

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   has_and_belongs_to_many :legacy_identifiers, join_table: :sirsi_metadata_legacy_identifiers
   has_and_belongs_to_many :components, join_table: :sirsi_metadata_components

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates :xml_schema, :presence=>false
   validates :desc_metadata, :presence=>false

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------

   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------
   # Returns an array of Bibl objects that are the parent, grandparent, etc..
   def ancestors
      parent_bibls = Array.new
      if parent_bibl_id != 0
         begin
            bibl = parent_bibl
            parent_bibls << bibl
            parent_bibls << bibl.ancestors unless bibl.ancestors.nil?
            return parent_bibls.flatten
         rescue ActiveRecord::RecordNotFound
            return parent_bibls.flatten
         end
      end
   end

   # Returns the array of Bibl objects for which this Bibl is parent.
   def child_bibls
      begin
         return SirsiMetadata.where(parent_bibl_id: id).to_a
      rescue ActiveRecord::RecordNotFound
         return Array.new
      end
   end

   def parent_bibl
      begin
         return SirsiMetadata.find(parent_bibl_id)
      rescue ActiveRecord::RecordNotFound
         return nil
      end
   end

   def legacy_identifier_links
     return "" if self.legacy_identifiers.empty?
     out = ""
     self.legacy_identifiers.each do |li|
         out << "<div><a href='/admin/legacy_identifiers/#{li.id}'>#{li.description} (#{li.legacy_identifier})</a></div>"
     end
     return out
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
end
