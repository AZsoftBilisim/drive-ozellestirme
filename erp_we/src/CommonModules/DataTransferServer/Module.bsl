#Region Public

// Returns the managers of the logical storage.
//
// Returns:
//  FixedMap of String - Logical Storage Managers:
//    * Key - String - ID of the logical storage;
//    * Value - CommonModule - logical storage Manager.
//
Function AllLogicalStorageManagers() Export
	
	Return DataTransferCached.LogicalStorageManagers();
	
EndFunction

// Returns the managers of the physical stores.
//
// Returns:
//  FixedMap of String - Physical Storage Managers:
//    * Key - String - ID of the physical storage;
//    * Value - CommonModule - physical storage Manager.
//
Function AllPhysicalStorageManagers() Export
	
	Return DataTransferCached.PhysicalStorageManagers();
	
EndFunction

// Retrieves data from logical storage.
//
// Parameters:
//   AccessParameters - Structure - Fields:
//     * URL - String - The service URL must be present and filled in;
//     * UserName - String - user name;
//     * Password - String - user password.
//     * Cache - Map of String - optional, an empty match, if specified, can be used for caching.
//   StorageID - String - ID of the logical storage.
//   Id - String - ID of the data in the logical storage.
//   Span - Structure - 
//     * Start - Number is the first byte.
//     * End - Number is the last byte.
//   FileName - String, Undefined - The name of the file to write the data to.
// 
// Returns:
//  Undefined, Structure - Get From Logical Storage:
//   * Name - String - file name 
//   * FullName - String - full file name (including file path) 
//
Function GetFromLogicalStorage(AccessParameters, StorageID, Id, Span = Undefined, FileName = Undefined) Export
	
	Return DataTransferInternal.Get(AccessParameters, False, StorageID, Id, Span, FileName);
	
EndFunction

// Retrieves information about the file from the logical storage.
//
// Parameters:
//   AccessParameters - Structure - Fields:
//     * URL - String - The service URL must be present and filled in;
//     * UserName - String - user name;
//     * Password - String - user password.
//   StorageID - String - ID of the logical storage.
//   Id - String - ID of the data in the logical storage.
//
// Returns:
//   Number - file size in bytes.
//
Function GetFileSizeFromLogicalStorage(AccessParameters, StorageID, Id) Export
	
	Return DataTransferInternal.GetFileSize(AccessParameters, False, StorageID, Id);
	
EndFunction

// Retrieves data from physical storage.
//
// Parameters:
//   AccessParameters - Structure - Fields:
//     * URL - String - The service URL must be present and filled in;
//     * UserName - String - user name;
//     * Password - String - user password.
//   StorageID - String - ID of the physical storage.
//   Id - String - ID of the data in the physical storage.
//   FileName - String, Undefined - The name of the file to write the data to.
//
// Returns:
//   Undefined, Structure - File description:
//	   * Name - String - file name;
//	   * FullName - String - the full name of the file (including the path to the file).
//
Function GetFromPhysicalStorage(AccessParameters, StorageID, Id, FileName = Undefined) Export
	
	Return DataTransferInternal.Get(AccessParameters, True, StorageID, Id,, FileName);
	
EndFunction

// Sends data to logical storage.
//
// Parameters:
//   AccessParameters - Structure - Fields:
//     * URL - String - The service URL must be present and filled in;
//     * UserName - String - user name;
//     * Password - String - user password.
//   StorageID - String - ID of the logical storage.
//   Data - String - address of data in temporary storage;
//          - String - full file name (including the path to the file);
//          - File - file object;
//          - BinaryData - the value is in the form of binary data.
//   FileName - String - name of the file to transfer.
//   AdditionalParameters - Structure - a structure with values serialized in json.
// 
// Returns:
//  Number, Undefined, Arbitrary -
//
Function SendToLogicalStorage(AccessParameters, StorageID, Data, Val FileName, AdditionalParameters = Undefined) Export
	
	Return DataTransferInternal.Send(AccessParameters, False, StorageID, Data, FileName, AdditionalParameters);
	
EndFunction

// Starts sending the file to the logical storage
// 
// Parameters:
//   AccessParameters - Structure - Fields:
//     * URL - String - The service URL must be present and filled in;
//     * UserName - String - user name;
//     * Password - String - user password.
//   StorageID - String - ID of the logical storage.
//   Data - String - address of data in temporary storage;
//          - String - full file name (including the path to the file);
//          - File - file object;
//          - BinaryData - the value is in the form of binary data.
//   FileName - String - name of the file to transfer.
//   AdditionalParameters - Structure - a structure with values serialized in json.
// 
// Returns:
//  Undefined, Structure - Fields:
//    * Location - Undefined, Arbitrary - 
//    * SetCookie - Arbitrary, Undefined - 
//    * S3Address - Arbitrary, Undefined - 
//    * S3FileId - Arbitrary, Undefined - 
//    * TransferInParts - Boolean
// 
Function StartSendingToLogicalStorage(AccessParameters, StorageID, Data, Val FileName, AdditionalParameters = Undefined) Export
	
	Return DataTransferInternal.StartSending(AccessParameters, False, StorageID, Data, FileName, AdditionalParameters);
	
EndFunction


// Sends the next part
//
// Parameters:
//   AccessParameters - Structure - Fields:
//     * URL - String - The service URL must be present and filled in;
//     * UserName - String - user name;
//     * Password - String - user password.
//   SendOptions - Structure - fields:
//     Location - String -
//     SetCookie - String - 
//     addresss3 - String - 
//     fileididators3 - String - 
//     Gearshift - Boolean - 
//  Data - Arbitrary -
//  LastPart - Boolean -
//  Offset - Number -
// 
// Returns:
//   Number, Undefined - The number of bytes in case of successful sending, or Undefined if it failed to send
//
Function SendPartOfFileToLogicalStorage(AccessParameters, SendOptions, Data, LastPart = True, Offset = 0) Export
	
	Return DataTransferInternal.SendPartOfFile(AccessParameters, SendOptions, Data, LastPart, Offset);
	
EndFunction

// Sends data to physical storage.
//
// Parameters:
//   AccessParameters - Structure - Fields:
//     * URL - String - The service URL must be present and filled in;
//     * UserName - String - user name;
//     * Password - String - user password.
//   StorageID - String - ID of the physical storage.
//   Data - String - address of data in temporary storage;
//          - String - full file name (including the path to the file);
//          - File - file object;
//          - BinaryData - the value is in the form of binary data.
//   FileName - String - name of the file to transfer.
//
// 
// Returns:
//  Number, Undefined, Arbitrary -
//
Function SendToPhysicalStorage(AccessParameters, StorageID, Data, Val FileName) Export
	
	Return DataTransferInternal.Send(AccessParameters, True, StorageID, Data, FileName);
	
EndFunction

#EndRegion