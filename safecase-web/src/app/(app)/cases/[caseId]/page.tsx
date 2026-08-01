import { CaseDetailContent } from "@/features/cases";

interface CaseDetailPageProps {
  params: Promise<{ caseId: string }>;
}

export default async function CaseDetailPage({ params }: CaseDetailPageProps) {
  const { caseId } = await params;

  return (
    <section>
      <header className="page-header">
        <h1 className="page-title">Case detail</h1>
      </header>
      <CaseDetailContent caseId={caseId} />
    </section>
  );
}
