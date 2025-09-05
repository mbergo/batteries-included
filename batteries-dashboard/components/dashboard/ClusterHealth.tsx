'use client'

import { motion } from 'framer-motion'
import { Activity, CheckCircle, AlertTriangle, XCircle } from 'lucide-react'

// ClusterHealth Component
// Displays real-time health status of the Kubernetes cluster
// Uses framer-motion for smooth animations and status transitions
interface ClusterHealthProps {
  data: {
    status: string
    nodes: number
    pods: number
    services: number
  }
}

export default function ClusterHealth({ data }: ClusterHealthProps) {
  // Determine health status color and icon based on cluster state
  const getStatusConfig = () => {
    switch (data.status) {
      case 'healthy':
        return {
          color: 'text-green-400',
          bgColor: 'bg-green-500/20',
          icon: CheckCircle,
          pulse: true
        }
      case 'warning':
        return {
          color: 'text-yellow-400',
          bgColor: 'bg-yellow-500/20',
          icon: AlertTriangle,
          pulse: true
        }
      case 'critical':
        return {
          color: 'text-red-400',
          bgColor: 'bg-red-500/20',
          icon: XCircle,
          pulse: false
        }
      default:
        return {
          color: 'text-purple-400',
          bgColor: 'bg-purple-500/20',
          icon: Activity,
          pulse: true
        }
    }
  }

  const statusConfig = getStatusConfig()
  const StatusIcon = statusConfig.icon

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5 }}
      className="glass rounded-xl p-6 glow-purple"
    >
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-purple-300">Cluster Health</h3>
        <div className={`p-2 rounded-full ${statusConfig.bgColor} ${statusConfig.pulse ? 'animate-pulse' : ''}`}>
          <StatusIcon className={`w-5 h-5 ${statusConfig.color}`} />
        </div>
      </div>
      
      {/* Animated status indicator */}
      <div className="space-y-4">
        <div className="flex items-center justify-center py-8">
          <motion.div
            animate={{
              scale: statusConfig.pulse ? [1, 1.1, 1] : 1,
            }}
            transition={{
              duration: 2,
              repeat: Infinity,
              ease: "easeInOut"
            }}
            className="relative"
          >
            {/* Outer ring */}
            <div className="absolute inset-0 rounded-full bg-gradient-to-r from-purple-500 to-purple-700 opacity-20 blur-xl"></div>
            
            {/* Inner circle with status */}
            <div className={`relative w-32 h-32 rounded-full ${statusConfig.bgColor} flex items-center justify-center border-2 border-purple-500/30`}>
              <StatusIcon className={`w-12 h-12 ${statusConfig.color}`} />
            </div>
          </motion.div>
        </div>
        
        {/* Cluster metrics */}
        <div className="grid grid-cols-3 gap-2 text-center">
          <motion.div
            whileHover={{ scale: 1.05 }}
            className="p-3 rounded-lg bg-purple-900/20 border border-purple-700/30"
          >
            <div className="text-2xl font-bold text-purple-300">{data.nodes}</div>
            <div className="text-xs text-purple-400/60">Nodes</div>
          </motion.div>
          
          <motion.div
            whileHover={{ scale: 1.05 }}
            className="p-3 rounded-lg bg-purple-900/20 border border-purple-700/30"
          >
            <div className="text-2xl font-bold text-purple-300">{data.pods}</div>
            <div className="text-xs text-purple-400/60">Pods</div>
          </motion.div>
          
          <motion.div
            whileHover={{ scale: 1.05 }}
            className="p-3 rounded-lg bg-purple-900/20 border border-purple-700/30"
          >
            <div className="text-2xl font-bold text-purple-300">{data.services}</div>
            <div className="text-xs text-purple-400/60">Services</div>
          </motion.div>
        </div>
        
        {/* Status text */}
        <div className="text-center pt-2">
          <span className={`text-sm font-medium ${statusConfig.color} uppercase tracking-wider`}>
            {data.status}
          </span>
        </div>
      </div>
    </motion.div>
  )
}