package generator

import (
	_ "embed"
	"io/ioutil"
	"os"
	"path"
	"sort"
	"strings"
	"text/template"

	"tidbyt.dev/community/apps/manifest"
)

const (
	appsDir = "apps"
	goExt   = ".go"
	appSrc  = "source.star"
)

//go:embed templates/source.star.tmpl
var starSource string

//go:embed templates/source.go.tmpl
var goSource string

//go:embed templates/apps.go.tmpl
var appsSource string

// Generator provides a structure for generating apps.
type Generator struct {
	starTmpl *template.Template
	goTmpl   *template.Template
	appsTmpl *template.Template
}

type packageDef struct {
	manifest.Manifest
	Package string
}

type appsDef struct {
	Imports  []string
	Packages []string
}

// GeneratePackageName creates a suitable go package name from an app name.
func GeneratePackageName(name string) string {
	packageName := strings.ReplaceAll(name, "-", "")
	packageName = strings.ReplaceAll(packageName, "_", "")
	return strings.ToLower(strings.Join(strings.Fields(packageName), ""))
}

// NewGenerator creates an instantiated generator with the templates parsed.
func NewGenerator() (*Generator, error) {
	starTmpl, err := template.New("star").Parse(starSource)
	if err != nil {
		return nil, err
	}

	goTmpl, err := template.New("go").Parse(goSource)
	if err != nil {
		return nil, err
	}

	appsTmpl, err := template.New("apps").Parse(appsSource)
	if err != nil {
		return nil, err
	}

	return &Generator{
		starTmpl: starTmpl,
		goTmpl:   goTmpl,
		appsTmpl: appsTmpl,
	}, nil
}

// GenerateApp creates the base app starlark, go package, and updates the app
// list.
func (g *Generator) GenerateApp(app manifest.Manifest) error {
	def := &packageDef{
		Manifest: app,
		Package:  GeneratePackageName(app.Name),
	}

	err := g.createDir(def)
	if err != nil {
		return err
	}

	err = g.generateStarlark(def)
	if err != nil {
		return err
	}

	err = g.generateGo(def)
	if err != nil {
		return err
	}

	return g.updateApps(def)
}

func (g *Generator) createDir(def *packageDef) error {
	p := path.Join(appsDir, def.Package)
	return os.MkdirAll(p, os.ModePerm)
}

func (g *Generator) updateApps(def *packageDef) error {
	imports := []string{
		"tidbyt.dev/community/" + appsDir + "/manifest",
	}
	packages := []string{}

	files, err := ioutil.ReadDir(appsDir)
	if err != nil {
		return err
	}

	for _, f := range files {
		if f.IsDir() && f.Name() != "manifest" {
			imp := "tidbyt.dev/community/" + appsDir + "/" + f.Name()
			imports = append(imports, imp)
			packages = append(packages, f.Name())
		}
	}
	p := path.Join(appsDir, appsDir+goExt)

	file, err := os.Create(p)
	if err != nil {
		return err
	}
	defer file.Close()

	sort.Strings(imports)
	sort.Strings(packages)

	a := &appsDef{
		Imports:  imports,
		Packages: packages,
	}

	return g.appsTmpl.Execute(file, a)
}

func (g *Generator) generateStarlark(def *packageDef) error {
	p := path.Join(appsDir, def.Package, appSrc)

	file, err := os.Create(p)
	if err != nil {
		return err
	}
	defer file.Close()

	return g.starTmpl.Execute(file, def)
}

func (g *Generator) generateGo(def *packageDef) error {
	p := path.Join(appsDir, def.Package, def.Package+goExt)

	file, err := os.Create(p)
	if err != nil {
		return err
	}
	defer file.Close()

	return g.goTmpl.Execute(file, def)
}
