module ActiveKit
  class Middleware
    def initialize(app)
      @app = app
    end

    # Middleware that determines which ActiveKit schedules to run.
    def call(env)
      request = ActionDispatch::Request.new(env)

      activekit_runner(request) do
        @app.call(env)
      end
    end

    private

    def activekit_runner(request, &blk)
      ActiveKit::Loader.ensure_middleware_for!(request: request)

      yield
    end
  end
end
