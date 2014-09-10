
# Just some tests while learning to write rake/rails tasks
# but they might occasionally be useful. 

namespace :last do

	desc "print last Bibl" 
	task :bibl => :environment do
		ap Bibl.last
	end

	desc "print last Order"
	task :order => :environment do
		ap Order.last
	end

	desc "print last Unit"
	task :unit => :environment do
		ap Unit.last
	end

	desc "print last Order, Unit, & Bibl"
	task :all => [ :order, :unit, :bibl ] 

end

namespace :env do

	desc "env:show print Rails.env, log_level"
	task :show => :environment  do 
		puts Rails.env
		puts Tracksys::Application.config.log_level
	end

end