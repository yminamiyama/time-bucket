"use client";

import React, { useMemo } from "react";
import { Bar, BarChart, CartesianGrid, Cell, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { useBuckets, useUser } from "@/hooks/use-buckets";
import { CATEGORY_CONFIG } from "@/constants";
import { DollarSign, TrendingUp } from "lucide-react";
import { ItemStatus } from "@/types";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function DashboardPage() {
  const { buckets, isLoading: bucketsLoading } = useBuckets();
  const { user, isLoading: userLoading } = useUser();

  const formatYen = (amount: number) => `¥${amount.toLocaleString()}`;

  const densityData = useMemo(() => {
    return buckets.map((b) => ({
      name: b.label,
      count: b.items.length,
      cost: b.items.reduce((acc, i) => acc + i.costEstimate, 0),
      done: b.items.filter((i) => i.status === ItemStatus.DONE).length,
    }));
  }, [buckets]);

  const categoryData = useMemo(() => {
    const counts: Record<string, number> = {};
    buckets.flatMap((b) => b.items).forEach((i) => {
      counts[i.category] = (counts[i.category] || 0) + 1;
    });
    return Object.entries(counts).map(([key, value]) => ({ name: key, value }));
  }, [buckets]);

  const currentBucketLabel = useMemo(() => {
    if (!user) return "-";
    const match = buckets.find(
      (b) => user.currentAge >= b.startAge && user.currentAge <= b.endAge
    );
    if (match) return match.label;
    // fallback: 直近の将来バケット or 最後のバケット
    const future = buckets.find((b) => b.startAge > user.currentAge);
    return future?.label || buckets[buckets.length - 1]?.label || "-";
  }, [buckets, user]);

  if (bucketsLoading || userLoading || !user) {
    return <div>Loading...</div>;
  }

  const totalCost = buckets
    .flatMap((b) => b.items)
    .reduce((acc, i) => acc + (typeof i.costEstimate === "number" ? i.costEstimate : 0), 0);
  const totalItems = buckets.flatMap((b) => b.items).length;
  const completedItems = buckets.flatMap((b) => b.items).filter((i) => i.status === ItemStatus.DONE).length;
  const completionRate = totalItems > 0 ? Math.round((completedItems / totalItems) * 100) : 0;

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-3xl font-bold tracking-tight">ライフダッシュボード</h2>
          <p className="text-muted-foreground">タイムバケットの状況と人生設計の統計概要です。</p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-blue-50 text-brand-600 rounded-lg">
                <TrendingUp size={24} />
              </div>
              <div>
                <p className="text-sm text-muted-foreground font-medium">バケット密度</p>
                <p className="text-2xl font-bold">
                  {totalItems} <span className="text-sm font-normal text-muted-foreground">体験</span>
                </p>
              </div>
            </div>
            <div className="mt-4 w-full bg-secondary rounded-full h-2">
              <div className="bg-primary h-2 rounded-full" style={{ width: `${completionRate}%` }}></div>
            </div>
            <p className="text-xs text-muted-foreground mt-2">{completionRate}% 達成率 (思い出の配当)</p>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="p-3 bg-green-50 text-green-600 rounded-lg">
                <DollarSign size={24} />
              </div>
              <div>
                <p className="text-sm text-muted-foreground font-medium">生涯概算コスト</p>
                <p className="text-2xl font-bold">{formatYen(totalCost)}</p>
              </div>
            </div>
            <p className="text-xs text-muted-foreground mt-4">全バケットアイテムの総見積もりコスト。</p>
          </CardContent>
        </Card>

        <Card className="relative overflow-hidden">
          <div className="absolute top-0 right-0 w-24 h-24 bg-blue-50 rounded-bl-full -mr-4 -mt-4 z-0"></div>
          <CardContent className="p-6 relative z-10">
            <p className="text-sm text-muted-foreground font-medium">現在の年齢</p>
            <div className="flex items-baseline gap-2 mt-1">
              <h3 className="text-4xl font-bold">{user.currentAge}</h3>
              <span className="text-sm text-muted-foreground">歳</span>
            </div>
            <p className="text-xs text-muted-foreground mt-2">
              現在のバケット: <span className="font-semibold text-brand-600">{currentBucketLabel}</span>
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="h-[400px]">
          <CardHeader>
            <CardTitle>バケット密度 (年代別のやりたいこと)</CardTitle>
          </CardHeader>
          <CardContent className="h-[300px]">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={densityData} margin={{ top: 20, right: 30, left: 0, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                <XAxis dataKey="name" axisLine={false} tickLine={false} tick={{ fill: "#64748b", fontSize: 12 }} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{ fill: "#64748b", fontSize: 12 }} />
                <Tooltip cursor={{ fill: "#f8fafc" }} contentStyle={{ borderRadius: "8px", border: "none", boxShadow: "0 4px 6px -1px rgb(0 0 0 / 0.1)" }} />
                <Bar dataKey="count" fill="#3b82f6" radius={[4, 4, 0, 0]} barSize={40} />
              </BarChart>
            </ResponsiveContainer>
          </CardContent>
        </Card>

        <Card className="h-[400px]">
          <CardHeader>
            <CardTitle>ライフバランス (カテゴリ)</CardTitle>
          </CardHeader>
          <CardContent className="h-[300px]">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={categoryData} cx="50%" cy="50%" innerRadius={80} outerRadius={120} paddingAngle={5} dataKey="value">
                  {categoryData.map((entry, index) => {
                    const colors = ["#3b82f6", "#ec4899", "#22c55e", "#ef4444", "#a855f7", "#f59e0b", "#64748b"];
                    return <Cell key={`cell-${index}`} fill={colors[index % colors.length]} strokeWidth={0} />;
                  })}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
            <div className="flex flex-wrap gap-2 justify-center mt-[-20px]">
              {categoryData.map((entry) => (
                <span
                  key={entry.name}
                  className="text-xs px-2 py-1 rounded-full bg-secondary text-secondary-foreground"
                >
                  {CATEGORY_CONFIG[entry.name as keyof typeof CATEGORY_CONFIG]?.label || entry.name}
                </span>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
