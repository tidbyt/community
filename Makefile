clean:
	rm -f ca-tools

build: clean
	go build -v ./...

lint:
	golangci-lint run

test:
	go test -v -cover ./...
