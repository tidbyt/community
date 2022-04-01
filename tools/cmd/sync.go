package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"tidbyt.dev/community/tools/generator"
)

var syncCmd = &cobra.Command{
	Use:   "sync",
	Short: "Syncs app list.",
	Long:  `This command will re-generate the apps list.`,
	Run: func(cmd *cobra.Command, args []string) {
		// Setup.
		g, err := generator.NewGenerator()
		if err != nil {
			fmt.Printf("app creation failed %v\n", err)
			os.Exit(1)
		}

		// Remove app.
		err = g.UpdateApps()
		if err != nil {
			fmt.Printf("app deletion failed %v\n", err)
			os.Exit(1)
		}
	},
}
