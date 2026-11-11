
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	If GetFunctionalOption("UseExchangeWithOfflinePeripherals") Then
		Items.CashRegisterType.ChoiceList.Add(Enums.CashRegisterTypes.CashRegisterOffline);
	EndIf;
	
	If GetFunctionalOption("UseDataSynchronization") Then
		Items.CashRegisterType.ChoiceList.Add(Enums.CashRegisterTypes.StandaloneCWP);
	EndIf;
	
	Items.Owner.Visible = GetFunctionalOption("UseMultipleCompanies");
	
	TypeOfCashRegisterWhenChangingOnServer();
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	ConfigureVisibilityOfESFSSLocalizationPaymentItems();
	FillInConnectionParametersOfNSPKLocalization();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
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

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" mechanism
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	FormEvents.OnWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	KKMCashRegisterRecordConnectionParametersOfCompanyNSPKLocalizationWhenRecordingATServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	RefreshReusableValues();

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	UpdateNameOfExchangeNode();

EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	AutoDescription();
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtServer
Procedure TypeOfCashRegisterWhenChangingOnServer()
	
	Items.Warehouse.Visible = Not(Object.CashRegisterType = Enums.CashRegisterTypes.CashRegisterOffline);
	Items.TextExchangeNode.Visible = Object.CashRegisterType = Enums.CashRegisterTypes.StandaloneCWP;
	Items.ItinerantTrade.Visible = Object.CashRegisterType = Enums.CashRegisterTypes.FiscalCashRegisters;

	If Object.CashRegisterType <> Enums.CashRegisterTypes.FiscalCashRegisters And Object.ItinerantTrade Then
		Object.ItinerantTrade = False;
	EndIf;
	
	
	UpdateNameOfExchangeNode();
	AutoDescription();
	
EndProcedure

&AtClient
Procedure CashRegisterTypeOnChange(Item)
	
	TypeOfCashRegisterWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure OwnerWhenChangedOnServer()
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Or Not ValueIsFilled(Object.CashCurrency) Then
		Object.CashCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Owner);
	EndIf;
	
EndProcedure

&AtClient
Procedure OwnerOnChange(Item)
	
	OwnerWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure TextExchangeNodeURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	RowsArray = StrSplit(FormattedStringURL, "_");
	Action = RowsArray[0];
	FullName = "";
	
	If RowsArray.Count() > 1 Then
		FullName = RowsArray[1];
	EndIf;
	
	StandardProcessing = False;
	
	If Action = "OpenObject" Then
		FileSystemClient.OpenURL(FullName);
		
	ElsIf Action = "ConfigureConnection" Then
		
		
		SettingOptionDetails = SettingOptionDetailsStructure();
		
		WizardParameters = New Structure;
		WizardParameters.Insert("ExchangePlanName",                     "DataSynchronizationViaUniversalFormat");
		WizardParameters.Insert("SettingID",             "ExchangeOfUPRMC");
		WizardParameters.Insert("SettingOptionDetails",          SettingOptionDetails);
		WizardParameters.Insert("DataExchangeWithExternalSystem",       False);
		WizardParameters.Insert("ExternalSystemConnectionParameters");
		WizardParameters.Insert("NewSYnchronizationSetting");
		
		WizardUniqueKey = WizardParameters.ExchangePlanName + "_" + WizardParameters.SettingID;
		
		OpenForm("DataProcessor.DataExchangeCreationWizard.Form.SyncSetup", WizardParameters, , WizardUniqueKey);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NSPKExchangeLogOnChange(Item)
	NSPKExchangeLogOnChangeLocalization(Item);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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

&AtClient
Procedure TestConnectionOfNSPC(Command)
	
	TestConnectionOfNSPCLocalization();
	
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

#Region PaymentESFSSLocalization

&AtClient
Procedure TestConnectionOfNSPCLocalization()
	
	
EndProcedure

&AtClient
Procedure NSPKExchangeLogOnChangeLocalization(Item)
	

EndProcedure

#EndRegion

#Region Other

// Handler for a command created by the mechanism that prohibits editing key details.
//
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

&AtServer
Function AutoDescription()
	
	Items.Description.ChoiceList.Clear();
	
	NameString_ = String(Object.CashRegisterType) + " (" + Object.Warehouse + ")";
	
	Items.Description.ChoiceList.Add(NameString_);
	
	Return NameString_;

EndFunction

&AtServer
Procedure UpdateNameOfExchangeNode()
	
	If Not ValueIsFilled(Object.Ref) Then
		Return;
	EndIf;
	
	If Not Object.CashRegisterType = Enums.CashRegisterTypes.StandaloneCWP Then
		Return;
	EndIf;
	
	If Not DataExchangeServer.HasRightsToAdministerExchanges() Then
		Return;
	EndIf;
	
	PartsOfFormattedString = New Array;
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	SyncingCashRegister.Ref AS Ref,
	|	SyncingCashRegister.Ref.Description AS Description
	|FROM
	|	ExchangePlan.DataSynchronizationViaUniversalFormat.CashRegisters AS SyncingCashRegister
	|WHERE
	|	SyncingCashRegister.CashRegister = &CashRegister
	|	AND SyncingCashRegister.Ref.SettingsMode = &SettingsMode";
	Query.SetParameter("CashRegister", Object.Ref);
	Query.SetParameter("SettingsMode", "ExchangeOfUPRMC");
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	If Selection.Next() Then
		PartsOfFormattedString.Add(New FormattedString(Selection.Description,,,,
											"OpenObject_" + GetURL(Selection.Ref)));
	Else
		PartsOfFormattedString.Add(New FormattedString(NStr("vi = 'Tùy chỉnh kết nối';
															|ru = 'Настройка подключения';
															|en = 'Configure connection'; fa = 'Configure connection';
															|it = 'Impostazione di collegamento';
															|pl = 'Konfiguracja połączenia';
															|tr = 'Bağlantı ayarları'"),,,,
												"ConfigureConnection_"));
	EndIf;
	
	HyperlinkText = PartsOfFormattedString;
	ExchangeNode = New FormattedString(HyperlinkText);
	
EndProcedure

&AtServerNoContext
Function SettingOptionDetailsStructure()
	
	SettingOptionDetails = DataExchangeServer.DefaultExchangeSettingOptionDetails(
									Metadata.ExchangePlans.DataSynchronizationViaUniversalFormat.Name);
	ExchangePlans.DataSynchronizationViaUniversalFormat.DescriptionOfConfigurationOptionExchangeUPRMC(SettingOptionDetails);
	SettingOptionDetails.Insert("PeerInfobaseName", SettingOptionDetails.CorrespondentConfigurationDescription);
	Return SettingOptionDetails;
	
EndFunction

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
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Localization

&AtServer
Procedure FillInConnectionParametersOfNSPKLocalization();
	
	
EndProcedure

&AtServer
Procedure ConfigureVisibilityOfESFSSLocalizationPaymentItems()
	
	Items.LocalizationParametersOfNSPC.Visible = False;
	Items.NSPKOrganizationKey.Visible = False;
	
	
EndProcedure

&AtServer
Procedure KKMCashRegisterRecordConnectionParametersOfCompanyNSPKLocalizationWhenRecordingATServer(Form, CurrentObject)
	
	
	
EndProcedure

#EndRegion

#EndRegion
