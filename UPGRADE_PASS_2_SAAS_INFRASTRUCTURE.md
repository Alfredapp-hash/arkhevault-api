# Arkhe Vault - Upgrade Pass 2: SaaS Infrastructure

**Date:** June 2, 2026  
**Status:** Planning Phase  
**Goal:** Transform desktop app into multi-tenant SaaS platform  
**Timeline:** 8-12 weeks  
**Investment:** $40,000-$80,000 (or DIY with this guide)

---

## Executive Summary

**Current State:** Single-user macOS app with local Core Data  
**Target State:** Multi-tenant SaaS with web API, cloud sync, multi-platform support

**Business Impact:**
- Enables 2-year free nonprofit program
- Increases valuation from $150K → $500K+
- Unlocks recurring revenue ($99-$299/month per org)
- Scales from 1 user/org → unlimited users/org

---

## Upgrade Overview

### What We're Building:

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  macOS App   │  │  Web Portal  │  │  iOS App     │  │
│  │  (Existing)  │  │  (New)       │  │  (New)       │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
└─────────┼─────────────────┼─────────────────┼──────────┘
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │ HTTPS/TLS 1.3
┌───────────────────────────┼───────────────────────────┐
│                    API LAYER                           │
│              ┌────────────┴────────────┐               │
│              │   REST API (Node.js)     │               │
│              │   - Authentication       │               │
│              │   - CRUD Operations    │               │
│              │   - Real-time Sync     │               │
│              │   - Rate Limiting      │               │
│              └────────────┬────────────┘               │
└───────────────────────────┼───────────────────────────┘
                            │
┌───────────────────────────┼───────────────────────────┐
│                 DATA LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  PostgreSQL  │  │    Redis     │  │     S3       │  │
│  │  (Primary)   │  │   (Cache)    │  │  (Files)     │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Phase 1: Backend API Development (Weeks 1-4)

### 1.1 API Architecture

**Technology Stack:**
- **Runtime:** Node.js 20+ with TypeScript
- **Framework:** Express.js or Fastify
- **Database:** PostgreSQL 15+
- **Cache:** Redis 7+
- **Auth:** JWT + bcrypt
- **Validation:** Zod
- **Documentation:** OpenAPI/Swagger

**API Structure:**
```
src/
├── config/           # Environment config
├── controllers/      # Route handlers
├── middleware/       # Auth, validation, rate limiting
├── models/          # Database models (Prisma)
├── routes/          # API endpoints
├── services/        # Business logic
├── utils/           # Helpers
├── types/           # TypeScript types
└── tests/           # API tests
```

### 1.2 Core API Endpoints

**Authentication:**
```typescript
// POST /api/v1/auth/register
// POST /api/v1/auth/login
// POST /api/v1/auth/refresh
// POST /api/v1/auth/logout
// POST /api/v1/auth/forgot-password
// POST /api/v1/auth/reset-password
```

**Organizations (Tenants):**
```typescript
// CRUD for multi-tenancy
// POST /api/v1/organizations
// GET /api/v1/organizations/:id
// PUT /api/v1/organizations/:id
// DELETE /api/v1/organizations/:id
// GET /api/v1/organizations/:id/users
// GET /api/v1/organizations/:id/stats
```

**Users:**
```typescript
// POST /api/v1/users
// GET /api/v1/users
// GET /api/v1/users/:id
// PUT /api/v1/users/:id
// DELETE /api/v1/users/:id
// PUT /api/v1/users/:id/role
```

**Clients (Case Management):**
```typescript
// POST /api/v1/clients
// GET /api/v1/clients
// GET /api/v1/clients/:id
// PUT /api/v1/clients/:id
// DELETE /api/v1/clients/:id
// GET /api/v1/clients/:id/notes
// GET /api/v1/clients/:id/programs
// GET /api/v1/clients/:id/documents
// GET /api/v1/clients/search?q=query
```

**Programs:**
```typescript
// POST /api/v1/programs
// GET /api/v1/programs
// GET /api/v1/programs/:id
// PUT /api/v1/programs/:id
// DELETE /api/v1/programs/:id
// POST /api/v1/programs/:id/enroll
// GET /api/v1/programs/:id/enrollments
```

**Safety Flags:**
```typescript
// POST /api/v1/safety-flags
// GET /api/v1/safety-flags
// GET /api/v1/safety-flags/:id
// PUT /api/v1/safety-flags/:id
// PUT /api/v1/safety-flags/:id/resolve
// GET /api/v1/safety-flags/stats
```

**Documents:**
```typescript
// POST /api/v1/documents (upload)
// GET /api/v1/documents
// GET /api/v1/documents/:id
// DELETE /api/v1/documents/:id
// GET /api/v1/documents/:id/download
```

**AI Integration:**
```typescript
// POST /api/v1/ai/summarize-client
// POST /api/v1/ai/analyze-risk
// POST /api/v1/ai/generate-grant-narrative
// POST /api/v1/ai/enhance-notes
// GET /api/v1/ai/usage-stats
```

### 1.3 Database Schema (PostgreSQL)

**Core Tables:**

```sql
-- Organizations (Tenants)
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    plan VARCHAR(50) DEFAULT 'growth', -- starter, growth, enterprise
    status VARCHAR(50) DEFAULT 'active', -- active, suspended, cancelled
    subscription_status VARCHAR(50) DEFAULT 'trialing', -- trialing, active, past_due
    trial_ends_at TIMESTAMP,
    max_users INTEGER DEFAULT 10,
    max_clients INTEGER DEFAULT 500,
    max_storage_gb INTEGER DEFAULT 10,
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(50) DEFAULT 'staff', -- admin, manager, staff, viewer
    status VARCHAR(50) DEFAULT 'active',
    last_login_at TIMESTAMP,
    mfa_enabled BOOLEAN DEFAULT FALSE,
    mfa_secret VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Clients
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(50),
    date_of_birth DATE,
    address TEXT,
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(50),
    status VARCHAR(50) DEFAULT 'active', -- active, inactive, graduated
    risk_level VARCHAR(50) DEFAULT 'low', -- low, medium, high, critical
    intake_date DATE,
    notes TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Client Notes
CREATE TABLE client_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    author_id UUID REFERENCES users(id),
    content TEXT NOT NULL,
    note_type VARCHAR(50) DEFAULT 'general', -- general, assessment, progress, incident
    is_confidential BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Programs
CREATE TABLE programs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    capacity INTEGER,
    status VARCHAR(50) DEFAULT 'active',
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Program Enrollments
CREATE TABLE program_enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_id UUID REFERENCES programs(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    enrollment_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(50) DEFAULT 'active', -- active, completed, dropped
    exit_date DATE,
    exit_reason VARCHAR(255),
    outcomes JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(program_id, client_id)
);

-- Safety Flags
CREATE TABLE safety_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    flagged_by UUID REFERENCES users(id),
    flag_type VARCHAR(100) NOT NULL, -- immediate_danger, domestic_violence, etc.
    severity VARCHAR(50) DEFAULT 'medium', -- low, medium, high, critical
    description TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'open', -- open, monitoring, resolved
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMP,
    resolution_notes TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Documents
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    client_id UUID REFERENCES clients(id) ON DELETE SET NULL,
    uploaded_by UUID REFERENCES users(id),
    filename VARCHAR(255) NOT NULL,
    original_filename VARCHAR(255) NOT NULL,
    file_size INTEGER,
    mime_type VARCHAR(100),
    storage_key VARCHAR(500) NOT NULL, -- S3 key
    document_type VARCHAR(100), -- intake_form, id, medical, etc.
    description TEXT,
    is_encrypted BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Audit Logs
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL, -- create, update, delete, view
    entity_type VARCHAR(100) NOT NULL, -- client, note, program, etc.
    entity_id UUID,
    metadata JSONB DEFAULT '{}',
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);

-- API Usage (for rate limiting & billing)
CREATE TABLE api_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    endpoint VARCHAR(255),
    method VARCHAR(10),
    status_code INTEGER,
    response_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- AI Usage (for Claude API billing)
CREATE TABLE ai_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    feature VARCHAR(100), -- summarize, risk_analysis, grant_narrative
    prompt_tokens INTEGER,
    completion_tokens INTEGER,
    total_tokens INTEGER,
    cost_usd DECIMAL(10, 4),
    created_at TIMESTAMP DEFAULT NOW()
);
```

**Indexes for Performance:**
```sql
-- Performance indexes
CREATE INDEX idx_users_org ON users(organization_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_clients_org ON clients(organization_id);
CREATE INDEX idx_clients_name ON clients(last_name, first_name);
CREATE INDEX idx_notes_client ON client_notes(client_id);
CREATE INDEX idx_enrollments_client ON program_enrollments(client_id);
CREATE INDEX idx_enrollments_program ON program_enrollments(program_id);
CREATE INDEX idx_safety_org ON safety_flags(organization_id);
CREATE INDEX idx_safety_client ON safety_flags(client_id);
CREATE INDEX idx_safety_status ON safety_flags(status);
CREATE INDEX idx_audit_org ON audit_logs(organization_id);
CREATE INDEX idx_audit_created ON audit_logs(created_at);
CREATE INDEX idx_api_usage_org ON api_usage(organization_id);
```

### 1.4 Multi-Tenancy Strategy

**Row-Level Security (RLS) in PostgreSQL:**

```sql
-- Enable RLS on all tables
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE client_notes ENABLE ROW LEVEL SECURITY;
-- etc.

-- Create policy function
CREATE POLICY organization_isolation ON clients
    FOR ALL
    USING (organization_id = current_setting('app.current_org')::UUID);

-- Set org context per request
SET app.current_org = 'org-uuid-here';
```

**Application-Level Isolation:**
```typescript
// Middleware to enforce tenant isolation
const tenantMiddleware = async (req, res, next) => {
    const orgId = req.user.organizationId;
    
    // Add to query context
    req.dbContext = { organizationId: orgId };
    
    next();
};

// All queries automatically filtered
const clients = await db.clients.findMany({
    where: { organizationId: req.dbContext.organizationId }
});
```

---

## Phase 2: Real-Time Sync (Weeks 5-6)

### 2.1 WebSocket Implementation

**Socket.io for real-time updates:**

```typescript
// Server-side
io.on('connection', (socket) => {
    const orgId = socket.user.organizationId;
    
    // Join organization room
    socket.join(`org:${orgId}`);
    
    // Handle client updates
    socket.on('client:update', async (data) => {
        // Update database
        const updated = await updateClient(data);
        
        // Broadcast to all users in organization
        io.to(`org:${orgId}`).emit('client:updated', updated);
    });
});

// Client-side (macOS app)
socket.on('client:updated', (data) => {
    // Update local Core Data
    syncToCoreData(data);
});
```

### 2.2 Sync Protocol

**Conflict Resolution:**
```typescript
interface SyncOperation {
    entityType: 'client' | 'note' | 'program';
    entityId: string;
    operation: 'create' | 'update' | 'delete';
    data: any;
    clientTimestamp: number; // Lamport timestamp
    version: number;
}

// Last-write-wins with version check
const resolveConflict = (serverOp: SyncOperation, clientOp: SyncOperation) => {
    if (serverOp.version > clientOp.version) {
        return serverOp; // Server wins
    } else if (clientOp.version > serverOp.version) {
        return clientOp; // Client wins
    } else {
        // Same version, use timestamp
        return serverOp.clientTimestamp > clientOp.clientTimestamp 
            ? serverOp : clientOp;
    }
};
```

---

## Phase 3: macOS App Integration (Weeks 7-8)

### 3.1 API Client Layer

**Replace Core Data with API:**

```swift
// API Client
class ArkheAPIClient {
    static let shared = ArkheAPIClient()
    
    private let baseURL = "https://api.arkhevault.com/v1"
    private var accessToken: String?
    
    // MARK: - Authentication
    func login(email: String, password: String) async throws -> AuthResponse {
        let endpoint = "\(baseURL)/auth/login"
        let body = ["email": email, "password": password]
        
        return try await post(endpoint, body: body)
    }
    
    // MARK: - Clients
    func fetchClients() async throws -> [Client] {
        let endpoint = "\(baseURL)/clients"
        return try await get(endpoint)
    }
    
    func createClient(_ client: Client) async throws -> Client {
        let endpoint = "\(baseURL)/clients"
        return try await post(endpoint, body: client)
    }
    
    func updateClient(_ client: Client) async throws -> Client {
        let endpoint = "\(baseURL)/clients/\(client.id)"
        return try await put(endpoint, body: client)
    }
    
    // MARK: - Generic HTTP Methods
    private func get<T: Decodable>(_ endpoint: String) async throws -> T {
        // Implementation
    }
    
    private func post<T: Decodable>(_ endpoint: String, body: Encodable) async throws -> T {
        // Implementation
    }
    
    private func put<T: Decodable>(_ endpoint: String, body: Encodable) async throws -> T {
        // Implementation
    }
}
```

### 3.2 Hybrid Mode (Offline + Online)

**Sync Strategy:**

```swift
class HybridDataController {
    // Local cache (Core Data)
    private let localContext: NSManagedObjectContext
    
    // Remote API
    private let apiClient = ArkheAPIClient.shared
    
    // Sync queue
    private let syncQueue = OperationQueue()
    
    // MARK: - Fetch (Hybrid)
    func fetchClients() async throws -> [Client] {
        // Try network first
        if NetworkMonitor.shared.isConnected {
            let remoteClients = try await apiClient.fetchClients()
            
            // Update local cache
            await syncToLocal(remoteClients)
            
            return remoteClients
        } else {
            // Fall back to local
            return try await fetchLocalClients()
        }
    }
    
    // MARK: - Save (Queue for sync)
    func saveClient(_ client: Client) async throws {
        // Save locally immediately
        try await saveLocal(client)
        
        // Queue for remote sync
        syncQueue.addOperation {
            do {
                let saved = try await self.apiClient.createClient(client)
                await self.markSynced(client.id)
            } catch {
                await self.markPending(client.id)
            }
        }
    }
}
```

---

## Phase 4: Web Portal (Weeks 9-10)

### 4.1 React Web App

**Technology Stack:**
- React 18+ with TypeScript
- Next.js 14 (App Router)
- Tailwind CSS
- React Query (TanStack Query)
- Zustand (State Management)
- React Hook Form + Zod

**Key Pages:**
```
src/
├── app/
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   ├── register/page.tsx
│   │   └── forgot-password/page.tsx
│   ├── (dashboard)/
│   │   ├── layout.tsx
│   │   ├── page.tsx (Dashboard)
│   │   ├── clients/
│   │   │   ├── page.tsx (Client List)
│   │   │   └── [id]/page.tsx (Client Detail)
│   │   ├── programs/
│   │   ├── safety/
│   │   ├── reports/
│   │   └── settings/
│   └── api/ (Next.js API routes if needed)
├── components/
│   ├── ui/ (shadcn/ui components)
│   ├── forms/
│   ├── charts/
│   └── layout/
├── hooks/
├── lib/
│   ├── api.ts
│   └── utils.ts
└── types/
```

### 4.2 Feature Parity

**Web Portal Features:**
- ✅ All dashboard charts and metrics
- ✅ Full client management (CRUD)
- ✅ Program enrollment
- ✅ Safety flag management
- ✅ Document upload/download
- ✅ AI features (summarization, risk analysis)
- ✅ User management (admin only)
- ✅ Reporting & analytics
- ✅ Settings & configuration

---

## Phase 5: DevOps & Deployment (Weeks 11-12)

### 5.1 Infrastructure (AWS)

**Services:**
```yaml
# docker-compose.yml for local development
version: '3.8'
services:
  api:
    build: ./api
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://postgres:password@db:5432/arkhevault
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=your-secret-here
    depends_on:
      - db
      - redis
  
  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=arkhevault
  
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
  
  web:
    build: ./web
    ports:
      - "3001:3000"
    depends_on:
      - api

volumes:
  postgres_data:
  redis_data:
```

**Production (AWS):**
- **ECS/Fargate** - API containers (auto-scaling)
- **RDS PostgreSQL** - Managed database
- **ElastiCache Redis** - Managed cache
- **S3** - Document storage
- **CloudFront** - CDN for web app
- **Route 53** - DNS
- **Application Load Balancer** - SSL termination

### 5.2 CI/CD Pipeline

**GitHub Actions:**
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run API tests
        run: cd api && npm test
      - name: Run web tests
        run: cd web && npm test
  
  deploy-api:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Build and push Docker image
        run: |
          docker build -t arkhevault/api:${{ github.sha }} ./api
          docker push arkhevault/api:${{ github.sha }}
      - name: Deploy to ECS
        run: |
          aws ecs update-service --cluster arkhevault --service api --force-new-deployment
  
  deploy-web:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Build Next.js app
        run: cd web && npm run build
      - name: Deploy to S3/CloudFront
        run: |
          aws s3 sync ./web/dist s3://arkhevault-web
          aws cloudfront create-invalidation --distribution-id XYZ --paths "/*"
```

---

## Migration Strategy

### Existing macOS Users

**Option 1: Gradual Migration (Recommended)**
1. Release v2.0 with hybrid mode (local + cloud)
2. Prompt users to "Enable Cloud Sync" (opt-in)
3. Migrate data in background
4. Keep local copy as cache
5. Eventually make cloud primary

**Option 2: Clean Slate**
1. New app: "Arkhe Vault Cloud"
2. Separate from existing macOS app
3. Users manually export/import
4. Phase out macOS-only version over 12 months

### Data Migration Script

```typescript
// One-time migration from Core Data to PostgreSQL
const migrateOrganization = async (orgId: string, coreDataExport: any) => {
    // Create organization
    const org = await db.organizations.create({
        data: {
            id: orgId,
            name: coreDataExport.organizationName,
            plan: 'growth',
            trial_ends_at: new Date(Date.now() + 730 * 24 * 60 * 60 * 1000) // 2 years
        }
    });
    
    // Migrate users
    for (const user of coreDataExport.users) {
        await db.users.create({
            data: {
                organization_id: org.id,
                email: user.email,
                password_hash: await bcrypt.hash(user.password, 10),
                first_name: user.firstName,
                last_name: user.lastName,
                role: user.role
            }
        });
    }
    
    // Migrate clients
    for (const client of coreDataExport.clients) {
        await db.clients.create({
            data: {
                organization_id: org.id,
                first_name: client.firstName,
                last_name: client.lastName,
                email: client.email,
                phone: client.phone,
                // ... other fields
            }
        });
    }
    
    console.log(`Migrated org ${org.name} with ${coreDataExport.clients.length} clients`);
};
```

---

## Cost Breakdown

### Development (One-Time)

| Item | Cost |
|------|------|
| Senior backend developer (4 weeks) | $8,000-$12,000 |
| Frontend developer (3 weeks) | $6,000-$9,000 |
| DevOps setup | $2,000-$4,000 |
| Testing & QA | $2,000-$3,000 |
| **Total** | **$18,000-$28,000** |

### Monthly Infrastructure (AWS)

| Service | Monthly Cost |
|---------|--------------|
| ECS Fargate (2 tasks) | $150-$300 |
| RDS PostgreSQL (db.t3.medium) | $100-$150 |
| ElastiCache Redis | $50-$100 |
| S3 Storage (100GB) | $5-$10 |
| CloudFront | $20-$50 |
| Route 53 | $1 |
| **Total (small scale)** | **$325-$610** |
| **Total (100 orgs)** | **$800-$1,500** |

### Claude API Costs

- $0.01-0.05 per AI request
- 100 orgs × 100 requests/month = $100-$500/month

---

## Success Metrics

**Technical:**
- API response time < 200ms (95th percentile)
- 99.9% uptime
- < 1 second sync latency
- Zero data loss during migration

**Business:**
- 50 organizations migrated in first 90 days
- 80% daily active users
- < 5% monthly churn
- $10K MRR by month 6

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Data migration errors | Backup everything, dry-run migrations, rollback plan |
| API performance issues | Rate limiting, caching, database optimization |
| Security breaches | Penetration testing, SOC 2 audit, encryption |
| Users resist cloud | Keep local option, gradual migration, education |
| AWS costs balloon | Auto-scaling limits, cost alerts, reserved instances |

---

## Next Steps (This Week)

1. **Decision:** Build in-house or hire contractors?
2. **Setup:** Create GitHub repo for API (`arkhevault-api`)
3. **Database:** Provision AWS RDS PostgreSQL
4. **Design:** API endpoint specification document
5. **Team:** Hire backend developer (if not DIY)

---

**Bottom Line:** This upgrade transforms Arkhe Vault from a $150K single-user app into a $500K+ SaaS platform. It enables the 2-year free nonprofit program and unlocks recurring revenue.

**ROI Timeline:**
- Investment: $40K-$80K
- Break-even: Month 8-12 (at 50 paying orgs)
- 2-year return: $200K-$500K ARR

---

*Ready to start? Begin with Phase 1: API Development*
