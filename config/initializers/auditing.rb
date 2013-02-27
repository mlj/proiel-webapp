def change_logging(options = {})
  audited options
  disable_auditing unless Proiel::Application.config.auditing
end
