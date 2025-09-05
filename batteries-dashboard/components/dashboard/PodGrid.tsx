'use client'

import { motion } from 'framer-motion'
import { Box, Activity, AlertCircle } from 'lucide-react'

// PodGrid Component  
// Displays a grid view of all pods with their status
// Real-time updates with color-coded health indicators
export default function PodGrid() {
  // Mock pod data - In production, this would come from K8s API
  const pods = [
    { name: 'control-server-1', namespace: 'battery-core', status: 'Running', cpu: '120m', memory: '256Mi', restarts: 0 },
    { name: 'postgres-primary', namespace: 'battery-data', status: 'Running', cpu: '500m', memory: '1Gi', restarts: 0 },
    { name: 'grafana-dashboard', namespace: 'battery-core', status: 'Running', cpu: '50m', memory: '128Mi', restarts: 1 },
    { name: 'istio-proxy', namespace: 'istio-system', status: 'Running', cpu: '100m', memory: '128Mi', restarts: 0 },
    { name: 'redis-master', namespace: 'battery-data', status: 'Running', cpu: '200m', memory: '512Mi', restarts: 0 },
    { name: 'nginx-ingress', namespace: 'ingress', status: 'Running', cpu: '100m', memory: '256Mi', restarts: 2 },
  ]

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Running': return 'bg-green-500/20 border-green-500/30 text-green-400'
      case 'Pending': return 'bg-yellow-500/20 border-yellow-500/30 text-yellow-400'
      case 'Failed': return 'bg-red-500/20 border-red-500/30 text-red-400'
      default: return 'bg-purple-500/20 border-purple-500/30 text-purple-400'
    }
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay: 0.2 }}
      className="glass rounded-xl p-6 glow-purple"
    >
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-purple-300">Pod Status</h3>
        <div className="flex items-center gap-2">
          <span className="text-xs text-purple-400/60">Total: {pods.length}</span>
          <span className="text-xs text-green-400">Running: {pods.filter(p => p.status === 'Running').length}</span>
        </div>
      </div>

      {/* Pod grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
        {pods.map((pod, index) => (
          <motion.div
            key={pod.name}
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: index * 0.05 }}
            whileHover={{ scale: 1.02 }}
            className="p-3 rounded-lg bg-purple-950/30 border border-purple-700/30 hover:border-purple-600/50 transition-all"
          >
            <div className="flex items-start justify-between mb-2">
              <div className="flex items-center gap-2">
                <Box className="w-4 h-4 text-purple-400" />
                <div>
                  <div className="text-sm font-medium text-purple-200">{pod.name}</div>
                  <div className="text-xs text-purple-500/60">{pod.namespace}</div>
                </div>
              </div>
              
              {/* Status badge */}
              <span className={`px-2 py-1 rounded-full text-xs border ${getStatusColor(pod.status)}`}>
                {pod.status}
              </span>
            </div>

            {/* Pod metrics */}
            <div className="grid grid-cols-3 gap-2 text-xs">
              <div>
                <div className="text-purple-500/60">CPU</div>
                <div className="text-purple-300 font-mono">{pod.cpu}</div>
              </div>
              <div>
                <div className="text-purple-500/60">Memory</div>
                <div className="text-purple-300 font-mono">{pod.memory}</div>
              </div>
              <div>
                <div className="text-purple-500/60">Restarts</div>
                <div className={`font-mono ${pod.restarts > 0 ? 'text-yellow-400' : 'text-purple-300'}`}>
                  {pod.restarts}
                </div>
              </div>
            </div>

            {/* Resource usage bars */}
            <div className="mt-2 space-y-1">
              <div className="h-1 bg-purple-950/50 rounded-full overflow-hidden">
                <div 
                  className="h-full bg-gradient-to-r from-purple-600 to-purple-400"
                  style={{ width: `${Math.random() * 60 + 20}%` }}
                />
              </div>
            </div>
          </motion.div>
        ))}
      </div>

      {/* Quick stats */}
      <div className="mt-4 pt-4 border-t border-purple-800/30">
        <div className="grid grid-cols-4 gap-2 text-center">
          <div>
            <div className="text-xl font-bold gradient-text">{pods.length}</div>
            <div className="text-xs text-purple-500/60">Total</div>
          </div>
          <div>
            <div className="text-xl font-bold text-green-400">{pods.filter(p => p.status === 'Running').length}</div>
            <div className="text-xs text-purple-500/60">Running</div>
          </div>
          <div>
            <div className="text-xl font-bold text-yellow-400">0</div>
            <div className="text-xs text-purple-500/60">Pending</div>
          </div>
          <div>
            <div className="text-xl font-bold text-red-400">0</div>
            <div className="text-xs text-purple-500/60">Failed</div>
          </div>
        </div>
      </div>
    </motion.div>
  )
}