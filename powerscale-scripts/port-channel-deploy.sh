#! /bin/bash
# port-channel-deploy.sh

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

if [[ -z "$OP" || -z "$2" || ($OP != 'bios' && $OP != 'uefi' && $OP != 'delete') || (( $# < 7 )) ]]; then
    echo "$0 <bios|uefi|delete> <node> <mfsbsd-image> <onefs-image> <data-network> <bsf1-network> <bsf2-network> <acs>"
    exit 1
fi

ONEFS_NODE=$2
source /opt/stack/data/ironic/inventory/$ONEFS_NODE.rc

MFSBSD=$3
ONEFS_IMAGE=$4
DATA_NETWORK=$5
BSF1_NETWORK=$6
BSF2_NETWORK=$7
CONFIG_DRIVE=$8

PROV_SRV=172.19.16.1:3928

./port-channel-enroll.sh uefi $ONEFS_NODE
openstack port delete $ONEFS_NODE-bsf1-port 2>> /dev/null
openstack port delete $ONEFS_NODE-bsf2-port 2>> /dev/null
openstack port delete $ONEFS_NODE-mgmt-port 2>> /dev/null
openstack port delete $ONEFS_NODE-cust-data-port 2>> /dev/null

if [[ $OP == 'delete' ]]; then
    exit
fi

NODE_UUID=$(openstack baremetal node list | grep $ONEFS_NODE | awk '{print $2}')

# Port on Backend Fabric 1
BSF1_PORT=$(openstack baremetal port list --node $NODE_UUID --field uuid --field physical_network | grep bsf1-net | awk '{print $2}')
BSF1_VIF=$(openstack port create $ONEFS_NODE-bsf1-port --network $BSF1_NETWORK | grep "| id "| awk '{print $4}')
baremetal node vif attach --port-uuid $BSF1_PORT $ONEFS_NODE $BSF1_VIF

# Port on Backend Fabric 2
BSF2_PORT=$(openstack baremetal port list --node $NODE_UUID --field uuid --field physical_network | grep bsf2-net | awk '{print $2}')
BSF2_VIF=$(openstack port create $ONEFS_NODE-bsf2-port --network $BSF2_NETWORK | grep "| id "| awk '{print $4}')
baremetal node vif attach --port-uuid $BSF2_PORT $ONEFS_NODE $BSF2_VIF

# Port on Mgmt network
MGMT_PGP_ID=$(openstack baremetal port group list | grep ${ONEFS_NODE}-mgmt-pgp | awk '{print $2}')


MGMT_VIF=$(openstack port create $ONEFS_NODE-mgmt-port --network fsf-mgmt-net | grep "| id "| awk '{print $4}')
baremetal node vif attach --vif-info portgroup-uuid=$MGMT_PGP_ID $ONEFS_NODE $MGMT_VIF

# Port on Customer Data network
DATA_PGP_ID=$(openstack baremetal port group list | grep ${ONEFS_NODE}-data-pgp | awk '{print $2}')


DATA_VIF=$(openstack port create $ONEFS_NODE-cust-data-port --network $DATA_NETWORK | grep "| id "| awk '{print $4}')
baremetal node vif attach --vif-info portgroup-uuid=$DATA_PGP_ID $ONEFS_NODE $DATA_VIF


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


if [[ -n $CONFIG_DRIVE ]]; then
    baremetal node deploy $ONEFS_NODE --config-drive http://$PROV_SRV/static/$CONFIG_DRIVE
else
    baremetal node deploy $ONEFS_NODE
fi

