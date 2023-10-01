# tf_splunk_fargate_efs

Demo app of Splunk running on AWS ECS Fargate with EFS for storage. It shows:

- Fargate usage on ECS
- Fargate EFS integration
- ECS Exec to log in to containers
- ALB integration
- Graviton Fargate usage

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
