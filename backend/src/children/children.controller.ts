import {
  Body,
  Controller,
  Get,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { ChildrenService } from './children.service';
import { AddChildDto } from './dto/add-child.dto';
import { CreateFamilyDto } from '../organization/dto/create-family.dto';

@ApiTags('children')
@Controller('children')
export class ChildrenController {
  constructor(private readonly childrenService: ChildrenService) {}

  @Get()
  @ApiBearerAuth('JWT-auth')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary:
      'Get children for a family (GET /children?familyId=xxx or own if family)',
  })
  async getChildren(@Request() req: any, @Query('familyId') familyId?: string) {
    const userId = req.user.id as string;
    const role = (req.user.role as string)?.toLowerCase?.();
    const targetFamilyId =
      familyId?.trim() || (role === 'family' ? userId : undefined);
    if (!targetFamilyId) {
      return [];
    }
    return this.childrenService.findByFamilyId(targetFamilyId, userId);
  }

  @Post()
  @ApiBearerAuth('JWT-auth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('family')
  @ApiOperation({ summary: 'Add a child (family only)' })
  async addChild(@Request() req: any, @Body() body: AddChildDto) {
    const userId = req.user.id as string;
    return this.childrenService.createForFamily(userId, userId, body);
  }

  // ── Specialist Private Children ──

  @Get('specialist/my-children')
  @ApiBearerAuth('JWT-auth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
    'other',
  )
  @ApiOperation({ summary: 'Get private children added by this specialist' })
  async getSpecialistChildren(@Request() req: any) {
    return this.childrenService.findBySpecialistId(req.user.id as string);
  }

  @Post('specialist/add-child')
  @ApiBearerAuth('JWT-auth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
    'other',
  )
  @ApiOperation({ summary: 'Add a private child (specialist only)' })
  async addSpecialistChild(@Request() req: any, @Body() body: AddChildDto) {
    return this.childrenService.createForSpecialist(
      req.user.id as string,
      body,
    );
  }

  @Post('specialist/add-family')
  @ApiBearerAuth('JWT-auth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(
    'psychologist',
    'speech_therapist',
    'occupational_therapist',
    'doctor',
    'volunteer',
    'other',
  )
  @ApiOperation({
    summary: 'Add a private family and their children (specialist only)',
  })
  async addSpecialistFamily(
    @Request() req: any,
    @Body() body: CreateFamilyDto,
  ) {
    return this.childrenService.createPrivateFamily(
      req.user.id as string,
      body,
    );
  }
}
