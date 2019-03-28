# coding: utf-8
require 'bundler/setup'
require 'pathname'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'active_list'
dummy_path = Pathname.new(__FILE__).dirname.join('dummy')

ENV['BUNDLE_GEMFILE'] = ''
# Kernel.system("cd #{dummy_path} && bundle install && bundle exec rake db:drop db:create db:migrate db:seed RAILS_ENV=test")

# CURRENT FILE :: test/test_helper.rb
# Configure Rails Environment
ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] = dummy_path.to_s

require dummy_path.join('config', 'environment.rb')
require 'rails/test_help'

ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = 'test.com'

# Patch from https://github.com/rails/rails/issues/34790#issuecomment-450502805
if RUBY_VERSION >= '2.6.0'
  if Rails.version < '5'
    class ActionController::TestResponse < ActionDispatch::TestResponse
      def recycle!
        # hack to avoid MonitorMixin double-initialize error:
        @mon_mutex_owner_object_id = nil
        @mon_mutex = nil
        initialize
      end
    end
  else
    puts "Monkeypatch for ActionController::TestResponse no longer needed"
  end
end

module ActionView
  class Base
    module Nomen
      class Currencies
        def self.[](_)
          klass = Struct.const_defined?(:Currency) ? Struct::Currency : Struct.new('Currency', :precision, :symbol)
          klass.new(2, '€')
        end
      end
    end
  end
end

Rails.backtrace_cleaner.remove_silencers!

# Run any available migration
# ActiveRecord::Migrator.migrate(dummy_path.join("db", "migrate"))

# Load support files
# Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# TODO: Adds integration test
# TODO: Adds test on list with double join on same table
