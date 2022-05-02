// Package cmd provides subcommands for the community-tools binary.
package cmd

import (
	"github.com/spf13/cobra"
)

var (
	rootCmd = &cobra.Command{
		Use:   "community-tools",
		Short: "Supporting tools for the Tidbyt community rep.",
		Long: `This tool is used for supporting operations and functions for
maintaining the Tidbyt community repo.`,
	}
)

// Execute executes the root command.
func Execute() error {
	return rootCmd.Execute()
}

func init() {
	rootCmd.AddCommand(createCmd)
	rootCmd.AddCommand(removeCmd)
	rootCmd.AddCommand(syncCmd)
}
