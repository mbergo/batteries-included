'use client'

import { useState, useEffect } from 'react'
import ClusterHealth from '@/components/dashboard/ClusterHealth'
import ResourceCharts from '@/components/dashboard/ResourceCharts'
import PodGrid from '@/components/dashboard/PodGrid'
import ServiceMap from '@/components/dashboard/ServiceMap'
import TokenManager from '@/components/dashboard/TokenManager'
import Terminal from '@/components/layout/Terminal'
import Header from '@/components/layout/Header'
import Sidebar from '@/components/layout/Sidebar'

// Main Dashboard Component - This is the entry point of our application
// It manages the overall layout and state for the dashboard
export default function Dashboard() {
  // State to track which section is currently active
  const [activeSection, setActiveSection] = useState('overview')
  
  // State to manage terminal visibility
  const [terminalOpen, setTerminalOpen] = useState(false)
  
  // Mock data for demonstration - In production, this would come from K8s API
  const [clusterData] = useState({
    name: 'batteries-included-aks',
    region: 'East US',
    provider: 'Azure',
    status: 'healthy',
    nodes: 2,
    pods: 12,
    services: 8,
  })

  // Bearer token from our Azure deployment
  const bearerToken = 'eyJhbGciOiJSUzI1NiIsImtpZCI6Ijhic3ZvWGtHT2NMRmZPbFgyeExtY085RWNtMmRFblpGUHh6QUFVYXhqc3cifQ...'

  return (
    <div className="min-h-screen gradient-bg mesh-overlay">
      {/* Header with cluster info and animated gradient */}
      <Header clusterData={clusterData} />
      
      <div className="flex">
        {/* Sidebar navigation with glassmorphism effect */}
        <Sidebar activeSection={activeSection} onSectionChange={setActiveSection} />
        
        {/* Main content area with responsive grid */}
        <main className="flex-1 p-6 space-y-6">
          {/* Hero section with animated title */}
          <div className="mb-8">
            <h1 className="text-5xl font-bold gradient-text animate-pulse-glow">
              Batteries Dashboard
            </h1>
            <p className="text-purple-300/60 mt-2">
              Real-time Kubernetes cluster monitoring and management
            </p>
          </div>
          
          {/* Dashboard grid layout - responsive and animated */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {/* Cluster Health Card - Shows real-time health status */}
            <div className="lg:col-span-1">
              <ClusterHealth data={clusterData} />
            </div>
            
            {/* Resource Usage Charts - CPU and Memory visualization */}
            <div className="lg:col-span-2">
              <ResourceCharts />
            </div>
            
            {/* Pod Status Grid - Live pod monitoring */}
            <div className="lg:col-span-2">
              <PodGrid />
            </div>
            
            {/* Service Map - Visual service topology */}
            <div className="lg:col-span-1">
              <ServiceMap />
            </div>
            
            {/* Token Manager - Secure token display and management */}
            <div className="lg:col-span-3">
              <TokenManager token={bearerToken} />
            </div>
          </div>
          
          {/* Floating Terminal Button */}
          <button
            onClick={() => setTerminalOpen(!terminalOpen)}
            className="fixed bottom-6 right-6 p-4 rounded-full bg-purple-600 hover:bg-purple-700 transition-all duration-300 glow-purple-intense hover:scale-110"
          >
            <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 9l3 3-3 3m5 0h3M5 20h14a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
            </svg>
          </button>
          
          {/* Terminal Component - Slides up from bottom */}
          {terminalOpen && (
            <Terminal onClose={() => setTerminalOpen(false)} />
          )}
        </main>
      </div>
    </div>
  )
}