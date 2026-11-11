#Region Internal

// Parameters:
// 	FileName - String
// 	
// Returns:
// 	Structure - LongDesc:
// * FileName - String
// * Size - Number
// * FolderSize - Number
// * Files - Array of See ReadDirectoryEntry
// * Stream - FileStream
//
Function Create(FileName) Export
	
	Info = New File(FileName);
	If Info.Exists() Then
		DeleteFiles(FileName);
	EndIf;
	
	Archive = New Structure;
	Archive.Insert("FileName", FileName);
	Archive.Insert("Stream", FileStreams.OpenForWrite(FileName));
	Archive.Insert("Files", New Array);
	Archive.Insert("FolderSize", 0);
	Archive.Insert("Size", 0);
	
	Return Archive;
	
EndFunction

// Parameters:
// 	Archive - See Create
// 	FileName - String
//
Procedure AppendFile(Archive, FileName) Export
	
	Var TempFileName;
	
	Info = New File(FileName);
	If Info.IsDirectory() Or Info.Size() > MaximumFileSizeInMemory() Then
		TempFileName = GetTempFileName("zip");
		Stream = FileStreams.Open(TempFileName, FileOpenMode.OpenOrCreate, FileAccess.ReadAndWrite);
	Else
		Stream = New MemoryStream();
	EndIf;
	RecordZIP = New ZipFileWriter(Stream);
	If Info.IsDirectory() Then
		RecordZIP.Add(FileName + GetPathSeparator() + "*", ZIPStorePathMode.StoreRelativePath, ZIPSubDirProcessingMode.ProcessRecursively);
	Else
		RecordZIP.Add(FileName, ZIPStorePathMode.DontStorePath);
	EndIf;
	RecordZIP.Write();
	
	ArchiveData = ReadArchive(Stream);
	
	Offset = 0;
	Buffer = ArchiveData.DirectoryEntries;
	Size = Buffer.Size;
	
	While Offset < Size Do
		
		RecordWasFound = ReadDirectoryEntry(Buffer, Offset);
		
		FileTitle = GetBytes(Stream, RecordWasFound.FileOffset, 30);
		Length = 30 + FileTitle.ReadInt16(26) + FileTitle.ReadInt16(28) + RecordWasFound.CompressedSize; // 30 + file name length + extra field length
		
		Offset = Archive.Size + Archive.Stream.CurrentPosition();
		If Offset >= 4294967295 Then
			
			FileNameLength = RecordWasFound.Buffer.ReadInt16(28);
			LengthOfAdditionalData = RecordWasFound.Buffer.ReadInt16(30);
			CommentLength = RecordWasFound.Buffer.ReadInt16(32);
			If CommentLength <> 0 Then
				Raise "not implemented";
			EndIf;
			BufferAdditionalData = RecordWasFound.Buffer.Read(46 + FileNameLength, LengthOfAdditionalData);
			Additional_Data = ParseAdditionalData(BufferAdditionalData);
			
			// Since the file in the source archive is always 1, then its offset is 0 and, accordingly, there is no extended information
			NewBuffer = New BinaryDataBuffer(8);
			NewBuffer.WriteInt64(0, Offset);
			For Each Addl64 In Additional_Data Do
				If Addl64.Type = NumberFromHexString("0x0001") Then
					Addl64.Data = Addl64.Data.Concat(NewBuffer);
					NewBuffer = Undefined;
					Break;
				EndIf;
			EndDo;
			If NewBuffer <> Undefined Then
				Additional_Data.Add(New Structure("Type, Data", NumberFromHexString("0x0001"), NewBuffer));
			EndIf;
			BufferAdditionalData = CollectAdditionalData(Additional_Data);
			RecordWasFound.Buffer = RecordWasFound.Buffer.Concat(New BinaryDataBuffer(BufferAdditionalData.Size - LengthOfAdditionalData));
			RecordWasFound.Buffer.WriteInt16(30, BufferAdditionalData.Size);
			RecordWasFound.Buffer.Write(46 + FileNameLength, BufferAdditionalData);
			RecordWasFound.RecordLength = RecordWasFound.Buffer.Size;
			
			Offset = 4294967295;
			
		EndIf;
		RecordWasFound.Buffer.WriteInt32(42, Offset); // FileOffset
		Archive.FolderSize = Archive.FolderSize + RecordWasFound.RecordLength;
		Archive.Files.Add(RecordWasFound);
		
		// The data itself
		Stream.Seek(RecordWasFound.FileOffset, PositionInStream.Begin);
		Stream.CopyTo(Archive.Stream, Length);		
		
		Offset = Offset + RecordWasFound.RecordLength;
		
	EndDo;
	
	Stream.Close();
	If TypeOf(Stream) = Type("FileStream") Then
		DeleteFiles(TempFileName);
	EndIf;
	
EndProcedure

// Parameters: 
//  Archive - See Create
// 
// Returns: 
//  Number
Function Size(Archive) Export
	
	Return Archive.Stream.Size();
	
EndFunction

// Parameters:
// 	Archive - See Create
// 	FileName - String
//
Procedure SeparatePart(Archive, FileName) Export
	
	Archive.Stream.Flush();
	Archive.Size = Archive.Size + Archive.Stream.Size();
	Archive.Stream.Close();
	MoveFile(Archive.FileName, FileName);
	Archive.Stream = FileStreams.OpenForWrite(Archive.FileName);
	
EndProcedure

// Parameters:
// 	Archive - See Create
//
Procedure ExitApp(Archive) Export
	
	WriteStream = Archive.Stream;
	FilesInArchive = Archive.Files; // Array of 
	
	DirectoryOffset = Archive.Size + WriteStream.CurrentPosition();
	
	// Central Directory Entry
	For Each RecordWasFound In FilesInArchive Do
		//Record data.Write down the two-part data (found record.Buffer);	
		WriteStream.Write(RecordWasFound.Buffer, 0, RecordWasFound.Buffer.Size);
	EndDo;
	
	If DirectoryOffset >= 4294967295 Or FilesInArchive.Count() >= 65535 Then
		
		// EndOfDirectory64
		Buffer = NewEndOfDirectory64(FilesInArchive.Count(), Archive.FolderSize, DirectoryOffset);
		OffsetEndOfDirectory64 = Archive.Size + WriteStream.CurrentPosition();
		WriteStream.Write(Buffer, 0, Buffer.Size);
		
		// Locator64
		Buffer = NewLocator64(OffsetEndOfDirectory64);
		WriteStream.Write(Buffer, 0, Buffer.Size);
		
		DirectoryOffset = 4294967295;
	EndIf;
	
	// EndOfDirectory
	Buffer = NewEndOfDirectory(FilesInArchive.Count(), Archive.FolderSize, DirectoryOffset);
	WriteStream.Write(Buffer, 0, Buffer.Size);
	
	// The archive is ready
	WriteStream.Close();
	
EndProcedure

// Read the archive.
// 
// Parameters: 
//  Source - FileStream, MemoryStream, UUID - 
//  	the source of the archive, if the unique identifier is a file in the volume.
// 
// Returns: 
//	Structure:
//	 * DirectoryEntries - FileStream, MemoryStream -
//   * Source - FileStream, MemoryStream, UUID -
//   * EndOfDirectory - see the end of the catalog
//   * Offset - Number
//   * Size - Number
//			  - Undefined
Function ReadArchive(Source) Export

	SetSafeModeDisabled(True);
	Return ReadArchiveInside(Source);
	
EndFunction

// Parameters:
// 	ArchiveData - See ZIPArchives.ReadArchive
// 	FileName - String - the name of the file in the archive
// 	
// Returns:
//  See ReadArchive 
Function ReadAttachedUncompressedArchive(ArchiveData, FileName) Export
	
	RecordWasFound = FindRecord(ArchiveData, FileName);
	
	If RecordWasFound = Undefined Then
		Raise StrTemplate(NStr("vi = 'Không tìm thấy tệp %1';
								|ru = 'Файл %1 не найден';
								|en = 'File %1 is not found'; fa = 'File %1 is not found';
								|it = 'File %1 non trovato';
								|pl = 'Plik %1 nie został znaleziony';
								|tr = '%1 dosyası bulunamadı'"), FileName);
	EndIf;
	
	FileTitle = ReadIntoBinaryDataBuffer(ArchiveData, RecordWasFound.FileOffset, 30);
	Offset = RecordWasFound.FileOffset + 30 + FileTitle.ReadInt16(26) + FileTitle.ReadInt16(28);
	
	SetSafeModeDisabled(True);
	Return ReadArchiveInside(ArchiveData.Source, Offset, RecordWasFound.UncompressedSize);
	
EndFunction

// Parameters: 
//  ArchiveData - See ZIPArchives.ReadArchive
//  FileName - String
//  Directory - String
// 
// Returns: 
//  Boolean
Function ExtractFile(ArchiveData, FileName, Directory) Export
	
	RecordWasFound = FindRecord(ArchiveData, FileName);
	
	If RecordWasFound = Undefined Then
		Return False;
	EndIf;
	
	If TypeOf(ArchiveData.Source) = Type("UUID") Then
		// Header length:
		//   header size, always 30
		//   file name length
		//   data length length, but here usually 0 
		Size = 30 + RecordWasFound.Buffer.ReadInt16(28) + 0 + RecordWasFound.CompressedSize;
		TimeFile = ReadToFileFromVolume(ArchiveData, RecordWasFound.FileOffset, Size);
		
		ReaderStream = FileStreams.OpenForRead(TimeFile);
		FileTitle = New BinaryDataBuffer(30);
		ReaderStream.Read(FileTitle, 0, 30);
		ReaderStream.Seek(0, PositionInStream.Begin);
		CorrectSize = 30 + FileTitle.ReadInt16(26) + FileTitle.ReadInt16(28) + RecordWasFound.CompressedSize;
		Difference = CorrectSize - Size;
		If Difference > 0 Then
			FileOffset = RecordWasFound.FileOffset + Size;
			Size = CorrectSize;
			ReaderStream.Close();
			DataWriter = New DataWriter(TimeFile, , , , True);
			DataWriter.WriteBinaryDataBuffer(ReadIntoBinaryDataBuffer(ArchiveData, FileOffset, Difference));
			DataWriter.Close();
			ReaderStream = FileStreams.OpenForRead(TimeFile);
		EndIf;
		
		If Size > MaximumFileSizeInMemory() Then 
			ArchiveName = GetTempFileName("zip");
		Else
			TemporaryBuffer = New BinaryDataBuffer(Size + RecordWasFound.Buffer.Size + 22);
			ArchiveName = New MemoryStream(TemporaryBuffer);
		EndIf;
		
		DataWriter = New DataWriter(ArchiveName);
		
		// The data itself
		ReaderStream.CopyTo(DataWriter.TargetStream());
		
		ReaderStream.Close();
		DeleteFiles(TimeFile);
	
	Else
	
		FileTitle = GetBytes(ArchiveData.Source, RecordWasFound.FileOffset + ArchiveData.Offset, 30);
		Size = 30 + FileTitle.ReadInt16(26) + FileTitle.ReadInt16(28) + RecordWasFound.CompressedSize;
		
		If Size > MaximumFileSizeInMemory() Then 
			ArchiveName = GetTempFileName("zip");
		Else
			TemporaryBuffer = New BinaryDataBuffer(Size + RecordWasFound.Buffer.Size + 22);
			ArchiveName = New MemoryStream(TemporaryBuffer);
		EndIf;
			
		DataWriter = New DataWriter(ArchiveName);
	
		// The data itself
		ArchiveData.Source.Seek(RecordWasFound.FileOffset + ArchiveData.Offset, PositionInStream.Begin);
		ArchiveData.Source.CopyTo(DataWriter.TargetStream(), Size);
		
	EndIf;
	
	
	// Central Directory Entry
	DirectoryEntry = RecordWasFound.Buffer.Copy();
	DirectoryEntry.WriteInt32(42, 0);
	DataWriter.WriteBinaryDataBuffer(DirectoryEntry);
	
	DirectoryOffset = Size;
	FolderSize = RecordWasFound.RecordLength;
	If DirectoryOffset > NumberFromHexString("0xFFFFFFFF") Then
		
		// EndOfDirectory64
		Buffer = NewEndOfDirectory64(1, FolderSize, DirectoryOffset);
		OffsetEndOfDirectory64 = DirectoryOffset + FolderSize;
		DataWriter.WriteBinaryDataBuffer(Buffer, 0, Buffer.Size);
		
		// Locator64
		Buffer = NewLocator64(OffsetEndOfDirectory64);
		DataWriter.WriteBinaryDataBuffer(Buffer, 0, Buffer.Size);
		
		DirectoryOffset = NumberFromHexString("0xFFFFFFFF");
		
	EndIf;
	
	// End of the central catalog
	EndOfDirectory = NewEndOfDirectory(1, FolderSize, DirectoryOffset);
	DataWriter.WriteBinaryDataBuffer(EndOfDirectory);
	
	// The archive is ready
	DataWriter.Close();
	DataWriter = Undefined;
	
	If TypeOf(ArchiveName) <> Type("String") Then 
		ArchiveName.Seek(0, PositionInStream.Begin);
	EndIf;
	
	// Archive Extraction;
	ZIPReader = New ZipFileReader(ArchiveName);
	ZIPReader.ExtractAll(Directory, ZIPRestoreFilePathsMode.Restore);
	ZIPReader.Close();
	
	If TypeOf(ArchiveName) = Type("String") Then
		DeleteFiles(ArchiveName);
	Else 
		ArchiveName.Close();
		ArchiveName = Undefined;
	EndIf;
	
	Return True;
	
EndFunction

// Read the file
// 
// Parameters: 
// 	ArchiveData - See ZIPArchives.ReadArchive
//  FileName - String
// 
// Returns: 
//   BinaryData, Undefined - Read the file
Function ReadFile(ArchiveData, FileName) Export
	
	// Archive Extraction;
	ArchiveDirectory = GetTempFileName("unzip");
	If Not ExtractFile(ArchiveData, FileName, ArchiveDirectory) Then
		Return Undefined;
	EndIf;
	
	DataReader = New DataReader(ArchiveDirectory + GetPathSeparator() + FileName);
	FileData = DataReader.Read().GetBinaryData();
	DataReader.Close();
	
	DeleteFiles(ArchiveDirectory);
	
	Return FileData;
	
EndFunction

// Find an Entry
// 
// Parameters:
// 	ArchiveData - See ZIPArchives.ReadArchive
//  FileName - String
// 
// Returns:
//  Undefined, Structure - See ReadDirectoryEntry
Function FindRecord(ArchiveData, FileName) Export
	
	Offset = ArchiveData.FileOffsetsInDirectory.Get(FileName);
	
	If Offset <> Undefined Then
		
		Return ReadDirectoryEntry(ArchiveData.DirectoryEntries, Offset);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Private

// @unavailable-in-safemode
Function ReadArchiveInside(Val Source, Val Offset = 0, Val Size = Undefined)

	ArchiveData = New Structure;
	ArchiveData.Insert("Source", Source);
	ArchiveData.Insert("Offset", Offset);
	
	If TypeOf(Source) = Type("UUID") Then
		FullSize = SaaSOperations.GetFileSizeFromServiceManagerStorage(Source);
		If FullSize = Undefined Then
			Raise NStr("vi = 'Không thể đọc tệp nén';
						|ru = 'Не удалось прочитать архив';
						|en = 'Cannot read archive'; fa = 'Cannot read archive';
						|it = 'Impossibile leggere l''archivio';
						|pl = 'Nie udało się odczytać archiwum';
						|tr = 'Arşiv okunamadı'");
		EndIf;
		
		ServiceManagerURL = SaaSOperations.InternalServiceManagerURL();
		SetPrivilegedMode(True);
		AccessParameters = New Structure;
		AccessParameters.Insert("URL", ServiceManagerURL);
		AccessParameters.Insert("UserName", SaaSOperations.ServiceManagerInternalUserName());
		AccessParameters.Insert("Password", SaaSOperations.ServiceManagerInternalUserPassword());
		AccessParameters.Insert("Cache", New Map);
		SetPrivilegedMode(False);
		If Not ValueIsFilled(ServiceManagerURL) Then
			Raise NStr("vi = 'Chưa đặt tham số liên hệ với người quản lý dịch vụ.';
						|ru = 'Не установлены параметры связи с менеджером сервиса.';
						|en = 'Service manager connection parameters are not specified.'; fa = 'Service manager connection parameters are not specified.';
						|it = 'Le impostazioni di comunicazione con il gestore del servizio non sono state impostate.';
						|pl = 'Nie są ustanowione parametry połączenia z menedżerem serwisu.';
						|tr = 'Servis yöneticisiyle bağlantı parametreleri ayarlanmamış.'");
		EndIf;
		If Not Common.SubsystemExists("CloudTechnology.DataTransfer") 
			Or Common.GetInterfaceVersions(AccessParameters, "DataTransfer").Count() = 0 Then
			Raise NStr("vi = 'Không thể nhận dữ liệu từ bộ quản lý dịch vụ.';
						|ru = 'Получение данных из менеджера сервиса невозможно.';
						|en = 'Cannot get data from the service manager.'; fa = 'Cannot get data from the service manager.';
						|it = 'Получение данных из менеджера сервиса невозможно.';
						|pl = 'Cannot get data from the service manager.';
						|tr = 'Servis yöneticisinin verileri alınamıyor.'");
		EndIf;
		ArchiveData.Insert("AccessParameters", AccessParameters);
	
	ElsIf TypeOf(Source) = Type("FileStream") Or TypeOf(Source) = Type("MemoryStream") Then 
		FullSize = Source.Size(); 
	Else
		Raise NStr("vi = 'Kiểu nguồn không xác định';
					|ru = 'Неизвестный тип источника';
					|en = 'Unknown source type'; fa = 'Unknown source type';
					|it = 'Tipo di fonte sconosciuto';
					|pl = 'Nieznany typ źródła';
					|tr = 'Bilinmeyen kaynak türü'");
	EndIf;
	
	If Size = Undefined Then
		Size = FullSize;
	ElsIf (Offset + Size - 1) > FullSize Then
		Raise NStr("vi = 'Dung lượng không chính xác';
					|ru = 'Некорректный размер';
					|en = 'Incorrect size'; fa = 'Incorrect size';
					|it = 'Dimensione errata';
					|pl = 'Niepoprawny rozmiar';
					|tr = 'Hatalı boyut'");
	EndIf;
	
	ArchiveData.Insert("Size", Size);
	
	EndOfDirectory = ReadEndOfDirectory(ArchiveData);
	ArchiveData.Insert("EndOfDirectory", EndOfDirectory);
	
	If EndOfDirectory.DirectoryOffset = NumberFromHexString("0xFFFFFFFF") 
		Or EndOfDirectory.NumberOfRecordsTotal = NumberFromHexString("0xFFFF") Then
		Locator64 = ReadLocator64(ArchiveData, ArchiveData.Size - EndOfDirectory.Buffer.Size);
		EndOfDirectory64 = ReadEndOfDirectory64(ArchiveData, Locator64.Offset);
		DirectoryEntries = ReadDirectoryEntries(ArchiveData, EndOfDirectory64.DirectoryOffset, EndOfDirectory64.FolderSize);
	Else
		DirectoryEntries = ReadDirectoryEntries(ArchiveData, EndOfDirectory.DirectoryOffset, EndOfDirectory.FolderSize);
	EndIf;
	
	ArchiveData.Insert("DirectoryEntries", DirectoryEntries);
	ArchiveData.Insert("FileOffsetsInDirectory", FileOffsetsInDirectory(DirectoryEntries));
	
	Return ArchiveData;
	
EndFunction

Function FileOffsetsInDirectory(DirectoryEntries)
	
	FileOffsetsInDirectory = New Map;
	
	Offset = 0;
	Size = DirectoryEntries.Size;
	
	While Offset < Size Do
		
		If DirectoryEntries.ReadInt32(Offset) <> 33639248 Then
			Raise NStr("vi = 'Sai định dạng';
						|ru = 'Неверный формат';
						|en = 'Incorrect format'; fa = 'Incorrect format';
						|it = 'Неверный формат';
						|pl = 'Błędny format';
						|tr = 'Hatalı format'");
		EndIf;
	
		FileNameLength = DirectoryEntries.ReadInt16(Offset + 28);
		LengthOfAdditionalData = DirectoryEntries.ReadInt16(Offset + 30);
		CommentLength = DirectoryEntries.ReadInt16(Offset + 32);
		RecordLength = 46 + FileNameLength + LengthOfAdditionalData + CommentLength;
		
		CrossSection = DirectoryEntries.GetSlice(Offset + 46, FileNameLength);
		FileName = GetStringFromBinaryDataBuffer(CrossSection);
		
		FileOffsetsInDirectory.Insert(FileName, Offset);
		
		Offset = Offset + RecordLength;
		
	EndDo;
	
	Return FileOffsetsInDirectory;

EndFunction

// Parameters: 
//  RecordsCount - Number
//  FolderSize - Number
//  DirectoryOffset - Number
// 
// Returns: 
//  BinaryDataBuffer
Function NewEndOfDirectory(RecordsCount, FolderSize, DirectoryOffset)
	
	Buffer = New BinaryDataBuffer(22);
	Buffer.WriteInt32(0, NumberFromHexString("0x06054b50")); // end of central dir signature
	Buffer.WriteInt16(4, 0); // number of this disk
	Buffer.WriteInt16(6, 0); // number of the disk with the start of the central directory
	Buffer.WriteInt16(8, Min(RecordsCount, 65535)); // total number of entries in the central directory on this disk
	Buffer.WriteInt16(10, Min(RecordsCount, 65535)); // total number of entries in  the central directory
	Buffer.WriteInt32(12, FolderSize); // size of the central directory
	Buffer.WriteInt32(16, DirectoryOffset); // offset of start of central directory with respect to the starting disk number
	Buffer.WriteInt16(20, 0); // .ZIP file comment length
	
	Return Buffer;
	
EndFunction

// Parameters: 
//  TotalRecords - Number
//  FolderSize - Number
//  DirectoryOffset - Number
// 
// Returns: 
//  BinaryDataBuffer
Function NewEndOfDirectory64(TotalRecords, FolderSize, DirectoryOffset)
	
	Buffer = New BinaryDataBuffer(56);
	Buffer.WriteInt32(0, NumberFromHexString("0x06064b50")); // zip64 end of central dir signature  
	Buffer.WriteInt64(4, 56 - 12); // size of zip64 end of central directory record 
	Buffer.WriteInt16(12, 45); // version made by
	Buffer.WriteInt16(14, 45); // version needed to extract
	Buffer.WriteInt32(16, 0); // number of this disk
	Buffer.WriteInt32(20, 0); // number of the disk with the start of the central directory
	Buffer.WriteInt64(24, TotalRecords); //total number of entries in the central directory on this disk
	Buffer.WriteInt64(32, TotalRecords); // total number of entries in the central directory
	Buffer.WriteInt64(40, FolderSize); // size of the central directory
	Buffer.WriteInt64(48, DirectoryOffset); // offset of start of central directory with respect to the starting disk number
	Return Buffer;
	
EndFunction

// Parameters: 
//  OffsetEndOfDirectory64 - Number
// 
// Returns: 
//  BinaryDataBuffer
Function NewLocator64(OffsetEndOfDirectory64)
	
	Buffer = New BinaryDataBuffer(20);
	Buffer.WriteInt32(0, NumberFromHexString("0x07064b50")); // zip64 end of central dir locator signature
	Buffer.WriteInt32(4, 0); // number of the disk with the start of the zip64 end of central directory
	Buffer.WriteInt64(8, OffsetEndOfDirectory64); // relative offset of the zip64 end of central directory record
	Buffer.WriteInt32(16, 1); // total number of disks
	
	Return Buffer;
	
EndFunction

// Parameters:
// 	Buffer - BinaryDataBuffer
// 	Offset - Number
// 	
// Returns:
// 	Structure:
// * Buffer - BinaryDataBuffer
// * CompressionMethod - Number
// * CompressedSize - Number
// * UncompressedSize - Number
// * FileOffset - Number
// * RecordLength - Number
// * FileName - String
//
Function ReadDirectoryEntry(Buffer, Offset)
	
	DirectoryEntry = Buffer;
	
	// The number of the hexadecimal string("0x02014b50") = 33639248
	If DirectoryEntry.ReadInt32(Offset) <> 33639248 Then
		Raise NStr("vi = 'Định dạng không chính xác';
					|ru = 'Неверный формат';
					|en = 'Incorrect format'; fa = 'Incorrect format';
					|it = 'Il formato non è valido';
					|pl = 'Błędny format';
					|tr = 'Hatalı format'");
	EndIf;
	
	FileNameLength = DirectoryEntry.ReadInt16(Offset + 28);
	LengthOfAdditionalData = DirectoryEntry.ReadInt16(Offset + 30);
	CommentLength = DirectoryEntry.ReadInt16(Offset + 32);
	RecordLength = 46 + FileNameLength + LengthOfAdditionalData + CommentLength;
	
	Data = New Structure;	
	Data.Insert("Buffer", DirectoryEntry.Read(Offset, RecordLength));
	Data.Insert("CompressionMethod", DirectoryEntry.ReadInt16(Offset + 10));
	Data.Insert("CompressedSize", DirectoryEntry.ReadInt32(Offset + 20));
	Data.Insert("UncompressedSize", DirectoryEntry.ReadInt32(Offset + 24));	
	Data.Insert("FileOffset", DirectoryEntry.ReadInt32(Offset + 42));
	Data.Insert("RecordLength", RecordLength);
	
	If Data.UncompressedSize = 4294967295 Or Data.FileOffset = 4294967295 Or Data.CompressedSize = 4294967295 Then
		
		If LengthOfAdditionalData = 0 Then
			Raise NStr("vi = 'Định dạng không chính xác';
						|ru = 'Неверный формат';
						|en = 'Incorrect format'; fa = 'Incorrect format';
						|it = 'Il formato non è valido';
						|pl = 'Błędny format';
						|tr = 'Hatalı format'");
		EndIf;
		
		For Each Additional_Data In ParseAdditionalData(DirectoryEntry.Read(Offset + 46 + FileNameLength, LengthOfAdditionalData)) Do 
			If Additional_Data.Type = NumberFromHexString("0x0001") Then
				Buffer64 = Additional_Data.Data;
				IndexOf64 = 0;
				If Data.UncompressedSize = 4294967295 Then
					Data.UncompressedSize = Buffer64.ReadInt64(IndexOf64);
					IndexOf64 = IndexOf64 + 8;
				EndIf;
				If Data.CompressedSize = 4294967295 Then
					Data.CompressedSize = Buffer64.ReadInt64(IndexOf64);
					IndexOf64 = IndexOf64 + 8;
				EndIf;
				If Data.FileOffset = 4294967295 Then
					Data.FileOffset = Buffer64.ReadInt64(IndexOf64);
					IndexOf64 = IndexOf64 + 8;
				EndIf;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Data.Insert("FileName", GetStringFromBinaryDataBuffer(DirectoryEntry.GetSlice(Offset + 46, FileNameLength))); // We use only the Latin alphabet
	
	Return Data;
	
EndFunction

// Reads the end of the directory from the stream
// 
// Parameters:
// 	ArchiveData - See ZIPArchives.ReadArchive
// Returns:
// 	Structure - LongDesc:
//   * DiskNumber - Number
//   * DiskStart - Number
//   * NumberOfRecordsOnDisk - Number
//   * NumberOfRecordsTotal - Number
//   * FolderSize - Number
//   * DirectoryOffset - Number
//   * CommentLength - Number
//   * Buffer - BinaryDataBuffer
Function ReadEndOfDirectory(ArchiveData)
	
	EndOfDirectory = ReadIntoBinaryDataBuffer(ArchiveData, ArchiveData.Size - 22, 22);
	If EndOfDirectory.ReadInt32(0) <> NumberFromHexString("0x06054b50") Then
		Raise NStr("vi = 'Tệp không phải là tệp nén zip';
					|ru = 'Файл не является zip архивом';
					|en = 'File is not a ZIP archive'; fa = 'File is not a ZIP archive';
					|it = 'File non è in formato zip';
					|pl = 'Plik nie jest archiwum zip';
					|tr = 'Dosya zip arşivi değil'");
	EndIf;
	
	Data = New Structure;
		
	Data.Insert("DiskNumber", EndOfDirectory.ReadInt16(4));
	Data.Insert("DiskStart", EndOfDirectory.ReadInt16(6));
	Data.Insert("NumberOfRecordsOnDisk", EndOfDirectory.ReadInt16(8));
	Data.Insert("NumberOfRecordsTotal", EndOfDirectory.ReadInt16(10));
	Data.Insert("FolderSize", EndOfDirectory.ReadInt32(12));
	Data.Insert("DirectoryOffset", EndOfDirectory.ReadInt32(16));
	Data.Insert("CommentLength", EndOfDirectory.ReadInt16(20));
	Data.Insert("Buffer", EndOfDirectory);
	
	Return Data;
	
EndFunction

Function ReadEndOfDirectory64(ArchiveData, Begin)
	
	EndOfDirectory = ReadIntoBinaryDataBuffer(ArchiveData, Begin, 56);
	If EndOfDirectory.ReadInt32(0) <> NumberFromHexString("0x06064b50") Then
		Raise NStr("vi = 'Tệp không phải là tệp nén zip';
					|ru = 'Файл не является zip архивом';
					|en = 'File is not a ZIP archive'; fa = 'File is not a ZIP archive';
					|it = 'File non è in formato zip';
					|pl = 'Plik nie jest archiwum zip';
					|tr = 'Dosya zip arşivi değil'");
	EndIf;
	
	Data = New Structure;
	Data.Insert("SizeEndOfDirectory64", EndOfDirectory.ReadInt64(4));
	Data.Insert("MadeByVersion", EndOfDirectory.ReadInt16(12));
	Data.Insert("VersionRequired", EndOfDirectory.ReadInt16(14));
	Data.Insert("DiskNumber", EndOfDirectory.ReadInt32(16));
	Data.Insert("DiskNumber2", EndOfDirectory.ReadInt32(20));
	Data.Insert("NumberOfRecordsOnThisDisk", EndOfDirectory.ReadInt64(24));
	Data.Insert("TotalRecords", EndOfDirectory.ReadInt64(32));
	Data.Insert("FolderSize", EndOfDirectory.ReadInt64(40));
	Data.Insert("DirectoryOffset", EndOfDirectory.ReadInt64(48));
	Data.Insert("Buffer", EndOfDirectory);
	
	// Bypass for problematic archives (see MC-7278), you can delete it only after a long time.
	Data.FolderSize = Begin - Data.DirectoryOffset;
	
	Return Data;
	
EndFunction

Function GetBytes(Stream, Begin, Size)
	
	Stream.Seek(Begin, PositionInStream.Begin);
	Buffer = New BinaryDataBuffer(Size);
	If Stream.Read(Buffer, 0, Size) <> Size Then
		Raise "Wrong_ cellsize";
	EndIf;
	
	Return Buffer;
	
EndFunction

Function ReadToFileFromVolume(ArchiveData, Begin, Size)
	
	Span = New Structure("Begin, End", Begin + ArchiveData.Offset, Begin + Size - 1 + ArchiveData.Offset);
	Result = DataTransferServer.GetFromLogicalStorage(ArchiveData.AccessParameters, "files", ArchiveData.Source, Span);
	If Result = Undefined Then
		Raise NStr("vi = 'Không thể nhận dữ liệu từ bộ quản lý dịch vụ';
					|ru = 'Не удалось получить данные из менеджера сервиса';
					|en = 'Cannot get data from service manager'; fa = 'Cannot get data from service manager';
					|it = 'Impossibile ricevere dati dal manager service';
					|pl = 'Nie udało się otrzymać danych z menedżera serwisu';
					|tr = 'Servis yöneticisinden veri alınamadı'");
	EndIf;
	Return Result.FullName;
	
EndFunction

Function ReadIntoBinaryDataBuffer(ArchiveData, Begin, Size)
	
	If TypeOf(ArchiveData.Source) = Type("UUID") Then
		FileName = ReadToFileFromVolume(ArchiveData, Begin, Size);
		BinaryData = New BinaryData(FileName);
		DeleteFiles(FileName);
		Return GetBinaryDataBufferFromBinaryData(BinaryData);
	Else
		Return GetBytes(ArchiveData.Source, Begin + ArchiveData.Offset, Size);
	EndIf;
	
EndFunction

Function ReadDirectoryEntries(ArchiveData, Begin, Size)
	
	Return ReadIntoBinaryDataBuffer(ArchiveData, Begin, Size);
	
EndFunction

Function ReadLocator64(ArchiveData, End)
	
	Locator = ReadIntoBinaryDataBuffer(ArchiveData, End - 20, 20);
	If Locator.ReadInt32(0) <> NumberFromHexString("0x07064b50") Then
		Raise NStr("vi = 'Tệp không phải là tệp nén zip';
					|ru = 'Файл не является zip архивом';
					|en = 'File is not a ZIP archive'; fa = 'File is not a ZIP archive';
					|it = 'File non è in formato zip';
					|pl = 'Plik nie jest archiwum zip';
					|tr = 'Dosya zip arşivi değil'");
	EndIf;
	
	Data = New Structure;
	Data.Insert("DiskNumber", Locator.ReadInt32(4));
	Data.Insert("Offset", Locator.ReadInt64(8));
	Data.Insert("TotalDisks", Locator.ReadInt32(16));
	Data.Insert("Buffer", Locator);
	
	Return Data;
	
EndFunction

// Parameters:
// 	BinaryDataBuffer - BinaryDataBuffer
// 	
// Returns:
// 	Array of Structure:
//	* Type - Number
//	* Data - BinaryDataBuffer
//
Function ParseAdditionalData(BinaryDataBuffer)
	
	Additional_Data = New Array;
	
	IndexOf = 0;
	While IndexOf < BinaryDataBuffer.Size Do
		
		Type = BinaryDataBuffer.ReadInt16(IndexOf);
		Size = BinaryDataBuffer.ReadInt16(IndexOf + 2);
		If Size > 0 Then
			Data = BinaryDataBuffer.Read(IndexOf + 4, Size);
		Else
			Data = Undefined;
		EndIf;
		
		Additional_Data.Add(New Structure("Type, Data", Type, Data));
		IndexOf = IndexOf + 4 + Size;
		
	EndDo;
	
	Return Additional_Data;
	
EndFunction

Function CollectAdditionalData(Additional_Data)
	
	Size = 0;
	For Each Data In Additional_Data Do
		Size = Size + 4 + Data.Data.Size;
	EndDo;
	
	Buffer = New BinaryDataBuffer(Size);
	Offset = 0;
	For Each Data In Additional_Data Do
		Buffer.WriteInt16(Offset, Data.Type);
		Buffer.WriteInt16(Offset + 2, Data.Data.Size);
		Buffer.Write(Offset + 4, Data.Data);
		Offset = Offset + 4 + Data.Data.Size;		
	EndDo;
	
	Return Buffer;
	
EndFunction

Function MaximumFileSizeInMemory()
	
	Return 10 * 1024 * 1024;
	
EndFunction

#EndRegion
