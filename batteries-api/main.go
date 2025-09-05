package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"time"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/rs/cors"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	// Metrics API removed for now - would need separate installation
)

type Server struct {
	k8sClient *kubernetes.Clientset
	upgrader  websocket.Upgrader
}

type DashboardData struct {
	Installations   InstallationsData   `json:"installations"`
	Services        ServicesData        `json:"services"`
	Databases       DatabasesData       `json:"databases"`
	Cluster         ClusterData         `json:"cluster"`
	Security        SecurityData        `json:"security"`
	Projects        []ProjectData       `json:"projects"`
	Namespaces      []NamespaceData     `json:"namespaces"`
	Alerts          []AlertData         `json:"alerts"`
	RecentActivity  []ActivityData      `json:"recentActivity"`
}

type InstallationsData struct {
	Total    int `json:"total"`
	Healthy  int `json:"healthy"`
	Degraded int `json:"degraded"`
	Offline  int `json:"offline"`
}

type ServicesData struct {
	Total       int     `json:"total"`
	Uptime      float64 `json:"uptime"`
	ErrorRate   float64 `json:"errorRate"`
	P95Latency  int     `json:"p95Latency"`
	Deployments int     `json:"deployments"`
}

type DatabasesData struct {
	Total           int    `json:"total"`
	AllSynced       bool   `json:"allSynced"`
	BackupStatus    string `json:"backupStatus"`
	ReplicationLag  int    `json:"replicationLag"`
	NextBackupHours int    `json:"nextBackupHours"`
}

type ClusterData struct {
	CPUUsage    float64 `json:"cpuUsage"`
	MemoryUsage float64 `json:"memoryUsage"`
	Nodes       int     `json:"nodes"`
	NodesReady  int     `json:"nodesReady"`
}

type SecurityData struct {
	Status          string `json:"status"`
	CertificatesOK  bool   `json:"certificatesOk"`
	SSOActive       bool   `json:"ssoActive"`
	CertExpireDays  int    `json:"certExpireDays"`
}

type ProjectData struct {
	Name       string `json:"name"`
	Version    string `json:"version"`
	Status     string `json:"status"`
	Health     string `json:"health"`
	Deployment string `json:"deployment"`
}

type NamespaceData struct {
	Name         string  `json:"name"`
	CPUUsage     float64 `json:"cpuUsage"`
	MemoryUsage  float64 `json:"memoryUsage"`
	PodCount     int     `json:"podCount"`
	ServiceCount int     `json:"serviceCount"`
}

type AlertData struct {
	Type      string    `json:"type"`
	Severity  string    `json:"severity"`
	Message   string    `json:"message"`
	Source    string    `json:"source"`
	Timestamp time.Time `json:"timestamp"`
}

type ActivityData struct {
	Type      string    `json:"type"`
	Message   string    `json:"message"`
	Timestamp time.Time `json:"timestamp"`
}

type ServiceMetrics struct {
	Name           string  `json:"name"`
	ErrorRate      float64 `json:"errorRate"`
	P95Latency     int     `json:"p95Latency"`
	RequestsPerSec int     `json:"requestsPerSec"`
	Status         string  `json:"status"`
}

type DatabaseMetrics struct {
	Name           string  `json:"name"`
	Type           string  `json:"type"`
	Status         string  `json:"status"`
	CPUUsage       float64 `json:"cpuUsage"`
	MemoryUsage    float64 `json:"memoryUsage"`
	Connections    int     `json:"connections"`
	MaxConnections int     `json:"maxConnections"`
	CacheHitRate   float64 `json:"cacheHitRate"`
	ReplicationLag int     `json:"replicationLag"`
	LastBackup     string  `json:"lastBackup"`
}

func NewServer() (*Server, error) {
	config, err := getKubernetesConfig()
	if err != nil {
		return nil, fmt.Errorf("failed to get kubernetes config: %w", err)
	}

	k8sClient, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, fmt.Errorf("failed to create kubernetes client: %w", err)
	}

	return &Server{
		k8sClient: k8sClient,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool {
				return true // Allow all origins in dev
			},
		},
	}, nil
}

func getKubernetesConfig() (*rest.Config, error) {
	// Try in-cluster config first
	config, err := rest.InClusterConfig()
	if err == nil {
		return config, nil
	}

	// Fall back to kubeconfig
	kubeconfig := os.Getenv("KUBECONFIG")
	if kubeconfig == "" {
		kubeconfig = os.Getenv("HOME") + "/.kube/config"
	}

	config, err = clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		return nil, err
	}

	return config, nil
}

func (s *Server) getDashboardData(ctx context.Context) (*DashboardData, error) {
	data := &DashboardData{}

	// Get cluster data
	nodes, err := s.k8sClient.CoreV1().Nodes().List(ctx, metav1.ListOptions{})
	if err == nil {
		data.Cluster.Nodes = len(nodes.Items)
		data.Cluster.NodesReady = 0
		for _, node := range nodes.Items {
			for _, condition := range node.Status.Conditions {
				if condition.Type == v1.NodeReady && condition.Status == v1.ConditionTrue {
					data.Cluster.NodesReady++
					break
				}
			}
		}
	}

	// Get namespace data
	namespaces, err := s.k8sClient.CoreV1().Namespaces().List(ctx, metav1.ListOptions{})
	if err == nil {
		for _, ns := range namespaces.Items {
			pods, _ := s.k8sClient.CoreV1().Pods(ns.Name).List(ctx, metav1.ListOptions{})
			services, _ := s.k8sClient.CoreV1().Services(ns.Name).List(ctx, metav1.ListOptions{})
			
			nsData := NamespaceData{
				Name:         ns.Name,
				PodCount:     len(pods.Items),
				ServiceCount: len(services.Items),
				CPUUsage:     rand.Float64() * 100,    // Simulated
				MemoryUsage:  rand.Float64() * 100,    // Simulated
			}
			data.Namespaces = append(data.Namespaces, nsData)
		}
	}

	// Simulated metrics (replace with real Prometheus queries in production)
	data.Installations = InstallationsData{
		Total:    3,
		Healthy:  2,
		Degraded: 1,
		Offline:  0,
	}

	data.Services = ServicesData{
		Total:       47,
		Uptime:      99.2,
		ErrorRate:   0.02,
		P95Latency:  145,
		Deployments: 3,
	}

	data.Databases = DatabasesData{
		Total:           8,
		AllSynced:       true,
		BackupStatus:    "Completed",
		ReplicationLag:  0,
		NextBackupHours: 2,
	}

	data.Cluster.CPUUsage = 42.0 + rand.Float64()*10
	data.Cluster.MemoryUsage = 58.0 + rand.Float64()*10

	data.Security = SecurityData{
		Status:         "OK",
		CertificatesOK: true,
		SSOActive:      true,
		CertExpireDays: 82,
	}

	// Sample projects
	data.Projects = []ProjectData{
		{Name: "batteries-core", Version: "v2.1.0", Status: "Running", Health: "Healthy", Deployment: "Stable"},
		{Name: "ml-workspace", Version: "v1.0.0", Status: "Deploying", Health: "Degraded", Deployment: "In Progress"},
		{Name: "api-gateway", Version: "v1.8.3", Status: "Running", Health: "Healthy", Deployment: "Stable"},
	}

	// Sample alerts
	data.Alerts = []AlertData{
		{
			Type:      "warning",
			Severity:  "medium",
			Message:   "High Memory Usage",
			Source:    "mongo-analytics",
			Timestamp: time.Now().Add(-15 * time.Minute),
		},
		{
			Type:      "info",
			Severity:  "low",
			Message:   "Scheduled Maintenance",
			Source:    "system",
			Timestamp: time.Now().Add(-2 * time.Hour),
		},
	}

	// Recent activity
	data.RecentActivity = []ActivityData{
		{Type: "deployment", Message: "Deployment completed", Timestamp: time.Now().Add(-5 * time.Minute)},
		{Type: "scaling", Message: "Auto-scaling triggered", Timestamp: time.Now().Add(-12 * time.Minute)},
		{Type: "backup", Message: "Backup completed", Timestamp: time.Now().Add(-2 * time.Hour)},
	}

	return data, nil
}

func (s *Server) handleDashboard(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	data, err := s.getDashboardData(ctx)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

func (s *Server) handleServices(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	
	services := []ServiceMetrics{
		{Name: "auth-service", ErrorRate: 0.8, P95Latency: 234, RequestsPerSec: 1200, Status: "healthy"},
		{Name: "data-processor", ErrorRate: 0.02, P95Latency: 845, RequestsPerSec: 450, Status: "healthy"},
		{Name: "webhook-handler", ErrorRate: 0.5, P95Latency: 123, RequestsPerSec: 890, Status: "degraded"},
		{Name: "api-gateway", ErrorRate: 0.01, P95Latency: 89, RequestsPerSec: 3400, Status: "healthy"},
		{Name: "ml-inference", ErrorRate: 0.03, P95Latency: 567, RequestsPerSec: 230, Status: "healthy"},
	}

	// Get real services from Kubernetes
	svcList, err := s.k8sClient.CoreV1().Services("").List(ctx, metav1.ListOptions{})
	if err == nil && len(svcList.Items) > 0 {
		for _, svc := range svcList.Items[:min(5, len(svcList.Items))] {
			services = append(services, ServiceMetrics{
				Name:           fmt.Sprintf("%s/%s", svc.Namespace, svc.Name),
				ErrorRate:      rand.Float64() * 0.5,
				P95Latency:     rand.Intn(500) + 50,
				RequestsPerSec: rand.Intn(1000) + 100,
				Status:         "healthy",
			})
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(services)
}

func (s *Server) handleDatabases(w http.ResponseWriter, r *http.Request) {
	databases := []DatabaseMetrics{
		{
			Name:           "postgres-main",
			Type:           "PostgreSQL",
			Status:         "Ready",
			CPUUsage:       12.0 + rand.Float64()*5,
			MemoryUsage:    45.0 + rand.Float64()*10,
			Connections:    24 + rand.Intn(20),
			MaxConnections: 100,
			CacheHitRate:   98.2,
			ReplicationLag: 0,
			LastBackup:     "2h ago",
		},
		{
			Name:           "redis-cache",
			Type:           "Redis",
			Status:         "Ready",
			CPUUsage:       8.0 + rand.Float64()*3,
			MemoryUsage:    22.0 + rand.Float64()*10,
			Connections:    145 + rand.Intn(50),
			MaxConnections: 500,
			CacheHitRate:   99.1,
			ReplicationLag: 0,
			LastBackup:     "N/A",
		},
		{
			Name:           "mongo-analytics",
			Type:           "MongoDB",
			Status:         "Degraded",
			CPUUsage:       78.0 + rand.Float64()*10,
			MemoryUsage:    82.0 + rand.Float64()*10,
			Connections:    89,
			MaxConnections: 100,
			CacheHitRate:   87.3,
			ReplicationLag: 4200,
			LastBackup:     "4h ago",
		},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(databases)
}

func (s *Server) handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := s.upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}
	defer conn.Close()

	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			ctx := context.Background()
			data, err := s.getDashboardData(ctx)
			if err != nil {
				log.Printf("Error getting dashboard data: %v", err)
				continue
			}

			if err := conn.WriteJSON(data); err != nil {
				log.Printf("WebSocket write error: %v", err)
				return
			}
		}
	}
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func main() {
	server, err := NewServer()
	if err != nil {
		log.Fatalf("Failed to create server: %v", err)
	}

	router := mux.NewRouter()
	
	// API endpoints
	router.HandleFunc("/api/health", server.handleHealth).Methods("GET")
	router.HandleFunc("/api/dashboard", server.handleDashboard).Methods("GET")
	router.HandleFunc("/api/services", server.handleServices).Methods("GET")
	router.HandleFunc("/api/databases", server.handleDatabases).Methods("GET")
	router.HandleFunc("/ws", server.handleWebSocket)

	// CORS middleware
	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
	})

	handler := c.Handler(router)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting Batteries API server on port %s", port)
	if err := http.ListenAndServe(":"+port, handler); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}