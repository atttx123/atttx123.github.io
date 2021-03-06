---
author: atttx123
title: "Hadoop 3 HDFS Erasure Coding"
date: 2019-12-28T21:19:16+08:00
draft: false
---

> Hadoop 3.0 引入了纠删码技术（Erasure Coding），它可以提高50%以上的存储利用率，并且保证数据的可靠性。

<!--more-->

## 前言

HDFS默认会将每一个Block复制三保存（为什么需要三副本？因为某胖不会数三。。。。。。）。副本机制（Replication）是一种可以抵御大多数故障的简单而健壮的冗余形式，同时副本机制还可以有效的简化计算的并行调度逻辑。

但是复制是非常昂贵的：默认的三副本方案会导致存储空间和其他资源（例如，写入数据时的网络带宽）产生200％的开销；对于冷门数据集可能在正常操作期间很少访问其他块副本（单IO、顺序读取）但仍会消耗相同数量的存储空间。

基于以上原因，在2014年下半年，英特尔和Cloudera共同提出了将纠删码（Erasure Code）融入到HDFS内部的想法和设计[^1]，随后吸引了包括Hortonworks、华为、Yahoo!等众多公司的参与，使之成为Hadoop开源社区较为活跃的一个项目：[HDFS-7285](https://issues.apache.org/jira/browse/HDFS-7285)。

[^1]:https://blog.cloudera.com/introduction-to-hdfs-erasure-coding-in-apache-hadoop/

## 纠删码（Erasure Code)

纠删码（Erasure Code）本身是一种编码容错技术，最早是在通信行业解决部分数据在传输中损耗的问题，它的基本原理是把传输的信号分段，加入一定的校验再让各段间发生一定的联系，即使在传输过程中丢失掉部分信号，接收端仍然能通过算法把完整的信息计算出来。

如果严格的区分，实际上按照误码控制的不同功能，可分为"检错"、"纠错"和"纠删"三种类型。

* 检错码仅具备识别错码功能 而无纠正错码功能；
* 纠错码不仅具备识别错码功能，同时具备纠正错码功能；
* 纠删码则不仅具备识别错码和纠正错码的功能，而且当错码超过纠正范围时，还可把无法纠错的信息删除。

