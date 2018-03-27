# Utility Scripts

Some utilities, mostly written as scripts.

## Scripts

* `addmanifest.sh` automagically add entries to MANIFEST files prior to commit to prevent complaints from git pre-hooks.
* `convert_path_spaces.sh` convert paths with spaces to underscores.
* `latest` show most recently changed/created files in directory.
* `logscope.sh` extract relevant debugging info from logs using tags.
* `showports.sh` show all ports currently in use by user.

## Backup

* `backitallup.sh` backup repo code, minus git metadata, and environment files.
* `copyback.sh` secondary script called by `dailyback.sh`
* `dailyback.sh` backup files changed today, optionally adding path to filename, minus git metadata.

