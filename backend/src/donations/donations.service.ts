import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Donation, DonationDocument } from './schemas/donation.schema';
import { User, UserDocument } from '../users/schemas/user.schema';
import { CreateDonationDto } from './dto/create-donation.dto';
import { CloudinaryService } from '../cloudinary/cloudinary.service';

@Injectable()
export class DonationsService {
  constructor(
    @InjectModel(Donation.name) private donationModel: Model<DonationDocument>,
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private cloudinary: CloudinaryService,
  ) {}

  async uploadDonationImage(file: {
    buffer: Buffer;
    mimetype: string;
  }): Promise<string> {
    if (this.cloudinary.isConfigured()) {
      const crypto = await import('crypto');
      const publicId = `donation-${crypto.randomUUID()}`;
      return this.cloudinary.uploadBuffer(file.buffer, {
        folder: 'cognicare/donations',
        publicId,
      });
    }
    const path = await import('path');
    const fs = await import('fs/promises');
    const crypto = await import('crypto');
    const uploadsDir = path.join(process.cwd(), 'uploads', 'donations');
    await fs.mkdir(uploadsDir, { recursive: true });
    const m = file.mimetype ?? '';
    const ext =
      m === 'image/png'
        ? 'png'
        : m === 'image/webp'
          ? 'webp'
          : m === 'image/heic'
            ? 'heic'
            : 'jpg';
    const id = crypto.randomUUID();
    const filename = `${id}.${ext}`;
    const filePath = path.join(uploadsDir, filename);
    await fs.writeFile(filePath, file.buffer);
    return `/uploads/donations/${filename}`;
  }

  async create(
    userId: string,
    dto: CreateDonationDto,
  ): Promise<{
    id: string;
    donorId: string;
    donorName: string;
    title: string;
    description: string;
    category: number;
    condition: number;
    location: string;
    isOffer: boolean;
    imageUrls: string[];
    createdAt: string;
  }> {
    const uid = new Types.ObjectId(userId);
    const user = await this.userModel.findById(uid).select('fullName').exec();
    if (!user) throw new NotFoundException('User not found');

    const donation = new this.donationModel({
      donorId: uid,
      donorName: user.fullName,
      title: dto.title,
      description: dto.description,
      category: dto.category,
      condition: dto.condition,
      location: dto.location,
      isOffer: dto.isOffer ?? true,
      imageUrls: dto.imageUrls ?? [],
    });
    await donation.save();

    return {
      id: donation._id.toString(),
      donorId: donation.donorId.toString(),
      donorName: donation.donorName,
      title: donation.title,
      description: donation.description,
      category: donation.category,
      condition: donation.condition,
      location: donation.location,
      isOffer: donation.isOffer,
      imageUrls: donation.imageUrls,
      createdAt: (donation as any).createdAt?.toISOString() ?? new Date().toISOString(),
    };
  }

  async findAll(filters?: {
    isOffer?: boolean;
    category?: number;
    search?: string;
  }): Promise<
    {
      id: string;
      donorId: string;
      donorName: string;
      title: string;
      description: string;
      fullDescription?: string;
      category: number;
      condition: number;
      location: string;
      isOffer: boolean;
      imageUrls: string[];
      imageUrl: string;
      createdAt: string;
    }[]
  > {
    const q: Record<string, unknown> = {};
    if (filters?.isOffer !== undefined) q.isOffer = filters.isOffer;
    if (filters?.category !== undefined && filters.category > 0) {
      const map: Record<number, number> = {
        1: 1,
        2: 2,
        3: 0,
      };
      const backendCat = map[filters.category];
      if (backendCat !== undefined) q.category = backendCat;
    }
    if (filters?.search && filters.search.trim()) {
      const s = filters.search.trim();
      q.$or = [
        { title: new RegExp(s, 'i') },
        { description: new RegExp(s, 'i') },
        { location: new RegExp(s, 'i') },
      ];
    }

    const docs = await this.donationModel
      .find(q)
      .sort({ createdAt: -1 })
      .lean()
      .exec();

    return docs.map((d: any) => ({
      id: d._id.toString(),
      donorId: d.donorId?.toString(),
      donorName: d.donorName ?? '',
      title: d.title ?? '',
      description: d.description ?? '',
      fullDescription: d.description,
      category: d.category ?? 0,
      condition: d.condition ?? 1,
      location: d.location ?? '',
      isOffer: d.isOffer ?? true,
      imageUrls: d.imageUrls ?? [],
      imageUrl: (d.imageUrls && d.imageUrls[0]) || '',
      createdAt: d.createdAt?.toISOString?.() ?? new Date().toISOString(),
    }));
  }
}
