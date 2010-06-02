app_config = YAML.load_file(Rails.root.join('config', 'app_config.yml'))
CONFIG = (app_config["all"] || {}).symbolize_keys
CONFIG.merge!((app_config[Rails.env] || {}).symbolize_keys)
CONFIG.freeze
