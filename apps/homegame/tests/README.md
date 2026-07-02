# HomeGame Integration Tests

## Overview

This directory contains **integration tests** that test the **actual production code** in `homegame.star` without code duplication.

### Key Features

- ✅ **Zero Code Duplication** - Tests inject mock data into production app
- ✅ **Deterministic** - Uses fixed mock time for reproducible results
- ✅ **Visual Regression** - Compares output against golden reference images
- ✅ **Fast** - No API calls, runs in seconds
- ✅ **CI-Ready** - Exit codes for automation

## How It Works

1. **Test Runner** (`run_integration_tests.ps1`) generates mock ESPN API data as JSON
2. **JSON Encoding** - Converts to base64 to avoid command-line escaping issues
3. **Config Injection** - Passes mock data via `_test_event_b64` config parameter
4. **Production Code** - `homegame.star` detects test config and uses mock data instead of API
5. **Golden Comparison** - Compares rendered WebP against reference images
6. **Result** - Reports pass/fail with pixel-perfect validation

## Running Tests

### All Tests (Automated)

```powershell
# From homegame/tests directory
.\run_integration_tests.ps1

# Keep test images for inspection
.\run_integration_tests.ps1 -KeepImages

# Update golden reference images (after verifying changes are correct)
.\run_integration_tests.ps1 -UpdateGolden
```

### Test Cases

| Test | Description | Mock Time | Expected Output |
|------|-------------|-----------|-----------------|
| `future` | Future game (Oct 19) | Oct 11, 3:30 PM | Date/time on separate lines |
| `countdown_home` | Home game countdown | Oct 11, 3:30 PM | RED background, "2h 30m" countdown |
| `countdown_away` | Away game countdown | Oct 11, 3:30 PM | GREEN background, "2h 0m" countdown |
| `in_progress` | Game in progress | Oct 11, 6:30 PM | Yellow "IN PROGRESS" text |

## Golden Images

The `golden_images/` directory contains reference images for visual regression testing.

**Important**:
- ✅ DO commit golden images to Git (they're small and essential)
- ⚠️  Only update via `-UpdateGolden` after manually verifying changes
- 🔍 Review diffs carefully when golden images change

## Test Architecture

### No Code Duplication

Unlike typical Tidbyt tests that duplicate business logic, this approach:

1. **Injects test data** via config parameters
2. **Tests actual production code** - same code path users hit
3. **Stays in sync automatically** - changes to production code are immediately tested

### Time Mocking

Tests use `_test_time` parameter to freeze time:

```powershell
_test_time=2025-10-11T20:30:00Z  # Fixed: Oct 11, 2025 @ 3:30 PM Central
```

This ensures:
- Countdown calculations are deterministic
- Tests produce identical output every run
- Can test edge cases (midnight, exact kickoff time, etc.)

### Visual Regression

Tests compare MD5 hashes of rendered images:

- **Exact Match** ✅ - Pixel-perfect, no changes
- **Mismatch** ❌ - Visual regression detected

This catches:
- Color changes (HOME=RED, AWAY=GREEN)
- Layout shifts
- Text changes
- Font/spacing issues

## Troubleshooting

### Tests Fail After Code Changes

**Expected!** If you modified `homegame.star`:

1. Run tests: `.\run_integration_tests.ps1 -KeepImages`
2. Inspect images in `test_output/`
3. If changes look correct: `.\run_integration_tests.ps1 -UpdateGolden`
4. Commit new golden images

### JSON Encoding Issues

Tests use base64 encoding to avoid PowerShell command-line escaping issues. If you see JSON parse errors, check the base64 encoding logic.

### Time Zone Issues

Mock time is in UTC (`Z` suffix). The app converts to `America/Chicago` (Central Time). Ensure your test scenarios account for the 5-6 hour offset.

## Extending Tests

To add a new test case:

1. Add test configuration to `$testCases` array in `run_integration_tests.ps1`
2. Define mock ESPN API event data
3. Set `MockTime` for deterministic countdown
4. Run with `-UpdateGolden` to create reference image
5. Document expected behavior

## CI/CD Integration

```yaml
# Example GitHub Actions
- name: Run Integration Tests
  run: |
    cd apps/homegame/tests
    pwsh -File run_integration_tests.ps1
```

Exit codes:
- `0` = All tests passed
- `1` = One or more tests failed
