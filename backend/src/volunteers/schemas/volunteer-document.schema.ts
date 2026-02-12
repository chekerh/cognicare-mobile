import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type VolunteerDocumentDoc = VolunteerDocument & Document;

@Schema({ _id: false })
export class VolunteerDocument {
  @Prop({ required: true })
  type: 'id' | 'certificate' | 'other';

  @Prop({ required: true })
  url: string;

  @Prop()
  publicId?: string;

  @Prop()
  fileName?: string;

  @Prop()
  mimeType?: string;

  @Prop({ default: () => new Date() })
  uploadedAt: Date;
}

export const VolunteerDocumentSchema =
  SchemaFactory.createForClass(VolunteerDocument);
