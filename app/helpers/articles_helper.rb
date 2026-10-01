module ArticlesHelper

  def facebook_like_button
    raw "<div class=\"fb-like\" data-href=\"#{request.url}\" data-send=\"true\" data-width=\"450\" data-show-faces=\"true\"></div>"
  end

  def google_plus_button
    raw "<g:plusone annotation=\"inline\" callback=\"google_plus_clicked\" href=\"#{request.url}\"></g:plusone>"
  end

  def comments_path
    send "create_comment_#{article_type}_path", article
  end

  def thumbs_up_path
    send "thumbs_up_#{article_type}_path", article
  end

  def two_thumbs_up_path
    send "two_thumbs_up_#{article_type}_path", article
  end

  #assumes that @trip_report, @album or @photo is defined
  #Returns the instance variable for this article.
  def article
    controller.instance_variable_get("@#{article_type}")
  end

  def article_type
    controller.controller_name.singularize
  end
end
