/**
 * Child Mapper - Infrastructure Layer
 * 
 * Converts between domain entities and persistence models.
 * This ensures the domain layer stays pure and independent of the database.
 */
import { Types } from 'mongoose';
import { ChildEntity, Gender } from '../../domain/entities/child.entity';
import { ChildDocument } from '../persistence/mongo/child.schema';
import { ChildOutputDto } from '../../application/dto/child.dto';

export class ChildMapper {
  /**
   * Convert Mongoose document to domain entity.
   */
  static toDomain(doc: ChildDocument): ChildEntity {
    return ChildEntity.reconstitute(doc._id.toString(), {
      fullName: doc.fullName,
      dateOfBirth: doc.dateOfBirth,
      gender: doc.gender as Gender,
      diagnosis: doc.diagnosis,
      medicalHistory: doc.medicalHistory,
      allergies: doc.allergies,
      medications: doc.medications,
      notes: doc.notes,
      parentId: doc.parentId?.toString(),
      organizationId: doc.organizationId?.toString(),
      specialistId: doc.specialistId?.toString(),
      addedByOrganizationId: doc.addedByOrganizationId?.toString(),
      addedBySpecialistId: doc.addedBySpecialistId?.toString(),
      lastModifiedBy: doc.lastModifiedBy?.toString(),
      deletedAt: doc.deletedAt,
      createdAt: doc.createdAt,
      updatedAt: doc.updatedAt,
    });
  }

  /**
   * Convert domain entity to persistence data (for save operations).
   */
  static toPersistence(entity: ChildEntity): Record<string, unknown> {
    return {
      fullName: entity.fullName,
      dateOfBirth: entity.dateOfBirth,
      gender: entity.gender,
      diagnosis: entity.diagnosis,
      medicalHistory: entity.medicalHistory,
      allergies: entity.allergies,
      medications: entity.medications,
      notes: entity.notes,
      parentId: entity.parentId ? new Types.ObjectId(entity.parentId) : undefined,
      organizationId: entity.organizationId ? new Types.ObjectId(entity.organizationId) : undefined,
      specialistId: entity.specialistId ? new Types.ObjectId(entity.specialistId) : undefined,
      addedByOrganizationId: entity.addedByOrganizationId 
        ? new Types.ObjectId(entity.addedByOrganizationId) 
        : undefined,
      addedBySpecialistId: entity.addedBySpecialistId 
        ? new Types.ObjectId(entity.addedBySpecialistId) 
        : undefined,
      lastModifiedBy: entity.lastModifiedBy 
        ? new Types.ObjectId(entity.lastModifiedBy) 
        : undefined,
      deletedAt: entity.deletedAt,
    };
  }

  /**
   * Convert domain entity to output DTO.
   */
  static toOutputDto(entity: ChildEntity): ChildOutputDto {
    return {
      id: entity.id,
      fullName: entity.fullName,
      dateOfBirth: entity.dateOfBirth.toISOString().slice(0, 10),
      gender: entity.gender,
      diagnosis: entity.diagnosis,
      medicalHistory: entity.medicalHistory,
      allergies: entity.allergies,
      medications: entity.medications,
      notes: entity.notes,
      parentId: entity.parentId,
      organizationId: entity.organizationId,
      specialistId: entity.specialistId,
      createdAt: entity.createdAt?.toISOString(),
      updatedAt: entity.updatedAt?.toISOString(),
    };
  }
}
