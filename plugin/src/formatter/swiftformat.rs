use std::path::{Path, PathBuf};
use std::process::Stdio;
use std::sync::Arc;

use anyhow::{bail, Context, Result};
use tokio::io::AsyncWriteExt;
use tokio::process::Command;
use tokio::sync::Notify;

use crate::config::Configuration;
use crate::formatter::command::build_command_args;

pub async fn format_with_swiftformat(
    file_path: &Path,
    file_text: &str,
    config: &Configuration,
    cancel: Arc<Notify>,
) -> Result<Option<String>> {
    let swiftformat_path = resolve_swiftformat_binary()?;
    let file_path_string = file_path.to_string_lossy().to_string();
    let args = build_command_args(config, &file_path_string);

    let mut child = Command::new(&swiftformat_path)
        .args(&args)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .with_context(|| format!("failed to spawn {}", swiftformat_path.display()))?;

    let pid = child.id();
    let cancel_task = tokio::spawn(async move {
        cancel.notified().await;
        if let Some(pid) = pid {
            let _ = kill_process(pid);
        }
    });

    let mut stdin = child
        .stdin
        .take()
        .context("failed to open swiftformat stdin")?;

    stdin
        .write_all(file_text.as_bytes())
        .await
        .context("failed to write to swiftformat stdin")?;
    drop(stdin);

    let output = child
        .wait_with_output()
        .await
        .context("failed waiting for swiftformat")?;

    cancel_task.abort();

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        bail!(if stderr.trim().is_empty() {
            format!("swiftformat exited with status {}", output.status)
        } else {
            stderr.trim().to_string()
        });
    }

    let formatted = String::from_utf8(output.stdout).context("swiftformat output was not utf-8")?;

    if formatted == file_text {
        Ok(None)
    } else {
        Ok(Some(formatted))
    }
}

pub fn resolve_swiftformat_binary() -> Result<PathBuf> {
    if let Ok(path) = std::env::var("SWIFTFORMAT_PATH") {
        let path = PathBuf::from(path);
        if path.is_file() {
            return Ok(path);
        }
        bail!(
            "SWIFTFORMAT_PATH does not point to a file: {}",
            path.display()
        );
    }

    if let Ok(exe_path) = std::env::current_exe() {
        if let Some(dir) = exe_path.parent() {
            let sibling = dir.join("swiftformat");
            if sibling.is_file() {
                return Ok(sibling);
            }
        }
    }

    if let Some(path) = find_on_path("swiftformat") {
        return Ok(path);
    }

    bail!(
        "swiftformat binary not found. Set SWIFTFORMAT_PATH, bundle swiftformat next to the plugin, or install swiftformat on PATH."
    );
}

fn find_on_path(binary: &str) -> Option<PathBuf> {
    let path_var = std::env::var_os("PATH")?;
    std::env::split_paths(&path_var)
        .map(|dir| dir.join(binary))
        .find(|path| path.is_file())
}

#[cfg(unix)]
fn kill_process(pid: u32) -> Result<()> {
    use std::process::Command as StdCommand;
    let _ = StdCommand::new("kill").arg(pid.to_string()).status();
    Ok(())
}

#[cfg(windows)]
fn kill_process(pid: u32) -> Result<()> {
    use std::process::Command as StdCommand;
    let _ = StdCommand::new("taskkill")
        .args(["/PID", &pid.to_string(), "/F"])
        .status();
    Ok(())
}
