package com.neverwinterdp.kafkaspinner.util;

import java.io.BufferedReader;
import java.io.InputStreamReader;

public class KafkaSpinnerHelper {
  public static boolean CLUSTER_STARTED = false;
  private String        command;

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
              KafkaSpinnerHelper.CLUSTER_STARTED = true;
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
}
