///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Not MobileStandaloneServer Then

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.BatchEditObjects

// Returns the object attributes that are not recommended to be edited
// using a bulk attribute modification data processor.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("IsInternal");
	NotAttributesToEdit.Add("IBUserID");
	NotAttributesToEdit.Add("ServiceUserID");
	NotAttributesToEdit.Add("DeleteInfobaseUserProperties");
	
	Return NotAttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowRead
	|WHERE
	|	TRUE
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	IsAuthorizedUser(Ref)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.AttachableCommands

// Defines the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
EndProcedure

// Intended for use by the AddGenerationCommands procedure in other object manager modules.
// Adds this object to the list of generation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - Details of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleGeneration = Common.CommonModule("GenerateFrom");
		Return ModuleGeneration.AddGenerationCommand(GenerationCommands, Metadata.Catalogs.Users);
	EndIf;
	
	Return Undefined;
	
EndFunction

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not Parameters.Filter.Property("Invalid") Then
		Parameters.Filter.Insert("Invalid", False);
	EndIf;
	
	If Not Parameters.Filter.Property("IsInternal") Then
		Parameters.Filter.Insert("IsInternal", False);
	EndIf;
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ChoiceForm" Then
		DefaultSelectedForm = SelectedForm;
		UsersOverridable.OnDefineUsersSelectionForm(SelectedForm, Parameters);
		If DefaultSelectedForm <> SelectedForm Then
			StandardProcessing = False;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//  Source - CatalogObject.Users
//
Function HasProhibitedChanges(Source) Export
	
	If Source.AdditionalProperties.Property("IBUserDetails") Then
		Return True;
	EndIf;
	
	PreviousValues1 = Common.ObjectAttributesValues(Source.Ref,
		"Ref,
		|DeletionMark,
		|Invalid,
		|IsInternal,
		|Prepared,
		|IBUserID,
		|ServiceUserID");
	
	If ValueIsFilled(PreviousValues1.Ref) Then
		For Each DetailsAndValue In PreviousValues1 Do
			If Source[DetailsAndValue.Key] <> PreviousValues1[DetailsAndValue.Key] Then
				Return True;
			EndIf;
		EndDo;
		Return False;
	EndIf;
	
	If Source.Prepared
	 Or ValueIsFilled(Source.ServiceUserID) Then
		Return True;
	EndIf;
	
	If Not ValueIsFilled(Source.IBUserID) Then
		Return False;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	IBUser = InfoBaseUsers.FindByUUID(
		Source.IBUserID);
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Return IBUser <> Undefined;
	
EndFunction

#Region InfobaseUpdate
	
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	UsersList = UsersInternal.UsersToEnablePasswordRecovery();
	
	If UsersList.Count() > 0 Then
		EnableStandardPasswordRecoverySettings();
		InfobaseUpdate.MarkForProcessing(Parameters, UsersList);
	EndIf;
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	UserRef = InfobaseUpdate.SelectRefsToProcess(Parameters.Queue, "Catalog.Users");
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;
	ErrorList = New Array;
	
	While UserRef.Next() Do
		Result = UsersInternal.UpdateEmailForPasswordRecovery(UserRef.Ref);
		
		If Result.Status = "Error" Then
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			ErrorList.Add(Result.ErrorText);
		Else
			ObjectsProcessed = ObjectsProcessed + 1;
			InfobaseUpdate.MarkProcessingCompletion(UserRef.Ref);
		EndIf;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "Catalog.Users");
	
	If ObjectsProcessed = 0 And ObjectsWithIssuesCount <> 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không thể xử lý một số thông tin về người sử dụng (đã bỏ qua): %1
			|%2';
			|ru = 'Не удалось обработать некоторых сведения о пользователях (пропущены): %1
			|%2';
			|en = 'Couldn''t process (skipped) some external user information records: %1
			|%2'; fa = 'Couldn''t process (skipped) some external user information records: %1
			|%2';
			|it = 'Non è stato possibile elaborare alcune informazioni sugli utenti (saltate): %1
			|%2';
			|pl = 'Nie udało się przetworzyć niektórych danych o użytkowników (pominięte): %1
			|%2';
			|tr = 'Bazı kullanıcı bilgileri işlenemedi (atlandı):%1
			|%2'"), ObjectsWithIssuesCount, StrConcat(ErrorList, Chars.LF));
		Raise MessageText;
	Else
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Information,
			Metadata.Catalogs.Users,,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã xử lý tùy chọn thông tin về người sử dụng theo trình tự: %1';
					|ru = 'Обработана очередная порция сведений о пользователях: %1';
					|en = 'Yet another batch of user information records is processed: %1'; fa = 'Yet another batch of user information records is processed: %1';
					|it = 'È stata elaborata un''altra porzione di informazioni sugli utenti: %1';
					|pl = 'Przetworzono kolejną część danych o użytkownikach: %1';
					|tr = 'Başka bir kullanıcı bilgisi grubu işlendi:%1'"),
				ObjectsProcessed));
	EndIf;
	
EndProcedure

Procedure EnableStandardPasswordRecoverySettings()
	
	Settings = AdditionalAuthenticationSettings.GetPasswordRecoverySettings();
	Settings.PasswordRecoveryMethod = InfoBaseUserPasswordRecoveryMethod.SendVerificationCodeByStandardService;
	AdditionalAuthenticationSettings.SetPasswordRecoverySettings(Settings);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#EndIf