web: bundle exec rails server -b 0.0.0.0 -p 5000 -e development 
sidekiq: bundle exec sidekiq -C config/sidekiq.yml -e development   
cronenberg: cronenberg ./ky-specific/cronenberg/cron-jobs.yml  
migration: ./ky-specific/migration/db-migrate.sh 
