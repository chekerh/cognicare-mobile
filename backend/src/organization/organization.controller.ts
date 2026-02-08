import {
  Controller,
  Post,
  Delete,
  Get,
  Param,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { OrganizationService } from './organization.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CreateStaffDto } from './dto/create-staff.dto';
import { CreateFamilyDto } from './dto/create-family.dto';

@ApiTags('organization')
@ApiBearerAuth()
@Controller('organization')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OrganizationController {
  constructor(private readonly organizationService: OrganizationService) {}

  // Staff management endpoints
  @Post(':orgId/staff')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Add staff member to organization' })
  async addStaff(@Param('orgId') orgId: string, @Body('email') email: string) {
    return this.organizationService.addStaff(orgId, email);
  }

  @Delete(':orgId/staff/:staffId')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Remove staff member from organization' })
  async removeStaff(
    @Param('orgId') orgId: string,
    @Param('staffId') staffId: string,
  ) {
    return this.organizationService.removeStaff(orgId, staffId);
  }

  @Get(':orgId/staff')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get all staff members in organization' })
  async getStaff(@Param('orgId') orgId: string) {
    return this.organizationService.getStaff(orgId);
  }

  // Family management endpoints
  @Post(':orgId/families')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Add family to organization' })
  async addFamily(@Param('orgId') orgId: string, @Body('email') email: string) {
    return await this.organizationService.addFamily(orgId, email);
  }

  @Delete(':orgId/families/:familyId')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Remove family from organization' })
  async removeFamily(
    @Param('orgId') orgId: string,
    @Param('familyId') familyId: string,
  ) {
    return await this.organizationService.removeFamily(orgId, familyId);
  }

  @Get(':orgId/families')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get all families in organization' })
  async getFamilies(@Param('orgId') orgId: string) {
    return await this.organizationService.getFamilies(orgId);
  }

  // Children management endpoints
  @Get(':orgId/children')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get all children in organization' })
  async getAllChildren(@Param('orgId') orgId: string) {
    return await this.organizationService.getAllChildren(orgId);
  }

  // Statistics endpoint
  @Get(':orgId/stats')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get organization statistics' })
  async getStats(@Param('orgId') orgId: string) {
    return await this.organizationService.getOrganizationStats(orgId);
  }

  // Create new staff member
  @Post(':orgId/staff/create')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Create a new staff member account' })
  async createStaff(
    @Param('orgId') orgId: string,
    @Body() createStaffDto: CreateStaffDto,
  ) {
    return await this.organizationService.createStaffMember(orgId, createStaffDto);
  }

  // Create new family member
  @Post(':orgId/families/create')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Create a new family account with optional children' })
  async createFamily(
    @Param('orgId') orgId: string,
    @Body() createFamilyDto: CreateFamilyDto,
  ) {
    return await this.organizationService.createFamilyMember(orgId, createFamilyDto);
  }
}
