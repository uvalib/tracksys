class CreateRoles < ActiveRecord::Migration
   def up
     create_table :roles do |t|
       t.string :name, :null => false
     end
     Role.create({name: "Administrator"})
     Role.create({name: "Editor"})
     Role.create({name: "Viewer"})
     Role.create({name: "Supervisor"})
     Role.create({name: "Student"})
   end

   def down
      drop_table :roles
   end
end
