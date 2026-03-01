import { Entity } from '../../../../core/entity.base';

export interface DonationProps {
  donorId: string;
  donorName: string;
  title: string;
  description: string;
  category: number;
  condition: number;
  location: string;
  latitude?: number;
  longitude?: number;
  suitableAge: string;
  isOffer: boolean;
  imageUrls: string[];
  createdAt?: Date;
  updatedAt?: Date;
}

export class DonationEntity extends Entity<DonationProps> {
  static create(props: Omit<DonationProps, 'createdAt' | 'updatedAt'>): DonationEntity {
    return new DonationEntity(props, Entity.generateId());
  }
  static reconstitute(id: string, props: DonationProps): DonationEntity {
    return new DonationEntity(props, id);
  }

  get donorId() { return this.props.donorId; }
  get donorName() { return this.props.donorName; }
  get title() { return this.props.title; }
  get description() { return this.props.description; }
  get category() { return this.props.category; }
  get condition() { return this.props.condition; }
  get location() { return this.props.location; }
  get latitude() { return this.props.latitude; }
  get longitude() { return this.props.longitude; }
  get suitableAge() { return this.props.suitableAge; }
  get isOffer() { return this.props.isOffer; }
  get imageUrls() { return this.props.imageUrls; }
  get createdAt() { return this.props.createdAt; }
}
