namespace :db do
  desc "writes db dump of database to #{Rails.root}/tmp"
  task :backup => :environment do
    dir = "#{Rails.root}/tmp"
    file = "#{Rails.env}-data-#{Date.today}.sql"
    user = ActiveRecord::Base.connection.pool.spec.config[:username]
    pass = ActiveRecord::Base.connection.pool.spec.config[:password]
    host = ActiveRecord::Base.connection.pool.spec.config[:host]
    db   = ActiveRecord::Base.connection.pool.spec.config[:database]
    puts "backing up production data to #{dir}/#{file}" 
    system "mysqldump -h #{host} -u #{user} -p'#{pass}' #{db} > #{dir}/#{file}"
  end
end
