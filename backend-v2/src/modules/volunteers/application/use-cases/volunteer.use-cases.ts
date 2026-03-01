import { Inject, Injectable, Logger } from '@nestjs/common';
import { ValidationException } from '@/core/domain';
import {
  VolunteerApplicationEntity,
  VolunteerDocProps,
  VolunteerTaskEntity,
  IVolunteerApplicationRepository,
  IVolunteerTaskRepository,
} from '../../domain';
import { UpdateApplicationMeDto, ReviewApplicationDto, AssignTaskDto } from '../dto/volunteer.dto';

export const VOLUNTEER_APPLICATION_REPOSITORY_TOKEN = Symbol('IVolunteerApplicationRepository');
export const VOLUNTEER_TASK_REPOSITORY_TOKEN = Symbol('IVolunteerTaskRepository');

/* ─── GetOrCreateApplication ─── */
@Injectable()
export class GetOrCreateApplicationUseCase {
  constructor(
    @Inject(VOLUNTEER_APPLICATION_REPOSITORY_TOKEN) private readonly repo: IVolunteerApplicationRepository,
  ) {}

  async execute(userId: string): Promise<VolunteerApplicationEntity> {
    const existing = await this.repo.findByUserId(userId);
    if (existing) return existing;
    const app = VolunteerApplicationEntity.create(userId);
    return this.repo.save(app);
  }
}

/* ─── UpdateApplicationMe ─── */
@Injectable()
export class UpdateApplicationMeUseCase {
  constructor(
    @Inject(VOLUNTEER_APPLICATION_REPOSITORY_TOKEN) private readonly repo: IVolunteerApplicationRepository,
  ) {}

  async execute(userId: string, dto: UpdateApplicationMeDto): Promise<VolunteerApplicationEntity> {
    const app = await this.repo.findByUserId(userId);
    if (!app) throw new ValidationException('Application not found');
    app.updateProfile(dto);
    return this.repo.update(app);
  }
}

/* ─── AddDocument ─── */
@Injectable()
export class AddDocumentUseCase {
  private readonly logger = new Logger(AddDocumentUseCase.name);
  private readonly ALLOWED_MIMES = ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'];
  private readonly MAX_SIZE = 5 * 1024 * 1024; // 5 MB

  constructor(
    @Inject(VOLUNTEER_APPLICATION_REPOSITORY_TOKEN) private readonly repo: IVolunteerApplicationRepository,
  ) {}

  async execute(
    userId: string,
    file: { buffer: Buffer; mimetype: string; originalname: string; size: number },
    docType: string,
    uploadFn: (buffer: Buffer, options: any) => Promise<string>,
  ): Promise<VolunteerApplicationEntity> {
    if (!this.ALLOWED_MIMES.includes(file.mimetype)) {
      throw new ValidationException('File type not allowed. Use PDF, JPEG, PNG, or WebP.');
    }
    if (file.size > this.MAX_SIZE) {
      throw new ValidationException('File too large (max 5 MB).');
    }

    const app = await this.repo.findByUserId(userId);
    if (!app) throw new ValidationException('Application not found');

    let url: string;
    try {
      url = await uploadFn(file.buffer, {
        folder: `volunteers/${userId}/documents`,
        publicId: `doc_${Date.now()}`,
      });
    } catch (err) {
      this.logger.warn('Cloudinary upload failed, using local fallback', err);
      const fs = await import('fs');
      const path = await import('path');
      const uploadDir = path.join(process.cwd(), 'uploads', 'volunteers');
      if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
      const fileName = `${userId}_${Date.now()}_${file.originalname}`;
      fs.writeFileSync(path.join(uploadDir, fileName), file.buffer);
      url = `/uploads/volunteers/${fileName}`;
    }

    const doc: VolunteerDocProps = {
      type: (docType as any) || 'other',
      url,
      fileName: file.originalname,
      mimeType: file.mimetype,
      uploadedAt: new Date(),
    };
    app.addDocument(doc);
    return this.repo.update(app);
  }
}

/* ─── RemoveDocument ─── */
@Injectable()
export class RemoveDocumentUseCase {
  constructor(
    @Inject(VOLUNTEER_APPLICATION_REPOSITORY_TOKEN) private readonly repo: IVolunteerApplicationRepository,
  ) {}

  async execute(userId: string, index: number): Promise<VolunteerApplicationEntity> {
    const app = await this.repo.findByUserId(userId);
    if (!app) throw new ValidationException('Application not found');
    app.removeDocument(index);
    return this.repo.update(app);
  }
}

/* ─── CompleteCertification ─── */
@Injectable()
export class CompleteCertificationUseCase {
  constructor(
    @Inject(VOLUNTEER_APPLICATION_REPOSITORY_TOKEN) private readonly repo: IVolunteerApplicationRepository,
  ) {}

  async execute(
    userId: string,
    hasCompletedQualification: () => Promise<boolean>,
  ): Promise<VolunteerApplicationEntity> {
    const app = await this.repo.findByUserId(userId);
    if (!app) throw new ValidationException('Application not found');
    if (app.status !== 'approved') {
      throw new ValidationException('Application must be approved before certification');
    }
    const completed = await hasCompletedQualification();
    if (!completed) {
      throw new ValidationException('You must complete a qualification course before certification');
    }
    app.certifyTraining();
    return this.repo.update(app);
  }
}

/* ─── ListForAdmin ─── */
@Injectable()
export class ListApplicationsForAdminUseCase {
  constructor(
    @Inject(VOLUNTEER_APPLICATION_REPOSITORY_TOKEN) private readonly repo: IVolunteerApplicationRepository,
  ) {}

  async execute(status?: string): Promise<VolunteerApplicationEntity[]> {
    return this.repo.findAll(status ? { status } : undefined);
  }
}

/* ─── GetByIdForAdmin ─── */
@Injectable()
export class GetApplicationByIdUseCase {
  constructor(
    @Inject(VOLUNTEER_APPLICATION_REPOSITORY_TOKEN) private readonly repo: IVolunteerApplicationRepository,
  ) {}

  async execute(id: string): Promise<VolunteerApplicationEntity> {
    const app = await this.repo.findById(id);
    if (!app) throw new ValidationException('Application not found');
    return app;
  }
}

/* ─── ReviewApplication ─── */
@Injectable()
export class ReviewApplicationUseCase {
  constructor(
    @Inject(VOLUNTEER_APPLICATION_REPOSITORY_TOKEN) private readonly repo: IVolunteerApplicationRepository,
  ) {}

  async execute(
    id: string,
    reviewerId: string,
    dto: ReviewApplicationDto,
    sendEmail?: (userId: string, reason?: string) => Promise<void>,
  ): Promise<VolunteerApplicationEntity> {
    const app = await this.repo.findById(id);
    if (!app) throw new ValidationException('Application not found');

    if (dto.decision === 'approved') {
      app.approve(reviewerId);
      if (sendEmail) await sendEmail(app.userId).catch(() => {});
    } else {
      app.deny(reviewerId, dto.deniedReason);
      if (sendEmail) await sendEmail(app.userId, dto.deniedReason).catch(() => {});
    }
    return this.repo.update(app);
  }
}

/* ─── AssignTask ─── */
@Injectable()
export class AssignTaskUseCase {
  constructor(
    @Inject(VOLUNTEER_TASK_REPOSITORY_TOKEN) private readonly taskRepo: IVolunteerTaskRepository,
  ) {}

  async execute(assignedBy: string, dto: AssignTaskDto): Promise<VolunteerTaskEntity> {
    const task = VolunteerTaskEntity.create({
      assignedBy,
      volunteerId: dto.volunteerId,
      title: dto.title,
      description: dto.description ?? '',
      dueDate: dto.dueDate ? new Date(dto.dueDate) : undefined,
    });
    return this.taskRepo.save(task);
  }
}

/* ─── GetMyTasks ─── */
@Injectable()
export class GetMyTasksUseCase {
  constructor(
    @Inject(VOLUNTEER_TASK_REPOSITORY_TOKEN) private readonly taskRepo: IVolunteerTaskRepository,
  ) {}

  async execute(volunteerId: string): Promise<VolunteerTaskEntity[]> {
    return this.taskRepo.findByVolunteerId(volunteerId);
  }
}
