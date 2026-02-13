# Use Node.js 18 Alpine for smaller image size
FROM node:18-alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install ALL dependencies (we need devDependencies to build)
RUN npm install && npm cache clean --force

# Copy all source files
COPY . .

# Build the NestJS application
RUN npm run build

# Remove devDependencies after build to reduce image size
RUN npm prune --production

# Create uploads directory for file storage
RUN mkdir -p uploads

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001 && \
    chown -R nestjs:nodejs /app

# Switch to non-root user
USER nestjs

# Expose port
EXPOSE 3000

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/v1/health || exit 1

# Start the application in production mode
CMD ["node", "dist/main"]