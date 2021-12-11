package main

import (
	"context"
	"fmt"
	"google.golang.org/grpc"
	"io"
	"log"
	"open-match.dev/open-match/pkg/pb"
	"os"
	"strconv"
	"sync"
	"time"
)

func generateProfiles() []*pb.MatchProfile {
	var profiles []*pb.MatchProfile
	modes := []string{"ffa", "ctf", "td"}

	for _, mode := range modes {
		profiles = append(profiles, &pb.MatchProfile{
			Name: "mode_based_profile_" + mode,
			Pools: []*pb.Pool{
				{
					Name: "pool_mode_" + mode,
					TagPresentFilters: []*pb.TagPresentFilter{
						{
							Tag: mode,
						},
					},
				},
			},
		})
	}

	return profiles
}

func main() {
	log.Println("Starting director")

	// Connect to open match backend service
	conn, err := grpc.Dial("localhost:50505", grpc.WithInsecure())
	if err != nil {
		log.Fatalf("Failed to connect to backend: %v", err)
	}
	log.Println("Connected to backend server")
	defer conn.Close()

	be := pb.NewBackendServiceClient(conn)
	profiles := generateProfiles()

	for range time.Tick(time.Second * 5) {
		var wg sync.WaitGroup
		for _, profile := range profiles {
			wg.Add(1)
			go func(wg *sync.WaitGroup, profile *pb.MatchProfile) {
				defer wg.Done()
				matches, err := fetch(be, profile)
				if err != nil {
					log.Printf("Failed to fetch matches for profile %v, error: %v\n", profile, err)
					return
				}

				log.Printf("Generated %v matches for profile %v\n", len(matches), profile.GetName())
				if err := assign(be, matches); err != nil {
					log.Printf("Failed to assign servers to matches: %v\n", err)
					return
				}
			}(&wg, profile)
		}

		wg.Wait()
	}
}

func fetch(be pb.BackendServiceClient, profile *pb.MatchProfile) ([]*pb.Match, error) {
	port, err := strconv.ParseInt(os.Getenv("MMF_PORT"), 10, 32)

	req := &pb.FetchMatchesRequest{
		Config: &pb.FunctionConfig{
			Host: os.Getenv("MMF_HOST"),
			Port: int32(port),
			Type: pb.FunctionConfig_GRPC,
		},
		Profile: profile,
	}
	stream, err := be.FetchMatches(context.Background(), req)
	if err != nil {
		log.Printf("Failed to fetch matches: %v\n", err)
		return nil, err
	}

	var result []*pb.Match
	for {
		resp, err := stream.Recv()
		if err == io.EOF {
			break
		}

		if err != nil {
			return nil, err
		}

		result = append(result, resp.GetMatch())
	}

	return result, nil
}

func assign(be pb.BackendServiceClient, matches []*pb.Match) error {
	for _, match := range matches {
		var ticketIDs []string
		for _, t := range match.GetTickets() {
			ticketIDs = append(ticketIDs, t.Id)
		}

		// todo request game server from agones
		conn := "127.0.0.1:8002"
		req := &pb.AssignTicketsRequest{
			Assignments: []*pb.AssignmentGroup{
				{
					TicketIds: ticketIDs,
					Assignment: &pb.Assignment{
						Connection: conn,
					},
				},
			},
		}

		if _, err := be.AssignTickets(context.Background(), req); err != nil {
			return fmt.Errorf("AssignTickets failed for match %v: %v", match.GetMatchId(), err)
		}

		log.Printf("Assigned server %v to match %v", conn, match.GetMatchId())
	}

	return nil
}
