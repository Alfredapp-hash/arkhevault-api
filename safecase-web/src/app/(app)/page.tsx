export default function DashboardPage() {
  return (
    <section className="dashboard-placeholder">
      <header className="page-header">
        <h1 className="page-title">Dashboard</h1>
        <p className="page-lead">
          Your caseload overview will appear here once modules are connected to
          the SafeCase API.
        </p>
      </header>

      <div className="dashboard-focus">
        <p className="dashboard-focus-text">
          This pilot shell provides navigation, organization context, and Entra
          authentication placeholders. Feature modules will live under{" "}
          <code className="inline-code">src/features/</code>.
        </p>
      </div>
    </section>
  );
}
