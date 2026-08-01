import { VerticalSliceButton } from "@/features/dashboard";

export default function DashboardPage() {
  return (
    <section className="dashboard-placeholder">
      <header className="page-header">
        <h1 className="page-title">Dashboard</h1>
        <p className="page-lead">
          Your caseload overview and pilot workflows for the SafeCase API.
        </p>
      </header>

      <div className="dashboard-focus">
        <VerticalSliceButton />
      </div>
    </section>
  );
}
