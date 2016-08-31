class AddUriToUseRights < ActiveRecord::Migration
  def change
     add_column :use_rights, :uri, :string
  end
end
