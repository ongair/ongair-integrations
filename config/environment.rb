Ongair.configure do |config|
  config.root     = File.dirname(__FILE__)
  yml = YAML.load(File.read("config/application.yml"))
  config.app_url = yml['app_url']
end