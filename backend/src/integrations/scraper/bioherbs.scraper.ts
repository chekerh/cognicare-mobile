import axios from 'axios';

const BASE = 'https://www.bioherbs.tn';
const COLLECTION_HANDLE = 'nos-produits';

/** Produit Bioherbs (format unifié pour le catalogue). */
export interface BioherbsProduct {
  externalId: string;
  name: string;
  price: string;
  availability: boolean;
  category: string;
  productUrl: string;
  imageUrls: string[];
}

/** Réponse Shopify collection products.json */
interface ShopifyProductJson {
  id: number;
  title: string;
  handle: string;
  variants?: Array<{
    id: number;
    price: string;
    available?: boolean;
  }>;
  images?: Array<{ src: string }>;
}

/**
 * Scraper Bioherbs (Shopify) — utilise l’API JSON publique (pas de BeautifulSoup côté backend Node).
 * Équivalent logique : récupération du catalogue et des détails produit.
 */
export async function fetchBioherbsProducts(page = 1, limit = 50): Promise<{
  products: BioherbsProduct[];
  nextPage: number | null;
}> {
  const url = `${BASE}/collections/${COLLECTION_HANDLE}/products.json?page=${page}&limit=${limit}`;
  const { data } = await axios.get<{ products?: ShopifyProductJson[] }>(url, {
    timeout: 15000,
    headers: { Accept: 'application/json' },
  });

  const list = data?.products ?? [];
  const products: BioherbsProduct[] = list.map((p) => {
    const variant = p.variants?.[0];
    const price = variant?.price ?? '0';
    const available = variant?.available ?? true;
    const imageUrls = (p.images ?? []).map((img) => img.src).filter(Boolean);
    const productUrl = `${BASE}/collections/${COLLECTION_HANDLE}/products/${p.handle}`;

    return {
      externalId: p.handle,
      name: p.title,
      price: `DT ${parseFloat(price).toFixed(3)}`,
      availability: available,
      category: 'Compléments',
      productUrl,
      imageUrls,
    };
  });

  const nextPage = list.length >= limit ? page + 1 : null;
  return { products, nextPage };
}

/**
 * Récupère tous les produits Bioherbs (toutes les pages).
 */
export async function fetchAllBioherbsProducts(): Promise<BioherbsProduct[]> {
  const all: BioherbsProduct[] = [];
  let page = 1;
  let nextPage: number | null = 1;

  while (nextPage) {
    const { products, nextPage: np } = await fetchBioherbsProducts(page, 50);
    all.push(...products);
    nextPage = np;
    page = nextPage ?? 0;
  }

  return all;
}

/**
 * Détail d’un produit par handle (pour récupérer le variant id pour le panier).
 */
export async function fetchBioherbsProductByHandle(handle: string): Promise<{
  handle: string;
  title: string;
  variantId: number;
  price: string;
} | null> {
  const url = `${BASE}/products/${handle}.json`;
  const res = await axios.get<{ product?: ShopifyProductJson }>(url, {
    timeout: 10000,
    headers: { Accept: 'application/json' },
  }).catch(() => ({ data: undefined }));

  const p = res.data?.product;
  if (!p?.variants?.length) return null;

  const v = p.variants[0];
  return {
    handle: p.handle,
    title: p.title,
    variantId: v.id,
    price: v.price,
  };
}

/**
 * Ajoute un produit au panier Shopify (Bioherbs).
 * Retourne l’URL du panier pour que l’utilisateur finalise le paiement sur le site.
 */
export async function addBioherbsToCart(variantId: number, quantity: number): Promise<string> {
  const url = `${BASE}/cart/add.js`;
  await axios.post(
    url,
    { items: [{ id: variantId, quantity }] },
    {
      timeout: 10000,
      headers: { 'Content-Type': 'application/json' },
      validateStatus: (s) => s >= 200 && s < 400,
    },
  ).catch((err) => {
    const msg = axios.isAxiosError(err) ? err.response?.data?.description ?? err.message : (err as Error).message;
    throw new Error(`Panier Bioherbs: ${msg}`);
  });

  return `${BASE}/cart`;
}
