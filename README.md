# 🚀 Ansible provisioning into OpenNMS Horizon ✨

Encoding your infrastructure using Ansible is widely adopted.
Ansible knows where, what and how you want to run your applications and infrastructure components.
We think getting hooked into these workflows is an ideal place to define how you want to monitor your infrastructure and applications during operation.
This repository is a conceptual playground investigating how we can use Ansible to fill the node inventory, define the service monitoring.
With Ansibles customization capabilities we can also investigate enrichment of nodes and services to drive notification workflows for alerting.

![Ansible-Provisioning.png](Ansible-Provisioning.png)

## 🎯 Goal

* Using environments like `develop`, `staging`, and `production` as a driver for requisitions as a node inventory in OpenNMS Horizon.
* Providing a workflow to deploy applications and assign operational service tests together with the application deployment.
* Give users some control in Ansible on how the service needs to be monitored.
* The focus here is mainly on black box service testing in operation which is defined in OpenNMS Horizon as "Service" in the Poller daemon.
* While Ansible is mostly used to deploy monitoring agents as well, e.g. Net-SNMP and Prometheus, we want to manage these services with Ansible in OpenNMS Horizon as well.
* Use as much as possible the REST APIs provided in OpenNMS Horizon.

## 🗺 Design principle
Users define in Ansible how services are deployed, it should also define how it is going to be tested in operation – no service detection in OpenNMS Horizon.

## 👋 Say hello
If you have ideas and you are excited we are happy to talk to you.
You can find us in following places:
* Public [Mattermost Chat](https://chat.opennms.com/opennms/channels/opennms-discussion)
* If you have longer discussions to share ideas use our [OpenNMS Discourse](https://opennms.discourse.group) and tag your post with `sig-ansible`.
* What are we doing is described in the [Project board](https://github.com/orgs/opennms-forge/projects/2)

## 💾 Requirements for this playground

* Ansible
* sshpass
* Docker and Docker-Compose

`sudo apt install ansible sshpass`

## 🎢 Ansible Playground

The docker based playground has 5 nodes:

* OpenNMS Horizon: 172.16.238.11
* node1: 172.16.238.12
* node2: 172.16.238.13
* switch1: 172.16.238.14
* switch2: 172.16.238.15

Node1 and Node2 are used to simulate two Linux server to deploy applications with Ansible and use it to do some service monitoring. While this approach runs playbooks to install node1 and node2 accordingly (here we set up Apache web server) and provision them into OpenNMS more or less in one step, also gathering facts from the VMs (Example 1), the Switch1 and Switch2 examples are used to demonstrate static inventory lists for devices that can't be ssh-ed from Ansible. The information are defined in the inventories/vars (Example 2).

## 🕹️ Usage

### Spin up OpenNMS Horizon with test nodes

In `./horizon/` is a `docker-compose` configuration to spin up an OpenNMS Horizon, and two Ubuntu clients locally on your computer.

To start the containers:
```
cd horizon/
docker-compose up -d
```
Wait until you can login to the Web UI which provides also the required REST endpoints.

### Example 1: How to add nodes that can use Ansible?

Since we want to use the gathered facts from Ansible to add more information about a node, for example the operating system, amount of RAM etc, it is required that the the nodes that should be added to OpenNMS can handle Ansible connections.

In `./ansible` all ansible playbook, inventories and variables are stored.
Running a full deployment for Net-SNMP and a web server on Node1,Node2, and the switches run the following command:

Example:
```
cd ansible
sudo -v
ansible-playbook -i inventory site.yml
```

When you run ansible the first time you probably get the following error message:

```
fatal: [node0]: FAILED! => {"msg": "Using a SSH password instead of a key is not possible because Host Key checking is enabled and sshpass does not support this.  Please add this host's fingerprint to your known_hosts file to manage this host."}
fatal: [node1]: FAILED! => {"msg": "Using a SSH password instead of a key is not possible because Host Key checking is enabled and sshpass does not support this.  Please add this host's fingerprint to your known_hosts file to manage this host."}
```

Just add the SSH fingerprint with the following commands:

```
ssh 172.16.238.12
ssh 172.16.238.13
```
You don't need to login, just adding the fingerprint to your `know_hosts` is enough.

### Example 2: How to add nodes that can not use Ansible?

While the first example uses the gathered facts of Ansible, here we are showing an approach how the playbook can be used in case the nodes can't handle that easy Ansible connections like common Linux distributions, for example, switches, iDRACs, and any other device that just is reachable somehow in the network.

Example:
```
cd ansible
ansible-playbook -i inventory/03-switches.yml 03-switches.yml
```

## :wrench: Configurations

Information about the variables that are supported in this playbook can be found [here](https://github.com/opennms-forge/ansible-provisioning/blob/main/ansible/README.md).
