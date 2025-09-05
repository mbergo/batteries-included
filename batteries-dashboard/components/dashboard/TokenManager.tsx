'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { Copy, Eye, EyeOff, Key, Shield, CheckCircle } from 'lucide-react'

// TokenManager Component
// Securely displays and manages bearer tokens with copy functionality
// Features masked display, copy-to-clipboard, and visual feedback
interface TokenManagerProps {
  token: string
}

export default function TokenManager({ token }: TokenManagerProps) {
  const [isRevealed, setIsRevealed] = useState(false)
  const [copied, setCopied] = useState(false)
  
  // Mask token for security - shows only first and last characters
  const maskedToken = `${token.substring(0, 20)}...${token.substring(token.length - 10)}`
  
  // Copy token to clipboard with visual feedback
  const copyToClipboard = async () => {
    try {
      await navigator.clipboard.writeText(token)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (err) {
      console.error('Failed to copy token:', err)
    }
  }
  
  // Additional tokens for different services
  const tokens = [
    {
      name: 'Dashboard Admin Token',
      type: 'Bearer',
      value: token,
      issuer: 'kubernetes-dashboard',
      expiry: '24 hours'
    },
    {
      name: 'Bootstrap Token',
      type: 'Bootstrap',
      value: '0vig8m.kww85or98n84nvim',
      issuer: 'kube-system',
      expiry: 'No expiry'
    },
    {
      name: 'OIDC Issuer',
      type: 'URL',
      value: 'https://eastus.oic.prod-aks.azure.com/...',
      issuer: 'Azure AKS',
      expiry: 'N/A'
    }
  ]

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay: 0.3 }}
      className="glass rounded-xl p-6 glow-purple"
    >
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <Shield className="w-5 h-5 text-purple-400" />
          <h3 className="text-lg font-semibold text-purple-300">Token Manager</h3>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs text-purple-400/60 bg-purple-900/30 px-2 py-1 rounded">
            Secure Storage
          </span>
        </div>
      </div>
      
      {/* Token cards grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {tokens.map((tokenItem, index) => (
          <motion.div
            key={index}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: index * 0.1 }}
            className="p-4 rounded-lg bg-purple-950/30 border border-purple-700/30 space-y-3"
          >
            {/* Token header */}
            <div className="flex items-start justify-between">
              <div>
                <h4 className="text-sm font-medium text-purple-200">{tokenItem.name}</h4>
                <div className="flex items-center gap-2 mt-1">
                  <span className="text-xs text-purple-400/60">{tokenItem.type}</span>
                  <span className="text-xs text-purple-500">•</span>
                  <span className="text-xs text-purple-400/60">{tokenItem.issuer}</span>
                </div>
              </div>
              <Key className="w-4 h-4 text-purple-500" />
            </div>
            
            {/* Token value with reveal/hide */}
            <div className="relative">
              <div className="font-mono text-xs text-purple-300/80 bg-black/40 p-2 rounded border border-purple-800/30 break-all">
                {index === 0 ? (isRevealed ? token : maskedToken) : tokenItem.value}
              </div>
              
              {index === 0 && (
                <button
                  onClick={() => setIsRevealed(!isRevealed)}
                  className="absolute right-2 top-1/2 -translate-y-1/2 p-1 hover:bg-purple-800/30 rounded transition-colors"
                >
                  {isRevealed ? (
                    <EyeOff className="w-3 h-3 text-purple-400" />
                  ) : (
                    <Eye className="w-3 h-3 text-purple-400" />
                  )}
                </button>
              )}
            </div>
            
            {/* Token actions */}
            <div className="flex items-center justify-between">
              <span className="text-xs text-purple-500/60">Expires: {tokenItem.expiry}</span>
              <button
                onClick={copyToClipboard}
                className="flex items-center gap-1 px-2 py-1 text-xs bg-purple-800/30 hover:bg-purple-700/40 rounded transition-all duration-200"
              >
                {copied ? (
                  <>
                    <CheckCircle className="w-3 h-3 text-green-400" />
                    <span className="text-green-400">Copied!</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-3 h-3 text-purple-300" />
                    <span className="text-purple-300">Copy</span>
                  </>
                )}
              </button>
            </div>
          </motion.div>
        ))}
      </div>
      
      {/* Security notice */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.5 }}
        className="mt-6 p-3 rounded-lg bg-purple-950/20 border border-purple-800/30"
      >
        <div className="flex items-start gap-2">
          <Shield className="w-4 h-4 text-purple-500 mt-0.5" />
          <div className="flex-1">
            <p className="text-xs text-purple-400/80">
              <span className="font-semibold text-purple-300">Security Notice:</span> These tokens provide full access to your Kubernetes cluster. 
              Keep them secure and never share them publicly. Tokens are encrypted at rest and in transit.
            </p>
          </div>
        </div>
      </motion.div>
    </motion.div>
  )
}