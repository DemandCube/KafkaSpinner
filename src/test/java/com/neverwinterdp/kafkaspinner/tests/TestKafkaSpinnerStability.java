package com.neverwinterdp.kafkaspinner.tests;

import static org.junit.Assert.assertEquals;

import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import org.apache.kafka.clients.producer.Callback;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.log4j.Logger;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import com.neverwinterdp.kafkaspinner.util.KafkaSpinnerHelper;
import com.neverwinterdp.kafkaspinner.util.KafkaSpinnerProducer;
import com.neverwinterdp.kafkaspinner.util.TestUtils;
import com.neverwinterdp.kafkaspinner.util.ZookeeperHelper;

public class TestKafkaSpinnerStability {
  static {
    System.setProperty("log4j.configuration", "file:src/test/resources/log4j.properties");
  }

  private static final Logger       logger               = Logger
                                                             .getLogger(TestKafkaSpinnerNoNodesDie.class);

  private static String             zkURL;
  private static ZookeeperHelper    helper;
  private static KafkaSpinnerHelper kafkaSpinner;
  private KafkaSpinnerProducer      writer;
  private String                    topic;
  private String                    message              = "Hello KafkaSpinner";
  private AtomicInteger             totalMessagesWritten = new AtomicInteger();

  @Before
  public void setUpBeforeClass() throws Exception {
    String command = "./start-kafka-spinner.sh --kafka-node-range 2-3 --zookeeper-node-range 1-3 --failure-time-range 1-1 --attach-time-range 2-2 --failure-num-node-range 1-1 --ssh-public-key /root/.ssh/id_rsa.pub --off-zookeeper-failure --new-nodes-only";
    kafkaSpinner = new KafkaSpinnerHelper(command);
    kafkaSpinner.start();

    System.out.println("Please wait. It may take time to start kafka cluster...");
    while (!kafkaSpinner.CLUSTER_STARTED) {
      Thread.sleep(1000);
    }
    System.out.println("Kafka cluster is started");
    zkURL = kafkaSpinner.getzkUrl();
    helper = new ZookeeperHelper(zkURL);
    Thread.sleep(10000);
  }

  @Test
  public void test1000Messages() throws Exception {
    testNMessagesOnNTopics(1, 1000);
  }

  @Test
  public void test1000MessagesOn10Topics() throws Exception {
    testNMessagesOnNTopics(10, 1000);
  }

  @Test
  public void testFor10Minutes() throws Exception {

    int minutes = 10;
    long startTime = System.currentTimeMillis();

    topic = TestUtils.createRandomTopic();
    helper.createTopic(topic, 2, 2);
    writer = new KafkaSpinnerProducer(topic, zkURL);

    Callback callback = new Callback() {
      @Override
      public void onCompletion(RecordMetadata metadata, Exception exception) {

        if (exception == null) {
          totalMessagesWritten.incrementAndGet();
        } else {
          exception.printStackTrace();
        }

      }
    };
    while ((System.currentTimeMillis() - startTime) < minutes * 60 * 1000) {

      for (int i = 0; i < 1000; i++) {
        writer.write(message + " " + System.currentTimeMillis(), callback);
        if ((System.currentTimeMillis() - startTime) > minutes * 60 * 1000) {
          break;
        }
      }

      Thread.sleep(1000);
      System.out.println(totalMessagesWritten.get() + " messages written in cluster");

    }

    List<String> messages;
    messages = TestUtils.readMessages(topic, zkURL);
    System.out.println("Total message written = " + totalMessagesWritten.get());
    System.out.println("Total message read = " + messages.size());
    assertEquals(totalMessagesWritten.get(), messages.size());

  }

  private void testNMessagesOnNTopics(int numTopic, int numMessagesPerTopic) throws Exception {
    for (int i = 0; i < numTopic; i++) {
      topic = "topic" + i;
      helper.createTopic(topic, 2, 2);
      System.out.println("Writing to topic " + topic);
      writer = new KafkaSpinnerProducer(topic, zkURL);
      for (int j = 0; j < numMessagesPerTopic; j++) {
        // write(topic, message + "-" + topic + "-" + i);
        writer.write(message + "-" + topic + "-" + i);
      }
      writer.close();
      Thread.sleep(1000);
    }
    logger.debug("finished writing to kafka");
    System.out.println("finished writing to kafka");
    List<String> messages;

    for (int i = 0; i < numTopic; i++) {
      topic = "topic" + i;
      messages = TestUtils.readMessages(topic, zkURL);
      logger.debug("Messages " + messages);

      assertEquals(numMessagesPerTopic, messages.size());
    }
  }

  @After
  public void tearDown() throws Exception {
    if (writer != null) {
      writer.close();
    }
    logger.info("tearDownClass.");
    logger.debug("Ignore All exceptions after this message.");
    helper.deleteKafkaData();
    helper.close();
    kafkaSpinner.stop();
  }

}
