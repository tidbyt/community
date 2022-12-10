clean:
	rm -f community-tools

build: clean
	go build -v ./...
	go build -o community-tools tidbyt.dev/community/tools

install-buildifier:
	go install github.com/bazelbuild/buildtools/buildifier@latest

lint:
	@ buildifier --version >/dev/null 2>&1 || $(MAKE) install-buildifier
	buildifier -r ./

format: lint

test:
	go test -v -cover ./...

sync:
	go run tools/main.go sync

app:
	@ go run tools/main.go create
