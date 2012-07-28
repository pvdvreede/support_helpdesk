class AddNewTracker < ActiveRecord::Migration
  def change
    tracker = Tracker.new :name => "Ticket", :is_in_chlog => 0, :is_in_roadmap => 0, :position => 4
    tracker.save
    reply = IssueCustomField.new :name => "Reply Address", :is_required => 0, :field_format => "string", \
                                  :searchable => 1, :trackers => [tracker], :max_length => 0, :min_length => 0
    reply.save
  end
end