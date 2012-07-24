class AddFieldsToComponents < ActiveRecord::Migration
  def change
		add_column :components, :followed_by_id, :integer
		add_column :components, :legacy_ead, :text
		add_column :components, :physical_desc, :text
		add_column :components, :scope_content, :text
		add_index  :components, :followed_by_id

  end
end
