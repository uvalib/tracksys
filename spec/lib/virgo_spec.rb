# rspec tests for Virgo class

require 'spec_helper'

describe Virgo do
  describe "#validate_barcode" do
    it "should take a valid barcode string and return true" do
      barcode="X001892622" # long index file breaks original library
      expect(Virgo.validate_barcode(barcode)).to be true
    end
    it "should take a valid barcode string and return true" do
      barcode="3587312-1001" # shorter index file (Nova reperta)
      expect(Virgo.validate_barcode(barcode)).to be true
    end
    it "should take an invalid barcode string and return false" do
      bad_barcode="no_way_this_is_a_barcode"
      expect(Virgo.validate_barcode(bad_barcode)).to be false
    end
  end

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
  describe "#external_update" do
    FactoryGirl.define do
      factory :bibl do
        created_at { 21.days.ago }
      end
    end
    bibls = []; computing_id = %x[ id -nu ].chomp # log errors as current user
    bibls[0] = FactoryGirl.build(:bibl, :title => "Nova reperta : new discoveries and inventions", :id => 16356, :barcode => "3587312-1001", :catalog_key => "u3587312" , :call_number => "Outdated CallNo.")
    bibls[1] = FactoryGirl.build(:bibl, :title => "Letters of the Preston family", :id => 16353, :barcode => "2387001-1001", :catalog_key => "u2387001" , :call_number => "Outdated CallNo.")
#    bibls[2] = FactoryGirl.build(:bibl, :title => "Corks and curls", :id => 16241, :barcode => "X001892622", :catalog_key => "u126747" , :call_number => "Outdated CallNo.")
    it "should take an array of Bibls and update their attributes from #{@metadata_server}" do
      Virgo.external_update(bibls, computing_id)
      expect(bibls[0].call_number).to eq "PS3554 .R68 N68 1999"
      expect(bibls[1].call_number).to eq "MSS 11166"
#      expect(bibls[2].call_number).to eq "LD 5687 .C7 v.37 1924"
      expect(bibls[0].updated_at).not_to eq(nil)
    end
    it "should take a single Bibl and update its attributes from #{@metadata_server}" do
      bibl = FactoryGirl.build(:bibl, :title => "Incorrect title", :id => 16349, :barcode => "3679718-1001", :catalog_key => "u3679718" , :call_number => "Outdated CallNo.")
      Virgo.external_update(bibl, computing_id)
      expect(bibl.call_number).to eq "LC214.22 .V8 D42 1955"
      expect(bibl.title).to eq "To the people of Virginia"
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
