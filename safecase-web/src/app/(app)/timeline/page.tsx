import { TimelinePageContent } from "@/features/timeline";

export default function TimelinePage() {
  return (
    <section>
      <header className="page-header">
        <h1 className="page-title">Timeline</h1>
        <p className="page-lead">
          Activity history for the case you most recently opened.
        </p>
      </header>
      <TimelinePageContent />
    </section>
  );
}
