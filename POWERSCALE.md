# Install Devstack

## add a sudo user stack

```
sudo useradd -s /bin/bash -d /opt/stack -m stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
```

login as in below

```
sudo su - stack
```

# run stack.sh

On the service node where all the openstack services will be running:

```
cd devstack
cp local.conf.service local.conf
./stack.sh
```

It's possible that it may fail for some reasons. If it complains about not being able to mysql as in the case with Ubuntu 20.04, you may want to manually start mysql and restack

```
./unstack.sh
sudo systemctl start mysql
./stack.sh
```

`/unstack.sh` will remove all the openstack services from the host.

On a compute node where the compute service will be running:
```
cd devstack
cp local.conf.compute local.conf
./stack.sh
```

# Access openstack services on a host
On a ubuntu 20.04 host, you may add the following to your /opt/stack/.bashrc file

```
export XDG_SESSION_TYPE=x11
export DISPLAY=:0.0
source /opt/stack/devstack/openrc admin
```

There are two pre-created openstack users: admin and demo. There are also pre-created openstack projects such as demo. The demo user can only have access to the demo project. For our purpose, use admin.

# Scripts

Under /opt/stack/devstack/powerscale-scripts, there are a few scripts you can use or refer to while learning to use the openstack services for our purpose:

1. baremetal.sh: create a virtual OneFS cluster. Run the command on the service node. The only required argument is the node name. Right now, only one of node1, node2, node3 can be used.
1. restart.sh: run this script when you restart your host or restack (by ./unstack.sh; ./stack.sh)
1. rem_links.sh: run this script to cleanup the virtual network interfaces after ./unstack.sh

Before the first time running baremetal.sh on your service node, you need to login to the node with an account with which you have GCP access already configured. Then run the following command to copy the required images and machineid files:

```
gsutil -m cp -r "gs://cloud-onefs-bdl.appspot.com/static/" /opt/stack/static
sudo chown stack:stack /opt/stack/static
```

