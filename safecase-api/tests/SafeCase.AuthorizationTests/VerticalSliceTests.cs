using System.Net;
using System.Net.Http.Json;
using SafeCase.Infrastructure.Persistence.Seed;

namespace SafeCase.AuthorizationTests;

public class VerticalSliceTests : IClassFixture<SafeCaseApiFactory>
{
    private readonly SafeCaseApiFactory _factory;

    public VerticalSliceTests(SafeCaseApiFactory factory) => _factory = factory;

    private HttpClient CreateClient(string entraId, Guid orgId, string? email = null)
    {
        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Dev-User", entraId);
        if (email is not null)
        {
            client.DefaultRequestHeaders.Add("X-Dev-Email", email);
        }

        client.DefaultRequestHeaders.Add("X-Organization-Id", orgId.ToString());
        return client;
    }

    [Fact]
    public async Task Vertical_Slice_Completes_For_OrgA_Admin()
    {
        using var client = CreateClient(
            DevDataSeeder.OrgAAdminEntraId,
            DevDataSeeder.OrgAId,
            "admin.a@safecase.local");

        var response = await client.PostAsJsonAsync(
            $"/api/v1/organizations/{DevDataSeeder.OrgAId}/workflows/vertical-slice",
            new
            {
                firstName = "Sam",
                lastName = "Quill",
                riskLevel = "moderate",
                openInitialCase = true,
                caseTitle = "Pilot intake"
            });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<SliceDto>();
        Assert.NotNull(body);
        Assert.Equal("Sam", body.Client.FirstName);
        Assert.Equal("Quill", body.Client.LastName);
        Assert.Equal(DevDataSeeder.OrgAId, body.Client.OrganizationId);
        Assert.Equal("open", body.Case.Status);
        Assert.False(string.IsNullOrWhiteSpace(body.Note.Narrative));
        Assert.Equal("Complete safety screening", body.Task.Title);
        Assert.True(body.Timeline.Count >= 5);

        var timeline = await client.GetFromJsonAsync<List<TimelineDto>>(
            $"/api/v1/organizations/{DevDataSeeder.OrgAId}/cases/{body.Case.Id}/timeline");
        Assert.NotNull(timeline);
        Assert.Contains(timeline, t => t.EventType == "case.assigned");
        Assert.Contains(timeline, t => t.EventType == "note.created");
        Assert.Contains(timeline, t => t.EventType == "task.created");

        var audits = await client.GetFromJsonAsync<List<AuditDto>>(
            $"/api/v1/organizations/{DevDataSeeder.OrgAId}/audit-events");
        Assert.NotNull(audits);
        Assert.Contains(audits, a => a.Action == "workflow.vertical_slice");
    }

    [Fact]
    public async Task OrgB_Cannot_Read_OrgA_Case_By_Id()
    {
        using var orgA = CreateClient(
            DevDataSeeder.OrgAAdminEntraId,
            DevDataSeeder.OrgAId,
            "admin.a@safecase.local");

        var created = await orgA.PostAsJsonAsync(
            $"/api/v1/organizations/{DevDataSeeder.OrgAId}/workflows/vertical-slice",
            new { firstName = "Hidden", lastName = "Case", openInitialCase = true });
        created.EnsureSuccessStatusCode();
        var slice = await created.Content.ReadFromJsonAsync<SliceDto>();
        Assert.NotNull(slice);

        using var orgB = CreateClient(
            DevDataSeeder.OrgBAdminEntraId,
            DevDataSeeder.OrgBId,
            "admin.b@safecase.local");

        var leak = await orgB.GetAsync(
            $"/api/v1/organizations/{DevDataSeeder.OrgBId}/cases/{slice.Case.Id}");
        Assert.Equal(HttpStatusCode.NotFound, leak.StatusCode);

        var crossOrg = await orgB.GetAsync(
            $"/api/v1/organizations/{DevDataSeeder.OrgAId}/cases/{slice.Case.Id}");
        Assert.Equal(HttpStatusCode.NotFound, crossOrg.StatusCode);
    }

    private sealed record SliceDto(
        ClientDto Client,
        CaseDto Case,
        NoteDto Note,
        TaskDto Task,
        List<TimelineDto> Timeline);

    private sealed record ClientDto(Guid Id, Guid OrganizationId, string FirstName, string LastName);
    private sealed record CaseDto(Guid Id, string Status);
    private sealed record NoteDto(string? Narrative);
    private sealed record TaskDto(string Title);
    private sealed record TimelineDto(string EventType);
    private sealed record AuditDto(string Action);
}
