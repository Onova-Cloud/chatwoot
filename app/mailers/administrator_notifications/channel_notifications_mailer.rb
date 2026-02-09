class AdministratorNotifications::ChannelNotificationsMailer < AdministratorNotifications::BaseMailer
  def facebook_disconnect(inbox)
    subject = 'La connessione alla tua pagina Facebook è scaduta'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def instagram_disconnect(inbox)
    subject = 'La tua connessione Instagram è scaduta'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def tiktok_disconnect(inbox)
    subject = 'La tua connessione TikTok è scaduta'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def whatsapp_disconnect(inbox)
    subject = 'La tua connessione WhatsApp è scaduta'
    send_notification(subject, action_url: inbox_url(inbox))
  end

  def email_disconnect(inbox)
    subject = 'La tua inbox email è stata disconnessa. Aggiorna le credenziali per SMTP/IMAP'
    send_notification(subject, action_url: inbox_url(inbox))
  end
end
