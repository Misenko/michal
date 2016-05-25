require 'sidekiq'
require 'sidekiq-status'

def redis_options
  options = {}

  options[:namespace] = Settings[:redis][:namespace]
  options[:url] = Settings[:redis][:url]

  if Settings[:redis][:password]
    options[:url].insert(options[:url].index('/') + 2, ":#{Settings[:redis][:password]}@")
  end

  options
end

Sidekiq::Logging.logger = Logger.new(STDOUT)
Sidekiq::Logging.logger.level = Logger::DEBUG
Sidekiq.configure_client do |config|
  options = redis_options
  options[:size] = 1
  config.redis = options
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware
  end
end
Sidekiq.configure_server do |config|
  config.redis = redis_options
  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 30.minutes # default
  end
  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware
  end
end
