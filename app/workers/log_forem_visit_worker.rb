#Logs a visit to a particular record such as a place or route.
class LogForemVisitWorker
  include Sidekiq::Worker
  include LogVisitHelper

  #Log the ip address then log the visit of the record if 

  def perform(user_agent, remote_ip, user_id, timestamp, record_class, record_id)
    logForemVisit(user_agent, remote_ip, user_id, timestamp, record_class, record_id)
  end

end
