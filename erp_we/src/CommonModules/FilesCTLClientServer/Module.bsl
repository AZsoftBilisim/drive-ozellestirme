//@strict-types

#Region Internal

// Parameters: 
//  FileName - String
//  FileSize - Number
// 
// Returns: 
//  String - file representation.
Function FilePresentation(FileName, FileSize) Export

	FSObject = New File(FileName);
	Return StrTemplate("%1 (%2)", FSObject.Name, FileSizePresentation(FileSize));

EndFunction

// Parameters: 
//  FileSize - Number
// 
// Returns: 
//  String - Representation of the file size.
Function FileSizePresentation(FileSize) Export
	
	If FileSize < 1024 Then
		Result = StrTemplate(NStr("vi = '%1 byte';
									|ru = '%1 байт';
									|en = '%1 Bytes'; fa = '%1 Bytes';
									|it = '%1 bite';
									|pl = '%1 bajt';
									|tr = '%1 bayt'"), FileSize);
	ElsIf FileSize < 1024 * 1024 Then
		Result = StrTemplate(NStr("vi = '%1 Kb';
									|ru = '%1 Кб';
									|en = '%1 KB'; fa = '%1 KB';
									|it = '%1 KB';
									|pl = '%1 Kb';
									|tr = '%1 Kb'"), Format(FileSize / 1024, "NFD=0"));
	ElsIf FileSize < 1024 * 1024 * 1024 Then
		Result = StrTemplate(NStr("vi = '%1 Mb';
									|ru = '%1 Мб';
									|en = '%1 MB'; fa = '%1 MB';
									|it = '%1 MB';
									|pl = '%1 MB';
									|tr = '%1 Mb'"), Format(FileSize / 1024 / 1024, "NFD=0"));
	Else
		Result = StrTemplate(NStr("vi = '%1 GB';
									|ru = '%1 Гб';
									|en = '%1 GB'; fa = '%1 GB';
									|it = '%1 Gb';
									|pl = '%1 GB';
									|tr = '%1 Gb'"), Format(FileSize / 1024 / 1024 / 1024, "NFD=0"));
	EndIf;

	Return Result;

EndFunction

// Parameters: 
//  FileSize - Number 
// 
// Returns: 
//  Number - Processing portion size
Function ProcessingPortionSize(FileSize, ImportToService = False) Export
	
	If ImportToService Then
		MinimumSize = 5 * 1024 * 1024;
	Else
		MinimumSize = 1;
	EndIf;
	
	MaximumSize = 10 * 1024 * 1024;
	
	Result = Round(FileSize / 10);
	Result = Min(Result, MaximumSize);
	Result = Max(Result, MinimumSize);
	
	Return Max(Result, 1);
	
EndFunction

// Maximum size of temporary storage
// 
// Returns: 
//  Number - The maximum size of the temporary storage.
Function MaximumSizeOfTemporaryStorage() Export

	Return 4 * 1024 * 1024 * 1024;

EndFunction

// Acceptable size of temporary storage
// 
// Returns: 
//  Number - Acceptable size of temporary storage.
Function AcceptableSizeOfTemporaryStorage() Export

	Return 100 * 1024 * 1024;

EndFunction

#EndRegion