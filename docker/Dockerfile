#CREDIT: This is taken from https://github.com/markhobson/docker-maven-chrome/blob/master/jdk-8/Dockerfile
#Chrome as headless browser
FROM markhobson/maven-chrome

#adding groovy and pythion support

RUN mkdir test
COPY test_data/test.py test/
COPY test_data/*.jmx test/
COPY test_data/*.csv test/

WORKDIR /test
#PIP, PIP LIBS for test,tools
RUN wget https://bootstrap.pypa.io/get-pip.py \
    && python get-pip.py \
    && pip install selenium \
	&& apt-get update -qqy \
	&& apt-get -qqy install vim groovy curl

#adding jmeter on top of this
ARG JMETER_VERSION=5.3
RUN apt-get clean && \
    apt-get update && \
    apt-get -qy install \
    wget \
    telnet \
    screen \
    iputils-ping \
    unzip
RUN mkdir /jmeter \
    && cd /jmeter/ \
    && wget https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-$JMETER_VERSION.tgz \
    && tar -xzf apache-jmeter-$JMETER_VERSION.tgz \
    && rm apache-jmeter-$JMETER_VERSION.tgz

RUN cd /jmeter/apache-jmeter-$JMETER_VERSION/ && wget -q -O /tmp/JMeterPlugins-Standard-1.4.0.zip https://jmeter-plugins.org/downloads/file/JMeterPlugins-Standard-1.4.0.zip && unzip -n /tmp/JMeterPlugins-Standard-1.4.0.zip && rm /tmp/JMeterPlugins-Standard-1.4.0.zip
RUN wget -q -O /jmeter/apache-jmeter-$JMETER_VERSION/lib/ext/pepper-box-1.0.jar https://github.com/raladev/load/blob/master/JARs/pepper-box-1.0.jar?raw=true
RUN cd /jmeter/apache-jmeter-$JMETER_VERSION/ && wget -q -O /tmp/bzm-parallel-0.7.zip https://jmeter-plugins.org/files/packages/bzm-parallel-0.7.zip && unzip -n /tmp/bzm-parallel-0.7.zip && rm /tmp/bzm-parallel-0.7.zip
#adding selenium support
RUN cd /jmeter/apache-jmeter-$JMETER_VERSION/ && wget -q -O /tmp/jpgc-webdriver-3.1.zip https://jmeter-plugins.org/files/packages/jpgc-webdriver-3.1.zip && unzip -n /tmp/jpgc-webdriver-3.1.zip && rm /tmp/jpgc-webdriver-3.1.zip
RUN cd /jmeter/apache-jmeter-$JMETER_VERSION/ && wget -q -O /tmp/jpgc-sts-2.4.zip https://jmeter-plugins.org/files/packages/jpgc-sts-2.4.zip && unzip -n /tmp/jpgc-sts-2.4.zip && rm /tmp/jpgc-sts-2.4.zip



ENV JMETER_HOME /jmeter/apache-jmeter-$JMETER_VERSION/

ENV PATH $JMETER_HOME/bin:$PATH