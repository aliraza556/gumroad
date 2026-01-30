web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -q critical -q default -q low -q mongo
release: bundle exec rails db:migrate
