class Timesheet < ActiveRecord::Base
  
  validates_presence_of :user, :date
  
  validates_presence_of :project, :message => "Project can\'t be blank."
  validates_presence_of :begin, :message => "Can\'t be blank."
  validates_presence_of :end, :message => "Can\'t be blank."
  validates_presence_of :enumeration, :message => "Activity can\'t be blank."
  #validates_presence_of :issue, :message => "Issue can\'t be blank."
  validate :end_greater_then_begin, :if => Proc.new { |t| t.begin != nil && t.end != nil }
  #validate :new_begin_greater_then_old_end, :if => Proc.new { |t| t.begin != nil && t.date != nil }
  validate :violates_interval, :if => Proc.new { |t| t.begin != nil && t.end != nil && t.date != nil }
  
  
  def end_greater_then_begin
    errors.add_to_base("Ending time must be greater then begining time.") unless self.end > self.begin
  end
  
  def new_begin_greater_then_old_end
    # In case of an existing timesheet, find all CREATED BEFORE
    if !self.id.nil?
      t = Timesheet.find(:all, :order => "id DESC", :conditions =>  [ "user_id = ? AND date = ? AND id <= ?", User.current.id, self.date, self.id ])
      return true unless t.count > 1
      t = t[1]
      
    # If case of a new timesheet, find all
    else
      t = Timesheet.find(:all, :order => "id DESC", :conditions => { :user_id => User.current.id, :date => self.date })
      return true unless !t.empty?
      t = t[0]
      
    end
    
    self_minutes = self.begin.hour*60 + self.begin.min
    t_minutes = t.end.hour*60 + t.end.min
    
    if (t_minutes > self_minutes)  
      errors.add_to_base("Begining time must be greater then the last line's ending time")
      return false
    else
      return true
    end
  end
  
  def violates_interval
    if self.id.nil?
      i = 0
    else
      i = self.id
    end
    
    #t = Timesheet.find(:all, :conditions => ["user_id = ? AND id != ? AND ((begin < ? AND end > ?) OR (begin < ? AND end > ?))", User.current.id, i, self.begin, self.begin, self.end, self.end])
    t = Timesheet.find(:all, :conditions => ["user_id = ? AND id != ? AND date = ? AND (((begin < ? AND end > ?) OR (begin < ? AND end > ?)) OR (begin > ? AND end < ?) OR (begin = ? OR end = ?))", User.current.id, i, self.date, self.begin, self.begin, self.end, self.end, self.begin, self.end, self.begin, self.end])
    
    return true unless !t.empty?
    errors.add_to_base("Given interval overlaps another entry")
    return false
  end
  
  def self.consolidate_data(args)
    
    sql = " SELECT "
    
    # GROUP BY statement require fields in the SELECT statement
    if(args[:groupings]) then
      args[:groupings].each{ |group|  
        sql += " p.name as Project, " if group == "project"
        sql += " CONCAT_WS(' ', u.firstname, u.lastname) as User, " if group == "user"
        sql += " e.name as Activity, " if group == "activity"
        sql += " case when i.subject is not null then i.subject else 'Not related to any issue' end as Issue, " if group == "issue"
      }
    end
    
    sql += " sum(t.minutes)/60 as Hours, \"0\" as foo "
    sql += " FROM timesheets t inner join enumerations e on t.enumeration_id = e.id "
    sql += " left join issues i on t.issue_id = i.id "
    sql += " inner join projects p on t.project_id = p.id "
    sql += " inner join users u on t.user_id = u.id "
    sql += " WHERE 1=1 "
    
    # WHERE statement
    
    sql += " and p.id = " + sanitize_sql(args[:where_project_id].to_s)  if !args[:where_project_id].nil? && args[:where_project_id] != ""
    sql += " and u.id = " + sanitize_sql(args[:where_user_id].to_s)  if !args[:where_user_id].nil? && args[:where_user_id] != ""
    sql += " and e.id = " + sanitize_sql(args[:where_activity_id].to_s) if !args[:where_activity_id].nil? && args[:where_activity_id] != ""
    sql += " and MONTH(t.date) = " + sanitize_sql(args[:where_data_month].to_s) if !args[:where_data_month].nil? && args[:where_data_month].to_i != 0
    sql += " and YEAR(t.date) = " + sanitize_sql(args[:where_data_year].to_s) if !args[:where_data_year].nil? && args[:where_data_year].to_i != 0
    
    # GROUP BY statement
    sql += " GROUP BY foo " unless args[:groupings] == nil || args[:groupings].length == 0
    
    if(args[:groupings]) then
      args[:groupings].each{ |group|  
        sql += " , p.name " if group == "project"
        sql += " , User " if group == "user"
        sql += " , e.name " if group == "activity"
        sql += " , i.subject " if group == "issue"
      }
    end
    
    puts sql
    
    return find_by_sql(sql)
  end
  
  def self.user_current_month_timesheet(user, month)
    sql = "select t.date as date, p.name as projectname, t.begin as begin, t.end as end, t.minutes as total, e.name as activity, t.issue_id as issuenumber, t.obs as obs"
    sql += " from timesheets t inner join projects p on t.project_id = p.id inner join enumerations e on t.enumeration_id = e.id "
    sql += " where MONTH(t.date) = " + sanitize_sql(month).to_s
    sql += " AND t.user_id = " + sanitize(user).to_s
    sql += " order by t.date ASC, t.begin ASC "
    return find_by_sql(sql)
  end
  
  belongs_to :user

  belongs_to :project

  ## Activities for time tracking
  belongs_to :enumeration
  
  belongs_to :issue
  
end
