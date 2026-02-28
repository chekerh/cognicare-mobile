import axios from 'axios';
import * as cheerio from 'cheerio';

const BASE = 'http://books.toscrape.com';

export interface BookProduct {
  externalId: string;
  name: string;
  price: string;
  availability: boolean;
  description: string;
  imageUrls: string[];
  category: string;
  productUrl: string;
}

/** Produit depuis la liste (sans description, imageUrls optionnel). */
type BookProductFromList = Omit<BookProduct, 'description'> & { imageUrls?: string[] };

export interface BookCategory {
  name: string;
  slug: string;
  url: string;
}

/**
 * Scraper for Books to Scrape (mock e-commerce). No API key required.
 */
export async function fetchBooksCategories(): Promise<BookCategory[]> {
  const { data } = await axios.get<string>(BASE, { timeout: 15000 });
  const $ = cheerio.load(data);
  const categories: BookCategory[] = [];
  $('.side_categories ul li ul li a').each((_, el) => {
    const a = $(el);
    const href = a.attr('href') ?? '';
    const name = a.text().trim();
    const slug = href.replace(/\/catalogue\/category\/books\/(.+)\/index\.html/, '$1');
    if (name && slug) {
      categories.push({
        name,
        slug,
        url: href.startsWith('http') ? href : new URL(href, BASE).href,
      });
    }
  });
  return categories;
}

/**
 * Fetch product list from a category page or main index. Handles pagination.
 */
export async function fetchBooksProductList(
  categoryUrl?: string,
): Promise<{ products: BookProductFromList[]; nextPageUrl?: string }> {
  const url = categoryUrl ?? `${BASE}/index.html`;
  const { data } = await axios.get<string>(url, { timeout: 15000 });
  const $ = cheerio.load(data);
  const products: BookProductFromList[] = [];

  $('article.product_pod').each((_, el) => {
    const article = $(el);
    const titleEl = article.find('h3 a');
    const name = titleEl.attr('title') ?? titleEl.text().trim();
    let href = titleEl.attr('href') ?? '';
    if (href && !href.startsWith('http')) {
      href = new URL(href, url).href;
    }
    const match = href.match(/catalogue\/([^/]+)\/index\.html/);
    const externalId = match ? match[1] : '';
    const price = article.find('.price_color').text().trim();
    const availabilityText = article.find('.availability').text().trim().toLowerCase();
    const availability = availabilityText.includes('in stock');
    const imgSrc = article.find('.image_container img').attr('src');
    const imageUrls = imgSrc ? [imgSrc.startsWith('http') ? imgSrc : new URL(imgSrc, url).href] : [];

    if (name && externalId) {
      products.push({
        externalId,
        name,
        price,
        availability,
        category: '',
        productUrl: href,
        imageUrls,
      });
    }
  });

  let nextPageUrl: string | undefined;
  const nextLink = $('li.next a').attr('href');
  if (nextLink) {
    nextPageUrl = nextLink.startsWith('http') ? nextLink : new URL(nextLink, url).href;
  }

  return { products, nextPageUrl };
}

/**
 * Fetch full product detail from product page.
 */
export async function fetchBooksProductDetail(productUrl: string): Promise<BookProduct | null> {
  const { data } = await axios.get<string>(productUrl, { timeout: 15000 });
  const $ = cheerio.load(data);
  const name = $('.product_main h1').text().trim();
  const price = $('.product_main .price_color').text().trim();
  const availabilityText = $('.product_main .availability').text().trim().toLowerCase();
  const availability = availabilityText.includes('in stock');
  const description = $('#product_description').siblings('p').first().text().trim();
  const imgSrc = $('.item.active img').attr('src');
  const imageUrls = imgSrc
    ? [imgSrc.startsWith('http') ? imgSrc : new URL(imgSrc, productUrl).href]
    : [];
  const externalId = productUrl.replace(/.*\/catalogue\/(.+)\/index\.html$/, '$1');
  const category = $('.breadcrumb li').eq(-2).text().trim();

  if (!name) return null;

  return {
    externalId,
    name,
    price,
    availability,
    description,
    imageUrls,
    category,
    productUrl,
  };
}

/**
 * Fetch all product list pages (follow pagination).
 */
export async function fetchAllBooksProducts(
  categoryUrl?: string,
): Promise<BookProductFromList[]> {
  const all: BookProductFromList[] = [];
  let url: string | undefined = categoryUrl;
  do {
    const result = await fetchBooksProductList(url);
    all.push(...result.products);
    url = result.nextPageUrl;
  } while (url);
  return all;
}
