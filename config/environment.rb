Ongair.configure do |config|
  config.root     = File.dirname(__FILE__)
  yml = YAML.load(File.read("config/application.yml"))
  config.app_url = yml['app_url']
  config.rollbar_access_token = yml['rollbar_access_token']
  config.rollbar_enabled = yml['rollbar_enabled']
  config.environment = yml['environment']
  config.new_relic_key = yml['new_relic_key']
  config.language_api_key = yml['language_api_key']
end