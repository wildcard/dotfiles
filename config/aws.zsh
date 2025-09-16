#!/usr/bin/env zsh

# ==========================================
# SECURE DOTFILES - AWS CONFIGURATION
# ==========================================
# AWS profile management and utilities
# Security-focused with MFA support

# ==========================================
# AWS PROFILE SWITCHER
# ==========================================

# Interactive AWS profile switcher
aws-switch() {
    if ! command -v aws &>/dev/null; then
        echo "❌ AWS CLI not installed"
        return 1
    fi

    # Get available profiles
    local profiles=($(aws configure list-profiles 2>/dev/null))

    if [[ ${#profiles[@]} -eq 0 ]]; then
        echo "❌ No AWS profiles configured"
        echo "Configure a profile with: aws configure --profile <profile_name>"
        return 1
    fi

    echo "🔧 Available AWS Profiles:"
    echo "========================="

    # Display profiles with numbers
    for i in {1..${#profiles[@]}}; do
        local profile="${profiles[$i]}"
        if [[ "$AWS_PROFILE" == "$profile" ]]; then
            echo "$i) $profile (current)"
        else
            echo "$i) $profile"
        fi
    done

    echo "0) Clear profile (use default)"
    echo ""

    # Get user selection
    read "selection?Select profile (0-${#profiles[@]}): "

    # Validate selection
    if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
        echo "❌ Invalid selection"
        return 1
    fi

    if [[ "$selection" -eq 0 ]]; then
        # Clear profile
        unset AWS_PROFILE
        unset AWS_DEFAULT_PROFILE
        echo "✅ AWS profile cleared (using default)"
    elif [[ "$selection" -ge 1 && "$selection" -le ${#profiles[@]} ]]; then
        # Set selected profile
        local selected_profile="${profiles[$selection]}"
        export AWS_PROFILE="$selected_profile"
        export AWS_DEFAULT_PROFILE="$selected_profile"
        echo "✅ AWS profile set to: $selected_profile"

        # Show current identity
        aws-whoami
    else
        echo "❌ Invalid selection"
        return 1
    fi

    # Update prompt if using robbyrussell theme
    if [[ -n "$ZSH_THEME" ]]; then
        # Trigger prompt refresh
        zle && zle reset-prompt
    fi
}

# ==========================================
# AWS UTILITIES
# ==========================================

# Show current AWS identity
aws-whoami() {
    if ! command -v aws &>/dev/null; then
        echo "❌ AWS CLI not installed"
        return 1
    fi

    echo "🔍 Current AWS Identity:"
    echo "======================="

    if [[ -n "$AWS_PROFILE" ]]; then
        echo "Profile: $AWS_PROFILE"
    else
        echo "Profile: default"
    fi

    # Try to get caller identity
    local identity=$(aws sts get-caller-identity 2>/dev/null)
    if [[ $? -eq 0 ]]; then
        echo "Account: $(echo $identity | jq -r '.Account // "Unknown"')"
        echo "User/Role: $(echo $identity | jq -r '.Arn // "Unknown"')"
        echo "User ID: $(echo $identity | jq -r '.UserId // "Unknown"')"
    else
        echo "❌ Unable to get caller identity (check credentials/permissions)"
        return 1
    fi
}

# List AWS regions
aws-regions() {
    if ! command -v aws &>/dev/null; then
        echo "❌ AWS CLI not installed"
        return 1
    fi

    echo "🌍 AWS Regions:"
    echo "=============="
    aws ec2 describe-regions --query 'Regions[].RegionName' --output table
}

# Set AWS region
aws-region() {
    local region="$1"

    if [[ -z "$region" ]]; then
        echo "Current region: ${AWS_DEFAULT_REGION:-$(aws configure get region)}"
        echo ""
        echo "Usage: aws-region <region_name>"
        echo "Example: aws-region us-west-2"
        echo ""
        echo "Available regions:"
        aws-regions
        return 1
    fi

    export AWS_DEFAULT_REGION="$region"
    echo "✅ AWS region set to: $region"
}

# ==========================================
# AWS MFA UTILITIES
# ==========================================

# Assume role with MFA
aws-assume-role() {
    local role_arn="$1"
    local session_name="${2:-AssumedRoleSession-$(date +%s)}"
    local mfa_device="$3"
    local duration="${4:-3600}"  # 1 hour default

    if [[ -z "$role_arn" ]]; then
        echo "Usage: aws-assume-role <role_arn> [session_name] [mfa_device] [duration_seconds]"
        echo "Example: aws-assume-role arn:aws:iam::123456789012:role/MyRole MySession arn:aws:iam::123456789012:mfa/user 3600"
        return 1
    fi

    local assume_command="aws sts assume-role --role-arn $role_arn --role-session-name $session_name --duration-seconds $duration"

    # Add MFA if device specified
    if [[ -n "$mfa_device" ]]; then
        read "mfa_code?Enter MFA code: "
        if [[ -z "$mfa_code" ]]; then
            echo "❌ MFA code required"
            return 1
        fi
        assume_command="$assume_command --serial-number $mfa_device --token-code $mfa_code"
    fi

    echo "🔐 Assuming role: $role_arn"

    # Execute assume role command
    local credentials=$(eval $assume_command 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to assume role"
        return 1
    fi

    # Extract credentials
    local access_key=$(echo $credentials | jq -r '.Credentials.AccessKeyId')
    local secret_key=$(echo $credentials | jq -r '.Credentials.SecretAccessKey')
    local session_token=$(echo $credentials | jq -r '.Credentials.SessionToken')
    local expiration=$(echo $credentials | jq -r '.Credentials.Expiration')

    # Set environment variables
    export AWS_ACCESS_KEY_ID="$access_key"
    export AWS_SECRET_ACCESS_KEY="$secret_key"
    export AWS_SESSION_TOKEN="$session_token"

    echo "✅ Role assumed successfully"
    echo "Expires: $expiration"
    echo ""
    echo "🔍 Current identity:"
    aws-whoami
}

# Clear assumed role credentials
aws-clear-session() {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN

    echo "✅ AWS session credentials cleared"

    if [[ -n "$AWS_PROFILE" ]]; then
        echo "Using profile: $AWS_PROFILE"
    else
        echo "Using default profile"
    fi
}

# ==========================================
# AWS SERVICE UTILITIES
# ==========================================

# List EC2 instances with useful information
aws-ec2-list() {
    local region="${1:-${AWS_DEFAULT_REGION}}"

    if [[ -z "$region" ]]; then
        echo "Usage: aws-ec2-list [region]"
        echo "Set a default region with: aws-region <region>"
        return 1
    fi

    echo "🖥️  EC2 Instances in $region:"
    echo "=========================="

    aws ec2 describe-instances \
        --region "$region" \
        --query 'Reservations[].Instances[].[
            InstanceId,
            State.Name,
            InstanceType,
            PrivateIpAddress,
            PublicIpAddress,
            Tags[?Key==`Name`].Value|[0]
        ]' \
        --output table
}

# List S3 buckets
aws-s3-list() {
    echo "🪣 S3 Buckets:"
    echo "============="
    aws s3 ls
}

# Get S3 bucket size
aws-s3-size() {
    local bucket="$1"

    if [[ -z "$bucket" ]]; then
        echo "Usage: aws-s3-size <bucket_name>"
        return 1
    fi

    echo "📊 Calculating size for bucket: $bucket"
    aws s3 ls "s3://$bucket" --recursive --summarize --human-readable | grep "Total Size"
}

# List Lambda functions
aws-lambda-list() {
    local region="${1:-${AWS_DEFAULT_REGION}}"

    if [[ -z "$region" ]]; then
        echo "Usage: aws-lambda-list [region]"
        return 1
    fi

    echo "⚡ Lambda Functions in $region:"
    echo "============================="

    aws lambda list-functions \
        --region "$region" \
        --query 'Functions[].[FunctionName,Runtime,LastModified]' \
        --output table
}

# ==========================================
# AWS COST UTILITIES
# ==========================================

# Get AWS costs for current month
aws-costs() {
    local start_date=$(date -d "$(date +'%Y-%m-01')" +'%Y-%m-%d' 2>/dev/null || date -j -f "%Y-%m-%d" "$(date +'%Y-%m-01')" +'%Y-%m-%d')
    local end_date=$(date +'%Y-%m-%d')

    echo "💰 AWS Costs for current month ($start_date to $end_date):"
    echo "========================================================"

    aws ce get-cost-and-usage \
        --time-period Start="$start_date",End="$end_date" \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --group-by Type=DIMENSION,Key=SERVICE \
        --query 'ResultsByTime[0].Groups[].[Keys[0],Metrics.BlendedCost.Amount]' \
        --output table
}

# ==========================================
# AWS SECURITY UTILITIES
# ==========================================

# List IAM users
aws-iam-users() {
    echo "👥 IAM Users:"
    echo "============"
    aws iam list-users --query 'Users[].[UserName,CreateDate,PasswordLastUsed]' --output table
}

# List IAM roles
aws-iam-roles() {
    echo "🎭 IAM Roles:"
    echo "============"
    aws iam list-roles --query 'Roles[].[RoleName,CreateDate,Description]' --output table
}

# Check IAM password policy
aws-iam-password-policy() {
    echo "🔒 IAM Password Policy:"
    echo "======================"
    aws iam get-account-password-policy --output table 2>/dev/null || echo "No password policy configured"
}

# ==========================================
# AWS RESOURCE CLEANUP
# ==========================================

# Find unused security groups
aws-sg-unused() {
    local region="${1:-${AWS_DEFAULT_REGION}}"

    if [[ -z "$region" ]]; then
        echo "Usage: aws-sg-unused [region]"
        return 1
    fi

    echo "🔍 Finding unused security groups in $region..."

    # Get all security groups
    local all_sgs=$(aws ec2 describe-security-groups --region "$region" --query 'SecurityGroups[].GroupId' --output text)

    # Get security groups in use
    local used_sgs=$(aws ec2 describe-instances --region "$region" --query 'Reservations[].Instances[].SecurityGroups[].GroupId' --output text)
    used_sgs="$used_sgs $(aws elbv2 describe-load-balancers --region "$region" --query 'LoadBalancers[].SecurityGroups[]' --output text 2>/dev/null)"
    used_sgs="$used_sgs $(aws rds describe-db-instances --region "$region" --query 'DBInstances[].VpcSecurityGroups[].VpcSecurityGroupId' --output text 2>/dev/null)"

    echo "🗑️  Potentially unused security groups:"
    echo "======================================"

    for sg in $all_sgs; do
        if [[ ! "$used_sgs" =~ "$sg" ]]; then
            aws ec2 describe-security-groups --region "$region" --group-ids "$sg" --query 'SecurityGroups[].[GroupId,GroupName,Description]' --output table
        fi
    done
}

# ==========================================
# AWS PROMPT INTEGRATION
# ==========================================

# Function to show AWS profile in prompt
aws_prompt_info() {
    if [[ -n "$AWS_PROFILE" ]]; then
        echo " aws:$AWS_PROFILE"
    fi
}

# ==========================================
# AWS CONFIGURATION VALIDATION
# ==========================================

# Validate AWS configuration
aws-validate() {
    echo "🔍 Validating AWS Configuration:"
    echo "================================"

    # Check AWS CLI installation
    if ! command -v aws &>/dev/null; then
        echo "❌ AWS CLI not installed"
        return 1
    fi

    echo "✅ AWS CLI installed: $(aws --version | cut -d' ' -f1)"

    # Check credentials
    if aws sts get-caller-identity &>/dev/null; then
        echo "✅ AWS credentials configured"
        aws-whoami
    else
        echo "❌ AWS credentials not configured or invalid"
        echo "Configure with: aws configure"
        return 1
    fi

    # Check jq availability (useful for JSON processing)
    if command -v jq &>/dev/null; then
        echo "✅ jq available for JSON processing"
    else
        echo "⚠️  jq not available (recommended for better JSON handling)"
        echo "Install with: brew install jq (macOS) or apt install jq (Linux)"
    fi

    echo ""
    echo "🔧 Configuration files:"
    echo "======================"
    [[ -f "$HOME/.aws/config" ]] && echo "✅ Config: $HOME/.aws/config" || echo "❌ Config file missing"
    [[ -f "$HOME/.aws/credentials" ]] && echo "✅ Credentials: $HOME/.aws/credentials" || echo "❌ Credentials file missing"
}

# ==========================================
# LOAD AWS COMPLETION
# ==========================================

# Enable AWS CLI completion if available
if command -v aws_completer &>/dev/null; then
    complete -C aws_completer aws
fi