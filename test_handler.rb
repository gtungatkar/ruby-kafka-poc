class TestHandler 
    include Phobos::Handler  
    def consume(payload, metadata)
        msSleep = rand(5000.0)
        secSleep = msSleep.to_f/1000
        puts "sleeping #{secSleep} #{payload}"
        sleep(secSleep)
        puts "wake up #{payload}"
    end
end
