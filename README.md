# Kube Config Updater

A small helper script for merging multiple kubeconfig files into your main Kubernetes config file.

The repository is meant to be cloned directly into your `~/.kube` directory:

```text
~/.kube/
  config
  config-updater/
    update-kubeconfig.sh
    extra-configs/
    backups/
```

The script reads every regular, non-hidden file from `extra-configs`, merges them into `~/.kube/config`, and creates a backup before making changes.

## Requirements

- Bash
- `kubectl`
- An existing main kubeconfig file at `~/.kube/config`

Check that `kubectl` is available:

```bash
kubectl version --client
```

## Installation

Clone this repository into `~/.kube/config-updater`:

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git ~/.kube/config-updater
```

Make sure the script is executable:

```bash
chmod +x ~/.kube/config-updater/update-kubeconfig.sh
```

## Add Extra Kubeconfig Files

Put any kubeconfig files you want to merge into:

```text
~/.kube/config-updater/extra-configs/
```

Example:

```text
~/.kube/config-updater/extra-configs/
  production_kubeconfig.yaml
  staging_kubeconfig.yaml
  dev_kubeconfig.yaml
```

The file names do not need to match the context, cluster, or user names inside the kubeconfig files. The script reads those names directly from each kubeconfig.

Hidden files are ignored. For example, `.gitkeep` and `.DS_Store` will not be merged.

## Usage

Run:

```bash
~/.kube/config-updater/update-kubeconfig.sh
```

Or from the repository directory:

```bash
cd ~/.kube/config-updater
./update-kubeconfig.sh
```

After the script finishes, your main Kubernetes config will be updated:

```text
~/.kube/config
```

You can confirm the merged contexts with:

```bash
kubectl config get-contexts
```

## What The Script Does

When you run `update-kubeconfig.sh`, it:

1. Finds its own directory.
2. Uses the parent directory as the kube directory.
3. Reads the main config from `~/.kube/config`.
4. Creates a timestamped backup in `~/.kube/config-updater/backups`.
5. Finds all regular, non-hidden files in `~/.kube/config-updater/extra-configs`.
6. Reads contexts, clusters, and users from each extra kubeconfig.
7. Deletes matching old entries from the main config.
8. Merges the main config and all extra configs with `kubectl config view --flatten`.
9. Replaces the main config with the merged result.
10. Keeps only the 10 most recent backups.

## Backups

Before changing `~/.kube/config`, the script creates a backup:

```text
~/.kube/config-updater/backups/config_YYYYMMDD_HHMMSS.yaml
```

Example:

```text
~/.kube/config-updater/backups/config_20260615_123201.yaml
```

Only the 10 newest backups are kept.

To restore a backup manually:

```bash
cp ~/.kube/config-updater/backups/config_YYYYMMDD_HHMMSS.yaml ~/.kube/config
```

Replace `config_YYYYMMDD_HHMMSS.yaml` with the backup file you want to restore.

## Repository Safety

Kubeconfig files often contain sensitive data such as tokens, certificates, usernames, cluster addresses, and authentication configuration.

This repository is configured to ignore:

```text
backups/*
extra-configs/*
.DS_Store
```

The `backups` and `extra-configs` directories are kept in git with `.gitkeep` files, but their real contents should not be committed.

Before publishing or pushing changes, check what git will include:

```bash
cd ~/.kube/config-updater
git status
```

Do not commit your real kubeconfig files.

## Troubleshooting

### `No extra config files found`

Make sure your kubeconfig files are inside:

```text
~/.kube/config-updater/extra-configs/
```

The script only reads files directly inside that directory. It does not scan nested folders.

### `Extra configs directory not found`

Make sure the repository has this directory:

```text
~/.kube/config-updater/extra-configs/
```

If it is missing, create it:

```bash
mkdir -p ~/.kube/config-updater/extra-configs
```

### `cp: ~/.kube/config: No such file or directory`

The script expects your main Kubernetes config to exist at:

```text
~/.kube/config
```

Create or obtain your main kubeconfig first, then run the updater again.

### A context still points to old data

Run the script again after checking that the updated kubeconfig file is present in `extra-configs`.

You can inspect a specific extra kubeconfig with:

```bash
kubectl config view --kubeconfig ~/.kube/config-updater/extra-configs/YOUR_FILE.yaml
```

## Recommended Workflow

1. Clone this repository to `~/.kube/config-updater`.
2. Copy extra kubeconfig files into `extra-configs`.
3. Run `./update-kubeconfig.sh`.
4. Verify contexts with `kubectl config get-contexts`.
5. Use `git status` before publishing changes.

## License

Add your preferred license before publishing this repository.
