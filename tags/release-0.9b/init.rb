require 'redmine'

Redmine::Plugin.register :redmine_timesheet do
  name 'Timesheet'
  author 'Henrique Copelli Zambon and Bruno Tohio Sugano'
  description 'Indigo\'s Redmine Timesheet plugin'
  version '0.9b'
  menu :top_menu, :timesheet, { :controller => 'timesheet', :action => 'index' }, :caption => 'Timesheet', :if => Proc.new { User.current.logged? }
end
