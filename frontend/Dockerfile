# Development stage
FROM node:18

# Update package manager
RUN apt-get update && apt-get install -y libc6-dev

WORKDIR /app

# Copy npm config and package files
COPY .npmrc package*.json ./

# Install dependencies
RUN npm install --no-cache --prefer-online

# Copy source code
COPY . .

EXPOSE 3000

# Start development server
CMD ["npm", "start"]
