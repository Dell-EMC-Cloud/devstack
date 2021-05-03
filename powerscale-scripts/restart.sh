# in case of stacking/restacking
openstack network create onefs-fe --provider-physical-network test-net --provider-network-type vlan
openstack subnet pool create onefs-fe-subnet-pool --pool-prefix 172.19.10.0/24 --default-prefix-length 26
openstack subnet create onefs-fe-subnet --ip-version 4 --subnet-pool onefs-fe-subnet-pool --network onefs-fe --dhcp
openstack port create c1-fe-port --network onefs-fe
openstack subnet set onefs-fe-subnet --no-dhcp

openstack network create onefs-be --provider-physical-network test-net --provider-network-type vlan
openstack subnet pool create onefs-be-subnet-pool --pool-prefix 172.19.20.0/24 --default-prefix-length 26
openstack subnet create onefs-be-subnet --ip-version 4 --subnet-pool onefs-be-subnet-pool --network onefs-be --dhcp
openstack port create c1-be-port --network onefs-be
openstack subnet set onefs-be-subnet --no-dhcp


ROUTER_ID=$(openstack router list | grep router1 | awk '{print $2}')
PORT_ID=$(openstack port list | grep "'172.19.1.1'" | awk '{print $2}')
NET_ID=$(openstack net list | grep private | awk '{print $2}')

sudo ip netns exec qrouter-${ROUTER_ID} ip add delete 172.19.1.1/26 dev qr-${PORT_ID:0:11}
sudo brctl delif brq${NET_ID:0:11} tap${PORT_ID:0:11}
sudo ip add add 172.19.1.1/26 dev brq${NET_ID:0:11}

# set dns-name
openstack port set --dns-name psstack-provisioning-service $PORT_ID

# in case there is another compute node
nova-manage cell_v2 discover_hosts --verbose

# Copy required images/machineid files 
# gsutil -m cp -r "gs://cloud-onefs-bdl.appspot.com/static/" /opt/stack/static
cp -r /opt/stack/static /opt/stack/data/ironic/httpboot

# If the host gets restarted, execute the following
if ! sudo brctl show br-ex >> /dev/null; then
    sudo brctl addbr br-ex
    sudo systemctl start devstack@q-agt.service
    openstack subnet set onefs-be-subnet --dhcp
    openstack subnet set onefs-be-subnet --no-dhcp
    openstack subnet set onefs-fe-subnet --dhcp
    openstack subnet set onefs-fe-subnet --no-dhcp
fi
