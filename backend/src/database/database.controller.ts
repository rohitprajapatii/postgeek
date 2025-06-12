import { Controller, Post, Body, Get, Delete, HttpException, HttpStatus } from '@nestjs/common';
import { DatabaseService } from './database.service';
import { ConnectionDto } from './dto/connection.dto';

@Controller('database')
export class DatabaseController {
  constructor(private readonly databaseService: DatabaseService) {}

  @Post('connect')
  async connect(@Body() connectionDto: ConnectionDto) {
    let connectionString;
    
    // Build connection string from parts if not provided directly
    if (connectionDto.connectionString) {
      connectionString = connectionDto.connectionString;
    } else {
      // Validate required fields
      if (!connectionDto.host || !connectionDto.database || !connectionDto.username) {
        throw new HttpException(
          'Host, database and username are required', 
          HttpStatus.BAD_REQUEST
        );
      }
      
      // Construct connection string
      connectionString = `postgresql://${connectionDto.username}:${connectionDto.password}@${connectionDto.host}:${connectionDto.port || 5432}/${connectionDto.database}`;
    }
    
    const connected = await this.databaseService.connect(connectionString);
    
    if (!connected) {
      throw new HttpException(
        'Failed to connect to database', 
        HttpStatus.BAD_REQUEST
      );
    }
    
    return { success: true, message: 'Successfully connected to database' };
  }

  @Delete('disconnect')
  async disconnect() {
    await this.databaseService.disconnect();
    return { success: true, message: 'Disconnected from database' };
  }

  @Get('status')
  getStatus() {
    return this.databaseService.getConnectionStatus();
  }
}