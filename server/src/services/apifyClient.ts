const APIFY_BASE = 'https://api.apify.com/v2';
const APIFY_TOKEN = process.env.APIFY_API_KEY || '';

interface ApifyResponse {
  data: {
    id: string;
    status: string;
  };
}

async function runActor(actorId: string, input: Record<string, unknown>): Promise<unknown[]> {
  if (!APIFY_TOKEN) {
    console.warn('APIFY_API_KEY not set, skipping scraper');
    return [];
  }

  try {
    const runResponse = await fetch(
      `${APIFY_BASE}/acts/${actorId}/runs`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${APIFY_TOKEN}` },
        body: JSON.stringify(input),
        signal: AbortSignal.timeout(30000),
      }
    );
    if (!runResponse.ok) return [];
    const runData = await runResponse.json() as ApifyResponse;
    const runId = runData.data.id;

    for (let i = 0; i < 12; i++) {
      await new Promise((r) => setTimeout(r, 5000));
      const statusResponse = await fetch(
        `${APIFY_BASE}/acts/${actorId}/runs/${runId}`,
        { headers: { 'Authorization': `Bearer ${APIFY_TOKEN}` }, signal: AbortSignal.timeout(10000) }
      );
      if (!statusResponse.ok) break;
      const statusData = await statusResponse.json() as ApifyResponse;
      const status = statusData.data.status;
      if (status === 'SUCCEEDED') {
        const datasetResponse = await fetch(
          `${APIFY_BASE}/acts/${actorId}/runs/${runId}/dataset/items`,
          { headers: { 'Authorization': `Bearer ${APIFY_TOKEN}` }, signal: AbortSignal.timeout(15000) }
        );
        if (!datasetResponse.ok) return [];
        return datasetResponse.json() as Promise<unknown[]>;
      }
      if (status === 'FAILED' || status === 'ABORTED') break;
    }
    return [];
  } catch (error) {
    console.error('Apify actor error:', error);
    return [];
  }
}

export const apifyClient = {
  async scrapeNoon(productName: string): Promise<unknown[]> {
    return runActor('saswave~noon-product-scraper', {
      searchKeyword: productName,
      country: 'SA',
      maxResults: 5,
    });
  },

  async scrapeAmazon(productName: string): Promise<unknown[]> {
    return runActor('junglee~amazon-crawler', {
      search: productName,
      domain: 'amazon.sa',
      maxItems: 5,
    });
  },
};
