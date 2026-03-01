import { Inject, Injectable } from "@nestjs/common";
import { Result, ok } from "../../../../core/result";
import { IDonationRepository } from "../../domain/repositories/donation.repository.interface";
import { DonationEntity } from "../../domain/entities/donation.entity";

export const DONATION_REPOSITORY_TOKEN = Symbol("IDonationRepository");

@Injectable()
export class CreateDonationUseCase {
  constructor(
    @Inject(DONATION_REPOSITORY_TOKEN)
    private readonly repo: IDonationRepository,
  ) {}

  async execute(
    userId: string,
    donorName: string,
    dto: {
      title: string;
      description: string;
      category: number;
      condition: number;
      location: string;
      latitude?: number;
      longitude?: number;
      suitableAge?: string;
      isOffer?: boolean;
      imageUrls?: string[];
    },
  ): Promise<Result<Record<string, any>, string>> {
    const entity = DonationEntity.create({
      donorId: userId,
      donorName,
      title: dto.title,
      description: dto.description,
      category: dto.category,
      condition: dto.condition,
      location: dto.location,
      latitude: dto.latitude,
      longitude: dto.longitude,
      suitableAge: dto.suitableAge ?? "",
      isOffer: dto.isOffer ?? true,
      imageUrls: dto.imageUrls ?? [],
    });
    const saved = await this.repo.save(entity);
    return ok({
      id: saved.id,
      donorId: saved.donorId,
      donorName: saved.donorName,
      title: saved.title,
      description: saved.description,
      category: saved.category,
      condition: saved.condition,
      location: saved.location,
      isOffer: saved.isOffer,
      imageUrls: saved.imageUrls,
      createdAt: saved.createdAt?.toISOString() ?? new Date().toISOString(),
    });
  }
}

@Injectable()
export class ListDonationsUseCase {
  constructor(
    @Inject(DONATION_REPOSITORY_TOKEN)
    private readonly repo: IDonationRepository,
  ) {}

  async execute(filters?: {
    isOffer?: boolean;
    category?: number;
    search?: string;
  }): Promise<Result<Record<string, any>[], string>> {
    const list = await this.repo.findAll(filters);
    return ok(
      list.map((d) => ({
        id: d.id,
        donorId: d.donorId,
        donorName: d.donorName,
        title: d.title,
        description: d.description,
        fullDescription: d.description,
        category: d.category,
        condition: d.condition,
        location: d.location,
        latitude: d.latitude,
        longitude: d.longitude,
        suitableAge: d.suitableAge,
        isOffer: d.isOffer,
        imageUrls: d.imageUrls,
        imageUrl: d.imageUrls[0] ?? "",
        createdAt: d.createdAt?.toISOString() ?? new Date().toISOString(),
      })),
    );
  }
}

@Injectable()
export class UploadDonationImageUseCase {
  async execute(file: {
    buffer: Buffer;
    mimetype: string;
  }): Promise<Result<string, string>> {
    // Cloudinary or local file upload – delegate to injected service when available
    const path = await import("path");
    const fs = await import("fs/promises");
    const crypto = await import("crypto");
    const uploadsDir = path.join(process.cwd(), "uploads", "donations");
    await fs.mkdir(uploadsDir, { recursive: true });
    const m = file.mimetype ?? "";
    const ext = m === "image/png" ? "png" : m === "image/webp" ? "webp" : "jpg";
    const id = crypto.randomUUID();
    const filename = `${id}.${ext}`;
    const filePath = path.join(uploadsDir, filename);
    await fs.writeFile(filePath, file.buffer);
    return ok(`/uploads/donations/${filename}`);
  }
}
