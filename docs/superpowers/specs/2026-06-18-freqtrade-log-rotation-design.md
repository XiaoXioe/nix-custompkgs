# Freqtrade Log Rotation Design Spec

## Objective
Provide a configurable, automated log rotation mechanism for Freqtrade and its extra background services (e.g., Uvicorn) without relying on global system daemons like `logrotate`.

## Problem Statement
When `logToFile = true` is used, systemd's `StandardOutput=append:file.log` causes log files to grow indefinitely. Over months of 24/7 operation, this can fill up the user's disk. A simple automatic size-based backup and cleanup mechanism is required.

## Architecture & Data Flow

1.  **Module Options (`modules/freqtrade-setup.nix`)**
    *   Add a new option: `logMaxSize` (default: `"10M"`).
    *   This specifies the threshold at which a log file is considered "too large" and must be rotated.

2.  **Helper Script (`freqtrade-log-rotate`)**
    *   A shell script created using `pkgs.writeShellScriptBin`.
    *   **Inputs:**
        1.  `$1`: Absolute path to the active `.log` file.
        2.  `$2`: Max size limit (e.g., `10M`, which the script will parse or use `find` / `stat` against).
    *   **Logic:**
        *   Check if `$1` exists.
        *   Determine the size of `$1`. If size is >= `$2` (parsed to bytes), proceed to rotation.
        *   If it proceeds, rename `$1` to `[basename]-[timestamp].log`. Timestamp format: `YYYYMMDD-HHMMSS`.
        *   Identify all `[basename]-*.log` files matching the pattern.
        *   Sort them by modification time or lexically by timestamp (newest first).
        *   If the count exceeds `5`, delete the older files (keeping only the 5 newest).

3.  **Systemd Integration (`ExecStartPre`)**
    *   Inside the NixOS `systemd.user.services` generator for both the **Main Service** and **Extra Services**.
    *   If `logToFile = true`:
        *   `ExecStartPre` will contain two commands:
            1.  `mkdir -p /path/to/logs/` (already exists).
            2.  `${freqtrade-log-rotate}/bin/freqtrade-log-rotate /path/to/logs/freqtrade-[name].log [logMaxSize]`

## File Management & Error Handling
*   **Missing file:** If the log file doesn't exist yet (first run), the script gracefully exits without doing anything.
*   **Parsing `10M`:** The script will use `numfmt --from=iec` (from coreutils) to convert human-readable sizes like "10M", "50M", "2G" to bytes for comparison against `stat -c %s`.
*   **Permissions:** Script runs as the systemd user service owner, which guarantees write access to their own `user_data/logs/` directory.

## Testing Strategy
*   Manual execution of the `freqtrade-log-rotate` script with a dummy file exceeding the size limit.
*   Verify exactly 5 backup files are retained.
*   Verify systemd services start smoothly after the integration.
