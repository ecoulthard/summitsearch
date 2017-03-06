class UserSweeper < ActionController::Caching::Sweeper
  observe User 

  def after_save(user)
    #This return statement is needed to prevent an error from blocking new users from signing in.
    return unless respond_to? :expire_fragment #expire_fragment is undefined if controller is nil

    #If user is on the front page then expire the front page users fragment
    if user.created_at >= User.order('created_at DESC').limit(9)[-1].created_at
      expire_fragment(:controller => '/main', :action => 'index', :part => 'users')
    end
  # If we update an existing user, the public list of updated users must be regenerated
    if user.created_at >= User.order('created_at DESC').limit(User.per_page)[-1].created_at
      expire_fragment(:controller=>"/users", :action=>"index")
      User::SORT_OPTIONS.keys.each do |sort|
        expire_fragment(:controller=>"/users", :action=>"index", :sort => sort)
      end
    end
  end

end
