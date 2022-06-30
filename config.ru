require 'sentry-ruby'
Sentry.init do |config|
  config.traces_sample_rate = 1.0
end
require 'active_record'
ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'postgres://localhost/mydb')

class Example < ActiveRecord::Base
end

run lambda { |env| env['REQUEST_PATH'] == '/' ? [200, {'Content-Type'=>'text/plain'}, StringIO.new("Hello #{Example.first.name}! Check out review apps\n")] : [404, {'Content-Type'=>'text/plain'}, StringIO.new("Not found\n")]}
