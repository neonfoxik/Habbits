# Development stage
FROM node:18

# Update package manager
RUN apt-get update && apt-get install -y libc6-dev

WORKDIR /app

# Copy npm config and package files
COPY .npmrc package*.json ./

# Configure network for faster downloads
RUN echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# Install dependencies
RUN npm install --verbose

# Copy source code
COPY . .

EXPOSE 3000

# Start development server
CMD ["npm", "start"]
