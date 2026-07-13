require "config"

require_relative "initializers/config"

env = ENV["SETTINGS__FORMS_ENV"]
env = "aws_#{env}" unless env == "local"
Config.load_and_set_settings(Config.setting_files(__dir__, env))
