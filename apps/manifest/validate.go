package manifest

import (
	"fmt"
	"strings"
)

func ValidateName(name string) error {
	if name != strings.Title(name) {
		return fmt.Errorf("%s should be title case, 'Fuzzy Clock' for example", name)
	}
	return nil
}

func ValidateSummary(summary string) error {
	return nil
}

func ValidateDesc(desc string) error {
	return nil
}

func ValidateAuthor(author string) error {
	return nil
}
