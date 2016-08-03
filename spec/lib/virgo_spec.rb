# rspec tests for Virgo class

require 'spec_helper'

describe Virgo do
  describe "#external_lookup" do
    # existing, long record
    it "should take a catalog key and return the corresponding catalog record as a Bibl object" do
      cat_key ="u126747" # Corks and curls
      bibl = Virgo.external_lookup(cat_key, '')
      expect(bibl.title).to eq "Corks and curls"
      expect(bibl.year).to eq "1888-"

    end
    it "should take a barcode and return the corresponding catalog record as a Bibl object" do
      barcode = "X001892622" # Corks and curls
      bibl = Virgo.external_lookup('', barcode)
      expect(bibl.call_number).to eq "LD 5687 .C7 v.37 1924"
      expect(bibl.title).to eq "Corks and curls"
      expect(bibl.year).to eq "1888-"
    end
    # existing, short record
    it "should take a catalog key and return the corresponding catalog record as a Bibl object" do
      cat_key = "u3587312" # Nova reperta
      bibl = Virgo.external_lookup(cat_key, '')
      expect(bibl.call_number).to eq "PS3554 .R68 N68 1999"
    end
    it "should take a barcode and return the corresponding catalog record as a Bibl object" do
      barcode = "3587312-1001" # Nova reperta
      bibl = Virgo.external_lookup('', barcode)
      expect(bibl.call_number).to eq "PS3554 .R68 N68 1999"
    end
    # non-existent id passed to method
    it "should take an invalid catalog key and raise an error" do
      bad_cat_key = "now_way_this_is_a_cat_key"
      expect{ Virgo.external_lookup(bad_cat_key, '') }.to raise_error RuntimeError, "Query to index.lib.virginia.edu failed to return a valid result."
    end
    it "should take an invalid barcode and raise an error" do
      bad_barcode = "no_way_this_is_a_barcode"
      expect{ Virgo.external_lookup('', bad_barcode) }.to raise_error RuntimeError, "Query to index.lib.virginia.edu failed to return a valid result."
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
