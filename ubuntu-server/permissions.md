# Linux Permissions

This is a short practical reference for Linux file and directory permissions.

## 1. Ownership

Every file and directory has:

- `user` owner
- `group` owner
- permissions for `user`, `group`, and `others`

Show ownership and permissions:

```bash
ls -l
```

Example:

```text
-rw-r--r-- 1 ubuntu www-data 1234 Apr 3 12:00 app.conf
```

Meaning:

- owner: `ubuntu`
- group: `www-data`
- permissions: `rw- r-- r--`

## 2. Permission types

The three basic permissions are:

- `r` = read
- `w` = write
- `x` = execute

They are applied separately to:

- `u` = user
- `g` = group
- `o` = others

## 3. Meaning for files

For a file:

- `r`: can read file content
- `w`: can modify or overwrite the file
- `x`: can execute the file as a program or script

## 4. Meaning for directories

For a directory:

- `r`: can list file names inside
- `w`: can create, rename, or delete entries inside
- `x`: can enter the directory and access items by name

Important:

- Directory access usually needs `x`.
- `w` without `x` is usually not useful.

## 5. Symbolic format

Example:

```text
rwxr-xr--
```

Split into three groups:

- `rwx` = user
- `r-x` = group
- `r--` = others

Common examples:

- `rw-r--r--`: normal readable file
- `rwxr-xr-x`: executable file
- `rwx------`: private file or script
- `rwxr-x---`: app directory shared with one group

## 6. Numeric format

Each permission has a numeric value:

- `r = 4`
- `w = 2`
- `x = 1`

Add them together:

- `7 = rwx`
- `6 = rw-`
- `5 = r-x`
- `4 = r--`
- `0 = ---`

Examples:

- `644` = `rw-r--r--`
- `600` = `rw-------`
- `755` = `rwxr-xr-x`
- `700` = `rwx------`

## 7. chmod

Change permissions with `chmod`.

Numeric mode:

```bash
chmod 644 file.txt
chmod 755 script.sh
chmod 700 ~/.ssh
```

Symbolic mode:

```bash
chmod u+x script.sh
chmod g-w file.txt
chmod o-r secret.txt
chmod ug+rwx shared-dir
```

Recursive change:

```bash
chmod -R 755 mydir
```

Use recursive changes carefully.

## 8. chown and chgrp

Change owner:

```bash
sudo chown ubuntu file.txt
```

Change owner and group:

```bash
sudo chown ubuntu:www-data file.txt
```

Change only group:

```bash
sudo chgrp www-data file.txt
```

Recursive ownership change:

```bash
sudo chown -R ubuntu:www-data /var/www/myapp
```

## 9. Default permissions and umask

New files and directories get default permissions reduced by `umask`.

Common defaults:

- files start from `666`
- directories start from `777`

Example with `umask 022`:

- file becomes `644`
- directory becomes `755`

Show current umask:

```bash
umask
```

Set temporary umask for current shell:

```bash
umask 022
```

## 10. Special permissions

### setuid

```bash
chmod 4755 file
```

- shown as `s` on the user execute bit
- executable runs with the file owner's privileges

### setgid

```bash
chmod 2755 dir
```

- shown as `s` on the group execute bit
- on directories, new files inherit the directory group

### sticky bit

```bash
chmod 1777 /shared-dir
```

- shown as `t`
- users can only delete their own files inside a shared writable directory
- common example: `/tmp`

## 11. Common secure permissions

Useful examples:

- `~/.ssh` -> `700`
- `~/.ssh/authorized_keys` -> `600`
- private key file -> `600`
- public key file -> `644`
- normal config file -> `644`
- executable script -> `755`
- private app secrets file -> `600`

## 12. How permission checks work

Linux checks in this order:

1. If you are the file owner, `user` permissions apply.
2. Otherwise, if you are in the file's group, `group` permissions apply.
3. Otherwise, `others` permissions apply.

Permissions are not added across categories. One matching category is used.

## 13. Root user

`root` can bypass most normal permission checks.

That is why commands with `sudo` must be used carefully.

## 14. Useful commands

```bash
ls -l
ls -ld /path/to/dir
stat file.txt
namei -l /path/to/file
id
getfacl file.txt
```

What they do:

- `ls -l`: show permissions for files
- `ls -ld`: show permissions for the directory itself
- `stat`: show detailed file metadata
- `namei -l`: show permissions for every part of a path
- `id`: show your user and groups
- `getfacl`: show ACL permissions if ACLs are used

## 15. ACLs

Standard permissions are only `user/group/others`.

ACLs allow extra rules for specific users and groups.

Example:

```bash
setfacl -m u:deploy:rwx /var/www/myapp
getfacl /var/www/myapp
```

Use ACLs only when standard ownership and modes are not enough.

## 16. Common mistakes

- Giving `777` to everything instead of fixing ownership.
- Forgetting execute permission on directories.
- Using recursive `chmod` or `chown` on the wrong path.
- Storing private keys with permissions that are too open.
- Running services under the wrong user or group.

## 17. Practical rule

Use the lowest permissions that still allow the application to work.

Typical approach:

- files: `644`
- directories: `755`
- secrets: `600`
- private directories: `700`
- fix ownership first, then adjust permissions
