# Development stage
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (generate package-lock.json if needed)
RUN npm install

# Copy source code
COPY . .

EXPOSE 3000

# Start development server
CMD ["npm", "start"]
