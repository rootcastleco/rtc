#!/usr/bin/env node

const { execSync, spawn } = require("child_process");
const os = require("os");
const path = require("path");
const fs = require("fs");

// ─── Colors ────────────────────────────────────────────────────────────────
const RED = "\x1b[31m";
const GREEN = "\x1b[32m";
const YELLOW = "\x1b[33m";
const CYAN = "\x1b[36m";
const BOLD = "\x1b[1m";
const NC = "\x1b[0m";

const log = {
  info: (msg) => console.log(`${CYAN}[INFO]${NC}  ${msg}`),
  ok: (msg) => console.log(`${GREEN}[OK]${NC}    ${msg}`),
  warn: (msg) => console.log(`${YELLOW}[WARN]${NC}  ${msg}`),
  err: (msg) => console.log(`${RED}[ERROR]${NC} ${msg}`),
};

// ─── Check if running on Linux ─────────────────────────────────────────────
if (os.platform() !== "linux") {
  log.err("This installer only works on Linux servers.");
  log.info("Run this on your Alma Linux server:");
  log.info("  npx frigate-nvr-installer");
  process.exit(1);
}

// ─── Check if running as root ──────────────────────────────────────────────
if (process.getuid && process.getuid() !== 0) {
  log.err("This script must be run as root!");
  log.info("Usage: sudo npx frigate-nvr-installer");
  process.exit(1);
}

// ─── Run the bash installer ────────────────────────────────────────────────
const scriptPath = path.join(__dirname, "install_frigate.sh");

if (!fs.existsSync(scriptPath)) {
  log.err(`Install script not found: ${scriptPath}`);
  process.exit(1);
}

console.log("");
console.log(`${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}`);
console.log(`${BOLD}║   🎥  Frigate NVR — Fleet Video Server Installer  🎥       ║${NC}`);
console.log(`${BOLD}║   via npx frigate-nvr-installer                            ║${NC}`);
console.log(`${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}`);
console.log("");

log.info("Launching Frigate NVR installer...");
log.info(`Script: ${scriptPath}`);
console.log("");

// Execute the bash script with inherited stdio
const child = spawn("bash", [scriptPath], {
  stdio: "inherit",
  env: process.env,
});

child.on("error", (err) => {
  log.err(`Failed to run installer: ${err.message}`);
  process.exit(1);
});

child.on("close", (code) => {
  if (code === 0) {
    log.ok("Installation completed successfully!");
  } else {
    log.err(`Installation failed with exit code: ${code}`);
  }
  process.exit(code);
});
