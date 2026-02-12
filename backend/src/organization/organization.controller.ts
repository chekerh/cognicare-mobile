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
  Res,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import type { Response } from 'express';
import { OrganizationService } from './organization.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { Public } from '../auth/decorators/public.decorator';
import {
  CreateStaffDto,
  CreateFamilyDto,
  UpdateStaffDto,
  UpdateFamilyDto,
  InviteUserDto,
  ReviewOrganizationDto,
} from './dto';
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
    return await this.organizationService.getMyOrganization(
      req.user.id as string,
    );
  }

  @Get('my-organization/staff')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get all staff in my organization' })
  async getMyStaff(@Request() req: any) {
    return await this.organizationService.getMyStaff(req.user.id as string);
  }

  @Get('my-organization/families')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get all families in my organization' })
  async getMyFamilies(@Request() req: any) {
    return await this.organizationService.getMyFamilies(req.user.id as string);
  }

  @Get('my-organization/children')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get all children in my organization' })
  async getMyChildren(@Request() req: any) {
    return await this.organizationService.getMyChildren(req.user.id as string);
  }

  @Get('my-organization/stats')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get my organization statistics' })
  async getMyStats(@Request() req: any) {
    return await this.organizationService.getMyStats(req.user.id as string);
  }

  @Post('my-organization/staff/create')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Create a new staff member in my organization' })
  async createMyStaff(
    @Request() req: any,
    @Body() createStaffDto: CreateStaffDto,
  ) {
    return await this.organizationService.createMyStaffMember(
      req.user.id as string,
      createStaffDto,
    );
  }

  @Patch('my-organization/staff/:staffId')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Update a staff member in my organization' })
  async updateMyStaff(
    @Request() req: any,
    @Param('staffId') staffId: string,
    @Body() updateStaffDto: UpdateStaffDto,
  ) {
    return await this.organizationService.updateMyStaff(
      req.user.id as string,
      staffId,
      updateStaffDto,
    );
  }

  @Delete('my-organization/staff/:staffId')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Remove a staff member from my organization' })
  async removeMyStaff(@Request() req: any, @Param('staffId') staffId: string) {
    return await this.organizationService.removeMyStaff(
      req.user.id as string,
      staffId,
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
    return await this.organizationService.createMyFamilyMember(
      req.user.id as string,
      createFamilyDto,
    );
  }

  @Patch('my-organization/families/:familyId')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Update a family member in my organization' })
  async updateMyFamily(
    @Request() req: any,
    @Param('familyId') familyId: string,
    @Body() updateFamilyDto: UpdateFamilyDto,
  ) {
    return await this.organizationService.updateMyFamily(
      req.user.id as string,
      familyId,
      updateFamilyDto,
    );
  }

  @Delete('my-organization/families/:familyId')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Remove a family from my organization' })
  async removeMyFamily(
    @Request() req: any,
    @Param('familyId') familyId: string,
  ) {
    return await this.organizationService.removeMyFamily(
      req.user.id as string,
      familyId,
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
    return await this.organizationService.addChildToMyFamily(
      req.user.id as string,
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
    return await this.organizationService.updateMyChild(
      req.user.id as string,
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
    return await this.organizationService.deleteMyChild(
      req.user.id as string,
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
    return await this.organizationService.deleteChild(orgId, familyId, childId);
  }

  // Invitation endpoints
  @Post('my-organization/staff/invite')
  @Roles('organization_leader')
  @ApiOperation({
    summary: 'Invite an existing user to join as staff (pending approval)',
  })
  async inviteStaff(
    @Request() req: any,
    @Body() inviteUserDto: InviteUserDto,
  ): Promise<{ message: string }> {
    return await this.organizationService.inviteMyUser(
      req.user.id as string,
      inviteUserDto.email,
      'staff',
    );
  }

  @Post('my-organization/families/invite')
  @Roles('organization_leader')
  @ApiOperation({
    summary: 'Invite an existing user to join as family (pending approval)',
  })
  async inviteFamily(
    @Request() req: any,
    @Body() inviteUserDto: InviteUserDto,
  ): Promise<{ message: string }> {
    return await this.organizationService.inviteMyUser(
      req.user.id as string,
      inviteUserDto.email,
      'family',
    );
  }

  @Get('my-organization/invitations')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get all pending invitations for my organization' })
  async getMyInvitations(@Request() req: any) {
    return await this.organizationService.getMyPendingInvitations(
      req.user.id as string,
    );
  }

  @Get('invitations/:token/accept')
  @Public()
  @ApiOperation({ summary: 'Accept an organization invitation' })
  async acceptInvitation(@Param('token') token: string, @Res() res: Response) {
    try {
      const result = await this.organizationService.acceptInvitation(token);

      // Return HTML page with success message
      return res.send(`
        <!DOCTYPE html>
        <html>
          <head>
            <title>Invitation Accepted</title>
            <style>
              body {
                font-family: Arial, sans-serif;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                background: linear-gradient(135deg, #A4D7E1 0%, #A7E9A4 100%);
              }
              .container {
                background: white;
                padding: 40px;
                border-radius: 12px;
                box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                text-align: center;
                max-width: 500px;
              }
              h1 { color: #5A5A5A; margin-bottom: 20px; }
              p { color: #888; line-height: 1.6; }
              .success-icon { font-size: 64px; margin-bottom: 20px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="success-icon">✓</div>
              <h1>Invitation Accepted!</h1>
              <p>You have successfully joined <strong>${result.organizationName}</strong>.</p>
              <p>You can now close this window and use the CogniCare app to access your organization's resources.</p>
            </div>
          </body>
        </html>
      `);
    } catch (error) {
      return res.send(`
        <!DOCTYPE html>
        <html>
          <head>
            <title>Error</title>
            <style>
              body {
                font-family: Arial, sans-serif;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                background: linear-gradient(135deg, #FF7675 0%, #FD79A8 100%);
              }
              .container {
                background: white;
                padding: 40px;
                border-radius: 12px;
                box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                text-align: center;
                max-width: 500px;
              }
              h1 { color: #5A5A5A; margin-bottom: 20px; }
              p { color: #888; line-height: 1.6; }
              .error-icon { font-size: 64px; margin-bottom: 20px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="error-icon">✗</div>
              <h1>Error</h1>
              <p>${error instanceof Error ? error.message : 'Unable to process invitation'}</p>
              <p>Please contact the organization administrator if you believe this is an error.</p>
            </div>
          </body>
        </html>
      `);
    }
  }

  @Get('invitations/:token/reject')
  @Public()
  @ApiOperation({ summary: 'Reject an organization invitation' })
  async rejectInvitation(@Param('token') token: string, @Res() res: Response) {
    try {
      await this.organizationService.rejectInvitation(token);

      return res.send(`
        <!DOCTYPE html>
        <html>
          <head>
            <title>Invitation Declined</title>
            <style>
              body {
                font-family: Arial, sans-serif;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                background: linear-gradient(135deg, #74b9ff 0%, #a29bfe 100%);
              }
              .container {
                background: white;
                padding: 40px;
                border-radius: 12px;
                box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                text-align: center;
                max-width: 500px;
              }
              h1 { color: #5A5A5A; margin-bottom: 20px; }
              p { color: #888; line-height: 1.6; }
              .info-icon { font-size: 64px; margin-bottom: 20px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="info-icon">ℹ</div>
              <h1>Invitation Declined</h1>
              <p>You have declined the invitation.</p>
              <p>You can close this window now.</p>
            </div>
          </body>
        </html>
      `);
    } catch (error) {
      return res.send(`
        <!DOCTYPE html>
        <html>
          <head>
            <title>Error</title>
            <style>
              body {
                font-family: Arial, sans-serif;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                background: linear-gradient(135deg, #FF7675 0%, #FD79A8 100%);
              }
              .container {
                background: white;
                padding: 40px;
                border-radius: 12px;
                box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                text-align: center;
                max-width: 500px;
              }
              h1 { color: #5A5A5A; margin-bottom: 20px; }
              p { color: #888; line-height: 1.6; }
              .error-icon { font-size: 64px; margin-bottom: 20px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="error-icon">✗</div>
              <h1>Error</h1>
              <p>${error instanceof Error ? error.message : 'Unable to process invitation'}</p>
            </div>
          </body>
        </html>
      `);
    }
  }

  // Admin endpoints for pending organizations
  @Get('admin/pending-requests')
  @Roles('admin')
  @ApiOperation({
    summary: 'Get all pending organization requests (Admin only)',
  })
  async getPendingOrganizationRequests() {
    return await this.organizationService.getAllPendingOrganizations();
  }

  @Post('admin/review/:requestId')
  @Roles('admin')
  @ApiOperation({ summary: 'Review pending organization request (Admin only)' })
  async reviewOrganizationRequest(
    @Param('requestId') requestId: string,
    @Body() reviewDto: ReviewOrganizationDto,
    @Request() req: any,
  ) {
    return await this.organizationService.reviewOrganization(
      requestId,
      req.user.id as string,
      reviewDto.decision,
      reviewDto.rejectionReason,
    );
  }

  // User endpoint to check pending organization status
  @Get('my-pending-request')
  @Roles('organization_leader')
  @ApiOperation({ summary: 'Get my pending organization request status' })
  async getMyPendingRequest(@Request() req: any) {
    return await this.organizationService.getUserPendingOrganization(
      req.user.id as string,
    );
  }
}
