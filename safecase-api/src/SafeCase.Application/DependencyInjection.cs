using Microsoft.Extensions.DependencyInjection;
using SafeCase.Application.Abstractions;

namespace SafeCase.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<IPermissionGate, PermissionGate>();
        return services;
    }
}
