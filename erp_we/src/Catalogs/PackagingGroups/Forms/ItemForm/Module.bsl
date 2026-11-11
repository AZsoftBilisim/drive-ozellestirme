
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Object.Predefined Then
		MessageText = NStr("vi = 'Không thể chỉnh sửa phần tử định trước ""%1""';
							|ru = 'Редактирование предопределенного элемента ""%1"" не предусмотрено';
							|en = 'Editing the predefined ""%1"" item is unavailable'; fa = 'Editing the predefined ""%1"" item is unavailable';
							|it = 'Editing the predefined ""%1"" item is unavailable';
							|pl = 'Editing the predefined ""%1"" item is unavailable';
							|tr = 'Önceden tanımlanmış ""%1"" öğesinin düzenlenmesi öngörülmemiştir'");
		MessageText = StrTemplate(MessageText, Object.Description);
		
		Raise MessageText;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		"UnitNameField, LabelExplanationOfTheUnitForReports",
		"Visible",
		GetFunctionalOption("UseUnitsOfMeasureForReports"));
	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	FormEvents.OnWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	FormEventsClient.OnOpen(ThisObject, Cancel);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	FormEvents.FillCheckProcessingAtServer(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ObjectAttributesLock.LockAttributes(ThisObject);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "SelectedPackagingForReports" Then
		
		If TypeOf(Parameter) = Type("Structure")
			And Parameter.Property("ZoomRatio") Then
			Object.UnitFactorForReports = Parameter.ZoomRatio;
		EndIf;
		
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	FormEventsClient.AfterWrite(ThisObject, WriteParameters);
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Attachable_WhenChangingElement(Item)
	
	FormEventsClient.WhenChangingElement(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure UnitOfMeasureOnChange(Item)
	
	FormEventsClient.WhenChangingElement(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure UnitForReportsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("PackagingGroup", Object.Ref);
	ParametersStructure.Insert("StorageUnit", Object.UnitOfMeasure);
	ParametersStructure.Insert("UnitForReports", Object.UnitForReports);
	
	OpenForm(
		"Catalog.PackagesAndUnitsOfMeasure.Form.SelectionFormOfUnitsForReports",
		ParametersStructure,
		Item,
		,
		,
		,
		,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		OpenForm(
			"Catalog.PackagingGroups.Form.AttributeUnlocking",
			,
			,
			,
			,
			,
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject),
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array")
		And Result.Count() > 0 Then
		
		ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, Result);
		ProductsClientLocalization.AllowObjectAttributeEditCompletion(
			ThisObject, Result, AdditionalParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion
