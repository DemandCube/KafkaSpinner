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

public class TestKafkaSpinnerNodesDie {
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
    String command = "./start-kafka-spinner.sh --kafka-node-range 1-3 --zookeeper-node-range 1-3 --failure-time-range 1-1 --attach-time-range 1-1 --failure-num-node 1 --ssh-public-key /root/.ssh/id_rsa.pub --off-zookeeper-failure --failure-num-node 1";
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
  public void testNodesDie() throws Exception {
    System.out.println("Node die in " + kafkaSpinner.NodeDieIn + " seconds.");

    String brokerInfoLocation = "/brokers/ids";
    List<String> brokerList = helper.getChildren(brokerInfoLocation);
    System.out.println(brokerList.size());
    int brokerSize = brokerList.size();
    for (String broker : brokerList) {
      System.out.println(broker);
    }
    System.out.println("Wait to node die");
    while (!kafkaSpinner.NodesDied) {
      Thread.sleep(1000);
    }
    System.out.println("Node died");
    Thread.sleep(1000*10);
    brokerList = helper.getChildren(brokerInfoLocation);
    assertEquals(brokerSize - brokerList.size(), kafkaSpinner.NumNodesToDie);
    // topic = TestUtils.createRandomTopic();
    // helper.createTopic(topic, 1, 2);
    // writer = new KafkaWriter.Builder(zkURL, topic).build();
    // String message = "Hello KafkaSpinner";
    // List<String> messages = new LinkedList<>();
    // try {
    // writer.write(message);
    // } catch (Exception e) {
    // e.printStackTrace();
    // }
    // logger.debug("finished writing to kafka");
    // messages = TestUtils.readMessages(topic, zkURL, 0);
    // logger.debug("Messages " + messages);
    // assertEquals(1, messages.size());
    // assertEquals(message, messages.get(0));

  }

  @After
  public void tearDown() throws Exception {
    if (writer != null){
      
      writer.close();
    }
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
