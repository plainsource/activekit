module ActiveKit
  module Base
    class Middleware
      def initialize(app)
        @app = app
      end

      # Middleware that determines which ActiveKit middlewares to run.
      def call(env)
        request = ActionDispatch::Request.new(env)

        activekit_run(request) do
          @app.call(env)
        end
      end

      private

      def activekit_run(request, &blk)
        ActiveKit::Position::Middleware.run(request: request)

        yield
      end
    end
  end
end
