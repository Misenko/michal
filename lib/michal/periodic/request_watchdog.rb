# Markes finished jobs when their data is available
#
class Michal::Periodic::RequestWatchdog
  # Checks status of waiting requests
  #
  def update_finished_requests
    unfinished_requests = Statistic.where(ready: false)
    unfinished_requests.each do |request|
      request_document_id = request[:_id]

      num_of_waiting = Waiting.where(statistic: request).count
      ready_request(request_document_id) if num_of_waiting == 0
    end
  end

  private

  # Mark request with given id as finished
  #
  # @param [String] request_document_id
  def ready_request(request_document_id)
    request = Statistic.find(request_document_id)
    request.update(ready: true, last_update: Time.now)
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
