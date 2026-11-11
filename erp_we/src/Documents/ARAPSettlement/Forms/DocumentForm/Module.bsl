#Region Variables

&AtClient
Var CounterpartyVerificationWaitHandlerParameters Export;

&AtClient
Var TimeConsumingOperationForm Export;

&AtClient
Var IdleParameters;

&AtClient
Var ParametersForRecording Export;

&AtClient
Var PreviousValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SetConditionalAppearance();
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	ARWriteOff = Enums.BusinessTransactions.ARWriteOff;
	APWriteOff = Enums.BusinessTransactions.APWriteOff;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.FooterGroup.BackColor = New Color();
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	GeneratingFiscalChecksServer.FormWhenCreatedOnServer(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	SetVisibilityBasicVersion();
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	BlockSettlementObjects();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	If Object.OperationKind <> Enums.KindsOfARAPSettlements.Arbitrary
		And Object.AccountsReceivable.Count() > 0 Then
		ARAPCurrency = Object.AccountsReceivable[0].ARAPCurrency;
	EndIf;
	OnReadCreateAtServer();
	
	GeneratingFiscalChecksServer.FormWhenReadingOnServer(ThisObject);
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)

	If ChoiceSource.FormName = "Catalog.ARAPObjects.Form.ARAPObjectSelection" Then
		
		If SelectionResult.BusinessOperation = ARWriteOff Then
			GetAccountsReceivableFromVault(SelectionResult.AddressOfPaymentsInTheStorage);
			If Object.AccountsReceivable.Count() > 0 Then
				SetSettlementCurrency(Object.AccountsReceivable[0].ARAPCurrency);
			EndIf;
			
			If Not NewOnlineARAPAccounting Then
				DebtParametersDebtor  = StructureOfDebtParameters(ThisForm);
				PopulatedTS = "AccountsReceivable";
				DimensionToCalculation = ThereAreTasksForDistribution(DebtParametersDebtor);
				If DimensionToCalculation.Count() > 0 Then
					AttachIdleHandler("BackgroundJobCheckOnClient", 0.1, True);
					Return;
				EndIf;
			EndIf;
			
			AdditionalParameters = New Structure("AmountsOnly");
			AutoTestToCalculateTheOffsetCompletion(Undefined,AdditionalParameters);
			
		Else
			GetAccountsPayableFromVault(SelectionResult.AddressOfPaymentsInTheStorage);
			If Object.AccountsPayable.Count() > 0 Then
				SetSettlementCurrency(Object.AccountsPayable[0].ARAPCurrency);
			EndIf;
			
			If Not NewOnlineARAPAccounting Then
				DebtParametersCreditor  = StructureOfDebtParameters(ThisForm);
				PopulatedTS = "AccountsPayable";
				DimensionToCalculation = ThereAreTasksForDistribution(DebtParametersCreditor);
				If DimensionToCalculation.Count() > 0 Then
					AttachIdleHandler("BackgroundJobCheckOnClient", 0.1, True);
					Return;
				EndIf;
			EndIf;
			
			AdditionalParameters = New Structure("AmountsOnly");
			AutoTestToCalculateTheOffsetCompletion(Undefined,AdditionalParameters);
			
		EndIf;
		
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	UpdateServiceAttributesOfTablePart("Dr");
	UpdateServiceAttributesOfTablePart("Cr");
	
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);

	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	Notify("Write_ARAPSettlement", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);

	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		DrLocalAmount  = Object.AccountsReceivable.Total("SumCompl");
		CrLocalSum  = Object.AccountsPayable.Total("SumCompl");
		AmountOfDrMan   = Object.AccountsReceivable.Total("SumMan");
		AmountOfCRMan   = Object.AccountsPayable.Total("SumMan");
		
		If Object.AccountsPayable.Total("Sum")<>0 Then
			For Each String In Object.AccountsPayable Do
				String.Sum = 0;
			EndDo;
		EndIf;
		
		If Object.AccountsReceivable.Total("Sum")<>0 Then
			For Each String In Object.AccountsReceivable Do
				String.Sum = 0;
			EndDo;
		EndIf;
		
		If DrLocalAmount = CrLocalSum Then
			Object.SumCompl = DrLocalAmount;
		EndIf;
		If AmountOfDrMan = AmountOfCRMan Then
			Object.SumMan = AmountOfDrMan;
		EndIf;
		
		If DrLocalAmount <> CrLocalSum Or AmountOfDrMan <> AmountOfCRMan Then
			
			If Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.Barter")
				Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.ARAPClearingBetweenCompanies")
				Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.Arbitrary") Then
				Cancel = True;
				AdditionalParameters = New Structure;
				AdditionalParameters.Insert("WriteParameters", WriteParameters);
				
				CallbackDescription = New CallbackDescription(
					"BeforeRecordingOfferToRecalculateAmountOfDocument", 
					ThisObject,
					AdditionalParameters);
				
				RecalculateLocalManAmounts(CallbackDescription);
				
			EndIf;
			
		EndIf;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToRecalculateAmountOfDocument(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult Then
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	EndIf;
	
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
	
	If EventName = "GiftCertificateIsRead"
		And Parameter.OwnerForm = UUID Then
		ProcessSelectedGiftCertificatesOnServer(Parameter.GiftCertificate);
	EndIf;
	
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	If RadioButtonAccountsReceivable = 0 Or RadioButtonAccountsPayable = 0 Then
		DocumentObject = FormAttributeToValue("Object");
		DocumentObject.AdditionalProperties.Insert("AccountsReceivableWithoutDivision", RadioButtonAccountsReceivable = 0);
		DocumentObject.AdditionalProperties.Insert("AccountsPayableWithoutSplitting", RadioButtonAccountsPayable = 0);
		
		If Items.GroupAccountsReceivable.Visible Then
			DocumentObject.AdditionalProperties.Insert("ListNameDr", Items.GroupAccountsReceivable.Title);
		EndIf;
		
		If Items.GroupAccountsPayable.Visible Then
			DocumentObject.AdditionalProperties.Insert("ListNameCr", Items.GroupAccountsPayable.Title);
		EndIf;
		
		If Not DocumentObject.CheckFilling() Then
			Cancel = True;
		EndIf;
		
		CheckedAttributes.Clear();
	EndIf;
	
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
	
	InitializePreviousValues();
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Return; // not an empty handler
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OperationKindStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Item.ChoiceList.Count() = 0 Then
	
		StandardProcessing = False;
		FormParameters = New Structure("OperationKind", Object.OperationKind);
		Notification = New CallbackDescription("OperationKindStartChoiceCompletion", ThisForm);
		OpenForm(
			"Document.ARAPSettlement.Form.SettlementsSetupWizard",
			FormParameters,
			ThisForm,,,,
			Notification,
			FormWindowOpeningMode.LockOwnerWindow);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationKindStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined And Object.OperationKind <> Result Then
		Object.OperationKind = Result;
		Modified = True;
		OperationKindOnChangeServer();
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure OperationKindOnChange(Item)
	OperationKindOnChangeServer();
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure CounterpartyDebtorTypeOnChange(Item)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Item", Item);
	
	Notification = New CallbackDescription(
		"TypeOfDebtorNeedsToBeClearedWhenChangingPMCompletion",
		ThisObject,
		AdditionalParameters);
	
	ItIsNecessaryToPurifyTS(Notification, ThereAreLines("AccountsReceivable"));
	
EndProcedure

&AtClient
Procedure TypeOfDebtorNeedsToBeClearedWhenChangingPMCompletion(ClearTS, AdditionalParameters) Export
	
	If ClearTS = DialogReturnCode.Yes Then
		
		Object.ARAPObjectDebtorCreditor = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
		DebtorTypeWhenChangedOnServer();
		
		ClearTablePart("AccountsReceivable");
		PreviousValues.CounterpartyDebtorType = Object.CounterpartyDebtorType;
		
		
	Else
		Object.CounterpartyDebtorType = PreviousValues.CounterpartyDebtorType;
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyCreditorTypeOnChange(Item)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Item", Item);
	
	Notification = New CallbackDescription(
		"TypeOfLenderWhenChangingNeedsToBeClearedPMCompletion",
		ThisObject,
		AdditionalParameters);
	
	ItIsNecessaryToPurifyTS(Notification, ThereAreLines("AccountsPayable"));
	
EndProcedure

&AtClient
Procedure TypeOfLenderWhenChangingNeedsToBeClearedPMCompletion(ClearTS, AdditionalParameters) Export
	
	If ClearTS = DialogReturnCode.Yes Then
		
		Object.ARAPObjectDebtorCreditor = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
		LenderTypeWhenChangedOnServer();
		
		ClearTablePart("AccountsPayable");
		PreviousValues.CounterpartyCreditorType = Object.CounterpartyCreditorType;
		
		
	Else
		Object.CounterpartyCreditorType = PreviousValues.CounterpartyCreditorType;
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyDebtorOnChange(Item)
	
	TableName = "AccountsReceivable";
	If Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty")
		Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany")
		Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty")
		Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany") Then
		TableName = "AccountsPayable";
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Item", Item);
	AdditionalParameters.Insert("TableName", TableName);
	
	Object.ARAPObjectDebtorCreditor = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	ItIsNecessaryToPurifyTS(
		New CallbackDescription("CounterpartyDebtorWhenChangingYouNeedToClearTS", ThisObject, AdditionalParameters),
		ThereAreLines(TableName));
	
EndProcedure

// Parameters:
// 	ClearTS - Boolean
// 	AdditionalParameters - Structure:
// 	 * Item - FormField
&AtClient
Procedure CounterpartyDebtorWhenChangingYouNeedToClearTS(ClearTS, AdditionalParameters) Export
	
	If ClearTS = DialogReturnCode.Yes Then
		
		CounterpartyDebtorWhenChangingOnServer();
		
		ClearTablePart("AccountsReceivable");
		If Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty")
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty")
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany")
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany")
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies")
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.AccountsReceivableOffsetBetweenTwoCompanies")
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies")
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies")
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.Barter")
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.ARAPClearingBetweenCompanies") Then
			ClearTablePart("AccountsPayable");
		ElsIf Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent") Then
			ClearTablePart("AccountsPayable");
		EndIf;
		PreviousValues.CounterpartyDebtor = Object.CounterpartyDebtor;
		
		
	Else
		Object.CounterpartyDebtor = PreviousValues.CounterpartyDebtor;
	EndIf;
	
EndProcedure

&AtClient
Procedure CreditorOnChange(Item)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Item", Item);
	
	ThereAreLines = ThereAreLines("AccountsPayable");
	If Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty")
		Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty")
		Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany")
		Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany")
		Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent") Then
			ThereAreLines = ThereAreLines Or	ThereAreLines("AccountsReceivable");
	EndIf;
	
	Object.ARAPObjectDebtorCreditor = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	ItIsNecessaryToPurifyTS(
		New CallbackDescription("CounterpartyLenderWhenChangingItIsNecessaryToClearTS", ThisObject, AdditionalParameters),
		ThereAreLines);
	
EndProcedure

// Parameters:
// 	ClearTS - Boolean
// 	AdditionalParameters - Structure:
// 	 * Item - FormField
&AtClient
Procedure CounterpartyLenderWhenChangingItIsNecessaryToClearTS(ClearTS, AdditionalParameters) Export
	
	If ClearTS = DialogReturnCode.Yes Then 
		
		CounterpartyCreditorWhenChangingOnServer();
		
		ClearTablePart("AccountsPayable");
		If Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty")
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty")
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany")
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany") Then
			ClearTablePart("AccountsReceivable");
		ElsIf Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent") Then
			ClearTablePart("AccountsReceivable");
		EndIf;
		
		PreviousValues.Creditor = Object.Creditor;
		
		
	Else
		Object.Creditor = PreviousValues.Creditor;
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	ThereAreLines = ThereAreLines("AccountsReceivable") Or ThereAreLines("AccountsPayable");
	
	ItIsNecessaryToPurifyTS(
		New CallbackDescription("OrganizationNeedsToClearPMCompletionWhenChanging", ThisObject),
		ThereAreLines);
	
EndProcedure

&AtClient
Procedure OrganizationNeedsToClearPMCompletionWhenChanging(ClearTS, AdditionalParameters) Export
	
	If ClearTS = DialogReturnCode.Yes Then
		ClearTablePart("AccountsReceivable");
		ClearTablePart("AccountsPayable");
		Object.ARAPObjectIntercompany = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
		Object.ARAPObjectIntercompanyMirrored = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
		OrganizationOnChangeServer();
		PreviousValues.Organization = Object.Organization;
	Else
		Object.Organization = PreviousValues.Organization;
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPObjectIntercompanyStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterValues = New Structure;
	FilterValues.Insert("Organization", Object.Organization);
	FilterValues.Insert("Counterparty",  Object.CompanyCreditor);
	
	SelectionSettings_ = New Structure();
	SelectionSettings_.Insert("CurrentRow", Object.ARAPObjectIntercompany);
	SelectionSettings_.Insert("RecordBranches", False);
	
	OpenFormForSelectingCalculationObjects(Item, FilterValues, SelectionSettings_);
	
EndProcedure

&AtClient
Procedure ARAPObjectIntercompanyChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		Object.ARAPObjectIntercompany = ValueSelected.ARAPObject;
		Modified = True;
		BlockSettlementObjects();
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPObjectIntercompanyMirroredStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterValues = New Structure;
	FilterValues.Insert("Organization", Object.CompanyCreditor);
	FilterValues.Insert("Counterparty",  Object.Organization);
	
	SelectionSettings_ = New Structure();
	SelectionSettings_.Insert("CurrentRow", Object.ARAPObjectIntercompanyMirrored);
	SelectionSettings_.Insert("RecordBranches", False);
	
	OpenFormForSelectingCalculationObjects(Item, FilterValues, SelectionSettings_);
	
EndProcedure

&AtClient
Procedure ARAPObjectIntercompanyMirroredChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		Object.ARAPObjectIntercompanyMirrored = ValueSelected.ARAPObject;
		Modified = True;
		BlockSettlementObjects();
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPObjectDebtorCreditorStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterValues = New Structure;
	
	If SettlementsBetweenCompaniesDebtor And (Not SettlementsBetweenCompaniesCreditor Or SettlementsWithCustomersCreditor) Then
		FilterValues.Insert("Organization", Object.CounterpartyDebtor);
		FilterValues.Insert("Counterparty",  Object.Creditor);
		
		FilterValues.Insert("PaymentType_", ?(SettlementsWithCustomersCreditor,
												PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"),
												PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting")));
	Else
		FilterValues.Insert("Organization", Object.Creditor);
		FilterValues.Insert("Counterparty",  Object.CounterpartyDebtor);
		
		FilterValues.Insert("PaymentType_", ?(SettlementsWithCustomersDebtor Or SettlementsBetweenCompaniesDebtor,
												PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"),
												PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting")));
	EndIf;

	If Not ValueIsFilled(FilterValues.Organization) Then
		Raise NStr("vi = 'Chưa chỉ ra doanh nghiệp';
					|ru = 'Не указана организация';
					|en = 'Company is not specified'; fa = 'Company is not specified';
					|it = 'Azienda non indicata';
					|pl = 'Nie podano firmy';
					|tr = 'İş yeri doldurulmadı'");
	EndIf;

	SelectionSettings_ = New Structure();
	SelectionSettings_.Insert("CurrentRow", Object.ARAPObjectDebtorCreditor);
	
	OpenFormForSelectingCalculationObjects(Item, FilterValues, SelectionSettings_);
	
EndProcedure

&AtClient
Procedure ARAPObjectDebtorCreditorChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		Object.ARAPObjectDebtorCreditor = ValueSelected.ARAPObject;
		Modified = True;
		BlockSettlementObjects();
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPObjectDebtorCreditorMirrorStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterValues = New Structure;
	
	If SettlementsBetweenCompaniesDebtor And (Not SettlementsBetweenCompaniesCreditor Or SettlementsWithCustomersCreditor) Then
		FilterValues.Insert("Organization", Object.Creditor);
		FilterValues.Insert("Counterparty",  Object.CounterpartyDebtor);
		
		FilterValues.Insert("PaymentType_", ?(SettlementsWithCustomersDebtor Or SettlementsBetweenCompaniesDebtor,
												PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"),
												PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting")));
	Else
		FilterValues.Insert("Organization", Object.CounterpartyDebtor);
		FilterValues.Insert("Counterparty",  Object.Creditor);
		
		FilterValues.Insert("PaymentType_", ?(SettlementsWithCustomersCreditor,
												PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"),
												PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting")));
	EndIf;

	SelectionSettings_ = New Structure();
	SelectionSettings_.Insert("CurrentRow", Object.ARAPObjectDebtorCreditorMirror);
	
	OpenFormForSelectingCalculationObjects(Item, FilterValues, SelectionSettings_);
	
EndProcedure

&AtClient
Procedure ARAPObjectDebtorCreditorMirrorChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		Object.ARAPObjectDebtorCreditorMirror = ValueSelected.ARAPObject;
		Modified = True;
		BlockSettlementObjects();
	EndIf;
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.GroupAccountsReceivable And Not RadioButtonAccountsReceivable Then
		AccountsReceivableOnStartEdit(Items.AccountsReceivable, False, False);
	EndIf;
	
	If CurrentPage = Items.GroupAccountsPayable And Not RadioButtonAccountsPayable Then
		AccountsPayableOnStartEdit(Items.AccountsPayable, False, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure RadioButtonAccountsReceivableOnChange(Item)
	
	ClearMessages();
	
	If Not RadioButtonAccountsReceivable Then
		If Object.AccountsReceivable.Count() = 0 Then
			NewRow = Object.AccountsReceivable.Add();
			Items.AccountsReceivable.CurrentRow = NewRow.GetID();
		ElsIf Object.AccountsReceivable.Count() = 1 Then
			If Items.AccountsReceivable.CurrentRow = Undefined Then
				Items.AccountsReceivable.CurrentRow = Object.AccountsReceivable[0].GetID();
			EndIf;
		ElsIf Object.AccountsReceivable.Count() > 1 Then
			MessageText = NStr("vi = 'Chuyển sang chế độ không phân chia là không thể nếu có nhiều hơn một dòng được nhập vào giải mã thanh toán!';
								|ru = 'Переключение в режим без разбиения невозможно, если в расшифровке платежа введено более одной строки!';
								|en = 'Cannot switch to no-split mode if multiple lines are entered into the payment details.'; fa = 'Cannot switch to no-split mode if multiple lines are entered into the payment details.';
								|it = 'Passare alla modalità senza la partizione è impossibile se nella decifrazione del pagamento viene inserita più di una riga!';
								|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w szczegółach płatności wprowadzono więcej niż jeden wiersz!';
								|tr = 'Ödeme detayında birden fazla satır girilmişse ayrıştırılmış moda geçmek mümkün değildir!'");
			CommonClient.MessageToUser(MessageText);
			RadioButtonAccountsReceivable = 1;
		EndIf;
	EndIf;
	
	SetPropertiesOfFormElementsByTypeOfOperation();
	
EndProcedure

&AtClient
Procedure RadioButtonAccountsPayableOnChange(Item)
	
	If Not RadioButtonAccountsPayable Then
		If Object.AccountsPayable.Count() = 0 Then
			NewRow = Object.AccountsPayable.Add();
			Items.AccountsPayable.CurrentRow = NewRow.GetID();
		ElsIf Object.AccountsPayable.Count() = 1 Then
			If Items.AccountsPayable.CurrentRow = Undefined Then
				Items.AccountsPayable.CurrentRow = Object.AccountsPayable[0].GetID();
			EndIf;
		ElsIf Object.AccountsPayable.Count() > 1 Then
			MessageText = NStr("vi = 'Chuyển sang chế độ không phân chia là không thể nếu có nhiều hơn một dòng được nhập vào giải mã thanh toán!';
								|ru = 'Переключение в режим без разбиения невозможно, если в расшифровке платежа введено более одной строки!';
								|en = 'Cannot switch to no-split mode if multiple lines are entered into the payment details.'; fa = 'Cannot switch to no-split mode if multiple lines are entered into the payment details.';
								|it = 'Passare alla modalità senza la partizione è impossibile se nella decifrazione del pagamento viene inserita più di una riga!';
								|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w szczegółach płatności wprowadzono więcej niż jeden wiersz!';
								|tr = 'Ödeme detayında birden fazla satır girilmişse ayrıştırılmış moda geçmek mümkün değildir!'");
			CommonClient.MessageToUser(MessageText);
			RadioButtonAccountsPayable = 1;
		EndIf;
	EndIf;
	
	SetPropertiesOfFormElementsByTypeOfOperation();
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ARAPObjectIntercompanyOnChange(Item)
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure ARAPObjectIntercompanyMirroredOnChange(Item)
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure ARAPObjectDebtorCreditorOnChange(Item)
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure ARAPObjectDebtorCreditorMirrorOnChange(Item)
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure CommissionSalesPartnerOnChange(Item)
	
	PartnerOfCommissionSaleWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure PartnerOfCommissionSaleWhenChangingOnServer()
	
	ThisIsPaymentThroughCommissionAgent = ?(Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent, True, False);
	
	If ThisIsPaymentThroughCommissionAgent Then
		CurrentRowClient = Object.AccountsReceivable[0];
		CurLineCommissionAgent = Object.AccountsPayable[0];
	Else
		CurLineCommissionAgent = Object.AccountsReceivable[0];
		CurrentRowClient = Object.AccountsPayable[0];
	EndIf;
	
	CommissionAgentContractData = GetContractDataFromSettlementObject(CurLineCommissionAgent.ARAPObject);
	
	If CommissionAgentContractData.ConductARAPAccountingThroughEndCustomers Then
		CurrentRowClient.Partner = CommissionSalesPartner;
	Else
		CurrentRowClient.Partner = CurLineCommissionAgent.Partner;
	EndIf;
	
EndProcedure

&AtClient
Procedure CommissionSaleClientOnChange(Item)
	
	TableName = "AccountsReceivable";
	If Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent") Then
		TableName = "AccountsPayable";
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Item", Item);
	AdditionalParameters.Insert("TableName", TableName);
	
	Object.ARAPObjectDebtorCreditor = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	ItIsNecessaryToPurifyTS(
		New CallbackDescription("ClientOfCommissionSaleNeedsToClearTSEndWhenChangeIsMade", ThisObject, AdditionalParameters),
		ThereAreLines(TableName));
	
EndProcedure

// Parameters:
// 	ClearTS - Boolean
// 	AdditionalParameters - Structure:
// 	 * Item - FormField
// 	 * TableName - String
&AtClient
Procedure ClientOfCommissionSaleNeedsToClearTSEndWhenChangeIsMade(ClearTS, AdditionalParameters) Export
	
	If ClearTS = DialogReturnCode.Yes Then
		
		ClientCommissionSaleOnChangeOnServer();
		ClearTablePart(AdditionalParameters.TableName);
		If AdditionalParameters.TableName = "AccountsReceivable" Then
			PreviousValues.CounterpartyDebtor = CommissionSaleClient;
		Else
			PreviousValues.Creditor = CommissionSaleClient;
		EndIf;
		
		
		Modified = True;
	Else
		If AdditionalParameters.TableName = "AccountsReceivable" Then
			CommissionSaleClient = PreviousValues.CounterpartyDebtor;
		Else
			CommissionSaleClient = PreviousValues.Creditor;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ClientCommissionSaleOnChangeOnServer()
	
	If ValueIsFilled(CommissionSaleClient) Then
		CommissionSalesPartner = CashServer.GetCounterpartyPartner(CommissionSaleClient);
	Else
		CommissionSalesPartner = Catalogs.Partners.EmptyRef();
	EndIf;
	
	ThisIsPaymentThroughCommissionAgent = ?(Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent, True, False);
	ThisIsRefundOfPaymentThroughCommissionAgent = ?(Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent, True, False);
	
	If (ThisIsPaymentThroughCommissionAgent Or ThisIsRefundOfPaymentThroughCommissionAgent)
		And Object.AccountsPayable.Count() = 1 And Object.AccountsReceivable.Count() = 1 Then
			If ThisIsPaymentThroughCommissionAgent Then
				CurrentRowClient = Object.AccountsReceivable[0];
				CurLineCommissionAgent = Object.AccountsPayable[0];
				DetailsNameOfClientSCounterparty = "CounterpartyDebtor";
				TypeOfCounterpartyDebt = "Dr";
			Else
				CurLineCommissionAgent = Object.AccountsReceivable[0];
				CurrentRowClient = Object.AccountsPayable[0];
				DetailsNameOfClientSCounterparty = "Creditor";
				TypeOfCounterpartyDebt = "Cr";
			EndIf;
			
			CommissionAgentContractData = GetContractDataFromSettlementObject(CurLineCommissionAgent.ARAPObject);
			CustomerAgreementData = GetContractDataFromSettlementObject(CurrentRowClient.ARAPObject);
			
			If CommissionAgentContractData.ConductARAPAccountingThroughEndCustomers Then
				CurrentRowClient.Partner = CommissionSalesPartner;
				Object[DetailsNameOfClientSCounterparty] = CommissionSaleClient;
				UpdateCounterpartySServiceAttributes(TypeOfCounterpartyDebt);
			EndIf;
			
			If ValueIsFilled(CustomerAgreementData.Contract) Then
				
				ContractDetails_ = Common.ObjectAttributesValues(CustomerAgreementData.Contract, "Partner, Counterparty");
				If CommissionSalesPartner <> ContractDetails_.Partner
					Or CommissionSaleClient <> ContractDetails_.Counterparty Then
					
					CurrentRowClient.ARAPObject = Undefined;
					
					If ThisIsPaymentThroughCommissionAgent Then
						SetAvailabilityOfAccountsReceivableItemsWithoutPartitioning();
					Else
						EstablishAvailabilityOfAccountsPayableItemsWithoutPartitioning();
					EndIf;
					
				EndIf;
			EndIf;
				
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccountsReceivable

&AtClient
Procedure AccountsReceivableWithoutSplitARAPObjectOnChange(Item)
	ObjectOfCalculationsCalculationsWhenChanging("AccountsReceivable");
	CurrentData = Items.AccountsPayable.CurrentData;
	AccountsReceivableWithoutSplittingObjectOfCalculationsWhenChangingOnServer(CurrentData.LineOfBusiness, CurrentData.ARAPObject);
EndProcedure

&AtClient
Procedure AccountsReceivableOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Item.CurrentData;
	If NewRow And Not Copy Then
		
		If Not (SettlementsBetweenCompaniesDebtor Or ValueIsFilled(PartnerDebtor)) Then
			FillInDebtorSPartner();
		EndIf;
		
		CurrentData.Partner = PartnerDebtor;
		
		AmountLocalBalance = Object.SumCompl - Object.AccountsReceivable.Total("SumCompl");
		CurrentData.SumCompl = AmountLocalBalance;
		
		AmountManBalance = Object.SumMan - Object.AccountsReceivable.Total("SumMan");
		CurrentData.SumMan = AmountManBalance;
		
	EndIf;
		
EndProcedure

&AtClient
Procedure AccountsReceivableARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ARAPObjectStartChoice("Dr", Item, ChoiceData);
	
EndProcedure

&AtClient
Procedure AccountsReceivableARAPObjectOnChange(Item)
	ObjectOfCalculationsCalculationsWhenChanging("AccountsReceivable");
	CurrentData = Items.AccountsPayable.CurrentData;
	Debt_ARAPObjectOnChangeServer(CurrentData.LineOfBusiness,CurrentData.ARAPObject);
EndProcedure

&AtClient
Procedure AccountsReceivableARAPObjectChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	CalculationObjectSelectionProcessing("Dr", ValueSelected);
	CalculationObjectSelectionProcessingServer("Dr");
	
	CurrentData = CurRowOfDebt("Dr");
	RecalculateAmountsOfManLocalServerCall(CurrentData);
	
EndProcedure

&AtClient
Procedure AccountsReceivableARAPObjectMirrorStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ARAPObjectStartChoice("Dr", Item, ChoiceData, "Mirror");
	
EndProcedure

&AtClient
Procedure AccountsReceivableARAPObjectMirrorChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	CalculationObjectSelectionProcessing("Dr", ValueSelected);
	BlockSettlementObjects();
	
EndProcedure

&AtClient
Procedure AccountsReceivableAmountARAPOnChange(Item)
	
	CurrentData = CurRowOfDebt("Dr");
	CurrentData.SumMan  = 0;
	CurrentData.SumCompl = 0;
	
	FillInManLocalAmounts(StructureOfDebtParameters(ThisForm, False), False);
	
	RecalculateAmountsOfManLocalServerCall(CurrentData);
	
EndProcedure

&AtClient
Procedure AccountsReceivableAfterDeleteRow(Item)
	ClearSettlementCurrency();
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure AccountsReceivableARAPObjectClearing(Item, StandardProcessing)
	ClearSettlementCurrency();
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure AccountsReceivableWithoutSplitARAPObjectClearing(Item, StandardProcessing)
	ClearSettlementCurrency();
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure AccountsReceivableARAPObjectMirrorOnChange(Item)
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure AccountsReceivableWithoutSplitARAPObjectMirrorOnChange(Item)
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure EndClientIsARAPObjectOfSelectionProcessing(Item, ValueSelected, StandardProcessing)
	
	ConversionTable = "Dr";
	ConversionTableIsReversed = "Cr";
	If Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent") Then
		ConversionTable = "Cr";
		ConversionTableIsReversed = "Dr";
	EndIf;
	
	StandardProcessing = False;
	CalculationObjectSelectionProcessing(ConversionTable, ValueSelected);
	BlockSettlementObjects();
	
	CurCurrentDataIsReverse = CurRowOfDebt(ConversionTableIsReversed);
	CurrentData = CurRowOfDebt(ConversionTable);
	CurrentData.SumMan  = CurCurrentDataIsReverse.SumMan;
	CurrentData.SumCompl = CurCurrentDataIsReverse.SumCompl;
	
	If CurrentData.ARAPCurrency = LocalAccountingCurrency Then
		CurrentData.AmountARAP = CurrentData.SumCompl;
	ElsIf ValueIsFilled(CurrentData.ARAPCurrency) Then
		CurrentData.AmountARAP = ConvertToSumOfMutualSettlements(CurrentData.SumCompl,
				CurrentData.ARAPCurrency, CurrentData.ARAPObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccountsPayable

&AtClient
Procedure AccountsPayableWithoutSplittingTheSettlementObjectOnChange(Item)
	ObjectOfCalculationsCalculationsWhenChanging("AccountsPayable");
	CurrentData = Items.AccountsPayable.CurrentData;
	AccountsPayableWithoutSplittingObjectOfCalculationsWhenChangingOnServer(CurrentData.LineOfBusiness,CurrentData.ARAPObject);
EndProcedure

&AtClient
Procedure AccountsPayableOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Item.CurrentData;
	If NewRow And Not Copy Then
		
		If Not (SettlementsBetweenCompaniesCreditor Or ValueIsFilled(PartnerCreditor)) Then
			FillInLenderSPartner();
		EndIf;
		
		CurrentData.Partner = PartnerCreditor;
		
		AmountLocalBalance = Object.SumCompl - Object.AccountsPayable.Total("SumCompl");
		CurrentData.SumCompl = AmountLocalBalance;
		
		AmountManBalance = Object.SumMan - Object.AccountsPayable.Total("SumMan");
		CurrentData.SumMan = AmountManBalance;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AccountsPayableARAPObjectOnChange(Item)
	ObjectOfCalculationsCalculationsWhenChanging("AccountsPayable");
	CurrentData = Items.AccountsPayable.CurrentData;
	Debt_ARAPObjectOnChangeServer(CurrentData.LineOfBusiness,CurrentData.ARAPObject);
EndProcedure

&AtClient
Procedure AccountsPayableARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ARAPObjectStartChoice("Cr", Item, ChoiceData);
	
EndProcedure

&AtClient
Procedure AccountsPayableARAPObjectChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	CalculationObjectSelectionProcessing("Cr", ValueSelected);
	CalculationObjectSelectionProcessingServer("Cr");
	
	CurrentData = CurRowOfDebt("Cr");
	RecalculateAmountsOfManLocalServerCall(CurrentData);
	
EndProcedure

&AtClient
Procedure AccountsPayableARAPObjectMirrorStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ARAPObjectStartChoice("Cr", Item, ChoiceData, "Mirror");
	
EndProcedure

&AtClient
Procedure AccountsPayableARAPObjectMirrorChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	CalculationObjectSelectionProcessing("Cr", ValueSelected);
	BlockSettlementObjects();
	
EndProcedure

&AtClient
Procedure AccountsPayableAmountARAPOnChange(Item)

	CurrentData = CurRowOfDebt("Cr");
	CurrentData.SumMan  = 0;
	CurrentData.SumCompl = 0;
	
	FillInManLocalAmounts(StructureOfDebtParameters(ThisForm, True), True);
	
	RecalculateAmountsOfManLocalServerCall(CurrentData);
	
EndProcedure

&AtClient
Procedure AccountsPayableAfterDeleteRow(Item)
	ClearSettlementCurrency();
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure AccountsPayableARAPObjectClearing(Item, StandardProcessing)
	ClearSettlementCurrency();
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure AccountsPayableWithoutSplittingTheSettlementObjectClearing(Item, StandardProcessing)
	ClearSettlementCurrency();
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure AccountsPayableARAPObjectMirrorOnChange(Item)
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure AccountsPayableWithoutSplitARAPObjectMirrorOnChange(Item)
	BlockSettlementObjects();
EndProcedure

&AtClient
Procedure AccountsPayableBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	ClearMessages();	
	TypeOfOperationPaymentByGiftCertificate = PredefinedValue("Enum.KindsOfARAPSettlements.PaymentByGiftCard");
	If Object.OperationKind = TypeOfOperationPaymentByGiftCertificate Then
		Cancel = True;	

		MessageText = NStr("vi = 'Cấm thêm và sao chép trực tác các dòng có dạng giao dịch ""%TransactionKindPresentation%"". Cần dùng chọn.';
							|ru = 'С видом операции ""%TransactionKindPresentation%"" интерактивное добавление и копирование строк запрещено. Необходимо использовать подбор.';
							|en = 'With the %TransactionKindPresentation% transaction type, you cannot add or copy lines manually. Use selection.'; fa = 'With the %TransactionKindPresentation% transaction type, you cannot add or copy lines manually. Use selection.';
							|it = 'Con il tipo di operazione ""%TransactionKindPresentation%"" non è possibile utilizzare l''aggiunta interattiva e la copia delle stringhe. Utilizzare selezionare.';
							|pl = 'Dla rodzaju operacji ""%TransactionKindPresentation%"" interaktywne dodawanie i kopiowanie wierszy jest zabronione. Należy używać filtru.';
							|tr = '""%TransactionKindPresentation%"" işlem türüyle, satırların etkileşimli olarak eklenmesi ve kopyalanması yasaktır. Seçim kullanılmalıdır.'");
		MessageText = StrReplace(MessageText, "%TransactionKindPresentation%", TypeOfOperationPaymentByGiftCertificate);
		CommonClient.MessageToUser(MessageText);
	EndIf;
EndProcedure

&AtClient
Procedure CommissionAgentCalculationObjectStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	ARAPObjectStartChoice("Cr", Item, ChoiceData);
	
EndProcedure

&AtServer
Function GetContractDataFromSettlementObject(ObjectOfARAP)
	
	StructureOfData = New Structure();
	StructureOfData.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
	StructureOfData.Insert("ConductARAPAccountingThroughEndCustomers", False);
	
	CommissionAgentSAgreement = Catalogs.CounterpartyContracts.EmptyRef();
	
	If ValueIsFilled(ObjectOfARAP) Then
		Contract = Common.ObjectAttributeValue(ObjectOfARAP, "Contract");
		StructureOfData.Contract = Contract;
		If ValueIsFilled(Contract) Then
			StructureOfData.ConductARAPAccountingThroughEndCustomers = Common.ObjectAttributeValue(Contract, "ConductARAPAccountingThroughEndCustomers");
		EndIf;
	EndIf;
	
	Return StructureOfData;
	
EndFunction

&AtClient
Procedure CustomerSettlementObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CommissionAgentData = Object.AccountsPayable[0];
	If Not ValueIsFilled(CommissionAgentData.ARAPObject) Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa đặt đối tượng hạch toán người nhận ký gửi. Hãy chọn đối tượng hạch toán người nhận ký gửi.';
										|ru = 'Не задан объект расчетов комиссионера. Выберите объект расчетов комиссионера.';
										|en = 'The consignee AR/AP object is not specified. Select the consignee AR/AP object.'; fa = 'The consignee AR/AP object is not specified. Select the consignee AR/AP object.';
										|it = 'Не задан объект расчетов комиссионера. Выберите объект расчетов комиссионера.';
										|pl = 'The consignee AR/AP object is not specified. Select the consignee AR/AP object.';
										|tr = 'Konsinye alacak/borç nesnesi belirlenmedi. Konsinye alacak/borç nesnesini seçin.'"));
		Return;
	EndIf;
	
	Kind = "Dr";
	DebtParameters = StructureOfDebtParameters(ThisForm, False);
	CurrentData = CurRowOfDebt(Kind);
	
	FilterValues = New Structure;
	FilterValues.Insert("PaymentType_", PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"));
	FilterValues.Insert("Organization", DebtParameters.Organization.Value);
	FilterValues.Insert("PaymentsAsPer275FZ" , False);
	DataOfContractWithCommissionAgent = GetContractDataFromSettlementObject(CommissionAgentData.ARAPObject);
	EndCustomerSelectionParameters = New Structure();
	EndCustomerSelectionParameters.Insert("SelectObjectsOfSettlementsWithEndClient", True);
	EndCustomerSelectionParameters.Insert("ContractWithCommissionAgent", DataOfContractWithCommissionAgent.Contract);
	If DataOfContractWithCommissionAgent.ConductARAPAccountingThroughEndCustomers Then
		EndCustomerSelectionParameters.Insert("Partner", CurrentData.Partner);
		EndCustomerSelectionParameters.Insert("Counterparty", DebtParameters.Counterparty.Value);
	Else
		EndCustomerSelectionParameters.Insert("Partner", CommissionSalesPartner);
		EndCustomerSelectionParameters.Insert("Counterparty", CommissionSaleClient);
	EndIf;
	
	SelectionSettings_ = New Structure;
	SelectionSettings_.Insert("SelectPaymentObjectsByCommission", EndCustomerSelectionParameters);
	SelectionSettings_.Insert("Sum", 0);
	SelectionSettings_.Insert("SelectAccountsReceivable", False);
	
	OpenFormForSelectingCalculationObjects(Item, FilterValues, SelectionSettings_);
	
EndProcedure

&AtClient
Procedure CustomerSettlementObjectReturnStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CommissionAgentData = Object.AccountsReceivable[0];
	If Not ValueIsFilled(CommissionAgentData.ARAPObject) Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa xác định đối tượng hạch toán người nhận ký gửi. Hãy chọn đối tượng hạch toán người nhận ký gửi.';
										|ru = 'Не задан объект расчетов комиссионера. Выберите объект расчетов комиссионера.';
										|en = 'The consignee AR/AP object is not specified. Select the consignee AR/AP object.'; fa = 'The consignee AR/AP object is not specified. Select the consignee AR/AP object.';
										|it = 'Не задан объект расчетов комиссионера. Выберите объект расчетов комиссионера.';
										|pl = 'The consignee AR/AP object is not specified. Select the consignee AR/AP object.';
										|tr = 'Konsinye alacak/borç nesnesi belirlenmedi. Konsinye alacak/borç nesnesini seçin.'"));
		Return;
	EndIf;
	
	Kind = "Cr";
	DebtParameters = StructureOfDebtParameters(ThisForm, True);
	CurrentData = CurRowOfDebt(Kind);
	
	FilterValues = New Structure;
	FilterValues.Insert("PaymentType_", PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"));
	FilterValues.Insert("Organization", DebtParameters.Organization.Value);
	FilterValues.Insert("PaymentsAsPer275FZ" , False);
	
	DataOfContractWithCommissionAgent = GetContractDataFromSettlementObject(CommissionAgentData.ARAPObject);
	EndCustomerSelectionParameters = New Structure();
	EndCustomerSelectionParameters.Insert("SelectObjectsOfSettlementsWithEndClient", True);
	EndCustomerSelectionParameters.Insert("ContractWithCommissionAgent", DataOfContractWithCommissionAgent.Contract);
	If DataOfContractWithCommissionAgent.ConductARAPAccountingThroughEndCustomers Then
		EndCustomerSelectionParameters.Insert("Partner", CurrentData.Partner);
		EndCustomerSelectionParameters.Insert("Counterparty", DebtParameters.Counterparty.Value);
	Else
		EndCustomerSelectionParameters.Insert("Partner", CommissionSalesPartner);
		EndCustomerSelectionParameters.Insert("Counterparty", CommissionSaleClient);
	EndIf;
	
	SelectionSettings_ = New Structure;
	SelectionSettings_.Insert("SelectPaymentObjectsByCommission", EndCustomerSelectionParameters);
	SelectionSettings_.Insert("Sum", 0);
	SelectionSettings_.Insert("SelectAccountsReceivable", False);
	
	OpenFormForSelectingCalculationObjects(Item, FilterValues, SelectionSettings_);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure
// End StandardSubsystems.AttachableCommands


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
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

// This function is used in the AutoTest of the sales process.
//
&AtClient
Procedure AutoTestToCalculateTheOffset(Command) Export
	
	AccountReceivableParameters = StructureOfDebtParameters(ThisForm);
	LenderParameters = StructureOfDebtParameters(ThisForm, True);
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert(
		AccountReceivableParameters.Organization.AttributeName,
		AccountReceivableParameters.Organization.Presentation);
	CheckParameters.CheckedAttributes.Insert(
		AccountReceivableParameters.Counterparty.AttributeName,
		AccountReceivableParameters.Counterparty.Presentation);
	
	If AccountReceivableParameters.Organization.AttributeName <> LenderParameters.Organization.AttributeName Then
		CheckParameters.CheckedAttributes.Insert(
			LenderParameters.Organization.AttributeName,
			LenderParameters.Organization.Presentation);
	EndIf;
	
	If AccountReceivableParameters.Counterparty.AttributeName <> LenderParameters.Counterparty.AttributeName Then
		CheckParameters.CheckedAttributes.Insert(
			LenderParameters.Counterparty.AttributeName,
			LenderParameters.Counterparty.Presentation);
	EndIf;
	
	Notification = New CallbackDescription("CalculateOffsetCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure CalculateOffsetCompletion(Result, AdditionalParameters) Export
	
	ThereAreLinesOfDr = ThereAreLines("AccountsReceivable");
	ThereAreCrLines =  ThereAreLines("AccountsPayable");
	
	If ThereAreLinesOfDr Or ThereAreCrLines Then
		
		ShowQueryBox(New CallbackDescription("CalculateOffset", ThisObject), 
			NStr("vi = 'Trong quá trình hoạt động, các phần bảng của các khoản phải thu và phải trả sẽ bị xóa. Tiếp tục?';
				|ru = 'При выполнении операции табличные части дебиторской и кредиторской задолженности будут очищены. Продолжить?';
				|en = 'While executing the operation, tables of receivable and payable accounts will be cleared. Continue?'; fa = 'While executing the operation, tables of receivable and payable accounts will be cleared. Continue?';
				|it = 'Durante l''operazione, le parti tabulari dei crediti e debiti verranno cancellate. Continuare?';
				|pl = 'Podczas wykonania operacji części tabelaryczne należności i zobowiązań będą oczyszczone. Kontynuować?';
				|tr = 'İşlem yapıldığında alacak ve borçların tablo halindeki bölümleri kaldırılacaktır. Devam et?'"),
			QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
		
	Else
		AutoTestToCalculateTheOffsetCompletion(Undefined, Undefined);
	EndIf
	
EndProcedure

&AtClient
Procedure CalculateOffset(Result, AdditionalParameters) Export
	
	Response = Result;
	If Response <> DialogReturnCode.Yes Then
		Return;
	Else
		Object.SumCompl = 0;
		Object.SumMan = 0;
		
		Object.AccountsReceivable.Clear();
		Object.AccountsPayable.Clear();
		AutoTestToCalculateTheOffsetCompletion(Undefined, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SelectAccountsReceivableByAmountDue(Command)
	
	DebtParameters = StructureOfDebtParameters(ThisForm);
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert(
		DebtParameters.Organization.AttributeName,
		DebtParameters.Organization.Presentation);
	CheckParameters.CheckedAttributes.Insert(
		DebtParameters.Counterparty.AttributeName,
		DebtParameters.Counterparty.Presentation);
	Notification = New CallbackDescription("SelectAccountsReceivableByAmountDueCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure SelectAccountsPayableByAmountDue(Command)
	
	DebtParameters = StructureOfDebtParameters(ThisForm, True);
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert(
		DebtParameters.Organization.AttributeName,
		DebtParameters.Organization.Presentation);
	CheckParameters.CheckedAttributes.Insert(
		DebtParameters.Counterparty.AttributeName,
		DebtParameters.Counterparty.Presentation);
	Notification = New CallbackDescription("SelectAccountsPayableByAmountDueCompletion", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure FillInAccordingToTheReceivable(Command)
	
	If Object.AccountsReceivable.Count() = 0
		Or Object.AccountsReceivable.Total("AmountARAP") = 0
		Or Not ValueIsFilled(Object.AccountsReceivable[0].ARAPObject) Then
		Text = NStr("vi = 'Chưa điền phần bảng ""%1""';
					|ru = 'Не заполнена табличная часть ""%1""';
					|en = 'Table ""%1"" is not filled in'; fa = 'Table ""%1"" is not filled in';
					|it = 'Non è compilata la parte tabulare ""%1""';
					|pl = 'Nie wypełniono części tabelarycznej ""%1""';
					|tr = '""%1"" tablo bölümü doldurulmadı'");
		Text = StrReplace(Text, "%1", Items.GroupAccountsReceivable.Title);
		CommonClient.MessageToUser(Text);
		Return;
	EndIf;
	
	PopulatedTS = "AccountsPayable";
	StartFillingInDebt("FillInAccordingToTheReceivableCompletion");
	
EndProcedure

&AtClient
Procedure FillInAccordingToTheReceivableCompletion(Result, AdditionalParameters) Export
	
	CheckBackgroundJobOnClient = FillInReceivablesOnServer(Result, AdditionalParameters);
	If Not NewOnlineARAPAccounting And CheckBackgroundJobOnClient Then
		AttachIdleHandler("BackgroundJobCheckOnClient", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Function FillInReceivablesOnServer(Result, AdditionalParameters)
	
	If Object.AccountsReceivable.Count() = 0 Then
		If TypeOfOperationSelectedIsArbitraryOrBarter() Then
			MessageText = NStr("vi = 'Chưa điền các khoản phải thu.';
								|ru = 'Дебиторская задолженность не заполнена.';
								|en = 'Accounts receivable is required.'; fa = 'Accounts receivable is required.';
								|it = 'Дебиторская задолженность не заполнена.';
								|pl = 'Accounts receivable is required.';
								|tr = 'Alacak hesapları doldurulmadı.'");
		Else
			MessageText = Items.GroupAccountsReceivable.Title + " " + NStr("vi = 'chưa điền';
																			|ru = 'не заполнены';
																			|en = 'not filled'; fa = 'not filled';
																			|it = 'не заполнены';
																			|pl = 'not filled';
																			|tr = 'doldurulmadı'") + ".";
		EndIf;
		Common.MessageToUser(MessageText);
		Return False;
	EndIf;
	
	DebtParametersCreditor = StructureOfDebtParameters(ThisForm, PopulatedTS = "AccountsPayable");
	
	If Not NewOnlineARAPAccounting Then
		DimensionToCalculation = ThereAreTasksForDistribution(DebtParametersCreditor);
		If DimensionToCalculation.Count() > 0 Then
			Return True;
		EndIf;
	EndIf;
	
	If TypeOfOperationSelectedIsArbitraryOrBarter() Then
		Object.SumCompl = Object.AccountsReceivable.Total("SumCompl");
		AmountForAllocation = Object.SumCompl;
	Else
		Object.DocumentAmount = Object.AccountsReceivable.Total("AmountARAP");
		AmountForAllocation = Object.DocumentAmount;
	EndIf;
	
	FillInRemainingAccountsPayable(DebtParametersCreditor);
	If Object.AccountsPayable.Count() = 0 Then
		InitializeDebt("Cr");
		Object.AccountsPayable[0].ARAPCurrency = Object.AccountsReceivable[0].ARAPCurrency;
		If TypeOfOperationSelectedIsArbitraryOrBarter() Then
			Object.AccountsPayable[0].SumCompl = Object.AccountsReceivable.Total("SumCompl");
		Else
			Object.AccountsPayable[0].AmountARAP = Object.AccountsReceivable.Total("AmountARAP");
		EndIf;
	ElsIf Object.AccountsPayable.Count() = 1 And Not TypeOfOperationSelectedIsArbitraryOrBarter() Then
		Object.AccountsPayable[0].ARAPCurrency = Object.AccountsReceivable[0].ARAPCurrency;
		Object.AccountsPayable[0].AmountARAP = Object.AccountsReceivable.Total("AmountARAP");
		Object.AccountsPayable[0].SumCompl = Object.AccountsReceivable.Total("SumCompl");
		Object.AccountsPayable[0].SumMan = Object.AccountsReceivable.Total("SumMan");
		InitializeDebt("Cr");
	
	Else
		CalculateNettingAmountsServer(AmountForAllocation);
		InitializeDebt("Dr");
		InitializeDebt("Cr");
	EndIf;
	
	SetPropertiesOfFormElementsByTypeOfOperation();
	
	Return False;
	
EndFunction

&AtClient
Procedure FillInAccordingToTheAccountsPayable(Command)
	
	If Object.AccountsPayable.Count() = 0
		Or Object.AccountsPayable.Total("AmountARAP") = 0
		Or Not ValueIsFilled(Object.AccountsPayable[0].ARAPObject) Then
		Text = NStr("vi = 'Chưa điền phần bảng ""%1""';
					|ru = 'Не заполнена табличная часть ""%1""';
					|en = 'Table ""%1"" is not filled in'; fa = 'Table ""%1"" is not filled in';
					|it = 'Non è compilata la parte tabulare ""%1""';
					|pl = 'Nie wypełniono części tabelarycznej ""%1""';
					|tr = '""%1"" tablo bölümü doldurulmadı'");
		Text = StrReplace(Text, "%1", Items.GroupAccountsReceivable.Title);
		CommonClient.MessageToUser(Text);
		Return;
	EndIf;
	
	PopulatedTS = "AccountsReceivable";
	StartFillingInDebt("FillInAccordingToTheAccountsPayableCompletion");
	
EndProcedure

&AtClient
Procedure FillInAccordingToTheAccountsPayableCompletion(Result, AdditionalParameters) Export
	
	CheckBackgroundJobOnClient = FillInAccountsPayableOnServer(Result, AdditionalParameters);
	If Not NewOnlineARAPAccounting And CheckBackgroundJobOnClient Then
		AttachIdleHandler("BackgroundJobCheckOnClient", 0.1, True);
	EndIf;
	
EndProcedure

&AtServer
Function FillInAccountsPayableOnServer(Result, AdditionalParameters)
	
	If Object.AccountsPayable.Count() = 0 Then
		If TypeOfOperationSelectedIsArbitraryOrBarter() Then
			MessageText = NStr("vi = 'Chưa điền các khoản phải trả.';
								|ru = 'Кредиторская задолженность не заполнена.';
								|en = 'Accounts payable is required.'; fa = 'Accounts payable is required.';
								|it = 'Кредиторская задолженность не заполнена.';
								|pl = 'Accounts payable is required.';
								|tr = 'Borç hesapları doldurulmadı.'");
		Else
			MessageText = Items.GroupAccountsPayable.Title + " " + NStr("vi = 'chưa điền';
																		|ru = 'не заполнены';
																		|en = 'not filled'; fa = 'not filled';
																		|it = 'не заполнены';
																		|pl = 'not filled';
																		|tr = 'doldurulmadı'") + ".";
		EndIf;
		Common.MessageToUser(MessageText);
		Return False;
	EndIf;
	
	DebtParametersDebtor = StructureOfDebtParameters(ThisForm, PopulatedTS = "AccountsPayable");
	
	If Not NewOnlineARAPAccounting Then
		DimensionToCalculation = ThereAreTasksForDistribution(DebtParametersDebtor);
		If DimensionToCalculation.Count() > 0 Then
			Return True;
		EndIf;
	EndIf;
	
	If TypeOfOperationSelectedIsArbitraryOrBarter() Then
		Object.SumCompl = Object.AccountsPayable.Total("SumCompl");
		AmountForAllocation = Object.SumCompl;
	Else
		Object.DocumentAmount = Object.AccountsPayable.Total("AmountARAP");
		AmountForAllocation = Object.DocumentAmount;
	EndIf;
	
	FillInRemainingAccountsReceivable(DebtParametersDebtor);
	If Object.AccountsReceivable.Count() = 0 Then
		InitializeDebt("Dr");
		Object.AccountsReceivable[0].ARAPCurrency = Object.AccountsPayable[0].ARAPCurrency;
		If TypeOfOperationSelectedIsArbitraryOrBarter() Then
			Object.AccountsReceivable[0].SumCompl = Object.AccountsPayable.Total("SumCompl");
		Else
			Object.AccountsReceivable[0].AmountARAP = Object.AccountsPayable.Total("AmountARAP");
		EndIf;
	ElsIf Object.AccountsReceivable.Count() = 1 And Not TypeOfOperationSelectedIsArbitraryOrBarter() Then
		Object.AccountsReceivable[0].ARAPCurrency = Object.AccountsPayable[0].ARAPCurrency;
		Object.AccountsReceivable[0].AmountARAP = Object.AccountsPayable.Total("AmountARAP");
		Object.AccountsReceivable[0].SumCompl = Object.AccountsPayable.Total("SumCompl");
		Object.AccountsReceivable[0].SumMan = Object.AccountsPayable.Total("SumMan");
		InitializeDebt("Dr");
	Else
		CalculateNettingAmountsServer(AmountForAllocation);
		InitializeDebt("Dr");
		InitializeDebt("Cr");
	EndIf;
	
	SetPropertiesOfFormElementsByTypeOfOperation();
	
	Return False;
	
EndFunction

&AtClient
Procedure StartFillingInDebt(NameOfPostHandler)
	
	DebtParameters = StructureOfDebtParameters(ThisForm, PopulatedTS = "AccountsPayable");
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert(
		DebtParameters.Organization.AttributeName,
		DebtParameters.Organization.Presentation);
	CheckParameters.CheckedAttributes.Insert(
		DebtParameters.Counterparty.AttributeName,
		DebtParameters.Counterparty.Presentation);
	Notification = New CallbackDescription(NameOfPostHandler, ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure PickUpGiftCertificate(Command)
	
	If GiftCertificatesClient.CheckPossibilityOfAddingGiftCertificate(ThisObject, False) Then
		If Object.Posted Then
			NotificationDetailsCompletion = New CallbackDescription("PickUpGiftCertificateStart", ThisObject);
			RetailSalesClient.DisplayQuestionAboutNeedForUnverifiedDocument(ThisObject, NotificationDetailsCompletion);
		Else
			OpenGiftCertificateSelectionForm();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateServiceAttributesOfTablePart(Kind)
	
	ThisIsDebit = Kind = "Dr";
	
	If ThisIsDebit Then
		TSName = "AccountsReceivable";
	Else
		TSName = "AccountsPayable";
	EndIf;
	
	TableOfCalculationObjects = Object[TSName].Unload(,"ARAPObject");
	TableOfCalculationObjects.GroupBy("ARAPObject", "");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ARAPObjects.Ref AS Ref,
	|	ARAPObjects.Object AS Object
	|FROM
	|	Catalog.ARAPObjects AS ARAPObjects
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON ARAPObjects.Contract = CounterpartyContracts.Ref
	|WHERE
	|	ARAPObjects.Ref IN (&ARAPObjects)";
	
	Query.SetParameter("ARAPObjects", TableOfCalculationObjects.UnloadColumn("ARAPObject"));
	AttributesOfSettlementObjects = New Map;
	Selection = Query.Execute().Select(); 
	While Selection.Next() Do
		Attributes = New Structure("Object");
		FillPropertyValues(Attributes, Selection);
		AttributesOfSettlementObjects.Insert(Selection.Ref, Attributes);
	EndDo;
	
	For Each String In Object[TSName] Do
		Attributes = AttributesOfSettlementObjects[String.ARAPObject];
		If Attributes <> Undefined Then
			If Not ThisIsDebit Then
				String.ObjectOfCalculationsIsGiftCertificate = TypeOf(Attributes.Object) = Type("CatalogRef.GiftCertificates");
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateCounterpartySServiceAttributes(Kind)
	
	ThisIsDebit = Kind = "Dr";
	
	RelatedAttributesOfForm = New Map;
	If ThisIsDebit Then
		ObjectAttributeName = "CounterpartyDebtor";
		AttributeNameOfSettlementBetweenOrganizations = "SettlementsBetweenCompaniesDebtor";
		RelatedAttributesOfForm.Insert("LegalEntityIndividualDebtor", "LegalEntityIndividual");
	Else
		ObjectAttributeName = "Creditor";
		AttributeNameOfSettlementBetweenOrganizations = "SettlementsBetweenCompaniesCreditor";
		RelatedAttributesOfForm.Insert("LegalEntityIndividualCreditor", "LegalEntityIndividual");
	EndIf;
	
	ObjectAttributesValues = New Structure;
	If ValueIsFilled(Object[ObjectAttributeName]) And Not ThisForm[AttributeNameOfSettlementBetweenOrganizations] Then
		ObjectAttributes = New Structure;
		For Each RelatedAttributes In RelatedAttributesOfForm Do
			ObjectAttributes.Insert(RelatedAttributes.Value);
		EndDo;
		ObjectAttributesValues = Common.ObjectAttributesValues(Object[ObjectAttributeName], ObjectAttributes);
	EndIf;
	
	FormAttributeValue = Undefined;
	For Each RelatedAttributes In RelatedAttributesOfForm Do
		ObjectAttributesValues.Property(RelatedAttributes.Value, FormAttributeValue);
		ThisForm[RelatedAttributes.Key] = FormAttributeValue;
	EndDo;
	
EndProcedure

&AtClient
Procedure ShowAmountsMenLocal(Command)
	
	NewMark = Not Items.AccountsReceivableShowAmountsMenLocal.Check;
	Items.AccountsReceivableSumCompl.Visible = NewMark;
	Items.AccountsReceivableSumMan.Visible = NewMark;
	Items.AccountsReceivableShowAmountsMenLocal.Check = NewMark;
	
	NewMark = Not Items.AccountsPayableShowAmountsMenLocal.Check;
	Items.AccountsPayableSumCompl.Visible = NewMark;
	Items.AccountsPayableSumMan.Visible = NewMark;
	Items.AccountsPayableShowAmountsMenLocal.Check = NewMark;
	
	If Items.Pages.CurrentPage = Items.GroupAccountsReceivable Then
		
	ElsIf Items.Pages.CurrentPage = Items.GroupAccountsPayable Then
		
	EndIf;
	
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

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
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

#Region Private

#Region FormItemsManagement

&AtServer
Procedure SetPropertiesOfFormElementsByTypeOfOperation(SwitchPages = False)
	
	ArbitraryOperation = (Object.OperationKind = Enums.KindsOfARAPSettlements.Arbitrary);
	OperationForOffsettingPaymentThroughCommissionAgent = (Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent);
	OperationToRefundPaymentFromCommissionAgent = (Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent);
	OperationPaymentByGiftCertificate = (Object.OperationKind = Enums.KindsOfARAPSettlements.PaymentByGiftCard);
	
	OperationBarter = (Object.OperationKind = Enums.KindsOfARAPSettlements.Barter
						Or Object.OperationKind = Enums.KindsOfARAPSettlements.ARAPClearingBetweenCompanies);
	
	Items.CounterpartyDebtorType.Visible  = ArbitraryOperation;
	Items.CounterpartyCreditorType.Visible = ArbitraryOperation;
	Items.FormCalculateOffset.Visible = ArbitraryOperation Or OperationBarter;
	
	PresentationsStructure = Documents.ARAPSettlement.PresentationOfBankingDetailsByTypeOfOperation(Object.OperationKind);
	Items.Organization.Title = PresentationsStructure.Organization;
	Items.CompanyCreditor.Title = PresentationsStructure.CompanyCreditor;
	Items.CounterpartyDebtorType.Title = PresentationsStructure.CounterpartyDebtor;
	Items.CounterpartyCreditorType.Title = PresentationsStructure.Creditor;
	
	Items.CounterpartyDebtor.Title = PresentationsStructure.CounterpartyDebtor;
	Items.Creditor.Title = PresentationsStructure.Creditor;
	
	CounterpartyDebtorSelectionParameters = New Array;
	
	If ArbitraryOperation Then
		Items.CounterpartyDebtor.TitleLocation = FormItemTitleLocation.None;
		Items.Creditor.TitleLocation = FormItemTitleLocation.None;
	Else
		Items.CounterpartyDebtor.TitleLocation = FormItemTitleLocation.Auto;
		Items.Creditor.TitleLocation = FormItemTitleLocation.Auto;
	EndIf;
	
	Items.CounterpartyDebtor.ChoiceParameters = New FixedArray(CounterpartyDebtorSelectionParameters);
	
	Items.Creditor.Enabled = Not OperationPaymentByGiftCertificate;
	
	Items.SelectDebtor.Visible = Not OperationForOffsettingPaymentThroughCommissionAgent
		And Not OperationToRefundPaymentFromCommissionAgent;
	
	BetweenCompanies = SelectedTypeOfOperationBetweenOrganizations(Object.OperationKind);
	Items.CompanyCreditor.Visible          = BetweenCompanies;
	
	ItemVisibility = SelectedTypeOfOperationBetweenCounterparties(Object.OperationKind);
	Items.SelectCreditor.Visible = ItemVisibility And Not OperationForOffsettingPaymentThroughCommissionAgent
		And Not OperationToRefundPaymentFromCommissionAgent;
	
	EstablishVisibilityOfDebt(SwitchPages);
	CustomerTransactions = TypeOfOperationWithClientIsSelected();
	RecipientSHeader = NStr("vi = 'Người nhận';
							|ru = 'Получатели';
							|en = 'Recipients'; fa = 'گیرندگان';
							|it = 'Получатели';
							|pl = 'Recipients';
							|tr = 'Alıcılar'");
	If SelectedTypeOfOperationAdvanceTransfer() Then
		
		NewTitle = NStr("vi = 'Ứng trước';
						|ru = 'Авансы';
						|en = 'Advance payments'; fa = 'پیش‌پرداخت‌ها';
						|it = 'Pagamenti anticipati';
						|pl = 'Zaliczki';
						|tr = 'Avanslar'");
		If CustomerTransactions Then
			Items.GroupAccountsPayable.Title = NewTitle;
			Items.GroupAccountsReceivable.Title = RecipientSHeader;
		Else
			Items.GroupAccountsReceivable.Title = NewTitle;
			Items.GroupAccountsPayable.Title = RecipientSHeader;
		EndIf;
		
	ElsIf SelectedTypeOfOperationDebtTransfer() Then
		
		NewTitle = NStr("vi = 'Nợ';
						|ru = 'Долги';
						|en = 'Debts'; fa = 'Debts';
						|it = 'Debiti';
						|pl = 'Długi';
						|tr = 'Borçlar'");
		If CustomerTransactions Then
			Items.GroupAccountsReceivable.Title = NewTitle;
			Items.GroupAccountsPayable.Title = RecipientSHeader;
		Else
			Items.GroupAccountsPayable.Title = NewTitle;
			Items.GroupAccountsReceivable.Title = RecipientSHeader;
		EndIf;
		
	ElsIf Object.OperationKind = Enums.KindsOfARAPSettlements.Barter
			Or Object.OperationKind = Enums.KindsOfARAPSettlements.ARAPClearingBetweenCompanies Then
		
		Items.GroupAccountsReceivable.Title = NStr("vi = 'Xuất kho';
													|ru = 'Отгрузки';
													|en = 'Shipments'; fa = 'Shipments';
													|it = 'Spedizioni';
													|pl = 'Shipments';
													|tr = 'Sevkiyatlar'");
		Items.GroupAccountsPayable.Title = NStr("vi = 'Doanh thu bán hàng và cung cấp dịch vụ';
												|ru = 'Поступления';
												|en = 'Inflow'; fa = 'ورودی';
												|it = 'Arrivi';
												|pl = 'Inflow';
												|tr = 'Girişler'");
		
	Else
		
		Items.GroupAccountsReceivable.Title = NStr("vi = 'Công nợ phải thu';
													|ru = 'Дебиторская задолженность';
													|en = 'Accounts receivable'; fa = 'حساب‌های دریافتنی';
													|it = 'Crediti';
													|pl = 'Wierzytelność';
													|tr = 'Alacak hesapları'");
		Items.GroupAccountsPayable.Title = NStr("vi = 'Công nợ phải trả';
												|ru = 'Кредиторская задолженность';
												|en = 'Accounts payable'; fa = 'حساب‌های پرداختنی';
												|it = 'Debiti';
												|pl = 'Zobowiązania';
												|tr = 'Borç hesapları'");
		
	EndIf;
	
	If Not RadioButtonAccountsReceivable Then
		Items.PagesAccountsReceivable.CurrentPage = Items.AccountsReceivableWithoutSplit;
		SetAvailabilityOfAccountsReceivableItemsWithoutPartitioning();
	Else
		Items.PagesAccountsReceivable.CurrentPage = Items.AccountsReceivableAsAList;
	EndIf;
	
	If Not RadioButtonAccountsPayable Then
		Items.PagesAccountsPayable.CurrentPage = Items.AccountsPayableWithoutSplit;
		EstablishAvailabilityOfAccountsPayableItemsWithoutPartitioning();
	Else
		Items.PagesAccountsPayable.CurrentPage = Items.AccountsPayableAsAList;
	EndIf;
	
	SetVisibilityOfBranches();
	SetVisibilityOfCalculationObjectDrCr();
	Items.ARAPObjectIntercompany.Visible = BetweenCompanies;
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfDebt(SwitchPages = False)
	
	Items.AccountsReceivableShowAmountsMenLocal.Visible = False;
	Items.AccountsPayableShowAmountsMenLocal.Visible = False;
	
	Items.FooterGroup.Visible = False;
	Items.GroupTotalSettlement.Visible = False;
	
	Items.AccountsReceivableWithoutSplitSumCompl.Visible = False;
	Items.AccountsReceivableWithoutSplitSumMan.Visible = False;
	
	Items.AccountsPayableWithoutDivisionAmountRegl.Visible = False;
	Items.AccountsPayableWithoutSplittingUprAmount.Visible = False;
	
	Items.AccountsReceivableSumCompl.Visible = False;
	Items.AccountsReceivableSumMan.Visible = False;
	
	Items.AccountsPayableSumCompl.Visible = False;
	Items.AccountsPayableSumMan.Visible = False;
	
	Items.AccountsReceivableShowAmountsMenLocal.Check = False;
	Items.AccountsPayableShowAmountsMenLocal.Check = False;
	
	SetAvailabilityOfMenSLocalAmounts(True);
	
	Items.FillInAccordingToTheReceivable.Visible = False;
	Items.FillInAccordingToTheAccountsPayable.Visible = False;
	
	Items.FillInAccordingToTheReceivable.Title = NStr("vi = 'Điền vào các khoản phải thu';
														|ru = 'Заполнить по дебиторской задолженности';
														|en = 'Fill in by accounts receivable'; fa = 'تکمیل بر اساس حساب‌های دریافتنی';
														|it = 'Compila secondo i crediti';
														|pl = 'Wypełnij wg wierzytelności';
														|tr = 'Alacak hesaplarına göre doldur'");
	Items.FillInAccordingToTheAccountsPayable.Title = NStr("vi = 'Điền vào các khoản phải trả';
															|ru = 'Заполнить по кредиторской задолженности';
															|en = 'Fill in by accounts payable'; fa = 'تکمیل بر اساس حساب‌های پرداختنی';
															|it = 'Compila secondo i debiti';
															|pl = 'Wypełnij wg zobowiązań';
															|tr = 'Borç hesaplarına göre doldur'");
	
	Items.AccountsReceivablePickUpGiftCertificate.Visible = False;
	Items.AccountsPayablePickUpGiftCertificate.Visible = False;
	
	ButtonTitle = NStr("vi = 'Điền';
						|ru = 'Заполнить';
						|en = 'Fill'; fa = 'پرکردن';
						|it = 'Compilare';
						|pl = 'Wypełnij';
						|tr = 'Doldur'");
	CustomerTransactions = TypeOfOperationWithClientIsSelected();
	
	ShowPartner = Not TypeOfOperationBetweenTwoCompaniesHasBeenSelected(Object.OperationKind);
	DebtorOrganization = Object.CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor
		Or Object.CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient;
	LenderOrganization = Object.CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor
		Or Object.CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient;
	Items.AccountsReceivablePartner.Visible = ShowPartner And Not DebtorOrganization;
	Items.AccountsReceivableWithoutSplitPartner.Visible = ShowPartner And Not DebtorOrganization;
	Items.AccountsPayablePartner.Visible = ShowPartner And Not LenderOrganization;
	Items.AccountsPayableWithoutSplittingPartner.Visible = ShowPartner And Not LenderOrganization;
	
	If SwitchPages Then
		Items.Move(Items.GroupAccountsReceivable,Items.Pages,Items.GroupAccountsPayable);
		Items.Pages.CurrentPage = Items.GroupAccountsReceivable;
	EndIf;
	If SelectedTypeOfOperationAdvanceTransfer() Then
		
		AdjustVisibilityOfLocalizedElements();
		
		Items.AccountsReceivableShowAmountsMenLocal.Visible = True;
		Items.AccountsPayableShowAmountsMenLocal.Visible = True;
		SetAvailabilityOfMenSLocalAmounts(False);
		
		If CustomerTransactions Then
			If SwitchPages Then
				Items.Move(Items.GroupAccountsPayable,Items.Pages,Items.GroupAccountsReceivable);
				Items.Pages.CurrentPage = Items.GroupAccountsPayable;
			EndIf;
			ButtonAutofill = Items.FillInAccordingToTheAccountsPayable;
		Else
			ButtonAutofill = Items.FillInAccordingToTheReceivable;
		EndIf;
		
		Items.PaymentViaCommissionAgentReflectionPage.Visible = False;
		Items.PageForReturningPaymentViaCommissionAgent.Visible = False;
		Items.DataOnIncomingDocument.Visible = False;
		
		ButtonAutofill.Title = NStr("vi = 'Điền theo khoản ứng trước';
									|ru = 'Заполнить по авансам';
									|en = 'Fill in by advances'; fa = 'Fill in by advances';
									|it = 'Completare per pagamenti anticipati';
									|pl = 'Wypełnij wg zaliczek';
									|tr = 'Avansa göre doldur'");
		ButtonAutofill.Visible = True;
		
	ElsIf SelectedTypeOfOperationDebtTransfer() Then
		
		Items.FooterGroup.Visible = True;
		Items.GroupTotalSettlement.Visible = False;
		
		Items.AccountsReceivableShowAmountsMenLocal.Visible = True;
		Items.AccountsPayableShowAmountsMenLocal.Visible = True;
		SetAvailabilityOfMenSLocalAmounts(False);
		
		If Not CustomerTransactions Then
			If SwitchPages Then
				Items.Move(Items.GroupAccountsPayable,Items.Pages,Items.GroupAccountsReceivable);
				Items.Pages.CurrentPage = Items.GroupAccountsPayable;
			EndIf;
			ButtonAutofill = Items.FillInAccordingToTheAccountsPayable;
		Else
			ButtonAutofill = Items.FillInAccordingToTheReceivable;
		EndIf;
		
		Items.PaymentViaCommissionAgentReflectionPage.Visible = False;
		Items.PageForReturningPaymentViaCommissionAgent.Visible = False;
		Items.DataOnIncomingDocument.Visible = False;
		
		ButtonAutofill.Title = NStr("vi = 'Điền theo công nợ';
									|ru = 'Заполнить по долгам';
									|en = 'Fill in by debts'; fa = 'Fill in by debts';
									|it = 'Completare per debiti';
									|pl = 'Wypełnij według długów';
									|tr = 'Borçlara göre doldur'");
		ButtonAutofill.Visible = True;
		
	ElsIf Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent Then
		
		Items.FooterGroup.Visible = True;
		Items.GroupTotalSettlement.Visible = False;
		
		Items.GroupAccountsReceivable.Visible = False;
		Items.ButtonsAccountsReceivable.Visible = False;
		Items.AccountsReceivableWithoutSplit.Visible = False;
		
		Items.GroupAccountsPayable.Visible = False;
		Items.ButtonsAccountsPayable.Visible = False;
		Items.AccountsPayableWithoutSplit.Visible = False;
		
		Items.PaymentViaCommissionAgentReflectionPage.Visible = True;
		Items.PageForReturningPaymentViaCommissionAgent.Visible = False;
		
		Items.DataOnIncomingDocument.Title = NStr("vi = 'Dữ liệu theo chứng từ thanh toán đầu vào';
													|ru = 'Данные по входящему платежному документу';
													|en = 'Incoming payment document data'; fa = 'داده‌های سند دریافت';
													|it = 'Dati del documento di pagamento in entrata';
													|pl = 'Dane dotyczące przychodzącego dokumentu płatniczego';
													|tr = 'Gelen ödeme belgesi verileri'");
		Items.DataOnIncomingDocument.Visible = True;
		
	ElsIf Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent Then
		
		Items.FooterGroup.Visible = True;
		Items.GroupTotalSettlement.Visible = False;
		
		Items.GroupAccountsReceivable.Visible = False;
		Items.ButtonsAccountsReceivable.Visible = False;
		Items.AccountsReceivableWithoutSplit.Visible = False;
		
		Items.GroupAccountsPayable.Visible = False;
		Items.ButtonsAccountsPayable.Visible = False;
		Items.AccountsPayableWithoutSplit.Visible = False;
		
		Items.PaymentViaCommissionAgentReflectionPage.Visible = False;
		Items.PageForReturningPaymentViaCommissionAgent.Visible = True;
		
		Items.DataOnIncomingDocument.Title = NStr("vi = 'Dữ liệu theo chứng từ thanh toán trả lại đầu vào';
													|ru = 'Данные по входящему платежному документу возврата';
													|en = 'Incoming payment return document data'; fa = 'Incoming payment return document data';
													|it = 'Dati del documento di pagamento in entrata del reso';
													|pl = 'Dane dotyczące przychodzącego dokumentu płatniczego zwrotu';
													|tr = 'İadenin gelen ödeme belgesine ilişkin verileri'");
		Items.DataOnIncomingDocument.Visible = True;
		
	Else
		
		Items.FooterGroup.Visible = True;
		Items.GroupTotalSettlement.Visible = True;
	
		Items.AccountsReceivableWithoutSplitSumCompl.Visible = True;
		Items.AccountsReceivableWithoutSplitSumMan.Visible = True;
		
		Items.AccountsPayableWithoutDivisionAmountRegl.Visible = True;
		Items.AccountsPayableWithoutSplittingUprAmount.Visible = True;
		
		Items.AccountsReceivableSumCompl.Visible = True;
		Items.AccountsReceivableSumMan.Visible = True;
		
		Items.AccountsPayableSumCompl.Visible = True;
		Items.AccountsPayableSumMan.Visible = True;
		
		Items.GroupAccountsReceivable.Visible = True;
		Items.ButtonsAccountsReceivable.Visible = True;
		Items.AccountsReceivableWithoutSplit.Visible = True;
		
		Items.GroupAccountsPayable.Visible = True;
		Items.ButtonsAccountsPayable.Visible = True;
		Items.AccountsPayableWithoutSplit.Visible = True;
		
		Items.FillInAccordingToTheReceivable.Visible = True;
		Items.FillInAccordingToTheAccountsPayable.Visible = True;
		
		Items.PaymentViaCommissionAgentReflectionPage.Visible = False;
		Items.PageForReturningPaymentViaCommissionAgent.Visible = False;
		Items.DataOnIncomingDocument.Visible = False;
		
	EndIf;
	
	EstablishVisibilityOfBusinessDirection();
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfBusinessDirection()
	VisibilityOfLineOfBusiness = 
		Object.OperationKind = Enums.KindsOfARAPSettlements.Arbitrary
		And Object.CounterpartyDebtorType <> Enums.ARAPSettlemenParticipantTypes.OrganizationClient
		And Object.CounterpartyDebtorType <> Enums.ARAPSettlemenParticipantTypes.CompanyVendor
		And Object.CounterpartyCreditorType <> Enums.ARAPSettlemenParticipantTypes.OrganizationClient
		And Object.CounterpartyCreditorType <> Enums.ARAPSettlemenParticipantTypes.CompanyVendor;
	
	Items.PayablesWithoutDivisionLineOfBusiness.Visible = VisibilityOfLineOfBusiness;
	Items.AccountsPayableLineOfBusiness.Visible = VisibilityOfLineOfBusiness;
	Items.ReceivablesWithoutDivisionLineOfBusiness.Visible = VisibilityOfLineOfBusiness;
	Items.AccountsReceivableLineOfBusiness.Visible = VisibilityOfLineOfBusiness;
EndProcedure

&AtServer
Procedure SetVisibilityOfCalculationObjectDrCr()
	Items.ARAPObjectDebtorCreditor.Visible = 
		(Object.CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient
			Or Object.CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor
			Or Object.CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient
			Or Object.CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor)
		And (Object.CounterpartyDebtor <> Object.Creditor
			Or Not (ValueIsFilled(Object.CounterpartyDebtor) Or ValueIsFilled(Object.Creditor)))
		And Not TypeOfOperationBetweenTwoCompaniesHasBeenSelected(Object.OperationKind);
EndProcedure

&AtServer
Procedure SetAvailabilityOfMenSLocalAmounts(ThereIsAccess)
	
	Items.AccountsReceivableSumCompl.ReadOnly = Not ThereIsAccess;
	Items.AccountsReceivableSumMan.ReadOnly = Not ThereIsAccess;
	
	Items.AccountsPayableSumCompl.ReadOnly = Not ThereIsAccess;
	Items.AccountsPayableSumMan.ReadOnly = Not ThereIsAccess;
	
EndProcedure

&AtServer
Procedure InitializeDebt(Kind)
	
	If Kind = "Dr" Then
		TSName                    = "AccountsReceivable";
		NameOfSwitchElement = "RadioButtonAccountsReceivable";
	Else
		TSName                    = "AccountsPayable";
		NameOfSwitchElement = "RadioButtonAccountsPayable";
	EndIf;
	
	TabularSection = Object[TSName];
	If TabularSection.Count() = 0 Then
		NewRow = TabularSection.Add();
		NewRow.ARAPCurrency = LocalAccountingCurrency;
		If Kind = "Dr" Then
			FillInDebtorSPartner();
		Else
			FillInLenderSPartner();
		EndIf;
	EndIf;
	Items[TSName].CurrentRow      = TabularSection[0].GetID();
	ThisForm[NameOfSwitchElement] = TabularSection.Count() > 1;
	
EndProcedure

&AtClient
Function CurRowOfDebt(Kind)

	TSName = ?(Kind = "Dr", "AccountsReceivable", "AccountsPayable");
	TableRow = Items[TSName].CurrentData;
	If TableRow = Undefined Then
		TableRow = Object[TSName][0];
	EndIf;
	Return TableRow;
	
EndFunction

&AtServer
Procedure SetAvailabilityOfAccountsReceivableItemsWithoutPartitioning()

	If Object.AccountsReceivable.Count() > 0 Then
		
		CurRow = Object.AccountsReceivable[0];
		
		Items.AccountsReceivableWithoutSplitSumCompl.Enabled = CurRow.ARAPCurrency <> LocalAccountingCurrency;
		Items.AccountsReceivableWithoutSplitSumMan.Enabled = CurRow.ARAPCurrency <> ManagementAccountingCurrency;
		
		Items.LocalCustomerSAmount.Enabled = CurRow.ARAPCurrency <> LocalAccountingCurrency;
		Items.AmountOfClientSMan.Enabled = CurRow.ARAPCurrency <> ManagementAccountingCurrency;
		
		Items.AmountOfLocalRefundOfCommissionAgent.Enabled = CurRow.ARAPCurrency <> LocalAccountingCurrency;
		Items.AmountOfManSRefundOfCommissionAgent.Enabled = CurRow.ARAPCurrency <> ManagementAccountingCurrency;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure EstablishAvailabilityOfAccountsPayableItemsWithoutPartitioning()
	
	If Object.AccountsPayable.Count() > 0 Then
		
		CurRow = Object.AccountsPayable[0];
		
		Items.AccountsPayableWithoutDivisionAmountRegl.Enabled = CurRow.ARAPCurrency <> LocalAccountingCurrency;
		Items.AccountsPayableWithoutSplittingUprAmount.Enabled = CurRow.ARAPCurrency <> ManagementAccountingCurrency;
		
		Items.AmountOfLocalCommissionAgent.Enabled = CurRow.ARAPCurrency <> LocalAccountingCurrency;
		Items.AmountOfManOfCommissionAgent.Enabled = CurRow.ARAPCurrency <> ManagementAccountingCurrency;
		
		Items.LocalCustomerRefundAmount.Enabled = CurRow.ARAPCurrency <> LocalAccountingCurrency;
		Items.ManSRefundAmount.Enabled = CurRow.ARAPCurrency <> ManagementAccountingCurrency;
		
	EndIf;
	
EndProcedure
	
&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	// Settlement currency = Currency

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsReceivableSumCompl.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsReceivableWithoutSplitSumCompl.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AccountsReceivable.ARAPCurrency");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("LocalAccountingCurrency");

	Item.Appearance.SetParameterValue("ReadOnly", True);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsPayableSumCompl.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsPayableWithoutDivisionAmountRegl.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AccountsPayable.ARAPCurrency");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("LocalAccountingCurrency");

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	// Settlement currency = Currency
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsReceivableSumMan.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsReceivableWithoutSplitSumMan.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AccountsReceivable.ARAPCurrency");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("ManagementAccountingCurrency");

	Item.Appearance.SetParameterValue("ReadOnly", True);

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsPayableSumMan.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsReceivableWithoutSplitSumMan.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AccountsPayable.ARAPCurrency");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("ManagementAccountingCurrency");

	Item.Appearance.SetParameterValue("ReadOnly", True);

	// 
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AccountsPayableARAPObject.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.OperationKind");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.KindsOfARAPSettlements.PaymentByGiftCard;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfBranches()
	
	ThereAreBranches = Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Object.Organization).Count() > 0;
	BetweenCompanies = SelectedTypeOfOperationBetweenOrganizations(Object.OperationKind);
	DrSCompanyMatches = Object.AccountsReceivable.Count() = 1 
		And ValueIsFilled(Object.AccountsReceivable[0].Organization)
		And Object.Organization = Object.AccountsReceivable[0].Organization;
	CrCompanyMatches = Object.AccountsPayable.Count() = 1 
		And ValueIsFilled(Object.AccountsPayable[0].Organization)
		And Object.Organization = Object.AccountsPayable[0].Organization;
	
	Items.AccountsReceivableOrganization.Visible  = ThereAreBranches;
	Items.AccountsReceivableWithoutSplitOrganization.Visible  = ThereAreBranches And Not DrSCompanyMatches;
	Items.AccountsPayableOrganization.Visible = ThereAreBranches And Not BetweenCompanies;
	Items.AccountsPayableWithoutDivisionOrganization.Visible = ThereAreBranches And Not BetweenCompanies And Not CrCompanyMatches;
	
EndProcedure

&AtServer
Procedure RestrictChoiceOfOperationType()
	
	If Not Users.IsFullUser()
		And Not Users.RolesAvailable("AddEditARAPAdjustmentDocuments") Then
		
		Items.OperationKind.ChoiceList.Add(Enums.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty);
		Items.OperationKind.ChoiceList.Add(Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty);
		Items.OperationKind.ChoiceList.Add(Enums.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty);
		
		If Items.OperationKind.ChoiceList.FindByValue(Object.OperationKind) = Undefined Then
			Items.OperationKind.ReadOnly = True;
		Else
			Items.OperationKind.ListChoiceMode = True;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FillType

&AtClient
Procedure AutoTestToCalculateTheOffsetCompletion(Result, AdditionalParameters) Export 
	
	If ValueIsFilled(AdditionalParameters) Then
		AmountsOnly = AdditionalParameters.Property("AmountsOnly");
	Else
		AmountsOnly = False;
	EndIf;
	
	DebtParametersDebtor  = StructureOfDebtParameters(ThisForm);
	DebtParametersCreditor = StructureOfDebtParameters(ThisForm, True);
	
	If Not AmountsOnly Then
		
		If Not NewOnlineARAPAccounting Then
			DimensionToCalculation = ThereAreTasksForDistribution(DebtParametersDebtor, DebtParametersCreditor);
			
			If DimensionToCalculation.Count() > 0 Then
				PopulatedTS = "";
				AttachIdleHandler("BackgroundJobCheckOnClient", 0.1, True);
				Return;
			EndIf;
		EndIf;
		
		FillInBalancesOfAccountsReceivableAndPayable(DebtParametersDebtor, DebtParametersCreditor);
		CalculateNettingAmounts(Object.SumCompl);
		
		Items.AccountsReceivable.Refresh();
		Items.AccountsPayable.Refresh();
		AutoTest_CalculateNettingCompletionOnServer();
	Else
		
		If PopulatedTS = "" Then
			FillInManLocalAmounts(DebtParametersDebtor, False);
			FillInManLocalAmounts(DebtParametersCreditor, True);
		ElsIf PopulatedTS = "AccountsReceivable" Then
			FillInManLocalAmounts(DebtParametersDebtor, False);
		Else
			FillInManLocalAmounts(DebtParametersCreditor, True);
		EndIf;
		
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AutoTest_CalculateNettingCompletionOnServer()
	SetPropertiesOfFormElementsByTypeOfOperation();
	BlockSettlementObjects();
EndProcedure

&AtServer
Procedure FillInRemainingAccountsReceivable(DebtParametersCreditor)
	
	ARAPAccountingServer.FillInDebtOnBalanceOfSettlements(
		DebtParametersCreditor.Organization.Value,
		DebtParametersCreditor.Counterparty.Value,
		Enums.DebtTypes.AccountsReceivableType,
		DebtParametersCreditor.PaymentType_,
		Object.Date,
		DocumentCurrencyToTransfer("AccountsReceivable"),
		Object.AccountsReceivable);
	BlockSettlementObjects();
	FillInLinesOfBusiness(Items.AccountsReceivable.Name);
	
EndProcedure

&AtServer
Procedure FillInRemainingAccountsPayable(DebtParametersCreditor)
	
	ARAPAccountingServer.FillInDebtOnBalanceOfSettlements(
		DebtParametersCreditor.Organization.Value,
		DebtParametersCreditor.Counterparty.Value,
		Enums.DebtTypes.AccountsPayableType,
		DebtParametersCreditor.PaymentType_,
		Object.Date,
		DocumentCurrencyToTransfer("AccountsPayable"),
		Object.AccountsPayable);
	BlockSettlementObjects();
	FillInLinesOfBusiness(Items.AccountsPayable.Name);
	
EndProcedure

&AtServer
Procedure FillInBalancesOfAccountsReceivableAndPayable(DebtParametersDebtor, DebtParametersCreditor)
	
	ARAPAccountingServer.FillInDebtOnBalanceOfSettlements(
		DebtParametersDebtor.Organization.Value,
		DebtParametersDebtor.Counterparty.Value,
		Enums.DebtTypes.AccountsReceivableType,
		DebtParametersDebtor.PaymentType_,
		Object.Date,
		DocumentCurrencyToTransfer("AccountsReceivable"),
		Object.AccountsReceivable);
	
	ARAPAccountingServer.FillInDebtOnBalanceOfSettlements(
		DebtParametersCreditor.Organization.Value,
		DebtParametersCreditor.Counterparty.Value,
		Enums.DebtTypes.AccountsPayableType,
		DebtParametersCreditor.PaymentType_,
		Object.Date,
		DocumentCurrencyToTransfer("AccountsPayable"),
		Object.AccountsPayable);
	BlockSettlementObjects();
	
EndProcedure

&AtClient
Procedure SelectAccountsReceivableByAmountDueCompletion(Result, AdditionalParameters) Export
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	AddressOfPaymentsInTheStorage = PlacePaymentDecryptionInVault(Object.AccountsReceivable);
	
	DebtParameters  = StructureOfDebtParameters(ThisForm);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ObjectRef",                          Object.Ref);
	OpeningParameters.Insert("AddressOfPaymentsInTheStorage",               AddressOfPaymentsInTheStorage);
	OpeningParameters.Insert("Organization",                           DebtParameters.Organization.Value);
	OpeningParameters.Insert("RecordBranches",                      True);
	OpeningParameters.Insert("Counterparty",                            DebtParameters.Counterparty.Value);
	OpeningParameters.Insert("FillInVATInDecryption",              False);
	If Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.Barter")
			And Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.ARAPClearingBetweenCompanies")
			And Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.Arbitrary")
			And Object.AccountsPayable.Count() > 0
			And ValueIsFilled(Object.AccountsPayable[0].ARAPObject) Then
		OpeningParameters.Insert("DocumentCurrency", Object.AccountsPayable[0].ARAPCurrency);
	EndIf; 
	OpeningParameters.Insert("DocumentAmount",                        0);
	OpeningParameters.Insert("DocumentDate",                         Object.Date);
	OpeningParameters.Insert("PaymentType_",                           DebtParameters.PaymentType_);
	OpeningParameters.Insert("PaymentID",                  "");
	OpeningParameters.Insert("PartnerOtherRelations",                False);
	OpeningParameters.Insert("SelectAccountsReceivable",        True);
	OpeningParameters.Insert("SelectOnlyUnconditionalDebt",  False);
	If Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.Arbitrary")
			And Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.Barter")
			And Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.ARAPClearingBetweenCompanies") Then
		OpeningParameters.Insert("ARAPCurrency", ARAPCurrency);
		OpeningParameters.Insert("OneARAPCurrency", True);
	EndIf;
	OpeningParameters.Insert("AdditionalFilters",                  New Map());
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", ThisForm);
	AdditionalParameters.Insert("NotificationAfterCompletion", Undefined);
	
	OpenForm(
		"Catalog.ARAPObjects.Form.ARAPObjectSelection",
		OpeningParameters, 
		ThisForm,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectAccountsPayableByAmountDueCompletion(Result, AdditionalParameters) Export
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	AddressOfPaymentsInTheStorage = PlacePaymentDecryptionInVault(Object.AccountsPayable);
	
	DebtParameters  = StructureOfDebtParameters(ThisForm, True);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ObjectRef",                          Object.Ref);
	OpeningParameters.Insert("AddressOfPaymentsInTheStorage",               AddressOfPaymentsInTheStorage);
	OpeningParameters.Insert("Organization",                           DebtParameters.Organization.Value);
	OpeningParameters.Insert("RecordBranches",                      True);
	OpeningParameters.Insert("Counterparty",                            DebtParameters.Counterparty.Value);
	OpeningParameters.Insert("FillInVATInDecryption",              False);
	If Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.Barter")
			And Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.ARAPClearingBetweenCompanies")
			And Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.Arbitrary")
			And Object.AccountsReceivable.Count() > 0 
			And ValueIsFilled(Object.AccountsReceivable[0].ARAPObject) Then
		OpeningParameters.Insert("DocumentCurrency", Object.AccountsReceivable[0].ARAPCurrency);
	EndIf;
	OpeningParameters.Insert("DocumentAmount",                        0);
	OpeningParameters.Insert("DocumentDate",                         Object.Date);
	OpeningParameters.Insert("PaymentType_",                           DebtParameters.PaymentType_);
	OpeningParameters.Insert("PaymentID",                  "");
	OpeningParameters.Insert("PartnerOtherRelations",                False);
	OpeningParameters.Insert("SelectAccountsReceivable",        False);
	OpeningParameters.Insert("SelectOnlyUnconditionalDebt",  False);
	If Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.Arbitrary")
			And Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.Barter")
			And Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.ARAPClearingBetweenCompanies") Then
		OpeningParameters.Insert("ARAPCurrency", ARAPCurrency);
		OpeningParameters.Insert("OneARAPCurrency", True);
	EndIf;
	OpeningParameters.Insert("AdditionalFilters",                  New Map());
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form", ThisForm);
	AdditionalParameters.Insert("NotificationAfterCompletion", Undefined);
	
	OpenForm(
		"Catalog.ARAPObjects.Form.ARAPObjectSelection",
		OpeningParameters, 
		ThisForm,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServer
Procedure FillInPartnerInTablePart(ObjectTablePart, PartnerLink, IntercompanyARAP)
	
	If Not ValueIsFilled(PartnerLink) Then
		Return;
	EndIf;
	
	For Each TableRow In ObjectTablePart Do
		If IntercompanyARAP Then
			TableRow.Partner = Undefined;
		ElsIf TableRow.Partner <> PartnerLink Then
			TableRow.Partner = PartnerLink;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure FillInDebtorSPartner()

	If Not SettlementsBetweenCompaniesDebtor Then
		If ValueIsFilled(Object.CounterpartyDebtor) Then
			PartnerDebtor = CashServer.GetCounterpartyPartner(Object.CounterpartyDebtor);
		Else
			PartnerDebtor = Catalogs.Partners.EmptyRef();
		EndIf;
	EndIf;
	
	If TypeOfOperationWithinSameCounterpartyHasBeenSelected() Then
		
		FillInPartnerInTablePart(Object.AccountsReceivable, PartnerDebtor, SettlementsBetweenCompaniesDebtor);
		FillInPartnerInTablePart(Object.AccountsPayable, PartnerDebtor, SettlementsBetweenCompaniesCreditor);
		
	Else
		
		If Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent
			Or Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent Then
			FillInEndClientData(True, PartnerDebtor);
		Else 
			FillInPartnerInTablePart(Object.AccountsReceivable, PartnerDebtor, SettlementsBetweenCompaniesDebtor);
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure FillInEndClientData(ReFillDocumentData = False, PartnerLink = Undefined)
	
	ThisIsPaymentThroughCommissionAgent = ?(Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent, True, False);
	ThisIsRefundOfPaymentThroughCommissionAgent = ?(Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent, True, False);
	
	If (ThisIsPaymentThroughCommissionAgent Or ThisIsRefundOfPaymentThroughCommissionAgent)
		And Object.AccountsPayable.Count() = 1 And Object.AccountsReceivable.Count() = 1 Then
		
		If ThisIsPaymentThroughCommissionAgent Then
			CurrentRowClient = Object.AccountsReceivable[0];
			CurLineCommissionAgent = Object.AccountsPayable[0];
			DetailsNameOfClientSCounterparty = "CounterpartyDebtor";
			DetailsNameOfCounterpartyCommissionAgent = "Creditor";
			TypeOfDebtOfClientSCounterparty = "Dr";
		Else
			CurLineCommissionAgent = Object.AccountsReceivable[0];
			CurrentRowClient = Object.AccountsPayable[0];
			DetailsNameOfClientSCounterparty = "Creditor";
			DetailsNameOfCounterpartyCommissionAgent = "CounterpartyDebtor";
			TypeOfDebtOfClientSCounterparty = "Cr";
		EndIf;
		
		If Not PartnerLink = Undefined And CurLineCommissionAgent.Partner <> PartnerLink Then
			CurLineCommissionAgent.Partner = PartnerLink;
		EndIf;
		
		If ValueIsFilled(CurLineCommissionAgent.ARAPObject) Then
			CommissionAgentContractData = GetContractDataFromSettlementObject(CurLineCommissionAgent.ARAPObject);
			CommissionAgentSAgreement = CommissionAgentContractData.Contract;
		Else
			CommissionAgentContractData = Undefined;
			CommissionAgentSAgreement = Undefined;
		EndIf;
		
		If ValueIsFilled(CurrentRowClient.ARAPObject) Then
			CustomerAgreementData = GetContractDataFromSettlementObject(CurrentRowClient.ARAPObject);
			CustomerContract = CustomerAgreementData.Contract;
		Else
			CustomerAgreementData = Undefined;
			CustomerContract = Undefined;
		EndIf;
		
		If ValueIsFilled(CustomerContract) Then
			CommissionSalesPartner = CustomerContract.Partner;
			CommissionSaleClient = CustomerContract.Counterparty;
		EndIf;
		
		If ReFillDocumentData
			And ValueIsFilled(CommissionAgentContractData) Then
			
			If CurLineCommissionAgent.Partner <> CommissionAgentSAgreement.Partner
				Or Object[DetailsNameOfCounterpartyCommissionAgent] <> CommissionAgentSAgreement.Counterparty Then
				
				CurLineCommissionAgent.ARAPObject = Undefined;
				
				If ThisIsPaymentThroughCommissionAgent Then
					EstablishAvailabilityOfAccountsPayableItemsWithoutPartitioning();
				Else
					SetAvailabilityOfAccountsReceivableItemsWithoutPartitioning();
				EndIf;
				
			EndIf;
			
			If CommissionAgentContractData.ConductARAPAccountingThroughEndCustomers Then
				NewCommissionSalesPartner = CommissionSalesPartner;
				NewCustomerCommissionSale = CommissionSaleClient;
			Else
				NewCommissionSalesPartner = CurLineCommissionAgent.Partner;
				NewCustomerCommissionSale = Object[DetailsNameOfCounterpartyCommissionAgent];
			EndIf;
			
			If CurrentRowClient.Partner <> NewCommissionSalesPartner
				Or Object[DetailsNameOfClientSCounterparty] <> NewCustomerCommissionSale Then
				
				CurrentRowClient.Partner = NewCommissionSalesPartner;
				Object[DetailsNameOfClientSCounterparty] = NewCustomerCommissionSale;
				UpdateCounterpartySServiceAttributes(TypeOfDebtOfClientSCounterparty);
				CurrentRowClient.ARAPObject = Undefined;
				
				If ThisIsPaymentThroughCommissionAgent Then
					SetAvailabilityOfAccountsReceivableItemsWithoutPartitioning();
				Else
					EstablishAvailabilityOfAccountsPayableItemsWithoutPartitioning();
				EndIf;
				
			EndIf
			
		EndIf;
		
		If ReFillDocumentData
			And ValueIsFilled(CustomerContract) Then
			
			If ValueIsFilled(CommissionAgentSAgreement)
				And CustomerContract.ContractWithCommissionAgent <> CommissionAgentSAgreement Then
			
				CurrentRowClient.ARAPObject = Undefined;
				If ThisIsPaymentThroughCommissionAgent Then
					SetAvailabilityOfAccountsReceivableItemsWithoutPartitioning();
				Else
					EstablishAvailabilityOfAccountsPayableItemsWithoutPartitioning();
				EndIf;
				
			ElsIf CustomerContract.Counterparty <> CommissionSaleClient
				Or CustomerContract.Partner <> CommissionSalesPartner Then
				
				CurrentRowClient.ARAPObject = Undefined;
				If ThisIsPaymentThroughCommissionAgent Then
					SetAvailabilityOfAccountsReceivableItemsWithoutPartitioning();
				Else
					EstablishAvailabilityOfAccountsPayableItemsWithoutPartitioning();
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInLenderSPartner(ClearTS = False)
	
	If Not SettlementsBetweenCompaniesCreditor Then
		If ValueIsFilled(Object.Creditor) Then
			PartnerCreditor = CashServer.GetCounterpartyPartner(Object.Creditor);
		Else
			PartnerCreditor = Catalogs.Partners.EmptyRef();
		EndIf;
	EndIf;
	
	If Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent Then
			FillInEndClientData(True, PartnerCreditor);
	Else
		FillInPartnerInTablePart(Object.AccountsPayable, PartnerCreditor, SettlementsBetweenCompaniesCreditor);
	EndIf;
	
EndProcedure

#EndRegion

#Region OnChangeAttributes

&AtClient
Procedure ObjectOfCalculationsCalculationsWhenChanging(TableName)
	If Object[TableName].Count() = 1 
			And Not ValueIsFilled(Object[TableName][0].ARAPObject) Then
			Object[TableName][0].ARAPCurrency = Undefined;
			Object[TableName][0].Organization = Undefined;
	EndIf;
EndProcedure

&AtClient
Procedure ARAPObjectStartChoice(Kind, Item, ChoiceData, Mirror = Undefined)
	
	ThisIsDebit = Kind = "Dr";
	
	DebtParameters = StructureOfDebtParameters(ThisForm, Not ThisIsDebit);
	
	ClientType = ?(ThisIsDebit, SettlementsWithCustomersDebtor, SettlementsWithCustomersCreditor);
	FilterValues = New Structure;
	FilterValues.Insert("PaymentType_", ?(ClientType,
											PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"),
											PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting")));
	If Not ValueIsFilled(Mirror) Then
		FilterValues.Insert("Organization", DebtParameters.Organization.Value);
		FilterValues.Insert("Counterparty",  DebtParameters.Counterparty.Value);
	Else
		FilterValues.Insert("Organization", DebtParameters.Counterparty.Value);
		FilterValues.Insert("Counterparty",  DebtParameters.Organization.Value);
	EndIf;
	FilterValues.Insert("PaymentsAsPer275FZ" , False);
	
 	ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	If TypeOf(FilterValues.Counterparty) = Type("CatalogRef.Companies") Then
		FilterValues.Insert("Partner", PredefinedValue("Catalog.Partners.OurEnterprise"));
	ElsIf ThisIsDebit Then
		If Items.AccountsReceivable.CurrentData <> Undefined Then
			If Not ValueIsFilled(Mirror) Then
				ARAPObject = Items.AccountsReceivable.CurrentData.ARAPObject;
			Else
				ARAPObject = Items.AccountsReceivable.CurrentData.ARAPObjectMirror;
			EndIf;
		ElsIf Object.AccountsReceivable.Count() > 0 Then
			If Not ValueIsFilled(Mirror) Then
				ARAPObject = Object.AccountsReceivable[0].ARAPObject;
			Else
				ARAPObject = Object.AccountsReceivable[0].ARAPObjectMirror;
			EndIf;
		EndIf;
	Else
		If Items.AccountsPayable.CurrentData <> Undefined Then
			If Not ValueIsFilled(Mirror) Then
				ARAPObject = Items.AccountsPayable.CurrentData.ARAPObject;
			Else
				ARAPObject = Items.AccountsPayable.CurrentData.ARAPObjectMirror;
			EndIf;
		ElsIf Object.AccountsPayable.Count() > 0 Then
			If Not ValueIsFilled(Mirror) Then
				ARAPObject = Object.AccountsPayable[0].ARAPObject;
			Else
				ARAPObject = Object.AccountsPayable[0].ARAPObjectMirror;
			EndIf;
		EndIf;
	EndIf;
	
	SelectionSettings_ = New Structure;
	SelectionSettings_.Insert("Sum", 0);
	SelectionSettings_.Insert("SelectAccountsReceivable", ThisIsDebit);
	SelectionSettings_.Insert("CurrentRow", ARAPObject);
	
	If Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent")
		Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent") Then
		SelectionSettings_.Insert("SelectPaymentObjectsByCommission", New Structure("SelectObjectsOfSettlementsWithEndClient", False));
	EndIf;

	OpenFormForSelectingCalculationObjects(Item, FilterValues, SelectionSettings_);
	
EndProcedure

&AtClient
Procedure CalculationObjectSelectionProcessing(Kind, ValueSelected)
		
	CurrentData = CurRowOfDebt(Kind);
	If TypeOf(ValueSelected) = Type("Structure") Then
		If Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent")
			Or Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent") Then
			FillPropertyValues(CurrentData, ValueSelected, "ARAPObject, ARAPCurrency, AmountARAP, Organization");
			FillInEndClientData(True);
		Else
			FillPropertyValues(CurrentData, ValueSelected,
				"ARAPObject, Partner, ARAPCurrency, Organization");
			If ValueSelected.AmountARAP <> 0 Then
				CurrentData.AmountARAP = ValueSelected.AmountARAP;
			EndIf;
		EndIf;
		
		CompanyCaps = CurrentData.Organization = Object.Organization;
		Modified = True;
		CurrentData.SumCompl = 0;
		CurrentData.SumMan = 0;
		If Kind = "Dr" Then
			SetAvailabilityOfAccountsReceivableItemsWithoutPartitioning();
			Items.AccountsReceivableWithoutSplitOrganization.Visible = Not CompanyCaps;
		Else
			EstablishAvailabilityOfAccountsPayableItemsWithoutPartitioning();
			Items.AccountsPayableWithoutDivisionOrganization.Visible = Not CompanyCaps;
		EndIf;
		SetSettlementCurrency(ValueSelected.ARAPCurrency);
	EndIf; 
	
EndProcedure

&AtServer
Procedure CalculationObjectSelectionProcessingServer(DebtKind)
	
	ThisIsLoan = DebtKind = "Cr";
	FillInManLocalAmounts(StructureOfDebtParameters(ThisForm, ThisIsLoan), ThisIsLoan);
	BlockSettlementObjects();
	FillInLinesOfBusiness(?(DebtKind = "Cr",Items.AccountsPayable.Name,Items.AccountsReceivable.Name));
	
EndProcedure

&AtClient
Procedure RecalculateAmountsOfManLocalServerCall(CurrentData)
	
	If CurrentData.ARAPCurrency = LocalAccountingCurrency Then
		CurrentData.SumCompl = CurrentData.AmountARAP;
	ElsIf CurrentData.SumCompl = 0 And ValueIsFilled(CurrentData.ARAPCurrency) Then
		CurrentData.SumCompl = ConvertToLocalSum(CurrentData.AmountARAP,
			CurrentData.ARAPCurrency, CurrentData.ARAPObject);
	EndIf;
	If CurrentData.ARAPCurrency = ManagementAccountingCurrency Then
		CurrentData.SumMan = CurrentData.AmountARAP;
	ElsIf CurrentData.SumMan = 0 And ValueIsFilled(CurrentData.ARAPCurrency) Then
		CurrentData.SumMan = RecalculateToAmountMAN(CurrentData.AmountARAP,
			CurrentData.ARAPCurrency, CurrentData.ARAPObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	FillInListOfOrganizations();
	SetVisibilityOfBranches();
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	BlockSettlementObjects();
	
EndProcedure

&AtClient
Procedure CompanyCreditorOnChange(Item)
	
	ItIsNecessaryToPurifyTS(
		New CallbackDescription("LenderOrganizationNeedsToClearPMCompletionWhenChanging", ThisObject),
		ThereAreLines("AccountsPayable"));
	
EndProcedure

&AtClient
Procedure LenderOrganizationNeedsToClearPMCompletionWhenChanging(ClearTS, AdditionalParameters) Export
	
	If ClearTS = DialogReturnCode.Yes Then
		LenderOrganizationWhenChangingOnServer();
		PreviousValues.CompanyCreditor = Object.CompanyCreditor;
	Else
		Object.CompanyCreditor = PreviousValues.CompanyCreditor;
	EndIf;
	
EndProcedure

&AtServer
Procedure LenderOrganizationWhenChangingOnServer()
	
	Object.ARAPObjectIntercompany = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	Object.ARAPObjectIntercompanyMirrored = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	BlockSettlementObjects();
	
EndProcedure

&AtServer
Procedure OperationKindOnChangeServer()
	
	Object.DocumentAmount = 0;
	Object.SumCompl = 0;
	Object.SumMan = 0;
	If Not ValueIsFilled(Object.ARAPObjectIntercompany) 
		And Not ValueIsFilled(Object.ARAPObjectDebtorCreditor) Then
		ARAPCurrency = Undefined;
	EndIf;
	
	If Object.OperationKind = Enums.KindsOfARAPSettlements.Arbitrary Then
		ARAPCurrency = Undefined;
	Else
		
		If TypeOfOperationWithClientIsSelected() Then
			CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.Client;
			CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.Client;
			If TypeOfOperationBetweenTwoCompaniesHasBeenSelected(Object.OperationKind) Then
				CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient;
				CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient;
			EndIf;
			If (Object.OperationKind = Enums.KindsOfARAPSettlements.PaymentByGiftCard) Then
				If Object.Creditor <> Catalogs.Counterparties.RetailCustomer Then
					Object.Creditor = Catalogs.Counterparties.RetailCustomer;
					UpdateCounterpartySServiceAttributes("Cr");
				EndIf;
				Object.AccountsPayable.Clear();
			EndIf;
		ElsIf TypeOfOperationWithSupplierIsSelected() Then
			CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.Vendor;
			CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.Vendor;
			If TypeOfOperationBetweenTwoCompaniesHasBeenSelected(Object.OperationKind) Then
				CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor;
				CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor;
			EndIf;
		Else //Barter
			CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.Client;
			CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.Vendor;
			If TypeOfOperationBetweenTwoCompaniesHasBeenSelected(Object.OperationKind) Then
				CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient;
				CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor;
			EndIf;
		EndIf;
		
		If Object.CounterpartyDebtorType <> CounterpartyDebtorType Then
			Object.CounterpartyDebtorType = CounterpartyDebtorType;
			SetDebtorType();
		EndIf;
		
		If Object.CounterpartyCreditorType <> CounterpartyCreditorType Then
			Object.CounterpartyCreditorType = CounterpartyCreditorType;
			SetLenderType();
		EndIf;
		
	EndIf;
	
	If SelectedTypeOfOperationBetweenCounterparties(Object.OperationKind)
		And Object.OperationKind <> Enums.KindsOfARAPSettlements.Arbitrary
		And Object.OperationKind <> Enums.KindsOfARAPSettlements.PaymentByGiftCard Then
		
		Object.Creditor = Catalogs.Counterparties.EmptyRef();
		If Object.OperationKind = Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties
			Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties Then
			UpdateCounterpartySServiceAttributes("Cr");
			For Each String In Object.AccountsPayable Do
				String.Partner = Undefined;
			EndDo;
		ElsIf Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties
			Or Object.OperationKind = Enums.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties Then
			UpdateCounterpartySServiceAttributes("Dr");
			For Each String In Object.AccountsReceivable Do
				String.Partner = Undefined;
			EndDo;
		EndIf;
		
	EndIf;
	
	If TypeOfOperationWithinSameCounterpartyHasBeenSelected() Then
		PartnerDebtor = CashServer.GetCounterpartyPartner(Object.CounterpartyDebtor);
		FillInPartnerInTablePart(Object.AccountsPayable, PartnerDebtor, SettlementsBetweenCompaniesCreditor);
	EndIf;
	
	If ValueIsFilled(Object.CompanyCreditor) And Not SelectedTypeOfOperationBetweenOrganizations(Object.OperationKind) Then
		Object.CompanyCreditor = Catalogs.Companies.EmptyRef();
	EndIf;
	
	If Not SelectedTypeOfOperationBetweenOrganizations(Object.OperationKind) Then
		Object.ARAPObjectIntercompany = Catalogs.ARAPObjects.EmptyRef();
	EndIf;
	
	If Object.CounterpartyCreditorType <> Enums.ARAPSettlemenParticipantTypes.OrganizationClient
		And Object.CounterpartyCreditorType <> Enums.ARAPSettlemenParticipantTypes.CompanyVendor Then
		Object.ARAPObjectDebtorCreditor = Catalogs.ARAPObjects.EmptyRef();
	EndIf;
	
	Object.AccountsReceivable.Clear();
	Object.AccountsPayable.Clear();
	
	InitializeDebt("Dr");
	InitializeDebt("Cr");
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	FillInListOfOrganizations();
	
	SwitchPages = True;
	SetPropertiesOfFormElementsByTypeOfOperation(SwitchPages);
	
	BlockSettlementObjects();
	
EndProcedure

&AtServer
Procedure DebtorTypeWhenChangedOnServer()
	
	SetVisibilityOfCalculationObjectDrCr();
	EstablishVisibilityOfBusinessDirection();
	SetDebtorType();
	FillInDebtorSPartner();
	BlockSettlementObjects();
	
EndProcedure

&AtServer
Procedure LenderTypeWhenChangedOnServer()
	
	SetVisibilityOfCalculationObjectDrCr();
	EstablishVisibilityOfBusinessDirection();
	SetLenderType();
	FillInLenderSPartner();
	BlockSettlementObjects();
	
EndProcedure

&AtServer
Procedure CounterpartyDebtorWhenChangingOnServer()
	
	UpdateCounterpartySServiceAttributes("Dr");
	FillInDebtorSPartner();
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	SetVisibilityOfCalculationObjectDrCr();
	BlockSettlementObjects();
	
EndProcedure

&AtServer
Procedure CounterpartyCreditorWhenChangingOnServer()
	
	UpdateCounterpartySServiceAttributes("Cr");
	FillInLenderSPartner();
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	SetVisibilityOfCalculationObjectDrCr();
	BlockSettlementObjects();
	
EndProcedure

&AtServer
Procedure AccountsReceivableWithoutSplittingObjectOfCalculationsWhenChangingOnServer(LineOfBusiness, ARAPObject)
	SetAvailabilityOfAccountsReceivableItemsWithoutPartitioning();
	BlockSettlementObjects();
	Debt_ARAPObjectOnChangeServer(LineOfBusiness, ARAPObject);
EndProcedure

&AtServer
Procedure AccountsPayableWithoutSplittingObjectOfCalculationsWhenChangingOnServer(LineOfBusiness, ARAPObject)
	EstablishAvailabilityOfAccountsPayableItemsWithoutPartitioning();
	BlockSettlementObjects();
	Debt_ARAPObjectOnChangeServer(LineOfBusiness, ARAPObject);
EndProcedure

&AtServer
Procedure Debt_ARAPObjectOnChangeServer(LineOfBusiness, ARAPObject)
	BlockSettlementObjects();
	If ValueIsFilled(ARAPObject) And Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.Arbitrary") Then
		LineOfBusiness = Common.ObjectAttributeValue(ARAPObject, "LineOfBusiness");
	Else
		LineOfBusiness = Catalogs.ARAPObjects.EmptyRef();
	EndIf;
EndProcedure

&AtServer
Procedure FillInLinesOfBusiness(TSName = "")
	
	ArrayOfCalculationObjects_ = Object.AccountsReceivable.Unload().UnloadColumn("ARAPObject");
	CommonClientServer.SupplementArray(ArrayOfCalculationObjects_, Object.AccountsPayable.Unload().UnloadColumn("ARAPObject"));
	MatchingDirections = Common.ObjectsAttributeValue(ArrayOfCalculationObjects_, "LineOfBusiness");
	
	If TSName = "" Or TSName = Items.AccountsReceivable.Name Then
		For Each Page1 In Object.AccountsReceivable Do
			If ValueIsFilled(Page1.ARAPObject) And Page1.LineOfBusiness <> MatchingDirections[Page1.ARAPObject] Then
				Page1.LineOfBusiness = MatchingDirections[Page1.ARAPObject];
			EndIf;
		EndDo;
	EndIf;
	
	If TSName = "" Or TSName = Items.AccountsPayable.Name Then
		For Each Page1 In Object.AccountsPayable Do
			If ValueIsFilled(Page1.ARAPObject) And Page1.LineOfBusiness <> MatchingDirections[Page1.ARAPObject] Then
				Page1.LineOfBusiness = MatchingDirections[Page1.ARAPObject];
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	Return; // not an empty handler
	
EndProcedure

#EndRegion

#Region FiscalTransaction 

&AtClient
Procedure FiscalOperationNavigationLinkProcessing(Item, Var_URL, StandardProcessing)
	
	If Var_URL = "CounterpartySupplierPunchReceipt" Then
		
		StandardProcessing = False;
		
		ReceiptPrintingCommandName = "CounterpartySupplier";
		NameOfReceiptBreakingCommandWhenChangingOnServer();
		
		CalculationType = PredefinedValue("Enum.CashSettlementTypes.CashOutflow");
		
		GeneratingFiscalChecksClient.DisplayReceipt(
			ThisObject,
			New CallbackDescription("FiscalTransactionCompletion", ThisObject));
		
	ElsIf Var_URL = "CounterpartySupplierOpenFiscalTransactionRecord" Then
		
		StandardProcessing = False;
		
		CalculationType = PredefinedValue("Enum.CashSettlementTypes.CashOutflow");
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(ThisObject, Object.Ref, , CalculationType);
	
	ElsIf Var_URL = "CounterpartyDebtorPunchCheck" Then
		
		StandardProcessing = False;
		
		ReceiptPrintingCommandName = "CounterpartyDebtor";
		NameOfReceiptBreakingCommandWhenChangingOnServer();
		
		CalculationType = PredefinedValue("Enum.CashSettlementTypes.CashReceipt");
		
		GeneratingFiscalChecksClient.DisplayReceipt(
			ThisObject,
			New CallbackDescription("FiscalTransactionCompletion", ThisObject));
		
	ElsIf Var_URL = "CounterpartyDebtorOpenRecordOfFiscalTransaction" Then
		
		StandardProcessing = False;
		
		CalculationType = PredefinedValue("Enum.CashSettlementTypes.CashReceipt");
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(ThisObject, Object.Ref, , CalculationType);
		
	ElsIf Var_URL = "CounterpartyLenderPunchCheck" Then
		
		StandardProcessing = False;
		
		ReceiptPrintingCommandName = "Creditor";
		NameOfReceiptBreakingCommandWhenChangingOnServer();
		
		CalculationType = PredefinedValue("Enum.CashSettlementTypes.Refund");
		
		GeneratingFiscalChecksClient.DisplayReceipt(
			ThisObject,
			New CallbackDescription("FiscalTransactionCompletion", ThisObject));
		
	ElsIf Var_URL = "CounterpartyCreditorOpenRecordOfFiscalTransaction" Then
		
		StandardProcessing = False;
		
		CalculationType = PredefinedValue("Enum.CashSettlementTypes.Refund");
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(ThisObject, Object.Ref, , CalculationType);
		
	ElsIf Var_URL = "CounterpartyGiftCertificatePunchReceipt" Then
		
		StandardProcessing = False;
		
		ReceiptPrintingCommandName = "CounterpartyGiftCertificate";
		NameOfReceiptBreakingCommandWhenChangingOnServer();
		
		CalculationType = PredefinedValue("Enum.CashSettlementTypes.CashReceipt");
		
		GeneratingFiscalChecksClient.DisplayReceipt(
			ThisObject,
			New CallbackDescription("FiscalTransactionCompletion", ThisObject));
		
	ElsIf Var_URL = "CounterpartyGiftCertificateOpenRecordOfFiscalTransaction" Then
		
		StandardProcessing = False;
		
		CalculationType = PredefinedValue("Enum.CashSettlementTypes.CashReceipt");
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(ThisObject, Object.Ref, , CalculationType);
		
	ElsIf Var_URL = "OrganizationPunchReceipt" Then
		
		StandardProcessing = False;
		
		ReceiptPrintingCommandName = "DebtorOrganization_";
		NameOfReceiptBreakingCommandWhenChangingOnServer();
		
		CalculationType = PredefinedValue("Enum.CashSettlementTypes.CashReceipt");
		
		GeneratingFiscalChecksClient.DisplayReceipt(
			ThisObject,
			New CallbackDescription("FiscalTransactionCompletion", ThisObject));
		
	ElsIf Var_URL = "OrganizationOpenFiscalTransactionRecord" Then
		
		StandardProcessing = False;
		
		CalculationType = PredefinedValue("Enum.CashSettlementTypes.CashReceipt");
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(ThisObject, Object.Ref, , CalculationType);
		
	ElsIf Var_URL = "LenderOrganizationPunchCheck" Then
		
		StandardProcessing = False;
		
		ReceiptPrintingCommandName = "CompanyCreditor";
		NameOfReceiptBreakingCommandWhenChangingOnServer();
		
		CalculationType = PredefinedValue("Enum.CashSettlementTypes.Refund");
		
		GeneratingFiscalChecksClient.DisplayReceipt(
			ThisObject,
			New CallbackDescription("FiscalTransactionCompletion", ThisObject));
		
	ElsIf Var_URL = "LenderOrganizationOpenRecordOfFiscalTransaction" Then
		
		StandardProcessing = False;
		
		CalculationType = PredefinedValue("Enum.CashSettlementTypes.Refund");
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(ThisObject, Object.Ref, , CalculationType);
		
	ElsIf Var_URL = "ConfigureHardware_" Then
		
		StandardProcessing = False;
		
		OpenForm("DataProcessor.PreviewReceipt.Form.ErrorOfCREConnection");
		
	EndIf;
	
EndProcedure

&AtServer
Procedure NameOfReceiptBreakingCommandWhenChangingOnServer()
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure FiscalTransactionCompletion(Result, AdditionalParameters) Export
	
	FiscalOperationCompletionOnServer();
	
EndProcedure

&AtServer
Procedure FiscalOperationCompletionOnServer()
	
	GeneratingFiscalChecksServer.UpdateFiscalCheckBreakdownHyperlink(Object.Ref, ThisObject, TextDocumentsBasedOnFooter);
	
EndProcedure

#Region FiscalTransactionLocalization

&AtServer
Procedure AdjustVisibilityOfLocalizedElements()
	
	Items.FooterGroup.Visible = True;
	Items.AccountsReceivablePickUpGiftCertificate.Visible = False;
	Items.AccountsPayablePickUpGiftCertificate.Visible = False;
	Items.AccountsPayableSelectAccountsPayableByAmountDue.Visible = True;
	
	
EndProcedure

#EndRegion

#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ManagementAccountingCurrency     = Constants.ManagementAccountingCurrency.Get();
	CounterpartiesLinkType = New TypeDescription("CatalogRef.Counterparties");
	CompanyLinkType = New TypeDescription("CatalogRef.Companies");
	
	FillInListOfOrganizations();
	SetDebtorType();
	SetLenderType();
	
	Items.GroupComment.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	InitializeDebt("Dr");
	InitializeDebt("Cr");

	UpdateCounterpartySServiceAttributes("Dr");
	UpdateCounterpartySServiceAttributes("Cr");
	
	UpdateServiceAttributesOfTablePart("Dr");
	UpdateServiceAttributesOfTablePart("Cr");
	
	FillInEndClientData();
	
	SwitchPages = True;
	SetPropertiesOfFormElementsByTypeOfOperation(SwitchPages);
	
	RestrictChoiceOfOperationType();
	
EndProcedure

&AtServer
Function PlacePaymentDecryptionInVault(Val ARAPDetails)
	
	VT = ARAPDetails.Unload();
	VT.Columns.Delete("Sum");
	VT.Columns.AmountARAP.Name = "Sum";
	
	AddressOfPaymentsInTheStorage = PutToTempStorage(
		VT,
		UUID);
	
	Return AddressOfPaymentsInTheStorage;
	
EndFunction

&AtServer
Procedure GetAccountsReceivableFromVault(AddressOfPaymentsInTheStorage)

	AccountsReceivable = GetFromTempStorage(AddressOfPaymentsInTheStorage); // ValueTable
	AccountsReceivable.GroupBy("PaymentType_, Partner, ARAPObject, ARAPCurrency, Organization","Sum, AccountsPayableOfCompany, PartnerDebt_");
	AccountsReceivable.Columns.Add("AmountARAP");
	
	For Each DebtLine In AccountsReceivable Do
		DebtLine.AmountARAP = DebtLine.Sum;
	EndDo;
	Object.AccountsReceivable.Load(AccountsReceivable);
	BlockSettlementObjects();
	
EndProcedure

&AtServer
Procedure GetAccountsPayableFromVault(AddressOfPaymentsInTheStorage)

	AccountsPayable = GetFromTempStorage(AddressOfPaymentsInTheStorage); // ValueTable
	AccountsPayable.GroupBy("PaymentType_, Partner, ARAPObject, ARAPCurrency, Organization","Sum, AccountsPayableOfCompany, PartnerDebt_");
	AccountsPayable.Columns.Add("AmountARAP");
	
	For Each DebtLine In AccountsPayable Do
		DebtLine.AmountARAP = DebtLine.Sum;
	EndDo;
	Object.AccountsPayable.Load(AccountsPayable);
	BlockSettlementObjects();
	
EndProcedure

&AtServer
Procedure SetDebtorType()
	
	SettlementsBetweenCompaniesDebtor =
		Object.CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient
		Or Object.CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor;
	
	SettlementsWithCustomersDebtor =
		Object.CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.Client
		Or Object.CounterpartyDebtorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient;
		
	TypeRestriction = ?(SettlementsBetweenCompaniesDebtor, CompanyLinkType, CounterpartiesLinkType);
	
	If Items.CounterpartyDebtor.TypeRestriction <> TypeRestriction Then
		Items.CounterpartyDebtor.TypeRestriction = TypeRestriction;
		Items.CommissionSaleClient.TypeRestriction = TypeRestriction;
	EndIf;
	
	Items.AccountsReceivablePartner.Visible = Not SettlementsBetweenCompaniesDebtor;
	Items.AccountsReceivableWithoutSplitPartner.Visible = Not SettlementsBetweenCompaniesDebtor;
	
	Items.CounterpartyDebtor.ListChoiceMode = SettlementsBetweenCompaniesDebtor;
	If SettlementsBetweenCompaniesDebtor Then
		ArrayOrganization = CompaniesForSelection.UnloadValues();
		Items.CounterpartyDebtor.ChoiceList.LoadValues(ArrayOrganization);
	Else
		Items.CounterpartyDebtor.ChoiceList.Clear();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetLenderType()
	
	SettlementsBetweenCompaniesCreditor =
		Object.CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient
		Or Object.CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.CompanyVendor;
		
	SettlementsWithCustomersCreditor =
		Object.CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.Client
		Or Object.CounterpartyCreditorType = Enums.ARAPSettlemenParticipantTypes.OrganizationClient;
		
	TypeRestriction = ?(SettlementsBetweenCompaniesCreditor, CompanyLinkType, CounterpartiesLinkType);
	
	If Items.Creditor.TypeRestriction <> TypeRestriction Then
		Items.Creditor.TypeRestriction = TypeRestriction;
		Items.Consignee.TypeRestriction = TypeRestriction;
		Items.CustomerCommissionSaleRefund.TypeRestriction = TypeRestriction;
		Items.RefundAgent.TypeRestriction = TypeRestriction;
	EndIf;
	
	Items.AccountsPayablePartner.Visible = Not SettlementsBetweenCompaniesCreditor;
	Items.AccountsPayableWithoutSplittingPartner.Visible = Not SettlementsBetweenCompaniesCreditor;
	
	Items.Creditor.ListChoiceMode = SettlementsBetweenCompaniesCreditor;
	If SettlementsBetweenCompaniesCreditor Then
		ArrayOrganization = CompaniesForSelection.UnloadValues();
		Items.Creditor.ChoiceList.LoadValues(ArrayOrganization);
	Else
		Items.Creditor.ChoiceList.Clear();
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculateNettingAmountsServer(Val OffsetAmount)
	
	Query = New Query("
	|SELECT
	|	*
	|INTO DocumentTable
	|FROM
	|	&SourceDocumentTable AS SourceDocumentTable
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	*,
	|	DocumentTable.ARAPObject.Date AS Date,
	|	DocumentTable.ARAPObject.Number AS Number
	|FROM
	|	DocumentTable AS DocumentTable
	|
	|ORDER BY
	|	Date,
	|	Number
	|");
	
	ArrayOfTabularParts = New Array;
	ArrayOfTabularParts.Add("AccountsReceivable");
	ArrayOfTabularParts.Add("AccountsPayable");
	
	If TypeOfOperationSelectedIsArbitraryOrBarter() Then
		ResourceName = "SumCompl";
	Else
		ResourceName = "AmountARAP";
	EndIf;
	For Each TabularSection In ArrayOfTabularParts Do
		
		DocumentAmount = OffsetAmount;
		
		DocumentTable = Object[TabularSection].Unload(,);
		Query.SetParameter("SourceDocumentTable", DocumentTable);
		
		Object[TabularSection].Clear();
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			Sum = Min(Selection[ResourceName], DocumentAmount);
			If Sum > 0 Then
			
				TableRow = Object[TabularSection].Add();
				FillPropertyValues(TableRow, Selection);
				
				If ManagementAccountingCurrency = LocalAccountingCurrency Then
					TableRow.SumMan = Sum;
				ElsIf Sum = DocumentAmount And Not TableRow[ResourceName] = 0 And Not TableRow.SumMan = 0 Then
					TableRow.SumMan = Sum / (TableRow[ResourceName] / TableRow.SumMan);
				EndIf;
				
				If Sum = DocumentAmount Then
					
					ARAPAccountingServer.WriteOffAmountProportionally(
						TableRow.AmountARAP,
						TableRow[ResourceName] - Sum,
						TableRow[ResourceName]);
						
				EndIf;
				
				TableRow[ResourceName] = Sum;
				DocumentAmount = DocumentAmount - TableRow[ResourceName];
				
			EndIf;
			
		EndDo;
	EndDo;
	
	AmountOfManOffsettingDr = Object.AccountsReceivable.Total("SumMan");
	AmountOfManOffsettingCr = Object.AccountsPayable.Total("SumMan");
	AmountOfManOffsetting = Min(AmountOfManOffsettingDr,AmountOfManOffsettingCr);
	If AmountOfManOffsettingDr <> AmountOfManOffsettingCr Then
		
		For Each TabularSection In ArrayOfTabularParts Do
			
			DocumentAmount = AmountOfManOffsetting;
			
			DocumentTable = Object[TabularSection].Unload(,);
			Query.SetParameter("SourceDocumentTable", DocumentTable);
			
			Object[TabularSection].Clear();
			
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				
				SumMan = Min(Selection.SumMan, DocumentAmount);
				If SumMan > 0 Then
				
					TableRow = Object[TabularSection].Add();
					FillPropertyValues(TableRow, Selection);
					
					If TableRow.ARAPCurrency <> ManagementAccountingCurrency Then
						TableRow.SumMan = SumMan;
					Else
						TableRow.SumMan = TableRow.AmountARAP;
					EndIf;
					DocumentAmount = DocumentAmount - TableRow.SumMan;
				Else
					TableRow = Object[TabularSection].Add();
					FillPropertyValues(TableRow, Selection);
					
					TableRow.SumMan = 0;
				EndIf;
				
			EndDo;
		EndDo;
	EndIf;
	
	If TypeOfOperationSelectedIsArbitraryOrBarter() Then
		PreRollManLocalAmounts("SumCompl", Query, ArrayOfTabularParts);
		PreRollManLocalAmounts("SumMan", Query, ArrayOfTabularParts);
		
		Object.SumMan  = Object.AccountsReceivable.Total("SumMan");
		Object.SumCompl = Object.AccountsReceivable.Total("SumCompl");
	Else
		Object.DocumentAmount = OffsetAmount;
	EndIf;
	Object.SumMan  = AmountOfManOffsetting;
	
EndProcedure

&AtServer
Procedure PreRollManLocalAmounts(ResourceName,Query,ArrayOfTabularParts)

	AmountOfOffsettingInAccountingCurrencyDr = Object.AccountsReceivable.Total(ResourceName);
	AmountOfOffsettingInAccountingCurrencyCr = Object.AccountsPayable.Total(ResourceName);
	AmountOfOffsettingInAccountingCurrency = Min(AmountOfOffsettingInAccountingCurrencyDr,AmountOfOffsettingInAccountingCurrencyCr);
	If AmountOfOffsettingInAccountingCurrencyDr <> AmountOfOffsettingInAccountingCurrencyCr Then
		
		For Each TabularSection In ArrayOfTabularParts Do
			
			DocumentAmount = AmountOfOffsettingInAccountingCurrency;
			
			DocumentTable = Object[TabularSection].Unload(,);
			Query.SetParameter("SourceDocumentTable", DocumentTable);
			
			Object[TabularSection].Clear();
			
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				
				AmountInAccountingCurrency = Min(Selection[ResourceName], DocumentAmount);
				If AmountInAccountingCurrency > 0 Then
				
					TableRow = Object[TabularSection].Add();
					FillPropertyValues(TableRow, Selection);
					
					If TableRow.ARAPCurrency = LocalAccountingCurrency Then
						TableRow[ResourceName] = TableRow.AmountARAP;
					Else
						TableRow[ResourceName] = AmountInAccountingCurrency;
					EndIf;
					DocumentAmount = DocumentAmount - TableRow[ResourceName];
				Else
					TableRow = Object[TabularSection].Add();
					FillPropertyValues(TableRow, Selection);
					
					TableRow[ResourceName] = 0;
				EndIf;
				
			EndDo;
		EndDo;
	EndIf;
		
EndProcedure

&AtClient
Procedure CalculateNettingAmounts(Val TheAmountOfTheDocumentRegl = 0)
	
	AccountsReceivableType  = Object.AccountsReceivable.Total("SumCompl");
	AccountsPayableType = Object.AccountsPayable.Total("SumCompl");
	If TheAmountOfTheDocumentRegl <> 0 Then
		OffsetAmount = Min(AccountsReceivableType, AccountsPayableType, TheAmountOfTheDocumentRegl);
	Else
		OffsetAmount = Min(AccountsReceivableType, AccountsPayableType);
	EndIf;
	
	If OffsetAmount = 0 Then
		Object.AccountsReceivable.Clear();
		Object.AccountsPayable.Clear();
		InitializeDebtOnServer();
		Return;
	EndIf;
	
	AdditionalParameters = New Structure("OffsetAmount", OffsetAmount);
	Notification = New CallbackDescription("CalculateNettingAmountsCompletion", ThisObject, AdditionalParameters);
	
	If OffsetAmount < TheAmountOfTheDocumentRegl Then
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Khấu trừ có thể bằng số tiền %1 %2, điều chỉnh số tiền?';
				|ru = 'Взаимозачет возможен на сумму %1 %2, скорректировать сумму?';
				|en = 'The amount of %1 %2 can be offset. Do you want to correct the amount?'; fa = 'The amount of %1 %2 can be offset. Do you want to correct the amount?';
				|it = 'La compensazione è possibile per l''importo %1 %2, rettificare l''importo?';
				|pl = 'Kompensata jest możliwa o wartości%1 %2, Skorygować wartość?';
				|tr = '%1 %2 tutarı için uzlaşma mümkün, tutar düzeltilsin mi?'"),
			OffsetAmount,
			LocalAccountingCurrency);
		ResponseCode = Undefined;
		
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
		
	Else
		RunCallback(Notification, DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateNettingAmountsCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CalculateAmountOfOffsetFragment(AdditionalParameters.OffsetAmount);
	Else
		InitializeDebtOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateAmountOfOffsetFragment(Val OffsetAmount)
	
	CalculateNettingAmountsServer(OffsetAmount);
	
	InitializeDebtOnServer();
	
	Text = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã tính giá trị đối trừ với số tiền là %1';
			|ru = 'Рассчитан взаимозачет на сумму %1';
			|en = 'Offsetting is calculated in the amount of %1'; fa = 'Offsetting is calculated in the amount of %1';
			|it = 'La compensazione calcolata per l''importo %1';
			|pl = 'Jest rozliczona kompensata o wartości %1';
			|tr = '%1 tutarı için hesaplanan uzlaşma'"), 
		OffsetAmount);
	ShowUserNotification(NStr("vi = 'Đã tính giá trị đối trừ';
								|ru = 'Рассчитан взаимозачет';
								|en = 'Offsetting is calculated'; fa = 'Offsetting is calculated';
								|it = 'La compensazione calcolata';
								|pl = 'Rozliczono kompensatę';
								|tr = 'Uzlaşma hesaplandı'"),, Text, PictureLib.Information32);
	
EndProcedure

&AtServer
Procedure InitializeDebtOnServer()
	
	InitializeDebt("Dr");
	InitializeDebt("Cr");
	SetPropertiesOfFormElementsByTypeOfOperation();
	
EndProcedure

&AtClient
Procedure OpenFormForSelectingCalculationObjects(Item, FilterValues, MoreSelectionSettings = Undefined)
	
	Try
		LockFormDataForEdit();
	Except
		ShowMessageBox(Undefined, BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	Sum = Object.AccountsReceivable.Total("SumCompl");
		
	SelectionSettings_ = New Structure;
	SelectionSettings_.Insert("SelectingThePaymentBasis", False);
	SelectionSettings_.Insert("EditableDocument", Object.Ref);
	SelectionSettings_.Insert("Currency", LocalAccountingCurrency);
	SelectionSettings_.Insert("Sum", Sum);
	SelectionSettings_.Insert("RecordBranches", True);
	SelectionSettings_.Insert("Filter", FilterValues);
	SelectionSettings_.Insert("ReturnStructure", True);
	If MoreSelectionSettings <> Undefined Then
		For Each Setting In MoreSelectionSettings Do
			SelectionSettings_.Insert(Setting.Key, Setting.Value);
		EndDo;
	EndIf;
	ClearSettlementCurrency();//we will clear the currency of mutual settlements if the document does not specify other settlement objects
	If ValueIsFilled(ARAPCurrency)
			And Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent")
			And Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent") Then
		SelectionSettings_.Filter.Insert("ARAPCurrency", ARAPCurrency);
		SelectionSettings_.Delete("Currency");
	EndIf;
	
	OpenForm("Catalog.ARAPObjects.ChoiceForm", SelectionSettings_, Item);
	
EndProcedure

&AtClient
Procedure ItIsNecessaryToPurifyTS(CallbackDescription, ThereAreLines)
	
	If ThereAreLines Then
		
		QueryText = NStr("vi = 'Số tiền hạch toán công nợ có thể sẽ không thiết thực.
		                        |Xóa danh sách công nợ?';
		                        |ru = 'Суммы взаимозачета могут стать неактуальными.
		                        |Очистить списки задолженностей?';
		                        |en = 'Offsetting amounts can become irrelevant.
		                        |Clear debt lists?'; fa = 'Offsetting amounts can become irrelevant.
		                        |Clear debt lists?';
		                        |it = 'Суммы взаимозачета могут стать неактуальными.
		                        |Очистить списки задолженностей?';
		                        |pl = 'Offsetting amounts can become irrelevant.
		                        |Clear debt lists?';
		                        |tr = 'Uzlaşma tutarları güncelliğini kaybedebilir.
		                        |Borç listeleri temizlensin mi?'");
		ShowQueryBox(
			CallbackDescription,
			QueryText,
			QuestionDialogMode.YesNo);
		
	Else
		
		RunCallback(CallbackDescription, DialogReturnCode.Yes);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInListOfOrganizations()
	
	Query = New Query(
	"SELECT ALLOWED
	|	Companies.Ref AS Ref
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	NOT Companies.DeletionMark
	|	AND Companies.Ref <> &ThisOrganization_
	|	AND Companies.ParentCompany <> &ThisOrganization_
	|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|	AND (Companies.Predefined = &UseMan
	|			OR NOT Companies.Predefined)
	|	AND (Companies.Ref NOT IN (
	|		SELECT
	|			Companies.ParentCompany AS Ref
	|		FROM
	|			Catalog.Companies AS Companies
	|		WHERE
	|			Companies.Ref = &ThisOrganization_)
	|		OR &OperationKind NOT IN (VALUE(Enum.KindsOfARAPSettlements.Barter),
	|								VALUE(Enum.KindsOfARAPSettlements.Arbitrary)))
	|");
	
	Query.SetParameter("ThisOrganization_", Object.Organization);
	Query.SetParameter("UseMan", GetFunctionalOption("UseManagementCompany"));
	Query.SetParameter("OperationKind", Object.OperationKind);
	
	CompanyArray = Query.Execute().Unload().UnloadColumn("Ref");
	CompaniesForSelection.LoadValues(CompanyArray);
	
	If SelectedTypeOfOperationBetweenOrganizations(Object.OperationKind) Then
		Items.CompanyCreditor.ChoiceList.LoadValues(CompanyArray);
	EndIf;
	
	If SettlementsBetweenCompaniesDebtor Then
		Items.CounterpartyDebtor.ChoiceList.LoadValues(CompanyArray);
	EndIf;
	
	If SettlementsBetweenCompaniesCreditor Then
		Items.Creditor.ChoiceList.LoadValues(CompanyArray);
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function StructureOfDebtParameters(Form, TheseAreAccountsPayable = False)
	
	Object = Form.Object;
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("RecordBranches", True);
	
	OperationsException = Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany");
	
	If TheseAreAccountsPayable And SelectedTypeOfOperationBetweenOrganizations(Object.OperationKind) And Not OperationsException
		Or (Not TheseAreAccountsPayable And SelectedTypeOfOperationBetweenOrganizations(Object.OperationKind) And OperationsException) Then
		AttributeName = "CompanyCreditor";
		ParametersStructure.RecordBranches = False;
	Else
		AttributeName = "Organization";
	EndIf;
	
	ValueStructure = New Structure(
		"AttributeName, Value, Presentation",
		AttributeName,
		Object[AttributeName],
		Form.PresentationsStructure[AttributeName]);
		
	ParametersStructure.Insert("Organization", ValueStructure);
	
	If TheseAreAccountsPayable And SelectedTypeOfOperationBetweenCounterparties(Object.OperationKind) Then
		AttributeName = "Creditor";
	Else
		AttributeName = "CounterpartyDebtor";
	EndIf;
	
	ValueStructure = New Structure(
		"AttributeName, Value, Presentation",
		AttributeName,
		Object[AttributeName],
		Form.PresentationsStructure[AttributeName]);
		
	ParametersStructure.Insert("Counterparty", ValueStructure);
	
	If (Form.SettlementsWithCustomersDebtor And Not TheseAreAccountsPayable)
	 Or (Form.SettlementsWithCustomersCreditor And TheseAreAccountsPayable) Then
		ParametersStructure.Insert("PaymentType_", 
			PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting"));
	Else
		ParametersStructure.Insert("PaymentType_", 
			PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting"));
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Function TypeOfOperationWithSupplierIsSelected()
	
	Return Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies
		
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies;
	
EndFunction

&AtServer
Function TypeOfOperationWithClientIsSelected()
	
	Return Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies
		
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.AccountsReceivableOffsetBetweenTwoCompanies
		
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.PaymentByGiftCard
		
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent;
		
EndFunction

&AtServer
Function TypeOfOperationWithinSameCounterpartyHasBeenSelected()
	
	Return Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.Barter
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany
		
EndFunction

&AtServer
Function TypeOfOperationSelectedIsArbitraryOrBarter()
	
	Return Object.OperationKind = Enums.KindsOfARAPSettlements.Arbitrary
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.Barter
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.ARAPClearingBetweenCompanies;
		
EndFunction

&AtServer
Function SelectedTypeOfOperationAdvanceTransfer()
	
	Return Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies
		
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies
		
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.PaymentByGiftCard;
		
EndFunction
	
&AtServer
Function SelectedTypeOfOperationDebtTransfer()
	
	Return Object.OperationKind = Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.AccountsReceivableOffsetBetweenTwoCompanies
		
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany
		Or Object.OperationKind = Enums.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies;
		
EndFunction

&AtClientAtServerNoContext
Function SelectedTypeOfOperationBetweenOrganizations(OperationKind)
	
	Return OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany")
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany")
	
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany")
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany");
		
EndFunction

&AtClientAtServerNoContext
Function TypeOfOperationBetweenTwoCompaniesHasBeenSelected(OperationKind)
	
	Return OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies")
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.AccountsReceivableOffsetBetweenTwoCompanies")
	
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies")
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies")
		
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.ARAPClearingBetweenCompanies");
		
EndFunction

&AtClientAtServerNoContext
Function SelectedTypeOfOperationBetweenCounterparties(OperationKind)
	
	Return Not ValueIsFilled(OperationKind)
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties")
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.PaymentByGiftCard")
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties")
		
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.Arbitrary")
		
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties")
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties")
		
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent")
		Or OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent");
		
EndFunction

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

&AtServer
Function ThereAreTasksForDistribution(DebtParametersDebtor = Undefined, DebtParametersCreditor = Undefined)
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	DimensionByPartners.DimensionKey AS DimensionKey
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		INNER JOIN InformationRegister.JobsForAllocatingCustomersARAP AS Jobs
	|			ON Jobs.AccountingDimensionByPartners = DimensionByPartners.DimensionKey
	|WHERE
	|	(&FilterClientDr
	|	OR
	|	&FilterClientCr)
	|	AND Jobs.Month <= &CurrentMonth
	|
	|UNION
	|
	|SELECT DISTINCT
	|	DimensionByPartners.DimensionKey AS DimensionKey
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		INNER JOIN InformationRegister.JobsForAllocatingVendorsARAP AS Jobs
	|			ON Jobs.AccountingDimensionByPartners = DimensionByPartners.DimensionKey
	|WHERE
	|	(&FilterVendorDr
	|	OR
	|	&FilterVendorCr)
	|	AND Jobs.Month <= &CurrentMonth";
	
	FilterDr = ?(Not ValueIsFilled(DebtParametersDebtor),"FALSE","(DimensionByPartners.Organization IN (&OrganizationDr)
	|		AND DimensionByPartners.Counterparty = &CounterpartyDr
	|		AND &PaymentType_Dr = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting))");
	
	FilterCr = ?(Not ValueIsFilled(DebtParametersCreditor),"FALSE","(DimensionByPartners.Organization IN (&OrganizationCr)
	|		AND DimensionByPartners.Counterparty = &CounterpartyCr
	|		AND &PaymentType_Cr = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting))");
	
	Query.Text = StrReplace(Query.Text, "&FilterClientDr", FilterDr);
	Query.Text = StrReplace(Query.Text, "&FilterClientCr", FilterCr);
	
	FilterDr = StrReplace(FilterDr, ".CustomerARAPAccounting)", ".VendorARAPAccounting)");
	FilterCr = StrReplace(FilterCr, ".CustomerARAPAccounting)", ".VendorARAPAccounting)");
	
	Query.Text = StrReplace(Query.Text, "&FilterVendorDr", FilterDr);
	Query.Text = StrReplace(Query.Text, "&FilterVendorCr", FilterCr);
	
	If ValueIsFilled(DebtParametersDebtor) Then
		Query.SetParameter("OrganizationDr", OrganizationsToCalculate_(DebtParametersDebtor));
		Query.SetParameter("CounterpartyDr",  DebtParametersDebtor.Counterparty.Value);
		Query.SetParameter("PaymentType_Dr", DebtParametersDebtor.PaymentType_);
	EndIf;
	
	If ValueIsFilled(DebtParametersCreditor) Then
		Query.SetParameter("OrganizationCr", OrganizationsToCalculate_(,DebtParametersCreditor));
		Query.SetParameter("CounterpartyCr",  DebtParametersCreditor.Counterparty.Value);
		Query.SetParameter("PaymentType_Cr", DebtParametersCreditor.PaymentType_);
	EndIf;
	
	Query.SetParameter("CurrentMonth",  BegOfMonth(Object.Date));
	
	Return Query.Execute().Unload().UnloadColumn("DimensionKey");
	
EndFunction

&AtServer
Procedure FillInManLocalAmounts(ParametersStructure_, ThisIsLoan)
	
	If ThisIsLoan Then
		TabularSection = Object.AccountsPayable;
	Else
		TabularSection = Object.AccountsReceivable;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("ARAPObject, Partner");
	
	ArrayOfCalculationObjects_ = New Array;
	
	For Each TSRow In TabularSection Do
		If ArrayOfCalculationObjects_.Find(TSRow.ARAPObject) = Undefined
			And TSRow.AmountARAP <> 0 Then
			ArrayOfCalculationObjects_.Add(TSRow.ARAPObject);
		EndIf;
	EndDo;
	
	OutstandingBalances = BalancesOfDebtOnSettlementObjects(ParametersStructure_, ArrayOfCalculationObjects_);
	OutstandingBalances.Indexes.Add("ARAPObject, Partner");
	
	For Each TSRow  In TabularSection Do
		If TSRow.AmountARAP <> 0 Then
			TheStructureOfTheSearch.ARAPObject = TSRow.ARAPObject;
			TheStructureOfTheSearch.Partner = TSRow.Partner;
			
			RemainderLines_ = OutstandingBalances.FindRows(TheStructureOfTheSearch);
			If RemainderLines_.Count() = 0 Then
				Continue;
			EndIf;
			
			If RemainderLines_[0].AmountARAP > 0 Then
				TSRow.SumMan = RemainderLines_[0].SumMan * (TSRow.AmountARAP / RemainderLines_[0].AmountARAP);
				TSRow.SumCompl = RemainderLines_[0].SumCompl * (TSRow.AmountARAP / RemainderLines_[0].AmountARAP);
			EndIf;
			
		EndIf;
	EndDo;
	
	Object.SumCompl = Object.AccountsReceivable.Total("SumCompl");
	Object.SumMan  = Object.AccountsReceivable.Total("SumMan");
	
EndProcedure

&AtServer
Function BalancesOfDebtOnSettlementObjects(AnalyticsParameters, ArrayOfCalculationObjects_)
	
	RequestOrganizations = New Query("SELECT ALLOWED
	|	Companies.Ref
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.ParentCompany IN (&Organization)
	|	AND Companies.TransactionsUsingParentCompanyAreAllowed");
	If AnalyticsParameters.RecordBranches Then
		RequestOrganizations.SetParameter("Organization", AnalyticsParameters.Organization.Value);
		AvailableCompanies = RequestOrganizations.Execute().Unload().UnloadColumn("Ref");
		AvailableCompanies.Add(AnalyticsParameters.Organization.Value);
		Organization = AvailableCompanies;
	Else
		Organization = AnalyticsParameters.Organization.Value;
	EndIf;
	
	TextTTAnalytics = "
		|SELECT
		|	RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
		|	RegisterAccountingAnalyticsForPartners.Partner AS Partner
		|INTO TTAnalytics_
		|FROM
		|	InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
		|WHERE
		|	RegisterAccountingAnalyticsForPartners.Organization IN (&Organization)
		|	AND RegisterAccountingAnalyticsForPartners.Counterparty = &Counterparty
		|INDEX BY
		|	AccountingDimensionByPartners
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|";
	
	If Not NewOnlineARAPAccounting Then
		
		TextSettlementsWithClients = "
		|SELECT
		|	Dimension.Partner AS Partner,
		|	Balance.SalesOrder AS ARAPObject,
		|	CASE
		|		WHEN Balance.DebtBalance + Balance.PrepaymentBalance < 0 
		|			THEN -(Balance.DebtBalance + Balance.PrepaymentBalance)
		|		ELSE Balance.DebtBalance + Balance.PrepaymentBalance
		|	END AS AmountARAP,
		|	CASE
		|		WHEN Balance.DebtLocalBalance + Balance.PrepaymentLocalBalance < 0 
		|			THEN -(Balance.DebtLocalBalance + Balance.PrepaymentLocalBalance)
		|		ELSE Balance.DebtLocalBalance + Balance.PrepaymentLocalBalance
		|	END AS SumCompl,
		|	CASE
		|		WHEN Balance.ARAPManBalance + Balance.PrepaymentManBalance < 0 
		|			THEN -(Balance.ARAPManBalance + Balance.PrepaymentManBalance)
		|		ELSE Balance.ARAPManBalance + Balance.PrepaymentManBalance
		|	END AS SumMan
		|FROM AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(&Boundary, SalesOrder IN (&ArrayOfCalculationObjects_) AND AccountingDimensionByPartners IN (
		|																SELECT Dimension.AccountingDimensionByPartners
		|																FROM TTAnalytics_ AS Dimension)) AS Balance
		|		LEFT JOIN TTAnalytics_ AS Dimension
		|			ON Dimension.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
		|";
		
		TextCalculationsWithErrors = "
		|SELECT
		|	Dimension.Partner       AS Partner,
		|	Balance.PurchaseOrder AS ARAPObject,
		|	CASE
		|		WHEN Balance.DebtBalance + Balance.PrepaymentBalance < 0 
		|			THEN -(Balance.DebtBalance + Balance.PrepaymentBalance)
		|		ELSE Balance.DebtBalance + Balance.PrepaymentBalance
		|	END AS AmountARAP,
		|	CASE
		|		WHEN Balance.DebtLocalBalance + Balance.PrepaymentLocalBalance < 0 
		|			THEN -(Balance.DebtLocalBalance + Balance.PrepaymentLocalBalance)
		|		ELSE Balance.DebtLocalBalance + Balance.PrepaymentLocalBalance
		|	END AS SumCompl,
		|	CASE
		|		WHEN Balance.ARAPManBalance + Balance.PrepaymentManBalance < 0 
		|			THEN -(Balance.ARAPManBalance + Balance.PrepaymentManBalance)
		|		ELSE Balance.ARAPManBalance + Balance.PrepaymentManBalance
		|	END AS SumMan
		|FROM AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(&Boundary, PurchaseOrder IN (&ArrayOfCalculationObjects_) AND AccountingDimensionByPartners IN (
		|																SELECT Dimension.AccountingDimensionByPartners
		|																FROM TTAnalytics_ AS Dimension)) AS Balance
		|		LEFT JOIN TTAnalytics_ AS Dimension
		|			ON Dimension.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
		|";
		
		If Not ValueIsFilled(AnalyticsParameters.PaymentType_) Then
			
			QueryText = TextTTAnalytics + TextSettlementsWithClients + "
			|
			|UNION ALL
			|
			|" + TextCalculationsWithErrors;
			
		ElsIf AnalyticsParameters.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
			QueryText = TextTTAnalytics + TextSettlementsWithClients;
		Else
			QueryText = TextTTAnalytics + TextCalculationsWithErrors;
		EndIf;
		
		Query = New Query(QueryText);
		
		PointInTime = EndOfDay(Object.Date);
		Boundary = New Boundary(PointInTime, BoundaryType.Including);
		
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("Counterparty", AnalyticsParameters.Counterparty.Value);
		Query.SetParameter("Boundary", Boundary);
		Query.SetParameter("ArrayOfCalculationObjects_", ArrayOfCalculationObjects_);
		
	Else
		
		TextSettlementsWithClients = "
		|SELECT
		|	Dimension.Partner                                       AS Partner,
		|	Balance.ARAPObject                                  AS ARAPObject,
		|	Balance.DebtBalance + Balance.PrepaymentBalance         AS AmountARAP,
		|	Balance.DebtLocalBalance + Balance.PrepaymentLocalBalance AS SumCompl,
		|	Balance.ARAPManBalance + Balance.PrepaymentManBalance   AS SumMan
		|FROM AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&Boundary, ARAPObject IN (&ArrayOfCalculationObjects_) AND AccountingDimensionByPartners IN (
		|																SELECT Dimension.AccountingDimensionByPartners
		|																FROM TTAnalytics_ AS Dimension)) AS Balance
		|		LEFT JOIN TTAnalytics_ AS Dimension
		|			ON Dimension.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
		|";
		
		TextCalculationsWithErrors = "
		|SELECT
		|	Dimension.Partner                                       AS Partner,
		|	Balance.ARAPObject                                  AS ARAPObject,
		|	Balance.DebtBalance + Balance.PrepaymentBalance         AS AmountARAP,
		|	Balance.DebtLocalBalance + Balance.PrepaymentLocalBalance AS SumCompl,
		|	Balance.ARAPManBalance + Balance.PrepaymentManBalance   AS SumMan
		|FROM AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(&Boundary, ARAPObject IN (&ArrayOfCalculationObjects_) AND AccountingDimensionByPartners IN (
		|																SELECT Dimension.AccountingDimensionByPartners
		|																FROM TTAnalytics_ AS Dimension)) AS Balance
		|		LEFT JOIN TTAnalytics_ AS Dimension
		|			ON Dimension.AccountingDimensionByPartners = Balance.AccountingDimensionByPartners
		|";
		
		Query = New Query;
		PointInTime = EndOfDay(Object.Date);
		Boundary = New Boundary(PointInTime, BoundaryType.Including);
		
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("Counterparty", AnalyticsParameters.Counterparty.Value);
		Query.SetParameter("Boundary", Boundary);
		Query.SetParameter("ArrayOfCalculationObjects_", ArrayOfCalculationObjects_);
		
		If Not ValueIsFilled(AnalyticsParameters.PaymentType_) Then
			QueryText = TextTTAnalytics + TextSettlementsWithClients + "
			|
			|UNION ALL
			|
			|" + TextCalculationsWithErrors;
		ElsIf AnalyticsParameters.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting Then
			QueryText = TextTTAnalytics + TextSettlementsWithClients;
		Else
			QueryText = TextTTAnalytics + TextCalculationsWithErrors;
		EndIf;
		
		Query.Text = QueryText;
		
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

&AtClient
Procedure RecalculateLocalManAmounts(CallbackDescription)
	
	QueryText = NStr("vi = 'Số tiền kế toán pháp quy và quản trị cho các dòng trong phần bảng không bằng số tiền Chứng từ, tính lại số tiền của Chứng từ?';
					|ru = 'Суммы регламентированного и управленческого учёта по строкам в табличной части не равны суммам документам, пересчитать суммы документа?';
					|en = 'Local accounting and management accounting sums in the table rows do not match the document amount. Recalculate the document amount?'; fa = 'Local accounting and management accounting sums in the table rows do not match the document amount. Recalculate the document amount?';
					|it = 'Gli importi della contabilità regolamentare e quella gestionale nelle righe della parte tabulare non sono uguali agli importi dei documenti, ricalcolare gli importi del documento?';
					|pl = 'Wartości ewidencji reglamentowanej i zarządczej według wierszy w części tabelarycznej nie równają się dokumentom, przeliczyć wartości dokumentu?';
					|tr = 'Tablo bölümündeki satırlar için yerel ve yönetim muhasebesi tutarları, belge tutarlarına eşit değil, belge tutarları yeniden hesaplansın mı?'");
	
	AddlParameters = New Structure;
	AddlParameters.Insert("Form", ThisForm);
	AddlParameters.Insert("CallbackDescription", CallbackDescription);
	
	CallbackDescription = New CallbackDescription("RecalculateAmountsOfPaymentDecryptionDocumentEnd",ThisObject, AddlParameters);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure RecalculateAmountsOfPaymentDecryptionDocumentEnd(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = DialogReturnCode.Yes Then
		Object.SumCompl = Object.AccountsReceivable.Total("SumCompl");
		Object.SumMan = Object.AccountsReceivable.Total("SumMan");
		RunCallback(AdditionalParameters.CallbackDescription, True);
	Else
		RunCallback(AdditionalParameters.CallbackDescription, False);
	EndIf;
	
EndProcedure

&AtServer
Function StateOfSettlementBackgroundTask()
	Filter = New Structure();
	Filter.Insert("Key", ARAPAllocationServerCall.NameOfCustomerSettlementBackgroundJob()+Key);
	TasksForSettlementsWithClients = BackgroundJobs.GetBackgroundJobs(Filter);
	
	Filter = New Structure();
	Filter.Insert("Key", ARAPAllocationServerCall.NameOfBackgroundTaskForSettlementsWithSuppliers()+Key);
	TasksForSettlementsWithSuppliers = BackgroundJobs.GetBackgroundJobs(Filter);
	
	If TasksForSettlementsWithClients.Count() = 0 And TasksForSettlementsWithSuppliers.Count() = 0 Then
		Return Undefined;
	Else
		If TasksForSettlementsWithClients.Count() > 0 And TasksForSettlementsWithClients[0].State = BackgroundJobState.Failed Then
				Return "Error";
		ElsIf TasksForSettlementsWithClients.Count() > 0 And TasksForSettlementsWithClients[0].State = BackgroundJobState.Active Then
			ClientCompleted = False;
		Else
			ClientCompleted = True;
		EndIf;
		
		If TasksForSettlementsWithSuppliers.Count() > 0 And TasksForSettlementsWithSuppliers[0].State = BackgroundJobState.Failed Then
			Return "Error";
		ElsIf TasksForSettlementsWithSuppliers.Count() > 0 And TasksForSettlementsWithSuppliers[0].State = BackgroundJobState.Active Then
			SupplierCompleted = False;
		Else
			SupplierCompleted = True;
		EndIf;
	EndIf;
		
	If Not ClientCompleted Or Not SupplierCompleted Then
		Return "Active";
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtClient
Procedure BackgroundJobCheckOnClient()
	
	State = StateOfSettlementBackgroundTask();
	
	If State = Undefined Then
		
		If PopulatedTS = "AccountsReceivable" Then
			DebtParametersDebtor  = StructureOfDebtParameters(ThisForm);
			DimensionToCalculation = ThereAreTasksForDistribution(DebtParametersDebtor);
			DistributeSettlementsWithCustomers = 
				DebtParametersDebtor.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting");
			DistributeSettlementsWithSupplier =
				DebtParametersDebtor.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting");
		ElsIf PopulatedTS = "AccountsPayable" Then
			DebtParametersCreditor = StructureOfDebtParameters(ThisForm, True);
			DimensionToCalculation = ThereAreTasksForDistribution(,DebtParametersCreditor);
			DistributeSettlementsWithCustomers = 
				DebtParametersCreditor.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting");
			DistributeSettlementsWithSupplier =
				DebtParametersCreditor.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting");
		Else
			DebtParametersDebtor  = StructureOfDebtParameters(ThisForm);
			DebtParametersCreditor = StructureOfDebtParameters(ThisForm, True);
			DimensionToCalculation = ThereAreTasksForDistribution(DebtParametersDebtor, DebtParametersCreditor);
			DistributeSettlementsWithCustomers = 
				DebtParametersDebtor.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting")
				Or DebtParametersCreditor.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting");
			DistributeSettlementsWithSupplier =
				DebtParametersDebtor.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting")
				Or DebtParametersCreditor.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.VendorARAPAccounting");
		EndIf;
		
		SettlementsAreAllocated = DimensionToCalculation.Count() = 0;
		
		If Not SettlementsAreAllocated Then
			
			Key = New UUID();
			StructureOfCalculations = New Structure("AccountingAnalyticsForPartners, Companies", DimensionToCalculation, Undefined);
			
			If TimeConsumingOperationForm = Undefined Then
				TimeConsumingOperationForm = TimeConsumingOperationsClient.OpenTimeConsumingOperationForm(ThisObject, UUID); // ClientApplicationForm
				TimeConsumingOperationsClient.InitIdleHandlerParameters(IdleParameters);
				Item = TimeConsumingOperationForm.Items.TimeConsumingOperationNoteTextDecoration; // FormField
				Item.Title = NStr("vi = 'Xin vui lòng đợi...';
									|ru = 'Пожалуйста, подождите...';
									|en = 'Please wait...'; fa = 'لطفاً صبر کنید...';
									|it = 'Attendere prego...';
									|pl = 'Proszę czekać...';
									|tr = 'Lütfen bekleyin...'")+Chars.LF+
					NStr("vi = 'Phân bổ thanh toán theo các chứng từ được thực hiện.';
						|ru = 'Выполняется распределение расчетов по документам.';
						|en = 'Allocating settlements by documents...'; fa = 'Allocating settlements by documents...';
						|it = 'È in corso la ripartizione dei calcoli sui documenti.';
						|pl = 'Jest wykonywany podział rozliczeń według dokumentów.';
						|tr = 'Hesaplamaların belgeler üzerinde dağıtımını gerçekleştirir.'");
			Else
				TimeConsumingOperationsClient.UpdateIdleHandlerParameters(IdleParameters);
			EndIf;
			
			If DistributeSettlementsWithCustomers Then
				ARAPAllocationServerCall.DistributeCalculationsByBackgroundJob(,StructureOfCalculations,"CustomersARAPAccounting",
					ARAPAllocationServerCall.NameOfCustomerSettlementBackgroundJob()+String(Key));
			EndIf;
			
			If DistributeSettlementsWithSupplier Then
				ARAPAllocationServerCall.DistributeCalculationsByBackgroundJob(,StructureOfCalculations,"VendorsARAPAccounting",
					ARAPAllocationServerCall.NameOfBackgroundTaskForSettlementsWithSuppliers()+String(Key));
			EndIf;
			
			AttachIdleHandler("BackgroundJobCheckOnClient", 0.1, True);
		Else
			
			Key = Undefined;
			
			If TimeConsumingOperationForm <> Undefined Then
				TimeConsumingOperationsClient.CloseTimeConsumingOperationForm(TimeConsumingOperationForm);
			EndIf;
			
			AdditionalParameters = New Structure();
			If PopulatedTS = "AccountsReceivable" Then
				AutoTestToCalculateTheOffsetCompletion(Undefined,AdditionalParameters);
				BlockSettlementObjects();
			ElsIf PopulatedTS = "AccountsPayable" Then
				AutoTestToCalculateTheOffsetCompletion(Undefined,AdditionalParameters);
				BlockSettlementObjects();
			Else
				AutoTestToCalculateTheOffsetCompletion(Undefined,Undefined);
			EndIf;
			
		EndIf;
		
	ElsIf State = "Active" Then
		
		If TimeConsumingOperationForm = Undefined Then
			TimeConsumingOperationForm = TimeConsumingOperationsClient.OpenTimeConsumingOperationForm(ThisObject, UUID); // ClientApplicationForm
			TimeConsumingOperationsClient.InitIdleHandlerParameters(IdleParameters);
			Item = TimeConsumingOperationForm.Items.TimeConsumingOperationNoteTextDecoration; // FormField
			Item.Title = NStr("vi = 'Xin vui lòng đợi...';
								|ru = 'Пожалуйста, подождите...';
								|en = 'Please wait...'; fa = 'لطفاً صبر کنید...';
								|it = 'Attendere prego...';
								|pl = 'Proszę czekać...';
								|tr = 'Lütfen bekleyin...'")+Chars.LF+
				NStr("vi = 'Phân bổ thanh toán theo các chứng từ được thực hiện.';
					|ru = 'Выполняется распределение расчетов по документам.';
					|en = 'Allocating settlements by documents...'; fa = 'Allocating settlements by documents...';
					|it = 'È in corso la ripartizione dei calcoli sui documenti.';
					|pl = 'Jest wykonywany podział rozliczeń według dokumentów.';
					|tr = 'Hesaplamaların belgeler üzerinde dağıtımını gerçekleştirir.'");
		Else
			TimeConsumingOperationsClient.UpdateIdleHandlerParameters(IdleParameters);
		EndIf;
		
		AttachIdleHandler("BackgroundJobCheckOnClient", IdleParameters.CurrentInterval, True);
		
	Else
		
		TimeConsumingOperationsClient.CloseTimeConsumingOperationForm(TimeConsumingOperationForm);
		MessageText = NStr("vi = 'Đã xảy ra lỗi trong quá trình phân bổ thanh toán trên các chứng từ. Xem Nhật ký để biết chi tiết.';
							|ru = 'Во время распределения расчетов по документам произошла ошибка. Подробности см. в Журнале регистрации.';
							|en = 'An error occurred while allocating settlements by the documents. For more information, see the Event log.'; fa = 'An error occurred while allocating settlements by the documents. For more information, see the Event log.';
							|it = 'Durante la ripartizione dei calcoli nei documenti si è verificato un errore. Vedere il registro per i dettagli.';
							|pl = 'Podczas podziału rozliczeń według dokumentów wystąpił błąd. Szczegóły zob. w Dzienniku rejestracji.';
							|tr = 'Ödemelerin belgeler arasında dağıtılırken hata oluştu. Ayrıntılar için Kayıt Defterine bak.'");
		CommonClient.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

&AtServer
Function ConvertToLocalSum(Sum,Currency,ARAPObject)
	Return ProcessingOfExchangeRatesTM.ConvertToCurrency(Sum,
				LocalAccountingCurrency,
				Currency,
				LocalAccountingCurrency,
				Object.Date,
				ARAPObject);
EndFunction

&AtServer
Function RecalculateToAmountMAN(Sum,Currency,ARAPObject)
	Return ProcessingOfExchangeRatesTM.ConvertToCurrency(Sum,
				LocalAccountingCurrency,
				Currency,
				ManagementAccountingCurrency,
				Object.Date,
				ARAPObject);
EndFunction

&AtServer
Function ConvertToSumOfMutualSettlements(Sum,Currency,ARAPObject)
	Return ProcessingOfExchangeRatesTM.ConvertToCurrency(Sum,
				LocalAccountingCurrency,
				LocalAccountingCurrency,
				Currency,
				Object.Date,
				ARAPObject);
EndFunction

&AtServer
Procedure SetVisibilityBasicVersion()
	
	ItSNotBasic = GetFunctionalOption("NotBaseVersion");
	
	ItemArray = New Array();
	ItemArray.Add("DecorationTheAmountOfUPRBasement");
	ItemArray.Add("AccountsReceivableTotalAmountOfUpr");
	ItemArray.Add("AccountsPayableTotalAmountOfUPR");
	ItemArray.Add("TheCurrencyFieldOfTheAccountingDepartment");
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Visible", ItSNotBasic);
	If Not ItSNotBasic Then
		Items.AccountsReceivableWithoutSplitSumCompl.Title = NStr("vi = 'Tổng số';
																	|ru = 'Сумма';
																	|en = 'Amount'; fa = 'مبلغ';
																	|it = 'Importo';
																	|pl = 'Wartość';
																	|tr = 'Tutar'");
		Items.AccountsPayableWithoutDivisionAmountRegl.Title = NStr("vi = 'Tổng số';
																	|ru = 'Сумма';
																	|en = 'Amount'; fa = 'مبلغ';
																	|it = 'Importo';
																	|pl = 'Wartość';
																	|tr = 'Tutar'");
		Items.DecorationSummaReglBasement.Title = NStr("vi = 'Tổng số';
														|ru = 'Сумма';
														|en = 'Amount'; fa = 'مبلغ';
														|it = 'Importo';
														|pl = 'Wartość';
														|tr = 'Tutar'");
		Items.AccountsPayableSumCompl.Title = NStr("vi = 'Tổng số';
													|ru = 'Сумма';
													|en = 'Amount'; fa = 'مبلغ';
													|it = 'Importo';
													|pl = 'Wartość';
													|tr = 'Tutar'");
		Items.AccountsReceivableSumCompl.Title = NStr("vi = 'Tổng số';
														|ru = 'Сумма';
														|en = 'Amount'; fa = 'مبلغ';
														|it = 'Importo';
														|pl = 'Wartość';
														|tr = 'Tutar'");
	EndIf;
	
EndProcedure

&AtServer
Function OrganizationsToCalculate_(DebtParametersDebtor = Undefined, DebtParametersCreditor = Undefined)
	
	AvailableCompanies = New Array;
	
	RequestOrganizations = New Query("SELECT ALLOWED
	|	Companies.Ref
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.ParentCompany IN (&Organization)
	|	AND Companies.TransactionsUsingParentCompanyAreAllowed");
	If ValueIsFilled(DebtParametersDebtor) Then
		If DebtParametersDebtor.RecordBranches Then
			RequestOrganizations.SetParameter("Organization", DebtParametersDebtor.Organization.Value);
			AvailableCompaniesDr = RequestOrganizations.Execute().Unload().UnloadColumn("Ref");
			For Each Org In AvailableCompaniesDr Do
				AvailableCompanies.Add(Org);
			EndDo;
		EndIf;
		AvailableCompanies.Add(DebtParametersDebtor.Organization.Value);
	EndIf;
	
	If ValueIsFilled(DebtParametersCreditor) Then
		If DebtParametersCreditor.RecordBranches Then
			RequestOrganizations.SetParameter("Organization", DebtParametersCreditor.Organization.Value);
			AvailableCompaniesCr = RequestOrganizations.Execute().Unload().UnloadColumn("Ref");
			For Each Org In AvailableCompaniesCr Do
				AvailableCompanies.Add(Org);
			EndDo;
		EndIf;
		AvailableCompanies.Add(DebtParametersCreditor.Organization.Value);
	EndIf;
	
	Return AvailableCompanies;
	
EndFunction

&AtClient
Procedure SetSettlementCurrency(NewSettlementCurrency)
	
	If Object.OperationKind <> PredefinedValue("Enum.KindsOfARAPSettlements.Arbitrary") Then
		If Not ValueIsFilled(ARAPCurrency) Then
			ARAPCurrency = NewSettlementCurrency;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ClearSettlementCurrency()
	
	DRIsEmpty = Object.AccountsReceivable.Count() = 0 
				Or Object.AccountsReceivable.Count() = 1 
					And Not ValueIsFilled(Object.AccountsReceivable[0].ARAPObject);
	CRIsEmpty = Object.AccountsPayable.Count() = 0 
				Or Object.AccountsPayable.Count() = 1 
					And Not ValueIsFilled(Object.AccountsPayable[0].ARAPObject);
	HeaderEmpty = Not ValueIsFilled(Object.ARAPObjectIntercompany) 
					And Not ValueIsFilled(Object.ARAPObjectDebtorCreditor);
	
	If DRIsEmpty And CRIsEmpty And HeaderEmpty Then
		ARAPCurrency = Undefined;
	EndIf;
	
EndProcedure

&AtServer
Procedure BlockSettlementObjects()
	
	UnlockDataForEdit(, UUID);
	
	ArrayOfCalculationObjects = New Array;
	For Each TableRow In Object.AccountsReceivable Do
		If ValueIsFilled(TableRow.ARAPObject) Then
			ArrayOfCalculationObjects.Add(TableRow.ARAPObject);
		EndIf;
		If ValueIsFilled(TableRow.ARAPObjectMirror) Then
			ArrayOfCalculationObjects.Add(TableRow.ARAPObjectMirror);
		EndIf;
	EndDo;
	For Each TableRow In Object.AccountsPayable Do
		If ValueIsFilled(TableRow.ARAPObject) Then
			ArrayOfCalculationObjects.Add(TableRow.ARAPObject);
		EndIf;
		If ValueIsFilled(TableRow.ARAPObjectMirror) Then
			ArrayOfCalculationObjects.Add(TableRow.ARAPObjectMirror);
		EndIf;
	EndDo;
	If ValueIsFilled(Object.ARAPObjectIntercompany) Then
		ArrayOfCalculationObjects.Add(Object.ARAPObjectIntercompany);
	EndIf;
	If ValueIsFilled(Object.ARAPObjectIntercompanyMirrored) Then
		ArrayOfCalculationObjects.Add(Object.ARAPObjectIntercompanyMirrored);
	EndIf;
	If ValueIsFilled(Object.ARAPObjectDebtorCreditor) Then
		ArrayOfCalculationObjects.Add(Object.ARAPObjectDebtorCreditor);
	EndIf;
	If ValueIsFilled(Object.ARAPObjectDebtorCreditorMirror) Then
		ArrayOfCalculationObjects.Add(Object.ARAPObjectDebtorCreditorMirror);
	EndIf;
	
	ArrayOfCalculationObjects = CommonClientServer.CollapseArray(ArrayOfCalculationObjects);
	
	For Each ARAPObject In ArrayOfCalculationObjects Do
		//@skip-warning
		Try
			LockDataForEdit(ARAPObject,, UUID);
		Except
		EndTry;
	EndDo;
	
EndProcedure

// Checks the fullness of the tabular part of the table name
// 
// Parameters:
//  TableName - String - Possible values: "Debtor's debt", "Creditor's debt".
// 
// Returns:
//  Boolean - True if there is data.
//
&AtClient
Function ThereAreLines(TableName)
	
	DebtList = True;
	If TableName = "AccountsReceivable" Then
		DebtList = RadioButtonAccountsReceivable = 1;
	Else
		DebtList = RadioButtonAccountsPayable = 1;
	EndIf;
	
	If DebtList Then
		ThereAreLines = Object[TableName].Count() > 0;
	Else
		ThereAreLines = Not (Object[TableName][0].ARAPObjectMirror = PredefinedValue("Catalog.ARAPObjects.EmptyRef")
			And Object[TableName][0].ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef")
			And Object[TableName][0].Sum = 0
			And Object[TableName][0].AmountARAP = 0
			And Object[TableName][0].SumCompl = 0
			And Object[TableName][0].SumMan = 0);
	EndIf;
	
	Return ThereAreLines;
	
EndFunction


// Clears the table part of the table name according to the switches
// 
// Parameters:
//  TableName - String - Possible values: "Debtor's debt", "Creditor's debt".
&AtClient
Procedure ClearTablePart(TableName)
	
	DebtList = True;
	If TableName = "AccountsReceivable" Then
		DebtList = RadioButtonAccountsReceivable = 1;
	Else
		DebtList = RadioButtonAccountsPayable = 1;
	EndIf;
	
	If DebtList Then
		Object[TableName].Clear();
	Else
		Object[TableName][0].ARAPObjectMirror = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
		Object[TableName][0].ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
		Object[TableName][0].Sum = 0;
		Object[TableName][0].AmountARAP = 0;
		Object[TableName][0].ARAPCurrency = PredefinedValue("Catalog.Currencies.EmptyRef");
		Object[TableName][0].SumCompl = 0;
		Object[TableName][0].SumMan = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure InitializePreviousValues()
	PreviousValues = New Structure();
	PreviousValues.Insert("CounterpartyDebtor", Object.CounterpartyDebtor);
	PreviousValues.Insert("Creditor", Object.Creditor);
	PreviousValues.Insert("Organization", Object.Organization);
	PreviousValues.Insert("CompanyCreditor", Object.CompanyCreditor);
	PreviousValues.Insert("CounterpartyDebtorType", Object.CounterpartyDebtorType);
	PreviousValues.Insert("CounterpartyCreditorType", Object.CounterpartyCreditorType);
EndProcedure

&AtClient
Procedure OpenGiftCertificateSelectionForm()
	
	StatusesForSelection = GiftCertificatesClientServer.AcceptableStatusesOfGiftCertificates(Object);
	FilterParameters = New Structure;
	FilterParameters.Insert("Organization", Object.Organization);
	FilterParameters.Insert("Currency", LocalAccountingCurrency);
	FilterParameters.Insert("Status", StatusesForSelection);
	FilterParameters.Insert("GiftCardAccounting25", True);
	FilterParameters.Insert("OperationType", GiftCertificatesClientServer.TypeOfOperationForGiftCertificates(Object));
	
	If Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties") Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Organization", Object.Organization);
		AdditionalParameters.Insert("DoNotUseManualInput", False);
		AdditionalParameters.Insert("Filter", FilterParameters);
		AdditionalParameters.Insert("RegisterNewOnes", True);
		
		OpenForm(
			"Catalog.GiftCertificates.Form.ReadGiftCard",
			AdditionalParameters,
			ThisObject,
			UUID);
		
	ElsIf Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.PaymentByGiftCard") Then

		IDOfCurLine = Undefined;
		If Not Items.AccountsPayable.CurrentData = Undefined Then
			IDOfCurLine = Items.AccountsPayable.CurrentData.GetID();
		EndIf;
		TabularSection = Object.AccountsPayable;
		
		PickingParameters = New Structure;
		PickingParameters.Insert("Organization", Object.Organization);
		PickingParameters.Insert("Currency", LocalAccountingCurrency);
		
		AddressOfTableOfProductsForAnalyzingPossibilityOfPayment = GiftCertificatesServerCall.AddressOfProductsTabularPartForAnalyzingPossibilityOfPayingWithGiftCertificates(Object.Ref, UUID);
		If ValueIsFilled(AddressOfTableOfProductsForAnalyzingPossibilityOfPayment) Then
			PickingParameters.Insert("AddressInStorageGoods", AddressOfTableOfProductsForAnalyzingPossibilityOfPayment);
		EndIf;

		DataOfPlacedTable = PlaceTableOfGiftCertificates(IDOfCurLine, TabularSection);
		PickingParameters.Insert("AddressInStorage", DataOfPlacedTable.AddressInTempStorage);
		PickingParameters.Insert("CurrentRowIndex", DataOfPlacedTable.CurrentRowIndex);

		PickingParameters.Insert("OpeningModeSurcharge", False);
		PickingParameters.Insert("PayInAddition", 0);
		PickingParameters.Insert("ShowResultItRemainsToPayExtra", False);
		PickingParameters.Insert("RegisterNewOnes", False);
		PickingParameters.Insert("OnCloseNotifyDescription", New CallbackDescription("PickUpGiftCertificateCompletion", ThisObject));
		
		If ValueIsFilled(Object.Ref) Then
			FilterParameters.Insert("Date", Object.Date);
		EndIf;

		PickingParameters.Insert("Filter", FilterParameters);
		GiftCertificatesClient.OpenGiftCertificateSelectionForm(ThisObject, PickingParameters);
		
	Else
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure PickUpGiftCertificateStart(Result, AdditionalParameters) Export
	
	OpenGiftCertificateSelectionForm();
	
EndProcedure

&AtClient
Procedure PickUpGiftCertificateCompletion(Result, AdditionalParameters) Export
	
	If IsTempStorageURL(Result) Then
		ProcessSelectedGiftCertificatesOnServer(Result);
		If Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.PaymentByGiftCard") Then
			If Object.AccountsPayable.Count() > 0 Then
				SetSettlementCurrency(Object.AccountsPayable[0].ARAPCurrency);
			EndIf;
		ElsIf Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties") Then
			If Object.AccountsReceivable.Count() > 0 Then
				SetSettlementCurrency(Object.AccountsReceivable[0].ARAPCurrency);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Function PlaceTableOfGiftCertificates(IDOfCurLine = Undefined, TabularSection)

	AmountCreditedByGiftCertificates = 0;

	TableOfCreditedGiftCertificates = New ValueTable;
	TableOfCreditedGiftCertificates.Columns.Add("GiftCertificate", New TypeDescription("CatalogRef.GiftCertificates"));
	TableOfCreditedGiftCertificates.Columns.Add("Sum", New TypeDescription("Number"));
	
	CurrentRowIndex = Undefined;
	CurCurrentDataObjectOfCalculations = Undefined;
	If Not IDOfCurLine = Undefined Then
		CurCurrentDataObjectOfCalculations = TabularSection.FindByID(IDOfCurLine).ARAPObject;
	EndIf;
	
	For Each DebtLine In TabularSection Do
		If ValueIsFilled(DebtLine.ARAPObject) Then
			DebtLineObject = Common.ObjectAttributeValue(DebtLine.ARAPObject, "Object");
			If TypeOf(DebtLineObject) = Type("CatalogRef.GiftCertificates") Then
				NewRow = TableOfCreditedGiftCertificates.Add();
				NewRow.GiftCertificate = DebtLineObject;
				NewRow.Sum = DebtLine.AmountARAP;
				AmountCreditedByGiftCertificates = AmountCreditedByGiftCertificates + DebtLine.AmountARAP;
				If DebtLine.ARAPObject = CurCurrentDataObjectOfCalculations Then
					CurrentRowIndex = TableOfCreditedGiftCertificates.IndexOf(NewRow);
				EndIf;
			EndIf; 
		EndIf;
	EndDo;
	
	Result = New Structure;
	Result.Insert("AddressInTempStorage", PutToTempStorage(TableOfCreditedGiftCertificates, UUID));
	Result.Insert("AmountCreditedByGiftCertificates", AmountCreditedByGiftCertificates);
	Result.Insert("CurrentRowIndex", CurrentRowIndex);	
	Return Result;
	
EndFunction

&AtServer
Procedure ProcessSelectedGiftCertificatesOnServer(Selected_Data)

	TabularEditingMode = False;
	If Object.OperationKind = Enums.KindsOfARAPSettlements.PaymentByGiftCard 
		And IsTempStorageURL(Selected_Data) Then

		TabularEditingMode = True;
		TabularSection = Object.AccountsPayable;
		ThereIsAttributeOfTabularPartARAPObjectGiftCard = True;
		
		SelectedGiftCertificates = GetFromTempStorage(Selected_Data);
		
	ElsIf Object.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties 
		And TypeOf(Selected_Data) = Type("CatalogRef.GiftCertificates") And ValueIsFilled(Selected_Data) Then 

		TabularSection = Object.AccountsReceivable;
		ThereIsAttributeOfTabularPartARAPObjectGiftCard = False;

		SelectedGiftCertificates = New ValueTable;
		SelectedGiftCertificates.Columns.Add("ARAPObject", New TypeDescription("CatalogRef.ARAPObjects"));
		SelectedGiftCertificates.Columns.Add("GiftCertificate", New TypeDescription("CatalogRef.GiftCertificates"));
		SelectedGiftCertificates.Columns.Add("Partner", New TypeDescription("CatalogRef.Partners"));
		SelectedGiftCertificates.Columns.Add("Sum", New TypeDescription("Number"));
		
		GiftCertificateDetails = GiftCertificatesServerCall.GetGiftCertificateDetails(Selected_Data);

		NewRow = SelectedGiftCertificates.Add();
		NewRow.ARAPObject = GiftCertificateDetails.ARAPObject;
		NewRow.GiftCertificate = GiftCertificateDetails.Ref;
		NewRow.Sum = GiftCertificateDetails.Nominal;
		NewRow.Partner = GiftCertificateDetails.Partner; 
		
	Else
		Return;
	EndIf;
	
	// Clear rows in the table part without calculation objects
	SelectingRowsWithUnfilledCalculationObject = New Structure("ARAPObject", Catalogs.ARAPObjects.EmptyRef());
	ArrayOfRowsToDelete_ = TabularSection.FindRows(SelectingRowsWithUnfilledCalculationObject);
	For Each RowForDeletion In ArrayOfRowsToDelete_ Do
		TabularSection.Delete(RowForDeletion);
	EndDo;
	
	If TabularEditingMode Then
		// If the previously selected certificates were cleared in the selection, then you need to clear them and Count them from the table
		ObjectsOfCalculationsOfTabularPart = TabularSection.Unload(,"ARAPObject");
		ObjectsOfCalculationsOfTabularPart.GroupBy("ARAPObject");
		ObjectAttributeValues = Common.ObjectsAttributeValue(ObjectsOfCalculationsOfTabularPart.UnloadColumn("ARAPObject"), "Object");
		ArrayOfRowsToDelete = New Array;
		For Each LineOfATabularSection In TabularSection Do
			RowOfTablePartIsObject = ObjectAttributeValues[LineOfATabularSection.ARAPObject];
			If TypeOf(RowOfTablePartIsObject) = Type("CatalogRef.GiftCertificates") Then
				TheStructureOfTheSearch = New Structure("GiftCertificate", RowOfTablePartIsObject);
				If SelectedGiftCertificates.FindRows(TheStructureOfTheSearch).Count()=0 Then
					ArrayOfRowsToDelete.Add(LineOfATabularSection);
				EndIf;
			EndIf;
		EndDo;
		For Each RowForDeletion In ArrayOfRowsToDelete Do
			TabularSection.Delete(RowForDeletion);
		EndDo;
	EndIf;
		
	// Gift certificates are selected in the same currency of mutual settlements.
	CurrencyOfMutualSettlementsOfSelectedGiftCertificates = Undefined;
	If SelectedGiftCertificates.Count() > 0 Then
		CurrencyOfMutualSettlementsOfSelectedGiftCertificates = Common.ObjectAttributeValue(
			SelectedGiftCertificates[0].ARAPObject,
			"ARAPCurrency");
	EndIf;
	
	TheStructureOfTheSearch = New Structure("ARAPObject, Partner");
	For Each TableRow In SelectedGiftCertificates Do
		
		FillPropertyValues(TheStructureOfTheSearch, TableRow);
		FoundRows = TabularSection.FindRows(TheStructureOfTheSearch);
		
		If FoundRows.Count() = 0 Then
			LineOfATabularSection = TabularSection.Add();
			LineOfATabularSection.Organization = Object.Organization;
			LineOfATabularSection.ARAPCurrency = CurrencyOfMutualSettlementsOfSelectedGiftCertificates;
			LineOfATabularSection.ARAPObject = TableRow.ARAPObject;
			LineOfATabularSection.Partner = TableRow.Partner;			
			LineOfATabularSection.PaymentType_ = PredefinedValue("Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting")			
		Else
			LineOfATabularSection = FoundRows[0];
		EndIf;
		
		If ThereIsAttributeOfTabularPartARAPObjectGiftCard = True Then
			LineOfATabularSection.ObjectOfCalculationsIsGiftCertificate = True;
		EndIf;
		
		LineOfATabularSection.Sum        		 = TableRow.Sum;
		LineOfATabularSection.AmountARAP = TableRow.Sum;

		LineOfATabularSection.SumCompl 			 = LineOfATabularSection.AmountARAP;
		LineOfATabularSection.SumMan 			 = LineOfATabularSection.AmountARAP;
		If CurrencyOfMutualSettlementsOfSelectedGiftCertificates <> LocalAccountingCurrency Then
			LineOfATabularSection.SumCompl = ProcessingOfExchangeRatesTM.ConvertDocumentAmountToCurrency(
				LineOfATabularSection.AmountARAP, CurrencyOfMutualSettlementsOfSelectedGiftCertificates, LocalAccountingCurrency, Object.Date, LocalAccountingCurrency);
		EndIf;			
		If CurrencyOfMutualSettlementsOfSelectedGiftCertificates <> ManagementAccountingCurrency Then
			LineOfATabularSection.SumMan = ProcessingOfExchangeRatesTM.ConvertDocumentAmountToCurrency(
				LineOfATabularSection.AmountARAP, CurrencyOfMutualSettlementsOfSelectedGiftCertificates, ManagementAccountingCurrency, Object.Date, LocalAccountingCurrency);
		EndIf;
				
	EndDo;
	
EndProcedure

&AtServer
Function DocumentCurrencyToTransfer(TabularSectionName)
	
	ThisIsDebit = TabularSectionName = "AccountsReceivable";
	
	Result = Undefined;
	If SelectedTypeOfOperationAdvanceTransfer() Or SelectedTypeOfOperationDebtTransfer() Then
		If ThisIsDebit Then
			Indebtedness = Object.AccountsPayable;
		Else
			Indebtedness = Object.AccountsReceivable;
		EndIf;
		If Indebtedness.Count() > 0 Then
			Result = Indebtedness[0].ARAPCurrency;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
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
