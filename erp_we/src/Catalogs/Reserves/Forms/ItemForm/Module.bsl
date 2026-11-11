#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(PurposeUseKey) Then
		PurposeUseKey = "FutureExpenseCommitments";
	EndIf;
	
	Items.ReserveType.ListChoiceMode = True;
	Items.ReserveType.ChoiceList.LoadValues(
		Enums.TypesOfProvisionsAndContingentLiabilities.TypesOfReservesByPurpose(PurposeUseKey));
	
	If Not ValueIsFilled(Object.Ref) Then
		OnCreatReadAtServer();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnCreatReadAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Cancel Then
		Return;
	EndIf;
	
	GLAccountSettingsServer.WhenWritingAccountSettingsObject(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_Reserves", WriteParameters, Object.Ref);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
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
	
	GLAccountSettingsClient.FinishedSettingUpAccountingAccounts(ThisObject, EventName, Parameter);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	GLAccountSettingsServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DiscountingOfEstimatedObligationOnChange(Item)
	CheckPossibilityOfNegativeBalanceSheetValue();
	ManagingFormOnServer();
EndProcedure

&AtClient
Procedure ReserveTypeOnChange(Item)
	CheckPossibilityOfNegativeBalanceSheetValue();
	ManagingFormOnServer();
EndProcedure

#Region SettingUpAccountingAccounts_EventHandlersForFormHeaderElements

&AtClient
Procedure LinkSettingUpAccountingAccountsProcessingTheNavigationLink(Item, FormattedStringURL, StandardProcessing)

	GLAccountSettingsClient.ProcessingNavigationLinkSettingUpAccountingAccounts(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_OnChange_SettingUpAccountingAccounts(Item)
	GLAccountSettingsClient.OnChange(Item, ThisObject);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure Attachable_StartOfSelection_SettingUpAccountingAccounts(Item, ChoiceData, StandardProcessing)
	GLAccountSettingsClient.StartChoice(ThisObject, Item, ChoiceData, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure Attachable_Regulation_SettingUpAccountingAccounts(Item, Direction, StandardProcessing)
	GLAccountSettingsClient.Tuning(ThisObject, Item, Direction, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure Attachable_Cleaning_SettingUpAccountingAccounts(Item, StandardProcessing)
	GLAccountSettingsClient.Clearing(ThisObject, Item, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

#Region StandardSubsystems

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#EndRegion

#Region Private

&AtClient
Procedure CheckPossibilityOfNegativeBalanceSheetValue()
	If Not (Object.ReserveType = PredefinedValue("Enum.TypesOfProvisionsAndContingentLiabilities.ResidualLiabilities")
			And Object.ProvisionDiscounting) Then
		Object.DepreciationComponentBookValueCanBeNegative = False;
	EndIf;
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	If PurposeUseKey = "WageReserves" Then
		
		Items.GroupPropertiesOfTypeOfReserveForUpcomingExpenses.Visible = False;
		
		Title = StrTemplate(NStr("vi = '%1 (Dự phòng thanh toán tiền lương)';
								|ru = '%1 (Резерв на оплату труда)';
								|en = '%1 (Payroll fund)'; fa = '%1 (Payroll fund)';
								|it = '%1 (Резерв на оплату труда)';
								|pl = '%1 (Payroll fund)';
								|tr = '%1 (Ücret yedeği)'"), Object.Description);
		AutoTitle = False;
		
	Else
		
		GLAccountSettingsServer.WhenReadingCreatingAccountSettingsObject(ThisObject);
		
	EndIf;

	ManagingFormOnServer();
	
EndProcedure

&AtServer
Procedure ManagingFormOnServer()

	Items.DepreciationComponentBookValueCanBeNegative.Enabled = False;
		
	If Object.ReserveType = PredefinedValue("Enum.TypesOfProvisionsAndContingentLiabilities.ResidualLiabilities")
			And Object.ProvisionDiscounting Then
		Items.DepreciationComponentBookValueCanBeNegative.Enabled = True;
	EndIf;

EndProcedure

#Region StandardSubsystemsProperties

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

#EndRegion

#EndRegion
