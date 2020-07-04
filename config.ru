require ::File.expand_path('../config/environment',  __FILE__)

if ENV['BASE_URL']
  map ENV['BASE_URL'] do
    run Proiel::Application
  end
else
  run Proiel::Application
end
