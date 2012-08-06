# Majority of code in this file is taken from Redmine::POP3 module

require 'net/pop'

module Support
	module POP3
    class << self
  		def check(handler, pop_options={})
  			host = pop_options[:host] || '127.0.0.1'
        port = pop_options[:port] || '110'
        apop = (pop_options[:apop].to_s == '1')
        pop = Net::POP3.APOP(apop).new(host, port)
        Support.log_info "Connecting to #{host}:#{port}..."
        pop.start(pop_options[:username], pop_options[:password]) do |pop_session|
          if pop_session.mails.empty?
            Support.log_info "No emails to fetch."
          else
            pop_session.each_mail do |mail|
              message = mail.pop
              message_id = (message =~ /^Message-I[dD]: (.*)/ ? $1 : '').strip
              Support.log_info "Processing message with message id #{message_id}..."
              # convert message into rails mail object
              mail_obj = Mail.new message
              if handler.receive(mail_obj)
                mail.delete
                Support.log_info "Message #{message_id} processed and deleted from the mailbox."
              end
            end
          end

          # add time of last run to all active support settings
          SupportHelpdeskSetting.update_all(
            {:last_run => Time.now.utc},
            {:active => true}
            )
        end
      end

    end
  end
end