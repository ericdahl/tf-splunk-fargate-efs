# tf_splunk_fargate_efs

Demo app of Splunk running on AWS ECS Fargate with EFS for storage

## TODO

- populate /opt/splunk somehow
-- env var to set data dir?
-- or.. copy contents into EFS fs..?
-- https://splunk.github.io/docker-splunk/STORAGE_OPTIONS.html
--- /opt/splunk/var

- Debug 

```
ResourceInitializationError: failed to invoke EFS utils commands to set up EFS volumes: stderr: mount.nfs4: mounting fs-e5645f66.efs.us-east-1.amazonaws.com:/opt/splunk failed, reason given by server: No such file or directory : unsuccessful EFS utils ...
```


- Migrate docker build into different repo with GitHub Action?
