use std::process::{Command, Child, Stdio};
use std::io::{Read, Write};
use std::sync::mpsc;
use std::time::{Duration, Instant};

const SEND_TIMEOUT: Duration = Duration::from_secs(120);

pub struct IsolatedProcess {
    child: Option<Child>,
}

impl IsolatedProcess {
    pub fn spawn(command: &str, args: &[&str]) -> Result<Self, String> {
        let child = Command::new(command)
            .args(args)
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .map_err(|e| format!("Failed to spawn process: {}", e))?;
        Ok(Self { child: Some(child) })
    }

    pub fn send_script(&mut self, script: &str) -> Result<String, String> {
        let mut child = self.child.take()
            .ok_or("Process already consumed".to_string())?;

        let mut stdin = child.stdin.take()
            .ok_or("Failed to open stdin".to_string())?;
        stdin.write_all(script.as_bytes())
            .map_err(|e| format!("Write error: {}", e))?;
        drop(stdin);

        // Drain stdout and stderr on separate threads so a full 64KB pipe on
        // either side cannot deadlock the child; kill and reap on timeout.
        let mut stdout = child.stdout.take()
            .ok_or("Failed to open stdout".to_string())?;
        let mut stderr = child.stderr.take()
            .ok_or("Failed to open stderr".to_string())?;
        let (tx, rx) = mpsc::channel::<(bool, String)>();
        let out_handle = {
            let tx = tx.clone();
            std::thread::spawn(move || {
                let mut buf = String::new();
                let _ = stdout.read_to_string(&mut buf);
                let _ = tx.send((true, buf));
            })
        };
        let err_handle = {
            let tx = tx.clone();
            std::thread::spawn(move || {
                let mut buf = String::new();
                let _ = stderr.read_to_string(&mut buf);
                let _ = tx.send((false, buf));
            })
        };
        drop(tx);

        let deadline = Instant::now() + SEND_TIMEOUT;
        let mut stdout_text = String::new();
        let mut stderr_text = String::new();
        let mut received = 0;
        while received < 2 {
            match rx.recv_timeout(deadline.saturating_duration_since(Instant::now())) {
                Ok((is_stdout, buf)) => {
                    if is_stdout {
                        stdout_text = buf;
                    } else {
                        stderr_text = buf;
                    }
                    received += 1;
                }
                Err(_) => {
                    let _ = child.kill();
                    let _ = child.wait();
                    let _ = out_handle.join();
                    let _ = err_handle.join();
                    return Err("Process timed out (120s), killed".to_string());
                }
            }
        }
        child
            .wait()
            .map_err(|e| format!("Process wait error: {}", e))?;
        if !stderr_text.is_empty() {
            return Err(format!("Process stderr: {}", stderr_text.trim()));
        }
        Ok(stdout_text)
    }

    pub fn kill(&mut self) {
        if let Some(ref mut child) = self.child {
            let _ = child.kill();
        }
    }
}

impl Drop for IsolatedProcess {
    fn drop(&mut self) {
        self.kill();
    }
}
