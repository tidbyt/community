// Package apps provides a clean way for Tidbyt to be able to get a list of all
// community apps.
package apps

import (
	"tidbyt.dev/community-apps/apps/community"
	"tidbyt.dev/community-apps/apps/fuzzyclock"
)

// GetApps returns a list of all apps in the this repository. Add your applet
// below to include it in the Tidbyt Mobile app for all Tidbyt users.
func GetApps() []community.App {
	return []community.App{
		fuzzyclock.New(),
	}
}
