package com.neverwinterdp.kafkaspinner.writer;

import static org.junit.Assert.assertEquals;

import java.util.LinkedList;
import java.util.List;
import java.util.UUID;

import org.apache.log4j.Logger;
import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;

import com.google.common.collect.Multimap;
import com.neverwinterdp.kafkaspinner.util.HostPort;
import com.neverwinterdp.kafkaspinner.util.KafkaSpinnerHelper;
import com.neverwinterdp.kafkaspinner.util.KafkaWriter;
import com.neverwinterdp.kafkaspinner.util.TestUtils;
import com.neverwinterdp.kafkaspinner.util.ZookeeperHelper;
//import com.neverwinterdp.kafkaproducer.messagegenerator.IntegerGenerator;

public class TestKafkaWriter {
  static {
    System.setProperty("log4j.configuration", "file:src/test/resources/log4j.properties");
  }

  private static final Logger       logger = Logger.getLogger(TestKafkaWriter.class);
  private static String             zkURL;
  private static ZookeeperHelper    helper;
  private static KafkaSpinnerHelper kafkaSpinner;

  private KafkaWriter               writer;
  private String                    topic;

  @BeforeClass
  public static void setUpBeforeClass() throws Exception {

    String command = "./start-kafka-spinner.sh --kafka-node-range 1-3 --zookeeper-node-range 1-3 --failure-time-range 1-1 --attach-time-range 1-1 --failure-num-node 1 --ssh-public-key /root/.ssh/id_rsa.pub --off-zookeeper-failure --new-nodes-only";
    kafkaSpinner = new KafkaSpinnerHelper(command);
    kafkaSpinner.start();

    System.out.println("Please wait. It may take time to start kafka cluster...");
    while (!KafkaSpinnerHelper.CLUSTER_STARTED) {
      Thread.sleep(1000);
    }
    System.out.println("Kafka cluster is started");
    zkURL = kafkaSpinner.getzkUrl();
    System.out.println("zkURL >>>>>>>" + zkURL);
    helper = new ZookeeperHelper(zkURL);
    Thread.sleep(10000);

  }

  @Before
  public void setUp() throws Exception {

    topic = TestUtils.createRandomTopic();
    helper.createTopic(topic, 1, 2);
    writer = new KafkaWriter.Builder(zkURL, topic).build();
  }

  /**
   * Write 2000 messages to kafka, count number of messages read. They should be
   * equal
   */
  @Test
  public void testCountMessages() {
    List<String> messages = new LinkedList<>();
    int count = 2000;
    try {
      String randomMessage;
      for (int i = 0; i < count; i++) {
        randomMessage = UUID.randomUUID().toString();
        writer.write(randomMessage);
      }

    } catch (Exception e) {
      e.printStackTrace();
    }
    logger.debug("finished writing to kafka");
    messages = TestUtils.readMessages(topic, zkURL);
    logger.debug("Messages " + messages);
    assertEquals(count, messages.size());
  
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
    // cluster.shutdown();
    //
    // printRunningThreads();
  }
}
