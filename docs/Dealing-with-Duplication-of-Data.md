# Dealing with Duplication of Data

## Current Situation

When a system is inspected some data is duplicated. This happens for example when multiple scopes handle and store the same information.
An example is repositories: The repositories are queried and then stored in `manifest.json` by the repositories scope.
Additionally the files in `/etc/zypp/repos.d` contain the same information and are handled by unmanaged-files.
Another example are users and groups, which are handled by the scopes 'users' and 'groups'. The files `/etc/passwd`,
`/etc/shadow`, and `/etc/group` contain the same information. Configuration files are handled by the scope config-files.

Duplication of this data leads to problems like the same repository appearing multiple times on a build image because it's applied by the unmanaged-files and the repositories scope.


## Current Approach

Currently a hard coded list of files is used to filter out the problematic files when an image is build, a kiwi or AutoYaST profile is exported. So, the current approach tries no
to apply config files when they are already covered on an more abstract level. This makes sure the data is not duplicated.


## Underlying Reason

There are different level of abstraction of data. A service can be described like a black box (e.g. webserver listening on port 80) or in detail (e.g. apache's configuration files).

Which level makes sense depends on the use case. Examples:

* System Recovery, System Replication: Using the unchanged data - speaking the config files - is the best way to configure the the system in the most similar way.

* Migration: When one migrates from one distribution to another it's essential to understand the configuration entries. In this case
  an abstraction of the configuration needs to be applied. Simply copying over the configuration files doesn't work because the config file format could have
  changed or even a different tool used which provides the same service (e.g. Lighttpd instead of Apache).


## Considerations

It makes sense to store all levels of abstraction during inspection and decide which data we want to use when we apply it:

* We don't want to lose data.
* During inspection we don't know how the system description will be used later on. This means we don't know which level of abstraction we will need.
* There will be more ways to get a system description besides inspection in the future. These also can lead to system descriptions containing redundant data:
  * Creation of a system description using an editor
  * Composition of a system description using hierarchical templates
  * Import from a different format (e.g. kiwi, AutoYaST)
* Configuration files can consist of data which is covered on a more abstract level and data which is not. This means we need to retrieve this file in order not to lose the uncovered data.


## Requirements

### Support of Hierarchical Templates

We want to support hierarchical templates and want to be able to compose a system description out of snippets. Such a snippet could contain all the configuration for one aspect on different levels of abstraction.


### Dealing with Inconsistency

We should bear in mind, that the information on different levels could be inconsistent and how we want to deal with that.


