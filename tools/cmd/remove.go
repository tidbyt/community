package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"tidbyt.dev/community/apps"
	"tidbyt.dev/community/tools/generator"
)

var id string

func init() {
	removeCmd.PersistentFlags().StringVarP(&id, "id", "i", "", "")
	_ = removeCmd.MarkFlagRequired("id")
}

// removeCmd prompts the user for info and generates a new app.
var removeCmd = &cobra.Command{
	Use:   "remove",
	Short: "Removes an app.",
	Long:  `This command will remove an app from this repo.`,
	Run: func(cmd *cobra.Command, args []string) {
		// Setup.
		g, err := generator.NewGenerator()
		if err != nil {
			fmt.Printf("app creation failed %v\n", err)
			os.Exit(1)
		}

		// Find app.
		app, err := apps.FindManifest(id)
		if err != nil {
			fmt.Printf("app creation failed %v\n", err)
			os.Exit(1)
		}

		// Remove app.
		err = g.RemoveApp(app)
		if err != nil {
			fmt.Printf("app deletion failed %v\n", err)
			os.Exit(1)
		}
	},
}
