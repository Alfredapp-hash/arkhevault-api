using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SafeCase.Infrastructure.Persistence;

namespace SafeCase.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddScoped<OrganizationContext>();
        services.AddScoped<IOrganizationContext>(sp => sp.GetRequiredService<OrganizationContext>());
        services.AddScoped<TenantConnectionInterceptor>();

        var connectionString = configuration.GetConnectionString("SafeCase")
            ?? configuration["DATABASE_URL"]
            ?? "Host=localhost;Port=5432;Database=safecase;Username=safecase;Password=safecase_dev_only";

        services.AddDbContext<SafeCaseDbContext>((sp, options) =>
        {
            options.UseNpgsql(connectionString);
            options.AddInterceptors(sp.GetRequiredService<TenantConnectionInterceptor>());
        });

        return services;
    }
}
