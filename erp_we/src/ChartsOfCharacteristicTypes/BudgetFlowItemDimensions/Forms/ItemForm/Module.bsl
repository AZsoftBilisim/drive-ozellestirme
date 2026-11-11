
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		Object.ValueType = New TypeDescription;
		AddSuggestedIdValueToSelectionList();
	EndIf;
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisForm);
	// End StandardSubsystems.ObjectAttributesLock
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, Object);
	// End StandardSubsystems.Core
	
	FormControl(ThisForm);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	AddSuggestedIdValueToSelectionList();
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisForm);
	// End StandardSubsystems.ObjectAttributesLock
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_BudgetFlowItemDimensions", , Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	FormControl(ThisObject);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DescriptionOnChange(Item)
	UpdateSuggestedIDValue();
EndProcedure

&AtClient
Procedure UnitOfMeasureFillingStartChoice(Item, ChoiceData, StandardProcessing)
	
	FormParameters = New Structure;
	FormParameters.Insert("ValueTypes", Object.ValueType);
	FormParameters.Insert("Count", True);
	
	Notification = New CallbackDescription("HandlerForNotificationWhenFeatureIsSelected", ThisForm, "Count");
	OpenForm("CommonForm.SelectionOfAccountingFlagSettings", FormParameters, ,,,, Notification);
	
EndProcedure

&AtClient
Procedure CurrencyFillingStartChoice(Item, ChoiceData, StandardProcessing)
	
	FormParameters = New Structure;
	FormParameters.Insert("ValueTypes", Object.ValueType);
	FormParameters.Insert("Currency", True);
	
	Notification = New CallbackDescription("HandlerForNotificationWhenFeatureIsSelected", ThisForm, "Currency");
	OpenForm("CommonForm.SelectionOfAccountingFlagSettings", FormParameters, ,,,, Notification);
	
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConfigureDimensionType(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ValueType", Object.ValueType);
	FormParameters.Insert("AdditionalProperty", Object.AdditionalProperty);
	
	DescriptionOfTheAlert = New CallbackDescription("ProcessingAnalyticsTypeSettings", ThisObject);
	OpenForm("ChartOfCharacteristicTypes.BudgetFlowItemDimensions.Form.DimensionTypeConfiguration", 
		FormParameters, ThisForm, , , , DescriptionOfTheAlert);
	
EndProcedure

&AtClient
Procedure FillInIdentifierByRules(Command)
	Object.Id = BudgetReportingClientServer.GetID(Object.Description);
	AddSuggestedIdValueToSelectionList();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("AllowObjectAttributeEditCompletion", ThisObject);
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm, ProcedureParameters);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdateSuggestedIDValue()
	
	If Object.Ref.IsEmpty() Then
		Object.Id = BudgetReportingClientServer.GetID(Object.Description);
	EndIf;
	AddSuggestedIdValueToSelectionList();
	
EndProcedure

&AtServer
Procedure AddSuggestedIdValueToSelectionList()
	
	Id = BudgetReportingClientServer.GetID(Object.Description);
	Items.Id.ChoiceList.Clear();
	
	If Not ValueIsFilled(Object.Id) Then
		Object.Id = Id;
		Modified = True;
	ElsIf Object.Id <> Id Then
		Items.Id.ChoiceList.Add(Object.Id);
	EndIf;
	
	If Not IsBlankString(Id) Then
		Items.Id.ChoiceList.Add(Id);
	EndIf;
	
EndProcedure

&AtClient
Procedure HandlerForNotificationWhenFeatureIsSelected(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If AdditionalParameters = "Currency" Then
		Object.CurrencyPresentation = Result.Presentation;
		Object.CurrencyFilling = Result.Value;
	Else
		Object.UnitOfMeasurePresentation = Result.Presentation;
		Object.UnitOfMeasureFilling = Result.Value;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	Items = Form.Items;
	Object   = Form.Object;
	
	Items.UnitOfMeasureFilling.Enabled = Object.RecordByQuantity;
	Items.UnitOfMeasureFilling.AutoMarkIncomplete = Object.RecordByQuantity;
	
	Items.CurrencyFilling.Enabled = Object.RecordByCurrency;
	Items.CurrencyFilling.AutoMarkIncomplete = Object.RecordByCurrency;
	
	Items.FillInIdentifierByRules.Enabled = Not Items.Id.ReadOnly;
	
EndProcedure

&AtClient
Procedure RecordByQuantityOnChange(Item)
	
	FormControl(ThisForm);
	
EndProcedure

&AtClient
Procedure RecordByCurrencyOnChange(Item)
	
	FormControl(ThisForm);
	
EndProcedure

&AtClient
Procedure ProcessingAnalyticsTypeSettings(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure") Then
		Object.ValueType = Result.ValueType;
		Object.AdditionalProperty = Result.AdditionalProperty;
		Object.PresentationValueType = BudgetingClientServer.PresentationValueType(Object);
		FormControl(ThisForm);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
