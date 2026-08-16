import { useState } from "react";
import { toast } from "sonner";
import { BlurFade } from "@/components/ui/blur-fade";
import { Card } from "@/components/Card";
import { Button } from "@/components/Button";
import { Confirm } from "@/components/Confirm";
import { ScreenHeader } from "@/components/ScreenHeader";
import {
  daysSince,
  localISODate,
  parseData,
  type AppData,
} from "@/lib/storage";
import { plural } from "@/lib/format";
import type { View } from "@/App";

/* Losing the history destroys the value of the app, so this is a first-class
 * screen rather than a settings footnote. Export is one tap and hands the JSON
 * to the iOS share sheet, which is the only route that reliably gets a file
 * off a home-screen PWA and into Files / Notes / a mail draft. */

interface Props {
  data: AppData;
  onBackedUp: () => void;
  onRestore: (next: AppData) => void;
  onErase: () => void;
  onNavigate: (view: View) => void;
}

export function Backup({
  data,
  onBackedUp,
  onRestore,
  onErase,
  onNavigate,
}: Props) {
  const [pasted, setPasted] = useState("");
  const [pendingRestore, setPendingRestore] = useState<AppData | null>(null);
  const [confirmErase, setConfirmErase] = useState(false);

  const since = daysSince(data.lastBackup);
  const count = data.history.length;

  const statusTone =
    since === null ? "border-l-rose" : since > 14 ? "border-l-[var(--accent)]" : "border-l-emerald";

  const statusText =
    since === null
      ? "Never backed up."
      : since === 0
        ? "Backed up today."
        : `Last backup ${since} ${plural(since, "day")} ago.`;

  const exportAndShare = async () => {
    const json = JSON.stringify(data, null, 1);
    const filename = `morning-backup-${localISODate()}.json`;

    try {
      const file = new File([json], filename, { type: "application/json" });
      if (navigator.canShare?.({ files: [file] })) {
        await navigator.share({ files: [file], title: "Morning backup" });
        onBackedUp();
        toast.success("Backed up");
        return;
      }
    } catch (err) {
      // Dismissing the share sheet is a deliberate cancel, not a failure.
      if (err instanceof Error && err.name === "AbortError") return;
    }

    // Desktop / unsupported: fall back to a plain download.
    const url = URL.createObjectURL(new Blob([json], { type: "application/json" }));
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
    onBackedUp();
    toast.success("Backup downloaded");
  };

  const copyAsText = async () => {
    try {
      await navigator.clipboard.writeText(JSON.stringify(data));
      onBackedUp();
      toast.success("Copied", { description: "Paste it into Notes." });
    } catch {
      toast.error("Couldn't copy to the clipboard");
    }
  };

  const stageRestore = () => {
    let parsed: AppData | null = null;
    try {
      parsed = parseData(JSON.parse(pasted));
    } catch {
      parsed = null;
    }
    if (!parsed) {
      toast.error("That doesn't look like a backup");
      return;
    }
    setPendingRestore(parsed);
  };

  return (
    <div>
      <ScreenHeader title="Backup" onNavigate={onNavigate} />

      <BlurFade delay={0.04} inView>
        <div
          className={`mb-4 rounded-r-[var(--radius-control)] border-l-2 bg-white/[0.035] px-4 py-3 ${statusTone}`}
        >
          <p className="text-[0.9rem] text-ink">{statusText}</p>
          <p className="tnum mt-0.5 text-[0.84rem] text-muted">
            {count} {plural(count, "session")} stored on this phone.
          </p>
        </div>

        <Card className="mb-5">
          <p className="text-[0.88rem] leading-relaxed text-muted">
            Your data lives in this app&apos;s storage on your phone. That
            survives restarts and updates — but not deleting the icon, not
            &ldquo;Clear History and Website Data&rdquo;, and not a new phone.
            One tap here covers all three.
          </p>
        </Card>

        <Button variant="primary" onClick={exportAndShare}>
          Export &amp; share
        </Button>
        <Button className="mt-3" onClick={copyAsText}>
          Copy as text
        </Button>
      </BlurFade>

      <BlurFade delay={0.1} inView>
        <h2 className="mt-9 mb-2.5 text-[1.02rem] font-semibold text-ink">
          Restore
        </h2>
        <textarea
          value={pasted}
          onChange={(e) => setPasted(e.target.value)}
          placeholder="Paste a backup here…"
          spellCheck={false}
          autoCapitalize="off"
          autoCorrect="off"
          className="min-h-[120px] w-full resize-y rounded-[var(--radius-control)] border border-hairline bg-black/25 p-3.5 font-mono text-[0.78rem] leading-relaxed text-ink select-text placeholder:text-dim focus:border-[var(--accent-line)] focus:outline-none"
        />
        <Button className="mt-2.5" onClick={stageRestore}>
          Restore from pasted text
        </Button>
      </BlurFade>

      <BlurFade delay={0.16} inView>
        <div className="mt-12 mb-2">
          <Button variant="danger" onClick={() => setConfirmErase(true)}>
            Erase everything
          </Button>
        </div>
      </BlurFade>

      <Confirm
        open={pendingRestore !== null}
        onOpenChange={(open) => !open && setPendingRestore(null)}
        title="Replace your history?"
        description={
          <>
            This swaps the{" "}
            <b className="tnum text-ink">
              {count} {plural(count, "session")}
            </b>{" "}
            on this phone for{" "}
            <b className="tnum text-ink">
              {pendingRestore?.history.length ?? 0}{" "}
              {plural(pendingRestore?.history.length ?? 0, "session")}
            </b>{" "}
            from the backup. What&apos;s here now is gone.
          </>
        }
        confirmLabel="Replace"
        destructive
        onConfirm={() => {
          if (pendingRestore) {
            onRestore(pendingRestore);
            setPasted("");
            toast.success("Restored");
            onNavigate("home");
          }
          setPendingRestore(null);
        }}
      />

      <Confirm
        open={confirmErase}
        onOpenChange={setConfirmErase}
        title="Delete all history?"
        description="Every session on this phone, gone. This can't be undone, and there's no cloud copy."
        confirmLabel="Erase everything"
        destructive
        onConfirm={() => {
          onErase();
          toast.success("Erased");
          onNavigate("home");
        }}
      />
    </div>
  );
}
