def sh_mysql(config)
  mysql = mysql_command << ' '
  mysql << "-u#{config['username']} " if config['username']
  mysql << "-p#{config['password']} " if config['password']
  mysql << "-h#{config['host']} "     if config['host']
  mysql << "-P#{config['port']} "     if config['port']
  mysql << config['database']         if config['database']
  mysql
end

def mysql_command
  'mysql'
end

desc "Launch mysql shell.  Use with an environment task (e.g. rake production mysql)"
task :mysql do
  system sh_mysql(YAML.load(open(File.join('config', 'database.yml')))[RAILS_ENV])
end
