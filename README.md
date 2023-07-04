# Ansible OpenNMS Provisioning

With this project we want to give it a try to provisiong out of Ansible inventories into OpenNMS.

## Requirements

* Ansible
* sshpass

`sudo apt install ansible sshpass`

## Usage

## Spin up OpenNMS + test nodes

In `./opennms/` is a `docker-compose` configuration to spin up an OpenNMS, and two Ubuntu clients locally on your computer.


To start the containers:
```
cd opennms/
docker-compose up -d
```

### IP addresses

OpenNMS: 172.16.238.11
Node1: 172.16.238.12
Node2: 172.16.238.13

## Ansible

In `./ansible` all ansible playbook, inventories and variables are stored.

Example call:
```
cd ansible
ansible-playbook opennms-provision.yml -i inventory/department1
```

## Hint from Mattermost chat about creating nodes

Flow for adding a node via APIs would be... 

* Create a Requisition
* Create a ForeignSource for the Requisition
* Import import?rescanExisting=false
* Add SNMP Config for a node
* Add a Node to Requisition
* Import [import?rescanExisting=false]


## Create a Requisition called fromCLI:

```
curl -vv -u admin:admin -XPOST -H 'Content-type: application/xml' -d '@emptyReq.xml'  "http://opennms:8980/opennms/rest/requisitions"
Content of emptyReq.xml
```
```
<model-import date-stamp="2022-09-22T09:31:05.469Z" foreign-source="fromCLI" last-import="2022-09-22T09:31:05.469Z">
</model-import>
```

## Create a ForeignSource for the Requisition fromCLI:

```
curl -v -u admin -H 'Content-type: application/xml' -XPOST -d '@fromCLI-foreignSource.xml' "http://opennms:8980/opennms/rest/foreignSources"
```

Content of fromCLI-foreignSource.xml file

```
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<foreign-source xmlns="http://xmlns.opennms.org/xsd/config/foreign-source" name="fromCLI" date-stamp="2022-12-13T07:50:49.323Z">
    <scan-interval>1d</scan-interval>
    <detectors>
        <detector name="ICMP" class="org.opennms.netmgt.provision.detector.icmp.IcmpDetector"/>
        <detector name="SNMP" class="org.opennms.netmgt.provision.detector.snmp.SnmpDetector"/>
    </detectors>
    <policies>
        <policy name="Unmanage IP Interfaces" class="org.opennms.netmgt.provision.persist.policies.MatchingIpInterfacePolicy">
            <parameter key="action" value="UNMANAGE"/>
            <parameter key="matchBehavior" value="ALL_PARAMETERS"/>
        </policy>
    </policies>
</foreign-source>
```

## Import Requisition with rescanExisting=false

```
curl -v -u admin -H 'Content-type: application/xml' -XPUT "http://opennms:8980/opennms/rest/requisitions/fromCLI/import?rescanExisting=false"
```

## Add SNMP Config for an ip-address

```
curl -v -u admin -H 'Content-type: application/xml' -XPUT -d '@snmpInfo.xml' "http://opennms:8980/opennms/rest/snmpConfig/10.2.0.9"
```

## Add a Node to Requisition

```
curl -vv -u admin:admin -XPOST -H 'Content-type: application/xml' -d '@newNode.xml' "http://opennms:8980/opennms/rest/requisitions/fromCLI/nodes"
```

## Content of newNode.xml

```
 <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<node foreign-id="1111" node-label="google-dns2">
<interface ip-addr="8.8.8.8" status="1" snmp-primary="P"/>
</node>
```

## Import with rescanExisting=false

```
curl -v -u admin -H 'Content-type: application/xml' -XPUT "http://opennms:8980/opennms/rest/requisitions/fromCLI/import?rescanExisting=false"
```