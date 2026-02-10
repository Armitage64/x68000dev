# Desktop Commander Quick Start Guide

## What is Desktop Commander?

Desktop Commander bridges Claude Code on the web with your local Windows development environment, allowing me to:
- Execute build commands on your Windows machine
- Run tests with your local tools
- Access your development environment directly
- Build and test X68000 code using your installed toolchain

## Quick Setup (5 Minutes)

### 1. Install Claude Desktop
- Download: https://claude.ai/download
- Install and sign in with your Anthropic account

### 2. Enable Desktop Commander
In Claude Desktop app:
1. Click Settings (gear icon)
2. Go to "Desktop Commander" or "Developer" section
3. Toggle ON "Allow web sessions to run commands"
4. Click "Add Directory" and select this repository folder
5. (Optional) Configure command approval settings

### 3. Connect to Web Session
1. Open https://claude.ai in your browser
2. Make sure you're signed in with the same account
3. The Desktop app will automatically connect when you start chatting
4. Look for a "Desktop Commander Connected" indicator

### 4. Test the Connection
Ask me to run a simple command:
```
"List the files in this directory using dir"
```

If I can execute it, you're all set!

## What Can I Do With Desktop Commander?

With Desktop Commander connected, I can help you:

### Building & Compiling
- Run make commands to build X68000 projects
- Execute compilers and assemblers
- Link executables
- Clean build artifacts

### Testing
- Run X68000 emulators (px68k, XM6, etc.)
- Test executables and music drivers
- Validate output files
- Check audio playback

### Development Tools
- Use git for version control
- Run batch scripts
- Execute development utilities
- Manage dependencies

### File Operations
- Create and modify files
- Organize project structure
- Search for files
- Check file contents

## Example Workflow

1. **You**: "Build the X68000 project using make"
2. **Me**: I'll run `make` on your Windows machine and show you the output
3. **You**: "Test it in the emulator"
4. **Me**: I'll launch the emulator with your compiled executable
5. **You**: "Looks good, commit the changes"
6. **Me**: I'll create a git commit with the changes

## Security & Privacy

### What I Can Access
- Only directories you explicitly allow in Desktop Commander settings
- Only commands you approve (based on your settings)
- Your local development environment and tools

### What I Cannot Access
- Directories outside allowed paths
- System files (unless you specifically allow them)
- Personal files outside the project

### Safety Features
- Command approval (you can require confirmation for each command)
- Directory restrictions (whitelist only)
- Command pattern filtering
- Activity logging in Desktop app
- Revocable access (disable anytime)

## Troubleshooting

### "Desktop Commander not connected"
✓ Claude Desktop app is running
✓ You're signed in to the same account on web and desktop
✓ Desktop Commander is enabled in settings
✓ Try restarting the Desktop app

### "Permission denied" errors
✓ Repository directory is added to allowed directories
✓ Command patterns are configured correctly
✓ You approved the command (if approval is required)
✓ Windows file permissions allow access

### "Command not found"
✓ Required tools are installed on your Windows machine
✓ Tools are in your system PATH
✓ You're running from the correct working directory

### Commands hang or timeout
✓ Command doesn't require interactive input
✓ Process isn't waiting for user input
✓ Timeout settings in Desktop Commander are adequate
✓ No antivirus blocking execution

## Configuration Tips

### Recommended Settings for X68000 Development

**Allowed Directories:**
```
C:\x68000dev
C:\your\project\path
```

**Command Patterns:**
```
make
make.exe
*.bat
*.cmd
git
git.exe
dir
cd
cls
type
```

**Command Approval:**
- Start with "Require approval for all commands"
- Once comfortable, switch to "Auto-approve safe commands"
- Keep "Always require approval for destructive commands" enabled

### Performance Optimization
- Keep Desktop app running in the background
- Add project directory to antivirus exceptions
- Use SSD for project files if possible
- Ensure network connection is stable

## Next Steps

Now that Desktop Commander is set up:

1. **Build your project**: Ask me to compile your X68000 code
2. **Run tests**: Have me execute tests on your local environment
3. **Debug issues**: I can help investigate build errors
4. **Automate workflows**: Set up build scripts and automation

## Questions?

Just ask! I can help you:
- Configure Desktop Commander for your specific needs
- Troubleshoot connection issues
- Set up your X68000 development environment
- Create build scripts and automation
- Optimize your workflow

Let's start building for the X68000!
