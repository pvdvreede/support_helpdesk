# Support Helpdesk

## Redmine plugin that generates issues from normal emails.

### Functionalities

Support Helpdesk provides the following functionalities:

* Rake task to poll a POP3 mailbox, bring in emails addressed to user specified addresses and create issues of a specified tracker
* The ability to assign that issue to a project based on the domain name in the from email address
* Assign the issue to members of a particular group in a round robin fashion
* Send an email back to the email sender on issue creation and issue close
* Automatically send an email to the email sender based on an issue note
* Administration GUI to create multiple support settings based on the sender's email address, including:
  * Custom email templates (in erb format)
  * Your sender email address
  * Whether or not to send a creation or closing email

### Installation

The plugin is a standard Redmine 2.x plugin and so will work with Redmine 2.0.0 and above. Simply download the code and put it in the redmine plugins directory. Then run

    rake redmine:plugins:migrate

to populate the database tables into the Redmine database.

There will now be a rake task as `rake support:fetch_pop_emails host=<mail host address> port=<mail host port number> username=<pop3 login> password=<pop3 password>`. Use this command to set a cron job for how often you would like the mailbox polled.

Once setup, navigate to <redmine url>/support/settings to add support settings so the plugin will start to pickup emails and add them as issues.

### License

Support Helpdesk is licensed under the GNU GPLv3 license and is free to use and alter. 

Pull requests are welcomed.