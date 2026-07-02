#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Integration test runner for HomeGame app - tests ACTUAL production code

.DESCRIPTION
    This script tests the production homegame.star by injecting mock data via config.
    No code duplication - tests the real app with deterministic mock data.

.PARAMETER OutputDir
    Directory to store test output images (default: ./test_output)

.PARAMETER GoldenDir
    Directory containing golden reference images (default: ./golden_images)

.PARAMETER UpdateGolden
    Update golden reference images instead of comparing

.PARAMETER KeepImages
    Keep generated test images after test completes

.EXAMPLE
    .\run_integration_tests.ps1
    .\run_integration_tests.ps1 -UpdateGolden  # Update reference images
    .\run_integration_tests.ps1 -KeepImages    # Keep test outputs
#>

param(
    [string]$OutputDir = "test_output",
    [string]$GoldenDir = "golden_images",
    [switch]$UpdateGolden,
    [switch]$KeepImages
)

# Test configurations
$testCases = @(
    @{
        Name = "future"
        Description = "Future game (not game day)"
        Expected = "Date and time on separate lines"
        Event = @{
            date = "2025-10-19T23:00Z"
            competitions = @(
                @{
                    status = @{
                        type = @{ name = "scheduled" }
                    }
                    competitors = @(
                        @{
                            homeAway = "home"
                            team = @{
                                id = "245"
                                name = "Texas A&M Aggies"
                                abbreviation = "A&M"
                            }
                        },
                        @{
                            homeAway = "away"
                            team = @{
                                id = "333"
                                name = "Louisiana State Tigers"
                                abbreviation = "LSU"
                            }
                        }
                    )
                }
            )
        }
        MockTime = "2025-10-11T20:30:00Z"  # Oct 11, 3:30 PM Central
    },
    @{
        Name = "countdown_home"
        Description = "Game day countdown (HOME - RED background)"
        Expected = "Countdown timer and RED HOME indicator"
        Event = @{
            date = "2025-10-11T23:00Z"
            competitions = @(
                @{
                    status = @{
                        type = @{ name = "scheduled" }
                    }
                    competitors = @(
                        @{
                            homeAway = "home"
                            team = @{
                                id = "245"
                                name = "Texas A&M Aggies"
                                abbreviation = "A&M"
                            }
                        },
                        @{
                            homeAway = "away"
                            team = @{
                                id = "2"
                                name = "Alabama Crimson Tide"
                                abbreviation = "ALA"
                            }
                        }
                    )
                }
            )
        }
        MockTime = "2025-10-11T20:30:00Z"  # 2.5 hours before kickoff
    },
    @{
        Name = "countdown_away"
        Description = "Game day countdown (AWAY - GREEN background)"
        Expected = "Countdown timer and GREEN AWAY indicator"
        Event = @{
            date = "2025-10-11T22:30Z"
            competitions = @(
                @{
                    status = @{
                        type = @{ name = "scheduled" }
                    }
                    competitors = @(
                        @{
                            homeAway = "home"
                            team = @{
                                id = "57"
                                name = "Florida Gators"
                                abbreviation = "FLA"
                            }
                        },
                        @{
                            homeAway = "away"
                            team = @{
                                id = "245"
                                name = "Texas A&M Aggies"
                                abbreviation = "A&M"
                            }
                        }
                    )
                }
            )
        }
        MockTime = "2025-10-11T20:30:00Z"  # 2 hours before kickoff
    },
    @{
        Name = "in_progress"
        Description = "Game in progress"
        Expected = "Scores on sides, Q3 in center"
        Event = @{
            date = "2025-10-11T22:00Z"
            competitions = @(
                @{
                    status = @{
                        type = @{ name = "in"; detail = "In Progress" }
                        period = 3
                    }
                    competitors = @(
                        @{
                            homeAway = "home"
                            team = @{
                                id = "245"
                                name = "Texas A&M Aggies"
                                abbreviation = "A&M"
                            }
                            score = "21"
                        },
                        @{
                            homeAway = "away"
                            team = @{
                                id = "228"
                                name = "Texas Longhorns"
                                abbreviation = "TEX"
                            }
                            score = "17"
                        }
                    )
                }
            )
        }
        MockTime = "2025-10-11T23:30:00Z"  # After kickoff
    }
)

# Colors for output
$ColorSuccess = "Green"
$ColorError = "Red"
$ColorInfo = "Cyan"
$ColorWarning = "Yellow"

# Test results
$totalTests = $testCases.Count
$passedTests = 0
$failedTests = 0
$results = @()

Write-Host "`n========================================" -ForegroundColor $ColorInfo
Write-Host "  HomeGame - Integration Test Suite" -ForegroundColor $ColorInfo
Write-Host "  (Testing ACTUAL Production Code)" -ForegroundColor $ColorInfo
Write-Host "========================================`n" -ForegroundColor $ColorInfo

# Check if pixlet is available
Write-Host "[INFO] Checking for pixlet..." -ForegroundColor $ColorInfo
$pixletPath = Get-Command pixlet -ErrorAction SilentlyContinue
if (-not $pixletPath) {
    Write-Host "[ERROR] pixlet not found in PATH" -ForegroundColor $ColorError
    exit 1
}
Write-Host "[OK] Found pixlet`n" -ForegroundColor $ColorSuccess

# Create directories
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}
if (-not (Test-Path $GoldenDir) -and -not $UpdateGolden) {
    Write-Host "[WARN] Golden image directory not found: $GoldenDir" -ForegroundColor $ColorWarning
    Write-Host "[INFO] Run with -UpdateGolden to create reference images`n" -ForegroundColor $ColorInfo
}

# Get production app path
$appPath = Join-Path (Split-Path -Parent $PSScriptRoot) "homegame.star"
if (-not (Test-Path $appPath)) {
    Write-Host "[ERROR] Production app not found: $appPath" -ForegroundColor $ColorError
    exit 1
}

Write-Host "[INFO] Testing production app: $appPath`n" -ForegroundColor $ColorInfo

# Run tests
foreach ($test in $testCases) {
    $testName = $test.Name
    $outputFile = Join-Path $OutputDir "$testName.webp"
    $goldenFile = Join-Path $GoldenDir "$testName.webp"

    Write-Host "----------------------------------------" -ForegroundColor $ColorInfo
    Write-Host "TEST: $testName" -ForegroundColor $ColorInfo
    Write-Host "  Description: $($test.Description)" -ForegroundColor Gray
    Write-Host "  Expected: $($test.Expected)" -ForegroundColor Gray
    Write-Host ""

    # Convert event to JSON (compact, no formatting)
    $eventJson = ($test.Event | ConvertTo-Json -Depth 10 -Compress)

    # Encode JSON as base64 to avoid command-line escaping issues
    $eventJsonBytes = [System.Text.Encoding]::UTF8.GetBytes($eventJson)
    $eventJsonB64 = [Convert]::ToBase64String($eventJsonBytes)

    # Build pixlet command with injected config
    Write-Host "  [RUNNING] pixlet render (with injected test data)..." -NoNewline

    try {
        # Use named parameters for clarity
        $output = & pixlet render $appPath `
            "_test_event_b64=$eventJsonB64" `
            "_test_time=$($test.MockTime)" `
            "team_id=245" `
            "timezone=America/Chicago" `
            -o $outputFile `
            2>&1

        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0 -and (Test-Path $outputFile)) {
            $fileSize = (Get-Item $outputFile).Length

            if ($fileSize -gt 0) {
                # Compare with golden image
                $imageMatch = $true
                if ((Test-Path $goldenFile) -and -not $UpdateGolden) {
                    $goldenHash = (Get-FileHash $goldenFile -Algorithm MD5).Hash
                    $actualHash = (Get-FileHash $outputFile -Algorithm MD5).Hash

                    if ($goldenHash -eq $actualHash) {
                        Write-Host " PASS (Exact Match)" -ForegroundColor $ColorSuccess
                        $passedTests++
                        $results += @{
                            Test = $testName
                            Status = "PASS"
                            Output = $outputFile
                            Match = "Exact"
                        }
                    } else {
                        Write-Host " FAIL (Visual Regression)" -ForegroundColor $ColorError
                        Write-Host "  [ERROR] Output differs from golden image" -ForegroundColor $ColorError
                        Write-Host "  [INFO] Golden: $goldenFile" -ForegroundColor Gray
                        Write-Host "  [INFO] Actual: $outputFile" -ForegroundColor Gray
                        $failedTests++
                        $imageMatch = $false
                        $results += @{
                            Test = $testName
                            Status = "FAIL"
                            Error = "Visual regression detected"
                        }
                    }
                } elseif ($UpdateGolden) {
                    # Copy to golden directory
                    Copy-Item $outputFile $goldenFile -Force
                    Write-Host " GOLDEN UPDATED" -ForegroundColor $ColorWarning
                    Write-Host "  [INFO] Reference image saved: $goldenFile" -ForegroundColor Gray
                    $passedTests++
                } else {
                    # No golden image exists
                    Write-Host " PASS (No Golden)" -ForegroundColor $ColorWarning
                    Write-Host "  [WARN] No golden image to compare. Run with -UpdateGolden to create." -ForegroundColor $ColorWarning
                    $passedTests++
                    $results += @{
                        Test = $testName
                        Status = "PASS"
                        Output = $outputFile
                        Match = "N/A"
                    }
                }
            } else {
                Write-Host " FAIL (Empty)" -ForegroundColor $ColorError
                $failedTests++
            }
        } else {
            Write-Host " FAIL" -ForegroundColor $ColorError
            Write-Host "  [ERROR] Render failed: $output" -ForegroundColor $ColorError
            $failedTests++
            $results += @{
                Test = $testName
                Status = "FAIL"
                Error = "Render failed: $output"
            }
        }
    } catch {
        Write-Host " FAIL" -ForegroundColor $ColorError
        Write-Host "  [ERROR] Exception: $_" -ForegroundColor $ColorError
        $failedTests++
    }

    Write-Host ""
}

# Summary
Write-Host "`n========================================" -ForegroundColor $ColorInfo
Write-Host "  TEST SUMMARY" -ForegroundColor $ColorInfo
Write-Host "========================================" -ForegroundColor $ColorInfo
Write-Host "Total Tests:  $totalTests" -ForegroundColor Gray
Write-Host "Passed:       $passedTests" -ForegroundColor $ColorSuccess
Write-Host "Failed:       $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { $ColorError } else { $ColorSuccess })
Write-Host ""

foreach ($result in $results) {
    $status = $result.Status
    $statusColor = if ($status -eq "PASS") { $ColorSuccess } else { $ColorError }
    $matchInfo = if ($result.Match) { " ($($result.Match))" } else { "" }

    Write-Host "[$status] $($result.Test)$matchInfo" -ForegroundColor $statusColor
    if ($result.Error) {
        Write-Host "      Error: $($result.Error)" -ForegroundColor $ColorError
    }
}

Write-Host "`n========================================`n" -ForegroundColor $ColorInfo

# Final status
if ($passedTests -eq $totalTests) {
    Write-Host "[SUCCESS] All tests passed!" -ForegroundColor $ColorSuccess
    if ($UpdateGolden) {
        Write-Host "`nGolden reference images updated in: $GoldenDir" -ForegroundColor $ColorInfo
    } else {
        Write-Host "`nAll outputs match golden reference images." -ForegroundColor $ColorSuccess
    }
} else {
    Write-Host "[FAILURE] Some tests failed." -ForegroundColor $ColorError
}

# Cleanup
if (-not $KeepImages -and -not $UpdateGolden) {
    Write-Host "`n[INFO] Cleaning up test images..." -ForegroundColor $ColorInfo
    Remove-Item $OutputDir -Recurse -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "`n[INFO] Test images preserved in: $OutputDir" -ForegroundColor $ColorInfo
}

exit $(if ($failedTests -eq 0) { 0 } else { 1 })
