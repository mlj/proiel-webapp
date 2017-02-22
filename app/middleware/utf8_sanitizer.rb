class Utf8Sanitizer
  SANITIZE_ENV_KEYS = %w(HTTP_REFERER PATH_INFO REQUEST_URI REQUEST_PATH QUERY_STRING)

  def initialize(app)
    @app = app
  end

  def call(env)
    SANITIZE_ENV_KEYS.each do |key|
      string = env[key].to_s
      valid = URI.decode(string).force_encoding('UTF-8').valid_encoding?
      return [400, { }, ['Bad request']] unless valid
    end

    @app.call(env)
  end
end
