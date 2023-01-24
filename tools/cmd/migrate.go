// Package cmd provides subcommands for the community-tools binary.
package cmd

import (
	"fmt"
	"os"
	"path"

	"github.com/spf13/cobra"
	"tidbyt.dev/community/apps"
)

var (
	migrateCmd = &cobra.Command{
		Use:   "migrate",
		Short: "Migrates an app from the .go based manifest to the .yaml based manifest",
		RunE:  migrate,
	}
)

func migrate(cmd *cobra.Command, args []string) error {
	manifests, err := apps.GetManifests()
	if err != nil {
		return fmt.Errorf("couldn't get app manifests: %w", err)
	}

	for _, app := range manifests {
		p := path.Join("apps", app.PackageName, "manifest.yaml")

		// Create the file
		f, err := os.Create(p)
		if err != nil {
			return fmt.Errorf("couldn't open manifest: %w", err)
		}
		defer f.Close()

		// Write the manifest.
		err = app.WriteManifest(f)
		if err != nil {
			return fmt.Errorf("couldn't write manifest: %w", err)
		}

		p = path.Join("apps", app.PackageName, app.PackageName+".go")
		err = os.Remove(p)
		if err != nil {
			fmt.Printf("couldn't remove old manifest: %v\n", err)
			continue
		}
	}

	return nil
}
