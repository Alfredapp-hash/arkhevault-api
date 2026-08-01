using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace SafeCase.Infrastructure.Persistence;

public sealed class SafeCaseDbContextFactory : IDesignTimeDbContextFactory<SafeCaseDbContext>
{
    public SafeCaseDbContext CreateDbContext(string[] args)
    {
        var options = new DbContextOptionsBuilder<SafeCaseDbContext>()
            .UseNpgsql(
                "Host=localhost;Port=5432;Database=safecase;Username=safecase;Password=safecase_dev_only",
                npgsql => npgsql.MigrationsHistoryTable("__EFMigrationsHistory", "public"))
            .Options;

        return new SafeCaseDbContext(options, new OrganizationContext());
    }
}
