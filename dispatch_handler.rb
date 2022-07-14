require 'json'
require 'timeout'
require_relative 'send_email.rb'

class DispatchHandler 
    include Phobos::Handler  
    
    registry = {
        'send-email': SendEmail.new
    }
    MAX_JOB_TIMEOUT_SECS = 900 # 15 minutes
    MAX_RETRY_COUNT = 3

    def consume(payload, metadata)
        
        parsed = JSON.parse(payload, :symbolize_names => true)
        if metadata['retry_count'] > MAX_RETRY_COUNT
            return
        end
        # TODO check metadata['retry_count'] to cap retries
        # TODO handle badly formatted message
        job_ctor = registry[parsed[:name]]
        if job_ctor.nil?
            # TODO increment error count, unknown job
            return
        end
        begin
            Timeout::timeout(job_ctor().run(parsed[:job_args]), MAX_JOB_TIMEOUT_SECS)
        rescue Timeout::error => te
            # TODO Increment timed out error, swallow the error and move ahead. 
            # Timeout is frowned upon, but we absolutely don't want long running jobs taking up resources 
            # here
        rescue => e
            # TODO increment error count
            raise
        end
    end
end
