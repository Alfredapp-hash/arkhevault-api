using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SafeCase.Infrastructure.Persistence.Seed;

namespace SafeCase.AuthorizationTests;

public sealed class SafeCaseApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    protected override void ConfigureWebHost(Microsoft.AspNetCore.Hosting.IWebHostBuilder builder)
    {
        builder.ConfigureAppConfiguration((_, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Auth:UseDevAuth"] = "true",
                // Seed explicitly once in InitializeAsync to avoid host-start races.
                ["Seed:Enabled"] = "false",
                ["ConnectionStrings:SafeCase"] =
                    "Host=127.0.0.1;Port=5432;Database=safecase;Username=safecase;Password=safecase_dev_only"
            });
        });
    }

    public async Task InitializeAsync()
    {
        // Force server creation, then seed once.
        _ = CreateClient();
        await DevDataSeeder.SeedAsync(Services);
    }

    async Task IAsyncLifetime.DisposeAsync()
    {
        await DisposeAsync();
    }
}
