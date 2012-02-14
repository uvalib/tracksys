class CreateAvailabilityPolicies < ActiveRecord::Migration
  def change
    create_table :availability_policies do |t|
      t.string :name
      t.string :xacml_policy_url
      t.integer :bibls_count, :default => 0
      t.integer :components_count, :default => 0
      t.integer :master_files_count, :default => 0
      t.integer :units_count, :default => 0

      t.timestamps
    end

    add_index :bibls, :availability_policy_id
    add_index :components, :availability_policy_id
    add_index :master_files, :availability_policy_id
    add_index :units, :availability_policy_id

    add_foreign_key :bibls, :availability_policies
    add_foreign_key :components, :availability_policies
    add_foreign_key :units, :availability_policies
    add_foreign_key :master_files, :availability_policies

    # In previous iteration of Tracksys, availabilities were chosen from an
    # enumerated list available in lib/digital_library_availabilities.rb.  In an
    # effort to give users of the application the ability to add or remove 
    # availabilities for digital library objects, this information will now exist
    # in the underlying database and available through the administrative interface.
    #
    # Additionally, the XACML policy URL is going to be stored in the DB rather than 
    # in lib/hydra.rb (or whatever this will be renamed) so it can be manipulated by the 
    # admin user.
    # 
    # Step 1 - Create all appropriate policies:
    Hash[
      "Public" => "http://text.lib.virginia.edu/policy/permit-to-all.xml",
      "VIVA only" => "http://text.lib.virginia.edu/policy/permit-to-viva-only.xml",
      "UVA only" => "http://text.lib.virginia.edu/policy/permit-to-uva-only.xml",
      "Restricted" => "http://text.lib.virginia.edu/policy/deny-to-all.xml"  
    ].each {|key, value|
      AvailabilityPolicy.create!(:name => "#{key}", :xacml_policy_url => "#{value}")
    }

    # Step 2 - Associate all legacy objects with an AvailabilityPolicy object rather than 
    # the legacy string in the object.availability attribute.  Legacy objects with this information are:
    # * Bibls
    # * Components
    # * MasterFiles
    # * Units
    objects = []
    say "Getting all Bibl objects with an availability value."
    objects.push(Bibl.where('availability is not null'))

    say "Getting all Component objects with an availability value."
    objects.push(Component.where('availability is not null'))

    say "Getting all MasterFile objects with an availability value."
    objects.push(MasterFile.where('availability is not null'))

    say "Getting all Unit objects with an availability value."
    objects.push(Unit.where('availability is not null'))
    objects.flatten!

    objects.each {|object|
      policy = AvailabilityPolicy.where(:name => object.availability).id
      object.update_attributes!(:availability_policy_id => policy.id, :availability => nil)
    }

    # Step 3 - Remove unncessary columns
    remove_column :bibls, :availability
    remove_column :components, :availability
    remove_column :master_files, :availability
    remove_column :units, :availability

  end
end