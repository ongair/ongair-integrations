# recursively requires all files in ./lib and down that end in .rb
require "active_record"
Dir.glob('./models/*').each do |folder|
  Dir.glob(folder +"/*.rb").each do |file|
    require file
  end
end

# tells AR what db file to use
ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'db/ongair_integrations.db'
)