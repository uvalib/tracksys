class UnitPolymorphicMetadata < ActiveRecord::Migration
  def change
     add_reference :units, :metadata, polymorphic: true, index: true
  end
end
