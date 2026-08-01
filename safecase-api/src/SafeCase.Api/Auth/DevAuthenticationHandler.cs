using System.Security.Claims;
using System.Text.Encodings.Web;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;

namespace SafeCase.Api.Auth;

/// <summary>
/// Development-only authentication. Send header:
/// X-Dev-User: &lt;entra-object-id&gt;
/// Optional: X-Dev-Email, X-Dev-Name
/// Never enable in production deployments with real data.
/// </summary>
public sealed class DevAuthenticationHandler(
    IOptionsMonitor<AuthenticationSchemeOptions> options,
    ILoggerFactory logger,
    UrlEncoder encoder) : AuthenticationHandler<AuthenticationSchemeOptions>(options, logger, encoder)
{
    public const string SchemeName = "Dev";

    protected override Task<AuthenticateResult> HandleAuthenticateAsync()
    {
        if (!Request.Headers.TryGetValue("X-Dev-User", out var userValues))
        {
            return Task.FromResult(AuthenticateResult.NoResult());
        }

        var entraId = userValues.ToString();
        if (string.IsNullOrWhiteSpace(entraId))
        {
            return Task.FromResult(AuthenticateResult.Fail("X-Dev-User empty."));
        }

        var email = Request.Headers.TryGetValue("X-Dev-Email", out var emailValues)
            ? emailValues.ToString()
            : $"{entraId}@safecase.local";
        var name = Request.Headers.TryGetValue("X-Dev-Name", out var nameValues)
            ? nameValues.ToString()
            : entraId;

        var claims = new[]
        {
            new Claim("oid", entraId),
            new Claim(ClaimTypes.NameIdentifier, entraId),
            new Claim("preferred_username", email),
            new Claim(ClaimTypes.Email, email),
            new Claim("name", name),
            new Claim(ClaimTypes.Name, name)
        };

        var identity = new ClaimsIdentity(claims, SchemeName);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new AuthenticationTicket(principal, SchemeName);
        return Task.FromResult(AuthenticateResult.Success(ticket));
    }
}
