'use client'

import { motion } from 'framer-motion'
import { LineChart, Line, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import { Cpu, HardDrive } from 'lucide-react'

// ResourceCharts Component
// Displays CPU and Memory usage with animated gradient charts
// Uses Recharts library for data visualization with custom purple theme
export default function ResourceCharts() {
  // Mock time-series data - In production, this would be real-time metrics
  const cpuData = [
    { time: '00:00', usage: 23 },
    { time: '04:00', usage: 35 },
    { time: '08:00', usage: 45 },
    { time: '12:00', usage: 62 },
    { time: '16:00', usage: 55 },
    { time: '20:00', usage: 40 },
    { time: '24:00', usage: 25 },
  ]

  const memoryData = [
    { time: '00:00', usage: 40 },
    { time: '04:00', usage: 45 },
    { time: '08:00', usage: 52 },
    { time: '12:00', usage: 58 },
    { time: '16:00', usage: 55 },
    { time: '20:00', usage: 48 },
    { time: '24:00', usage: 42 },
  ]

  // Custom tooltip component with glassmorphism effect
  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload[0]) {
      return (
        <div className="glass-darker px-3 py-2 rounded-lg border border-purple-500/30">
          <p className="text-purple-300 text-sm">{label}</p>
          <p className="text-purple-400 font-bold">{`${payload[0].value}%`}</p>
        </div>
      )
    }
    return null
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay: 0.1 }}
      className="glass rounded-xl p-6 glow-purple"
    >
      <h3 className="text-lg font-semibold text-purple-300 mb-6">Resource Usage</h3>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* CPU Usage Chart */}
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <Cpu className="w-4 h-4 text-purple-400" />
            <span className="text-sm text-purple-300">CPU Usage</span>
            <span className="ml-auto text-xl font-bold gradient-text">25%</span>
          </div>
          
          <ResponsiveContainer width="100%" height={150}>
            <AreaChart data={cpuData}>
              {/* Gradient definition for area fill */}
              <defs>
                <linearGradient id="cpuGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#a855f7" stopOpacity={0.3} />
                  <stop offset="100%" stopColor="#a855f7" stopOpacity={0} />
                </linearGradient>
              </defs>
              
              <CartesianGrid strokeDasharray="3 3" stroke="#3b0764" opacity={0.3} />
              <XAxis 
                dataKey="time" 
                stroke="#9333ea"
                fontSize={10}
                axisLine={false}
                tickLine={false}
              />
              <YAxis 
                stroke="#9333ea"
                fontSize={10}
                axisLine={false}
                tickLine={false}
                domain={[0, 100]}
              />
              <Tooltip content={<CustomTooltip />} />
              
              {/* Animated area with gradient fill */}
              <Area
                type="monotone"
                dataKey="usage"
                stroke="#a855f7"
                strokeWidth={2}
                fill="url(#cpuGradient)"
                animationDuration={1500}
                animationEasing="ease-in-out"
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Memory Usage Chart */}
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <HardDrive className="w-4 h-4 text-purple-400" />
            <span className="text-sm text-purple-300">Memory Usage</span>
            <span className="ml-auto text-xl font-bold gradient-text">42%</span>
          </div>
          
          <ResponsiveContainer width="100%" height={150}>
            <LineChart data={memoryData}>
              <defs>
                <linearGradient id="memoryGradient" x1="0" y1="0" x2="1" y2="0">
                  <stop offset="0%" stopColor="#7e22ce" />
                  <stop offset="100%" stopColor="#c084fc" />
                </linearGradient>
              </defs>
              
              <CartesianGrid strokeDasharray="3 3" stroke="#3b0764" opacity={0.3} />
              <XAxis 
                dataKey="time" 
                stroke="#9333ea"
                fontSize={10}
                axisLine={false}
                tickLine={false}
              />
              <YAxis 
                stroke="#9333ea"
                fontSize={10}
                axisLine={false}
                tickLine={false}
                domain={[0, 100]}
              />
              <Tooltip content={<CustomTooltip />} />
              
              {/* Animated line with gradient stroke */}
              <Line
                type="monotone"
                dataKey="usage"
                stroke="url(#memoryGradient)"
                strokeWidth={3}
                dot={false}
                animationDuration={1500}
                animationEasing="ease-in-out"
              />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
      
      {/* Resource allocation bars */}
      <div className="mt-6 space-y-3">
        <div className="space-y-2">
          <div className="flex justify-between text-xs text-purple-400">
            <span>CPU Allocation</span>
            <span>2.5 / 4 cores</span>
          </div>
          <div className="h-2 bg-purple-950/50 rounded-full overflow-hidden">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: '62.5%' }}
              transition={{ duration: 1, ease: 'easeOut' }}
              className="h-full bg-gradient-to-r from-purple-600 to-purple-400 rounded-full"
            />
          </div>
        </div>
        
        <div className="space-y-2">
          <div className="flex justify-between text-xs text-purple-400">
            <span>Memory Allocation</span>
            <span>6.7 / 16 GB</span>
          </div>
          <div className="h-2 bg-purple-950/50 rounded-full overflow-hidden">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: '42%' }}
              transition={{ duration: 1, ease: 'easeOut', delay: 0.2 }}
              className="h-full bg-gradient-to-r from-purple-600 to-purple-400 rounded-full"
            />
          </div>
        </div>
      </div>
    </motion.div>
  )
}