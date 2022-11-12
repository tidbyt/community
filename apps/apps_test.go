package apps_test

import (
	"os"
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
		assert.NoErrorf(t, err, app.ID)
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

func TestAllAppsRegistered(t *testing.T) {
	// List of directories that are not expected to be registered in apps.go.
	exclusions := []string{
		"manifest",
	}

	manifests := apps.GetManifests()
	registered := make(map[string]bool, len(manifests))
	for _, app := range manifests {
		registered[app.PackageName] = true
	}

	dirs, err := os.ReadDir(".")
	if err != nil {
		assert.NoError(t, err)
	}
	for _, dir := range dirs {
		if !dir.IsDir() {
			continue
		}
		excluded := false
		for _, exclusion := range exclusions {
			if dir.Name() == exclusion {
				excluded = true
			}
		}
		if excluded {
			continue
		}
		assert.Containsf(t, registered, dir.Name(), "Package %s is not registered", dir.Name())
	}
}
