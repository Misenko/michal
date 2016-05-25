require 'mongo'
require 'securerandom'

# MongoDB client
#
class Michal::DbClient
  attr_reader :mongo_client, :logger

  # Constructor
  #
  # @param [Logger] logger instance
  def initialize(logger)
    @logger = logger

    mongo_url = "#{Settings[:mongodb][:hostname]}:#{Settings[:mongodb][:port]}"
    mongo_db = "#{Settings[:mongodb][:database]}_#{ENV["RAILS_ENV"]}"
    user = "#{Settings[:mongodb][:user]}"
    password = "#{Settings[:mongodb][:password]}"
    @mongo_client = ::Mongo::Client.new([mongo_url], database: mongo_db, user: user, password: password)
  end

  # Writes data into collection
  #
  # @param [String] collection
  # @param [Hash] data
  # @return [String] id of inserted record
  def write_one(collection, data)
    result = mongo_client[collection].insert_one(data)
    fail Michal::Errors::DbClient::InsertError, result.inspect unless result.ok?

    result.inserted_id
  end

  # Updates selected records with specified method
  #
  # @param [String] collection
  # @param [Hash] find conditions
  # @param [Hash] update method
  # @param [Hash] additional options
  def update(collection, find, method, options={})
    mongo_client[collection].update_one(find, method, options)
  end

  # Updates selected records with specified method and returns them
  #
  # @param [String] collection
  # @param [Hash] find conditions
  # @param [Hash] update method
  # @param [Hash] additional options
  def update_and_return(collection, find, method, options={})
    mongo_client[collection].find_one_and_update(find, method, options)
  end

  # Reads one record from collection
  #
  # @param [String] collection
  # @param [Hash] find conditions
  # @param [Hash] additional options
  # @return [Hash] found record
  def read_one(collection, find, options={})
    mongo_client[collection].find(find, options).first
  end

  # Reads multiple record from collection
  #
  # @param [String] collection
  # @param [Hash] find conditions
  # @param [Hash] additional options
  # @return [Array] found records
  def read_many(collection, find, options={})
    mongo_client[collection].find(find, options)
  end

  # Runs aggregate function on collection
  #
  # @param [String] collection
  # @param [Array] aggregation operators
  # @return [Hash] result of aggregation functions
  def aggregate(collection, *operators)
    mongo_client[collection].aggregate(operators)
  end

  # Finds records and removes duplicate results
  #
  # @param [String] collection
  # @param [Hash] find conditions
  # @param [String] distinct record element
  # @return [Hash] found records
  def distinct(collection, find, distinct)
    mongo_client[collection].find(find).distinct(distinct)
  end

  # Deletes one record
  #
  # @param [String] collection
  # @param [Hash] find conditions
  def delete_one(collection, find)
    mongo_client[collection].delete_one(find)
  end

  # Copies content of one collection to another
  #
  # @param [String] from collection to copy from
  # @param [String] to collection to copy to
  def copy_collection(from, to)
    read_many(from, nil).each { |document| write_one(to, document) }
  end

  # Drops collection
  #
  # @param [String] collection
  def drop_collection(collection)
    mongo_client[collection].drop
  end
end
