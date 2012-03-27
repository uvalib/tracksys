ActiveAdmin.register Agency do
  menu :parent => "Miscellaneous"

  scope :all, :default => true

  index :id => 'agencies' do 
    selectable_column
    column :name
  end
  
end