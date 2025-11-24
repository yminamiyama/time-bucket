const posthogKey = process.env.NEXT_PUBLIC_POSTHOG_KEY;
const posthogHost = process.env.NEXT_PUBLIC_POSTHOG_HOST || "https://app.posthog.com";

export const analytics = {
  async track(event: string, properties: Record<string, unknown> = {}) {
    if (!posthogKey) return;

    try {
      await fetch(`${posthogHost}/capture/`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${posthogKey}`,
        },
        body: JSON.stringify({
          api_key: posthogKey,
          event,
          properties,
        }),
      });
    } catch (error) {
      console.warn("posthog track failed", error);
    }
  },
};
