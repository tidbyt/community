clean:
	rm -f ca-tools

build: clean
	go build -v ./...

test:
	go test -v -cover ./...
