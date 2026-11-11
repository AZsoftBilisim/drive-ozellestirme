///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.BatchEditObjects

// Returns object attributes that can be edited using the bulk attribute modification data processor.
// 
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	AttributesToEdit = New Array;
	Return AttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Then
		StandardProcessing = False;
		Parameters.Insert("ShowPage", "Programs");
		SelectedForm = Metadata.CommonForms.DigitalSignatureAndEncryptionSettings;
		
	ElsIf Parameters.Property("Key")
	        And Parameters.Key.IsBuiltInCryptoProvider
	        And Metadata.DataProcessors.Find("ApplicationForNewQualifiedCertificateIssue") <> Undefined Then
		
		StandardProcessing = False;
		SelectedForm = "DataProcessor.DigitalSignatureAndEncryptionApplications.Form.BuiltinCryptoprovider";
	EndIf;
	
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not DigitalSignatureInternal.UseDigitalSignatureSaaS() Then
		Parameters.Filter.Insert("IsBuiltInCryptoProvider", False);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// See DigitalSignatureInternal.ApplicationsSettingsToSupply
Function ApplicationsSettingsToSupply() Export
	
	Settings = DigitalSignatureInternal.ApplicationsSettingsToSupply();
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		DigitalSignatureAndEncryptionApplicationProcessing = Common.ObjectManagerByFullName(
			"DataProcessor.DigitalSignatureAndEncryptionApplications");
		DigitalSignatureAndEncryptionApplicationProcessing.AddSuppliedProgramSettings(Settings);
	Else
		AddMicrosoftEnhancedCSPSettings(Settings);
	EndIf;
	
	Return Settings;
	
EndFunction

Procedure AddMicrosoftEnhancedCSPSettings(Settings) Export
	
	// Microsoft Enhanced CSP
	Setting = Settings.Add();
	Setting.Presentation       = NStr("vi = 'Microsoft Enhanced CSP';
										|ru = 'Microsoft Enhanced CSP';
										|en = 'Microsoft Enhanced CSP'; fa = 'Microsoft Enhanced CSP';
										|it = 'Microsoft Enhanced CSP';
										|pl = 'Microsoft Enhanced CSP';
										|tr = 'Microsoft Enhanced CSP'");
	Setting.ApplicationName        = "Microsoft Enhanced Cryptographic Provider v1.0";
	Setting.ApplicationType        = 1;
	Setting.SignAlgorithm     = "RSA_SIGN"; // One option.
	Setting.HashAlgorithm = "MD5";      // Options: SHA-1, MD2, MD4, MD5.
	Setting.EncryptAlgorithm  = "RC2";      // Options: RC2, RC4, DES, 3DES.
	Setting.Id       = "MicrosoftEnhanced";
	
	Setting.SignAlgorithms.Add("RSA_SIGN");
	Setting.HashAlgorithms.Add("SHA-1");
	Setting.HashAlgorithms.Add("MD2");
	Setting.HashAlgorithms.Add("MD4");
	Setting.HashAlgorithms.Add("MD5");
	Setting.EncryptAlgorithms.Add("RC2");
	Setting.EncryptAlgorithms.Add("RC4");
	Setting.EncryptAlgorithms.Add("DES");
	Setting.EncryptAlgorithms.Add("3DES");
	Setting.NotOnLinux = True;
	Setting.NotInMacOS = True;
	
	// Microsoft Enhanced RSA and AES CSP
	Setting = Settings.Add();
	Setting.Presentation       = NStr("vi = 'Microsoft Enhanced RSA and AES CSP';
										|ru = 'Microsoft Enhanced RSA and AES CSP';
										|en = 'Microsoft Enhanced RSA and AES CSP'; fa = 'Microsoft Enhanced RSA and AES CSP';
										|it = 'Microsoft Enhanced RSA and AES CSP';
										|pl = 'Microsoft Enhanced RSA and AES CSP';
										|tr = 'Microsoft Enhanced RSA and AES CSP'");
	Setting.ApplicationName        = "Microsoft Enhanced RSA and AES Cryptographic Provider";
	Setting.ApplicationType        = 24;
	Setting.SignAlgorithm     = "RSA_SIGN"; // One option.
	Setting.HashAlgorithm = "SHA-256";  // Options: SHA-256, SHA-1, MD2, MD4, MD5.
	Setting.EncryptAlgorithm  = "3DES";     // Options: RC2, RC4, DES, 3DES.
	Setting.Id       = "MicrosoftEnhanced_RSA_AES";
	
	Setting.SignAlgorithms.Add("RSA_SIGN");
	Setting.HashAlgorithms.Add("SHA-256");
	Setting.HashAlgorithms.Add("SHA-1");
	Setting.HashAlgorithms.Add("MD2");
	Setting.HashAlgorithms.Add("MD4");
	Setting.HashAlgorithms.Add("MD5");
	Setting.EncryptAlgorithms.Add("RC2");
	Setting.EncryptAlgorithms.Add("RC4");
	Setting.EncryptAlgorithms.Add("DES");
	Setting.EncryptAlgorithms.Add("3DES");
	Setting.NotOnLinux = True;
	Setting.NotInMacOS = True;
	
	// Microsoft Base Smart Card Crypto Provider
	Setting = Settings.Add();
	Setting.Presentation       = NStr("vi = 'Microsoft Base Smart Card CSP';
										|ru = 'Microsoft Base Smart Card CSP';
										|en = 'Microsoft Base Smart Card CSP'; fa = 'Microsoft Base Smart Card CSP';
										|it = 'Microsoft Base Smart Card CSP';
										|pl = 'Microsoft Base Smart Card CSP';
										|tr = 'Microsoft Base Smart Card CSP'");
	Setting.ApplicationName        = "Microsoft Base Smart Card Crypto Provider";
	Setting.ApplicationType        = 1;
	Setting.SignAlgorithm     = "RSA_SIGN"; // One option.
	Setting.HashAlgorithm = "SHA-256";  // Options: SHA-256, SHA-1, SHA-384, SHA-512, MD2, MD4, MD5.
	Setting.EncryptAlgorithm  = "3DES";     // Options: RC2, RC4, DES, 3DES.
	Setting.Id       = "MicrosoftBaseSmartCard";
	
	Setting.SignAlgorithms.Add("RSA_SIGN");
	Setting.HashAlgorithms.Add("SHA-256");
	Setting.HashAlgorithms.Add("SHA-384");
	Setting.HashAlgorithms.Add("SHA-512");
	Setting.HashAlgorithms.Add("SHA-1");
	Setting.HashAlgorithms.Add("MD2");
	Setting.HashAlgorithms.Add("MD4");
	Setting.HashAlgorithms.Add("MD5");
	Setting.EncryptAlgorithms.Add("RC2");
	Setting.EncryptAlgorithms.Add("RC4");
	Setting.EncryptAlgorithms.Add("DES");
	Setting.EncryptAlgorithms.Add("3DES");
	Setting.NotOnLinux = True;
	Setting.NotInMacOS = True;
	
EndProcedure

Function SupplyThePathToTheProgramModules() Export
	
	ThePathToTheModules = DigitalSignatureInternal.SupplyThePathToTheProgramModules();
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		DigitalSignatureAndEncryptionApplicationProcessing = Common.ObjectManagerByFullName(
			"DataProcessor.DigitalSignatureAndEncryptionApplications");
		DigitalSignatureAndEncryptionApplicationProcessing.AddSuppliedPathsToProgramModules(ThePathToTheModules);
	EndIf;
	
	Return ThePathToTheModules;
	
EndFunction

#Region InfobaseUpdate

Procedure FillInitialSettings(Programs = Undefined, WithoutEmbeddedCryptoprovider = False) Export
	
	If Programs = Undefined Then
		Programs = New Map;
	EndIf;
	
	ApplicationsDetails = New Array;
	For Each KeyAndValue In Programs Do
		ApplicationsDetails.Add(DigitalSignature.NewApplicationDetails(
			KeyAndValue.Key, KeyAndValue.Value));
	EndDo;
	
	DigitalSignature.FillApplicationsList(ApplicationsDetails);
	
	If WithoutEmbeddedCryptoprovider Then
		Return;
	EndIf;
	
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		DigitalSignatureAndEncryptionApplicationProcessing = Common.ObjectManagerByFullName(
			"DataProcessor.DigitalSignatureAndEncryptionApplications");
		DigitalSignatureAndEncryptionApplicationProcessing.UpdatetheBuiltInCryptoprovider();
	EndIf;
	
EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DigitalSignatureAndEncryptionApplications.Ref
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS DigitalSignatureAndEncryptionApplications
	|WHERE
	|	NOT DigitalSignatureAndEncryptionApplications.IsBuiltInCryptoProvider";
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		InfobaseUpdate.MarkForProcessing(Parameters, SelectionDetailRecords.Ref);
	EndDo;
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ProcessingCompleted = True;
	
	SelectionDetailRecords = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue,
		"Catalog.DigitalSignatureAndEncryptionApplications");
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	
	SettingsToSupply = ApplicationsSettingsToSupply();
	
	While SelectionDetailRecords.Next() Do
		UpdateAppDataWithDeferral(SelectionDetailRecords.Ref,
			ObjectsProcessed, ObjectsWithIssuesCount, SettingsToSupply);
	EndDo;
	
	FillInitialSettingsDeferred(ObjectsProcessed, ObjectsWithIssuesCount);
	
	If Not InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.DigitalSignatureAndEncryptionApplications") Then
		ProcessingCompleted = False;
	EndIf;
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý một số ứng dụng chữ ký điện tử (đã bỏ qua): %1';
				|ru = 'Не удалось обработать некоторые приложения электронной подписи (пропущены): %1';
				|en = 'Couldn''t process (skipped) some digital signing apps: %1'; fa = 'Couldn''t process (skipped) some digital signing apps: %1';
				|it = 'Не удалось обработать некоторые приложения электронной подписи (пропущены): %1';
				|pl = 'Couldn''t process (skipped) some digital signing apps: %1';
				|tr = 'Bazı elektronik imza uygulamaları işlenemedi (atlandı): %1'"), 
			ObjectsWithIssuesCount);
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.DigitalSignatureAndEncryptionApplications,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xử lý tùy chọn ứng dụng chữ ký điện tử theo trình tự: %1';
					|ru = 'Обработана очередная порция приложений электронной подписи: %1';
					|en = 'Yet another batch of digital signing apps is processed: %1'; fa = 'Yet another batch of digital signing apps is processed: %1';
					|it = 'Обработана очередная порция приложений электронной подписи: %1';
					|pl = 'Yet another batch of digital signing apps is processed: %1';
					|tr = 'Elektronik imza uygulamalarının bir grubu daha işlendi:%1'"),
				ObjectsProcessed));
	EndIf;
	
	Parameters.ProcessingCompleted = ProcessingCompleted;

EndProcedure

// Parameters:
//  Application - CatalogRef.DigitalSignatureAndEncryptionApplications
//
Procedure UpdateAppDataWithDeferral(Application, ObjectsProcessed, ObjectsWithIssuesCount, SettingsToSupply)
	
	Block = New DataLock;
	Block.Add("Catalog.DigitalSignatureAndEncryptionApplications");
	
	RepresentationOfTheReference = String(Application);
	
	BeginTransaction();
	Try
		Block.Lock();
		
		Properties = Common.ObjectAttributesValues(Application,
			"ApplicationName, ApplicationType, Description, IsBuiltInCryptoProvider, DeletionMark, UsageMode");
		
		Filter = New Structure("ApplicationName, ApplicationType", Properties.ApplicationName, Properties.ApplicationType);
		Rows = SettingsToSupply.FindRows(Filter);
		
		If Not Properties.IsBuiltInCryptoProvider
		   And Rows.Count() = 1
		   And (Rows[0].Presentation <> Properties.Description Or Not ValueIsFilled(Properties.UsageMode)) Then
			
			ApplicationObject = Application.GetObject();
			ApplicationObject.Description = Rows[0].Presentation;
			If Not ValueIsFilled(Properties.UsageMode) Then
				ApplicationObject.UsageMode = ?(Properties.DeletionMark,
					Enums.DigitalSignatureAppUsageModes.NotUsed,
					Enums.DigitalSignatureAppUsageModes.Configured)
			EndIf;
			InfobaseUpdate.WriteObject(ApplicationObject);
		ElsIf Not ValueIsFilled(Properties.UsageMode) Then
			
			ApplicationObject = Application.GetObject();
			ApplicationObject.UsageMode = ?(Properties.DeletionMark,
				Enums.DigitalSignatureAppUsageModes.NotUsed,
				Enums.DigitalSignatureAppUsageModes.Configured);
			InfobaseUpdate.WriteObject(ApplicationObject);
			
		EndIf;
		
		ObjectsProcessed = ObjectsProcessed + 1;
		CommitTransaction();
	Except
		RollbackTransaction();
		ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
		
		InfobaseUpdate.WriteErrorToEventLog(
			Application,
			RepresentationOfTheReference,
			ErrorInfo());
		Return;
	EndTry;
	
	InfobaseUpdate.MarkProcessingCompletion(Application);
	
EndProcedure

Procedure FillInitialSettingsDeferred(ObjectsProcessed, ObjectsWithIssuesCount)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DigitalSignatureAndEncryptionApplications.ApplicationName AS ApplicationName,
	|	DigitalSignatureAndEncryptionApplications.ApplicationType AS ApplicationType
	|FROM
	|	Catalog.DigitalSignatureAndEncryptionApplications AS DigitalSignatureAndEncryptionApplications
	|WHERE
	|	DigitalSignatureAndEncryptionApplications.IsBuiltInCryptoProvider";
	
	Programs = New Map;
	
	Block = New DataLock;
	Block.Add("Catalog.DigitalSignatureAndEncryptionApplications");
	
	BeginTransaction();
	Try
		Block.Lock();
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			If Programs.Get(Selection.ApplicationName) = Selection.ApplicationType Then
				Programs.Delete(Selection.ApplicationName);
			EndIf;
		EndDo;
		
		FillInitialSettings(Programs, True);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể điền vào tùy chỉnh ban đầu của ứng dụng do nguyên nhân:
			|%1';
			|ru = 'Не удалось дозаполнить начальные настройки приложения по причине:
			|%1';
			|en = 'Couldn''t perform the initial population of the app settings due to:
			|%1'; fa = 'Couldn''t perform the initial population of the app settings due to:
			|%1';
			|it = 'Не удалось дозаполнить начальные настройки приложения по причине:
			|%1';
			|pl = 'Couldn''t perform the initial population of the app settings due to:
			|%1';
			|tr = 'Uygulamanın başlangıç ayarları şu sebeple doldurulamadı:
			|%1'"), ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		Raise MessageText;
	EndTry;
	
	If Metadata.DataProcessors.Find("DigitalSignatureAndEncryptionApplications") <> Undefined Then
		DigitalSignatureAndEncryptionApplicationProcessing = Common.ObjectManagerByFullName(
			"DataProcessor.DigitalSignatureAndEncryptionApplications");
		DigitalSignatureAndEncryptionApplicationProcessing.UpdatetheBuiltInCryptoprovider(True,
			ObjectsProcessed, ObjectsWithIssuesCount);
	EndIf;
	
EndProcedure

#EndRegion

// See StandardSubsystemsServer.OnDefineMethodsAllowedForCallAsArbitraryCode
Procedure OnDefineMethodsAllowedForCallAsArbitraryCode(Methods) Export
	
	Methods.Insert("FillInitialSettings");
	
EndProcedure

#EndRegion

#EndIf