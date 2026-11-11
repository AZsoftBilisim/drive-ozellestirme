#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	TransitionDate = Date('00010101');
	If AdditionalParameters <> Undefined Then
		AdditionalParameters.Property("NewDate", TransitionDate);
	EndIf;
	
	Status = Enums.StatusesOfCustomerInvoices[NewStatus];
	
	// Setting the date of transfer of ownership
	If ValueIsFilled(TransitionDate) Then
		
		If BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
			Or BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer Then
			DateOfTransferOfTitleToGoods = TransitionDate;
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	ARAPDetails.Clear();
	
	FillParameters = Documents.CustomerInvoiceServicesAndAssets.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = True;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Income, StructureOfActions, CachedValues);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Income,
		CachedValues);
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Income,Expenses");
	
	CustomerInvoiceServicesAndAssetsLocalization.OnCopy(ThisObject, CopiedObject);
	Author = Users.CurrentUser();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	AttributesNotToCheck.Add("Expenses");
	AttributesNotToCheck.Add("Expenses.AssetKind");
	AttributesNotToCheck.Add("Expenses.NonCurrentAsset");
	AttributesNotToCheck.Add("Expenses.AmountOfDepreciationAllowance");
	AttributesNotToCheck.Add("Expenses.IncomeItem");
	AttributesNotToCheck.Add("Expenses.DimensionOfRevenue");
	AttributesNotToCheck.Add("Income.RentalObject");
	
	If Not ValueIsFilled(BusinessOperation)
		Or BusinessOperation <> Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle 
			And BusinessOperation <> Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer Then
		AttributesNotToCheck.Add("Status");
		AttributesNotToCheck.Add("DateOfTransferOfTitleToGoods");
	EndIf;
	
	If Not ValueIsFilled(Status)
		Or Status <> Enums.StatusesOfCustomerInvoices.Shipped Then
		AttributesNotToCheck.Add("DateOfTransferOfTitleToGoods");
	EndIf;
	
	If Not ValueIsFilled(Terms)
		Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		AttributesNotToCheck.Add("Contract");
	EndIf;
	If BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale
		Or BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer Then
		AttributesNotToCheck.Add("Expenses.ExpenseItem");
		AttributesNotToCheck.Add("Expenses.AssetAndLiabilityItem");
		CheckSaleOfNonCurrentAssets(AttributesNotToCheck, Cancel);
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.RenderRentalServices Then
		CheckImplementationOfRentalServices(Cancel);
	EndIf;
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	SalesServer.CheckShipmentBan(Partner, Cancel);
	
	ItemsAndDimensionsSelectionParameters = Documents.CustomerInvoiceServicesAndAssets.ItemsAndDimensionsSelectionParameters(
		BusinessOperation, SaleToAssociatedPerson);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	CustomerInvoiceServicesAndAssetsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);

	If WriteMode = DocumentWriteMode.UndoPosting Then
		ThereAreAdjustingEntries = False;
		SalesServer.CheckForAdjustments(Ref, Ref, ThereAreAdjustingEntries);
        If ThereAreAdjustingEntries Then
			SalesServer.ReportErrorsCancellationsAndAdjustments(Ref,Cancel);
		EndIf; 
	EndIf;
	
	RegistrationParameters = Documents.CustomerInvoiceServicesAndAssets.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	If WriteMode = DocumentWriteMode.Posting Then
		TopUpRevenueData();
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Income,Expenses");
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Income, PriceIncludesVAT);
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.CustomerInvoiceServicesAndAssets.AccountingAccountSettings_(BusinessOperation));
	ItemsAndDimensionsSelectionParameters = Documents.CustomerInvoiceServicesAndAssets.ItemsAndDimensionsSelectionParameters(
		BusinessOperation, SaleToAssociatedPerson);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	SetPropertiesForChangingBankingDetails(ThisObject, AdditionalProperties);
	
	CustomerInvoiceServicesAndAssetsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	AdditionalProperties.Insert("DocumentNumber", Number);
	
	CustomerInvoiceServicesAndAssetsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	If AdditionalProperties.Property("OnlyStateOfTransferOfOwnershipHasChanged")
		And AdditionalProperties.OnlyStateOfTransferOfOwnershipHasChanged Then
		SkipCheckingProhibitionOfChangingRegisters(RegisterRecords);
	EndIf;
	
	CreateTasksForEndOfMonth();

	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	CustomerInvoiceServicesAndAssetsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	If Not AdditionalProperties.OnlyStateOfTransferOfOwnershipHasChanged Then
		RegistrationParameters = Documents.CustomerInvoiceServicesAndAssets.ParametersForRegisteringInvoicesIssued(ThisObject);
		VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	EndIf;
	

EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	CustomerInvoiceServicesAndAssetsLocalization.UndoPosting(ThisObject, Cancel);
	
	RegistrationParameters = Documents.CustomerInvoiceServicesAndAssets.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("CatalogRef.TermsOfSale") Then
		SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(FillingData);
		
		SalesServer.CheckPossibilityOfEnteringOnBasisOfAgreement("CustomerInvoiceServicesAndAssets",
			SalesTermsAndConditions.BusinessOperation);
		
		AcceptableStatuses = New Array();
		AcceptableStatuses.Add(Enums.StatusesOfTermsOfSales.Valid);
		StatusErrors = (SalesTermsAndConditions.AgreementStatus <> Enums.StatusesOfTermsOfSales.Valid);
		TMCommonUse.CheckPossibilityOfEnteringOnBasisOfAgreement(SalesTermsAndConditions.Standard_);
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(FillingData, SalesTermsAndConditions.AgreementStatus, , StatusErrors, AcceptableStatuses);
		
		If (Not SalesTermsAndConditions.Standard_) And ValueIsFilled(SalesTermsAndConditions.Partner) Then
			Partner = SalesTermsAndConditions.Partner;
		EndIf;
		Terms = FillingData;
		Documents.CustomerInvoiceServicesAndAssets.FillInByTermsOfSales(ThisObject, SalesTermsAndConditions);
	ElsIf FillInDataType = Type("DocumentRef.PreparingForIntangibleAssetSale2_4") Then
		FillInDocumentPreparationForTransferOfNMA2_4(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.PreparingForFixedAssetSale2_4") Then
		FillInDocumentPreparationForTransferOfOS2_4(FillingData);
	EndIf;

	CustomerInvoiceServicesAndAssetsLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	FillOutBankAccounts();

	FillParameters = Documents.CustomerInvoiceServicesAndAssets.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	ItemsAndDimensionsSelectionParameters = Documents.CustomerInvoiceServicesAndAssets.ItemsAndDimensionsSelectionParameters(
		BusinessOperation, SaleToAssociatedPerson);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	Prefix = TMCommonUseCached.AdditionalPrefixOfNumeratorDocumentsOfSaleOfGoods();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	Documents.CustomerInvoiceServicesAndAssets.FillByDefault(ThisObject);
	
EndProcedure

Procedure FillInDocumentPreparationForTransferOfOS2_4(FillingData)
	
	QueryText =
	"SELECT
	|	Operation.Ref AS Ref,
	|	Operation.Organization AS Organization,
	|	Operation.Department AS Department,
	|	TabularSection.FixedAsset AS FixedAsset,
	|	Operation.Partner AS Partner,
	|	Operation.Counterparty AS Counterparty,
	|	Operation.Currency AS Currency,
	|	Operation.PriceIncludesVAT AS PriceIncludesVAT,
	|	Operation.VATTaxation AS VATTaxation,
	|	Operation.Basis AS Basis,
	|	Operation.ReferenceDocumentDateForPrintForms AS ReferenceDocumentDateForPrintForms,
	|	Operation.BaseDocumentNumber AS BaseDocumentNumber,
	|	Operation.Shipper AS Shipper,
	|	Operation.GoodsRecipient AS GoodsRecipient,
	|	Operation.CompanyBankAccount AS CompanyBankAccount,
	|	Operation.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	Operation.ShipperBankAccount AS ShipperBankAccount,
	|	Operation.GoodsRecipientBankAccount AS GoodsRecipientBankAccount,
	|	Operation.IssuiedBy AS IssuiedBy,
	|	Operation.IssuiedByJobTitle AS IssuiedByJobTitle,
	|	Operation.Director AS Director,
	|	Operation.ChiefAccountant AS ChiefAccountant,
	|	TabularSection.Sum AS Price,
	|	TabularSection.Sum AS Sum,
	|	TabularSection.VATRate AS VATRate,
	|	TabularSection.VATAmount AS VATAmount,
	|	TabularSection.AmountIncludingVAT AS AmountIncludingVAT
	|INTO TTBaseData
	|FROM
	|	Document.PreparingForFixedAssetSale2_4 AS Operation
	|		INNER JOIN Document.PreparingForFixedAssetSale2_4.FA AS TabularSection
	|		ON Operation.Ref = TabularSection.Ref
	|WHERE
	|	Operation.Ref = &FillingData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TRUE AS SaleBasedOn,
	|	TTBaseData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale) AS BusinessOperation,
	|	VALUE(Enum.StatusesOfCustomerInvoices.Shipped) AS Status,
	|	TTBaseData.Organization AS Organization,
	|	TTBaseData.Department AS Department,
	|	TTBaseData.Partner AS Partner,
	|	TTBaseData.Counterparty AS Counterparty,
	|	TTBaseData.Currency AS Currency,
	|	TTBaseData.PriceIncludesVAT AS PriceIncludesVAT,
	|	TTBaseData.VATTaxation AS VATTaxation,
	|	TTBaseData.Basis AS Basis,
	|	TTBaseData.ReferenceDocumentDateForPrintForms AS ReferenceDocumentDateForPrintForms,
	|	TTBaseData.BaseDocumentNumber AS BaseDocumentNumber,
	|	TTBaseData.Shipper AS Shipper,
	|	TTBaseData.GoodsRecipient AS GoodsRecipient,
	|	TTBaseData.CompanyBankAccount AS CompanyBankAccount,
	|	TTBaseData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	TTBaseData.ShipperBankAccount AS ShipperBankAccount,
	|	TTBaseData.GoodsRecipientBankAccount AS GoodsRecipientBankAccount,
	|	TTBaseData.IssuiedBy AS IssuiedBy,
	|	TTBaseData.IssuiedByJobTitle AS IssuiedByJobTitle,
	|	TTBaseData.Director AS Director,
	|	TTBaseData.ChiefAccountant AS ChiefAccountant
	|FROM
	|	TTBaseData AS TTBaseData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PRESENTATION(TTBaseData.FixedAsset) AS Content,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.FixedAssetSale) AS IncomeItem,
	|	TTBaseData.FixedAsset AS DimensionOfRevenue,
	|	&UnitOfMeasurementPieces AS UnitOfMeasure,
	|	1 AS Count,
	|	TTBaseData.Sum AS Price,
	|	TTBaseData.Sum AS Sum,
	|	TTBaseData.VATRate AS VATRate,
	|	TTBaseData.VATAmount AS VATAmount,
	|	TTBaseData.AmountIncludingVAT AS AmountIncludingVAT
	|FROM
	|	TTBaseData AS TTBaseData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets) AS AssetAndLiabilityItem,
	|	TTBaseData.FixedAsset AS AssetsLiabilitiesDimension,
	|	VALUE(Enum.KindsOfNonCurrentAssets.FixedAsset) AS AssetKind,
	|	TTBaseData.FixedAsset AS NonCurrentAsset
	|FROM
	|	TTBaseData AS TTBaseData";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", CurrentSessionDate());
	Query.SetParameter("FillingData", FillingData);
	Query.SetParameter("UnitOfMeasurementPieces", Catalogs.PackagesAndUnitsOfMeasure.FindByCode("796", False));
	
	Package = Query.ExecuteBatch();
	
	Selection = Package[Package.Count()-3].Select();
	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection);
	EndIf;
	
	Income.Load(Package[Package.Count()-2].Unload());
	Expenses.Load(Package[Package.Count()-1].Unload());
	
	CustomerInvoiceServicesAndAssetsLocalization.FillInDocumentPreparationForTransferOfOS2_4Completion(ThisObject);
	
EndProcedure

Procedure FillInDocumentPreparationForTransferOfNMA2_4(FillingData)
	
	QueryText =
	"SELECT
	|	Operation.Ref AS Ref,
	|	Operation.Organization AS Organization,
	|	Operation.Department AS Department,
	|	TabularSection.IntangibleAsset AS IntangibleAsset,
	|	Operation.Partner AS Partner,
	|	Operation.Counterparty AS Counterparty
	|INTO TTBaseData
	|FROM
	|	Document.PreparingForIntangibleAssetSale2_4 AS Operation
	|		INNER JOIN Document.PreparingForIntangibleAssetSale2_4.IA AS TabularSection
	|		ON (TabularSection.Ref = Operation.Ref)
	|WHERE
	|	Operation.Ref = &FillingData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TRUE AS SaleBasedOn,
	|	TTBaseData.Ref AS DocumentBasis,
	|	VALUE(Enum.BusinessTransactions.NonCurrentAssetsSale) AS BusinessOperation,
	|	VALUE(Enum.StatusesOfCustomerInvoices.Shipped) AS Status,
	|	DATETIME(1, 1, 1) AS DateOfTransferOfTitleToGoods,
	|	TTBaseData.Organization AS Organization,
	|	TTBaseData.Department AS Department,
	|	TTBaseData.Partner AS Partner,
	|	TTBaseData.Counterparty AS Counterparty
	|FROM
	|	TTBaseData AS TTBaseData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PRESENTATION(TTBaseData.IntangibleAsset) AS Content,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) AS IncomeItem,
	|	TTBaseData.IntangibleAsset AS DimensionOfRevenue,
	|	&UnitOfMeasurementPieces AS UnitOfMeasure,
	|	1 AS Count
	|FROM
	|	TTBaseData AS TTBaseData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceIntangibleAssets) AS AssetAndLiabilityItem,
	|	TTBaseData.IntangibleAsset AS AssetsLiabilitiesDimension,
	|	VALUE(Enum.KindsOfNonCurrentAssets.IA) AS AssetKind,
	|	TTBaseData.IntangibleAsset AS NonCurrentAsset
	|FROM
	|	TTBaseData AS TTBaseData";
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", CurrentSessionDate());
	Query.SetParameter("FillingData", FillingData);
	Query.SetParameter("UnitOfMeasurementPieces", Catalogs.PackagesAndUnitsOfMeasure.FindByCode("796", False));
	
	Package = Query.ExecuteBatch();
	
	Selection = Package[Package.Count()-3].Select();
	If Selection.Next() Then
		FillPropertyValues(ThisObject, Selection);
	EndIf;
	Income.Load(Package[Package.Count()-2].Unload());
	Expenses.Load(Package[Package.Count()-1].Unload());
	
EndProcedure
Procedure FillOutBankAccounts()
	
	If ValueIsFilled(CompanyBankAccount) And ValueIsFilled(CounterpartyBankAccount) Then
		Return;
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Contract,
		?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount),
		?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
	
	If ValueIsFilled(Organization) And Not ValueIsFilled(CompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		ParametersOfAccount.LineOfBusiness = LineOfBusiness;
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If ValueIsFilled(Counterparty) And Not ValueIsFilled(CounterpartyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure SkipCheckingProhibitionOfChangingRegisters(Var_RegisterRecords)
	
	For Each CurRecordSet In Var_RegisterRecords Do
		
		CurRecordSet.AdditionalProperties.Insert("OnlyStateOfTransferOfOwnershipHasChanged", True);

		If Not GetFunctionalOption("NewOnlineARAPAccounting") 
			And (CurRecordSet.ThisObject.Metadata().Name = "CustomersARAPAccounting"
			Or CurRecordSet.ThisObject.Metadata().Name = "VendorsARAPAccounting") Then
			Continue;
		EndIf;
		
		CurRecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck", True);
	EndDo;
	
EndProcedure

Procedure TopUpRevenueData()
	For Each String In Income Do
		If VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT And Not ValueIsFilled(String.VATRate) Then
			String.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
		EndIf;
	EndDo;
EndProcedure

Procedure CheckSaleOfNonCurrentAssets(AttributesNotToCheck, Cancel)
	
	If BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer Then
		MessageTemplate = NStr("vi = 'Chưa điền cột %1 tại dòng %2 của danh sách ""Tài sản cố định""';
								|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""Основные средства""';
								|en = 'Column ""%1"" in line %2 of the ""Fixed assets"" list is not filled in'; fa = 'Column ""%1"" in line %2 of the ""Fixed assets"" list is not filled in';
								|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""Capitale Fisso"" non è compilata';
								|pl = 'Kolumna ""%1"" w wierszu %2 listy ""Środki trwałe"" nie jest wypełniona.';
								|tr = '"" Sabit kıymetler"" listesinin %2 satırındaki ""%1"" sütunu doldurulmamış'");
		NonCurrentAssetField = NStr("vi = 'Tài sản cố định';
									|ru = 'Основное средство';
									|en = 'Fixed asset'; fa = 'دارایی ثابت';
									|it = 'Capitale fisso';
									|pl = 'Środek trwały';
									|tr = 'Sabit kıymetler'");
	Else
		MessageTemplate = NStr("vi = 'Chưa điền cột ""%1"" trong dòng %2 của danh sách ""Tài sản dài hạn""';
								|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""Внеоборотные активы""';
								|en = 'The ""%1"" column in %2 line of the ""Fixed and intangible assets"" list is not filled in'; fa = 'The ""%1"" column in %2 line of the ""Fixed and intangible assets"" list is not filled in';
								|it = 'La colonna ""%1"" nella riga %2 dell''elenco ""Attivi non circolanti"" non è compilata';
								|pl = 'Kolumna ""%1"" w wierszu %2 listy ""Aktywa trwałe"" nie jest wypełniona.';
								|tr = '"" Duran varlıklar"" listesinin %2 satırındaki ""%1"" sütunu doldurulmamış'");
		NonCurrentAssetField = NStr("vi = 'Tài sản dài hạn';
									|ru = 'Внеоборотный актив';
									|en = 'Fixed or intangible asset'; fa = 'دارایی ثابت یا نامشهود';
									|it = 'Attivi non circolanti';
									|pl = 'Aktyw nieobrotowy';
									|tr = 'Duran varlık'");
	EndIf; 
	
	If Expenses.Count() = 0 Then
		If BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer Then
			MessageText = NStr("vi = 'Chưa nhập dòng nào vào danh sách ""Tài sản cố định""';
								|ru = 'Не введено ни одной строки в список ""Основные средства""';
								|en = 'No line is entered into the ""Fixed assets"" list'; fa = 'No line is entered into the ""Fixed assets"" list';
								|it = 'Non è stata inserita alcuna riga nell''elenco ""Capitale Fisso""';
								|pl = 'Nie wprowadzono żadnego wiersza do listy ""Środki trwałe""';
								|tr = '""Sabit kıymetler"" listesine tek bir satır girilmedi'");
		Else
			MessageText = NStr("vi = 'Chưa nhập dòng nào vào danh sách ""Tài sản dài hạn""';
								|ru = 'Не введено ни одной строки в список ""Внеоборотные активы""';
								|en = 'No line is entered into the ""Fixed and intangible assets"" list'; fa = 'No line is entered into the ""Fixed and intangible assets"" list';
								|it = 'Non è stata inserita alcuna riga nell''elenco ""Attivi non circolanti""';
								|pl = 'Nie wprowadzono żadnego wiersza do listy ""Aktywa trwałe""';
								|tr = '""Duran varlıklar"" listesine tek bir satır bile girilmedi'");
		EndIf; 
		CommonClientServer.MessageToUser(MessageText, ThisObject, "Expenses", "", Cancel);
	EndIf; 
	
	For Each RowData In Expenses Do
		
		If Not ValueIsFilled(RowData.AssetKind) Then
			MessageText = StrTemplate(MessageTemplate, NStr("vi = 'Dạng tài sản';
															|ru = 'Вид актива';
															|en = 'Asset type'; fa = 'نوع دارایی';
															|it = 'Tipo di attività';
															|pl = 'Rodzaj aktywa';
															|tr = 'Varlık türü'"), Format(RowData.LineNumber, "NG="));
			Field = CommonClientServer.PathToTabularSection("Expenses", RowData.LineNumber, "AssetKind");
			CommonClientServer.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf; 
		
		If Not ValueIsFilled(RowData.NonCurrentAsset) Then
			MessageText = StrTemplate(MessageTemplate, NonCurrentAssetField, Format(RowData.LineNumber, "NG="));
			Field = CommonClientServer.PathToTabularSection("Expenses", RowData.LineNumber, "NonCurrentAsset");
			CommonClientServer.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf; 
		
		If RowData.ReverseBonusDepreciation Then
			
			If Not ValueIsFilled(RowData.AmountOfDepreciationAllowance) Then
				MessageText = StrTemplate(MessageTemplate, NStr("vi = 'Số tiền trích bù khấu hao';
																|ru = 'Сумма амортизационной премии';
																|en = 'Bonus depreciation amount'; fa = 'مبلغ استهلاک تشویقی';
																|it = 'Importo del premi di ammortamento';
																|pl = 'Wartość premii amortyzacyjnej';
																|tr = 'Amortisman Primi tutarı'"), Format(RowData.LineNumber, "NG="));
				Field = CommonClientServer.PathToTabularSection("Expenses", RowData.LineNumber, "AmountOfDepreciationAllowance");
				CommonClientServer.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			EndIf; 
			
			If Not ValueIsFilled(RowData.IncomeItem) Then
				MessageText = StrTemplate(MessageTemplate, NStr("vi = 'Dạng thu nhập';
																|ru = 'Статья доходов';
																|en = 'Income item'; fa = 'قلم درآمد';
																|it = 'Voce dei ricavi';
																|pl = 'Rodzaj przychodów';
																|tr = 'Gelir kalemi'"), Format(RowData.LineNumber, "NG="));
				Field = CommonClientServer.PathToTabularSection("Expenses", RowData.LineNumber, "IncomeItem");
				CommonClientServer.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			EndIf; 
			
		EndIf;
		
	EndDo; 
	
EndProcedure

Procedure CheckImplementationOfRentalServices(Cancel)

	MessageTemplate = NStr("vi = 'Chưa điền cột ""Đối tượng thuê"" trong dòng %1 của danh sách ""Doanh thu (thu nhập)""';
							|ru = 'Не заполнена колонка ""Предмет аренды"" в строке %1 списка ""Выручка (доходы)""';
							|en = 'The ""Rental object"" column in line %1 of the ""Revenue (income)"" list is required.'; fa = 'The ""Rental object"" column in line %1 of the ""Revenue (income)"" list is required.';
							|it = 'The ""Rental object"" column in line %1 of the ""Revenue (income)"" list is required.';
							|pl = 'The ""Rental object"" column in line %1 of the ""Revenue (income)"" list is required.';
							|tr = '""Hasılat (gelirler)"" listesinin %1 satırındaki ""Kira konusu"" sütunu doldurulmadı'");

	For Each RowData In Income Do

		If RowData.RentalComponentOfContract And Not ValueIsFilled(RowData.RentalObject) Then
			MessageText = StrTemplate(MessageTemplate, Format(RowData.LineNumber, "NG="));
			Field = CommonClientServer.PathToTabularSection("Income", RowData.LineNumber, "RentalObject");
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
		EndIf; 

	EndDo; 

EndProcedure
 
Procedure SetPropertiesForChangingBankingDetails(Object, Var_AdditionalProperties)
	
	OnlyStateOfTransferOfOwnershipHasChanged = False;
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or Object.BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer)
	 And Object.Posted Then
		AttributesNotToCheck = New Structure;
		AttributesNotToCheck.Insert("Comment");
		AttributesNotToCheck.Insert("PaymentDate");
		AttributesNotToCheck.Insert("PaymentID");
		
		UnverifiableTableParts = New Structure;
		UnverifiableTableParts.Insert("AdditionalAttributes");
		
		DocumentChanges = TMCommonUse.DocumentChanges(Object, AttributesNotToCheck, UnverifiableTableParts);
		
		OnlyStateOfTransferOfOwnershipHasChanged = True;
		OldDateOfTransferOfOwnership = Object.DateOfTransferOfTitleToGoods;
		
		If DocumentChanges.Property("TabularSections") Then
			OnlyStateOfTransferOfOwnershipHasChanged = False;
		EndIf;
		
		If DocumentChanges.Property("Attributes") Then
			For Each Attribute In DocumentChanges.Attributes Do
				
				If Attribute.Name = "Status" Then 
					
					If (Attribute.NewValue = Enums.StatusesOfCustomerInvoices.ForPrepayment
					 	Or Attribute.PreviousValue2 = Enums.StatusesOfCustomerInvoices.ForPrepayment) Then
					 		
						OnlyStateOfTransferOfOwnershipHasChanged = False;
						Break;
					EndIf;
					
				ElsIf Attribute.Name = "DateOfTransferOfTitleToGoods" Then
					
					OldDateOfTransferOfOwnership = Attribute.PreviousValue2;
					
				Else
					
					OnlyStateOfTransferOfOwnershipHasChanged = False;
					Break;
					
				EndIf;
				
			EndDo;
		EndIf;
	EndIf;
	
	Var_AdditionalProperties.Insert("OnlyStateOfTransferOfOwnershipHasChanged", 
		OnlyStateOfTransferOfOwnershipHasChanged);
		
	Var_AdditionalProperties.Insert("OldDateOfTransferOfOwnership", 
		OldDateOfTransferOfOwnership);
	
EndProcedure

Procedure CreateTasksForEndOfMonth()
	
	If ExchangePlans.MasterNode() <> Undefined Then
		Return;
	EndIf;
	
	OnlyStateOfTransferOfOwnershipHasChanged =
		AdditionalProperties.Property("OnlyStateOfTransferOfOwnershipHasChanged")
		And AdditionalProperties.OnlyStateOfTransferOfOwnershipHasChanged;
	
	If Not OnlyStateOfTransferOfOwnershipHasChanged
		And (BusinessOperation = Enums.BusinessTransactions.NonCurrentAssetsSale
			Or BusinessOperation = Enums.BusinessTransactions.FixedAssetsSaleWithDeferredTitleTransfer) Then
		
		TempTablesManager = DocumentsPosting.ManagerOfTemporaryControlTables(ThisObject);
		
		QueryText =
		"SELECT
		|	DocumentData.Ref AS Document,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Date AS Period,
		|	DocumentData.DateOfTransferOfTitleToGoods AS DateOfTransferOfTitleToGoods,
		|	DocumentData.Status AS Status,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentDataTableExpenses.NonCurrentAsset AS NonCurrentAsset
		|
		|INTO CustomerInvoiceServicesAndAssetsUpdate
		|
		|FROM
		|	Document.CustomerInvoiceServicesAndAssets AS DocumentData
		|
		|		INNER JOIN Document.CustomerInvoiceServicesAndAssets.Expenses AS DocumentDataTableExpenses
		|		ON DocumentDataTableExpenses.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND DocumentData.Posted";
		Query = New Query(QueryText);
		Query.TempTablesManager = TempTablesManager;
		Query.SetParameter("Ref", Ref);
		Query.Execute();
	
		TablesData = DocumentsPosting.OldStructureTableData(ThisObject, TempTablesManager);
		TablesData.Insert("CustomerInvoiceServicesAndAssetsUpdate", True);
		
		ClosingExpensesFromDisposalOfFixedAssets.GenerateJobs(ThisObject, TempTablesManager);
		DeferredFARecordGeneration.GenerateJobs(ThisObject, TablesData);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
