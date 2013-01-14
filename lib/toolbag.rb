module Toolbag

  module Parses
    def found_pending_marker line
      line.match( /^[\s\t]*Pending:/ )
    end

    def found_new_spec_marker line, status
      ( status == 'start' || status == 'updating spec data' ) && !line.match( /^[\s\t]*#/ )
    end

    def found_spec_details_marker line, status
      ( status == 'found new pending spec' || status == 'updating spec data' ) && line.match( /^[\s\t]*\#/ )
    end
  end

  module Searches
    def search
      @tasks.each_pair do |key, attributes|
        contributors = []
        `git blame "#{attributes[:spec_file]}"`.each do |blame|
          contributor = blame.split(")")[0].split("(")[1]
          contributor = contributor.split(/\s+\d/)[0]
          contributors.push( contributor )
        end
        @tasks[key][:contributors] = contributors.uniq
        @tasks[key][:contributors].reject!{ |contributor| contributor == 'Not Committed Yet'}
      end
      @tasks
    end

    def find_contributors
      Dir.chdir( workspace ) { search }
      @tasks
    end
  end

  module Organizes
    def tasks_by_contributor
      open_addressbook
      consolidated_emails = {}
      @email_mappings.each_key do |contributor|
        consolidated_emails[contributor] = []
        @tasks.each do |object|
          key = object[0]
          values = object[1]
          if values[:contributors].include?( contributor )
            message = "\n" +
              "  Spec:          #{values[:spec_file]}:#{values[:line_number]}\n" +
              "    Collaborators: #{values[:contributors].join(',')}\n" +
              "    Title:         #{values[:name]}\n" +
              "    Details:       #{values[:details].join('\n')}"
            consolidated_emails[contributor].push( message )
          end
        end
        consolidated_emails[contributor] = consolidated_emails[contributor].join(
          "\n\n"
        )
      end
      consolidated_emails
    end
  end

  module Writes
    def stdout key, attributes
      puts "\nPending Spec Information:"
      puts "  Description: #{key}"
      puts "  Contributors: #{attributes[:contributors].join(', ')}"
      puts "  File: #{attributes[:spec_file]}"
      puts "  Line: #{attributes[:line_number]}\n"
    end
  end

  module Communicates

    def open_addressbook
      config = YAML::load_file( './config/email.yml' )
      @email_from = config['authentication']['from']
      @email_password = config['authentication']['password']
      @email_mappings = config['users']
    end

    def report(options = nil)
      if !options[:spam]
        self.tasks_by_contributor.each_pair do |recipient, message|
          if message == ''
            subject = 'Congratulations, you have no pending specs! :)'
            messy   = 'Woot!'
          else
            subject = "Please collaborate to fix consolidated list of specs: "
            messy   = message
          end

          send_gmail( 
            :recipients => [recipient],
            :subject => subject,
            :message => messy
          )
        end
      else
        self.tasks.each_pair do |key, attributes|
          if options.nil? || !options[:email]
            stdout key, attributes
          else
            send_gmail :recipients => attributes[:contributors],
              :subject => "Please collaborate to fix spec: " +
                "#{attributes[:spec_file]} : " +
                "#{attributes[:line_number]}",
              :message => "Spec Details:\n  " +
                "Details\n  #{attributes[:details].join('\n')}\n" +
                "Collaborators:\n  #{attributes[:contributors].join(', ')}\n"
          end
        end
      end
    end

    def send_gmail options
      open_addressbook
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
end
