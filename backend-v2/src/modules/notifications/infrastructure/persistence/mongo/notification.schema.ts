import { Schema, Types } from 'mongoose';

export const NotificationMongoSchema = new Schema(
  {
    userId: { type: Types.ObjectId, required: true, index: true },
    type: { type: String, required: true },
    title: { type: String, required: true },
    description: { type: String, default: '' },
    read: { type: Boolean, default: false },
    data: { type: Schema.Types.Mixed, default: null },
  },
  { timestamps: true },
);
NotificationMongoSchema.index({ userId: 1, createdAt: -1 });
