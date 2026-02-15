import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type DonationDocument = Donation & Document;

@Schema({ timestamps: true })
export class Donation {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  donorId: Types.ObjectId;

  @Prop({ required: true })
  donorName: string;

  @Prop({ required: true })
  title: string;

  @Prop({ required: true })
  description: string;

  /** 0: Vêtements, 1: Mobilier, 2: Matériel d'éveil */
  @Prop({ required: true })
  category: number;

  /** 0: Neuf, 1: Très bon état, 2: Bon état */
  @Prop({ required: true })
  condition: number;

  @Prop({ required: true })
  location: string;

  @Prop({ type: Number })
  latitude?: number;

  @Prop({ type: Number })
  longitude?: number;

  /** Âge adapté pour les vêtements / équipements (ex: "0-2 ans", "3-5 ans") */
  @Prop({ default: '' })
  suitableAge: string;

  /** true = offre (Je donne), false = demande (Je recherche) */
  @Prop({ default: true })
  isOffer: boolean;

  /** URLs des photos (jusqu'à 5) */
  @Prop({ type: [String], default: [] })
  imageUrls: string[];

  createdAt?: Date;
  updatedAt?: Date;
}

export const DonationSchema = SchemaFactory.createForClass(Donation);
