set -x

if [[ $1 == 'create' ]]; then
    NET_ID=$(openstack network create fsf-cust-data-net --provider-physical-network fsf-net --provider-network-type vlan --provider-segment 2500 | grep '| id ' | awk '{print $4}')
    openstack subnet pool create fsf-cust-data-subnet-pool --pool-prefix 192.168.16.0/20 --default-prefix-length 20
    openstack subnet create fsf-cust-data-subnet --ip-version 4 --subnet-pool fsf-cust-data-subnet-pool --network fsf-cust-data-net --no-dhcp
    PORT_ID=$(openstack port create cust-data --disable-port-security --fixed-ip subnet=fsf-cust-data-subnet,ip-address=192.168.16.3 --network fsf-cust-data-net | grep '| id ' | awk '{print $4}')

    sudo ip link add pic${PORT_ID:0:11} type veth peer name tap${PORT_ID:0:11}
    openstack port set --binding-profile provisioning-fsf=true --host pic-1 ${PORT_ID}

    MAC_ADDRESS=$(openstack port show cust-data | grep '| mac_address ' | awk '{print $4}')
    sudo ip link set pic${PORT_ID:0:11} address $MAC_ADDRESS
    sudo ip link set pic${PORT_ID:0:11} up
    sudo ip add add 192.168.16.3/20 dev pic${PORT_ID:0:11}
elif [[ $1 == 'delete' ]]; then
    PORT_ID=$(openstack port show cust-data | grep '| id ' | awk '{print $4}')
    sudo ip link delete pic${PORT_ID:0:11}
    openstack port delete cust-data
    openstack subnet delete fsf-cust-data-subnet
    openstack subnet pool delete  fsf-cust-data-subnet-pool
    openstack network delete fsf-cust-data-net
fi
