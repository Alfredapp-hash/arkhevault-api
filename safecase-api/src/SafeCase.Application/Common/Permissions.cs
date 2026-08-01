namespace SafeCase.Application.Common;

public static class PermissionCodes
{
    public const string ClientRead = "client.read";
    public const string ClientCreate = "client.create";
    public const string ClientUpdateIdentity = "client.update_identity";
    public const string CaseRead = "case.read";
    public const string CaseAssign = "case.assign";
    public const string CaseClose = "case.close";
    public const string NoteCreate = "note.create";
    public const string NoteReadRestricted = "note.read_restricted";
    public const string DocumentUpload = "document.upload";
    public const string DocumentDownload = "document.download";
    public const string DocumentShare = "document.share";
    public const string ConsentManage = "consent.manage";
    public const string ReportGenerate = "report.generate";
    public const string AuditReview = "audit.review";
    public const string OrganizationManageUsers = "organization.manage_users";

    public static readonly string[] All =
    [
        ClientRead, ClientCreate, ClientUpdateIdentity,
        CaseRead, CaseAssign, CaseClose,
        NoteCreate, NoteReadRestricted,
        DocumentUpload, DocumentDownload, DocumentShare,
        ConsentManage, ReportGenerate, AuditReview, OrganizationManageUsers
    ];
}

public static class RoleCodes
{
    public const string PlatformOperator = "platform_operator";
    public const string OrganizationOwner = "organization_owner";
    public const string OrganizationAdministrator = "organization_administrator";
    public const string ProgramDirector = "program_director";
    public const string Supervisor = "supervisor";
    public const string Advocate = "advocate";
    public const string IntakeSpecialist = "intake_specialist";
    public const string ReferralPartner = "referral_partner";
    public const string ReportAnalyst = "report_analyst";
    public const string Auditor = "auditor";
    public const string ReadOnlyReviewer = "read_only_reviewer";
}
