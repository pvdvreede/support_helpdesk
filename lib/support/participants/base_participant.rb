class Support::Participants::BaseParticipant < Ruote::Participant

  private

  def email
    @email ||= Mail::Message.from_yaml(workitem.fields["email"])
  end

end
