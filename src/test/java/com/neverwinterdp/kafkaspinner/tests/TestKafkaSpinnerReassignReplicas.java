package com.neverwinterdp.kafkaspinner.tests;

import static org.junit.Assert.assertEquals;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import com.neverwinterdp.kafkaspinner.util.KafkaSpinnerHelper;
import com.neverwinterdp.kafkaspinner.util.KafkaWriter;
import com.neverwinterdp.kafkaspinner.util.TestUtils;
import com.neverwinterdp.kafkaspinner.util.ZookeeperHelper;

public class TestKafkaSpinnerReassignReplicas {
  static {
    System.setProperty("log4j.configuration", "file:src/test/resources/log4j.properties");
  }

  private static final Logger       logger             = Logger
                                                           .getLogger(TestKafkaSpinnerNoNodesDie.class);

  private static String             zkURL;
  private static ZookeeperHelper    helper;
  private static KafkaSpinnerHelper kafkaSpinner;
  private String                    brokerInfoLocation = "/brokers/ids";
  private KafkaWriter               writer;
  private String                    topic;
  

  @Before
  public void setUpBefore() throws Exception {
    String command = "./start-kafka-spinner.sh --kafka-node-range 2-3 --zookeeper-node-range 1-3 --failure-time-range 2-2 --attach-time-range 1-1 --failure-num-node-range 1-1 --ssh-public-key /root/.ssh/id_rsa.pub --off-zookeeper-failure --new-nodes-only";
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
  public void testNewNodesGoingUpAndDown() throws Exception {

    List<String> brokerList = helper.getChildren(brokerInfoLocation);

    System.out.println("Broker list before node(s) die \n" + brokerList.toString());

    int brokerSize = brokerList.size();

    writeTenMessageWithTenTopic();

    System.out.println("Node(s) will die in " + kafkaSpinner.NodeDieIn + " seconds. Please wait.");
    while (!kafkaSpinner.NodesDied) {
      Thread.sleep(1000);
    }

    Thread.sleep(1000 * 10);
    System.out.println("Node(s) died");

    List<String> brokerListAfterNodesDie = helper.getChildren(brokerInfoLocation);

    List<String> diedNodes = new ArrayList<String>();

    for (String node : brokerList) {
      if (!brokerListAfterNodesDie.contains(node)) {
        diedNodes.add(node);
      }
    }
    
    System.out.println("Died nodes are " + diedNodes);
    System.out.println("Broker list after node(s) die \n" + brokerListAfterNodesDie.toString());
    assertEquals(brokerSize - brokerListAfterNodesDie.size(), kafkaSpinner.NumNodesToDie);

    System.out.println("Node(s) will add in " + kafkaSpinner.NewNodeIn + " seconds. Please wait.");
    while (!kafkaSpinner.NodesAdded) {
      Thread.sleep(1000);
    }

    // System.out.println("Waiting for reassaignment");
    // while (!kafkaSpinner.ReassignmentSuccess) {
    // Thread.sleep(1000);
    // }

    Thread.sleep(1000 * 10);
    System.out.println("Node(s) Added");
    List<String> brokerListAfterNodesAdded = helper.getChildren(brokerInfoLocation);
    System.out.println("Broker list after add \n" + brokerListAfterNodesAdded.toString());
    List<String> addedNodes = new ArrayList<String>();

    for (String node : brokerListAfterNodesAdded) {
      if (!brokerListAfterNodesDie.contains(node)) {
        addedNodes.add(node);
      }
    }
    System.out.println("Added nodes are " + addedNodes);

    Assert.assertFalse(diedNodes.containsAll(addedNodes) && addedNodes.containsAll(diedNodes));
    assertEquals(brokerList.size(), brokerSize);

    readAndTestReassignment();

  }

  Map<String, List<String>> map = new HashMap<String, List<String>>();

  private void writeTenMessageWithTenTopic() throws Exception {
    System.out.println("Writing messages to cluster");
    int count = 10;
    String message = "Hello KafkaSpinner in ";

    for (int i = 0; i < count; i++) {
      topic = "reassaigntopic" + i;
      helper.createTopic(topic, 1, 3);

      // System.out.println("brokerssss >>>> " +
      // helper.getBrokersForTopicAndPartition(topic, 0));
      // List<String> hostPorts =
      // helper.getBrokersForTopicAndPartitionAsList(topic, 0);
      // List<String> hostString =
      map.put(topic, helper.getBrokersForTopicAndPartitionAsList(topic, 0));
      writer = new KafkaWriter.Builder(zkURL, topic).build();
      for (int j = 0; j < count; j++) {
        String inputMsg = message + topic;
        writer.write(inputMsg);
      }
    }
    logger.debug("finished writing to kafka");

  }

  private void readAndTestReassignment() throws Exception {
    int count = 10;
    List<String> messages;
    for (int i = 0; i < count; i++) {
      messages = new LinkedList<>();
      topic = "reassaigntopic" + i;
      List<String> hostPorts = helper.getBrokersForTopicAndPartitionAsList(topic, 0);

      System.out.println("Replicas before reassaignment - " + map.get(topic)
          + "  ->  Replicas after reassaignment - " + hostPorts);
      Assert.assertFalse(hostPorts.containsAll(map.get(topic))
          && map.get(topic).containsAll(hostPorts));
      messages = TestUtils.readMessages(topic, zkURL);
      assertEquals(count, messages.size());
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