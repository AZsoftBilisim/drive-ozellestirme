//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	DocumentModificationIsAvailable = AccessManagement.EditionAllowed(Object.Ref);
	If Not DocumentModificationIsAvailable Then
		
		FieldNamesAvailability = New Array; // Array of String
		FieldNamesAvailability.Add(Items.CurrencyDecorationAndPaymentRate.Name);
		
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Items,
			FieldNamesAvailability,
			"Enabled",
			False);
		
		// All the conditions for retro bonuses are based on the availability of the organization in the act, so it's enough to check the first one in the list.
		// We don't check for the availability of metadata, because it may be available within another organization (not according to the one in the report).
		
		If Object.Rebates.Count() > 0 Then
			
			BonusDocumentsAreAvailable = True;
			For Each BonusLine In Object.Rebates Do
				
				If Not BonusLine.TermDocument.IsEmpty() Then
					
					BonusDocumentsAreAvailable = AccessManagement.ReadingAllowed(BonusLine.TermDocument);
					Break;
					
				EndIf;
				
			EndDo;
			
			If Not BonusDocumentsAreAvailable Then
				
				FieldNamesVisibility = New Array; // Array of String
				FieldNamesVisibility.Add(Items.Rebates.Name);
				
				TMCommonUseClientServer.SetPropertyOfFormElements(
					Items,
					FieldNamesVisibility,
					"Visible",
					False,
					True);
				
			EndIf;
			
		EndIf;
			
	EndIf;
	
	ARAPAccountingFormWork.FormWhenReadingOnServer(ThisObject);
	
	OnCreatReadAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorBonusCertificate.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.VendorBonusCertificate.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, SetupParameters);
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If ExchangePlans.MasterNode() <> Undefined Then
		
		ReadOnly = True;
		
	EndIf;
	
	ARAPAccountingFormWork.FormWhenCreatedOnServer(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnCreatReadAtServer();
		
	EndIf;
	
	CurContract = Object.Contract;
	If Not Object.Contract.IsEmpty() Then
		ContractRateOption = Common.ObjectAttributeValue(Object.Contract, "ContractRateOption");
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorBonusCertificate.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetupParameters = Documents.VendorBonusCertificate.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, SetupParameters);
	SetConditionalAppearance();
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	CalculateTotals();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	// End StandardSubsystems.AttachableCommands
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillMultiplicityCourseWithText();
	FillInServiceAttributesOfRebates();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	GLAccountSettingsServer.AfterWriteAtServer(ThisObject);
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.ShowConfirmationForClosingFormWithFiles(ThisObject, Cancel, Exit, Object.Ref);
	If Cancel Then
		Return;
	EndIf;
	// End StandardSubsystems.FilesOperations
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Async Procedure OrganizationOnChange(Item)
	
	If ItIsNecessaryToClearRebates() Then
		
		QueryText = NStr("vi = 'Sẽ xóa dòng với chứng từ điều kiện đã điền.
							|Tiếp tục?';
							|ru = 'Строки с заполненными документами условий будут удалены.
							|Продолжить?';
							|en = 'Lines with populated condition documents will be deleted.
							|Continue?'; fa = 'Lines with populated condition documents will be deleted.
							|Continue?';
							|it = 'Строки с заполненными документами условий будут удалены.
							|Продолжить?';
							|pl = 'Lines with populated condition documents will be deleted.
							|Continue?';
							|tr = 'Doldurulmuş şart belgeleri bulunan satırlar silinecektir.
							|Devam edilsin mi?'");
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		
		If Response = DialogReturnCode.Yes Then
			
			ClearLinesOfRebates();
			CurrentCompany = Object.Organization;
			OrganizationOnChangeServer();
			
		Else
			
			Object.Organization = CurrentCompany;
			
		EndIf;
		
	Else
		
		CurrentCompany = Object.Organization;
		OrganizationOnChangeServer();
		
	EndIf;
	
EndProcedure

&AtClient
Async Procedure CounterpartyOnChange(Item)
	
	If ItIsNecessaryToClearRebates() Then
		
		QueryText = NStr("vi = 'Sẽ xóa dòng với chứng từ điều kiện đã điền.
							|Tiếp tục?';
							|ru = 'Строки с заполненными документами условий будут удалены.
							|Продолжить?';
							|en = 'Lines with populated condition documents will be deleted.
							|Continue?'; fa = 'Lines with populated condition documents will be deleted.
							|Continue?';
							|it = 'Строки с заполненными документами условий будут удалены.
							|Продолжить?';
							|pl = 'Lines with populated condition documents will be deleted.
							|Continue?';
							|tr = 'Doldurulmuş şart belgeleri bulunan satırlar silinecektir.
							|Devam edilsin mi?'");
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		
		If Response = DialogReturnCode.Yes Then
			
			ClearLinesOfRebates();
			CurrentCounterparty = Object.Counterparty;
			CounterpartyOnChangeServer();
			
		Else
			
			Object.Counterparty = CurrentCounterparty;
			
		EndIf;
		
	Else
		
		CurrentCounterparty = Object.Counterparty;
		CounterpartyOnChangeServer();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PartnerOnChange(Item)
	
	PartnerOnChangeServer();
	
EndProcedure

&AtClient
Procedure ContractOnChange(Item)
	
	ContractOnChangeServer();
	
EndProcedure

// Parameters:
//  Item - FormDecoration - Item
//  StandardProcessing - Boolean
//
&AtClient
Procedure InscriptionDecorationOfCurrencyAndRateOfPaymentClick(Item, StandardProcessing)
	
	Try
		
		LockFormDataForEdit();
		
	Except
		
		ShowMessageBox(, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return;
		
	EndTry;
	
	Notification = New CallbackDescription("CurrencyDecorationAndPaymentRateClickCompletion", ThisObject);
	
	FillInInformationOnBonusCurrencies();
	RateVisibility = (Not MultipleCurrencyBonuses
					  And Object.Rebates.Count() > 0
					  And Not BonusesCurrency.IsEmpty());
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ReadOnly", ReadOnly);
	OpeningParameters.Insert("BonusesCurrency", BonusesCurrency);
	OpeningParameters.Insert("ARAPCurrency", Object.ARAPCurrency);
	OpeningParameters.Insert("CurrencyOfComplianceAccounting", CurrencyOfComplianceAccounting);
	OpeningParameters.Insert("ExchangeRateNumeratorOfMutualSettlements", ExchangeRateNumeratorOfMutualSettlements);
	OpeningParameters.Insert("TheExchangeRateIsTheDenominatorOfMutualSettlements", TheExchangeRateIsTheDenominatorOfMutualSettlements);
	OpeningParameters.Insert("CurrencyChangeBan", Not Object.Contract.IsEmpty());
	OpeningParameters.Insert("RateVisibility", RateVisibility);
	OpeningParameters.Insert("Contract", Object.Contract);
	OpeningParameters.Insert("DateOfCurrencyExchangeRate", Object.Date);
	
	OpenForm("Document.VendorBonusCertificate.Form.CurrenciesAndRates", OpeningParameters, ThisObject,,,, Notification);
	
EndProcedure

&AtClient
Procedure PresentationOfRecordingInComplAccountingClick(Item, StandardProcessing)
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	Return;
	
EndProcedure

&AtClient
Procedure IncomeLiabilityItemStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure IncomeLiabilityItemOnChange(Item)
	
	AssetRefOnChangeServer(Item.Name);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRebates

&AtClient
Procedure RebatesTermsAndConditionsDocumentOnChange(Item)
	
	CurrentData = Items.Rebates.CurrentData;
	IDCurrentRow = CurrentData.GetID();
	
	RebatesTermsAndConditionsDocumentOnChangeServer(IDCurrentRow);
	
EndProcedure

&AtClient
Procedure RebatesBonusAmountOnChange(Item)
	
	RebatesBonusAmountOnChangeServer();
	
EndProcedure

&AtClient
Procedure RebatesBonusCurrencyOnChange(Item)
	
	RebatesBonusCurrencyOnChangeServer();
	
EndProcedure

&AtClient
Procedure RebatesExchangeRateNumeratorOfMutualSettlementsOnChange(Item)
	
	RebatesExchangeRateNumeratorOfMutualSettlementsOnChangesAtServer();
	
EndProcedure

&AtClient
Procedure RebatesOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateTotals();
	
EndProcedure

&AtClient
Procedure RebatesAfterDeleteRow(Item)
	
	RebatesAfterDeleteRowServer();
	
EndProcedure

&AtClient
Procedure PartnerSRetroRebatesOnChange(Item)
	
	SetSelectionOfContractInRebates();
	
EndProcedure

&AtClient
Procedure RebatesOnActivateRow(Item)
	
	SetSelectionOfContractInRebates();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject, True);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);

EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

// StandardSubsystems.AttachableCommands

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

// StandardSubsystems.FilesOperations

// Parameters:
//  Command - FormCommand - executed command.
//
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
	
EndProcedure

// End StandardSubsystems.FilesOperations

// End StandardSubsystems.AttachableCommands

&AtClient
Procedure PickUpByBalance(Command)
	
	ClearMessages();
	Cancel = False;
	FieldKind = "Field";
	MessageKind = "FillType";
	
	FieldsToCheck = New Map;
	FieldsToCheck.Insert("Organization", NStr("vi = 'Doanh nghiệp';
												|ru = 'Организация';
												|en = 'Company'; fa = 'Company';
												|it = 'Организация';
												|pl = 'Firma';
												|tr = 'İş yeri'"));
	FieldsToCheck.Insert("Counterparty", NStr("vi = 'Đối tác';
												|ru = 'Контрагент';
												|en = 'Counterparty'; fa = 'طرف حساب';
												|it = 'Контрагент';
												|pl = 'Kontrahent';
												|tr = 'Cari hesap'"));
	FieldsToCheck.Insert("Date", NStr("vi = 'Ngày';
										|ru = 'Дата';
										|en = 'Date'; fa = 'تاریخ';
										|it = 'Дата';
										|pl = 'Date';
										|tr = 'Tarih'"));
	
	For Each CurrentField In FieldsToCheck Do
		
		Field = CurrentField.Key;
		
		If Not ValueIsFilled(Object[Field]) Then
			
			FieldName = CurrentField.Value;
			MessageText = CommonClientServer.FillingErrorText(FieldKind, MessageKind, FieldName);
			CommonClient.MessageToUser(MessageText,, Field, "Object", Cancel);
			
		EndIf;
		
	EndDo;
	
	If Not Cancel Then
		
		PickUpAccruedRB();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region EventHandlersForFormHeaderElementsAuxiliary

&AtServer
Procedure DateOnChangeServer()
	
	FieldsNames = New Array; // Array of String
	FieldsNames.Add("Date");
	FieldsNames.Add("ARAPCurrency");
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, FieldsNames);
	
	UpdateSettlementDataInLines();
	CalculateTotals();
	
EndProcedure

&AtServer
Procedure OrganizationOnChangeServer()
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	SetupParameters = Documents.VendorBonusCertificate.AccountingAccountSettings_();
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Organization, ARAPCurrency");
	
	SetVisibilityByCurrency();
	UpdateSettlementDataInLines();
	CalculateTotals();
	SetParametersForSelectingConditionDocuments()
	
EndProcedure

&AtServer
Procedure CounterpartyOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Counterparty");
	
	If ValueIsFilled(Object.Counterparty) Then
		
		Object.Partner = Common.ObjectAttributeValue(Object.Counterparty, "Partner");
		
	EndIf;
	SetParametersForSelectingConditionDocuments();
	
EndProcedure

&AtServer
Procedure PartnerOnChangeServer()
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "Partner");
	
EndProcedure

&AtServer
Procedure ContractOnChangeServer()
	
	If CurContract = Object.Contract Then
		Return;
	EndIf;
	
	If Object.Contract.IsEmpty() Then
		
		ContractRateOption = Enums.ContractRateOptions.EmptyRef();
		
	Else
		
		// In the case when we just cleared the Contract, we keep the same currency
		
		Object.ARAPCurrency = Catalogs.Currencies.EmptyRef();
		
		NamesOfContractDetails = "ARAPCurrency,LineOfBusiness,ContractRateOption";
		ContractDetails_ = Common.ObjectAttributesValues(Object.Contract, NamesOfContractDetails);
		Object.ARAPCurrency = ContractDetails_.ARAPCurrency;
		Object.LineOfBusiness = ContractDetails_.LineOfBusiness;
		ContractRateOption = ContractDetails_.ContractRateOption;
		
		FieldsNames = New Array; // Array of String
		FieldsNames.Add("Contract");
		FieldsNames.Add("ARAPCurrency");
		ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, FieldsNames);
		ARAPAccountingFormWork.WhenChangingParametersOfMechanism(ThisObject);
		
		UpdateSettlementDataInLines();
		SetVisibilityByCurrency();
		CalculateTotals();
		
	EndIf;
	
EndProcedure

// Parameters:
//  CompletionParameters - See RebatesClientServer.EndParametersForSpecifyingExchangeRateCurrency
//  AdditionalParameters - Arbitrary
//
&AtClient
Procedure CurrencyDecorationAndPaymentRateClickCompletion(CompletionParameters, AdditionalParameters) Export
	
	If TypeOf(CompletionParameters) <> Type("Structure") Then
		Return;
	EndIf;
	
	If Object.ARAPCurrency <> CompletionParameters.ARAPCurrency
	 Or ExchangeRateNumeratorOfMutualSettlements <> CompletionParameters.CourseNumerator
	 Or TheExchangeRateIsTheDenominatorOfMutualSettlements <> CompletionParameters.CourseDenominator Then
		
		CurrencyDecorationAndPaymentRateClickFinishOnServer(CompletionParameters);
		
	EndIf;
	
EndProcedure

// Parameters:
//  CompletionParameters - See RebatesClientServer.EndParametersForSpecifyingExchangeRateCurrency
//
&AtServer
Procedure CurrencyDecorationAndPaymentRateClickFinishOnServer(Val CompletionParameters)
	
	Object.ARAPCurrency = CompletionParameters.ARAPCurrency;
	
	ARAPAccountingFormWork.FormWhenChangingBankingDetails(ThisObject, "ARAPCurrency", True);
	
	For Each TableRow In Object.Rebates Do
		
		If Object.Organization.IsEmpty() Then
			
			TableRow.ExchangeRateNumeratorOfMutualSettlements = 0;
			TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 0;
			
		ElsIf ExchangeRateNumeratorOfMutualSettlements <> CompletionParameters.CourseNumerator
			  Or TheExchangeRateIsTheDenominatorOfMutualSettlements <> CompletionParameters.CourseDenominator Then
			
			TableRow.ExchangeRateNumeratorOfMutualSettlements = CompletionParameters.CourseNumerator;
			TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = CompletionParameters.CourseDenominator;
			
		Else
			
			FillInCourseAndMultiplicityInLine(TableRow);
			
		EndIf;
		
		FormCourseDenominatorByText(TableRow, Object.ARAPCurrency);
		CalculateAmountOfSettlementsInLine(TableRow);
		
	EndDo;
	
	SetVisibilityByCurrency();
	CalculateTotals();
	
EndProcedure

&AtServer
Procedure AssetRefOnChangeServer(Val TagName)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	SetupParameters = Documents.VendorBonusCertificate.AccountingAccountSettings_();
	GLAccountSettingsServer.WhenChangingSettings(ThisObject, SetupParameters);
EndProcedure

#EndRegion

#Region EventHandlersForRebatesTableElements

&AtServer
Procedure RebatesAfterDeleteRowServer()
	
	FillInInformationOnBonusCurrencies();
	SetVisibilityByCurrency();
	CalculateTotals();
	
EndProcedure

&AtServer
Procedure RebatesTermsAndConditionsDocumentOnChangeServer(Val IDCurrentRow)
	
	TableRow = Object.Rebates.FindByID(IDCurrentRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInCurrencyIndicationForRebatesOfSuppliers",
		New Structure("TermDocument", "CurrencyIsDeterminedByCondition"));
	StructureOfActions.Insert(
		"FillInCurrencyOfVendorSRebates",
		New Structure("TermDocument", "BonusCurrency"));
	
	CacheOfValues = Undefined;
	BatchProcessingOfTablePartServer.ProcessTSString(
		TableRow,
		StructureOfActions,
		CacheOfValues,
		Object.Rebates);
	
	FillInCourseAndMultiplicityInLine(TableRow);
	FormCourseDenominatorByText(TableRow, Object.ARAPCurrency);
	CalculateAmountOfSettlementsInLine(TableRow);
	
	FillInInformationOnBonusCurrencies();
	SetVisibilityByCurrency();
	CalculateTotals();
	
EndProcedure

&AtServer
Procedure RebatesBonusAmountOnChangeServer()
	
	RowID = Items.Rebates.CurrentRow; // Number
	TableRow = Object.Rebates.FindByID(RowID);
	
	CalculateAmountOfSettlementsInLine(TableRow);
	
	CalculateTotals();
	
EndProcedure

&AtServer
Procedure RebatesBonusCurrencyOnChangeServer()
	
	RowID = Items.Rebates.CurrentRow; // Number
	TableRow = Object.Rebates.FindByID(RowID);
	
	FillInCourseAndMultiplicityInLine(TableRow);
	FormCourseDenominatorByText(TableRow, Object.ARAPCurrency);
	CalculateAmountOfSettlementsInLine(TableRow);
	
	FillInInformationOnBonusCurrencies();
	SetVisibilityByCurrency();
	CalculateTotals();
	
EndProcedure

&AtServer
Procedure RebatesExchangeRateNumeratorOfMutualSettlementsOnChangesAtServer()
	
	RowID = Items.Rebates.CurrentRow; // Number
	TableRow = Object.Rebates.FindByID(RowID);
	
	CalculateAmountOfSettlementsInLine(TableRow);
	FormCourseDenominatorByText(TableRow, Object.ARAPCurrency);
	CalculateTotals();
	
EndProcedure

#EndRegion

#Region ConditionalAppearance

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	SetDesignOfRebatesCurrencyOfBonus();
	SetDesignRebatesCourseNumeratorOfMutualSettlements();
	
EndProcedure

&AtServer
Procedure SetDesignOfRebatesCurrencyOfBonus()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RebatesBonusCurrency.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Rebates.CurrencyIsDeterminedByCondition");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

&AtServer
Procedure SetDesignRebatesCourseNumeratorOfMutualSettlements()
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RebatesExchangeRateNumeratorOfMutualSettlements.Name);
	
	Item.Appearance.SetParameterValue("Text", "");
	
EndProcedure

#EndRegion

#Region SelectionByStock

&AtClient
Async Procedure PickUpAccruedRB()
	
	QuestionIsRequired = False;
	If Object.Posted Then
		
		QuestionIsRequired = True;
		QueryText = NStr("vi = 'Trước khi chọn phương án tính, cần hủy kết chuyển chứng từ. Tiếp tục?';
						|ru = 'Перед подбором начислений необходимо отменить проведение документа. Продолжить?';
						|en = 'Before you pick accruals, unpost the document. Continue?'; fa = 'Before you pick accruals, unpost the document. Continue?';
						|it = 'Перед подбором начислений необходимо отменить проведение документа. Продолжить?';
						|pl = 'Before you pick accruals, unpost the document. Continue?';
						|tr = 'Tahakkukları seçmeden önce belge işlemini iptal etmelisiniz. Devam edilsin mi?'");
		
	EndIf;
	
	If QuestionIsRequired Then
		
		Response = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo); // DialogReturnCode
		If Response = DialogReturnCode.No Then
			Return;
		Else
			
			If Object.Posted Then
				Write(New Structure("WriteMode", DocumentWriteMode.UndoPosting));
			EndIf;
			
		EndIf;
		
	EndIf;
	
	PickUpAccruedRBContinue();
	
EndProcedure

&AtClient
Procedure PickUpAccruedRBContinue()
	
	AddressOfTableOfSelectedRows = AddressOfTableOfSelectedRows();
	
	PickingParameters = New Structure;
	PickingParameters.Insert("Organization", Object.Organization);
	PickingParameters.Insert("Counterparty", Object.Counterparty);
	PickingParameters.Insert("AddressOfTableOfSelectedRows", AddressOfTableOfSelectedRows);
	PickingParameters.Insert("ChoiceMode", True);
	PickingParameters.Insert("UpdateDate", Object.Date);
	
	Notification = New CallbackDescription("PickUpAccruedRBCompletion", ThisObject);
	
	OpenForm("AccumulationRegister.VendorRebates.Form.FormForPickingByBalance",
		PickingParameters, ThisObject,,,, Notification);
	
EndProcedure

&AtServer
Function AddressOfTableOfSelectedRows()
	
	Table_SelectedRows = Object.Rebates.Unload();
	Table_SelectedRows.Columns.Add("DocumentSelected", New TypeDescription("Boolean"));
	Table_SelectedRows.Columns.Add("Check", New TypeDescription("Boolean"));
	Table_SelectedRows.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	
	For Each TableRow In Table_SelectedRows Do
		
		TableRow.DocumentSelected = True;
		TableRow.Check = True;
		TableRow.Currency = TableRow.BonusCurrency;
		
	EndDo;
	
	AddressOfTableOfSelectedRows = PutToTempStorage(Table_SelectedRows, UUID);
	
	Return AddressOfTableOfSelectedRows;
	
EndFunction

// Parameters:
//  Result - Undefined, String - 
//  AdditionalParameters - Arbitrary -
//
&AtClient
Procedure PickUpAccruedRBCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined
	   And IsTempStorageURL(Result) Then
		
		ProcessingSelectionOfAccrualDocuments(Result);
		Modified = True;
		
	EndIf;
	
EndProcedure

// Parameters:
//  AddressInStorage - String - Address in the store
//
&AtServer
Procedure ProcessingSelectionOfAccrualDocuments(Val AddressInStorage)
	
	BalanceTable = TableOfSelectedBalances(AddressInStorage);
	DeleteFromTempStorage(AddressInStorage);
	
	Object.Rebates.Clear();
	
	For Each CurrentRow In BalanceTable Do
		
		NewRow = Object.Rebates.Add();
		FillPropertyValues(NewRow, CurrentRow);
		NewRow.BonusCurrency = CurrentRow.Currency;
		NewRow.BonusAmount = CurrentRow.Sum;
		
	EndDo;
	
	UpdateSettlementDataInLines();
	PerformOfficialFillingProcedures();
	
EndProcedure

// Parameters:
//  AddressInStorage - String - Address in the store
// 
// Returns:
//  ValueTable:
//   * TermDocument - DocumentRef.ConditionsOfVendorRebates
//   * Partner - CatalogRef.Partners
//   * Contract - CatalogRef.CounterpartyContracts
//   * RebateKind - CatalogRef.VendorRebateKinds
//   * LongDesc - String
//   * ValidOnDate - Date
//   * ValidTo - Date
//   * Sum - DefinedType.MonetaryAmountPositiveNegative
//   * Currency - CatalogRef.Currencies
//
&AtServer
Function TableOfSelectedBalances(AddressInStorage)
	
	Return GetFromTempStorage(AddressInStorage);
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure EstablishRelationshipsBetweenContractSelectionParameters()
	
	RelationshipsOfContractParameters = New Array(); // Array of ChoiceParameterLink
	
	NewLink = New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty");
	RelationshipsOfContractParameters.Add(NewLink);
	
	NewLink = New ChoiceParameterLink("Filter.Organization", "Object.Organization");
	RelationshipsOfContractParameters.Add(NewLink);
	
	NewLink = New ChoiceParameterLink("Partner", "Object.Partner");
	RelationshipsOfContractParameters.Add(NewLink);
	
	Items.Contract.ChoiceParameterLinks = New FixedArray(RelationshipsOfContractParameters);
	
	ContractSelectionParameters_ = New Array(); // Array of ChoiceParameter
	
	NewParameter1 = New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid);
	ContractSelectionParameters_.Add(NewParameter1);
	
	NewParameter1 = New ChoiceParameter("Filter.DeletionMark", False);
	ContractSelectionParameters_.Add(NewParameter1);
	
	ContractTypes = RebatesClientServer.TypesOfProcurementContracts();
	NewParameter1 = New ChoiceParameter("Filter.ContractType",  New FixedArray(ContractTypes));
	ContractSelectionParameters_.Add(NewParameter1);
	
	Items.Contract.ChoiceParameters = New FixedArray(ContractSelectionParameters_);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtServer
Procedure OnCreatReadAtServer()
	
	CurrencyOfComplianceAccounting = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	FillMultiplicityCourseWithText();
	PerformOfficialFillingProcedures();
	
	CurrentCounterparty = Object.Counterparty;
	CurrentCompany = Object.Organization;
	
EndProcedure

&AtServer
Procedure PerformOfficialFillingProcedures()
	
	FillInServiceAttributesOfRebates();
	FillInInformationOnBonusCurrencies();
	SetVisibilityByCurrency();
	EstablishRelationshipsBetweenContractSelectionParameters();
	SetParametersForSelectingConditionDocuments();
	CalculateTotals();
	
EndProcedure

&AtServer
Procedure FillInServiceAttributesOfRebates()
	
	If Not DocumentModificationIsAvailable Then
		
		// If we can't change the document by rights, then we don't see the TS either, it doesn't need to be filled in 
		Return;
		
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert(
		"FillInCurrencyIndicationForRebatesOfSuppliers",
		New Structure("TermDocument", "CurrencyIsDeterminedByCondition"));
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Rebates, StructureOfActions);
	
EndProcedure

&AtServer
Procedure UpdateSettlementDataInLines()
	
	KnownParametersByCurrency = New Map;
	
	For Each TableRow In Object.Rebates Do
		
		If Object.Organization.IsEmpty() Then
			
			TableRow.ExchangeRateNumeratorOfMutualSettlements = 0;
			TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = 0;
			
		Else
			
			CourseAndMultiplicity = KnownParametersByCurrency[TableRow.BonusCurrency]; // See CourseNumeratorAndCourseDenominatorOfMutualSettlements
			If CourseAndMultiplicity = Undefined Then
				
				FillParameters = CourseFillingAndMultiplicityParameters();
				FillParameters.Currency = TableRow.BonusCurrency;
				
				CourseAndMultiplicity = CourseNumeratorAndCourseDenominatorOfMutualSettlements(FillParameters);
				KnownParametersByCurrency[TableRow.BonusCurrency] = CourseAndMultiplicity;
				
			EndIf;
			
			TableRow.ExchangeRateNumeratorOfMutualSettlements = CourseAndMultiplicity.CourseNumerator;
			TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAndMultiplicity.CourseDenominator;
			
			FormCourseDenominatorByText(TableRow, Object.ARAPCurrency);
			CalculateAmountOfSettlementsInLine(TableRow);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure CalculateTotals()
	
	AmountARAP = Object.Rebates.Total("AmountARAP");
	
	Items.CurrencyDecorationAndPaymentRate.Title = CurrencyLabelAndPaymentRate();
	
EndProcedure

&AtServer
Function CurrencyLabelAndPaymentRate()
	
	CopyOfRebates = Object.Rebates.Unload(,
		"BonusAmount, BonusCurrency, ExchangeRateNumeratorOfMutualSettlements, TheExchangeRateIsTheDenominatorOfMutualSettlements");
	CopyOfRebates.GroupBy("BonusCurrency, ExchangeRateNumeratorOfMutualSettlements, TheExchangeRateIsTheDenominatorOfMutualSettlements", "BonusAmount");
	
	If Object.ARAPCurrency.IsEmpty() Then
		
		TitleLine = NStr("vi = 'Tính toán: <Chưa chỉ ra tiền tệ>, Thưởng:';
						|ru = 'Расчеты: <Валюта не указана>, Бонусы:';
						|en = 'Calculations: <Currency not specified>, Bonuses:'; fa = 'Calculations: <Currency not specified>, Bonuses:';
						|it = 'Расчеты: <Валюта не указана>, Бонусы:';
						|pl = 'Calculations: <Currency not specified>, Bonuses:';
						|tr = 'Muhasebeler: <Para birimi belirtilmemiş>, Bonuslar:'");
		
	ElsIf Object.Organization.IsEmpty() Then
		
		TitleLine = NStr("vi = 'Tính toán: <hãy chỉ ra doanh nghiệp của chứng từ>, Thưởng:';
						|ru = 'Расчеты: <укажите организацию документа>, Бонусы:';
						|en = 'Calculations: <specify the document company>, Rebates:'; fa = 'Calculations: <specify the document company>, Rebates:';
						|it = 'Расчеты: <укажите организацию документа>, Бонусы:';
						|pl = 'Calculations: <specify the document company>, Rebates:';
						|tr = 'Muhasebeler: <belgede geçen iş yerini belirtin>, Bonuslar:'");
		
	Else
		
		TitleTemplate1 = NStr("vi = 'Tính toán: %1 %2, Thưởng:';
								|ru = 'Расчеты: %1 %2, Бонусы:';
								|en = 'Calculations: %1 %2, Rebates:'; fa = 'Calculations: %1 %2, Rebates:';
								|it = 'Расчеты: %1 %2, Бонусы:';
								|pl = 'Calculations: %1 %2, Rebates:';
								|tr = 'Muhasebeler: %1 %2, Bonuslar:'");
		TitleLine = StringFunctionsClientServer.SubstituteParametersToString(
			TitleTemplate1,
			Format(AmountARAP, "NFD=2;"),
			String(Object.ARAPCurrency));
		
	EndIf;
	
	CourseTemplate = "(%1 %2 = %3 %4)";
	CaptionLines = New Array; // Array of String
	CaptionLines.Add(TitleLine);
	
	For Each TableRow In CopyOfRebates Do
		
		CaptionLines.Add(String(TableRow.BonusAmount));
		CaptionLines.Add(String(TableRow.BonusCurrency));
		
		If TableRow.ExchangeRateNumeratorOfMutualSettlements <> 0
		   And Not Object.ARAPCurrency.IsEmpty()
		   And Not CurrencyOfComplianceAccounting.IsEmpty() Then
			
			If TableRow.BonusCurrency = CurrencyOfComplianceAccounting Then
				
				LabelText = StrTemplate(
					CourseTemplate,
					TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements,
					Object.ARAPCurrency,
					Format(TableRow.ExchangeRateNumeratorOfMutualSettlements, "NFD=4"),
					TableRow.BonusCurrency);
				
			Else
				
				LabelText = StrTemplate(
					CourseTemplate,
					TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements,
					TableRow.BonusCurrency,
					Format(TableRow.ExchangeRateNumeratorOfMutualSettlements, "NFD=4"),
					Object.ARAPCurrency);
				
			EndIf;
			
			CaptionLines.Add(LabelText);
			
		EndIf;
		
	EndDo;
	
	Return StrConcat(CaptionLines, " ");
	
EndFunction

&AtServer
Procedure FillMultiplicityCourseWithText()
	
	For Each TSRow In Object.Rebates Do
		
		FormCourseDenominatorByText(TSRow, Object.ARAPCurrency);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FormCourseDenominatorByText(TSRow, RecalculationCurrency)
	
	CourseTemplate = "%1 %2 = %3 %4";
	If TSRow.ExchangeRateNumeratorOfMutualSettlements <> 0 Then
		
		If TSRow.BonusCurrency = CurrencyOfComplianceAccounting Then
			
			TSRow.CourseNumeratorOfMutualSettlementsText = StrTemplate(
				CourseTemplate,
				TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements,
				RecalculationCurrency,
				Format(TSRow.ExchangeRateNumeratorOfMutualSettlements, "NFD=4"),
				TSRow.BonusCurrency);
			
		Else
			
			TSRow.CourseNumeratorOfMutualSettlementsText = StrTemplate(
				CourseTemplate,
				TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements,
				TSRow.BonusCurrency,
				Format(TSRow.ExchangeRateNumeratorOfMutualSettlements, "NFD=4"),
				RecalculationCurrency);
			
		EndIf;
		
	Else
		
		TSRow.CourseNumeratorOfMutualSettlementsText = "0";
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculateAmountOfSettlementsInLine(TSRow)
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("Currency", TSRow.BonusCurrency);
	CalculationParameters.Insert("CourseNumerator", TSRow.ExchangeRateNumeratorOfMutualSettlements);
	CalculationParameters.Insert("CourseDenominator", TSRow.TheExchangeRateIsTheDenominatorOfMutualSettlements);
	CalculationParameters.Insert("ARAPCurrency", Object.ARAPCurrency);
	
	TSRow.AmountARAP = RebatesClientServer.RecalculateAmountOfSettlementsInLine(
		CalculationParameters, TSRow.BonusAmount, CurrencyOfComplianceAccounting);
	
EndProcedure

&AtServer
Function CourseFillingAndMultiplicityParameters()
	
	FillParameters = New Structure;
	FillParameters.Insert("ARAPCurrency", Object.ARAPCurrency);
	FillParameters.Insert("Currency", Catalogs.Currencies.EmptyRef());
	FillParameters.Insert("LocalAccountingCurrency", CurrencyOfComplianceAccounting);
	FillParameters.Insert("Contract", Object.Contract);
	FillParameters.Insert("ContractRateOption", ContractRateOption);
	FillParameters.Insert("Date", Object.Date);
	
	Return FillParameters;
	
EndFunction

&AtServer
Procedure FillInCourseAndMultiplicityInLine(TableRow)
	
	FillParameters = CourseFillingAndMultiplicityParameters();
	FillParameters.Currency = TableRow.BonusCurrency;
	
	CourseAndMultiplicity = CourseNumeratorAndCourseDenominatorOfMutualSettlements(FillParameters);
	
	TableRow.ExchangeRateNumeratorOfMutualSettlements = CourseAndMultiplicity.CourseNumerator;
	TableRow.TheExchangeRateIsTheDenominatorOfMutualSettlements = CourseAndMultiplicity.CourseDenominator;
	
EndProcedure

// Parameters:
//  FillParameters - See CourseFillingAndMultiplicityParameters
// 
// Returns:
//  Structure:
// * CourseNumerator - Number -
// * CourseDenominator - Number - 
// * ContractRateOption - EnumRef.ContractRateOptions - 
//
&AtServer
Function CourseNumeratorAndCourseDenominatorOfMutualSettlements(FillParameters)
	
	CourseAndMultiplicity = New Structure;
	CourseAndMultiplicity.Insert("CourseNumerator", 1);
	CourseAndMultiplicity.Insert("CourseDenominator", 1);
	CourseAndMultiplicity.Insert("ContractRateOption", Enums.ContractRateOptions.Mutable);
	
	If FillParameters.Currency <> FillParameters.ARAPCurrency Then
		
		If ValueIsFilled(FillParameters.Contract) Then
			CourseAndMultiplicity.ContractRateOption = FillParameters.ContractRateOption;
		EndIf;
		
		If CourseAndMultiplicity.ContractRateOption = Enums.ContractRateOptions.SpecifiedInContract Then
			
			If FillParameters.Currency = CurrencyOfComplianceAccounting Then
				
				CourseAndMultiplicity = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(
					FillParameters.Contract, FillParameters.Date);
				
			Else
				
				DocumentCourse = ProcessingOfExchangeRatesTM.GetCurrencyRate(
					FillParameters.Currency,
					FillParameters.Date,
					FillParameters.LocalAccountingCurrency);
				TransactionRate = InformationRegisters.ARAPAccountingExchangeRatesForContracts.GetContractCurrencyExchangeRateValues(
					FillParameters.Contract,
					FillParameters.Date);
				CourseAndMultiplicity = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(DocumentCourse,TransactionRate);
				
			EndIf;
			
		Else
			
			If FillParameters.Currency = FillParameters.LocalAccountingCurrency Then
				
				CourseAndMultiplicity = ProcessingOfExchangeRatesTM.GetCurrencyRate(
					FillParameters.ARAPCurrency,
					FillParameters.Date,
					FillParameters.LocalAccountingCurrency);
				
			ElsIf FillParameters.ARAPCurrency = FillParameters.LocalAccountingCurrency Then
				
				CourseAndMultiplicity = ProcessingOfExchangeRatesTM.GetCurrencyRate(
					FillParameters.Currency,
					FillParameters.Date,
					FillParameters.LocalAccountingCurrency);
				
			Else
				
				DocumentCourse = ProcessingOfExchangeRatesTM.GetCurrencyRate(
					FillParameters.Currency,
					FillParameters.Date,
					FillParameters.LocalAccountingCurrency);
				TransactionRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(
					FillParameters.ARAPCurrency,
					FillParameters.Date,
					FillParameters.LocalAccountingCurrency);
				CourseAndMultiplicity = ProcessingOfExchangeRatesTM.GetCrossCurrencyExchangeRate(DocumentCourse,TransactionRate);
				
			EndIf;
			
		EndIf;
		
		CourseAndMultiplicity.Insert("ARAPObjectType", Enums.ARAPObjectTypes.EmptyRef());
		
	EndIf;
	
	Return CourseAndMultiplicity;
	
EndFunction

&AtServer
Procedure SetVisibilityByCurrency()
	
	NamesOfCurrencyElements = New Array; // Array of String
	NamesOfCurrencyElements.Add(Items.RebatesAmountARAP.Name);
	NamesOfCurrencyElements.Add(Items.CourseGroupRebates.Name);
	
	HideCoursesByRow = False;
	If Not MultipleCurrencyBonuses
	 Or Object.ARAPCurrency.IsEmpty()
	 Or CurrencyOfComplianceAccounting.IsEmpty() Then
		
		HideCoursesByRow = True;
		
	EndIf;
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		NamesOfCurrencyElements,
		"Visible",
		Not HideCoursesByRow);
	
EndProcedure

&AtServer
Procedure FillInInformationOnBonusCurrencies()
	
	TableFieldNames = "BonusCurrency, ExchangeRateNumeratorOfMutualSettlements, TheExchangeRateIsTheDenominatorOfMutualSettlements";
	CopyOfBonusTable = Object.Rebates.Unload(, TableFieldNames);
	CopyOfBonusTable.GroupBy(TableFieldNames);
	
	If CopyOfBonusTable.Count() = 0 Then
		
		MultipleCurrencyBonuses = False;
		BonusesCurrency = Catalogs.Currencies.EmptyRef();
		ExchangeRateNumeratorOfMutualSettlements = 0;
		TheExchangeRateIsTheDenominatorOfMutualSettlements = 0;
		
	ElsIf CopyOfBonusTable.Count() = 1 Then
		
		MultipleCurrencyBonuses = False;
		BonusesCurrency = CopyOfBonusTable[0].BonusCurrency;
		ExchangeRateNumeratorOfMutualSettlements = CopyOfBonusTable[0].ExchangeRateNumeratorOfMutualSettlements;
		TheExchangeRateIsTheDenominatorOfMutualSettlements = CopyOfBonusTable[0].TheExchangeRateIsTheDenominatorOfMutualSettlements;
		
	Else
		
		MultipleCurrencyBonuses = True;
		BonusesCurrency = Catalogs.Currencies.EmptyRef();
		ExchangeRateNumeratorOfMutualSettlements = 0;
		TheExchangeRateIsTheDenominatorOfMutualSettlements = 0;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearLinesOfRebates()
	
	ArrayToDelete = New Array;  // Array of FormDataCollectionItem
	
	For Each CurrentRow In Object.Rebates Do
		
		If ValueIsFilled(CurrentRow.TermDocument) Then
			
			ArrayToDelete.Add(CurrentRow);
			
		EndIf;
		
	EndDo;
	
	TMCommonUse.DeleteTableRows(Object.Rebates, ArrayToDelete);
	
EndProcedure

&AtClient
Function ItIsNecessaryToClearRebates()
	
	NeedToCleanUp = False;
	
	If Object.Rebates.Count() > 0 
	   And (CurrentCompany <> Object.Organization
	     Or CurrentCounterparty <> Object.Counterparty) Then
		
		For Each CurrentRow In Object.Rebates Do
			
			If ValueIsFilled(CurrentRow.TermDocument) Then
				
				NeedToCleanUp = True;
				Break;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return NeedToCleanUp;
	
EndFunction

&AtServer
Procedure SetParametersForSelectingConditionDocuments()
	
	ParametersForSelectingConditionDocument = New Array(); // Array of ChoiceParameter
	
	NewParameter1 = New ChoiceParameter("Filter.Organization", Object.Organization);
	ParametersForSelectingConditionDocument.Add(NewParameter1);
	
	NewParameter1 = New ChoiceParameter("Counterparty", Object.Counterparty);
	ParametersForSelectingConditionDocument.Add(NewParameter1);
	
	NewParameter1 = New ChoiceParameter("PickupByCounterparty", True);
	ParametersForSelectingConditionDocument.Add(NewParameter1);
	
	Items.RebatesTermDocument.ChoiceParameters = New FixedArray(ParametersForSelectingConditionDocument);
	
EndProcedure

&AtClient
Procedure SetSelectionOfContractInRebates()
	
	RowData = Items.Rebates.CurrentData;
	ContractSelectionParameters_ = ContractSelectionParameters_(RowData);
	Items.RebatesContract.ChoiceParameters = New FixedArray(ContractSelectionParameters_);
	
EndProcedure

&AtClient
Function ContractSelectionParameters_(RowData)
	
	SupportedContractTypes = RebatesClientServer.TypesOfProcurementContracts();
	
	ContractSelectionParameters_ = New Array(); // Array of ChoiceParameter
	
	FilterType = New ChoiceParameter("Filter.ContractType", New FixedArray(SupportedContractTypes));
	ContractSelectionParameters_.Add(FilterType);
	
	FilterCheck = New ChoiceParameter("Filter.DeletionMark", False);
	ContractSelectionParameters_.Add(FilterCheck);
	
	If RowData <> Undefined
	   And ValueIsFilled(RowData.Partner) Then
		
		NewFilter = New ChoiceParameter("Partner", RowData.Partner);
		ContractSelectionParameters_.Add(NewFilter);
		
	EndIf;
	
	Return ContractSelectionParameters_;
	
EndFunction

#EndRegion

#Region StandardSubsystems_PlugInCommands

// StandardSubsystems.AttachableCommands

// The Attachable one continues to execute the Commands on the server.
// 
// Parameters:
//  ExecutionParameters - Structure -
//  AdditionalParameters - Structure -
//
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

// IntegrationWith1CDocumentManagementSubsystem

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

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
