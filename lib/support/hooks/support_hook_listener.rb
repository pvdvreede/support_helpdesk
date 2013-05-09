# Support Helpdesk - Redmine plugin
# Copyright (C) 2012 Paul Van de Vreede
#
# This file is part of Support Helpdesk.
#
# Support Helpdesk is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Support Helpdesk is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Support Helpdesk.  If not, see <http://www.gnu.org/licenses/>.

module Support
  module Hooks
    class SupportHookListener < Redmine::Hook::ViewListener

      def view_issues_edit_notes_bottom(context={})
        issue = context[:issue]
        return unless issue.support_helpdesk_setting.nil?

        supports, trackers = get_trackers_for_support()
        return unless trackers.include? issue.tracker_id 


        context[:controller].send(:render_to_string, {
            :partial => "issues/support_type_option",
            :locals => { :issue => issue, :supports => supports}
          })
      end

      def controller_issues_edit_before_save(context={})
        return if context[:params][:support].nil?
        
        unless context[:params][:support][:id].nil?
          new_support_id = context[:params][:support][:id]
          issue = context[:issue]

          # get the support
          support = SupportHelpdeskSetting.find new_support_id
          
          issue.support_helpdesk_setting = support
          issue.support_type = support.name
        end
      end

      private
      def get_trackers_for_support
        supports = SupportHelpdeskSetting.active
        # return array of tracker ids to check against.
        trackers = supports.map { |x| x.tracker_id }
        return supports, trackers
      end

    end
  end
end