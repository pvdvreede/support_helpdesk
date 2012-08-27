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

namespace :support do
	desc <<-END_DESC
Pick up emails from POP3 server and process them into support tickets.
END_DESC
  task :fetch_pop_emails => :environment do
    options = {}
    pop_options = {}
    pop_options[:host] = ENV['host'] if ENV['host']
    pop_options[:port] = ENV['port'].to_i if ENV['port']
    pop_options[:username] = ENV['username'] if ENV['username']
    pop_options[:password] = ENV['password'] if ENV['password']
    Support::POP.check(pop_options)
  end
end