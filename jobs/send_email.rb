require_relative 'job.rb'
class SendEmail < Job
    queue_name = 'test'
    def run(job_args)
        puts "Sending email to #{job_args[:email]}"
    end
end