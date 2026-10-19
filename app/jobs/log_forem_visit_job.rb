class LogForemVisitJob < ApplicationJob
  queue_as :default
  # Compatibility sink for jobs queued before cutover. Keep the class until
  # old queues/retries have drained; retired tracking must not mutate history.
  def perform(*)
  end
end
