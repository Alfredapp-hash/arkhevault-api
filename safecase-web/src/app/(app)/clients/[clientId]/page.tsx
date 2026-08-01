import { ClientDetailContent } from "@/features/clients";

interface ClientDetailPageProps {
  params: Promise<{ clientId: string }>;
}

export default async function ClientDetailPage({ params }: ClientDetailPageProps) {
  const { clientId } = await params;

  return (
    <section>
      <header className="page-header">
        <h1 className="page-title">Client detail</h1>
      </header>
      <ClientDetailContent clientId={clientId} />
    </section>
  );
}
