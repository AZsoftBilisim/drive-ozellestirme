///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Parameters for the call of the AddInsServer.AttachAddInSSL procedure.
//
// Returns:
//  Structure:
//    * ObjectsCreationIDs - Array of String - IDs of object module instances.
//              Use it only for add-ins with several object creation IDs.
//              When specified, the ID parameter is used only to determine an add-in.
//    * Isolated - Boolean  - If set to "True", the add-in is attached isolatedly. 
//                               That is, it runs in a separate OS process.
//                               If set to "False", the add-in runs in the same OS process that runs 1C:Enterprise scripts. 
//                                
//              - Undefined - Defines the 1C:Enterprise behavior.:
//                               Non-isolatedly if the add-in supports only this mode. 
//                               Isolatedly, in other cases. By default, "Undefined".
//                               See https://its.1c.eu/db/v83doc#bookmark:dev:TI000001866
//    * FullTemplateName - String - Full name of the template with a ZIP archive containing the add-in.
//
Function ConnectionParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("ObjectsCreationIDs", New Array);
	Parameters.Insert("Isolated");
	Parameters.Insert("FullTemplateName");
	
	Return Parameters;
	
EndFunction

// Attaches the add-in from the add-in storage
// based on Native API or COM technologies on 1C:Enterprise server.
// In SaaS mode, you can only attach common add-ins approved by the service administrator.
//
// Parameters:
//  Id - String - the add-in identification code.
//  Version        - String - an add-in version.
//  ConnectionParameters - See ConnectionParameters.
//
// Returns:
//   Structure - Add-in attachment result:
//     * Attached - Boolean - attachment flag.
//     * Attachable_Module - AddInObject - an instance of the add-in;
//                          - FixedMap of KeyAndValue - Add-in object instances stored in
//                            AttachmentParameters.ObjectsCreationIDs:
//                            ** Key - String - ID.
//                            ** Value - AddInObject - an instance of the add-in.
//     * ErrorDescription - String - brief error message. 
//
Function AttachAddInSSL(Val Id, Version = Undefined, ConnectionParameters = Undefined) Export
	
	If ConnectionParameters = Undefined Then
		Isolated = Undefined;
	Else
		Isolated = ConnectionParameters.Isolated;
	EndIf;
	
	CheckResult = AddInsInternal.CheckAddInAttachmentAbility(Id, Version, ConnectionParameters);
	If Not IsBlankString(CheckResult.ErrorDescription) Then
		Result = New Structure;
		Result.Insert("Attached", False);
		Result.Insert("Attachable_Module", Undefined);
		Result.Insert("Version", Version);
		Result.Insert("ErrorDescription", CheckResult.ErrorDescription);
		Return Result;
	EndIf;
	
	Return Common.AttachAddInSSLByID(
		CheckResult.Id, CheckResult.Location, Isolated);
	
EndFunction

// Returns the information about an add-in by its ID and version.
//
// Parameters:
//  Id - String - Add-in identification code.
//  Version - String - an add-in version. 
//
// Returns:
//  Structure:
//      * Exists - Boolean - Add-in absence flag.
//      * EditingAvailable - Boolean - indicates that the area administrator can change the add-in.
//      * ErrorDescription - String - brief error message.
//      * Id - String - the add-in identification code.
//      * Version - String - Add-in version.
//      * Description - String - Add-in description and brief details.
//
// Example:
//
//  Result = AddInServer.InformationOnAddIn("InputDevice", "8.1.7.10");
//  If Result.Exists Then
//      ID = Result.ID;
//      Version        = Result.Version;
//      Description = Result.Description;
//  Else
//      CommonClientServer.MessageToUser(Result.ErrorDetails);
//  EndIf;
//
Function AddInInformation(Val Id, Val Version = Undefined) Export
	
	Result = New Structure;
	Result.Insert("Exists", False);
	Result.Insert("EditingAvailable", False);
	Result.Insert("Id", Id);
	Result.Insert("Version", "");
	Result.Insert("Description", "");
	Result.Insert("ErrorDescription", "");
	
	Information = AddInsInternal.SavedAddInInformation(Id, Version);
	
	If Information.State = "NotFound1" Then
		Result.ErrorDescription = NStr("vi = 'Cấu phần bên ngoài không tồn tại';
										|ru = 'Внешняя компонента не существует';
										|en = 'Add-in does not exist'; fa = 'Add-in does not exist';
										|it = 'La componente esterna non esiste';
										|pl = 'Zewnętrznego komponentu nie istnieje';
										|tr = 'Harici bileşen mevcut değil'");
		Return Result;
	EndIf;
	
	If Information.State = "DisabledByAdministrator" Then
		Result.ErrorDescription = NStr("vi = 'Cấu phần bên ngoài bị tắt sử dụng';
										|ru = 'Внешняя компонента отключена';
										|en = 'Add-in is disabled'; fa = 'Add-in is disabled';
										|it = 'Componente esterno disattivato';
										|pl = 'Odłączono komponent zewnętrzny';
										|tr = 'Harici bileşen devre dışı'");
		Return Result;
	EndIf;
	
	Result.Exists = True;
	Result.EditingAvailable = True;
	
	If Information.State = "FoundInSharedStorage" Then
		Result.EditingAvailable = False;
	EndIf;
	
	Result.Version = Information.Attributes.Version;
	Result.Description = Information.Attributes.Description;
	
	Return Result;
	
EndFunction

#Region InterfaceImplementation

// OnlineUserSupport.GetAddIns

// Returns a table of add-in details.
//
// Parameters:
//  Variant - String - Valid values::
//    ForUpdate - Add-ins with the internet update flag set.
//    ForImport - Add-ins used in the configuration.
//    Supplied1 - For determining 1C-supplied add-ins in the SaaS mode.
//
// Returns:
//   - ValueTable:
//      * Id - String - The add-in UUID manually specified
//                                 in the publication base.
//      * Version        - String - Add-in version.
//      * Description  - String - Add-in description.
//      * VersionDate    - Date - The date the add-in version (build) was released.
//      * AutoUpdate - Boolean - The add-in auto-update flag.
//   - Array of String - IDs of 1C-supplied add-ins in case "Option" is set to "Supplied1".
//
Function ComponentsToUse(Variant) Export
	
	If Not Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		Raise NStr("vi = 'Thao tác không khả dụng.';
					|ru = 'Действие недоступно.';
					|en = 'Action is unavailable.'; fa = 'Action is unavailable.';
					|it = 'Action is unavailable.';
					|pl = 'Action is unavailable.';
					|tr = 'Eylem kullanılamıyor.'");
	EndIf;
	
	If Variant = "Supplied1" Then
		Return AddInsInternal.SuppliedAddIns();
	EndIf;
	
	ModuleGetAddIns = Common.CommonModule("GetAddIns");
	AddInsDetails = ModuleGetAddIns.AddInsDetails();
	
	AddInsData = AddInsInternal.AddInsData(Variant);
	For Each ComponentDetails In AddInsData Do
		NewRow = AddInsDetails.Add();
		FillPropertyValues(NewRow, ComponentDetails);
	EndDo;
	
	Return AddInsDetails;
	
EndFunction

// Updates add-ins.
//
// Parameters:
//  AddInsData - ValueTable:
//    * Id - String
//    * Version - String
//    * VersionDate - String
//    * Description - String
//    * FileName - String
//    * FileAddress - String
//    * ErrorCode - String
//  ResultAddress - String - Temp storage address. If specified, the operation result will be put to the storage.
//      Structure:
//       # Result - Boolean - If "False", errors occur.
//       # Errors - Map:
//         ## Key - String - Add-in UUID.
//         ## Value - String - Message text.
//       # Success - Map:
//         ## Key - String - Add-in UUID.
//         ## Value - String - Message text.
//
Procedure UpdateAddIns(AddInsData, ResultAddress = Undefined) Export
	
	If Not Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		Raise NStr("vi = 'Thao tác không khả dụng.';
					|ru = 'Действие недоступно.';
					|en = 'Action is unavailable.'; fa = 'Action is unavailable.';
					|it = 'Action is unavailable.';
					|pl = 'Action is unavailable.';
					|tr = 'Eylem kullanılamıyor.'");
	EndIf;
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("Result", False);
	ExecutionResult.Insert("Errors", New Map);
	ExecutionResult.Insert("Success", New Map);
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	AddIns.Ref AS Ref,
		|	AddIns.Id AS Id,
		|	AddIns.Version AS Version,
		|	AddIns.VersionDate AS VersionDate
		|FROM
		|	Catalog.AddIns AS AddIns
		|WHERE
		|	AddIns.Id IN(&IDs)";
	
	Query.SetParameter("IDs", AddInsData.UnloadColumn("Id"));
	Selection = Query.Execute().Select();
	
	UsedAddIns = Undefined;
	For Each ResultString1 In AddInsData Do
		
		AddInPresentation = AddInsInternal.AddInPresentation(
			ResultString1.Id, ResultString1.Version);
		
		ErrorCode = ResultString1.ErrorCode;
		
		If ValueIsFilled(ErrorCode) Then
			
			If ErrorCode = "LatestVersion" Then
				ExecutionResult.Success.Insert(ResultString1.Id,
					StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 - phiên bản cập nhật.';
						|ru = '%1 - актуальная версия.';
						|en = '%1: the latest version.'; fa = '%1: the latest version.';
						|it = '%1 - versione aggiornata.';
						|pl = '%1 - aktualna wersja.';
						|tr = '%1 - geçerli versiyon.'"), AddInPresentation));
				Continue;
			EndIf;
			
			ErrorInfo = "";
			If ErrorCode = "ComponentNotFound" Then 
				ErrorInfo = NStr("vi = 'Dịch vụ thiếu cấu phần bên ngoài này.';
								|ru = 'В сервисе отсутствует данная внешняя компонента.';
								|en = 'This add-in is missing in the service.'; fa = 'This add-in is missing in the service.';
								|it = 'This add-in is missing in the service.';
								|pl = 'This add-in is missing in the service.';
								|tr = 'Hizmette bu harici bileşen mevcut değil.'");
			ElsIf ErrorCode = "FileNotImported" Then 
				ErrorInfo = NStr("vi = 'Chưa kết nhập tệp cấu phần ngoài từ dịch vụ.';
								|ru = 'Файл внешней компоненты не загружен из сервиса.';
								|en = 'The add-in file is not imported from the service.'; fa = 'The add-in file is not imported from the service.';
								|it = 'The add-in file is not imported from the service.';
								|pl = 'The add-in file is not imported from the service.';
								|tr = 'Harici dosya bileşenleri hizmetten indirilemedi.'");
			EndIf;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không tải được thành phần bên ngoài %1 từ server:
				           |%2';
				           |ru = 'Не удалось загрузить внешнюю компоненту %1 из сервиса:
				           |%2';
				           |en = 'Cannot import the %1 add-in from the service:
				           |%2'; fa = 'Cannot import the %1 add-in from the service:
				           |%2';
				           |it = 'Impossibile caricare il componente esterno %1 dal service:
				           |%2';
				           |pl = 'Nie udało się pobrać komponentu %1 z serwisu:
				           |%2';
				           |tr = 'Hizmetten %1 harici bileşen dosyası yüklenemedi:
				           |%2'"),
				AddInPresentation, ErrorInfo);
			
			ExecutionResult.Errors.Insert(ResultString1.Id, ErrorText);
		
			WriteLogEvent(NStr("vi = 'Cập nhật cấu phần ngoài';
								|ru = 'Обновление внешних компонент';
								|en = 'Updating add-ins'; fa = 'به‌روزرسانی افزونه‌ها';
								|it = 'Aggiornamento dei componenti esterni';
								|pl = 'Aktualizacja komponentów zewnętrznych';
								|tr = 'Harici bileşenlerin yenilenmesi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,,,	ErrorText);
			
			Continue;
		EndIf;
		
		BinaryData = GetFromTempStorage(ResultString1.FileAddress);
		Information = AddInsInternal.InformationOnAddInFromFile(BinaryData, False);
		
		If Not Information.Disassembled Then
			
			ExecutionResult.Errors.Insert(ResultString1.Id, AddInPresentation + " - "
				+ Information.ErrorDescription + ?(Information.ErrorInfo = Undefined, "", ": "
				+ ErrorProcessing.BriefErrorDescription(Information.ErrorInfo)));

			WriteLogEvent(NStr("vi = 'Cập nhật cấu phần ngoài';
								|ru = 'Обновление внешних компонент';
								|en = 'Updating add-ins'; fa = 'به‌روزرسانی افزونه‌ها';
								|it = 'Aggiornamento dei componenti esterni';
								|pl = 'Aktualizacja komponentów zewnętrznych';
								|tr = 'Harici bileşenlerin yenilenmesi'",
				Common.DefaultLanguageCode()), EventLogLevel.Error, , ,
				Information.ErrorDescription);
			Continue;
		EndIf;
		
		// Find the ref.
		Filter = New Structure("Id", ResultString1.Id);
		Selection.Reset();
		If Selection.FindNext(Filter) Then 
			// If the earlier add-in than on 1C:ITS Portal is imported, it should not be updated.
			If Selection.VersionDate > ResultString1.VersionDate Then 
				AddInPresentation = AddInsInternal.AddInPresentation(
					ResultString1.Id, Selection.Version);
				
				ExecutionResult.Success.Insert(ResultString1.Id,
					StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = '%1 - ứng dụng có phiên bản mới hơn so với trong dịch vụ (%2 ngày %3).';
							|ru = '%1 - в приложении более новая версия, чем в сервисе (%2 от %3).';
							|en = '%1: the application contains a version that is newer than the version in the service (%2 dated %3).'; fa = '%1: the application contains a version that is newer than the version in the service (%2 dated %3).';
							|it = '%1 - в приложении более новая версия, чем в сервисе (%2 от %3).';
							|pl = '%1: the application contains a version that is newer than the version in the service (%2 dated %3).';
							|tr = '%1 - uygulamadaki versiyon, hizmetteki versiyondan daha yenidir (%3 üzerinden %2).'"), 
						AddInPresentation, ResultString1.Version, Format(ResultString1.VersionDate, "DLF=D")));
				Continue;
			EndIf;
			
			ObjectReference = Selection.Ref;
		Else
			ObjectReference = Undefined;
			If UsedAddIns = Undefined Then
				UsedAddIns = AddInsInternal.UsedAddIns();
			EndIf;
			RowOfAddIn = UsedAddIns.Find(ResultString1.Id, "Id");
			If RowOfAddIn <> Undefined Then
				AutoUpdate = RowOfAddIn.AutoUpdate;
			Else
				AutoUpdate = False;
			EndIf;
		EndIf;
			
		BeginTransaction();
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("Catalog.AddIns");
			If ObjectReference <> Undefined Then
				LockItem.SetValue("Ref", ObjectReference);
			EndIf;
			Block.Lock();
			
			If ObjectReference <> Undefined Then
				Object = ObjectReference.GetObject();
				Object.Lock();
			Else
				Object = Catalogs.AddIns.CreateItem();
				Object.UpdateFrom1CITSPortal = AutoUpdate;
				Object.Use = Enums.AddInUsageOptions.Used;
			EndIf;
			
			FillPropertyValues(Object, Information.Attributes); // According to manifest data.
			FillPropertyValues(Object, ResultString1);     // By data from the website.
			
			Object.TargetPlatforms = New ValueStorage(Information.Attributes.TargetPlatforms, New Deflation(9));
			Object.AdditionalProperties.Insert("ComponentBinaryData", Information.BinaryData);
			
			Object.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã kết nhập từ Cổng 1C:ITS. %1.';
					|ru = 'Загружена с Портала 1С:ИТС. %1.';
					|en = 'Imported from 1C:ITS Portal. %1.'; fa = 'Imported from 1C:ITS Portal. %1.';
					|it = 'Scaricato dal portale 1C:ITS. %1.';
					|pl = 'Pobrano z portalu 1C:ITS. %1.';
					|tr = '1C:ITS portalından yüklendi. %1.'"),
				CurrentSessionDate());
			
			Object.Write();
			
			ExecutionResult.Success.Insert(ResultString1.Id, 
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = '%1 - cập nhật thành công.';
						|ru = '%1 - успешно обновлена.';
						|en = '%1: updated.'; fa = '%1: updated.';
						|it = '%1 - aggiornato con successo.';
						|pl = '%1 - pomyślnie aktualizowano.';
						|tr = '%1 - başarıyla güncellendi.'"), AddInPresentation));
			
			CommitTransaction();
		Except
			RollbackTransaction();
			
			ExecutionResult.Errors.Insert(ResultString1.Id, AddInPresentation
				+ " - " + ErrorProcessing.BriefErrorDescription(ErrorInfo()));
				
			WriteLogEvent(NStr("vi = 'Cập nhật cấu phần ngoài';
								|ru = 'Обновление внешних компонент';
								|en = 'Updating add-ins'; fa = 'به‌روزرسانی افزونه‌ها';
								|it = 'Aggiornamento dei componenti esterni';
								|pl = 'Aktualizacja komponentów zewnętrznych';
								|tr = 'Harici bileşenlerin yenilenmesi'",
					Common.DefaultLanguageCode()),
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndDo;
	
	ExecutionResult.Result = ExecutionResult.Errors.Count() = 0;
	
	If ValueIsFilled(ResultAddress) Then 
		PutToTempStorage(ExecutionResult, ResultAddress);
	EndIf;
	
EndProcedure

// Returns:
//  Structure:
//      * Id - String
//      * Version - String
//      * VersionDate - Date
//      * Description - String
//      * FileName - String
//      * PathToFile - String
//
Function SuppliedSharedAddInDetails() Export
	
	LongDesc = New Structure;
	LongDesc.Insert("Id");
	LongDesc.Insert("Version");
	LongDesc.Insert("VersionDate");
	LongDesc.Insert("Description");
	LongDesc.Insert("FileName");
	LongDesc.Insert("PathToFile");
	Return LongDesc;
	
EndFunction

// Updates add-ins shares.
//
// Parameters:
//  ComponentDetails - See SuppliedSharedAddInDetails.
//
Procedure UpdateSharedAddIn(ComponentDetails) Export
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.AddInsSaaS") Then
		ModuleAddInsSaaSInternal = Common.CommonModule("AddInsSaaSInternal");
		ModuleAddInsSaaSInternal.UpdateSharedAddIn(ComponentDetails);
	EndIf;
	
EndProcedure

// For OSL versions 2.7.2.0 and later, use ComponentsToUse("ForUpdate").
// Returns a table containing the details of the add-ins that must be auto-updated from 1C:ITS Portal.
//
// Returns:
//  ValueTable:
//    * Id - String - The add-in UUID manually specified in the publication base.
//                   
//    * Version        - String - The add-in version.
//    * Description  - String - The add-in description.
//    * VersionDate    - Date - The date the add-in version (build) was released.
//    * AutoUpdate - Boolean - The add-in auto-update flag.
//
Function AutomaticallyUpdatedAddIns() Export
	
	If Not Common.SubsystemExists("OnlineUserSupport.GetAddIns") Then
		Raise NStr("vi = 'Thao tác không khả dụng.';
					|ru = 'Действие недоступно.';
					|en = 'Action is unavailable.'; fa = 'Action is unavailable.';
					|it = 'Action is unavailable.';
					|pl = 'Action is unavailable.';
					|tr = 'Eylem kullanılamıyor.'");
	EndIf;
	
	ModuleGetAddIns = Common.CommonModule("GetAddIns");
	AddInsDetails = ModuleGetAddIns.AddInsDetails();
	
	AddInsData = AddInsInternal.AddInsData("ForUpdate");
	For Each ComponentDetails In AddInsData Do
		NewRow = AddInsDetails.Add();
		FillPropertyValues(NewRow, ComponentDetails);
	EndDo;
	
	Return AddInsDetails;
	
EndFunction

// End OnlineUserSupport.GetAddIns

#EndRegion

#EndRegion

