FROM golang:alpine as build
WORKDIR /app
COPY . .
RUN go build -o director

FROM alpine as app
WORKDIR /app
COPY --from=build /app/director .
CMD ["/app/director"]