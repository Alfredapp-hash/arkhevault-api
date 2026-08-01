using Microsoft.AspNetCore.Diagnostics;
using SafeCase.Application.Abstractions;

namespace SafeCase.Api.Middleware;

public static class ExceptionHandlingExtensions
{
    public static IServiceCollection AddSafeCaseExceptionHandling(this IServiceCollection services)
    {
        services.AddProblemDetails(options =>
        {
            options.CustomizeProblemDetails = context =>
            {
                context.ProblemDetails.Extensions["traceId"] =
                    context.HttpContext.TraceIdentifier;
            };
        });

        services.AddExceptionHandler<SafeCaseExceptionHandler>();
        return services;
    }
}

public sealed class SafeCaseExceptionHandler(IProblemDetailsService problemDetailsService) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        var (status, title, type) = exception switch
        {
            PermissionDeniedException => (StatusCodes.Status403Forbidden, "Forbidden", "https://safecase.org/problems/forbidden"),
            NotFoundException => (StatusCodes.Status404NotFound, "Not Found", "https://safecase.org/problems/not-found"),
            ConflictException => (StatusCodes.Status409Conflict, "Conflict", "https://safecase.org/problems/conflict"),
            _ => (StatusCodes.Status500InternalServerError, "Server Error", "https://safecase.org/problems/server-error")
        };

        // Avoid leaking internals on unexpected errors.
        var detail = status >= 500 ? "An unexpected error occurred." : exception.Message;

        httpContext.Response.StatusCode = status;
        return await problemDetailsService.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = httpContext,
            Exception = exception,
            ProblemDetails =
            {
                Status = status,
                Title = title,
                Type = type,
                Detail = detail
            }
        });
    }
}
