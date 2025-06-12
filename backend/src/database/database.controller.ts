import {
  Controller,
  Post,
  Body,
  Get,
  Delete,
  HttpException,
  HttpStatus,
} from "@nestjs/common";
import { DatabaseService } from "./database.service";
import { ConnectionDto } from "./dto/connection.dto";

@Controller("database")
export class DatabaseController {
  constructor(private readonly databaseService: DatabaseService) {}

  @Post("connect")
  async connect(@Body() connectionDto: ConnectionDto) {
    console.log(
      "[DatabaseController] POST /database/connect - Request received"
    );
    console.log("[DatabaseController] Request body:", {
      hasConnectionString: !!connectionDto.connectionString,
      host: connectionDto.host,
      port: connectionDto.port,
      database: connectionDto.database,
      username: connectionDto.username,
      hasPassword: !!connectionDto.password,
    });

    let connectionString;

    // Build connection string from parts if not provided directly
    if (connectionDto.connectionString) {
      console.log("[DatabaseController] Using provided connection string");
      connectionString = connectionDto.connectionString;
    } else {
      console.log("[DatabaseController] Building connection string from parts");

      // Validate required fields
      if (
        !connectionDto.host ||
        !connectionDto.database ||
        !connectionDto.username
      ) {
        console.error("[DatabaseController] ❌ Missing required fields:", {
          hasHost: !!connectionDto.host,
          hasDatabase: !!connectionDto.database,
          hasUsername: !!connectionDto.username,
        });
        throw new HttpException(
          "Host, database and username are required",
          HttpStatus.BAD_REQUEST
        );
      }

      // Construct connection string
      connectionString = `postgresql://${connectionDto.username}:${connectionDto.password}@${connectionDto.host}:${connectionDto.port || 5432}/${connectionDto.database}`;
      console.log(
        "[DatabaseController] Built connection string:",
        connectionString.replace(/\/\/[^@]+@/, "//***:***@")
      );
    }

    console.log("[DatabaseController] Attempting database connection...");
    const connected = await this.databaseService.connect(connectionString);
    console.log("[DatabaseController] Database connection result:", {
      connected,
    });

    if (!connected) {
      console.error(
        "[DatabaseController] ❌ Connection failed, throwing HTTP exception"
      );
      throw new HttpException(
        "Failed to connect to database",
        HttpStatus.BAD_REQUEST
      );
    }

    const response = {
      success: true,
      message: "Successfully connected to database",
    };
    console.log(
      "[DatabaseController] ✅ Connection successful, sending response:",
      response
    );
    return response;
  }

  @Delete("disconnect")
  async disconnect() {
    console.log(
      "[DatabaseController] DELETE /database/disconnect - Request received"
    );
    await this.databaseService.disconnect();
    const response = { success: true, message: "Disconnected from database" };
    console.log(
      "[DatabaseController] Disconnect completed, sending response:",
      response
    );
    return response;
  }

  @Get("status")
  getStatus() {
    console.log("[DatabaseController] GET /database/status - Request received");
    const status = this.databaseService.getConnectionStatus();
    console.log("[DatabaseController] Status response:", status);
    return status;
  }
}
