import { VolunteerApplicationEntity, VolunteerDocProps, VolunteerTaskEntity } from '../../domain';

export class VolunteerApplicationMapper {
  static toDomain(raw: any): VolunteerApplicationEntity {
    const docs: VolunteerDocProps[] = (raw.documents ?? []).map((d: any) => ({
      type: d.type,
      url: d.url,
      publicId: d.publicId,
      fileName: d.fileName,
      mimeType: d.mimeType,
      uploadedAt: d.uploadedAt ? new Date(d.uploadedAt) : new Date(),
    }));

    const id = raw._id?.toString() ?? raw.id;
    return VolunteerApplicationEntity.reconstitute(id, {
      userId: raw.userId?.toString(),
      status: raw.status ?? 'pending',
      careProviderType: raw.careProviderType,
      specialty: raw.specialty,
      organizationName: raw.organizationName,
      organizationRole: raw.organizationRole,
      documents: docs,
      deniedReason: raw.deniedReason,
      reviewedBy: raw.reviewedBy?.toString(),
      reviewedAt: raw.reviewedAt ? new Date(raw.reviewedAt) : undefined,
      denialNotificationSent: raw.denialNotificationSent ?? false,
      trainingCertified: raw.trainingCertified ?? false,
      trainingCertifiedAt: raw.trainingCertifiedAt ? new Date(raw.trainingCertifiedAt) : undefined,
      createdAt: raw.createdAt ? new Date(raw.createdAt) : new Date(),
      updatedAt: raw.updatedAt ? new Date(raw.updatedAt) : new Date(),
    });
  }

  static toPersistence(entity: VolunteerApplicationEntity): Record<string, any> {
    return {
      userId: entity.userId,
      status: entity.status,
      careProviderType: entity.careProviderType,
      specialty: entity.specialty,
      organizationName: entity.organizationName,
      organizationRole: entity.organizationRole,
      documents: entity.documents.map((d) => ({
        type: d.type,
        url: d.url,
        publicId: d.publicId,
        fileName: d.fileName,
        mimeType: d.mimeType,
        uploadedAt: d.uploadedAt,
      })),
      deniedReason: entity.deniedReason,
      reviewedBy: entity.reviewedBy,
      reviewedAt: entity.reviewedAt,
      denialNotificationSent: entity.denialNotificationSent,
      trainingCertified: entity.trainingCertified,
      trainingCertifiedAt: entity.trainingCertifiedAt,
    };
  }
}

export class VolunteerTaskMapper {
  static toDomain(raw: any): VolunteerTaskEntity {
    const id = raw._id?.toString() ?? raw.id;
    return VolunteerTaskEntity.reconstitute(id, {
      assignedBy: raw.assignedBy?.toString(),
      volunteerId: raw.volunteerId?.toString(),
      title: raw.title,
      description: raw.description ?? '',
      status: raw.status ?? 'pending',
      dueDate: raw.dueDate ? new Date(raw.dueDate) : undefined,
      completedAt: raw.completedAt ? new Date(raw.completedAt) : undefined,
      createdAt: raw.createdAt ? new Date(raw.createdAt) : new Date(),
    });
  }

  static toPersistence(entity: VolunteerTaskEntity): Record<string, any> {
    return {
      assignedBy: entity.assignedBy,
      volunteerId: entity.volunteerId,
      title: entity.title,
      description: entity.description,
      status: entity.status,
      dueDate: entity.dueDate,
      completedAt: entity.completedAt,
    };
  }
}
