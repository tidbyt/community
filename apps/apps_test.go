package apps_test

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"tidbyt.dev/community/apps"
	"tidbyt.dev/pixlet/runtime"
)

func TestAllAppsLoad(t *testing.T) {
	manifests, err := apps.GetManifests()
	assert.NoError(t, err)

	for _, m := range manifests {
		applet := runtime.Applet{}

		runtime.InitCache(runtime.NewInMemoryCache())

		err := applet.Load(m.Name, m.Source, nil)
		assert.NoError(t, err)
	}
}

func TestFindManifest(t *testing.T) {
	// App that should exist.
	found, err := apps.FindManifest("fuzzy-clock")
	assert.NoError(t, err)
	assert.Equal(t, found.Name, "Fuzzy Clock")

	// App that should not exist.
	_, err = apps.FindManifest("foo-bar-123")
	assert.Error(t, err)
}

func TestAllAppsRegistered(t *testing.T) {
	// List of directories that are not expected to be registered in apps.go.
	exclusions := []string{
		"manifest",
	}

	manifests, err := apps.GetManifests()
	assert.NoError(t, err)

	// The number 100 is arbitrary here. We need to ensure that the apps did in
	// fact make it into the manifests and there isn't a bug somewhere. If we
	// for some reason have less then 100 apps in this repo in the future, we
	// can reduce this check.
	assert.True(t, len(manifests) > 100)

	registered := make(map[string]bool, len(manifests))
	for _, app := range manifests {
		registered[app.PackageName] = true
	}

	// Make sure each directory shows up using go embedding.
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
