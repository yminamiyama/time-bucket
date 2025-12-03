"use client";

import React from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Activity, LayoutDashboard, ListTodo } from "lucide-react";
import { Sidebar } from "./Sidebar";

interface AppLayoutProps {
  children: React.ReactNode;
}

export default function AppLayout({ children }: AppLayoutProps) {
  const pathname = usePathname();
  const navItems = [
    { name: "ダッシュボード", icon: LayoutDashboard, path: "/" },
    { name: "マイチャプター", icon: ListTodo, path: "/buckets" },
    { name: "今やるべきこと", icon: Activity, path: "/actions-now" },
  ];

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col md:flex-row font-sans text-slate-900">
      <Sidebar className="hidden md:flex" />

      <div className="md:hidden bg-white border-b p-4 flex justify-between items-center sticky top-0 z-20">
        <span className="font-bold text-lg text-brand-600">LifeChapters</span>
        <button className="p-2 text-slate-600">
          <LayoutDashboard />
        </button>
      </div>

      <main className="flex-1 overflow-y-auto">
        <div className="max-w-7xl mx-auto p-4 md:p-8">{children}</div>
      </main>

      <div className="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t flex justify-around p-4 z-20">
        {navItems.map((item) => {
          const isActive = pathname === item.path;
          return (
            <Link
              key={item.path}
              href={item.path}
              className={`flex flex-col items-center gap-1 text-xs ${
                isActive ? "text-brand-600" : "text-slate-500"
              }`}
            >
              <item.icon size={24} />
              {item.name}
            </Link>
          );
        })}
      </div>
    </div>
  );
}
