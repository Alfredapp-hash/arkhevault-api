using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SafeCase.Application.Abstractions;
using SafeCase.Infrastructure.Persistence;
using SafeCase.Infrastructure.Services;

namespace SafeCase.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddScoped<CurrentUser>();
        services.AddScoped<ICurrentUser>(sp => sp.GetRequiredService<CurrentUser>());
        services.AddScoped<OrganizationContext>();
        services.AddScoped<IOrganizationContext>(sp => sp.GetRequiredService<OrganizationContext>());
        services.AddScoped<TenantConnectionInterceptor>();
        services.AddScoped<IAuditService, AuditService>();
        services.AddScoped<MeService>();
        services.AddScoped<OrganizationService>();
        services.AddScoped<MembershipService>();
        services.AddScoped<CaseworkService>();

        var connectionString = configuration.GetConnectionString("SafeCase")
            ?? configuration["DATABASE_URL"]
            ?? "Host=localhost;Port=5432;Database=safecase;Username=safecase;Password=safecase_dev_only";

        services.AddDbContext<SafeCaseDbContext>((sp, options) =>
        {
            options.UseNpgsql(connectionString, npgsql =>
                npgsql.MigrationsHistoryTable("__EFMigrationsHistory", "public"));
            options.AddInterceptors(sp.GetRequiredService<TenantConnectionInterceptor>());
        });

        return services;
    }
}
