# frozen_string_literal: true

require_relative "shill/version"
# Autoload internal files
require_relative "shill/helpers"

# Load Railtie if Rails is present
if defined?(Rails::Railtie)
  require_relative "shill/railtie"
end

module Shill
  class Error < StandardError; end
  # Your code goes here...

  # Simple value-object that stores all configurable options.
  class Configuration
    # URL that returns a JSON array of project objects.
    attr_accessor :endpoint_url

    # Custom cache store (defaults to Rails.cache when available or a lightweight in-memory store).
    # The store should respond to `fetch(key, **options) { ... }` and `delete(key)`.
    attr_accessor :cache_store
  end

  # Simple value object representing a single project.
  Project = Struct.new(:name, :url, :description, :logo_url, keyword_init: true)

  class << self
    # Access the global configuration object.
    def configuration
      @configuration ||= Configuration.new
    end

    # Configure the gem inside an initializer or plain Ruby
    # Example (Rails):
    #   Shill.configure do |config|
    #     config.endpoint_url = "https://example.com/projects.json"
    #   end
    def configure
      yield(configuration) if block_given?
    end

    # Convenience getter/setter so existing `Shill.endpoint_url =` still works.
    def endpoint_url
      configuration.endpoint_url
    end

    def endpoint_url=(value)
      configuration.endpoint_url = value
    end

    # Choose the cache store. Priority:
    # 1. Explicitly configured via `Shill.configure { |c| c.cache_store = ... }`
    # 2. Rails.cache if Rails is loaded
    # 3. A simple in-process memory cache
    def cache_store
      configuration.cache_store || default_cache_store
    end

    def cache_store=(store)
      configuration.cache_store = store
    end

    # Return all projects fetched from the configured endpoint.
    # Results are memoised – pass `refresh: true` to force a new HTTP request.
    def projects(refresh: false)
      clear_cache if refresh

      cache_store.fetch("shill_projects") { fetch_projects }
    end

    # Return a single random project (or nil if none present).
    def random_project(refresh: false)
      projects(refresh: refresh).sample
    end

    # Remove cached payload.
    def clear_cache
      if cache_store.respond_to?(:delete)
        cache_store.delete("shill_projects")
      end
    end

    private

    # Fetch and parse the projects JSON from the endpoint.
    def fetch_projects
      raise Error, "Shill.endpoint_url must be configured" unless endpoint_url && !endpoint_url.empty?

      require "json"
      require "uri"
      require "net/http"

      uri = URI.parse(endpoint_url)

      response_body = Net::HTTP.get(uri)

      begin
        parsed = JSON.parse(response_body, symbolize_names: true)
      rescue JSON::ParserError => e
        raise Error, "Invalid JSON received from #{endpoint_url}: #{e.message}"
      end

      validate_projects!(parsed)
      # Return an array of Project objects for nicer dot-notation access.
      parsed.map { |attrs| Project.new(attrs) }
    rescue StandardError => e
      # Re-wrap into Shill::Error to keep API consistent
      raise Error, e.message unless e.is_a?(Error)
    end

    # Ensure we have an array of hashes with required keys.
    def validate_projects!(obj)
      unless obj.is_a?(Array)
        raise Error, "Projects JSON must be an array"
      end

      obj.each_with_index do |proj, idx|
        unless proj.is_a?(Hash)
          raise Error, "Project at index #{idx} must be an object"
        end

        required_keys = %i[name url description]

        missing = required_keys.reject { |k| proj.key?(k) }

        unless missing.empty?
          raise Error, "Project at index #{idx} is missing keys: #{missing.join(", ")}"
        end
      end
    end

    # Determine the default cache store based on environment.
    def default_cache_store
      if defined?(Rails) && Rails.respond_to?(:cache) && Rails.cache
        Rails.cache
      else
        @memory_cache ||= MemoryCache.new
      end
    end

    # Minimal in-process cache that exposes `fetch`/`delete` to mimic ActiveSupport::Cache API.
    class MemoryCache
      def initialize
        @data = {}
      end

      def fetch(key)
        return @data[key] if @data.key?(key)
        @data[key] = yield
      end

      def delete(key)
        @data.delete(key)
      end
    end
  end
end
