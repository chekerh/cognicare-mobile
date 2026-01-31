import {
  Controller,
  Get,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
  Query,
  Request,
  Post,
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiParam,
  ApiQuery,
  ApiBody,
} from '@nestjs/swagger';
import { UsersService } from './users.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { UpdatePasswordDto, UpdateEmailDto, RequestEmailChangeDto, VerifyEmailChangeDto } from './dto/update-credentials.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/admin.guard';

@ApiTags('users')
@ApiBearerAuth('JWT-auth')
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'Get all users (Admin only)' })
  @ApiQuery({
    name: 'role',
    required: false,
    enum: ['family', 'doctor', 'volunteer', 'admin'],
    description: 'Filter users by role',
  })
  @ApiResponse({ status: 200, description: 'List of all users' })
  @ApiResponse({ status: 403, description: 'Admin access required' })
  async findAll(@Query('role') role?: 'family' | 'doctor' | 'volunteer' | 'admin') {
    if (role) {
      return this.usersService.findByRole(role);
    }
    return this.usersService.findAll();
  }

  @Get(':id')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'Get user by ID (Admin only)' })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiResponse({ status: 200, description: 'User found' })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 403, description: 'Admin access required' })
  async findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'Update user (Admin only)' })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiResponse({ status: 200, description: 'User updated successfully' })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 403, description: 'Admin access required' })
  async update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.update(id, updateUserDto);
  }

  @Delete(':id')
  @UseGuards(AdminGuard)
  @ApiOperation({ summary: 'Delete user (Admin only)' })
  @ApiParam({ name: 'id', description: 'User ID' })
  @ApiResponse({ status: 200, description: 'User deleted successfully' })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 403, description: 'Admin access required' })
  async remove(@Param('id') id: string) {
    await this.usersService.remove(id);
    return { message: 'User deleted successfully' };
  }

  @Post('update-password')
  @ApiOperation({ 
    summary: 'Update user password',
    description: 'Change the authenticated user\'s password. This will invalidate all refresh tokens and require re-login.'
  })
  @ApiBody({ type: UpdatePasswordDto })
  @ApiResponse({ 
    status: 200, 
    description: 'Password updated successfully. Refresh token invalidated.',
    schema: {
      type: 'object',
      properties: {
        message: { type: 'string', example: 'Password updated successfully. Please login again.' }
      }
    }
  })
  @ApiResponse({ status: 400, description: 'Invalid current password' })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 401, description: 'Unauthorized - Invalid or missing JWT token' })
  async updatePassword(@Request() req, @Body() updatePasswordDto: UpdatePasswordDto) {
    await this.usersService.updatePassword(
      req.user.id,
      updatePasswordDto.currentPassword,
      updatePasswordDto.newPassword,
    );
    return { message: 'Password updated successfully. Please login again.' };
  }

  @Post('update-email')
  @ApiOperation({ 
    summary: 'Request email change',
    description: 'Request to change email address. A verification code will be sent to the new email address.'
  })
  @ApiBody({ type: RequestEmailChangeDto })
  @ApiResponse({ 
    status: 200, 
    description: 'Verification code sent to new email address',
    schema: {
      type: 'object',
      properties: {
        message: { type: 'string', example: 'Verification code sent to new email address' }
      }
    }
  })
  @ApiResponse({ status: 400, description: 'Invalid password or email already in use' })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 401, description: 'Unauthorized - Invalid or missing JWT token' })
  async requestEmailChange(@Request() req, @Body() requestEmailChangeDto: RequestEmailChangeDto) {
    await this.usersService.requestEmailChange(
      req.user.id,
      requestEmailChangeDto.newEmail,
      requestEmailChangeDto.password,
    );
    return { 
      message: 'Verification code sent to new email address' 
    };
  }

  @Post('verify-email-change')
  @ApiOperation({ 
    summary: 'Verify email change with code',
    description: 'Verify the email change using the code sent to the new email address. This will update the email and invalidate all refresh tokens.'
  })
  @ApiBody({ type: VerifyEmailChangeDto })
  @ApiResponse({ 
    status: 200, 
    description: 'Email updated successfully',
    schema: {
      type: 'object',
      properties: {
        message: { type: 'string', example: 'Email updated successfully. Please login again.' },
        user: {
          type: 'object',
          properties: {
            id: { type: 'string' },
            fullName: { type: 'string' },
            email: { type: 'string' },
            phone: { type: 'string' },
            role: { type: 'string' },
          }
        }
      }
    }
  })
  @ApiResponse({ status: 400, description: 'Invalid or expired verification code' })
  @ApiResponse({ status: 404, description: 'User not found' })
  @ApiResponse({ status: 401, description: 'Unauthorized - Invalid or missing JWT token' })
  async verifyEmailChange(@Request() req, @Body() verifyEmailChangeDto: VerifyEmailChangeDto) {
    const user = await this.usersService.verifyEmailChange(
      req.user.id,
      verifyEmailChangeDto.code,
    );
    return { 
      message: 'Email updated successfully. Please login again.',
      user 
    };
  }
}
