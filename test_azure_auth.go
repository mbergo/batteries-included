package main

import (
	"context"
	"fmt"
	"log"

	"github.com/Azure/azure-sdk-for-go/sdk/azcore/policy"
	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
)

func main() {
	ctx := context.Background()

	// Create a default Azure credential chain
	cred, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		log.Fatalf("Failed to create Azure credential: %v", err)
	}

	// Get token for Azure Resource Manager
	token, err := cred.GetToken(ctx, policy.TokenRequestOptions{
		Scopes: []string{"https://management.azure.com/.default"},
	})
	if err != nil {
		log.Fatalf("Failed to get Azure token: %v", err)
	}

	fmt.Printf("✅ Azure authentication successful!\n")
	fmt.Printf("Token expires at: %v\n", token.ExpiresOn)
	fmt.Printf("Token length: %d characters\n", len(token.Token))
	fmt.Printf("Token preview: %s...\n", token.Token[:min(50, len(token.Token))])
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
