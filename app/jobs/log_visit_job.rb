class LogVisitJob < ApplicationJob
  queue_as :default
  include LogVisitHelper

  def perform(user_agent, remote_ip, user_id, timestamp, record_class, record_id, rateable)
    logVisit(user_agent, remote_ip, user_id, timestamp, record_class, record_id, rateable)
  end
end
