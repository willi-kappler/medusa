require "settingslogic"

class Backup < Settingslogic
  source File.expand_path("../../../config/application.yml", __FILE__)
  namespace "backup"
end
