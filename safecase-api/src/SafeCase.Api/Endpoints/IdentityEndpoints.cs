using SafeCase.Application.Abstractions;
using SafeCase.Application.Common;
using SafeCase.Application.Identity;
using SafeCase.Infrastructure.Persistence;
using SafeCase.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;

namespace SafeCase.Api.Endpoints;

public static class IdentityEndpoints
{
    public static IEndpointRouteBuilder MapIdentityEndpoints(this IEndpointRouteBuilder app)
    {
        var api = app.MapGroup("/api/v1").WithTags("Identity");

        api.MapGet("/me", async (MeService meService, CancellationToken ct) =>
        {
            var me = await meService.GetOrProvisionAsync(ct);
            return Results.Ok(me);
        }).RequireAuthorization();

        api.MapGet("/organizations", async (OrganizationService orgs, CancellationToken ct) =>
        {
            var list = await orgs.ListForCurrentUserAsync(ct);
            return Results.Ok(list);
        }).RequireAuthorization();

        api.MapPost("/organizations", async (CreateOrganizationRequest request, OrganizationService orgs, CancellationToken ct) =>
        {
            var created = await orgs.CreateAsync(request, ct);
            return Results.Created($"/api/v1/organizations/{created.Id}", created);
        }).RequireAuthorization();

        api.MapGet("/organizations/{organizationId:guid}", async (Guid organizationId, OrganizationService orgs, CancellationToken ct) =>
        {
            var org = await orgs.GetAsync(organizationId, ct);
            return Results.Ok(org);
        }).RequireAuthorization();

        api.MapGet("/organizations/{organizationId:guid}/memberships", async (
            Guid organizationId,
            MembershipService memberships,
            CancellationToken ct) =>
        {
            var list = await memberships.ListAsync(organizationId, ct);
            return Results.Ok(list);
        }).RequireAuthorization();

        api.MapPost("/organizations/{organizationId:guid}/memberships", async (
            Guid organizationId,
            CreateMembershipRequest request,
            MembershipService memberships,
            CancellationToken ct) =>
        {
            var created = await memberships.CreateAsync(organizationId, request, ct);
            return Results.Created($"/api/v1/organizations/{organizationId}/memberships/{created.Id}", created);
        }).RequireAuthorization();

        api.MapPost("/organizations/{organizationId:guid}/memberships/{membershipId:guid}/disable", async (
            Guid organizationId,
            Guid membershipId,
            DisableMembershipRequest request,
            MembershipService memberships,
            CancellationToken ct) =>
        {
            var updated = await memberships.DisableAsync(organizationId, membershipId, request, ct);
            return Results.Ok(updated);
        }).RequireAuthorization();

        api.MapGet("/organizations/{organizationId:guid}/audit-events", async (
            Guid organizationId,
            SafeCaseDbContext db,
            OrganizationContext organizationContext,
            ICurrentUser currentUser,
            IPermissionGate gate,
            CancellationToken ct) =>
        {
            organizationContext.OrganizationId = organizationId;
            currentUser.OrganizationId = organizationId;
            gate.RequirePermission(PermissionCodes.AuditReview);

            var events = await db.AuditEvents.AsNoTracking()
                .OrderByDescending(e => e.CreatedAt)
                .Take(100)
                .Select(e => new
                {
                    e.Id,
                    e.Action,
                    e.ResourceType,
                    e.ResourceId,
                    e.Result,
                    e.Reason,
                    e.ActorUserId,
                    e.CreatedAt,
                    e.CorrelationId
                })
                .ToListAsync(ct);

            return Results.Ok(events);
        }).RequireAuthorization();

        // Tenancy probe used by authorization tests (not a product UI surface).
        api.MapGet("/organizations/{organizationId:guid}/clients", async (
            Guid organizationId,
            SafeCaseDbContext db,
            OrganizationContext organizationContext,
            ICurrentUser currentUser,
            IPermissionGate gate,
            CancellationToken ct) =>
        {
            organizationContext.OrganizationId = organizationId;
            currentUser.OrganizationId = organizationId;

            if (!currentUser.IsPlatformOperator)
            {
                if (currentUser.MembershipId is null)
                {
                    throw new NotFoundException("Organization not found.");
                }

                gate.RequirePermission(PermissionCodes.ClientRead);
            }

            var clients = await db.Clients.AsNoTracking()
                .Include(c => c.Identity)
                .Select(c => new
                {
                    c.Id,
                    c.OrganizationId,
                    FirstName = c.Identity!.FirstName,
                    LastName = c.Identity.LastName,
                    c.Status
                })
                .ToListAsync(ct);

            return Results.Ok(clients);
        }).RequireAuthorization();

        return app;
    }
}
