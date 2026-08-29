# 🔒 Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 3.0.x   | ✅ Yes             |
| 2.0.x   | ❌ No              |
| < 2.0   | ❌ No              |

## Reporting a Vulnerability

If you discover a security vulnerability within BloxStrike, please send an email to [your-email@example.com]. All security vulnerabilities will be promptly addressed.

**Please do NOT report security vulnerabilities through public GitHub issues.**

### What to include

When reporting a vulnerability, please include:

- Type of vulnerability (e.g., code injection, privilege escalation, etc.)
- Full paths of source file(s) related to the vulnerability
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

### Response timeline

- **Initial response**: Within 48 hours
- **Status update**: Within 1 week
- **Fix timeline**: Depends on severity

## Security Best Practices

### For Users

1. **Use trusted executors only**
   - Fluxus, Delta, Wave, Solara, etc.
   - Avoid unknown/sketchy executors

2. **Keep scripts updated**
   - Always use the latest version
   - Check for updates regularly

3. **Use alternate accounts**
   - Never use your main account
   - Risk of ban exists with any script

4. **Be cautious with settings**
   - Don't use extreme values
   - Enable safety features

### For Developers

1. **Input validation**
   - Always validate user input
   - Sanitize strings before use

2. **Error handling**
   - Use pcall for risky operations
   - Don't expose sensitive info in errors

3. **Code obfuscation**
   - Consider obfuscating sensitive code
   - Protect against reverse engineering

## Known Security Considerations

### Anti-Cheat Systems

BloxStrike includes bypass mechanisms for educational purposes:

- **Metamethod Protection**: Guards against AC detection
- **Environment Spoofing**: Hides modifications from detection
- **Thread Hiding**: Conceals running threads from monitoring
- **Memory Protection**: Protects against memory scanning

### Limitations

- No system is 100% secure
- Anti-cheat systems are constantly updating
- Use at your own risk
- We are not responsible for any bans

## Vulnerability Disclosure Policy

### Coordinated Disclosure

We follow coordinated disclosure:

1. **Report**: Researcher reports vulnerability privately
2. **Confirm**: We confirm the vulnerability
3. **Fix**: We develop and test a fix
4. **Release**: We release the fix
5. **Disclose**: We publicly disclose the vulnerability

### Timeline

- **Day 0**: Vulnerability reported
- **Day 1-2**: Initial response and confirmation
- **Day 7-14**: Fix development
- **Day 14-30**: Fix release and disclosure

## Contact

For security-related inquiries:

- **Email**: [your-email@example.com]
- **GitHub**: Create a private security advisory

## Acknowledgments

We thank security researchers who responsibly disclose vulnerabilities.

## Changes to This Policy

We may update this security policy from time to time. Please check the repository for the latest version.
