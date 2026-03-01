import { Inject, Injectable, OnModuleInit, Logger } from "@nestjs/common";
import { IUseCase } from "../../../../core/application/use-case.interface";
import { Result, ok, err } from "../../../../core/application/result";
import {
  PRODUCT_REPOSITORY_TOKEN,
  REVIEW_REPOSITORY_TOKEN,
  IProductRepository,
  IReviewRepository,
} from "../../domain/repositories/marketplace.repository.interface";
import {
  ProductEntity,
  ReviewEntity,
} from "../../domain/entities/marketplace.entity";
import { CreateProductDto, CreateReviewDto } from "../dto/marketplace.dto";

// ── List Products ──
@Injectable()
export class ListProductsUseCase implements IUseCase<
  { limit?: number; category?: string },
  Result<any[], string>
> {
  constructor(
    @Inject(PRODUCT_REPOSITORY_TOKEN)
    private readonly productRepo: IProductRepository,
  ) {}

  async execute(input: {
    limit?: number;
    category?: string;
  }): Promise<Result<any[], string>> {
    const products = await this.productRepo.findAll(
      input.limit ?? 20,
      input.category,
    );
    return ok(products.map((p) => p.toObject()));
  }
}

// ── List Products By Seller ──
@Injectable()
export class ListProductsBySellerUseCase implements IUseCase<
  string,
  Result<any[], string>
> {
  constructor(
    @Inject(PRODUCT_REPOSITORY_TOKEN)
    private readonly productRepo: IProductRepository,
  ) {}

  async execute(sellerId: string): Promise<Result<any[], string>> {
    const products = await this.productRepo.findBySellerId(sellerId);
    return ok(products.map((p) => p.toObject()));
  }
}

// ── Get Product By Id ──
@Injectable()
export class GetProductByIdUseCase implements IUseCase<
  string,
  Result<any, string>
> {
  constructor(
    @Inject(PRODUCT_REPOSITORY_TOKEN)
    private readonly productRepo: IProductRepository,
  ) {}

  async execute(id: string): Promise<Result<any, string>> {
    const product = await this.productRepo.findById(id);
    if (!product) return err("Product not found");
    return ok(product.toObject());
  }
}

// ── Create Product ──
@Injectable()
export class CreateProductUseCase implements IUseCase<
  { userId: string; dto: CreateProductDto },
  Result<any, string>
> {
  constructor(
    @Inject(PRODUCT_REPOSITORY_TOKEN)
    private readonly productRepo: IProductRepository,
  ) {}

  async execute(input: {
    userId: string;
    dto: CreateProductDto;
  }): Promise<Result<any, string>> {
    const entity = ProductEntity.create({
      sellerId: input.userId,
      title: input.dto.title,
      price: input.dto.price,
      imageUrl: input.dto.imageUrl,
      description: input.dto.description ?? "",
      badge: input.dto.badge,
      category: input.dto.category ?? "all",
      order: input.dto.order ?? 0,
    });
    const saved = await this.productRepo.save(entity);
    return ok(saved.toObject());
  }
}

// ── List Reviews ──
@Injectable()
export class ListReviewsUseCase implements IUseCase<
  string,
  Result<any[], string>
> {
  constructor(
    @Inject(REVIEW_REPOSITORY_TOKEN)
    private readonly reviewRepo: IReviewRepository,
  ) {}

  async execute(productId: string): Promise<Result<any[], string>> {
    const reviews = await this.reviewRepo.findByProductId(productId);
    return ok(reviews.map((r) => r.toObject()));
  }
}

// ── Create or Update Review ──
@Injectable()
export class CreateOrUpdateReviewUseCase implements IUseCase<
  { productId: string; userId: string; userName: string; dto: CreateReviewDto },
  Result<any, string>
> {
  constructor(
    @Inject(REVIEW_REPOSITORY_TOKEN)
    private readonly reviewRepo: IReviewRepository,
  ) {}

  async execute(input: {
    productId: string;
    userId: string;
    userName: string;
    dto: CreateReviewDto;
  }): Promise<Result<any, string>> {
    const existing = await this.reviewRepo.findByProductAndUser(
      input.productId,
      input.userId,
    );
    if (existing) {
      existing.updateRating(input.dto.rating, input.dto.comment);
      await this.reviewRepo.update(existing);
      return ok(existing.toObject());
    }
    const entity = ReviewEntity.create({
      productId: input.productId,
      userId: input.userId,
      userName: input.userName,
      rating: input.dto.rating,
      comment: input.dto.comment ?? "",
    });
    const saved = await this.reviewRepo.save(entity);
    return ok(saved.toObject());
  }
}

// ── Upload Product Image ──
@Injectable()
export class UploadProductImageUseCase implements IUseCase<
  { buffer: Buffer; mimetype: string },
  Result<string, string>
> {
  async execute(input: {
    buffer: Buffer;
    mimetype: string;
  }): Promise<Result<string, string>> {
    try {
      let cloudinary: any;
      try {
        const { v2 } = await import("cloudinary");
        cloudinary = v2;
      } catch {
        /* noop */
      }

      if (cloudinary && process.env.CLOUDINARY_CLOUD_NAME) {
        const crypto = await import("crypto");
        const publicId = `product-${crypto.randomUUID()}`;
        const url = await new Promise<string>((resolve, reject) => {
          const { Readable } = require("stream");
          const stream = cloudinary.uploader.upload_stream(
            {
              folder: "cognicare/products",
              public_id: publicId,
              resource_type: "image",
            },
            (e: any, r: any) => {
              if (e) reject(e);
              else resolve(r?.secure_url ?? "");
            },
          );
          Readable.from(input.buffer).pipe(stream);
        });
        return ok(url);
      }

      const path = await import("path");
      const fs = await import("fs/promises");
      const crypto = await import("crypto");
      const dir = path.join(process.cwd(), "uploads", "products");
      await fs.mkdir(dir, { recursive: true });
      const ext = input.mimetype === "image/png" ? "png" : "jpg";
      const filename = `${crypto.randomUUID()}.${ext}`;
      await fs.writeFile(path.join(dir, filename), input.buffer);
      return ok(`/uploads/products/${filename}`);
    } catch (error) {
      return err(error instanceof Error ? error.message : "Upload failed");
    }
  }
}

// ── Seed Products (onModuleInit) ──
@Injectable()
export class SeedProductsService implements OnModuleInit {
  private readonly logger = new Logger(SeedProductsService.name);
  constructor(
    @Inject(PRODUCT_REPOSITORY_TOKEN)
    private readonly productRepo: IProductRepository,
  ) {}

  async onModuleInit() {
    const count = await this.productRepo.count();
    if (count > 0) return;
    this.logger.log("Seeding marketplace products...");
    const seeds = this.getSeedProducts();
    const entities = seeds.map((s) => ProductEntity.create(s));
    await this.productRepo.saveMany(entities);
    this.logger.log(`Seeded ${seeds.length} products`);
  }

  private getSeedProducts(): Omit<
    import("../../domain/entities/marketplace.entity").ProductProps,
    "createdAt" | "updatedAt"
  >[] {
    return [
      {
        title: "Multivitamines complex",
        price: "18,90",
        imageUrl:
          "https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400",
        description: "Immunité, vitalité, antioxydant.",
        category: "supplements",
        badge: "Meilleure vente",
        externalUrl: "https://www.terravita.fr/collections/immunite-vitalite",
        order: 0,
      },
      {
        title: "Set de jeux de mémoire cognitive",
        price: "29",
        imageUrl:
          "https://images.unsplash.com/photo-1611195974226-ef7b4610e667?w=400",
        description: "Cartes et activités pour stimuler la mémoire.",
        category: "games",
        badge: "Top",
        order: 0,
      },
      {
        title: "Veste sensorielle adaptable",
        price: "45",
        imageUrl:
          "https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400",
        description: "Vêtement apaisant pour hypersensibilité sensorielle.",
        category: "clothing",
        badge: "Adapté TSA",
        order: 0,
      },
      {
        title: "Fidget cube anti-stress",
        price: "12",
        imageUrl:
          "https://images.unsplash.com/photo-1609220136736-443140cffec6?w=400",
        description: "Stimulation tactile et concentration.",
        category: "sensory",
        badge: "Top",
        order: 0,
      },
      {
        title: "Puzzle 3D motricité fine",
        price: "22",
        imageUrl:
          "https://images.unsplash.com/photo-1587654780291-39c9404d7dd0?w=400",
        description: "Développe la coordination œil-main.",
        category: "motor",
        order: 0,
      },
    ];
  }
}
