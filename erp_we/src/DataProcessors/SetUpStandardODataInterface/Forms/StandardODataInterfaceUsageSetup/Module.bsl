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
	
	If Not AccessRight("DataAdministration", Metadata) Then
		Raise(NStr("vi = 'Không đủ quyền để tùy chỉnh dịch vụ REST tự động.';
					|ru = 'Недостаточно прав для настройки автоматического REST-сервиса.';
					|en = 'Insufficient rights to configure automatic REST service.'; fa = 'Insufficient rights to configure automatic REST service.';
					|it = 'Недостаточно прав для настройки автоматического REST-сервиса.';
					|pl = 'Insufficient rights to configure automatic REST service.';
					|tr = 'Otomatik REST hizmetini kurmak için haklar yetersiz.'"),
			ErrorCategory.AccessViolation);
	EndIf;
	
	AuthorizationSettings = DataProcessors.SetUpStandardODataInterface.AuthorizationSettingsForStandardODataInterface();
	CreateStandardODataInterfaceUser = AuthorizationSettings.Used;
	
	If ValueIsFilled(AuthorizationSettings.Login) Then
		
		UserName = AuthorizationSettings.Login;
		If CreateStandardODataInterfaceUser Then
			
			CheckPasswordChange = String(New UUID());
			Password = CheckPasswordChange;
			PasswordConfirmation = CheckPasswordChange;
			
		EndIf;
		
	Else
		UserName = "odata.user";
	EndIf;
		
	SetVisibilityAndAvailability();
	SetConditionalAppearance();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not CreateStandardODataInterfaceUser Then
		Return;
	EndIf;
		
	CheckedAttributes.Add("UserName");
	CheckedAttributes.Add("Password");
	CheckedAttributes.Add("PasswordConfirmation");
	
	If Password <> PasswordConfirmation Then
		Common.MessageToUser(NStr("vi = 'Xác nhận mật khẩu không trùng với mật khẩu';
									|ru = 'Подтверждение пароля не совпадает с паролем';
									|en = 'Password confirmation does not match password'; fa = 'Password confirmation does not match password';
									|it = 'La conferma della password non coincide con la password';
									|pl = 'Potwierdzenie hasła nie pasuje do hasła';
									|tr = 'Onaylama şifresi parolayla uyuşmuyor'"), , "PasswordConfirmation");
		Cancel = True;
	EndIf;
	
	If MetadataObjects.GetItems().Count() = 0 Then
		Common.MessageToUser(
			NStr("vi = 'Chưa chỉ ra các đối tượng mà có thể truy cập thông qua dịch vụ REST tự động.';
				|ru = 'Не указаны объекты, доступ к которым может быть предоставлен через автоматический REST-сервис.';
				|en = 'Objects that you can access via automatic REST service are not specified.'; fa = 'Objects that you can access via automatic REST service are not specified.';
				|it = 'Non sono indicati gli oggetti, l''accesso ai quali può essere previsto tramite il servizio automatico REST.';
				|pl = 'Nie podano obiektów, dostęp do których może być udzielony przez automatyczną usługę REST.';
				|tr = 'Otomatik REST hizmeti aracılığıyla erişilebilen nesneler belirtilmemiştir.'"),, 
			"MetadataObjects");
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If Modified Then
		
		Cancel = True;
		
		CallbackDescription = New CallbackDescription("ContinueClosingAfterQuestion", ThisObject);
		ShowQueryBox(CallbackDescription, NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
												|ru = 'Данные были изменены. Сохранить изменения?';
												|en = 'The data was changed. Do you want to save the changes?'; fa = 'The data was changed. Do you want to save the changes?';
												|it = 'I dati sono stati modificati. Salvare le modifiche?';
												|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
												|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'"), QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MetadataObjectsUseOnChange(Item)
	
	CurrentData = Items.MetadataObjects.CurrentData;
	
	If CurrentData.Use Then
		Create = True;
		Dependencies = DependenciesToAddObject(CurrentData.GetID());
	Else
		Create = False;
		Dependencies = DependenciesToDeleteObject(CurrentData.GetID());
	EndIf;
	
	If Dependencies.Count() > 0 Then
		
		FormParameters = New Structure();
		FormParameters.Insert("FullObjectName", CurrentData.FullName);
		FormParameters.Insert("ObjectDependencies", Dependencies);
		FormParameters.Insert("Create", Create);
		
		Context = New Structure();
		Context.Insert("Dependencies", Dependencies);
		Context.Insert("Create", Create);
		
		CallbackDescription = New CallbackDescription("MetadataObjectsUseOnChangeContinued", ThisObject, Context);
		
		OpenForm("DataProcessor.SetUpStandardODataInterface.Form.MetadataObjectDependencies",
			FormParameters,,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateStandardODataInterfaceUserOnChange(Item)
	
	SetVisibilityAndAvailability();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Function Save(Command = Undefined)
	
	ClearMessages();
	
	If Not Modified Then
		Return True;
	EndIf;
		
	If Not CheckFilling() Then
		Return False;
	EndIf;
	
	SaveAtServer();
	Return True;
	
EndFunction

&AtClient
Procedure SaveAndLoad(Command = Undefined)
	
	If Save() Then
		Close();
	EndIf;	
	
EndProcedure

&AtClient
Procedure ImportMetadata(Command)
	
	If Modified
		And MetadataObjects.GetItems().Count() > 0 Then
		
		Notification = New CallbackDescription("ImportMetadataContinued", ThisObject);
		ShowQueryBox(Notification, NStr("vi = 'Kết nhập lại metadata? Những thay đổi đã nhập sẽ bị mất.';
										|ru = 'Загрузить метаданные заново? Внесенные изменения будут потеряны.';
										|en = 'Import metadata again? The changes made will be lost.'; fa = 'Import metadata again? The changes made will be lost.';
										|it = 'Scaricare i metadati nuovamente? Le modifiche apportate andranno perse.';
										|pl = 'Pobrać metadane ponownie? Wprowadzone zmiany zostaną utracone.';
										|tr = 'Meta veriler yeniden yüklensin mi? Değişiklikleriniz kaybolacak.'"), QuestionDialogMode.YesNo);
		
	Else
		ImportMetadataContinued(DialogReturnCode.Yes, Undefined);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ImportMetadataContinued(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Result = StartPreparingSetupParameters();
	JobID = Result.JobID;
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	Notification = New CallbackDescription("SetupParametersReceivingCompletion", ThisObject);
	If Result.Status = "Completed2" Then
		RunCallback(Notification, Result);
	Else
		TimeConsumingOperationsClient.WaitCompletion(Result, Notification,
			TimeConsumingOperationsClient.IdleParameters(ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinueClosingAfterQuestion(Result, Context) Export
	
	If Result = DialogReturnCode.Yes Then
		SaveAndLoad();
	ElsIf Result = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

// Parameters:
//   Result - DialogReturnCode
//             - Undefined
//   Context  - Structure
//
&AtClient
Procedure MetadataObjectsUseOnChangeContinued(Result, Context) Export
	
	If Result = DialogReturnCode.Yes Then
		SetDependenciesUsage(Context.Dependencies, Context.Create);
	Else
		Items.MetadataObjects.CurrentData.Use = Not Items.MetadataObjects.CurrentData.Use;
	EndIf;
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure SetupParametersReceivingCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	If Result.Status <> "Completed2" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	ImportSetupParameters(Result.ResultAddress);
	
EndProcedure

&AtServer
Procedure SetVisibilityAndAvailability()
	
	Items.UsernameAndPassword.Enabled = CreateStandardODataInterfaceUser;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	Item.Use = True;
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("MetadataObjectsUse");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MetadataObjects.Root");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Show", False);
	
EndProcedure

&AtServer
Function DependenciesToAddObject(Val RowID)
	
	DependenciesTable = FormAttributeToValue("DependenciesForAdding");
	Return ObjectDependencies(RowID, DependenciesTable, True);
	
EndFunction

&AtServer
Function DependenciesToDeleteObject(Val RowID)
	
	DependenciesTable = FormAttributeToValue("DependenciesForDeletion");
	Return ObjectDependencies(RowID, DependenciesTable, False);
	
EndFunction

&AtServer
Function ObjectDependencies(Val RowID, DependenciesTable, UseValue)
	
	CurrentObjectName = MetadataObjects.FindByID(RowID).FullName;
	
	ObjectsTree = FormAttributeToValue("MetadataObjects");
	
	Result = ObjectDependenciesByString(
		ObjectsTree, DependenciesTable, CurrentObjectName, UseValue);
	
	Return Result;
	
EndFunction

&AtServer
Function ObjectDependenciesByString(ObjectsTree, DependenciesTable, InitialObjectName, UseValue)
	
	Result = New Array;
	
	ProcessingQueue = New Array;
	ProcessingQueue.Add(InitialObjectName);
	
	IndexOf = 0;
	While IndexOf < ProcessingQueue.Count() Do
		
		CurrentName = ProcessingQueue[IndexOf];
		IndexOf = IndexOf + 1;
		
		// Searching for lines where the current object is the parent.
		FilterParameters = New Structure("ObjectName", CurrentName);
		DependenciesStrings = DependenciesTable.FindRows(FilterParameters);
		
		For Each String In DependenciesStrings Do
			
			DependentItemName = String.DependentObjectName;
			
			If Result.Find(DependentItemName) <> Undefined Then
				Continue;
			EndIf;
			
			DependentInTree = ObjectsTree.Rows.Find(DependentItemName, "FullName", True);
			
			If DependentInTree <> Undefined
				And DependentInTree.Use <> UseValue Then
				
				Result.Add(DependentItemName);
				
				ProcessingQueue.Add(DependentItemName);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetDependenciesUsage(Val Dependencies, Val Use)
	
	RootItems = MetadataObjects.GetItems();
	For Each RootItem In RootItems Do
		
		TreeItems = RootItem.GetItems();
		For Each TreeItem In TreeItems Do
			
			If Dependencies.Find(TreeItem.FullName) <> Undefined Then
				TreeItem.Use = Use;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SaveAtServer()
	
	BeginTransaction();
	
	Try
		
		Settings = New Structure();
		
		Settings.Insert("Used", CreateStandardODataInterfaceUser);
		Settings.Insert("Login", UserName);
		If CheckPasswordChange <> Password Then
			Settings.Insert("Password", Password);
		EndIf;
		
		DataProcessors.SetUpStandardODataInterface.WriteAuthorizationSettingsForStandardODataInterface(Settings);
		
		Content = New Array();
		Tree = FormAttributeToValue("MetadataObjects");
		Rows = Tree.Rows.FindRows(New Structure("Use", True), True);
		For Each String In Rows Do
			Content.Add(String.FullName);
		EndDo;
		
		SetStandardODataInterfaceContent(Content);
		
		Modified = False;
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServer
Procedure ImportSetupParameters(Val StorageAddress)
	
	Data = GetFromTempStorage(StorageAddress);
	If TypeOf(Data) <> Type("Structure") Then
		Return;
	EndIf;
	
	ValueToFormAttribute(Data.ObjectsTree, "MetadataObjects");
	ValueToFormAttribute(Data.AdditionDependencies, "DependenciesForAdding");
	ValueToFormAttribute(Data.DeletionDependencies, "DependenciesForDeletion");
	
EndProcedure

&AtServer
Function StartPreparingSetupParameters()
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = "PrepareStandardODataInterfaceContentSetupParameters";
	
	Return TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.SetUpStandardODataInterface.PrepareStandardODataInterfaceContentSetupParameters",
		New Structure,
		BackgroundExecutionParameters);
	
EndFunction

#EndRegion


