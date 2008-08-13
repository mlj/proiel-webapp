desc "Run all tasks that should be run regularly (typically from cron)"
task(:cron => [ "db:backup", "proiel:export:all:public", "proiel:validator", "db:validate" ])
