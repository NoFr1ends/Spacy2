package main

import (
	"fmt"
	"google.golang.org/grpc"
	"log"
	"net"
	"open-match.dev/open-match/pkg/pb"
)

type MatchFunctionService struct {
	grpc 				*grpc.Server
	queryServiceClient 	pb.QueryServiceClient
	port 				int
}

func main() {
	log.Println("Starting matchmaking function")

	// Connect to open match query service
	conn, err := grpc.Dial("localhost:50503", grpc.WithInsecure())
	if err != nil {
		log.Fatalf("Failed to connect to open match: %v", err)
	}
	log.Println("Connected to matchmaking server")
	defer conn.Close()

	mmfService := MatchFunctionService{
		queryServiceClient:	pb.NewQueryServiceClient(conn),
	}

	// Create grpc server which get called by open match
	server := grpc.NewServer()
	pb.RegisterMatchFunctionServer(server, &mmfService)
	ln, err := net.Listen("tcp", fmt.Sprintf(":%d", 8001))
	if err != nil {
		log.Fatalf("TCP net listener initialization failed: %v", err)
	}

	log.Println("Match function is listening")
	err = server.Serve(ln)
	if err != nil {
		log.Fatalf("Failed to initialize gRPC service: %v", err)
	}
}
