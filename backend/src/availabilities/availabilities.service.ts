import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Availability, AvailabilityDocument } from './availability.schema';

@Injectable()
export class AvailabilitiesService {
  constructor(
    @InjectModel(Availability.name)
    private readonly availabilityModel: Model<AvailabilityDocument>,
  ) {}

  async create(
    volunteerId: string,
    dto: {
      dates: string[];
      startTime?: string;
      endTime?: string;
      recurrence?: string;
      recurrenceOn?: boolean;
    },
  ) {
    const doc = await this.availabilityModel.create({
      volunteerId,
      dates: dto.dates,
      startTime: dto.startTime ?? '14:00',
      endTime: dto.endTime ?? '18:00',
      recurrence: dto.recurrence ?? 'weekly',
      recurrenceOn: dto.recurrenceOn ?? true,
    });
    return doc.toObject();
  }

  /** List availabilities for families (with volunteer info). */
  async listForFamilies(): Promise<
    {
      id: string;
      volunteerId: string;
      volunteerName: string;
      volunteerProfilePic: string;
      dates: string[];
      startTime: string;
      endTime: string;
      recurrence: string;
      recurrenceOn: boolean;
    }[]
  > {
    const docs = await this.availabilityModel
      .find()
      .populate('volunteerId', 'fullName profilePic role')
      .sort({ createdAt: -1 })
      .lean()
      .exec();

    const out: {
      id: string;
      volunteerId: string;
      volunteerName: string;
      volunteerProfilePic: string;
      dates: string[];
      startTime: string;
      endTime: string;
      recurrence: string;
      recurrenceOn: boolean;
    }[] = [];
    for (const d of docs) {
      const vol = d.volunteerId as {
        _id: { toString(): string };
        fullName?: string;
        profilePic?: string;
      } | null;
      if (!vol) continue;
      const dates = d.dates ?? [];
      if (dates.length === 0) continue;
      out.push({
        id: d._id.toString(),
        volunteerId: vol._id.toString(),
        volunteerName: vol.fullName ?? 'Bénévole',
        volunteerProfilePic: vol.profilePic ?? '',
        dates,
        startTime: d.startTime ?? '14:00',
        endTime: d.endTime ?? '18:00',
        recurrence: d.recurrence ?? 'weekly',
        recurrenceOn: d.recurrenceOn ?? true,
      });
    }
    return out;
  }
}
