use std::process::{Command, Child, Stdio};
use std::io::{Read, Write};
use std::sync::mpsc;
use std::time::Duration;

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

        // Read stdout on a thread so a hung process or a full pipe cannot
        // block forever; kill the child on timeout.
        let mut stdout = child.stdout.take()
            .ok_or("Failed to open stdout".to_string())?;
        let (tx, rx) = mpsc::channel();
        let handle = std::thread::spawn(move || {
            let mut buf = String::new();
            let _ = stdout.read_to_string(&mut buf);
            let _ = tx.send(buf);
        });

        let stdout_text = match rx.recv_timeout(SEND_TIMEOUT) {
            Ok(text) => text,
            Err(_) => {
                let _ = child.kill();
                let _ = handle.join();
                return Err("Process timed out (120s), killed".to_string());
            }
        };
        child
            .wait()
            .map_err(|e| format!("Process wait error: {}", e))?;
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
