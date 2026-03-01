import { Schema, Types } from "mongoose";

export const DonationMongoSchema = new Schema(
  {
    donorId: { type: Types.ObjectId, ref: "User", required: true },
    donorName: { type: String, required: true },
    title: { type: String, required: true },
    description: { type: String, required: true },
    category: { type: Number, required: true },
    condition: { type: Number, required: true },
    location: { type: String, required: true },
    latitude: { type: Number },
    longitude: { type: Number },
    suitableAge: { type: String, default: "" },
    isOffer: { type: Boolean, default: true },
    imageUrls: { type: [String], default: [] },
  },
  { timestamps: true },
);
