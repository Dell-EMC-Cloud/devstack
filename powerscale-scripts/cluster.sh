#! /bin/bash
# cluster.sh
#
# Requires inventory files created at /opt/stack/data/ironic/inventory
# A powerscale node is named as <node service tag>.rc
# Examples: 69KMK93.rc 69KLK93.rc
#
# to create a cluster:
#    ./cluster.sh create 2 slb 25gige-agg-1 192.168.16.0 pic-mfsbsd.iso agg_install.tar.gz 69KMK93 69KLK93
#
# To delete a cluster
#    ./cluster.sh delete 2 slb 25gige-agg-1 192.168.16.0 pic-mfsbsd.iso agg_install.tar.gz 69KMK93 69KLK93

set -x

OP=$1
CLUSTER_ID=$2
CLUSTER_NAME=$3
EXT_IF=$4
DATA_NET_CIDR=$5
MFSBSD_IMAGE=$6
ONEFS_IMAGE=$7

if (( $# < 8 )); then
    echo "$0 <create | delete> <cluster_id> <cluster_name> <ext_if> <data_net_cidr> <mfsbsd-image> <onefs-image> <node-1-service-tag> ..."
    exit
fi
shift 7

NODES=($@)
echo ${NODES[@]}

MGMT_NET_CIDR=172.19.32.0/20

function get_mgmt_range {
    cluster_id=$1
    cidr_parts=(${MGMT_NET_CIDR//./ })
    (( least_net_byte=${cidr_parts[2]} + $CLUSTER_ID - 1 ))
    echo "${cidr_parts[0]}.${cidr_parts[1]}.$least_net_byte.5 ${cidr_parts[0]}.${cidr_parts[1]}.$least_net_byte.254"
}

function get_data_net_info {
    cidr_parts=(${DATA_NET_CIDR//./ })
    echo "${cidr_parts[0]}.${cidr_parts[1]}.${cidr_parts[2]}.1 ${cidr_parts[0]}.${cidr_parts[1]}.${cidr_parts[2]}.4 ${cidr_parts[0]}.${cidr_parts[1]}.${cidr_parts[2]}.5 ${cidr_parts[0]}.${cidr_parts[1]}.${cidr_parts[2]}.254"
}

MGMT_RANGE=(`get_mgmt_range`)
DATA_NET_INFO=(`get_data_net_info`)

if [[ $OP == "create" ]]; then
    ./data-net.sh create $CLUSTER_NAME $DATA_NET_CIDR ${DATA_NET_INFO[0]}
    DATA_NET_VLAN=$(openstack net show fsf-cust-data-net-$CLUSTER_NAME | grep '| provider:segmentation_id ' | awk '{print $4}')
fi

CLUSTER_ACS_FNAME=/opt/stack/data/ironic/httpboot/static/cluster-${CLUSTER_NAME}.json

NODES_JSON=
for node in ${NODES[@]}; do
    if [[ -z $NODES_JSON ]]; then
        NODES_JSON=`echo {\"serial_number\":\"$node\"}`
    else
        NODES_JSON=`echo $NODES_JSON,{\"serial_number\":\"$node\"}`
    fi
done

cat > $CLUSTER_ACS_FNAME <<EOF
{
    "cluster": {
        "name": "$CLUSTER_NAME",
        "password": "a",
        "admin_user_password": "a",
        "nodes": [
            $NODES_JSON
        ],
        "timezone": {
            "abbreviation": "Eastern",
            "path": "America/New_York",
            "name": "Eastern Time Zone",
            "custom": ""
        },
        "cluster_name_nt4_compatibility": false,
        "l3_cache": {
            "ssd_l3_cache_default_enabled": false
        },
        "encoding": "utf-8",
        "override_serialno_check": true,
        "join_mode": "auto",
        "datetime": "2021/04/11 21:47:30"
    },
    "internal_networking": {
        "internal_interfaces": [
            {
                "interface": "int-a",
                "netmask": "255.255.255.0",
                "ip_address_ranges": [
                    {
                        "high": "128.221.252.8",
                        "low": "128.221.252.1"
                    }
                ]
            },
            {
                "interface": "int-b",
                "netmask": "255.255.255.0",
                "ip_address_ranges": [
                    {
                        "high": "128.221.253.8",
                        "low": "128.221.253.1"
                    }
                ],
                "failover_interface": [
                    {
                        "high": "128.221.254.8",
                        "low": "128.221.254.1"
                    }
                ]
            }
        ],
        "internal_mtu": 9000
    },
    "external_networking": {
        "internal_as_external": false,
        "external_interfaces": [
            {
                "interface": "$EXT_IF",
                "netmask": "255.255.224.0",
                "ip_address_ranges": [
                    {
                        "high": "${MGMT_RANGE[1]}",
                        "low": "${MGMT_RANGE[0]}"
                    }
                ],
                "gateway": "172.19.32.1",
                "mtu": 1500
            }
        ],
        "smartconnect": {
            "service_addr": "172.19.32.4",
            "zone": "mgmt.pic.com"
        }
    },
    "post_cluster": {
        "post_install_commands": {
            "cmd": "isi network groupnet create groupnet-data \n sleep 5 \n isi zone zones create customer-az /ifs/customer-data --create-path --groupnet groupnet-data \n isi auth users modify Guest --enabled yes --zone customer-az \n isi auth users create admin --enabled yes --password admin --provider local --zone customer-az \n isi auth roles modify --zone customer-az ZoneAdmin --add-user admin \n isi auth roles modify --zone customer-az ZoneSecurityAdmin --add-user admin \n isi network subnets create groupnet-data.cust-data-subnet ipv4 255.255.224.0 --vlan-enabled true --vlan-id $DATA_NET_VLAN --sc-service-addr ${DATA_NET_INFO[1]} \n isi network pools create groupnet-data.cust-data-subnet.pool-data --access-zone customer-az --ranges ${DATA_NET_INFO[2]}-${DATA_NET_INFO[3]} --ifaces 1:$EXT_IF\n"
        }
    }
}
EOF

NODE_SCRIPT=onefs-node.sh
if [[ "$EXT_IF" == *agg* ]]; then
    NODE_SCRIPT=port-channel-onefs-node.sh
fi
if [[ $OP == "create" ]]; then
    ./$NODE_SCRIPT uefi ${NODES[0]} $MFSBSD_IMAGE $ONEFS_IMAGE fsf-cust-data-net-$CLUSTER_NAME cluster-${CLUSTER_NAME}.json &
    (( LAST=${#NODES[@]} - 1 ))
    if [[ $LAST != 0 ]]; then
        for i in $(seq 1 $LAST); do
            ./$NODE_SCRIPT uefi ${NODES[$i]} $MFSBSD_IMAGE $ONEFS_IMAGE fsf-cust-data-net-$CLUSTER_NAME &
        done
    fi
else
    echo ${NODES[@]}
    for node in ${NODES[@]}; do
        ./$NODE_SCRIPT delete $node $MFSBSD_IMAGE $ONEFS_IMAGE fsf-cust-data-net-$CLUSTER_NAME &
    done
    wait
    ./data-net.sh delete $CLUSTER_NAME $DATA_NET_CIDR ${DATA_NET_INFO[0]}
fi
