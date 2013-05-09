# Support Helpdesk

### Redmine plugin to handle incoming emails as Redmine issues

## Features

* Uses the excellent Ruote workflow engine with RuoteKit for bringing in emails. This gives you the ability to view and fix broken incoming emails.
* Rake daemon task to poll a POP3 mailbox.
* The ability to assign that issue to a project based on the domain name in the from email address.
* Send an email back to the email sender on issue creation and issue close.
* Automatically send an email to the email sender based on an issue note.
* Create custom email templates using ERB.
* Regular expessions to ignore emails from a certain address or with a certain subject.
* Administration GUI to create multiple support settings based on the sender's email address.

## Requirements

* Redmine 2.x.x
* Ruby MRI 1.9, it has not yet been tested on 2.0 or other Ruby implementations.
* **Currently Redis is required for Ruote persistence and it is assumed this is on the same host (this will to be configurable in a later version).**

## Installing

To install from scratch, clone this repository into the plugins directory of Redmine. You will then need to run `bundle install` in the root Redmine directory to bring in all the dependencies.

Then run `rake redmine:plugins:migrate` to add the required database tables.

The plugin comes with two rake tasks, these are both daemons and something like upstart should be used to run them along with your web server setup of choice. The rake commands to use for these are:

    rake support:fetch_pop_emails host=<email server host> port=<email server port> username=<email user> password=<email users password> every=<integer for how often in seconds the server should be checked>
    rake support:run_email_engine

The first one should be configurable from a file and this will be added in the future.

*If you are using **Unicorn** you will need to place the following in the `after_fork` method in your unicorn config for Ruote to use Redis across multiple processes:*

    RuoteKit.engine.storage.redis.client.reconnect

## Upgrading

## Running

The administration GUI is built into Redmine in the Administration section.

To check Ruote to see if there are any errored emails go to `/_ruote`. **WARNING: This is currently an unprotected site which will be secured to only allow Redmine admins in a later verion.**

## Roadmap

Consult the issues of this project to see what is on the Roadmap. Feel free to request any features you would like.

## Testing

## License

Support Helpdesk is licensed under the GNU GPLv3 license and is free to use and alter.

Pull requests are welcomed.
