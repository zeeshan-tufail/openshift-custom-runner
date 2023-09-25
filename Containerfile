ARG BASE_IMG=quay.io/redhat-github-actions/runner:latest
FROM $BASE_IMG AS kfh-openshifttools-runner

MAINTAINER Zeeshan M Tufail <zeeshan.tufail@kfh.com>

USER root

ARG HELM_VERSION="3.5.0"
ENV HELM_VERSION=${HELM_VERSION}

ARG KN_VERSION="0.19.1"
ENV KN_VERSION=${KN_VERSION}

ARG OC_VERSION=4.7.4
#ARG OC_VERSION="4.6.18"
#ENV OC_VERSION=${OC_VERSION}

ARG TKN_VERSION="0.15.0"
ENV TKN_VERSION=${TKN_VERSION}

ARG YQ_VERSION="4.6.0"
ENV YQ_VERSION=${YQ_VERSION}

COPY ./install-tools.sh .

#RUN chmod +x ./install-tools.sh 
#	ls -l ./install-tools.sh &&\
#	echo $UID

#The ^M is a carriage return character. Linux uses the line feed character to mark the end of a line, whereas Windows uses the 
#two-character sequence CR LF. Your file has Windows line endings, which is confusing Linux. Remove the spurious CR characters. 
#You can do it with the following command:
RUN sed -i -e 's/\r$//' ./install-tools.sh	&& \
	chmod 755 ./install-tools.sh && \	
	./install-tools.sh && \
	rm ./install-tools.sh

#Install Buildah/Podman Actions Runner 
RUN dnf -y update && \
    dnf -y install xz slirp4netns buildah podman fuse-overlayfs shadow-utils --exclude container-selinux && \
    dnf -y reinstall shadow-utils && \
    dnf clean all 

RUN curl -sSLf https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OC_VERSION}/openshift-client-linux.tar.gz \
    | tar --exclude=README.md -xzvf - && \
    mv kubectl oc /usr/local/bin/

ENV BUILDAH_ISOLATION=chroot
ENV BUILDAH_LAYERS=true

#ADD https://github.com/containers/buildah/blob/main/contrib/buildahimage/containers.conf /etc/containers/
ADD ./containers.conf /etc/containers/

RUN chgrp -R 0 /etc/containers/ && \
    chmod -R a+r /etc/containers/ && \
    chmod -R g+w /etc/containers/

# Use VFS since fuse does not work
# https://github.com/containers/buildah/blob/master/vendor/github.com/containers/storage/storage.conf
RUN mkdir -vp /home/${USERNAME}/.config/containers && \
    printf '[storage]\ndriver = "vfs"\n' > /home/${USERNAME}/.config/containers/storage.conf && \
    chown -Rv ${USERNAME} /home/${USERNAME}/.config/
	
#Include a JDK and Maven.
RUN dnf -y update && \
	dnf --setopt=install_weak_deps=0 --setopt=tsflags=nodocs install -y java-11-openjdk-devel.x86_64 nmap-ncat iputils maven &&\
	dnf update --nodocs -y && \	
	dnf clean all 

	
USER $UID