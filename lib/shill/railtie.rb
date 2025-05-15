# frozen_string_literal: true

require "rails/railtie"

module Shill
  class Railtie < ::Rails::Railtie
    initializer "shill.view_helpers" do
      ActiveSupport.on_load(:action_view) do
        include Shill::Helpers
      end
    end
  end
end 