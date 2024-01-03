module ActiveKit
  module Schedule
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        request = ActionDispatch::Request.new(env)

        middleware_run(request) do
          @app.call(env)
        end
      end

      private

      def middleware_run(request, &blk)
        # Schedule middleware code

        yield
      end
    end
  end
end
