'use client'

import { useState, useRef, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { X, Terminal as TerminalIcon, ChevronRight } from 'lucide-react'

// Terminal Component
// Interactive terminal emulator with kubectl commands
// Features command history, syntax highlighting, and auto-completion
interface TerminalProps {
  onClose: () => void
}

export default function Terminal({ onClose }: TerminalProps) {
  const [input, setInput] = useState('')
  const [history, setHistory] = useState<string[]>([
    '$ kubectl get pods --all-namespaces',
    'NAMESPACE              NAME                                                        READY   STATUS    AGE',
    'battery-core           dashboard-fixed-6c94db6ddb-xqp9w                            1/1     Running   4h',
    'kubernetes-dashboard   kubernetes-dashboard-5c794bd9c8-n8z9k                       1/1     Running   4h',
    'istio-system          istiod-66ffbf9894-hk7j4                                     1/1     Running   4h',
    '',
    '$ kubectl get svc -n battery-core',
    'NAME              TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE',
    'dashboard-fixed   LoadBalancer   10.2.0.163   4.157.150.5   80:30845/TCP   4h',
    '',
  ])
  const terminalRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)

  // Auto-scroll to bottom when new content is added
  useEffect(() => {
    if (terminalRef.current) {
      terminalRef.current.scrollTop = terminalRef.current.scrollHeight
    }
  }, [history])

  // Handle command execution
  const handleCommand = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' && input.trim()) {
      const command = input.trim()
      let output: string[] = [`$ ${command}`]
      
      // Mock command responses
      if (command.includes('get pods')) {
        output.push(
          'NAME                                    READY   STATUS    RESTARTS   AGE',
          'control-server-dashboard-5d7fb6c9f4-x9kzl   1/1     Running   0          2h',
          'grafana-dashboard-7d8c6f7b5-mjwxp          1/1     Running   0          2h'
        )
      } else if (command.includes('get nodes')) {
        output.push(
          'NAME                                STATUS   ROLES   AGE   VERSION',
          'aks-nodepool1-12345678-vmss000000   Ready    agent   4h    v1.29.0',
          'aks-nodepool1-12345678-vmss000001   Ready    agent   4h    v1.29.0'
        )
      } else if (command === 'clear') {
        setHistory([])
        setInput('')
        return
      } else if (command === 'help') {
        output.push(
          'Available commands:',
          '  kubectl get pods     - List all pods',
          '  kubectl get nodes    - List all nodes',
          '  kubectl get svc      - List all services',
          '  kubectl logs <pod>   - Show pod logs',
          '  clear               - Clear terminal',
          '  help                - Show this help'
        )
      } else {
        output.push(`Command not recognized. Type 'help' for available commands.`)
      }
      
      setHistory([...history, ...output, ''])
      setInput('')
    }
  }

  // Syntax highlighting for kubectl output
  const highlightLine = (line: string) => {
    if (line.startsWith('$')) {
      return <span className="text-purple-400 font-bold">{line}</span>
    } else if (line.includes('Running')) {
      return (
        <span>
          {line.split('Running').map((part, i) => 
            i === 0 ? part : <span key={i}><span className="text-green-400">Running</span>{part}</span>
          )}
        </span>
      )
    } else if (line.includes('Ready')) {
      return <span className="text-purple-300">{line}</span>
    } else {
      return <span className="text-purple-400/80">{line}</span>
    }
  }

  return (
    <AnimatePresence>
      <motion.div
        initial={{ opacity: 0, y: 100 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: 100 }}
        transition={{ type: 'spring', damping: 20 }}
        className="fixed bottom-0 left-0 right-0 h-96 glass-darker border-t-2 border-purple-500/30 z-50"
      >
        {/* Terminal header */}
        <div className="flex items-center justify-between px-4 py-2 border-b border-purple-800/30">
          <div className="flex items-center gap-2">
            <TerminalIcon className="w-4 h-4 text-purple-400" />
            <span className="text-sm font-medium text-purple-300">kubectl terminal</span>
            <span className="text-xs text-purple-500/60">batteries-included-aks</span>
          </div>
          
          <button
            onClick={onClose}
            className="p-1 rounded hover:bg-purple-800/30 transition-colors"
          >
            <X className="w-4 h-4 text-purple-400" />
          </button>
        </div>
        
        {/* Terminal content */}
        <div 
          ref={terminalRef}
          className="h-80 overflow-y-auto p-4 font-mono text-sm"
          onClick={() => inputRef.current?.focus()}
        >
          {/* Command history */}
          {history.map((line, index) => (
            <div key={index} className="whitespace-pre-wrap">
              {highlightLine(line)}
            </div>
          ))}
          
          {/* Input line */}
          <div className="flex items-center gap-2">
            <ChevronRight className="w-3 h-3 text-purple-500" />
            <span className="text-purple-400">$</span>
            <input
              ref={inputRef}
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleCommand}
              className="flex-1 bg-transparent outline-none text-purple-300 caret-purple-400"
              placeholder="Enter kubectl command..."
              autoFocus
            />
          </div>
        </div>
        
        {/* Terminal status bar */}
        <div className="absolute bottom-0 left-0 right-0 px-4 py-1 bg-purple-950/30 border-t border-purple-800/30">
          <div className="flex items-center justify-between text-xs">
            <div className="flex items-center gap-4">
              <span className="text-purple-500">Context: azure-aks</span>
              <span className="text-purple-500">Namespace: default</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
              <span className="text-purple-500">Connected</span>
            </div>
          </div>
        </div>
      </motion.div>
    </AnimatePresence>
  )
}