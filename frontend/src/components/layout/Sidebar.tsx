"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { Activity, LayoutDashboard, ListTodo, Settings, UserCircle, LogOut } from "lucide-react";
import { cn } from "@/lib/utils";
import { useUser } from "@/hooks/use-buckets";
import { useMemo, useState, useTransition } from "react";
import { createPortal } from "react-dom";
import { BACKEND_BASE_URL } from "@/lib/api-client";

export function Sidebar({ className }: { className?: string }) {
  const pathname = usePathname();
  const { user, isLoading, updateUser } = useUser();
  const [open, setOpen] = useState(false);
  const [birthdate, setBirthdate] = useState("");
  const [timezone, setTimezone] = useState("");
  const [pending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const navItems = [
    { name: "ダッシュボード", icon: LayoutDashboard, path: "/" },
    { name: "マイバケット", icon: ListTodo, path: "/buckets" },
    { name: "今やるべきこと", icon: Activity, path: "/actions-now" },
  ];

  const tzList = useMemo(() => Intl.supportedValuesOf("timeZone"), []);

  const handleOpen = () => {
    setBirthdate(user?.birthdate ?? "");
    setTimezone(user?.timezone ?? Intl.DateTimeFormat().resolvedOptions().timeZone);
    setError(null);
    setOpen(true);
  };

  const handleSave = () => {
    setError(null);
    startTransition(async () => {
      try {
        await updateUser({ birthdate: birthdate || undefined, timezone: timezone || undefined });
        setOpen(false);
      } catch (e) {
        setError(e instanceof Error ? e.message : "更新に失敗しました");
      }
    });
  };

  const handleLogout = async () => {
    try {
      await fetch(`${BACKEND_BASE_URL || ""}/logout`, {
        method: "DELETE",
        credentials: "include",
      });
    } catch (e) {
      console.error("Logout failed", e);
    } finally {
      if (typeof window !== "undefined") {
        window.localStorage.removeItem("timebucket_demo_mode");
        window.dispatchEvent(new Event("timebucket-demo-toggle"));
      }
      window.location.href = "/login";
    }
  };

  return (
    <aside className={cn("flex flex-col w-64 bg-card border-r h-screen sticky top-0", className)}>
      <div className="p-6 border-b">
        <h1 className="text-xl font-bold bg-gradient-to-r from-brand-600 to-indigo-600 bg-clip-text text-transparent">
          TimeBucket
        </h1>
        <p className="text-xs text-muted-foreground mt-1">Design Your Life</p>
      </div>

      <nav className="flex-1 p-4 space-y-1">
        {navItems.map((item) => {
          const isActive = pathname === item.path;
          return (
            <Link
              key={item.path}
              href={item.path}
              className={cn(
                "flex items-center gap-3 px-4 py-3 rounded-lg transition-colors text-sm font-medium",
                isActive
                  ? "bg-brand-50 text-brand-600"
                  : "text-muted-foreground hover:bg-accent hover:text-accent-foreground"
              )}
            >
              <item.icon size={20} />
              {item.name}
            </Link>
          );
        })}
      </nav>

      <div className="p-4 border-t">
        <button
          onClick={handleOpen}
          className="flex items-center gap-3 px-4 py-3 text-muted-foreground hover:text-foreground w-full rounded-lg hover:bg-accent transition-colors text-sm font-medium"
        >
          <Settings size={20} />
          設定
        </button>
        <div className="mt-4 flex items-center gap-3 px-4">
          <UserCircle className="text-muted-foreground" size={32} />
          <div className="min-w-0">
            <p className="text-sm font-medium">
              <span className="block truncate max-w-[150px]">
                {isLoading ? "読み込み中..." : user?.email || "ログイン中"}
              </span>
            </p>
            <p className="text-xs text-muted-foreground">&nbsp;</p>
          </div>
        </div>
      </div>

      {typeof document !== "undefined" && open
        ? createPortal(
            <div
              className="fixed inset-0 z-[9999] bg-black/40 backdrop-blur-sm flex items-center justify-center px-4"
              onClick={() => setOpen(false)}
            >
              <div
                className="bg-white rounded-2xl shadow-2xl w-full max-w-md border overflow-hidden"
                onClick={(e) => e.stopPropagation()}
              >
                <div className="p-4 border-b">
                  <p className="text-sm font-semibold">プロフィール設定</p>
                  <p className="text-xs text-muted-foreground mt-1">生年月日とタイムゾーンを設定してください。</p>
                </div>
                <div className="p-4 space-y-4 max-h-[70vh] overflow-y-auto">
                  <div className="space-y-1">
                    <label className="text-sm font-medium text-foreground">生年月日</label>
                    <input
                      type="date"
                      value={birthdate || ""}
                      onChange={(e) => setBirthdate(e.target.value)}
                      className="w-full rounded-lg border px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
                    />
                    <p className="text-xs text-muted-foreground">年齢計算に利用します。</p>
                  </div>

                  <div className="space-y-1">
                    <label className="text-sm font-medium text-foreground">タイムゾーン</label>
                    <select
                      value={timezone}
                      onChange={(e) => setTimezone(e.target.value)}
                      className="w-full rounded-lg border px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
                    >
                      {tzList.map((tz) => (
                        <option key={tz} value={tz}>
                          {tz}
                        </option>
                      ))}
                    </select>
                  </div>

                  {error && <p className="text-xs text-destructive">{error}</p>}
                </div>
                <div className="px-4 py-3 border-t flex items-center justify-between bg-slate-50">
                  <button
                    onClick={handleLogout}
                    className="text-sm text-destructive hover:underline flex items-center gap-1 disabled:opacity-50"
                    disabled={pending}
                  >
                    <LogOut size={16} />
                    ログアウト
                  </button>
                  <div className="flex gap-2">
                    <button
                      onClick={() => setOpen(false)}
                      className="px-4 py-2 text-sm rounded-lg border hover:bg-accent"
                      disabled={pending}
                    >
                      キャンセル
                    </button>
                    <button
                      onClick={handleSave}
                      disabled={pending}
                      className="px-4 py-2 text-sm rounded-lg bg-primary text-primary-foreground hover:bg-primary/90 disabled:opacity-60"
                    >
                      {pending ? "保存中..." : "保存"}
                    </button>
                  </div>
                </div>
              </div>
            </div>,
            document.body
          )
        : null}
    </aside>
  );
}
