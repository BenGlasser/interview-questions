const express = require('express');
const { createClient } = require('redis');

const app = express();
const PORT = process.env.PORT || 3000;

// Redis configuration from environment variables
const REDIS_HOST = process.env.REDIS_HOST || 'localhost';
const REDIS_PORT = process.env.REDIS_PORT || 6379;
const REDIS_TLS = process.env.REDIS_TLS === 'true';
const REDIS_PASSWORD = process.env.REDIS_PASSWORD;

// Create Redis client
const redisClient = createClient({
  socket: {
    host: REDIS_HOST,
    port: parseInt(REDIS_PORT),
    tls: REDIS_TLS,
    connectTimeout: 5000,
    commandTimeout: 5000
  },
  password: REDIS_PASSWORD,
  // Retry configuration
  retry_unfulfilled_commands: true,
  socket_keepalive: true,
  socket_initial_delay: 0
});

// Redis error handling
redisClient.on('error', (err) => {
  console.error('Redis Client Error:', err.message);
});

redisClient.on('connect', () => {
  console.log(`Connected to Redis at ${REDIS_HOST}:${REDIS_PORT}`);
});

redisClient.on('disconnect', () => {
  console.log('Disconnected from Redis');
});

// Middleware
app.use(express.json());
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
  next();
});

// Health check endpoint - THE MAIN TROUBLESHOOTING TARGET
app.get('/health', async (req, res) => {
  try {
    console.log(`Attempting Redis connection to ${REDIS_HOST}:${REDIS_PORT}`);
    
    // Try to connect if not already connected
    if (!redisClient.isOpen) {
      await redisClient.connect();
    }
    
    // Ping Redis
    const pong = await redisClient.ping();
    console.log('Redis PING response:', pong);
    
    // Try to set and get a test value
    await redisClient.set('health_check', new Date().toISOString());
    const healthValue = await redisClient.get('health_check');
    
    res.json({
      status: 'healthy',
      redis: 'ok',
      redis_host: REDIS_HOST,
      redis_port: REDIS_PORT,
      timestamp: new Date().toISOString(),
      ping_response: pong,
      test_value: healthValue
    });
    
  } catch (error) {
    console.error('Health check failed:', error);
    
    // Return detailed error information for troubleshooting
    res.status(500).json({
      status: 'unhealthy',
      redis: 'error',
      redis_host: REDIS_HOST,
      redis_port: REDIS_PORT,
      error: error.message,
      error_code: error.code,
      error_type: error.constructor.name,
      timestamp: new Date().toISOString(),
      troubleshooting: {
        check_vpc_connector: 'Verify App Runner VPC Connector subnets',
        check_security_groups: 'Verify security group rules allow port 6379',
        check_nacls: 'Check Network ACL rules on connector subnets',
        check_redis_endpoint: 'Verify Redis endpoint is reachable from VPC'
      }
    });
  }
});

// Basic info endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'Terraform Challenge App',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      info: '/',
      set: '/set?key=<key>&value=<value>',
      get: '/get?key=<key>'
    },
    redis_config: {
      host: REDIS_HOST,
      port: REDIS_PORT,
      tls: REDIS_TLS,
      auth_enabled: !!REDIS_PASSWORD
    },
    timestamp: new Date().toISOString()
  });
});

// Set a key-value pair in Redis
app.get('/set', async (req, res) => {
  const { key, value } = req.query;
  
  if (!key || !value) {
    return res.status(400).json({
      error: 'Both key and value query parameters are required',
      example: '/set?key=mykey&value=myvalue'
    });
  }
  
  try {
    if (!redisClient.isOpen) {
      await redisClient.connect();
    }
    
    await redisClient.set(key, value);
    
    res.json({
      success: true,
      operation: 'set',
      key: key,
      value: value,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Set operation failed:', error);
    res.status(500).json({
      success: false,
      operation: 'set',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Get a value from Redis
app.get('/get', async (req, res) => {
  const { key } = req.query;
  
  if (!key) {
    return res.status(400).json({
      error: 'Key query parameter is required',
      example: '/get?key=mykey'
    });
  }
  
  try {
    if (!redisClient.isOpen) {
      await redisClient.connect();
    }
    
    const value = await redisClient.get(key);
    
    res.json({
      success: true,
      operation: 'get',
      key: key,
      value: value,
      found: value !== null,
      timestamp: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Get operation failed:', error);
    res.status(500).json({
      success: false,
      operation: 'get',
      error: error.message,
      timestamp: new Date().toISOString()
    });
  }
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('Received SIGTERM, shutting down gracefully');
  
  if (redisClient.isOpen) {
    await redisClient.quit();
  }
  
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('Received SIGINT, shutting down gracefully');
  
  if (redisClient.isOpen) {
    await redisClient.quit();
  }
  
  process.exit(0);
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n🚀 Terraform Challenge App running on port ${PORT}`);
  console.log(`📊 Redis configuration:`);
  console.log(`   Host: ${REDIS_HOST}`);
  console.log(`   Port: ${REDIS_PORT}`);
  console.log(`   TLS: ${REDIS_TLS}`);
  console.log(`   Auth: ${REDIS_PASSWORD ? 'Enabled' : 'Disabled'}`);
  console.log(`\n🔍 Available endpoints:`);
  console.log(`   GET / - Service information`);
  console.log(`   GET /health - Redis connectivity test`);
  console.log(`   GET /set?key=<key>&value=<value> - Set Redis key`);
  console.log(`   GET /get?key=<key> - Get Redis key`);
  console.log(`\n⏳ Ready to troubleshoot! Visit /health to test Redis connectivity.\n`);
});