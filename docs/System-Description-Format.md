# Machinery System Description Format

This is the documentation of the format
[Machinery](http://machinery-project.org) uses to store system descriptions.

## Structure

Machinery stores each system description in a directory. The name of the system
description is used as name of the directory.
The description consists of a JSON file named `manifest.json` which
contains all the primary data and meta data of the description. The data is
separated in scopes, which represent different areas of the system. Each scope
has its own section in the JSON file. Some scopes have additional data stored as
files in a
subdirectory of the main system description directory. The names of the scopes
are used as names of these subdirectories.

By default all system descriptions are stored in the directory `~/.machinery`.
The Machinery log file is also written to this directory.

## Manifest

The primary data and meta data of the description is stored in a `manifest.json`
file. It has an own section for each scope, and an additional section with meta
data.

A simplified example of the manifest can look like this:

```json
{
  "os": {
    "name": "openSUSE 13.1 (Bottle)",
    "version": "13.1 (Bottle)",
    "architecture": "x86_64"
  },
  "packages": [
    {
      "name": "aaa_base",
      "version": "13.1"
    },
    {
      "name": "zypper",
      "version": "1.9.16"
    }
  ],
  "config_files": {
    "extracted": true,
    "files": [
      {
        "name": "/etc/ntp.conf",
        "package_name": "ntp",
        "package_version": "4.2.6p5",
        "status": "changed",
        "changes": [
          "md5"
        ],
        "user": "root",
        "group": "ntp",
        "mode": "640",
        "type": "file"
      }
    ]
  },
  "meta": {
    "format_version": 4,
    "os": {
      "modified": "2014-08-22T14:34:59Z",
      "hostname": "host.example.org"
    },
    "packages": {
      "modified": "2014-08-22T14:34:59Z",
      "hostname": "host.example.org"
    }
  }
}
```

## Scopes

The file scopes have a sub directory in the system description directory, which
contains the files, which are referenced from the manifest. The structure of
the files directory depends on the specific scope.

The name of the sub directory corresponds to the scope name. Scope names which
consist of multiple words, use underscores to separate the words in the manifest
as well as in the sub directory name.

For example the configuration files of the `config-files` scope are stored in
the directory `config_files`. The config file from the example above is stored
at `~/.machinery/mini/config_files/etc/ntp.conf`.

The names of the scopes in the JSON use `_` as separator of words, while when
specifying a scope name on the command line `-` is used as separator of words.

### meta

The global scope contains a meta object that holds this information about the inspected system:

JSON Example:
```json
"meta": {
    "format_version": 4,
    "services": {
      "modified": "2014-09-09T08:27:51Z",
      "hostname": "192.168.121.109"
    },
    "groups": {
      "modified": "2014-09-09T08:27:51Z",
      "hostname": "192.168.121.109"
    },
    "changed_managed_files": {
      "modified": "2014-09-09T08:27:51Z",
      "hostname": "192.168.121.109"
    }
}
```

| item            | description                           | type                       |
|-----------------|---------------------------------------|----------------------------|
| format_version  | version of used schema                | integer, minimum 1         |
| modified        | last modification date for scope      | string (date and time in ISO 8601 format)     |
| hostname        | the host name of the inspected system | string |


### config-files

The config file scope contains entries for all information related to managed config files.
If the `--extract-files` option is used, all files also get copied from the inspected machine into `~/.machinery/<hostname>/config_files`. The directory structure of the files and directories is identical to the one they had on the inspected system, e.g.:

```
config_files/
└── etc
    ├── crontab
    ├── default
    │   └── grub
    ├── modprobe.d
    │   └── 10-unsupported-modules.conf
    ├── ssh
    │   └── sshd_config
    ├── sudoers
    └── zypp
        └── zypp.conf
```


JSON Example:
```json
"config_files": {
  "extracted": true,
  "files": [
    {
      "name": "/etc/crontab",
      "package_name": "cronie",
      "package_version": "1.4.11",
      "status": "changed",
      "changes": [
        "md5"
      ],
      "user": "root",
      "group": "root",
      "mode": "600",
      "type": "file"
    },
    {
      "name": "/etc/cron.daily/mdadm",
      "package_name": "mdadm",
      "package_version": "3.3.1",
      "status": "changed",
      "changes": [
        "deleted"
      ],
      "type": "file"
    },
    {
      "name": "/etc/sshd/ssh_config",
      "package_name": "ssh",
      "package_version": "1.2.3-4",
      "status": "error",
      "error_message": "some error message that would appear",
      "type": "file"
    }
  ]
}
```

#### Common information for every file

The top level structure looks like this:

| item            | description                          | type                       | 
|-----------------|--------------------------------------|----------------------------|
| extracted       | tells whether the files were extracted or not | boolean           | 
| files           | the list of config files             | array                      | 

The items within the files array look like this:

| item            | description                          | type                       | 
|-----------------|--------------------------------------|----------------------------|
| name            | config filename                      | string                     | 
| package_name    | packagename config file comes from   | string                     | 
| package_version | version of package                   | string                     | 


in case of errors we also store those:

| item            | description                          | type                       |
|-----------------|--------------------------------------|----------------------------|
| status          | set to "error"                         | enum                       |
| error_message   | the actual error message             | string                     |

#### Information for changed files

If something got changed for a config file, the changes are stored within this scope as well, however it also is stored what is changed and how:

| item            | description                          | type                       | 
|-----------------|--------------------------------------|----------------------------|
| status          | set to "changed" | enum - (changed)           | 

#### Information on changed files - modification

If the file got modified, the kind of modification gets stored:

| item            | description                          | type                       |
|-----------------|--------------------------------------|----------------------------|
| changes         | what is changed                      | array (at least one of: size, mode, md5, device_number, link_path, user, group, time, capabilities, replaced, other_rpm_change)                     |
| mode            | the permissions of the file          | string pattern (octal permission bits) |
| user            | the file owner                       | string                     |
| group           | the group owning the file            | string                     |

#### Information on changed files - deletion

If the file was deleted, we only save this information:

| item            | description                          | type                       |
|-----------------|--------------------------------------|----------------------------|
| changes         | what is changed                      | array (deleted)                     |


### changed-managed-files

Here all information relating to managed files that got changed since they got installed is stored. It contains again the config file name, its orginating package and the package version. Beside that it gets stored if user, group, permissions or the file content was changed or if the file was deleted.

If the `--extract-files` option is used, all files also get copied from the inspected machine into `~/.machinery/<hostname>/changed_managed_files`. The directory structure of the files and directories is identical to the one they had on the inspected system:

```
changed_managed_files/
└── usr
    └── share
        ├── bash
        │   └── helpfiles
        │       └── read
        └── doc
            └── packages
                └── sssd
                    └── COPYING
```

JSON Example
```json
"changed_managed_files": {
  "extracted": true,
  "files": [
    {
      "name": "/etc/crontab",
      "package_name": "cronie",
      "package_version": "1.4.11",
      "status": "changed",
      "changes": [
        "md5"
      ],
      "user": "root",
      "group": "root",
      "mode": "600",
      "type": "file"
    },
    {
      "name": "/etc/cron.daily/mdadm",
      "package_name": "mdadm",
      "package_version": "3.3.1",
      "status": "changed",
      "changes": [
        "deleted"
      ],
      "type": "file"
    },
    {
      "name": "/etc/sshd/ssh_config",
      "package_name": "ssh",
      "package_version": "1.2.3-4",
      "status": "error",
      "error_message": "some error message that would appear",
      "type": "file"
    }
  ]
}
```

#### Common information for every file

The top level structure looks like this:

| item            | description                          | type                       | 
|-----------------|--------------------------------------|----------------------------|
| extracted       | tells whether the files were extracted or not | boolean           | 
| files           | the list of changed managed files    | array                      | 

The items within the files array look like this:

| item            | description | type   |
|-----------------|-------------|--------|
| name            | name of file | string |
| package name    | package name file originates from | string |
| package_version | version of package | string |

in case of errors we also store those:

| item          | description | type   |
|---------------|-------------|--------|
| status        | error status | enum - (error) |
| error_message | actual error message | string |

#### Information for changed files

If something got changed for a config file, the changes are stored within this scope as well, however it also is stored what is changed and how:

| item   | description | type  | 
|--------|-------------|-------|
| status | set to "changed" | enum - (changed)  |

#### Information on changed files - modification

If the file got modified, the kind of modification gets stored:

| item    | description | type           |
|---------|-------------|----------------|
| changes | what is changed | array (at least one of: size, mode, md5, device_number, link_path, user, group, time, capabilities, replaced, other_rpm_change))         |
| mode    | file permissions | string pattern (octal permission bits) |
| user    | file owner | string         |
| group   | file group | string         |

#### Information on changed files - deletion

If the file was deleted, we only save this information:

| item    | description | type  |
|---------|-------------|-------|
| changes | set to 'deleted' | array |



### unmanaged-files

This scope holds information about the unmanaged files which have not been installed from a package but got created manually or by script. If the `--extract-files` option is used all unmanaged files are extracted and saved under `~/.machinery/<hostname>/unmanaged_files/`. Unmanaged trees are stored under `~/.machinery/<hostname>/unmanaged_files/trees` as compressed tar archives. The directory structure is kept identical to the inspected system. Unmanaged files which do not belong to an unmanaged tree are all stored in one compressed tar archive in the `file.tgz` file.

Example of the file structure:
```
unmanaged_files/
├── files.tgz
└── trees
    ├── boot
    │   └── grub2
    │       ├── fonts.tgz
    │       ├── i386-pc.tgz
    │       └── locale.tgz
    ├── etc
    │   ├── iscsi.tgz
    │   ├── systemd
    │   │   └── system
    │   │       ├── default.target.wants.tgz
    │   │       ├── getty.target.wants.tgz
    │   │       ├── multi-user.target.wants.tgz
    │   │       ├── network-online.target.wants.tgz
    │   │       ├── system-update.target.wants.tgz
    │   │       ├── wickedd.service.wants.tgz
    │   │       └── wicked.service.wants.tgz
    │   ├── yaddayadda.tgz
    │   └── YaST2
    │       └── licenses.tgz
    ├── home
    │   └── vagrant.tgz
    ├── root
    │   └── inst-sys.tgz
    ├── srv
    │   └── www
    │       └── htdocs
    │           └── test.tgz
    ├── usr
    │   └── local
    │       └── magicapp.tgz
    ├── vagrant.tgz
    └── var
        ├── adm
        │   ├── mount.tgz
        │   ├── netconfig.tgz
        │   └── SuSEconfig.tgz
        ├── cache
        │   └── zypp
        │       ├── packages.tgz
        │       ├── raw.tgz
        │       └── solv.tgz
        ├── lib
        │   ├── dhcpcd.tgz
        │   ├── hardware
        │   │   └── unique-keys.tgz
        │   └── YaST2
        │       └── backup_boot_sectors.tgz
        └── log
            └── news.tgz
```

JSON Example:
```json
  "unmanaged_files": {
    "extracted": true,
    "files": [
      {
        "name": "/boot/backup_mbr",
        "type": "file",
        "user": "root",
        "group": "root",
        "size": 512,
        "mode": "644"
      },
      {
        "name": "/boot/grub2/device.map",
        "type": "file",
        "user": "root",
        "group": "root",
        "size": 15,
        "mode": "600"
      }
    ]
  }
```

The top level structure looks like this:

| item            | description                          | type                       | 
|-----------------|--------------------------------------|----------------------------|
| extracted       | tells whether the files were extracted or not | boolean           | 
| files           | the list of unmanaged files             | array                      | 

The items within the files array look like this:

| item | description | type   |
|------|-------------|--------|
| name | file name   | string |

When files are not extracted only the name and the type is saved:

| item | description | type |
|------|-------------|------|
| type | filetype - dir, remote_dir, file or link | enum |

When files get extracted however, we save much more information on them, for all we save:

| item  | description | type   |
|-------|-------------|--------|
| user  | file owner  | string |
| group | file group  | string |

The the depending on the file type again different information 
when extracted file type is file:

| item | description | type           |
|------|-------------|----------------|
| type | filetype - file | enum           |
| size | file size | integer        |
| mode | file permission | string pattern (octal permission bits) |

when extracted file is a directory:

| item  | description | type           |
|-------|-------------|----------------|
| type  | filetype - dir           | enum           |
| size  | file size            | integer        |
| mode  | file permissions            | string pattern (octal permission bits) |
| files | files inside the directory            | integer        |

when the extracted file is a link:

| item | description | type |
|------|-------------|------|
| type | file type - link   | enum |

### os

This scope contains entries for the OS name, its version and the architecture.

JSON Example:

```json
  "os": {
    "name": "SUSE Linux Enterprise Server 12",
    "version": "12 Beta 10",
    "architecture": "x86_64"
  }
```

| item         | description | type   |
|--------------|-------------|--------|
| name         | operating system name | string |
| version      | operation system version | string |
| architecture | hardware architecture the operating system runs on | string |

### users

The users scope stores all user related information.

JSON Example:
```json
"users": [
    {
      "name": "+",
      "password": "",
      "uid": null,
      "gid": null,
      "comment": "",
      "home": "",
      "shell": ""
    },
    {
      "name": "bin",
      "password": "x",
      "uid": 1,
      "gid": 1,
      "comment": "bin",
      "home": "/bin",
      "shell": "/bin/bash",
      "encrypted_password": "*",
      "last_changed_date": 16266
    }
```


| item               | description | type    |
|--------------------|-------------|---------|
| name               | username    | string  |
| password           | password hash   | string  |
| uid                | user ID     | integer |
| gid                | group ID    | integer |
| comment            | some freeform comment | string |
| home               | location of users home directory | string  |
| shell              | user login shell            | string  |
| encrypted password | the password in encrypted format            | string  |
| last_changed_state | days since jan 1, 1970 that password was last changed           | integer |
| min_days           | days before password may be changed           | integer |
| max_days           | days after which password must be changed            | integer |
| warn_days          | days before password is to expire that user is warned            | integer |
| disable_days       | days after password expires that account is disabled           | integer |
| disabled_date      | days since Jan 1, 1970 that account is disabled          | integer |

### groups

Similar as for users also group related information is stored in the group scope.
The entries are simply the group name, a group password, the group id and users
in it.

JSON Example:
```json
  "groups": [
    {
      "name": "+",
      "password": "",
      "gid": null,
      "users": [

      ]
    },
    {
      "name": "audio",
      "password": "x",
      "gid": 17,
      "users": [

      ]
    }
]
```


| item     | description | type             |
|----------|-------------|------------------|
| name     | group name  | string           |
| password | group password hash | string           |
| gid      | group ID    | integer          |
| users    | user ID     | array of strings |

### repositories

JSON Example:
```json
  "repositories": [
    {
      "alias": "SLE-12-SLP",
      "name": "SLE-12-SLP",
      "type": "yast2",
      "url": "http://dist.suse.de/install/SLP/SLE-12-Server-Beta10/x86_64/DVD1/",
      "enabled": true,
      "autorefresh": false,
      "gpgcheck": true,
      "priority": 99,
      "package_manager": "zypp"
    }
  ]
```

Here all information for repositories configured in the inspected system get stored. The repo alias, it repo name, its url, type, if it is enabled and if autorefresh is on, if the gpg key is checked for it, the repository priority and the package manager (zypp or yum).

| item        | description | type                |
|-------------|-------------|---------------------|
| alias       | repo alias  | string              |
| name        | repository alias | string              |
| type        | repository type, e.g. yast2 | enum                |
| url         | repository URL | uri formated string |
| enabled     | 1 if the repository is enabled            | boolean             |
| autorefresh | 1 if the repository gets refreshed automatically on every zypper run            | boolean             |
| gpgcheck    | 1 if the key for the repository si checked            | boolean             |
| priority    | repo priority - defines in which order repositories are used            | integer             |

### packages

JSON Example:
```json
"packages": [
    {
      "name": "SUSEConnect",
      "version": "0.2.4",
      "release": "1.1",
      "arch": "x86_64",
      "vendor": "SUSE LLC <https://www.suse.com/>",
      "checksum": "2883d8edd3743ca644f0c9c463686bd5"
    },
    {
      "name": "SuSEfirewall2",
      "version": "3.6.307",
      "release": "1.2",
      "arch": "noarch",
      "vendor": "SUSE LLC <https://www.suse.com/>",
      "checksum": "6a017ef4c19bee596efaf9a249291292"
    }
]
```

| item     | description                           | type       |
|----------|---------------------------------------|------------|
| name     | package name                          | string     |
| version  | package version                       | string     |
| release  | package release                       | string     |
| arch     | hardware architecture package runs on | string     |
| vendor   | package vendor                        | string     |
| checksum | md5 checksum of package               | md5 string |


### patterns

JSON Example:
```json
  "patterns": [
    {
      "name": "Minimal",
      "version": "12",
      "release": "44.1"
    },
    {
      "name": "base",
      "version": "12",
      "release": "44.1"
    }
```

| item    | description     | type   |
|---------|-----------------|--------|
| name    | pattern name    | string |
| version | pattern version | string |
| vendor  | pattern vendor  | string |

### services

Information about service run configuation is stored in the service scope. There are two kind of init_systems possible:

* systemv - The traditional linux init system, services are started via scripts that get executed on bootup
* systemd - A new init system that works with binary and handles inter service dependencies better for a faster startup. Read more about it on the [systemd homepage](http://www.freedesktop.org/wiki/Software/systemd/)

For both a list of configured services with their state is saved. This state can be:

* enabled - service gets started on boot
* disabled - service is not started

For systemd there are two additional states defined:

* static - service is enabled by other service depending on it
* masked - service is disabled and can not even manually be started 

JSON Example:
```json
  "services": {
    "init_system": "systemd",
    "services": [
      {
        "name": "SuSEfirewall2.service",
        "state": "enabled"
      },
      {
        "name": "SuSEfirewall2_init.service",
        "state": "disabled"
      }
]
```

| item        | description          | type   | 
|-------------|----------------------|--------|
| init_system | the init system used | string | 
| services    | list of services     | array  |

| item  | description  | type   | 
|-------|--------------|--------|
| name  | service name | string | 
| state | service state| array  | 

## Versioning

The system description is versioned by the `format_version` attribute in the
`meta` section in the manifest.

The format version is incremented when the format is changed in a way that older
versions of Machinery can not read the new version of the format anymore.

Older versions of the format will transparently be upgraded and read by newer
version of Machinery.

## History

### Version 1

* Initial version

### Version 2

* Schema version 2 introduces an "extracted" flag for the [[config-files|System Description Format#config-  files]], [[changed-managed-files|System Description Format#changed-managed-files]] and [[unmanaged-files|System Description Format#unmanaged-files]], indicating whether the files were extracted or not.

* It also introduces a "remote_dir" type for the unmanaged_files scope indicating that the directory is a remote mount point and that the content is not checked or extracted.

* Add the missing GID key for NIS placeholder entries in groups.

### Version 3

* Schema version 3 stores the analyzed data under the directory "analyze" and config files diffs in the config_file_diffs subdirectory. So the existing directory config-file-diffs needs to be moved.

* It also adds a "package_manager" attribute to the repository.

### Version 4

* Schema version 4 adds a "type" attribute to [changed-managed](#changed-managed-files) and [[config-files|System Description Format#config-files]] with the possible values "file", "directory" and "link".

* For both scopes an additional attribute "target_path" was introduced which will be only added in case of the file type "link" to store the destination.
