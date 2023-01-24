// Package cmd provides subcommands for the community-tools binary.
package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"tidbyt.dev/community/apps"
)

var (
	listCmd = &cobra.Command{
		Use:   "list",
		Short: "Lists apps in the repo",
		RunE:  listApps,
	}
)

func listApps(cmd *cobra.Command, args []string) error {
	manifests, err := apps.GetManifests()
	if err != nil {
		return fmt.Errorf("couldn't get app manifests: %w", err)
	}

	for _, app := range manifests {
		fmt.Println(app.Name)
	}

	return nil
}
