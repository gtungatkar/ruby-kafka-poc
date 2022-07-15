require 'json'
require 'timeout'
require_relative 'jobs/send_email.rb'
require_relative 'jobs/error_job.rb'

class DispatchHandler 
    include Phobos::Handler  
    
    
    MAX_JOB_TIMEOUT_SECS = 900 # 15 minutes
    MAX_RETRY_COUNT = 3

    def initialize
        @registry = {
            "send-email" => SendEmail,
            "error-job" => ErrorJob
        }
    end

    def consume(payload, metadata)
        if metadata[:retry_count] > MAX_RETRY_COUNT
            return
        end
        parsed = JSON.parse(payload, :symbolize_names => true)
        puts parsed
        # TODO handle badly formatted message
        job_ctor = @registry[parsed[:name]]
        if job_ctor.nil?
            # TODO increment error count, unknown job
            puts "No suitable job found for #{parsed[:name]}"
            return
        end
        begin
            Timeout::timeout(MAX_JOB_TIMEOUT_SECS) {job_ctor.new().run(parsed[:job_args])}
        rescue Timeout::Error
            puts "Timeout error"
            # TODO Increment timed out error, swallow the error and move ahead. 
            # Timeout is frowned upon, but we absolutely don't want long running jobs taking up resources 
            # here
        rescue => e
            # TODO increment error count
            raise
        end
    end
end
