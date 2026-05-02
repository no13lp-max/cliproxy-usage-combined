# CLIProxyAPI + CPA Usage Keeper Combined Runtime

This repository deploys CLIProxyAPI and CPA Usage Keeper in one Render web service.

- `/` routes to CLIProxyAPI.
- `/management.html` remains the CLIProxyAPI management UI.
- `/usage/` routes to CPA Usage Keeper.
- Usage Keeper reads CLIProxyAPI's Redis-compatible usage queue through `127.0.0.1:8317`.

The combined layout avoids depending on Render private networking for the usage queue.
