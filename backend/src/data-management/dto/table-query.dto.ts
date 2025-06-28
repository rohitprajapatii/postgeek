import {
  IsString,
  IsOptional,
  IsInt,
  Min,
  IsArray,
  IsObject,
  IsBoolean,
} from "class-validator";

export class TableQueryDto {
  @IsOptional()
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @IsInt()
  @Min(1)
  limit?: number = 50;

  @IsOptional()
  @IsString()
  sortBy?: string;

  @IsOptional()
  @IsString()
  sortOrder?: "ASC" | "DESC" = "ASC";

  @IsOptional()
  @IsArray()
  filters?: FilterCondition[];
}

export class FilterCondition {
  @IsString()
  column: string;

  @IsString()
  operator: string; // =, !=, >, <, >=, <=, LIKE, ILIKE, IN, NOT IN

  @IsString()
  value: string;

  @IsOptional()
  @IsString()
  logicalOperator?: "AND" | "OR" = "AND";
}

export class CreateRecordDto {
  @IsObject()
  data: Record<string, any>;
}

export class UpdateRecordDto {
  @IsObject()
  data: Record<string, any>;

  @IsObject()
  where: Record<string, any>;
}

export class DeleteRecordDto {
  @IsObject()
  where: Record<string, any>;
}

export class BulkOperationDto {
  @IsArray()
  records: Record<string, any>[];

  @IsOptional()
  @IsBoolean()
  upsert?: boolean = false;
}

export class QueryExecutionDto {
  @IsString()
  query: string;

  @IsOptional()
  @IsArray()
  params?: any[];

  @IsOptional()
  @IsBoolean()
  readonly?: boolean = true;
}

export class SavedQueryDto {
  @IsString()
  name: string;

  @IsString()
  query: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsArray()
  tags?: string[];
}
