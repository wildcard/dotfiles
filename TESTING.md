# Dotfiles Testing Plan

This document outlines how to test the newly added GitHub Codespaces support and modern CLI tools.

## Quick Links
- **Repository**: https://github.com/wildcard/dotfiles
- **Latest Commit**: 41ff97f

---

## Test 1: GitHub Codespaces (Primary Test)

### Purpose
Verify the devcontainer works in a real GitHub Codespaces environment.

### Steps

1. **Create a Codespace**
   ```bash
   # Via GitHub Web UI:
   # 1. Go to https://github.com/wildcard/dotfiles
   # 2. Click "Code" → "Codespaces" → "Create codespace on main"

   # OR via GitHub CLI:
   gh codespace create --repo wildcard/dotfiles --branch main
   ```

2. **Wait for Container Build**
   - Should see devcontainer building
   - Setup script should run automatically
   - Terminal should show: "☁️  Running in GitHub Codespaces"

3. **Verify Shell**
   ```bash
   echo $SHELL              # Should be /bin/zsh or /usr/bin/zsh
   echo $ZSH_THEME          # Should be "robbyrussell"
   which zsh                # Should exist
   ```

4. **Verify Modern Tools Installed**
   ```bash
   # Check core modern tools
   command -v rg && echo "✅ ripgrep"
   command -v bat && echo "✅ bat"
   command -v fd && echo "✅ fd"
   command -v fzf && echo "✅ fzf"
   command -v eza && echo "✅ eza"
   command -v delta && echo "✅ delta"
   command -v jq && echo "✅ jq"
   command -v httpie && echo "✅ httpie"

   # Check additional modern tools
   command -v zoxide && echo "✅ zoxide"
   command -v procs && echo "✅ procs"
   command -v bottom && echo "✅ bottom"
   command -v tldr && echo "✅ tealdeer"
   command -v hyperfine && echo "✅ hyperfine"
   command -v sd && echo "✅ sd"
   command -v starship && echo "✅ starship"
   command -v gh && echo "✅ GitHub CLI"
   command -v mise && echo "✅ mise"

   # Check symlinks work (Debian naming)
   bat --version            # Should work (not batcat)
   fd --version             # Should work (not fdfind)
   ```

5. **Verify Aliases Work**
   ```bash
   # Test eza aliases
   ls                       # Should use eza with icons
   ll                       # Should show long format with icons
   lt                       # Should show tree view

   # Test bat aliases
   cat README.md            # Should use bat with syntax highlighting

   # Test other aliases
   alias | grep "eza"       # Should show eza aliases
   alias | grep "bat"       # Should show bat aliases
   ```

6. **Verify Git Delta Integration**
   ```bash
   # Make a test change
   echo "# Test" >> README.md

   # View diff (should use delta)
   git diff README.md

   # Check delta config
   git config core.pager    # Should be "delta"

   # Revert test change
   git restore README.md
   ```

7. **Verify FZF Integration**
   ```bash
   # Test FZF with bat preview (Ctrl+T to trigger file finder)
   # Press Ctrl+T and you should see:
   # - File list
   # - Bat preview on the right with syntax highlighting

   # Verify FZF config
   echo $FZF_CTRL_T_OPTS    # Should include bat preview command
   ```

8. **Verify Environment Variables**
   ```bash
   echo $IS_CODESPACE       # Should be "true"
   echo $CODESPACES         # Should be "true"
   echo $BROWSER            # Should be "echo" (disabled)
   ```

9. **Verify Oh My Zsh Plugins**
   ```bash
   # Check plugins loaded (should exclude 1password/ssh-agent)
   echo $plugins | grep -o "\w\+" | sort

   # Should NOT see:
   # - 1password
   # - ssh-agent

   # Should see:
   # - git, docker, kubectl, z, zsh-autosuggestions, etc.
   ```

### Expected Results
- ✅ Zsh is default shell
- ✅ All modern tools installed and in PATH
- ✅ Aliases work correctly
- ✅ Git uses delta for diffs
- ✅ FZF shows bat previews
- ✅ No macOS-specific plugins loaded
- ✅ Oh My Zsh custom plugins installed (autosuggestions, syntax-highlighting)

---

## Test 2: Local macOS (Verify Backward Compatibility)

### Purpose
Ensure existing macOS setup still works after changes.

### Steps

1. **Update Homebrew Packages**
   ```bash
   cd ~/workspace/dotfiles  # Or wherever your dotfiles are
   ./brew.sh
   ```

2. **Verify No Errors**
   - Should NOT see any `--with-*` option errors
   - All packages should install successfully
   - New tools (ripgrep, bat, fd, fzf, eza, delta) should install

3. **Reload Zsh Config**
   ```bash
   exec zsh
   ```

4. **Verify macOS-Specific Features Still Work**
   ```bash
   # Should see macOS-specific plugins loaded
   echo $plugins | grep "1password"
   echo $plugins | grep "ssh-agent"

   # Should NOT see Codespace detection
   echo $IS_CODESPACE       # Should be empty

   # Homebrew should be Apple Silicon or Intel path
   echo $HOMEBREW_PREFIX    # Should be /opt/homebrew or /usr/local
   ```

5. **Test Modern Tools Work**
   ```bash
   # Same tests as Codespace
   rg "TODO" .
   bat README.md
   fd "*.md"
   eza -la

   # Test git delta
   echo "test" >> README.md
   git diff README.md
   git restore README.md
   ```

### Expected Results
- ✅ No errors during brew.sh execution
- ✅ All modern tools installed via Homebrew
- ✅ macOS-specific plugins loaded (1password, ssh-agent)
- ✅ All aliases work
- ✅ Git delta integration works

---

## Test 3: Fresh Install (macOS)

### Purpose
Test the install.sh script works non-interactively and interactively.

### Steps

1. **Backup Current Dotfiles** (if testing on your main machine)
   ```bash
   cp ~/.zshrc ~/.zshrc.backup
   cp ~/.gitconfig ~/.gitconfig.backup
   ```

2. **Run Install Script (Interactive)**
   ```bash
   cd ~/workspace/dotfiles
   ./install.sh
   ```

3. **Verify Install**
   - Should prompt for secrets scan
   - Should prompt for Git user.name/email
   - Should create backup directory
   - Should install Oh My Zsh if missing
   - Should install Oh My Zsh plugins

4. **Test Non-Interactive Mode**
   ```bash
   INTERACTIVE=false ./install.sh
   # Should skip all prompts
   ```

### Expected Results
- ✅ Interactive prompts work
- ✅ Non-interactive mode skips prompts
- ✅ Symlinks created correctly
- ✅ No errors during installation

---

## Test 4: VS Code Devcontainer (Local)

### Purpose
Test devcontainer locally without using GitHub Codespaces.

### Prerequisites
- Docker Desktop installed
- VS Code with "Dev Containers" extension

### Steps

1. **Open in Container**
   ```bash
   # In VS Code:
   # 1. Open the dotfiles folder
   # 2. Press Cmd+Shift+P (Mac) or Ctrl+Shift+P (Windows/Linux)
   # 3. Select "Dev Containers: Reopen in Container"
   ```

2. **Wait for Build**
   - Container should build using .devcontainer/devcontainer.json
   - Setup script should run

3. **Run Same Tests as Codespaces**
   - Follow all steps from Test 1
   - Should have identical results

### Expected Results
- ✅ Same as Test 1 (Codespaces)

---

## Test 5: Ripgrep Configuration

### Purpose
Verify .ripgreprc is loaded and working.

### Steps

```bash
# Create test files
mkdir -p /tmp/rg-test
cd /tmp/rg-test
echo "password=secret123" > .env
echo "TODO: implement feature" > main.py
mkdir node_modules
echo "test" > node_modules/test.js

# Test ripgrep
rg "password"              # Should NOT search .env (ignored)
rg "TODO"                  # Should find main.py
rg "test" --hidden         # Should skip node_modules (ignored)

# Verify config loaded
rg --version
echo $RIPGREP_CONFIG_PATH  # Should be ~/.ripgreprc

# Cleanup
cd ~
rm -rf /tmp/rg-test
```

### Expected Results
- ✅ .ripgreprc is loaded
- ✅ Ignore patterns work (.git, node_modules)
- ✅ Colors configured

---

## Test 6: Bat Configuration

### Purpose
Verify bat theme and pager settings.

### Steps

```bash
# Check bat config
echo $BAT_THEME            # Should be "Solarized (dark)"
echo $BAT_STYLE            # Should be "numbers,changes,header"

# Test bat with paging
bat install.sh             # Should show syntax highlighting with line numbers

# Test man pages with bat
man ls                     # Should use bat for syntax highlighting
```

### Expected Results
- ✅ Syntax highlighting works
- ✅ Line numbers shown
- ✅ Man pages use bat

---

## Validation Checklist

After running tests, verify:

### Codespaces ✅
- [ ] Devcontainer builds without errors
- [ ] Zsh is default shell
- [ ] All 8 modern tools installed (rg, bat, fd, fzf, eza, delta, jq, httpie)
- [ ] Aliases work (ls→eza, cat→bat, grep→rg, find→fd)
- [ ] Git uses delta for diffs
- [ ] FZF has bat/eza previews
- [ ] No macOS-specific plugins loaded
- [ ] IS_CODESPACE=true

### macOS ✅
- [ ] brew.sh runs without errors
- [ ] No deprecated flag warnings
- [ ] Modern tools installed via Homebrew
- [ ] macOS plugins loaded (1password, ssh-agent)
- [ ] Homebrew path correct (/opt/homebrew or /usr/local)
- [ ] All aliases work
- [ ] Git delta works

### Both Environments ✅
- [ ] .ripgreprc loaded and working
- [ ] bat theme set to Solarized
- [ ] Man pages use bat
- [ ] Git delta side-by-side diffs
- [ ] FZF with previews
- [ ] Oh My Zsh custom plugins work

---

## Troubleshooting

### Issue: Devcontainer fails to build
**Solution**: Check .devcontainer/devcontainer.json syntax with `jsonlint` or VS Code

### Issue: Tools not in PATH
**Solution**: Run `exec zsh` to reload shell or check PATH with `echo $PATH`

### Issue: Bat shows no colors
**Solution**: Check `echo $BAT_THEME` and verify bat version with `bat --version`

### Issue: Delta not working in git
**Solution**: Run `git config core.pager` to verify, manually set with `git config --global core.pager delta`

### Issue: Aliases not working
**Solution**: Check if tools are installed with `command -v <tool>`, reload with `source ~/.zshrc`

---

## Performance Testing

### Measure Tool Speed

```bash
# Benchmark ripgrep vs grep
time rg "TODO" .
time grep -r "TODO" .

# Benchmark fd vs find
time fd "*.md"
time find . -name "*.md"

# Benchmark eza vs ls
time eza -la
time ls -la
```

### Expected Performance
- ripgrep: 5-10x faster than grep on large codebases
- fd: 2-5x faster than find
- eza: Similar to ls, slightly slower due to icons/git integration

---

## Success Criteria

The implementation is successful if:

1. ✅ Codespace launches and all tools work
2. ✅ macOS setup unchanged and working
3. ✅ No errors during installation
4. ✅ All modern tools faster than traditional equivalents
5. ✅ Git diffs are more readable with delta
6. ✅ FZF provides helpful previews
7. ✅ Aliases provide better UX without breaking workflows

---

## Next Steps After Testing

If all tests pass:
- ✅ Update README.md with Codespaces badge
- ✅ Add screenshots of delta/bat/eza in action
- ✅ Document modern tools in main README
- ✅ Create video demo of Codespaces setup

If tests fail:
- Debug specific failures
- Check logs in Codespace: `cat ~/.dotfiles_install.log`
- Verify package versions: `<tool> --version`
- Open issue with error details
