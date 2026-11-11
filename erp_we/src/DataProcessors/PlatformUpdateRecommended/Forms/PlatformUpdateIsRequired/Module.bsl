///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SystemInfo = New SystemInfo;
	CurrentVersion = SystemInfo.AppVersion;
	
	AllDeprecatedVersions = Common.InvalidPlatformVersions();
	
	CommonParameters    = Common.CommonCoreParameters();
	MinVersion = CommonParameters.MinPlatformVersion;
	
	Refinement = "";
	ClarificationRestart = "";
	If Not Common.FileInfobase()
		Or Common.IsWebClient() Then
		Refinement = NStr("vi = 'Để thực hiện này, hãy liên hệ với người quản trị.';
							|ru = 'Для этого обратитесь к администратору.';
							|en = 'Contact the administrator.'; fa = 'Contact the administrator.';
							|it = 'Per questo, rivolgersi all''amministratore.';
							|pl = 'W tym celu zwróć się do administratora.';
							|tr = 'Bunun için yöneticiyle iletişime geçin.'");
	EndIf;
	
	If Not Common.IsLinuxClient()
		And Not Common.IsWebClient()
		And Common.FileInfobase() Then 
		
		PlatformDirectory = PlatformStartupDirectory(CurrentVersion, AllDeprecatedVersions);
		If ValueIsFilled(PlatformDirectory) Then
			Items.FormRestart.Visible = True;
			Items.FormRestart.DefaultButton = True;
			ClarificationRestart = Chars.LF + Chars.LF + NStr("vi = 'Khởi động lại ứng dụng trên phiên bản nền tảng phù hợp (nút <b>Khởi động lại</b>).';
																|ru = 'Перезапустите приложение на подходящей версии платформы (кнопка <b>Перезапустить</b>).';
																|en = 'Run the application on the supported 1C:Enterprise version (click <b>Restart</b>).'; fa = 'Run the application on the supported 1C:Enterprise version (click <b>Restart</b>).';
																|it = 'Перезапустите приложение на подходящей версии платформы (кнопка <b>Перезапустить</b>).';
																|pl = 'Run the application on the supported 1C:Enterprise version (click <b>Restart</b>).';
																|tr = 'Uygulama platformun uygun bir sürümünde yeniden başlatın (<b>Yeniden başlat butonu</b>).'");
		EndIf;
	EndIf;
	
	Items.Warning.Title = StringFunctions.FormattedString(Items.Warning.Title, 
		"<b>" + CurrentVersion + "</b>",
		ClarificationRestart,
		"<b>" + MinVersion + "</b>",
		Refinement);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UpdateInstructionClick(Item) 
	ParametersOfUpdate = New Structure;
	ParametersOfUpdate.Insert("IsInstructionForFileInfobase", True);
	
	OpenForm("DataProcessor.PlatformUpdateRecommended.Form.PlatformUpdateOrder", ParametersOfUpdate, ThisObject);
EndProcedure

&AtClient
Procedure PlatformUninstallInstructionClick(Item)
	ParametersOfUpdate = New Structure;
	ParametersOfUpdate.Insert("IsApplicationUninstallation", True);
	ParametersOfUpdate.Insert("PlatformVersion", CurrentVersion);
	
	OpenForm("DataProcessor.PlatformUpdateRecommended.Form.PlatformUpdateOrder", ParametersOfUpdate, ThisObject);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Restart(Command)
	
	StartupCommand = New Array;
	StartupCommand.Add(PlatformDirectory + "1cv8.exe");
	StartupCommand.Add("ENTERPRISE");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(InfoBaseConnectionString());
	StartupCommand.Add("AppAutoCheckVersion-");
	
	ApplicationStartupParameters = FileSystemClient.ApplicationStartupParameters();
	ApplicationStartupParameters.Notification = New CallbackDescription("RestartCompletion", ThisObject);
	ApplicationStartupParameters.WaitForCompletion = False;
	
	FileSystemClient.StartApplication(StartupCommand, ApplicationStartupParameters);
	
EndProcedure 

#EndRegion

#Region Private

&AtServer
Function PlatformStartupDirectory(CurrentVersion, AllDeprecatedVersions)
	
	BinDir = BinDir();
	AppllicationDirectoryByParts = StrSplit(BinDir, GetPathSeparator(), False); 
	FoundPlatform = Undefined;
	If AppllicationDirectoryByParts.Count() > 2 Then
		AppllicationDirectoryByParts.Delete(AppllicationDirectoryByParts.UBound());
		AppllicationDirectoryByParts.Delete(AppllicationDirectoryByParts.UBound());
		
		BinDir = StrConcat(AppllicationDirectoryByParts, GetPathSeparator());
		
		AvailablePlatforms = FindFiles(BinDir, "*");
		
		PlatformVersionsTable = PlatformVersionsTable(AvailablePlatforms, AllDeprecatedVersions);
		
		FoundPlatform = FoundPlatform(PlatformVersionsTable, CurrentVersion);
	EndIf;
	
	If FoundPlatform <> Undefined Then
		PlatformDirectory = FoundPlatform.FullPath + GetPathSeparator() + "bin" + GetPathSeparator();
		Return PlatformDirectory;
	EndIf;
	
EndFunction

&AtServer
Function PlatformVersionsTable(Platforms, AllDeprecatedVersions)
	
	Table = New ValueTable;
	Table.Columns.Add("Assembly");
	Table.Columns.Add("Version");
	Table.Columns.Add("FullPath");
	Table.Columns.Add("VersionWeight");
	
	Separator = GetPathSeparator();
	
	AllMinOnes = Common.MinPlatformVersion();
	AllMinOnesByParts = StrSplit(AllMinOnes, "; ");
	MinBuildsMap = New Map;
	For Each Min In AllMinOnesByParts Do
		MinVersion = CommonClientServer.ConfigurationVersionWithoutBuildNumber(Min);
		MinBuildsMap.Insert(MinVersion, Min);
	EndDo;
	
	For Each Platform In Platforms Do 
		If Not StrStartsWith(Platform.Name, "8.3.") Then
			Continue;
		EndIf;
		
		If StrFind(AllDeprecatedVersions, Platform.Name) Then
			Continue;
		EndIf;
		
		If StrSplit(Platform.BaseName, ".").Count() <> 3 Then
			Continue;
		EndIf;
		
		// Check the versions of 1C:Enterprise installed on the user's PC. A minimum supported compatibility mode is required.
		If CommonClientServer.CompareVersionsWithoutBuildNumber(Platform.BaseName, "8.3.24") < 0 Then
			Continue;
		EndIf;
		
		If MinBuildsMap[Platform.BaseName] <> Undefined
			And CommonClientServer.CompareVersions(Platform.Name, MinBuildsMap[Platform.BaseName]) < 0 Then
			Continue;
		EndIf;
		
		ExecutableFileName = Platform.FullName + Separator + "bin" + Separator + "1cv8.exe";
		File = New File(ExecutableFileName);
		If Not File.Exists() Then
			Continue;
		EndIf;
		
		String = Table.Add();
		String.Assembly = Platform.Name;
		String.Version = Platform.BaseName;
		String.FullPath = Platform.FullName;
		String.VersionWeight = VersionWeight(Platform.Name);
	EndDo;
	
	Table.Sort("VersionWeight Desc");
	
	Return Table;
	
EndFunction

&AtServer
Function VersionWeight(BuildNumber)
	BuildNumberByParts = StrSplit(BuildNumber, ".");
	
	Weight = Number(BuildNumberByParts[0]) * 10000000
		+ Number(BuildNumberByParts[1]) * 1000000
		+ Number(BuildNumberByParts[2]) * 10000
		+ Number(BuildNumberByParts[3]);
	
	Return Weight;
EndFunction

&AtServer
Function FoundPlatform(PlatformVersionsTable, CurrentVersion)
	
	Version = CommonClientServer.ConfigurationVersionWithoutBuildNumber(CurrentVersion);
	SuitableBuild = PlatformVersionsTable.Find(Version, "Version");
	While SuitableBuild = Undefined Do
		VersionByParts = StrSplit(Version, ".");
		VersionNumber = VersionByParts[2];
		TypeDescription = New TypeDescription("Number");
		Try
			VersionNumber = TypeDescription.AdjustValue(VersionNumber);
		Except
			Return Undefined;
		EndTry;
		VersionNumber = VersionNumber - 1;
		If VersionNumber < 24 Then // 8.3.24
			Return Undefined;
		EndIf;
		VersionByParts[2] = String(VersionNumber);
		Version = StrConcat(VersionByParts, ".");
		SuitableBuild = PlatformVersionsTable.Find(Version, "Version");
	EndDo;
	
	Return SuitableBuild;
	
EndFunction

&AtClient
Procedure RestartCompletion(Result, AdditionalParameters) Export
	
	Exit(False, False);
	
EndProcedure

#EndRegion
