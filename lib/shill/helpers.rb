# frozen_string_literal: true

module Shill
  # View-helper methods for Rails
  module Helpers
    # Returns all cached projects (see Shill.projects)
    def shill_projects
      Shill.projects
    end

    # Returns a single random project
    def shill_random_project
      Shill.random_project
    end
  end
end 