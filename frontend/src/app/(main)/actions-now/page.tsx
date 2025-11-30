"use client";

import React from "react";
import { Clock, ArrowRight } from "lucide-react";
import { useBuckets, useUser } from "@/hooks/use-buckets";
import { ItemStatus } from "@/types";
import { CATEGORY_CONFIG } from "@/constants";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

export default function ActionsNowPage() {
  const { buckets } = useBuckets();
  const { user } = useUser();

  if (!user || buckets.length === 0) return <div>Loading...</div>;

  const urgentItems = buckets
    .flatMap((b) => b.items)
    .filter((item) => {
      const isPending = item.status !== ItemStatus.DONE;
      const isUrgent = item.targetYear <= user.currentAge + 2 && item.targetYear >= user.currentAge - 5;
      return isPending && isUrgent;
    })
    .sort((a, b) => a.targetYear - b.targetYear);

  return (
    <div className="max-w-4xl mx-auto">
      <div className="mb-8 text-center">
        <div className="inline-flex items-center justify-center p-3 bg-brand-100 text-brand-600 rounded-full mb-4">
          <Clock size={32} />
        </div>
        <h2 className="text-3xl font-bold tracking-tight">今やるべきこと</h2>
        <p className="text-muted-foreground mt-2">
          これらの体験に集中しましょう。現在の年齢 ({user.currentAge}歳) に基づいて、優先度が高いまたは期限が迫っている項目です。
        </p>
      </div>

      <div className="space-y-4">
        {urgentItems.length === 0 ? (
          <Card className="text-center p-12 border-dashed">
            <p className="text-muted-foreground">直近の目標はすべて達成または計画済みです！</p>
          </Card>
        ) : (
          urgentItems.map((item) => {
            const yearsDiff = item.targetYear - user.currentAge;
            const isOverdue = yearsDiff < 0;
            const urgencyText = isOverdue ? "期限超過" : yearsDiff === 0 ? "今年" : `あと ${yearsDiff} 年`;

            return (
              <Card
                key={item.id}
                className={cn(
                  "p-6 flex flex-col sm:flex-row gap-6 transition-transform hover:scale-[1.01] overflow-hidden relative",
                  isOverdue && "border-red-200 bg-red-50/30"
                )}
              >
                <div className="flex flex-col items-center justify-center w-20 h-20 bg-background border rounded-xl shrink-0 shadow-sm z-10">
                  <span className="text-xs text-muted-foreground font-bold uppercase">目標</span>
                  <span className="text-2xl font-bold">{item.targetYear}</span>
                </div>

                <div className="flex-1 z-10">
                  <div className="flex items-center gap-2 mb-2">
                    <Badge variant={isOverdue ? "destructive" : "brand"}>{urgencyText}</Badge>
                    <span
                      className={cn(
                        "text-xs px-2 py-0.5 rounded font-medium",
                        CATEGORY_CONFIG[item.category].bg,
                        CATEGORY_CONFIG[item.category].color
                      )}
                    >
                      {CATEGORY_CONFIG[item.category].label}
                    </span>
                  </div>
                  <h3 className="text-xl font-bold">{item.title}</h3>
                  <p className="text-muted-foreground mt-1 mb-3">{item.valueStatement}</p>

                  <div className="flex items-center text-sm text-muted-foreground gap-4">
                    <span>費用: ¥{item.costEstimate}k</span>
                    <span>•</span>
                    <span>
                      難易度: <span className="capitalize">{item.difficulty}</span>
                    </span>
                  </div>
                </div>

                <div className="flex items-center z-10">
                  <button className="flex items-center gap-2 px-6 py-3 bg-primary text-primary-foreground rounded-lg hover:bg-primary/90 transition-colors font-medium shadow-md">
                    開始
                    <ArrowRight size={16} />
                  </button>
                </div>
              </Card>
            );
          })
        )}
      </div>
    </div>
  );
}
