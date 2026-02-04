import { Controller, Post, Delete, Get, Param, Body, UseGuards, Request } from '@nestjs/common';
import { OrganizationService } from './organization.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';

@Controller('organization')
@UseGuards(JwtAuthGuard, RolesGuard)
export class OrganizationController {
    constructor(private readonly organizationService: OrganizationService) { }

    @Post(':orgId/staff')
    @Roles('organization_leader')
    async addStaff(@Param('orgId') orgId: string, @Body('email') email: string) {
        return this.organizationService.addStaff(orgId, email);
    }

    @Delete(':orgId/staff/:staffId')
    @Roles('organization_leader')
    async removeStaff(@Param('orgId') orgId: string, @Param('staffId') staffId: string) {
        return this.organizationService.removeStaff(orgId, staffId);
    }

    @Get(':orgId/staff')
    @Roles('organization_leader')
    async getStaff(@Param('orgId') orgId: string) {
        return this.organizationService.getStaff(orgId);
    }
}
