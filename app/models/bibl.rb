require "#{Hydraulics.models_dir}/bibl"

class Bibl

  include Pidable

  VIRGO_FIELDS = ['title', 'creator_name', 'creator_name_type', 'call_number', 'catalog_key', 'barcode', 'copy', 'date_external_update', 'location', 'citation', 'year', 'year_type', 'location', 'copy', 'title_control', 'date_external_update']
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
  # aliases
  #------------------------------------------------------------------
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :title

  # Although many Bibl records have citations provided through the MARC record, many do not 
  # (especially those which lack a MARC record or are otherwise not cataloged in VIRGO).  As 
  # a result, this method will impose some general order on the act of creating citations where
  # needed and rely upon the canonical citation when present.
  def get_citation
    if self.citation
      return self.citation
    else
      citation = String.new
      citation << "#{self.cleanedup_title}.  " if self.title
      citation << "#{self.call_number}.  " if self.call_number
      if self.location
        begin
          citation << "#{LOCATION_HASH.fetch(self.location)}"
        rescue
          citation << "Special Collections, University of Virginia, Charlottesville, VA"
        end
      else
        citation << "Special Collections, University of Virginia, Charlottesville, VA"
      end
      return citation
    end
  end

  # For the purposes of citations, run the title through some manipulation.
  def cleanedup_title
    # Remove trailing periods.
    if self.title.match(/.$/)
      return self.title.chop
    else
      return self.title
    end
  end

  def physical_virgo_url
    return "#{VIRGO_URL}/#{self.catalog_key}"
  end

  def dl_virgo_url
    return "#{VIRGO_URL}/#{self.pid}"
  end

  def fedora_url
    return "#{FEDORA_REST_URL}/objects/#{self.pid}"
  end
end
