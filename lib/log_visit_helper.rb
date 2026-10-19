module LogVisitHelper

  def logVisit(user_agent, remote_ip, user_id, timestamp, record_class, record_id, rateable)
    ip_address = logIpAddress(user_agent, remote_ip, user_id, timestamp)
    return if record_id.nil? || ip_address.nil?
  
    record = record_class.to_s.safe_constantize&.find_by(id: record_id)
    return unless record
    record.register_visit_by(ip_address) if record.respond_to?(:register_visit_by)

    return unless rateable && user_id.present?

    # If the user is not the author then record statistics about how much they viewed the record
    user = User.find_by(id: user_id)
    return unless user
    record.register_view_by(user) if record.respond_to?(:register_view_by) && (!record.respond_to?(:user) || record.user != user)
  end

  # If there is a signed in user then record their id in the IpAddress record.
  # user_id is not nil if there is a signed in user.
  def logIpAddress(user_agent, remote_ip, user_id, timestamp)
    ip_address = IpAddress.find_by(address: remote_ip) # Seen this address yet?
    
    if ip_address.nil?
      ip_address = IpAddress.create(
        address: remote_ip,
        user_id: user_id,
        visit_count: 1,
        first_visit_at: timestamp,
        last_visit_at: timestamp,
        last_http_user_agent: user_agent
      )
    # Don't increment count if we have already counted this visit.
    elsif ip_address.last_visit_at != timestamp
      ip_address.visit_count += 1
      ip_address.last_visit_at = timestamp
      ip_address.user_id = user_id if user_id.present?
      ip_address.last_http_user_agent = user_agent
      ip_address.save
    else # This visit has already been logged so return nil
      ip_address = nil
    end
    ip_address
  end

end
