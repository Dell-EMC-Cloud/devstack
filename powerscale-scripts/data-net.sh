set -x

NODE=$2
VLAN=$3
SUBNET=$4
FIXED_IP=$5

if [ -z $NODE ]; then
	echo "usage: $0 [create|delete] node_id vlan subnet fixed_ip"
	echo "example: $0 create 1 2500 192.168.16.0 192.168.16.3"
	exit
fi

if [[ $1 == 'create' ]]; then
    NET_ID=$(openstack network create fsf-cust-data-net-$NODE --provider-physical-network fsf-net --provider-network-type vlan --provider-segment $VLAN | grep '| id ' | awk '{print $4}')
    openstack subnet pool create fsf-cust-data-subnet-pool-$NODE --pool-prefix $SUBNET/20 --default-prefix-length 20
    openstack subnet create fsf-cust-data-subnet-$NODE --ip-version 4 --subnet-pool fsf-cust-data-subnet-pool-$NODE --network fsf-cust-data-net-$NODE --no-dhcp
    PORT_ID=$(openstack port create cust-data-$NODE --disable-port-security --fixed-ip subnet=fsf-cust-data-subnet-$NODE,ip-address=$FIXED_IP --network fsf-cust-data-net-$NODE | grep '| id ' | awk '{print $4}')

    sudo ip link add pic${PORT_ID:0:11} type veth peer name tap${PORT_ID:0:11}
    openstack port set --binding-profile provisioning-fsf=true --host pic-1 ${PORT_ID}

    MAC_ADDRESS=$(openstack port show cust-data-$NODE | grep '| mac_address ' | awk '{print $4}')
    sudo ip link set pic${PORT_ID:0:11} address $MAC_ADDRESS
    sudo ip link set pic${PORT_ID:0:11} up
    sudo ip add add $FIXED_IP/20 dev pic${PORT_ID:0:11}
elif [[ $1 == 'delete' ]]; then
    PORT_ID=$(openstack port show cust-data-$NODE | grep '| id ' | awk '{print $4}')
    sudo ip link delete pic${PORT_ID:0:11}
    openstack port delete cust-data-$NODE
    openstack subnet delete fsf-cust-data-subnet-$NODE
    openstack subnet pool delete  fsf-cust-data-subnet-pool-$NODE
    openstack network delete fsf-cust-data-net-$NODE
fi
