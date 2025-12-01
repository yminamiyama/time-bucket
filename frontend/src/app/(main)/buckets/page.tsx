"use client";

import React, { useEffect, useRef, useState } from "react";
import { Plus, Calendar, DollarSign, Tag, Pencil, Trash2 } from "lucide-react";
import { useBuckets, useUser } from "@/hooks/use-buckets";
import BucketCard from "@/components/BucketCard";
import { ItemStatus, BucketItem } from "@/types";
import { CATEGORY_CONFIG, RISK_CONFIG, STATUS_CONFIG } from "@/constants";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";
import { BucketItemDialog } from "@/components/buckets/BucketItemDialog";
import { StatusSelector } from "@/components/buckets/StatusSelector";

export default function BucketListPage() {
  const { buckets, updateItem, createItem, deleteItem, isLoading, isError } = useBuckets();
  const { user } = useUser();
  const [manualSelectedBucketId, setManualSelectedBucketId] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<BucketItem | null>(null);
  const listRef = useRef<HTMLDivElement | null>(null);
  const cardRefs = useRef<Record<string, HTMLDivElement | null>>({});

  const formatYen = (amount: number) => `¥${amount.toLocaleString()}`;

  // デフォルト選択: 現在の年齢を含むバケット → 未来で最も近い → 最後
  const defaultBucketId = React.useMemo(() => {
    if (!user || buckets.length === 0) return null;
    const age = user.currentAge;
    const current = buckets.find((b) => age >= b.startAge && age <= b.endAge);
    if (current) return current.id;
    const future = buckets
      .filter((b) => b.startAge > age)
      .sort((a, b) => a.startAge - b.startAge)[0];
    if (future) return future.id;
    return buckets[buckets.length - 1]?.id ?? null;
  }, [user, buckets]);

  const effectiveBucketId = manualSelectedBucketId ?? defaultBucketId ?? buckets[0]?.id ?? null;
  const selectedBucket = buckets.find((b) => b.id === effectiveBucketId);

  const temporalState = (bucketId: string) => {
    if (!user) return "future";
    const bucket = buckets.find((b) => b.id === bucketId);
    if (!bucket) return "future";
    if (user.currentAge < bucket.startAge) return "future";
    if (user.currentAge > bucket.endAge) return "past";
    return "current";
  };

  // 選択カードがスクロール外なら自動スクロール
  useEffect(() => {
    if (!effectiveBucketId || !listRef.current) return;
    const el = cardRefs.current[effectiveBucketId];
    const container = listRef.current;
    if (!el || !container) return;

    const elRect = el.getBoundingClientRect();
    const contRect = container.getBoundingClientRect();
    const isAbove = elRect.top < contRect.top;
    const isBelow = elRect.bottom > contRect.bottom;
    const isLeft = elRect.left < contRect.left;
    const isRight = elRect.right > contRect.right;
    if (isAbove || isBelow || isLeft || isRight) {
      el.scrollIntoView({ behavior: "smooth", block: "center", inline: "center" });
    }
  }, [effectiveBucketId, buckets]);

  const handleCreateItem = async (payload: Partial<BucketItem>) => {
    if (!selectedBucket) throw new Error("バケットが選択されていません。");

    const birthYear = user?.birthdate ? new Date(user.birthdate).getFullYear() : undefined;
    if (birthYear && payload.targetYear) {
      const minYear = birthYear + selectedBucket.startAge;
      const maxYear = birthYear + selectedBucket.endAge;
      if (payload.targetYear < minYear || payload.targetYear > maxYear) {
        throw new Error(`目標年は ${minYear} 〜 ${maxYear} の範囲で入力してください。`);
      }
    }

    if (editingItem) {
      await updateItem(selectedBucket.id, editingItem.id, payload);
    } else {
      await createItem(selectedBucket.id, payload);
    }
    setEditingItem(null);
  };

  const handleDeleteItem = async (bucketId: string, itemId: string) => {
    const ok = window.confirm("この体験を削除しますか？");
    if (!ok) return;
    await deleteItem(bucketId, itemId);
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
    <div className="flex flex-col lg:flex-row gap-6 min-h-screen lg:h-[calc(100vh-100px)]">
      <div className="lg:w-1/3 flex flex-col gap-3">
        <h2 className="text-2xl font-bold tracking-tight sticky top-0 bg-slate-50 py-2 z-10">
          マイ・タイムバケット
        </h2>
        <div
          ref={listRef}
          className="flex gap-3 overflow-x-auto lg:overflow-y-auto no-scrollbar pb-4 lg:pb-10 flex-row lg:flex-col pr-2"
        >
          {buckets.map((bucket) => (
            <div
              key={bucket.id}
              className="min-w-[240px] max-w-[260px] lg:min-w-full"
              ref={(el) => {
                cardRefs.current[bucket.id] = el;
              }}
            >
              <BucketCard
                bucket={bucket}
                temporalState={temporalState(bucket.id) as "past" | "current" | "future"}
                isActive={effectiveBucketId === bucket.id}
                onSelect={() => setManualSelectedBucketId(bucket.id)}
              />
            </div>
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
              <button
                className="flex items-center gap-2 bg-primary hover:bg-primary/90 text-primary-foreground px-4 py-2 rounded-lg transition-colors shadow-sm text-sm font-medium"
                onClick={() => {
                  setEditingItem(null);
                  setDialogOpen(true);
                }}
              >
                <Plus size={18} />
                体験を追加
              </button>
            </div>
          </div>

            <div className="flex-1 overflow-y-auto p-6 space-y-4 pb-28">
              {selectedBucket.items.length === 0 ? (
                <div className="h-full flex flex-col items-center justify-center text-muted-foreground">
                  <Calendar size={48} className="mb-4 opacity-20" />
                  <p>この人生のステージにはまだ計画がありません。</p>
                  <button
                    className="text-primary font-medium mt-2 hover:underline"
                    onClick={() => {
                      setEditingItem(null);
                      setDialogOpen(true);
                    }}
                  >
                    最初のアイテムを追加する
                  </button>
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
                        <StatusSelector
                          value={item.status}
                          onChange={(status) => {
                            const completedAt = status === ItemStatus.DONE ? new Date().toISOString() : undefined;
                            updateItem(item.timeBucketId, item.id, { status, completedAt });
                          }}
                        />

                        <div className="flex-1">
                          <div className="flex justify-between items-start">
                            <h3 className={cn("font-bold text-lg", isDone ? "text-muted-foreground line-through" : "text-foreground")}>
                              {item.title}
                            </h3>
                            <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                              <button
                                onClick={() => {
                                  setEditingItem(item);
                                  setDialogOpen(true);
                                }}
                                className="p-1 rounded hover:bg-accent text-muted-foreground"
                                title="編集"
                              >
                                <Pencil size={14} />
                              </button>
                              <button
                                onClick={() => handleDeleteItem(selectedBucket.id, item.id)}
                                className="p-1 rounded hover:bg-accent text-destructive"
                                title="削除"
                              >
                                <Trash2 size={14} />
                              </button>
                              <Badge className={cn("text-[10px]", STATUS_CONFIG[item.status].color)}>
                                {STATUS_CONFIG[item.status].label}
                              </Badge>
                            </div>
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
                              {formatYen(item.costEstimate)}
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

      {/* モバイル用 FAB */}
      <button
        className="lg:hidden fixed right-5 h-14 w-14 rounded-full bg-primary text-primary-foreground shadow-xl flex items-center justify-center hover:bg-primary/90 transition-colors"
        style={{ bottom: "calc(env(safe-area-inset-bottom, 0px) + 88px)" }}
        aria-label="体験を追加"
        onClick={() => {
          setEditingItem(null);
          setDialogOpen(true);
        }}
      >
        <Plus size={24} />
      </button>

      <BucketItemDialog
        open={dialogOpen}
        item={editingItem}
        onOpenChange={(open) => {
          setDialogOpen(open);
          if (!open) setEditingItem(null);
        }}
        defaultTargetYear={
          selectedBucket && user?.birthdate
            ? new Date(user.birthdate).getFullYear() + selectedBucket.startAge
            : new Date().getFullYear()
        }
        onSubmit={handleCreateItem}
      />
    </div>
  );
}
