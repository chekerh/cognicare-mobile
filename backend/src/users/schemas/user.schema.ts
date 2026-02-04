import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

export type UserDocument = User & Document;

@Schema({ timestamps: true })
export class User {
  @Prop({ required: true })
  fullName: string;

  @Prop({ required: true, unique: true })
  email: string;

  @Prop()
  phone?: string;

  @Prop({ required: true })
  passwordHash: string;

  @Prop({ required: true, enum: ['family', 'doctor', 'volunteer', 'admin', 'organization_leader'] })
  role: 'family' | 'doctor' | 'volunteer' | 'admin' | 'organization_leader';

  @Prop({ type: 'ObjectId', ref: 'Organization' })
  organizationId?: string;

  @Prop({ type: [{ type: 'ObjectId', ref: 'User' }] })
  staffIds?: string[];

  @Prop()
  profilePic?: string;

  @Prop()
  refreshToken?: string;

  @Prop()
  passwordResetCode?: string;

  @Prop()
  passwordResetExpires?: Date;

  @Prop()
  emailChangeCode?: string;

  @Prop()
  emailChangeExpires?: Date;

  @Prop()
  pendingEmail?: string;

  createdAt?: Date;
  updatedAt?: Date;
}

export const UserSchema = SchemaFactory.createForClass(User);
