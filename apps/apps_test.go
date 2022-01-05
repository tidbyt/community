package apps_test

import (
	"fmt"
	"testing"

	"tidbyt.dev/community-apps/apps"
)

// TODO(mark): add tests to validate all applet fields. We should check casing,
// spelling, and length.

// TODO(mark): add a test that tests the actual starlark

// TODO(mark): add the ability to use our unit test module.
func TestGetApps(t *testing.T) {
	applets := apps.GetApps()
	for _, app := range applets {
		fmt.Println(app.Name)
	}
}
