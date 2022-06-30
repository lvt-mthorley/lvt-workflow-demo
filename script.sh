# Setup - https://devcenter.heroku.com/articles/rack

setup() {
  echo Create app config.ru
  cat <<EOF> config.ru
run lambda { |env| env['REQUEST_PATH'] == '/' ? [200, {'Content-Type'=>'text/plain'}, StringIO.new("Hello World!\n")] : [404, {'Content-Type'=>'text/plain'}, StringIO.new("Not found\n")]}
EOF

  echo Create Gemfile
  cat <<EOF> Gemfile
source 'https://rubygems.org'
gem 'rack'
gem 'puma'
EOF

  echo 'bundle/' > .gitignore
  echo 'vendor/' >> .gitignore
  echo '*.swp' >> .gitignore

  echo Select ruby version
  chruby 3.0.1

  echo Bundle
  bundle lock --add-platform x86_64-linux
}

create() {
  echo Create Heroku app
  git init
  git add .
  git commit -m 'Init'
  heroku create -a 'lvt-workflow-demo'
  git push heroku master

  echo Open the app
  heroku apps:open
}

scale() {
  echo Scale the app down and back up
  heroku ps:scale web=0
  heroku ps:scale web=1
}

logs() {
  echo Attach a logging service
  heroku addons:create papertrail
  heroku addons:open papertrail
}

db() {
  heroku addons:create heroku-postgresql:hobby-dev
  psql $(heroku config |grep DATABASE_URL |cut -c15-) -c "create table examples (id int, name varchar); insert into examples values (1, 'LVT');"

  echo "gem 'activerecord'" >> Gemfile
  echo "gem 'pg'" >> Gemfile

  cat <<EOF> config.ru
require 'active_record'
ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'postgres://localhost/mydb')

class Example < ActiveRecord::Base
end

run lambda { |env| env['REQUEST_PATH'] == '/' ? [200, {'Content-Type'=>'text/plain'}, StringIO.new("Hello #{Example.first.name}!\n")] : [404, {'Content-Type'=>'text/plain'}, StringIO.new("Not found\n")]}
EOF
}

sentry() {
  heroku addons:create sentry
  echo 'gem "sentry-ruby"' >> Gemfile

  cat <<EOF> new_config.ru
require 'sentry-ruby'
Sentry.init do |config|
  config.traces_sample_rate = 1.0
end
EOF
  cat config.ru >> new_config.ru
  cp new_config.ru config.ru
}

deploy() {
  bundle install
  git commit -am 'Looks good :P' && git push heroku master
}

destroy() {
  rm Gemfile Gemfile.lock config.ru
  rm -rf .git
  rm -rf vendor
  heroku apps:destroy lvt-workflow-demo --confirm lvt-workflow-demo
  heroku apps:destroy lvt-workflow-demo-prd --confirm lvt-workflow-demo-prd
  heroku apps:destroy lvt-workflow-demo-stg --confirm lvt-workflow-demo-stg
}

update() {
  source ./script.sh
}

pipelines() {
  heroku pipelines:create lvt-workflow-demo -s development
  heroku create lvt-workflow-demo-stg #--remote stage
  heroku pipelines:add lvt-workflow-demo -a lvt-workflow-demo-stg -s staging
}

promote() {
  heroku pipelines:promote
}

rollback() {
  heroku releases:rollback -a lvt-workflow-demo-stg
}

releases() {
  # https://devcenter.heroku.com/articles/releases
  heroku releases
}

github() {
  # https://devcenter.heroku.com/articles/github-integration-review-apps
  git remote add origin git@github.com-lvt-paas-demo:lvt-mthorley/lvt-workflow-demo.git
  git push --set-upstream origin master
}

## Database 
#
## Redis
#
# heroku addons:create redistogo:nano
#
## Sentry
#
# heroku addons:create sentry:f1
#
## Pipelines - https://devcenter.heroku.com/articles/pipelines
#
#heroku pipelines:create -a thawing-cliffs-86575
#heroku pipelines:add pipeline-demo -a thawing-cliffs-staging
#heroku pipelines:add pipeline-demo -a thawing-cliffs-production
#
#heroku pipelines:info pipeline-demo
#
#heroku create thawing-cliffs-production --remote production
#heroku pipelines:promote -a thawing-cliffs-staging         
#
#heroku ps:scale web=0 -a thawing-cliffs-staging            
#heroku ps:scale web=0 -a thawing-cliffs-production         
