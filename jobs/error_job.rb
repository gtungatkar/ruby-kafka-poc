require_relative 'job.rb'
class ErrorJob < Job
    queue_name = 'test'
    def run(job_args)
        raise "this job always errors out"
    end
end