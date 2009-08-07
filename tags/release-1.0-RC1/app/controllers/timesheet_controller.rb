class TimesheetController < ApplicationController
  unloadable
  
  def index
    @username = User.current.name
    @related_projects = User.current.projects.collect {|project| project.id}
    calendar(Date.today.month, Date.today.year)
    timesheets_parent
  end
  
  ## Render calendar
  def calendar(month, year)
    @month = month
    @year = year
    @month_name = Date.new(year, month).strftime('%B')
        
    ## count = 1 - "month's first wday (week day)"
    ## counter used to print the correct days in calendar
    @count = 1 - Date.new(year, month, 1).wday
    
    @lastday = Date.new(year, month, -1).mday
    @today = Date.today
  end
  
  ## Change current calendar's month and/or year
  def refresh_calendar
    new_month = params[:new_month].to_i
    new_year = params[:new_year].to_i
    
    if new_month == 0
      new_month = 12
      new_year -= 1
    elsif new_month == 13
      new_month = 1
      new_year += 1
    end
    
    calendar(new_month, new_year)
    
    respond_to do |format|
      format.html
      format.js do
        render :update do |page|
          page.replace('calendar_container', :partial => 'calendar', :locals => {:month => new_month, :year => new_year})
        end
      end
    end
  end

  ## Render the timesheets header partial
  def timesheets_parent
    
  end
  
  ## Render one timesheet
  def timesheet
    
  end
  
  def new_timesheet_params
    @projects = Project.find(:all, :order => 'name ASC', :conditions => Project.visible_by(User.current))    
    @enumerations = Enumeration.find(:all, :order => 'name ASC', :conditions => { :opt => "ACTI" })
    @issues = Issue.find(:all)
    @date = params[:date]
    @new_timesheet_id = (rand*100000).to_i.to_s
  end
  
  ## Render all timesheets from the current user by date by replacing and inserting partials
  def refresh_timesheets
    date = params[:date]
    @date = date
    datestr = params[:datestr]
    timesheets = Timesheet.find(:all, :order => "begin ASC", :conditions => {:user_id => User.current.id, :date => date})
    new_timesheet_params
    
    respond_to do |format|
      format.html
      format.js do
        render :update do |page|
          page.replace_html('timesheets_parent', :partial => 'timesheets_parent', :locals => {:display => "block", :date => date, :datestr => datestr})
          timesheets.each do |t|
            page.insert_html('bottom', 'add_here', :partial => 'timesheet', :locals => {:timesheet => t, :action => "retrieve"})
          end
          page.insert_html('bottom', 'add_here', :partial => 'timesheet', :locals => {:action => "new"})
        end
      end
    end
  end
  
  def new_timesheet
    new_timesheet_params
    respond_to do |format|
      format.html
      format.js do
        render :update do |page|
          page.insert_html('bottom', 'add_here', :partial => 'timesheet', :locals => {:action => "new"})
        end
      end
    end
  end
  
  ## Saves OR updates a timesheet
  def save_timesheet
    timesheet_id = params[:timesheet_id].to_i
    new_timesheet_id = params[:new_timesheet_id]
    
    # If timesheet_id is null, we have a new timesheet
    if timesheet_id == 0
      t = Timesheet.new
      t.user_id = User.current.id
      t.date = Time.parse(params[:date])
      element_id = "new_timesheet_" + new_timesheet_id
      validation_error_element_id = "validation_error_" + new_timesheet_id
    # In case of an existing timesheet (edit), timesheet_id.to_i returns its id
    else
      t = Timesheet.find(:first, :conditions => { :id => timesheet_id })
      element_id = "edit_timesheet_" + t.id.to_s
      validation_error_element_id = "validation_error_" + t.id.to_s
    end
    
    t.project_id = params[:project_id].to_i
    
    if params[:tbegin] != ""
      t.begin = Time.parse(params[:tbegin])
    else
      t.begin = nil
    end
    
    if params[:tend] != ""
      t.end = Time.parse(params[:tend])
    else
      t.end = nil
    end
    
    t.enumeration_id = params[:enumeration_id].to_i
    t.issue_id = params[:issue_id].to_i
    t.obs = params[:obs]
    
    if t.valid?
      t.minutes = ((t.end - t.begin)/60).to_i
      t.save
      
      day_element = "day_" + t.date.day.to_s
      
      respond_to do |format|
        format.html
        format.js do
          render :update do |page|
            page.replace(element_id, :partial => 'timesheet', :locals => { :timesheet => t, :action => 'retrieve'})
            page.replace_html(day_element, :partial => 'day', :locals => { :day => t.date.day.to_s, :today => t.date })
            page.visual_effect :highlight, day_element
          end
        end
      end
    else
      respond_to do |format|
        format.html
        format.js do
          render :update do |page|
            page.replace_html(validation_error_element_id, :partial => 'validation_error', :locals => { :timesheet => t, :errors => t.errors })
          end
        end
      end
    end
  end
  
  def retrieve_timesheet
    timesheet_id = params[:timesheet_id]
    t = Timesheet.find(:first, :conditions => { :id => timesheet_id.to_i })
    @timesheet = t
    
    respond_to do |format|
      format.html
      format.js do
        render :update do |page|
          page.replace('edit_timesheet_' + timesheet_id, :partial => 'timesheet', :locals => { :timesheet => t, :action => "retrieve"})
        end
      end
    end
  end
  
  def edit_timesheet
    timesheet_id = params[:timesheet_id]
    t = Timesheet.find(:first, :conditions => { :id => timesheet_id.to_i })
    
    @projects = Project.find(:all, :order => 'name ASC', :conditions => Project.visible_by(User.current))    
    @enumerations = Enumeration.find(:all, :order => 'name ASC', :conditions => { :opt => "ACTI" })
    @issues = Issue.find(:all, :conditions => ["project_id = ?", t.project_id])
    @date = params[:date]
    
    respond_to do |format|
      format.html
      format.js do
        render :update do |page|
          page.replace('retrieve_timesheet_' + timesheet_id, :partial => 'timesheet', :locals => { :timesheet => t, :action => "edit"})
        end
      end
    end
  end
  
  def delete_timesheet
    timesheet_id = params[:timesheet_id].to_i
    t = Timesheet.find(:first, :conditions => { :id => timesheet_id })

    day = t.date.day.to_s
    today = t.date
    day_element = "day_" + day

    t.destroy
    
    respond_to do |format|
      format.html
      format.js do
        render :update do |page|
          page.remove('retrieve_timesheet_' + timesheet_id.to_s)
          page.replace_html(day_element, :partial => 'day', :locals => { :day => day, :today => today })
          page.visual_effect :highlight, day_element
        end
      end
    end
  end
  
  def export_to_excel
    headers['Content-Type'] = "application/vnd.ms-excel"
    headers['Content-Disposition'] = 'attachment; filename="timesheet.xls"'
    headers['Cache-Control'] = ''
    
    month = params[:month].to_i unless params[:month].nil?
    
    @timesheets = Timesheet.user_current_month_timesheet User.current.id, month
    @user = User.current.name
    
    render :layout => false
  end
  
  def get_issues
    project_id = params[:project_id].to_i
    element_id = params[:element_id].to_s
    timesheet_id = params[:id].to_i
    
    @timesheet = timesheet_id == 0 ? nil : Timesheet.find(:first, :conditions => {:id => timesheet_id})
    @issues = Issue.find(:all, :order => 'fixed_version_id', :conditions => ['project_id = ?', project_id])
    
    respond_to do |format|
      format.html
      format.js do
        render :update do |page|
          page.replace_html(element_id, :partial => 'select', :locals => {:issues => @issues, :timesheet => @timesheet})
        end
      end
    end
  end
  
end
