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
    Support::POP3.check(pop_options)
  end
end