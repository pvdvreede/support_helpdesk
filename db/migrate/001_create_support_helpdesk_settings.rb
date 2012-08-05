class CreateSupportHelpdeskSettings < ActiveRecord::Migration
  def change
    create_table :support_helpdesk_settings do |t|
      t.string    :name, :null => false
      t.integer   :project_id, :null => false
      t.integer   :email_domain_custom_field_id
      t.integer   :author_id, :null => false
      t.integer   :assignee_group_id, :null => false
      t.integer   :new_status_id, :null => false
      t.string    :to_email_address, :null => false
      t.string    :from_email_address, :null => false
      t.integer   :tracker_id, :null => false
      t.integer   :reply_email_custom_field_id, :null => false
      t.integer   :type_custom_field_id, :null => false
      t.string    :created_template_name, :null => false
      t.string    :closed_template_name, :null => false
      t.string    :question_template_name, :null => false
      t.boolean   :send_created_email_to_user, :null => false
      t.boolean   :send_closed_email_to_user, :null => false
      t.integer   :last_assigned_user_id
      t.boolean   :active,:null => false, :default => true
      t.datetime  :last_run

      t.timestamps
    end
  end
end
