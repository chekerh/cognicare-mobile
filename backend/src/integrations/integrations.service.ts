import { Injectable, Logger, NotFoundException, OnModuleInit } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import axios from 'axios';
import {
  fetchAllBioherbsProducts,
  fetchBioherbsProducts,
} from './scraper/bioherbs.scraper';
import {
  ExternalWebsite,
  ExternalWebsiteDocument,
  FormFieldMapping,
} from './schemas/external-website.schema';
import {
  ExternalProduct,
  ExternalProductDocument,
} from './schemas/external-product.schema';
import {
  IntegrationOrder,
  IntegrationOrderDocument,
} from './schemas/integration-order.schema';

const BIOHERBS_SLUG = 'bioherbs';
const BIOHERBS_BASE = 'https://www.bioherbs.tn';

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
    await this.websiteModel.deleteMany({ slug: 'books-to-scrape' }).exec();
    let exists = await this.websiteModel.findOne({ slug: BIOHERBS_SLUG }).exec();
    if (!exists) {
      await this.websiteModel.create({
        slug: BIOHERBS_SLUG,
        name: 'BioHerbs',
        baseUrl: BIOHERBS_BASE,
        isActive: true,
        refreshIntervalMinutes: 60,
      });
      this.logger.log('Registered external website: BioHerbs');
    }
  }

  async listWebsites(): Promise<ExternalWebsite[]> {
    return this.websiteModel
      .find({ isActive: true, slug: BIOHERBS_SLUG })
      .sort({ name: 1 })
      .lean()
      .exec();
  }

  async getWebsite(slug: string): Promise<ExternalWebsite> {
    const doc = await this.websiteModel.findOne({ slug, isActive: true }).lean().exec();
    if (!doc) throw new NotFoundException(`Website ${slug} not found`);
    return doc as ExternalWebsite;
  }

  /**
   * Catalogue pour un site intégré (BioHerbs uniquement).
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
    const website = await this.getWebsite(websiteSlug);
    const websiteId = (website as unknown as { _id: Types.ObjectId })._id;
    const limit = 20;
    const skip = ((page ?? 1) - 1) * limit;

    if (websiteSlug !== BIOHERBS_SLUG) {
      throw new NotFoundException(`Website ${websiteSlug} not supported`);
    }

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
      await this.syncBioherbsCatalog(websiteId);
      products = await this.productModel
        .find({ websiteId })
        .sort({ name: 1 })
        .skip(skip)
        .limit(limit)
        .lean()
        .exec();
    }
    const categories = [{ name: 'Nos produits', slug: 'nos-produits', url: `${BIOHERBS_BASE}/collections/nos-produits` }];
    return {
      categories,
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

  private async syncBioherbsCatalog(websiteId: Types.ObjectId): Promise<void> {
    const list = await fetchAllBioherbsProducts();
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
    this.logger.log(`Synced ${list.length} products for BioHerbs`);
  }

  async getProduct(websiteSlug: string, externalId: string): Promise<ExternalProduct & { lastScrapedAt?: Date }> {
    if (websiteSlug !== BIOHERBS_SLUG) {
      throw new NotFoundException(`Website ${websiteSlug} not supported`);
    }
    const website = await this.getWebsite(websiteSlug);
    const websiteId = (website as unknown as { _id: Types.ObjectId })._id;
    const product = await this.productModel.findOne({ websiteId, externalId }).lean().exec();
    if (product) return product as ExternalProduct & { lastScrapedAt?: Date };
    const list = await fetchBioherbsProducts(1, 100);
    const found = list.products.find((p) => p.externalId === externalId);
    if (!found) throw new NotFoundException('Product not found');
    const created = await this.productModel
      .findOneAndUpdate(
        { websiteId, externalId: found.externalId },
        {
          $set: {
            websiteId,
            externalId: found.externalId,
            name: found.name,
            price: found.price,
            availability: found.availability,
            category: found.category,
            productUrl: found.productUrl,
            imageUrls: found.imageUrls ?? [],
            lastScrapedAt: new Date(),
          },
        },
        { upsert: true, new: true },
      )
      .lean()
      .exec();
    return created as ExternalProduct & { lastScrapedAt?: Date };
  }

  /**
   * Refresh a single product from the live site (e.g. on user view).
   */
  async refreshProduct(
    websiteSlug: string,
    externalId: string,
  ): Promise<ExternalProduct & { lastScrapedAt?: Date }> {
    if (websiteSlug !== BIOHERBS_SLUG) {
      throw new NotFoundException(`Website ${websiteSlug} not supported`);
    }
    return this.getProduct(websiteSlug, externalId);
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
  ): Promise<{ orderId: string; status: string; sentToSiteAt: Date | null; message: string; cartUrl?: string }> {
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

    const websiteDoc = await this.websiteModel.findOne({ slug: websiteSlug }).lean().exec();
    const formActionUrl = websiteDoc?.formActionUrl?.trim();

    try {
      if (formActionUrl) {
        await this.sendOrderToExternalSite(
          websiteDoc as ExternalWebsite & { _id: Types.ObjectId },
          order,
          payload,
        );
        order.sentToSiteAt = new Date();
        order.status = 'sent';
        await order.save();
      }
      // Pas d’ouverture du site : commande uniquement dans l’app, données envoyées vers formActionUrl si configuré (ex. BioHerbs).
    } catch (e) {
      this.logger.warn(
        `Order ${order._id} saved but send to site failed: ${(e as Error).message}`,
      );
    }

    const sentAt = order.sentToSiteAt ?? null;
    const message =
      order.status === 'sent'
        ? 'Commande enregistrée et envoyée. Le marchand vous contactera pour la livraison.'
        : 'Commande enregistrée. Elle sera traitée sous peu.';

    return {
      orderId: (order._id as Types.ObjectId).toString(),
      status: order.status,
      sentToSiteAt: sentAt,
      message,
    };
  }

  /**
   * Envoi réel de la commande vers le site : POST du formulaire vers formActionUrl.
   * Utilise formFieldMapping pour mapper nos champs (fullName, email, …) vers les noms attendus par le site.
   */
  private async sendOrderToExternalSite(
    website: ExternalWebsite & { _id?: Types.ObjectId },
    order: IntegrationOrderDocument,
    payload: {
      externalId: string;
      quantity?: number;
      productName?: string;
      formData: Record<string, string>;
    },
  ): Promise<void> {
    const formActionUrl = website.formActionUrl?.trim();
    if (!formActionUrl) return;

    const formData = payload.formData ?? {};
    const mapping = website.formFieldMapping as FormFieldMapping[] | undefined;
    const params = new URLSearchParams();

    if (mapping?.length) {
      for (const m of mapping) {
        const value = formData[m.appFieldName] ?? '';
        params.append(m.siteSelector, value);
      }
    } else {
      for (const [k, v] of Object.entries(formData)) {
        params.append(k, String(v ?? ''));
      }
    }

    params.append('productId', payload.externalId);
    params.append('productName', payload.productName ?? order.productName ?? '');
    params.append('quantity', String(payload.quantity ?? order.quantity ?? 1));

    await axios.post(formActionUrl, params.toString(), {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      timeout: 15000,
      maxRedirects: 5,
      validateStatus: (status) => status >= 200 && status < 400,
    }).catch((err) => {
      const msg = axios.isAxiosError(err)
        ? `${err.response?.status ?? err.code}: ${err.message}`
        : (err as Error).message;
      throw new Error(`Envoi au site échoué: ${msg}`);
    });

    this.logger.log(`Order ${order._id} sent to site ${website.slug} (${formActionUrl})`);
  }
}
