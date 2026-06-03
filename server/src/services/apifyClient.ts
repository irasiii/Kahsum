const APIFY_BASE = 'https://api.apify.com/v2';
const APIFY_TOKEN = process.env.APIFY_API_KEY || '';

// Hard cap: each scraper gets at most this long before we give up and let
// the AI work with whatever internal history we have.
const MAX_WAIT_MS = 15_000;
const POLL_INTERVAL_MS = 3_000;
const MAX_POLLS = Math.floor(MAX_WAIT_MS / POLL_INTERVAL_MS); // 5 polls

interface ApifyRunResponse { data: { id: string; status: string } }

async function runActor(actorId: string, input: Record<string, unknown>): Promise<unknown[]> {
  if (!APIFY_TOKEN) return [];

  // Overall deadline: if the actor hasn't returned within MAX_WAIT_MS, abort.
  const deadline = Date.now() + MAX_WAIT_MS;

  try {
    const runRes = await fetch(`${APIFY_BASE}/acts/${actorId}/runs`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${APIFY_TOKEN}`,
      },
      body: JSON.stringify(input),
      signal: AbortSignal.timeout(8_000),
    });
    if (!runRes.ok) return [];

    const runData = (await runRes.json()) as ApifyRunResponse;
    const runId = runData.data.id;

    for (let i = 0; i < MAX_POLLS; i++) {
      // Respect overall deadline
      const remaining = deadline - Date.now();
      if (remaining <= 0) {
        console.warn(`Apify actor ${actorId} timed out after ${MAX_WAIT_MS}ms`);
        return [];
      }

      await new Promise((r) => setTimeout(r, Math.min(POLL_INTERVAL_MS, remaining)));

      const statusRes = await fetch(`${APIFY_BASE}/acts/${actorId}/runs/${runId}`, {
        headers: { Authorization: `Bearer ${APIFY_TOKEN}` },
        signal: AbortSignal.timeout(5_000),
      });
      if (!statusRes.ok) break;

      const { data } = (await statusRes.json()) as ApifyRunResponse;

      if (data.status === 'SUCCEEDED') {
        const dataRes = await fetch(
          `${APIFY_BASE}/acts/${actorId}/runs/${runId}/dataset/items`,
          {
            headers: { Authorization: `Bearer ${APIFY_TOKEN}` },
            signal: AbortSignal.timeout(8_000),
          }
        );
        if (!dataRes.ok) return [];
        return (await dataRes.json()) as unknown[];
      }

      // Terminal failure states — bail immediately instead of burning the clock
      if (['FAILED', 'ABORTED', 'TIMED-OUT'].includes(data.status)) {
        console.warn(`Apify actor ${actorId} ended with status ${data.status}`);
        break;
      }
    }
    return [];
  } catch (err) {
    // AbortError or any network failure — log and return empty so AI can
    // still produce a result from internal history
    if ((err as any)?.name !== 'AbortError') {
      console.error(`Apify actor ${actorId} error:`, err);
    }
    return [];
  }
}

export const apifyClient = {
  scrapeNoon(productName: string): Promise<unknown[]> {
    return runActor('saswave~noon-product-scraper', {
      searchKeyword: productName,
      country: 'SA',
      maxResults: 5,
    });
  },

  scrapeAmazon(productName: string): Promise<unknown[]> {
    return runActor('junglee~amazon-crawler', {
      search: productName,
      domain: 'amazon.sa',
      maxItems: 5,
    });
  },
};
