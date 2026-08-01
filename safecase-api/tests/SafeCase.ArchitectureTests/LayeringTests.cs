using NetArchTest.Rules;

namespace SafeCase.ArchitectureTests;

public class LayeringTests
{
    [Fact]
    public void Domain_Should_Not_Reference_Infrastructure_Or_Api()
    {
        var result = Types.InAssembly(typeof(SafeCase.Domain.Common.Entity).Assembly)
            .ShouldNot()
            .HaveDependencyOnAny("SafeCase.Infrastructure", "SafeCase.Api", "SafeCase.Application")
            .GetResult();

        Assert.True(result.IsSuccessful, string.Join(", ", result.FailingTypeNames ?? []));
    }

    [Fact]
    public void Application_Should_Not_Reference_Api_Or_Infrastructure()
    {
        var result = Types.InAssembly(typeof(SafeCase.Application.Common.PermissionCodes).Assembly)
            .ShouldNot()
            .HaveDependencyOnAny("SafeCase.Infrastructure", "SafeCase.Api")
            .GetResult();

        Assert.True(result.IsSuccessful, string.Join(", ", result.FailingTypeNames ?? []));
    }
}
