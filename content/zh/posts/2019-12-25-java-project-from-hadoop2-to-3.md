---
author: atttx123
title: "Java程序从Hadoop 2迁移到3"
date: 2019-12-25T20:46:21+08:00
draft: false
---

> Java程序从Hadoop 2迁移到3需要注意的事项，有哪些坑?
> <!--more-->

## Hadoop 3 版本介绍

------

hadoop 3 的第一个版本是2017年12月8日GA的，主要版本及发布时间如下：

| 版本   | 时间       |
| ------ | ---------- |
| r3.2.1 | 2019-09-24 |
| r3.2.0 | 2019-01-08 |
| r3.1.3 | 2019-09-12 |
| r3.1.2 | 2019-01-29 |
| r3.1.1 | 2018-08-02 |
| r3.1.0 | 2018-03-30 |
| r3.0.3 | 2018-05-31 |
| r3.0.2 | 2018-04-13 |
| r3.0.1 | 2018-03-16 |
| r3.0.0 | 2017-12-08 |

## Hadoop 2与3有哪些不同

------

Hadoop 3 在 Hadoop 2的基础上进行了大量的更新，从官方文档中整理出以下几个大方面[^1]：

[^1]: [Hadoop 3.0 Release Note](https://hadoop.apache.org/docs/r3.0.0/index.html)

### Common主要改进

- 重写了shell管理脚本
- 过时API删除
- 客户端拆分成hadoop-client-api和hadoop-client-runtime，避免依赖包冲突

### HDFS改进

- 支持erasure编码
- 支持超过两个namenode
- 多个服务默认端口发生变化（影响NameNode, Secondary NameNode, DataNode, KMS）

### Yarn改进

- 新版本YARN Timeline Service
- 支持Cgroup和docker

### MapRduece改进

- 任务原生优化
- 更加简易的内存配置

## 终端用户关心的主要变化

------

以上更新中，终端用户比较关心的变化有以下两个：

### 默认端口发生变化

主要是HDFS和KMS的部分端口发生了变化，具体的更新是这两个issue：[HDFS-9427](https://issues.apache.org/jira/browse/HDFS-9427)（HDFS部分）和[HADOOP-12811](https://issues.apache.org/jira/browse/HADOOP-12811)（KMS部分）

HDFS端口变化如下：

| 组件 | 服务               | 协议  | 端口 (2 --> 3)                  | 配置                                   | 备注                                                         |
| ---- | ------------------ | ----- | ------------------------------- | -------------------------------------- | ------------------------------------------------------------ |
| HDFS | NameNode           | HTTP  | 50070 --> 9870                  | `dfs.namenode.http-address`            | WebUI，一般是集群管理员或运维人员访问                        |
| HDFS | NameNode           | HTTPS | 50470 --> 9871                  | `dfs.namenode-https-address`           | WebUI，一般是集群管理员或运维人员访问                        |
| HDFS | NameNode           | IPC   | 8020 --> 9820                   | `fs.defaultFS`                         | 交换metadata，所有的数据请求都需要访问                       |
| HDFS | NameNode           | TPC   | 默认没有配置（CDH推荐使用8022） | `dfs.namenode. servicerpc-address`     | 如果配置了，HDFS内部服务会通过这个地址交换信息，避免和client抢占 `fs.defaultFS` |
| HDFS | Secondary NameNode | HTTP  | 50090 --> 9868                  | `dfs.namenode.secondary.http-address`  | Checkpoin for NameNode metadata                              |
| HDFS | Secondary NameNode | HTTPS | 50091 --> 9869                  | `dfs.namenode.secondary.https-address` |                                                              |
| HDFS | DataNode           | TPC   | 50010 --> 9866                  | `dfs.datanode.address`                 | 数据交换                                                     |
| HDFS | DataNode           | IPC   | 50020 --> 9867                  | `dfs.datanode.ipc.address`             | Metadata operations                                          |
| HDFS | DataNode           | HTTP  | 50075 --> 9864                  | `dfs.datanode.http.address`            | WebUI                                                        |
| HDFS | DataNode           | HTTPS | 50475 --> 9865                  | `dfs.datanode.https.address`           | WebUI                                                        |

### Java Client拆分

在Hadoop 2中常用的client包有以下几种：

- HDFS：
  - [hadoop-common](https://search.maven.org/artifact/org.apache.hadoop/hadoop-common)包：提供`UserGroupInformation`、`Configuration`等基本类以及`FileSystem`这个抽象接口类
  - [hadoop-hdfs-client](https://search.maven.org/artifact/org.apache.hadoop/hadoop-hdfs-client)：提供`DistributedFileSystem`这个具体实现以及`DFSClient`等与HDFS通信的工具类
- Yarn
  - [hadoop-yarn-client](https://search.maven.org/artifact/org.apache.hadoop/hadoop-yarn-client)：提供`YarnClient`（与Yarn通信的工具类）

不过Hadoop 2提供的包有以下几个问题：

1. 抽象层不统一：比如[hadoop-common](https://search.maven.org/artifact/org.apache.hadoop/hadoop-common)包内有`FTPFileSystem`、`HTTPFileSystem`等具体实现
2. 包依赖过多容易发生冲突：比如[hadoop-common](https://search.maven.org/artifact/org.apache.hadoop/hadoop-common)包依赖Guava、log4j等库[^2]

[^2]: [hadoop client 2.7.4和3.2.1依赖对比](/html/hadoop-client-dependencies-2vs-3.html)

#### 拆分的新包

基于以上问题，在Hadoop 3中有了新的两个包：

* [hadoop-client-api](https://search.maven.org/artifact/org.apache.hadoop/hadoop-client-api)：提供接口定义
* [hadoop-client-runtime](https://search.maven.org/artifact/org.apache.hadoop/hadoop-client-runtime)：提供具体实现

新包的依赖结构比之前版本简单很多，具体依赖如下：

```
+- org.apache.hadoop:hadoop-client-api:jar:3.2.1:compile
\- org.apache.hadoop:hadoop-client-runtime:jar:3.2.1:runtime
   +- org.apache.htrace:htrace-core4:jar:4.1.0-incubating:runtime
   +- org.slf4j:slf4j-api:jar:1.7.25:runtime
   +- commons-logging:commons-logging:jar:1.1.3:runtime
   \- com.google.code.findbugs:jsr305:jar:3.0.0:runtime
```

