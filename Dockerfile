# build stage
FROM golang AS build-env
ADD . /src
RUN cd /src && GO111MODULE=on go build -o c cmd/cmd.go

# serve stage
FROM ubuntu:jammy
WORKDIR /app
COPY --from=build-env /src/c /app/cmd
COPY ./example/ /app/example/
ENV TZ=Asia/Tokyo
RUN apt update -y && apt install -y tzdata wget jq \
  && apt upgrade -y \
  && wget -P /tmp https://github.com/sclevine/yj/releases/download/v5.1.0/yj-linux-amd64 \
  && mv /tmp/yj-linux-amd64 /usr/local/bin/yj \
  && chmod +x /usr/local/bin/yj \
  && GH_CLI_VERSION=$(curl -sL -H "Accept: application/vnd.github+json"   https://api.github.com/repos/cli/cli/releases/latest | jq -r '.tag_name' | sed 's/^v//g') \
  && GH_CLI_DOWNLOAD_URL=$(curl -sL -H "Accept: application/vnd.github+json"   https://api.github.com/repos/cli/cli/releases/latest | jq ".assets[] | select(.name == \"gh_${GH_CLI_VERSION}_linux_${DPKG_ARCH}.deb\")" | jq -r '.browser_download_url') \
  && curl -sSLo /tmp/ghcli.deb ${GH_CLI_DOWNLOAD_URL} && apt-get -y install /tmp/ghcli.deb && rm /tmp/ghcli.deb \
CMD ["./cmd", "--config", "./example/config.yaml"]
