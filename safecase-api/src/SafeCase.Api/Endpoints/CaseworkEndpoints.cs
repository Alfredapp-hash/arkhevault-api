using SafeCase.Application.Casework;
using SafeCase.Infrastructure.Services;

namespace SafeCase.Api.Endpoints;

public static class CaseworkEndpoints
{
    public static IEndpointRouteBuilder MapCaseworkEndpoints(this IEndpointRouteBuilder app)
    {
        var org = app.MapGroup("/api/v1/organizations/{organizationId:guid}")
            .WithTags("Casework")
            .RequireAuthorization();

        org.MapGet("/clients", async (Guid organizationId, CaseworkService casework, CancellationToken ct) =>
            Results.Ok(await casework.ListClientsAsync(organizationId, ct)));

        org.MapPost("/clients", async (
            Guid organizationId,
            CreateClientRequest request,
            CaseworkService casework,
            CancellationToken ct) =>
        {
            var created = await casework.CreateClientAsync(organizationId, request, ct);
            return Results.Created($"/api/v1/organizations/{organizationId}/clients/{created.Id}", created);
        });

        org.MapGet("/clients/{clientId:guid}", async (
            Guid organizationId,
            Guid clientId,
            CaseworkService casework,
            CancellationToken ct) =>
            Results.Ok(await casework.GetClientAsync(organizationId, clientId, ct)));

        org.MapGet("/clients/{clientId:guid}/cases", async (
            Guid organizationId,
            Guid clientId,
            CaseworkService casework,
            CancellationToken ct) =>
            Results.Ok(await casework.ListCasesForClientAsync(organizationId, clientId, ct)));

        org.MapPost("/clients/{clientId:guid}/cases", async (
            Guid organizationId,
            Guid clientId,
            CreateCaseRequest request,
            CaseworkService casework,
            CancellationToken ct) =>
        {
            var created = await casework.CreateCaseAsync(organizationId, clientId, request, ct);
            return Results.Created($"/api/v1/organizations/{organizationId}/cases/{created.Id}", created);
        });

        org.MapGet("/cases/{caseId:guid}", async (
            Guid organizationId,
            Guid caseId,
            CaseworkService casework,
            CancellationToken ct) =>
            Results.Ok(await casework.GetCaseAsync(organizationId, caseId, ct)));

        org.MapPost("/cases/{caseId:guid}/assignments", async (
            Guid organizationId,
            Guid caseId,
            CreateAssignmentRequest request,
            CaseworkService casework,
            CancellationToken ct) =>
        {
            var created = await casework.AssignAsync(organizationId, caseId, request, ct);
            return Results.Created(
                $"/api/v1/organizations/{organizationId}/cases/{caseId}/assignments/{created.Id}",
                created);
        });

        org.MapGet("/cases/{caseId:guid}/notes", async (
            Guid organizationId,
            Guid caseId,
            CaseworkService casework,
            CancellationToken ct) =>
            Results.Ok(await casework.ListNotesAsync(organizationId, caseId, ct)));

        org.MapPost("/cases/{caseId:guid}/notes", async (
            Guid organizationId,
            Guid caseId,
            CreateNoteRequest request,
            CaseworkService casework,
            CancellationToken ct) =>
        {
            var created = await casework.AddNoteAsync(organizationId, caseId, request, ct);
            return Results.Created(
                $"/api/v1/organizations/{organizationId}/cases/{caseId}/notes/{created.Id}",
                created);
        });

        org.MapGet("/cases/{caseId:guid}/tasks", async (
            Guid organizationId,
            Guid caseId,
            CaseworkService casework,
            CancellationToken ct) =>
            Results.Ok(await casework.ListTasksAsync(organizationId, caseId, ct)));

        org.MapPost("/cases/{caseId:guid}/tasks", async (
            Guid organizationId,
            Guid caseId,
            CreateTaskRequest request,
            CaseworkService casework,
            CancellationToken ct) =>
        {
            var created = await casework.AddTaskAsync(organizationId, caseId, request, ct);
            return Results.Created(
                $"/api/v1/organizations/{organizationId}/cases/{caseId}/tasks/{created.Id}",
                created);
        });

        org.MapGet("/cases/{caseId:guid}/timeline", async (
            Guid organizationId,
            Guid caseId,
            CaseworkService casework,
            CancellationToken ct) =>
            Results.Ok(await casework.GetTimelineAsync(organizationId, caseId, ct)));

        org.MapPost("/workflows/vertical-slice", async (
            Guid organizationId,
            CreateClientRequest request,
            CaseworkService casework,
            CancellationToken ct) =>
        {
            var result = await casework.RunVerticalSliceAsync(organizationId, request, ct);
            return Results.Ok(result);
        });

        return app;
    }
}
