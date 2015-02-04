# Dealing with Duplication of Data

## Problem

When a system is inspected some data is duplicated. This happens when multiple scopes handle and store the same information.
An example is repositories: The repositories are queried and then stored in `manifest.json` by the repositories scope.
Additionally the files in `/etc/zypp/repos.d` contian the same information and are handled by unmanaged-files.
Another example are users and groups, which are handled by the scopes 'users' and 'groups'. The files `/etc/passwd`,
`/etc/shadow`, and `/etc/group` contain the same information. Configuration files are handled by the scope changed-configuration-files.

Duplication of this data leads to problems like the same repository appearing multiple times on a build image.


## Current Approach

Currently a hard coded list of files is used to filters out the problematic files when an image is build or a kiwi or AutoYaST profile is exported.
This makes sure the data is not duplicated.


## Challenges

There are following challenges:

* It's getting tricky when a file contains data covered by a scope and data not covered by any scope, because filtering out this files
would lead to loosing the data which is not covered by any scope.

* In case certain scopes are skipped the data is missing, because the files are still filtered out.


## Possible Solutions

* Filtering during inspection:
  Each scope knows which data it inspects and which files contain the same data. Thus, each scope provides the filters to filter out files.

* Filtering during build and export

