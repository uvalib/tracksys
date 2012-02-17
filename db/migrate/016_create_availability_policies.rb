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

    # add_index :bibls, :availability_policy_id
    # add_index :components, :availability_policy_id
    # add_index :master_files, :availability_policy_id
    # add_index :units, :availability_policy_id

    # add_foreign_key :bibls, :availability_policies
    # add_foreign_key :components, :availability_policies
    # add_foreign_key :units, :availability_policies
    # add_foreign_key :master_files, :availability_policies

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
    # Create all appropriate policies and for each policy, associate it with pertinent objects.
    # Legacy objects with this information are:
    # * Bibls
    # * Components
    # * MasterFiles
    # * Units

    say "Reassign old and new availability information."
    Hash[
      "Public" => "http://text.lib.virginia.edu/policy/permit-to-all.xml",
      "VIVA only" => "http://text.lib.virginia.edu/policy/permit-to-viva-only.xml",
      "UVA only" => "http://text.lib.virginia.edu/policy/permit-to-uva-only.xml",
      "Restricted" => "http://text.lib.virginia.edu/policy/deny-to-all.xml"  
    ].each {|policy, url|
      policy_object = AvailabilityPolicy.create!(:name => "#{policy}", :xacml_policy_url => "#{url}")
      update_availability(policy_object.id, policy)
    }

    # Remove unncessary columns.
    # Note: The following cannot be consolidated into their respective change_table methods because an
    # object.availiability_policy_id must exist before the migration can occur.
    remove_column :bibls, :availability
    remove_column :components, :availability
    remove_column :master_files, :availability
    remove_column :units, :availability

  end

  # Migrate legacy availability string and turn it into a new legacy object of the same meaning.
  # i.e. master_file.availiability = "Public" becomes 
  # policy = AvailabilityPolicy.where(:name => "Public"); master_file.availability = policy (or master_file.availability_policy_id = policy.id)
  #
  # Note: update_all write a direct SQL UPDATE call and bypasses all validations, callbacks, etc...
  def update_availability(policy_id, old_value)
    classes = ['bibl', 'component', 'master_file', 'unit']
    classes.each {|class_name|
      class_name.classify.constantize.where(:availability => old_value).update_all(:availability_policy_id => policy_id, :availability => nil)
    }
  end
end