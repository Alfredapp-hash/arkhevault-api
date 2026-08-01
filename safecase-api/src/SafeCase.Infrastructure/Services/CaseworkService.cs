using Microsoft.EntityFrameworkCore;
using SafeCase.Application.Abstractions;
using SafeCase.Application.Casework;
using SafeCase.Application.Common;
using SafeCase.Domain.Cases;
using SafeCase.Domain.Clients;
using SafeCase.Domain.Tasks;
using SafeCase.Infrastructure.Persistence;

namespace SafeCase.Infrastructure.Services;

public sealed class CaseworkService(
    SafeCaseDbContext db,
    OrganizationContext organizationContext,
    ICurrentUser currentUser,
    IPermissionGate gate,
    IAuditService auditService)
{
    public async Task<IReadOnlyList<ClientDto>> ListClientsAsync(Guid organizationId, CancellationToken cancellationToken = default)
    {
        await EnsureAccessAsync(organizationId, PermissionCodes.ClientRead, cancellationToken);
        organizationContext.OrganizationId = organizationId;

        return await db.Clients.AsNoTracking()
            .Include(c => c.Identity)
            .OrderBy(c => c.Identity!.LastName)
            .ThenBy(c => c.Identity!.FirstName)
            .Select(c => ToClientDto(c))
            .ToListAsync(cancellationToken);
    }

    public async Task<ClientDto> GetClientAsync(Guid organizationId, Guid clientId, CancellationToken cancellationToken = default)
    {
        await EnsureAccessAsync(organizationId, PermissionCodes.ClientRead, cancellationToken);
        organizationContext.OrganizationId = organizationId;

        var client = await db.Clients.AsNoTracking()
            .Include(c => c.Identity)
            .FirstOrDefaultAsync(c => c.Id == clientId, cancellationToken)
            ?? throw new NotFoundException("Client not found.");

        await auditService.WriteAsync(new AuditWriteRequest(
            Action: "client.viewed",
            ResourceType: "client",
            ResourceId: client.Id,
            ClientId: client.Id), cancellationToken);

        return ToClientDto(client);
    }

    public async Task<ClientDto> CreateClientAsync(
        Guid organizationId,
        CreateClientRequest request,
        CancellationToken cancellationToken = default)
    {
        await EnsureAccessAsync(organizationId, PermissionCodes.ClientCreate, cancellationToken);

        if (string.IsNullOrWhiteSpace(request.FirstName) || string.IsNullOrWhiteSpace(request.LastName))
        {
            throw new ConflictException("First and last name are required.");
        }

        var client = await TenantWriteHelper.ExecuteInTenantTransactionAsync(
            db,
            organizationContext,
            organizationId,
            async ct =>
            {
                var entity = new Client
                {
                    OrganizationId = organizationId,
                    Status = "active",
                    RiskLevel = string.IsNullOrWhiteSpace(request.RiskLevel) ? null : request.RiskLevel.Trim(),
                    CreatedByMembershipId = currentUser.MembershipId,
                    Identity = new ClientIdentity
                    {
                        OrganizationId = organizationId,
                        FirstName = request.FirstName.Trim(),
                        LastName = request.LastName.Trim()
                    }
                };
                db.Clients.Add(entity);

                if (request.OpenInitialCase)
                {
                    var caseEntity = new Case
                    {
                        OrganizationId = organizationId,
                        ClientId = entity.Id,
                        Status = "open",
                        Title = string.IsNullOrWhiteSpace(request.CaseTitle)
                            ? $"Intake — {entity.Identity.LastName}"
                            : request.CaseTitle.Trim(),
                        OpenedByMembershipId = currentUser.MembershipId
                    };
                    db.Cases.Add(caseEntity);
                    db.CaseTimelineEvents.Add(CreateTimeline(
                        organizationId,
                        caseEntity.Id,
                        entity.Id,
                        "client.created",
                        "Client record created",
                        entity.Id,
                        "client"));
                    db.CaseTimelineEvents.Add(CreateTimeline(
                        organizationId,
                        caseEntity.Id,
                        entity.Id,
                        "case.created",
                        "Case opened",
                        caseEntity.Id,
                        "case"));
                }

                await db.SaveChangesAsync(ct);
                return entity;
            },
            cancellationToken);

        await auditService.WriteAsync(new AuditWriteRequest(
            Action: "client.created",
            ResourceType: "client",
            ResourceId: client.Id,
            ClientId: client.Id), cancellationToken);

        return ToClientDto(await db.Clients.AsNoTracking()
            .Include(c => c.Identity)
            .FirstAsync(c => c.Id == client.Id, cancellationToken));
    }

    public async Task<CaseDto> CreateCaseAsync(
        Guid organizationId,
        Guid clientId,
        CreateCaseRequest request,
        CancellationToken cancellationToken = default)
    {
        await EnsureAccessAsync(organizationId, PermissionCodes.CaseAssign, cancellationToken);
        // case.create maps to assign/create permissions for MVP — use CaseAssign + ClientRead check
        gate.RequirePermission(PermissionCodes.ClientRead);

        var caseDto = await TenantWriteHelper.ExecuteInTenantTransactionAsync(
            db,
            organizationContext,
            organizationId,
            async ct =>
            {
                var clientExists = await db.Clients.AnyAsync(c => c.Id == clientId, ct);
                if (!clientExists)
                {
                    throw new NotFoundException("Client not found.");
                }

                var entity = new Case
                {
                    OrganizationId = organizationId,
                    ClientId = clientId,
                    Status = "open",
                    Title = string.IsNullOrWhiteSpace(request.Title) ? "Case" : request.Title.Trim(),
                    OpenedByMembershipId = currentUser.MembershipId
                };
                db.Cases.Add(entity);
                db.CaseTimelineEvents.Add(CreateTimeline(
                    organizationId,
                    entity.Id,
                    clientId,
                    "case.created",
                    "Case opened",
                    entity.Id,
                    "case"));
                await db.SaveChangesAsync(ct);
                return ToCaseDto(entity);
            },
            cancellationToken);

        await auditService.WriteAsync(new AuditWriteRequest(
            Action: "case.created",
            ResourceType: "case",
            ResourceId: caseDto.Id,
            CaseId: caseDto.Id,
            ClientId: caseDto.ClientId), cancellationToken);

        return caseDto;
    }

    public async Task<CaseDto> GetCaseAsync(Guid organizationId, Guid caseId, CancellationToken cancellationToken = default)
    {
        await EnsureAccessAsync(organizationId, PermissionCodes.CaseRead, cancellationToken);
        organizationContext.OrganizationId = organizationId;

        var entity = await db.Cases.AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == caseId, cancellationToken)
            ?? throw new NotFoundException("Case not found.");

        await auditService.WriteAsync(new AuditWriteRequest(
            Action: "case.viewed",
            ResourceType: "case",
            ResourceId: entity.Id,
            CaseId: entity.Id,
            ClientId: entity.ClientId), cancellationToken);

        return ToCaseDto(entity);
    }

    public async Task<IReadOnlyList<CaseDto>> ListCasesForClientAsync(
        Guid organizationId,
        Guid clientId,
        CancellationToken cancellationToken = default)
    {
        await EnsureAccessAsync(organizationId, PermissionCodes.CaseRead, cancellationToken);
        organizationContext.OrganizationId = organizationId;

        return await db.Cases.AsNoTracking()
            .Where(c => c.ClientId == clientId)
            .OrderByDescending(c => c.CreatedAt)
            .Select(c => ToCaseDto(c))
            .ToListAsync(cancellationToken);
    }

    public async Task<AssignmentDto> AssignAsync(
        Guid organizationId,
        Guid caseId,
        CreateAssignmentRequest request,
        CancellationToken cancellationToken = default)
    {
        await EnsureAccessAsync(organizationId, PermissionCodes.CaseAssign, cancellationToken);

        var assignment = await TenantWriteHelper.ExecuteInTenantTransactionAsync(
            db,
            organizationContext,
            organizationId,
            async ct =>
            {
                var caseEntity = await db.Cases.FirstOrDefaultAsync(c => c.Id == caseId, ct)
                    ?? throw new NotFoundException("Case not found.");

                var membershipOk = await db.Memberships.AnyAsync(m =>
                    m.Id == request.MembershipId
                    && m.OrganizationId == organizationId
                    && m.IsActive, ct);
                if (!membershipOk)
                {
                    throw new NotFoundException("Membership not found.");
                }

                var entity = new CaseAssignment
                {
                    OrganizationId = organizationId,
                    CaseId = caseId,
                    MembershipId = request.MembershipId,
                    RoleOnCase = string.IsNullOrWhiteSpace(request.RoleOnCase) ? "advocate" : request.RoleOnCase.Trim()
                };
                db.CaseAssignments.Add(entity);
                db.CaseTimelineEvents.Add(CreateTimeline(
                    organizationId,
                    caseId,
                    caseEntity.ClientId,
                    "case.assigned",
                    "Advocate assigned",
                    entity.Id,
                    "assignment"));
                await db.SaveChangesAsync(ct);
                return new AssignmentDto(entity.Id, entity.CaseId, entity.MembershipId, entity.RoleOnCase, entity.AssignedAt);
            },
            cancellationToken);

        await auditService.WriteAsync(new AuditWriteRequest(
            Action: "case.assigned",
            ResourceType: "assignment",
            ResourceId: assignment.Id,
            CaseId: caseId), cancellationToken);

        return assignment;
    }

    public async Task<NoteDto> AddNoteAsync(
        Guid organizationId,
        Guid caseId,
        CreateNoteRequest request,
        CancellationToken cancellationToken = default)
    {
        await EnsureAccessAsync(organizationId, PermissionCodes.NoteCreate, cancellationToken);

        if (string.IsNullOrWhiteSpace(request.Narrative))
        {
            throw new ConflictException("Narrative is required.");
        }

        var visibility = request.VisibilityLevel is "restricted" ? "restricted" : "standard";

        var note = await TenantWriteHelper.ExecuteInTenantTransactionAsync(
            db,
            organizationContext,
            organizationId,
            async ct =>
            {
                var caseEntity = await db.Cases.FirstOrDefaultAsync(c => c.Id == caseId, ct)
                    ?? throw new NotFoundException("Case not found.");

                var entity = new CaseNote
                {
                    OrganizationId = organizationId,
                    CaseId = caseId,
                    AuthorMembershipId = currentUser.MembershipId
                        ?? throw new PermissionDeniedException("Membership required."),
                    NoteType = string.IsNullOrWhiteSpace(request.NoteType) ? "general" : request.NoteType.Trim(),
                    VisibilityLevel = visibility,
                    Narrative = request.Narrative.Trim()
                };
                db.CaseNotes.Add(entity);
                db.CaseTimelineEvents.Add(CreateTimeline(
                    organizationId,
                    caseId,
                    caseEntity.ClientId,
                    "note.created",
                    visibility == "restricted" ? "Restricted note added" : "Case note added",
                    entity.Id,
                    "note"));
                await db.SaveChangesAsync(ct);
                return MapNote(entity, canReadRestricted: true);
            },
            cancellationToken);

        await auditService.WriteAsync(new AuditWriteRequest(
            Action: "note.created",
            ResourceType: "note",
            ResourceId: note.Id,
            CaseId: caseId,
            Reason: visibility), cancellationToken);

        return note;
    }

    public async Task<IReadOnlyList<NoteDto>> ListNotesAsync(
        Guid organizationId,
        Guid caseId,
        CancellationToken cancellationToken = default)
    {
        await EnsureAccessAsync(organizationId, PermissionCodes.CaseRead, cancellationToken);
        organizationContext.OrganizationId = organizationId;

        var canReadRestricted = currentUser.IsPlatformOperator
            || currentUser.Permissions.Contains(PermissionCodes.NoteReadRestricted);

        var notes = await db.CaseNotes.AsNoTracking()
            .Where(n => n.CaseId == caseId)
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync(cancellationToken);

        return notes.Select(n => MapNote(n, canReadRestricted)).ToList();
    }

    public async Task<TaskDto> AddTaskAsync(
        Guid organizationId,
        Guid caseId,
        CreateTaskRequest request,
        CancellationToken cancellationToken = default)
    {
        await EnsureAccessAsync(organizationId, PermissionCodes.CaseAssign, cancellationToken);

        if (string.IsNullOrWhiteSpace(request.Title))
        {
            throw new ConflictException("Task title is required.");
        }

        var task = await TenantWriteHelper.ExecuteInTenantTransactionAsync(
            db,
            organizationContext,
            organizationId,
            async ct =>
            {
                var caseEntity = await db.Cases.FirstOrDefaultAsync(c => c.Id == caseId, ct)
                    ?? throw new NotFoundException("Case not found.");

                var entity = new TaskItem
                {
                    OrganizationId = organizationId,
                    CaseId = caseId,
                    ClientId = caseEntity.ClientId,
                    Title = request.Title.Trim(),
                    Priority = string.IsNullOrWhiteSpace(request.Priority) ? "normal" : request.Priority.Trim(),
                    DueAt = request.DueAt,
                    AssignedMembershipId = request.AssignedMembershipId,
                    CreatedByMembershipId = currentUser.MembershipId
                        ?? throw new PermissionDeniedException("Membership required.")
                };
                db.Tasks.Add(entity);
                db.CaseTimelineEvents.Add(CreateTimeline(
                    organizationId,
                    caseId,
                    caseEntity.ClientId,
                    "task.created",
                    "Task created",
                    entity.Id,
                    "task"));
                await db.SaveChangesAsync(ct);
                return ToTaskDto(entity);
            },
            cancellationToken);

        await auditService.WriteAsync(new AuditWriteRequest(
            Action: "task.created",
            ResourceType: "task",
            ResourceId: task.Id,
            CaseId: caseId,
            ClientId: task.ClientId), cancellationToken);

        return task;
    }

    public async Task<IReadOnlyList<TaskDto>> ListTasksAsync(
        Guid organizationId,
        Guid caseId,
        CancellationToken cancellationToken = default)
    {
        await EnsureAccessAsync(organizationId, PermissionCodes.CaseRead, cancellationToken);
        organizationContext.OrganizationId = organizationId;

        return await db.Tasks.AsNoTracking()
            .Where(t => t.CaseId == caseId)
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => ToTaskDto(t))
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<TimelineEventDto>> GetTimelineAsync(
        Guid organizationId,
        Guid caseId,
        CancellationToken cancellationToken = default)
    {
        await EnsureAccessAsync(organizationId, PermissionCodes.CaseRead, cancellationToken);
        organizationContext.OrganizationId = organizationId;

        var exists = await db.Cases.AnyAsync(c => c.Id == caseId, cancellationToken);
        if (!exists)
        {
            throw new NotFoundException("Case not found.");
        }

        return await db.CaseTimelineEvents.AsNoTracking()
            .Where(e => e.CaseId == caseId)
            .OrderBy(e => e.CreatedAt)
            .Select(e => new TimelineEventDto(
                e.Id,
                e.CaseId,
                e.ClientId,
                e.EventType,
                e.Summary,
                e.ActorMembershipId,
                e.RelatedResourceId,
                e.RelatedResourceType,
                e.CreatedAt))
            .ToListAsync(cancellationToken);
    }

    /// <summary>
    /// One-shot vertical slice used by demos/tests:
    /// create client + case + assign self + note + task + return timeline.
    /// </summary>
    public async Task<VerticalSliceResult> RunVerticalSliceAsync(
        Guid organizationId,
        CreateClientRequest request,
        CancellationToken cancellationToken = default)
    {
        await EnsureAccessAsync(organizationId, PermissionCodes.ClientCreate, cancellationToken);
        gate.RequirePermission(PermissionCodes.CaseAssign);
        gate.RequirePermission(PermissionCodes.NoteCreate);

        var membershipId = currentUser.MembershipId
            ?? throw new PermissionDeniedException("Membership required.");

        var result = await TenantWriteHelper.ExecuteInTenantTransactionAsync(
            db,
            organizationContext,
            organizationId,
            async ct =>
            {
                var client = new Client
                {
                    OrganizationId = organizationId,
                    Status = "active",
                    RiskLevel = request.RiskLevel,
                    CreatedByMembershipId = membershipId,
                    Identity = new ClientIdentity
                    {
                        OrganizationId = organizationId,
                        FirstName = request.FirstName.Trim(),
                        LastName = request.LastName.Trim()
                    }
                };
                db.Clients.Add(client);

                var caseEntity = new Case
                {
                    OrganizationId = organizationId,
                    ClientId = client.Id,
                    Status = "open",
                    Title = string.IsNullOrWhiteSpace(request.CaseTitle)
                        ? $"Intake — {request.LastName.Trim()}"
                        : request.CaseTitle.Trim(),
                    OpenedByMembershipId = membershipId
                };
                db.Cases.Add(caseEntity);

                var assignment = new CaseAssignment
                {
                    OrganizationId = organizationId,
                    CaseId = caseEntity.Id,
                    MembershipId = membershipId,
                    RoleOnCase = "advocate"
                };
                db.CaseAssignments.Add(assignment);

                var note = new CaseNote
                {
                    OrganizationId = organizationId,
                    CaseId = caseEntity.Id,
                    AuthorMembershipId = membershipId,
                    NoteType = "intake",
                    VisibilityLevel = "standard",
                    Narrative = "Initial intake note (synthetic)."
                };
                db.CaseNotes.Add(note);

                var task = new TaskItem
                {
                    OrganizationId = organizationId,
                    CaseId = caseEntity.Id,
                    ClientId = client.Id,
                    Title = "Complete safety screening",
                    Priority = "high",
                    AssignedMembershipId = membershipId,
                    CreatedByMembershipId = membershipId
                };
                db.Tasks.Add(task);

                db.CaseTimelineEvents.AddRange(
                    CreateTimeline(organizationId, caseEntity.Id, client.Id, "client.created", "Client record created", client.Id, "client"),
                    CreateTimeline(organizationId, caseEntity.Id, client.Id, "case.created", "Case opened", caseEntity.Id, "case"),
                    CreateTimeline(organizationId, caseEntity.Id, client.Id, "case.assigned", "Advocate assigned", assignment.Id, "assignment"),
                    CreateTimeline(organizationId, caseEntity.Id, client.Id, "note.created", "Case note added", note.Id, "note"),
                    CreateTimeline(organizationId, caseEntity.Id, client.Id, "task.created", "Task created", task.Id, "task"));

                await db.SaveChangesAsync(ct);

                var timeline = await db.CaseTimelineEvents.AsNoTracking()
                    .Where(e => e.CaseId == caseEntity.Id)
                    .OrderBy(e => e.CreatedAt)
                    .Select(e => new TimelineEventDto(
                        e.Id, e.CaseId, e.ClientId, e.EventType, e.Summary,
                        e.ActorMembershipId, e.RelatedResourceId, e.RelatedResourceType, e.CreatedAt))
                    .ToListAsync(ct);

                return new VerticalSliceResult(
                    ToClientDto(client),
                    ToCaseDto(caseEntity),
                    new AssignmentDto(assignment.Id, assignment.CaseId, assignment.MembershipId, assignment.RoleOnCase, assignment.AssignedAt),
                    MapNote(note, canReadRestricted: true),
                    ToTaskDto(task),
                    timeline);
            },
            cancellationToken);

        await auditService.WriteAsync(new AuditWriteRequest(
            Action: "workflow.vertical_slice",
            ResourceType: "case",
            ResourceId: result.Case.Id,
            CaseId: result.Case.Id,
            ClientId: result.Client.Id), cancellationToken);

        return result;
    }

    private async Task EnsureAccessAsync(Guid organizationId, string permission, CancellationToken cancellationToken)
    {
        gate.RequireAuthenticated();

        if (currentUser.IsPlatformOperator)
        {
            organizationContext.OrganizationId = organizationId;
            currentUser.OrganizationId = organizationId;
            return;
        }

        // Always resolve membership for the *route* organization. Never reuse a membership
        // established from a different X-Organization-Id header (IDOR guard).
        var membership = await db.Memberships
            .Include(m => m.MembershipRoles).ThenInclude(mr => mr.Role)
            .ThenInclude(r => r!.RolePermissions).ThenInclude(rp => rp.Permission)
            .FirstOrDefaultAsync(m =>
                m.OrganizationId == organizationId
                && m.UserId == currentUser.UserId
                && m.IsActive, cancellationToken);

        if (membership is null)
        {
            throw new NotFoundException("Organization not found.");
        }

        organizationContext.OrganizationId = organizationId;
        currentUser.OrganizationId = organizationId;
        currentUser.MembershipId = membership.Id;
        currentUser.Permissions = membership.MembershipRoles
            .SelectMany(mr => mr.Role!.RolePermissions.Select(rp => rp.Permission!.Code))
            .ToHashSet();

        gate.RequirePermission(permission);
    }

    private CaseTimelineEvent CreateTimeline(
        Guid organizationId,
        Guid caseId,
        Guid? clientId,
        string eventType,
        string summary,
        Guid? relatedId,
        string relatedType)
        => new()
        {
            OrganizationId = organizationId,
            CaseId = caseId,
            ClientId = clientId,
            EventType = eventType,
            Summary = summary,
            ActorMembershipId = currentUser.MembershipId,
            RelatedResourceId = relatedId,
            RelatedResourceType = relatedType
        };

    private static ClientDto ToClientDto(Client c) => new(
        c.Id,
        c.OrganizationId,
        c.Identity!.FirstName,
        c.Identity.LastName,
        c.Status,
        c.RiskLevel,
        c.CreatedAt);

    private static CaseDto ToCaseDto(Case c) => new(
        c.Id,
        c.OrganizationId,
        c.ClientId,
        c.Status,
        c.Title,
        c.CreatedAt);

    private static TaskDto ToTaskDto(TaskItem t) => new(
        t.Id,
        t.CaseId,
        t.ClientId,
        t.Title,
        t.Status,
        t.Priority,
        t.DueAt,
        t.AssignedMembershipId,
        t.CreatedAt);

    private static NoteDto MapNote(CaseNote note, bool canReadRestricted)
    {
        var restricted = note.VisibilityLevel == "restricted";
        var redact = restricted && !canReadRestricted;
        return new NoteDto(
            note.Id,
            note.CaseId,
            note.AuthorMembershipId,
            note.NoteType,
            note.VisibilityLevel,
            redact ? null : note.Narrative,
            redact,
            note.CreatedAt);
    }
}
