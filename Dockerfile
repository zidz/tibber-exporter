FROM golang:1.21.4-alpine3.18 as builder

ARG UA="tibber-exporter (https://github.com/terjesannum/tibber-exporter)"

RUN apk --update add ca-certificates
RUN echo 'tibber:*:65532:' > /tmp/group && \
    echo 'tibber:*:65532:65532:tibber:/:/tibber-exporter' > /tmp/passwd

WORKDIR /workspace
COPY go.* ./
RUN go mod download

COPY . /workspace

RUN CGO_ENABLED=0 go build -a -o tibber-exporter -ldflags "-X 'main.userAgent=$UA'" .

FROM scratch

LABEL org.opencontainers.image.title="tibber-exporter" \
      org.opencontainers.image.description="Prometheus exporter for Tibber power usage and costs" \
      org.opencontainers.image.authors="Terje Sannum <terje@offpiste.org>" \
      org.opencontainers.image.url="https://github.com/terjesannum/tibber-exporter" \
      org.opencontainers.image.source="https://github.com/terjesannum/tibber-exporter"

WORKDIR /
EXPOSE 8080

COPY --from=builder /tmp/passwd /tmp/group /etc/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /workspace/tibber-exporter .

USER 65532:65532

ENTRYPOINT ["/tibber-exporter"]
