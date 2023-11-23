module ActiveKit
  class Engine < ::Rails::Engine
    isolate_namespace ActiveKit
    config.eager_load_namespaces << ActiveKit

    initializer "active_kit.add_middleware" do |app|
      require "active_kit/base/middleware"

      app.middleware.use ActiveKit::Base::Middleware
    end

    initializer "active_kit.position" do
      require "active_kit/position/positionable"

      ActiveSupport.on_load(:active_record) do
        include ActiveKit::Position::Positionable
      end
    end
  end
end
