'use client'

import { motion } from 'framer-motion'
import { Cloud, MapPin, Activity } from 'lucide-react'

// Header Component
// Displays cluster information with animated gradient background
interface HeaderProps {
  clusterData: {
    name: string
    region: string
    provider: string
    status: string
  }
}

export default function Header({ clusterData }: HeaderProps) {
  return (
    <motion.header
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      className="glass-darker border-b border-purple-800/30"
    >
      <div className="px-6 py-4">
        <div className="flex items-center justify-between">
          {/* Logo and title with gradient animation */}
          <div className="flex items-center gap-4">
            <motion.div
              animate={{ rotate: 360 }}
              transition={{ duration: 20, repeat: Infinity, ease: "linear" }}
              className="w-10 h-10 rounded-lg bg-gradient-to-br from-purple-500 to-purple-700 flex items-center justify-center"
            >
              <span className="text-white font-bold text-xl">B</span>
            </motion.div>
            
            <div>
              <h1 className="text-xl font-bold gradient-text">Batteries Included</h1>
              <p className="text-xs text-purple-400/60">Kubernetes Dashboard</p>
            </div>
          </div>
          
          {/* Cluster info badges */}
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-purple-900/30 border border-purple-700/30">
              <Cloud className="w-3 h-3 text-purple-400" />
              <span className="text-xs text-purple-300">{clusterData.provider}</span>
            </div>
            
            <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-purple-900/30 border border-purple-700/30">
              <MapPin className="w-3 h-3 text-purple-400" />
              <span className="text-xs text-purple-300">{clusterData.region}</span>
            </div>
            
            <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-purple-900/30 border border-purple-700/30">
              <Activity className="w-3 h-3 text-green-400 animate-pulse" />
              <span className="text-xs text-purple-300">{clusterData.name}</span>
            </div>
          </div>
        </div>
      </div>
      
      {/* Animated gradient border */}
      <div className="h-[2px] bg-gradient-to-r from-transparent via-purple-500 to-transparent animate-gradient"></div>
    </motion.header>
  )
}