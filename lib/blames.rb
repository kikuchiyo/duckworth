module Git::Blames
  include Git::Emails

  def blame(options = nil)
    if !options[:spam]
      self.tasks_by_collaborator.each_pair do |recipient, message|
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

  def stdout key, attributes
    puts "\nPending Spec Information:"
    puts "  Description: #{key}"
    puts "  Contributors: #{attributes[:contributors].join(', ')}"
    puts "  File: #{attributes[:spec_file]}"
    puts "  Line: #{attributes[:line_number]}\n"
  end

  # class Pending
  # end

  # class Blame
  # end
end
