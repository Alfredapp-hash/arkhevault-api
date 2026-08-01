namespace SafeCase.Application.Abstractions;

public interface IPermissionGate
{
    void RequireAuthenticated();
    void RequireOrganization();
    void RequirePermission(string permissionCode);
    void RequirePlatformOperator();
}

public sealed class PermissionDeniedException : Exception
{
    public PermissionDeniedException(string message) : base(message) { }
}

public sealed class NotFoundException : Exception
{
    public NotFoundException(string message) : base(message) { }
}

public sealed class ConflictException : Exception
{
    public ConflictException(string message) : base(message) { }
}

public sealed class PermissionGate(ICurrentUser currentUser) : IPermissionGate
{
    public void RequireAuthenticated()
    {
        if (!currentUser.IsAuthenticated || currentUser.UserId is null)
        {
            throw new PermissionDeniedException("Authentication required.");
        }
    }

    public void RequireOrganization()
    {
        RequireAuthenticated();
        if (currentUser.OrganizationId is null || currentUser.MembershipId is null)
        {
            throw new PermissionDeniedException("Organization context required.");
        }
    }

    public void RequirePermission(string permissionCode)
    {
        RequireOrganization();
        if (currentUser.IsPlatformOperator)
        {
            return;
        }

        if (!currentUser.Permissions.Contains(permissionCode))
        {
            throw new PermissionDeniedException($"Missing permission: {permissionCode}");
        }
    }

    public void RequirePlatformOperator()
    {
        RequireAuthenticated();
        if (!currentUser.IsPlatformOperator)
        {
            throw new PermissionDeniedException("Platform operator role required.");
        }
    }
}
