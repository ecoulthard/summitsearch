# Public: Provide server-side preview of editor markup
#
class MarkitupController < ApplicationController
  #layout Markitup::Rails.configuration.layout

  def preview
    @content = params[:data]#Markitup::Rails.configuration.formatter.call(params[:data])
    respond_to do |format|
      format.html { render :layout => false }
      format.xml  { render :xml => @content }
    end
  end
end
