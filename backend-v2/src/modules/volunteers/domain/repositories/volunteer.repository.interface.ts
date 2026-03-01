import {
  VolunteerApplicationEntity,
  VolunteerTaskEntity,
} from "../entities/volunteer.entity";

export interface IVolunteerApplicationRepository {
  findByUserId(userId: string): Promise<VolunteerApplicationEntity | null>;
  findById(id: string): Promise<VolunteerApplicationEntity | null>;
  findAll(filters?: { status?: string }): Promise<VolunteerApplicationEntity[]>;
  save(entity: VolunteerApplicationEntity): Promise<VolunteerApplicationEntity>;
  update(
    entity: VolunteerApplicationEntity,
  ): Promise<VolunteerApplicationEntity>;
}

export interface IVolunteerTaskRepository {
  findByVolunteerId(volunteerId: string): Promise<VolunteerTaskEntity[]>;
  save(entity: VolunteerTaskEntity): Promise<VolunteerTaskEntity>;
}
