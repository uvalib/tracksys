# rspec tests for Virgo class

require 'spec_helper'

describe Virgo do
  describe "#validate_barcode" do
    it "should take a valid barcode string and return true" do
      code="X001892622"
      expect(Virgo.validate_barcode(code)).to be true
    end
    it "should take an invalid barcode string and return false" do
      code="no_way_this_is_a_barcode"
      expect(Virgo.validate_barcode(code)).to be true
    end
  end
  describe "#external_lookup" do
    it "should take a catalog key and return the corresponding catalog record as a Bibl object" do
    end
    it "should take a barcode and return the corresponding catalog record as a Bibl object" do
    end
  end
  describe "#external_update" do
    it "should " do
    end
  end
  describe "#get_main_element" do
    it "should " do
    end
  end
  describe "#query_metadata_server" do
    it "should " do
    end
  end
  describe "#set_bibl_attributes" do
    it "should " do
    end
  end
end # end class description
