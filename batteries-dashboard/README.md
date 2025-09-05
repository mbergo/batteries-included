# 🔋 Batteries Dashboard - Black & Purple Theme

An awesome Kubernetes dashboard with a sleek black and purple theme, built with Next.js, shadcn/ui, and Tailwind CSS.

![Dashboard Preview](preview.png)

## ✨ Features

### 🎨 Visual Design
- **Black & Purple Gradient Theme**: Sophisticated dark theme with purple accents
- **Glassmorphism Effects**: Modern glass-like components with backdrop blur
- **Animated Gradients**: Smooth gradient animations throughout the UI
- **Framer Motion Animations**: Smooth transitions and interactions

### 📊 Dashboard Components

1. **Cluster Health Monitor**
   - Real-time health status with animated indicators
   - Node, pod, and service counts
   - Visual pulse animations for active status

2. **Resource Charts**
   - CPU and Memory usage visualization
   - Animated line and area charts with Recharts
   - Custom purple gradient fills
   - Real-time metrics display

3. **Pod Grid**
   - Live pod status monitoring
   - Color-coded health indicators
   - Resource usage per pod
   - Restart count tracking

4. **Service Map**
   - Visual service topology
   - Interactive node connections
   - Service type and port information
   - Animated service nodes

5. **Token Manager**
   - Secure bearer token display
   - Copy-to-clipboard functionality
   - Token masking for security
   - Multiple token type support

6. **Interactive Terminal**
   - kubectl command emulation
   - Syntax highlighting
   - Command history
   - Auto-completion suggestions

## 🚀 How It Works

### Architecture

The dashboard follows a component-based architecture:

```
app/
├── page.tsx          # Main dashboard entry point
├── layout.tsx        # Root layout with metadata
└── globals.css       # Global styles and utilities

components/
├── dashboard/        # Dashboard-specific components
│   ├── ClusterHealth.tsx    # Health monitoring
│   ├── ResourceCharts.tsx   # CPU/Memory charts
│   ├── PodGrid.tsx          # Pod status grid
│   ├── ServiceMap.tsx       # Service topology
│   └── TokenManager.tsx     # Token management
└── layout/          # Layout components
    ├── Header.tsx           # Top navigation
    ├── Sidebar.tsx          # Side navigation
    └── Terminal.tsx         # Terminal emulator
```

### Key Technologies

- **Next.js 14**: React framework with App Router
- **TypeScript**: Type-safe development
- **Tailwind CSS**: Utility-first styling
- **shadcn/ui**: Headless UI components
- **Framer Motion**: Animation library
- **Recharts**: Chart visualization
- **Radix UI**: Accessible component primitives

### Component Explanation

#### ClusterHealth Component
```typescript
// Uses framer-motion for smooth animations
// Displays real-time cluster status with color-coded indicators
// Animated pulse effect for active status
```

#### ResourceCharts Component
```typescript
// Recharts library for data visualization
// Custom gradient definitions for purple theme
// Real-time CPU and memory metrics
// Responsive chart containers
```

#### TokenManager Component
```typescript
// Secure token display with masking
// Copy-to-clipboard with visual feedback
// Multiple token type support
// Security notice for best practices
```

#### Terminal Component
```typescript
// Interactive command-line interface
// kubectl command emulation
// Syntax highlighting for output
// Command history navigation
```

## 🛠️ Installation

1. Install dependencies:
```bash
cd batteries-dashboard
npm install
```

2. Run the development server:
```bash
npm run dev
```

3. Open [http://localhost:3000](http://localhost:3000)

## 🎯 Customization

### Theme Colors

Edit the color palette in `tailwind.config.ts`:

```javascript
purple: {
  50: '#faf5ff',
  100: '#f3e8ff',
  200: '#e9d5ff',
  300: '#d8b4fe',
  400: '#c084fc',  // Primary accent
  500: '#a855f7',  // Main purple
  600: '#9333ea',
  700: '#7e22ce',
  800: '#6b21a8',
  900: '#581c87',
  950: '#3b0764',  // Dark purple
}
```

### Gradient Effects

Customize gradients in `globals.css`:

```css
.gradient-bg {
  background: linear-gradient(-45deg, #0a0a0a, #18181b, #3b0764, #581c87);
  background-size: 400% 400%;
  animation: gradient 15s ease infinite;
}
```

### Animation Speed

Adjust animation durations in components:

```typescript
animate={{ opacity: 1, y: 0 }}
transition={{ duration: 0.5, delay: 0.1 }}
```

## 🔗 Integration

### Connecting to Real Kubernetes API

Replace mock data with actual API calls:

```typescript
// Example: Fetch real pod data
const fetchPods = async () => {
  const response = await fetch('/api/k8s/pods', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  })
  const data = await response.json()
  setPods(data.items)
}
```

### WebSocket for Real-time Updates

```typescript
// Connect to K8s watch API
const ws = new WebSocket('wss://your-cluster/api/v1/watch/pods')
ws.onmessage = (event) => {
  const update = JSON.parse(event.data)
  updatePodStatus(update)
}
```

## 📱 Responsive Design

The dashboard is fully responsive:
- **Desktop**: Full sidebar + main content
- **Tablet**: Collapsible sidebar
- **Mobile**: Bottom navigation

## 🔒 Security

- Bearer tokens are masked by default
- Copy-to-clipboard requires user interaction
- Tokens stored in memory only
- HTTPS recommended for production

## 🎭 Performance

- Lazy loading for heavy components
- Memoized chart data
- Debounced terminal input
- Optimized re-renders with React.memo

## 📄 License

MIT

## 🤝 Contributing

Pull requests are welcome! Please follow the existing code style and add tests for new features.

---

Built with 💜 for the Batteries Included project