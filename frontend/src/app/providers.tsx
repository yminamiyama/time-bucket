"use client";

import { SWRConfig } from "swr";
import { apiClient } from "@/lib/api-client";
import { ReactNode } from "react";
import DemoBanner from "@/components/DemoBanner";

const fetcher = (url: string) => apiClient.get(url);

export function Providers({ children }: { children: ReactNode }) {
  return (
    <SWRConfig value={{ fetcher }}>
      <DemoBanner />
      {children}
    </SWRConfig>
  );
}
