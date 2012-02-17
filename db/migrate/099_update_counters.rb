class UpdateCounters < ActiveRecord::Migration
  def change
    say "Updating customer.orders_count."
    Customer.find(:all).each {|c|
      Customer.update_counters c.id, :orders_count => c.orders.count
    }

    say "Updating unit.master_files_count and unit.automation_messages_count"
    Unit.find(:all).each {|u|
      Unit.update_counters u.id, :master_files_count => u.master_files.count
      Unit.update_counters u.id, :automation_messages_count => u.automation_messages.count
    }

    say "Updating order.units_count, order.invoices_count, and order.automation_messages_count"
    Order.find(:all).each {|o|
      Order.update_counters o.id, :units_count => o.units.count
      Order.update_counters o.id, :automation_messages_count => o.automation_messages.count
      Order.update_counters o.id, :invoices_count => o.invoices.count
    }

    say "Updating bibl.units_count, bibl.master_files_count, bibl.orders_count and bibl.automation_messages_count"
    Bibl.find(:all).each {|b|
      Bibl.update_counters b.id, :units_count => b.units.count
      Bibl.update_counters b.id, :orders_count => b.orders.count
      Bibl.update_counters b.id, :automation_messages_count => b.automation_messages.count
      Bibl.update_counters b.id, :master_files_count => b.master_files.count
    }

    # Given the large number of MasterFile objects, this migration requires dividing the 
    # MasterFile array into smaller increments
    say "Updating master_file.automation_messages_count"
    MasterFile.where('automation_messages_count is null').limit(1000).each {|m|
      MasterFile.update_counters m.id, :automation_messages_count => m.automation_messages.count
    }

    say "Updating agency.orders_count"
    Agency.find(:all).each {|a|
      Agency.update_counters a.id, :orders_count => a.orders.count
    }

    say "Updateing archive.units_count"
    Archive.find(:all).each {|a|
      Archive.update_counters a.id, :units_count => a.units.count
    }

    say "Updating departments.customers_count"
    Department.find(:all).each {|d|
      Department.update_counters d.id, :customers_count => d.customers.count
    }

    say "Updating heard_about_service.customers_count"
    HeardAboutService.find(:all).each {|h|
      HeardAboutService.update_counters h.id, :customers_count => h.customers.count
    }

    say "Update intended_use.units_count"
    IntendedUse.find(:all).each {|i|
      IntendedUse.update_counters i.id, :units_count => i.units.count
    }

    say "Updating academic_status.customers_count"
    AcademicStatus.find(:all).each {|a|
      AcademicStatus.update_counters a.id, :customers_count => a.customers.count
    }

    say "Updating availability_policy.orders_count, availability_policy.units_count, availability_policy.components_counts and availability_policy.master_files_count"
    AvailabilityPolicy.find(:all).each {|a|
      AvailabilityPolicy.update_counters a.id, :bibls_count => a.bibls.count
      AvailabilityPolicy.update_counters a.id, :units_count => a.units.count
      AvailabilityPolicy.update_counters a.id, :components_count => a.components.count
      AvailabilityPolicy.update_counters a.id, :master_files_count => a.master_files.count
    }

    say "Updating use_right.orders_count, use_right.units_count, use_right.components_counts and use_right.master_files_count"
    UseRight.find(:all).each {|u|
      UseRight.update_counters u.id, :bibls_count => u.bibls.count
      UseRight.update_counters u.id, :units_count => u.units.count
      UseRight.update_counters u.id, :components_count => u.components.count
      UseRight.update_counters u.id, :master_files_count => u.master_files.count
    }

    say "Updating indexing_scenario.orders_count, indexing_scenario.units_count, indexing_scenario.components_counts and indexing_scenario.master_files_count"
    IndexingScenario.find(:all).each {|i|
      IndexingScenario.update_counters i.id, :bibls_count => i.bibls.count
      IndexingScenario.update_counters i.id, :units_count => i.units.count
      IndexingScenario.update_counters i.id, :components_count => i.components.count
      IndexingScenario.update_counters i.id, :master_files_count => i.master_files.count
    }
  end
end
