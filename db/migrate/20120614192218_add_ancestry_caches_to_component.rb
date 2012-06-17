class AddAncestryCachesToComponent < ActiveRecord::Migration
  def change
		add_column :components, :pids_depth_cache, :string
		add_column :components, :ead_id_atts_depth_cache, :string
  end
end
