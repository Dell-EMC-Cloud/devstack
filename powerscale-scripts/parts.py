parts = [
    {
        "index": 1,
        "type": "isilon-scratch",
        "alignment": "512B",
        "start": 50333696,
        "size": "53686784B",
        "label": "scratch",
        "geom": "da1",
    },
    {
        "index": 2,
        "type": "isilon-ifs",
        "alignment": "512B",
        "start": 50446336,
        "size": "3814927106048B",
        "label": "ifs",
        "geom": "da1",
    },
    {
        "index": 3,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 2048,
        "size": "8589934592B",
        "label": "journal-backup",
        "geom": "da1",
    },
    {
        "index": 4,
        "type": "isilon-bootdiskid",
        "alignment": "512B",
        "start": 40,
        "size": "512B",
        "label": "bootdiskid",
        "geom": "da1",
    },
    {
        "index": 5,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 16779264,
        "size": "3221225472B",
        "label": "var-crash",
        "geom": "da1",
    },
    {
        "index": 6,
        "type": "isilon-kerneldump",
        "alignment": "512B",
        "start": 23070720,
        "size": "2147483648B",
        "label": "kerneldump",
        "geom": "da1",
    },
    {
        "index": 7,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 27265024,
        "size": "2147483648B",
        "label": "root1",
        "attrib": ["isi_active", "bootme"],
        "geom": "da1",
    },
    {
        "index": 8,
        "type": "efi",
        "alignment": "512B",
        "start": 31459328,
        "size": "293601280B",
        "label": "efi-boot",
        "geom": "da1",
    },
    {
        "index": 9,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 32032768,
        "size": "2147483648B",
        "label": "root0",
        "geom": "da1",
    },
    {
        "index": 10,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 36227072,
        "size": "1073741824B",
        "label": "var1",
        "geom": "da1",
    },
    {
        "index": 11,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 38324224,
        "size": "1073741824B",
        "label": "var0",
        "geom": "da1",
    },
    {
        "index": 12,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 40421376,
        "size": "524288000B",
        "label": "hw",
        "geom": "da1",
    },
    {
        "index": 13,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 41445376,
        "size": "67108864B",
        "label": "mfg",
        "geom": "da1",
    },
    {
        "index": 14,
        "type": "isilon-kernelsdump",
        "alignment": "512B",
        "start": 41576448,
        "size": "67108864B",
        "label": "kernelsdump",
        "geom": "da1",
    },
    {
        "index": 15,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 41707520,
        "size": "67108864B",
        "label": "keystore",
        "geom": "da1",
    },

    {
        "index": 1,
        "type": "isilon-scratch",
        "alignment": "512B",
        "start": 50333696,
        "size": "53686784B",
        "label": "scratch",
        "geom": "da2",
    },
    {
        "index": 2,
        "type": "isilon-ifs",
        "alignment": "512B",
        "start": 50446336,
        "size": "3814927106048B",
        "label": "ifs",
        "geom": "da2",
    },
    {
        "index": 1,
        "type": "isilon-scratch",
        "alignment": "512B",
        "start": 50333696,
        "size": "53686784B",
        "label": "scratch",
        "geom": "da3",
    },
    {
        "index": 2,
        "type": "isilon-ifs",
        "alignment": "512B",
        "start": 50446336,
        "size": "3814927106048B",
        "label": "ifs",
        "geom": "da3",
    },
    {
        "index": 3,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 2048,
        "size": "8589934592B",
        "label": "journal-backup",
        "geom": "da4",
    },
    {
        "index": 4,
        "type": "isilon-bootdiskid",
        "alignment": "512B",
        "start": 40,
        "size": "512B",
        "label": "bootdiskid",
        "geom": "da4",
    },
    {
        "index": 5,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 16779264,
        "size": "3221225472B",
        "label": "var-crash",
        "geom": "da4",
    },
    {
        "index": 6,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 23070720,
        "size": "2147483648B",
        "label": "root1",
        "attrib": ["isi_active", "bootme"],
        "geom": "da4",
    },
    {
        "index": 7,
        "type": "efi",
        "alignment": "512B",
        "start": 27265024,
        "size": "293601280B",
        "label": "efi-boot",
        "geom": "da4",
    },
    {
        "index": 8,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 27838464,
        "size": "2147483648B",
        "label": "root0",
        "geom": "da4",
    },
    {
        "index": 9,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 32032768,
        "size": "1073741824B",
        "label": "var1",
        "geom": "da4",
    },
    {
        "index": 10,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 34129920,
        "size": "1073741824B",
        "label": "var0",
        "geom": "da4",
    },
    {
        "index": 11,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 36227072,
        "size": "524288000B",
        "label": "hw",
        "geom": "da4",
    },
    {
        "index": 12,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 37251072,
        "size": "67108864B",
        "label": "mfg",
        "geom": "da4",
    },
    {
        "index": 13,
        "type": "freebsd-ufs",
        "alignment": "512B",
        "start": 37382144,
        "size": "67108864B",
        "label": "keystore",
        "geom": "da4",
    },

    {
        "index": 1,
        "type": "isilon-scratch",
        "alignment": "512B",
        "start": 50333696,
        "size": "53686784B",
        "label": "scratch",
        "geom": "da4",
    },
    {
        "index": 2,
        "type": "isilon-ifs",
        "alignment": "512B",
        "start": 50446336,
        "size": "3814927106048B",
        "label": "ifs",
        "geom": "da4",
    },
]

if __name__ == "__main__":
    for p in parts:
        if p.get("size", None) is not None:
            print("gpart add -i %s -t %s -a %s -b %s -s %s -l %s %s" % (
                    p["index"], p["type"], p["alignment"], p["start"], p["size"], p["label"], p["geom"]))
        else:
            print("gpart add -i %s -t %s -a %s -b %s -l %s %s" % (
                    p["index"], p["type"], p["alignment"], p["start"], p["label"], p["geom"]))
        attrib = p.get("attrib", None)
        if attrib is not None:
            for a in attrib: 
                print("gpart set -i %s -a %s %s" % (p["index"], a, p["geom"]))

    print("gmirror label -b load -s 4096 root1 da1p7 da4p6")
    print("gmirror label -b load -s 4096 keystore da4p13 da1p15")
    print("gmirror label -b load -s 4096 mfg da4p12 da1p13")
    print("gmirror label -b load -s 4096 hw da4p11 da1p12")
    print("gmirror label -b load -s 4096 var0 da4p10 da1p11")
    print("gmirror label -b load -s 4096 var1 da4p9 da1p10")
    print("gmirror label -b load -s 4096 root0 da4p8 da1p9")
    print("gmirror label -b load -s 4096 var-crash da4p5 da1p5")
    print("gmirror label -b load -s 4096 journal-backup da4p3 da1p3")
    print("gmirror label -b load -s 4096 kernelsdump da1p14")
    print("gmirror label -b load -s 4096 kerneldump da1p6")

    print("newfs /dev/mirror/root1")
    print("newfs /dev/mirror/keystore")
    print("newfs /dev/mirror/mfg")
    print("newfs /dev/mirror/hw")
    print("newfs /dev/mirror/var0")
    print("newfs /dev/mirror/var1")
    print("newfs /dev/mirror/root0")
    print("newfs /dev/mirror/var-crash")
    print("newfs /dev/mirror/journal-backup")
    print("newfs /dev/mirror/kernelsdump")
    print("newfs /dev/mirror/kerneldump")
