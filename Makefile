PROTOC_VER ?= 3.0.0
GOGO_PROTO_TAG ?= v0.3
GRPC_GATEWAY_TAG ?= v1.1.0
BUILDBOX_TAG := spifee-buildbox:0.0.1
PLATFORM := linux-x86_64
GRPC_DIRS := workload/workloadpb

# all goinstalls everything
.PHONY: all
all: install

# install installs binary
.PHONY: install
install: 
	go install github.com/spiffe/spiffe/tool/spiffe

# run runs local dev server
.PHONY: run
run: install
	spiffe

# buildbox builds docker buildbox image used to compile binaries and generate GRPc stuff
.PHONY: buildbox
buildbox:
	cd build.assets && docker build \
          --build-arg PROTOC_VER=$(PROTOC_VER) \
          --build-arg=GOGO_PROTO_TAG=$(GOGO_PROTO_TAG) \
          --build-arg GRPC_GATEWAY_TAG=$(GRPC_GATEWAY_TAG) \
          --build-arg PLATFORM=$(PLATFORM) \
          -t $(BUILDBOX_TAG) .

# proto generates GRPC defs from service definitions
.PHONY: grpc
grpc: buildbox
	docker run -v $(shell pwd):/go/src/github.com/spiffe/spiffe $(BUILDBOX_TAG) make -C /go/src/github.com/spiffe/spiffe buildbox-grpc

# proto generates GRPC stuff inside buildbox
.PHONY: buildbox-grpc
buildbox-grpc:
# standard GRPC output
	echo $$PROTO_INCLUDE
	cd $(GRPC_DIRS) && protoc -I=.:$$PROTO_INCLUDE \
      --gofast_out=plugins=grpc:.\
    *.proto
# HTTP JSON gateway adapter
	cd $(GRPC_DIRS) && protoc -I=.:$$PROTO_INCLUDE \
      --grpc-gateway_out=logtostderr=true:. \
      --swagger_out=logtostderr=true:. \
      *.proto	
