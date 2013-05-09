class Support::Workflow

  def initialize(engine)
    @engine = engine
    register_participants
  end

  def register_participants
    participants.each do |const|
      @engine.register_participant const.to_s.underscore.split("/").last, const
    end
  end

  def send_created_email(issue, to)
    pdef = Ruote.define "support_helpdesk send closing email" do
      sequence do
        send_email :template => 'ticket_created'
        add_outgoing_email_attachment
      end
    end
    fields = {
      'related_issue'          => issue.attributes,
      'outgoing_email_to'      => to,
      'support_settings'       => issue.support_helpdesk_setting.attributes
    }
    @engine.launch(pdef, fields)
  end

  def send_closing_email(issue, to)
    pdef = Ruote.define "support_helpdesk send creating email" do
      sequence do
        send_email :template => 'ticket_closed'
        add_outgoing_email_attachment
      end
    end
    fields = {
      'related_issue'          => issue.attributes,
      'outgoing_email_to'      => to,
      'support_settings'       => issue.support_helpdesk_setting.attributes
    }
    @engine.launch(pdef, fields)
  end

  def send_question_email(issue, to, question)
    pdef = Ruote.define "support_helpdesk send creating email" do
      sequence do
        send_email :template => 'user_question'
        add_outgoing_email_attachment
      end
    end
    fields = {
      'related_issue'          => issue.attributes,
      'outgoing_email_to'      => to,
      'support_settings'       => issue.support_helpdesk_setting.attributes,
      'outgoing_email_opts'    => { :question => question }
    }
    @engine.launch(pdef, fields)
  end

  def receive_email(email)
    pdef = Ruote.define(:name => "receive_email", :version => "2.0") do
      sequence do

        get_global_settings
        get_support_settings
        terminate :if => "${f:cancel} == true"

        check_from_exclusions
        check_subject_exclusions
        terminate :if => "${f:cancel} == true"

        search_current_issue
        create_issue_body

        # when the issue already exists
        _if "${f:related_issue} is set" do
          sequence do
            update_support_issue
            add_email_attachment
          end
        end

        # when this is a new issue
        _if "${f:related_issue} is not set" do
          sequence do
            set_email_reply
            search_project
            create_support_issue
            add_email_attachment
            # only send out an email to the user if its in the settings
            _if "${f:support_settings.send_created_email_to_user}" do
              sequence do
                send_email :template => 'ticket_created',
                           :outgoing_email_to => "${f:email_reply_to}"
                add_outgoing_email_attachment
              end
            end
          end
        end

        create_support_message_id
      end
    end

    fields = {
      'email'   => email.to_yaml,
      :wfid     => email.message_id
    }

    @engine.launch(pdef, fields)
  end

  def participants
    Support::Participants.constants.select do |p|
      pc = Support::Participants.const_get(p)
      pc.is_a?(Class) &&
        pc.ancestors[1..3].include?(Support::Participants::BaseParticipant)
    end.map { |p| Support::Participants.const_get(p) }
  end

end
