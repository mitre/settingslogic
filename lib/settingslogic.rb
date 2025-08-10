# frozen_string_literal: true

require 'yaml'
require 'erb'

# A simple settings solution using a YAML file. See README for more information.
class Settingslogic < Hash
  class MissingSetting < StandardError; end

  class << self
    def name # :nodoc:
      superclass != Hash && instance.key?('name') ? instance.name : super
    end

    # Enables Settings.get('nested.key.name') for dynamic access
    def get(key)
      parts = key.split('.')
      curs = self
      while (p = parts.shift)
        curs = curs.send(p)
      end
      curs
    end

    def source(value = nil)
      @source ||= value
    end

    def namespace(value = nil)
      @namespace ||= value
    end

    def suppress_errors(value = nil)
      @suppress_errors ||= value
    end

    def [](key)
      instance.fetch(key.to_s, nil)
    end

    def []=(key, val)
      # Setting[:key][:key2] = 'value' for dynamic settings
      val = new(val, source) if val.is_a? Hash
      instance.store(key.to_s, val)
      instance.create_accessor_for(key, val)
    end

    def load!
      instance
      true
    end

    def reload!
      @instance = nil
      load!
    end

    private

    def instance
      return @instance if @instance

      @instance = new
      create_accessors!
      @instance
    end

    def method_missing(name, *args, &block)
      instance.send(name, *args, &block)
    end

    # It would be great to DRY this up somehow, someday, but it's difficult because
    # of the singleton pattern.  Basically this proxies Setting.foo to Setting.instance.foo
    def create_accessors!
      instance.each_key do |key|
        create_accessor_for(key)
      end
    end

    def create_accessor_for(key)
      return unless /^\w+$/.match?(key.to_s) # could have "some-setting:" which blows up eval

      instance_eval "def #{key}; instance.send(:#{key}); end", __FILE__, __LINE__
    end
  end

  # Initializes a new settings object. You can initialize an object in any of the following ways:
  #
  #   Settings.new(:application) # will look for config/application.yml
  #   Settings.new("application.yaml") # will look for application.yaml
  #   Settings.new("/var/configs/application.yml") # will look for /var/configs/application.yml
  #   Settings.new(:config1 => 1, :config2 => 2)
  #
  # Basically if you pass a symbol it will look for that file in the configs directory of your rails app,
  # if you are using this in rails. If you pass a string it should be an absolute path to your settings file.
  # Then you can pass a hash, and it just allows you to access the hash via methods.
  def initialize(hash_or_file = self.class.source, section = nil)
    # puts "new! #{hash_or_file}"
    case hash_or_file
    when nil
      raise Errno::ENOENT, 'No file specified as Settingslogic source'
    when Hash
      replace hash_or_file
    else
      file_contents = read_file(hash_or_file)
      hash = file_contents.empty? ? {} : parse_yaml_content(file_contents)
      if self.class.namespace
        hash = hash[self.class.namespace] or
          return missing_key("Missing setting '#{self.class.namespace}' in #{hash_or_file}")
      end

      replace hash
    end
    @section = section || self.class.source # so end of error says "in application.yml"
    create_accessors!
  end

  # Called for dynamically-defined keys, and also the first key deferenced at the top-level, if load! is not used.
  # Otherwise, create_accessors! (called by new) will have created actual methods for each key.
  def method_missing(name, *_args)
    key = name.to_s
    return missing_key("Missing setting '#{key}' in #{@section}") unless key? key

    value = fetch(key)
    create_accessor_for(key)
    value.is_a?(Hash) ? self.class.new(value, "'#{key}' section in #{@section}") : value
  end

  def [](key)
    fetch(key.to_s, nil)
  end

  def []=(key, val)
    # Setting[:key][:key2] = 'value' for dynamic settings
    val = self.class.new(val, @section) if val.is_a? Hash
    store(key.to_s, val)
    create_accessor_for(key, val)
  end

  # Returns an instance of a Hash object
  def to_hash
    to_h
  end

  # Prevents Array#flatten from trying to expand Settings objects
  # This fixes RSpec issues when Settings objects are included in arrays
  def to_ary
    nil
  end

  # This handles naming collisions with Sinatra/Vlad/Capistrano. Since these use a set()
  # helper that defines methods in Object, ANY method_missing ANYWHERE picks up the Vlad/Sinatra
  # settings!  So settings.deploy_to title actually calls Object.deploy_to (from set :deploy_to, "host"),
  # rather than the app_yml['deploy_to'] hash.  Jeezus.
  def create_accessors!
    each do |key, _val|
      create_accessor_for(key)
    end
  end

  # Use instance_eval/class_eval because they're actually more efficient than define_method{}
  # http://stackoverflow.com/questions/185947/ruby-definemethod-vs-def
  # http://bmorearty.wordpress.com/2009/01/09/fun-with-rubys-instance_eval-and-class_eval/
  def create_accessor_for(key, val = nil)
    return unless /^\w+$/.match?(key.to_s) # could have "some-setting:" which blows up eval

    instance_variable_set("@#{key}", val)
    self.class.class_eval <<-ENDEVAL, __FILE__, __LINE__ + 1
      def #{key}
        return @#{key} if @#{key}
        return missing_key("Missing setting '#{key}' in #{@section}") unless key? '#{key}'
        value = fetch('#{key}')
        @#{key} = if value.is_a?(Hash)
          self.class.new(value, "'#{key}' section in #{@section}")
        elsif value.is_a?(Array) && value.all?{|v| v.is_a? Hash}
          value.map{|v| self.class.new(v)}
        else
          value
        end
      end
    ENDEVAL
  end

  # Convert all keys to symbols recursively
  def symbolize_keys
    each_with_object({}) do |(key, value), memo|
      k = begin
        key.to_sym
      rescue StandardError
        key
      end
      # Access the value properly through the accessor method
      v = respond_to?(key) ? send(key) : value
      # Recursively symbolize nested hashes
      memo[k] = if v.is_a?(self.class)
                  v.symbolize_keys
                elsif v.respond_to?(:symbolize_keys)
                  v.symbolize_keys
                else
                  v
                end
    end
  end

  # Convert all keys to strings recursively (Rails compatibility)
  def stringify_keys
    each_with_object({}) do |(key, value), memo|
      k = key.to_s
      v = begin
        send(key)
      rescue StandardError
        value
      end
      memo[k] = v.respond_to?(:stringify_keys) ? v.stringify_keys : v
    end
  end

  # Deep merge settings (useful for overrides)
  def deep_merge(other_hash)
    self.class.new(deep_merge_hash(to_hash, other_hash))
  end

  # Deep merge in place
  def deep_merge!(other_hash)
    replace(deep_merge_hash(to_hash, other_hash))
  end

  private

  # Helper for deep merging
  def deep_merge_hash(hash, other_hash)
    hash.merge(other_hash) do |_key, old_val, new_val|
      if old_val.is_a?(Hash) && new_val.is_a?(Hash)
        deep_merge_hash(old_val, new_val)
      else
        new_val
      end
    end
  end

  def missing_key(msg)
    return nil if self.class.suppress_errors

    raise MissingSetting, msg
  end

  # Parse YAML content with Psych 4 / Ruby 3.1+ compatibility
  # Handles YAML aliases which are disabled by default in Psych 4
  def parse_yaml_content(file_content)
    erb_result = ERB.new(file_content).result

    if YAML.respond_to?(:unsafe_load)
      # Ruby 3.1+ with Psych 4 - fastest for trusted config files
      YAML.unsafe_load(erb_result).to_hash
    elsif YAML.respond_to?(:safe_load)
      # Ruby 3.0+ with safe_load supporting aliases option
      begin
        YAML.safe_load(erb_result, aliases: true, permitted_classes: [Symbol, Date, Time]).to_hash
      rescue ArgumentError
        # Older versions without aliases parameter
        YAML.safe_load(erb_result).to_hash
      end
    else
      # Ruby 2.x fallback
      YAML.safe_load(erb_result).to_hash
    end
  rescue Psych::DisallowedClass, Psych::BadAlias => e
    # Additional fallback for edge cases
    raise e unless defined?(Psych::VERSION) && Psych::VERSION >= '4.0.0'

    raise MissingSetting, 'YAML file contains aliases but they are disabled in Psych 4. ' \
                          'Please update your YAML file or use unsafe_load.'
  end

  # Read file contents handling both local files and URIs
  # Uses Net::HTTP for security instead of open-uri
  def read_file(source)
    source_str = source.to_s

    # Check for dangerous protocols first
    if source_str.match?(%r{\A(file|ftp|gopher|ldap|dict|tftp|sftp)://}i)
      raise ArgumentError, "Invalid URL protocol: #{source}"
    end

    if source_str.match?(%r{\Ahttps?://}i)
      # For HTTP/HTTPS URLs, use Net::HTTP which is more secure
      require 'net/http'
      require 'uri'

      uri = URI.parse(source_str)

      # Security: validate the URI
      raise ArgumentError, "Invalid URL: #{source}" unless uri.is_a?(URI::HTTP)

      # Use Net::HTTP with proper error handling
      response = Net::HTTP.get_response(uri)

      case response
      when Net::HTTPSuccess
        response.body
      else
        raise "Failed to fetch #{source}: #{response.code} #{response.message}"
      end
    else
      # For local files, use File.read which is more efficient
      File.read(source_str)
    end
  end
end
