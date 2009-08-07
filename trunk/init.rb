require 'redmine'

Redmine::Plugin.register :redmine_timesheet do
  name 'RedmineTimesheet'
  author 'Henrique Copelli Zambon and Bruno Toshio Sugano'
  description 'Indigo\'s Redmine Timesheet plugin'
  version '1.0-RC1'
  menu :top_menu, :timesheet, { :controller => 'timesheet', :action => 'index' }, :caption => 'Timesheet', :if => Proc.new { User.current.logged? }
end
