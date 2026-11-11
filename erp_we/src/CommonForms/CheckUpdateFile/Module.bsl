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
	
	NameOfFirstUpdateFile = Parameters.NameOfFirstUpdateFile;
	Metadata_Version = Metadata.Version;
	
	If InfobaseUpdateInternal.DeferredUpdateCompleted()
	 Or Not ValueIsFilled(NameOfFirstUpdateFile)
	   And Not ConfigurationChanged() Then
		Cancel = True;
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(NameOfFirstUpdateFile) Then
		ImportFile_();
		If TypeOf(Result) = Type("Boolean") Then
			Cancel = True;
		EndIf;
	Else
#If Not WebClient And Not MobileClient Then
		Try
			Result = OnlyBuildNumberOfMainConfigurationChanged();
		Except
			ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			WriteError(ErrorText);
		EndTry;
#EndIf
		Cancel = True;
		If TypeOf(Result) <> Type("Boolean") Then
			Result = False;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#If Not WebClient And Not MobileClient Then

&AtClient
Function OnlyBuildNumberOfMainConfigurationChanged()
	
	PathToTempDir = GetTempFileName() + "\";
	ListFileName    = PathToTempDir + "ConfigFiles.txt";
	MessagesFileName = PathToTempDir + "Out.txt";
	
	CreateDirectory(PathToTempDir);
	
	TextDocument = New TextDocument;
	TextDocument.SetText("Configuration");
	TextDocument.Write(ListFileName);
	
	ParametersOfSystem = New Array;
	ParametersOfSystem.Add("DESIGNER");
	ParametersOfSystem.Add("/DisableStartupMessages");
	ParametersOfSystem.Add("/DisableStartupDialogs");
	ParametersOfSystem.Add("/DumpConfigToFiles");
	ParametersOfSystem.Add("""" + PathToTempDir + """");
	ParametersOfSystem.Add("-listfile");
	ParametersOfSystem.Add("""" + ListFileName + """");
	ParametersOfSystem.Add("/Out");
	ParametersOfSystem.Add("""" + MessagesFileName + """");
	
	ReturnCode = 0;
	RunSystem(StrConcat(ParametersOfSystem, " "), True, ReturnCode);
	
	If ReturnCode <> 0 Then
		TextDocument = New TextDocument;
		TextDocument.Read(MessagesFileName);
		DeleteFiles(PathToTempDir);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể kết xuất cấu hình vào tệp do nguyên nhân:
			           |%1';
			           |ru = 'Не удалось выгрузить конфигурацию в файлы по причине:
			           |%1';
			           |en = 'Cannot dump the configuration to files due to:
			           |%1'; fa = 'Cannot dump the configuration to files due to:
			           |%1';
			           |it = 'Не удалось выгрузить конфигурацию в файлы по причине:
			           |%1';
			           |pl = 'Cannot dump the configuration to files due to:
			           |%1';
			           |tr = 'Dosyalardaki konfigürasyon şu sebeple indirilemedi:
			           |%1'"),
			"ReturnCode" + " = " + String(ReturnCode) + "
			|" + TextDocument.GetText());
		Raise ErrorText;
	EndIf;
	
	XMLReader = New XMLReader;
	DOMBuilder = New DOMBuilder;
	XMLReader.OpenFile(PathToTempDir + "Configuration.xml");
	DOMDocument = DOMBuilder.Read(XMLReader);
	XMLReader.Close();
	
	DeleteFiles(PathToTempDir);
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Không tìm thấy phiên bản trong tệp kết xuất %1';
			|ru = 'Не найдена версия в файле выгрузки %1';
			|en = 'A version is not found in the %1 dump file'; fa = 'A version is not found in the %1 dump file';
			|it = 'Не найдена версия в файле выгрузки %1';
			|pl = 'A version is not found in the %1 dump file';
			|tr = 'Dışa aktarılan %1 dosyasında sürüm bulunamadı'"),
		"Configuration.xml");
	
	Dereferencer = New DOMNamespaceResolver(DOMDocument);
	XPathExpression = "/xmlns:MetaDataObject/xmlns:Configuration/xmlns:Properties/xmlns:Version";
	XPathResult = DOMDocument.EvaluateXPathExpression(XPathExpression, DOMDocument, Dereferencer);
	If Not XPathResult.InvalidIteratorState Then
		NextNode = XPathResult.IterateNext();
		If TypeOf(NextNode) = Type("DOMElement")
		   And Upper(NextNode.TagName) = Upper("Version") Then
			Version = NextNode.TextContent;
			If StrSplit(Version, ".", False).Count() < 4 Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Sai phiên bản ""%1"" trong tệp kết xuất %2';
						|ru = 'Некорректная версия ""%1"" в файле выгрузки %2';
						|en = 'Incorrect version ""%1"" in the %2 dump file'; fa = 'Incorrect version ""%1"" in the %2 dump file';
						|it = 'Некорректная версия ""%1"" в файле выгрузки %2';
						|pl = 'Incorrect version ""%1"" in the %2 dump file';
						|tr = 'İndirilen %2 dosyasındaki ""%1"" sürümü yanlış'"),
					Version, "Configuration.xml");
			Else
				Return CommonClientServer.ConfigurationVersionWithoutBuildNumber(Metadata_Version)
				      = CommonClientServer.ConfigurationVersionWithoutBuildNumber(Version);
			EndIf;
		EndIf;
	EndIf;
	
	Raise ErrorText;
	
EndFunction

#EndIf
&AtClient
Procedure ImportFile_()
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.FormIdentifier = UUID;
	ImportParameters.Interactively = False;
	
	Notification = New CallbackDescription("AfterFileImported", ThisObject);
	FileSystemClient.ImportFile_(Notification, ImportParameters, NameOfFirstUpdateFile);
	
EndProcedure

&AtClient
Procedure AfterFileImported(ImportedFile, Context) Export
	
	If ValueIsFilled(ImportedFile)
	   And ValueIsFilled(ImportedFile.Name)
	   And ValueIsFilled(ImportedFile.Location)
	   And IsOnlyBuildNumberChanged(ImportedFile.Location, ImportedFile.Name) Then
		
		Result = True;
	Else
		Result = False;
	EndIf;
	
	If IsOpen() Then
		Close(Result);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function IsOnlyBuildNumberChanged(AddressInTempStorage, FullFileName)
	
	Try
		BinaryData = GetFromTempStorage(AddressInTempStorage);
		DeleteFromTempStorage(AddressInTempStorage);
		If TypeOf(BinaryData) <> Type("BinaryData") Then
			Return False;
		EndIf;
	
		If StrEndsWith(FullFileName, ".cfu") Then
			UpdateDetails1 = New ConfigurationUpdateDescription(BinaryData);
			ConfigurationDescription = UpdateDetails1.TargetConfiguration;
		Else
			ConfigurationDescription = New ConfigurationDescription(BinaryData);
		EndIf;
		IsOnlyBuildNumberChanged =
			  CommonClientServer.ConfigurationVersionWithoutBuildNumber(Metadata.Version)
			= CommonClientServer.ConfigurationVersionWithoutBuildNumber(ConfigurationDescription.Version);
	Except
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteError(ErrorText);
		IsOnlyBuildNumberChanged = False;
	EndTry;
	
	Return IsOnlyBuildNumberChanged;
	
EndFunction

&AtServerNoContext
Procedure WriteError(ErrorText)
	
	ErrorTitle = NStr("vi = 'Không thể nhận phiên bản cấu hình mới do nguyên nhân:';
						|ru = 'Не удалось получить версию новой конфигурации по причине:';
						|en = 'Cannot get the new configuration version due to:'; fa = 'Cannot get the new configuration version due to:';
						|it = 'Не удалось получить версию новой конфигурации по причине:';
						|pl = 'Cannot get the new configuration version due to:';
						|tr = 'Yeni konfigürasyonun sürümü şu sebeple alınamadı:'") + Chars.LF;
	WriteLogEvent(ConfigurationUpdate.EventLogEvent(),
		EventLogLevel.Error,,, ErrorTitle + ErrorText);
	
EndProcedure

#EndRegion
