require 'phobos'
Phobos.configure('config/phobos.yml')

class ProducerWrapper 
    include Phobos::Producer
    attr_accessor :topic, :key, :partition_key

    def perform(payload)
        begin
            set_topic
            set_key
            set_partition_key
            begin
                ProducerWrapper
                .producer
                .publish(
                    topic: topic, 
                    payload: payload, 
                    key: key, 
                    partition_key: partition_key
                )
                puts "produced #{key}"
            rescue Kafka::BufferOverflow => e
                puts '| waiting'
                sleep(1)
                retry
            end
        ensure
            # Before we stop we must shutdown the async producer to ensure that all messages
            # are delivered
            close_safely
        end
    end

    private

    def close_safely
        ProducerWrapper
            .producer
            .async_producer_shutdown

        ProducerWrapper
            .producer
            .kafka_client
            .close
    end

    def set_topic
        @topic ||= 'default'
    end

    def set_key
        @key ||= SecureRandom.uuid # Not sure about the default value of key
    end

    def set_partition_key
        @partition_key ||= nil
    end

end
