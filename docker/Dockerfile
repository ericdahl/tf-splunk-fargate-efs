# used to build the EFS RPMs and dependencies
FROM centos:8 AS builder

RUN yum update -y

RUN yum install -y make rpm-build git
WORKDIR /tmp
RUN git clone https://github.com/aws/efs-utils
WORKDIR /tmp/efs-utils
RUN make rpm

RUN cp ./build/amazon-efs-utils*rpm /tmp/amazon-efs-utils.rpm

RUN dnf --downloadonly --downloaddir=/tmp/nfs-utils install -y nfs-utils




FROM splunk/splunk:latest

COPY --from=builder  /tmp/amazon-efs-utils.rpm /tmp/amazon-efs-utils.rpm
COPY --from=builder  /tmp/nfs-utils/ /tmp/nfs-utils/

# microdnf can't install RPMs directly
RUN sudo microdnf install -y dnf

# install EFS utils and dependencies
RUN sudo dnf install -y /tmp/nfs-utils/*.rpm /tmp/amazon-efs-utils.rpm

# not sure why this symlink was lost
RUN sudo ln -s /usr/bin/python2 /usr/bin/python

# Add "webapp" index
ADD etc/apps/search/local/indexes.conf /opt/splunk/etc/apps/search/local/indexes.conf

# Add "ecs" HEC tokens
ADD etc/apps/launcher/local/inputs.conf /opt/splunk/etc/apps/launcher/local/inputs.conf

# Add "default.yml" file loaded by splunk docker ansible initialization
ADD tmp/defaults/default.yml /tmp/defaults/default.yml

WORKDIR /

