class ReportController < ApplicationController
  unloadable

  def index
    @projects = Project.find(:all, :order => 'name', :conditions => Project.visible_by(User.current))
    @enumerations = Enumeration.find(:all, :order => 'name', :conditions => { :opt => "ACTI" })
    @users = User.find(:all, :order => 'firstname')
    
    render :action => 'index', :layout => false if request.xhr?
  end
  
  def build_report
    
    filter = params[:filter]
    group = params[:group]
    args = Hash.new
    
    session[:timesheet_report_filter] = filter
    session[:timesheet_report_group] = group
    
    ## Setting filter conditions
    if(filter[:data].to_i != 0) then
      args[:where_data] = filter[:data]
      args[:where_data_month] = filter[:data].to_i.modulo(100)
      args[:where_data_year] = filter[:data].to_i / 100    
      puts args[:where_data_month]
      puts args[:where_data_year]
    end
    args[:where_project_id] = filter[:project] if filter[:project] != "" && filter[:project] != 0
    args[:where_user_id] = filter[:user] if filter[:user] != "" && filter[:user] != 0
    args[:where_activity_id] = filter[:activity] if filter[:activity] != "" && filter[:activity] != 0
    
    # Setting grouping
    if(group[:type]) then
      groups = Array.new(4)
      i = 0
      @columns = Array.new(group[:type].length)
      group[:type].values.each do |grouping| 
        groups[i] = grouping.downcase 
        @columns[i] = grouping 
        i += 1
      end      
      args[:groupings] = groups
    else
      @columns = []
    end
    
    # Getting the results
    @results = Timesheet.consolidate_data(args)
    
    # Calculate the total hours
    @total = 0
    @results.each do |result|
      @total += result.Hours.to_f
    end
    
    
    respond_to do |format|
      format.html
      format.js do
        render :update do |page|
          page.replace_html('results', :partial => 'result', :locals => {:columns => @columns, :results => @results, :total => @total})
        end
      end
    end
  end
  
  def export_to_excel
    
    # Setting the headers to respond in xls format
    headers['Content-Type'] = "application/vnd.ms-excel"
    headers['Content-Disposition'] = 'attachment; filename="report.xls"'
    headers['Cache-Control'] = ''
    
    # Get the last filter and grouping condition -- I don't like this, perhaps there might be some better way to get the last query conditions
    filter = session[:timesheet_report_filter]
    group = session[:timesheet_report_group]
    args = Hash.new
    
    ## Setting filter conditions
    if(filter[:data].to_i != 0) then
      args[:where_data] = filter[:data]
      args[:where_data_month] = filter[:data].to_i.modulo(100)
      args[:where_data_year] = filter[:data].to_i / 100    
      puts args[:where_data_month]
      puts args[:where_data_year]
    end
    args[:where_project_id] = filter[:project] if filter[:project] != "" && filter[:project] != 0
    args[:where_user_id] = filter[:user] if filter[:user] != "" && filter[:user] != 0
    args[:where_activity_id] = filter[:activity] if filter[:activity] != "" && filter[:activity] != 0
    
    # Setting grouping
    if(group[:type]) then
      groups = Array.new(4)
      i = 0
      @columns = Array.new(group[:type].length)
      group[:type].values.each do |grouping| 
        groups[i] = grouping.downcase 
        @columns[i] = grouping 
        i += 1
      end      
      args[:groupings] = groups
    else
      @columns = []
    end
    
    # Getting the results
    @results = Timesheet.consolidate_data(args)
    
    # Calculate the total hours
    @total = 0
    @results.each do |result|
      @total += result.Hours.to_f
    end
    
    render :layout => false
  end

  def show_timesheet
    
    filter = params[:filter]
    @month = filter[:data].to_i % 100
    @user = filter[:user].to_i
    
    @results = Timesheet.user_current_month_timesheet @user, @month
    
    respond_to do |format|
      format.html
      format.js do
        render :update do |page|
          page.replace_html('timesheets', :partial => 'timesheet', :locals => {:results => @results, :month => @month, :user => @user})
        end
      end
    end
    
  end
  
  def timesheet_export_to_excel
     headers['Content-Type'] = "application/vnd.ms-excel"
     headers['Content-Disposition'] = 'attachment; filename="timesheet.xls"'
     headers['Cache-Control'] = ''

     @month = params[:month]
     @user = params[:user]
     @username = User.current.name
     
     @timesheets = Timesheet.user_current_month_timesheet @user, @month
     
     render :layout => false
   end

end
