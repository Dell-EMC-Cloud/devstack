set -x
NET_ID=$(openstack network create fsf-provisioning-net --provider-physical-network fsf-net --provider-network-type vlan --provider-segment 2000 | grep '| id ' | awk '{print $4}')
openstack subnet pool create fsf-provisioning-subnet-pool --pool-prefix 172.19.16.0/20 --default-prefix-length 20
openstack subnet create fsf-provisioning-subnet --ip-version 4 --subnet-pool fsf-provisioning-subnet-pool --network fsf-provisioning-net --dhcp
openstack port create provisioning --fixed-ip subnet=fsf-provisioning-subnet,ip-address=172.19.16.1 --network fsf-provisioning-net
# wait for neutron l2 agent to pick up
sleep 5
sudo ip add add 172.19.16.1/20 dev brq${NET_ID:0:11}
