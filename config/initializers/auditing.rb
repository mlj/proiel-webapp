def change_logging(options = {})
  acts_as_audited options
  disable_auditing unless Proiel::Application.config.auditing
end
