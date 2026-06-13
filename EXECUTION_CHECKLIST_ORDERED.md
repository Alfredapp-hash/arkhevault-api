# Arkhe Vault - Ordered Execution Checklist

**Execute these steps in exact order. Do not skip ahead.**

---

## PHASE 0: COMPLETE REBRAND (Do This First)

### Step 1: Execute Terminal Commands (5 minutes)

Copy and paste these commands ONE AT A TIME into Terminal:

```bash
# Navigate to project directory
cd /Users/purduelaw/Desktop/ArkheApps/StudentTracker
```

```bash
# Rename root folder
mv ArkheVaultClientManager ArkheVault
```

```bash
# Enter renamed folder
cd ArkheVault
```

```bash
# Replace "Arkhe Vault" with "Arkhe Vault"
find . -type f \( -name "*.swift" -o -name "*.md" \) -exec sed -i '' 's/Arkhe Vault/Arkhe Vault/g' {} +
```

```bash
# Replace "ArkheVault" with "ArkheVault"
find . -type f \( -name "*.swift" -o -name "*.md" \) -exec sed -i '' 's/ArkheVault/ArkheVault/g' {} +
```

```bash
# Replace "arkhevault" with "arkhevault"
find . -type f \( -name "*.swift" -o -name "*.md" \) -exec sed -i '' 's/arkhevault/arkhevault/g' {} +
```

```bash
# Replace "ArkheButton" with "ArkheButton"
find . -type f -name "*.swift" -exec sed -i '' 's/ArkheButton/ArkheButton/g' {} +
```

```bash
# Replace "ArkheCard" with "ArkheCard"
find . -type f -name "*.swift" -exec sed -i '' 's/ArkheCard/ArkheCard/g' {} +
```

```bash
# Replace "ArkheLogo" with "ArkheLogo"
find . -type f -name "*.swift" -exec sed -i '' 's/ArkheLogo/ArkheLogo/g' {} +
```

```bash
# Rename main app file
mv App/ArkheVaultApp.swift App/ArkheVaultApp.swift 2>/dev/null; echo "Done"
```

```bash
# Rename button component
mv Shared/Components/ArkheButton.swift Shared/Components/ArkheButton.swift 2>/dev/null; echo "Done"
```

```bash
# Rename logo component
mv Shared/Components/ArkheLogo.swift Shared/Components/ArkheLogo.swift 2>/dev/null; echo "Done"
```

```bash
# Verify no "Arkhe Vault" remains
grep -r "Arkhe Vault" . --include="*.swift" --include="*.md" 2>/dev/null || echo "✅ No references found"
```

```bash
# Verify no "ArkheVault" remains
grep -r "ArkheVault" . --include="*.swift" --include="*.md" 2>/dev/null || echo "✅ No references found"
```

```bash
# Check new branding is present
grep "appName" Shared/Utilities/Branding.swift
```

**Expected output:** `static let appName = "Arkhe Vault"`

### Step 2: Open in IDE (1 minute)

```bash
# Open in VS Code
code /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVault

# OR open in Xcode
# open /Users/purduelaw/Desktop/ArkheApps/StudentTracker/ArkheVault/*.xcodeproj
```

### Step 3: Verify Build (5 minutes)

In Xcode:
1. Clean build folder (Cmd+Shift+K)
2. Build project (Cmd+B)
3. Verify no errors

**STOP HERE IF BUILD FAILS.** Fix errors before proceeding.

---

## PHASE 1A: AWS INFRASTRUCTURE SETUP (Do Before Coding)

### Step 4: Create AWS Account (15 minutes)

1. Go to https://aws.amazon.com
2. Click "Create an AWS Account"
3. Enter email: `your-email@domain.com`
4. Account name: `ArkheVault-Production`
5. Complete registration
6. **IMPORTANT:** Set up MFA on root account immediately
7. Go to Billing → Budgets → Create budget
   - Monthly budget: $500
   - Alert at 80% ($400)

### Step 5: Create IAM Admin User (10 minutes)

1. Sign in to AWS Console
2. Go to IAM (Identity and Access Management)
3. Click "Users" → "Create user"
4. Username: `arkhevault-admin`
5. Attach policies directly:
   - ☑️ AdministratorAccess
6. Create access key (CLI use)
   - Download credentials CSV
   - **SAVE SECURELY - CANNOT DOWNLOAD AGAIN**

### Step 6: Install AWS CLI (5 minutes)

```bash
# Download and install AWS CLI
brew install awscli

# Verify installation
aws --version

# Configure with your credentials
aws configure
# Enter:
# AWS Access Key ID: (from Step 5)
# AWS Secret Access Key: (from Step 5)
# Default region: us-east-1
# Default output: json
```

### Step 7: Create VPC (10 minutes)

```bash
# Create VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=ArkheVault-VPC}]'

# Note the VpcId from output (looks like vpc-xxxxxxxx)
# Save it: export VPC_ID=vpc-xxxxxxxx
```

### Step 8: Provision RDS PostgreSQL (15 minutes)

1. AWS Console → RDS → "Create database"
2. Choose database creation method: "Standard create"
3. Engine options:
   - Engine type: PostgreSQL
   - Engine version: 15.4
4. Templates: "Free tier" (for development)
5. Settings:
   - DB instance identifier: `arkhevault-dev`
   - Master username: `postgres`
   - Master password: `[generate strong password]`
6. Instance configuration:
   - DB instance class: `db.t3.micro`
7. Storage:
   - Storage type: gp2
   - Allocated storage: 20 GB
8. Connectivity:
   - VPC: Select your VPC from Step 7
   - Public access: Yes (for development)
9. Database authentication: Password authentication
10. Additional configuration:
    - Initial database name: `arkhevault`
11. Create database

**Save endpoint:** Looks like `arkhevault-dev.xxxxx.us-east-1.rds.amazonaws.com`

### Step 9: Provision Redis (ElastiCache) (10 minutes)

1. AWS Console → ElastiCache → "Get started"
2. Cluster engine: Redis
3. Location: AWS Cloud
4. Cluster settings:
   - Name: `arkhevault-redis`
   - Engine version: 7.0
5. Cluster mode: Disabled
6. Node type: cache.t3.micro (free tier eligible)
7. Number of replicas: 0
8. Subnet group: Create new
   - Name: `arkhevault-subnet-group`
   - VPC ID: Your VPC from Step 7
9. Create

### Step 10: Create S3 Bucket for Documents (5 minutes)

```bash
# Create bucket (replace 'yourname' with your name/company)
aws s3api create-bucket \
    --bucket arkhevault-documents-yourname \
    --region us-east-1

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket arkhevault-documents-yourname \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }'

# Block public access
aws s3api put-public-access-block \
    --bucket arkhevault-documents-yourname \
    --public-access-block-configuration '{
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }'
```

### Step 11: Save Environment Variables (5 minutes)

Create file: `~/arkhevault-env.sh`

```bash
#!/bin/bash
# Arkhe Vault Environment Variables

export NODE_ENV=development
export PORT=3000

# Database
export DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@arkhevault-dev.xxxxx.us-east-1.rds.amazonaws.com:5432/arkhevault"

# Redis
export REDIS_URL="redis://arkhevault-redis.xxxxx.cache.amazonaws.com:6379"

# S3
export AWS_S3_BUCKET="arkhevault-documents-yourname"
export AWS_REGION="us-east-1"

# Security
export JWT_SECRET="$(openssl rand -base64 32)"
export JWT_EXPIRES_IN="7d"
export BCRYPT_ROUNDS="12"

# AI (Claude)
export CLAUDE_API_KEY="your-anthropic-api-key"
export CLAUDE_RATE_LIMIT_PER_MINUTE="60"
export CLAUDE_RATE_LIMIT_PER_HOUR="1000"

echo "Environment variables loaded!"
```

**Make it executable:**
```bash
chmod +x ~/arkhevault-env.sh
```

---

## PHASE 1B: DEVELOPMENT ENVIRONMENT

### Step 12: Install Development Tools (10 minutes)

```bash
# Install Homebrew (if not installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js 20
brew install node@20
brew link node@20

# Verify
node --version  # Should show v20.x.x
npm --version

# Install Git (if not installed)
brew install git

# Install VS Code (if preferred)
brew install --cask visual-studio-code

# Install Postman (for API testing)
brew install --cask postman
```

### Step 13: Create GitHub Repository (5 minutes)

1. Go to https://github.com
2. Click "+" → "New repository"
3. Repository name: `arkhevault-api`
4. Description: `Backend API for Arkhe Vault - nonprofit case management SaaS`
5. Visibility: Private (for now)
6. ☑️ Initialize with README
7. Create repository

**Save the repo URL:** `https://github.com/YOUR_USERNAME/arkhevault-api`

### Step 14: Clone and Setup Project (10 minutes)

```bash
# Navigate to where you want the project
cd ~/Developer  # or wherever you keep projects

# Clone the repo
git clone https://github.com/YOUR_USERNAME/arkhevault-api.git

# Enter project
cd arkhevault-api

# Initialize Node.js project
npm init -y

# Install core dependencies
npm install express cors helmet morgan dotenv

# Install database & ORM
npm install prisma @prisma/client pg

# Install authentication
npm install jsonwebtoken bcryptjs

# Install validation
npm install zod

# Install utilities
npm install uuid date-fns

# Install dev dependencies
npm install -D typescript @types/node @types/express @types/cors @types/jsonwebtoken @types/bcryptjs @types/uuid ts-node nodemon jest @types/jest supertest @types/supertest

# Initialize TypeScript
npx tsc --init
```

### Step 15: Create Project Structure (10 minutes)

```bash
# Create directory structure
mkdir -p src/{config,controllers,middleware,models,routes,services,utils,types}
mkdir -p src/tests/{unit,integration}
mkdir -p prisma

# Create essential files
touch src/index.ts
touch src/app.ts
touch src/config/database.ts
touch src/config/redis.ts
touch src/types/index.ts

# Initialize Prisma
npx prisma init
```

### Step 16: Configure Prisma Schema (20 minutes)

Edit `prisma/schema.prisma`:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Organization {
  id                String   @id @default(uuid())
  name              String
  slug              String   @unique
  plan              String   @default("growth")
  status            String   @default("active")
  subscriptionStatus String  @default("trialing")
  trialEndsAt       DateTime?
  maxUsers          Int      @default(10)
  maxClients        Int      @default(500)
  maxStorageGb      Int      @default(10)
  settings          Json     @default("{}")
  createdAt         DateTime @default(now())
  updatedAt         DateTime @updatedAt

  users    User[]
  clients  Client[]
  programs Program[]
  safetyFlags SafetyFlag[]
  documents Document[]
  auditLogs AuditLog[]

  @@map("organizations")
}

model User {
  id            String   @id @default(uuid())
  organizationId String
  email         String   @unique
  passwordHash  String
  firstName     String?
  lastName      String?
  role          String   @default("staff")
  status        String   @default("active")
  lastLoginAt   DateTime?
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt

  organization Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  notes        ClientNote[]

  @@map("users")
}

model Client {
  id           String   @id @default(uuid())
  organizationId String
  firstName    String
  lastName     String
  email        String?
  phone        String?
  dateOfBirth  DateTime?
  address      String?
  emergencyContactName  String?
  emergencyContactPhone String?
  status       String   @default("active")
  riskLevel    String   @default("low")
  intakeDate   DateTime?
  notes        String?
  metadata     Json     @default("{}")
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  organization Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  notes        ClientNote[]
  enrollments  ProgramEnrollment[]
  safetyFlags  SafetyFlag[]
  documents    Document[]

  @@map("clients")
}

model ClientNote {
  id          String   @id @default(uuid())
  clientId    String
  authorId    String?
  content     String
  noteType    String   @default("general")
  isConfidential Boolean @default(false)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  client Client @relation(fields: [clientId], references: [id], onDelete: Cascade)
  author User?  @relation(fields: [authorId], references: [id])

  @@map("client_notes")
}

model Program {
  id          String   @id @default(uuid())
  organizationId String
  name        String
  description String?
  capacity    Int?
  status      String   @default("active")
  startDate   DateTime?
  endDate     DateTime?
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  organization Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  enrollments  ProgramEnrollment[]

  @@map("programs")
}

model ProgramEnrollment {
  id            String   @id @default(uuid())
  programId     String
  clientId      String
  enrollmentDate DateTime @default(now())
  status        String   @default("active")
  exitDate      DateTime?
  exitReason    String?
  outcomes      Json     @default("{}")
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt

  program Program @relation(fields: [programId], references: [id], onDelete: Cascade)
  client  Client  @relation(fields: [clientId], references: [id], onDelete: Cascade)

  @@unique([programId, clientId])
  @@map("program_enrollments")
}

model SafetyFlag {
  id           String   @id @default(uuid())
  organizationId String
  clientId     String
  flaggedBy    String?
  flagType     String
  severity     String   @default("medium")
  description  String
  status       String   @default("open")
  resolvedBy   String?
  resolvedAt   DateTime?
  resolutionNotes String?
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  organization Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  client       Client       @relation(fields: [clientId], references: [id], onDelete: Cascade)

  @@map("safety_flags")
}

model Document {
  id              String   @id @default(uuid())
  organizationId  String
  clientId        String?
  uploadedBy      String?
  filename        String
  originalFilename String
  fileSize        Int?
  mimeType        String?
  storageKey      String
  documentType    String?
  description     String?
  isEncrypted     Boolean  @default(true)
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt

  organization Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)
  client       Client?      @relation(fields: [clientId], references: [id], onDelete: SetNull)

  @@map("documents")
}

model AuditLog {
  id             String   @id @default(uuid())
  organizationId String
  userId         String?
  action         String
  entityType     String
  entityId       String?
  metadata       Json     @default("{}")
  ipAddress      String?
  userAgent      String?
  createdAt      DateTime @default(now())

  organization Organization @relation(fields: [organizationId], references: [id], onDelete: Cascade)

  @@map("audit_logs")
  @@index([organizationId])
  @@index([createdAt])
}
```

### Step 17: Run Initial Migration (5 minutes)

```bash
# Load environment variables
source ~/arkhevault-env.sh

# Generate Prisma client
npx prisma generate

# Run migration
npx prisma migrate dev --name init

# Verify tables created
npx prisma studio
```

---

## PHASE 1C: API DEVELOPMENT

### Step 18: Create Basic Express App (20 minutes)

Create `src/index.ts`:

```typescript
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// TODO: Add routes here

app.listen(PORT, () => {
  console.log(`🚀 Arkhe Vault API running on port ${PORT}`);
});
```

### Step 19: Test Local Server (5 minutes)

```bash
# Add to package.json scripts:
npm pkg set scripts.dev="nodemon src/index.ts"
npm pkg set scripts.build="tsc"
npm pkg set scripts.start="node dist/index.js"

# Start development server
npm run dev
```

**Test:** Open browser to `http://localhost:3000/health`

**Expected:** `{"status":"ok","timestamp":"..."}`

---

## PHASE 1D: AUTHENTICATION (Week 2)

### Step 20: Create Auth Controller (30 minutes)

Continue with authentication implementation...

---

## Checkpoint Summary

**After completing Steps 1-19, you should have:**

✅ Fully rebranded codebase (Arkhe Vault)  
✅ AWS account with infrastructure  
✅ PostgreSQL database running  
✅ Redis cache provisioned  
✅ S3 bucket for documents  
✅ GitHub repo initialized  
✅ Local dev environment setup  
✅ Database schema defined  
✅ Express server running locally  

**Ready for:** Authentication implementation (Week 2)

**Do not proceed to Week 2 until:**
- All 19 steps above are complete
- Local server responds to `/health`
- Database connection working
- No build errors

---

*Execute in order. Check off each step before proceeding.*
