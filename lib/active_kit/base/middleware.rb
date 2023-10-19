module ActiveKit
  module Base
    class Middleware
      def initialize(app)
        @app = app
      end

      # Middleware that determines which ActiveKit middlewares to run.
      def call(env)
        request = ActionDispatch::Request.new(env)

        activekit_runner(request) do
          @app.call(env)
        end
      end

      private

      # Here constantize is used to get the latest reloaded class as per the below link.
      # https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#use-case-3-configure-application-classes-for-engines
      def activekit_runner(request, &blk)
        "ActiveKit::Schedule::Middleware".constantize.run(request: request)

        yield
      end
    end
  end
end
