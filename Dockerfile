FROM ubuntu:14.04
MAINTAINER Peter Jerold Leslie <jeroldleslie@gmail.com>
RUN apt-get update && apt-get install -y openjdk-7-jdk wget openssh-server openssh-client nano

RUN mkdir /var/run/sshd
RUN echo 'root:kafka' | chpasswd

RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile


RUN wget -q http://apache.communilink.net/kafka/0.8.1.1/kafka_2.9.2-0.8.1.1.tgz -O /tmp/kafka_2.9.2-0.8.1.1.tgz
RUN tar xfz /tmp/kafka_2.9.2-0.8.1.1.tgz -C /opt
RUN mv /opt/kafka_2.9.2-0.8.1.1 /opt/kafka

RUN wget -q -O - http://apache.mirrors.pair.com/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz | tar -xzf - -C /opt
RUN mv /opt/zookeeper-3.4.6 /opt/zookeeper
RUN cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg
RUN mkdir -p /tmp/zookeeper

ADD start-kafka.sh /opt/kafka/start-kafka.sh
ADD start-zookeeper.sh /opt/zookeeper/start-zookeeper.sh
RUN chmod +x /opt/zookeeper/start-zookeeper.sh
RUN chmod +x /opt/kafka/start-kafka.sh

ADD config_modifier.sh /opt/kafka/config/config_modifier.sh
RUN chmod +x /opt/kafka/config/config_modifier.sh

#RUN  echo "    IdentityFile ~/.ssh/id_rsa" >> /etc/ssh/ssh_config
ADD authorized_keys /opt/authorized_keys

ENV KAFKA_HOME /opt/kafka

EXPOSE 2181 9092 22

#WORKDIR /opt/zookeeper

#VOLUME ["/opt/zookeeper/conf", "/tmp/zookeeper"]

#ENTRYPOINT ["/opt/zookeeper/bin/zkServer.sh", "start"]
#CMD ["start-foreground"]
#CMD ["/opt/zookeeper/bin/zkServer.sh start"]
#CMD ["/usr/sbin/sshd", "-D"]
#CMD ["/opt/zookeeper/bin/zkServer.sh", "start"]
#CMD ["/opt/kafka/config/replace.sh"]
