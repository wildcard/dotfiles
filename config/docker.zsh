#!/usr/bin/env zsh

# ==========================================
# SECURE DOTFILES - DOCKER CONFIGURATION
# ==========================================
# Docker utilities and cleanup functions
# Security-focused with safe defaults

# ==========================================
# DOCKER SYSTEM INFORMATION
# ==========================================

# Docker system overview
docker-info() {
    if ! command -v docker &>/dev/null; then
        echo "❌ Docker not installed"
        return 1
    fi

    echo "🐳 Docker System Information:"
    echo "============================"

    # Check if Docker daemon is running
    if ! docker info &>/dev/null; then
        echo "❌ Docker daemon not running"
        echo "Start Docker Desktop or run: sudo systemctl start docker"
        return 1
    fi

    echo "✅ Docker daemon running"
    echo ""

    # System info
    docker system df

    echo ""
    echo "📊 Container Statistics:"
    echo "======================="
    echo "Running containers: $(docker ps -q | wc -l | tr -d ' ')"
    echo "Total containers: $(docker ps -a -q | wc -l | tr -d ' ')"
    echo "Images: $(docker images -q | wc -l | tr -d ' ')"
    echo "Volumes: $(docker volume ls -q | wc -l | tr -d ' ')"
    echo "Networks: $(docker network ls -q | wc -l | tr -d ' ')"
}

# ==========================================
# DOCKER CLEANUP FUNCTIONS
# ==========================================

# Comprehensive Docker cleanup with safety checks
docker-cleanup() {
    if ! command -v docker &>/dev/null; then
        echo "❌ Docker not installed"
        return 1
    fi

    if ! docker info &>/dev/null; then
        echo "❌ Docker daemon not running"
        return 1
    fi

    echo "🧹 Docker Cleanup Utility"
    echo "========================="
    echo ""

    # Show current disk usage
    echo "📊 Current Docker disk usage:"
    docker system df
    echo ""

    echo "🗑️  Cleanup options:"
    echo "1) Remove stopped containers"
    echo "2) Remove unused images"
    echo "3) Remove unused volumes"
    echo "4) Remove unused networks"
    echo "5) Remove build cache"
    echo "6) Complete cleanup (all of the above)"
    echo "7) Nuclear option (remove EVERYTHING - dangerous!)"
    echo "0) Cancel"
    echo ""

    read "choice?Select cleanup option (0-7): "

    case "$choice" in
        1)
            docker-cleanup-containers
            ;;
        2)
            docker-cleanup-images
            ;;
        3)
            docker-cleanup-volumes
            ;;
        4)
            docker-cleanup-networks
            ;;
        5)
            docker-cleanup-cache
            ;;
        6)
            docker-cleanup-all
            ;;
        7)
            docker-nuclear-cleanup
            ;;
        0)
            echo "❌ Cleanup cancelled"
            ;;
        *)
            echo "❌ Invalid choice"
            return 1
            ;;
    esac
}

# Remove stopped containers
docker-cleanup-containers() {
    echo "🗑️  Removing stopped containers..."

    local stopped_containers=$(docker ps -a -q -f status=exited)
    if [[ -z "$stopped_containers" ]]; then
        echo "✅ No stopped containers to remove"
        return 0
    fi

    echo "Stopped containers to remove:"
    docker ps -a -f status=exited --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
    echo ""

    read "confirm?Remove these containers? (y/N): "
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        docker rm $stopped_containers
        echo "✅ Stopped containers removed"
    else
        echo "❌ Container cleanup cancelled"
    fi
}

# Remove unused images
docker-cleanup-images() {
    echo "🗑️  Removing unused images..."

    local dangling_images=$(docker images -f "dangling=true" -q)
    if [[ -z "$dangling_images" ]]; then
        echo "✅ No dangling images to remove"
    else
        echo "Dangling images to remove:"
        docker images -f "dangling=true"
        echo ""

        read "confirm?Remove dangling images? (y/N): "
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            docker rmi $dangling_images
            echo "✅ Dangling images removed"
        fi
    fi

    echo ""
    read "remove_unused?Also remove unused images (not just dangling)? (y/N): "
    if [[ "$remove_unused" =~ ^[Yy]$ ]]; then
        docker image prune -a
        echo "✅ Unused images removed"
    fi
}

# Remove unused volumes
docker-cleanup-volumes() {
    echo "🗑️  Removing unused volumes..."

    local unused_volumes=$(docker volume ls -f dangling=true -q)
    if [[ -z "$unused_volumes" ]]; then
        echo "✅ No unused volumes to remove"
        return 0
    fi

    echo "Unused volumes to remove:"
    docker volume ls -f dangling=true
    echo ""

    read "confirm?Remove these volumes? (y/N): "
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        docker volume prune -f
        echo "✅ Unused volumes removed"
    else
        echo "❌ Volume cleanup cancelled"
    fi
}

# Remove unused networks
docker-cleanup-networks() {
    echo "🗑️  Removing unused networks..."

    docker network prune
    echo "✅ Unused networks removed"
}

# Remove build cache
docker-cleanup-cache() {
    echo "🗑️  Removing build cache..."

    docker builder prune
    echo "✅ Build cache removed"
}

# Complete cleanup (safe)
docker-cleanup-all() {
    echo "🧹 Performing complete Docker cleanup..."
    echo "======================================="

    # Remove stopped containers
    docker container prune -f

    # Remove unused images
    docker image prune -f

    # Remove unused volumes
    docker volume prune -f

    # Remove unused networks
    docker network prune -f

    # Remove build cache
    docker builder prune -f

    echo ""
    echo "✅ Complete cleanup finished"
    echo ""
    echo "📊 Updated Docker disk usage:"
    docker system df
}

# Nuclear cleanup (removes EVERYTHING)
docker-nuclear-cleanup() {
    echo "☢️  NUCLEAR CLEANUP - THIS WILL REMOVE EVERYTHING!"
    echo "================================================="
    echo ""
    echo "⚠️  WARNING: This will remove:"
    echo "   • ALL containers (running and stopped)"
    echo "   • ALL images"
    echo "   • ALL volumes"
    echo "   • ALL networks (except default ones)"
    echo "   • ALL build cache"
    echo ""
    echo "🚨 THIS CANNOT BE UNDONE!"
    echo ""

    read "confirm1?Type 'DELETE EVERYTHING' to confirm: "
    if [[ "$confirm1" != "DELETE EVERYTHING" ]]; then
        echo "❌ Nuclear cleanup cancelled"
        return 1
    fi

    read "confirm2?Are you absolutely sure? (y/N): "
    if [[ ! "$confirm2" =~ ^[Yy]$ ]]; then
        echo "❌ Nuclear cleanup cancelled"
        return 1
    fi

    echo "☢️  Initiating nuclear cleanup in 5 seconds... (Ctrl+C to abort)"
    sleep 5

    # Stop all containers
    echo "🛑 Stopping all containers..."
    docker stop $(docker ps -q) 2>/dev/null || true

    # Remove everything
    echo "💣 Removing everything..."
    docker system prune -a -f --volumes

    echo ""
    echo "☢️  Nuclear cleanup completed"
    echo ""
    echo "📊 Docker disk usage after nuclear cleanup:"
    docker system df
}

# ==========================================
# DOCKER DEVELOPMENT UTILITIES
# ==========================================

# Quick container shell access
docker-shell() {
    local container="$1"
    local shell="${2:-bash}"

    if [[ -z "$container" ]]; then
        echo "Usage: docker-shell <container_name_or_id> [shell]"
        echo ""
        echo "Available containers:"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
        return 1
    fi

    if ! docker ps -q -f name="$container" | grep -q .; then
        echo "❌ Container '$container' not found or not running"
        return 1
    fi

    echo "🐚 Connecting to container: $container"
    docker exec -it "$container" "$shell"
}

# View container logs with follow
docker-logs-follow() {
    local container="$1"
    local lines="${2:-100}"

    if [[ -z "$container" ]]; then
        echo "Usage: docker-logs-follow <container_name_or_id> [number_of_lines]"
        echo ""
        echo "Available containers:"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
        return 1
    fi

    echo "📄 Following logs for container: $container (last $lines lines)"
    docker logs -f --tail "$lines" "$container"
}

# Show container resource usage
docker-stats-pretty() {
    echo "📊 Container Resource Usage:"
    echo "==========================="
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# ==========================================
# DOCKER COMPOSE UTILITIES
# ==========================================

# Docker Compose with better output
dc-up() {
    local service="$1"

    if [[ ! -f "docker-compose.yml" && ! -f "docker-compose.yaml" ]]; then
        echo "❌ No docker-compose.yml file found in current directory"
        return 1
    fi

    echo "🚀 Starting Docker Compose services..."

    if [[ -n "$service" ]]; then
        docker-compose up -d "$service"
        echo "✅ Service '$service' started"
    else
        docker-compose up -d
        echo "✅ All services started"
    fi

    echo ""
    echo "📊 Service status:"
    docker-compose ps
}

# Docker Compose logs with follow
dc-logs() {
    local service="$1"
    local lines="${2:-100}"

    if [[ ! -f "docker-compose.yml" && ! -f "docker-compose.yaml" ]]; then
        echo "❌ No docker-compose.yml file found in current directory"
        return 1
    fi

    if [[ -n "$service" ]]; then
        echo "📄 Following logs for service: $service"
        docker-compose logs -f --tail "$lines" "$service"
    else
        echo "📄 Following logs for all services"
        docker-compose logs -f --tail "$lines"
    fi
}

# Docker Compose down with cleanup
dc-down-clean() {
    if [[ ! -f "docker-compose.yml" && ! -f "docker-compose.yaml" ]]; then
        echo "❌ No docker-compose.yml file found in current directory"
        return 1
    fi

    echo "🛑 Stopping and cleaning up Docker Compose services..."

    read "remove_volumes?Remove volumes as well? (y/N): "
    if [[ "$remove_volumes" =~ ^[Yy]$ ]]; then
        docker-compose down -v --remove-orphans
        echo "✅ Services stopped and volumes removed"
    else
        docker-compose down --remove-orphans
        echo "✅ Services stopped"
    fi
}

# ==========================================
# DOCKER SECURITY UTILITIES
# ==========================================

# Scan image for vulnerabilities (requires docker scan or trivy)
docker-security-scan() {
    local image="$1"

    if [[ -z "$image" ]]; then
        echo "Usage: docker-security-scan <image_name:tag>"
        return 1
    fi

    echo "🔍 Scanning image for vulnerabilities: $image"

    # Try trivy first (more comprehensive)
    if command -v trivy &>/dev/null; then
        trivy image "$image"
    # Fall back to docker scan
    elif docker scan --help &>/dev/null; then
        docker scan "$image"
    else
        echo "❌ No vulnerability scanner available"
        echo "Install trivy: brew install trivy"
        echo "Or enable Docker scan in Docker Desktop"
        return 1
    fi
}

# Check for running containers with privileged access
docker-check-privileged() {
    echo "🔍 Checking for privileged containers:"
    echo "====================================="

    local privileged_containers=$(docker ps --filter "label=privileged=true" -q)
    local privileged_inspect=$(docker ps -q | xargs -I {} docker inspect {} --format='{{.Name}} {{.HostConfig.Privileged}}' | grep true)

    if [[ -n "$privileged_inspect" ]]; then
        echo "⚠️  Found privileged containers:"
        echo "$privileged_inspect"
        echo ""
        echo "🚨 Security Warning: Privileged containers have full access to the host system!"
    else
        echo "✅ No privileged containers found"
    fi
}

# ==========================================
# DOCKER IMAGE UTILITIES
# ==========================================

# Build image with automatic tagging
docker-build-smart() {
    local dockerfile="${1:-Dockerfile}"
    local context="${2:-.}"
    local tag="$3"

    if [[ ! -f "$dockerfile" ]]; then
        echo "❌ Dockerfile not found: $dockerfile"
        return 1
    fi

    # Auto-generate tag if not provided
    if [[ -z "$tag" ]]; then
        local repo_name=$(basename "$(pwd)")
        local git_hash=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
        tag="$repo_name:$git_hash"
    fi

    echo "🔨 Building Docker image: $tag"
    echo "Dockerfile: $dockerfile"
    echo "Context: $context"
    echo ""

    docker build -f "$dockerfile" -t "$tag" "$context"

    if [[ $? -eq 0 ]]; then
        echo ""
        echo "✅ Build completed: $tag"
        echo "Image size: $(docker images "$tag" --format '{{.Size}}')"
    else
        echo "❌ Build failed"
        return 1
    fi
}

# List images with sizes and vulnerabilities
docker-images-detailed() {
    echo "📦 Docker Images (Detailed):"
    echo "============================"

    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}" | head -20

    echo ""
    echo "💾 Total disk usage by images:"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | \
        awk 'NR>1 {gsub(/MB|GB/, "", $3); if($3 ~ /GB/) $3=$3*1024; total+=$3} END {print "Total: " total " MB"}'
}

# ==========================================
# DOCKER NETWORK UTILITIES
# ==========================================

# List networks with detailed information
docker-networks() {
    echo "🌐 Docker Networks:"
    echo "=================="

    docker network ls --format "table {{.Name}}\t{{.Driver}}\t{{.Scope}}"

    echo ""
    echo "📊 Network details:"
    docker network ls -q | xargs -I {} sh -c 'echo "Network: $(docker network inspect {} --format {{.Name}})" && docker network inspect {} --format "  Driver: {{.Driver}}" && docker network inspect {} --format "  Containers: {{len .Containers}}" && echo ""'
}

# ==========================================
# DOCKER HEALTH CHECKS
# ==========================================

# Check health of all containers
docker-health-check() {
    echo "🏥 Container Health Check:"
    echo "========================="

    local unhealthy_count=0

    for container in $(docker ps -q); do
        local name=$(docker inspect "$container" --format '{{.Name}}' | sed 's|^/||')
        local health=$(docker inspect "$container" --format '{{.State.Health.Status}}' 2>/dev/null)
        local status=$(docker inspect "$container" --format '{{.State.Status}}')

        if [[ "$health" == "unhealthy" ]]; then
            echo "❌ $name: $status ($health)"
            unhealthy_count=$((unhealthy_count + 1))
        elif [[ "$health" == "healthy" ]]; then
            echo "✅ $name: $status ($health)"
        else
            echo "ℹ️  $name: $status (no health check)"
        fi
    done

    echo ""
    if [[ $unhealthy_count -gt 0 ]]; then
        echo "⚠️  Found $unhealthy_count unhealthy container(s)"
        return 1
    else
        echo "✅ All containers are healthy"
    fi
}

# ==========================================
# DOCKER ALIASES ENHANCEMENT
# ==========================================

# Override dangerous commands with confirmations
docker-rm-all() {
    echo "⚠️  WARNING: This will remove ALL containers!"
    read "confirm?Are you sure? (y/N): "
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        docker rm -f $(docker ps -a -q)
        echo "✅ All containers removed"
    else
        echo "❌ Operation cancelled"
    fi
}

docker-rmi-all() {
    echo "⚠️  WARNING: This will remove ALL images!"
    read "confirm?Are you sure? (y/N): "
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        docker rmi -f $(docker images -q)
        echo "✅ All images removed"
    else
        echo "❌ Operation cancelled"
    fi
}