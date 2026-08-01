import { ClientsPageContent } from "@/features/clients";

export default function ClientsPage() {
  return (
    <section>
      <header className="page-header">
        <h1 className="page-title">Clients</h1>
        <p className="page-lead">
          View and create client records for your organization.
        </p>
      </header>
      <ClientsPageContent />
    </section>
  );
}
