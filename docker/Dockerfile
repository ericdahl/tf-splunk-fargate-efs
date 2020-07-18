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
WORKDIR /tmp
RUN sudo microdnf install -y dnf

COPY --from=builder  /tmp/nfs-utils/ /tmp/nfs-utils/
RUN sudo dnf install -y ./nfs-utils/*.rpm # nfs-utils-2.3.3-31.el8.x86_64.rpm

RUN sudo dnf install -y ./amazon-efs-utils.rpm



WORKDIR /



#FROM splunk/splunk:latest
#
#RUN sudo microdnf install git
#
#WORKDIR /tmp
#RUN git clone https://github.com/aws/efs-utils
#WORKDIR /tmp/efs-utils
#
#RUN sudo microdnf install make
#
##run sudo microdnf install epel-release
##RUN sudo microdnf install rpm-build
#
#RUN sudo make rpm
