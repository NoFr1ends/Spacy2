package main

import (
	"context"
	"encoding/json"
	"github.com/gorilla/mux"
	"google.golang.org/grpc"
	"log"
	"net/http"
	"open-match.dev/open-match/pkg/pb"
	"os"
	"os/signal"
	"time"
)

type SearchMatch struct {
	GameModes []string
}

type SearchMatchResult struct {
	Id string `json:"id"`
}

func SearchHandler(w http.ResponseWriter, r *http.Request) {
	var search SearchMatch
	if err := json.NewDecoder(r.Body).Decode(&search); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	log.Printf("Searching for match in the following game modes: %v\n", search.GameModes)

	req := &pb.CreateTicketRequest{
		Ticket: &pb.Ticket{
			SearchFields: &pb.SearchFields{
				Tags: search.GameModes,
			},
		},
	}
	resp, err := fe.CreateTicket(context.Background(), req)
	if err != nil {
		log.Printf("Failed to generate ticket: %v\n", err)
		http.Error(w, "Failed to generate ticket", http.StatusInternalServerError)
		return
	}

	res := SearchMatchResult{Id: resp.Id}
	if err := json.NewEncoder(w).Encode(res); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func TicketHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	got, err := fe.GetTicket(context.Background(), &pb.GetTicketRequest{TicketId: vars["ticket"]})
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := json.NewEncoder(w).Encode(got); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

var fe pb.FrontendServiceClient

func main() {
	log.Println("Starting matchmaking frontend")

	// Connect to open match frontend service
	conn, err := grpc.Dial("localhost:50504", grpc.WithInsecure())
	if err != nil {
		log.Fatalf("Failed to connect to open match: %v", err)
	}
	log.Println("Connected to matchmaking server")
	defer conn.Close()

	// Create frontend service
	fe = pb.NewFrontendServiceClient(conn)

	// Create http server which is used in the game client
	r := mux.NewRouter()
	r.HandleFunc("/search", SearchHandler)
	r.HandleFunc("/ticket/{ticket}", TicketHandler)

	srv := &http.Server {
		Handler: r,
		Addr: ":8000",
		WriteTimeout: 15 * time.Second,
		ReadTimeout: 15 * time.Second,
	}
	go func() {
		log.Println("Starting http server")
		if err := srv.ListenAndServe(); err != nil {
			log.Printf("Failed to start http server: %v\n", err)
		}
	}()

	c := make(chan os.Signal, 1)
	// Wait for SIGINT
	signal.Notify(c, os.Interrupt)
	<-c

	// Received SIGINT -> exit the server gracefully
	log.Println("Shutting down")
	ctx, cancel := context.WithTimeout(context.Background(), 15 * time.Second)
	defer cancel()
	// Gracefully exit server, will block if there are still requests which are getting handled
	err = srv.Shutdown(ctx)
	if err != nil {
		log.Printf("Failed to gracefully stop http server: %v\n", err)
	}
	log.Println("Shutdown completed")
	os.Exit(0)
}
