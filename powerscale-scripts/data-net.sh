set -x
NET_ID=$(openstack network create fsf-cust-data-net --provider-physical-network fsf-net --provider-network-type vlan --provider-segment 2500 | grep '| id ' | awk '{print $4}')
openstack subnet pool create fsf-cust-data-subnet-pool --pool-prefix 192.168.16.0/20 --default-prefix-length 20
openstack subnet create fsf-cust-data-subnet --ip-version 4 --subnet-pool fsf-cust-data-subnet-pool --network fsf-cust-data-net --no-dhcp
openstack port create cust-data --fixed-ip subnet=fsf-cust-data-subnet,ip-address=192.168.16.1 --network fsf-cust-data-net
# wait for neutron l2 agent to pick up
sleep 5
sudo ip add add 192.168.16.1/20 dev brq${NET_ID:0:11}
