FROM golang:alpine as build
WORKDIR /app
COPY . .
RUN go build -o matchmaker

FROM alpine as app
WORKDIR /app
COPY --from=build /app/matchmaker .
CMD ["/app/matchmaker"]