import { Injectable, Logger, NotFoundException, OnModuleInit } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import {
  fetchBooksCategories,
  fetchBooksProductDetail,
  fetchBooksProductList,
  fetchAllBooksProducts,
  BookProduct,
} from './scraper/books-to-scrape.scraper';
import {
  ExternalWebsite,
  ExternalWebsiteDocument,
} from './schemas/external-website.schema';
import {
  ExternalProduct,
  ExternalProductDocument,
} from './schemas/external-product.schema';
import {
  IntegrationOrder,
  IntegrationOrderDocument,
} from './schemas/integration-order.schema';

const BOOKS_TO_SCRAPE_SLUG = 'books-to-scrape';
const BOOKS_BASE = 'http://books.toscrape.com';

@Injectable()
export class IntegrationsService implements OnModuleInit {
  private readonly logger = new Logger(IntegrationsService.name);

  constructor(
    @InjectModel(ExternalWebsite.name)
    private readonly websiteModel: Model<ExternalWebsiteDocument>,
    @InjectModel(ExternalProduct.name)
    private readonly productModel: Model<ExternalProductDocument>,
    @InjectModel(IntegrationOrder.name)
    private readonly orderModel: Model<IntegrationOrderDocument>,
  ) {}

  async onModuleInit() {
    const exists = await this.websiteModel.findOne({ slug: BOOKS_TO_SCRAPE_SLUG }).exec();
    if (!exists) {
      await this.websiteModel.create({
        slug: BOOKS_TO_SCRAPE_SLUG,
        name: 'Books to Scrape',
        baseUrl: BOOKS_BASE,
        isActive: true,
        refreshIntervalMinutes: 60,
      });
      this.logger.log('Registered external website: Books to Scrape');
    }
  }

  async listWebsites(): Promise<ExternalWebsite[]> {
    return this.websiteModel.find({ isActive: true }).sort({ name: 1 }).lean().exec();
  }

  async getWebsite(slug: string): Promise<ExternalWebsite> {
    const doc = await this.websiteModel.findOne({ slug, isActive: true }).lean().exec();
    if (!doc) throw new NotFoundException(`Website ${slug} not found`);
    return doc as ExternalWebsite;
  }

  /**
   * Catalog for a website. For Books to Scrape: returns categories and products from DB;
   * if DB is empty for this site, runs initial scrape and then returns.
   */
  async getCatalog(
    websiteSlug: string,
    categorySlug?: string,
    page?: number,
    forceRefresh?: boolean,
  ): Promise<{
    categories: Array<{ name: string; slug: string; url: string }>;
    products: Array<{
      externalId: string;
      name: string;
      price: string;
      availability: boolean;
      category: string;
      productUrl: string;
      imageUrls: string[];
    }>;
  }> {
    if (websiteSlug !== BOOKS_TO_SCRAPE_SLUG) {
      throw new NotFoundException(`Scraper for ${websiteSlug} not implemented`);
    }

    const website = await this.getWebsite(websiteSlug);
    const websiteId = (website as unknown as { _id: Types.ObjectId })._id;

    let categories = await fetchBooksCategories();
    const limit = 20;
    const skip = ((page ?? 1) - 1) * limit;

    if ((page ?? 1) === 1 && forceRefresh) {
      await this.productModel.deleteMany({ websiteId }).exec();
    }

    let products = await this.productModel
      .find({ websiteId })
      .sort({ name: 1 })
      .skip(skip)
      .limit(limit)
      .lean()
      .exec();

    if (products.length === 0 && (page ?? 1) === 1) {
      await this.syncBooksToScrapeCatalog(websiteId);
      products = await this.productModel
        .find({ websiteId })
        .sort({ name: 1 })
        .skip(skip)
        .limit(limit)
        .lean()
        .exec();
    }

    if (categorySlug) {
      products = await this.productModel
        .find({ websiteId, category: new RegExp(categorySlug, 'i') })
        .sort({ name: 1 })
        .skip(skip)
        .limit(limit)
        .lean()
        .exec();
    }

    return {
      categories: categories.map((c) => ({ name: c.name, slug: c.slug, url: c.url })),
      products: products.map((p) => ({
        externalId: p.externalId,
        name: p.name,
        price: p.price,
        availability: p.availability,
        category: p.category,
        productUrl: p.productUrl,
        imageUrls: p.imageUrls ?? [],
      })),
    };
  }

  private async syncBooksToScrapeCatalog(websiteId: Types.ObjectId): Promise<void> {
    const list = await fetchAllBooksProducts();
    for (const item of list) {
      await this.productModel
        .findOneAndUpdate(
          { websiteId, externalId: item.externalId },
          {
            $set: {
              websiteId,
              externalId: item.externalId,
              name: item.name,
              price: item.price,
              availability: item.availability,
              category: item.category,
              productUrl: item.productUrl,
              imageUrls: item.imageUrls ?? [],
              lastScrapedAt: new Date(),
            },
          },
          { upsert: true },
        )
        .exec();
    }
    this.logger.log(`Synced ${list.length} products for Books to Scrape`);
  }

  async getProduct(websiteSlug: string, externalId: string): Promise<ExternalProduct & { lastScrapedAt?: Date }> {
    if (websiteSlug !== BOOKS_TO_SCRAPE_SLUG) {
      throw new NotFoundException(`Scraper for ${websiteSlug} not implemented`);
    }

    const website = await this.getWebsite(websiteSlug);
    const websiteId = (website as unknown as { _id: Types.ObjectId })._id;

    let product = await this.productModel
      .findOne({ websiteId, externalId })
      .lean()
      .exec();

    if (!product) {
      const list = await fetchBooksProductList();
      const found = list.products.find((p) => p.externalId === externalId);
      if (!found) throw new NotFoundException('Product not found');
      const full = await fetchBooksProductDetail(found.productUrl);
      if (!full) throw new NotFoundException('Product detail not found');
      product = await this.productModel
        .findOneAndUpdate(
          { websiteId, externalId: full.externalId },
          { $set: this.bookProductToDoc(websiteId, full) },
          { upsert: true, new: true },
        )
        .lean()
        .exec();
    }

    return product as ExternalProduct & { lastScrapedAt?: Date };
  }

  /**
   * Refresh a single product from the live site (e.g. on user view).
   */
  async refreshProduct(
    websiteSlug: string,
    externalId: string,
  ): Promise<ExternalProduct & { lastScrapedAt?: Date }> {
    if (websiteSlug !== BOOKS_TO_SCRAPE_SLUG) {
      throw new NotFoundException(`Scraper for ${websiteSlug} not implemented`);
    }

    const website = await this.getWebsite(websiteSlug);
    const websiteId = (website as unknown as { _id: Types.ObjectId })._id;
    const existing = await this.productModel.findOne({ websiteId, externalId }).lean().exec();
    const productUrl = existing?.productUrl ?? `${BOOKS_BASE}/catalogue/${externalId}/index.html`;
    const full = await fetchBooksProductDetail(productUrl);
    if (!full) throw new NotFoundException('Product no longer available');

    const updated = await this.productModel
      .findOneAndUpdate(
        { websiteId, externalId },
        { $set: this.bookProductToDoc(websiteId, full) },
        { new: true },
      )
      .lean()
      .exec();

    return updated as ExternalProduct & { lastScrapedAt?: Date };
  }

  private bookProductToDoc(
    websiteId: Types.ObjectId,
    p: BookProduct,
  ): Partial<ExternalProduct> {
    return {
      websiteId,
      externalId: p.externalId,
      name: p.name,
      price: p.price,
      availability: p.availability,
      description: p.description,
      imageUrls: p.imageUrls,
      category: p.category,
      productUrl: p.productUrl,
      lastScrapedAt: new Date(),
    };
  }

  /**
   * Enregistre la commande en base puis l'envoie au site cible (sans ouvrir le site dans le navigateur).
   */
  async submitOrder(
    websiteSlug: string,
    payload: {
      externalId: string;
      quantity?: number;
      productName?: string;
      formData: Record<string, string>;
    },
  ): Promise<{ orderId: string; status: string; message: string }> {
    const website = await this.getWebsite(websiteSlug);
    const websiteId = (website as unknown as { _id: Types.ObjectId })._id;

    const order = await this.orderModel.create({
      websiteId,
      externalId: payload.externalId,
      productName: payload.productName ?? '',
      quantity: payload.quantity ?? 1,
      formData: payload.formData ?? {},
      status: 'received',
    });

    try {
      if (websiteSlug === BOOKS_TO_SCRAPE_SLUG) {
        await this.sendOrderToBooksToScrape(order, payload);
      }
      order.sentToSiteAt = new Date();
      order.status = 'sent';
      await order.save();
    } catch (e) {
      this.logger.warn(
        `Order ${order._id} saved but send to site failed: ${(e as Error).message}`,
      );
    }

    return {
      orderId: (order._id as Types.ObjectId).toString(),
      status: order.status,
      message:
        'Commande enregistrée. Le site vous contactera pour la livraison.',
    };
  }

  private async sendOrderToBooksToScrape(
    _order: IntegrationOrderDocument,
    _payload: { externalId: string; quantity?: number; formData: Record<string, string> },
  ): Promise<void> {
    // Books to Scrape est un site démo sans API de commande réelle.
    // La commande est enregistrée en base ; pour un vrai site (ex. Bioherbs)
    // on ferait ici un POST vers le formulaire du site.
  }
}
