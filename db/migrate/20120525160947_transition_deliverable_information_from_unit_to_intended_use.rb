class TransitionDeliverableInformationFromUnitToIntendedUse < ActiveRecord::Migration
  def change
    # Change the following IntendedUse types to highest possible TIFF
    # * Digital Archive
    # * Print Publication (academic)
    # * GIS Processing
    # * Physical Exhibit
    # * Print Publication (non-academic)
    IntendedUse.find(101, 102, 105, 107, 108).each {|intended_use|
      intended_use.update_attributes(:deliverable_format => 'tiff', :deliverable_resolution => 'Highest Possible', :deliverable_resolution_unit => 'dpi')
    }

    # Change the following IntendedUse types to 300dpi JPEG
    # * Classroom Instruction
    # * Online Exhibit
    # * Personal Research
    # * Presentation
    # * Sharing with Colleagues
    # * Web Publication
    IntendedUse.find(100, 103, 104, 106, 111, 109).each {|intended_use|
      intended_use.update_attributes(:deliverable_format => 'jpeg', :deliverable_resolution => '300', :deliverable_resolution_unit => 'dpi')
    }

    # N.B. The IntendedUse for 'Digital Colleciton Building' has no deliverables therefore all three values set above remain nil.
  end
end
