# frozen_string_literal: true

class Settings < Settingslogic
  source "#{File.dirname(__FILE__)}/settings.yml"
end

class SettingsInst < Settingslogic
end
