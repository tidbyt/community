// Package apps provides a clean way for Tidbyt to be able to get a list of all
// community apps.
package apps

import (
	"errors"
  
	"tidbyt.dev/community/apps/manifest"
)

var (
	Manifests []manifest.Manifest
)

// GetManifests returns a list of all apps in the this repository. Add your applet
// below to include it in the Tidbyt Mobile app for all Tidbyt users.
func GetManifests() []manifest.Manifest {
	return Manifests
}

// FindManifest finds an manifest at the given ID.
func FindManifest(id string) (*manifest.Manifest, error) {
	for _, app := range Manifests {
		if app.ID == id {
			return &app, nil
		}
	}

	return nil, errors.New("app manifest does not exist")
}
