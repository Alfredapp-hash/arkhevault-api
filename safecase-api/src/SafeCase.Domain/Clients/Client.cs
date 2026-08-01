using SafeCase.Domain.Common;

namespace SafeCase.Domain.Clients;

public class Client : TenantEntity
{
    public string Status { get; set; } = "active";
    public string? RiskLevel { get; set; }
    public Guid? CreatedByMembershipId { get; set; }

    public ClientIdentity? Identity { get; set; }
    public ICollection<ClientContactMethod> ContactMethods { get; set; } = [];
    public ICollection<Cases.Case> Cases { get; set; } = [];
}

public class ClientIdentity : TenantEntity
{
    public Guid ClientId { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public DateOnly? DateOfBirth { get; set; }

    public Client? Client { get; set; }
}

public class ClientContactMethod : TenantEntity
{
    public Guid ClientId { get; set; }
    public string MethodType { get; set; } = string.Empty; // email, phone, other
    public string Value { get; set; } = string.Empty;
    public bool IsSafeToUse { get; set; } = true;
    public bool IsPrimary { get; set; }

    public Client? Client { get; set; }
}
