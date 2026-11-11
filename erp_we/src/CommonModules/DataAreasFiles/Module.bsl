
#Region Public

// Parameters:
//	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.DataAreasFiles);
	
EndProcedure

// Returns the name, size, location, or binary data of a file by ID.
// If the file is stored on disk, the file location is returned to the fullname value.
// If the file is stored in an information database, binary data is returned to the Data value. 
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//  DataArea - Number - number of the data area.
//  Id - String - file ID (length-36).
// 
// Returns:
//  Structure - file description, see newfile descriptionreferences:
//	 * FileName - String - file name
//	 * Size - Number - file size in bytes
//	 * FullName - String, Undefined - location of the file in the volume.
//	 * Data - BinaryData, Undefined - binary data of the file.
//	 * CRC32 - Number - checksum of the file data.
//	 * SetTemporaryOnGet - Boolean - indicates whether it is temporary when received.
//
Function FileDetails(Val DataArea, Val Id) Export
EndFunction

// Returns binary file data by ID.
// @skip-warning EmptyMethod - a feature of the implementation.
// 
// Parameters:
//  DataArea - Number - number of the data area.
//  Id - String - file ID (length-36).
//
// Returns:
//  BinaryData - binary data of the file.
//
Function FileBinaryData(Val DataArea, Val Id) Export
EndFunction

// Places file data in temporary storage and returns a description
// for saving or opening the file.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataArea - Number - number of the data area.
//  FileID - UUID - file identifier. 
//  FormIdentifier - UUID - ID of the form for the room.
// 
// Returns:
//  TransferableFileDescription - File descriptiontransferable - description for saving or opening the file.
//
Function TransferableFileDescription(Val DataArea, FileID, FormIdentifier) Export
EndFunction

// Saves data as a file entry in the Data File information register.
// If the parameter Data = Undefined, the parameter Fullname = full filename with path must be filled in.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataArea - Number - number of the data area.
//  Name - String - name of the file in the storage.
//  Data - BinaryData, String, Undefined - binary data of the file, if fullname = Undefined.
//  FullName - String, Undefined - full file name with path if Data = Undefined.
//  Temp - Boolean - flag for a temporary file (will be deleted according to the specified schedule of the reg. task for deleting timestampfiles in the data Area)
//  SetTemporaryOnGet - Boolean - set the temporary file flag when it is first received.
//
// Returns:
//  UUID - file identifier.
//
Function ImportFile_(Val DataArea, Val Name, Data = Undefined, FullName = Undefined, 
	Temp = False, SetTemporaryOnGet = False) Export
EndFunction

// Sets the "Temporary" = True attribute for the file.
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataArea - Number - number of the data area.
//  FileID - UUID -  file identifier.
//  
// Returns:
//	Boolean - True if the installation was successful, False otherwise.
Function SetTemporaryFlag(Val DataArea, Val FileID) Export
EndFunction

// Delete a file from the information database
// @skip-warning EmptyMethod - a feature of the implementation.
//
// Parameters:
//  DataArea - Number - number of the data area.
//  FileID - UUID -  ID of the file to delete.
//  DeleteIfOnDisk - Boolean - if False and stored on disk, it is registered as temporary and is not deleted from disk.
//
// Returns:
//  Boolean - The success of the deletion.
//
Function DeleteFile(Val DataArea, Val FileID, Val DeleteIfOnDisk = True) Export
EndFunction

#EndRegion
