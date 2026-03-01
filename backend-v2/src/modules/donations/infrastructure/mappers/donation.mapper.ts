import { Types } from 'mongoose';
import { DonationEntity } from '../../domain/entities/donation.entity';

export class DonationMapper {
  static toDomain(raw: Record<string, any>): DonationEntity {
    return DonationEntity.reconstitute(raw._id.toString(), {
      donorId: raw.donorId?.toString() ?? '',
      donorName: raw.donorName ?? '',
      title: raw.title ?? '',
      description: raw.description ?? '',
      category: raw.category ?? 0,
      condition: raw.condition ?? 0,
      location: raw.location ?? '',
      latitude: raw.latitude,
      longitude: raw.longitude,
      suitableAge: raw.suitableAge ?? '',
      isOffer: raw.isOffer ?? true,
      imageUrls: raw.imageUrls ?? [],
      createdAt: raw.createdAt,
      updatedAt: raw.updatedAt,
    });
  }

  static toPersistence(entity: DonationEntity): Record<string, any> {
    return {
      _id: new Types.ObjectId(entity.id),
      donorId: new Types.ObjectId(entity.donorId),
      donorName: entity.donorName,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      condition: entity.condition,
      location: entity.location,
      latitude: entity.latitude,
      longitude: entity.longitude,
      suitableAge: entity.suitableAge,
      isOffer: entity.isOffer,
      imageUrls: entity.imageUrls,
    };
  }
}
