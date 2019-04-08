// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

#import <sqlite3.h>

#import "AppCenter+Internal.h"
#import "MSAppCenterInternal.h"
#import "MSConstants+Internal.h"
#import "MSDBDocumentStorePrivate.h"
#import "MSDBStoragePrivate.h"
#import "MSDataStore.h"
#import "MSDataStoreInternal.h"
#import "MSDocumentWrapper.h"
#import "MSUtility+StringFormatting.h"
#import "MSWriteOptions.h"

static const NSUInteger kMSSchemaVersion = 1;

@implementation MSDBDocumentStore

#pragma mark - Initialization

- (instancetype)init {

  /*
   * DO NOT modify schema without a migration plan and bumping database version.
   */
  MSDBSchema *schema = @{kMSAppDocumentTableName : [MSDBDocumentStore columnsSchema]};
  if ((self = [super init])) {
    self.dbStorage = [[MSDBStorage alloc] initWithSchema:schema version:kMSSchemaVersion filename:kMSDBDocumentFileName];
    NSDictionary *columnIndexes = [MSDBStorage columnsIndexes:schema];
    _idColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSIdColumnName]).unsignedIntegerValue;
    _partitionColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSPartitionColumnName]).unsignedIntegerValue;
    _documentIdColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSDocumentIdColumnName]).unsignedIntegerValue;
    _documentColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSDocumentColumnName]).unsignedIntegerValue;
    _eTagColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSETagColumnName]).unsignedIntegerValue;
    _expirationTimeColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSExpirationTimeColumnName]).unsignedIntegerValue;
    _downloadTimeColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSDownloadTimeColumnName]).unsignedIntegerValue;
    _operationTimeColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSOperationTimeColumnName]).unsignedIntegerValue;
    _pendingOperationColumnIndex = ((NSNumber *)columnIndexes[kMSAppDocumentTableName][kMSPendingOperationColumnName]).unsignedIntegerValue;
  }
  return self;
}

#pragma mark - Table Management

- (BOOL)upsertWithPartition:(NSString *)partition
                  accountId:(NSString *_Nullable)accountId
            documentWrapper:(MSDocumentWrapper *)documentWrapper
                  operation:(NSString *_Nullable)operation
                    options:(MSBaseOptions *)options {
  NSDate *now = [NSDate date];
  NSDate *expirationTime = [now dateByAddingTimeInterval:options.deviceTimeToLive];
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:partition accountId:accountId];
  NSString *insertQuery =
      [NSString stringWithFormat:@"REPLACE INTO '%@' ('%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@') "
                                 @"VALUES ('%@', '%@', '%@', '%@', '%@', '%@', '%@', '%@')",
                                 tableName, kMSPartitionColumnName, kMSDocumentIdColumnName, kMSDocumentColumnName,
                                 kMSETagColumnName, kMSExpirationTimeColumnName, kMSDownloadTimeColumnName, kMSOperationTimeColumnName,
                                 kMSPendingOperationColumnName, partition, documentWrapper.documentId, documentWrapper.jsonValue,
                                 documentWrapper.eTag, expirationTime, documentWrapper.lastUpdatedDate, now, operation];
  NSInteger result = [self.dbStorage executeNonSelectionQuery:insertQuery];
  if (result != SQLITE_OK) {
    MSLogError([MSDataStore logTag], @"Unable to update or replace stored document, SQLite error code: %ld", (long)result);
  }
  return result == SQLITE_OK;
}

- (BOOL)deleteWithPartition:(NSString *)partition
                  accountId:(NSString *_Nullable)accountId
                 documentId:(NSString *)documentId {
  NSString *tableName = [MSDBDocumentStore tableNameForPartition:partition accountId:accountId];
  NSString *deleteQuery = [NSString stringWithFormat:@"DELETE FROM '%@' WHERE '%@' = '%@' AND '%@' = '%@'", tableName,
                                                     kMSPartitionColumnName, partition, kMSDocumentIdColumnName, documentId];
  NSInteger result = [self.dbStorage executeNonSelectionQuery:deleteQuery];
  if (result != SQLITE_OK) {
    MSLogError([MSDataStore logTag], @"Unable to delete stored document, SQLite error code: %ld", (long)result);
  }
  return result == SQLITE_OK;
}

- (BOOL)createUserStorageWithAccountId:(NSString *)accountId {

  // Create table based on the schema.
  return [self.dbStorage createTable:[NSString stringWithFormat:kMSUserDocumentTableNameFormat, accountId]
                       columnsSchema:[MSDBDocumentStore columnsSchema]];
}

- (BOOL)deleteUserStorageWithAccountId:(NSString *)accountId {
  NSString *tableName = [NSString stringWithFormat:kMSUserDocumentTableNameFormat, accountId];
  return [self.dbStorage dropTable:tableName];
}

+ (MSDBColumnsSchema *)columnsSchema {

  // TODO create composite key for partition and the document id
  NSMutableArray *schema = [NSMutableArray new];
  [schema addObject:@{kMSIdColumnName : @[ kMSSQLiteTypeInteger, kMSSQLiteConstraintPrimaryKey, kMSSQLiteConstraintAutoincrement ]}];
  [schema addObject:@{kMSPartitionColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}];
  [schema addObject:@{kMSDocumentIdColumnName : @[ kMSSQLiteTypeText, kMSSQLiteConstraintNotNull ]}];
  [schema addObject:@{kMSDocumentColumnName : @[ kMSSQLiteTypeText ]}];
  [schema addObject:@{kMSETagColumnName : @[ kMSSQLiteTypeText ]}];
  [schema addObject:@{kMSExpirationTimeColumnName : @[ kMSSQLiteTypeInteger ]}];
  [schema addObject:@{kMSDownloadTimeColumnName : @[ kMSSQLiteTypeInteger ]}];
  [schema addObject:@{kMSOperationTimeColumnName : @[ kMSSQLiteTypeInteger ]}];
  [schema addObject:@{kMSPendingOperationColumnName : @[ kMSSQLiteTypeText ]}];
  
  // Schema needs to be immutable for versioning.
  NSArray *immutableSchema = [schema copy];
  return immutableSchema;
}

+ (NSString *)tableNameForPartition:(NSString *)partition
                          accountId:(NSString *_Nullable)accountId {
  if ([partition isEqualToString:MSDataStoreAppDocumentsPartition]) {
    return kMSAppDocumentTableName;
  }
  return [NSString stringWithFormat:kMSUserDocumentTableNameFormat, accountId];
}

@end
