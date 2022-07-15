**Proof of concept of a job dispatcher based on kafka.**

Based on https://github.com/phobos/phobos framework for kafka message consumption.

**Design**

A producer produces a message to a job queue. The produced message looks like the following
```{"name":"send-email", "job_args":{"email":"gaurav@hingehealth.com", "created_at": <timestamp>, "instance_id":"e3f10855-6f9b-4fd2-99e2-fbf9ccba9ba7"}}```
name: unique job name
job_args: json blob of args that the job needs to run
created_at: timestamp in millis since epoc
instance_id: uuid for a particular instance/invocation of the job

DispatchHandler consumes the job message, and triggers the actual job. It maintains a mapping of job name to the actual job class implementing the job. It looks at the job name from the incoming message and runs the matching job if found.

**Priority and queues**

One kafka topic is supposed to handle all jobs of a "priority". We can start with 2 priorities : "high" and "normal" priority. High priority can have more concurrent executions and possibly tighter bounds on job runtime. 

**Concurrency**

Depends on kafka partitions for concurrency. A topic should have 8 or more partitions so that 8 concurrent jobs can run per consumer group. One job per partition. For a single parition, jobs get executed linearly and can suffer head of line blocking.

**Scaling**

Multiple levers to scale. 
- Add more concurrency by adding more partitions. 
- Run multiple consumer groups per topic (priority), each interested in only a subset of jobs.

**Error Handling**
A job can raise exceptions in case of error. Job will be retried if there is an exception up to the MAX_RETRY_COUNT (3). Each retry is done following an exponential backoff. Phobos takes care of retries by consuming the same message again on every retry. It is important to exhaust the retries so that job processing can move on to the next job messages in the queue. While retries are happening, jobs queue up in the partition which holds the erroring job message.
Retries happen within a few seconds of each other. This is different than sidekiq which can retry a job long after the first execution. 

**Support for at least once job execution**

At least once execution depends on kafka at least once message consumption semantics.

**Support for multiple languages**

Standard job messages that can be produced in any language. Similar thi consumer framework can be built in typescript as well.

**Job metrics**
Expected to use datadog custom metrics.

**Long running jobs**

Not designed for running jobs longer than a few minutes. Few = 15 in this case. Kafka consumer heartbeat interval is the upper bound for how long a job can run. Jobs run in the same thread on which consumers have to send a heartbeat back to kafka broker. If job takes longer than heartbeat timeout, it will lead consumer rebalancing churn. timeout is used to interrupt a job after the heartbeat interval so that heartbeat is not blocked and other jobs can be consumed.

Long running jobs should likely be running as k8s jobs. Design TBD.

**Delayed Job**

No support for delayed jobs.

**Scheduled Job**

A separate components that can understand a schedule and produce the appropriate job message at the scheduled time.

**Running the examples**

1. Setup a local kafka cluster described in https://hingehealth.atlassian.net/browse/BD-16
2. Create a topic say "test"
3. Run a producer to produce the job messages. For example run the console produces 
```docker exec --interactive --tty broker kafka-console-producer --bootstrap-server broker:9092                        --topic test```  
```{"name":"send-email", "job_args":{"email":"gaurav@hingehealth.com", "created_at": <timestamp>, "instance_id":"e3f10855-6f9b-4fd2-99e2-fbf9ccba9ba7"}}```
4. Setup this example by ```bundle install```
5. Run as ```phobos start```
Should get an output like: ```{:name=>"send-email", :job_args=>{:email=>"test@hh.com"}}```
```Sending email to test@hingehealth.com```
