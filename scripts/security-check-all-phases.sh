#!/bin/bash

# Security Check - All Phases
# Verifies no sensitive information is about to be committed
# Applies to all phases (Phase 1, 2, 3)
# Usage: ./scripts/security-check-all-phases.sh

set -e

echo "=========================================="
echo "Security Check - Pre-Commit Verification"
echo "=========================================="
echo ""

FAILED=0

# Check for AWS account IDs (pattern: 12 digits)
echo "Checking for hardcoded AWS account IDs..."
if grep -r "[0-9]\{12\}" . --exclude-dir=.git --exclude-dir=.terraform --exclude-dir=target --exclude="*.tfstate*" --exclude="outputs.json" --exclude="*.md" --exclude="*.sh" 2>/dev/null | grep -v "YOUR_AWS_ACCOUNT_ID" | grep -v ".example"; then
    echo "⚠ WARNING: Possible AWS account IDs found"
    FAILED=$((FAILED + 1))
else
    echo "✓ No hardcoded AWS account IDs found"
fi

echo ""

# Check for AWS access keys (exclude documentation)
echo "Checking for AWS access keys..."
if grep -r "AKIA" . --exclude-dir=.git --exclude-dir=.terraform --exclude="*.md" --exclude="*.sh" 2>/dev/null; then
    echo "✗ FAILED: AWS access keys found!"
    FAILED=$((FAILED + 1))
else
    echo "✓ No AWS access keys found"
fi

echo ""

# Check for private keys
echo "Checking for private keys..."
if find . -name "*.key" -o -name "*.pem" | grep -v ".terraform" | grep -v ".git"; then
    echo "✗ FAILED: Private keys found!"
    FAILED=$((FAILED + 1))
else
    echo "✓ No private keys found"
fi

echo ""

# Check for terraform.tfvars
echo "Checking for terraform.tfvars..."
if [ -f "terraform/terraform.tfvars" ]; then
    if git check-ignore terraform/terraform.tfvars > /dev/null 2>&1; then
        echo "✓ terraform.tfvars is properly ignored"
    else
        echo "✗ FAILED: terraform.tfvars is not in .gitignore!"
        FAILED=$((FAILED + 1))
    fi
else
    echo "⚠ terraform.tfvars not found (this is OK if using environment variables)"
fi

echo ""

# Check for .env files
echo "Checking for .env files..."
if find . -name ".env*" -not -path "./.git/*" -not -path "./.terraform/*" | grep -v ".example"; then
    echo "✗ FAILED: .env files found!"
    FAILED=$((FAILED + 1))
else
    echo "✓ No .env files found"
fi

echo ""

# Check for kubeconfig
echo "Checking for kubeconfig files..."
if find . -name "kubeconfig*" -not -path "./.git/*" -not -path "./.terraform/*" -not -path "./docs/*" 2>/dev/null | grep -v "^$"; then
    echo "✗ FAILED: kubeconfig files found!"
    FAILED=$((FAILED + 1))
else
    echo "✓ No kubeconfig files found"
fi

echo ""

# Check GitHub Actions workflow for hardcoded values
echo "Checking GitHub Actions workflow..."
if grep -r "role-to-assume.*444625565163\|role-to-assume.*[0-9]\{12\}" .github/ 2>/dev/null | grep -v "YOUR_AWS_ACCOUNT_ID"; then
    echo "✗ FAILED: Hardcoded account IDs in GitHub Actions workflow!"
    FAILED=$((FAILED + 1))
else
    echo "✓ GitHub Actions workflow uses variables"
fi

echo ""

# Check Helm values
echo "Checking Helm values..."
if grep -r "registry.*[0-9]\{12\}" helm/ 2>/dev/null | grep -v "YOUR_AWS_ACCOUNT_ID"; then
    echo "✗ FAILED: Hardcoded account IDs in Helm values!"
    FAILED=$((FAILED + 1))
else
    echo "✓ Helm values use variables"
fi

echo ""
echo "=========================================="

if [ $FAILED -eq 0 ]; then
    echo "✓ All security checks passed!"
    echo "✓ Safe to commit and push to GitHub"
    echo "=========================================="
    exit 0
else
    echo "✗ Security checks failed!"
    echo "✗ DO NOT commit until issues are resolved"
    echo "=========================================="
    exit 1
fi
