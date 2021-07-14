FROM golang:alpine as build
WORKDIR /app
COPY . .
RUN go build -o frontend

FROM alpine as app
WORKDIR /app
COPY --from=build /app/frontend .
CMD ["/app/frontend"]