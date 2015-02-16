package com.neverwinterdp.kafkaspinner.tests;

import static org.junit.Assert.assertEquals;

import java.util.LinkedList;
import java.util.List;
import java.util.UUID;

import kafka.common.FailedToSendMessageException;

import org.apache.log4j.Logger;
import org.junit.After;
import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

import com.neverwinterdp.kafkaspinner.util.KafkaSpinnerHelper;
import com.neverwinterdp.kafkaspinner.util.KafkaWriter;
import com.neverwinterdp.kafkaspinner.util.TestUtils;
import com.neverwinterdp.kafkaspinner.util.ZookeeperHelper;

public class TestKafkaSpinnerNoNodesDie {
  static {
    System.setProperty("log4j.configuration", "file:src/test/resources/log4j.properties");
  }

  private static final Logger       logger = Logger.getLogger(TestKafkaSpinnerNoNodesDie.class);
  private static String             zkURL;
  private static ZookeeperHelper    helper;
  private static KafkaSpinnerHelper kafkaSpinner;

  private KafkaWriter               writer;
  private String                    topic;

  @BeforeClass
  public static void setUpBeforeClass() throws Exception {

    String command = "./start-kafka-spinner.sh --kafka-node-range 1-3 --zookeeper-node-range 1-3 --failure-time-range 1-1 --attach-time-range 1-1 --failure-num-node-range 1-1 --ssh-public-key /root/.ssh/id_rsa.pub --off-zookeeper-failure";
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
  public void testSingleMessageWithSingleTopic() throws Exception {
    topic = TestUtils.createRandomTopic();
    helper.createTopic(topic, 1, 2);
    writer = new KafkaWriter.Builder(zkURL, topic).build();
    String message = "Hello KafkaSpinner";
    List<String> messages = new LinkedList<>();
    try {
      writer.write(message);
    } catch (Exception e) {
      e.printStackTrace();
    }
    logger.debug("finished writing to kafka");
    messages = TestUtils.readMessages(topic, zkURL, 0);
    logger.debug("Messages " + messages);
    assertEquals(1, messages.size());
    assertEquals(message, messages.get(0));

  }

  @Test
  public void testTenMessageWithSingleTopic() throws Exception {
    topic = TestUtils.createRandomTopic();
    helper.createTopic(topic, 1, 2);
    writer = new KafkaWriter.Builder(zkURL, topic).build();
    String message = "Hello KafkaSpinner";
    List<String> messages = new LinkedList<>();
    int count = 10;
    try {
      for (int i = 0; i < count; i++) {
        writer.write(message);
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
    logger.debug("finished writing to kafka");
    messages = TestUtils.readMessages(topic, zkURL, 0);
    logger.debug("Messages " + messages);
    assertEquals(count, messages.size());
    for (String recievedMsg : messages) {
      assertEquals(message, recievedMsg);
    }
  }

  @Test
  public void testTenMessageWithTenTopic() throws Exception {
    int count = 10;
    String message = "Hello KafkaSpinner in ";

    for (int i = 0; i < count; i++) {
      topic = "topic" + i;
      String inputMsg = message + topic;
      helper.createTopic(topic, 1, 2);
      writer = new KafkaWriter.Builder(zkURL, topic).build();
      writer.write(inputMsg);
      
      logger.debug("finished writing to kafka");
    }
    List<String> messages;
    for (int i = 0; i < count; i++) {
      messages = new LinkedList<>();
      topic = "topic" + i;
      String outputMsg = message + topic;
      messages = TestUtils.readMessages(topic, zkURL, 0);
      assertEquals(1, messages.size());
      assertEquals(outputMsg, messages.get(0));
    }

  }

  @Test(expected = FailedToSendMessageException.class)
  public void testTopicDoesNotExists() throws Exception {
    topic = "topicdoesnotexists";
    writer = new KafkaWriter.Builder(zkURL, topic).build();
    writer.write("Hello KafkaSpinner - " + UUID.randomUUID().toString());
  }

  @After
  public void tearDown() throws Exception {
    writer.close();
  }

  @AfterClass
  public static void tearDownClass() throws Exception {
    logger.info("tearDownClass.");
    logger.debug("Ignore All exceptions after this message.");

    helper.deleteKafkaData();
    helper.close();
    kafkaSpinner.stop();
  }
}
