# Development stage
FROM node:18-alpine

WORKDIR /app

# Copy npm config and package files
COPY .npmrc package*.json ./

# Install dependencies
# Use npm ci if package-lock.json exists (faster and more reliable)
# Otherwise use npm install
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

# Copy source code
COPY . .

EXPOSE 3000

# Start development server
CMD ["npm", "start"]
