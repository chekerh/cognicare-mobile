import { DonationEntity } from "../entities/donation.entity";

export interface IDonationRepository {
  findAll(filters?: {
    isOffer?: boolean;
    category?: number;
    search?: string;
  }): Promise<DonationEntity[]>;
  findById(id: string): Promise<DonationEntity | null>;
  save(entity: DonationEntity): Promise<DonationEntity>;
}
