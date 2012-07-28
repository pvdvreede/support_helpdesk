# Majority of code in this file is taken from Redmine::POP3 module

require 'net/pop'

module Support
	module POP3
    class << self
  		def check(pop_options={})
  			host = pop_options[:host] || '127.0.0.1'
        port = pop_options[:port] || '110'
        apop = (pop_options[:apop].to_s == '1')
        pop = Net::POP3.APOP(apop).new(host, port)
        logger.debug "Connecting to #{host}:#{port}..." if logger && logger.debug?
        pop.start(pop_options[:username], pop_options[:password]) do |pop_session|
          if pop_session.mails.empty?
            logger.debug "No emails to fetch." if logger && logger.debug?
          else
            pop_session.each_mail do |mail|
              message = mail.pop
              message_id = (message =~ /^Message-I[dD]: (.*)/ ? $1 : '').strip
              logger.debug "Processing message with message id #{message_id}: #{message}" if logger && logger.debug?
              if SupportMailHandler.receive(message)
                true
              end
            end
          end
        end
      end

      private

      def logger
        ::Rails.logger
      end
    end
  end
end