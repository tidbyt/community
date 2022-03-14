package apps_test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/apps/fuzzyclock"
	"tidbyt.dev/pixlet/runtime"
)

func TestAllApps(t *testing.T) {
	for _, m := range apps.GetManifests() {
		applet := runtime.Applet{}

		runtime.InitCache(runtime.NewInMemoryCache())

		err := applet.Load(m.Name, m.Source, nil)
		assert.NoError(t, err)
	}
}

func TestManifestsValidate(t *testing.T) {
	applets := apps.GetManifests()
	for _, app := range applets {
		err := app.Validate()
		assert.NoError(t, err)
	}
}

func TestFindManifest(t *testing.T) {
	// App that should exist.
	expected := fuzzyclock.New()
	found, err := apps.FindManifest(expected.ID)
	assert.NoError(t, err)
	assert.Equal(t, found, &expected)

	// App that should not exist.
	_, err = apps.FindManifest("foo-bar-123")
	assert.Error(t, err)
}
