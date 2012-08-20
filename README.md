# Support Helpdesk

## Redmine plugin that generates issues from normal emails.

### Functionalities

Support Helpdesk provides the following functionalities:

* Rake task to poll a POP3 mailbox, bring in emails addressed to user specified addresses and create issues of a specified tracker
* The ability to assign that issue to a project based on the domain name in the from email address
* Send an email back to the email sender on issue creation and issue close
* Automatically send an email to the email sender based on an issue note
* Administration GUI to create multiple support settings based on the sender's email address, including:
  * Custom email templates (in erb format)
  * Your sender email address
  * Whether or not to send a creation or closing email
  * Specify bcc email addresses for outgoing emails
  * Add email domains to ignore

You can also get round robin assigning of issues from a group with the Round Robin plugin. See [Round Robin - Redmine Plugin](https://github.com/pvdvreede/round_robin).

### Requirements

Support Helpdesk requires Redmine 2.0.0 or later. It is not compatible with Redmine 1.x.

### Installation

The plugin is a standard Redmine 2.x plugin and so will work with Redmine 2.0.0 and above. Simply download the code and put it in the redmine plugins directory. Then run:

    rake redmine:plugins:migrate

to populate the database tables into the Redmine database.

There will now be a rake task available:

    rake support:fetch_pop_emails host=<host> port=<port> username=<login> password=<pop3 password>
   
Use this command to set a cron job for how often you would like the mailbox polled.

Once setup, a new option will appear in the administration menu called `Support Helpdesk`. From here you can setup support settings for which emails to bring in, what templates to use, and which tracker and projects to create the issues in.

### License

Support Helpdesk is licensed under the GNU GPLv3 license and is free to use and alter. 

Pull requests are welcomed.