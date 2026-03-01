/**
 * Children Controller - Interface Layer
 * 
 * HTTP interface for children operations.
 * Controllers are thin - they only handle HTTP concerns and delegate to use cases.
 */
import {
  Body,
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Query,
  Request,
  UseGuards,
  HttpCode,
  HttpStatus,
  BadRequestException,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags, ApiQuery, ApiResponse } from '@nestjs/swagger';
import { JwtAuthGuard } from '@/shared/guards/jwt-auth.guard';
import { RolesGuard } from '@/shared/guards/roles.guard';
import { Roles } from '@/shared/decorators/roles.decorator';
import { 
  EntityNotFoundException, 
  ForbiddenAccessException,
  BusinessRuleViolationException,
  DomainException
} from '@/core/domain';
import { AddChildInputDto, ChildOutputDto } from '../../application/dto/child.dto';
import { UpdateChildInputDto } from '../../application/dto/update-child.dto';
import { CreateChildForFamilyUseCase } from '../../application/use-cases/create-child-for-family.use-case';
import { CreateChildForSpecialistUseCase } from '../../application/use-cases/create-child-for-specialist.use-case';
import { GetChildrenByFamilyUseCase } from '../../application/use-cases/get-children-by-family.use-case';
import { GetChildrenBySpecialistUseCase } from '../../application/use-cases/get-children-by-specialist.use-case';
import { UpdateChildUseCase } from '../../application/use-cases/update-child.use-case';

interface AuthenticatedRequest {
  user: {
    id: string;
    role: string;
    email: string;
  };
}

@ApiTags('children')
@Controller('children')
export class ChildrenController {
  constructor(
    private readonly createChildForFamilyUseCase: CreateChildForFamilyUseCase,
    private readonly createChildForSpecialistUseCase: CreateChildForSpecialistUseCase,
    private readonly getChildrenByFamilyUseCase: GetChildrenByFamilyUseCase,
    private readonly getChildrenBySpecialistUseCase: GetChildrenBySpecialistUseCase,
    private readonly updateChildUseCase: UpdateChildUseCase,
  ) {}

  /**
   * Convert domain exceptions to HTTP exceptions.
   */
  private handleError(error: Error): never {
    if (error instanceof EntityNotFoundException) {
      throw new NotFoundException(error.message);
    }
    if (error instanceof ForbiddenAccessException) {
      throw new ForbiddenException(error.message);
    }
    if (error instanceof BusinessRuleViolationException) {
      throw new BadRequestException(error.message);
    }
    if (error instanceof DomainException) {
      throw new BadRequestException(error.message);
    }
    throw error;
  }

  @Get()
  @ApiBearerAuth('JWT-auth')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: 'Get children for a family',
    description: 'Get children. If familyId is provided, returns that family\'s children (if authorized). Otherwise returns own children if requester is a family.',
  })
  @ApiQuery({ name: 'familyId', required: false, description: 'Family user ID to get children for' })
  @ApiResponse({ status: 200, description: 'List of children', type: [ChildOutputDto] })
  async getChildren(
    @Request() req: AuthenticatedRequest,
    @Query('familyId') familyId?: string,
  ): Promise<ChildOutputDto[]> {
    const userId = req.user.id;
    const role = req.user.role?.toLowerCase();
    const targetFamilyId = familyId?.trim() || (role === 'family' ? userId : undefined);

    if (!targetFamilyId) {
      return [];
    }

    const result = await this.getChildrenByFamilyUseCase.execute({
      familyId: targetFamilyId,
      requesterId: userId,
    });

    if (result.isFailure) {
      this.handleError(result.error);
    }

    return result.value;
  }

  @Post()
  @ApiBearerAuth('JWT-auth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('family')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Add a child (family only)' })
  @ApiResponse({ status: 201, description: 'Child created', type: ChildOutputDto })
  async addChild(
    @Request() req: AuthenticatedRequest,
    @Body() body: AddChildInputDto,
  ): Promise<ChildOutputDto> {
    const result = await this.createChildForFamilyUseCase.execute({
      familyId: req.user.id,
      requesterId: req.user.id,
      childData: body,
    });

    if (result.isFailure) {
      this.handleError(result.error);
    }

    return result.value;
  }

  @Patch(':id')
  @ApiBearerAuth('JWT-auth')
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Update a child' })
  @ApiResponse({ status: 200, description: 'Child updated', type: ChildOutputDto })
  async updateChild(
    @Request() req: AuthenticatedRequest,
    @Param('id') childId: string,
    @Body() body: UpdateChildInputDto,
  ): Promise<ChildOutputDto> {
    const result = await this.updateChildUseCase.execute({
      childId,
      requesterId: req.user.id,
      requesterRole: req.user.role,
      updateData: body,
    });

    if (result.isFailure) {
      this.handleError(result.error);
    }

    return result.value;
  }

  // ── Specialist Private Children ──

  @Get('specialist/my-children')
  @ApiBearerAuth('JWT-auth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('psychologist', 'speech_therapist', 'occupational_therapist', 'doctor', 'volunteer', 'other')
  @ApiOperation({ summary: 'Get private children added by this specialist' })
  @ApiResponse({ status: 200, description: 'List of children', type: [ChildOutputDto] })
  async getSpecialistChildren(
    @Request() req: AuthenticatedRequest,
  ): Promise<ChildOutputDto[]> {
    const result = await this.getChildrenBySpecialistUseCase.execute({
      specialistId: req.user.id,
    });

    if (result.isFailure) {
      this.handleError(result.error);
    }

    return result.value;
  }

  @Post('specialist/add-child')
  @ApiBearerAuth('JWT-auth')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('psychologist', 'speech_therapist', 'occupational_therapist', 'doctor', 'volunteer', 'other')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Add a private child (specialist only)' })
  @ApiResponse({ status: 201, description: 'Child created', type: ChildOutputDto })
  async addSpecialistChild(
    @Request() req: AuthenticatedRequest,
    @Body() body: AddChildInputDto,
  ): Promise<ChildOutputDto> {
    const result = await this.createChildForSpecialistUseCase.execute({
      specialistId: req.user.id,
      childData: body,
    });

    if (result.isFailure) {
      this.handleError(result.error);
    }

    return result.value;
  }
}
