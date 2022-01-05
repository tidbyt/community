package apps_test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"tidbyt.dev/community/apps"
	"tidbyt.dev/pixlet/runtime"
)

func TestAllApps(t *testing.T) {
	for _, m := range apps.GetManifests() {
		applet := runtime.Applet{}

		runtime.InitCache(runtime.NewInMemoryCache())

		err := applet.Load(m.Name, m.Source, nil)
		assert.NoError(t, err)

		_, err = applet.Run(map[string]string{})
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
