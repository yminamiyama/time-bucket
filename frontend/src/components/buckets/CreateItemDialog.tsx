import React, { useState, useEffect } from "react";
import { Category, Difficulty, RiskLevel, ItemStatus, BucketItem } from "@/types";
import { CATEGORY_CONFIG, DIFFICULTY_CONFIG, RISK_CONFIG } from "@/constants";
import { cn } from "@/lib/utils";
import { Loader2 } from "lucide-react";

interface CreateItemDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSubmit: (data: Partial<BucketItem>) => Promise<void>;
  defaultTargetYear: number;
}

export function CreateItemDialog({ open, onOpenChange, onSubmit, defaultTargetYear }: CreateItemDialogProps) {
  const [isLoading, setIsLoading] = useState(false);
  const [formData, setFormData] = useState({
    title: "",
    valueStatement: "",
    category: Category.LEISURE,
    difficulty: Difficulty.MEDIUM,
    riskLevel: RiskLevel.LOW,
    costEstimate: 0,
    targetYear: defaultTargetYear,
  });
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    if (open) {
      setFormData((prev) => ({ ...prev, targetYear: defaultTargetYear }));
    }
  }, [open, defaultTargetYear]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.valueStatement.trim()) {
      setFormError("価値・意味を入力してください。");
      return;
    }
    setIsLoading(true);
    try {
      await onSubmit({
        ...formData,
        status: ItemStatus.PLANNED,
        costEstimate: Number(formData.costEstimate),
        targetYear: Number(formData.targetYear),
      });
      onOpenChange(false);
      setFormData({
        title: "",
        valueStatement: "",
        category: Category.LEISURE,
        difficulty: Difficulty.MEDIUM,
        riskLevel: RiskLevel.LOW,
        costEstimate: 0,
        targetYear: defaultTargetYear,
      });
      setFormError(null);
    } catch (error) {
      console.error(error);
      setFormError("保存に失敗しました。もう一度お試しください。");
    } finally {
      setIsLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-[9999] bg-black/30 backdrop-blur-sm flex items-center justify-center px-4" onClick={() => onOpenChange(false)}>
      <div
        className="bg-white rounded-2xl shadow-2xl w-full max-w-xl border overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="p-5 border-b">
          <p className="text-base font-semibold">新しい体験を追加</p>
          <p className="text-xs text-muted-foreground mt-1">この時期にやりたいことを具体的に書きましょう。</p>
        </div>

        <form onSubmit={handleSubmit} className="p-5 space-y-4 max-h-[70vh] overflow-y-auto">
          <div className="space-y-1">
            <label className="text-sm font-medium">タイトル <span className="text-red-500">*</span></label>
            <input
              type="text"
              name="title"
              required
              placeholder="例: フルマラソン完走、家族でハワイ..."
              value={formData.title}
              onChange={handleChange}
              className="flex h-10 w-full rounded-md border px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
            />
          </div>

          <div className="space-y-1">
            <label className="text-sm font-medium">価値・意味 (Why) <span className="text-red-500">*</span></label>
            <textarea
              name="valueStatement"
              rows={2}
              placeholder="なぜこれをやりたい？どんな思い出（配当）になる？"
              value={formData.valueStatement}
              onChange={handleChange}
              required
              className="flex min-h-[60px] w-full rounded-md border px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
            />
            {formError && <p className="text-xs text-destructive">{formError}</p>}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1">
              <label className="text-sm font-medium">カテゴリ</label>
              <select
                name="category"
                value={formData.category}
                onChange={handleChange}
                className="flex h-10 w-full rounded-md border px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
              >
                {Object.values(Category).map((c) => (
                  <option key={c} value={c}>
                    {CATEGORY_CONFIG[c]?.label || c}
                  </option>
                ))}
              </select>
            </div>

            <div className="space-y-1">
              <label className="text-sm font-medium">目標年 (西暦)</label>
              <input
                type="number"
                name="targetYear"
                required
                min={1900}
                max={2100}
                value={formData.targetYear}
                onChange={handleChange}
                className="flex h-10 w-full rounded-md border px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1">
              <label className="text-sm font-medium">概算予算 (円)</label>
              <div className="relative">
                <span className="absolute left-3 top-2.5 text-muted-foreground text-xs">¥</span>
                <input
                  type="number"
                  name="costEstimate"
                  min={0}
                  value={formData.costEstimate}
                  onChange={handleChange}
                  className="flex h-10 w-full rounded-md border pl-6 pr-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                />
              </div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4 bg-slate-50 p-3 rounded-lg border border-slate-100">
            <div className="space-y-2">
              <label className="text-xs font-semibold uppercase text-muted-foreground">難易度</label>
              <div className="flex gap-2">
                {Object.values(Difficulty).map((d) => (
                  <button
                    key={d}
                    type="button"
                    onClick={() => setFormData((prev) => ({ ...prev, difficulty: d }))}
                    className={cn(
                      "flex-1 py-1.5 text-xs rounded border transition-colors",
                      formData.difficulty === d
                        ? "bg-white border-brand-500 text-brand-700 shadow-sm font-medium"
                        : "bg-transparent border-transparent hover:bg-white/50 text-slate-500"
                    )}
                  >
                    {DIFFICULTY_CONFIG[d].label}
                  </button>
                ))}
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-xs font-semibold uppercase text-muted-foreground">リスク</label>
              <div className="flex gap-2">
                {Object.values(RiskLevel).map((r) => (
                  <button
                    key={r}
                    type="button"
                    onClick={() => setFormData((prev) => ({ ...prev, riskLevel: r }))}
                    className={cn(
                      "flex-1 py-1.5 text-xs rounded border transition-colors",
                      formData.riskLevel === r
                        ? "bg-white border-brand-500 text-brand-700 shadow-sm font-medium"
                        : "bg-transparent border-transparent hover:bg-white/50 text-slate-500"
                    )}
                  >
                    {RISK_CONFIG[r].label}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div className="flex justify-end gap-3 pt-4">
            <button
              type="button"
              onClick={() => onOpenChange(false)}
              className="inline-flex items-center justify-center rounded-md text-sm font-medium border px-4 py-2 hover:bg-accent"
            >
              キャンセル
            </button>
            <button
              type="submit"
              disabled={isLoading}
              className="inline-flex items-center justify-center rounded-md text-sm font-medium bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2 min-w-[100px] disabled:opacity-60"
            >
              {isLoading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
              追加する
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
