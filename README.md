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

The docker based playground has 3 nodes:

* OpenNMS Horizon: 172.16.238.11
* Node1: 172.16.238.12
* Node2: 172.16.238.13

Node1 and Node2 are used to simulate two Linux server to deploy applications and use it to do some service monitoring.

## 🕹️ Usage

### Spin up OpenNMS Horizon with test nodes

In `./horizon/` is a `docker-compose` configuration to spin up an OpenNMS Horizon, and two Ubuntu clients locally on your computer.

To start the containers:
```
cd horizon/
docker-compose up -d
```
Wait until you can login to the Web UI which provides also the required REST endpoints.

### Example: How to add nodes that can not use Ansible?

While the first example uses the gathered facts of Ansible, here we are showing an approach how the playbook can be used in case the nodes can't handle that easy Ansible connections like common Linux distributions, for example, switches, iDRACs, and any other device that just is reachable somehow in the network.

Example:
```
cd ansible
ansible-playbook -i inventory/03-switches.yml 03-switches.yml
```

The inventory here just contains a list of nodes with a name and an IP address. Within the `group_vars/switches` additional information can be added.

### Example: How to add nodes that can use Ansible?

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


### Ansible

#### Parameters

`group_vars/all` Should be set to overwrite the role defaults

Example:
```
# OpenNMS Horizon server settings
onms_hzn_base_rest_url: https://opennms.fra1.ad1.proemion.com/opennms/rest
onms_hzn_user: USER
onms_hzn_password: PASSWORD
```

`onms_requisition_name` defines the name of the requisition that a nodes belongs to

Example:
```
onms_requisition_name: switches
```

`onms_policies` can create [provisioning policies](https://docs.opennms.com/horizon/latest/reference/provisioning/policies.html) to requisitions.

Examples:
```
# OpenNMS Horizon provision policies
onms_policies:
  # There are often special interfaces for that we don't want to collect data/monitor
  ignore_interfaces:
    class: org.opennms.netmgt.provision.persist.policies.MatchingSnmpInterfacePolicy
    parameters:
      action: DO_NOT_PERSIST
      ifDescr: "~^(docker|tap|veth).*$"
      matchBehavior: ALL_PARAMETERS
  # Based on the SysObjId for Linux net-nnmp agent, the category "linux" will be added
  set_category_if_linux_os:
    class: org.opennms.netmgt.provision.persist.policies.NodeCategorySettingPolicy
    parameters:
      category: linux
      sysObjectId: |-
        ~^\.1\.3\.6\.1\.4\.1\.8072\.3\.2\.10.*
      matchBehavior: ALL_PARAMETERS
  # All nodes in the requisition get a node MetaData that can be used to send notifications to a specific destinationPath
  set_metdadata_alerting_channel:
    class: org.opennms.netmgt.provision.persist.policies.NodeMetadataSettingPolicy
    parameters:
      foreignSource: "{{ onms_requisition_name }}"
      metadataKey: alerting_channel
      metadataValue: "alerting-{{onms_requisition_name}}"
      matchBehavior: ANY_PARAMETER
```

`onms_location` to set the nodes location (important for Minion usage)

Example:
```
onms_location: Default
```

`onms_host_assets` / `onms_group_assets` can be used to fill asset fields on group or host var level. Check the asset [docs](https://docs.opennms.com/horizon/32/reference/configuration/filters/parameters.html)

Example:
```
onms_host_assets:
    description: switch
```

`onms_host_categories` puts nodes into OpenNMS categories. Should be used on host var level. Will be merged with `onms_group_categories`

Example:
```
onms_host_categories:
   - switch
```

`onms_group_categories` puts nodes into OpenNMS categories. Should be used on group var level. Will be merged with `onms_host_categories`

Example:
```
onms_group_categories:
   - prod
```

`onms_group_services` can be used in group vars to define services for a whole group.
Needs to be defined at least as `empty` `like onms_group_metadata: {}`
Example:
```
onms_group_services:
   ICMP: {}
   SNMP: {}
```


`onms_host_services` can be used to assign services to single nodes
Needs to be defined at least as `empty` `like onms_host_metadata: {}`
Example:
```
onms_host_services:
   HTTPS: {}
```

`onms_node_parent_foreign_id` can be used in group -or- host vars to define the parent_foreign_id which is required to use the path outage feature

Example:
```
onms_node_parent_foreign_id: "1000"
```

`onms_node_additional_nic` can be used to add secondary interfaces. You can also add services and meta-data

Example:
```
onms_node_additional_nic:
  "172.16.238.20":
    ICMP:
      retry: 5
      timeout: 10
    HTTP:
      port: 90
  "172.16.238.21":
    SNMP:
      retry: 5
      timeout: 10
```

`skip_import` can be used to control, whether the requisition gets imported or not

Example:

The default is `false` to always import.
```
ansible-playbook -i inventory site.yml --extra-vars '{"skip_import":"true"}'
```

#### Development

##### Debug tasks

If changes on the node template are required, it makes sense to not call the OpenNMS API.
By running the playbook with `--tags debug` only the xml node file definition files will be created locally.
