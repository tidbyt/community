// Package apps provides a clean way for Tidbyt to be able to get a list of all
// community apps.
package apps

import (
	"tidbyt.dev/community/apps/fuzzyclock"
	"tidbyt.dev/community/apps/manifest"
)

// GetManifests returns a list of all apps in the this repository. Add your applet
// below to include it in the Tidbyt Mobile app for all Tidbyt users.
func GetManifests() []manifest.Manifest {
	return []manifest.Manifest{
		fuzzyclock.New(),
	}
}
