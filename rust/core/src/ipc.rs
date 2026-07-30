use std::process::{Command, Child, Stdio};
use std::io::Write;

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

        let output = child.wait_with_output()
            .map_err(|e| format!("Process error: {}", e))?;
        String::from_utf8(output.stdout)
            .map_err(|e| format!("Invalid UTF-8 output: {}", e))
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
