set -x

CLUSTER=$2
# SUBNET is assumed to be /20
SUBNET=$3
GW_IP=$4

if [ -z $CLUSTER ]; then
	echo "usage: $0 [create|delete] cluster subnet gateway_ip"
	echo "example: $0 create 1 192.168.16.0 192.168.16.3"
	exit
fi

if [[ $1 == 'create' ]]; then
    NET_ID=$(openstack network show fsf-cust-data-net-$CLUSTER 2>> /dev/null | grep '| id ' | awk '{print $4}')
    if [[ -z $NET_ID ]]; then
        NET_ID=$(openstack network create fsf-cust-data-net-$CLUSTER --provider-physical-network fsf-net --provider-network-type vlan  | grep '| id ' | awk '{print $4}')
        openstack subnet pool create fsf-cust-data-subnet-pool-$CLUSTER --pool-prefix $SUBNET/20 --default-prefix-length 20
        openstack subnet create fsf-cust-data-subnet-$CLUSTER --ip-version 4 --subnet-pool fsf-cust-data-subnet-pool-$CLUSTER --network fsf-cust-data-net-$CLUSTER --no-dhcp
        PORT_ID=$(openstack port create cust-data-$CLUSTER --disable-port-security --fixed-ip subnet=fsf-cust-data-subnet-$CLUSTER,ip-address=$GW_IP --network fsf-cust-data-net-$CLUSTER | grep '| id ' | awk '{print $4}')

        sudo ip link add pic${PORT_ID:0:11} type veth peer name tap${PORT_ID:0:11}
	openstack port set --binding-profile provisioning-fsf=true --host $(hostname) ${PORT_ID}

        MAC_ADDRESS=$(openstack port show cust-data-$CLUSTER | grep '| mac_address ' | awk '{print $4}')
        sudo ip link set pic${PORT_ID:0:11} address $MAC_ADDRESS
        sudo ip link set pic${PORT_ID:0:11} up
        sudo ip add add $GW_IP/20 dev pic${PORT_ID:0:11}
    fi
elif [[ $1 == 'delete' ]]; then
    PORT_ID=$(openstack port show cust-data-$CLUSTER | grep '| id ' | awk '{print $4}')
    sudo ip link delete pic${PORT_ID:0:11}
    openstack port delete cust-data-$CLUSTER
    openstack subnet delete fsf-cust-data-subnet-$CLUSTER
    openstack subnet pool delete  fsf-cust-data-subnet-pool-$CLUSTER
    openstack network delete fsf-cust-data-net-$CLUSTER
fi
