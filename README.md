# tf_splunk_fargate_efs

Demo app of Splunk running on AWS ECS Fargate with EFS for storage. It shows:

- Fargate usage on ECS
- Fargate EFS integration
- ECS Exec to log in to containers
- ALB integration
- Graviton Fargate usage
- Splunk running in a container
- Kinesis Firehose -> Splunk integration with HEC

This uses a custom docker image which builds on top of the official Splunk image only to pre-set up some
indexes and HEC keys

It also uses CloudFront as a hack/trick to add HTTPS support without the need for you to have
a public domain for a cert. Kinesis requires that the HEC endpoint use HTTPS.

## Quick Start

- `terraform apply`
- wait for deployment
- wait 10 minutes more
    - initially Kinesis will have logs like `Failed to deliver data to Splunk or to receive acknowledgment. Make sure HEC endpoint is reachable from Firehose and it is healthy.`
        - not sure exactly what timing issue is here
- Query Splunk: `index=ecs`


## Firelens Forward config

- SSH to jumphost
- `docker run --rm -it --net host fluentd`
- exec into container and tail logs


### Notes

- ecs-agent uses `go-config-generator-for-fluentd-and-fluentbit` to  generate config and puts it in
  `/var/lib/ecs/data/firelens/{Task ID}/config` which is mounted to the fluent-bit container

Default config
```
[INPUT]
    Name forward
    unix_path /var/run/fluent.sock

[INPUT]
    Name forward
    Listen 127.0.0.1
    Port 24224

[INPUT]
    Name tcp
    Tag firelens-healthcheck
    Listen 127.0.0.1
    Port 8877

[FILTER]
    Name record_modifier
    Match *
    Record ec2_instance_id i-057662f4cea748cf5
    Record ecs_cluster tf-splunk-fargate-ecs
    Record ecs_task_arn arn:aws:ecs:us-east-1:123456:task/tf-splunk-fargate-ecs/446fc0cecd06498da9f181b2773da859
    Record ecs_task_definition httpbin-fargate:64

[OUTPUT]
    Name null
    Match firelens-healthcheck

[OUTPUT]
    Name firehose
    Match redis-firelens*
    delivery_stream splunk
    region us-east-1

[OUTPUT]
    Name forward
    Match httpbin-firelens*
    Host 10.0.1.13
    Port 24224
```

default entrypoint
```
echo -n "AWS for Fluent Bit Container Image Version "
cat /AWS_FOR_FLUENT_BIT_VERSION
exec /fluent-bit/bin/fluent-bit -e /fluent-bit/firehose.so -e /fluent-bit/cloudwatch.so -e /fluent-bit/kinesis.so -c /fluent-bit/etc/fluent-bit.conf
```

app log config

```
            "LogConfig": {
                "Type": "fluentd",
                "Config": {
                    "fluentd-address": "unix:///var/lib/ecs/data/firelens/446fc0cecd06498da9f181b2773da859/socket/fluent.sock",
                    "fluentd-async-connect": "true",
                    "fluentd-sub-second-precision": "true",
                    "tag": "httpbin-firelens-446fc0cecd06498da9f181b2773da859"
                }
            },
```

## TODO
- SSM Session Manager for instance
- shorter log buffering? fluent-bit config?


### Debugging

#### ECS Exec

```
aws ecs execute-command --cluster tf-splunk-fargate-ecs --command /bin/sh --interactive --container httpbin --task TASK_ID
```

#### Console Access

- log in to web console
- default creds = admin/password
- Settings -> Data Inputs -> HTTP Event Collector
    - 1111... requires HEC ACK
    - 2222... does not require ACK
        - Firehose seems to require this version
```

## TODO

- reduce delivery stream delay
- HTTPS only on console?
- fargate private IP

- clean up SGs
