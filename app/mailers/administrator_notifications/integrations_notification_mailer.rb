class AdministratorNotifications::IntegrationsNotificationMailer < AdministratorNotifications::BaseMailer
  def slack_disconnect
    subject = 'La tua integrazione Slack è scaduta'
    action_url = settings_url('integrations/slack')
    send_notification(subject, action_url: action_url)
  end

  def dialogflow_disconnect
    subject = 'La tua integrazione Dialogflow è stata disconnessa'
    send_notification(subject)
  end
end
