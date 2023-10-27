module ActiveKit
  class Engine < ::Rails::Engine
    isolate_namespace ActiveKit
    config.eager_load_namespaces << ActiveKit

    initializer "active_kit.add_middleware" do |app|
      require "active_kit/base/middleware"

      app.middleware.use ActiveKit::Base::Middleware
    end

    initializer "active_kit.activekitable" do
      require "active_kit/base/activekitable"

      ActiveSupport.on_load(:active_record) do
        include ActiveKit::Base::Activekitable
      end
    end
  end
end
