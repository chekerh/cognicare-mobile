import { Module, Logger } from "@nestjs/common";
import { MongooseModule } from "@nestjs/mongoose";
import {
  VolunteerApplicationMongoSchema,
  VolunteerTaskMongoSchema,
} from "./infrastructure/persistence/mongo/volunteer.schema";
import {
  VolunteerApplicationMongoRepository,
  VolunteerTaskMongoRepository,
} from "./infrastructure/persistence/mongo/volunteer.mongo-repository";
import {
  VOLUNTEER_APPLICATION_REPOSITORY_TOKEN,
  VOLUNTEER_TASK_REPOSITORY_TOKEN,
  GetOrCreateApplicationUseCase,
  UpdateApplicationMeUseCase,
  AddDocumentUseCase,
  RemoveDocumentUseCase,
  CompleteCertificationUseCase,
  ListApplicationsForAdminUseCase,
  GetApplicationByIdUseCase,
  ReviewApplicationUseCase,
  AssignTaskUseCase,
  GetMyTasksUseCase,
} from "./application/use-cases/volunteer.use-cases";
import { VolunteersController } from "./interface/http/volunteers.controller";

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: "VolunteerApplication", schema: VolunteerApplicationMongoSchema },
      { name: "VolunteerTask", schema: VolunteerTaskMongoSchema },
    ]),
  ],
  controllers: [VolunteersController],
  providers: [
    {
      provide: VOLUNTEER_APPLICATION_REPOSITORY_TOKEN,
      useClass: VolunteerApplicationMongoRepository,
    },
    {
      provide: VOLUNTEER_TASK_REPOSITORY_TOKEN,
      useClass: VolunteerTaskMongoRepository,
    },
    GetOrCreateApplicationUseCase,
    UpdateApplicationMeUseCase,
    AddDocumentUseCase,
    RemoveDocumentUseCase,
    CompleteCertificationUseCase,
    ListApplicationsForAdminUseCase,
    GetApplicationByIdUseCase,
    ReviewApplicationUseCase,
    AssignTaskUseCase,
    GetMyTasksUseCase,
    // Injected collaborator functions (provided by parent module or overridden)
    {
      provide: "CLOUDINARY_UPLOAD_FN",
      useFactory: () => {
        const logger = new Logger("VolunteersModule");
        return async (buffer: Buffer, options: any) => {
          logger.warn("Cloudinary not configured — using local fallback");
          const fs = await import("fs");
          const path = await import("path");
          const dir = path.join(process.cwd(), "uploads", "volunteers");
          if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
          const name = `${Date.now()}_${options.publicId ?? "doc"}`;
          fs.writeFileSync(path.join(dir, name), buffer);
          return `/uploads/volunteers/${name}`;
        };
      },
    },
    {
      provide: "HAS_COMPLETED_QUALIFICATION_FN",
      useFactory: () => {
        return async (_userId: string) => false;
      },
    },
    {
      provide: "SEND_VOLUNTEER_EMAIL_FN",
      useFactory: () => {
        return async (
          _userId: string,
          _decision: string,
          _reason?: string,
        ) => {};
      },
    },
  ],
  exports: [
    VOLUNTEER_APPLICATION_REPOSITORY_TOKEN,
    GetOrCreateApplicationUseCase,
    CompleteCertificationUseCase,
  ],
})
export class VolunteersModule {}
