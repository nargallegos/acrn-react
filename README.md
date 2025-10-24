# ACRN Tinnitus Protocol Implementation

This is a React-based implementation of the Acoustic Coordinated Reset (ACRN) neuromodulation tinnitus treatment protocol. The goal of this project is to provide a web-based tool for individuals to try the ACRN protocol.

The live website can be found at: [https://acrn.cele.rocks](https://acrn.cele.rocks)

## Forked From

This repository was originally forked from [https://github.com/headphonejames/acrn-react](https://github.com/headphonejames/acrn-react).

## What is ACRN?

Acoustic Coordinated Reset (ACRN) neuromodulation is a tinnitus treatment protocol that involves listening to a sequence of tones that are tailored to the individual's tinnitus frequency. The goal of the protocol is to disrupt the pathological synchrony in the auditory cortex that is thought to be the cause of tinnitus.

## Getting Started

To run this project locally, you will need to have Node.js and npm installed.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/nargallegs/acrn-react.git
    cd acrn-react
    ```

2.  **Install dependencies:**
    ```bash
    npm install
    ```

3.  **Start the development server:**
    ```bash
    npm start
    ```
    This will open the project in your web browser at `http://localhost:3000`.

## Building and Deploying

### Local Build

To build the project for production, run the following command:

```bash
npm run build
```

This will create a `build` directory with the optimized and minified files. You can then deploy the contents of this directory to your web server.

For more information on deployment, please refer to the [Create React App deployment documentation](https://facebook.github.io/create-react-app/docs/deployment).

### AWS Deployment with Terraform

This project includes Infrastructure as Code (IaC) using Terraform to deploy to AWS App Runner with a custom domain.

**🔐 Modern IAM Setup - No Access Keys Required!**

This project uses AWS IAM roles with temporary credentials following current security best practices:
- ✅ No long-lived access keys
- ✅ Least privilege permissions
- ✅ OIDC support for CI/CD
- ✅ AWS SSO/IAM Identity Center compatible

#### Quick Start

```bash
cd terraform/

# Configure your variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# Initial deployment (requires admin access)
terraform init
terraform apply

# Get deployment instructions
terraform output deployment_instructions
```

#### Deployment Options

1. **Local Development** - Use AWS CLI with assumed roles
2. **AWS SSO/IAM Identity Center** - Recommended for teams
3. **GitHub Actions OIDC** - Zero secrets CI/CD

See detailed guides:
- [IAM Setup Guide](terraform/IAM-SETUP.md)
- [Deployment Guide](terraform/DEPLOYMENT.md)
- [IAM Reference](terraform/IAM-REFERENCE.md)

#### What Gets Deployed

- AWS App Runner service running the React app
- Route53 DNS records for custom domain
- IAM roles for secure access (no access keys!)
- Custom domain association with SSL/TLS

#### Infrastructure Includes

- `terraform/main.tf` - Terraform configuration
- `terraform/apprunner.tf` - App Runner service
- `terraform/route53.tf` - DNS configuration
- `terraform/iam.tf` - IAM roles and policies (secure deployment)
- `Dockerfile` - Container configuration

## Disclaimer

This is not a medical device and is not intended to be used for the diagnosis or treatment of any medical condition. This is an experimental implementation of the ACRN protocol and has not been clinically tested. Please consult with a medical professional before using this tool.