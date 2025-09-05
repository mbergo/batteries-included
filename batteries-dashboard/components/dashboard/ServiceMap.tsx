'use client'

import { motion } from 'framer-motion'
import { Network, Globe, Shield, Database } from 'lucide-react'

// ServiceMap Component
// Visual representation of services and their connections
// Interactive service topology with hover effects
export default function ServiceMap() {
  const services = [
    { name: 'Dashboard', type: 'LoadBalancer', port: '80', icon: Globe, color: 'purple' },
    { name: 'Postgres', type: 'ClusterIP', port: '5432', icon: Database, color: 'blue' },
    { name: 'Grafana', type: 'LoadBalancer', port: '3000', icon: Network, color: 'green' },
    { name: 'Auth', type: 'ClusterIP', port: '443', icon: Shield, color: 'yellow' },
  ]

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay: 0.3 }}
      className="glass rounded-xl p-6 glow-purple h-full"
    >
      <h3 className="text-lg font-semibold text-purple-300 mb-4">Service Map</h3>
      
      {/* Service visualization */}
      <div className="relative h-64 flex items-center justify-center">
        {/* Center hub */}
        <motion.div
          animate={{ rotate: 360 }}
          transition={{ duration: 30, repeat: Infinity, ease: "linear" }}
          className="absolute w-24 h-24 rounded-full border-2 border-dashed border-purple-600/30"
        />
        
        <div className="absolute w-16 h-16 rounded-full bg-gradient-to-br from-purple-600 to-purple-800 flex items-center justify-center glow-purple">
          <Network className="w-8 h-8 text-white" />
        </div>
        
        {/* Service nodes */}
        {services.map((service, index) => {
          const Icon = service.icon
          const angle = (index * 360) / services.length
          const x = Math.cos((angle * Math.PI) / 180) * 80
          const y = Math.sin((angle * Math.PI) / 180) * 80
          
          return (
            <motion.div
              key={service.name}
              initial={{ opacity: 0, scale: 0 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: index * 0.1 }}
              whileHover={{ scale: 1.2 }}
              className="absolute"
              style={{ transform: `translate(${x}px, ${y}px)` }}
            >
              {/* Connection line */}
              <svg
                className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none"
                style={{ width: 200, height: 200, zIndex: -1 }}
              >
                <line
                  x1="100"
                  y1="100"
                  x2={100 - x}
                  y2={100 - y}
                  stroke="url(#gradient)"
                  strokeWidth="1"
                  strokeDasharray="5,5"
                  opacity="0.3"
                />
                <defs>
                  <linearGradient id="gradient">
                    <stop offset="0%" stopColor="#a855f7" />
                    <stop offset="100%" stopColor="#6b21a8" />
                  </linearGradient>
                </defs>
              </svg>
              
              {/* Service node */}
              <div className="relative group">
                <div className="w-12 h-12 rounded-full bg-purple-900/50 border border-purple-600/30 flex items-center justify-center group-hover:border-purple-400/50 transition-all">
                  <Icon className="w-6 h-6 text-purple-400" />
                </div>
                
                {/* Tooltip */}
                <div className="absolute -bottom-8 left-1/2 -translate-x-1/2 opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
                  <div className="glass-darker px-2 py-1 rounded text-xs whitespace-nowrap">
                    {service.name}
                  </div>
                </div>
              </div>
            </motion.div>
          )
        })}
      </div>
      
      {/* Service list */}
      <div className="space-y-2 mt-6">
        {services.map((service, index) => (
          <motion.div
            key={service.name}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: index * 0.05 }}
            className="flex items-center justify-between p-2 rounded-lg bg-purple-950/20 border border-purple-800/30"
          >
            <div className="flex items-center gap-2">
              <service.icon className="w-4 h-4 text-purple-400" />
              <span className="text-sm text-purple-300">{service.name}</span>
            </div>
            <div className="flex items-center gap-3 text-xs">
              <span className="text-purple-500/60">{service.type}</span>
              <span className="text-purple-400 font-mono">:{service.port}</span>
            </div>
          </motion.div>
        ))}
      </div>
    </motion.div>
  )
}