# X68000 Development Environment

This repository contains Sharp X68000 development files and tools.

## Desktop Commander Setup

Desktop Commander enables Claude Code (web) to execute commands directly on your Windows machine, allowing for building and testing X68000 code with your local development environment.

### Prerequisites

1. **Claude Desktop App** installed on your Windows machine
2. **Desktop Commander** feature enabled in Claude Desktop
3. Your development tools installed locally (X68000 cross-compilers, emulators, etc.)

### Setup Instructions

#### Step 1: Install Claude Desktop App

1. Download and install the Claude Desktop app from: https://claude.ai/download
2. Sign in with your Anthropic account

#### Step 2: Enable Desktop Commander

1. Open Claude Desktop app settings
2. Navigate to the "Desktop Commander" section
3. Enable "Allow web sessions to run commands on this computer"
4. Configure your allowed directories (include this repository's path)

#### Step 3: Connect This Repository

1. In the Desktop Commander settings, add this repository path:
   ```
   C:\path\to\x68000dev
   ```

2. Set allowed command patterns (examples for X68000 development):
   - `make` - for building projects
   - `*.bat` - for batch scripts
   - `*.exe` - for running compilers and tools
   - `dir`, `ls` - for directory listing
   - `git` - for version control operations

#### Step 4: Start a Commander Session

1. Open Claude.ai in your web browser
2. Navigate to this project or start a new conversation
3. Share this repository with Claude
4. Claude will detect the Desktop Commander connection and can now run commands

### Security Considerations

Desktop Commander gives Claude the ability to execute commands on your local machine. To stay safe:

- Only allow specific directories (not your entire system)
- Review command patterns carefully
- Monitor the commands being executed
- You can revoke access at any time in Desktop App settings
- Commands require your approval before execution (configurable)

### Testing the Connection

Once configured, you can test the connection by asking Claude to:

```
Run 'dir' to list files in this directory
```

If Desktop Commander is properly configured, Claude will execute this on your Windows machine.

### Building X68000 Projects

With Desktop Commander connected, you can ask Claude to:

- Build projects using your local toolchain
- Run emulators to test code
- Compile and link X68000 executables
- Test audio drivers (like mxdrv.x)
- Debug compilation errors

Example commands you might use:
```batch
REM Build a project
make all

REM Run in emulator
px68k.exe mxdrv.x

REM Clean build artifacts
make clean
```

### Troubleshooting

**Connection not detected:**
- Ensure Claude Desktop app is running
- Check that Desktop Commander is enabled in settings
- Verify the repository path is in allowed directories
- Restart Claude Desktop app

**Commands fail to execute:**
- Check command patterns in Desktop Commander settings
- Ensure required tools are in your PATH
- Verify file permissions
- Check that you're in the correct working directory

**Permission errors:**
- Review allowed directories in Desktop Commander settings
- Ensure the directory is not restricted by antivirus
- Run Claude Desktop with appropriate permissions

### File Structure

```
x68000dev/
├── README.md           # This file
├── mxdrv.x            # X68000 executable
├── MAGICAL.MDX        # Music data file
├── SPLASH.MDX         # Music data file
├── PASSING.MDX        # Music data file
└── LAST.MDX           # Music data file
```

## Development Workflow

1. **Edit code** in your preferred editor or ask Claude to make changes
2. **Build** using Claude with Desktop Commander: "Build the project"
3. **Test** on your local X68000 emulator
4. **Debug** issues with Claude's help
5. **Commit** changes when ready

## Additional Resources

- [Claude Desktop Commander Documentation](https://docs.anthropic.com/claude/docs/desktop-commander)
- [X68000 Development Guide](https://github.com/yosshin4004/x68k_gcc_has_build)
- Sharp X68000 technical documentation

## Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Desktop Commander logs in Claude Desktop app
3. Visit the Claude support documentation
