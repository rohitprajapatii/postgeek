# 🚧 Interactive Data Management Studio

A powerful, intuitive PostgreSQL database management interface built with modern web technologies, providing developers and database administrators with comprehensive CRUD operations, advanced data browsing, and query execution capabilities.

## 🎯 Overview

The Interactive Data Management Studio is a full-featured database management tool that seamlessly integrates with your existing PostgreSQL monitoring infrastructure. It provides a streamlined, user-friendly interface for performing complex database operations while maintaining enterprise-grade security and performance.

## ✨ Key Features

### 🎨 User Interface & Experience

- **Minimalist Design**: Clean, clutter-free interface focused on productivity
- **Dark Mode Support**: Customizable themes with automatic system preference detection
- **Responsive Layout**: Optimized for various screen sizes and devices
- **Keyboard Shortcuts**: Power-user optimizations for enhanced productivity
- **Real-time Updates**: Live data monitoring with auto-refresh capabilities

### 🗄️ Database Operations

- **Table Browser**: Intuitive tree view for navigating schemas and tables
- **Advanced Search**: Quick search and filtering across schemas and tables
- **Data Viewer**: Paginated, sortable, and filterable data tables
- **Inline Editing**: Quick cell-level edits with immediate validation
- **CRUD Operations**: Complete Create, Read, Update, Delete functionality

### 🔍 Advanced Features

- **Foreign Key Navigation**: Auto-detection and quick navigation between related tables
- **Bulk Operations**: Import/export data with CSV and JSON support
- **Query Console**: SQL editor with syntax highlighting and autocompletion
- **Data Validation**: Real-time type checking and constraint validation
- **Export/Import**: Multiple format support for data exchange

### 🔒 Security & Safety

- **Secure Connections**: TLS/SSL support for encrypted connections
- **Undo Functionality**: Rollback capabilities for accidental changes
- **Read-only Mode**: Safe query execution with write protection
- **Input Validation**: Comprehensive SQL injection protection

## 🏗️ Architecture

### Backend (NestJS + TypeScript)

```
backend/src/
├── data-management/
│   ├── data-management.module.ts      # Main module
│   ├── data-management.controller.ts   # API endpoints
│   ├── data-management.service.ts      # Business logic
│   ├── dto/
│   │   └── table-query.dto.ts          # Data transfer objects
│   └── interfaces/
│       └── data-management.interface.ts # Type definitions
└── app.module.ts                       # Updated with new module
```

### Frontend (Flutter + Dart)

```
frontend/lib/features/data_management/
├── bloc/                               # BLoC state management
│   ├── data_management_bloc.dart      # Main BLoC
│   ├── data_management_event.dart     # Events
│   └── data_management_state.dart     # States
├── models/                            # Data models
│   ├── schema_info.dart              # Schema and table info
│   ├── table_details.dart            # Detailed table metadata
│   └── table_data.dart               # Table data and pagination
├── screens/
│   └── data_management_screen.dart    # Main tabbed interface
└── widgets/                           # Reusable widgets
    ├── schema_browser.dart           # Database schema explorer
    ├── query_console.dart            # SQL query executor
    └── simple_data_table.dart       # Data table with CRUD
```

## 📚 API Documentation

### Core Endpoints

#### Schema Operations

```typescript
GET /data-management/schemas
// Returns all database schemas with table counts

GET /data-management/tables/:schema/:table/info
// Returns detailed table information including columns, constraints, and indexes
```

#### Data Operations

```typescript
GET /data-management/tables/:schema/:table/data
// Paginated table data with sorting and filtering
// Query parameters: page, limit, sortBy, sortOrder, filters

POST /data-management/tables/:schema/:table/records
// Create new record
// Body: { data: Record<string, any> }

PUT /data-management/tables/:schema/:table/records
// Update existing records
// Body: { data: Record<string, any>, where: Record<string, any> }

DELETE /data-management/tables/:schema/:table/records
// Delete records
// Body: { where: Record<string, any> }
```

#### Advanced Operations

```typescript
POST /data-management/tables/:schema/:table/bulk-insert
// Bulk insert with upsert support
// Body: { records: Record<string, any>[], upsert?: boolean }

POST /data-management/query/execute
// Execute custom SQL queries
// Body: { query: string, params?: any[], readonly?: boolean }

POST /data-management/tables/:schema/:table/export
// Export table data in CSV or JSON format
// Body: { format?: 'csv' | 'json', filters?: FilterCondition[] }
```

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ and npm
- PostgreSQL database (local, Docker, or remote)
- Modern web browser with JavaScript enabled

### Installation & Setup

1. **Install Dependencies**

   ```bash
   # Install backend dependencies
   cd backend && npm install

   # Install Flutter dependencies
   cd frontend && flutter pub get
   ```

2. **Start Development Servers**

   ```bash
   # Start backend server (port 3001)
   cd backend && npm run start:dev

   # Run Flutter app
   cd frontend && flutter run
   ```

3. **Access the Application**
   - The Flutter app will launch automatically
   - Backend API runs on: http://localhost:3001
   - Connect to your database and navigate to "Data Studio"

### Database Connection

The studio supports multiple connection types:

#### Local PostgreSQL

```
Host: localhost
Port: 5432
Database: your_database
Username: your_username
Password: your_password
```

#### Docker PostgreSQL

```
Host: localhost (or docker container name)
Port: 5432 (or mapped port)
Database: your_database
Username: your_username
Password: your_password
```

#### Remote PostgreSQL

```
Host: your.remote.host.com
Port: 5432 (or custom port)
Database: your_database
Username: your_username
Password: your_password
```

## 🎮 Usage Guide

### Basic Operations

1. **Connect to Database**

   - Navigate to the Connection page
   - Enter your database credentials
   - Click "Connect" to establish connection

2. **Browse Schemas and Tables**

   - Use the Data Studio to explore your database structure
   - Search for specific tables using the search functionality
   - Click on schemas to expand and view tables

3. **View and Edit Data**

   - Click on any table to view its data
   - Use pagination, sorting, and filtering to navigate large datasets
   - Perform inline edits directly in the data grid

4. **Execute Queries**
   - Navigate to the Query Console
   - Write and execute custom SQL queries
   - View results with syntax highlighting and formatting

### Advanced Features

#### Filtering Data

```typescript
// Example filter conditions
{
  column: "name",
  operator: "LIKE",
  value: "john",
  logicalOperator: "AND"
}
```

#### Bulk Operations

```typescript
// Bulk insert example
{
  records: [
    { name: "John", email: "john@example.com" },
    { name: "Jane", email: "jane@example.com" }
  ],
  upsert: true
}
```

## 🔧 Configuration

### Environment Variables

Create a `.env` file in the root directory:

```bash
# Backend Configuration
DATABASE_URL=postgresql://username:password@localhost:5432/database_name
PORT=3001

# Frontend Configuration
REACT_APP_API_URL=http://localhost:3001
```

### Customization

#### Themes

The application supports light and dark themes with automatic system preference detection. Users can toggle themes using the theme switcher in the navigation bar.

#### API Configuration

Modify `src/services/api.ts` to adjust:

- Request timeouts
- Base URLs
- Authentication headers
- Error handling

## 🧪 Testing

### Manual Testing Checklist

- [ ] Database connection with various PostgreSQL setups
- [ ] Schema and table browsing functionality
- [ ] Data viewing with pagination and sorting
- [ ] CRUD operations on test data
- [ ] Query execution in read-only and write modes
- [ ] Dark mode toggle and theme persistence
- [ ] Responsive design on different screen sizes

### API Testing

Use tools like Postman or curl to test API endpoints:

```bash
# Test connection status
curl http://localhost:3001/database/status

# Test schema retrieval
curl http://localhost:3001/data-management/schemas
```

## 🐛 Troubleshooting

### Common Issues

#### Connection Failures

- Verify PostgreSQL server is running
- Check connection credentials
- Ensure network connectivity (especially for Docker setups)
- Review backend logs for detailed error messages

#### Frontend Not Loading

- Ensure all dependencies are installed: `npm install`
- Check for TypeScript errors: `npm run type-check`
- Verify backend is running on the correct port

#### API Errors

- Check backend console for detailed error logs
- Verify database permissions for the connected user
- Ensure table and schema names are correctly specified

## 🛠️ Development

### Adding New Features

1. **Backend API Endpoint**

   ```typescript
   // Add to data-management.controller.ts
   @Get('new-endpoint')
   async newEndpoint() {
     return this.dataManagementService.newMethod();
   }
   ```

2. **Frontend Integration**

   ```typescript
   // Add to services/api.ts
   export const dataManagementApi = {
     newMethod: async () => {
       const response = await api.get("/data-management/new-endpoint");
       return response.data;
     },
   };
   ```

3. **React Component**
   ```typescript
   // Use React Query for state management
   const { data, isLoading } = useQuery({
     queryKey: ["new-data"],
     queryFn: dataManagementApi.newMethod,
   });
   ```

### Code Style and Conventions

- Use TypeScript for type safety
- Follow React hooks best practices
- Implement proper error handling
- Add loading states for async operations
- Include comprehensive TypeScript interfaces

## 📈 Performance Optimization

### Database Queries

- Implement pagination for large datasets
- Use efficient SQL queries with proper indexing
- Cache frequently accessed schema information
- Optimize foreign key lookups

### Frontend Performance

- Implement virtual scrolling for large data sets
- Use React Query for intelligent caching
- Debounce search inputs
- Lazy load components where appropriate

## 🔮 Future Enhancements

### Planned Features

- [ ] Advanced query builder with visual interface
- [ ] Database schema visualization and ERD generation
- [ ] Real-time collaboration features
- [ ] Advanced analytics and reporting
- [ ] Multi-database support (MySQL, SQLite, etc.)
- [ ] Saved queries and query templates
- [ ] Data migration and backup tools
- [ ] User management and role-based permissions
- [ ] API documentation generator
- [ ] Performance monitoring and query optimization

### Technical Improvements

- [ ] WebSocket integration for real-time updates
- [ ] Progressive Web App (PWA) capabilities
- [ ] Enhanced mobile responsiveness
- [ ] Offline functionality for cached data
- [ ] Advanced caching strategies
- [ ] Internationalization (i18n) support

## 📄 License

This project is part of the PostGeek PostgreSQL monitoring tool suite. Please refer to the main project license for usage terms and conditions.

## 🤝 Contributing

Contributions are welcome! Please follow the existing code style and include appropriate tests for new features. Submit pull requests with clear descriptions of changes and their impact.

## 📞 Support

For issues, feature requests, or questions about the Interactive Data Management Studio, please:

1. Check the troubleshooting section above
2. Review existing issues in the project repository
3. Create a new issue with detailed reproduction steps
4. Contact the development team for enterprise support options

---

**Built with ❤️ for the PostgreSQL community**
