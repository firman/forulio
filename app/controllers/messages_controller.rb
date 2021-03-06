class MessagesController < ApplicationController
  before_filter :login_required
  before_filter :admin_required, :only=>[:send_all]
  
  
  def index
    
    if params[:sent]
      conditions = ["sender_id = ?", current_user.id]
    else
      
      conditions = ["user_id = ?", current_user.id]
    end  
    @messages = Message.paginate(:page => params[:page], :per_page => 20, :conditions=>conditions, :order => "created_at DESC")
  end
  
  def last_conversation
    conditions = ["(sender_id = ? AND user_id = ?) OR (sender_id = ? AND user_id = ?)", params[:with_user], current_user.id, current_user.id, params[:with_user]]
    @messages = Message.find(:all, :conditions=>conditions, :limit => 50, :order => "created_at DESC")
    render :update do |page|
      page.replace_html 'conversation', :partial=>"messages/conversation", :locals=>{:messages=>@messages} 
    end
  end
  
  def delete
    message = Message.find_by_id(params[:id])
    return unless message.sender == current_user || message.user == current_user
    render :update do |page| 
         page << (message.destroy ? "Message.remove(#{message.id})" : "alert('%s')") % ["Message can not be deleted"[:message_can_not_be_deleted]]
    end
  end
  
  def send_message
    @to_user = User.find_by_id(params[:id])
    if request.post? && @to_user
      @message = Message.new(params[:message])
      @message.sender = current_user
      @message.user = @to_user
      if @message.save
        flash[:notice] = "Message sent"[:message_sent]
        @message.body=''
      end
    end
  end
  
  def send_all
    @to_user = nil
    if request.post?
      @message = Message.new(params[:message])
      if @message.valid?
        users = User.find(:all)
        users.each do |u|
          @message = Message.new(params[:message])
          @message.sender = current_user
          @message.user = u
          @message.save
        end
        @message.body=''
        flash[:notice] = "Message sent"[:message_sent]
      else  
      end
    end
    render :action=> 'send_message'
  end
  
  
  def hide
    message = Message.find_by_id(params[:id])
    if message.user == current_user
      message.update_attribute(:closed, true)
    end
    message_new = Message.find(:first, :conditions=>["user_id=? and closed < 1", current_user.id], :order=>"id DESC")
    render :update do |page|
       if message_new
          page.replace_html 'your_message', :partial=>"partials/message", :locals=>{:message=>message_new}
          page.visual_effect :Highlight,  'your_message', {:duration=>1.5}
       else
          page.visual_effect :Fade,  'your_message', {:duration=>0.5}
       end
    end
  end
  
end
