package com.neverwinterdp.kafkaspinner.util;

import java.io.IOException;
import java.util.Collection;
import java.util.Properties;

import org.apache.kafka.clients.producer.Callback;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

import com.google.common.collect.ImmutableSet;

public class KafkaSpinnerProducer {
  // private kafka.javaapi.producer.Producer<Integer, String> producer;
  private final Properties     props        = new Properties();
  private int                  messageCount = 0;
  private String               zkURL;
  private ZookeeperHelper      helper;
  private Collection<HostPort> brokers;
  private String               brokerString;
  private String               topic;
  private KafkaProducer        producer;

  public int getMessageCount() {
    return messageCount;
  }

  public KafkaSpinnerProducer(String topic, String zkURL) throws Exception {
    this.zkURL = zkURL;
    this.topic = topic;
    if (zkURL != null) {
      helper = new ZookeeperHelper(this.zkURL);
    }
    if (zkURL != null) {
      brokers = ImmutableSet.copyOf(helper.getBrokersForTopic(topic).values());
    }
    brokerString = brokers.toString().replace("[", "").replace("]", "");

    props.put("message.send.max.retries", "3");
    props.put("retry.backoff.ms", "1000");
    props.put("request.required.acks", "-1");
    props.put("serializer.class", "kafka.serializer.StringEncoder");
    props.put("metadata.broker.list", brokerString);
    props.put("bootstrap.servers", brokerString);
    props.put("topic.metadata.refresh.interval.ms", 60000);

    // producer = new kafka.javaapi.producer.Producer<Integer, String>(new
    // ProducerConfig(props));
    producer = new KafkaProducer(props);
  }

  // public void write(String messageStr) throws Exception {
  // producer.send(new KeyedMessage<Integer, String>(this.topic, messageStr));
  // messageCount++;
  // }

  public void write(String message, Callback callback) {
    String key;
    key = message;
    // ProducerRecord record = new ProducerRecord(topic, 0, key.getBytes(),
    // message.getBytes());

    producer.send(new ProducerRecord(topic, message.getBytes()), callback);
  }

  public void write(String message) {
    String key;
    key = message;
    producer.send(new ProducerRecord(topic, message.getBytes()));
  }

  public void close() throws IOException {
    if (producer != null) {
      producer.close();
    }
    if (helper != null) {
      helper.close();
    }
  }
}
