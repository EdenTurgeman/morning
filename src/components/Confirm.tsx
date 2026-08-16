import * as AlertDialog from "@radix-ui/react-alert-dialog";
import type { ReactNode } from "react";

/* Replaces window.confirm, which in a standalone PWA renders as a jarring
 * system sheet with the site's URL in it. Radix gives us focus trapping and
 * escape handling for free. */

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description: ReactNode;
  confirmLabel: string;
  cancelLabel?: string;
  destructive?: boolean;
  onConfirm: () => void;
}

export function Confirm({
  open,
  onOpenChange,
  title,
  description,
  confirmLabel,
  cancelLabel = "Cancel",
  destructive = false,
  onConfirm,
}: Props) {
  return (
    <AlertDialog.Root open={open} onOpenChange={onOpenChange}>
      <AlertDialog.Portal>
        <AlertDialog.Overlay className="fixed inset-0 z-50 bg-black/70 backdrop-blur-[3px] data-[state=open]:animate-[fadeIn_180ms_ease-out]" />
        <AlertDialog.Content
          className="surface fixed top-1/2 left-1/2 z-50 w-[min(23rem,calc(100vw-2.5rem))] -translate-x-1/2 -translate-y-1/2 rounded-[var(--radius-card)] p-6 data-[state=open]:animate-[popIn_220ms_var(--ease-out-expo)]"
        >
          <AlertDialog.Title className="text-[1.15rem] font-semibold tracking-[-0.01em] text-ink">
            {title}
          </AlertDialog.Title>
          <AlertDialog.Description className="mt-2 text-[0.92rem] leading-relaxed text-muted">
            {description}
          </AlertDialog.Description>

          <div className="mt-6 flex flex-col gap-2.5">
            <AlertDialog.Action
              onClick={onConfirm}
              className={
                destructive
                  ? "min-h-[54px] rounded-[var(--radius-control)] border border-rose/30 bg-rose/10 font-semibold text-rose"
                  : "min-h-[54px] rounded-[var(--radius-control)] bg-[var(--accent)] font-semibold text-[var(--accent-contrast)]"
              }
            >
              {confirmLabel}
            </AlertDialog.Action>
            <AlertDialog.Cancel className="min-h-[50px] rounded-[var(--radius-control)] text-[0.94rem] text-muted">
              {cancelLabel}
            </AlertDialog.Cancel>
          </div>
        </AlertDialog.Content>
      </AlertDialog.Portal>
    </AlertDialog.Root>
  );
}
