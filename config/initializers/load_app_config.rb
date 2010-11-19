CONFIG = Class.new do
  def initialize(file_name)
    app_config = YAML.load_file(Rails.root.join('config', 'app_config.yml'))
    @d = (app_config["all"] || {}).symbolize_keys
    @d.merge!((app_config[Rails.env] || {}).symbolize_keys)
    @d.freeze
  end

  def method_missing(name, *args)
    if @d.has_key?(name)
      @d[name]
    else
      super
    end
  end
end.new(Rails.root.join('config', 'app_config.yml'))
