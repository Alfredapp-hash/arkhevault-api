using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using SafeCase.Application.Abstractions;
using SafeCase.Application.Common;
using SafeCase.Infrastructure.Persistence;

namespace SafeCase.Api.Middleware;

public sealed class CurrentUserMiddleware(RequestDelegate next)
{
    public const string OrganizationHeader = "X-Organization-Id";

    public async Task InvokeAsync(
        HttpContext context,
        CurrentUser currentUser,
        OrganizationContext organizationContext,
        SafeCaseDbContext db)
    {
        var principal = context.User;
        if (principal.Identity?.IsAuthenticated == true)
        {
            currentUser.IsAuthenticated = true;
            currentUser.EntraObjectId = principal.FindFirstValue("oid")
                ?? principal.FindFirstValue(ClaimTypes.NameIdentifier);
            currentUser.Email = principal.FindFirstValue("preferred_username")
                ?? principal.FindFirstValue(ClaimTypes.Email);
            currentUser.DisplayName = principal.FindFirstValue("name")
                ?? principal.Identity?.Name;

            if (!string.IsNullOrWhiteSpace(currentUser.EntraObjectId))
            {
                var user = await db.Users.AsNoTracking()
                    .FirstOrDefaultAsync(u => u.EntraObjectId == currentUser.EntraObjectId);
                if (user is not null)
                {
                    currentUser.UserId = user.Id;
                    currentUser.IsPlatformOperator = await db.MembershipRoles.AsNoTracking()
                        .AnyAsync(mr =>
                            mr.Membership!.UserId == user.Id
                            && mr.Membership.IsActive
                            && mr.Role!.Code == RoleCodes.PlatformOperator);
                }
            }
        }

        if (context.Request.Headers.TryGetValue(OrganizationHeader, out var orgHeader)
            && Guid.TryParse(orgHeader.ToString(), out var orgId))
        {
            organizationContext.OrganizationId = orgId;
            currentUser.OrganizationId = orgId;

            if (currentUser.UserId is not null)
            {
                var membership = await db.Memberships.AsNoTracking()
                    .Include(m => m.MembershipRoles)
                        .ThenInclude(mr => mr.Role)
                            .ThenInclude(r => r!.RolePermissions)
                                .ThenInclude(rp => rp.Permission)
                    .FirstOrDefaultAsync(m =>
                        m.OrganizationId == orgId
                        && m.UserId == currentUser.UserId
                        && m.IsActive);

                if (membership is not null)
                {
                    currentUser.MembershipId = membership.Id;
                    currentUser.Permissions = membership.MembershipRoles
                        .SelectMany(mr => mr.Role!.RolePermissions.Select(rp => rp.Permission!.Code))
                        .ToHashSet();
                }
                else if (!currentUser.IsPlatformOperator)
                {
                    // Keep org id for fail-closed queries, but clear membership/permissions.
                    currentUser.MembershipId = null;
                    currentUser.Permissions = new HashSet<string>();
                }
            }
        }

        await next(context);
    }
}
