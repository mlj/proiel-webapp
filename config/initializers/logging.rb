# Monkey-patch ActionView to remove some logging in production when run with
# `config.log_level = info`. Replace this with `config.action_view.logger =
# nil` in R4.
module ActionView
  class LogSubscriber < ActiveSupport::LogSubscriber
    def logger
      @memoized_logger ||= Logger.new('/dev/null')
    end
  end
end
