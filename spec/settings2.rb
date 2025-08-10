# frozen_string_literal: true

class Settings2 < Settingslogic
  source "#{File.dirname(__FILE__)}/settings.yml"
  namespace 'setting1'
end
