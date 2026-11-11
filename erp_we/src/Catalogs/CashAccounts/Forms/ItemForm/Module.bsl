
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If TypeOf(ValueSelected) = Type("ValueList") Then
		
		Object.RecipientOfCashTransfer.Clear();
		For Each PaymentBeneficiary In ValueSelected Do
			If PaymentBeneficiary.Value.IsEmpty() Then
				Continue;
			EndIf;
			PayeeLine = Object.RecipientOfCashTransfer.Add();
			PayeeLine.PaymentBeneficiary = PaymentBeneficiary.Value;
		EndDo;
		
		FormItemsManagement();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If IsBlankString(Object.Description) Then
		Object.Description = GenerateAutoName(ThisObject);
	EndIf;
	
	If Not AllowPaymentsWithoutSpecifyingReferences Then
		Object.RecipientOfCashTransfer.Clear();
	EndIf;
	
	If Object.OperationalCashAccount And Not ValueIsFilled(Object.Individual) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Cá nhân""';
				|ru = 'Поле ""Физическое лицо"" не заполнено';
				|en = '""Person"" is required'; fa = '""Person"" is required';
				|it = 'Il campo ""Persona fisica"" non è compilato';
				|pl = 'Pole ""Osoba fizyczna"" nie jest wypełnione';
				|tr = '""Gerçek kişi"" alanı doldurulmadı'"),,
			"Individual",
			,
			Cancel);
	EndIf;

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	If Not AllowPaymentsWithoutSpecifyingReferences Then
		Items.EditTheReceivingCashAccountList.Title = GetListOfCheckoutRecipients();
	EndIf;
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_CashAccounts", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	GLAccountSettingsClient.FinishedSettingUpAccountingAccounts(ThisObject, EventName, Parameter);
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	GLAccountSettingsServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
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
Procedure OwnerOnChange(Item)
	
	OwnerOnChangeServer();
	
	Object.RecipientOfCashTransfer.Clear();
	GenerateAutoName(ThisObject);
	
EndProcedure

&AtClient
Procedure CashCurrencyOnChange(Item)
	
	CashCurrencyOnChangeServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	GenerateAutoName(ThisObject);
	
EndProcedure

&AtClient
Procedure IndicatesWhetherTheCashBookOfASeparateDivisionIsChanged(Item)
	
	Object.ThisIsCashAccountOfBranchOffice = (IndicatesACashBookOfBranchOffice = 1);
	
	If Not Object.ThisIsCashAccountOfBranchOffice Then
		Object.CashBook = Undefined;
	EndIf;
	
	IndicatesWhetherTheCashBookOfASeparateDivisionIsChangedServer();
	
EndProcedure

&AtClient
Procedure IndicatesWhetherTheCashBookOfASeparateDivisionIsChangedServer()
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure AllowPaymentsWithoutSpecifyingReferencesOnChange(Item)
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure OperationalCashAccountOnChange(Item)
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure ListOfCashRegistersOfRecipients(Button)
	
	Cancel = False;
	
	If Not ValueIsFilled(Object.Owner) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
				|ru = 'Поле ""Организация"" не заполнено';
				|en = '""Company"" is required'; fa = '""Company"" is required';
				|it = 'Il campo ""Società"" non è compilato';
				|pl = 'Nie wypełniono pola ""Firma""';
				|tr = '""İş yeri"" alanı doldurulmadı'"),,
			"Owner",
			"Object",
			Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.CashCurrency) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Tiền tệ""';
				|ru = 'Поле ""Валюта"" не заполнено';
				|en = '""Currency"" is required'; fa = '""Currency"" is required';
				|it = 'Il campo ""Valuta"" non è compilato';
				|pl = 'Pole ""Waluta"" nie jest wypełnione';
				|tr = '""Para Birimi"" alanı doldurulmadı'"),,
			"CashCurrency",
			"Object",
			Cancel);
	EndIf;
	
	If Not Cancel Then
		
		FormParameters = New Structure;
		FormParameters.Insert("CashAccount", Object.Ref);
		FormParameters.Insert("Owner", Object.Owner);
		FormParameters.Insert("CashCurrency", Object.CashCurrency);
		FormParameters.Insert("ListOfPaymentRecipients", New ValueList);
		For Each PayeeLine In Object.RecipientOfCashTransfer Do
			FormParameters.ListOfPaymentRecipients.Add(PayeeLine.PaymentBeneficiary)
		EndDo;
		
		OpenForm("Catalog.CashAccounts.Form.BeneficiariesOnCashTransferForm",
			FormParameters,
			ThisForm,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
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
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
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

&AtServer
Procedure OnReadCreateAtServer()
	
	UseMultipleCashAccounts        = GetFunctionalOption("UseMultipleCashAccounts");
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	IsBaseVersion                 = GetFunctionalOption("BaseVersion");
	
	IndicatesACashBookOfBranchOffice = ?(Object.ThisIsCashAccountOfBranchOffice, 1, 0);
	
	AllowPaymentsWithoutSpecifyingReferences = (Object.RecipientOfCashTransfer.Count() > 0);
	
	FormItemsManagement();
	
	GenerateAutoName(ThisObject);
	GLAccountSettingsServer.WhenReadingCreatingAccountSettingsObject(ThisObject);
EndProcedure

&AtServer
Procedure FormItemsManagement()
	
	Items.AllowPaymentsWithoutSpecifyingReferences.Visible          = UseMultipleCashAccounts;
	Items.TheInscriptionOfTheListOfBoxOfficeRecipients.Visible                     = UseMultipleCashAccounts;
	Items.EditTheReceivingCashAccountList.Visible               = UseMultipleCashAccounts;
	
	Items.TheInscriptionOfTheListOfBoxOfficeRecipients.Enabled                   = AllowPaymentsWithoutSpecifyingReferences;
	Items.EditTheReceivingCashAccountList.Enabled             = AllowPaymentsWithoutSpecifyingReferences;
	
	Items.Owner.Visible                                         = UseMultipleCompanies;
	Items.EditTheReceivingCashAccountList.Title               = GetListOfCheckoutRecipients();
	
	Items.CashBook.Enabled                                  = Object.ThisIsCashAccountOfBranchOffice;
	
	Items.Individual.Visible                                   = Object.OperationalCashAccount;
	
	If IsBaseVersion Then
		Items.CashBook.Visible = False;
		Items.IndicatesACashBookOfBranchOffice1.Visible = False;
		Items.IndicatesACashBookOfBranchOffice2.Visible = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function GenerateAutoName(Form)
	
	Object = Form.Object;
	Form.Items.Description.ChoiceList.Clear();
	
	NameString_ =
		TrimAll(Object.Owner) + 
		?(ValueIsFilled(Object.Department), " - " + TrimAll(Object.Department), "") + 
		" (" + String(Object.CashCurrency) + ")";
	NameString_ = Left(NameString_, 100);
	
	Form.Items.Description.ChoiceList.Add(NameString_);
	
	Return NameString_;

EndFunction

&AtServer
Function GetListOfCheckoutRecipients()
	
	If Object.RecipientOfCashTransfer.Count() = 0 Then
		CashAccountList = NStr("vi = '<Chỉ ra quỹ tiền mặt>';
								|ru = '<Указать кассы>';
								|en = '<Specify cash accounts>'; fa = '<Specify cash accounts>';
								|it = '<Indicare le casse>';
								|pl = '<Wskaż kasy>';
								|tr = '<Kasaları belirt>'");
	Else
		
		PaymentRecipients = Common.UnloadColumn(Object.RecipientOfCashTransfer, "PaymentBeneficiary", True);
		NameOfPayees = Common.ObjectsAttributeValue(PaymentRecipients, "Description");
		
		CashAccountList = "";
		For Each PayeeLine In NameOfPayees Do
			CashAccountList = CashAccountList + ?(CashAccountList = "", "", ", ") + PayeeLine.Value;
		EndDo;
		
	EndIf;
	
	Return CashAccountList;
	
EndFunction

&AtServer
Procedure CashCurrencyOnChangeServer()
	
	Object.RecipientOfCashTransfer.Clear();
	GenerateAutoName(ThisObject);
	GLAccountSettingsClientServer.OnChangeAttribute(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

// StandardSubsystems.Properties
&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure OwnerOnChangeServer()
	
	If Not ValueIsFilled(Object.CashCurrency) Then
		Object.CashCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Owner);
	EndIf;
	
EndProcedure

#EndRegion
