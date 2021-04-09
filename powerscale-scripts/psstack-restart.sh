if ! sudo brctl show br-ex >> /dev/null; then
    sudo systemctl stop tftpd-hpa.service
    sudo systemctl restart xinetd.service

    sudo brctl addbr br-ex
    sudo systemctl start devstack@q-agt.service
    # wait for a bit so that the agent will create the required bridge
    sleep 10

    NET_ID=$(openstack network show fsf-provisioning-net | grep '| id ' | awk '{print $4}')
    sudo ip add add 172.19.16.1/20 dev brq${NET_ID:0:11}

    NET_ID=$(openstack network show fsf-mgmt-net | grep '| id ' | awk '{print $4}')
    sudo ip add add 172.19.32.1/20 dev brq${NET_ID:0:11}

    NET_ID=$(openstack network show fsf-cust-data-net | grep '| id ' | awk '{print $4}')
    sudo ip add add 192.168.16.1/20 dev brq${NET_ID:0:11}
fi
