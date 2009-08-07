class CreateTimesheets < ActiveRecord::Migration
  def self.up
    create_table :timesheets do |t|
      t.column      :id, :int
      t.references  :user, :null => false
      t.column      :date, :datetime, :null => false
      t.references  :project, :null => false
      t.column      :begin, :time, :null => false
      t.column      :end, :time, :null => false
      t.column      :minutes, :int, :null => false
      t.references  :enumeration, :null => false
      t.references  :issue
      t.column      :obs, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :timesheets
  end
end
