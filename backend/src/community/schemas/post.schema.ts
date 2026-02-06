import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

export type PostDocument = Post & Document;

@Schema({ timestamps: true })
export class Post {
  @Prop({ type: Types.ObjectId, ref: 'User', required: true })
  authorId: Types.ObjectId;

  @Prop({ required: true })
  authorName: string;

  @Prop({ required: true })
  text: string;

  @Prop({ default: null })
  imageUrl?: string;

  @Prop({ type: [String], default: [] })
  tags: string[];

  @Prop({ type: [{ type: Types.ObjectId, ref: 'User' }], default: [] })
  likedBy: Types.ObjectId[];

  createdAt?: Date;
  updatedAt?: Date;
}

export const PostSchema = SchemaFactory.createForClass(Post);
