'use client'

import { motion } from 'framer-motion'
import { 
  LayoutDashboard, 
  Box, 
  Network, 
  Database, 
  Shield, 
  Terminal as TerminalIcon,
  Settings,
  Activity
} from 'lucide-react'

// Sidebar Component
// Navigation sidebar with glassmorphism effect and hover animations
interface SidebarProps {
  activeSection: string
  onSectionChange: (section: string) => void
}

export default function Sidebar({ activeSection, onSectionChange }: SidebarProps) {
  const menuItems = [
    { id: 'overview', label: 'Overview', icon: LayoutDashboard },
    { id: 'pods', label: 'Pods', icon: Box },
    { id: 'services', label: 'Services', icon: Network },
    { id: 'storage', label: 'Storage', icon: Database },
    { id: 'security', label: 'Security', icon: Shield },
    { id: 'monitoring', label: 'Monitoring', icon: Activity },
    { id: 'terminal', label: 'Terminal', icon: TerminalIcon },
    { id: 'settings', label: 'Settings', icon: Settings },
  ]

  return (
    <motion.aside
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: 1, x: 0 }}
      className="w-64 min-h-screen glass-darker border-r border-purple-800/30"
    >
      <nav className="p-4 space-y-2">
        {menuItems.map((item, index) => {
          const Icon = item.icon
          const isActive = activeSection === item.id
          
          return (
            <motion.button
              key={item.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.05 }}
              onClick={() => onSectionChange(item.id)}
              className={`
                w-full flex items-center gap-3 px-4 py-3 rounded-lg
                transition-all duration-300 group relative overflow-hidden
                ${isActive 
                  ? 'bg-purple-600/20 border border-purple-500/30 text-purple-300' 
                  : 'hover:bg-purple-900/20 text-purple-400/60 hover:text-purple-300'
                }
              `}
            >
              {/* Active indicator */}
              {isActive && (
                <motion.div
                  layoutId="activeIndicator"
                  className="absolute left-0 top-0 bottom-0 w-1 bg-gradient-to-b from-purple-400 to-purple-600"
                />
              )}
              
              {/* Hover effect background */}
              <motion.div
                className="absolute inset-0 bg-gradient-to-r from-purple-600/10 to-transparent"
                initial={{ x: '-100%' }}
                whileHover={{ x: 0 }}
                transition={{ duration: 0.3 }}
              />
              
              <Icon className={`w-5 h-5 relative z-10 ${isActive ? 'text-purple-400' : ''}`} />
              <span className="font-medium relative z-10">{item.label}</span>
              
              {/* Notification dot for some items */}
              {item.id === 'pods' && (
                <span className="ml-auto w-2 h-2 bg-green-400 rounded-full animate-pulse"></span>
              )}
              {item.id === 'security' && (
                <span className="ml-auto text-xs bg-purple-600/30 text-purple-300 px-2 py-0.5 rounded">2</span>
              )}
            </motion.button>
          )
        })}
      </nav>
      
      {/* Status indicator at bottom */}
      <div className="absolute bottom-0 left-0 right-0 p-4">
        <div className="glass rounded-lg p-3 border border-purple-700/30">
          <div className="flex items-center gap-2">
            <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
            <span className="text-xs text-purple-400">Connected to Cluster</span>
          </div>
          <div className="mt-1 text-xs text-purple-500/60">API: v1.29.0</div>
        </div>
      </div>
    </motion.aside>
  )
}