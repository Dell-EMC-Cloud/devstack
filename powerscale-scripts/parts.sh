# ls /dev/mirror
# gmirror destroy <mirrored device list in above>
# gpart delete -i <partition id> da1
# gpart delete -i <partition id> da4

gpart add -i 1 -t isilon-scratch -a 512B -b 50333696 -s 53686784B -l scratch da1
gpart add -i 2 -t isilon-ifs -a 512B -b 50446336 -s 3814927106048B -l ifs da1
gpart add -i 3 -t freebsd-ufs -a 512B -b 2048 -s 8589934592B -l journal-backup da1
gpart add -i 4 -t isilon-bootdiskid -a 512B -b 40 -s 512B -l bootdiskid da1
gpart add -i 5 -t freebsd-ufs -a 512B -b 16779264 -s 3221225472B -l var-crash da1
gpart add -i 6 -t isilon-kerneldump -a 512B -b 23070720 -s 2147483648B -l kerneldump da1
gpart add -i 7 -t freebsd-ufs -a 512B -b 27265024 -s 2147483648B -l root1 da1
gpart set -i 7 -a isi_active da1
gpart set -i 7 -a bootme da1
gpart add -i 8 -t efi -a 512B -b 31459328 -s 293601280B -l efi-boot da1
gpart add -i 9 -t freebsd-ufs -a 512B -b 32032768 -s 2147483648B -l root0 da1
gpart add -i 10 -t freebsd-ufs -a 512B -b 36227072 -s 1073741824B -l var1 da1
gpart add -i 11 -t freebsd-ufs -a 512B -b 38324224 -s 1073741824B -l var0 da1
gpart add -i 12 -t freebsd-ufs -a 512B -b 40421376 -s 524288000B -l hw da1
gpart add -i 13 -t freebsd-ufs -a 512B -b 41445376 -s 67108864B -l mfg da1
gpart add -i 14 -t isilon-kernelsdump -a 512B -b 41576448 -s 67108864B -l kernelsdump da1
gpart add -i 15 -t freebsd-ufs -a 512B -b 41707520 -s 67108864B -l keystore da1

gpart add -i 1 -t isilon-scratch -a 512B -b 50333696 -s 53686784B -l scratch da2
gpart add -i 2 -t isilon-ifs -a 512B -b 50446336 -s 3814927106048B -l ifs da2

gpart add -i 1 -t isilon-scratch -a 512B -b 50333696 -s 53686784B -l scratch da3
gpart add -i 2 -t isilon-ifs -a 512B -b 50446336 -s 3814927106048B -l ifs da3

gpart add -i 1 -t isilon-scratch -a 512B -b 50333696 -s 53686784B -l scratch da4
gpart add -i 2 -t isilon-ifs -a 512B -b 50446336 -s 3814927106048B -l ifs da4
gpart add -i 3 -t freebsd-ufs -a 512B -b 2048 -s 8589934592B -l journal-backup da4
gpart add -i 4 -t isilon-bootdiskid -a 512B -b 40 -s 512B -l bootdiskid da4
gpart add -i 5 -t freebsd-ufs -a 512B -b 16779264 -s 3221225472B -l var-crash da4
gpart add -i 6 -t freebsd-ufs -a 512B -b 23070720 -s 2147483648B -l root1 da4
gpart set -i 6 -a isi_active da4
gpart set -i 6 -a bootme da4
gpart add -i 7 -t efi -a 512B -b 27265024 -s 293601280B -l efi-boot da4
gpart add -i 8 -t freebsd-ufs -a 512B -b 27838464 -s 2147483648B -l root0 da4
gpart add -i 9 -t freebsd-ufs -a 512B -b 32032768 -s 1073741824B -l var1 da4
gpart add -i 10 -t freebsd-ufs -a 512B -b 34129920 -s 1073741824B -l var0 da4
gpart add -i 11 -t freebsd-ufs -a 512B -b 36227072 -s 524288000B -l hw da4
gpart add -i 12 -t freebsd-ufs -a 512B -b 37251072 -s 67108864B -l mfg da4
gpart add -i 13 -t freebsd-ufs -a 512B -b 37382144 -s 67108864B -l keystore da4

gmirror label -b load -s 4096 root1 da1p7 da4p6
gmirror label -b load -s 4096 keystore da4p13 da1p15
gmirror label -b load -s 4096 mfg da4p12 da1p13
gmirror label -b load -s 4096 hw da4p11 da1p12
gmirror label -b load -s 4096 var0 da4p10 da1p11
gmirror label -b load -s 4096 var1 da4p9 da1p10
gmirror label -b load -s 4096 root0 da4p8 da1p9
gmirror label -b load -s 4096 var-crash da4p5 da1p5
gmirror label -b load -s 4096 journal-backup da4p3 da1p3
gmirror label -b load -s 4096 kernelsdump da1p14
gmirror label -b load -s 4096 kerneldump da1p6

# Recover MFG partition
# newfs -U /dev/mirror/mfg
# mount /dev/mirror/mfg /mnt
# mkdir /mnt/psi
# fetch http://172.19.16.1:3928/static/psf.json --output /mnt/psi/psf.json
# umount /mnt
# 
# In the case that mfs is damaged, repair it with
# fsck /dev/mirror/mfg
#
# After recover:
# /usr/bin/isi_hwtools/isi_psi_tool -v
# 
isi-bsd# /usr/bin/isi_hwtools/isi_psi_tool -v                                                                                                              
{                                                                                                                                                          
    "NETWORK": [                                                                                                                                           
        "NETWORK_25GBE_PCI_SLOT1",                                                                                                                         
        "NETWORK_25GBE_PCI_RNDC"                                                                                                                           
    ],                                                                                                                                                     
    "PLATFORM_TYPE": "PLATFORM_PER640",                                                                                                                    
    "JOURNAL": "JOURNAL_NVDIMM_1x16GB",                                                                                                                    
    "DRIVES": [                                                                                                                                            
        "DRIVES_4x3840GB(ssd)"                                                                                                                             
    ],                                                                                                                                                     
    "PLATFORM": "PLATFORM_PE",                                                                                                                             
    "MEMORY": "MEMORY_DIMM_6x16GB",                                                                                                                        
    "PLATFORM_MODEL": "MODEL_F200"                                                                                                                         
}                                       
