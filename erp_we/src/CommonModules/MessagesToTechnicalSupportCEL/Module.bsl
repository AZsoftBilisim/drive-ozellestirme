#Region Public


#EndRegion

#Region Internal

Function FilesInArchiveWithBreakdown(FilesFound) Export

	Attachments = New Array();
	Results = New Array();
	
	Archive = New ZipFileWriter();
	Archive.Add(FilesFound, 
		ZIPStorePathMode.StoreRelativePath, 
		ZIPSubDirProcessingMode.ProcessRecursively);
	BinaryData = Archive.GetBinaryData();
	AddAttachmentFile(Attachments, BinaryData, "logs.b64");
	
	For Each Attachment In Attachments Do
		Presentation = ?(Right(Attachment.FileName,4) = ".txt", Attachment.FileName, Attachment.FileName + ".txt");
		
		Id = New UUID();
		ResultAddress = PutToTempStorage("", Id);
		ResultAddress = PutToTempStorage(Attachment.Data, ResultAddress);
		
		Result = New Structure();
		Result.Insert("FileName", Presentation);
		Result.Insert("Data", ResultAddress);
		Results.Add(Result);
	EndDo;
	
	Return Results;
	
EndFunction

Function FileInArchiveIsBrokenDown(PathToFile) Export

	Attachments = New Array();
	Results = New Array();
	
	Archive = New ZipFileWriter();
	Archive.Add(PathToFile);
	BinaryData = Archive.GetBinaryData();
	AddAttachmentFile(Attachments, BinaryData, "logs.b64");
	
	For Each Attachment In Attachments Do
		Presentation = ?(Right(Attachment.FileName,4) = ".txt", Attachment.FileName, Attachment.FileName + ".txt");
		AttachmentParameters = New Structure;
		AttachmentParameters.Insert("DataKind", "Address");
		AttachmentParameters.Insert("Presentation", Presentation);
		
		Id = New UUID();
		ResultAddress = PutToTempStorage("", Id);
		ResultAddress = PutToTempStorage(Attachment.Data, ResultAddress);
		
		Result = New Structure();
		Result.Insert("FileName", Presentation);
		Result.Insert("Data", ResultAddress);
		Results.Add(Result);
	EndDo;
	
	Return Results;
	
EndFunction

#EndRegion

#Region Private


// Adds a file converted to BASE64 to the Attachment array and splits it into parts if the file exceeds 
// the allowed size.
//
// Parameters:
//  Attachments - Array of Structure - array of structures containing attachments
//  BinaryData - BinaryData - data to add to attachments
//  FileName - String - attachment file name
Procedure AddAttachmentFile(Attachments, BinaryData, FileName)
	
	MaximumBASE64FileSize = MaximumFileSizeOfBIP();
	// Reducing the maximum file size by transfer characters, two transfer characters for every 80
	MaxFileSize = MaximumBASE64FileSize - MaximumBASE64FileSize / 80 * 2;
	// Reducing the maximum file size due to transcoding
	MaxFileSize = Int(MaxFileSize * 3/4 * 0.9);
	
	If MaxFileSize > BinaryData.Size() Then
		Attachment = New Structure();
		Attachment.Insert("FileName", FileName);
		Data = GetBinaryDataFromString(GetBase64StringFromBinaryData(BinaryData));
		Attachment.Insert("Data", Data);
		Attachments.Add(Attachment);
	Else
		BinaryDataArray = SplitBinaryData(BinaryData, MaxFileSize);
		For Number = 0 To BinaryDataArray.UBound() Do
			Attachment = New Structure();
			Attachment.Insert("FileName", Left(FileName, StrLen(FileName) - 2) + Right("00" + Number, 2));
			Data = GetBinaryDataFromString(GetBase64StringFromBinaryData(BinaryDataArray[Number]));
			Attachment.Insert("Data", Data);
			Attachments.Add(Attachment);
		EndDo;
	EndIf;
	
EndProcedure

// Determines the maximum size of the attachment file.
//
// Returns:
//  Number - maximum file size in bytes.
//
Function MaximumFileSizeOfBIP()
	
	Return 10485760; // 10 MB.
	
EndFunction

#EndRegion
