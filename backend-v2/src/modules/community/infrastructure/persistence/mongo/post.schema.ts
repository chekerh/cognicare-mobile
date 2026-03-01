import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type PostDocument = PostMongoSchema & Document;

@Schema({ timestamps: true, collection: "posts" })
export class PostMongoSchema {
  @Prop({ type: Types.ObjectId, ref: "User", required: true })
  authorId!: Types.ObjectId;

  @Prop({ required: true })
  authorName!: string;

  @Prop({ required: true })
  text!: string;

  @Prop({ default: null })
  imageUrl?: string;

  @Prop({ type: [String], default: [] })
  tags!: string[];

  @Prop({ type: [{ type: Types.ObjectId, ref: "User" }], default: [] })
  likedBy!: Types.ObjectId[];

  createdAt?: Date;
  updatedAt?: Date;
}

export const PostSchema = SchemaFactory.createForClass(PostMongoSchema);
PostSchema.index({ authorId: 1 });
PostSchema.index({ createdAt: -1 });
