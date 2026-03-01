import { Prop, Schema, SchemaFactory } from "@nestjs/mongoose";
import { Document, Types } from "mongoose";

export type CommentDocument = CommentMongoSchema & Document;

@Schema({ timestamps: true, collection: "comments" })
export class CommentMongoSchema {
  @Prop({ type: Types.ObjectId, ref: "Post", required: true })
  postId!: Types.ObjectId;

  @Prop({ type: Types.ObjectId, ref: "User", required: true })
  authorId!: Types.ObjectId;

  @Prop({ required: true })
  authorName!: string;

  @Prop({ required: true })
  text!: string;

  createdAt?: Date;
  updatedAt?: Date;
}

export const CommentSchema = SchemaFactory.createForClass(CommentMongoSchema);
CommentSchema.index({ postId: 1, createdAt: 1 });
