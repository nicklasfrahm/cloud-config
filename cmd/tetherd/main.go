package main

import (
	"context"
	"log"
	"time"

	"github.com/nicklasfrahm/cloud/pkg/k8s"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func main() {
	clientset, err := k8s.DynamicClientset()
	if err != nil {
		log.Fatal(err)
	}

	ticker := time.NewTicker(5 * time.Second)
	for range ticker.C {
		nodes, err := clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
		if err != nil {
			log.Printf("failed to list nodes: %v", err)
			continue
		}

		log.Printf("found %d node(s)", len(nodes.Items))
	}
}
