package com.neverwinterdp.kafkaspinner.util;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.List;

public class KafkaSpinnerHelper {
  public boolean CLUSTER_STARTED     = false;
  public int     NodeDieIn           = 0;
  public int     NewNodeIn           = 0;
  public int     NumNodesToDie       = 0;
  public boolean NodesDied           = false;
  public boolean NodesAdded          = false;
  public boolean ReassignmentSuccess = false;
  private String command;

  public KafkaSpinnerHelper(String command) {
    this.command = command;
  }

  Process p;

  public void start() {
    Thread clusterThread = new Thread(new Runnable() {
      @Override
      public void run() {
        try {
          Runtime r = Runtime.getRuntime();
          p = r.exec(command);
          BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
          String line = "";
          while ((line = reader.readLine()) != null) {
            // System.out.println(line);
            if (line.trim().equals("Kafka Cluster started")) {
              CLUSTER_STARTED = true;
            }

            if (line.indexOf("Node die in") > -1) {
              NodeDieIn = Integer.parseInt(line.substring(11, line.length()).trim());
            }

            if (line.indexOf("New node in") > -1) {
              NewNodeIn = Integer.parseInt(line.substring(11, line.length()).trim());
            }

            if (line.indexOf("Nodes died") > -1) {
              // System.out.println(line);
              NodesDied = true;
            }

            if (line.indexOf("Nodes Added") > -1) {
              NodesAdded = true;
            }

            if (line.indexOf("node going to die now") > -1) {
              NumNodesToDie = Integer.parseInt(line.substring(0,
                  line.indexOf("node going to die now")).trim());
            }

            if (line.indexOf("Reassignment Success") > -1) {
              ReassignmentSuccess = true;
            }
          }
          p.waitFor();
        } catch (Exception e) {
          e.printStackTrace();
        }
      }
    });
    clusterThread.start();
  }

  public void stop() {
    p.destroy();
    try {
      Runtime r = Runtime.getRuntime();
      Process process = r.exec("./kill-node.sh --all");
      process.waitFor();
      BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
      String line = "";
      while ((line = reader.readLine()) != null) {
        System.out.println(line);
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public String getzkUrl() {
    String zkUrl = "";

    Process p;
    try {
      p = Runtime.getRuntime().exec("./cluster-helper.sh --ip");
      p.waitFor();
      BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
      String line = "";
      while ((line = reader.readLine()) != null) {
        if (line.indexOf("zoo") > -1) {
          zkUrl += line.split("\\s+")[1].trim() + ":2181,";
        }
      }

    } catch (Exception e) {
      e.printStackTrace();
    }

    zkUrl = zkUrl.substring(0, zkUrl.length() - 1);
    return zkUrl;
  }

  public List<String> getKafkaNodeList() {
    List<String> nodeList = new ArrayList<String>();
    Process p;
    try {
      p = Runtime.getRuntime().exec("./cluster-helper.sh --ip");
      p.waitFor();
      BufferedReader reader = new BufferedReader(new InputStreamReader(p.getInputStream()));
      String line = "";
      while ((line = reader.readLine()) != null) {
        if (line.indexOf("knode") > -1) {
          nodeList.add(line.split("\\s+")[0].trim());
        }
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
    return nodeList;
  }
}
