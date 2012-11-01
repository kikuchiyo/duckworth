module Git::Emails
  def load_configuration
    config = YAML::load_file( './config/email.yml' )
    @email_from = config['authentication']['from']
    @email_password = config['authentication']['password']
    @email_mappings = config['users']
  end

  def send_gmail options
    load_configuration
    recipients = options[:recipients]
    msg = "Subject: #{options[:subject]}\n\n#{options[:message]}"
    smtp = Net::SMTP.new 'smtp.gmail.com', 587
    smtp.enable_starttls
    puts "Sending e-mail to #{recipients.join(',')}"
    smtp.start( '', @email_from, @email_password, :login ) do
      smtp.send_message( msg, @email_from, recipients.map{ |recipient| 
          # @email_mappings["#{recipient.gsub(' ', '_') }" ] 
          @email_mappings[ recipient ] 
      })
    end
  end
end


