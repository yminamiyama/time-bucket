import { getInitialData } from "@/services/mockDataService";
import { BucketItem, TimeBucket, UserProfile, Difficulty, RiskLevel, ItemStatus } from "@/types";

// Demo/Mock 判定をランタイムで行う
// 環境変数で明示的に true → 常にモック
// 非 production で env 未設定 → デフォルトでモック
// localStorage のフラグ or ?demo=1 で強制モック（本番でも可）
export const isMockEnabled = (): boolean => {
  if (process.env.NEXT_PUBLIC_USE_MOCK === "true") return true;
  if (!process.env.NEXT_PUBLIC_USE_MOCK && process.env.NODE_ENV !== "production") return true;

  if (typeof window === "undefined") return false;

  // URL クエリでデモ起動
  const params = new URLSearchParams(window.location.search);
  if (params.get("demo") === "1") {
    window.localStorage.setItem("timebucket_demo_mode", "true");
    return true;
  }

  const stored = window.localStorage.getItem("timebucket_demo_mode");
  return stored === "true";
};

// API_BASE_URL is the API prefix (default /v1). BACKEND_BASE_URL is the origin for auth redirects.
export const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || "/v1";
export const BACKEND_BASE_URL = process.env.NEXT_PUBLIC_BACKEND_URL || "";

type ApiBucketItem = {
  id: string;
  time_bucket_id: string;
  title: string;
  category: string;
  difficulty: BucketItem["difficulty"];
  risk_level: BucketItem["riskLevel"];
  cost_estimate: number | null;
  status: BucketItem["status"];
  target_year: number;
  value_statement: string;
  completed_at?: string | null;
  created_at?: string;
  updated_at?: string;
};

type ApiTimeBucket = {
  id: string;
  start_age: number;
  end_age: number;
  description?: string;
  position?: number;
};

type ApiUser = {
  id: string;
  email?: string;
  birthdate?: string;
  current_age: number;
  timezone?: string;
};

export class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = "ApiError";
  }
}

const fetchJson = async <T>(url: string, options: RequestInit = {}): Promise<T | null> => {
  const res = await fetch(url, {
    credentials: "include", // send session cookies for auth
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
  });

  if (!res.ok) {
    let detail = res.statusText;
    try {
      const errBody = (await res.json()) as { errors?: string[] | Record<string, unknown>; error?: string };
      if (Array.isArray(errBody?.errors)) {
        detail = errBody.errors.join(", ");
      } else if (errBody?.errors && typeof errBody.errors === "object") {
        detail = JSON.stringify(errBody.errors);
      }
      if (errBody?.error && typeof errBody.error === "string") {
        detail = errBody.error;
      }
    } catch {
      // ignore parse errors
    }
    if (res.status === 401) {
      throw new ApiError(401, detail || "Unauthorized");
    }
    throw new ApiError(res.status, `API request failed: ${detail}`);
  }

  if (res.status === 204) return null;

  return (await res.json()) as T;
};

const mapBucketItem = (apiItem: ApiBucketItem): BucketItem => ({
  id: apiItem.id,
  timeBucketId: apiItem.time_bucket_id,
  title: apiItem.title,
  category: mapCategoryFromApi(apiItem.category),
  difficulty: apiItem.difficulty,
  riskLevel: apiItem.risk_level,
  costEstimate: apiItem.cost_estimate ?? 0,
  status: apiItem.status,
  targetYear: apiItem.target_year,
  valueStatement: apiItem.value_statement,
  description: apiItem.value_statement || "",
  completedAt: apiItem.completed_at || undefined,
  createdAt: apiItem.created_at,
  updatedAt: apiItem.updated_at,
});

const mapTimeBucket = (apiBucket: ApiTimeBucket): TimeBucket => ({
  id: apiBucket.id,
  label: `${apiBucket.start_age}-${apiBucket.end_age}`,
  startAge: apiBucket.start_age,
  endAge: apiBucket.end_age,
  description: apiBucket.description,
  position: apiBucket.position,
  items: [],
});

const mapUserProfile = (apiUser: ApiUser): UserProfile => ({
  id: apiUser.id,
  email: apiUser.email,
  birthdate: apiUser.birthdate,
  currentAge: apiUser.current_age,
  timezone: apiUser.timezone,
});

const mapCategoryFromApi = (apiCat: string): BucketItem["category"] => {
  if (apiCat === "travel") return "leisure" as BucketItem["category"];
  if (apiCat === "family") return "relationships" as BucketItem["category"];
  return apiCat as BucketItem["category"];
};

const mapCategoryToApi = (cat?: BucketItem["category"]) => {
  if (!cat) return undefined;
  if (cat === "leisure") return "travel";
  if (cat === "relationships") return "family";
  return cat;
};

const patchProfile = async (body: Partial<UserProfile>): Promise<UserProfile> => {
  const data = await fetchJson<ApiUser>(`${API_BASE_URL}/profile`, {
    method: "PATCH",
    body: JSON.stringify(body),
  });
  if (!data) throw new ApiError(500, "Empty profile response");
  return mapUserProfile(data);
};

const RealApiClient = {
  get: async <T>(path: string): Promise<T> => {
    if (path === "/user") {
      const data = await fetchJson<ApiUser>(`${API_BASE_URL}/profile`);
      if (!data) throw new ApiError(500, "Empty profile response");
      return mapUserProfile(data) as T;
    }

    if (path === "/buckets") {
      const bucketsData = await fetchJson<ApiTimeBucket[]>(`${API_BASE_URL}/time_buckets`);
      if (!bucketsData) throw new ApiError(500, "Empty buckets response");
      const buckets = bucketsData.map(mapTimeBucket);

      const bucketsWithItems = await Promise.all(
        buckets.map(async (bucket: TimeBucket) => {
          try {
            const itemsData = await fetchJson<ApiBucketItem[]>(
              `${API_BASE_URL}/time_buckets/${bucket.id}/bucket_items`
            );
            return { ...bucket, items: itemsData ? itemsData.map(mapBucketItem) : [] };
          } catch (e) {
            console.error(`Failed to fetch items for bucket ${bucket.id}`, e);
            return bucket;
          }
        })
      );

      return bucketsWithItems as T;
    }

    throw new ApiError(404, `Path ${path} not handled in Real Client`);
  },

  post: async <T>(path: string, body: Partial<BucketItem>): Promise<T> => {
    const match = path.match(/\/time_buckets\/(.+)\/bucket_items/);
    if (match) {
      const bucketId = match[1];
      const apiBody = {
        title: body.title,
        category: mapCategoryToApi(body.category),
        difficulty: body.difficulty,
        risk_level: body.riskLevel,
        cost_estimate: body.costEstimate,
        status: body.status,
        target_year: body.targetYear,
        value_statement: body.valueStatement,
      };

      const data = await fetchJson<ApiBucketItem>(
        `${API_BASE_URL}/time_buckets/${bucketId}/bucket_items`,
        {
          method: "POST",
          body: JSON.stringify({ bucket_item: apiBody }),
        }
      );
      if (!data) throw new ApiError(500, "Empty item response");
      return mapBucketItem(data) as T;
    }
    throw new ApiError(400, "Invalid post path. Expected /time_buckets/:bucketId/bucket_items");
  },

  patch: async <T>(path: string, body: Partial<BucketItem>): Promise<T> => {
    const match = path.match(/\/bucket_items\/(.+)/);
    if (match) {
      const itemId = match[1];

      const apiBody: Partial<ApiBucketItem> = {};
      if (body.status) apiBody.status = body.status;
      if (body.title) apiBody.title = body.title;
      if (body.category) apiBody.category = mapCategoryToApi(body.category);
      if (body.difficulty) apiBody.difficulty = body.difficulty;
      if (body.riskLevel) apiBody.risk_level = body.riskLevel;
      if (body.costEstimate !== undefined) apiBody.cost_estimate = body.costEstimate;
      if (body.targetYear) apiBody.target_year = body.targetYear;
      if (body.valueStatement) apiBody.value_statement = body.valueStatement;
      if (body.completedAt !== undefined) apiBody.completed_at = body.completedAt;

      const data = await fetchJson<ApiBucketItem>(
        `${API_BASE_URL}/bucket_items/${itemId}`,
        {
          method: "PATCH",
          body: JSON.stringify({ bucket_item: apiBody }),
        }
      );
      if (!data) throw new ApiError(500, "Empty item response");
      return mapBucketItem(data) as T;
    }

    throw new ApiError(400, "Invalid patch path. Expected /bucket_items/:itemId");
  },

  delete: async <T>(path: string): Promise<T> => {
    const match = path.match(/\/bucket_items\/(.+)/);
    if (match) {
      const itemId = match[1];
      const data = await fetchJson<ApiBucketItem | null>(`${API_BASE_URL}/bucket_items/${itemId}`, {
        method: "DELETE",
      });
      if (data) {
        return mapBucketItem(data) as T;
      }
      // DELETE may return no content
      return null as unknown as T;
    }
    throw new ApiError(400, "Invalid delete path. Expected /bucket_items/:itemId");
  },
  patchProfile,
};

const mockDb = getInitialData();
const DELAY = 600;
const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

const MockApiClient = {
  get: async <T>(path: string): Promise<T> => {
    await delay(DELAY);
    if (path === "/user") return mockDb.user as T;
    if (path === "/buckets") return mockDb.buckets as T;
    throw new ApiError(404, `Path ${path} not found`);
  },

  post: async <T>(path: string, body: Partial<BucketItem>): Promise<T> => {
    await delay(DELAY / 2);
    const bucketId = path.split("/")[2];
    const newItem: BucketItem = {
      id: `item-${Date.now()}`,
      timeBucketId: bucketId,
      title: body.title || "",
      category: body.category || (mockDb.buckets[0]?.items[0]?.category as BucketItem["category"]) || "other",
      difficulty: (body.difficulty as Difficulty) || Difficulty.MEDIUM,
      riskLevel: (body.riskLevel as RiskLevel) || RiskLevel.LOW,
      costEstimate: body.costEstimate ?? 0,
      status: (body.status as ItemStatus) || ItemStatus.PLANNED,
      targetYear: body.targetYear ?? new Date().getFullYear(),
      valueStatement: body.valueStatement || "",
      description: body.valueStatement || "",
      tags: [],
    };

    mockDb.buckets = mockDb.buckets.map((b) =>
      b.id === bucketId ? { ...b, items: [...b.items, newItem] } : b
    );
    return newItem as T;
  },

  patch: async <T>(path: string, body: Partial<BucketItem>): Promise<T> => {
    await delay(DELAY / 2);
    const itemId = path.split("/").pop();

    let updatedItem: BucketItem | undefined;
    mockDb.buckets = mockDb.buckets.map((b) => ({
      ...b,
      items: b.items.map((i) => {
        if (i.id === itemId) {
          updatedItem = { ...i, ...body };
          return updatedItem;
        }
        return i;
      }),
    }));

    if (updatedItem) return updatedItem as T;
    throw new ApiError(404, "Item not found in Mock DB");
  },
  patchProfile,

  delete: async <T>(path: string): Promise<T> => {
    await delay(DELAY / 2);
    const parts = path.split("/");
    const itemId = parts[parts.length - 1];

    let deletedItem: BucketItem | undefined;
    mockDb.buckets = mockDb.buckets.map((b) => {
      const filtered = b.items.filter((i) => {
        if (i.id === itemId) {
          deletedItem = i;
          return false;
        }
        return true;
      });
      return { ...b, items: filtered };
    });

    if (deletedItem) return deletedItem as T;
    throw new ApiError(404, "Item not found in Mock DB");
  },
};

const selectClient = () => (isMockEnabled() ? MockApiClient : RealApiClient);

export const apiClient = {
  get: <T>(path: string) => selectClient().get<T>(path),
  post: <T>(path: string, body: Partial<BucketItem>) => selectClient().post<T>(path, body),
  patch: <T>(path: string, updates: Partial<BucketItem>) => selectClient().patch<T>(path, updates),
  patchProfile: (body: Partial<UserProfile>) => selectClient().patchProfile(body),
  delete: <T>(path: string) => selectClient().delete<T>(path),
};
