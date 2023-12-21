## OpenNMS specific

### group_vars/all

Should be set to overwrite the role default vars.

**Example:**
```
# OpenNMS Horizon server settings
onms_hzn_base_rest_url: https://opennms.domain/opennms/rest
onms_hzn_user: USER
onms_hzn_password: PASSWORD
```

### onms_requisition_name

Defines the name of the requisition that a nodes belongs to.

**Example:**
```
onms_requisition_name: switches
```

### onms_policies

Create [provisioning policies](https://docs.opennms.com/horizon/latest/reference/provisioning/policies.html) in requisitions.

**Examples:**
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

### onms_location

Sets the node location (important for Minion usage).

**Example:**
```
onms_location: Default
```

### onms_host_assets / onms_group_assets

Can be used to fill asset fields on group or host var level. Check the available assets in the [docs](https://docs.opennms.com/horizon/latest/reference/configuration/filters/parameters.html). Both lists get merged into `onms_node_assets`.

**Example:**

*inventory/inventory.yml*
```
onms_host_assets:
  rack: 2
```

*group_vars/all.yml*
```
onms_group_assets:
  description: switch
```

### onms_host_categories / onms_group_categories

Puts node into OpenNMS categories. Both lists get merged into `onms_node_categories`.

**Example:**
*inventory/inventory.yml*
```
onms_host_categories:
  - switch
```
*group_vars/all.yml*
```
onms_group_categories:
  - prod
```

### onms_host_services / onms_group_services

Can be used in group or hosts vars to define services for a whole group or node.

:info: Also the parameters can be set to define how the monitors should behave for each node. But this requires changes in the default `poller-configuration.xml`. Examples can be found [here](https://github.com/opennms-forge/ansible-provisioning/blob/main/horizon/container-fs/opt/opennms-overlay/etc/poller-configuration.xml).

**Example:**
*group_vars/all.yml*
```
onms_group_services:
  ICMP: {}
```
*inventory/inventory.yml*
```
onms_host_services:
  SNMP:
    retry: 30
    timeout: 6000
  FTP: {}
```

### onms_node_metadata / onms_group_metadata

Can be used to set MetaData in node context.

**Example:**
*group_vars/all.yml*
```
onms_group_metadata:
  environment: test
```
*inventory/inventory.yml*
```
onms_host_metadata:
  docs: http://nice-documentation.com
```

### onms_host_parent[foreignsource|foreignid|nodelabel]

Can be used in group -or- host vars to define the corresponding parent node which is required to use the path outage feature.
`onms_host_parentforeignsource` is required if the parent node is in a different requisition. And one of the other two is required.

**Example:**
```
onms_host_parentforeignsource: 'switches'
onms_host_parentnodelabel: 'switch1'
onms_host_parentforeignid: '5048'
```


### onms_node_additional_nic

Can be used to add additional interfaces. You can also add services and the parameters.

**Example:**
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

## General

### Remove nodes from OpenNMS

The removal API calls are `never` called by default. They can be run by using the tag `opennms-node-removal`.

**Example:**

```
ansible-playbook -i inventory/03-switches.yml 03-switches.yml -l switch1 --tags opennms-node-removal
```

### skip_import

skip_import` can be used to control, whether the requisition gets imported or not

**Example:**

The default is `false` to always import.
```
ansible-playbook -i inventory site.yml --extra-vars '{"skip_import":"true"}'
```

### Debug tasks

If changes on the node template are required, it makes sense to not call the OpenNMS API.
By running the playbook with `--tags debug` only the xml node file definition files will be created locally.
