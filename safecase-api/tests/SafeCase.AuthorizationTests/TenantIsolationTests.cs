using System.Net;
using System.Net.Http.Json;
using SafeCase.Infrastructure.Persistence.Seed;

namespace SafeCase.AuthorizationTests;

public class TenantIsolationTests : IClassFixture<SafeCaseApiFactory>
{
    private readonly SafeCaseApiFactory _factory;

    public TenantIsolationTests(SafeCaseApiFactory factory)
    {
        _factory = factory;
    }

    private HttpClient CreateClient(string entraId, Guid? organizationId = null, string? email = null)
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Dev-User", entraId);
        if (email is not null)
        {
            client.DefaultRequestHeaders.Add("X-Dev-Email", email);
        }

        if (organizationId is not null)
        {
            client.DefaultRequestHeaders.Add("X-Organization-Id", organizationId.Value.ToString());
        }

        return client;
    }

    [Fact]
    public async Task Me_Provisions_And_Returns_Memberships()
    {
        using var client = CreateClient(
            DevDataSeeder.OrgAAdminEntraId,
            email: "admin.a@safecase.local");
        var response = await client.GetAsync("/api/v1/me");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("admin.a@safecase.local", body);
        Assert.Contains("north-county", body);
    }

    [Fact]
    public async Task OrgA_Admin_Cannot_List_OrgB_Clients()
    {
        using var client = CreateClient(DevDataSeeder.OrgAAdminEntraId, DevDataSeeder.OrgBId);
        var response = await client.GetAsync($"/api/v1/organizations/{DevDataSeeder.OrgBId}/clients");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task OrgA_Admin_Can_List_OrgA_Clients_Only()
    {
        using var client = CreateClient(DevDataSeeder.OrgAAdminEntraId, DevDataSeeder.OrgAId);
        var response = await client.GetAsync($"/api/v1/organizations/{DevDataSeeder.OrgAId}/clients");
        response.EnsureSuccessStatusCode();
        var payload = await response.Content.ReadFromJsonAsync<List<ClientDto>>();
        Assert.NotNull(payload);
        Assert.All(payload, c => Assert.Equal(DevDataSeeder.OrgAId, c.OrganizationId));
        Assert.DoesNotContain(payload, c => c.LastName == "Lee");
        Assert.Contains(payload, c => c.LastName == "Rivera");
    }

    [Fact]
    public async Task OrgB_Admin_Sees_Only_OrgB_Clients()
    {
        using var client = CreateClient(DevDataSeeder.OrgBAdminEntraId, DevDataSeeder.OrgBId);
        var response = await client.GetAsync($"/api/v1/organizations/{DevDataSeeder.OrgBId}/clients");
        response.EnsureSuccessStatusCode();
        var payload = await response.Content.ReadFromJsonAsync<List<ClientDto>>();
        Assert.NotNull(payload);
        Assert.All(payload, c => Assert.Equal(DevDataSeeder.OrgBId, c.OrganizationId));
        Assert.Contains(payload, c => c.LastName == "Lee");
        Assert.DoesNotContain(payload, c => c.LastName == "Rivera");
    }

    [Fact]
    public async Task Advocate_Cannot_Manage_Users()
    {
        using var client = CreateClient(DevDataSeeder.OrgAAdvocateEntraId, DevDataSeeder.OrgAId);
        var response = await client.GetAsync($"/api/v1/organizations/{DevDataSeeder.OrgAId}/memberships");
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Disabled_Membership_Blocks_Org_Access()
    {
        using var admin = CreateClient(
            DevDataSeeder.OrgAAdminEntraId,
            DevDataSeeder.OrgAId,
            email: "admin.a@safecase.local");

        // Create a disposable membership so other tests keep the seeded advocate intact.
        var created = await admin.PostAsJsonAsync(
            $"/api/v1/organizations/{DevDataSeeder.OrgAId}/memberships",
            new
            {
                email = "temp.disable@safecase.local",
                displayName = "Temp Disable",
                entraObjectId = "dev-temp-disable",
                roleCode = "advocate"
            });
        created.EnsureSuccessStatusCode();
        var membership = await created.Content.ReadFromJsonAsync<MembershipDto>();
        Assert.NotNull(membership);

        var disableResponse = await admin.PostAsJsonAsync(
            $"/api/v1/organizations/{DevDataSeeder.OrgAId}/memberships/{membership.Id}/disable",
            new { reason = "test_disable" });
        disableResponse.EnsureSuccessStatusCode();

        using var disabledClient = CreateClient("dev-temp-disable", DevDataSeeder.OrgAId);
        var blocked = await disabledClient.GetAsync($"/api/v1/organizations/{DevDataSeeder.OrgAId}/clients");
        Assert.Equal(HttpStatusCode.NotFound, blocked.StatusCode);
    }

    [Fact]
    public async Task Unknown_Org_Id_Does_Not_Leak_Existence()
    {
        using var client = CreateClient(DevDataSeeder.OrgAAdminEntraId, Guid.Parse("99999999-9999-9999-9999-999999999999"));
        var response = await client.GetAsync("/api/v1/organizations/99999999-9999-9999-9999-999999999999/clients");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.DoesNotContain("Rivera", body);
        Assert.DoesNotContain("Lee", body);
    }

    private sealed record ClientDto(Guid Id, Guid OrganizationId, string FirstName, string LastName, string Status);
    private sealed record MembershipDto(Guid Id, string Email, bool IsActive);
}
