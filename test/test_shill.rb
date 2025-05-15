# frozen_string_literal: true

require "test_helper"
require "json"
require "net/http"

class TestShill < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Shill::VERSION
  end

  def test_fetches_projects_and_returns_them
    # Configure endpoint URL
    Shill.endpoint_url = "https://example.com/projects.json"

    stubbed_json = [
      {
        name: "My Project",
        url: "https://example.com",
        description: "An example project"
      }
    ].to_json

    # Stub Net::HTTP.get to avoid real HTTP requests
    Net::HTTP.stub :get, stubbed_json do
      projects = Shill.projects(refresh: true)

      assert_equal 1, projects.size
      project = projects.first
      assert_equal "My Project", project[:name]
      assert_equal "My Project", project.name
    end
  end
end
