import React, { useState, useRef, useEffect } from "react";
import { ItemStatus, BucketItem } from "@/types";
import { CheckCircle2, Clock3, Circle } from "lucide-react";
import { cn } from "@/lib/utils";

type Props = {
  value: ItemStatus;
  onChange: (status: ItemStatus) => void;
};

const STATUS_OPTIONS: { value: ItemStatus; label: string; icon: React.ReactNode }[] = [
  { value: ItemStatus.PLANNED, label: "計画中", icon: <Circle size={14} /> },
  { value: ItemStatus.IN_PROGRESS, label: "実行中", icon: <Clock3 size={14} /> },
  { value: ItemStatus.DONE, label: "完了", icon: <CheckCircle2 size={14} /> },
];

export function StatusSelector({ value, onChange }: Props) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const onClick = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", onClick);
    return () => document.removeEventListener("mousedown", onClick);
  }, []);

  const current = STATUS_OPTIONS.find((s) => s.value === value) ?? STATUS_OPTIONS[0];

  return (
    <div className="relative" ref={ref}>
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className={cn(
          "w-8 h-8 rounded-full border flex items-center justify-center transition-colors",
          value === ItemStatus.DONE && "bg-green-500 border-green-500 text-white",
          value === ItemStatus.IN_PROGRESS && "border-blue-500 text-blue-600",
          value === ItemStatus.PLANNED && "border-slate-300 text-slate-400"
        )}
        title={current.label}
      >
        {current.icon}
      </button>

      {open && (
        <div className="absolute left-0 mt-2 w-36 rounded-lg border bg-white shadow-lg z-20">
          {STATUS_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              type="button"
              onClick={() => {
                onChange(opt.value);
                setOpen(false);
              }}
              className={cn(
                "w-full flex items-center gap-2 px-3 py-2 text-sm hover:bg-accent text-left",
                value === opt.value ? "bg-accent" : ""
              )}
            >
              {opt.icon}
              <span>{opt.label}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
