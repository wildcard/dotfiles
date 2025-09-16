#!/usr/bin/env zsh

# ==========================================
# SECURE DOTFILES - KUBERNETES CONFIGURATION
# ==========================================
# Kubernetes utilities and helpers
# Security-focused with context awareness

# ==========================================
# KUBERNETES CONTEXT MANAGEMENT
# ==========================================

# Interactive Kubernetes context switcher
kctx-switch() {
    if ! command -v kubectl &>/dev/null; then
        echo "❌ kubectl not installed"
        return 1
    fi

    # Get available contexts
    local contexts=($(kubectl config get-contexts -o name 2>/dev/null))

    if [[ ${#contexts[@]} -eq 0 ]]; then
        echo "❌ No Kubernetes contexts configured"
        return 1
    fi

    local current_context=$(kubectl config current-context 2>/dev/null)

    echo "☸️  Available Kubernetes Contexts:"
    echo "=================================="

    # Display contexts with numbers
    for i in {1..${#contexts[@]}}; do
        local context="${contexts[$i]}"
        if [[ "$current_context" == "$context" ]]; then
            echo "$i) $context (current)"
        else
            echo "$i) $context"
        fi
    done

    echo ""

    # Get user selection
    read "selection?Select context (1-${#contexts[@]}): "

    # Validate selection
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt ${#contexts[@]} ]]; then
        echo "❌ Invalid selection"
        return 1
    fi

    # Set selected context
    local selected_context="${contexts[$selection]}"
    kubectl config use-context "$selected_context"

    if [[ $? -eq 0 ]]; then
        echo "✅ Switched to context: $selected_context"
        k8s-context-info
    else
        echo "❌ Failed to switch context"
        return 1
    fi
}

# Show current Kubernetes context information
k8s-context-info() {
    if ! command -v kubectl &>/dev/null; then
        echo "❌ kubectl not installed"
        return 1
    fi

    echo "☸️  Current Kubernetes Context:"
    echo "==============================="

    local current_context=$(kubectl config current-context 2>/dev/null)
    if [[ -z "$current_context" ]]; then
        echo "❌ No current context set"
        return 1
    fi

    echo "Context: $current_context"

    local current_ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
    echo "Namespace: ${current_ns:-default}"

    # Try to get cluster info
    local cluster_info=$(kubectl cluster-info 2>/dev/null | head -1)
    if [[ -n "$cluster_info" ]]; then
        echo "Cluster: $cluster_info"
    fi

    # Check if we can access the cluster
    if kubectl auth can-i get pods &>/dev/null; then
        echo "Access: ✅ Can access cluster"
    else
        echo "Access: ❌ Cannot access cluster (check credentials)"
    fi
}

# ==========================================
# KUBERNETES NAMESPACE MANAGEMENT
# ==========================================

# Interactive namespace switcher
kns-switch() {
    if ! command -v kubectl &>/dev/null; then
        echo "❌ kubectl not installed"
        return 1
    fi

    # Get available namespaces
    local namespaces=($(kubectl get namespaces -o name 2>/dev/null | sed 's|namespace/||'))

    if [[ ${#namespaces[@]} -eq 0 ]]; then
        echo "❌ No namespaces found or cannot access cluster"
        return 1
    fi

    local current_ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)
    current_ns=${current_ns:-default}

    echo "📁 Available Namespaces:"
    echo "========================"

    # Display namespaces with numbers
    for i in {1..${#namespaces[@]}}; do
        local namespace="${namespaces[$i]}"
        if [[ "$current_ns" == "$namespace" ]]; then
            echo "$i) $namespace (current)"
        else
            echo "$i) $namespace"
        fi
    done

    echo ""

    # Get user selection
    read "selection?Select namespace (1-${#namespaces[@]}): "

    # Validate selection
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt ${#namespaces[@]} ]]; then
        echo "❌ Invalid selection"
        return 1
    fi

    # Set selected namespace
    local selected_ns="${namespaces[$selection]}"
    kubectl config set-context --current --namespace="$selected_ns"

    if [[ $? -eq 0 ]]; then
        echo "✅ Switched to namespace: $selected_ns"
    else
        echo "❌ Failed to switch namespace"
        return 1
    fi
}

# ==========================================
# KUBERNETES RESOURCE HELPERS
# ==========================================

# Enhanced pod listing with useful information
kpods() {
    local namespace="$1"
    local selector="$2"

    local cmd="kubectl get pods"

    if [[ -n "$namespace" ]]; then
        cmd="$cmd -n $namespace"
    fi

    if [[ -n "$selector" ]]; then
        cmd="$cmd -l $selector"
    fi

    cmd="$cmd -o wide"

    echo "🚀 Kubernetes Pods:"
    echo "=================="
    eval "$cmd"

    # Show summary
    local total_pods=$(eval "$cmd --no-headers 2>/dev/null | wc -l | tr -d ' '")
    local running_pods=$(eval "$cmd --no-headers 2>/dev/null | grep Running | wc -l | tr -d ' '")
    local pending_pods=$(eval "$cmd --no-headers 2>/dev/null | grep Pending | wc -l | tr -d ' '")
    local failed_pods=$(eval "$cmd --no-headers 2>/dev/null | grep -E 'Failed|Error|CrashLoopBackOff' | wc -l | tr -d ' '")

    echo ""
    echo "📊 Summary: $total_pods total, $running_pods running, $pending_pods pending, $failed_pods failed"
}

# Get pod logs with enhanced options
klogs() {
    local pod="$1"
    local container="$2"
    local namespace="$3"
    local lines="${4:-100}"

    if [[ -z "$pod" ]]; then
        echo "Usage: klogs <pod_name> [container] [namespace] [lines]"
        echo ""
        echo "Available pods:"
        kubectl get pods -o name | sed 's|pod/||'
        return 1
    fi

    local cmd="kubectl logs"

    if [[ -n "$namespace" ]]; then
        cmd="$cmd -n $namespace"
    fi

    cmd="$cmd --tail=$lines"

    if [[ -n "$container" ]]; then
        cmd="$cmd -c $container"
    fi

    cmd="$cmd $pod"

    echo "📄 Logs for pod: $pod"
    if [[ -n "$container" ]]; then
        echo "Container: $container"
    fi
    if [[ -n "$namespace" ]]; then
        echo "Namespace: $namespace"
    fi
    echo "Lines: $lines"
    echo "===================="

    # Add follow option
    read "follow?Follow logs? (y/N): "
    if [[ "$follow" =~ ^[Yy]$ ]]; then
        cmd="$cmd -f"
    fi

    eval "$cmd"
}

# Execute command in pod
kexec() {
    local pod="$1"
    local cmd="${2:-/bin/bash}"
    local namespace="$3"

    if [[ -z "$pod" ]]; then
        echo "Usage: kexec <pod_name> [command] [namespace]"
        echo ""
        echo "Available pods:"
        kubectl get pods -o name | sed 's|pod/||'
        return 1
    fi

    local kubectl_cmd="kubectl exec -it"

    if [[ -n "$namespace" ]]; then
        kubectl_cmd="$kubectl_cmd -n $namespace"
    fi

    kubectl_cmd="$kubectl_cmd $pod -- $cmd"

    echo "🐚 Executing in pod: $pod"
    echo "Command: $cmd"
    echo "====================="

    eval "$kubectl_cmd"
}

# ==========================================
# KUBERNETES CLUSTER OPERATIONS
# ==========================================

# Cluster health check
k8s-health() {
    echo "🏥 Kubernetes Cluster Health Check:"
    echo "==================================="

    # Check API server
    if kubectl cluster-info &>/dev/null; then
        echo "✅ API Server: Accessible"
    else
        echo "❌ API Server: Not accessible"
        return 1
    fi

    # Check nodes
    echo ""
    echo "🖥️  Node Status:"
    kubectl get nodes -o wide

    local total_nodes=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
    local ready_nodes=$(kubectl get nodes --no-headers 2>/dev/null | grep " Ready " | wc -l | tr -d ' ')

    echo ""
    echo "📊 Nodes: $ready_nodes/$total_nodes ready"

    # Check system pods
    echo ""
    echo "🔧 System Pods Status:"
    kubectl get pods -n kube-system | grep -v Running | head -10

    local total_system_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | wc -l | tr -d ' ')
    local running_system_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null | grep Running | wc -l | tr -d ' ')

    echo ""
    echo "📊 System Pods: $running_system_pods/$total_system_pods running"

    # Check cluster resources
    echo ""
    echo "📊 Cluster Resource Usage:"
    kubectl top nodes 2>/dev/null || echo "⚠️  Metrics server not available"
}

# Get cluster information
k8s-info() {
    echo "☸️  Kubernetes Cluster Information:"
    echo "==================================="

    # Basic cluster info
    kubectl cluster-info

    echo ""
    echo "📋 Kubernetes Version:"
    kubectl version --short 2>/dev/null || kubectl version --client

    echo ""
    echo "🏷️  API Resources:"
    kubectl api-resources --verbs=list --namespaced -o name | head -20
    echo "... (showing first 20, use 'kubectl api-resources' for full list)"

    echo ""
    echo "📊 Resource Quotas and Limits:"
    kubectl describe limitranges 2>/dev/null | head -20
}

# ==========================================
# KUBERNETES TROUBLESHOOTING
# ==========================================

# Find problematic pods
k8s-problems() {
    echo "🔍 Finding Problematic Pods:"
    echo "============================"

    # Failed pods
    echo "❌ Failed Pods:"
    kubectl get pods --all-namespaces --field-selector=status.phase=Failed

    echo ""
    echo "🔄 Pending Pods:"
    kubectl get pods --all-namespaces --field-selector=status.phase=Pending

    echo ""
    echo "🚨 CrashLoopBackOff Pods:"
    kubectl get pods --all-namespaces | grep CrashLoopBackOff

    echo ""
    echo "⚠️  High Restart Count Pods:"
    kubectl get pods --all-namespaces --sort-by='.status.containerStatuses[0].restartCount' | tail -10
}

# Describe pod with events
kdesc() {
    local resource="$1"
    local name="$2"
    local namespace="$3"

    if [[ -z "$resource" ]] || [[ -z "$name" ]]; then
        echo "Usage: kdesc <resource_type> <resource_name> [namespace]"
        echo "Example: kdesc pod my-pod"
        echo "Example: kdesc deployment my-app production"
        return 1
    fi

    local cmd="kubectl describe $resource $name"

    if [[ -n "$namespace" ]]; then
        cmd="$cmd -n $namespace"
    fi

    echo "📋 Describing $resource: $name"
    if [[ -n "$namespace" ]]; then
        echo "Namespace: $namespace"
    fi
    echo "=========================="

    eval "$cmd"
}

# Get events for troubleshooting
kevents() {
    local namespace="$1"

    local cmd="kubectl get events --sort-by='.lastTimestamp'"

    if [[ -n "$namespace" ]]; then
        cmd="$cmd -n $namespace"
    else
        cmd="$cmd --all-namespaces"
    fi

    echo "📅 Recent Kubernetes Events:"
    echo "============================"
    eval "$cmd" | tail -20
}

# ==========================================
# KUBERNETES SECURITY
# ==========================================

# Check RBAC permissions
k8s-can-i() {
    local action="$1"
    local resource="$2"
    local namespace="$3"

    if [[ -z "$action" ]] || [[ -z "$resource" ]]; then
        echo "Usage: k8s-can-i <action> <resource> [namespace]"
        echo "Example: k8s-can-i get pods"
        echo "Example: k8s-can-i create deployments production"
        return 1
    fi

    local cmd="kubectl auth can-i $action $resource"

    if [[ -n "$namespace" ]]; then
        cmd="$cmd -n $namespace"
    fi

    echo "🔐 Checking permissions:"
    echo "Action: $action"
    echo "Resource: $resource"
    if [[ -n "$namespace" ]]; then
        echo "Namespace: $namespace"
    fi
    echo "======================="

    if eval "$cmd"; then
        echo "✅ Permission granted"
    else
        echo "❌ Permission denied"
        return 1
    fi
}

# List service accounts
k8s-service-accounts() {
    local namespace="$1"

    local cmd="kubectl get serviceaccounts"

    if [[ -n "$namespace" ]]; then
        cmd="$cmd -n $namespace"
    else
        cmd="$cmd --all-namespaces"
    fi

    echo "👤 Service Accounts:"
    echo "==================="
    eval "$cmd"
}

# Check pod security contexts
k8s-security-contexts() {
    local namespace="$1"

    echo "🔒 Pod Security Contexts:"
    echo "========================"

    local cmd="kubectl get pods"
    if [[ -n "$namespace" ]]; then
        cmd="$cmd -n $namespace"
    fi

    # Get pod names and check their security contexts
    local pods=$(eval "$cmd -o name 2>/dev/null | sed 's|pod/||'")

    for pod in $pods; do
        local security_context=$(kubectl get pod "$pod" -o jsonpath='{.spec.securityContext}' 2>/dev/null)
        local privileged=$(kubectl get pod "$pod" -o jsonpath='{.spec.containers[*].securityContext.privileged}' 2>/dev/null)

        echo "Pod: $pod"
        if [[ "$privileged" == "true" ]]; then
            echo "  ⚠️  Privileged: Yes"
        else
            echo "  ✅ Privileged: No"
        fi

        if [[ -n "$security_context" && "$security_context" != "{}" ]]; then
            echo "  Security Context: $security_context"
        else
            echo "  Security Context: Default"
        fi
        echo ""
    done
}

# ==========================================
# KUBERNETES UTILITIES
# ==========================================

# Port forward with automatic cleanup
kport() {
    local pod="$1"
    local local_port="$2"
    local pod_port="$3"
    local namespace="$4"

    if [[ -z "$pod" ]] || [[ -z "$local_port" ]] || [[ -z "$pod_port" ]]; then
        echo "Usage: kport <pod_name> <local_port> <pod_port> [namespace]"
        echo "Example: kport my-app 8080 80"
        return 1
    fi

    local cmd="kubectl port-forward"

    if [[ -n "$namespace" ]]; then
        cmd="$cmd -n $namespace"
    fi

    cmd="$cmd $pod $local_port:$pod_port"

    echo "🔌 Port forwarding:"
    echo "Pod: $pod"
    echo "Local port: $local_port"
    echo "Pod port: $pod_port"
    if [[ -n "$namespace" ]]; then
        echo "Namespace: $namespace"
    fi
    echo "======================"
    echo "Press Ctrl+C to stop"

    eval "$cmd"
}

# Copy files to/from pod
kcopy() {
    local source="$1"
    local destination="$2"
    local namespace="$3"

    if [[ -z "$source" ]] || [[ -z "$destination" ]]; then
        echo "Usage: kcopy <source> <destination> [namespace]"
        echo "Copy from pod: kcopy pod:/path/to/file ./local/file"
        echo "Copy to pod: kcopy ./local/file pod:/path/to/file"
        return 1
    fi

    local cmd="kubectl cp $source $destination"

    if [[ -n "$namespace" ]]; then
        cmd="$cmd -n $namespace"
    fi

    echo "📁 Copying files:"
    echo "Source: $source"
    echo "Destination: $destination"
    if [[ -n "$namespace" ]]; then
        echo "Namespace: $namespace"
    fi
    echo "======================"

    eval "$cmd"

    if [[ $? -eq 0 ]]; then
        echo "✅ Copy completed"
    else
        echo "❌ Copy failed"
        return 1
    fi
}

# Apply with dry-run option
kapply() {
    local file="$1"
    local namespace="$2"

    if [[ -z "$file" ]]; then
        echo "Usage: kapply <yaml_file> [namespace]"
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        echo "❌ File not found: $file"
        return 1
    fi

    local cmd="kubectl apply -f $file"

    if [[ -n "$namespace" ]]; then
        cmd="$cmd -n $namespace"
    fi

    echo "📄 Applying Kubernetes manifest: $file"
    if [[ -n "$namespace" ]]; then
        echo "Namespace: $namespace"
    fi
    echo "========================================"

    # Show what would be applied
    echo "🔍 Dry run (what would be applied):"
    eval "$cmd --dry-run=client"

    echo ""
    read "confirm?Apply these changes? (y/N): "
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        eval "$cmd"
        echo "✅ Applied successfully"
    else
        echo "❌ Apply cancelled"
    fi
}

# ==========================================
# KUBERNETES PROMPT INTEGRATION
# ==========================================

# Function to show current Kubernetes context in prompt
k8s_prompt_info() {
    if command -v kubectl &>/dev/null; then
        local context=$(kubectl config current-context 2>/dev/null)
        local namespace=$(kubectl config view --minify --output 'jsonpath={..namespace}' 2>/dev/null)

        if [[ -n "$context" ]]; then
            if [[ -n "$namespace" && "$namespace" != "default" ]]; then
                echo " k8s:$context/$namespace"
            else
                echo " k8s:$context"
            fi
        fi
    fi
}