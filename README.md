# DDEV OCI8 Add-on

This add-on installs Oracle Instant Client and the PHP OCI8 extension for DDEV projects, supporting both AMD64 and ARM64 architectures.

## Requirements

- **DDEV** v1.24+
- **PHP** 8.2 or higher

## Features

- Installs Oracle Instant Client (Basic + SDK)
- Configures PHP OCI8 extension
- Supports both AMD64 and ARM64 architectures
- Automatic library path configuration

## Intended Usage

This setup only installs the **Oracle client**, and is meant for applications (like PHP apps using OCI8) that connect to a **remote Oracle database** not for running a database server.

## Installation

```bash
ddev add-on get takielias/ddev-oci8
ddev restart
```

## Verification

After installation, verify the OCI8 extension is loaded:

```bash
ddev php -m | grep oci8
```

Check Oracle client version:

```bash
ddev php -i | grep -i "oracle.*version"
```

## Troubleshooting

### Common Issues

1. **Download fails**:
   - Verify the exact package version exists on Oracle's website
   - Check your internet connection can reach Oracle's servers

2. **PHP version compatibility**:
   - This add-on requires PHP ≥ 8.2
   - Verify with `ddev exec php -v`

3. **ARM64 support**:
   - You must use a Docker provider that supports Rosetta 2

### Debugging

Check installation logs:

```bash
ddev logs -s web
```

Verify library paths:

```bash
ddev exec ldconfig -p | grep oci
```

## Uninstallation

To remove the add-on:

```bash
ddev add-on remove oci8
ddev restart
```

## License

Apache 2 License. See [LICENSE](LICENSE) file.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.
