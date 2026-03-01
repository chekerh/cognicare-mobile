/**
 * Organization Mapper - Infrastructure Layer
 */
import { Types } from 'mongoose';
import { OrganizationEntity } from '../../domain/entities/organization.entity';
import { OrganizationDocument } from '../persistence/mongo/organization.schema';

export class OrganizationMapper {
  static toDomain(doc: OrganizationDocument): OrganizationEntity {
    return OrganizationEntity.reconstitute(doc._id.toString(), {
      name: doc.name,
      leaderId: doc.leaderId.toString(),
      staffIds: doc.staffIds?.map(id => id.toString()) || [],
      childIds: doc.childIds?.map(id => id.toString()) || [],
      certificateUrl: doc.certificateUrl,
      description: doc.description,
      address: doc.address,
      phone: doc.phone,
      email: doc.email,
      website: doc.website,
      isApproved: doc.isApproved,
      approvedAt: doc.approvedAt,
      rejectedAt: doc.rejectedAt,
      rejectionReason: doc.rejectionReason,
      deletedAt: doc.deletedAt,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    });
  }

  static toPersistence(entity: OrganizationEntity): Record<string, unknown> {
    return {
      name: entity.name,
      leaderId: new Types.ObjectId(entity.leaderId),
      staffIds: entity.staffIds.map(id => new Types.ObjectId(id)),
      childIds: entity.childIds.map(id => new Types.ObjectId(id)),
      certificateUrl: entity.certificateUrl,
      description: entity.description,
      address: entity.address,
      phone: entity.phone,
      email: entity.email,
      website: entity.website,
      isApproved: entity.isApproved,
      approvedAt: entity.approvedAt,
      rejectedAt: entity.rejectedAt,
      rejectionReason: entity.rejectionReason,
      deletedAt: entity.deletedAt,
    };
  }
}
