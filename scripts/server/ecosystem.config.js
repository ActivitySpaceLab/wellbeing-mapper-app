module.exports = {
  apps: [{
    name: 'barcelona-server',
    script: 'src/app.js',
    cwd: '/opt/barcelona-server',
    user: 'barcelona',
    
    // Process management
    instances: 1, // Single instance for research server
    exec_mode: 'fork',
    
    // Auto-restart configuration
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    
    // Logging
    log_file: '/var/log/barcelona-server/combined.log',
    out_file: '/var/log/barcelona-server/out.log',
    error_file: '/var/log/barcelona-server/error.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // Environment
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    
    // Graceful shutdown
    kill_timeout: 5000,
    
    // Monitoring
    min_uptime: '10s',
    max_restarts: 5
  }]
};