import {
  Injectable,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { VolunteerApplication } from './schemas/volunteer-application.schema';
import { CloudinaryService } from '../cloudinary/cloudinary.service';
import { MailService } from '../mail/mail.service';
import { ReviewApplicationDto } from './dto/review-application.dto';

const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024; // 5MB
const ALLOWED_IMAGE_MIMES = ['image/jpeg', 'image/png', 'image/webp'];
const ALLOWED_PDF_MIME = 'application/pdf';
const ALLOWED_MIMES = [...ALLOWED_IMAGE_MIMES, ALLOWED_PDF_MIME];

export type DocumentType = 'id' | 'certificate' | 'other';

@Injectable()
export class VolunteersService {
  constructor(
    @InjectModel(VolunteerApplication.name)
    private readonly applicationModel: Model<VolunteerApplication>,
    private readonly cloudinary: CloudinaryService,
    private readonly mail: MailService,
  ) {}

  async getOrCreateApplication(userId: string) {
    let app = await this.applicationModel
      .findOne({ userId: new Types.ObjectId(userId) })
      .lean()
      .exec();
    if (!app) {
      const created = await this.applicationModel.create({
        userId: new Types.ObjectId(userId),
        status: 'pending',
        documents: [],
      });
      app = created.toObject();
    }
    return this.toResponse(app as Record<string, unknown>);
  }

  async addDocument(
    userId: string,
    type: DocumentType,
    file: { buffer: Buffer; mimetype: string; originalname?: string },
  ) {
    if (file.buffer.length > MAX_FILE_SIZE_BYTES) {
      throw new BadRequestException(
        `File size must not exceed ${MAX_FILE_SIZE_BYTES / 1024 / 1024}MB`,
      );
    }
    if (!ALLOWED_MIMES.includes(file.mimetype)) {
      throw new BadRequestException(
        `Allowed types: images (JPEG, PNG, WebP) and PDF`,
      );
    }

    let app = await this.applicationModel
      .findOne({ userId: new Types.ObjectId(userId) })
      .exec();
    if (!app) {
      app = await this.applicationModel.create({
        userId: new Types.ObjectId(userId),
        status: 'pending',
        documents: [],
      });
    }
    if (app.status !== 'pending') {
      throw new BadRequestException(
        'Cannot add documents after application has been reviewed',
      );
    }

    const isPdf = file.mimetype === ALLOWED_PDF_MIME;
    let url: string;
    if (this.cloudinary.isConfigured()) {
      const folder = 'cognicare/volunteers';
      const publicId = `vol_${userId}_${type}_${Date.now()}`;
      url = isPdf
        ? await this.cloudinary.uploadRawBuffer(file.buffer, {
            folder,
            publicId,
            resourceType: 'raw',
          })
        : await this.cloudinary.uploadBuffer(file.buffer, {
            folder,
            publicId,
          });
    } else {
      const path = await import('path');
      const fs = await import('fs/promises');
      const uploadsDir = path.join(process.cwd(), 'uploads', 'volunteers');
      await fs.mkdir(uploadsDir, { recursive: true });
      const ext = isPdf ? 'pdf' : file.mimetype === 'image/png' ? 'png' : 'jpg';
      const filename = `vol_${userId}_${type}_${Date.now()}.${ext}`;
      const filePath = path.join(uploadsDir, filename);
      await fs.writeFile(filePath, file.buffer);
      url = `/uploads/volunteers/${filename}`;
    }

    const docPublicId = `vol_${userId}_${type}_${Date.now()}`;
    app.documents.push({
      type,
      url,
      publicId: docPublicId,
      fileName: file.originalname,
      mimeType: file.mimetype,
      uploadedAt: new Date(),
    });
    await app.save();
    return this.getOrCreateApplication(userId);
  }

  async removeDocument(userId: string, documentIndex: number) {
    const app = await this.applicationModel
      .findOne({ userId: new Types.ObjectId(userId) })
      .exec();
    if (!app) throw new NotFoundException('Application not found');
    if (app.status !== 'pending') {
      throw new BadRequestException('Cannot remove documents after review');
    }
    if (documentIndex < 0 || documentIndex >= app.documents.length) {
      throw new BadRequestException('Invalid document index');
    }
    app.documents.splice(documentIndex, 1);
    await app.save();
    return this.getOrCreateApplication(userId);
  }

  async listForAdmin(filters?: { status?: 'pending' | 'approved' | 'denied' }) {
    const query: Record<string, unknown> = {};
    if (filters?.status) query.status = filters.status;
    const list = await this.applicationModel
      .find(query)
      .populate('userId', 'fullName email phone')
      .sort({ updatedAt: -1 })
      .lean()
      .exec();
    return list.map((a) => this.toResponse(a as Record<string, unknown>, true));
  }

  async getByIdForAdmin(applicationId: string, adminId: string) {
    const app = await this.applicationModel
      .findById(applicationId)
      .populate('userId', 'fullName email phone')
      .populate('reviewedBy', 'fullName email')
      .lean()
      .exec();
    if (!app) throw new NotFoundException('Application not found');
    return this.toResponse(app as Record<string, unknown>, true);
  }

  async review(
    applicationId: string,
    adminId: string,
    dto: ReviewApplicationDto,
  ) {
    const app = await this.applicationModel.findById(applicationId).exec();
    if (!app) throw new NotFoundException('Application not found');
    if (app.status !== 'pending') {
      throw new BadRequestException('Application has already been reviewed');
    }
    if (dto.decision === 'denied' && !dto.deniedReason?.trim()) {
      throw new BadRequestException('Denial reason is required when denying');
    }

    app.status = dto.decision;
    app.reviewedBy = new Types.ObjectId(adminId);
    app.reviewedAt = new Date();
    app.deniedReason = dto.deniedReason?.trim();
    await app.save();

    const populated = await this.applicationModel
      .findById(applicationId)
      .populate('userId', 'fullName email')
      .lean()
      .exec();
    const user = (populated as Record<string, unknown>)?.userId as
      | { email?: string; fullName?: string }
      | undefined;
    const email = user?.email;
    const fullName = user?.fullName ?? 'Volunteer';

    if (dto.decision === 'approved' && email) {
      await this.mail.sendVolunteerApproved(email, fullName);
    }
    if (dto.decision === 'denied' && email) {
      const courseUrl = `${process.env.FRONTEND_URL ?? 'https://cognicare.app'}/courses`;
      await this.mail.sendVolunteerDenied(
        email,
        fullName,
        dto.deniedReason,
        courseUrl,
      );
      app.denialNotificationSent = true;
      await app.save();
    }

    return this.getByIdForAdmin(applicationId, adminId);
  }

  private toResponse(
    app: Record<string, unknown>,
    includeUser = false,
  ): Record<string, unknown> {
    const id = (app._id as { toString(): string })?.toString?.();
    const userIdRaw = app.userId;
    const userIdStr =
      userIdRaw && typeof userIdRaw === 'object' && '_id' in userIdRaw
        ? (userIdRaw as { _id: { toString(): string } })._id?.toString?.()
        : (userIdRaw as Types.ObjectId)?.toString?.();
    const doc: Record<string, unknown> = {
      id,
      userId: userIdStr,
      status: app.status,
      documents: app.documents ?? [],
      deniedReason: app.deniedReason,
      reviewedBy: (app.reviewedBy as Types.ObjectId)?.toString?.(),
      reviewedAt: app.reviewedAt,
      createdAt: app.createdAt,
      updatedAt: app.updatedAt,
    };
    if (includeUser && userIdRaw && typeof userIdRaw === 'object') {
      doc.user = userIdRaw;
    }
    return doc;
  }
}
