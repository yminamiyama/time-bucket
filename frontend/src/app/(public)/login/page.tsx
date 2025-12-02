"use client";

import { BACKEND_BASE_URL, API_BASE_URL } from "@/lib/api-client";
import { ShieldCheck, LogIn, Eye } from "lucide-react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();
  // 認証エンドポイントは /auth/google_oauth2 (API prefixなし)
  const action = `${(BACKEND_BASE_URL || API_BASE_URL.replace(/\/v1$/, ""))}/auth/google_oauth2`;

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 px-4">
      <div className="bg-white rounded-2xl shadow-lg border w-full max-w-md p-8 space-y-6">
        <div className="flex items-center gap-3">
          <div className="p-3 rounded-full bg-brand-50 text-brand-600">
            <ShieldCheck size={28} />
          </div>
          <div>
            <h1 className="text-2xl font-bold text-slate-900">TimeBucket へログイン</h1>
            <p className="text-sm text-muted-foreground">Googleで認証してダッシュボードに進みます。</p>
          </div>
        </div>

        <form action={action} method="post" className="w-full">
          <button
            type="submit"
            className="w-full flex items-center justify-center gap-2 bg-primary text-primary-foreground py-3 rounded-xl font-semibold hover:bg-primary/90 transition-colors shadow-sm"
          >
            <LogIn size={18} />
            Sign in with Google
          </button>
        </form>

        <button
          type="button"
          onClick={() => {
            if (typeof window !== "undefined") {
              window.localStorage.setItem("timebucket_demo_mode", "true");
              window.dispatchEvent(new Event("timebucket-demo-toggle"));
            }
            router.push("/");
          }}
          className="w-full flex items-center justify-center gap-2 border border-primary/40 text-primary py-3 rounded-xl font-semibold hover:bg-primary/5 transition-colors shadow-sm"
        >
          <Eye size={18} />
          デモモードで見る
        </button>

        <p className="text-xs text-muted-foreground text-center">
          サインインすると、バックエンドの認証エンドポイントへリダイレクトします。
        </p>
      </div>
    </div>
  );
}
