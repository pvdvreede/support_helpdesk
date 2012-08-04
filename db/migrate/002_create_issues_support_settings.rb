class CreateIssuesSupportSettings < ActiveRecord::Migration
  def change
    create_table :issues_support_settings do |t|
      t.integer :issue_id
      t.integer :support_helpdesk_setting_id

      t.timestamps
    end
  end
end
