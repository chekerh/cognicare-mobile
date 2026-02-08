import {
  Controller,
  Post,
  Delete,
  Get,
  Patch,
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
import { CreateStaffDto, CreateFamilyDto } from './dto';
import { AddChildDto } from '../children/dto/add-child.dto';
import { UpdateChildDto } from '../children/dto/update-child.dto';

@ApiTags('organization')
@ApiBearerAuth()
@Controller('organization')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OrganizationController {
  constructor(private readonly organizationService: OrganizationService) {}

  // My Organization endpoints (uses logged-in user)
  @Get('my-organization')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get my organization details' })
  async getMyOrganization(@Request() req: any) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
    return await this.organizationService.getMyOrganization(req.user.id);
  }

  @Get('my-organization/staff')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get all staff in my organization' })
  async getMyStaff(@Request() req: any) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
    return await this.organizationService.getMyStaff(req.user.id);
  }

  @Get('my-organization/families')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get all families in my organization' })
  async getMyFamilies(@Request() req: any) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
    return await this.organizationService.getMyFamilies(req.user.id);
  }

  @Get('my-organization/children')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get all children in my organization' })
  async getMyChildren(@Request() req: any) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
    return await this.organizationService.getMyChildren(req.user.id);
  }

  @Get('my-organization/stats')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get my organization statistics' })
  async getMyStats(@Request() req: any) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
    return await this.organizationService.getMyStats(req.user.id);
  }

  @Post('my-organization/staff/create')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Create a new staff member in my organization' })
  async createMyStaff(
    @Request() req: any,
    @Body() createStaffDto: CreateStaffDto,
  ) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
    return await this.organizationService.createMyStaffMember(
      req.user.id,
      createStaffDto,
    );
  }

  @Post('my-organization/families/create')
  @Roles('organization_leader')
  @ApiOperation({
    summary:
      'Create a new family account in my organization with optional children',
  })
  async createMyFamily(
    @Request() req: any,
    @Body() createFamilyDto: CreateFamilyDto,
  ) {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
    return await this.organizationService.createMyFamilyMember(
      req.user.id,
      createFamilyDto,
    );
  }

  @Post('my-organization/families/:familyId/children')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Add a new child to a family in my organization' })
  async addChildToMyFamily(
    @Request() req: any,
    @Param('familyId') familyId: string,
    @Body() addChildDto: AddChildDto,
  ): Promise<{ fullName: string; dateOfBirth: Date; gender: string }> {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
    return await this.organizationService.addChildToMyFamily(
      req.user.id,
      familyId,
      addChildDto,
    );
  }

  @Patch('my-organization/families/:familyId/children/:childId')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Update child information in my organization' })
  async updateMyChild(
    @Request() req: any,
    @Param('familyId') familyId: string,
    @Param('childId') childId: string,
    @Body() updateChildDto: UpdateChildDto,
  ): Promise<{ fullName: string; dateOfBirth: Date; gender: string }> {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
    return await this.organizationService.updateMyChild(
      req.user.id,
      familyId,
      childId,
      updateChildDto,
    );
  }

  @Delete('my-organization/families/:familyId/children/:childId')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Delete a child from a family in my organization' })
  async deleteMyChild(
    @Request() req: any,
    @Param('familyId') familyId: string,
    @Param('childId') childId: string,
  ): Promise<{ message: string }> {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
    return await this.organizationService.deleteMyChild(
      req.user.id,
      familyId,
      childId,
    );
  }

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
    return await this.organizationService.createStaffMember(
      orgId,
      createStaffDto,
    );
  }

  // Create new family member
  @Post(':orgId/families/create')
  @Roles('organization_leader')
  @ApiOperation({
    summary: 'Create a new family account with optional children',
  })
  async createFamily(
    @Param('orgId') orgId: string,
    @Body() createFamilyDto: CreateFamilyDto,
  ) {
    return await this.organizationService.createFamilyMember(
      orgId,
      createFamilyDto,
    );
  }

  // Child management endpoints
  @Post(':orgId/families/:familyId/children')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Add a new child to a family' })
  async addChildToFamily(
    @Param('orgId') orgId: string,
    @Param('familyId') familyId: string,
    @Body() addChildDto: AddChildDto,
  ): Promise<{ fullName: string; dateOfBirth: Date; gender: string }> {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
    return await this.organizationService.addChildToFamily(
      orgId,
      familyId,
      addChildDto,
    );
  }

  @Patch(':orgId/families/:familyId/children/:childId')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Update child information' })
  async updateChild(
    @Param('orgId') orgId: string,
    @Param('familyId') familyId: string,
    @Param('childId') childId: string,
    @Body() updateChildDto: UpdateChildDto,
  ): Promise<{ fullName: string; dateOfBirth: Date; gender: string }> {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
    return await this.organizationService.updateChild(
      orgId,
      familyId,
      childId,
      updateChildDto,
    );
  }

  @Delete(':orgId/families/:familyId/children/:childId')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Delete a child from a family' })
  async deleteChild(
    @Param('orgId') orgId: string,
    @Param('familyId') familyId: string,
    @Param('childId') childId: string,
  ): Promise<{ message: string }> {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-call
    return await this.organizationService.deleteChild(orgId, familyId, childId);
  }
}
