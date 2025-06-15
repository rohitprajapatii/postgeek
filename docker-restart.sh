#!/bin/bash

echo "🔄 Rebuilding and restarting Docker containers..."

# Stop and remove existing containers
echo "📦 Stopping existing containers..."
docker-compose down

# Remove any orphaned containers
echo "🧹 Cleaning up..."
docker system prune -f

# Rebuild and start containers
echo "🚀 Building and starting containers..."
docker-compose up --build -d

# Show container status
echo "📊 Container status:"
docker-compose ps

echo "✅ Done! Your application should be available at:"
echo "   🌐 Frontend: http://localhost:8081"
echo "   🔗 Backend API: http://localhost:3000"
echo ""
echo "🔍 To check logs:"
echo "   Frontend: docker-compose logs -f frontend"
echo "   Backend:  docker-compose logs -f backend" 