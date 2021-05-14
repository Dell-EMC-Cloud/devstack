#! /bin/bash
# onefs-node-enroll.sh

set -x

function generate_mac {
  hexchars="0123456789abcdef"
  echo "fa:16:3e$(
    for i in {1..6}; do 
      echo -n ${hexchars:$(( $RANDOM % 16 )):1}
    done | sed -e 's/\(..\)/:\1/g'
  )"
}

OP=$1

if [[ -z "$OP" || -z "$2" || ($OP != 'bios' && $OP != 'uefi' && $OP != 'delete') || (( $# < 2 )) ]]; then
    echo "$0 <bios|uefi|delete> <node>"
    exit 1
fi

ONEFS_NODE=$2
source /opt/stack/data/ironic/inventory/$ONEFS_NODE.rc

PROV_SRV=172.19.16.1:3928

baremetal node maintenance set $ONEFS_NODE 2>> /dev/null
OLD_NODE_UUID=`baremetal node list | grep $ONEFS_NODE | awk '{print $2}'`
if [[ -n "$OLD_NODE_UUID" ]]; then
    AGENT_ID=`openstack net agent list | grep $OLD_NODE_UUID |  awk '{print $2}'`
fi
if [[ -n "$AGENT_ID" ]]; then
   openstack net agent delete $AGENT_ID
fi
baremetal node delete $ONEFS_NODE 2>> /dev/null

if [[ $OP == 'delete' ]]; then
    exit
fi

NODE_UUID=$(baremetal node create --name $ONEFS_NODE --driver idrac --deploy-interface direct --rescue-interface agent | grep '| uuid ' | awk '{print $4}')

baremetal node set $ONEFS_NODE \
    --driver-info redfish_username=root \
    --driver-info redfish_password=D@ngerous1 \
    --driver-info redfish_address=$REDFISH_ADDRESS \
    --driver-info redfish_system_id=/redfish/v1/Systems/System.Embedded.1 \
    --driver-info redfish_verify_ca=False \
    --bios-interface idrac-redfish \
    --boot-interface powerscale \
    --management-interface idrac-redfish \
    --power-interface idrac-redfish \
    --driver-info provisioning_network=fsf-provisioning-net \
    --driver-info rescuing_network=fsf-provisioning-net
#    --boot-interface idrac-redfish-virtual-media \

baremetal port create ${PXE_PORT1[0]} --node $NODE_UUID --pxe-enabled true --physical-network fsf-net --local-link-connection switch_id=11:22:33:44:55:66 --local-link-connection port_id="${PXE_PORT1[2]}" --local-link-connection switch_info="{'switch_ip': '${PXE_PORT1[1]}', 'cluster': 'TestCustomer1', 'preemption': false, 'access_mode': 'access', 'fabric': 'frontend'}"

# Port on Backend Fabric 1
BSF1_PORT=$(baremetal port create $INT_PORT1 --node $NODE_UUID --pxe-enable false --physical-network bsf1-net --local-link-connection switch_id=11:22:33:44:55:66 --local-link-connection port_id=e1000 | grep '| uuid ' | awk '{print $4}')

# Port on Backend Fabric 2
BSF2_PORT=$(baremetal port create $INT_PORT2 --node $NODE_UUID --pxe-enable false --physical-network bsf2-net --local-link-connection switch_id=11:22:33:44:55:66 --local-link-connection port_id=e1000 | grep '| uuid ' | awk '{print $4}')

# Port on Mgmt network
MGMT_PORT=$(baremetal port create $(generate_mac) --node $NODE_UUID --pxe-enable false --physical-network fsf-net --local-link-connection switch_id=11:22:33:44:55:66 --local-link-connection port_id="${PXE_PORT1[2]}" --local-link-connection switch_info="{'switch_ip': '${PXE_PORT1[1]}', 'cluster': 'TestCustomer1', 'preemption': false, 'access_mode': 'access', 'fabric': 'frontend'}" | grep '| uuid ' | awk '{print $4}')

# Port on Customer Data network
DATA_PORT=$(baremetal port create $(generate_mac) --node $NODE_UUID --pxe-enable false --physical-network fsf-net --local-link-connection switch_id=11:22:33:44:55:66 --local-link-connection port_id="${PXE_PORT1[2]}" --local-link-connection switch_info="{'switch_ip': '${PXE_PORT1[1]}', 'cluster': 'TestCustomer1', 'preemption': false, 'access_mode': 'trunk', 'fabric': 'frontend'}" | grep '| uuid ' | awk '{print $4}')

baremetal node manage $ONEFS_NODE
baremetal node provide $ONEFS_NODE

