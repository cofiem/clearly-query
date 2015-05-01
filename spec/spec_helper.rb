require 'simplecov'

# start code coverage
SimpleCov.start

require 'active_record'
require 'sqlite3'
require 'logger'

include ActiveRecord::Tasks

require 'clearly-query'

# include supporting files
Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |file| require file }

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = [:expect]
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  app_root = File.expand_path('../..', __FILE__)
  rspec_root = File.join(app_root, 'spec')
  support_root = File.join(rspec_root, 'support')
  db_root = File.join(support_root, 'db')
  migrations_path = File.join(db_root, 'migrate')
  test_db_path = File.join(app_root, 'tmp', 'db', 'test.sqlite3')

  # if test database exists, delete it
  File.delete(test_db_path) if File.exist?(test_db_path)

  # configure database
  DatabaseTasks.env = 'test'
  DatabaseTasks.database_configuration = {
      'test' => {
          adapter: :sqlite3,
          database: test_db_path,
          pool: 5,
          timeout: 5000
      }
  }
  DatabaseTasks.db_dir = File.join rspec_root, 'db'
  #DatabaseTasks.fixtures_path = File.join root, 'test/fixtures'
  DatabaseTasks.migrations_paths = [migrations_path]
  #DatabaseTasks.seed_loader = Seeder.new File.join root, 'db/seeds.rb'
  DatabaseTasks.root = rspec_root

  # Set the logger for active record
  ActiveRecord::Base.logger = Logger.new(File.join('tmp', 'debug.activerecord.log'))

  # configure ActiveRecord database
  ActiveRecord::Base.configurations = DatabaseTasks.database_configuration

  # Connect to db for environment
  ActiveRecord::Base.establish_connection DatabaseTasks.env.to_sym

  # run migrations
  ActiveRecord::Migrator.migrate(migrations_path)

  #load 'active_record/railties/databases.rake'

end