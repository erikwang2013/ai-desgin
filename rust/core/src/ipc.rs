use std::process::{Command, Child, Stdio};
use std::io::Write;

pub struct IsolatedProcess {
    child: Child,
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
        Ok(Self { child })
    }

    pub fn send_script(&mut self, script: &str) -> Result<String, String> {
        let stdin = self.child.stdin.as_mut()
            .ok_or("Failed to open stdin".to_string())?;
        stdin.write_all(script.as_bytes())
            .map_err(|e| format!("Write error: {}", e))?;
        Ok(String::new())
    }

    pub fn kill(&mut self) {
        let _ = self.child.kill();
    }
}

impl Drop for IsolatedProcess {
    fn drop(&mut self) {
        self.kill();
    }
}
