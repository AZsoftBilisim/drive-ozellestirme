
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TypesDetailsBoolean = New TypeDescription("Boolean");
	Object.FiscalReceiptsAreGeneratedByPaymentSystem = TypesDetailsBoolean.AdjustValue(Object.FiscalReceiptsAreGeneratedByPaymentSystem);
	FiscalReceiptsAreGeneratedByPaymentSystem = Object.FiscalReceiptsAreGeneratedByPaymentSystem;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
		
	ExcludeVerificationOfFillingInARAPObjectOfFee = False;
	If Not Object.KeepRecordsOfCommissionInARAPAccounting Then
		NotCheckedAttributeArray.Add("CommissionAgreement");
		ExcludeVerificationOfFillingInARAPObjectOfFee = True;
	EndIf;
	
	If Not ValueIsFilled(CommissionAgreement) Then
		ExcludeVerificationOfFillingInARAPObjectOfFee = True;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
		
	If ExcludeVerificationOfFillingInARAPObjectOfFee Then
		DocumentObject = FormAttributeToValue("Object");
		DocumentObject.AdditionalProperties.Insert("ExcludeVerificationOfFillingInARAPObjectOfFee", True);
		
		If Not DocumentObject.CheckFilling() Then
			Cancel = True;
		EndIf;
		
		ObjectAttributesToBeChecked = CheckedAttributes.Find("Object");
		If ObjectAttributesToBeChecked <> Undefined Then
			CheckedAttributes.Delete(ObjectAttributesToBeChecked);
		EndIf;
	EndIf;
	GLAccountSettingsServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisForm, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "Write_POSTerminals" Then
		CreateInscriptionAcquiringTerminals();
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	// Subsystem prohibiting editing of key details of objects	
	ObjectAttributesLock.LockAttributes(ThisForm);
	
	FormEvents.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
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
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerOnChangeServer(
		Object.Partner, Object.Counterparty, Object.CounterpartyBankAccount, Object.ContactPerson);
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure MakingPaymentMethodOnChange(Item)

	Object.POSTerminalsAreUsed = False;
	If Object.MakingPaymentMethod = PredefinedValue("Enum.MakingPaymentMethods.InternetAcquiring") Then
		ConfigureDependentFormElements("MakingPaymentMethod");
	Else
		PaymentMethodWhenChangedOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure PaymentMethodWhenChangedOnServer()
	
	Object.POSTerminalsAreUsed = False;
	Object.FiscalReceiptsAreGeneratedByPaymentSystem = False;
	If Object.MakingPaymentMethod = PredefinedValue("Enum.MakingPaymentMethods.POSTerminal") Then
		Object.POSTerminalsAreUsed = True;
		CreateInscriptionAcquiringTerminals();
	ElsIf Object.MakingPaymentMethod = PredefinedValue("Enum.MakingPaymentMethods.InstantPayments") Then
		CreateInscriptionSettingUpPaymentSystemConnection();
	EndIf;
	ConfigureDependentFormElementsOnServer("MakingPaymentMethod");
	
EndProcedure

&AtClient
Procedure TheInscriptionOfAcquiringTerminalsURLProcessing(Item, FormattedStringURL, StandardProcessing)

	ClearMessages();
	
	If FormattedStringURL = "TerminalList" Then
		
		StandardProcessing = False;
		
		FormParameters = New Structure;
		Filter = New Structure;
		Filter.Insert("Owner", Object.Ref);
		FormParameters.Insert("Filter", Filter);
		
		OpenForm("Catalog.POSTerminals.ListForm", FormParameters, ThisObject);
		
	ElsIf FormattedStringURL = "Add" Then
		
		StandardProcessing = False;
		
		CallbackDescription = New CallbackDescription("AddAcquiringTerminal", ThisObject);
		
		If ValueIsFilled(Object.Ref) Then
			RunCallback(CallbackDescription, "");
		Else
			QueryText = NStr("vi = 'Trước khi thêm thiết bị thẻ thanh toán, hợp đồng sẽ được ghi lại, tiếp tục?';
							|ru = 'Перед добавлением эквайрингового терминала договор будет записан, продолжить?';
							|en = 'The contract will be written before adding a POS terminal. Continue?'; fa = 'The contract will be written before adding a POS terminal. Continue?';
							|it = 'Prima dell''aggiunta del terminal di acquisizione, l''accordo sarà registrato. Continuare?';
							|pl = 'Przed dodaniem terminalu płatniczego umowa zostanie zapisana, kontynuować?';
							|tr = 'PoS terminalini eklemeden önce sözleşme kaydedilecek, devam edilsin mi?'");
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		EndIf;
	EndIf
	
EndProcedure

&AtClient
Procedure AddAcquiringTerminal(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		ItemRecorded = False;
	ElsIf Result = DialogReturnCode.Yes Then
		ItemRecorded = Write();
	Else
		ItemRecorded = True;
	EndIf;
	
	If ItemRecorded Then
		FormParameters = New Structure;
		Filter = New Structure;
		Filter.Insert("Owner", Object.Ref);
		Filter.Insert("EnableCreatingCashIssueWithoutPaymentRequest", Object.EnableCreatingCashIssueWithoutPaymentRequest);
		FormParameters.Insert("FillingValues", Filter);
		
		OpenForm("Catalog.POSTerminals.ObjectForm", FormParameters, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure InscriptionSettingUpPaymentSystemConnectionURLProcessing(Item, FormattedStringURL, StandardProcessing)

	ClearMessages();
	AcquiringContractsClientLocalization.InscriptionSettingUpPaymentSystemConnectionURLProcessing(
		ThisObject, Item, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FixedFeeRateOnChange(Item)
	
	Object.FixedFeeRate = Boolean(FixedFeeRate);
	
	ConfigureDependentFormElements("FixedFeeRate");
	
EndProcedure

&AtClient
Procedure CommissionPostingMethodOnChange(Item)
	
	ConfigureDependentFormElements("CommissionPostingMethod");
	
EndProcedure

&AtClient
Procedure HowCommissionIsReflectedInBankSReportOnChange(Item)
	
	MethodOfReflectingCommissionWhenCrediting = Undefined;
	MethodOfReflectingCommissionDuringTransaction = Undefined;
	MethodOfReflectingCommissionInSeparateWriteOff = Undefined;
	
	Object.CommissionPostingMethod = PredefinedValue("Enum.MethodsOfAcquiringCommissionRecording.InReport");
	
	ConfigureDependentFormElements("CommissionPostingMethod");
	
EndProcedure

&AtClient
Procedure MethodOfReflectingCommissionWhenCreditingOnChange(Item)
	
	HowCommissionIsReflectedInBankSReport = Undefined;
	MethodOfReflectingCommissionDuringTransaction = Undefined;
	MethodOfReflectingCommissionInSeparateWriteOff = Undefined;
	
	Object.CommissionPostingMethod = PredefinedValue("Enum.MethodsOfAcquiringCommissionRecording.OnCashReceiving");
	
	ConfigureDependentFormElements("CommissionPostingMethod");
	
EndProcedure

&AtClient
Procedure MethodOfReflectingCommissionDuringTransactionOnChange(Item)
	
	HowCommissionIsReflectedInBankSReport = Undefined;
	MethodOfReflectingCommissionWhenCrediting = Undefined;
	MethodOfReflectingCommissionInSeparateWriteOff = Undefined;
	
	Object.CommissionPostingMethod = PredefinedValue("Enum.MethodsOfAcquiringCommissionRecording.DuringTransaction");
	
	ConfigureDependentFormElements("CommissionPostingMethod");
	
EndProcedure

&AtClient
Procedure MethodOfReflectingCommissionInSeparateWriteOffOnChange(Item)
	
	HowCommissionIsReflectedInBankSReport = Undefined;
	MethodOfReflectingCommissionWhenCrediting = Undefined;
	MethodOfReflectingCommissionDuringTransaction = Undefined;
	
	Object.CommissionPostingMethod = PredefinedValue("Enum.MethodsOfAcquiringCommissionRecording.InSeparateBankPayment");
	
	ConfigureDependentFormElements("CommissionPostingMethod");
	
EndProcedure

&AtClient
Procedure KeepRecordsOfCommissionInMutualSettlementsSwitchOnChange(Item)
	
	Object.KeepRecordsOfCommissionInARAPAccounting = KeepRecordsOfCommissionInMutualSettlementsSwitch;
	
	If Not Object.KeepRecordsOfCommissionInARAPAccounting Then
		CommissionAgreement = PredefinedValue("Catalog.CounterpartyContracts.EmptyRef");
		Object.CommissionARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	EndIf;
	ConfigureDependentFormElements("KeepRecordsOfCommissionInARAPAccounting");
	
EndProcedure

&AtClient
Procedure CommissionAgreementStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	Cancel = False;
	
	If Not ValueIsFilled(Object.Organization) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Doanh nghiệp"".';
										|ru = 'Поле ""Организация"" не заполнено.';
										|en = 'The ""Company"" field is required.'; fa = 'The ""Company"" field is required.';
										|it = 'Поле ""Организация"" не заполнено.';
										|pl = 'The ""Company"" field is required.';
										|tr = '""İş yeri"" alanı doldurulmamış.'"), , "Organization",
			"Object", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Partner) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Ngân hàng thanh toán"".';
										|ru = 'Поле ""Эквайер"" не заполнено.';
										|en = '""Acquirer"" is required.'; fa = '""Acquirer"" is required.';
										|it = 'Campo ""Aquirer"" non compilato.';
										|pl = 'Pole ""Centrum autoryzacyjne"" nie zostało wypełnione.';
										|tr = '""Alıcı banka"" alanı doldurulmadı.'"), , "Partner",
			"Object", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Counterparty) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Đối tác""';
										|ru = 'Поле ""Контрагент"" не заполнено';
										|en = '""Counterparty"" is not filled in'; fa = '""Counterparty"" is not filled in';
										|it = 'Il campo ""Contraente"" non è compilato';
										|pl = 'Pole ""Kontrahent"" nie jest wypełnione';
										|tr = '""Cari hesap"" alanı doldurulmadı'"), , "Counterparty",
			"Object", Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.BankAccount) Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa điền trường ""Tài khoản ngân hàng để trích""';
										|ru = 'Поле ""Банковский счет для зачисления"" не заполнено';
										|en = 'The ""Bank account for payouts"" field is not filled in'; fa = 'The ""Bank account for payouts"" field is not filled in';
										|it = 'Поле ""Банковский счет для зачисления"" не заполнено';
										|pl = 'The ""Bank account for payouts"" field is not filled in';
										|tr = '""Tahakkuk için banka hesabı"" alanı doldurulmadı'"), ,
			"BankAccount", "Object", Cancel);
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	FilterValues = New Structure;
	FilterValues.Insert("Organization", Object.Organization);
	FilterValues.Insert("Partner", Object.Partner);
	FilterValues.Insert("Counterparty", Object.Counterparty);
	FilterValues.Insert("ARAPCurrency", BankAccountCurrency(Object.BankAccount));
	FilterValues.Insert("ARAPObjectSettings", PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts"));
	
	StructureOfSelectionParameters = New Structure;
	StructureOfSelectionParameters.Insert("ChoiceMode", True);
	StructureOfSelectionParameters.Insert("ContractTypes", ARAPAccountingClientServer.TypesOfContractsWithSupplier());
	StructureOfSelectionParameters.Insert("Filter", FilterValues);
	
	OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm", StructureOfSelectionParameters, Item, Item);
	
EndProcedure

&AtClient
Procedure CommissionAgreementOnChange(Item)
	
	ContractFeesOnChangesATServer();
	
EndProcedure

// Parameters:
// 	Item - FormField - 
&AtClient
Procedure Attachable_WhenChanging_SetAvailabilityOfItemsByStatusServer(Item)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.OnChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventOnChange(Item);
	EndIf;

EndProcedure

// Parameters:
// 	Command - FormCommand - 
&AtClient
Procedure Attachable_Command_SetAvailabilityOfItemsByStatusServer(Command)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.Commands.Property(Command.Name) Then
		ControlOfNonConsistentChangesHandleCommandEvent(Command);
	EndIf;
	
EndProcedure

// Parameters:
// 	Item - FormField - 
&AtClient
Procedure Attachable_BeforeStartingChange_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	If StructureOfActionsControlOfNonAgreedChanges.BeforeRowChange.Property(Item.Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel);
	EndIf;
	
EndProcedure

// Parameters:
// 	Item - FormField - 
&AtClient
Procedure Attachable_BeforeDeleting_SetAvailabilityOfItemsByStatusServer(Item, Cancel)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeDeleteRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel);
	EndIf;
	
EndProcedure

// Parameters:
// 	Item - FormField - 
&AtClient
Procedure Attachable_BeforeYouStartAdding_SetAvailabilityOfItemsByStatusServer(Item, Cancel, Copy, Parent, Var_Group)
	
	If TMCommonUseClient.WhenActingOnStatusDependentElement(ThisForm) Then
		Return;
	EndIf;
	
	Name = Item.Name;
	If StructureOfActionsControlOfNonAgreedChanges.BeforeAddRow.Property(Name) Then
		ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_WhenChangingDetailsDependingOnStatus()
	
	SetAvailabilityOfItemsByStatusServer();
	TMCommonUseClient.AfterChangingPropsDependentOnStatus(ThisForm);
	
EndProcedure

#Region ControlOfInconsistentChanges

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventOnChange(Item)
	
	If Item.Name = "Partner" Then
		PartnerOnChange(Item);
	ElsIf Item.Name = "Counterparty" Then
		CounterpartyOnChange(Item);
	ElsIf Item.Name = "Organization" Then
		OrganizationOnChange(Item);
	Else
		TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
	EndIf;
	
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleCommandEvent(Command)
	
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingChange(Item, Cancel)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeDeletion(Item, Cancel)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

&AtClient
Procedure ControlOfNonConsistentChangesHandleEventBeforeStartingAdding(Item, Cancel, Copy, Parent, Var_Group)
	TMCommonUseClient.MonitoringNonConsistentChangesCauseException(ThisForm, Item);
EndProcedure

&AtClient
Procedure FiscalReceiptsAreGeneratedByPaymentSystemOnChange(Item)
	
	Object.FiscalReceiptsAreGeneratedByPaymentSystem = FiscalReceiptsAreGeneratedByPaymentSystem;
	
EndProcedure

#EndRegion

&AtClient
Procedure BankAccountOnChange(Item)
	
	FillInContractFeeSVObjectOfSettlementARAPObject();

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

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisForm);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
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

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	HowCommissionIsReflectedInBankSReport = Object.CommissionPostingMethod;
	MethodOfReflectingCommissionWhenCrediting = Object.CommissionPostingMethod;
	MethodOfReflectingCommissionDuringTransaction = Object.CommissionPostingMethod;
	MethodOfReflectingCommissionInSeparateWriteOff = Object.CommissionPostingMethod;
	KeepRecordsOfCommissionInMutualSettlementsSwitch = Object.KeepRecordsOfCommissionInARAPAccounting;
	
	If ValueIsFilled(Object.CommissionARAPObject) Then
		CommissionAgreement = Common.ObjectAttributeValue(Object.CommissionARAPObject, "Contract");
	EndIf;
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	EditRight = AccessRight("Update", Metadata.Catalogs.AcquiringContracts);
	
	FixedFeeRate = Number(Object.FixedFeeRate);
	
	CreateInscriptionAcquiringTerminals();
	CreateInscriptionSettingUpPaymentSystemConnection();
	
	AcquiringContractsLocalization.OnReadCreateAtServer(ThisObject);
	
	FormItemsManagement();
	ConfigureDependentFormElementsOnServer();
	GLAccountSettingsServer.WhenReadingCreatingAccountSettingsObject(ThisObject);
EndProcedure

&AtServerNoContext
Procedure FillInOrganizationSDefaultBankAccount(Organization, BankAccount)
	
	If ValueIsFilled(BankAccount) Or Not ValueIsFilled(Organization) Then
		Return;
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer(Partner, Counterparty, CounterpartyBankAccount, ContactPerson)
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	FillInCounterpartySDefaultBankAccount(Counterparty, CounterpartyBankAccount);
	FillInContractFeeSVObjectOfSettlementARAPObject();
	
EndProcedure

&AtServerNoContext
Procedure FillInCounterpartySDefaultBankAccount(Counterparty, CounterpartyBankAccount)
	
	If (ValueIsFilled(CounterpartyBankAccount)
		And Counterparty = Common.ObjectAttributeValue(CounterpartyBankAccount, "Owner"))
		Or Not ValueIsFilled(Counterparty) Then
		Return;
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	
EndProcedure

&AtServer
Procedure CreateInscriptionAcquiringTerminals()
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	COUNT(CatalogData.Ref) AS NumberOfTerminals
	|FROM
	|	Catalog.POSTerminals AS CatalogData
	|WHERE
	|	CatalogData.Owner = &Ref
	|	AND NOT CatalogData.DeletionMark
	|;
	|
	|SELECT TOP 1
	|	CatalogData.Ref AS Ref
	|FROM
	|	Catalog.POSTerminals AS CatalogData
	|WHERE
	|	CatalogData.Owner = &Ref
	|	AND NOT CatalogData.DeletionMark
	|";
	
	Query.SetParameter("Ref", Object.Ref);
	
	Result = Query.ExecuteBatch();
	
	LineAcquiringTerminals = "";
	
	NumberOfTerminals = Result[0].Unload()[0].NumberOfTerminals;
	If NumberOfTerminals > 1 Then
		
		LineAcquiringTerminals =
			"<a href = TerminalList>" + NStr("vi = 'Thiết bị';
											|ru = 'Терминалы';
											|en = 'Terminals'; fa = 'Terminals';
											|it = 'Terminali';
											|pl = 'Terminale';
											|tr = 'Terminaller'") + " (" + NumberOfTerminals + ")</a>"
			+ "   "
			+ "<a href = Add>+ " + NStr("vi = 'Thêm';
										|ru = 'Добавить';
										|en = 'Add'; fa = 'افزودن';
										|it = 'Aggiungere';
										|pl = 'Dodaj';
										|tr = 'Ekle'") + "</a>";
		
	ElsIf NumberOfTerminals = 1 Then
		
		TerminalLink = Result[1].Unload()[0].Ref;
		LineAcquiringTerminals =
			"<a href = " + GetURL(TerminalLink) + ">" + String(TerminalLink) + "</a>"
			+ "   "
			+ "<a href = Add>+ " + NStr("vi = 'Thêm';
										|ru = 'Добавить';
										|en = 'Add'; fa = 'افزودن';
										|it = 'Aggiungere';
										|pl = 'Dodaj';
										|tr = 'Ekle'") + "</a>";
	Else
		LineAcquiringTerminals =
			"<a href = Add>+ " + NStr("vi = 'Thêm';
										|ru = 'Добавить';
										|en = 'Add'; fa = 'افزودن';
										|it = 'Aggiungere';
										|pl = 'Dodaj';
										|tr = 'Ekle'") + "</a>";
	EndIf;
	
	TheInscriptionOfAcquiringTerminals = StringFunctions.FormattedString(LineAcquiringTerminals);
	
	If Not AccessRight("Insert", Metadata.Catalogs.POSTerminals) Then
		Items.TheInscriptionOfAcquiringTerminals.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	ItemArray = New Array;
	
	// Header Controls
	ItemArray.Add("Date");
	ItemArray.Add("Number");
	ItemArray.Add("Partner");
	ItemArray.Add("Counterparty");
	ItemArray.Add("Organization");
	
	TMCommonUse.SetSubscriptionForFormElementChangeEvents(ThisObject, ItemArray);
	
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisObject));
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("EditRight", Form.EditRight);
	
	Return FormAttributes;
	
EndFunction

&AtServer
Procedure FormItemsManagement()
	
	Items.GroupIsWayToReflectCommission.Visible = EditRight;
	
EndProcedure

&AtServerNoContext
Function BankAccountCurrency(Val BankAccount)
	
	Return Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount).Currency
	
EndFunction

&AtServer
Procedure FillInContractFeeSVObjectOfSettlementARAPObject()
	
	AccountCurrency = BankAccountCurrency(Object.BankAccount);
	
	If Not ValueIsFilled(Object.Organization)
		Or Not ValueIsFilled(Object.Partner)
		Or Not ValueIsFilled(Object.Counterparty)
		Or Not ValueIsFilled(AccountCurrency) Then
		CommissionAgreement = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;

	If ValueIsFilled(CommissionAgreement) Then
		
		ContractDetails_ = Common.ObjectAttributesValues(CommissionAgreement,
			"Organization, Partner, Counterparty, ARAPCurrency");
		
		Clear_Contract = (Object.Organization <> ContractDetails_.Organization
			Or Object.Partner <> ContractDetails_.Partner
			Or Object.Counterparty <> ContractDetails_.Counterparty
			Or AccountCurrency <> ContractDetails_.ARAPCurrency);
		
		If Clear_Contract Then
			CommissionAgreement = Catalogs.CounterpartyContracts.EmptyRef();
		EndIf;
	EndIf;

	Object.CommissionARAPObject = ?(ValueIsFilled(CommissionAgreement),
		ARAPObjectsServer.GetCalculationObjectFromLink(CommissionAgreement), Catalogs.ARAPObjects.EmptyRef());

EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	FillInOrganizationSDefaultBankAccount(Object.Organization, Object.BankAccount);
	FillInContractFeeSVObjectOfSettlementARAPObject();
	
EndProcedure

&AtServer
Procedure CounterpartyWhenChangesAreMadeOnServer()
	
	FillInCounterpartySDefaultBankAccount(Object.Counterparty, Object.CounterpartyBankAccount);
	FillInContractFeeSVObjectOfSettlementARAPObject();
	
EndProcedure

&AtServer
Procedure ContractFeesOnChangesATServer()
	
	Object.CommissionARAPObject = ?(ValueIsFilled(CommissionAgreement),
		ARAPObjectsServer.GetCalculationObjectFromLink(CommissionAgreement), Catalogs.ARAPObjects.EmptyRef());
	
EndProcedure

&AtServer
Procedure CreateInscriptionSettingUpPaymentSystemConnection()

	AcquiringContractsLocalization.SetHeaderOfPaymentSystemConnectionSettings(ThisObject);

EndProcedure

&AtClient
Procedure SetUpConnectionToPaymentSystemEnd(Result, AdditionalParameters) Export
	
	PaymentMethodWhenChangedOnServer();
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
