# Disks And Filesystems

This guide covers disk inspection, partitioning basics, filesystems, mounts, and storage troubleshooting on Linux systems.

## Inspect Disk Layout

### Show block devices

```bash
lsblk
lsblk -f
```

`lsblk -f` shows filesystem type, label, and UUID alongside the device tree.

### Show partition tables

```bash
sudo fdisk -l
sudo parted -l
```

### Show filesystem usage

```bash
df -h
df -i
```

Use `df -i` when a filesystem reports free space but applications still cannot create files. Inode exhaustion is a common cause.

## Measure Directory Usage

```bash
du -sh /var/log
du -sh /opt/*
du -xhd1 /
```

Useful flags:

- `-s` summary
- `-h` human-readable
- `-x` stay on one filesystem
- `-d1` one level deep

## Filesystem Identification

```bash
blkid
lsblk -f
```

Common Linux filesystem types:

- `ext4` general-purpose default on many systems
- `xfs` common on enterprise distributions and large volumes
- `btrfs` modern copy-on-write filesystem with advanced features
- `vfat` often used for EFI partitions and removable media

## Mounting And Unmounting

### Mount a filesystem temporarily

```bash
sudo mount /dev/sdb1 /mnt/data
```

### Unmount

```bash
sudo umount /mnt/data
sudo umount /dev/sdb1
```

If a mount is busy:

```bash
sudo lsof +f -- /mnt/data
sudo fuser -vm /mnt/data
```

### Persistent mounts with `/etc/fstab`

Example:

```fstab
UUID=1234-ABCD /data ext4 defaults,nofail 0 2
```

After editing `/etc/fstab`, validate before reboot:

```bash
sudo mount -a
```

This catches syntax errors and missing devices early.

## Creating Filesystems

Examples:

```bash
sudo mkfs.ext4 /dev/sdb1
sudo mkfs.xfs /dev/sdb1
```

This destroys data on the target device. Verify the device path carefully before running filesystem creation commands.

## Swap

### Show swap usage

```bash
swapon --show
free -h
```

### Create a swap file

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

Add to `/etc/fstab`:

```fstab
/swapfile none swap sw 0 0
```

## Storage Health

### Check for I/O errors

```bash
dmesg | grep -iE "error|fail|ext4|xfs|i/o"
journalctl -k -p warning
```

### SMART checks

```bash
sudo smartctl -a /dev/sda
sudo smartctl -H /dev/sda
```

`smartctl` is one of the first tools to use when hardware failure is suspected.

## Repair And Integrity

### `ext4`

```bash
sudo fsck -f /dev/sdb1
```

### `xfs`

```bash
sudo xfs_repair /dev/sdb1
```

Run repair tools on unmounted filesystems unless the tool explicitly supports online checks.

## Large File And Space Investigations

### Find large files

```bash
find /var -type f -size +500M -ls
find / -xdev -type f -size +1G 2>/dev/null
```

### Check deleted files still held open

```bash
sudo lsof +L1
```

A deleted log file can still consume disk space until the owning process closes it.

## Common Mount Locations

- `/` root filesystem
- `/boot` boot files
- `/boot/efi` EFI system partition
- `/home` user home directories
- `/var` logs, caches, variable application data
- `/tmp` temporary files
- `/mnt` temporary admin mount point
- `/media` removable media

## Best Practices

- Use UUIDs in `/etc/fstab` instead of raw device names where possible.
- Validate `fstab` changes with `mount -a` before rebooting.
- Monitor both space usage and inode usage.
- Separate application data, logs, and database storage when growth or performance justifies it.
- Investigate disk growth with `du` before deleting files blindly.
- Treat `mkfs`, `fdisk`, `parted`, and repair tools as high-risk commands and confirm the target device first.
