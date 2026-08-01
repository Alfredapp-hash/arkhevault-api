using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using SafeCase.Api.Auth;
using SafeCase.Api.Endpoints;
using SafeCase.Api.Middleware;
using SafeCase.Application;
using SafeCase.Infrastructure;
using SafeCase.Infrastructure.Persistence.Seed;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSafeCaseExceptionHandling();
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

builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

var entraTenantId = builder.Configuration["Entra:TenantId"];
var entraAudience = builder.Configuration["Entra:Audience"];
var entraConfigured = !string.IsNullOrWhiteSpace(entraTenantId) && !string.IsNullOrWhiteSpace(entraAudience);
var useDevAuth = builder.Configuration.GetValue("Auth:UseDevAuth", builder.Environment.IsDevelopment());

var authBuilder = builder.Services.AddAuthentication(options =>
{
    if (useDevAuth)
    {
        options.DefaultAuthenticateScheme = DevAuthenticationHandler.SchemeName;
        options.DefaultChallengeScheme = DevAuthenticationHandler.SchemeName;
    }
    else
    {
        options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    }
});

if (useDevAuth)
{
    authBuilder.AddScheme<AuthenticationSchemeOptions, DevAuthenticationHandler>(
        DevAuthenticationHandler.SchemeName,
        _ => { });
}

if (entraConfigured)
{
    authBuilder.AddJwtBearer(options =>
    {
        options.Authority = $"https://{builder.Configuration["Entra:AuthorityHost"] ?? $"{entraTenantId}.ciamlogin.com"}/{entraTenantId}/v2.0/";
        options.Audience = entraAudience;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            NameClaimType = "name"
        };
    });
}

builder.Services.AddAuthorization();
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
app.UseAuthentication();
app.UseMiddleware<CurrentUserMiddleware>();
app.UseAuthorization();

app.MapGet("/", () => Results.Ok(new
{
    service = "SafeCase.Api",
    version = "0.2.0",
    status = "ok",
    authConfigured = entraConfigured,
    devAuth = useDevAuth
}));

app.MapHealthChecks("/health", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("live")
});
app.MapHealthChecks("/health/ready", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready")
});

app.MapIdentityEndpoints();

if (builder.Configuration.GetValue("Seed:Enabled", app.Environment.IsDevelopment()))
{
    await DevDataSeeder.SeedAsync(app.Services);
}

app.Run();

public partial class Program;
