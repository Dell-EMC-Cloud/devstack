SEGMENT_ID=$(openstack network create bsf1-onefs-cluster --provider-physical-network bsf1-net --provider-network-type vlan | grep provider:segmentation_id | awk '{print $4}')
openstack subnet pool create bsf1-onefs-cluster-subnet-pool --pool-prefix 172.20.16.0/20 --default-prefix-length 20
openstack subnet create bsf1-onefs-cluster-subnet --ip-version 4 --subnet-pool bsf1-onefs-cluster-subnet-pool --network bsf1-onefs-cluster --no-dhcp
openstack port create bsf1-onefs-cluster-port --network bsf1-onefs-cluster

openstack network create bsf2-onefs-cluster --provider-physical-network bsf2-net --provider-network-type vlan  --provider-segment $SEGMENT_ID
openstack subnet pool create bsf2-onefs-cluster-subnet-pool --pool-prefix 172.20.16.0/20 --default-prefix-length 20
openstack subnet create bsf2-onefs-cluster-subnet --ip-version 4 --subnet-pool bsf2-onefs-cluster-subnet-pool --network bsf2-onefs-cluster --no-dhcp
openstack port create bsf2-onefs-cluster-port --network bsf2-onefs-cluster
