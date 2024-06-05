package k8s

import (
	"fmt"
	"os"
	"path/filepath"

	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

// DynamicClientset fetches the kubeconfig automatically
// based on the environment. It attempts to use the
// in-cluster config first, and falls back to the
// out-of-cluster config.
func DynamicClientset() (*kubernetes.Clientset, error) {
	config, err := rest.InClusterConfig()
	if err != nil {
		config, err = OutOfClusterConfig()
		if err != nil {
			return nil, fmt.Errorf("failed to get dynamic config: %w", err)
		}
	}

	return kubernetes.NewForConfig(config)
}

// OutOfClusterConfig fetches the kubeconfig file from the local filesystem.
func OutOfClusterConfig() (*rest.Config, error) {
	// Find the kubeconfig file
	kubeconfigPath := os.Getenv("KUBECONFIG")
	if kubeconfigPath == "" {
		homedir, err := os.UserHomeDir()
		if err != nil {
			return nil, fmt.Errorf("failed to get user home directory: %w", err)
		}

		kubeconfigPath = filepath.Join(homedir, ".kube", "config")
	}

	// use the current context in kubeconfig
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfigPath)
	if err != nil {
		return nil, fmt.Errorf("failed to build config from flags: %w", err)
	}

	return config, nil
}
