require_relative 'producer_wrapper.rb'

class TestProducer < ProducerWrapper
    attr_reader :payload

    def initialize(payload)
        @topic = 'test'
        @key = 'test-key'
        @payload = payload
    end

    def run
        perform(payload)
    end
end

TestProducer.new({name: 'User message', instance_id: '1234', job_args: {}, created_at: Time.now}).run