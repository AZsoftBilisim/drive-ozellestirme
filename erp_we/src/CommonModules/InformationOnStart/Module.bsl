///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// The function updates subsystem data considering the application mode.
//   Usage example: after clearing settings storage.
//
// Parameters:
//   Settings - Structure:
//       * SharedData       - Boolean - Optional. Update shared data.
//       * SeparatedData - Boolean - Optional. Update separated data.
//       * Nonexclusive - Boolean - Optional. Real-time data update.
//       * Deferred2  - Boolean - Optional. Deferred data update.
//       * Full      - Boolean - Optional. Ignore hash during the deferred data update.
//
Function Refresh(Settings = Undefined) Export
	
	If Settings = Undefined Then
		Settings = New Structure;
	EndIf;
	
	Default = New Structure("SharedData, SeparatedData, Nonexclusive, Deferred2, Full");
	If Settings.Count() < Default.Count() Then
		If Common.DataSeparationEnabled() Then
			If Common.SeparatedDataUsageAvailable() Then
				Default.SharedData       = False;
				Default.SeparatedData = True;
			Else // Shared session.
				Default.SharedData       = True;
				Default.SeparatedData = False;
			EndIf;
		Else
			If Common.IsStandaloneWorkplace() Then // Standalone workstation.
				Default.SharedData       = False;
				Default.SeparatedData = True;
			Else // On-prem.
				Default.SharedData       = True;
				Default.SeparatedData = True;
			EndIf;
		EndIf;
		Default.Nonexclusive  = True;
		Default.Deferred2   = False;
		Default.Full       = False;
		CommonClientServer.SupplementStructure(Settings, Default, False);
	EndIf;
	
	Result = New Structure;
	Result.Insert("HasChanges", False);
	
	If Settings.Nonexclusive And Settings.SharedData Then
		
		Query = New Query("SELECT * FROM InformationRegister.InformationPackagesOnStart ORDER BY Number");
		TableBeforeUpdate = Query.Execute().Unload();
		
		CommonDataNonexclusiveUpdate();
		
		TableAfterUpdate = Query.Execute().Unload();
		
		If Not Common.DataMatch(TableBeforeUpdate, TableAfterUpdate) Then
			Result.HasChanges = True;
		EndIf;
		
	EndIf;
	
	Return Result;
EndFunction

#Region ConfigurationSubsystemsEventHandlers

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	Handler = Handlers.Add();
	Handler.ExecuteInMandatoryGroup = True;
	Handler.SharedData                  = True;
	Handler.HandlerManagement      = False;
	Handler.ExecutionMode              = "Seamless";
	Handler.Version      = "*";
	Handler.Procedure   = "InformationOnStart.CommonDataNonexclusiveUpdate";
	Handler.Comment = NStr("vi = 'Cập nhật dữ liệu của việc trình bày đầu tiên.';
							|ru = 'Актуализирует данные первого показа.';
							|en = 'Updates data of the first show.'; fa = 'Updates data of the first show.';
							|it = 'Attualizza i dati della prima manifestazione.';
							|pl = 'Aktualizuje dane pierwszego pokazu.';
							|tr = 'İlk görüntüleme verileri etkinleştiriyor.'");
	Handler.Priority   = 100;
EndProcedure

// See InfobaseUpdateSSL.AfterUpdateInfobase.
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, ExclusiveMode) Export
	
	Common.CommonSettingsStorageDelete("InformationOnStart", Undefined, Undefined);
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	Parameters.Insert("InformationOnStart", New FixedStructure(GlobalSettings()));
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

// Updates data of the first show.
Procedure CommonDataNonexclusiveUpdate() Export
	
	UpdateFirstShowCache(DataProcessors.InformationOnStart.Create());
	
EndProcedure

#EndRegion

// Updates data of the first show.
Procedure UpdateFirstShowCache(TemplatesMedia)
	
	// Generate the general information about pages packages.
	PagesPackages = PagesPackages(TemplatesMedia);
	
	// Extract packages data and recording them to the register.
	SetPrivilegedMode(True);
	RecordSet = InformationRegisters.InformationPackagesOnStart.CreateRecordSet();
	For Each Package In PagesPackages Do
		PackageKit = ExtractPackageFiles(TemplatesMedia, Package.TemplateName);
		
		Record = RecordSet.Add();
		Record.Number  = Package.NumberInRegister;
		Record.Content = New ValueStorage(PackageKit, New Deflation(9));
	EndDo;
	
	// Metadata is recorded to the register under number 0.
	Record = RecordSet.Add();
	Record.Number  = 0;
	Record.Content = New ValueStorage(PagesPackages, New Deflation(9));
	
	InfobaseUpdate.WriteData(RecordSet, False, False);
	SetPrivilegedMode(False);
	
EndProcedure

// Global subsystem settings.
Function GlobalSettings()
	Settings = New Structure;
	Settings.Insert("Show", True);
	
	// Disable information in the PROF version if the user cleared the check box.
	Settings.Show = (Metadata.DataProcessors.InformationOnStart.Templates.Count() > 0)
		And (StandardSubsystemsServer.IsBaseConfigurationVersion() Or ShowAtStartup());
	
	If Settings.Show Then
		// Disable information if changes details are displayed.
		If Common.SubsystemExists("StandardSubsystems.IBVersionUpdate") Then
			ModuleUpdatingInfobaseInternal = Common.CommonModule("InfobaseUpdateInternal");
			If ModuleUpdatingInfobaseInternal.ShowChangeHistory1() Then
				Settings.Show = False;
			EndIf;
		EndIf;
	EndIf;
	
	If Settings.Show Then
		// Disable information if the assistant of setting completion of the subordinate DIB node is displayed.
		If Common.SubsystemExists("StandardSubsystems.DataExchange") Then
			ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
			If ModuleDataExchangeServer.OpenDataExchangeCreationWizardForSubordinateNodeSetup() Then
				Settings.Show = False;
			EndIf;
		EndIf;
	EndIf;
	
	If Settings.Show Then
		SetPrivilegedMode(True);
		RegisterRecord = InformationRegisters.InformationPackagesOnStart.Get(New Structure("Number", 0));
		PagesPackages = RegisterRecord.Content.Get();
		SetPrivilegedMode(False);
		If PagesPackages = Undefined Then
			Settings.Show = False;
		Else
			Information = PreparePagesPackageForOutput(PagesPackages, BegOfDay(CurrentSessionDate()));
			If Information.PreparedPackages.Count() = 0
				Or Information.MinPriority = 100 Then
				Settings.Show = False;
			EndIf;
		EndIf;
	EndIf;
	
	InformationOnStartOverridable.DefineSettings(Settings);
	
	Return Settings;
EndFunction

// Read the stored value of the "Show on startup" check box.
Function ShowAtStartup() Export
	Show = Common.CommonSettingsStorageLoad("InformationOnStart", "Show", True);
	If Not Show Then
		NextShowDate = Common.CommonSettingsStorageLoad("InformationOnStart", "NextShowDate");
		If NextShowDate <> Undefined
			And NextShowDate > CurrentSessionDate() Then
			Return False;
		EndIf;
	EndIf;
	Return True;
EndFunction

// Global subsystem settings.
// 
// Returns:
//  ValueTable:
//     * NumberInRegister - Number
//     * Id - String
//     * TemplateName - String
//     * Section - String
//     * StartPageDescription - String
//     * HomePageFileName - String
//     * ShowFrom - Date
//     * ShowTill - Date
//     * Priority - Number
//     * ShowInProf - Boolean
//     * ShowInBasic - Boolean
//     * ShowInSaaS - Boolean
//
Function PagesPackages(TemplatesMedia) Export
	Result = New ValueTable;
	Result.Columns.Add("NumberInRegister",                New TypeDescription("Number"));
	Result.Columns.Add("Id",                 New TypeDescription("String"));
	Result.Columns.Add("TemplateName",                     New TypeDescription("String"));
	Result.Columns.Add("Section",                        New TypeDescription("String"));
	Result.Columns.Add("StartPageDescription", New TypeDescription("String"));
	Result.Columns.Add("HomePageFileName",     New TypeDescription("String"));
	Result.Columns.Add("ShowFrom",              New TypeDescription("Date"));
	Result.Columns.Add("ShowTill",           New TypeDescription("Date"));
	Result.Columns.Add("Priority",                     New TypeDescription("Number"));
	Result.Columns.Add("ShowInProf",               New TypeDescription("Boolean"));
	Result.Columns.Add("ShowInBasic",            New TypeDescription("Boolean"));
	Result.Columns.Add("ShowInSaaS",      New TypeDescription("Boolean"));
	
	NumberInRegister = 0;
	
	// Read the Specifier template.
	If TemplatesMedia.Metadata().Templates.Find("Specifier") = Undefined Then
		Return Result;
	EndIf;
		
	SpreadsheetDocument = TemplatesMedia.GetTemplate("Specifier");
	SpreadsheetDocument.LanguageCode = Common.DefaultLanguageCode();
	For LineNumber = 3 To SpreadsheetDocument.TableHeight Do
		RowPrefix = "R"+ LineNumber +"C";
		
		// Read the first column data.
		TemplateName = CellData(SpreadsheetDocument, RowPrefix, 1, , "TableEnd");
		If Upper(TemplateName) = Upper("TableEnd") Then
			Break;
		EndIf;
		
		StartPageDescription = CellData(SpreadsheetDocument, RowPrefix, 3);
		If Not ValueIsFilled(StartPageDescription) Then
			Continue;
		EndIf;
		
		NumberInRegister = NumberInRegister + 1;
		
		// Registering command information.
		TableRow = Result.Add();
		TableRow.NumberInRegister                = NumberInRegister;
		TableRow.TemplateName                     = TemplateName;
		TableRow.Id                 = String(LineNumber - 2);
		TableRow.Section                        = CellData(SpreadsheetDocument, RowPrefix, 2);
		TableRow.StartPageDescription = StartPageDescription;
		TableRow.HomePageFileName     = CellData(SpreadsheetDocument, RowPrefix, 4);
		TableRow.ShowFrom              = CellData(SpreadsheetDocument, RowPrefix, 5, "Date", '00010101');
		TableRow.ShowTill           = CellData(SpreadsheetDocument, RowPrefix, 6, "Date", '29990101');
		
		If Lower(TableRow.Section) = Lower(NStr("vi = 'Quảng cáo';
												|ru = 'Реклама';
												|en = 'Ads'; fa = 'Ads';
												|it = 'Pubblicità';
												|pl = 'Ads';
												|tr = 'Reklam'")) Then // ACC:1391 Localizable section.
			TableRow.Priority = 0;
		Else
			TableRow.Priority = CellData(SpreadsheetDocument, RowPrefix, 7, "Number", 0);
			If TableRow.Priority = 0 Then
				TableRow.Priority = 99;
			EndIf;
		EndIf;
		
		TableRow.ShowInProf          = CellData(SpreadsheetDocument, RowPrefix, 8, "Boolean", True);
		TableRow.ShowInBasic       = CellData(SpreadsheetDocument, RowPrefix, 9, "Boolean", True);
		TableRow.ShowInSaaS = CellData(SpreadsheetDocument, RowPrefix, 10, "Boolean", True);
		
	EndDo;
	
	Return Result;
EndFunction

// Reads the contents of a cell from a spreadsheet document and converts to the specified type.
Function CellData(SpreadsheetDocument, RowPrefix, ColumnNumber, Type = "String", DefaultValue = "")
	Result = TrimAll(SpreadsheetDocument.Area(RowPrefix + String(ColumnNumber)).Text);
	If IsBlankString(Result) Then
		Return DefaultValue;
	ElsIf Type = "Number" Then
		Return Number(Result);
	ElsIf Type = "Date" Then
		Return Date(Result);
	ElsIf Type = "Boolean" Then
		Return Result <> "0";
	Else
		Return Result;
	EndIf;
EndFunction

// Global subsystem settings.
// Parameters:
//  PagesPackages - See PagesPackages
//
Function PreparePagesPackageForOutput(PagesPackages, CurrentDate) Export
	Result = New Structure;
	Result.Insert("MinPriority", 100);
	Result.Insert("PreparedPackages", Undefined);
	
	If Common.DataSeparationEnabled()
		Or Common.IsStandaloneWorkplace() Then
		ColumnShow = PagesPackages.Columns.ShowInSaaS;
	Else
		If StandardSubsystemsServer.IsBaseConfigurationVersion() Then
			ColumnShow = PagesPackages.Columns.ShowInBasic;
		Else
			ColumnShow = PagesPackages.Columns.ShowInProf;
		EndIf;
	EndIf;
	
	ColumnShow.Name = "Show";
	Filter = New Structure("Show", True);
	FoundItems = PagesPackages.FindRows(Filter);
	For Each Package In FoundItems Do
		If Package.ShowFrom > CurrentDate Or Package.ShowTill < CurrentDate Then
			Package.Show = False;
			Continue;
		EndIf;
		
		If Result.MinPriority > Package.Priority Then
			Result.MinPriority = Package.Priority;
		EndIf;
	EndDo;
	
	ColumnsNames = "NumberInRegister, Id, TemplateName, Section, StartPageDescription, HomePageFileName, Priority";
	Result.PreparedPackages = PagesPackages.Copy(Filter, ColumnsNames);
	Return Result;
EndFunction

// Extracts files package from the InformationOnStart data processor template.
Function ExtractPackageFiles(TemplatesMedia, TemplateName) Export
	TempFilesDir = FileSystem.CreateTemporaryDirectory("extras");
	
	// Extract a page.
	ArchiveFullName = TempFilesDir + "tmp.zip";
	Try
		TemplatesCollection = TemplatesMedia.Metadata().Templates;
		
		LocalizedTemplateName = TemplateName + "_" + CurrentLanguage().LanguageCode;
		Template                   = TemplatesCollection.Find(LocalizedTemplateName);
		If Template = Undefined Then
			LocalizedTemplateName = TemplateName + "_" + Common.DefaultLanguageCode();
			Template                   = TemplatesCollection.Find(LocalizedTemplateName);
		EndIf;
		
		If Template = Undefined Then
			LocalizedTemplateName = TemplateName;
		EndIf;
		
		BinaryData = TemplatesMedia.GetTemplate(LocalizedTemplateName);
		BinaryData.Write(ArchiveFullName);
	Except
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể lấy ra tệp từ khuôn in %1 (%2: %3) của bộ xử lý %4 do nguyên nhân:';
				|ru = 'Не удалось извлечь файл из макета %1 (%2: %3) обработки %4 по причине:';
				|en = 'Cannot retrieve the file from template %1(%2:%3) of data processor %4 due to:'; fa = 'Cannot retrieve the file from template %1(%2:%3) of data processor %4 due to:';
				|it = 'Non è stato possibile estrarre il file dal modello %1 (%2: %3) di elaborazione %4 a causa di:';
				|pl = 'Nie udało się wydobyć pliku z makietyc %1 (%2: %3) procesora danych %4 z powodu:';
				|tr = 'Dosya %1(%2: %3) işleme %4şablonundan şu nedenle alınamadı:'"),
				TemplateName, "LocalizedTemplateName", LocalizedTemplateName, "InformationOnStart") + Chars.LF;
		If TemplatesMedia.Metadata().Templates.Find(LocalizedTemplateName) = Undefined Then
			MessageText = MessageText + NStr("vi = 'Bố cục có tên này không tồn tại.';
											|ru = 'Макет с таким именем не существует.';
											|en = 'Template with this name does not exist.'; fa = 'Template with this name does not exist.';
											|it = 'Il layout con il nome indicato non esiste.';
											|pl = 'Nie istnieje makiety o takiej nazwie.';
											|tr = 'Bu ada sahip bir şablon mevcut değil.'") + Chars.LF;
		EndIf;
		MessageText = MessageText + ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(
			NStr("vi = 'Thông tin khi khởi động';
				|ru = 'Информация при запуске';
				|en = 'Startup notifications'; fa = 'اعلان‌های هنگام راه‌اندازی';
				|it = 'Informazioni all''avvio';
				|pl = 'Informacje na starcie';
				|tr = 'Başlangıçtaki bilgiler'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, MessageText);
		Return Undefined;
	EndTry;
	
	ZipFileReader = New ZipFileReader(ArchiveFullName);
	ZipFileReader.ExtractAll(TempFilesDir, ZIPRestoreFilePathsMode.Restore);
	ZipFileReader.Close();
	ZipFileReader = Undefined;
	
	DeleteFiles(ArchiveFullName);
	
	Images = New ValueTable;
	Images.Columns.Add("RelativeName",     New TypeDescription("String"));
	Images.Columns.Add("RelativeDirectory", New TypeDescription("String"));
	Images.Columns.Add("Data");
	
	WebPages = New ValueTable;
	WebPages.Columns.Add("RelativeName",     New TypeDescription("String"));
	WebPages.Columns.Add("RelativeDirectory", New TypeDescription("String"));
	WebPages.Columns.Add("Data");
	
	// Register page references and generating a list of pictures.
	FilesDirectories = New ValueList;
	FilesDirectories.Add(TempFilesDir, "");
	Left = 1;
	While Left > 0 Do
		Left = Left - 1;
		Directory = FilesDirectories[0];
		DirectoryFullPath        = Directory.Value; // A full path in the file system format.
		DirectoryRelativePath = Directory.Presentation; // A relative path in the URL format.
		FilesDirectories.Delete(0);
		
		FoundItems = FindFiles(DirectoryFullPath, "*", False);
		For Each File In FoundItems Do
			
			FileRelativeName = DirectoryRelativePath + File.Name;
			
			If File.IsDirectory() Then
				Left = Left + 1;
				FilesDirectories.Add(File.FullName, FileRelativeName + "/");
				Continue;
			EndIf;
			
			// Clear the ReadOnly flag to avoid mistakes during the deletion.
			File.SetReadOnly(False);
			
			Extension = StrReplace(Lower(File.Extension), ".", "");
			
			If Extension = "htm" Or Extension = "html" Then
				FileLocation = WebPages.Add();
				TextReader = New TextReader(File.FullName);
				Data = TextReader.Read();
				TextReader.Close();
				TextReader = Undefined;
			Else
				FileLocation = Images.Add();
				Data = New Picture(New BinaryData(File.FullName));
			EndIf;
			FileLocation.RelativeName     = FileRelativeName;
			FileLocation.RelativeDirectory = DirectoryRelativePath;
			FileLocation.Data               = Data;
		EndDo;
	EndDo;
	
	// Delete temporary files (all files were moved to the temporary storage).
	FileSystem.DeleteTemporaryDirectory(TempFilesDir);
	
	Result = New Structure;
	Result.Insert("Images", Images);
	Result.Insert("WebPages", WebPages);
	
	Return Result;
EndFunction

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("CommonDataNonexclusiveUpdate");
	
EndProcedure

#EndRegion