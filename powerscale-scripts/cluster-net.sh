set -x

CLUSTER=$2

if [ -z $CLUSTER ]; then
	echo "usage: $0 [create|delete] cluster"
	echo "example: $0 create 1"
	exit
fi

if [[ $1 == 'create' ]]; then
    NET_ID=$(openstack network show bsf1-onefs-$CLUSTER 2>> /dev/null | grep '| id ' | awk '{print $4}')
    if [[ -z $NET_ID ]]; then
        SEGMENT_ID=$(openstack network create bsf1-onefs-$CLUSTER --provider-physical-network bsf1-net --provider-network-type vlan | grep provider:segmentation_id | awk '{print $4}')
        openstack subnet pool create bsf1-onefs-$CLUSTER-subnet-pool --pool-prefix 172.20.16.0/20 --default-prefix-length 20
        openstack subnet create bsf1-onefs-$CLUSTER-subnet --ip-version 4 --subnet-pool bsf1-onefs-$CLUSTER-subnet-pool --network bsf1-onefs-$CLUSTER --no-dhcp
#        openstack port create bsf1-onefs-$CLUSTER-port --network bsf1-onefs-$CLUSTER
        
        openstack network create bsf2-onefs-$CLUSTER --provider-physical-network bsf2-net --provider-network-type vlan  --provider-segment $SEGMENT_ID
        openstack subnet pool create bsf2-onefs-$CLUSTER-subnet-pool --pool-prefix 172.20.16.0/20 --default-prefix-length 20
        openstack subnet create bsf2-onefs-$CLUSTER-subnet --ip-version 4 --subnet-pool bsf2-onefs-$CLUSTER-subnet-pool --network bsf2-onefs-$CLUSTER --no-dhcp
#        openstack port create bsf2-onefs-$CLUSTER-port --network bsf2-onefs-$CLUSTER
    fi
elif [[ $1 == 'delete' ]]; then
#    openstack port delete bsf1-onefs-$CLUSTER-port
    openstack subnet delete bsf1-onefs-$CLUSTER-subnet
    openstack subnet pool delete bsf1-onefs-$CLUSTER-subnet-pool
    openstack network delete bsf1-onefs-$CLUSTER

#    openstack port delete bsf2-onefs-$CLUSTER-port
    openstack subnet delete bsf2-onefs-$CLUSTER-subnet
    openstack subnet pool delete bsf2-onefs-$CLUSTER-subnet-pool
    openstack network delete bsf2-onefs-$CLUSTER
fi


