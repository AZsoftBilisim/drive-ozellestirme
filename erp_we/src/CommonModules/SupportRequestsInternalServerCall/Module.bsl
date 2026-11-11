///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function IsOperationsWithExternalResourcesAvailable() Export
	
	Return Not ScheduledJobsServer.OperationsWithExternalResourcesLocked();
	
EndFunction

Function TechnicalInformationArchiveAddress(Val RequestParameters_) Export
	
	TempDirectory = FileSystem.CreateTemporaryDirectory();
	FilesAddresses = TechnicalInfoFilesAddresses(RequestParameters_);
	
	AddTechnicalInfoFileToTempDirectory(
		FilesAddresses.TechnologicalInfo,
		NStr("vi = 'Thông tin kỹ thuật.txt';
			|ru = 'Технологическая информация.txt';
			|en = 'Technical information.txt'; fa = 'Technical information.txt';
			|it = 'Technical information.txt';
			|pl = 'Technical information.txt';
			|tr = 'Teknik bilgi.txt'"),
		TempDirectory);
	
	AddTechnicalInfoFileToTempDirectory(
		FilesAddresses.EventLog,
		NStr("vi = 'Nhật ký sự kiện.xml';
			|ru = 'Журнал регистрации.xml';
			|en = 'Event log.xml'; fa = 'Event log.xml';
			|it = 'Event log.xml';
			|pl = 'Event log.xml';
			|tr = 'Olay günlüğü.xml'"),
		TempDirectory);
	
	For Each AdditionalFile In RequestParameters_.AdditionalFiles Do
		AddTechnicalInfoFileToTempDirectory(
			AdditionalFile.FileAddress,
			AdditionalFile.FullFileName,
			TempDirectory);
	EndDo;
	
	TechnicalInfoArchive = New ZipFileWriter();
	TechnicalInfoArchive.Add(TempDirectory);
	
	ArchiveData = TechnicalInfoArchive.GetBinaryData();
	Result = PutToTempStorage(ArchiveData, New UUID);
	
	FileSystem.DeleteTemporaryDirectory(TempDirectory);
	
	Return Result;
	
EndFunction

Function TechnicalInfoFilesAddresses(Val RequestParameters_) Export
	
	Result = New Structure("TechnologicalInfo, EventLog");
	Result.TechnologicalInfo = AddressTechnologicalInfo(RequestParameters_.TechnologicalInfo);
	Result.EventLog = EventLogAddress(RequestParameters_.EventLogFilter);
	
	Return Result;
	
EndFunction

Function AddressTechnologicalInfo(TechnologicalInfo)
	
	TempFileName = GetTempFileName("txt");
	
	SupportInformationText = New TextDocument;
	SupportInformationText.SetText(TechnologicalInfo);
	SupportInformationText.Write(TempFileName);
	
	Result = PutToTempStorage(New BinaryData(TempFileName), New UUID);
	
	DeleteFiles(TempFileName);
	
	Return Result;
	
EndFunction

Function EventLogAddress(EventLogFilter)
	
	SecondsBeforeEventsStart = 600;
	
	If EventLogFilter.Property("StartDate") Then // ACC:1415 - A dynamic property set.
		StartDate = EventLogFilter.StartDate - SecondsBeforeEventsStart;
	Else
		StartDate = CurrentSessionDate() - SecondsBeforeEventsStart;
	EndIf;
	
	EventLogFilter.Insert("StartDate", StartDate);
	EventLogFilter.Insert("User", InfoBaseUsers.CurrentUser());
	
	EventCount1 = 100;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Result = EventLog.TechnicalSupportLog(EventLogFilter, EventCount1);
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Return Result;
	
EndFunction

Function AddressOfScreenshot(Val Screenshot) Export
	
	Return PutToTempStorage(Screenshot.GetBinaryData(), New UUID);
	
EndFunction

Procedure AddTechnicalInfoFileToTempDirectory(FileAddress, FileName, TempDirectory)
	
	BinaryData = GetFromTempStorage(FileAddress);
	BinaryData.Write(TempDirectory + FileName);
	
	DeleteFromTempStorage(FileAddress);
	
EndProcedure

#EndRegion
