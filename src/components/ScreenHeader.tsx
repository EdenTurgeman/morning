import type { View } from "@/App";

export function ScreenHeader({
  title,
  onNavigate,
}: {
  title: string;
  onNavigate: (view: View) => void;
}) {
  return (
    <header className="mb-5 flex items-center justify-between">
      <h1 className="text-[1.55rem] font-bold tracking-[-0.03em] text-ink">
        {title}
      </h1>
      <button
        onClick={() => onNavigate("home")}
        className="-mr-2 rounded-full px-3 py-2 text-[0.85rem] text-muted"
      >
        ‹ Home
      </button>
    </header>
  );
}
