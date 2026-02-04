# Documentation Guide - Find What You Need

Quick reference to help you find the right documentation for your task.

## 🎯 By User Role

### I'm a New Developer Setting Up Locally
1. Start with **[README.md](README.md)** - Project overview
2. Follow **[SETUP.md](SETUP.md)** - Complete setup guide
3. Review **[SECURITY.md](SECURITY.md)** - Before pushing to GitHub
4. Read **[CONTRIBUTING.md](CONTRIBUTING.md)** - Development guidelines

### I'm Deploying to Production
1. Read **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Complete deployment steps
2. Reference **[terraform/EKS_DEPLOYMENT_GUIDE.md](terraform/EKS_DEPLOYMENT_GUIDE.md)** - EKS details
3. Follow **[E2E_TEST_PLAN.md](E2E_TEST_PLAN.md)** - Testing procedures
4. Check **[CI_CD_WORKFLOW_SUMMARY.md](CI_CD_WORKFLOW_SUMMARY.md)** - Pipeline details

### I'm Reviewing Security
1. Start with **[SECURITY.md](SECURITY.md)** - Security overview and checklist
2. Follow pre-commit checklist before pushing
3. Review best practices section

### I'm Contributing Code
1. Read **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
2. Follow **[SETUP.md](SETUP.md)** - Local setup
3. Check **[CI_CD_WORKFLOW_SUMMARY.md](CI_CD_WORKFLOW_SUMMARY.md)** - Pipeline validation

### I'm Troubleshooting an Issue
1. Check **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Troubleshooting section
2. Review **[terraform/EKS_DEPLOYMENT_GUIDE.md](terraform/EKS_DEPLOYMENT_GUIDE.md)** - EKS troubleshooting
3. Check **[E2E_TEST_PLAN.md](E2E_TEST_PLAN.md)** - Test procedures

---

## 🔍 By Task

### Setting Up AWS Account
- **[SETUP.md](SETUP.md)** - AWS Configuration section
- Get AWS account ID
- Configure AWS credentials
- Verify configuration

### Configuring GitHub
- **[SETUP.md](SETUP.md)** - GitHub Configuration section
- Add GitHub Secrets
- Verify secrets are set

### Creating terraform/terraform.tfvars
- **[SETUP.md](SETUP.md)** - Initial Setup section
- Copy from `.example` file
- Fill in your values
- Verify configuration

### Deploying Infrastructure
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Infrastructure Deployment section
- Run Terraform init
- Run Terraform plan
- Run Terraform apply

### Deploying Microservice
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Microservice Deployment section
- Build Docker image
- Push to ECR
- Deploy with Helm

### Running Tests
- **[E2E_TEST_PLAN.md](E2E_TEST_PLAN.md)** - Test procedures
- Unit tests
- Integration tests
- Smoke tests

### Checking Security Before Push
- **[SECURITY.md](SECURITY.md)** - Pre-Commit Security Checklist
- Run security check script
- Review git status
- Verify .gitignore

### Fixing Credentials Leak
- **[SECURITY.md](SECURITY.md)** - If You Accidentally Commit Secrets section
- Rotate credentials
- Remove from git history
- Update GitHub Secrets

### Understanding the Pipeline
- **[CI_CD_WORKFLOW_SUMMARY.md](CI_CD_WORKFLOW_SUMMARY.md)** - Pipeline overview
- Workflow stages
- Trigger conditions
- Troubleshooting

### Understanding Architecture
- **[PROJECT_SUMMARY.md](PROJECT_SUMMARY.md)** - Architecture overview
- Component descriptions
- Design decisions

---

## 📚 File Descriptions

| File | Purpose | Audience | Length |
|------|---------|----------|--------|
| **README.md** | Project overview and quick start | Everyone | 5 min |
| **SETUP.md** | Setup and configuration guide | New developers | 20 min |
| **SECURITY.md** | Security best practices and checklist | All developers | 15 min |
| **DEPLOYMENT_GUIDE.md** | Complete deployment instructions | DevOps/Deployment | 30 min |
| **CONTRIBUTING.md** | Contribution guidelines | Contributors | 10 min |
| **E2E_TEST_PLAN.md** | End-to-end testing procedures | QA/Testers | 15 min |
| **CI_CD_WORKFLOW_SUMMARY.md** | GitHub Actions pipeline details | DevOps/Developers | 10 min |
| **PROJECT_SUMMARY.md** | Project architecture and overview | Architects/Leads | 15 min |
| **terraform/EKS_DEPLOYMENT_GUIDE.md** | EKS-specific deployment guide | DevOps/Infrastructure | 20 min |

---

## 🚀 Quick Navigation

### First Time Setup (30 minutes)
```
README.md (5 min)
    ↓
SETUP.md (20 min)
    ↓
SECURITY.md - Pre-commit checklist (5 min)
```

### First Deployment (1 hour)
```
DEPLOYMENT_GUIDE.md (30 min)
    ↓
terraform/EKS_DEPLOYMENT_GUIDE.md (20 min)
    ↓
E2E_TEST_PLAN.md (10 min)
```

### Before Pushing to GitHub (15 minutes)
```
SECURITY.md - Pre-commit checklist (10 min)
    ↓
Run security-check.sh (5 min)
```

### Troubleshooting (varies)
```
DEPLOYMENT_GUIDE.md - Troubleshooting section
    ↓
terraform/EKS_DEPLOYMENT_GUIDE.md - Troubleshooting section
    ↓
E2E_TEST_PLAN.md - Test procedures
```

---

## 🔗 Cross-References

### SETUP.md references
- README.md - Project overview
- SECURITY.md - Pre-push checklist
- DEPLOYMENT_GUIDE.md - Next steps

### SECURITY.md references
- SETUP.md - Configuration details
- .gitignore - Ignored files
- scripts/security-check.sh - Automated checks

### DEPLOYMENT_GUIDE.md references
- terraform/EKS_DEPLOYMENT_GUIDE.md - EKS details
- E2E_TEST_PLAN.md - Testing procedures
- CI_CD_WORKFLOW_SUMMARY.md - Pipeline details

### E2E_TEST_PLAN.md references
- DEPLOYMENT_GUIDE.md - Deployment steps
- CI_CD_WORKFLOW_SUMMARY.md - Pipeline details

### CI_CD_WORKFLOW_SUMMARY.md references
- DEPLOYMENT_GUIDE.md - Deployment steps
- E2E_TEST_PLAN.md - Testing procedures

---

## 💡 Tips

### Finding Information
- Use Ctrl+F to search within a file
- Check the table of contents at the top of each file
- Look for section headers that match your task

### Getting Help
- Check the Troubleshooting section in relevant guide
- Search for your error message in documentation
- Review the E2E_TEST_PLAN.md for test procedures

### Staying Updated
- Check documentation when things change
- Update documentation when you learn something new
- Share improvements with the team

---

## 📞 Still Need Help?

1. **Check the relevant guide** - Use this guide to find the right documentation
2. **Search for your issue** - Use Ctrl+F to search within files
3. **Review troubleshooting** - Most guides have troubleshooting sections
4. **Check E2E_TEST_PLAN.md** - Contains test procedures and validation steps
5. **Ask your team** - Reach out to team members for help

---

**Last Updated:** February 3, 2026
