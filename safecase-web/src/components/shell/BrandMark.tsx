import Link from "next/link";

interface BrandMarkProps {
  variant?: "hero" | "compact";
}

export function BrandMark({ variant = "compact" }: BrandMarkProps) {
  if (variant === "hero") {
    return (
      <div className="brand-hero">
        <Link href="/" className="brand-hero-link">
          <span className="brand-hero-mark" aria-hidden="true">
            SC
          </span>
          <span className="brand-hero-text">
            <span className="brand-hero-name">SafeCase</span>
            <span className="brand-hero-tagline">
              Victim services case management
            </span>
          </span>
        </Link>
      </div>
    );
  }

  return (
    <Link href="/" className="brand-compact">
      <span className="brand-compact-mark" aria-hidden="true">
        SC
      </span>
      <span className="brand-compact-name">SafeCase</span>
    </Link>
  );
}
