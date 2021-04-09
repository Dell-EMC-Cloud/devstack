#! /bin/bash
# onefs-node.sh <node>

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
ONEFS_NODE=onefs-node$2

if [[ -z "$OP" || -z "$2" || ($OP != 'bios' && $OP != 'uefi' && $OP != 'delete') ]]; then
    echo "baremetal.sh <bios|uefi|delete> <1|2|3> [<image>] [onefs-image]"
    exit 1
fi

MFSBSD=pic-mfsbsd.iso
if [[ -n $3 ]]; then
    MFSBSD=$3
fi

ONEFS_IMAGE=install.tar.gz
if [[ -n $4 ]]; then
    ONEFS_IMAGE=$4
fi

PROV_SRV=172.19.16.1:3928

baremetal node maintenance set $ONEFS_NODE 2>> /dev/null
baremetal node delete $ONEFS_NODE 2>> /dev/null
openstack port delete $ONEFS_NODE-bsf1-port 2>> /dev/null
openstack port delete $ONEFS_NODE-bsf2-port 2>> /dev/null
openstack port delete $ONEFS_NODE-mgmt-port 2>> /dev/null
openstack port delete $ONEFS_NODE-cust-data-port 2>> /dev/null

if [[ $OP == 'delete' ]]; then
    exit
fi

NODE_UUID=$(baremetal node create --name $ONEFS_NODE --driver idrac --deploy-interface direct --rescue-interface agent | grep '| uuid ' | awk '{print $4}')

baremetal node set $ONEFS_NODE \
    --driver-info redfish_username=root \
    --driver-info redfish_password=D@ngerous1 \
    --driver-info redfish_address=100.127.0.211 \
    --driver-info redfish_system_id=/redfish/v1/Systems/System.Embedded.1 \
    --driver-info redfish_verify_ca=False \
    --bios-interface idrac-redfish \
    --boot-interface powerscale \
    --management-interface idrac-redfish \
    --power-interface idrac-redfish \
    --driver-info provisioning_network=fsf-provisioning-net \
    --driver-info rescuing_network=fsf-provisioning-net
#    --boot-interface idrac-redfish-virtual-media \

baremetal port create 0C:42:A1:E0:83:E0 --node $NODE_UUID --pxe-enabled true --physical-network fsf-net --local-link-connection switch_id=11:22:33:44:55:66 --local-link-connection port_id="ethernet 1/1/1:1" --local-link-connection switch_info='{"switch_ip": "100.127.0.125", "access_mode": "access"}'

# Port on Backend Fabric 1
BSF1_PORT=$(baremetal port create 04:3F:72:A2:3C:BA --node $NODE_UUID --pxe-enable false --physical-network bsf1-net --local-link-connection switch_id=11:22:33:44:55:66 --local-link-connection port_id=e1000 | grep '| uuid ' | awk '{print $4}')
BSF1_VIF=$(openstack port create $ONEFS_NODE-bsf1-port --network bsf1-onefs-cluster | grep "| id "| awk '{print $4}')
baremetal node vif attach --port-uuid $BSF1_PORT $ONEFS_NODE $BSF1_VIF

# Port on Backend Fabric 2
BSF2_PORT=$(baremetal port create 04:3F:72:A2:3C:BB --node $NODE_UUID --pxe-enable false --physical-network bsf2-net --local-link-connection switch_id=11:22:33:44:55:66 --local-link-connection port_id=e1000 | grep '| uuid ' | awk '{print $4}')
BSF2_VIF=$(openstack port create $ONEFS_NODE-bsf2-port --network bsf2-onefs-cluster | grep "| id "| awk '{print $4}')
baremetal node vif attach --port-uuid $BSF2_PORT $ONEFS_NODE $BSF2_VIF

# Port on Mgmt network
MGMT_PORT=$(baremetal port create $(generate_mac) --node $NODE_UUID --pxe-enable false --physical-network fsf-net --local-link-connection switch_id=11:22:33:44:55:66 --local-link-connection port_id="ethernet 1/1/1:1" --local-link-connection switch_info='{"switch_ip": "100.127.0.125", "access_mode": "access"}' | grep '| uuid ' | awk '{print $4}')
MGMT_VIF=$(openstack port create $ONEFS_NODE-mgmt-port --network fsf-mgmt-net | grep "| id "| awk '{print $4}')
baremetal node vif attach --port-uuid $MGMT_PORT $ONEFS_NODE $MGMT_VIF

# Port on Customer Data network
DATA_PORT=$(baremetal port create $(generate_mac) --node $NODE_UUID --pxe-enable false --physical-network fsf-net --local-link-connection switch_id=11:22:33:44:55:66 --local-link-connection port_id="ethernet 1/1/1:1" --local-link-connection switch_info='{"switch_ip": "100.127.0.125", "access_mode": "trunk"}' | grep '| uuid ' | awk '{print $4}')
DATA_VIF=$(openstack port create $ONEFS_NODE-cust-data-port --network fsf-cust-data-net | grep "| id "| awk '{print $4}')
baremetal node vif attach --port-uuid $DATA_PORT $ONEFS_NODE $DATA_VIF


baremetal node set $ONEFS_NODE \
    --driver-info deploy_kernel=http://$PROV_SRV/static/memdisk \
    --driver-info deploy_ramdisk=http://$PROV_SRV/static/$MFSBSD

baremetal node set $ONEFS_NODE \
    --driver-info rescue_kernel=http://$PROV_SRV/static/memdisk \
    --driver-info rescue_ramdisk=http://$PROV_SRV/static/$MFSBSD
#    --driver-info bootloader=http://$PROV_SRV/static/OneFS_v9.1.0.5_2021-03_reimg.img

baremetal node set $ONEFS_NODE --property capabilities="boot_mode:uefi"

CHECKSUM=$(md5sum /opt/stack/data/ironic/httpboot/static/$ONEFS_IMAGE | awk '{print $1}')

baremetal node set $ONEFS_NODE \
    --instance-info image_source=http://$PROV_SRV/static/$ONEFS_IMAGE \
    --instance-info image_checksum=$CHECKSUM \
    --instance-info image_type=whole-disk-image \
    --instance-info root_gb=16

# Let the baremetal agent to catch up
sleep 30

baremetal node manage $ONEFS_NODE
baremetal node provide $ONEFS_NODE
baremetal node deploy $ONEFS_NODE --config-drive http://$PROV_SRV/static/$ONEFS_NODE.cfg



