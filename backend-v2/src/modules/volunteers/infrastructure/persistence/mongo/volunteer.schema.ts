import { Schema, Types } from "mongoose";

const VolunteerDocumentSubSchema = new Schema(
  {
    type: {
      type: String,
      required: true,
      enum: ["id", "certificate", "other"],
    },
    url: { type: String, required: true },
    publicId: String,
    fileName: String,
    mimeType: String,
    uploadedAt: { type: Date, default: Date.now },
  },
  { _id: false },
);

export const VolunteerApplicationMongoSchema = new Schema(
  {
    userId: { type: Types.ObjectId, ref: "User", required: true, unique: true },
    status: {
      type: String,
      default: "pending",
      enum: ["pending", "approved", "denied"],
      required: true,
    },
    careProviderType: {
      type: String,
      enum: [
        "speech_therapist",
        "occupational_therapist",
        "psychologist",
        "doctor",
        "ergotherapist",
        "caregiver",
        "organization_leader",
        "other",
      ],
    },
    specialty: String,
    organizationName: String,
    organizationRole: String,
    documents: { type: [VolunteerDocumentSubSchema], default: [] },
    deniedReason: String,
    reviewedBy: { type: Types.ObjectId, ref: "User" },
    reviewedAt: Date,
    denialNotificationSent: { type: Boolean, default: false },
    trainingCertified: { type: Boolean, default: false },
    trainingCertifiedAt: Date,
  },
  { timestamps: true },
);
VolunteerApplicationMongoSchema.index({ userId: 1 });
VolunteerApplicationMongoSchema.index({ status: 1 });

export const VolunteerTaskMongoSchema = new Schema(
  {
    assignedBy: { type: Types.ObjectId, ref: "User", required: true },
    volunteerId: { type: Types.ObjectId, ref: "User", required: true },
    title: { type: String, required: true },
    description: { type: String, default: "" },
    status: {
      type: String,
      default: "pending",
      enum: ["pending", "accepted", "completed", "cancelled"],
    },
    dueDate: Date,
    completedAt: Date,
  },
  { timestamps: true, collection: "volunteertasks" },
);
VolunteerTaskMongoSchema.index({ volunteerId: 1, createdAt: -1 });
