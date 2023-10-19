module ActiveKit
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

    def activekit_runner(request, &blk)
      ActiveKit::Ensure.middleware_for!(request: request)

      yield
    end
  end
end
