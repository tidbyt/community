# HomeGame Development Guide

## Prerequisites

- **Pixlet** - The only tool you need! (includes buildifier linter built-in)
- **PowerShell** - For running test scripts (Windows)

## Development Workflow

### 1. Local Development & Preview

```bash
# Serve the app locally with hot reload
pixlet serve homegame.star --port 81

# View in browser
# http://localhost:81
```

### 2. Code Quality & Linting

Pixlet includes **Buildifier**, the official Bazel/Starlark linter, built-in!

```bash
# Check code quality (format + lint + tests)
pixlet check homegame.star

# View lint warnings
pixlet lint homegame.star

# Auto-fix lint issues
pixlet lint --fix homegame.star
```

**What does the linter check?**
- ✅ Starlark code formatting (whitespace, indentation)
- ✅ Code style consistency
- ✅ Best practices for Tidbyt apps
- ✅ Buildifier warnings (unused variables, deprecated patterns, etc.)

**Tip**: Always run `pixlet lint --fix` before committing!

### 3. Testing

```powershell
# From the tests/ directory

# Run all integration tests
.\run_integration_tests.ps1

# Keep test images for inspection
.\run_integration_tests.ps1 -KeepImages

# Update golden reference images (after verifying changes)
.\run_integration_tests.ps1 -UpdateGolden
```

### 4. Pre-Commit Checklist

Before committing changes, ensure:

1. ✅ **Lint**: `pixlet lint --fix homegame.star`
2. ✅ **Check**: `pixlet check homegame.star` (must pass)
3. ✅ **Test**: `.\tests\run_integration_tests.ps1` (must pass)
4. ✅ **Preview**: `pixlet serve homegame.star` (visual inspection)

### 5. Pre-Commit Hook (Automated)

A Git pre-commit hook is **already installed** that automates steps 1 & 2!

**What it does:**
- ✅ Automatically runs `pixlet lint --fix` on staged `.star` files
- ✅ Runs `pixlet check` to verify code quality
- ✅ Stages auto-fixed files
- ✅ Blocks commit if checks fail

**Usage:**
Just commit as normal - the hook runs automatically:
```bash
git add homegame.star
git commit -m "Update game logic"
# Hook runs automatically before commit
```

**Hook output:**
```
========================================
  HomeGame Pre-Commit Quality Check
========================================

[INFO] Found modified Starlark files:
  - apps/homegame/homegame.star

[LINT] Running pixlet lint --fix...
[OK] Linting complete
[OK] Staged auto-fixed file

[CHECK] Running pixlet check...
✔️ apps/homegame/homegame.star
[OK] All checks passed

========================================
  PRE-COMMIT CHECK PASSED ✓
========================================
```

**Bypass hook** (not recommended):
```bash
git commit --no-verify
```

**Verify hook is installed:**
```bash
ls -la .git/hooks/pre-commit
# Should show: -rwxr-xr-x (executable)
```

## Buildifier Integration

### What is Buildifier?

Buildifier is the official linter for Bazel and Starlark code. It's maintained by the Bazel team and enforces consistent code style.

**GitHub**: https://github.com/bazelbuild/buildtools/blob/main/buildifier/README.md

### How Pixlet Uses Buildifier

As of 2025, Pixlet has **unified tooling** built-in:
- No need to install buildifier separately
- No need to install Make, Go, or golangci-lint
- Just install Pixlet, and you're ready to develop!

**Key Command**: `pixlet check` runs:
1. **Format check** - Ensures proper Starlark formatting
2. **Lint check** - Runs buildifier with linting rules
3. **App validation** - Tidbyt-specific checks

### Common Lint Fixes

Buildifier will automatically fix:
- ✅ Inconsistent indentation (spaces vs tabs)
- ✅ Trailing whitespace
- ✅ Missing blank lines
- ✅ Incorrect import order
- ✅ Unnecessary parentheses
- ✅ Deprecated Starlark patterns

### Suppressing Warnings

To suppress specific buildifier warnings:

```starlark
# buildifier: disable=<warning-name>
problematic_code_here()
```

Example:
```starlark
# buildifier: disable=unused-variable
unused_var = get_some_data()
```

**Warning**: Only suppress when absolutely necessary!

## Code Style Guidelines

### Naming Conventions

- **Functions**: `snake_case` (e.g., `parse_game_event`)
- **Variables**: `snake_case` (e.g., `our_team`, `is_home_game`)
- **Constants**: `UPPER_SNAKE_CASE` (e.g., `DEFAULT_TEAM_ID`)

### Documentation

Always include docstrings:

```starlark
def my_function(param1, param2):
    """
    Brief description of what the function does.

    Args:
        param1: Description of param1
        param2: Description of param2

    Returns:
        Description of return value
    """
    # Implementation
```

### Line Length

- Prefer lines ≤ 80 characters
- Buildifier will warn on lines > 119 characters

### Import Order

Load statements should be alphabetically sorted:

```starlark
load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
```

## Integration Tests

### Architecture

The test suite uses **dependency injection** to test production code without duplication:

```
Test Runner (PowerShell)
    ↓ Generates mock data
    ↓ Encodes as base64
    ↓ Passes via config parameter
    ↓
Production App (homegame.star)
    ↓ Detects test mode
    ↓ Uses mock data instead of API
    ↓ Renders actual output
    ↓
Golden Image Comparison
    ↓ MD5 hash comparison
    ✅ PASS if exact match
```

**Benefits**:
- Zero code duplication
- Tests actual production code
- Automatic sync with code changes
- Pixel-perfect visual regression detection

### Adding New Tests

1. Add test case to `tests/run_integration_tests.ps1`:

```powershell
@{
    Name = "my_test"
    Description = "Test description"
    Expected = "What should be displayed"
    Event = @{
        # Mock ESPN API data
    }
    MockTime = "2025-10-11T20:30:00Z"
}
```

2. Run with `-UpdateGolden` to create reference image:

```powershell
.\run_integration_tests.ps1 -UpdateGolden
```

3. Commit the new golden image in `tests/golden_images/`

## Debugging

### Print Debugging

Use `print()` statements (output appears in console):

```starlark
print("Debug: our_team =", our_team)
print("Debug: game_status =", game_status)
```

### Visual Debugging

Use `pixlet serve` to see changes in real-time:

```bash
pixlet serve homegame.star --port 81
# Edit code, save, browser auto-refreshes
```

### Test-Specific Debugging

Keep test images for inspection:

```powershell
.\run_integration_tests.ps1 -KeepImages
# Images saved in tests/test_output/
```

## Performance Tips

### API Caching

```starlark
# Cache API responses for 5 minutes
cached_data = cache.get(cache_key)
if cached_data:
    return cached_data

# Fetch and cache
data = http.get(url).json()
cache.set(cache_key, data, ttl_seconds = 300)
```

### Minimize API Calls

- Use cache aggressively
- Fetch only what you need
- Avoid redundant API requests

### Test Without API

Use test injection for development:

```bash
# No API calls made during testing!
.\run_integration_tests.ps1
```

## Publishing to Tidbyt Community

Before submitting a PR to `tidbyt/community`:

1. ✅ Run `pixlet check homegame.star` (must pass)
2. ✅ Run all tests (must pass)
3. ✅ Test on physical Tidbyt device
4. ✅ Update `manifest.yaml` with correct metadata
5. ✅ Ensure `README.md` is up-to-date
6. ✅ Include screenshots/GIFs

**Submission Process**:
1. Fork `tidbyt/community`
2. Create feature branch
3. Add your app to `apps/`
4. Open pull request
5. Maintainers will review (linting is automated via CI)

## Useful Resources

- **Pixlet Docs**: https://tidbyt.dev/docs/
- **Starlark Spec**: https://github.com/bazelbuild/starlark
- **Buildifier Docs**: https://github.com/bazelbuild/buildtools/blob/main/buildifier/README.md
- **Tidbyt Community**: https://github.com/tidbyt/community
- **ESPN API**: http://site.api.espn.com/apis/site/v2/sports/football/college-football/teams/{team_id}

## Quick Reference

```bash
# Development
pixlet serve homegame.star --port 81

# Quality
pixlet lint --fix homegame.star
pixlet check homegame.star

# Testing
.\tests\run_integration_tests.ps1
.\tests\run_integration_tests.ps1 -KeepImages
.\tests\run_integration_tests.ps1 -UpdateGolden

# Production
pixlet render homegame.star -o output.webp
pixlet push YOUR_DEVICE_ID homegame.star
```

## Troubleshooting

### "linting failed with exit code: 4"

**Solution**: Run `pixlet lint --fix homegame.star` to auto-fix issues.

### Tests fail after code changes

**Expected!** If you modified the UI:
1. Run tests with `-KeepImages`
2. Inspect images in `test_output/`
3. If correct: `.\run_integration_tests.ps1 -UpdateGolden`
4. Commit new golden images

### API returns unexpected data

**Debug**:
1. Add `print()` statements
2. Check ESPN API directly: `http://site.api.espn.com/apis/site/v2/sports/football/college-football/teams/245`
3. Verify API response structure hasn't changed

### Pixlet command not found

**Solution**: Add Pixlet to PATH or use full path to executable.

---

**Happy Coding!** 🏈
