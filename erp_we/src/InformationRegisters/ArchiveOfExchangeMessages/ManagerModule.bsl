///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure PackMessageToArchive(InfobaseNode, PathToSourceFile) Export
	
	If Not ValueIsFilled(InfobaseNode) Then
		Return;
	EndIf;
	
	SSLExchangePlans = DataExchangeCached.SSLExchangePlans();
	If SSLExchangePlans.Find(InfobaseNode.Metadata().Name) = Undefined Then
		Return;
	EndIf;
	
	Settings = InformationRegisters.ExchangeMessageArchiveSettings.GetSettings(InfobaseNode);
	
	If Settings = Undefined Or Settings.FilesCount = 0 Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		PutToArchive(InfobaseNode, PathToSourceFile, Settings);
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(EventLogEventMessagePutToArchive(),
			EventLogLevel.Error, , , ErrorMessage);
		
		ReasonText = NStr("vi = 'Chưa sắp xếp tệp vào lưu trữ.';
							|ru = 'Файл не был помещен в архив.';
							|en = 'The file was not archived.'; fa = 'The file was not archived.';
							|it = 'Файл не был помещен в архив.';
							|pl = 'The file was not archived.';
							|tr = 'Dosya arşivlenmedi.'") + Chars.LF + ErrorMessage;
		
		WriteParameters = New Structure;
		WriteParameters.Insert("InfobaseNode", InfobaseNode);
		WriteParameters.Insert("Cause", ReasonText);
		WriteParameters.Insert("IssueType", Enums.DataExchangeIssuesTypes.IsExchangeMessageOutsideOfArchive);
		InformationRegisters.DataExchangeResults.AddAnEntryAboutTheResultsOfTheExchange(WriteParameters);
		
	EndTry;
	
EndProcedure 

#EndRegion

#Region Private

Procedure PutToArchive(InfobaseNode, PathToSourceFile, Settings)

	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ArchiveOfExchangeMessages");
	LockItem.SetValue("InfobaseNode", InfobaseNode);
	Block.Lock();
	
	Set = InformationRegisters.ArchiveOfExchangeMessages.CreateRecordSet();
	Set.Filter.InfobaseNode.Set(InfobaseNode);
	Set.Read();
	
	RecordsCount = Set.Count();
	For Cnt = 1 To RecordsCount Do
		
		IndexOf = RecordsCount - Cnt;
		Record = Set[IndexOf];
		If Record.IsFileExceeds100MB Then
			Set.Delete(IndexOf);
		EndIf;
		
	EndDo;
	
	For Cnt = 1 To Set.Count() - Settings.FilesCount + 1 Do
		
		Record = Set.Get(0);
		
		If Record.FullFileName <> "" Then
			DeleteFiles(Record.FullFileName);
		EndIf;
			
		Set.Delete(0);
		
	EndDo;
		
	If StrEndsWith(Lower(PathToSourceFile), "zip") Then
		FileExtention = "zip";
	Else
		FileExtention = "xml";
	EndIf;
	
	HashAmountOfExchangeMessages = "";
	
	If FileExtention = "zip" Then
		TempDirectoryName = GetTempFileName("");
		
		If DataExchangeServer.UnpackZipFile(PathToSourceFile, TempDirectoryName) Then
			UnpackedFileList = FindFiles(TempDirectoryName, GetAllFilesMask(), True);
			
			If UnpackedFileList.Count() Then
				BinaryDataExchangeMessages = New BinaryData(UnpackedFileList[0].FullName);
				HashAmountOfExchangeMessages = DataExchangeServer.HashAmountOfExchangeMessage(BinaryDataExchangeMessages);
			EndIf;
		EndIf; 
		
		DeleteFiles(TempDirectoryName);
	Else
		BinaryDataExchangeMessages = New BinaryData(PathToSourceFile);
		HashAmountOfExchangeMessages = DataExchangeServer.HashAmountOfExchangeMessage(BinaryDataExchangeMessages);
	EndIf;
	
	DeleteFileAfterPut = False;
	If Settings.ShouldCompressFiles And FileExtention <> "zip" Then
		
		DeleteFileAfterPut = True;
		FileExtention = "zip";
		FileName = GetTempFileName(FileExtention);
		
		DataExchangeServer.PackIntoZipFile(FileName, PathToSourceFile);
		
	Else
		
		FileName = PathToSourceFile;
		
	EndIf;
	
	File = New File(FileName);
	FileSize = File.Size() / (1024 * 1024); 
	
	Template = "%1_%2_%3";
	FileNameInArchive = StrTemplate(Template, 
		InfobaseNode.Code,
		InfobaseNode.ReceivedNo,
		String(New UUID));
	
	NewArchive = Set.Add();
	NewArchive.InfobaseNode = InfobaseNode;
	NewArchive.Period = CurrentSessionDate();
	NewArchive.ReceivedMessageNumber = InfobaseNode.ReceivedNo;
	NewArchive.FileSize = FileSize;
	NewArchive.FileName = FileNameInArchive;
	NewArchive.FileExtention = FileExtention;
	NewArchive.TheHashSumOfTheFile = HashAmountOfExchangeMessages;
	
	If Settings.StoreOnDisk Then
		
		Template = "%1%2.%3";
		
		FolderName = Settings.FullPath;
				
		FullFilenameInFolder = StringFunctions.FormattedString(Template,
			FolderName,
			FileNameInArchive,
			FileExtention);
			
		CopyFile(FileName, FullFilenameInFolder);
		NewArchive.FullFileName = FullFilenameInFolder;
			
	Else
				
		If Common.DataSeparationEnabled() And FileSize > 100 Then
			
			NewArchive.IsFileExceeds100MB = True;
			
			Cause = NStr("vi = 'Thông báo trao đổi lớn hơn 100 Mb. Không thể sắp xếp tệp vào lưu trữ.';
						|ru = 'Сообщение обмена больше 100 Мб. Файл не был помещен в архив.';
						|en = 'Exchange message larger than 100 MB. The file is not placed to the archive.'; fa = 'Exchange message larger than 100 MB. The file is not placed to the archive.';
						|it = 'Messaggio di scambio superiore a 100 Mb. Il file non è stato salvato in archivio.';
						|pl = 'Wiadomość wymiany ponad 100 MB. Plik nie został zarchiwizowany.';
						|tr = 'Değişim mesajı 100 Mb''tan büyük. Dosya arşivlenmedi.'");
			WriteParameters = New Structure;
			WriteParameters.Insert("InfobaseNode", InfobaseNode);
			WriteParameters.Insert("Cause", Cause);
			WriteParameters.Insert("IssueType", Enums.DataExchangeIssuesTypes.IsExchangeMessageOutsideOfArchive);
			InformationRegisters.DataExchangeResults.AddAnEntryAboutTheResultsOfTheExchange(WriteParameters);
	
		Else
			
			NewArchive.Storage = New ValueStorage(New BinaryData(FileName));
			
		EndIf;
		
	EndIf;
	
	If DeleteFileAfterPut Then
		DeleteFiles(FileName);
	EndIf;
    
	Set.Write();
	
EndProcedure

Function EventLogEventMessagePutToArchive()
	
	Return NStr("vi = 'Trao đổi dữ liệu.Sắp xếp thông báo vào lưu trữ';
				|ru = 'Обмен данными.Помещение сообщения в архив';
				|en = 'Data exchange.Place message to archive'; fa = 'Data exchange.Place message to archive';
				|it = 'Scambio dati.Salvataggio del messaggio nell''archivio';
				|pl = 'Wymiana danych.Archiwizacja wiadomości';
				|tr = 'Veri değişimi.Mesajı arşivle'", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndIf