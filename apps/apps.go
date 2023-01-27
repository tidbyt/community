// Package apps provides a clean way for Tidbyt to be able to get a list of all
// community apps.
package apps

import (
	"embed"
	"fmt"
	"path/filepath"

	"tidbyt.dev/pixlet/manifest"
)

//go:embed **/*.yaml **/*.star
var embededApps embed.FS

// GetManifests returns a list of all apps in the this repository. You no longer
// have to register your app here! So long as it's created as a directory, it
// will work as expected.
func GetManifests() ([]*manifest.Manifest, error) {
	manifests := []*manifest.Manifest{}

	contents, err := embededApps.ReadDir(".")
	if err != nil {
		return nil, fmt.Errorf("couldn't read internal fs: %w", err)
	}
	for _, item := range contents {
		// We only care about directories.
		if !item.IsDir() {
			continue
		}

		manifestFile := filepath.Join(item.Name(), "manifest.yaml")
		f, err := embededApps.Open(manifestFile)
		if err != nil {
			return nil, fmt.Errorf("couldn't open manifest file: %w", err)
		}

		m, err := manifest.LoadManifest(f)
		if err != nil {
			return nil, fmt.Errorf("couldn't load manifest file: %w", err)
		}

		sourceFile := filepath.Join(item.Name(), m.FileName)
		b, err := embededApps.ReadFile(sourceFile)
		if err != nil {
			return nil, fmt.Errorf("couldn't load source file: %w", err)
		}
		m.Source = b

		manifests = append(manifests, m)
	}

	return manifests, nil
}

// FindManifest finds an manifest at the given ID.
func FindManifest(id string) (*manifest.Manifest, error) {
	manifests, err := GetManifests()
	if err != nil {
		return nil, fmt.Errorf("getting manifests: %w", err)
	}
	for _, app := range manifests {
		if app.ID == id {
			return app, nil
		}
	}

	return nil, fmt.Errorf("app manifest does not exist")
}
