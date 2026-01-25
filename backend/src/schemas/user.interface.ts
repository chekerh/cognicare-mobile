import { Document } from 'mongoose';

export interface User extends Document {
  fullName: string;
  email: string;
  phone?: string;
  passwordHash: string;
  role: 'family' | 'doctor' | 'volunteer';
  profilePic?: string;
  createdAt: Date;
}