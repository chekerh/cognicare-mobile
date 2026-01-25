import { Schema } from 'mongoose';

export const UserSchema = new Schema({
  fullName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  phone: { type: String },
  passwordHash: { type: String, required: true },
  role: { type: String, enum: ['family', 'doctor', 'volunteer'], required: true },
  profilePic: { type: String },
  createdAt: { type: Date, default: Date.now }
});