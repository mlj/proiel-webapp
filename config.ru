require ::File.expand_path('../config/environment',  __FILE__)

if ENV['HOSTNAME'] == 'hf-tekstlab-ny02.uio.no'
  map '/proiel' do
    run Proiel::Application
  end
else
  run Proiel::Application
end
