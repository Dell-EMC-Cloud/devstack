#! /bin/bash
# baremetal.sh <node>

set -x

function generate_mac {
  hexchars="0123456789abcdef"
  echo "fa:16:3e$(
    for i in {1..6}; do 
      echo -n ${hexchars:$(( $RANDOM % 16 )):1}
    done | sed -e 's/\(..\)/:\1/g'
  )"
}

MACHINE_DIR=/opt/stack/machines

function create_vm {
    vm_name=$1
    vmdir=$2
    vmxml=$3
    mgmt_br=$4
    mgmt_mac1=$5
    mgmt_mac2=$6
    be_br=$7
    be_mac=$8
    fe_br=$9
    fe_mac=${10}

    vm_uuid=$(uuidgen)
    qemu-img create -f qcow2 $vmdir/disk0.qcow2 16G
    qemu-img create -f qcow2 $vmdir/disk1.qcow2 30G
    qemu-img create -f qcow2 $vmdir/disk2.qcow2 30G
    qemu-img create -f qcow2 $vmdir/disk3.qcow2 30G
    qemu-img create -f qcow2 $vmdir/disk4.qcow2 30G
    qemu-img create -f qcow2 $vmdir/disk5.qcow2 30G    
    
    cat > $vmxml <<-EOF
	<domain type='kvm'>
	  <name>$vm_name</name>
	  <uuid>$vm_uuid</uuid>
	  <memory unit='KiB'>3097152</memory>
	  <currentMemory unit='KiB'>3097152</currentMemory>
	  <vcpu placement='static'>1</vcpu>
	  <os>
	    <type arch='x86_64' machine='pc-i440fx-2.7'>hvm</type>
	    <boot dev='network'/>
	    <bootmenu enable='no'/>
	    <bios useserial='yes' rebootTimeout='10000'/>
	  </os>
	  <features>
	    <acpi/>
	    <apic/>
	    <vmport state='off'/>
	  </features>
	  <cpu mode='host-model' check='partial'/>
	  <clock offset='utc'>
	    <timer name='rtc' tickpolicy='catchup'/>
	    <timer name='pit' tickpolicy='delay'/>
	    <timer name='hpet' present='no'/>
	  </clock>
	  <on_poweroff>destroy</on_poweroff>
	  <on_reboot>restart</on_reboot>
	  <on_crash>restart</on_crash>
	  <pm>
	    <suspend-to-mem enabled='no'/>
	    <suspend-to-disk enabled='no'/>
	  </pm>
	  <devices>
	    <emulator>/usr/bin/qemu-system-x86_64</emulator>
	    <disk type='file' device='disk'>
	      <driver name='qemu' type='qcow2' cache='writethrough'/>
	      <source file='$vmdir/disk0.qcow2'/>
	      <target dev='sda' bus='scsi'/>
	      <address type='drive' controller='0' bus='0' target='1' unit='0'/>
	    </disk>
	    <disk type='file' device='disk'>
	      <driver name='qemu' type='qcow2' cache='writethrough'/>
	      <source file='$vmdir/disk1.qcow2'/>
	      <target dev='sdb' bus='scsi'/>
	      <address type='drive' controller='0' bus='0' target='2' unit='0'/>
	    </disk>
	    <disk type='file' device='disk'>
	      <driver name='qemu' type='qcow2' cache='writethrough'/>
	      <source file='$vmdir/disk2.qcow2'/>
	      <target dev='sdc' bus='scsi'/>
	      <address type='drive' controller='0' bus='0' target='3' unit='0'/>
	    </disk>
	    <disk type='file' device='disk'>
	      <driver name='qemu' type='qcow2' cache='writethrough'/>
	      <source file='$vmdir/disk3.qcow2'/>
	      <target dev='sdd' bus='scsi'/>
	      <address type='drive' controller='0' bus='0' target='4' unit='0'/>
	    </disk>
	    <disk type='file' device='disk'>
	      <driver name='qemu' type='qcow2' cache='writethrough'/>
	      <source file='$vmdir/disk4.qcow2'/>
	      <target dev='sdh' bus='scsi'/>
	      <address type='drive' controller='0' bus='0' target='5' unit='0'/>
	    </disk>
	    <disk type='file' device='disk'>
	      <driver name='qemu' type='qcow2' cache='writethrough'/>
	      <source file='$vmdir/disk5.qcow2'/>
	      <target dev='sdi' bus='scsi'/>
	      <address type='drive' controller='0' bus='0' target='6' unit='0'/>
	    </disk>
	    <controller type='usb' index='0' model='ich9-ehci1'>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x7'/>
	    </controller>
	    <controller type='usb' index='0' model='ich9-uhci1'>
	      <master startport='0'/>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0' multifunction='on'/>
	    </controller>
	    <controller type='usb' index='0' model='ich9-uhci2'>
	      <master startport='2'/>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x1'/>
	    </controller>
	    <controller type='usb' index='0' model='ich9-uhci3'>
	      <master startport='4'/>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x2'/>
	    </controller>
	    <controller type='scsi' index='0' model='virtio-scsi'>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0'/>
	    </controller>
	    <controller type='scsi' index='1' model='virtio-scsi'>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x09' function='0x0'/>
	    </controller>
	    <controller type='pci' index='0' model='pci-root'/>
	    <controller type='virtio-serial' index='0'>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x0a' function='0x0'/>
	    </controller>
	    <controller type='ide' index='0'>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
	    </controller>
	    <interface type='bridge'>
	      <mac address='$mgmt_mac1'/>
	      <source bridge='$mgmt_br'/>
	      <model type='e1000'/>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
	    </interface>
	    <interface type='bridge'>
	      <mac address='$mgmt_mac2'/>
	      <source bridge='$mgmt_br'/>
	      <model type='e1000'/>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x0c' function='0x0'/>
	    </interface>
	    <interface type='bridge'>
	      <mac address='$be_mac'/>
	      <source bridge='$be_br'/>
	      <model type='virtio'/>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x04' function='0x0'/>
	    </interface>
	    <interface type='bridge'>
	      <mac address='$fe_mac'/>
	      <source bridge='$fe_br'/>
	      <model type='virtio'/>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
	    </interface>
	    <serial type='pty'>
	      <target type='isa-serial' port='0'>
		<model name='isa-serial'/>
	      </target>
	    </serial>
	    <console type='pty'>
	      <target type='serial' port='0'/>
	    </console>
	    <channel type='spicevmc'>
	      <target type='virtio' name='com.redhat.spice.0'/>
	      <address type='virtio-serial' controller='0' bus='0' port='1'/>
	    </channel>
	    <input type='mouse' bus='ps2'/>
	    <input type='keyboard' bus='ps2'/>
	    <graphics type='spice' autoport='yes'>
	      <listen type='address'/>
	      <image compression='off'/>
	    </graphics>
	    <sound model='ich6'>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
	    </sound>
	    <video>
	      <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
	    </video>
	    <redirdev bus='usb' type='spicevmc'>
	      <address type='usb' bus='0' port='1'/>
	    </redirdev>
	    <redirdev bus='usb' type='spicevmc'>
	      <address type='usb' bus='0' port='2'/>
	    </redirdev>
	    <memballoon model='virtio'>
	      <address type='pci' domain='0x0000' bus='0x00' slot='0x0b' function='0x0'/>
	    </memballoon>
	  </devices>
	</domain>
EOF
    virsh define $vmxml
}

if [[ -z "$1" ]]; then
	echo "baremetal.sh <nodename>"
	exit 1
fi

NODE=$1
MACHINEID=${NODE:4}


MGMT_NET_ID=$(openstack net list | grep private | awk '{print $2}')
BE_NET_ID=$(openstack net list | grep onefs-be | awk '{print $2}')
FE_NET_ID=$(openstack net list | grep onefs-fe | awk '{print $2}')

MGMT_BR=brq${MGMT_NET_ID:0:11}
BE_BR=brq${BE_NET_ID:0:11}
FE_BR=brq${FE_NET_ID:0:11}

MGMT_MAC1=$(generate_mac)
MGMT_MAC2=$(generate_mac)
BE_MAC=$(generate_mac)
FE_MAC=$(generate_mac)

VMDIR=$MACHINE_DIR/$NODE
VMXML=$VMDIR/$NODE.xml
OLD_MGMTMAC=$(grep 'mac address' ${VMXML} | head -n 1 | cut -d "'" -f2)

if [ -d $VMDIR ]; then
    virsh destroy $NODE 2>> /dev/null
    virsh undefine $NODE 2>> /dev/null
    sudo rm -rf $VMDIR
fi
mkdir -p $VMDIR

baremetal node maintenance set $NODE 2>> /dev/null
baremetal node delete $NODE 2>> /dev/null
create_vm $NODE $VMDIR $VMXML $MGMT_BR $MGMT_MAC1 $MGMT_MAC2 $BE_BR $BE_MAC $FE_BR $FE_MAC

if vbmc show $NODE; then
    vbmc delete $NODE
fi

echo "add $NODE to vbmc"
IPMIPORT=`shuf -i 1200-2000 -n 1`
while ! vbmc add $NODE --port $IPMIPORT; do
	IPMIPORT=`shuf -i 1200-2000 -n 1`
done
vbmc start $NODE



NODE_UUID=$(baremetal node create --name $NODE --driver ipmi --deploy-interface direct --rescue-interface agent | grep '| uuid ' | awk '{print $4}')

baremetal node set $NODE \
    --driver-info ipmi_username=admin \
    --driver-info ipmi_password=password \
    --driver-info ipmi_address=localhost \
    --driver-info ipmi_port=$IPMIPORT

baremetal port create $MGMT_MAC1 --node $NODE_UUID --pxe-enable true --physical-network test-net --local-link-connection switch_id=11:22:33:44:55:66 --local-link-connection port_id=e1000

if [[ -n $OLD_MGMTMAC ]]; then
    PROVISION_VIF=$(openstack port list | grep $OLD_MGMTMAC |  awk '{print $2}')

    if [[ -n $PROVISION_VIF ]]; then
       openstack port delete $PROVISION_VIF
    fi
fi

openstack port delete $NODE-mgmt-port 2>> /dev/null
MGMT_VIF=$(openstack port create $NODE-mgmt-port --network private | grep "| id "| awk '{print $4}')

MGMT_PORT=$(baremetal port create $MGMT_MAC2 --node $NODE_UUID --pxe-enable false --physical-network test-net --local-link-connection switch_id=11:22:33:44:55:66 --local-link-connection port_id=e1000 | grep '| uuid ' | awk '{print $4}')

baremetal node vif attach --port-uuid $MGMT_PORT $NODE $MGMT_VIF



baremetal node set $NODE \
    --driver-info deploy_kernel=http://172.19.1.1:3928/static/memdisk \
    --driver-info deploy_ramdisk=http://172.19.1.1:3928/static/ipa-mfsbsd-em0.img

baremetal node set $NODE \
    --driver-info rescue_kernel=http://172.19.1.1:3928/static/memdisk \
    --driver-info rescue_ramdisk=http://172.19.1.1:3928/static/ipa-mfsbsd-em0.img

CHECKSUM=$(md5sum /opt/stack/data/ironic/httpboot/static/install.tar.gz | awk '{print $1}')

baremetal node set $NODE \
    --instance-info image_source=http://172.19.1.1:3928/static/install.tar.gz \
    --instance-info image_checksum=$CHECKSUM \
    --instance-info image_type=whole-disk-image \
    --instance-info root_gb=16

# Let the baremetal agent to catch up
sleep 30

baremetal node manage $NODE
baremetal node provide $NODE
baremetal node deploy $NODE --config-drive http://172.19.1.1:3928/static/machineid_${MACHINEID}



