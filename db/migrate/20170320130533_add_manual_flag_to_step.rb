class AddManualFlagToStep < ActiveRecord::Migration
  def change
     add_column :steps, :manual, :boolean, default: false
  end
end
