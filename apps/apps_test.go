package apps_test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"tidbyt.dev/community/apps"
)

// TODO(mark): add a test that tests the actual starlark

// TODO(mark): add the ability to use our unit test module.
func TestManifestsValidate(t *testing.T) {
	applets := apps.GetManifests()
	for _, app := range applets {
		err := app.Validate()
		assert.NoError(t, err)
	}
}
