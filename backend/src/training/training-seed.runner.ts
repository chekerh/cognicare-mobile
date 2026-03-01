import { Injectable, OnModuleInit } from '@nestjs/common';
import { TrainingService } from './training.service';

@Injectable()
export class TrainingSeedRunner implements OnModuleInit {
  constructor(private readonly trainingService: TrainingService) {}

  async onModuleInit(): Promise<void> {
    await this.trainingService.seedCoursesIfEmpty();
  }
}
