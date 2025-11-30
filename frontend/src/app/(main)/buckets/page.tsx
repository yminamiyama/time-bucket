"use client";

import React, { useState } from "react";
import { Plus, Calendar, DollarSign, Tag, CheckCircle2 } from "lucide-react";
import { useBuckets } from "@/hooks/use-buckets";
import BucketCard from "@/components/BucketCard";
import { ItemStatus, BucketItem } from "@/types";
import { CATEGORY_CONFIG, RISK_CONFIG, STATUS_CONFIG } from "@/constants";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

export default function BucketListPage() {
  const { buckets, updateItem, isLoading, isError } = useBuckets();
  const [selectedBucketId, setSelectedBucketId] = useState<string | null>(null);

  const effectiveBucketId = selectedBucketId ?? buckets[0]?.id ?? null;
  const selectedBucket = buckets.find((b) => b.id === effectiveBucketId);

  const handleToggleStatus = (item: BucketItem) => {
    const nextStatus =
      item.status === ItemStatus.PLANNED
        ? ItemStatus.IN_PROGRESS
        : item.status === ItemStatus.IN_PROGRESS
        ? ItemStatus.DONE
        : ItemStatus.PLANNED;

    updateItem(item.timeBucketId, item.id, { status: nextStatus });
  };

  if (isLoading) {
    return <div className="p-6 text-muted-foreground">Loading...</div>;
  }

  if (isError) {
    return <div className="p-6 text-destructive">データの取得に失敗しました。</div>;
  }

  if (buckets.length === 0) {
    return (
      <div className="p-6 text-muted-foreground">
        バケットがありません。最初のバケットを作成してください。
      </div>
    );
  }

  return (
    <div className="flex flex-col lg:flex-row h-[calc(100vh-100px)] gap-6">
      <div className="lg:w-1/3 flex flex-col gap-4 overflow-y-auto no-scrollbar pb-10">
        <h2 className="text-2xl font-bold tracking-tight sticky top-0 bg-slate-50 py-2 z-10">マイ・タイムバケット</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-1 gap-4">
          {buckets.map((bucket) => (
            <BucketCard
              key={bucket.id}
              bucket={bucket}
              isActive={selectedBucketId === bucket.id}
              onSelect={() => setSelectedBucketId(bucket.id)}
            />
          ))}
        </div>
      </div>

      <Card className="lg:w-2/3 border shadow-sm flex flex-col overflow-hidden bg-white">
        {selectedBucket ? (
          <>
            <div className="p-6 border-b bg-white sticky top-0 z-10">
              <div className="flex justify-between items-start">
                <div>
                  <Badge variant="brand" className="mb-2">
                    年齢 {selectedBucket.startAge} - {selectedBucket.endAge}
                  </Badge>
                  <h2 className="text-3xl font-bold text-slate-900">{selectedBucket.label}</h2>
                  <p className="text-muted-foreground mt-1">{selectedBucket.description}</p>
                </div>
                <button className="flex items-center gap-2 bg-primary hover:bg-primary/90 text-primary-foreground px-4 py-2 rounded-lg transition-colors shadow-sm text-sm font-medium">
                  <Plus size={18} />
                  体験を追加
                </button>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-6 space-y-4">
              {selectedBucket.items.length === 0 ? (
                <div className="h-full flex flex-col items-center justify-center text-muted-foreground">
                  <Calendar size={48} className="mb-4 opacity-20" />
                  <p>この人生のステージにはまだ計画がありません。</p>
                  <button className="text-primary font-medium mt-2 hover:underline">最初のアイテムを追加する</button>
                </div>
              ) : (
                selectedBucket.items.map((item) => {
                  const CatIcon = CATEGORY_CONFIG[item.category].icon;
                  const isDone = item.status === ItemStatus.DONE;
                  return (
                    <div
                      key={item.id}
                      className={cn(
                        "group border rounded-xl p-4 transition-all hover:shadow-md relative bg-card",
                        isDone && "bg-secondary/50"
                      )}
                    >
                      <div className="flex gap-4">
                        <button
                          onClick={() => handleToggleStatus(item)}
                          className={cn(
                            "mt-1 w-6 h-6 rounded-full border-2 flex items-center justify-center transition-colors shrink-0",
                            isDone ? "bg-green-500 border-green-500" : "border-slate-300 hover:border-brand-500"
                          )}
                        >
                          {isDone && <CheckCircle2 size={14} className="text-white" />}
                        </button>

                        <div className="flex-1">
                          <div className="flex justify-between items-start">
                            <h3 className={cn("font-bold text-lg", isDone ? "text-muted-foreground line-through" : "text-foreground")}>
                              {item.title}
                            </h3>
                            <Badge className={cn("text-[10px]", STATUS_CONFIG[item.status].color)}>
                              {STATUS_CONFIG[item.status].label}
                            </Badge>
                          </div>

                          <p className="text-muted-foreground text-sm mt-1">{item.description}</p>

                          <div className="mt-3 bg-secondary p-3 rounded-lg text-sm text-muted-foreground italic border">
                            {item.valueStatement}
                          </div>

                          <div className="flex flex-wrap items-center gap-3 mt-4 text-xs text-muted-foreground">
                            <span className={cn("flex items-center gap-1 px-2 py-1 rounded", CATEGORY_CONFIG[item.category].bg, CATEGORY_CONFIG[item.category].color)}>
                              <CatIcon size={12} />
                              {CATEGORY_CONFIG[item.category].label}
                            </span>
                            <span className="flex items-center gap-1">
                              <DollarSign size={12} />
                              ¥{item.costEstimate}k
                            </span>
                            <span className={cn("flex items-center gap-1", RISK_CONFIG[item.riskLevel].color)}>
                              <span className="w-1.5 h-1.5 rounded-full bg-current"></span>
                              {RISK_CONFIG[item.riskLevel].label}
                            </span>
                            {item.tags?.map((tag: string) => (
                              <span key={tag} className="flex items-center gap-1">
                                <Tag size={10} /> {tag}
                              </span>
                            ))}
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </>
        ) : (
          <div className="flex items-center justify-center h-full text-muted-foreground">Loading...</div>
        )}
      </Card>
    </div>
  );
}
