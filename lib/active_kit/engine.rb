module ActiveKit
  class Engine < ::Rails::Engine
    isolate_namespace ActiveKit
    config.eager_load_namespaces << ActiveKit

    initializer "active_kit.add_middleware" do |app|
      require "active_kit/position/middleware"
      require "active_kit/schedule/middleware"

      app.middleware.use ActiveKit::Position::Middleware
      app.middleware.use ActiveKit::Schedule::Middleware
    end

    initializer "active_kit.activekitable" do
      require "active_kit/bedrock/bedrockable"
      require "active_kit/export/exportable"
      require "active_kit/position/positionable"
      require "active_kit/schedule/scheduleable"
      require "active_kit/search/searchable"

      ActiveSupport.on_load(:active_record) do
        include ActiveKit::Export::Exportable
        include ActiveKit::Position::Positionable
        include ActiveKit::Schedule::Scheduleable
        include ActiveKit::Search::Searchable
      end
    end
  end
end
