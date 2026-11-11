
#Region Variables

//used by the mechanism for processing changes in PM details
&AtClient
Var CachedValues;


&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// Handler of the "Versioning of objects" mechanism
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	GeneratingFiscalChecksServer.FormWhenCreatedOnServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		
		If Parameters.Property("Basis") Then
			Basis = Parameters.Basis;
		EndIf;
	EndIf;
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisForm);
	GeneratingFiscalChecksServer.FormWhenCreatedOnServer(ThisObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.PaymentCardTransaction.ItemsAndDimensionsSelectionParameters(
		Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	Items.DecryptionWithoutSplittingRepaymentDate.ReadOnly = Not AccessRight(
		"Edit",
		Metadata.Documents.PaymentCardTransaction.TabularSections.ARAPDetails.Attributes.MaturityDate);
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not ValueIsFilled(Object.Ref) Then
		FinancesClient.CheckDocumentCompletionBasedOn(Object, Basis);
	EndIf;
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
	If TypeOf(SelectionResult) = Type("DocumentRef.PaymentCardTransaction") Then
		
		ProcessingDocumentSelectionViaServer(SelectionResult);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	GeneratingFiscalChecksServer.FormWhenReadingOnServer(ThisObject);
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.PaymentCardTransaction.ItemsAndDimensionsSelectionParameters(
		Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisObject, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	If Object.DocumentAmount = 0 Then
		Object.DocumentAmount = Object.ARAPDetails.Total("Sum");
	EndIf;
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting Then
		
		Cancel = True;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("WriteParameters", WriteParameters);
		
		FinancesClient.RecalculateAmountOfDocumentBasedOnPaymentDecryption(
			ThisForm,
			New CallbackDescription("BeforeRecordingOfferToRecalculateAmountOfDocument", ThisObject, AdditionalParameters));
		Return;
		
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtClient
Procedure BeforeRecordingOfferToRecalculateAmountOfDocument(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult Then
		TMCommonUseClient.RecordObjectIfNecessary(ThisObject, AdditionalParameters.WriteParameters,,True);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("NotificationDocumentKeys", OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Object.BusinessOperation));
	Notify("Write_PaymentCardTransaction", WriteParameters, Object.Ref);
	ARAPAccountingClient.FormAfterRecording(ThisForm);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisForm, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrectionClient.AfterWrite(Object);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
	ARAPAccountingServer.BeforeWriteAtServer(ThisForm, CurrentObject);
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

	ARAPAccountingFormWork.FormAfterRecordingOnServer(ThisForm, CurrentObject.AdditionalProperties);
	
	FillInParametersOfCalculationObjectInDecryption();
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CompleteVATTaxation(False);
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	
	If EventName = "GiftCertificateIsRead"
		And Parameter.OwnerForm = UUID Then
		
		ProcessGiftCertificate(Parameter.GiftCertificate);
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	
	Return;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckCompletionOfCommissionArticle = (Object.RecordCommission And Object.FeeAmount <> 0
		And Not Object.KeepRecordsOfCommissionInARAPAccounting);
		
	PerformVerificationOfFillingOutContractOfCommission = (Object.RecordCommission And Object.FeeAmount <> 0
		And Object.KeepRecordsOfCommissionInARAPAccounting);
	
	ItemsAndDimensionsSelectionParameters = Documents.PaymentCardTransaction.ItemsAndDimensionsSelectionParameters(
		CheckCompletionOfCommissionArticle);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	ExcludeVerificationOfFillingInARAPObjectOfFee = False;
	If Not PerformVerificationOfFillingOutContractOfCommission Then
		NotCheckedAttributeArray.Add("CommissionAgreement");
		ExcludeVerificationOfFillingInARAPObjectOfFee = True;
	EndIf;
	
	If Not ValueIsFilled(CommissionAgreement) Then
		ExcludeVerificationOfFillingInARAPObjectOfFee = True; 
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not DecryptionSwitch Then
		DocumentObject = FormAttributeToValue("Object");
		DocumentObject.AdditionalProperties.Insert("ExplanationWithoutSplit", True);
		
		If ExcludeVerificationOfFillingInARAPObjectOfFee Then
			DocumentObject.AdditionalProperties.Insert("ExcludeVerificationOfFillingInARAPObjectOfFee", True);
		EndIf;
		
		If Not DocumentObject.CheckFilling() Then
			Cancel = True;
		EndIf;
		
		ObjectAttributesToBeChecked = CheckedAttributes.Find("Object");
		If ObjectAttributesToBeChecked <> Undefined Then
			CheckedAttributes.Delete(ObjectAttributesToBeChecked);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	
	DateOfChangeOnServer();
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	CompleteVATTaxation();
	
	FillInCourseCourseDenominatorOfSettlements();
	CalculateAmountOfSettlements_();
	FillMultiplicityCourseWithText();
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure BusinessOperationOnChange(Item)
	
	BusinessOperationOnChangeServer();
	
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtServer
Procedure BusinessOperationOnChangeServer()
	
	CFItemByBT =
		Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Object.BusinessOperation);
	Object.CashFlowItem = CFItemByBT;
	For Each PaymentDecryptionString In Object.ARAPDetails Do
		PaymentDecryptionString.CashFlowItem = CFItemByBT;
	EndDo;
	
	ArrayOfAllProps = New Array; ArrayOfOperationDetails = New Array;
	Documents.PaymentCardTransaction.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails);
	
	If ArrayOfOperationDetails.Find("ARAPDetails") <> Undefined Then
		If ArrayOfOperationDetails.Find("ARAPDetails.MaturityDate") = Undefined Then
			For Each DecryptionString In Object.ARAPDetails Do
				DecryptionString.MaturityDate = Date(1 , 1 ,1);
			EndDo;
		EndIf;
	EndIf;
	
	GetDefaultContractServer();
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisForm);
	
	If ValueIsFilled(Object.AcquiringContract) Then
		
		AttributesValues = DetailsOfAcquiringAgreement(Object.AcquiringContract);
		
		If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
			Object.RecordCommission = (AttributesValues.CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.DuringTransaction);
		ElsIf Object.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
			Object.RecordCommission = (AttributesValues.CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.DuringTransaction)
				And AttributesValues.FeeIsChargedOnRefund;
		EndIf;
	EndIf;
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure BaseDocumentPresentationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		
		ShowValue(Undefined, Object.DocumentBasis);
		
	Else
		
		TypesList = New ValueList;
		BasisType = TypeOf(Object.DocumentBasis);
		If Not BasisType = Type("Undefined") Then
			TypesList.Add(BasisType);
		ElsIf Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToCustomer") Then
			TypesList.Add(Type("DocumentRef.PaymentCardTransaction"));
		EndIf;
		
		StructureFilter = New Structure;
		StructureFilter.Insert("Posted", True);
		StructureFilter.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.CashReceiptFromCustomer"));
		
		ChoiceFormName = "Document.PaymentCardTransaction.ChoiceForm";
		
		OpenForm(
			ChoiceFormName,
			New Structure("Filter", StructureFilter),
			ThisForm);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CounterpartyOnChange(Item)
	
	If ValueIsFilled(Object.Counterparty) Then
		CounterpartyOnChangeServer();
	EndIf;
	
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, "Counterparty");
	CashServer.SetApplicationSelectionParameters(Object, Items.PaymentRequest);
	
	If CurrentCounterparty <> Object.Counterparty Then
		CashServer.ClearApplicationForSpendingMoney(Object, False);
	EndIf;

	If ValueIsFilled(Object.Counterparty) Then
		
		Partner = CashServer.GetCounterpartyPartner(Object.Counterparty, Object.BusinessOperation);
		GetDefaultContractServer();
		
		If ValueIsFilled(CounterpartyContract) Then
			ARAPObjectContract = ARAPObjectsServer.GetCalculationObjectFromLink(CounterpartyContract)
		EndIf;
		
		For Each TSRow In Object.ARAPDetails Do
			TSRow.Partner = Partner;
			If ValueIsFilled(CounterpartyContract) Then
				TSRow.PaymentPurpose = CounterpartyContract;
				TSRow.ARAPObject = ARAPObjectContract;
				TSRow.CashFlowItem = Object.CashFlowItem;
				TSRow.VATRate = VATRate;
				TSRow.ARAPCurrency = ARAPCurrency;
				FillInCourseAndMultiplicityInDecryptionLine(TSRow);
				CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
					TSRow, Object.Currency, CurrencyOfComplianceAccounting);
				CashServer.FormCourseDenominatorByText(TSRow, Object.Currency, CurrencyOfComplianceAccounting);
				FillInCurrencyOfMutualSettlementsOfDocument();
				DecryptionOfTheCalculationObjectWhenChangingServer(TSRow.GetID());
			EndIf;
		EndDo;
	EndIf;
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
	PaymentCardTransactionLocalization.SetVisibilityOfGiftCertificateSelectionButton(ThisObject);
	
	If Not DecryptionSwitch Then
		SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	EndIf;
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
	CurrentCounterparty = Object.Counterparty;
	
EndProcedure

&AtClient
Procedure AcquiringContractOnChange(Item)
	
	AttributesValues = DetailsOfAcquiringAgreement(Object.AcquiringContract);
	
	If Not FinancesClient.CurrencyConversionRequired(Object, Object.Currency, AttributesValues.Currency) Then
		
		AcquiringAgreementInCaseOfChangesOnServer(AttributesValues, False);
	Else
		
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tính lại số tiền trong chứng từ theo tiền tệ %1?';
				|ru = 'Пересчитать суммы в документе в валюту %1?';
				|en = 'Convert amounts in the document in %1?'; fa = 'Convert amounts in the document in %1?';
				|it = 'Ricalcolare gli importi del documento in valuta %1?';
				|pl = 'Przeliczyć kwoty w dokumencie na walutę %1?';
				|tr = 'Belgedeki tutarlar %1 para birimine göre yeniden hesaplansın mı?'"), AttributesValues.Currency);
		
		QuestionDialogButtons = New ValueList;
		QuestionDialogButtons.Add(DialogReturnCode.Yes, NStr("vi = 'Tính lại';
															|ru = 'Пересчитать';
															|en = 'Recalculate'; fa = 'محاسبه مجدد';
															|it = 'Ricalcolare';
															|pl = 'Recalculate';
															|tr = 'Yeniden hesapla'"));
		QuestionDialogButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
																|ru = 'Отменить';
																|en = 'Cancel'; fa = 'انصراف';
																|it = 'Annullare';
																|pl = 'Cancel';
																|tr = 'İptal et'"));
		
		CallbackDescription = New CallbackDescription(
			"CurrencyConversionAllowed", ThisObject, New Structure("AttributesValues", AttributesValues));
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogButtons);
	EndIf;
	
EndProcedure

&AtServer
Procedure AcquiringAgreementInCaseOfChangesOnServer(AttributesValues, AmountsRecalculate)
	
	CurrentAcquiringAgreement = Object.AcquiringContract;
	
	MakingPaymentMethod = Enums.MakingPaymentMethods.EmptyRef();
	If ValueIsFilled(Object.AcquiringContract) Then
		MakingPaymentMethod = Common.ObjectAttributeValue(Object.AcquiringContract, Metadata.Catalogs.AcquiringContracts.Attributes.MakingPaymentMethod.Name);
	EndIf;
	
	CurrencyChanged_1 = (Object.Currency <> AttributesValues.Currency);
	Object.Organization = AttributesValues.Organization;
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	If ValueIsFilled(Object.AcquiringContract) Then
		BranchesOfOrganization.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(Object.Organization));
	Else
		BranchesOfOrganization.Clear();
	EndIf;
	
	POSTerminalsAreUsed = AttributesValues.POSTerminalsAreUsed;
	If POSTerminalsAreUsed Then
		Object.POSTerminal = Catalogs.POSTerminals.DefaultPOSTerminal(, CurrentAcquiringAgreement);
	Else
		Object.POSTerminal = Undefined;
	EndIf;
	
	EnabledCreatingCashIssueWithoutPaymentRequest = AttributesValues.EnableCreatingCashIssueWithoutPaymentRequest;
	If ValueIsFilled(Object.POSTerminal) Then
		EnabledCreatingCashIssueWithoutPaymentRequest =
			Common.ObjectAttributeValue(Object.POSTerminal, "EnableCreatingCashIssueWithoutPaymentRequest");
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
		Object.RecordCommission = (AttributesValues.CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.DuringTransaction);
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
		Object.RecordCommission = (AttributesValues.CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.DuringTransaction)
			And AttributesValues.FeeIsChargedOnRefund;
	EndIf;
	
	If Object.RecordCommission Then
		
		If AttributesValues.FixedFeeRate Then
			CommissionRate = AttributesValues.CommissionRate;
			Object.FeeAmount = CashClientServer.CalculateCommissionAmount(Object.DocumentAmount, CommissionRate);
		Else
			CommissionRate = 0;
		EndIf;
		
		Object.ExpenseItem    = AttributesValues.ExpenseItem;
		Object.DimensionOfExpenses = AttributesValues.DimensionOfExpenses;
		Object.Department     = AttributesValues.ExpensesBusinessUnit;
		Object.KeepRecordsOfCommissionInARAPAccounting = AttributesValues.KeepRecordsOfCommissionInARAPAccounting;
		Object.CommissionARAPObject = AttributesValues.CommissionARAPObject;
		CommissionAgreement = Common.ObjectAttributeValue(Object.CommissionARAPObject, "Contract");
	Else
		Object.FeeAmount = 0;
		Object.KeepRecordsOfCommissionInARAPAccounting = False;
		Object.CommissionARAPObject = Catalogs.ARAPObjects.EmptyRef();
		CommissionAgreement = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	KeepRecordsOfCommissionInMutualSettlementsSwitch = Object.KeepRecordsOfCommissionInARAPAccounting;
	
	AttributesArray = New Array;
	
	If ValueIsFilled(CurrentAcquiringAgreement) Then
		If Object.Organization <> AttributesValues.Organization Then
			AttributesArray.Add("Organization");
		EndIf;
		FillPropertyValues(Object, AttributesValues, "Organization");
		GetDefaultContractServer();
	EndIf;
	
	If CurrencyChanged_1 Then
		AttributesArray.Add("Currency");
	EndIf;
	
	CurrentCurrency = Object.Currency;
	Object.Currency = AttributesValues.Currency;
	
	If AmountsRecalculate Then
		CashServer.ConversionOfDocumentAmountsIntoCurrency(Object, CurrentCurrency, Object.Currency);
		VATConversionParameters = New Structure("PriceIncludesVAT", True);
		StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
		BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	EndIf;
	
	For Each TSRow In Object.ARAPDetails Do
		If Not ValueIsFilled(TSRow.ARAPObject) Then
			TSRow.AmountARAP = TSRow.Sum;
			TSRow.ARAPCurrency = Object.Currency;
			TSRow.ExchangeRateNumeratorOfMutualSettlements = 1;
			TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
		ElsIf CurrencyChanged_1 Then
			CashServer.CalculateExchangeRateNumeratorOfMutualSettlementsInDecryptionLine(TSRow, Object.Currency, CurrencyOfComplianceAccounting);
			CalculateAmountOfSettlements_();
		EndIf;
	EndDo;
	
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	If CurrencyChanged_1 Then
		UpdateAmountUnallocated();
		GenerateHyperlinkCaptionPaymentObjectDetails();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.PaymentCardTransaction.ItemsAndDimensionsSelectionParameters(
		Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
	
	FormItemsManagement();
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisForm, AttributesArray);
	
EndProcedure

&AtClient
Procedure POSTerminalOnChange(Item)
	POSTerminalOnChangeServer();
EndProcedure

&AtServer
Procedure POSTerminalOnChangeServer()
	GeneratingFiscalChecksServer.FormWhenChangingBankingDetails(ThisObject);
EndProcedure

&AtClient
Procedure DocumentAmountOnChange(Item)
	
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, Object.DocumentAmount, False);
	DocumentAmountOnChangeServer();
	
EndProcedure

&AtServer
Procedure DocumentAmountOnChangeServer()
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	
	If Object.RecordCommission Then
		Object.FeeAmount = CashClientServer.CalculateCommissionAmount(Object.DocumentAmount, CommissionRate);
		Items.GroupCommission.Title = NStr("vi = 'Phí ngân hàng';
											|ru = 'Комиссия';
											|en = 'Fee'; fa = 'کارمزد';
											|it = 'Commissione';
											|pl = 'Prowizja';
											|tr = 'Komisyon'") +
			" " + String(Object.FeeAmount) + " " + String(Object.Currency) + " " + String(CommissionRate) + "%";
	EndIf;
	
	CalculateAmountOfSettlements_();
	FillInCurrencyOfMutualSettlementsOfDocument();
	
EndProcedure

&AtClient
Procedure FeeAmountOnChange(Item)
	
	If Object.DocumentAmount <> 0 Then
		CommissionRate = CashClientServer.CalculateCommissionRate(Object.DocumentAmount, Object.FeeAmount);
	Else
		CommissionRate = 0;
	EndIf;
	Items.GroupCommission.Title = NStr("vi = 'Phí ngân hàng';
										|ru = 'Комиссия';
										|en = 'Fee'; fa = 'کارمزد';
										|it = 'Commissione';
										|pl = 'Prowizja';
										|tr = 'Komisyon'") +
		" " + String(Object.FeeAmount) + " " + String(Object.Currency) + " " + String(CommissionRate) + "%";
	
EndProcedure

&AtClient
Procedure CurrencyConversionAllowed(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CurrentCurrency = Object.Currency;
		If CurrentCurrency <> AdditionalParameters.AttributesValues.Currency Then
			FinancesClient.ClearAmountAndCurrencyOfSettlementsPaymentDecryption(Object);
		EndIf;
		AcquiringAgreementInCaseOfChangesOnServer(AdditionalParameters.AttributesValues, True);
		PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(CurrentCurrency, Object.Currency);
	Else
		Object.AcquiringContract = CurrentAcquiringAgreement;
	EndIf;
	
EndProcedure

&AtClient
Procedure PaymentRequestOnChange(Item)
	
	If ValueIsFilled(Object.PaymentRequest) Then
		PaymentRequestOnChangeServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure PaymentRequestOnChangeServer()
	
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.Fill(Object.PaymentRequest);
	ValueToFormAttribute(DocumentObject, "Object");
	
	ManagingFormElementsDependentOnFoundationDocument();
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	If CurrentPage = Items.TheDecryptionPage And Not DecryptionSwitch And Not ReadOnly Then
		ARAPDetailsOnStartEdit(Item, False, False);
	EndIf;
	
EndProcedure

&AtClient
Procedure HyperlinkPaymentObjectDetailsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	BlockData_();
	
	CallbackDescription = New CallbackDescription("HyperlinkPaymentObjectDetailsClickCompletion", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("BusinessOperation", Object.BusinessOperation);
	FormParameters.Insert("Counterparty",            Object.Counterparty);
	
	FormParameters.Insert("FinancialAccountingGroup",  Object.FinancialAccountingGroup);
	FormParameters.Insert("LineOfBusiness", Object.LineOfBusiness);
	FormParameters.Insert("Contract",                 Object.Contract);
	FormParameters.Insert("Organization",             Object.Organization);
	FormParameters.Insert("Department",           Object.Department);
	FormParameters.Insert("VATTaxation",      Object.VATTaxation);
	FormParameters.Insert("ListOfVATTaxes",Items.DecodingWithoutSplittingVATTaxation.ChoiceList);
	FormParameters.Insert("DocumentRef", Object.Ref);
	FormParameters.Insert("AddressInTempStorage", PlaceDecryptionInTemporaryStorage());

	OpenForm("CommonForm.FormForSelectionOfPaymentARAPObjectDetails",
		FormParameters,
		ThisForm,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure HyperlinkPaymentObjectDetailsClickCompletion(Result, AdditionalParameters) Export
	
	UnlockData();
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Object.FinancialAccountingGroup  = Result.FinancialAccountingGroup;
	Object.LineOfBusiness = Result.LineOfBusiness;
	Object.Contract                 = Result.Contract;
	Object.Department           = Result.Department;
	ThereIsChangeInVATTaxation = ?(Object.VATTaxation = Result.VATTaxation, False, True);
	HyperlinkDetailsOfSettlementObjectClickEndOnServer();
	If ThereIsChangeInVATTaxation Then
		Object.VATTaxation = Result.VATTaxation;
		CompleteVATTaxation();
	EndIf;
	
EndProcedure

&AtServer
Procedure HyperlinkDetailsOfSettlementObjectClickEndOnServer()

	ModifiedRows = CashServer.CheckFillInARAPObject(Object);
	
	For Each IndexOf In ModifiedRows Do
		DecryptionString = Object.ARAPDetails[IndexOf]; 
		CashServer.CheckFillOutContract(Object, DecryptionString.GetID());
		CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, DecryptionString.GetID(), True);
		FillInCourseAndMultiplicityInDecryptionLine(DecryptionString);
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
		YouAreAllowedToWorkWithAffiliatedPartners(DecryptionString);
	EndDo;
	
	If ValueIsFilled(Object.Contract) Then
		
		ContractDetails_ = Undefined;
		CashServer.FillInDataOfDocumentFormByContract(ThisObject, ContractDetails_);
		
		For Each DecryptionString In Object.ARAPDetails Do
			
			If (Not ValueIsFilled(DecryptionString.ARAPObject)
				Or DecryptionString.CalculationObject = Object.Ref) Then
				FillInPaymentDecryptionLineUnderContract(DecryptionString, ContractDetails_);
			EndIf;
			
		EndDo;
		
		FillInCurrencyOfMutualSettlementsOfDocument();
		
		StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
		BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
		
	Else
		CashServer.ClearPaymentDecryptionContract(Object);
	EndIf;
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();

EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	AgreementWhenModifiedOnServer();
	
EndProcedure

&AtServer
Procedure AgreementWhenModifiedOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	ClearCalculationObject(CurrentRow);
	
	If ValueIsFilled(Object.Contract) Then
		
		ContractDetails_ = Undefined;
		CashServer.FillInDataOfDocumentFormByContract(ThisObject, ContractDetails_);

		If CommonClientServer.HasAttributeOrObjectProperty(ContractDetails_, "FinancialAccountingGroup") Then
			Object.FinancialAccountingGroup = ContractDetails_.FinancialAccountingGroup;
		EndIf;

		If CommonClientServer.HasAttributeOrObjectProperty(ContractDetails_, "LineOfBusiness") Then
			Object.LineOfBusiness = CashServer.LineOfBusiness(
				Object.BusinessOperation,
				ContractDetails_.LineOfBusiness);
		EndIf;

		FillInPaymentDecryptionLineUnderContract(CurrentRow, ContractDetails_);
		FillInCurrencyOfMutualSettlementsOfDocument();
		
	EndIf;
	
	CashServer.CheckFillInARAPObject(Object, Items.ARAPDetails.CurrentRow);
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
	
	CompleteVATTaxation();
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
	StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure SettlementObjectContractStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("DeletionMark", False);
	
	StructureOfSelectionParameters = New Structure;
	StructureOfSelectionParameters.Insert("ChoiceMode", True);
	StructureOfSelectionParameters.Insert("AllowSelectionOfBranchContracts", True);
	StructureOfSelectionParameters.Insert("Partner", Partner);
	StructureOfSelectionParameters.Insert("Counterparty", Object.Counterparty);
	StructureOfSelectionParameters.Insert("Organization", Object.Organization);
	
	FilterStructure1.Insert("Counterparty", Object.Counterparty);
	
	If FinancesClient.TheseAreSettlementsWithCustomers(Object.BusinessOperation) Then
		ContractTypes = ARAPAccountingClientServer.TypesOfContractsWithClient();
	Else
		ContractTypes = ARAPAccountingClientServer.TypesOfContractsWithSupplier();
	EndIf;
	
	ContractTypes.Add(PredefinedValue("Enum.ContractTypes.WithConsignor"));
	
	FilterStructure1.Insert("ContractType", New FixedArray(ContractTypes.UnloadValues()));
	FilterStructure1.Insert("Partner", Partner);
	StructureOfSelectionParameters.Insert("ShowSalesThroughCommissionAgent", True);
	
	StructureOfSelectionParameters.Insert("Filter",FilterStructure1);
	OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm",
		StructureOfSelectionParameters,
		Item,
		Item,)
	
EndProcedure

&AtClient
Procedure FiscalOperationStatusURLProcessing(Item, Var_URL, StandardProcessing)
	
	GeneratingFiscalChecksClient.FiscalOperationNavigationLinkProcessing(
		ThisObject, Var_URL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure FiscalTransactionCompletion(Result, AdditionalParameters) Export
	
	FiscalOperationCompletionOnServer();
	
EndProcedure

&AtServer
Procedure FiscalOperationCompletionOnServer()
	
	GeneratingFiscalChecksServer.UpdateFiscalCheckBreakdownHyperlink(Object.Ref, ThisObject, FiscalOperationStatus);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpenseItemStartListChoice(Item, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesOnChange(Item)
	IncomeAndExpensesClientServer.DimensionOfExpensesOnChange(ThisObject, Item);
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(ThisObject, FormattedStringURL, StandardProcessing);		
EndProcedure

&AtClient
Procedure CurrencyDecorationAndPaymentRateClick(Item, StandardProcessing)
	
	Notification = New CallbackDescription("CurrencyDecorationAndPaymentRateClickCompletion", ThisObject);
	ARAPAccountingClient.CurrencyAndExchangeRateOfDocument(ThisForm, Item, StandardProcessing, Notification);
	
EndProcedure

&AtClient
Procedure CurrencyDecorationAndPaymentRateClickCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FinancesClientServer.RecalculateAmountsInPaymentDecryptionLine(Object, Object.DocumentAmount, False);
	CurrencyDecorationAndPaymentRateClickFinishOnServer();
	
EndProcedure

&AtServer
Procedure CurrencyDecorationAndPaymentRateClickFinishOnServer()
	
	DocumentAmountOnChangeServer();
	FillMultiplicityCourseWithText();
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	VATConversionParameters = New Structure("PriceIncludesVAT", True);
	StructureOfActions = New Structure("RecalculateVATAmount", VATConversionParameters);
	BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure FPSPaymentIDOnChange(Item)
	ClearMessages();
	PaymentIdOfSBPWhenChangedOnServer();
EndProcedure

&AtServer
Procedure PaymentIdOfSBPWhenChangedOnServer()
	PaymentCardTransactionLocalization.FormItemsManagement(ThisObject);
EndProcedure

&AtClient
Procedure LineOfBusinessOnChange(Item)

	DirectionOfActivityWhenChangingOnServer();

EndProcedure

&AtClient
Procedure FinancialAccountingGroupOnChange(Item)

	FinancialAccountingGroupOnChangeAtServer();

EndProcedure

&AtClient
Procedure DecryptionWithoutPartitioningPartnerOnChange(Item)

	ARAPDetailsPartnerOnChangeAtServer();

EndProcedure

&AtClient
Procedure CommissionAgreementOnChange(Item)
	
	ContractFeesOnChangesATServer();
	
EndProcedure

&AtClient
Procedure CommissionAgreementStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	DetailsOfAcquiringAgreement = DetailsOfAcquiringAgreement(Object.AcquiringContract);
	
	FilterValues = New Structure;
	FilterValues.Insert("Organization", Object.Organization);
	FilterValues.Insert("ARAPCurrency", Object.Currency);
	FilterValues.Insert("Partner", DetailsOfAcquiringAgreement.Partner);
	FilterValues.Insert("Counterparty", DetailsOfAcquiringAgreement.Acquirer);
	FilterValues.Insert("ARAPObjectSettings", PredefinedValue("Enum.ARAPObjectSettings.ByCounterpartyContracts"));
	
	StructureOfSelectionParameters = New Structure;
	StructureOfSelectionParameters.Insert("ChoiceMode", True);
	StructureOfSelectionParameters.Insert("ContractTypes", ARAPAccountingClientServer.TypesOfContractsWithSupplier());
	StructureOfSelectionParameters.Insert("Filter", FilterValues);
	
	OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm", StructureOfSelectionParameters, Item, Item);
	
EndProcedure

&AtClient
Procedure KeepRecordsOfCommissionInMutualSettlementsSwitchOnChange(Item)
	
	KeepRecordsOfCommissionInMutualSettlementsSwitchOnChangesAtServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersARAPDetails

&AtClient
Procedure DecryptionSwitchOnChange(Item)
	
	If Not DecryptionSwitch Then
		If Object.ARAPDetails.Count() = 0 Then
			Object.ARAPDetails.Add();
			Items.ARAPDetails.CurrentRow = Object.ARAPDetails[0].GetID();
			ARAPDetailsOnStartEdit(Items.ARAPDetails, True, False);
		ElsIf Object.ARAPDetails.Count() = 1 Then
			If Items.ARAPDetails.CurrentRow = Undefined Then
				Items.ARAPDetails.CurrentRow = Object.ARAPDetails[0].GetID();
			EndIf;
		ElsIf Object.ARAPDetails.Count() > 1 Then
			ClearMessages();
			MessageText = NStr("vi = 'Chuyển sang chế độ không phân chia là không thể nếu có nhiều hơn một dòng được nhập vào giải mã thanh toán!';
								|ru = 'Переключение в режим без разбиения невозможно, если в расшифровке платежа введено более одной строки!';
								|en = 'Cannot switch to no-split mode if multiple lines are entered into the payment details.'; fa = 'Cannot switch to no-split mode if multiple lines are entered into the payment details.';
								|it = 'Passare alla modalità senza la partizione è impossibile se nella decifrazione del pagamento viene inserita più di una riga!';
								|pl = 'Przełączenie do trybu bez podziału jest niemożliwe, jeśli w szczegółach płatności wprowadzono więcej niż jeden wiersz!';
								|tr = 'Ödeme detayında birden fazla satır girilmişse ayrıştırılmış moda geçmek mümkün değildir!'");
			CommonClientServer.MessageToUser(MessageText);
			DecryptionSwitch = 1;
		EndIf;
	EndIf;
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure ARAPDetailsOnStartEdit(Item, NewRow, Copy)
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	If Not ValueIsFilled(Partner) Then
		GetDefaultServerPartner(Object.Counterparty, Partner, Object.BusinessOperation);
	EndIf;
	
	FinancesClient.ARAPDetailsOnStartEdit(
		Object, Partner, CounterpartyContract, TableRow, NewRow, Copy);
		
	If NewRow Then
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			TableRow, Object.Currency, CurrencyOfComplianceAccounting);
		UpdateTaxRateRecalculateVATAmount(TableRow.GetID());
	EndIf;
	
	DecryptionOfPaymentAmountWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure ARAPDetailsOnEditEnd(Item, NewRow, CancelEdit)
	
	DecryptionOfPaymentAtEndOfEditingOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentAtEndOfEditingOnServer()
	
	CashServer.FillInCurrencyOfMutualSettlementsOfDocument(ThisObject);
	CurrencyDecorationAndPaymentRate = CashServer.CurrencyLabelAndPaymentRate(ThisObject);
	
EndProcedure

&AtClient
Procedure ARAPDetailsAfterDeleteRow(Item)
	
	ARAPDetailsAfterDeleteRowServer();
	
EndProcedure

&AtServer
Procedure ARAPDetailsAfterDeleteRowServer()
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	FillInCurrencyOfMutualSettlementsOfDocument();
	
EndProcedure

&AtClient
Procedure ARAPDetailsSumOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		TableRow, Object.Currency, CurrencyOfComplianceAccounting);
		
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
	DecryptionOfPaymentAmountWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentAmountWhenChangedOnServer()
	
	CurrencyDecorationAndPaymentRate = CashServer.CurrencyLabelAndPaymentRate(ThisObject);
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
EndProcedure

&AtClient
Procedure ARAPDetailsAmountARAPOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	If ValueIsFilled(TableRow.AmountARAP)
		And TableRow.ARAPCurrency = Object.Currency
		And TableRow.AmountARAP <> TableRow.Sum Then
		TableRow.AmountARAP = TableRow.Sum;
	Else
		DecryptionOfPaymentAmountOfSettlementsWhenChangingOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentAmountOfSettlementsWhenChangingOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);

	If CurrentRow.Sum = 0 Then
		CashClientServer.CalculateAmountInDecryptionLine(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	Else
		CashServer.CalculateExchangeRateNumeratorOfMutualSettlementsInDecryptionLine(
			CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	EndIf;
	
	FillInCurrencyOfMutualSettlementsOfDocument();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectStartChoice(Item, ChoiceData, StandardProcessing)
	
	ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
	CurrentData = Items.ARAPDetails.CurrentData;
	If CurrentData <> Undefined Then
		ARAPObject = CurrentData.ARAPObject;
	EndIf;
	
	ARAPAccountingClient.ARAPObjectStartChoice(ThisForm, Item, StandardProcessing,, ARAPObject);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		PaymentDecryptionSettlementObjectSelectionProcessingOnServer(ValueSelected);
	EndIf;
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtServer
Procedure PaymentDecryptionSettlementObjectSelectionProcessingOnServer(ValueSelected)
	
	RowID = Items.ARAPDetails.CurrentRow;
	TableRow = Object.ARAPDetails.FindByID(RowID);
	
	TableRow.Partner = ValueSelected.Partner;
	TableRow.Contract = ValueSelected.Contract;
	TableRow.ItIsAllowedToWorkWithSubsidiaryPartners = ValueSelected.ItIsAllowedToWorkWithSubsidiaryPartners;
	TableRow.AmountARAP = ValueSelected.AmountARAP;
	TableRow.ARAPObject = ValueSelected.ARAPObject;
	TableRow.ARAPCurrency = ValueSelected.ARAPCurrency;
	TableRow.MaturityDate = ValueSelected.MaturityDate;
	
	ValueSelected.Insert("CashFlowItem");
	ValueSelected.Insert("ExchangeRateNumeratorOfMutualSettlements", 1);
	ValueSelected.Insert("TheExchangeRateIsTheDenominatorOfMutualSettlements", 1);
	
	AddSelectedValue(ValueSelected);
	
	If ValueIsFilled(ValueSelected.CashFlowItem) Then
		TableRow.CashFlowItem = ValueSelected.CashFlowItem;
	EndIf;
	
	TableRow.VATRate = ValueSelected.VATRate;
	TableRow.VATAmount = ValueSelected.VATAmount;
	TableRow.ExchangeRateNumeratorOfMutualSettlements = ValueSelected.ExchangeRateNumeratorOfMutualSettlements;
	TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = ValueSelected.TheExchangeRateIsTheDenominatorOfMutualSettlements;
	
	Modified = True;
	
	If Not ValueIsFilled(TableRow.VATAmount) Then
		StructureOfRecalculationOfAmount = New Structure;
		StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		BatchProcessingOfTablePartServer.ProcessTSString(TableRow, StructureOfActions, Undefined);
	EndIf;
	
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	UpdateAmountUnallocated();
	
	CashServer.CheckFillOutContract(Object, RowID);
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object, RowID);
	
	GenerateHyperlinkCaptionPaymentObjectDetails();
	FillInCourseAndMultiplicityInDecryptionLine(TableRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	YouAreAllowedToWorkWithAffiliatedPartners(TableRow);
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure AddSelectedValue(ValueSelected)
	
	ValueSelected.Insert("CashFlowItem",
		CashServer.ArticleOfCashFlowOfSettlementObject(ValueSelected.ARAPObject, Object.BusinessOperation));
	
	ARAPObjects = New Array;
	ARAPObjects.Add(ValueSelected.ARAPObject);
	
	ValueSelected.Insert("VATRate", CashServer.VATRateOfSettlementObject(Object.Organization, ARAPObjects));
	
	If ValueIsFilled(ValueSelected.ARAPCurrency) Then
		CurrencyExchangeRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(ValueSelected.ARAPCurrency, Undefined,
						SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));
		ValueSelected.Insert("ExchangeRateNumeratorOfMutualSettlements", CurrencyExchangeRate.CourseNumerator);
		ValueSelected.Insert("TheExchangeRateIsTheDenominatorOfMutualSettlements", CurrencyExchangeRate.CourseDenominator);
	EndIf;
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPCurrencyOnChange(Item)
	
	DecryptionOfPaymentCurrencyOfSettlementsWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentCurrencyOfSettlementsWhenChangedOnServer()
	
	CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	ClearCalculationObject(CurrentRow);
	FillInCourseAndMultiplicityInDecryptionLine(CurrentRow);
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure ARAPDetailsExchangeRateNumeratorOfMutualSettlementsOnChange(Item)
	
	DecryptionOfPaymentExchangeRateNumeratorOfSettlementsWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure DecryptionOfPaymentExchangeRateNumeratorOfSettlementsWhenChangedOnServer()
	
	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
		CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	CashServer.FormCourseDenominatorByText(CurrentRow, Object.Currency, CurrencyOfComplianceAccounting);
	FillInCurrencyOfMutualSettlementsOfDocument();
	
EndProcedure

&AtServer
Procedure FillInCourseAndMultiplicityInDecryptionLine(TSRow)
	
	CourseAndMultiplicity = CashServer.CourseNumeratorAndCourseDenominatorOfMutualSettlements(
		Object.Currency, TSRow.ARAPCurrency, CurrencyOfComplianceAccounting, Object.Date, TSRow.ARAPObject, Object.Contract);
	TSRow.ExchangeRateNumeratorOfMutualSettlements = CourseAndMultiplicity.CourseNumerator;
	TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAndMultiplicity.CourseDenominator;
	TSRow.ContractRateOption = CourseAndMultiplicity.ContractRateOption;
	TSRow.ARAPObjectType = CourseAndMultiplicity.ARAPObjectType;
	
EndProcedure

&AtClient
Procedure ARAPDetailsPaymentPurposeOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	TableRow.AmountARAP = 0;
	TableRow.ARAPCurrency = Undefined;
	
	If Not ValueIsFilled(TableRow.PaymentPurpose) Then
		TableRow.ARAPObject = PredefinedValue("Catalog.ARAPObjects.EmptyRef");
		TableRow.MaturityDate = Date(1, 1, 1);
	EndIf;
	UpdatePresentationOfMaturityDate();
	
	DecryptionOfTheCalculationObjectWhenChangingServer(TableRow.GetID());
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
EndProcedure

&AtClient
Procedure ARAPDetailsPaymentPurposeStartChoice(Item, ChoiceData, StandardProcessing)
	
	PaymentPurpose = Undefined;
	CurrentData = Items.ARAPDetails.CurrentData;
	If CurrentData <> Undefined Then
		PaymentPurpose = CurrentData.PaymentPurpose;
	EndIf;
	
	ARAPAccountingClient.ARAPObjectStartChoice(ThisForm, Item, StandardProcessing, True, PaymentPurpose);
	
EndProcedure

&AtClient
Procedure ARAPDetailsPaymentPurposeAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, False);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, True);
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheCalculationObjectAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, True);
	
EndProcedure

&AtClient
Procedure ARAPDetailsPaymentPurposeTextEditEnd(Item, Text, ChoiceData, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, False);
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, True);
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheCalculationObjectTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	ARAPAccountingClient.ObjectOfCalculationsBasisOfPaymentAutoSelection(ThisForm, Items.ARAPDetails, Text, ChoiceData, StandardProcessing, False, True);
	
EndProcedure

&AtClient
Procedure ARAPDetailsPaymentPurposeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		ARAPDetailsPaymentBasisChoiceProcessingAtServer(ValueSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheBasisOfThePaymentAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	ARAPDetailsPaymentPurposeAutoComplete(Item, Text, ChoiceData, Waiting, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingTheBasisOfThePaymentTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	ARAPDetailsPaymentPurposeTextEditEnd(Item, Text, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ARAPDetailsVATRateOnChange(Item)
	
	CurrentRow = Items.ARAPDetails.CurrentData;
	
	StructureOfRecalculationOfAmount = New Structure;
	StructureOfRecalculationOfAmount.Insert("PriceIncludesVAT", True);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	Items.DecryptionWithoutSplittingTheVATAmount.ReadOnly =
		CashClientServer.ThisIsZeroVATRATE(CurrentRow.VATRate);
	
EndProcedure

&AtServer
Procedure DecryptionOfTheCalculationObjectWhenChangingServer(LineID)
	
	UpdateTaxRateRecalculateVATAmount(LineID);
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	CashServer.CheckFillOutContract(Object, LineID);
	
EndProcedure

&AtClient
Procedure TranscriptOfThePaymentTaxationOfPersonalIncomeTaxChanges(Item)
	
	CompleteVATTaxation();
	
EndProcedure

&AtClient
Procedure ARAPDetailsARAPObjectOnChange(Item)
	
	TableRow = Items.ARAPDetails.CurrentData;
	
	If Not ValueIsFilled(TableRow.ARAPObject) Then
		
		If Not ValueIsFilled(TableRow.Contract) Then
			TableRow.PaymentPurpose = Undefined;
		EndIf;
		
		TableRow.AmountARAP = 0;
		TableRow.ARAPCurrency = Undefined;
		TableRow.MaturityDate = Date(1, 1, 1);
		
	EndIf;
	
	DecryptionWithoutSplittingTheCalculationObjectOnChangeServer();
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtServer
Procedure DecryptionWithoutSplittingTheCalculationObjectOnChangeServer()
	
	RowID = Items.ARAPDetails.CurrentRow;
	CashServer.CheckFillOutContract(Object, RowID);
	UpdateTaxRateRecalculateVATAmount(RowID);
	
EndProcedure

&AtClient
Procedure ARAPDetailsOnActivateCell(Item)
	
	CashClient.SetAvailabilityOfPaymentDecryptionItemAmountOfSettlements(ThisObject, Object.Currency);
	CashClient.SetAvailabilityOfPaymentDecryptionContractElement(ThisObject);
	
EndProcedure

&AtClient
Procedure DecodingWithoutSplittingIsVariantOfContractCourseClick(Item, StandardProcessing)
	ARAPAccountingClient.TranscriptOfPaymentCourseOptionOfContractClick(Items.ARAPDetails.CurrentData, StandardProcessing);
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateOnChange(Item)
	
	Object.ARAPDetails[0].MaturityDate = MaturityDateWithoutSplitting;
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpeningParameters = New Structure("InitialValue", Object.ARAPDetails[0].MaturityDate);
	CallbackDescription = New CallbackDescription("DecryptionWithoutSplittingRepaymentDateEndOfSelection", ThisObject);
	OpenForm("CommonForm.SelectDate", OpeningParameters, ThisObject,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	Object.ARAPDetails[0].MaturityDate = Date(1, 1, 1);
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If TypeOf(MaturityDateWithoutSplitting) = Type("Date") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	DateInNumbers = StrConcat(StrSplit(Text, StrConcat(StrSplit(Text, "0123456789"))));
	If Not IsBlankString(DateInNumbers) Then
		SelectedDay  = Left(DateInNumbers, 2);
		If StrLen(DateInNumbers) > 2 Then
			SelectedMonth = Mid(DateInNumbers, 3, 2);
		Else
			SelectedMonth = Format(CommonClient.SessionDate(), "DF=MM")
		EndIf;
		If StrLen(DateInNumbers) > 4 Then
			SelectedYear = Mid(DateInNumbers, 5, 4);
		Else
			SelectedYear   = Format(CommonClient.SessionDate(), "DF=yyyy")
		EndIf;
		SelectedDateAsString = StrTemplate("%1.%2.%3", SelectedDay, SelectedMonth, SelectedYear);
		SelectedDate = StringFunctionsClientServer.StringToDate(SelectedDateAsString);
		Object.ARAPDetails[0].MaturityDate = SelectedDate;
		UpdatePresentationOfMaturityDate();
		ChoiceData = New ValueList();
		ChoiceData.Add(SelectedDate);
	EndIf;
	
EndProcedure

&AtClient
Procedure TranscriptOfPaymentContractOnChange(Item)
	
	LineOfATabularSection = Items.ARAPDetails.CurrentData;
	
	If LineOfATabularSection = Undefined Then
		Return;
	EndIf;
	
	Object.Contract = LineOfATabularSection.Contract;
	
	AgreementWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure TranscriptOfPaymentContractStartChoice(Item, ChoiceData, StandardProcessing)
	
	SettlementObjectContractStartOfSelection(Item, ChoiceData, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ARAPDetailsPartnerOnChange(Item)

	ARAPDetailsPartnerOnChangeAtServer();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm, True);
	
EndProcedure

&AtClient
Procedure SelectionByStock(Command)
	
	CheckParameters = ProcessingOfTabularFormsClient.FillVerificationParameters();
	CheckParameters.CheckedAttributes.Insert("AcquiringContract",     NStr("vi = 'Hợp đồng kết nối đến hệ thống thanh toán';
																			|ru = 'Договор подключения к платежной системе';
																			|en = 'Payment system contract'; fa = 'قرارداد سیستم پرداخت';
																			|it = 'Contratto di connessione a un sistema di pagamento';
																			|pl = 'Umowa o podłączenie do systemu płatniczego';
																			|tr = 'Ödeme sistemine bağlama sözleşmesi'"));
	If POSTerminalsAreUsed Then
		CheckParameters.CheckedAttributes.Insert("POSTerminal", NStr("vi = 'Thiết bị thẻ thanh toán';
																	|ru = 'Эквайринговый терминал';
																	|en = 'POS terminal'; fa = 'پایانه فروش (POS)';
																	|it = 'Terminale di pagamento POS';
																	|pl = 'Terminal acquiringowy';
																	|tr = 'PoS terminali'"));
	EndIf;
	CheckParameters.CheckedAttributes.Insert("Counterparty",            NStr("vi = 'Đối tác';
																			|ru = 'Контрагент';
																			|en = 'Counterparty'; fa = 'طرف حساب';
																			|it = 'Controparte';
																			|pl = 'Kontrahent';
																			|tr = 'Cari hesap'"));
	CheckParameters.CheckedAttributes.Insert("BusinessOperation", NStr("vi = 'Giao dịch';
																		|ru = 'Операция';
																		|en = 'Transaction'; fa = 'تراکنش';
																		|it = 'Operazione';
																		|pl = 'Transaction';
																		|tr = 'İşlem'"));
	Notification = New CallbackDescription("SelectionBasedOnBalancesAfterVerification", ThisObject);
	ProcessingOfTabularFormsClient.CheckIfItCanBeFilledIn(ThisForm, Notification, CheckParameters);
	
EndProcedure

&AtClient
Procedure PickUpGiftCertificate(Command)
	
	If GiftCertificatesClient.CheckPossibilityOfAddingGiftCertificate(ThisObject, False) Then
		DescriptionOfAssuranceNotification = New CallbackDescription("PickUpGiftCertificateCompletion", ThisObject);
		If Object.Posted Then
			RetailSalesClient.DisplayQuestionAboutNeedForUnverifiedDocument(ThisObject, DescriptionOfAssuranceNotification);
		Else
			RunCallback(DescriptionOfAssuranceNotification, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure PickUpGiftCertificateCompletion(Result, AdditionalParameters) Export
	
	If Result = True Then
		FilterParameters = New Structure;
		AdditionalParameters = New Structure;
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromCustomer") Then
			
			AdditionalParameters.Insert("RegisterNewOnes", True);
			
		Else
			
			StatusesForSelection = New Array;
			StatusesForSelection.Add(PredefinedValue("Enum.GiftCertificateStatuses.Activated"));
			StatusesForSelection.Add(PredefinedValue("Enum.GiftCertificateStatuses.PartiallyRepaid"));
			FilterParameters.Insert("Status", StatusesForSelection);
			FilterParameters.Insert("Currency", CurrencyOfComplianceAccounting);
			
			AdditionalParameters.Insert("Organization", Object.Organization);
			AdditionalParameters.Insert("RegisterNewOnes", False);
			
		EndIf;
		
		FilterParameters.Insert("Organization", Object.Organization);
		FilterParameters.Insert("GiftCardAccounting25", True);
		FilterParameters.Insert("OperationType", GiftCertificatesClientServer.TypeOfOperationForGiftCertificates(Object));
		
		AdditionalParameters.Insert("DoNotUseManualInput", False);
		AdditionalParameters.Insert("Filter", FilterParameters);
		
		OpenForm(
			"Catalog.GiftCertificates.Form.ReadGiftCard",
			AdditionalParameters,
			ThisObject,
			UUID);
	EndIf;
	
EndProcedure	

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm, True);
	
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	TMCommonUseClient.SetDeletionMarkForADocument(ThisForm);
EndProcedure

#EndRegion

#Region Private

#Region WorkingWithCounterparties
&AtClient
Procedure CheckCounterparties(Command)
	
	
	Return;
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	CashServer.ManagingFormElementsWhenReadingCreatingOnServer(ThisObject);
	
	UseMultipleCurrencies     = GetFunctionalOption("UseMultipleCurrencies");
	UseCustomerContracts = GetFunctionalOption("UseCustomerContracts");
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CurrentCounterparty = Object.Counterparty;
	CurrentAcquiringAgreement = Object.AcquiringContract;
	KeepRecordsOfCommissionInMutualSettlementsSwitch = Object.KeepRecordsOfCommissionInARAPAccounting;
	
	If ValueIsFilled(Object.CommissionARAPObject) Then
		CommissionAgreement = Common.ObjectAttributeValue(Object.CommissionARAPObject, "Contract");
	EndIf;
	
	If ValueIsFilled(CurrentAcquiringAgreement) Then
		
		AttributesValues = Catalogs.AcquiringContracts.ContractDetails_(CurrentAcquiringAgreement);
		
		BranchesOfOrganization.LoadValues(Catalogs.Companies.BranchesWithPaymentsThroughParentOrganization(AttributesValues.Organization));
		POSTerminalsAreUsed = AttributesValues.POSTerminalsAreUsed;
		MakingPaymentMethod = AttributesValues.MakingPaymentMethod;
		
		EnabledCreatingCashIssueWithoutPaymentRequest = AttributesValues.EnableCreatingCashIssueWithoutPaymentRequest;
		If ValueIsFilled(Object.POSTerminal) Then
			EnabledCreatingCashIssueWithoutPaymentRequest =
				Common.ObjectAttributeValue(Object.POSTerminal, "EnableCreatingCashIssueWithoutPaymentRequest");
		EndIf;
		
		If Object.RecordCommission Then
			If AttributesValues.FixedFeeRate
				And Not ValueIsFilled(Object.Ref) Then
				CommissionRate = AttributesValues.CommissionRate;
			ElsIf Object.DocumentAmount <> 0 Then
				CommissionRate = CashClientServer.CalculateCommissionRate(Object.DocumentAmount, Object.FeeAmount);
			Else
				CommissionRate = 0;
			EndIf;
			Items.GroupCommission.Title = NStr("vi = 'Phí ngân hàng';
												|ru = 'Комиссия';
												|en = 'Fee'; fa = 'کارمزد';
												|it = 'Commissione';
												|pl = 'Fee';
												|tr = 'Komisyon'") +
				" " + String(Object.FeeAmount) + " " + String(Object.Currency) + " " + String(CommissionRate) + "%";
		EndIf;
	EndIf;
	
	GetDefaultServerPartner(Object.Counterparty, Partner, Object.BusinessOperation);
	GetDefaultContractServer();
	
	If Object.ARAPDetails.Count() = 0 Then
		NewRow = Object.ARAPDetails.Add();
		Items.ARAPDetails.CurrentRow = NewRow.GetID();
		NewRow.CashFlowItem = Object.CashFlowItem;
		NewRow.Sum = Object.DocumentAmount;
		NewRow.ARAPCurrency = Object.Currency;
		NewRow.ExchangeRateNumeratorOfMutualSettlements = 1;
		NewRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 1;
		CompleteVATTaxation();
	ElsIf Object.ARAPDetails.Count() = 1 Then
		Items.ARAPDetails.CurrentRow = Object.ARAPDetails[0].GetID();
	Else
		DecryptionSwitch = 1;
	EndIf;
	FillInParametersOfCalculationObjectInDecryption();
	
	FillInCurrencyOfMutualSettlementsOfDocument();
	FillMultiplicityCourseWithText();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	FormItemsManagement();
	
EndProcedure

&AtServer
Procedure ManagingFormElementsDependentOnFoundationDocument()
	
	BaseDocumentPresentation = NStr("vi = 'Hãy chọn chứng từ cơ sở';
									|ru = 'Выберите документ-основание';
									|en = 'Select a base document'; fa = 'Select a base document';
									|it = 'Selezionare documento base';
									|pl = 'Wybierz dokument źródłowy';
									|tr = 'Lütfen, temel belge seçin.'");
	Items.DecryptionSwitch.Enabled = True;
	If ValueIsFilled(Object.DocumentBasis) Then
		BaseDocumentPresentation = Object.DocumentBasis;
		If TypeOf(Object.DocumentBasis) = Type("DocumentRef.PaymentCardTransaction") Then
			Items.DecryptionSwitch.Enabled = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInParametersOfCalculationObjectInDecryption()
	ComplianceOfContractCurrencyExchangeRate = ARAPAccountingServer.ComplianceOfARAPObjectsAndParametersOfContract(
		Object.ARAPDetails.Unload(,"ARAPObject").UnloadColumn("ARAPObject"));
	For Each TSRow In Object.ARAPDetails Do
		TSRow.ContractRateOption = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].ContractRateOption;
		TSRow.ItIsAllowedToWorkWithSubsidiaryPartners = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].ItIsAllowedToWorkWithSubsidiaryPartners;
		TSRow.TheCalculationObjectMatchesTheDocument = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].Object = Object.Ref;
		If ValueIsFilled(TSRow.ARAPObject) Then
			TSRow.ARAPObjectType = ComplianceOfContractCurrencyExchangeRate[TSRow.ARAPObject].ARAPObjectType;
		EndIf;
	EndDo;
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CashClientServer.CustomizeFormElements(ThisForm, ChangedProps, FormAttributes(ThisForm));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("UseMultipleCurrencies");
	FormAttributes.Insert("UseCustomerContracts");
	FormAttributes.Insert("EnabledCreatingCashIssueWithoutPaymentRequest");
	FormAttributes.Insert("AmountUnallocated");
	FormAttributes.Insert("POSTerminalsAreUsed");
	FormAttributes.Insert("ARAPCurrency");
	FormAttributes.Insert("CurrencyOfComplianceAccounting");
	FormAttributes.Insert("ContractRateOption");
	FormAttributes.Insert("ARAPObjectType");
	FormAttributes.Insert("ExchangeRateNumeratorOfMutualSettlements");
	FormAttributes.Insert("MultipleARAPCurrency");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtClient
Procedure RecalculateAmountOfDocumentBasedOnPaymentDecryptionCompletion(QuestionResult, AdditionalParameters) Export
	
	If AdditionalParameters.Property("TabularSectionName") Then
		TabularSection = Object[AdditionalParameters.TabularSectionName];
	Else
		TabularSection = Object.ARAPDetails;
	EndIf;
	
	ResponseCode = QuestionResult;
	If ResponseCode = DialogReturnCode.Yes Then
		Object.DocumentAmount = TabularSection.Total("Sum");
		Write(AdditionalParameters.WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionBasedOnBalancesAfterVerification(Result, AdditionalParameters) Export
	
	Notification = New CallbackDescription("SelectionByStockCompletion", ThisObject);
	PlacePaymentDecryptionInTemporaryStorage();
	ARAPAccountingClient.AddToPaymentDecryption(ThisForm, Items.ARAPDetailsSelectionByStock.Name, Notification);
	
EndProcedure

&AtServer
Procedure PlacePaymentDecryptionInTemporaryStorage()
	ARAPAccountingFormWork.PlacePaymentDecryptionInTemporaryStorage(ThisForm, "ARAPDetailsSelectionByStock");
EndProcedure

&AtClient
Procedure SelectionByStockCompletion(Result, AdditionalParameters) Export
	If Result <> Undefined Then
		SelectionByStockCompletionServer();
	EndIf;
EndProcedure

&AtServer
Procedure SelectionByStockCompletionServer()
	
	ARAPAccountingFormWork.DownloadPaymentTranscriptFromTemporaryStorage(ThisObject);
	DefaultCFItem =
		Catalogs.CashFlowReportItems.CashFlowItemForBusinessTransaction(Object.BusinessOperation);
	
	For Each TableRow In Object.ARAPDetails Do
		If Not ValueIsFilled(TableRow.CashFlowItem) Then
			TableRow.CashFlowItem = DefaultCFItem;
		EndIf;
		FillInCourseAndMultiplicityInDecryptionLine(TableRow);
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			TableRow, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(TableRow, Object.Currency, CurrencyOfComplianceAccounting);
	EndDo;
	
	CashServer.CheckFillOutContract(Object);
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	FillInCurrencyOfMutualSettlementsOfDocument();
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	CashServer.FillInDataOfSettlementObjectOfPaymentDecryption(Object);
	
	// If the selection is not for the entire amount of the document, then you need to fill in the VAT rate on the line without the calculation object
	For Each DecryptionString In Object.ARAPDetails Do
		If Not ValueIsFilled(DecryptionString.ARAPObject)
			Or DecryptionString.CalculationObject = Object.Ref Then
			If ValueIsFilled(DecryptionString.Contract) Then
				DecryptionString.VATRate = Common.ObjectAttributeValue(DecryptionString.Contract, "VATRate");
			EndIf;
			If ValueIsFilled(DecryptionString.VATRate) Then
				StructureOfActions = New Structure("RecalculateVATAmount", New Structure("PriceIncludesVAT", True));
				BatchProcessingOfTablePartServer.TreatTS(Object.ARAPDetails, StructureOfActions, Undefined);
			Else
				UpdateAllRowsOnServer(DecryptionString.GetID());
			EndIf;
		EndIf;
	EndDo;
	
	FillInParametersOfCalculationObjectInDecryption();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

#Region FormItemsManagement

&AtServer
Procedure FormItemsManagement()
	
	CashServer.SetPaymentAmountHeader(Object.Currency, Items);
	CashServer.CompleteVATTaxation(Object, Object.VATTaxation, Items.DecodingWithoutSplittingVATTaxation,, False);
	Items.LabelCurrency.Title = String(Object.Currency);
	Items.LabelCurrencyCommission.Title = Items.LabelCurrency.Title;
	
	Items.GroupCommission.Title = NStr("vi = 'Phí ngân hàng';
										|ru = 'Комиссия';
										|en = 'Fee'; fa = 'کارمزد';
										|it = 'Commissione';
										|pl = 'Prowizja';
										|tr = 'Komisyon'") +
		" " + String(Object.FeeAmount) + " " + String(Object.Currency) + " " + String(CommissionRate) + "%";
	
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation(
		ThisObject, "ARAPDetailsPartner", Object.BusinessOperation);
	PartnersAndCounterparties.TitleOfPartnerElementDependingOnBusinessOperation(
		ThisObject, "DecryptionWithoutPartitioningPartner", Object.BusinessOperation);
	
	UpdateAmountUnallocated();
	GenerateHyperlinkCaptionPaymentObjectDetails();
	
	If DecryptionSwitch Then
		Items.ExplanationPages.CurrentPage = Items.ExplanationAsAList;
	Else
		Items.ExplanationPages.CurrentPage = Items.ExplanationWithoutSplit;
	EndIf;
	
	If Not DecryptionSwitch Then
		SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
		If Object.ARAPDetails.Count() > 0
			And ValueIsFilled(Object.ARAPDetails[0].MaturityDate) Then
			MaturityDateWithoutSplitting = Object.ARAPDetails[0].MaturityDate;
		Else
			MaturityDateWithoutSplitting = NStr("vi = '<tự động>';
												|ru = '<автоматически>';
												|en = '<automatically>'; fa = '<automatically>';
												|it = '<автоматически>';
												|pl = '<automatically>';
												|tr = '<otomatik olarak>'");
		EndIf;
	EndIf;
	
	CashServer.SetParametersForChoosingAcquiringAgreement(Object, Items.AcquiringContract);
	CashServer.SetContractSelectionParameters(ThisObject, Items.Contract);
	CashServer.SetApplicationSelectionParameters(Object, Items.PaymentRequest);
	
	If Object.BusinessOperation = Enums.BusinessTransactions.RefundToCustomer Then
		Items.BaseDocumentPresentation.Visible = True;
	Else
		Items.BaseDocumentPresentation.Visible = False;
	EndIf;
	
	ManagingFormElementsDependentOnFoundationDocument();
	
	ConfigureDependentFormElementsOnServer();
	
	PaymentCardTransactionLocalization.FormItemsManagement(ThisObject);
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning()
	
	CashServer.SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning(ThisObject);
	
EndProcedure

&AtClient
Procedure UpdatePresentationOfMaturityDate()
	If Object.ARAPDetails.Count() = 0 
		Or Not ValueIsFilled(Object.ARAPDetails[0].MaturityDate) Then
		MaturityDateWithoutSplitting = NStr("vi = '<tự động>';
											|ru = '<автоматически>';
											|en = '<automatically>'; fa = '<automatically>';
											|it = '<автоматически>';
											|pl = '<automatically>';
											|tr = '<otomatik olarak>'");
	Else
		MaturityDateWithoutSplitting = Object.ARAPDetails[0].MaturityDate;
	EndIf;
EndProcedure

&AtClient
Procedure DecryptionWithoutSplittingRepaymentDateEndOfSelection(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		Object.ARAPDetails[0].MaturityDate = Result;
		Modified = True;
	EndIf;
	UpdatePresentationOfMaturityDate();
	
EndProcedure

&AtServer
Procedure ARAPDetailsPaymentBasisChoiceProcessingAtServer(ValueSelected)

	TableRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	
	TableRow.PaymentPurpose = ValueSelected.PaymentPurpose;
	TableRow.Contract = ValueSelected.Contract;
	TableRow.ARAPObject = ARAPObjectsServer.ARAPObjectOnBasisOfPayment(TableRow.PaymentPurpose);
	
	DecryptionWithoutSplittingTheCalculationObjectOnChangeServer();
	
	If Not ValueIsFilled(TableRow.ARAPObject) Then
	
		If ValueIsFilled(TableRow.Contract) Then
			Object.Contract = TableRow.Contract;
			AgreementWhenModifiedOnServer();
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure DirectionOfActivityWhenChangingOnServer()

	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	ClearCalculationObject(CurrentRow);

EndProcedure

&AtServer
Procedure FinancialAccountingGroupOnChangeAtServer()

	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	ClearCalculationObject(CurrentRow);

EndProcedure

&AtServer
Procedure ARAPDetailsPartnerOnChangeAtServer()

	CurrentRow = Object.ARAPDetails.FindByID(Items.ARAPDetails.CurrentRow);
	ClearCalculationObject(CurrentRow);

EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure GetDefaultContractServer()
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.PaymentCardTransaction.FillInNamesOfBusinessTransactionDetails(
		Object.BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails);
		
	If ArrayOfOperationDetails.Find("ARAPDetails.ARAPObject") = Undefined Then
		Return;
	EndIf;
	
	If AccessRight("Read", Metadata.Catalogs.CounterpartyContracts) Then
	
		ContractBusinessTransaction = New Array;
		ContractBusinessTransaction.Add(Enums.BusinessTransactions.SaleToCustomer);
		ContractBusinessTransaction.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
		
		CounterpartyContract = CashServer.DefaultContract(
			CounterpartyContract, Partner, Object.Counterparty, Object.Organization, ContractBusinessTransaction);
			
		If ValueIsFilled(CounterpartyContract) Then
			AccountingInformationUnderAgreement = Catalogs.CounterpartyContracts.AccountingInformationUnderAgreement(CounterpartyContract);
			If ValueIsFilled(AccountingInformationUnderAgreement) Then
				If Not ValueIsFilled(Object.CashFlowItem) Then
					AccountingInformationUnderAgreement.Property("CashFlowItem", Object.CashFlowItem);
				EndIf;
				AccountingInformationUnderAgreement.Property("VATRate", VATRate);
				AccountingInformationUnderAgreement.Property("ARAPCurrency", ARAPCurrency);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure GetDefaultServerPartner(Counterparty, Partner, BusinessOperation)
	
	Partner = CashServer.GetCounterpartyPartner(Counterparty, BusinessOperation);
	
EndProcedure

// Gets the structure of the Contract Attributes by reference.
// 
// Parameters:
//  Ref - CatalogRef.AcquiringContracts -
//
// Returns:
//  See Catalogs.AcquiringContracts.ContractDetails_
//
&AtServer
Function DetailsOfAcquiringAgreement(Ref)
	
	Return Catalogs.AcquiringContracts.ContractDetails_(Ref);
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsARAPObject.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.ARAPObject.Object");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.ARAPObject.Object");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("Object.ARAPDetails.PaymentPurpose");
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<trùng với cơ sở thanh toán>';
													|ru = '<совпадает с основанием платежа>';
													|en = '<coincides with payment base document>'; fa = '<coincides with payment base document>';
													|it = '<Coincide con la motivazione del pagamento>';
													|pl = '<jest zgodna z podstawą płatności>';
													|tr = '<ödeme gerekçesine uygun>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsPartner.Name);
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsARAPCurrency.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.ItIsAllowedToWorkWithSubsidiaryPartners");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsARAPObject.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.ARAPObject");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ARAPDetails.TheCalculationObjectMatchesTheDocument");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.DarkGray);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Chứng từ này>';
													|ru = '<этот документ>';
													|en = '<this document>'; fa = '<this document>';
													|it = '<questo documento>';
													|pl = '<ten dokument>';
													|tr = '<bu belge>'"));

	LinesOfBusinessServer.EstablishConditionalAppearanceOfDirectionOfActivity(ThisForm);
	
	// The course of settlements
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsExchangeRateNumeratorOfMutualSettlements.Name);
	
	Item.Appearance.SetParameterValue("Text", "");
	
	// Maturity Date
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ARAPDetailsMaturityDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Object.ARAPDetails.MaturityDate");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tự động>';
													|ru = '<автоматически>';
													|en = '<automatically>'; fa = '<automatically>';
													|it = '<автоматически>';
													|pl = '<automatically>';
													|tr = '<otomatik olarak>'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
	// VATAmount
	CashServer.SetConditionalAppearanceOfVATAmountOfPaymentDecryption(ThisObject);
	
	PaymentCardTransactionLocalization.SetConditionalAppearance(ThisObject);
	
EndProcedure

&AtServer
Procedure GenerateHyperlinkCaptionPaymentObjectDetails()
	CashServer.GenerateHyperlinkCaptionPaymentObjectDetails(ThisForm, Object, True);
EndProcedure

&AtServer
Function PlaceDecryptionInTemporaryStorage()
	Return PutToTempStorage(Object.ARAPDetails.Unload());
EndFunction

&AtServer
Procedure BlockData_()
	LockDataForEdit(Object.Ref,,ThisForm.UUID);
EndProcedure

&AtServer
Procedure UnlockData()
	UnlockDataForEdit(,ThisForm.UUID);
EndProcedure

&AtServer
Procedure FillInCurrencyOfMutualSettlementsOfDocument()
	
	CashServer.FillInCurrencyOfMutualSettlementsOfDocument(ThisForm);
	CurrencyDecorationAndPaymentRate = CashServer.CurrencyLabelAndPaymentRate(ThisObject);
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure FillInCourseCourseDenominatorOfSettlements()
	
	For Each TSRow In Object.ARAPDetails Do
		FillInCourseAndMultiplicityInDecryptionLine(TSRow);
	EndDo;
	CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
EndProcedure

&AtServer
Procedure FillMultiplicityCourseWithText()
	
	For Each TSRow In Object.ARAPDetails Do
		CashServer.FormCourseDenominatorByText(TSRow, Object.Currency, CurrencyOfComplianceAccounting);
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateAmountOfSettlements_()
	
	For Each TSRow In Object.ARAPDetails Do
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			TSRow, Object.Currency, CurrencyOfComplianceAccounting);
	EndDo;
	
EndProcedure

&AtServer
Procedure CompleteVATTaxation(UpdateVATRateAndAmount = True)
	
	CashServer.CompleteVATTaxation(Object, Object.VATTaxation, Items.DecodingWithoutSplittingVATTaxation, Items.DecryptionWithoutDivisionTaxationVATRefund, UpdateVATRateAndAmount);
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	UpdateAmountUnallocated();
	
EndProcedure

&AtServer
Procedure UpdateAllRowsOnServer(LineID)
	
	SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
	UpdateTaxRateRecalculateVATAmount(LineID);
	UpdateAmountUnallocated();
	
EndProcedure

&AtServer
Procedure UpdateTaxRateRecalculateVATAmount(LineID = Undefined)
	
	CashServer.UpdateTaxRateRecalculateVATAmount(Object, LineID);
	
EndProcedure

&AtServer
Procedure ProcessGiftCertificate(GiftCertificate)
	
	FoundRow = GiftCertificatesServer.AddGiftCertificateToTablePartOfPaymentDecryption(GiftCertificate, ThisObject);
	If FoundRow <> Undefined Then
		
		Modified = True;
		
		UpdateAmountUnallocated();
		GenerateHyperlinkCaptionPaymentObjectDetails();
		SetVisibilityAvailabilityOfDecryptionElementsWithoutPartitioning();
		
		FillInCourseAndMultiplicityInDecryptionLine(FoundRow);
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			FoundRow, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(FoundRow, Object.Currency, CurrencyOfComplianceAccounting);
		FillInCurrencyOfMutualSettlementsOfDocument();
		CashServer.SetDesignAccuracyOfCourse(ThisObject);
		
		ConfigureDependentFormElementsOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure YouAreAllowedToWorkWithAffiliatedPartners(TableRow)
	
	ReferencesArrray = CommonClientServer.ValueInArray(TableRow.ARAPObject);
	ComplianceOfContractCurrencyExchangeRate = ARAPAccountingServer.ComplianceOfARAPObjectsAndParametersOfContract(ReferencesArrray);
	TableRow.ItIsAllowedToWorkWithSubsidiaryPartners = ComplianceOfContractCurrencyExchangeRate[TableRow.ARAPObject].ItIsAllowedToWorkWithSubsidiaryPartners;
	TableRow.TheCalculationObjectMatchesTheDocument = ComplianceOfContractCurrencyExchangeRate[TableRow.ARAPObject].Object = Object.Ref;
	
EndProcedure

&AtServer
Procedure UpdateAmountUnallocated()

	AmountUnallocated = CashServer.UnallocatedPaymentBalance(Object);
	ConfigureDependentFormElementsOnServer("AmountUnallocated");

EndProcedure

&AtServer
Procedure ProcessingDocumentSelectionViaServer(ValueSelected)
	
	Modified = True;
	
	FillingData = CashServer.FillingDataForRefundOfAcquiringTransactionPayment(ValueSelected);
	FillPropertyValues(Object, FillingData);
	
	CashServer.FillInPaymentTranscriptForPaymentDocument(
		ValueSelected, FillingData.BusinessOperation, Object.ARAPDetails);
	
	Object.DocumentAmount = Object.ARAPDetails.Total("Sum");
	
	OnReadCreateAtServer();
	
	ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
	
EndProcedure

&AtServer
Procedure ClearCalculationObject(DecryptionString)

	CashServer.ClearCalculationObject(Object, DecryptionString);

EndProcedure

&AtServer
Procedure FillInPaymentDecryptionLineUnderContract(DecryptionString, ContractDetails_)

	If ValueIsFilled(ContractDetails_) Then
		
		FillPropertyValues(DecryptionString, ContractDetails_);
		DecryptionString.Contract = Object.Contract;
		
		FillInCourseAndMultiplicityInDecryptionLine(DecryptionString);
		CashClientServer.CalculateAmountOfSettlementsInDecryptionLine(
			DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.FormCourseDenominatorByText(DecryptionString, Object.Currency, CurrencyOfComplianceAccounting);
		CashServer.SetDesignAccuracyOfCourse(ThisObject);
	
	EndIf;

EndProcedure

&AtServer
Procedure ContractFeesOnChangesATServer()
	
	Object.CommissionARAPObject = ?(ValueIsFilled(CommissionAgreement),
		ARAPObjectsServer.GetCalculationObjectFromLink(CommissionAgreement), Catalogs.ARAPObjects.EmptyRef());
	
EndProcedure

&AtServer
Procedure KeepRecordsOfCommissionInMutualSettlementsSwitchOnChangesAtServer()

	Object.KeepRecordsOfCommissionInARAPAccounting = KeepRecordsOfCommissionInMutualSettlementsSwitch;
	
	If Not Object.KeepRecordsOfCommissionInARAPAccounting Then
		CommissionAgreement = Catalogs.CounterpartyContracts.EmptyRef();
		Object.CommissionARAPObject = Catalogs.ARAPObjects.EmptyRef();
	EndIf;
	ItemsAndDimensionsSelectionParameters = Documents.PaymentCardTransaction.ItemsAndDimensionsSelectionParameters(
		Object.RecordCommission And Not Object.KeepRecordsOfCommissionInARAPAccounting);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	ConfigureDependentFormElementsOnServer("KeepRecordsOfCommissionInARAPAccounting");

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
