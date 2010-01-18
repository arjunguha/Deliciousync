# Deliciousync
Copyright (c) 2010 Arjun Guha.
All Rights Reserved.

Licensed by the terms of the GNU General Public License 3.0. See the
file LICENSE for details.

Deliciousync is a utility that periodically synchronizes Safari's
bookmarks with bookmarks from a Delicious account.

## Uninstallation

To uninstall, delete:

1. the Deliciousync application bundle,
2. the folder `~/Library/Application Support/Deliciousync`,
3. the file `~/Library/LaunchAgents/DeliciousyncAgent.plist`, and
4. the application password for Deliciousync (launch the Keychain Access 
   utility).

## System Architecture

The Deliciousync application bundle uses a command-line tool,
DeliciousyncAgent that does the actual work of synchronization. The GUI
is a front-end to configure the agent, which may be used independently.

When opened, Deliciousync copies the agent and configuration files to
the following directory:

    ~/Library/Application Support/Deliciousync

Deliciousync also creates a launchd configuration file that periodically
launches the agent:

    ~/Library/LaunchAgents/DeliciousyncAgent.plist

Hence, launchd can locate and launch the agent, even if the Deliciousync
bundle is moved.

The agent uses Sync Services to synchronize with Safari, and the
api.del.icio.us HTTP API to synchronize with Delicious.  In the
Application Support folder, the agent maintains a cache of Safari and
Delicious bookmarks. This cache lets the agent sync incrementally.

## Synchronization Model

For the moment, Deliciousync does not synchronize folders and
tags. However, Deliciousync lets the user select a destination folder in
Safari for newly created Delicious bookmarks.

Deliciousync associates Safari and Delicious bookmarks by URL. Since
Delicious only permits a single bookmark per URL, a Delicious bookmark
may correspond to multiple Safari bookmarks.

A complete synchronization round has four steps that are executed in order:

1. pull updates from Delicious, 
2. push updates to Safari,
3. pull updates from Safari, and
4. push updates to Delicious.

In most cases, Safari and Delicious will be consistent after a single
synchronization round; i.e. another synchronization will yield no
further updates, assuming no further updates are made.  For example:

1. If a bookmark is deleted or renamed in Delicious, all its associated
   bookmarks are deleted or renamed in Safari.
2. If a bookmark is deleted in Safari and there are no other Safari bookmarks
   with the same URL, then the bookmark is deleted from Delicious.

However, renaming a Safari bookmark is trickier.  Suppose a single URL
is bookmarked multiple times in Safari with different names. What should
we name the associated Delicious bookmark?  In this situation, we
arbitrarily pick one of its names. On the next synchronization round,
all associated Safari bookmarks are renamed to the name we picked
earlier.
