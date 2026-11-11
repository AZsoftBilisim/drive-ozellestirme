#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		Object.Date = CurrentSessionDate();
		OnReadCreateAtServer();
	EndIf;
	
	AddressOfTheContractSchedule = PutToTempStorage(Undefined, UUID);
		
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_OBEntryOfLeaseSettlements", WriteParameters, Object.Ref);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PageGeneral

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOfChangeOnServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	CounterpartyOnChangeServer();

EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure RecordInOperationalAccountingOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure PostInFinancialAndTaxAccountingOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure RecordInMAOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

#EndRegion

#Region PagePaymentsUnderTheContract

&AtClient
Procedure SecurityDepositAmountOnChange(Item)
	
	RecalculateContractAmountAndVATAmount(Object);
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure DateOfFirstSecurityPaymentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure LeaseServicesAmount(Item)
	
	AmountOfRentalServicesWhenChangedOnServer();

EndProcedure

&AtClient
Procedure DateOfFirstPaymentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure AmountOfLeaseAssetsByuoutOnChange(Item)
	
	AmountOfRedemptionOfRentalItemsWhenChangingOnServer();

EndProcedure

&AtClient
Procedure VATAmountOnChange(Item)
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure VATRateOnChange(Item)
	
	VATRateForChangesOnServer();

EndProcedure

&AtClient
Procedure RentalPeriodURLProcessing(Item, FormattedStringURL, StandardProcessing)

	StandardProcessing = False;
	
	LeasedAssetAccountingClient.EnterLeaseTerm(
		ThisObject, 
		Object,
		New CallbackDescription("EnterLeaseTermCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure PaymentFrequencyOnChange(Item)
	
	If Not ValueIsFilled(Object.PaymentFrequency) Then
		Object.PaymentFrequency = PredefinedValue("Enum.ScheduleTimeFence.Month");
	EndIf;
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure AccrualFrequencyOnChange(Item)
	
	If Not ValueIsFilled(Object.AccrualFrequency) Then
		Object.AccrualFrequency = PredefinedValue("Enum.ScheduleTimeFence.Month");
	EndIf;
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure PaymentForLeaseServiceOnChange(Item)
	
	ChangedBankingDetails = Item.Name;
	
	If Object.PaymentFrequency = Object.AccrualFrequency
		And Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
		And Object.AccrualOfLeaseService = 0
		And Object.PaymentForLeaseService <> 0 Then
			
		Object.AccrualOfLeaseService = Object.PaymentForLeaseService;
		ChangedBankingDetails = ChangedBankingDetails + ",AccrualOfLeaseService";
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);

EndProcedure

&AtClient
Procedure AccrualOfLeaseServiceOnChange(Item)
	
	ChangedBankingDetails = Item.Name;
	
	If Object.PaymentFrequency = Object.AccrualFrequency
		And Object.PaymentFrequency <> PredefinedValue("Enum.ScheduleTimeFence.Custom")
		And Object.PaymentForLeaseService = 0
		And Object.AccrualOfLeaseService <> 0 Then
			
		Object.PaymentForLeaseService = Object.AccrualOfLeaseService;
		ChangedBankingDetails = ChangedBankingDetails + ",PaymentForLeaseService";
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);

EndProcedure

&AtClient
Procedure BasementInformationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "#FillInSchedule" Then
		FillInScheduleAccordingToCalculations();		
	ElsIf FormattedStringURL = "#FillInCalculationsAccordingToSchedule" Then
		FillInCalculationsAccordingToSchedule();		
	ElsIf FormattedStringURL = "#ChangeDocumentVersion" Then
		ChangeDocumentVersion();		
	EndIf;
	
EndProcedure

#EndRegion

#Region PaymentBalancesPage

&AtClient
Procedure LeaseObligationsBalanceOnChange(Item)
	
	If Items.LeaseLiabilityBalanceLocal.Visible
		And ContractCurrency = ComplCurrency
		And Object.LeaseLiabilityBalanceLocal = AttributesValuesBeforeChange.LeaseObligationsBalance Then
		Object.LeaseLiabilityBalanceLocal = Object.LeaseObligationsBalance;
	EndIf;
	
	If Items.LeaseLiabilityBalanceMan.Visible
		And ContractCurrency = CurrencyOfMan
		And Object.LeaseLiabilityBalanceMan = AttributesValuesBeforeChange.LeaseObligationsBalance Then
		Object.LeaseLiabilityBalanceMan = Object.LeaseObligationsBalance;
	EndIf;

	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure LeaseLiabilityBalanceLocalOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure LeaseLiabilityBalanceManOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure RentalServiceBalanceOnChange(Item)
	
	If Items.RentalServiceBalanceLocal.Visible
		And ContractCurrency = ComplCurrency
		And Object.RentalServiceBalanceLocal = AttributesValuesBeforeChange.RentalServiceBalance Then
		Object.RentalServiceBalanceLocal = Object.RentalServiceBalance;
	EndIf;
	
	If Items.RentalServiceBalanceMan.Visible
		And ContractCurrency = CurrencyOfMan
		And Object.RentalServiceBalanceMan = AttributesValuesBeforeChange.RentalServiceBalance Then
		Object.RentalServiceBalanceMan = Object.RentalServiceBalance;
	EndIf;

	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure RentalServiceBalanceLocalOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure RentalServiceBalanceManOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure BuyoutValueBalanceOnChange(Item)
	
	If Items.BuyoutValueBalanceLocal.Visible
		And ContractCurrency = ComplCurrency
		And Object.BuyoutValueBalanceLocal = AttributesValuesBeforeChange.BuyoutValueBalance Then
		Object.BuyoutValueBalanceLocal = Object.BuyoutValueBalance;
	EndIf;
	
	If Items.BuyoutValueBalanceMan.Visible
		And ContractCurrency = CurrencyOfMan
		And Object.BuyoutValueBalanceMan = AttributesValuesBeforeChange.BuyoutValueBalance Then
		Object.BuyoutValueBalanceMan = Object.BuyoutValueBalance;
	EndIf;

	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure BuyoutValueBalanceLocalOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure BuyoutValueBalanceManOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure VATBalanceOnChange(Item)
	
	If Items.VATBalanceLocal.Visible
		And ContractCurrency = ComplCurrency
		And Object.VATBalanceLocal = AttributesValuesBeforeChange.VATBalance Then
		Object.VATBalanceLocal = Object.VATBalance;
	EndIf;
	
	If Items.VATBalanceMan.Visible
		And ContractCurrency = CurrencyOfMan
		And Object.VATBalanceMan = AttributesValuesBeforeChange.VATBalance Then
		Object.VATBalanceMan = Object.VATBalance;
	EndIf;

	ConfigureDependentFormElements(Item);

EndProcedure

&AtClient
Procedure VATBalanceLocalOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure VATBalanceManOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure InterestsBalanceOnChange(Item)
	
	If Items.InterestBalanceLocal.Visible
		And ContractCurrency = ComplCurrency
		And Object.InterestBalanceLocal = AttributesValuesBeforeChange.InterestsBalance Then
		Object.InterestBalanceLocal = Object.InterestsBalance;
	EndIf;
	
	If Items.InterestBalanceMan.Visible
		And ContractCurrency = CurrencyOfMan
		And Object.InterestBalanceMan = AttributesValuesBeforeChange.InterestsBalance Then
		Object.InterestBalanceMan = Object.InterestsBalance;
	EndIf;
	
	ConfigureDependentFormElements(Item);
	
EndProcedure

&AtClient
Procedure InterestBalanceLocalOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

&AtClient
Procedure InterestBalanceManOnChange(Item)
	ConfigureDependentFormElements(Item);
EndProcedure

#EndRegion

#Region AdditionalPage

&AtClient
Procedure VATTaxationOnChange(Item)
	TaxationOfVATWhenChangingOnServer();
EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersPrepaymentsUnderLeaseContracts

&AtClient
Procedure PrepaymentsUnderLeaseContractsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow 
		And Not Copy
		And FormServiceParameters.ContractDetails_ <> Undefined Then
		
		CurrentData = Items.PrepaymentsUnderLeaseContracts.CurrentData;
		If FormServiceParameters.ContractDetails_.HasSecurityDeposit Then
			CurrentData.PaymentType = PredefinedValue("Enum.TypesOfLeasePayments.DepositPayment");
		Else
			CurrentData.PaymentType = PredefinedValue("Enum.TypesOfLeasePayments.BuyoutValuePrepayment");
		EndIf;
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure OpenPaymentSchedule(Command)
	
	OpenPaymentAndAccrualSchedule("ServicePaymentSchedule");
	
EndProcedure

&AtClient
Procedure OpenTheAccrualSchedule(Command)
	
	OpenPaymentAndAccrualSchedule("ServiceAccrualSchedule");

EndProcedure

&AtClient
Procedure OpenTheInterestAccrualSchedule(Command)
	
	OpenPaymentAndAccrualSchedule("InterestAccrualSchedule");

EndProcedure

&AtClient
Procedure CalculateTheBidOrCost(Command)
	
	If LeasedAssetAccountingClient.YouCanCalculateRateOrCost(Object, FormServiceParameters.ContractDetails_, "") Then
		CalculateRateCostPercentagesOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	OBEntryOfLeaseSettlementsClientLocalization.OnExecuteCommand(Command, ThisObject);

EndProcedure

#Region StandardSubsystems

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
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
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtClient
Procedure ConfigureDependentFormElements(Val ChangedDetailsOrElement = "")

	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If RequiresServerCallToConfigureFormElements(StructureOfChangedProps) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails)
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Val Form, Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("VNAManagementIsUsed_2_4", FormServiceParameters.VNAManagementIsUsed_2_4);
	AuxiliaryAttributes.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed);
	AuxiliaryAttributes.Insert("StartOfLeaseAccountingUnderFSB25_2018", FormServiceParameters.StartOfLeaseAccountingUnderFSB25_2018);
	AuxiliaryAttributes.Insert("ContractDetails_", FormServiceParameters.ContractDetails_);
	AuxiliaryAttributes.Insert("InsignificantVATRate", FormServiceParameters.InsignificantVATRate);
	AuxiliaryAttributes.Insert("SeparateFAAccountingByVATTaxation", FormServiceParameters.SeparateFAAccountingByVATTaxation);
	AuxiliaryAttributes.Insert("UseLocal", FormServiceParameters.UseLocal);
	AuxiliaryAttributes.Insert("KeepManagementAccountingOnSelfFinancingChartOfAccounts", FormServiceParameters.KeepManagementAccountingOnSelfFinancingChartOfAccounts);
	AuxiliaryAttributes.Insert("RecordInMA", Object.RecordInMA);
	AuxiliaryAttributes.Insert("PostInFinancialAndTaxAccounting", Object.PostInFinancialAndTaxAccounting);
	AuxiliaryAttributes.Insert("RecordInOperationalAccounting", Object.RecordInOperationalAccounting);
	AuxiliaryAttributes.Insert("DocumentVersion24", False);
	AuxiliaryAttributes.Insert("NameOfFATablePart", "");

	ItemDetailsParameters = LeasedAssetAccountingClientServer.PropertyValuesOfDependentDetails_EnteringLeaseSettlementBalances(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(
			Object, ItemDetailsParameters, "ServicePaymentSchedule,ServiceAccrualSchedule,InterestAccrualSchedule");
	EndIf;
	
	AccountingForBalanceSheet = (FormServiceParameters.ContractDetails_.AssetHolder = PredefinedValue("Enum.LeasedAssetHolder.Lessor"));
	
	#Region PageGeneral
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		
		Items.Comment.MaxWidth = 
			?(FormServiceParameters.LeaseAccountingAccordingToFSB25_2018IsUsed Or Not AccountingForBalanceSheet, 67, 75);
		
		Items.EnterBalanceBy.Visible = 
				Items.RecordInOperationalAccounting.Visible
				Or Items.PostInFinancialAndTaxAccounting.Visible
				Or Items.RecordInMA.Visible;
			
	EndIf;
	
	#EndRegion
	
	#Region PagePaymentsUnderTheContract
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then

		PropertyValue =
			AuxiliaryAttributes.LeaseAccountingAccordingToFSB25_2018IsUsed 
			Or Not AccountingForBalanceSheet;
			
		Items.PictureHowToFillOutCalculations.Visible = PropertyValue;
		Items.ExplanationHowToFillOutCalculations.Visible = PropertyValue;	
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or UpdateAll Then
		
		PropertyValue = AuxiliaryAttributes.RecordInOperationalAccounting;
				
		Items.RentalPeriod.Visible = PropertyValue;
		Items.OpenPaymentSchedule.Visible = PropertyValue;
		Items.OpenTheAccrualSchedule.Visible = PropertyValue;
		
	EndIf;
		
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or UpdateAll Then

		PropertyValue = Items.PaymentFrequency.Visible;

		Items.PictureHowToFillOutCalculations.Visible = PropertyValue;
		Items.ExplanationHowToFillOutCalculations.Visible = PropertyValue;
		
	EndIf;
		
	#EndRegion
	
	#Region Name
	
	If StructureOfChangedProps.Property("PostInFinancialAndTaxAccounting") 
		Or StructureOfChangedProps.Property("RecordInMA") 
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting") 
		Or StructureOfChangedProps.Property("Contract") 
		Or UpdateAll Then
		
		Items.DecorationBalancesInTheContractCurrency.Visible = 
			Items.LeaseObligationsBalance.Visible
			Or Items.RentalServiceBalance.Visible
			Or Items.BuyoutValueBalance.Visible
			Or Items.VATBalance.Visible
			Or Items.InterestsBalance.Visible;
			
		Items.DecorationRemnantsOfRegl.Visible = 
			Items.LeaseLiabilityBalanceLocal.Visible
			Or Items.RentalServiceBalanceLocal.Visible
			Or Items.BuyoutValueBalanceLocal.Visible
			Or Items.VATBalanceLocal.Visible
			Or Items.InterestBalanceLocal.Visible;

		Items.DecorationRemainsOfUPR.Visible = 
			Items.LeaseLiabilityBalanceMan.Visible
			Or Items.RentalServiceBalanceMan.Visible
			Or Items.BuyoutValueBalanceMan.Visible
			Or Items.VATBalanceMan.Visible
			Or Items.InterestBalanceMan.Visible;

		Items.DecorationRemainsIndentation.Visible = 
			Items.DecorationBalancesInTheContractCurrency.Visible
			Or Items.DecorationRemnantsOfRegl.Visible
			Or Items.DecorationRemainsOfUPR.Visible;

		//
		Items.LeaseObligationsBalanceDecoration.Visible =
			Items.LeaseObligationsBalance.Visible
			Or Items.LeaseLiabilityBalanceLocal.Visible
			Or Items.LeaseLiabilityBalanceMan.Visible;

		Items.ServiceRentalTheRestOfTheDecorations.Visible =
			Items.RentalServiceBalance.Visible
			Or Items.RentalServiceBalanceLocal.Visible
			Or Items.RentalServiceBalanceMan.Visible;

		Items.PurchasePriceBalanceDecoration.Visible =
			Items.BuyoutValueBalance.Visible
			Or Items.BuyoutValueBalanceLocal.Visible
			Or Items.BuyoutValueBalanceMan.Visible;

		Items.HastalikDecoration.Visible =
			Items.VATBalance.Visible
			Or Items.VATBalanceLocal.Visible
			Or Items.VATBalanceMan.Visible;

		Items.InterestTheRestOfTheDecorations.Visible =
			Items.InterestsBalance.Visible
			Or Items.InterestBalanceLocal.Visible
			Or Items.InterestBalanceMan.Visible;

		//
		Items.LeaseLiabilitiesDebitBalance.Visible = 
			Items.LeaseObligationsBalance.Visible
			Or Items.LeaseLiabilityBalanceLocal.Visible
			Or Items.LeaseLiabilityBalanceMan.Visible;
		
		Items.RentalServiceDebitBalance.Visible = 
			Items.RentalServiceBalance.Visible
			Or Items.RentalServiceBalanceLocal.Visible
			Or Items.RentalServiceBalanceMan.Visible;
		
		Items.BuyoutValueDebitBalance.Visible = 
			Items.BuyoutValueBalance.Visible
			Or Items.BuyoutValueBalanceLocal.Visible
			Or Items.BuyoutValueBalanceMan.Visible;

		Items.VATDebitBalance.Visible = 
			Items.VATBalance.Visible
			Or Items.VATBalanceLocal.Visible
			Or Items.VATBalanceMan.Visible;

		Items.InterestDebitBalance.Visible = 
			Items.InterestsBalance.Visible
			Or Items.InterestBalanceLocal.Visible
			Or Items.InterestBalanceMan.Visible;

		//
		Items.TheSceneryRemainsBalance.Visible = 
			Items.LeaseLiabilitiesDebitBalance.Visible
			Or Items.RentalServiceDebitBalance.Visible
			Or Items.BuyoutValueDebitBalance.Visible
			Or Items.VATDebitBalance.Visible
			Or Items.InterestDebitBalance.Visible;
		
	EndIf;
		
	If StructureOfChangedProps.Property("LeaseObligationsBalance")
		Or StructureOfChangedProps.Property("LeaseLiabilityBalanceLocal")
		Or StructureOfChangedProps.Property("LeaseLiabilityBalanceMan")
		Or StructureOfChangedProps.Property("RentalServiceBalance")
		Or StructureOfChangedProps.Property("RentalServiceBalanceLocal")
		Or StructureOfChangedProps.Property("RentalServiceBalanceMan")
		Or StructureOfChangedProps.Property("BuyoutValueBalance")
		Or StructureOfChangedProps.Property("BuyoutValueBalanceLocal")
		Or StructureOfChangedProps.Property("BuyoutValueBalanceMan")
		Or StructureOfChangedProps.Property("VATBalance")
		Or StructureOfChangedProps.Property("VATBalanceLocal")
		Or StructureOfChangedProps.Property("VATBalanceMan")
		Or StructureOfChangedProps.Property("InterestsBalance")
		Or StructureOfChangedProps.Property("InterestBalanceLocal")
		Or StructureOfChangedProps.Property("InterestBalanceMan") Then
			
		UpdateDetailsValuesBeforeChange(Form);
	EndIf;
		
	#EndRegion
	
	#Region DiscountingPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract")
		Or StructureOfChangedProps.Property("RecordInOperationalAccounting")
		Or UpdateAll Then

		Items.FairValueCurrency.Visible = Items.FairValue.Visible;
		Items.NonGuaranteedValueCurrency.Visible = Items.NonGuaranteedFinalCost.Visible;
		Items.CostCurrency.Visible = Items.Cost.Visible;
	
	EndIf;
	
	#EndRegion
	
	#Region FooterGroup
	
	If StructureOfChangedProps.Property("VATTaxation")
		Or UpdateAll Then
		
		PurchaseIsSubjectToVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfProcurementDocument(Object.VATTaxation);
		
		If PurchaseIsSubjectToVAT Then
			Items.VATPageGroup.CurrentPage   = Items.PageVAT;
			Items.PagesTotalGroup.CurrentPage = Items.TotalSNDSPage;
		Else
			Items.VATPageGroup.CurrentPage   = Items.PageExcludingVAT;
			Items.PagesTotalGroup.CurrentPage = Items.PageTotalWithoutVAT;
		EndIf;
	
	EndIf;
	
	#EndRegion
	
	LeasedAssetAccountingClientServer.ConfigureDependentFormElements__(Form, AuxiliaryAttributes, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	#Region PageGeneral
	
	If UpdateAll Then
		Items.EnterBalanceBy.Visible = False;
	EndIf;
	
	#EndRegion
	
	#Region PaymentBalancesPage
	
	If StructureOfChangedProps.Property("Contract")
		Or UpdateAll Then
		
		ContractCurrency = FormServiceParameters.ContractDetails_.ARAPCurrency;
		Items.DecorationBalancesInTheContractCurrency.Title = String(ContractCurrency);
		
		SelectionParameterSelection = Undefined;
		IndexOfFilter = 0;
		For Each ChoiceParameter In Items.PrepaymentsUnderLeaseContractsPaymentType.ChoiceParameters Do 
			IndexOfFilter = IndexOfFilter+1;
			If ChoiceParameter.Name = "Filter.Ref" Then
				ElementRentalServiceAdvancePayment = ChoiceParameter.Value.Find(Enums.TypesOfLeasePayments.RentalServicePrepayment);
				If FormServiceParameters.ContractDetails_.KeepAccountingOfPrepaymentsForCurrentRentalPaymentsBrokenDownByPaymentDocuments = True Then 
					If ElementRentalServiceAdvancePayment = Undefined Then 
						AvailablePaymentTypes = New Array(ChoiceParameter.Value);
						AvailablePaymentTypes.Add(Enums.TypesOfLeasePayments.RentalServicePrepayment);
						SelectionParameterSelection = New ChoiceParameter("Filter.Ref", New FixedArray(AvailablePaymentTypes));
					EndIf;
				Else
					If ElementRentalServiceAdvancePayment <> Undefined Then 
						AvailablePaymentTypes = New Array(ChoiceParameter.Value);
						AvailablePaymentTypes.Delete(ElementRentalServiceAdvancePayment);
						SelectionParameterSelection = New ChoiceParameter("Filter.Ref", New FixedArray(AvailablePaymentTypes));
					EndIf;
				EndIf;
				Break;
			EndIf;
		EndDo;
		
		If SelectionParameterSelection <> Undefined Then
			ParametersForSelectingPaymentTypes = New Array(Items.PrepaymentsUnderLeaseContractsPaymentType.ChoiceParameters);
			ParametersForSelectingPaymentTypes.Delete(IndexOfFilter-1);
			ParametersForSelectingPaymentTypes.Add(SelectionParameterSelection);
			Items.PrepaymentsUnderLeaseContractsPaymentType.ChoiceParameters = New FixedArray(ParametersForSelectingPaymentTypes);
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		Items.DecorationRemainsOfUPR.Title = StrTemplate(NStr("vi = 'Quản trị (%1):';
																|ru = 'Упр. (%1):';
																|en = 'Mgmt (%1):'; fa = 'Mgmt (%1):';
																|it = 'Gest. (%1):';
																|pl = 'Zarz. (%1):';
																|tr = 'Yönetim (%1):'"), String(CurrencyOfMan));
		
		If ValueIsFilled(ComplCurrency) Then
			Items.DecorationRemnantsOfRegl.Title = StrTemplate(NStr("vi = 'Quản trị (%1):';
																	|ru = 'Регл. (%1):';
																	|en = 'Local (%1):'; fa = 'Local (%1):';
																	|it = 'Regol. (%1):';
																	|pl = 'Reg. (%1):';
																	|tr = 'Yerel (%1):'"), String(ComplCurrency));
		Else
			Items.DecorationRemnantsOfRegl.Title = NStr("vi = 'Tài chính:';
														|ru = 'Регл.:';
														|en = 'Local.:'; fa = 'Local.:';
														|it = 'Reg.:';
														|pl = 'Local.:';
														|tr = 'Yerel'");
		EndIf;
	EndIf;
	
	#EndRegion
	
	#Region Other
	
	If UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"UseVATAccounting",
			GetFunctionalOption("UseVATAccounting"),
			FormServiceParameters);
		
		If Not FormServiceParameters.UseVATAccounting Then
			Items.AmountOfPersonalIncomeTax.Visible = False;
		EndIf;
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"UseLocal",
			GetFunctionalOption("UseLocal"),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"KeepManagementAccountingOnSelfFinancingChartOfAccounts",
			GetFunctionalOption("KeepManagementAccountingOnSelfFinancingChartOfAccounts"),
			FormServiceParameters);

	EndIf;

	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrencyPresentation",
			String(ComplCurrency),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"CurrenciesDoNotMatch",
			FormServiceParameters.CurrencyOfManPresentation = FormServiceParameters.ComplCurrencyPresentation,
			FormServiceParameters);
		ParentCompany = AccountingPoliciesTaxSettingsCached.ParentCompany(Object.Organization);
		SetFormFunctionalOptionParameters(New Structure("Organization", ParentCompany));
		
	EndIf;
		
	If StructureOfChangedProps.Property("Organization") Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"StartOfLeaseAccountingUnderFSB25_2018",
			LeasedAssetAccounting.StartOfLeaseAccountingUnderFSB25_2018(Object.Organization),
			FormServiceParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Date") Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"VNAManagementIsUsed_2_4",
			NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date),
			FormServiceParameters);
		
	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"LeaseAccountingAccordingToFSB25_2018IsUsed",
			LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date),
			FormServiceParameters);
		
		//
		AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
			"VATAccountingSettings", Object.Organization, ?(Object.Date <> '000101010000', EndOfMonth(Object.Date), '000101010000'));

		NonCurrentAssetsInternal.SetStructureProperty(
			"SeparateFAAccountingByVATTaxation",
			AccountingPolicyParameters <> Undefined And AccountingPolicyParameters.SeparateFAAccountingByVATTaxation,
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("VATRate") Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"InsignificantVATRate",
			VATAccountingERP.InsignificantRate(Object.VATRate),
			FormServiceParameters);
		
	EndIf;

	#EndRegion
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	Return StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Contract");

EndFunction

&AtServer
Procedure DateOfChangeOnServer()
	
	UpdatePurchaseForActivity();
	
	ConfigureDependentFormElementsOnServer("Date");
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	UpdatePurchaseForActivity();
	
	ConfigureDependentFormElementsOnServer("Organization,Contract");
	
EndProcedure

&AtServer
Procedure PartnerWhenChangesAreMadeOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	CounterpartyOnChangeServer();
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	FillParameters = Documents.OBEntryOfLeaseSettlements.ParametersForFillingInVATTaxationPurchases(Object);
	
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);

	VATAccountingERP.FillInVATTaxationPurchases(
		Object.VATTaxation, 
		FillParameters, 
		VATAccountingCachedParameterValues);
		
	Contract = Catalogs.LeaseContract.DefaultContract(
					Object.Organization, Object.Partner, Object.Counterparty, Object.Contract);
	
	If Contract <> Object.Contract Then
		Object.Contract = Contract;
		AgreementWhenModifiedOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	FillParameters = Documents.OBEntryOfLeaseSettlements.ParametersForFillingInVATTaxationPurchases(Object);
	
	VATAccountingERP.FillInListOfVATTaxChoices(Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);

	VATAccountingERP.FillInVATTaxationPurchases(
		Object.VATTaxation, 
		FillParameters, 
		VATAccountingCachedParameterValues);
		
	UpdatePurchaseForActivity();

	AddContractDetailsToServiceParametersOfForm();
	
	If Not ValueIsFilled(Object.Contract) Then
		DocumentCurrency = Catalogs.Currencies.EmptyRef();
	EndIf;
	
	ContractDetails_ = FormServiceParameters.ContractDetails_;
	
	DocumentCurrency = ContractDetails_.ARAPCurrency;
	DocumentCurrencyPresentation = String(DocumentCurrency);
	
	ConfigureDependentFormElementsOnServer("Contract,VATTaxation");
	
EndProcedure

&AtServer
Procedure AddContractDetailsToServiceParametersOfForm()
	
	NonCurrentAssetsInternal.SetStructureProperty(
		"ContractDetails_",
		LeasedAssetAccounting.DetailsOfLeaseAgreement(Object.Contract),
		FormServiceParameters);
	
EndProcedure

&AtServer
Procedure AmountOfRentalServicesWhenChangedOnServer()
	
	RecalculateContractAmountAndVATAmount(Object);
	ConfigureDependentFormElementsOnServer("LeaseServicesAmount");
	
EndProcedure

&AtServer
Procedure AmountOfRedemptionOfRentalItemsWhenChangingOnServer()

	RecalculateContractAmountAndVATAmount(Object);
	RecalculateAmountOfVATRepurchaseOfRentalItems(Object);

	ConfigureDependentFormElementsOnServer("AmountOfLeaseAssetsByuout");
	
EndProcedure

&AtServer
Procedure VATRateForChangesOnServer()
	
	RecalculateContractAmountAndVATAmount(Object);
	RecalculateAmountOfVATRepurchaseOfRentalItems(Object);
	
	Object.PresentValue = PresentValue(Object, FormServiceParameters.ContractDetails_);

	ConfigureDependentFormElementsOnServer("VATRate");
	
EndProcedure

#EndRegion

#Region RecalculationOfAmounts

&AtClientAtServerNoContext
Procedure RecalculateContractAmountAndVATAmount(Object)
	
	LeasedAssetAccountingClientServer.RecalculateAmountOfRentalDocument(Object);
	LeasedAssetAccountingClientServer.RecalculateAmountOfNDSInLeaseDocument(Object);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateAmountOfVATRepurchaseOfRentalItems(Object)
	
	CurPercentVAT = VATAccountingERPClientServer.ValueOfVATRate(Object.VATRate);
	Object.AmountOfVATRepurchaseOfRentalItems = VATAccountingERPClientServer.CalculateVATAmount(Object.AmountOfLeaseAssetsByuout, CurPercentVAT, True);
	
EndProcedure
	
#EndRegion

#Region Other

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("AssetHolder", Undefined);

	ParameterValue = NonCurrentAssets.VNAManagementIsUsed_2_4(Object.Date);
	NewServiceParametersOfForm.Insert("VNAManagementIsUsed_2_4", ParameterValue);

	ParameterValue = LeasedAssetAccounting.StartOfLeaseAccountingUnderFSB25_2018(Object.Organization);
	NewServiceParametersOfForm.Insert("StartOfLeaseAccountingUnderFSB25_2018", ParameterValue);

	ParameterValue = LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date);
	NewServiceParametersOfForm.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", ParameterValue);

	ParameterValue = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	NewServiceParametersOfForm.Insert("ComplianceCAAccountingIsKept", ParameterValue);
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	NewServiceParametersOfForm.Insert("CurrencyOfManPresentation", String(CurrencyOfMan));
	NewServiceParametersOfForm.Insert("ComplCurrencyPresentation", String(ComplCurrency));
	NewServiceParametersOfForm.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	NewServiceParametersOfForm.Insert("InsignificantVATRate", VATAccountingERP.InsignificantRate(Object.VATRate));
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

	AddContractDetailsToServiceParametersOfForm();
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	FillParameters = Documents.OBEntryOfLeaseSettlements.ParametersForFillingInVATTaxationPurchases(Object);
	VATAccountingERP.FillInListOfVATTaxChoices(
		Items.VATTaxation,
		Object.VATTaxation,
		FillParameters,
		VATAccountingCachedParameterValues);

	UpdatePurchaseForActivity();

	InitializeServiceParametersOfForm();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	InitializingFormWhenCreatingItOnServer();
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	UsePartnersAndCounterparties = GetFunctionalOption("UsePartnersAndCounterparties");
	Items.Counterparty.Visible = UsePartnersAndCounterparties;
	
	TheCounterpartyPriorToTheChange = Object.Counterparty;
	PartnerBeforeTheChange = Object.Partner;
	
	UpdateDetailsValuesBeforeChange(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure TaxationOfVATWhenChangingOnServer()
	
	FillInVATRate();
	RecalculateContractAmountAndVATAmount(Object);

	ConfigureDependentFormElementsOnServer("VATTaxation,VATRate");	
	
EndProcedure

&AtServer
Procedure UpdatePurchaseForActivity()
	
	FillParameters = Documents.OBEntryOfLeaseSettlements.ParametersForFillingInVATActivityType(Object);
	
	VATAccountingERP.FillInTypeOfActivityVAT(
		Object.PurchaseForActivity, 
		FillParameters,
		VATAccountingCachedParameterValues);
	
EndProcedure

&AtServer
Procedure FillInVATRate()
	
	If Object.VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT
		Or Object.VATTaxation = Enums.VATTaxationTypes.VATTaxAgent Then
		Object.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
	Else
		Object.VATRate = VATAccountingERP.DefaultVATRate(Object.Organization, Object.Date);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenPaymentAndAccrualSchedule(ChartName)
	
	LeasedAssetAccountingClient.OpenPaymentAndAccrualSchedule(
		Object, 
		ThisObject, 
		PutGraphsInTemporaryStorage(), 
		New CallbackDescription("OpenPaymentAndAccrualScheduleCompletion", ThisObject), 
		ChartName);
		
EndProcedure

&AtServer
Function PutGraphsInTemporaryStorage()

	ContractSchedules = New Structure;
	ContractSchedules.Insert("ServiceAccrualSchedule", Object.ServiceAccrualSchedule.Unload());
	ContractSchedules.Insert("ServicePaymentSchedule", Object.ServicePaymentSchedule.Unload());
	ContractSchedules.Insert("InterestAccrualSchedule", Object.InterestAccrualSchedule.Unload());

	Address = PutToTempStorage(ContractSchedules, AddressOfTheContractSchedule);
		
	Return Address;
	
EndFunction

&AtClient
Procedure OpenPaymentAndAccrualScheduleCompletion(ClosingResult, AddlParameters) Export

	If IsTempStorageURL(ClosingResult) Then
		OpenPaymentAndAccrualScheduleDirectlyOnServer(ClosingResult);
	EndIf;

EndProcedure

&AtServer
Procedure OpenPaymentAndAccrualScheduleDirectlyOnServer(Val ClosingResult)
	
	Modified = True;

	ContractSchedules = GetFromTempStorage(ClosingResult);

	Object.TheInterestAccrualScheduleIsEnteredManually = ContractSchedules.TheInterestAccrualScheduleIsEnteredManually;
	Object.InterestAmount = ContractSchedules.InterestAmount;
	Object.ServicePaymentSchedule.Load(ContractSchedules.ServicePaymentSchedule);
	Object.ServiceAccrualSchedule.Load(ContractSchedules.ServiceAccrualSchedule);
	Object.InterestAccrualSchedule.Load(ContractSchedules.InterestAccrualSchedule);
	
	LeasedAssetAccountingClientServer.RecalculateAmountOfNDSInLeaseDocument(Object);

	Object.PresentValue = PresentValue(Object, FormServiceParameters.ContractDetails_);

	ConfigureDependentFormElementsOnServer(
		"ServicePaymentSchedule,ServiceAccrualSchedule,InterestAccrualSchedule,TheInterestAccrualScheduleIsEnteredManually");
	
EndProcedure

&AtServer
Procedure CalculateRateCostPercentagesOnServer()

	Documents.OBEntryOfLeaseSettlements.CalculateRateCostInterest(Object, FormServiceParameters.ContractDetails_);
		
	ConfigureDependentFormElementsOnServer("FAFairValue");
			
EndProcedure

&AtClient
Procedure FillInScheduleAccordingToCalculations()
	
	If (Object.PaymentFrequency = PredefinedValue("Enum.ScheduleTimeFence.Custom")
			Or Not ValueIsFilled(Object.PaymentFrequency))
		And (Object.AccrualFrequency = PredefinedValue("Enum.ScheduleTimeFence.Custom")
			Or Not ValueIsFilled(Object.AccrualFrequency)) Then
				
		Return;
	EndIf;
	
	If LeasedAssetAccountingClient.CheckAbilityToFillInScheduleByCalculations(Object, FormServiceParameters.ContractDetails_) Then
		
		CalculateTheBidOrCost = LeasedAssetAccountingClient.YouCanCalculateRateOrCost(
			Object, FormServiceParameters.ContractDetails_, "", False);
		
		FillInScheduleForCalculationsOnServer(CalculateTheBidOrCost);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInScheduleForCalculationsOnServer(Val CalculateTheBidOrCost)
	
	Modified = True;
	
	LeasedAssetAccounting.FillInScheduleOfPaymentsAndChargesForSettlements(Object, FormServiceParameters.ContractDetails_);
	
	Object.PresentValue = PresentValue(Object, FormServiceParameters.ContractDetails_);

	If CalculateTheBidOrCost Then
		CalculateRateCostPercentagesOnServer();
	EndIf;
	
	LeaseTermHasBeenChanged = False;
	
	ConfigureDependentFormElementsOnServer("ServicePaymentSchedule,ServiceAccrualSchedule");
	
EndProcedure

&AtServer
Procedure FillInCalculationsAccordingToSchedule()
	
	Modified = True;

	LeasedAssetAccounting.FillInCalculationsAccordingToScheduleOfPaymentsAndAccruals(Object, FormServiceParameters.ContractDetails_);
	
	ChangedBankingDetails = 
	"SecurityDepositAmount,DateOfFirstSecurityPayment,
	|LeaseServicesAmount,DateOfFirstPayment,
	|AmountOfLeaseAssetsByuout,AmountOfVATRepurchaseOfRentalItems,
	|VATAmount,
	|PaymentFrequency,PaymentForLeaseService,
	|AccrualFrequency,AccrualOfLeaseService";

	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure ChangeDocumentVersion()
	
	QueryText = NStr("vi = 'Sau khi thay đổi phiên bản chứng từ, một số mục tin sẽ bắt buộc điền.
						|Không thể quay lại phiên bản cũ của chứng từ.
						|Tiếp tục?';
						|ru = 'После изменения версии документа некоторые реквизиты будут обязательны для заполнения.
						|Вернуться к старой версии документа будет невозможно. 
						|Продолжить?';
						|en = 'Some attributes will become mandatory after changing the document version.
						|It will be impossible to return to the old version of the document.
						|Continue?'; fa = 'Some attributes will become mandatory after changing the document version.
						|It will be impossible to return to the old version of the document.
						|Continue?';
						|it = 'Dopo la modifica della versione del documento, alcuni attributi diventeranno obbligatori per la compilazione. 
						|Sarà impossibile tornare alla vecchia versione del documento,
						| continuare?';
						|pl = 'Po zmianie wersji dokumentu niektóre atrybuty będą obowiązkowe do wypełnienia.
						|Powrócić do starej wersji dokumentu będzie niemożliwe. 
						|Kontynuować?';
						|tr = 'Belge sürümünü değiştirdikten sonra bazı öznitelikler zorunlu olacaktır.
						|Belgenin eski sürümüne dönmek mümkün olmayacaktır.
						| Devam edilsin mi?'");
	CallbackDescription = New CallbackDescription("ChangeDocumentVersionCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ChangeDocumentVersionCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Modified = True;
		Object.DocumentVersion24 = False;
		ConfigureDependentFormElements("DocumentVersion24");
	EndIf;
	
EndProcedure

&AtClient
Procedure EnterLeaseTermCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined 
		Or TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;

	ConfigureDependentFormElements("LeaseStartDate,TermYears,TermMonths,TermDays");
	
EndProcedure

&AtClientAtServerNoContext
Function PresentValue(Object, ContractDetails_)

	LeaseItemsCost = LeasedAssetAccountingClientServer.LeaseItemsCost(
		Object, ContractDetails_, "");
	
	PresentValue = LeasedAssetAccountingClientServer.PresentValue(
									LeaseItemsCost, 
									Object.ServicePaymentSchedule, 
									Object.LeaseStartDate);
	Return PresentValue;
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateDetailsValuesBeforeChange(Form)

	AttributesList = 
	"LeaseObligationsBalance,LeaseLiabilityBalanceLocal,LeaseLiabilityBalanceMan,
	|RentalServiceBalance,RentalServiceBalanceLocal,RentalServiceBalanceMan,
	|BuyoutValueBalance,BuyoutValueBalanceLocal,BuyoutValueBalanceMan,
	|VATBalance,VATBalanceLocal,VATBalanceMan,
	|InterestsBalance,InterestBalanceLocal,InterestBalanceMan";
	
	NewValues = New Structure(AttributesList);
	FillPropertyValues(NewValues, Form);
	
	Form.AttributesValuesBeforeChange = New FixedStructure(NewValues);
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, NotificationParameters) Export
	
	If NotificationParameters.ServerCallRequired_ Then
		WhenExecutingEndCommandOnServer(CommandName, NotificationParameters.ProcessingParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenExecutingEndCommandOnServer(Val CommandName, Val AdditionalParameters)
	
	OBEntryOfLeaseSettlementsLocalization.OnExecuteCommand(CommandName, ThisObject);
	
EndProcedure

#EndRegion

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
	ElsIf Item.Name = "sh_ShamsiInput_DateOfFirstSecurityPayment" Then
		DateOfFirstSecurityPaymentOnChange(Items.DateOfFirstSecurityPayment);
	ElsIf Item.Name = "sh_ShamsiInput_DateOfFirstPayment" Then
		DateOfFirstPaymentOnChange(Items.DateOfFirstPayment);
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
