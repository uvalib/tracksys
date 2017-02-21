class AddWorkstationToProject < ActiveRecord::Migration
  def change
      add_reference :projects, :workstation, index: true
  end
end
