set -x
NET_ID=$(openstack network create fsf-mgmt-net --provider-physical-network fsf-net --provider-network-type vlan --provider-segment 2001 | grep '| id ' | awk '{print $4}')
openstack subnet pool create fsf-mgmt-subnet-pool --pool-prefix 172.19.32.0/20 --default-prefix-length 20
openstack subnet create fsf-mgmt-subnet --ip-version 4 --subnet-pool fsf-mgmt-subnet-pool --network fsf-mgmt-net --no-dhcp
openstack port create mgmt --fixed-ip subnet=fsf-mgmt-subnet,ip-address=172.19.32.1 --network fsf-mgmt-net
# wait for neutron l2 agent to pick up
sleep 5
sudo ip add add 172.19.32.1/20 dev brq${NET_ID:0:11}
