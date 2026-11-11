
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	If Object.Ref.IsEmpty() Then
		UnitOfMeasureIsDeterminedByDimension = Object.UnitOfMeasureIsDeterminedByDimension;
		CurrencyIsDeterminedByDimension = Object.CurrencyIsDeterminedByDimension;
		If Parameters.Property("CopyingValue") And ValueIsFilled(Parameters.CopyingValue) Then
			CopyingValue = Parameters.CopyingValue;
		EndIf;
	EndIf;
	
	LimitedTransactions = LimitsByBudgetingDataServer.UsedLimitedOFOperations();
	If LimitedTransactions.Count() > 0 Then
		Items.LimitedTransaction.ChoiceList.LoadValues(LimitedTransactions);
	Else
		Items.LimitedTransaction.Visible = False;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties

	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	// Copying rules for obtaining actual data
	If ValueIsFilled(CopyingValue)
	   And Not ValueIsFilled(Object.Ref)
	   And (Not WriteParameters.Property("NotCopyRulesForGettingFact")
	      And Not WriteParameters.Property("CopyRulesForGettingFact")) Then
		
		Cancel = True;
		ShowQueryBox(
			New CallbackDescription("AfterAnsweringQuestionAboutCopyingRules", ThisObject, WriteParameters),
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Ngoài ra, sao chép quy tắc nhận dữ kiện theo dạng ""%1""?';
					|ru = 'Скопировать также правила получения факта по статье ""%1""?';
					|en = 'Do you want to copy the rules for obtaining actual data on the ""%1"" item as well?'; fa = 'Do you want to copy the rules for obtaining actual data on the ""%1"" item as well?';
					|it = 'Скопировать также правила получения факта по статье ""%1""?';
					|pl = 'Do you want to copy the rules for obtaining actual data on the ""%1"" item as well?';
					|tr = '""%1"" kalemine göre gerçeği alma kurallarını da kopyansın mı?'"), String(CopyingValue)),
			QuestionDialogMode.YesNo);
		Return;
	EndIf;

EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If WriteParameters.Property("CopyRulesForGettingFact") Then
		BudgetingServer.CopyRulesForGettingActualData(CopyingValue, CurrentObject.Ref);
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.ObjectAttributesLock
	ObjectAttributesLock.LockAttributes(ThisObject);
	// End StandardSubsystems.ObjectAttributesLock
	FormControl(ThisObject);

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_BudgetFlowItems", Object.Description, Object.Ref);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	UnitOfMeasureIsDeterminedByDimension = Object.UnitOfMeasureIsDeterminedByDimension;
	CurrencyIsDeterminedByDimension = Object.CurrencyIsDeterminedByDimension;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DimensionKindOnChange(Item)
	
	FormControl(ThisObject);
	SetRelatedParameters();
	
EndProcedure

&AtClient
Procedure AccountingByQuantityWhenChanging(Item)
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure AccountingByCurrencyWhenChanging(Item)
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure DefineTheUnitOfMeasurementWhenChanging(Item)
	
	If UnitOfMeasureIsDeterminedByDimension Then
		Object.UnitOfMeasure = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	Else
		Object.DimensionUnitsOfMeasurement = Undefined;
	EndIf;
	
	Object.UnitOfMeasureIsDeterminedByDimension = UnitOfMeasureIsDeterminedByDimension;
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure CurrencyIsDeterminedByDimensionOnChange(Item)
	
	If Not CurrencyIsDeterminedByDimension Then
		Object.DimensionCurrencies = Undefined;
	EndIf;
	
	Object.CurrencyIsDeterminedByDimension = CurrencyIsDeterminedByDimension;
	
	FormControl(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.NotificationAboutUnblocking = New CallbackDescription("AllowObjectAttributeEditCompletion", ThisObject);
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject, ProcedureParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Private

// StandardSubsystems.Properties 
&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

#Region Other

&AtClientAtServerNoContext
Procedure FormControl(Form)
	
	FormItems = Form.Items;
	
	If Not FormItems.RecordByQuantity.ReadOnly Then
		QuantityAvailability = Form.Object.RecordByQuantity;
		FormItems.UnitOfMeasureIsDeterminedByDimension.Enabled = QuantityAvailability;
		FormItems.SpecifiedUnitOfMeasure.Enabled = QuantityAvailability;
		DefineUnitOfMeasurement = Form.UnitOfMeasureIsDeterminedByDimension;
		
		FormItems.UnitOfMeasure.Enabled = QuantityAvailability And Not DefineUnitOfMeasurement;
		FormItems.DimensionUnitsOfMeasurement.Enabled = QuantityAvailability And DefineUnitOfMeasurement;
	Else
		FormItems.UnitOfMeasureIsDeterminedByDimension.Enabled = False;
		FormItems.SpecifiedUnitOfMeasure.Enabled = False;
		FormItems.UnitOfMeasure.Enabled = False;
		FormItems.DimensionUnitsOfMeasurement.Enabled = False;
	EndIf;
	
	If Not FormItems.RecordByCurrency.ReadOnly Then
		CurrencyAvailability = Form.Object.RecordByCurrency;
		FormItems.CurrencyIsDeterminedByDimension.Enabled = CurrencyAvailability;
		FormItems.CurrencyIsSpecifiedInTheBudgetProfile.Enabled = CurrencyAvailability;
		CurrencyIsDeterminedByDimension = Form.CurrencyIsDeterminedByDimension;
		FormItems.DimensionCurrencies.Enabled = CurrencyAvailability And CurrencyIsDeterminedByDimension;
	Else
		FormItems.CurrencyIsDeterminedByDimension.Enabled = False;
		FormItems.CurrencyIsSpecifiedInTheBudgetProfile.Enabled = False;
		FormItems.DimensionCurrencies.Enabled = False;
	EndIf;
	
	Array = New Array;
	For Cnt = 1 To 6 Do
		Array.Add(Form.Object["DimensionKind" + Cnt]);
	EndDo;
	
	ChoiceParameters = Form.Items.DimensionUnitsOfMeasurement.ChoiceParameters;
	ChoiceArray = New Array(ChoiceParameters);
	ChoiceArray[1] = 
		New ChoiceParameter("Filter.Ref", New FixedArray(Array));
	Form.Items.DimensionUnitsOfMeasurement.ChoiceParameters = New FixedArray(ChoiceArray);
	
	ChoiceParameters = Form.Items.DimensionCurrencies.ChoiceParameters;
	ChoiceArray = New Array(ChoiceParameters);
	ChoiceArray[1] = 
		New ChoiceParameter("Filter.Ref", New FixedArray(Array));
	Form.Items.DimensionCurrencies.ChoiceParameters = New FixedArray(ChoiceArray);
	
EndProcedure

&AtClient
Procedure SetRelatedParameters()
	
	Array = New Array;
	For Cnt = 1 To 6 Do
		Array.Add(Object["DimensionKind" + Cnt]);
	EndDo;
	
	If Array.Find(Object.DimensionCurrencies) = Undefined Then
		Object.DimensionCurrencies = Undefined;
	EndIf;
	
	If Array.Find(Object.DimensionUnitsOfMeasurement) = Undefined Then
		Object.DimensionUnitsOfMeasurement = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Procedure AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	FormControl(ThisObject);
	
EndProcedure

&AtClient
Procedure AfterAnsweringQuestionAboutCopyingRules(Response, WriteParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		WriteParameters.Insert("CopyRulesForGettingFact");
	Else
		WriteParameters.Insert("NotCopyRulesForGettingFact");
	EndIf;
	Write(WriteParameters);
	
EndProcedure

#EndRegion

#EndRegion
