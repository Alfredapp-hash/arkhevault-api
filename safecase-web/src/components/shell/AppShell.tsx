import { BrandMark } from "./BrandMark";
import { OrgSelector } from "./OrgSelector";
import { AppNav } from "./AppNav";
import { UserMenu } from "./UserMenu";

interface AppShellProps {
  children: React.ReactNode;
}

export function AppShell({ children }: AppShellProps) {
  return (
    <div className="app-shell">
      <header className="app-header">
        <div className="app-header-brand">
          <BrandMark variant="hero" />
        </div>
        <div className="app-header-controls">
          <OrgSelector />
          <UserMenu />
        </div>
      </header>

      <div className="app-body">
        <aside className="app-sidebar">
          <AppNav />
        </aside>
        <main className="app-main">{children}</main>
      </div>
    </div>
  );
}
