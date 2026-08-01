interface ModulePlaceholderProps {
  title: string;
  description: string;
}

export function ModulePlaceholder({ title, description }: ModulePlaceholderProps) {
  return (
    <section className="module-placeholder">
      <header className="page-header">
        <h1 className="page-title">{title}</h1>
        <p className="page-lead">{description}</p>
      </header>
    </section>
  );
}
