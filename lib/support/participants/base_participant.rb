class Support::Participants::BaseParticipant < Ruote::Participant

  private

  def email
    @email ||= Mail::Message.from_yaml(workitem.fields["email"])
  end

  def cancel_workflow
    Support.log_info("Email #{email.message_id} workflow is being cancelled from #{participant_name} participant.")
    workitem.fields['cancel'] = true
  end

end
