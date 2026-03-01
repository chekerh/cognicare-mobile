import { PartialType } from '@nestjs/mapped-types';
import { CreateTrainingCourseDto } from './create-training-course.dto';

export class UpdateTrainingCourseDto extends PartialType(CreateTrainingCourseDto) {}
