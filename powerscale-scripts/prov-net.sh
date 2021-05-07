set -x

if [[ $1 == 'create' ]]; then
    NET_ID=$(openstack network create fsf-provisioning-net --provider-physical-network fsf-net --provider-network-type vlan --provider-segment 2000 | grep '| id ' | awk '{print $4}')
    openstack subnet pool create fsf-provisioning-subnet-pool --pool-prefix 172.19.16.0/20 --default-prefix-length 20
    openstack subnet create fsf-provisioning-subnet --ip-version 4 --subnet-pool fsf-provisioning-subnet-pool --network fsf-provisioning-net --dhcp
    PORT_ID=$(openstack port create provisioning --disable-port-security --fixed-ip subnet=fsf-provisioning-subnet,ip-address=172.19.16.1 --network fsf-provisioning-net --dns-name psstack-provisioning-service | grep '| id ' | awk '{print $4}')

    sudo ip link add pic${PORT_ID:0:11} type veth peer name tap${PORT_ID:0:11}
    openstack port set --binding-profile provisioning-fsf=true --host $(hostname) ${PORT_ID}

    MAC_ADDRESS=$(openstack port show provisioning | grep '| mac_address ' | awk '{print $4}')
    sudo ip link set pic${PORT_ID:0:11} address $MAC_ADDRESS
	sudo ip link set pic${PORT_ID:0:11} up
    sudo ip add add 172.19.16.1/20 dev pic${PORT_ID:0:11}
elif [[ $1 == 'delete' ]]; then
    PORT_ID=$(openstack port show provisioning | grep '| id ' | awk '{print $4}')
    sudo ip link delete pic${PORT_ID:0:11}
    openstack port delete provisioning
    openstack subnet delete fsf-provisioning-subnet
    openstack subnet pool delete fsf-provisioning-subnet-pool
    openstack network delete fsf-provisioning-net
fi
