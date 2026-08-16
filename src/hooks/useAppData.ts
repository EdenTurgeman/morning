import { useCallback, useRef, useState } from "react";
import { toast } from "sonner";
import {
  emptyData,
  loadData,
  saveData,
  localISODate,
  type AppData,
  type SessionRecord,
} from "@/lib/storage";

/** The history, and the only writer of it. Every mutation goes through
 *  `commit` so a failed localStorage write can never pass silently — losing a
 *  session without being told is the one unacceptable failure mode. */
export function useAppData() {
  const [data, setData] = useState<AppData>(() => loadData());

  // Mirror of the latest value, so mutators never close over stale state.
  const latest = useRef(data);
  latest.current = data;

  const commit = useCallback((next: AppData) => {
    latest.current = next;
    setData(next);
    if (!saveData(next)) {
      toast.error("Couldn't save to storage", {
        description:
          "Storage may be full. Back up now, before you lose anything.",
        duration: 10_000,
      });
    }
  }, []);

  const addSession = useCallback(
    (record: Omit<SessionRecord, "d" | "ts">): SessionRecord => {
      // Field order matches what parseData() emits on the way back in, so an
      // export → restore → export round trip is byte-identical and a backup
      // file can be diffed against a later one.
      const full: SessionRecord = {
        d: localISODate(),
        s: record.s,
        log: record.log,
        min: record.min,
        reps: record.reps,
        ts: Date.now(),
      };
      commit({
        ...latest.current,
        history: [...latest.current.history, full],
      });
      return full;
    },
    [commit],
  );

  const markBackedUp = useCallback(() => {
    commit({ ...latest.current, lastBackup: new Date().toISOString() });
  }, [commit]);

  const replaceAll = useCallback((next: AppData) => commit(next), [commit]);

  const eraseAll = useCallback(() => commit(emptyData()), [commit]);

  return { data, addSession, markBackedUp, replaceAll, eraseAll };
}
