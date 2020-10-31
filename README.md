# AWSMigrationWindowsFailoverCluster

This is the github repository that is part of the blog series on the AMIS Technology Blog (https://technology.amis.nl) about the AWS migration of Windows Failover Clusters from on-premise to AWS.

## Directories
There are four directories in this github repository:
* FailoverCluster-HyperV: you can use this to get a Windows Failover Cluster environment under Hyper-V
* FailoverCluster: in this directory are all the files that can be used to get a Windows Failover Cluster in AWS
* ASG: this directory contains all the files that belong to the Auto Scaling Group with one node, without a Custom Image
* ASGWithCustomImage: the files that belong to the Auto Scaling Group with Custom Image solution

Please read the blog on the AMIS Technology Blog site how to install and use these files.

## Files
This directory contains the following two files:
* Costs.ods: costs of the different solutions
* Results.ods: failover times of the different solutions
