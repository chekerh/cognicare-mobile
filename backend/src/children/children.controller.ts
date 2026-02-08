import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Request,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ChildrenService } from './children.service';
import { CreateChildDto } from './dto/create-child.dto';
import { UpdateChildDto } from './dto/update-child.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@ApiTags('children')
@ApiBearerAuth()
@Controller('children')
@UseGuards(JwtAuthGuard)
export class ChildrenController {
  constructor(private readonly childrenService: ChildrenService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new child record (family only)' })
  create(@Request() req, @Body() createChildDto: CreateChildDto) {
    return this.childrenService.create(req.user.userId, createChildDto);
  }

  @Get('my-children')
  @ApiOperation({ summary: 'Get all children for the authenticated parent' })
  findMyChildren(@Request() req) {
    return this.childrenService.findByParent(req.user.userId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a specific child by ID' })
  findOne(@Request() req, @Param('id') id: string) {
    return this.childrenService.findOne(id, req.user.userId, req.user.role);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update child information (parent only)' })
  update(
    @Request() req,
    @Param('id') id: string,
    @Body() updateChildDto: UpdateChildDto,
  ) {
    return this.childrenService.update(id, req.user.userId, updateChildDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a child record (parent only)' })
  remove(@Request() req, @Param('id') id: string) {
    return this.childrenService.remove(id, req.user.userId);
  }
}
