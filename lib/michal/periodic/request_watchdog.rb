# Markes finished jobs when their data is available
#
class Michal::Periodic::RequestWatchdog
  attr_reader :db_client

  def initialize
    @db_client = Michal::DbClient.new logger
  end

  # Checks status of waiting requests
  #
  def update_finished_requests
    unfinished_requests = db_client.read_many(:statistics, {ready: false})
    unfinished_requests.each do |request|
      request_document_id = request[:_id]

      waiting = db_client.read_many(:waiting, {request_id: BSON::ObjectId(request_document_id)})
      ready_request(request_document_id) if waiting.count == 0
    end
  end

  private

  # Mark request with given id as finished
  #
  # @param [String] request_document_id
  def ready_request(request_document_id)
    request = db_client.update_and_return(:statistics, {_id: BSON::ObjectId(request_document_id)}, {"$set" => {ready: true, last_update: Time.now}}, { upsert: true })
    request_url = request[:url]
    email = request[:email]

    send_email(email, request_url) unless email.blank?
  end

  # Sends email notification
  #
  # @param [String] email address
  # @param [String] url of computed statisatic
  def send_email(email, url)
    NotificationMailer.statistics_ready_email(email, url).deliver
  end
end
