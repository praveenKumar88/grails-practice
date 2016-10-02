FROM jenkins
COPY plugins.txt /plugins.txt
RUN /usr/local/bin/plugins.sh /plugins.txt

USER root
RUN apt-get update && apt-get install -y netcat
ENV		JMETER_VERSION	3.0
ENV		JMETER_HOME	/opt/jmeter
ENV		JMETER_DOWNLOAD_URL  http://mirror.serversupportforum.de/apache/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz

RUN mkdir -p "/statsd-cli/"
copy libs/statsd-cli /statsd-cli

RUN mkdir -p ${JMETER_HOME}
RUN ls -al ${JMETER_HOME}
RUN curl -L --silent ${JMETER_DOWNLOAD_URL} | tar -xz --strip=1 -C ${JMETER_HOME}
COPY testplans ${JMETER_HOME}/testplans
COPY run_jmeter_jenkins.sh ${JMETER_HOME}/
COPY properties/ ${JMETER_HOME}/
RUN mkdir /usr/share/jenkins/ref/jobs
COPY jobs /usr/share/jenkins/ref/jobs
RUN echo -n 2.0 > /usr/share/jenkins/ref/jenkins.install.UpgradeWizard.state && \
    echo -n 2.0 > /usr/share/jenkins/ref/jenkins.install.InstallUtil.lastExecVersion
