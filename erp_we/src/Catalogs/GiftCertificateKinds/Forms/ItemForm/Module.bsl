#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		Object.Currency = LocalAccountingCurrency(Object.Organization);
		Object.Permanent = True;
		Object.PartialPayment = True;
		OnCreatReadAtServer();
	EndIf;
	
	Items.GiftCardAccounting25.Title =  NStr("vi = 'Ghi nhận phiếu quà tặng 2.5';
											|ru = 'Учет подарочных сертификатов (11.5)';
											|en = 'Gift card accounting (11.5)'; fa = 'Gift card accounting (11.5)';
											|it = 'Учет подарочных сертификатов (11.5)';
											|pl = 'Gift card accounting (11.5)';
											|tr = 'Hediye kartı muhasebesi (11.5)'");
	Items.GiftCardAccounting25.Title =  NStr("vi = 'Ghi nhận phiếu quà tặng 2.5';
											|ru = 'Учет подарочных сертификатов (2.5)';
											|en = 'Gift card accounting (2.5)'; fa = 'Gift card accounting (2.5)';
											|it = 'Учет подарочных сертификатов (2.5)';
											|pl = 'Gift card accounting (2.5)';
											|tr = 'Hediye kartı muhasebesi (2.5)'");
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetVisibilityOfOrganizationFormElement();
	SetVisibilityOfDDSArticleFormElement();
	SetVisibilityOfFinancialAccountingGroupFormElement();
	SetVisibilityOfFormElementGroupValidityPeriod();
	SetAvailabilityOfProductSegmentFormElement();
	
	If Object.PartialPayment Then
		Items.HintPartialPayment.Visible = False;
	Else
		Items.HintPartialPayment.Visible = True;;
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	GLAccountSettingsClient.FinishedSettingUpAccountingAccounts(ThisObject, EventName, Parameter);
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If CurrentObject.Permanent Then
        CurrentObject.NumberOfValidityPeriods = 999;
        CurrentObject.ActionPeriod = PredefinedValue("Enum.Periodicity.Year");
	EndIf;
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Subsystem prohibiting editing of key details of objects
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	OnCreatReadAtServer();

	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);

	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	If UseProductSegments = 1 And Not ValueIsFilled(Object.ProductSegment) Then
		
		Common.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Phân khúc mặt hàng"".';
				|ru = 'Поле ""Сегмент номенклатуры"" не заполнено.';
				|en = '""Inventory segment"" is required.'; fa = '""Inventory segment"" is required.';
				|it = 'Il campo ""segmento articolo"" non è compilato.';
				|pl = 'Nie wypełniono pola ""Segment nomenklatury"".';
				|tr = '""Stok Segmenti"" alanı doldurulmadı.'"),,"Object.ProductSegment",, Cancel);
		
	EndIf;
	GLAccountSettingsServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Cancel Then
		Return;
	EndIf;
	GLAccountSettingsServer.WhenWritingAccountSettingsObject(ThisObject, Cancel, CurrentObject, WriteParameters);
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseACustomLabelTemplateWhenChanging(Item)
	
	Object.ProductSegment = PredefinedValue("Catalog.ProductSegments.EmptyRef");
	UseProductSegments = (UseProductSegments = 1);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ProductSegment","Enabled", (UseProductSegments = 1));

EndProcedure

&AtClient
Procedure CardTypeOnChange(Item)
	
	MapTypeWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure CardTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PartialPaymentRadioButtonOnChange(Item)
	
	If PartialPaymentRadioButton = "AllowPartialPayment" Then
		Object.PartialPayment = True;
		Items.HintPartialPayment.Visible = False;	
	Else
		Object.PartialPayment = False;	
		Items.HintPartialPayment.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure LinkSettingUpAccountingAccountsProcessingTheNavigationLink(Item, FormattedStringURL, StandardProcessing)
	GLAccountSettingsClient.ProcessingNavigationLinkSettingUpAccountingAccounts(
		ThisObject, FormattedStringURL, StandardProcessing);
	Return; // The UT handler is empty
	
EndProcedure

&AtClient
Procedure GiftCardAccounting25OnChange(Item)
	
	If Object.GiftCardAccounting25 Then
		Object.ProductSegment = Undefined;
		UseProductSegments = 0;
	EndIf;
	
	SetVisibilityOfOrganizationFormElement();
	SetVisibilityOfDDSArticleFormElement();
	SetVisibilityOfFinancialAccountingGroupFormElement();
	SetAvailabilityOfProductSegmentFormElement();
	
EndProcedure

&AtClient
Procedure PermanentOnChange(Item)

    If Not Object.Permanent Then
        Object.NumberOfValidityPeriods = 1;
    EndIf;
    
    SetVisibilityOfFormElementGroupValidityPeriod()

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

#Region SettingUpAccountingAccounts_EventHandlersForFormHeaderElements

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

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	EditParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	EditParameters.OnlyVisible = False;
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject, EditParameters);
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If Result = True Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("OnlyVisible", False);
		AdditionalParameters.Insert("Form", ThisObject);
		
		TMCommonUseClient.AllowObjectAttributeEditCompletion(Result, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#Region OnChangeAttributes

&AtServer
Procedure MapTypeWhenChangedOnServer()
	
	Visible = Object.CardType = Enums.CardTypes.Magnetic Or Object.CardType = Enums.CardTypes.Mixed;
	Items.GiftCertificateCodeTemplatesMagneticCodeLength.Visible           = Visible;
	Items.GiftCertificateCodeTemplatesStartOfMagneticCodeRange.Visible = Visible;
	Items.GiftCertificateCodeTemplatesEndOfMagneticCodeRange.Visible  = Visible;
	Items.GiftCertificateCodeTemplatesMagneticCardCodeTemplate.Visible      = Visible;
	
	Visible = Object.CardType = Enums.CardTypes.Barcode_ Or Object.CardType = Enums.CardTypes.Mixed;
	Items.GiftCertificateCodeTemplatesBarcodeLength.Visible           = Visible;
	Items.GiftCertificateCodeTemplatesStartOfBarcodeRange.Visible = Visible;
	Items.GiftCertificateCodeTemplatesEndOfBarcodeRange.Visible  = Visible;
	
EndProcedure

#EndRegion

#Region PropertySubsystemProcedures

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure SetVisibilityOfOrganizationFormElement()
	
	Items.Organization.Visible = Object.GiftCardAccounting25;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfDDSArticleFormElement()
	
	Items.CashFlowItemSale.Visible = Object.GiftCardAccounting25;
	Items.CashFlowItemReturn.Visible = Object.GiftCardAccounting25;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfFinancialAccountingGroupFormElement()
	
	Items.FinancialAccountingGroup.Visible = Object.GiftCardAccounting25;
	
EndProcedure

&AtClient
Procedure SetVisibilityOfFormElementGroupValidityPeriod()     
	
	Items.ValidityPeriodGroup.Visible = Not Object.Permanent;
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfProductSegmentFormElement()
	
	Items.GroupProductSegmentLeft.ReadOnly = Object.GiftCardAccounting25;
	
EndProcedure

&AtServerNoContext
Function LocalAccountingCurrency(Organization)
	LocalAccountingCurrency = SettingsValueCached.DefaultBaseCurrency();
	If ValueIsFilled(Organization) Then
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	Return LocalAccountingCurrency;
EndFunction

&AtServer
Procedure OnCreatReadAtServer()
	
	MapTypeWhenChangedOnServer();
	
	If Object.PartialPayment Then
		PartialPaymentRadioButton = "AllowPartialPayment";
	Else
		PartialPaymentRadioButton = "ProhibitPartialPayment";
	EndIf;
	
	If ValueIsFilled(Object.ProductSegment) Then
		UseProductSegments = 1;
	Else
		UseProductSegments = 0;
	EndIf;
	GLAccountSettingsServer.WhenReadingCreatingAccountSettingsObject(ThisObject);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ProductSegment","Enabled", (UseProductSegments = 1));
	
	Items.GroupProductSegmentLeft.Visible = GetFunctionalOption("UseProductSegments");
	Items.GiftCardAccounting25.Visible = GetFunctionalOption("NewOnlineARAPAccounting");
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	Object.Currency = LocalAccountingCurrency(Object.Organization);
	
EndProcedure

#EndRegion

#EndRegion
