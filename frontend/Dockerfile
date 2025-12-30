# Development stage
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY package-lock.json* ./

# Install dependencies using npm ci for deterministic builds
RUN npm ci

# Copy source code
COPY . .

EXPOSE 3000

# Start development server
CMD ["npm", "start"]
