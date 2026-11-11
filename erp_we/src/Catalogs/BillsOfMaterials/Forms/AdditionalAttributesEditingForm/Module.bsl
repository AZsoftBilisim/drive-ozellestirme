
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("Title",              Title);
	Parameters.Property("OwnerID", OwnerID);
	Parameters.Property("ItemKind",            ItemKind);
	Parameters.Property("ItemTypeName",        ItemTypeName);
	
	CurrentObject = Catalogs[ItemTypeName].CreateItem();
	
	AddressOfPropertyTable = Undefined;
	If Parameters.Property("AddressOfPropertyTable", AddressOfPropertyTable)
			And IsTempStorageURL(AddressOfPropertyTable) Then
		CurrentObject.AdditionalAttributes.Load(GetFromTempStorage(AddressOfPropertyTable));
	EndIf;
	
	ObjectAttributeName = ObjectAttributeName(ItemKind);
	ValueToFormAttribute(CurrentObject, ObjectAttributeName);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", ThisObject[ObjectAttributeName]);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		StandardProcessing = False;
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject),
			NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
				|ru = 'Данные были изменены. Сохранить изменения?';
				|en = 'The data has changed. Do you want to save the changes?'; fa = 'The data has changed. Do you want to save the changes?';
				|it = 'I dati sono stati modificati. Salvare le modifiche?';
				|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
				|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'"),
			QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ThisObject[ObjectAttributeName]);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveAndLoad(Command)
	
	CompleteEditing();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CompleteEditing()
	
	Result = FinishEditingOnServer();
	
	If Result <> Undefined Then
		
		Modified = False;
		
		Close(Result);
		
	EndIf;
	
EndProcedure

&AtServer
Function FinishEditingOnServer()
	
	If CheckFilling() Then
	
		CurrentObject = ThisObject[ObjectAttributeName];
		
		PropertyManager.TransferValuesFromFormAttributesToObject(ThisObject, CurrentObject);
		
		Return PutToTempStorage(CurrentObject.AdditionalAttributes.Unload(), OwnerID);
		
	Else
		
		Return Undefined;
		
	EndIf;
	
EndFunction

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CompleteEditing();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function ObjectAttributeName(ItemKind)
	
	AvailableAttributes = New Structure;
	AvailableAttributes.Insert("Stage",     "StageObject");
	AvailableAttributes.Insert("Operation", "OperationObject");
	
	Return AvailableAttributes[ItemKind];
	
EndFunction

#Region UniversalMechanisms

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject, ThisObject[ObjectAttributeName]);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject, ThisObject[ObjectAttributeName]);
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#EndRegion