import { IsNotEmpty, IsString, IsEnum } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class CreatePlanDto {
  @ApiProperty({ example: "507f1f77bcf86cd799439011" })
  @IsNotEmpty()
  @IsString()
  childId!: string;

  @ApiProperty({ enum: ["PECS", "TEACCH", "SkillTracker", "Activity"] })
  @IsNotEmpty()
  @IsEnum(["PECS", "TEACCH", "SkillTracker", "Activity"])
  type!: "PECS" | "TEACCH" | "SkillTracker" | "Activity";

  @ApiProperty({ example: "Daily Communication Cards" })
  @IsNotEmpty()
  @IsString()
  title!: string;

  @ApiProperty({ example: { cards: [], activities: [] } })
  @IsNotEmpty()
  content!: any;
}
