using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SafeCase.Infrastructure;
using SafeCase.Infrastructure.Persistence;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddProblemDetails();
builder.Services.AddOpenApi();
builder.Services.AddHealthChecks()
    .AddCheck("self", () => Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy(), tags: ["live"])
    .AddNpgSql(
        builder.Configuration.GetConnectionString("SafeCase")
            ?? builder.Configuration["DATABASE_URL"]
            ?? "Host=localhost;Port=5432;Database=safecase;Username=safecase;Password=safecase_dev_only",
        name: "postgres",
        failureStatus: Microsoft.Extensions.Diagnostics.HealthChecks.HealthStatus.Degraded,
        tags: ["ready"]);

builder.Services.AddInfrastructure(builder.Configuration);

var entraTenantId = builder.Configuration["Entra:TenantId"];
var entraAudience = builder.Configuration["Entra:Audience"];
var authEnabled = !string.IsNullOrWhiteSpace(entraTenantId) && !string.IsNullOrWhiteSpace(entraAudience);

if (authEnabled)
{
    builder.Services
        .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.Authority = $"https://{builder.Configuration["Entra:AuthorityHost"] ?? $"{entraTenantId}.ciamlogin.com"}/{entraTenantId}/v2.0/";
            options.Audience = entraAudience;
            options.TokenValidationParameters = new TokenValidationParameters
            {
                ValidateIssuer = true,
                NameClaimType = "name",
                RoleClaimType = ClaimTypes.Role
            };
        });
    builder.Services.AddAuthorization();
}
else
{
    // Local/dev skeleton only — never the production default once Entra is configured.
    builder.Services.AddAuthorization();
}

builder.Services.AddCors(options =>
{
    options.AddPolicy("WebPilot", policy =>
    {
        var origins = builder.Configuration.GetSection("Cors:Origins").Get<string[]>()
            ?? ["http://localhost:3000"];
        policy.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod();
    });
});

var app = builder.Build();

app.UseExceptionHandler();
app.UseStatusCodePages();

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseCors("WebPilot");

if (authEnabled)
{
    app.UseAuthentication();
}
app.UseAuthorization();

app.MapGet("/", () => Results.Ok(new
{
    service = "SafeCase.Api",
    version = "0.1.0",
    status = "ok",
    authConfigured = authEnabled
}));

app.MapHealthChecks("/health", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("live")
});
app.MapHealthChecks("/health/ready", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});

app.MapGet("/api/v1/me", (ClaimsPrincipal user) =>
{
    if (!authEnabled)
    {
        return Results.Ok(new
        {
            mode = "development-unauthenticated",
            message = "Configure Entra:TenantId and Entra:Audience to enable JWT auth.",
            memberships = Array.Empty<object>()
        });
    }

    if (user.Identity?.IsAuthenticated != true)
    {
        return Results.Unauthorized();
    }

    return Results.Ok(new
    {
        entraObjectId = user.FindFirstValue("oid") ?? user.FindFirstValue(ClaimTypes.NameIdentifier),
        name = user.FindFirstValue("name") ?? user.Identity?.Name,
        email = user.FindFirstValue("preferred_username") ?? user.FindFirstValue(ClaimTypes.Email),
        memberships = Array.Empty<object>()
    });
}).WithName("GetMe");

app.Run();

public partial class Program;
