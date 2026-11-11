#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.PurchaseAdjustment - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	If TypeOf(DocumentObject) = Type("DocumentObject.ReversingEntry") Then
		If WriteMode = DocumentWriteMode.UndoPosting Then
			FillParameters.IgnoreTraceableWorkPurchasesUnderPrincipal = True;
		EndIf;
	Else
		If WriteMode = DocumentWriteMode.Posting Then
			FillParameters.IgnoreTraceableWorkPurchasesUnderPrincipal = True;
		EndIf;
	EndIf;
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	DocumentObject.AdditionalProperties.Insert("DisableProductControlForIssuingReportsToPurchasingCommittee", True);
	
	UseSeparateProcurement = PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BusinessOperation);
	FillParameters.UseSeparateProcurement = UseSeparateProcurement;
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part
// The 'Discrepancies' of the document, and also fills in the tabular part of the 'Types of reserves'.
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.PurchaseAdjustment.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables = Undefined) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	FillStockTypes(Cancel);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting 
		And ValueIsFilled(DocumentBasis)
		And Not Common.ObjectAttributeValue(DocumentBasis,"Posted") Then
		PurchasesServer.ReportErrorsOnUnverifiedBasis(DocumentBasis, Cancel);
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	CheckChainOfCorrectionsBeforeRecording(Cancel, WriteMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not ValueIsFilled(ServiceReceiptOption) Then
		ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Contract);
	EndIf;
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	If AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated
		Or AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated Then
		DocumentAmount = ARAPAdjustment.Total("AdjustmentSum");
	Else
		DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(
						Goods, 
						PriceIncludesVAT Or VATTaxation = Enums.VATTaxationTypes.SubjectToVATAtCustomer);
	EndIf;
	
	If ValueIsFilled(DocumentBasis) Then
		
		BasisType = TypeOf(DocumentBasis);
		
		If BasisType = Type("DocumentRef.VendorInvoice") Then
			
			DetailsOfFoundation = "GoodsReceiptOption, ServiceReceiptOption, BusinessOperation";
			
		ElsIf BasisType = Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
			
			DetailsOfFoundation = "GoodsReceiptOption, BusinessOperation";
			
		ElsIf BasisType <> Type("DocumentRef.SourceDocument")
			And BasisType <> Type("DocumentRef.SubcontractorReport2_5")
			And BasisType <> Type("Undefined") Then
			
			DetailsOfFoundation = "BusinessOperation";
			
		Else
			
			DetailsOfFoundation = "";
			
		EndIf;
		
		If ValueIsFilled(DetailsOfFoundation) Then
			
			AttributesValues = Common.ObjectAttributesValues(DocumentBasis, DetailsOfFoundation);
			FillPropertyValues(ThisObject, AttributesValues, DetailsOfFoundation);
			
		EndIf;
		
	EndIf;
	
	RegistrationParameters = Documents.PurchaseAdjustment.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices
		Or AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets Then
			
			Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Currency,ARAPCurrency,Date,Organization,CourseNumerator,CourseDenominator);
			ParametersStructure = ARAPAccountingServer.MechanismParameters();
			ParametersStructure.Insert("PropsNameTSAmountWithVAT", "AmountIncludingVAT");
			ParametersStructure.Insert("AmountARAP", Goods.Total("AmountIncludingVAT") * Coefficients.ConversionRateToSettlementCurrency);
			ParametersStructure.Insert("AmountARAPByPackage", "");
			ParametersStructure.Insert("CourseNumerator", CourseNumerator);
			ParametersStructure.Insert("CourseDenominator", CourseDenominator);
			ParametersStructure.Insert("DocumentCurrency", Currency);
			ParametersStructure.Insert("ARAPCurrency", ARAPCurrency);
			ParametersStructure.Insert("Organization", Organization);
			ParametersStructure.Insert("PathToTSData", "Object.Goods");
			ARAPAccountingServer.CheckAndFillInAmountsOfSettlementsInTablePart(ThisObject, ParametersStructure);
			
			If WriteMode = DocumentWriteMode.Posting Then
				CheckFullnessOfSettlementAmount(Cancel);
			EndIf;
			
	EndIf;
	
	TMCommonUse.ChangeDocumentConsistencyAttribute(
		ThisObject,
		WriteMode);
	
	AccountingForTraceableGoodsLocalization.ClearGTDUNumbersOfTraceableWorks(ThisObject);
	AccountingForTraceableGoodsLocalization.ClearGTDUNumbersOfTraceableWorks(ThisObject, "Discrepancies");
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		If VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
			For Each String In Goods Do
				If Not ValueIsFilled(String.VATRate) Then
					String.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
				EndIf;
			EndDo;
			For Each String In Discrepancies Do
				If Not ValueIsFilled(String.VATRate) Then
					String.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
				EndIf;
			EndDo;
		EndIf;
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		
		For Each String In Discrepancies Do
			If ValueIsFilled(String.InventoryOwnerAttribute) Then
				String.InventoryOwnerAttribute = Undefined
			EndIf;
		EndDo;
		
		InventoryKinds.Clear();
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Discrepancies,InventoryKinds,ARAPAdjustment");
	
	// We will clear the unused document details.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.PurchaseAdjustment.FillInNamesOfDetailsOnBasis(
		DocumentBasis,
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		AdjustingEntryType);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
		
	ProductsServer.ClearUnusedSeries(ThisObject, 
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.PurchaseAdjustment));
	
	RecordInOtherIncome = False;
	ToExpenseAs  = False;
	
	If AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated Then
		ToExpenseAs = True;
	ElsIf AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated Then
		RecordInOtherIncome = True;
	Else
		For Each LineOfDiscrepancies In Discrepancies Do
			If LineOfDiscrepancies.PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome Then
				RecordInOtherIncome = True;
			ElsIf LineOfDiscrepancies.PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs Then
				ToExpenseAs = True;
			EndIf;
		EndDo;
	EndIf;
	
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", AdjustmentKind);
	OptionsForSelection.Insert("DocumentBasis", DocumentBasis);
	OptionsForSelection.Insert("DocumentDate", Date);
	OptionsForSelection.Insert("RecordInOtherIncome", RecordInOtherIncome);
	OptionsForSelection.Insert("ToExpenseAs", ToExpenseAs);
	OptionsForSelection.Insert("AdjustingEntryType", AdjustingEntryType);
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);	
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.PurchaseAdjustment.AccountingAccountSettings_(OptionsForSelection));
	If AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated
		Or AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated Then
		PriceIncludesVAT = True;
	EndIf;
		
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
	If Not ValueIsFilled(AdjustingEntryType) Then
		AdjustingEntryType = Enums.AdjustingEntryTypes.StandardAdjustment;
	EndIf;
	
	If GetFunctionalOption("UseGoodsQualityControl")
			And AdjustingEntryType = Enums.AdjustingEntryTypes.StandardAdjustment
			// When purchasing separately, the purchase adjustment does not Register Records for the PH of Goods in warehouses, the Lot reference is not needed.
			// In addition, it is impossible to fill it in a non-ordinary warehouse, since the Lot reference will be the document "Receipt of goods to the warehouse",
			//	which is not referenced in the "Purchase Adjustment". 
			And Not PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BusinessOperation)
			And BusinessOperation <> Enums.BusinessTransactions.SubcontractorReportAdjustment
			And Not TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		
		// The mechanism of "Controlled Lot references".
		SetPrivilegedMode(True);
		Query = New Query();
		Query.Text =
			"SELECT DISTINCT
			|	TabPart.PurchaseOrder AS PurchaseOrder,
			|	CAST(TabPart.Warehouse AS Catalog.Warehouses) AS Warehouse
			|INTO TabPart
			|FROM
			|	&TabPart AS TabPart
			|;
			|///////////////////////
			|SELECT DISTINCT
			|	CASE
			|		WHEN NOT ISNULL(TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
			|					AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &Date, FALSE)
			|			THEN &DocumentBasis
			|		WHEN
			|			&GoodsReceiptOption IN(
			|				VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
			|				VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
			|				VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
			|			THEN &Terms
			|		WHEN &GoodsReceiptOption IN(
			|				VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
			|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
			|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
			|			THEN &Contract
			|		WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
			|				OR NOT &ReceiptUnderOrders
			|			THEN &DocumentBasis
			|		ELSE TabPart.PurchaseOrder
			|	END AS DocumentLots,
			|	TabPart.PurchaseOrder AS PurchaseOrder,
			|	TabPart.Warehouse AS Warehouse,
			|	CASE
			|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
			|			THEN ISNULL(Purchase.AdvanceHolder, &Partner)
			|		ELSE &Partner
			|	END AS Sender,
			|	&BusinessOperation AS BusinessOperation
			|FROM
			|	TabPart AS TabPart
			|		LEFT JOIN Document.VendorInvoice AS Purchase
			|		ON Purchase.Ref = &DocumentBasis";
		Query.SetParameter("GoodsReceiptOption", GoodsReceiptOption);
		Query.SetParameter("Terms", Terms);
		Query.SetParameter("Contract", Contract);
		Query.SetParameter("ReceiptUnderOrders", ReceiptUnderOrders);
		Query.SetParameter("DocumentBasis", DocumentBasis);
		Query.SetParameter("Partner", Partner);
		Query.SetParameter("BusinessOperation", BusinessOperation);
		Query.SetParameter("Date", Date);
		Indexes = "PurchaseOrder,Warehouse";
		Query.SetParameter("TabPart", Discrepancies.Unload(, Indexes));
		DocumentsOfLotReference = Query.Execute().Unload();
		SetPrivilegedMode(False);
		
		QualityControl.FillInControlledLotReferencesInTablePart(
			ThisObject,
			Discrepancies,
			DocumentsOfLotReference,
			Indexes);
			
	EndIf;
	
	PurchaseAdjustmentLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.VendorInvoice") Then
		
		InformationOnReceiptOfGoodsServices(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		
		IncomeFromServicesOtherAssets(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.SourceDocument") Then
		
		FillInPrimaryDocument(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.SubcontractorReport2_5") Then
		
		FillInReportOfProcessor(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("DiscrepancyCertificate")
		And FillingData.Property("BasisOfAct") Then
		
		FillInAccordingToDiscrepancyCertificate(FillingData, FillingData);
		
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")And FillingData.Property("BusinessOperation") Then
		If FillingData.BusinessOperation = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated Then
			FillingData.Insert("AdjustmentKind", Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated);
		ElsIf FillingData.BusinessOperation = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated Then
			FillingData.Insert("AdjustmentKind", Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated);
		ElsIf FillingData.BusinessOperation = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties
			Or FillingData.BusinessOperation = Enums.BusinessTransactions.ErrorCorrection Then
			FillingData.Insert("AdjustmentKind", FillingData.BusinessOperation);
			FillingData.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		Else
			FillingData.Insert("AdjustmentKind", Enums.BusinessTransactions.ErrorCorrection);
		EndIf;
		If FillingData.BusinessOperation = Enums.BusinessTransactions.AdjustBeforeEnteringBalance Then
			BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
			DocumentBasis = Documents.SourceDocument.EmptyRef();
		EndIf;
	EndIf;
	
	InitializeDocument(FillingData);
	
	PurchaseAdjustmentLocalization.Filling(ThisObject, FillingData, StandardProcessing);

	DocumentBaseParameter = DocumentBasis;
	DateParameter = Date;
	AdjustmentTypeParameter = AdjustmentKind;
	
	If TypeOf(FillingData) = Type("Structure") Then
		If Not ValueIsFilled(DocumentBaseParameter) Then
			FillingData.Property("DocumentBasis", DocumentBaseParameter);
		EndIf;
		If Not ValueIsFilled(DateParameter) And 
			 Not FillingData.Property("Date", DateParameter) Then
			DateParameter = CurrentSessionDate();
		EndIf;	
		If Not ValueIsFilled(AdjustmentTypeParameter) And 
			 Not FillingData.Property("AdjustmentKind", AdjustmentTypeParameter)  Then
			 AdjustmentTypeParameter = Enums.BusinessTransactions.ErrorCorrection;
		EndIf;
	EndIf;		
		
	OptionsForSelection = New Structure;
	OptionsForSelection.Insert("BusinessOperation", AdjustmentTypeParameter);
	OptionsForSelection.Insert("DocumentBasis", DocumentBaseParameter);
	OptionsForSelection.Insert("DocumentDate", DateParameter);
	OptionsForSelection.Insert("AdjustingEntryType", AdjustingEntryType);
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ArrayOfAllProps			= New Array;
	ArrayOfOperationDetails		= New Array;
	NotCheckedAttributeArray	= New Array;
	
	Documents.PurchaseAdjustment.FillInNamesOfDetailsOnBasis(
		DocumentBasis,
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		AdjustingEntryType);
	
	For Each ArrayElement In ArrayOfAllProps Do
		If ArrayOfOperationDetails.Find(ArrayElement) = Undefined Then
			NotCheckedAttributeArray.Add(ArrayElement);
		EndIf;
	EndDo;
	
	If AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated
		Or AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated Then
		
		NotCheckedAttributeArray.Add("DocumentBasis");
		
	EndIf;
	
	If Not ValueIsFilled(Terms)
		Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		
		NotCheckedAttributeArray.Add("Contract");
		
	EndIf;
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument")
		Or VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
		
		NotCheckedAttributeArray.Add("Goods.VATRate");
		NotCheckedAttributeArray.Add("Discrepancies.VATRate");
		
	EndIf;
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument")
		Or TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
		
		NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
		NotCheckedAttributeArray.Add("Goods.Count");
		
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	If Not ReceiptUnderOrders Then
		NotCheckedAttributeArray.Add("Goods.PurchaseOrder");
		NotCheckedAttributeArray.Add("Discrepancies.PurchaseOrder");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument") Then
		NotCheckedAttributeArray.Add("Goods.Content");
		NotCheckedAttributeArray.Add("Goods.Products");
		NotCheckedAttributeArray.Add("Goods.Characteristic");
		NotCheckedAttributeArray.Add("Goods.Series");
		NotCheckedAttributeArray.Add("Goods.Price");
		NotCheckedAttributeArray.Add("Goods.Sum");
		NotCheckedAttributeArray.Add("Goods.PostingOption");
		NotCheckedAttributeArray.Add("Goods.DimensionOfExpenses");
		
		NotCheckedAttributeArray.Add("Discrepancies.Content");
		NotCheckedAttributeArray.Add("Discrepancies.Products");
		NotCheckedAttributeArray.Add("Discrepancies.Characteristic");
		NotCheckedAttributeArray.Add("Discrepancies.PostingOption");
		NotCheckedAttributeArray.Add("Discrepancies.DimensionOfExpenses");
		
		AdjustmentTable = Documents.PurchaseAdjustment.AdjustmentDataBeforeEnteringBalances(ThisObject,
								AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices);
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.PurchaseAdjustment);
		SeriesSpecificationParameters.NameTSGoods	= "AdjustmentTable";
		SeriesSpecificationParameters.TSSeriesName	= "AdjustmentTable";
		
		DocumentData = New Structure;
		DocumentData.Insert("Object",					ThisObject);
		DocumentData.Insert("SeriesSpecificationParameters",	SeriesSpecificationParameters);
		DocumentData.Insert("AdjustmentTable",	AdjustmentTable);
		
		Documents.PurchaseAdjustment.CheckAttributesFilling(DocumentData, CheckedAttributes, Cancel);
		
	Else
		
		If TypeOf(DocumentBasis) <> Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
			ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
		EndIf;
		
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
		
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "Discrepancies";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,
															NotCheckedAttributeArray,
															Cancel,
															CheckParameters);
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.PurchaseAdjustment);
		ProductsServer.CheckSeriesCompletion(ThisObject,
													ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.PurchaseAdjustment),
													Cancel,
													NotCheckedAttributeArray);
		
		If ValueIsFilled(DocumentBasis)
			And TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
			NotCheckedAttributeArray.Add("Goods.Price");
			NotCheckedAttributeArray.Add("Goods.Sum");
			
			MatchingProductsType = Common.ObjectsAttributeValue(
											Goods.UnloadColumn("Products"),
											"ItemsType");
			ValueOfDocumentDetails = Common.ObjectAttributesValues(
													DocumentBasis,
													"ToReturnReusablePackage, PackageDepositIsRequired");
			
			For CurIndex__ = 0 To Goods.Count()-1 Do
				CurrentRow = Goods[CurIndex__];
				
				CheckFillingOfRowColumn("Price",
												ValueOfDocumentDetails,
												MatchingProductsType,
												CurrentRow,
												Cancel);
				CheckFillingOfRowColumn("Sum",
												ValueOfDocumentDetails,
												MatchingProductsType,
												CurrentRow,
												Cancel);
			EndDo;
		Else
			If BusinessOperation = Enums.BusinessTransactions.SubcontractorReportAdjustment Then
				NotCheckedAttributeArray.Add("Goods.Price");
				NotCheckedAttributeArray.Add("Goods.Sum");
			EndIf;
		EndIf;
		
		ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date);
		
		If (ThisIsTraceableDocument
				Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers"))
			And TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoice")
			And ValueIsFilled(DocumentBasis)
			And Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation") <> Enums.BusinessTransactions.PurchaseByImport Then
			
			CheckParameters = InventoriesServer.ParametersForCheckingFillingInOfCCDNumbers();
			CheckParameters.CheckWorks = True;
			CheckParameters.BusinessOperation = Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation");
			InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel, CheckParameters);
			
		EndIf;
		
		If ThisIsTraceableDocument Then
			AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject, Goods, Date);
		EndIf;
		
		CheckVHFArticleDivisionAndAnalytics = True;
		
		If ValueIsFilled(DocumentBasis) Then
			
			BusinessTransactionGrounds = Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation");
			ContractDetails_ = Common.ObjectAttributesValues(Contract,
				"PurchaseRegistrationOption, OptionForRegisteringServiceReceiptDocuments");
			
			OperationsOfUnfacturedDelivery = New Array;
			OperationsOfUnfacturedDelivery.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
			OperationsOfUnfacturedDelivery.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
			
			CheckVHFArticleDivisionAndAnalytics = Not (OperationsOfUnfacturedDelivery.Find(BusinessTransactionGrounds) <> Undefined
				And (ContractDetails_.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices
				Or ContractDetails_.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced));
			
			If Date < Common.ObjectAttributeValue(DocumentBasis, "Date") Then
				ErrorText = NStr("vi = 'Ngày chứng từ không cần nhỏ hơn ngày chứng từ cơ sở.';
								|ru = 'Дата документа не должна быть меньше даты документа основания.';
								|en = 'The document date must be later than the base document date.'; fa = 'The document date must be later than the base document date.';
								|it = 'Дата документа не должна быть меньше даты документа основания.';
								|pl = 'The document date must be later than the base document date.';
								|tr = 'Belge tarihi, temel belge tarihinden daha önce olmamalıdır.'");
				Common.MessageToUser(ErrorText,, "Object.Date",, Cancel);
			EndIf;
			
		EndIf;
		
		If CheckVHFArticleDivisionAndAnalytics
			And TypeOf(DocumentBasis) <> Type("DocumentRef.VendorInvoiceServicesAndAssets") Then
			
			NotCheckedAttributeArray.Add("Goods.Department");
			
			ItemsTypes = New Array;
			ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
			ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
			ItemsTypes.Add(Enums.ItemsTypes.OperationService);
			ItemsTypes.Add(Enums.ItemsTypes.Work_5);
			
			ErrorText = NStr("vi = 'Chưa chỉ ra người nhận hàng hóa/công việc/dịch vụ tại dòng %1 của danh sách Hàng hóa';
							|ru = 'Не указан получатель товаров/работ/услуг в строке %1 списка Товары';
							|en = 'Recipient of goods, works, services is not specified in line %1 of the Goods list'; fa = 'Recipient of goods, works, services is not specified in line %1 of the Goods list';
							|it = 'Destinatario di articoli/lavori/servizi non indicato nella riga %1 dell''elenco Articoli';
							|pl = 'Nie jest wskazany odbiorca towarów/prac/usług w wierszu %1 listy Towary';
							|tr = 'Ürünlerin/işlerin/hizmetlerin alıcısı Ürünler listesinin %1satırında belirtilmemiştir '");
			
			InventoriesServer.CheckFillingOfDivisionInTablePart(ThisObject, ItemsTypes, ErrorText, Cancel);
		EndIf;
		
		ResultsOfDiscrepancyCheck = CheckFillingForDiscrepancies(NotCheckedAttributeArray, Cancel);
		
		RecordInOtherIncome = 
			ResultsOfDiscrepancyCheck.RecordInOtherIncome
			Or AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated;
		ToExpenseAs = ResultsOfDiscrepancyCheck.ToExpenseAs
			Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated;
		
		OptionsForSelection = New Structure;
		OptionsForSelection.Insert("BusinessOperation",	AdjustmentKind);
		OptionsForSelection.Insert("DocumentBasis",		DocumentBasis);
		OptionsForSelection.Insert("DocumentDate",			Date);
		OptionsForSelection.Insert("RecordInOtherIncome",	RecordInOtherIncome);
		OptionsForSelection.Insert("ToExpenseAs",			ToExpenseAs);
		OptionsForSelection.Insert("CheckArticlesAndDimension", CheckVHFArticleDivisionAndAnalytics);
		OptionsForSelection.Insert("AdjustingEntryType",			AdjustingEntryType);
		
		ItemsAndDimensionsSelectionParameters = Documents.PurchaseAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
		IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
		
		PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject, Cancel);
	EndIf;
	
	QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"Discrepancies",
		NStr("vi = 'Chênh lệch';
			|ru = 'Расхождения';
			|en = 'Discrepancies'; fa = 'مغایرت‌ها';
			|it = 'Discrepancies';
			|pl = 'Discrepancies';
			|tr = 'Tutarsızlıklar'"),
		Undefined);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	CheckCompletionOfDebtAdjustmentTable(Cancel);
	
	CheckParameters = VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases();
	CheckParameters.TabularSectionName = "Goods";
	CheckParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	VATAccountingERP.CheckCompletionOfPurchaseDocumentForVATTaxation(ThisObject, VATTaxation, CheckParameters, Cancel);
	
	CheckParameters = VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases();
	CheckParameters.TabularSectionName = "Discrepancies";
	CheckParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	VATAccountingERP.CheckCompletionOfPurchaseDocumentForVATTaxation(ThisObject, VATTaxation, CheckParameters, Cancel);
	
	PurchaseAdjustmentLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	PurchasesServer.CheckSeparateRegistrationOfGoods(Organization, BusinessOperation, Contract, 
		Goods.Unload(, "LineNumber, Products"), Cancel);
	
	If Not Cancel
		And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.Posting);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RegistrationParameters = Documents.PurchaseAdjustment.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
	PurchaseAdjustmentLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.UndoPosting);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RegistrationParameters = Documents.PurchaseAdjustment.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
	PurchaseAdjustmentLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	MetadataDocumentBase = DocumentBasis.Metadata();
	If Not AccessRight("Update", MetadataDocumentBase) Then
		ErrorText = NStr("vi = 'Người sử dụng không đủ quyền chỉnh sửa chứng từ ""%1"".';
						|ru = 'У пользователя недостаточно прав на корректировку документа ""%1"".';
						|en = 'User is not authorized to adjust document ""%1"".'; fa = 'User is not authorized to adjust document ""%1"".';
						|it = 'У пользователя недостаточно прав на корректировку документа ""%1"".';
						|pl = 'User is not authorized to adjust document ""%1"".';
						|tr = 'Kullanıcının ""%1"" belgesini düzeltmek için yeterli yetkisi yoktur.'");
		ErrorText = StrTemplate(ErrorText, MetadataDocumentBase.Synonym);
		Raise ErrorText;
	EndIf;
	
	If AdjustingEntryType = Enums.AdjustingEntryTypes.StandardAdjustment Then
		Goods.Clear();
		Discrepancies.Clear();
	EndIf;
	
	InventoryKinds.Clear();
	Approved  = False;
	BaseDocumentDate = Common.ObjectAttributeValue(DocumentBasis, "Date");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	ParametersForFillingInVATStacks = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	ParametersForFillingInVATStacks.Date = BaseDocumentDate;
	ParametersForFillingInVATStacks.InitializingIncomingDocument = True;
	
	StructureOfActions = New Structure;
	CacheDiscrepancies = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	CacheProducts = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", ParametersForFillingInVATStacks);
	BatchProcessingOfTablePartServer.TreatTS(Discrepancies, StructureOfActions, CacheDiscrepancies);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CacheProducts);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CacheDiscrepancies.ProcessedRows,
		StructureOfActions,
		Discrepancies,
		Undefined);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CacheProducts.ProcessedRows,
		StructureOfActions,
		Goods,
		Undefined);
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Discrepancies,InventoryKinds");
	
	PurchaseAdjustmentLocalization.OnCopy(ThisObject, CopiedObject);

	Author = Users.CurrentUser();

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateControlledLotReferencesInTablePart(ThisObject);
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	PurchaseAdjustmentLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region Initialization_And_Filling

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	If TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("Currency")
		And ValueIsFilled(FillingData.Currency) Then
		Currency = FillingData.Currency;
	EndIf;
	If TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("ARAPCurrency") 
		And ValueIsFilled(FillingData.ARAPCurrency) Then
		ARAPCurrency = FillingData.ARAPCurrency;
	EndIf;
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("ARAPObjectSettings") 
		And ValueIsFilled(FillingData.ARAPObjectSettings) Then
		ARAPObjectSettings = FillingData.ARAPObjectSettings;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("Organization")
		And ValueIsFilled(FillingData.Organization) Then
		Organization = FillingData.Organization;
	Else
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("DocumentBasis") 
		And ValueIsFilled(FillingData.DocumentBasis) Then
		DateOfCourse = Common.ObjectAttributeValue(FillingData.DocumentBasis,"Date");
	Else
		DateOfCourse = CurrentSessionDate();
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("PurchaseForActivity") 
		And ValueIsFilled(FillingData.PurchaseForActivity) Then
		PurchaseForActivity = FillingData.PurchaseForActivity;
	Else
		FillParameters = Documents.PurchaseAdjustment.ParametersForFillingInVATActivityType(ThisObject);
		VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	EndIf;
	
	If Not ValueIsFilled(AdjustingEntryType) Then
		If TypeOf(FillingData) = Type("Structure")
			And ((FillingData.Property("DocumentBasis")
				And TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.SourceDocument"))
				Or (FillingData.Property("BusinessOperation")
					And FillingData.BusinessOperation = Enums.BusinessTransactions.AdjustBeforeEnteringBalance)) Then
			
			AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices;
			
		Else
			AdjustingEntryType = Enums.AdjustingEntryTypes.StandardAdjustment;
		EndIf;
	EndIf;
	
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, Currency, ARAPCurrency, Organization, DateOfCourse, Contract);
	
	If TypeOf(FillingData) = Type("Structure")
			And CommonClientServer.HasAttributeOrObjectProperty(FillingData, "DocumentBasis") Then
		BasisOfFillingData = FillingData.DocumentBasis;
	ElsIf Common.IsReference(TypeOf(FillingData)) Then
		BasisOfFillingData = FillingData;
	Else
		BasisOfFillingData = Undefined;
	EndIf;
	ResponsiblePersonsServer.InstallManager(ThisObject, BasisOfFillingData);
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Discrepancies, StructureOfActions);
	
EndProcedure

Procedure InformationOnReceiptOfGoodsServices(Val DocumentBasis, FillingData)
	
	MetadataDocumentBase = DocumentBasis.Metadata();
	If Not AccessRight("Update", MetadataDocumentBase) Then
		ErrorText = NStr("vi = 'Ở người sử dụng không đủ quyền điều chỉnh chứng từ ""';
						|ru = 'У пользователя недостаточно прав на корректировку документа ""';
						|en = 'User is not authorized to adjust document ""'; fa = 'User is not authorized to adjust document ""';
						|it = 'Utente non ha i diritti sufficienti per eseguire la rettifica del documento ""';
						|pl = 'Użytkownik ma niewystarczające uprawnienia na zapis korygujący dokumentu ""';
						|tr = 'Kullanıcının "" "" belgesini düzenlemek için yeterli hakkı yok'")
			+ MetadataDocumentBase.Synonym + """.";
		Raise ErrorText;
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("DocumentBasis", DocumentBasis);
	
	If Not ValueIsFilled(DocumentBasis) Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	DocumentData.Ref				 AS DocumentBasis,
	|	DocumentData.Partner				 AS Partner,
	|	DocumentData.Counterparty			 AS Counterparty,
	|	DocumentData.Terms			 AS Terms,
	|	DocumentData.Organization			 AS Organization,
	|	DocumentData.Contract				 AS Contract,
	|	DocumentData.Warehouse				 AS Warehouse,
	|	DocumentData.Currency				 AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.VATTaxation	 AS VATTaxation,
	|	DocumentData.PurchaseForActivity AS PurchaseForActivity,
	|	DocumentData.Department		 AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.SalesOpportunity				 AS SalesOpportunity,
	|	DocumentData.PriceIncludesVAT		 AS PriceIncludesVAT,
	|	DocumentData.ARAPObjectSettings		 AS ARAPObjectSettings,
	|	DocumentData.ReceiptUnderOrders AS ReceiptUnderOrders,
	|	NOT DocumentData.Posted			 AS ThereAreErrorsPosted,
	|	DocumentData.GoodsReceiptOption AS GoodsReceiptOption,
	|	DocumentData.ServiceReceiptOption  AS ServiceReceiptOption,
	|	DocumentData.BusinessOperation AS EconomicOperationOfFoundation,
	|	
	|	CASE WHEN DocumentData.BusinessOperation IN (&Available_BusinessTransactions) THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS ThereAreErrorsOperation,
	|
	|	CASE
	|		WHEN DocumentData.VATTaxation IN (VALUE(Enum.VATTaxationTypes.VATTaxAgent),
	|												VALUE(Enum.VATTaxationTypes.DigitalServices)) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS ThereAreErrorsVATTaxation,
	|
	|	DocumentData.BusinessOperation AS BusinessOperation
	|	
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentBasis
	|");
	
	Available_BusinessTransactions = New Array();
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit);
	
	NewWayToCreateApplicationForGoodsImportFromEAEU = Common.ObjectAttributeValue(DocumentBasis, "NewWayToCreateApplicationForGoodsImportFromEAEU");
	If NewWayToCreateApplicationForGoodsImportFromEAEU = True Then
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEU);
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
		Available_BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	EndIf;
	
	Query.SetParameter("DocumentBasis",    DocumentBasis);
	Query.SetParameter("Available_BusinessTransactions", Available_BusinessTransactions);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập điều chỉnh tiếp nhận trên cơ sở chứng từ %1.';
				|ru = 'Не требуется вводить корректировку поступления на основании документа %1.';
				|en = 'Generating receipt adjustment from base document %1 is not required.'; fa = 'Generating receipt adjustment from base document %1 is not required.';
				|it = 'Non è necessario immettere la rettifica dell''arrivo in base al documento %1.';
				|pl = 'Nie wymaga się wprowadzać zapis korygujący wpłaty na podstawie dokumentu %1.';
				|tr = '%1 belgesine dayalı bir gelir düzenlemesi girmeye gerek yoktur.'"),
			DocumentBasis);
		Raise Text;
	EndIf;
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	If Selection.ThereAreErrorsOperation Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để tiếp nhận với giao dịch ""%1"" không nên nhập điều chỉnh.';
				|ru = 'Для поступления с операцией ""%1"" не требуется вводить корректировку.';
				|en = 'For a receipt with operation ""%1"" the adjustment is not required.'; fa = 'For a receipt with operation ""%1"" the adjustment is not required.';
				|it = 'Non è richiesta la rettifica per l''arrivo con operazione ""%1"".';
				|pl = 'Dla wpłaty z operacją ""%1"" nie jest wymagane wprowadzenie zapisu korygującego.';
				|tr = '""%1"" işlemine sahip makbuzlar bir düzenleme girilmesini gerektirmez.'"),
			Selection.EconomicOperationOfFoundation);
		Raise Text;
	EndIf;
	
	If Selection.ThereAreErrorsVATTaxation Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để tiếp nhận có thuế ""%1"", không cần nhập điều chỉnh.';
				|ru = 'Для поступления с налогообложением ""%1"" не требуется вводить корректировку.';
				|en = 'For a receipt with taxation ""%1"", the adjustment is not required'; fa = 'For a receipt with taxation ""%1"", the adjustment is not required';
				|it = 'Non è richiesta la rettifica per l''arrivo con la tassazione ""%1"".';
				|pl = 'Dla wpłaty z opodatkowaniem ""%1"" nie jest wymagane  wprowadzenie zapisu korygującego..';
				|tr = '""%1"" vergilendirmesine sahip makbuzlar bir düzenleme girilmesini gerektirmez.'"),
			Selection.VATTaxation);
		Raise Text;
	EndIf;
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.DocumentBasis,
		, // Status
		Selection.ThereAreErrorsPosted);
	
	FillPropertyValues(FillingData, Selection);
	FillPropertyValues(ThisObject, Selection, "BusinessOperation, Organization, Partner, Counterparty, Terms, Contract, Currency, ARAPCurrency ");
		
	Documents.PurchaseAdjustment.FillInProductsBasedOnSourceData(Selection.DocumentBasis, Goods);
	
EndProcedure

Procedure IncomeFromServicesOtherAssets(Val DocumentBasis, FillingData)
	
	MetadataDocumentBase = DocumentBasis.Metadata();
	If Not AccessRight("Update", MetadataDocumentBase) Then
		ErrorText = NStr("vi = 'Ở người sử dụng không đủ quyền điều chỉnh chứng từ ""';
						|ru = 'У пользователя недостаточно прав на корректировку документа ""';
						|en = 'User is not authorized to adjust document ""'; fa = 'User is not authorized to adjust document ""';
						|it = 'Utente non ha i diritti sufficienti per eseguire la rettifica del documento ""';
						|pl = 'Użytkownik ma niewystarczające uprawnienia na zapis korygujący dokumentu ""';
						|tr = 'Kullanıcının "" "" belgesini düzenlemek için yeterli hakkı yok'")
			+ MetadataDocumentBase.Synonym + """.";
		Raise ErrorText;
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("DocumentBasis", DocumentBasis);
	
	If Not ValueIsFilled(DocumentBasis) Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	DocumentData.Ref				 AS DocumentBasis,
	|	DocumentData.Partner				 AS Partner,
	|	DocumentData.Counterparty			 AS Counterparty,
	|	DocumentData.Terms			 AS Terms,
	|	DocumentData.Organization			 AS Organization,
	|	DocumentData.Contract				 AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Currency				 AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.VATTaxation	 AS VATTaxation,
	|	DocumentData.PurchaseForActivity AS PurchaseForActivity,
	|	DocumentData.Department		 AS Department,
	|	DocumentData.PriceIncludesVAT		 AS PriceIncludesVAT,
	|	DocumentData.ARAPObjectSettings		 AS ARAPObjectSettings,
	|	FALSE								 AS ReceiptUnderOrders,
	|	NOT DocumentData.Posted			 AS ThereAreErrorsPosted,
	|	DocumentData.BusinessOperation AS EconomicOperationOfFoundation,
	|	
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier) THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS ThereAreErrorsOperation,
	|
	|	CASE
	|		WHEN DocumentData.VATTaxation IN (VALUE(Enum.VATTaxationTypes.VATTaxAgent),
	|												VALUE(Enum.VATTaxationTypes.DigitalServices)) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS ThereAreErrorsVATTaxation,
	|
	|	DocumentData.BusinessOperation AS BusinessOperation
	|	
	|FROM
	|	Document.VendorInvoiceServicesAndAssets AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentBasis
	|");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập điều chỉnh tiếp nhận trên cơ sở chứng từ %1.';
				|ru = 'Не требуется вводить корректировку поступления на основании документа %1.';
				|en = 'Generating receipt adjustment from base document %1 is not required.'; fa = 'Generating receipt adjustment from base document %1 is not required.';
				|it = 'Non è necessario immettere la rettifica dell''arrivo in base al documento %1.';
				|pl = 'Nie wymaga się wprowadzać zapis korygujący wpłaty na podstawie dokumentu %1.';
				|tr = '%1 belgesine dayalı bir gelir düzenlemesi girmeye gerek yoktur.'"),
			DocumentBasis);
		Raise Text;
	EndIf;
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	If Selection.ThereAreErrorsOperation Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để tiếp nhận với giao dịch ""%1"" không nên nhập điều chỉnh.';
				|ru = 'Для поступления с операцией ""%1"" не требуется вводить корректировку.';
				|en = 'For a receipt with operation ""%1"" the adjustment is not required.'; fa = 'For a receipt with operation ""%1"" the adjustment is not required.';
				|it = 'Non è richiesta la rettifica per l''arrivo con operazione ""%1"".';
				|pl = 'Dla wpłaty z operacją ""%1"" nie jest wymagane wprowadzenie zapisu korygującego.';
				|tr = '""%1"" işlemine sahip makbuzlar bir düzenleme girilmesini gerektirmez.'"),
			Selection.EconomicOperationOfFoundation);
		Raise Text;
	EndIf;
	
	If Selection.ThereAreErrorsVATTaxation Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để tiếp nhận có thuế ""%1"", không cần nhập điều chỉnh.';
				|ru = 'Для поступления с налогообложением ""%1"" не требуется вводить корректировку.';
				|en = 'For a receipt with taxation ""%1"", the adjustment is not required'; fa = 'For a receipt with taxation ""%1"", the adjustment is not required';
				|it = 'Non è richiesta la rettifica per l''arrivo con la tassazione ""%1"".';
				|pl = 'Dla wpłaty z opodatkowaniem ""%1"" nie jest wymagane  wprowadzenie zapisu korygującego..';
				|tr = '""%1"" vergilendirmesine sahip makbuzlar bir düzenleme girilmesini gerektirmez.'"),
			Selection.VATTaxation);
		Raise Text;
	EndIf;
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.DocumentBasis,
		, // Status
		Selection.ThereAreErrorsPosted);
	
	FillPropertyValues(FillingData, Selection);
	FillPropertyValues(ThisObject, Selection, "Organization, Partner, Counterparty, Terms, Contract, Currency, ARAPCurrency, BusinessOperation");
	
	Documents.PurchaseAdjustment.FillInProductsBasedOnSourceData(Selection.DocumentBasis, Goods);
	
EndProcedure

Procedure FillInPrimaryDocument(Val DocumentBasis, FillingData)

	MetadataDocumentBase = DocumentBasis.Metadata();
	If Not AccessRight("Read", MetadataDocumentBase) Then
		ErrorText = NStr("vi = 'Người sử dụng không đủ quyền điều chỉnh chứng từ ""';
						|ru = 'У пользователя недостаточно прав на корректировку документа ""';
						|en = 'User is not authorized to adjust document ""'; fa = 'User is not authorized to adjust document ""';
						|it = 'Utente non ha i diritti sufficienti per eseguire la rettifica del documento ""';
						|pl = 'Użytkownik ma niewystarczające uprawnienia na zapis korygujący dokumentu ""';
						|tr = 'Kullanıcının "" "" belgesini düzenlemek için yeterli hakkı yok'")
			+ MetadataDocumentBase.Synonym + """.";
		Raise ErrorText;
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("DocumentBasis", DocumentBasis);
	
	If Not ValueIsFilled(DocumentBasis) Then
		Return;
	EndIf;
	
	QueryTextTheseGrounds = 
	"SELECT ALLOWED
	|	SourceDocument.Ref AS DocumentBasis,
	|	SourceDocument.SourceDocumentType AS DocumentType,
	|	SourceDocument.Organization AS Organization,
	|	SourceDocument.Counterparty AS Counterparty,
	|	SourceDocument.Contract AS Contract,
	|	ISNULL(SourceDocument.Contract.ContractType, VALUE(Enum.ContractTypes.EmptyRef)) AS ContractType,
	|	SourceDocument.Currency AS Currency,
	|	SourceDocument.ARAPCurrency AS ARAPCurrency,
	|	SourceDocument.DocumentAmount AS DocumentAmount,
	|	SourceDocument.Partner AS Partner,
	|	SourceDocument.LineOfBusiness AS LineOfBusiness,
	|	SourceDocument.Department AS Department,
	|	SourceDocument.ARAPObjectSettings AS ARAPObjectSettings,
	|	SourceDocument.VATTaxation AS VATTaxation,
	|	NOT SourceDocument.Posted AS ThereAreErrorsPosted,
	|	ISNULL(PreviousDocument.AdjustingEntryType, 
	|		&AdjustingEntryType)AS AdjustingEntryType,
	|	ISNULL(PreviousDocument.Ref.Terms, VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)) AS Terms,
	|	ISNULL(PreviousDocument.Ref.Warehouse, VALUE(Catalog.Warehouses.EmptyRef)) AS Warehouse
	|FROM
	|	Document.SourceDocument AS SourceDocument
	|	LEFT JOIN 
	|		TTPreviousAdjustment AS PreviousDocument 
	|		ON TRUE
	|WHERE
	|	SourceDocument.Ref = &DocumentBasis";
	
	QueryTexts = New Array;
	QueryTexts.Add(Documents.PurchaseAdjustment.QueryTextTTPreviousAdjustmentData());
	QueryTexts.Add(QueryTextTheseGrounds);
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("Date", CurrentSessionDate());
	Query.SetParameter("AdjustingEntryType", AdjustingEntryType);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập điều chỉnh tiếp nhận trên cơ sở chứng từ %1.';
				|ru = 'Не требуется вводить корректировку поступления на основании документа %1.';
				|en = 'Generating receipt adjustment from base document %1 is not required.'; fa = 'Generating receipt adjustment from base document %1 is not required.';
				|it = 'Non è necessario immettere la rettifica dell''arrivo in base al documento %1.';
				|pl = 'Nie wymaga się wprowadzać zapis korygujący wpłaty na podstawie dokumentu %1.';
				|tr = '%1 belgesine dayalı bir gelir düzenlemesi girmeye gerek yoktur.'"),
			DocumentBasis);
		Raise Text;
	EndIf;
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	If Selection.DocumentType <> Enums.SourceDocumentTypes.PurchaseFromVendor Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập điều chỉnh tiếp nhận trên cơ sở chứng từ %1, với kiểu chứng từ %2.';
				|ru = 'Не требуется вводить корректировку поступления на основании документа %1, с типом документа %2.';
				|en = 'Do not enter receipt adjustment based on the %1 document with the %2 document type.'; fa = 'Do not enter receipt adjustment based on the %1 document with the %2 document type.';
				|it = 'Non è richiesto l''inserimento della correzione di ricezione nel documento di base %1, con tipo di documento %2.';
				|pl = 'Nie wymaga się wprowadzać zapis korygujący wpłaty na podstawie dokumentu %1, z typem dokumentu %2.';
				|tr = 'Belge türü %2 olan %1 belgesine dayalı bir makbuz düzeltmesi girmek gerekli değildir.'"),
			DocumentBasis,
			Selection.DocumentType);
		Raise Text;
	EndIf;
	
	If Selection.ContractType <> Enums.ContractTypes.WithVendor
		And Selection.ContractType <> Enums.ContractTypes.TransferToTolling2_5
		And ValueIsFilled(Selection.Contract) Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập điều chỉnh tiếp nhận trên cơ sở chứng từ %1, với kiểu hợp đồng %2.';
				|ru = 'Не требуется вводить корректировку поступления на основании документа %1, с типом договора %2.';
				|en = 'Do not enter the receipt adjustment based on the %1 document with the %2 contract type.'; fa = 'Do not enter the receipt adjustment based on the %1 document with the %2 contract type.';
				|it = 'Non è richiesto l''inserimento della correzione di ricezione nel documento di base %1, con tipo di accordo %2.';
				|pl = 'Nie wymagane jest wprowadzenie korekty przyjęcia na podstawie dokumentu %1, z typem umowy %2.';
				|tr = 'Sözleşme türü %2 olan %1 belgesine dayalı bir makbuz düzeltmesi girmek gerekli değildir.'"),
			DocumentBasis,
			Selection.ContractType);
		Raise Text;
	EndIf;
	
	If Not ValueIsFilled(Selection.VATTaxation) Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập điều chỉnh tiếp nhận trên cơ sở chứng từ %1 mà chưa điền hệ thống thuế.';
				|ru = 'Не требуется вводить корректировку поступления на основании документа %1, с не заполненным налогообложением.';
				|en = 'Do not enter the receipt adjustment based on the %1 document with empty taxation.'; fa = 'Do not enter the receipt adjustment based on the %1 document with empty taxation.';
				|it = 'Non è richiesto l''inserimento della correzione di ricezione nel documento di base %1, con tassazione non compilata.';
				|pl = 'Nie wymagane jest wprowadzanie korekty przyjęcia na podstawie dokumentu %1, z niewypełnionym opodatkowaniem.';
				|tr = 'Vergilendirmesi doldurulmamış %1 belgesine dayalı bir makbuz düzeltmesi girmek gerekli değildir.'"),
			DocumentBasis,
			Selection.ContractType);
		Raise Text;
	EndIf;
	
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập điều chỉnh tiếp nhận trên cơ sở chứng từ %1 khi tắt tùy chọn chức năng ""Cấu trúc hạch toán công nợ mới"".';
				|ru = 'Не требуется вводить корректировку поступления на основании документа %1, при выключенной функциональной опции ""Новая архитектура взаиморасчетов"".';
				|en = 'Do not enter receipt adjustment based on the %1 document with the disabled ""New AR/AP configuration"" functional option.'; fa = 'Do not enter receipt adjustment based on the %1 document with the disabled ""New AR/AP configuration"" functional option.';
				|it = 'Non è richiesto l''inserimento della correzione di ricezione nel documento di base %1, quando la funzionalità di variante ""Nuova architettura dei conti reciproci"" è disattivata.';
				|pl = 'Nie jest wymagane wprowadzenie korekty przyjęcia na podstawie dokumentu %1, przy wyłączonej opcji funkcjonalnej ""Nowa architektura rozliczeń wzajemnych"".';
				|tr = '""Yeni Karşılıklı Hesaplar Mimarisi"" işlevi devre dışı bırakıldığında, %1 belgesine dayalı bir makbuz düzeltmesi girmeye gerek yoktur.'"),
			DocumentBasis);
		Raise Text;
	EndIf;
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.DocumentBasis,
		, // Status
		Selection.ThereAreErrorsPosted);
		
	FillPropertyValues(FillingData, Selection);
	FillPropertyValues(ThisObject, Selection);
	
	Documents.PurchaseAdjustment.FillInProductsBasedOnSourceData(Selection.DocumentBasis, Goods);
	
	// Filling in the series indication statuses
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.PurchaseAdjustment);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

Procedure FillInAccordingToDiscrepancyCertificate(Val ParametersStructure, FillingData)
	
	ReceiptDocument      = ParametersStructure.BasisOfAct;
	DocumentActOnDiscrepancies = ParametersStructure.DiscrepancyCertificate;
	
	MetadataDocumentBase = ReceiptDocument.Metadata();
	If Not AccessRight("Update", MetadataDocumentBase) Then
		ErrorText = NStr("vi = 'Ở người sử dụng không đủ quyền điều chỉnh chứng từ ""';
						|ru = 'У пользователя недостаточно прав на корректировку документа ""';
						|en = 'User is not authorized to adjust document ""'; fa = 'User is not authorized to adjust document ""';
						|it = 'Utente non ha i diritti sufficienti per eseguire la rettifica del documento ""';
						|pl = 'Użytkownik ma niewystarczające uprawnienia na zapis korygujący dokumentu ""';
						|tr = 'Kullanıcının "" "" belgesini düzenlemek için yeterli hakkı yok'")
			+ MetadataDocumentBase.Synonym + """.";
		Raise ErrorText;
	EndIf;
	
	If Not ValueIsFilled(ReceiptDocument)
		Or Not ValueIsFilled(DocumentActOnDiscrepancies) Then
		Return;
	EndIf;
	
	FillingData = New Structure;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DocumentData.Ref                  AS DocumentBasis,
	|	DocumentData.Partner                 AS Partner,
	|	DocumentData.Counterparty              AS Counterparty,
	|	DocumentData.Terms              AS Terms,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.Warehouse                   AS Warehouse,
	|	DocumentData.Department           AS Department,
	|	DocumentData.SalesOpportunity                  AS SalesOpportunity,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Currency                  AS Currency,
	|	DocumentData.ARAPCurrency    AS ARAPCurrency,
	|	DocumentData.Manager                AS Manager,
	|	DocumentData.PaymentMethod             AS PaymentMethod,
	|	DocumentData.PriceIncludesVAT         AS PriceIncludesVAT,
	|	DocumentData.VATTaxation      AS VATTaxation,
	|	DocumentData.ReceiptUnderOrders    AS ReceiptUnderOrders,
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.IncomingDocumentDate  AS IncomingDocumentDate,
	|	DocumentData.ARAPObjectSettings         AS ARAPObjectSettings,
	|	DocumentData.GoodsReceiptOption   AS GoodsReceiptOption,
	|	DocumentData.Contract.ServiceReceiptOption AS ServiceReceiptOption,
	|	DocumentData.BusinessOperation   AS EconomicOperationOfFoundation,
	|	NOT DocumentData.Posted             AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (&Available_BusinessTransactions)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsOperation,
	|	CASE
	|		WHEN DocumentData.VATTaxation IN (VALUE(Enum.VATTaxationTypes.VATTaxAgent),
	|												VALUE(Enum.VATTaxationTypes.DigitalServices))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreErrorsVATTaxation,
	|	FALSE AS ThereAreErrorsStatus,
	|	DiscrepancyReportFollowingReceipt.DiscrepanciesPostingMethod AS DiscrepanciesPostingMethod,
	|	DiscrepancyReportFollowingReceipt.Ref AS DiscrepancyReportFollowingReceiptBaseDocument,
	|	CASE
	|		WHEN DiscrepancyReportFollowingReceipt.Status IN (VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion), VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsStatusActDiscrepancies,
	|	NOT DiscrepancyReportFollowingReceipt.Posted AS ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
	|	DiscrepancyReportFollowingReceipt.Status AS StatusActOfDivergence,
	|	DocumentData.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt AS DiscrepancyReportFollowingReceipt
	|		ON (TRUE)
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DocumentActOnDiscrepancies
	|	AND DocumentData.Ref = &ReceiptDocument";
	
	Available_BusinessTransactions = New Array();
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit);
	Available_BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	
	Query.SetParameter("Available_BusinessTransactions", Available_BusinessTransactions);
	Query.SetParameter("DocumentActOnDiscrepancies", DocumentActOnDiscrepancies);
	Query.SetParameter("ReceiptDocument", ReceiptDocument);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập điều chỉnh tiếp nhận trên cơ sở chứng từ %1.';
				|ru = 'Не требуется вводить корректировку поступления на основании документа %1.';
				|en = 'Generating receipt adjustment from base document %1 is not required.'; fa = 'Generating receipt adjustment from base document %1 is not required.';
				|it = 'Non è necessario immettere la rettifica dell''arrivo in base al documento %1.';
				|pl = 'Nie wymaga się wprowadzać zapis korygujący wpłaty na podstawie dokumentu %1.';
				|tr = '%1 belgesine dayalı bir gelir düzenlemesi girmeye gerek yoktur.'"),
			DocumentBasis);
		Raise Text;
	EndIf;
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	If Selection.ThereAreErrorsOperation Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Để tiếp nhận với giao dịch ""%1"" không nên nhập điều chỉnh.';
				|ru = 'Для поступления с операцией ""%1"" не требуется вводить корректировку.';
				|en = 'For a receipt with operation ""%1"" the adjustment is not required.'; fa = 'For a receipt with operation ""%1"" the adjustment is not required.';
				|it = 'Non è richiesta la rettifica per l''arrivo con operazione ""%1"".';
				|pl = 'Dla wpłaty z operacją ""%1"" nie jest wymagane wprowadzenie zapisu korygującego.';
				|tr = '""%1"" işlemine sahip makbuzlar bir düzenleme girilmesini gerektirmez.'"),
			Selection.EconomicOperationOfFoundation);
		Raise Text;
	EndIf;
	
	If Selection.DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CorrectSourceDocuments Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối với một hành động với phương pháp phản ánh sự khác biệt ""%1"" không cần điều chỉnh.';
				|ru = 'Для акта со способом отражения расхождений ""%1"" не требуется вводить корректировку.';
				|en = 'Adjustment is not required for the certificate with discrepancy record method ""%1"".'; fa = 'Adjustment is not required for the certificate with discrepancy record method ""%1"".';
				|it = 'Per un atto con la modalità di riportare le discrepanze ""%1"" non è necessario immettere la rettifica.';
				|pl = 'Dla aktu ze sposobem odzwierciedlenie odchylenia ""%1"" nie jest wymagane wprowadzenie zapisu korygującego.';
				|tr = 'Tutarsızlık yöntemi ""%1"" olan bir rapor için herhangi bir düzeltme girilmesine gerek yoktur.'"),
			Selection.DiscrepanciesPostingMethod);
		Raise Text;
	EndIf;
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfDiscrepancyReport.ForCompletion);
	ArrayOfValidStatuses.Add(Enums.StatusesOfDiscrepancyReport.Processed_);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.DiscrepancyReportFollowingReceiptBaseDocument,
		Selection.StatusActOfDivergence,
		Selection.ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
		Selection.ThereAreErrorsStatusActDiscrepancies,
		ArrayOfValidStatuses);
		
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.DocumentBasis,
		, // Status
		Selection.ThereAreErrorsPosted);
		
	FillPropertyValues(FillingData, Selection);
	FillPropertyValues(ThisObject, Selection, "Organization, Warehouse, Currency, ARAPCurrency, DocumentBasis, DiscrepancyReportFollowingReceiptBaseDocument, PriceIncludesVAT, VATTaxation, BusinessOperation, Contract");
	
	Documents.PurchaseAdjustment.FillInGoodsAccordingToCertificateOfDiscrepancies(ThisObject);
	
	// Filling in the series indication statuses
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.PurchaseAdjustment);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	SeriesSpecificationParameters.NameTSGoods = "Discrepancies";
	SeriesSpecificationParameters.TSSeriesName  = "Discrepancies";
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure
Procedure FillInReportOfProcessor(Val DocumentBasis, FillingData)
	
	MetadataDocumentBase = DocumentBasis.Metadata();
	If Not AccessRight("Update", MetadataDocumentBase) Then
		ErrorText = NStr("vi = 'Người sử dụng không đủ quyền điều chỉnh chứng từ ""';
						|ru = 'У пользователя недостаточно прав на корректировку документа ""';
						|en = 'User is not authorized to adjust document ""'; fa = 'User is not authorized to adjust document ""';
						|it = 'Utente non ha i diritti sufficienti per eseguire la rettifica del documento ""';
						|pl = 'Użytkownik ma niewystarczające uprawnienia na zapis korygujący dokumentu ""';
						|tr = 'Kullanıcının "" "" belgesini düzenlemek için yeterli hakkı yok'")
			+ MetadataDocumentBase.Synonym + """.";
		Raise ErrorText;
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("DocumentBasis", DocumentBasis);
	
	If Not ValueIsFilled(DocumentBasis) Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	DocumentData.Ref                   AS DocumentBasis,
	|	DocumentData.Partner                  AS Partner,
	|	DocumentData.Counterparty               AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.Contract                  AS Contract,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	DocumentData.Currency                   AS Currency,
	|	DocumentData.ARAPCurrency     AS ARAPCurrency,
	|	DocumentData.VATTaxation       AS VATTaxation,
	|	DocumentData.Department            AS Department,
	|	DocumentData.LineOfBusiness  AS LineOfBusiness,
	|	DocumentData.SalesOpportunity                   AS SalesOpportunity,
	|	DocumentData.PriceIncludesVAT          AS PriceIncludesVAT,
	|	DocumentData.ARAPObjectSettings          AS ARAPObjectSettings,
	|	DocumentData.ByOrders                AS ReceiptUnderOrders,
	|	NOT DocumentData.Posted              AS ThereAreErrorsPosted,
	|	VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment) AS EconomicOperationOfFoundation,
	|	
	|	FALSE                                     AS ThereAreErrorsOperation,
	|	FALSE                                     AS ThereAreErrorsVATTaxation,
	|
	|	VALUE(Enum.BusinessTransactions.SubcontractorReportAdjustment) AS BusinessOperation
	|	
	|FROM
	|	Document.SubcontractorReport2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentBasis
	|");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập điều chỉnh trên cơ sở chứng từ %1.';
				|ru = 'Не требуется вводить корректировку на основании документа %1.';
				|en = 'Generation of adjustment from the %1 document is not required.'; fa = 'Generation of adjustment from the %1 document is not required.';
				|it = 'Non è necessario immettere la rettifica in base al documento %1.';
				|pl = 'Nie jest wymagane wprowadzanie korekty na podstawie dokumentu %1.';
				|tr = '%1 belgesine dayalı bir düzeltme girilmesine gerek yoktur.'"),
			DocumentBasis);
		Raise Text;
	EndIf;
	
	For Each Column In QueryResult.Columns Do
		FillingData.Insert(Column.Name);
	EndDo;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.DocumentBasis,
		, // Status
		Selection.ThereAreErrorsPosted);
	
	FillPropertyValues(FillingData, Selection);
	FillPropertyValues(ThisObject, Selection, "Organization, Currency, ARAPCurrency, DocumentBasis, PriceIncludesVAT, VATTaxation, BusinessOperation");
	
	Documents.PurchaseAdjustment.FillInProductsBasedOnSourceData(Selection.DocumentBasis, Goods);
	
EndProcedure
#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	If AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfAcquisitionIncreaseInDebtConsolidated
		Or AdjustmentKind = Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated Then
		Return;
	EndIf;
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoiceServicesAndAssets")
		Or TypeOf(DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5")
		Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If TypeOf(DocumentBasis) <> Type("DocumentRef.SourceDocument") Then
		DocumentBusinessTransaction = Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation");
	Else
		DocumentBusinessTransaction = BusinessOperation;
	EndIf;
	
	UseSeparateProcurement = PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(DocumentBusinessTransaction);
	UsePrimaryDocument = AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices
		Or AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
	
	TempTablesManager = TemporaryDocumentDataTables(DocumentBusinessTransaction);
	
	RefillInventoryKinds = Not Posted
								Or InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject)
								Or CheckChangesToDocumentDetails(TempTablesManager)
								Or CheckProductChanges_(TempTablesManager);
	
	If UseSeparateProcurement
		And RefillInventoryKinds Then
		
		FillInInventoryOwnerAttributeOfWorksBeingTracked(DocumentBusinessTransaction);
		
		Filter = New Structure("PostingOption, IncludeTraceableWorks", New Array, False);
		Filter.PostingOption.Add(Enums.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners);
		Filter.PostingOption.Add(Enums.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost);
		Filter.PostingOption.Add(Enums.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome);
		
		TemporaryTableManagerSurplus = TemporaryDocumentDataTables(DocumentBusinessTransaction, Filter);
		
		Filter.Insert("IncludeTraceableWorks", False);
		Filter.PostingOption.Clear();
		Filter.PostingOption.Add(Enums.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners);
		Filter.PostingOption.Add(Enums.OptionsOfPostingReceiptAdjustingEntries.ReduceCost);
		Filter.PostingOption.Add(Enums.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs);
		
		ManagerOfTemporaryShortageTables = TemporaryDocumentDataTables(DocumentBusinessTransaction, Filter);
		
		TypesOfStocksIntermediate = InventoryKinds.Unload(New Array);
		
		InventoryKinds.Clear();
		
		// we allow you to write off balances on empty GTD numbers
		AdditionalProperties.Insert("MonitorCCDNumbers", False);
		
		FillParameters = ParametersForFillingInventoryTypes(True, DocumentBusinessTransaction);
		
		InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																TemporaryTableManagerSurplus,
																Cancel,
																FillParameters);
		
		CommonClientServer.SupplementTable(InventoryKinds.Unload(), TypesOfStocksIntermediate);
		InventoryKinds.Clear();
		
		// we allow you to write off balances on empty GTD numbers
		AdditionalProperties.Insert("MonitorCCDNumbers", False);
		
		FillParameters = ParametersForFillingInventoryTypes(False, DocumentBusinessTransaction);
		
		InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																ManagerOfTemporaryShortageTables,
																Cancel,
																FillParameters);
		
		CommonClientServer.SupplementTable(TypesOfStocksIntermediate, InventoryKinds);
		
		InventoryKindsWithPrices = InventoryKinds.Unload();
		For Each TableRow In InventoryKindsWithPrices Do
			TableRow.Price = ?(TableRow.Count = 0, 0, TableRow.AmountIncludingVAT / TableRow.Count);
		EndDo;	
		
		InventoryKindsWithPrices.GroupBy(
			"ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, PostingOption, VATRate, Price",
			"Count, QuantityByGBRN"
		);
		
		InventoryKinds.Load(InventoryKindsWithPrices);
		
		FillInAdditionalStockTypes();
		
		ThisIsNonfacturing = DocumentBusinessTransaction = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
			Or DocumentBusinessTransaction = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
		
		If ThisIsNonfacturing Then
			FillInByAnalystsTakingIntoAccountSeries();
		EndIf;
		
	ElsIf Not UseSeparateProcurement
		And Not UsePrimaryDocument
		And RefillInventoryKinds Then

		InventoriesServer.FillStockTypesByDefault(TempTablesManager, Discrepancies);
		
		DocumentDiscrepancies_ = Discrepancies.Unload();
		
		Filter = New Structure("IncludeTraceableWorks", False);
		TempTablesManager	= TemporaryDocumentDataTables(DocumentBusinessTransaction, Filter);
		
		FillParameters = ParametersForFillingInventoryTypes(False, DocumentBusinessTransaction);
		FillParameters.NameTSTypesOfStocks	= "Discrepancies";
		FillParameters.NameOfRemainderTable	= "AcceptedGoods";
		
		InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		AllocateInventoryForDiscrepancies(DocumentDiscrepancies_, DocumentBusinessTransaction);
		
	ElsIf RefillInventoryKinds Then
		
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, Discrepancies);
		
		DocumentDiscrepancies_	= Discrepancies.Unload();
		
		Filter = New Structure("IncludeTraceableWorks", False);
		TempTablesManager	= TemporaryDocumentDataTables(DocumentBusinessTransaction, Filter);
		
		FillParameters = ParametersForFillingInventoryTypes(False, DocumentBusinessTransaction);
		FillParameters.NameTSTypesOfStocks	= "Discrepancies";
		FillParameters.NameOfRemainderTable	= "CompanyGoods";
		FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
		FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		DiscrepanciesTypesOfStocks = Discrepancies.Unload();
		
		DiscrepanciesTypesOfStocks.Columns.Count.Name = "QuantityForDistribution";
		
		For Each String In DiscrepanciesTypesOfStocks Do
			String.QuantityForDistribution = -String.QuantityForDistribution;
		EndDo;
		
		Var_Key	= "Products, Characteristic, Purpose, Series, CCDNumber";
		Condition	= "On [Count]";
		
		InvoicesServer.DistributeQuantityAndFill(DiscrepanciesTypesOfStocks,
														DocumentDiscrepancies_,
														"QuantityForDistribution",
														Var_Key,
														Condition,
														True,
														"InventoryOwnerAttribute");
		
		Discrepancies.Load(DocumentDiscrepancies_);
		
	EndIf;
	
EndProcedure

Procedure FillInByAnalystsTakingIntoAccountSeries()
	
	// 1. Distribution of shortages - using the analytics of the foundation document.
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	VendorInvoiceInventoryKinds.LineNumber AS LineNumber,
	|	VendorInvoiceInventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	VendorInvoiceInventoryKinds.ItemsLocationAttributes.Products AS Products,
	|	VendorInvoiceInventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	VendorInvoiceInventoryKinds.ItemsLocationAttributes.Purpose AS Purpose,
	|	VendorInvoiceInventoryKinds.ItemsLocationAttributes.Series AS Series,
	|	VendorInvoiceInventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	VendorInvoiceInventoryKinds.CCDNumber AS CCDNumber,
	|	VendorInvoiceInventoryKinds.Count AS Count,
	|	VendorInvoiceInventoryKinds.QuantityByGBRN AS QuantityByGBRN
	|FROM
	|	Document.VendorInvoice.InventoryKinds AS VendorInvoiceInventoryKinds
	|WHERE
	|	VendorInvoiceInventoryKinds.Ref = &Ref";
	
	TableTypesOfStocks_ = InventoryKinds.Unload();
	
	TableTypesOfStocks_.Columns.Add("ProductAccountingAnalyticsBasedOnAcquisitionData", New TypeDescription("CatalogRef.InventoryLocationAttributeKeys"));
	TableTypesOfStocks_.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	TableTypesOfStocks_.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableTypesOfStocks_.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	TableTypesOfStocks_.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	TableTypesOfStocks_.Columns.Add("QuantityAccordingToAcquisitionData", New TypeDescription("Number"));
	TableTypesOfStocks_.Columns.Add("QuantityModulo", New TypeDescription("Number"));
	TableTypesOfStocks_.Columns.Add("QuantityAccordingToProductBatchIDModulo", New TypeDescription("Number"));
	
	TableTypesOfStocks_.Columns.Add("AnalysisOfProductAccountingByRegister", New TypeDescription("CatalogRef.InventoryLocationAttributeKeys"));
	TableTypesOfStocks_.Columns.Add("NumberByCase", New TypeDescription("Number"));
	
	For Each String In TableTypesOfStocks_ Do
		AttributesValues = Common.ObjectAttributesValues(String.ItemsLocationAttributes, "Products, Characteristic, Purpose, Series");
		FillPropertyValues(String, AttributesValues);
		String.QuantityModulo = ?(String.Count < 0, -String.Count, String.Count);
		String.QuantityAccordingToProductBatchIDModulo = ?(String.QuantityByGBRN < 0, -String.QuantityByGBRN, String.QuantityByGBRN);
	EndDo;
	
	Query.SetParameter("Ref", DocumentBasis);
	
	Result = Query.Execute().Unload();
	Result.Columns.Count.Name = "QuantityAccordingToAcquisitionData";
	Result.Columns.ItemsLocationAttributes.Name = "ProductAccountingAnalyticsBasedOnAcquisitionData";
	
	Query.Text = "
		|SELECT
		|	*
		|INTO TTTableTypesOfStocks
		|FROM
		|	&TableTypesOfStocks_ AS TableTypesOfStocks_
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT *
		|FROM
		|	TTTableTypesOfStocks AS TableTypesOfStocks_
		|WHERE
		|	TableTypesOfStocks_.Count < 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT *
		|FROM
		|	TTTableTypesOfStocks AS TableTypesOfStocks_
		|WHERE
		|	TableTypesOfStocks_.Count > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT *
		|FROM
		|	TTTableTypesOfStocks AS TableTypesOfStocks_
		|WHERE
		|	TableTypesOfStocks_.Count = 0";
	
	Query.SetParameter("TableTypesOfStocks_", TableTypesOfStocks_);
	DataOnTypesOfStocks = Query.ExecuteBatch();
	TableTypesOfStocks_Expense = DataOnTypesOfStocks[1].Unload(); 
	TableTypesOfStocks_Receipt = DataOnTypesOfStocks[2].Unload();
	TableTypesOfInventoryAmounts   = DataOnTypesOfStocks[3].Unload();
	
	Var_Key = "Products, Characteristic, Purpose, CCDNumber, Series";
	
	Condition = "On [QuantityModulo]";
	InvoicesServer.DistributeQuantityAndFill(Result, TableTypesOfStocks_Expense, 
		"QuantityAccordingToAcquisitionData", Var_Key, Condition, False, "ProductAccountingAnalyticsBasedOnAcquisitionData");
	
	For Each String In TableTypesOfStocks_Expense Do
		If ValueIsFilled(String.ProductAccountingAnalyticsBasedOnAcquisitionData)
			And String.Count < 0
			Or (String.Count <= 0
				And String.AmountARAP < 0) Then
			String.ItemsLocationAttributes = ?(String.ProductAccountingAnalyticsBasedOnAcquisitionData
				<> Catalogs.InventoryLocationAttributeKeys.EmptyRef(),
					String.ProductAccountingAnalyticsBasedOnAcquisitionData,
					String.ItemsLocationAttributes);
			// If the initial quantity = 0, then the difference is only cumulative. It is enough to install only analytics.
			If String.Count > 0 Then
				String.Count = String.QuantityAccordingToAcquisitionData;
				String.QuantityByGBRN = String.Count * String.QuantityAccordingToProductBatchIDModulo / String.QuantityModulo;
			ElsIf String.Count < 0 Then
				String.Count = -String.QuantityAccordingToAcquisitionData;
				String.QuantityByGBRN = String.Count * String.QuantityAccordingToProductBatchIDModulo / String.QuantityModulo;
			EndIf;
		EndIf;
	EndDo;
	
	// 2. The distribution of surpluses is completely similar to the acquisition, i.e. the selection of goods from PH organizations.
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	CAST(InventoryKinds.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTInitialStockInventoryOwnerAttributes
	|FROM
	|	&InventoryKinds AS InventoryKinds
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTTypesOfStocks
	|FROM
	|	TTInitialStockInventoryOwnerAttributes AS InventoryKinds
	|GROUP BY
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute
	|INDEX BY
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Dimension.DimensionKey AS Dimension,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTAnalyst
	|FROM
	|	InformationRegister.ItemsLocationAttributes AS Dimension
	|		INNER JOIN TTTypesOfStocks AS InventoryKinds
	|		ON Dimension.Products = InventoryKinds.ItemsLocationAttributes.Products
	|			AND Dimension.Characteristic = InventoryKinds.ItemsLocationAttributes.Characteristic
	|			AND Dimension.StorageLocation = InventoryKinds.ItemsLocationAttributes.StorageLocation
	|			AND Dimension.Purpose = InventoryKinds.ItemsLocationAttributes.Purpose
	|			AND Dimension.ProductCostElement = InventoryKinds.ItemsLocationAttributes.ProductCostElement
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|	SELECT
	|		TableTypesOfStocks_Expense.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		-TableTypesOfStocks_Expense.Count AS Count
	|	INTO AnalystBalancesInCaseOfShortage
	|	FROM
	|		&TableTypesOfStocks_Expense AS TableTypesOfStocks_Expense
	|	WHERE
	|		TableTypesOfStocks_Expense.Count < 0	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////	
	|SELECT
	|	Set.Priority AS Priority,
	|	Set.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Set.ItemsLocationAttributes.Products AS Products,
	|	Set.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	Set.ItemsLocationAttributes.Purpose AS Purpose,
	|	SUM(Set.Count) AS Count
	|FROM
	|	(SELECT
	|		Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		-Balance.CountBalance AS Count,
	|		2 AS Priority
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(
	|				,
	|				(ItemsLocationAttributes, InventoryOwnerAttribute) IN
	|						(SELECT
	|							Table.Dimension,
	|							Table.InventoryOwnerAttribute
	|						FROM
	|							TTAnalyst AS Table)
	|					AND Organization = &Organization) AS Balance
	|			INNER JOIN TTTypesOfStocks AS InventoryKinds
	|			ON Balance.ItemsLocationAttributes.Products = InventoryKinds.ItemsLocationAttributes.Products
	|				AND Balance.ItemsLocationAttributes.Characteristic = InventoryKinds.ItemsLocationAttributes.Characteristic
	|				AND Balance.ItemsLocationAttributes.StorageLocation = InventoryKinds.ItemsLocationAttributes.StorageLocation
	|				AND Balance.ItemsLocationAttributes.Purpose = InventoryKinds.ItemsLocationAttributes.Purpose
	|				AND Balance.ItemsLocationAttributes.ProductCostElement = InventoryKinds.ItemsLocationAttributes.ProductCostElement
	|	WHERE
	|		Balance.CountBalance < 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterRecords.ItemsLocationAttributes,
	|		RegisterRecords.Count,
	|		1 AS Priority
	|	FROM
	|		AccumulationRegister.CompanyGoods AS RegisterRecords
	|			INNER JOIN TTTypesOfStocks AS InventoryKinds
	|			ON RegisterRecords.ItemsLocationAttributes.Products = InventoryKinds.ItemsLocationAttributes.Products
	|				AND RegisterRecords.ItemsLocationAttributes.Characteristic = InventoryKinds.ItemsLocationAttributes.Characteristic
	|				AND RegisterRecords.ItemsLocationAttributes.StorageLocation = InventoryKinds.ItemsLocationAttributes.StorageLocation
	|				AND RegisterRecords.ItemsLocationAttributes.Purpose = InventoryKinds.ItemsLocationAttributes.Purpose
	|				AND RegisterRecords.ItemsLocationAttributes.ProductCostElement = InventoryKinds.ItemsLocationAttributes.ProductCostElement
	|	WHERE
	|		RegisterRecords.Recorder = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AnalystBalancesInCaseOfShortage.ItemsLocationAttributes,
	|		AnalystBalancesInCaseOfShortage.Count,
	|		3 AS Priority
	|	FROM
	|		AnalystBalancesInCaseOfShortage AS AnalystBalancesInCaseOfShortage
	|	) AS Set
	|
	|GROUP BY
	|	Set.Priority,
	|	Set.ItemsLocationAttributes
	|
	|ORDER BY
	|	Priority
	|";
	
	Query.SetParameter("InventoryKinds", TableTypesOfStocks_);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("TableTypesOfStocks_Expense", TableTypesOfStocks_Expense);
	
	Result = Query.Execute().Unload();
	Result.Columns.Count.Name = "NumberByCase";
	Result.Columns.ItemsLocationAttributes.Name = "AnalysisOfProductAccountingByRegister";
	
	Var_Key = "Products, Characteristic, Purpose";
	
	Condition = "On [Count]";
	InvoicesServer.DistributeQuantityAndFill(Result, TableTypesOfStocks_Receipt, 
		"NumberByCase", Var_Key, Condition, False, "AnalysisOfProductAccountingByRegister");
	
	For Each String In TableTypesOfStocks_Receipt Do
		If ValueIsFilled(String.AnalysisOfProductAccountingByRegister)
			And (String.Count > 0
			Or (String.Count >= 0
				And String.AmountARAP > 0)) Then
			String.ItemsLocationAttributes = ?(
				String.AnalysisOfProductAccountingByRegister
					<> Catalogs.InventoryLocationAttributeKeys.EmptyRef(),
						String.AnalysisOfProductAccountingByRegister,
						String.ItemsLocationAttributes);
			If String.Count > 0 Then
				String.Count = String.NumberByCase;
				String.QuantityByGBRN = String.Count * String.QuantityAccordingToProductBatchIDModulo / String.QuantityModulo;
			ElsIf String.Count < 0 Then
				String.Count = -String.NumberByCase;
				String.QuantityByGBRN = String.Count * String.QuantityAccordingToProductBatchIDModulo / String.QuantityModulo;
			EndIf;
		EndIf;
	EndDo;
	
	CommonClientServer.SupplementTable(TableTypesOfStocks_Receipt, TableTypesOfStocks_Expense);
	CommonClientServer.SupplementTable(TableTypesOfInventoryAmounts, TableTypesOfStocks_Expense);
	
	InventoryKinds.Load(TableTypesOfStocks_Expense);
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.PurchaseAdjustment.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.PurchaseAdjustment.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	DivergenceTable = DocumentTables.Discrepancies;
	
	AnalyticsSelectionOperation = AdjustmentKind;
	
	If ValueIsFilled(DocumentBasis)
		And TypeOf(DocumentBasis) <> Type("DocumentRef.SourceDocument") Then
		BaseOperation = Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation");
		If PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BaseOperation) Then
			AnalyticsSelectionOperation = BaseOperation;
		ElsIf BusinessOperation = Enums.BusinessTransactions.SubcontractorReportAdjustment Then
			AnalyticsSelectionOperation = BaseOperation;
		EndIf;
	EndIf;
	
	If TypeOf(DocumentBasis) <> Type("DocumentRef.VendorInvoiceServicesAndAssets")
		And AdjustingEntryType <> Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets Then
		PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(AnalyticsSelectionOperation,
																			Warehouse,
																			Department,
																			Partner,
																			Contract);
		
		If ValueIsFilled(DocumentBasis) Then
			
			InvoicingOperations = New Array;
			InvoicingOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
			InvoicingOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
			
			ContractDetails_ = Common.ObjectAttributesValues(Contract,
				"PurchaseRegistrationOption, OptionForRegisteringServiceReceiptDocuments");
			
			If InvoicingOperations.Find(BaseOperation) <> Undefined
				And (ContractDetails_.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices
				Or ContractDetails_.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced) Then
				
				PlacesOfAccounting.Work_5 = Contract;
				PlacesOfAccounting.Insert("OperationService", Contract);
				
			EndIf;
			
		EndIf;
		
		FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
		FieldsNames.Insert("Work_5", "Department");
		
		TextOfWarehouseProductField = "
			|CASE
			|	WHEN Collection.ToExpenseAs
			|		THEN Collection.Department
			|	ELSE UNDEFINED
			|END";
		
		If ValueIsFilled(Warehouse) Then
			WarehouseDetails = Common.ObjectAttributesValues(Warehouse, "IsFolder, SelectGroup");
		Else
			WarehouseDetails = New Structure;
			WarehouseDetails.Insert("IsFolder",	False);
			WarehouseDetails.Insert("SelectGroup",	Undefined);
		EndIf;
		
		If WarehouseDetails.IsFolder
			And Not PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BaseOperation)
			And WarehouseDetails.SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
			
			FieldsNames.Insert("Arbitrary", "Warehouse");
			
			TextOfWarehouseProductField = "
				|CASE
				|	WHEN Collection.ToExpenseAs
				|		THEN Collection.Department
				|	ELSE Collection.Warehouse
				|END";
			
		EndIf;
		
		FieldsNames.Insert("OwnGoods", New Structure("FieldText", TextOfWarehouseProductField));
		If BusinessOperation = Enums.BusinessTransactions.SubcontractorReportAdjustment Then
			FieldsNames.Insert("ProductCostElement", "ProductCostElement");
			FieldsNames.Purpose = "";
			FieldsNames.Work_5 = "";
			
			// The WIP for processing is taken into account in the context of contracts, not divisions.
			PlacesOfAccounting.Delete("Work_5");
		EndIf;
		InformationRegisters.ItemsLocationAttributes.FillInCollection(DivergenceTable, PlacesOfAccounting, FieldsNames);
	EndIf;
	
EndProcedure

Procedure FillInInventoryOwnerAttributeOfWorksBeingTracked(DocumentBusinessTransaction)
	
	TaxationOfOrganization = VATAccountingERP.AccountingParametersForOrganization(Organization, Date).BasicTaxationVATSales;
		
	NamesOfDocumentDetails = "Organization, InventoryType, GoodsOwner, Counterparty, Terms,
		|Contract, Currency, VATTaxation, TaxationOfOrganization, InventoryOwnerAttribute, FinancialAccountingGroup, ProductsGroup,
		|BusinessOperation, PriceKind, RetainedStockType";
	DocumentAttributes = New Structure(NamesOfDocumentDetails);
	FillPropertyValues(DocumentAttributes, ThisObject);
	DocumentAttributes.GoodsOwner = Partner;
	DocumentAttributes.InventoryType = Enums.InventoryTypes.Work_5;
	DocumentAttributes.TaxationOfOrganization = TaxationOfOrganization;
	DocumentAttributes.BusinessOperation = DocumentBusinessTransaction;
	
	InventoryOwnerAttributeOfTraceableWorks = Catalogs.InventoryKinds.DocumentInventoryView(Organization,
																	BusinessOperation,
																	DocumentAttributes);
	
	Query = New Query();
	Query.Text = 
	"SELECT DISTINCT
	|	Goods.Products AS Products
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|
	|;
	|SELECT
	|	Goods.Products AS Products
	|FROM
	|	TTProducts_1 AS Goods
	|WHERE
	|	Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND Goods.Products.TracedGoods
	|	AND &UseTraceableImportedGoodsAccounting
	|";
	
	Query.SetParameter("Period", Date);
	Query.SetParameter("Goods", Discrepancies.Unload());
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Selection = Query.Execute().Select();
	
	TheStructureOfTheSearch = New Structure("Products");
	While Selection.Next() Do
		FillPropertyValues(TheStructureOfTheSearch, Selection);
		FoundRows = Discrepancies.FindRows(TheStructureOfTheSearch);
		For Each FoundRow In FoundRows Do
			FoundRow.InventoryOwnerAttribute = InventoryOwnerAttributeOfTraceableWorks;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Function CheckFillingForDiscrepancies(NotCheckedAttributeArray, Cancel)
	
	AmountForOtherIncome			= 0;
	AmountForOtherExpenses		= 0;
	RecordInOtherIncome		= False;
	ToExpenseAs			= False;
	PaymentDateIsRequired		= False;
	
	For Each LineOfDiscrepancies In Discrepancies Do
		If LineOfDiscrepancies.PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.RecordInOtherIncome Then
			RecordInOtherIncome = True;
			AmountForOtherIncome		= AmountForOtherIncome
										+ ?(LineOfDiscrepancies.AmountIncludingVAT < 0,
											-LineOfDiscrepancies.AmountIncludingVAT,
											LineOfDiscrepancies.AmountIncludingVAT);
		ElsIf Not LineOfDiscrepancies.ToExpenseAs
			And LineOfDiscrepancies.PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.ToExpenseAs Then
			
			ToExpenseAs		= True;
			AmountForOtherExpenses	= AmountForOtherExpenses
										+ ?(LineOfDiscrepancies.AmountIncludingVAT < 0,
											-LineOfDiscrepancies.AmountIncludingVAT,
											LineOfDiscrepancies.AmountIncludingVAT);
		EndIf;
		
		If LineOfDiscrepancies.Sum > 0 Then
			PaymentDateIsRequired = True;
		EndIf;
	EndDo;
	
	Result = New Structure("RecordInOtherIncome, ToExpenseAs, PaymentDateIsRequired",
								RecordInOtherIncome, ToExpenseAs, PaymentDateIsRequired);
	
	Return Result;
	
EndFunction

Procedure CheckCompletionOfDebtAdjustmentTable(Cancel)
	
	If AdjustmentKind <> Enums.BusinessTransactions.AcquisitionAdjustmentDebtReductionConsolidated Then
		Return;
	EndIf;
	
	ErrorTemplate = NStr("vi = 'Tại dòng ""%1"" số tiền giảm lớn hơn số tiền mua hàng';
						|ru = 'В строке ""%1"" сумма уменьшения больше суммы приобретения';
						|en = 'In the ""%1"" line the decrease amount is greater than the purchase amount'; fa = 'In the ""%1"" line the decrease amount is greater than the purchase amount';
						|it = 'Nella riga ""%1"" l''importo di riduzione è maggiore dell''importo di acquisizione';
						|pl = 'W wierszu ""%1"" kwota zmniejszenia jest większa niż kwota nabycia';
						|tr = '""%1"" satırında azalma miktarı satın alım miktarından fazla'");
	DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
	For Each TableRow In ARAPAdjustment Do
		If TableRow.AdjustmentSum > TableRow.AmountIncludingVAT Then
			ErrorMessage = StrTemplate(ErrorTemplate, TableRow.LineNumber);
			Field = CommonClientServer.PathToTabularSection("ARAPAdjustment",
																	TableRow.LineNumber,
																	"AdjustmentSum");
			Common.MessageToUser(ErrorMessage, DataKey, Field, "Object", Cancel);
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckFullnessOfSettlementAmount(Cancel)
	
	If Currency = ARAPCurrency Then
		Return;
	EndIf;
	
	ErrorTemplate = NStr("vi = 'Trong dòng ""%1"" đã chỉ ra sai số tiền hạch toán công nợ ""sau"", bởi vì số tiền hạch toán công nợ ""trước"" bằng 0.';
						|ru = 'В строке ""%1"" неверно указана сумма взаиморасчетов ""после"", т.к. сумма взаиморасчетов ""до"" стала нулевой.';
						|en = 'In line %1, the ""after"" AR/AP amount is specified incorrectly as the ""before"" AR/AP amount is now zero.'; fa = 'In line %1, the ""after"" AR/AP amount is specified incorrectly as the ""before"" AR/AP amount is now zero.';
						|it = 'Nella stringa ""%1"" è indicato in modo non corretto l''importo dei conti reciproci ""dopo"", poiché l''importo dei conti reciproci ""fino a"" è zero.';
						|pl = 'W wierszu ""%1"" jest nieprawidłowo podana wartość rozliczeń wzajemnych ""po"", ponieważ wartość rozliczeń wzajemnych ""przed"" stała się zerową.';
						|tr = '""%1"" satırında ""sonra"" uzlaştırma tutarı yanlıştır çünkü ""önce"" uzlaştırma tutarı sıfır olmuştur.'");
	DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
	AdjustmentOfPurchaseOfOtherAssetServices = AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
	
	AttributesRow = Documents.PurchaseAdjustment.KeyAttributesOFRelationshipOfTableRows(AdjustmentOfPurchaseOfOtherAssetServices);
	ParamtraSelected = New Structure(AttributesRow);
	
	For Each TableRow In Goods Do
		
		FillPropertyValues(ParamtraSelected, TableRow);
		LinesOfDiscrepancy = Discrepancies.FindRows(ParamtraSelected);
		AmountOfMutualSettlementOfDiscrepancy = 0;
		CountDiscrepancies = 0;
		For Each DivergenceLine In LinesOfDiscrepancy Do
			AmountOfMutualSettlementOfDiscrepancy = AmountOfMutualSettlementOfDiscrepancy + DivergenceLine.AmountARAP;
			CountDiscrepancies = CountDiscrepancies + DivergenceLine.Count;
		EndDo;
		
		If TableRow.AmountARAP = AmountOfMutualSettlementOfDiscrepancy
			And TableRow.Count <> CountDiscrepancies Then
			
			ErrorMessage = StrTemplate(ErrorTemplate, TableRow.LineNumber);
			Field = CommonClientServer.PathToTabularSection("AdjustmentTable",
																	TableRow.LineNumber,
																	"AmountOfSettlementsAfter");
			Common.MessageToUser(ErrorMessage, DataKey, Field, "", Cancel);
			
		EndIf;
	EndDo;
	
EndProcedure

Function TemporaryDocumentDataTables(DocumentBusinessTransaction, Filter = Undefined)
	
	Query = New Query;
	QueryText =
	"SELECT
	|	&Date					AS Date,
	|	&Organization			AS Organization,
	|	&Partner				AS Partner,
	|	&Counterparty				AS Counterparty,
	|	&Terms				AS Terms,
	|	&AdjustmentKind		AS AdjustmentKind,
	|	&Contract				AS Contract,
	|	&Currency					AS Currency,
	|	&VATTaxation		AS VATTaxation,
	|	&BusinessOperation	AS BusinessOperation,
	|	&InventoryType				AS InventoryType,
	|	FALSE					AS ThereAreTransactionsInTablePart
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.DocumentInflow			AS DocumentInflow,
	|	CAST(TableOfGoods.Products AS Catalog.Products) AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	CAST(TableOfGoods.Purpose AS Catalog.Assignments) AS Purpose,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableOfGoods.PostingOption 			AS PostingOption,
	|	TableOfGoods.CCDNumber						AS CCDNumber,
	|	TableOfGoods.Warehouse						AS Warehouse,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END										AS QuantityByGBRN,
	|	TableOfGoods.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						AS VATAmount,
	|	TableOfGoods.ARAPObject				AS ARAPObject
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.DocumentInflow			AS DocumentInflow,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableOfGoods.PostingOption 			AS PostingOption,
	|	TableOfGoods.CCDNumber						AS CCDNumber,
	|	TableOfGoods.Warehouse						AS Warehouse,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.QuantityByGBRN				AS QuantityByGBRN,
	|	TableOfGoods.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						AS VATAmount,
	|	TableOfGoods.ARAPObject				AS ARAPObject
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|WHERE
	|	&TableOfProductsSelection
	|	AND (TableOfGoods.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|		OR (&IncludeTraceableWorks
	|			AND &UseTraceableImportedGoodsAccounting
	|			AND TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND TableOfGoods.Products.TracedGoods)
	|	)
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.DocumentInflow			AS DocumentInflow,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute			AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.PostingOption				AS PostingOption,
	|	TableTypesOfStocks_.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END											AS QuantityByGBRN,
	|	TableTypesOfStocks_.ARAPObject				AS ARAPObject,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|WHERE
	|	&TableTypesOfStocksSelection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.DocumentInflow			AS DocumentInflow,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic						AS Characteristic,
	|	Dimension.Series									AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)	AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.PostingOption				AS PostingOption,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	Dimension.StorageLocation							AS Warehouse,
	|	TableTypesOfStocks_.ARAPObject				AS ARAPObject,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|WHERE
	|	Dimension.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|	OR (&IncludeTraceableWorks
	|		AND &UseTraceableImportedGoodsAccounting
	|		AND Dimension.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND Dimension.Products.TracedGoods)
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Rows.ItemsLocationAttributes,
	|	Rows.InventoryOwnerAttribute
	|INTO TypesOfInventoryReceipts
	|FROM
	|	Document.VendorInvoice.Goods AS Rows
	|WHERE
	|	Rows.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.DocumentInflow							AS DocumentInflow,
	|	TableOfGoods.LineNumber									AS LineNumber,
	|	TableOfGoods.Products									AS Products,
	|	CASE
	|		WHEN TableOfGoods.PostingOption IN(VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncreaseWarehouseStock),
	|												VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncludeDuringPhysicalInventoryCount))
	|			THEN ISNULL(TypesOfInventoryReceipts.InventoryOwnerAttribute, VALUE(Catalog.InventoryKinds.EmptyRef))
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	CASE
	|		WHEN ProductDetails.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND &ToReturnReusablePackage
	|			THEN TRUE
	|		ELSE FALSE
	|	END														AS ThisIsReusablePackage,
	|	&Organization												AS Organization,
	|	&BusinessOperation										AS BusinessOperation,
	|	CASE
	|		WHEN TableOfGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		WHEN ProductDetails.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.InventoryTypes.OperationService)
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END														AS InventoryType,
	|	CASE
	|		WHEN TableOfGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN TableOfGoods.Purpose.Partner
	|		ELSE UNDEFINED
	|	END														AS GoodsOwner,
	|	TableOfGoods.PostingOption								AS PostingOption,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)	AS Terms,
	|	CASE
	|		WHEN TableOfGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN TableOfGoods.Purpose.Contract.Counterparty
	|		ELSE VALUE(Catalog.Counterparties.EmptyRef)
	|	END														AS Counterparty,
	|	CASE
	|		WHEN TableOfGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN TableOfGoods.Purpose.Contract
	|		ELSE VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|	END														AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef)					AS Currency,
	|	CASE
	|		WHEN &UseSeparateAccountingByTaxation
	|				AND NOT &BatchAccountingVersion22
	|			THEN &PurchaseForActivity
	|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END														AS VATTaxation,
	|	&TaxationOfOrganization									AS TaxationOfOrganization,
	|	VALUE(Catalog.VendorPriceTypes.EmptyRef)		AS PriceKind
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS ProductDetails
	|		ON ProductDetails.Ref = TableOfGoods.Products
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TableOfGoods.InventoryOwnerAttribute = InventoryKinds.Ref
	|		
	|		LEFT JOIN TypesOfInventoryReceipts AS TypesOfInventoryReceipts
	|		ON TypesOfInventoryReceipts.ItemsLocationAttributes = TableOfGoods.ItemsLocationAttributes
	|
	|WHERE
	|	(&RefillInventoryKinds
	|	OR TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|	OR ISNULL(InventoryKinds.InventoryType, VALUE(Enum.InventoryTypes.EmptyRef)) <> 
	|		CASE
	|			WHEN ProductDetails.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|					AND &ToReturnReusablePackage
	|				THEN VALUE(Enum.InventoryTypes.OwnGoods)
	|			ELSE &InventoryType
	|		END
	|	OR ISNULL(InventoryKinds.Organization, VALUE(Catalog.Companies.EmptyRef)) <> &Organization)
	|	AND NOT (&UseTraceableImportedGoodsAccounting
	|		AND TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND TableOfGoods.Products.TracedGoods)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.DocumentInflow							AS DocumentInflow,
	|	TableOfGoods.LineNumber									AS LineNumber,
	|	TableOfGoods.Products									AS Products,
	|	CASE
	|		WHEN TableOfGoods.PostingOption IN(VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncreaseWarehouseStock),
	|												VALUE(Enum.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseIncludeDuringPhysicalInventoryCount))
	|			THEN ISNULL(TypesOfInventoryReceipts.InventoryOwnerAttribute, VALUE(Catalog.InventoryKinds.EmptyRef))
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	CASE
	|		WHEN ProductDetails.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND &ToReturnReusablePackage
	|			THEN TRUE
	|		ELSE FALSE
	|	END														AS ThisIsReusablePackage,
	|	&Organization												AS Organization,
	|	&BusinessOperation										AS BusinessOperation,
	|	CASE
	|		WHEN TableOfGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		WHEN ProductDetails.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.InventoryTypes.OperationService)
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END														AS InventoryType,
	|	CASE
	|		WHEN TableOfGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN TableOfGoods.Purpose.Partner
	|		ELSE UNDEFINED
	|	END														AS GoodsOwner,
	|	TableOfGoods.PostingOption								AS PostingOption,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)	AS Terms,
	|	CASE
	|		WHEN TableOfGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN TableOfGoods.Purpose.Contract.Counterparty
	|		ELSE VALUE(Catalog.Counterparties.EmptyRef)
	|	END														AS Counterparty,
	|	CASE
	|		WHEN TableOfGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN TableOfGoods.Purpose.Contract
	|		ELSE VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|	END														AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef)					AS Currency,
	|	CASE
	|		WHEN &UseSeparateAccountingByTaxation
	|				AND NOT &BatchAccountingVersion22
	|			THEN &PurchaseForActivity
	|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END														AS VATTaxation,
	|	&TaxationOfOrganization									AS TaxationOfOrganization,
	|	VALUE(Catalog.VendorPriceTypes.EmptyRef)		AS PriceKind
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS ProductDetails
	|		ON ProductDetails.Ref = TableOfGoods.Products
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TableOfGoods.InventoryOwnerAttribute = InventoryKinds.Ref
	|		
	|		LEFT JOIN TypesOfInventoryReceipts AS TypesOfInventoryReceipts
	|		ON TypesOfInventoryReceipts.ItemsLocationAttributes = TableOfGoods.ItemsLocationAttributes
	|
	|WHERE
	|	(&RefillInventoryKinds
	|		OR TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|		OR ISNULL(InventoryKinds.InventoryType, VALUE(Enum.InventoryTypes.EmptyRef)) <> &InventoryType
	|		OR ISNULL(InventoryKinds.Organization, VALUE(Catalog.Companies.EmptyRef)) <> &Organization)
	|	AND &IncludeTraceableWorks
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND TableOfGoods.Products.TracedGoods
	|";
	
	SelectionTextTableOfProducts	= "TRUE";
	SelectionTextTypesOfStocks		= "TRUE";
	
	IncludeTraceableWorks = True;
	
	If ValueIsFilled(Filter) Then
		If Filter.Property("IncludeTraceableWorks") Then
			IncludeTraceableWorks = Filter.IncludeTraceableWorks;
			Filter.Delete("IncludeTraceableWorks");
		EndIf;
		
		For Each KeyValue In Filter Do
			SelectionTextTableOfProducts = SelectionTextTableOfProducts + " And " + "TableOfGoods." + KeyValue.Key
										+ " IN (&" + KeyValue.Key + ")";
			
			SelectionTextTypesOfStocks = SelectionTextTypesOfStocks + " And " + "TableTypesOfStocks_." + KeyValue.Key
										+ " IN (&" + KeyValue.Key + ")";
			
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	Query.SetParameter("IncludeTraceableWorks", IncludeTraceableWorks);
	
	QueryText = StrReplace(QueryText, "&TableOfProductsSelection",		SelectionTextTableOfProducts);
	QueryText = StrReplace(QueryText, "&TableTypesOfStocksSelection",	SelectionTextTypesOfStocks);
	
	TempTablesManager = New TempTablesManager;
	
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	
	DiscrepanciesWithReceiptDocuments = Discrepancies.Unload(, "LineNumber, Products, Characteristic, Purpose,
																|Series, ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber,
																|VATRate, Count, QuantityByGBRN, AmountIncludingVAT,
																|VATAmount, Warehouse, BatchesIndicationStatus, PostingOption,
																|ARAPObject");
	DiscrepanciesWithReceiptDocuments.Columns.Add("DocumentInflow",
														New TypeDescription("DocumentRef.VendorInvoice"));
	DiscrepanciesWithReceiptDocuments.FillValues(DocumentBasis, "DocumentInflow");
	
	TypesOfStocksWithReceiptDocuments = InventoryKinds.Unload(, "LineNumber, ItemsLocationAttributes, InventoryOwnerAttribute,
																|RecipientInventoryOwnerAttribute, CCDNumber, PostingOption,
																|Count, QuantityByGBRN, ARAPObject, AmountIncludingVAT");
	TypesOfStocksWithReceiptDocuments.Columns.Add("DocumentInflow",
														New TypeDescription("DocumentRef.VendorInvoice"));
	TypesOfStocksWithReceiptDocuments.FillValues(DocumentBasis, "DocumentInflow");
	
	AccountingParametersForOrganization	= VATAccountingERP.AccountingParametersForOrganization(Organization, Date);
	
	If TypeOf(DocumentBasis) <> Type("DocumentRef.SourceDocument") Then
		DetailsOfFoundation = Common.ObjectAttributesValues(DocumentBasis,
																	"PurchaseForActivity,ToReturnReusablePackage");
	EndIf;
	
	Query.SetParameter("Organization",			 Organization);
	Query.SetParameter("Date",					 Date);
	Query.SetParameter("Partner",				 Partner);
	Query.SetParameter("Counterparty",				 Counterparty);
	Query.SetParameter("Terms",				 Terms);
	Query.SetParameter("Contract",				 Contract);
	Query.SetParameter("Currency",					 Currency);
	Query.SetParameter("VATTaxation",		 VATTaxation);
	Query.SetParameter("BusinessOperation",	 DocumentBusinessTransaction);
	Query.SetParameter("InventoryType",				 TypeOfInventoryByBusinessTransaction(DocumentBusinessTransaction));
	Query.SetParameter("AdjustmentKind",		 AdjustmentKind);
	Query.SetParameter("Posted",				 Posted);
	Query.SetParameter("TableOfGoods",			 DiscrepanciesWithReceiptDocuments);
	Query.SetParameter("TableTypesOfStocks_",		 TypesOfStocksWithReceiptDocuments);
	Query.SetParameter("DocumentBasis",		 DocumentBasis);
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument") Then
		Query.SetParameter("ToReturnReusablePackage", False);
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.SubcontractorReport2_5") Then
		Query.SetParameter("ToReturnReusablePackage", False);
	Else
		Query.SetParameter("ToReturnReusablePackage", DetailsOfFoundation.ToReturnReusablePackage);
	EndIf;
	
	If TypeOf(DocumentBasis) <> Type("DocumentRef.SourceDocument") Then
		Query.SetParameter("PurchaseForActivity",
								DetailsOfFoundation.PurchaseForActivity);
	Else
		Query.SetParameter("PurchaseForActivity",
								False);
	EndIf;
	Query.SetParameter("TaxationOfOrganization",
								AccountingParametersForOrganization.BasicTaxationVATSales);
	
	Query.SetParameter("UseSeparateAccountingByTaxation",
								AccountingPoliciesTaxSettingsCached.SeparateAccountingOfGoodsByVATTaxation(Organization, Date));
	Query.SetParameter("BatchAccountingVersion22",
								CalculationOfCostCached.BatchAccountingVersion22(BegOfMonth(Date)));
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Function ParametersForFillingInventoryTypes(BySurplus, DocumentBusinessTransaction)
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = True;
	FillParameters.TableOfDetailsOfStockTypesByDefault = TableOfDetailsOfStockTypesByDefault(DocumentBusinessTransaction);
	FillParameters.NameOfRemainderTable = ?(BySurplus, "ProductsFromPartnersHavePositiveBalance", "PartnerProductsHaveNegativeBalance");
	FillParameters.WithoutSelectionByCCDNumbers = True;
	FillParameters.SelectionOfStockTypes_.InventoryType.Clear();
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(TypeOfInventoryByBusinessTransaction(DocumentBusinessTransaction));
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
	FillParameters.SelectionOfStockTypes_.Organization = Organization;
	FillParameters.SelectionOfStockTypes_.PriceKind = Catalogs.VendorPriceTypes.EmptyRef();
	
	Return FillParameters;
	
EndFunction

Function TableOfDetailsOfStockTypesByDefault(DocumentBusinessTransaction)
	
	TableOfDetailsOfStockTypesByDefault = Discrepancies.Unload(, "LineNumber, ItemsLocationAttributes, PostingOption"); // ValueTable
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"GoodsOwner", New TypeDescription("CatalogRef.Partners"));
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"Contract", New TypeDescription("CatalogRef.CounterpartyContracts"));
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"InventoryType", New TypeDescription("EnumRef.InventoryTypes"));
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"Organization", New TypeDescription("CatalogRef.Companies"));
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"InventoryOwnerAttribute", New TypeDescription("CatalogRef.InventoryKinds"));
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"CCDNumber", New TypeDescription("CatalogRef.CCDNumbers"));
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"Counterparty", New TypeDescription("CatalogRef.Counterparties"));
	
	TableOfDetailsOfStockTypesByDefault.FillValues(Partner, "GoodsOwner");
	TableOfDetailsOfStockTypesByDefault.FillValues(Contract, "Contract");
	TableOfDetailsOfStockTypesByDefault.FillValues(Organization, "Organization");
	TableOfDetailsOfStockTypesByDefault.FillValues(TypeOfInventoryByBusinessTransaction(DocumentBusinessTransaction), "InventoryType");
	TableOfDetailsOfStockTypesByDefault.FillValues(Counterparty, "Counterparty");
	
	Return TableOfDetailsOfStockTypesByDefault;
	
EndFunction

Function TypeOfInventoryByBusinessTransaction(DocumentBusinessTransaction)
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument") Then
		Return Enums.InventoryTypes.OwnGoods;
	EndIf;
	
	If DocumentBusinessTransaction = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit Or
		 DocumentBusinessTransaction = Enums.BusinessTransactions.ImportGoodsInTransit Or
		 DocumentBusinessTransaction = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit Then
		 Return Enums.InventoryTypes.OwnGoodsInTransit;
	ElsIf 
		 DocumentBusinessTransaction = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery Or
		 DocumentBusinessTransaction = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt Then
		 Return Enums.InventoryTypes.OwnGoodsOfUninvoicedDelivery;
	ElsIf 
		 DocumentBusinessTransaction = Enums.BusinessTransactions.ConsignmentProcurement Then
		 Return Enums.InventoryTypes.ConsignedGoods;
	Else
		 Return Enums.InventoryTypes.OwnGoods;
	EndIf;
	
EndFunction

Procedure FillInAdditionalStockTypes()
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	StructureOfCCDSearch = New Structure("ItemsLocationAttributes,CCDNumber");

	Dimensions = "ItemsLocationAttributes, RowID, CCDNumber,
				|PurchaseOrder, Price, VATRate,
				|SalesOpportunity, PostingOption, RowCode,
				|Department, ToExpenseAs, ExpenseItem,
				|DimensionOfExpenses, AssetsLiabilitiesDimension, DimensionOfRevenue, ARAPObject";
	Resources = "Count, QuantityByGBRN, AmountARAP, AmountVATARAP, AmountIncludingVAT, VATAmount";
	
	ResourcesStructure = New Structure(Resources);
	ArrayOfResources = StrSplit(Resources, ", ", False);
	
	RowFilter = New Structure("Count", 0);
	DiscrepanciesOnlyInAmounts = Discrepancies.Unload(RowFilter);
	TypesOfStocksDifferencesOnlyInAmounts = InventoryKinds.UnloadColumns();
	
	For Each RowTypesOfStocksDifferencesInAmountsOnly In InventoryKinds.FindRows(RowFilter) Do
		FillPropertyValues(TheStructureOfTheSearch, RowTypesOfStocksDifferencesInAmountsOnly);
		
		For Each RowOfDiscrepanciesOnlyByAmounts In DiscrepanciesOnlyInAmounts.FindRows(TheStructureOfTheSearch) Do
			NewRow = TypesOfStocksDifferencesOnlyInAmounts.Add();
			FillPropertyValues(NewRow, RowTypesOfStocksDifferencesInAmountsOnly);
			FillPropertyValues(NewRow, RowOfDiscrepanciesOnlyByAmounts, Dimensions + ", " + Resources);
		EndDo;
	EndDo;
	
	GoodsTable = Discrepancies.Unload(, Dimensions + ", " + Resources);
	GoodsTable.GroupBy(Dimensions, Resources); 
	
	SearchStringArray = New Array;
	FoundRows = New Array;
	
	For Each RowOfGoods In GoodsTable Do
		
		FillPropertyValues(ResourcesStructure, RowOfGoods);
		SearchStringArray.Clear();
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		If ValueIsFilled(RowOfGoods.CCDNumber) Then
			FillPropertyValues(StructureOfCCDSearch, RowOfGoods);
			SearchStringArray.Add(StructureOfCCDSearch);
		EndIf;

		SearchStringArray.Add(TheStructureOfTheSearch);
		
		For Each SearchString In SearchStringArray Do
			
			FoundRows = InventoryKinds.FindRows(SearchString);			
			
			For Each InventoryLine In FoundRows Do
				
				If InventoryLine.Count = 0 Then
					Continue;
				EndIf;
				
				If (ResourcesStructure.Count > 0
					And InventoryLine.Count < 0)
					Or (ResourcesStructure.Count < 0
					And InventoryLine.Count > 0) Then
					Continue;
				EndIf;
					
				ModuleNumberOfResources = ?(ResourcesStructure.Count > 0, ResourcesStructure.Count, -ResourcesStructure.Count);
				InventoryQuantityModule = ?(InventoryLine.Count > 0, InventoryLine.Count, -InventoryLine.Count);
				If ModuleNumberOfResources < InventoryQuantityModule Then
					QuantityPerRow = ResourcesStructure.Count;
				Else
					QuantityPerRow = InventoryLine.Count;
				EndIf;
				
				NewRow = InventoryKinds.Add();
				FillPropertyValues(NewRow, InventoryLine);
				FillPropertyValues(NewRow, RowOfGoods, Dimensions);
				
				NewRow.Count			= QuantityPerRow;
				NewRow.QuantityByGBRN	= QuantityPerRow * InventoryLine.QuantityByGBRN
													/ InventoryLine.Count;
				
				If ResourcesStructure.Count Then
					For Each ResourceElement In ArrayOfResources Do
						NewRow[ResourceElement] = QuantityPerRow * ResourcesStructure[ResourceElement]
														/ ResourcesStructure.Count;
					EndDo;
				EndIf;
				
				InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
				InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
				
				For Each ResourceElement In ArrayOfResources Do
					ResourcesStructure[ResourceElement] = ResourcesStructure[ResourceElement] - NewRow[ResourceElement];
				EndDo;
				
				If ResourcesStructure.Count = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
			If ResourcesStructure.Count = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
	For Each RowTypesOfStocksDifferencesInAmountsOnly In TypesOfStocksDifferencesOnlyInAmounts Do
		FillPropertyValues(InventoryKinds.Add(), RowTypesOfStocksDifferencesInAmountsOnly);
	EndDo;
	
EndProcedure

Procedure AllocateInventoryForDiscrepancies(DocumentDiscrepancies_, DocumentBusinessTransaction)
	
	DocumentDiscrepancies_.Columns.Add("QuantityForDistribution", New TypeDescription("Number"));
	
	DiscrepanciesTypesOfStocks = Discrepancies.Unload();
	DiscrepanciesTypesOfStocks.Columns.Count.Name = "QuantityForDistribution";
	
	DistributeCCD = DocumentBusinessTransaction = Enums.BusinessTransactions.ImportFromEAEU
						And AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date);
	
	ProductTraceability = Undefined;
	
	If DistributeCCD Then
		GoodsOfDiscrepancies		= DiscrepanciesTypesOfStocks.UnloadColumn("Products");
		ProductTraceability	= Common.ObjectsAttributeValue(GoodsOfDiscrepancies, "TracedGoods");
	EndIf;
	
	KeyWithCCD	= "Products, Characteristic, Purpose, Series, CCDNumber";
	KeyWithoutCCD	= "Products, Characteristic, Purpose, Series";
	
	FilterWithCCD	= New Structure(KeyWithCCD);
	FilterWithoutCCD	= New Structure(KeyWithoutCCD);
	
	For Each InventoryLine In DiscrepanciesTypesOfStocks Do
		// For lines of discrepancies in the purchase increase, inventory types are filled in by default.
		If InventoryLine.QuantityForDistribution > 0 Then
			Continue;
		EndIf;
		
		TracedGoods = ?(ProductTraceability <> Undefined,
								ProductTraceability.Get(InventoryLine.Products),
								False);
		
		Filter = ?(TracedGoods, FilterWithoutCCD, FilterWithCCD);
		FillPropertyValues(Filter, InventoryLine);
		
		FoundRows = DocumentDiscrepancies_.FindRows(Filter);
		
		For Each LineProducts_ In FoundRows Do
			If InventoryLine.QuantityForDistribution = 0 Then
				Break;
			EndIf;
			
			Count	= InventoryLine.QuantityForDistribution;
			Excess	= LineProducts_.QuantityForDistribution + Count - LineProducts_.Count;
			
			If Excess <> 0 Then
				If Excess <= Count Then
					Continue;
				Else
					Count = Count - Excess;
				EndIf;
			EndIf;
			
			If Count = 0 Then
				Continue;
			EndIf;
			
			FieldsToFillInAreEqual = InventoryLine.InventoryOwnerAttribute = LineProducts_.InventoryOwnerAttribute;
			
			If TracedGoods
				And FieldsToFillInAreEqual Then
				
				FieldsToFillInAreEqual = InventoryLine.CCDNumber = LineProducts_.CCDNumber;
				
			EndIf;
			
			If Not FieldsToFillInAreEqual
				And LineProducts_.QuantityForDistribution = 0 Then
				
				LineProducts_.InventoryOwnerAttribute = InventoryLine.InventoryOwnerAttribute;
				
				If TracedGoods Then
					LineProducts_.CCDNumber = InventoryLine.CCDNumber;
				EndIf;
				
				LineProducts_.QuantityForDistribution		= LineProducts_.QuantityForDistribution + Count;
				InventoryLine.QuantityForDistribution	= InventoryLine.QuantityForDistribution - Count;
				
			ElsIf FieldsToFillInAreEqual Then
				LineProducts_.QuantityForDistribution		= LineProducts_.QuantityForDistribution + Count;
				InventoryLine.QuantityForDistribution	= InventoryLine.QuantityForDistribution - Count;
			EndIf;
		EndDo;
		
		If FoundRows.Count() > 0
			And InventoryLine.QuantityForDistribution < 0 Then
			
			LineProducts_ = FoundRows[FoundRows.UBound()];
			LineProducts_.QuantityForDistribution = LineProducts_.QuantityForDistribution
														+ InventoryLine.QuantityForDistribution;
			
			LineProducts_.InventoryOwnerAttribute = InventoryLine.InventoryOwnerAttribute;
			
			If TracedGoods Then
				LineProducts_.CCDNumber = InventoryLine.CCDNumber;
			EndIf;
			
			InventoryLine.QuantityForDistribution = 0;
		EndIf;
	EndDo;
	
	Discrepancies.Load(DocumentDiscrepancies_);
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Date, Organization, AdjustmentKind, Partner, Counterparty, Terms";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.PostingOption AS PostingOption,
	|		TableOfGoods.ARAPObject AS ARAPObject,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT
	|
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes,
	|		TableTypesOfStocks_.PostingOption AS PostingOption,
	|		TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|		-TableTypesOfStocks_.Count,
	|		-TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|		-TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.PostingOption,
	|	TableOfGoods.ARAPObject
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.QuantityByGBRN) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0";
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure CheckFillingOfRowColumn(ColumnName, ValueOfDocumentDetails, MatchingProductsType, CurrentRow, Cancel)
	
	Var ErrorText;
	
	If Not ValueIsFilled(CurrentRow[ColumnName]) Then
		
		ErrorText = StrTemplate(NStr("vi = 'Cột ""%1"" trong hàng %2 của danh sách ""Sản phẩm"" không được điền';
									|ru = 'Не заполнена колонка ""%1"" в строке %2 списка ""Товары""';
									|en = 'Column ""%1"" in line %2 of the ""Goods"" list is not filled in'; fa = 'Column ""%1"" in line %2 of the ""Goods"" list is not filled in';
									|it = 'Colonna ""%1"" nella riga %2 dell''elenco ""Merci"" non è compilata';
									|pl = 'Nie wypełniono kolumny ""%1"" w wierszu %2 listy ""Wiersze pozycji""';
									|tr = '""Ürünler"" listesinin %2 satırındaki ""%1"" sütunu eksik'"), ColumnName, CurrentRow.LineNumber);
		
		If Not MatchingProductsType.Get(CurrentRow.Products) = Enums.ItemsTypes.ReusablePackage 
			Or MatchingProductsType.Get(CurrentRow.Products) = Enums.ItemsTypes.ReusablePackage 
			And (Not ValueOfDocumentDetails.ToReturnReusablePackage Or ValueOfDocumentDetails.PackageDepositIsRequired) Then
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, ColumnName),
				,
				Cancel);
			
		EndIf;
	EndIf;

EndProcedure

Procedure CheckChainOfCorrectionsBeforeRecording(Cancel, WriteMode)
	
	If Cancel Then
		Return
	EndIf;
	
	// The document being corrected has been completed and has not been completed or canceled
	If WriteMode = DocumentWriteMode.Posting And ValueIsFilled(CorrectedDocument)
		And AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection
		And (Not Common.ObjectAttributeValue(CorrectedDocument, "Posted")
			Or DocumentCorrection.IsThereFixOrReverse(CorrectedDocument)) Then
		
		ErrorText = NStr("vi = 'Chưa kết chuyển hoặc đảo ngược chứng từ được chỉnh sửa.
				|Không thể kết chuyển chứng từ.';
				|ru = 'Исправляемый документ не проведен или сторнирован.
				|Проведение документа невозможно.';
				|en = 'The document to correct is not posted or reversed.
				|Cannot post the document.'; fa = 'The document to correct is not posted or reversed.
				|Cannot post the document.';
				|it = 'Исправляемый документ не проведен или сторнирован.
				|Проведение документа невозможно.';
				|pl = 'The document to correct is not posted or reversed.
				|Cannot post the document.';
				|tr = 'Düzeltme belgesi kaydedilmedi veya  iptal edildi.
				|Belgenin kaydedilmesi mümkün değildir.'");
		Common.MessageToUser(ErrorText,,,, Cancel);
		
	EndIf;
	
	// Define the verification parameters
	Attributes = Documents.PurchaseAdjustment.ParametersForGettingDocumentBeingCorrected();
	FillPropertyValues(Attributes, ThisObject);
	CheckParameters = InformationRegisters.DocumentCorrections.DocumentCorrectionVerificationParameters();
	FillPropertyValues(CheckParameters, ThisObject,, "CorrectedDocument");
	CheckParameters.CorrectedDocument = Documents.PurchaseAdjustment.CorrectedDocument(Attributes);
	
	// Checking for changes in the date or the document being corrected when re-checking
	ChangesDuringFollowUp = False;
	If WriteMode = DocumentWriteMode.Posting And Posted 
		And AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection Then
		ChangesDuringFollowUp = DocumentCorrection.ParametersForCorrectingDocumentsHaveChanged(CheckParameters);
	EndIf;
	
	// Checking for the existence of documents in the chain with a longer date
	If ChangesDuringFollowUp Or WriteMode = DocumentWriteMode.UndoPosting
		Or (WriteMode = DocumentWriteMode.Posting And Not Posted) Then
		
		If AdjustmentKind = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties Then
			CheckParameters.CorrectedDocument = Ref;
		EndIf;
		
		Patch = DocumentCorrection.CorrectionAfterDocumentDate(CheckParameters);
		
		If ValueIsFilled(Patch) Then
			ErrorText = NStr("vi = 'Nếu chỉnh sửa muộn hơn ngày của chứng từ hiện tại.
				|Đã cấm thay đổi chứng từ.';
				|ru = 'Есть исправление позднее даты текущего документа.
				|Изменение документа запрещено.';
				|en = 'There is a correction later than the current document date.
				|Cannot edit the document.'; fa = 'There is a correction later than the current document date.
				|Cannot edit the document.';
				|it = 'Есть исправление позднее даты текущего документа.
				|Изменение документа запрещено.';
				|pl = 'There is a correction later than the current document date.
				|Cannot edit the document.';
				|tr = 'Mevcut belgenin tarihinden daha sonra düzeltme mevcut.
				|Belgenin değiştirilmesi yasaktır.'");
			Common.MessageToUser(ErrorText,,,, Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// Filling in discrepancies

Function VariantOfReflectionByLine(LineOfDiscrepancies, ItemsType, LastPeriodAdjustment, UninvoicedReceiptDocumentIsUsed)
	
	PostingOption = Undefined;
	
	If Not UninvoicedReceiptDocumentIsUsed  
		And ((ItemsType <> Enums.ItemsTypes.OwnGoods
		And ItemsType <> Enums.ItemsTypes.ReusablePackage)
		Or LineOfDiscrepancies.NumberOfPackages = 0) Then
		
		If LineOfDiscrepancies.AmountIncludingVAT < 0
			Or (LineOfDiscrepancies.AmountIncludingVAT = 0 And LineOfDiscrepancies.VATAmount < 0)
			Or (LineOfDiscrepancies.AmountIncludingVAT = 0 And LineOfDiscrepancies.VATAmount = 0
				And LineOfDiscrepancies.NumberOfPackages < 0) Then
			PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.ReduceCost;
		Else
			PostingOption = Enums.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost;
		EndIf;
	ElsIf UninvoicedReceiptDocumentIsUsed Then
		If LineOfDiscrepancies.Count <> 0 Then
			If ItemsType = Enums.ItemsTypes.OperationService
				Or ItemsType = Enums.ItemsTypes.Work_5 Then
				PostingOption = ?(LineOfDiscrepancies.Count < 0,
					Enums.OptionsOfPostingReceiptAdjustingEntries.ReduceCost,
					Enums.OptionsOfPostingReceiptAdjustingEntries.IncreaseCost);
			Else
				PostingOption = ?(LineOfDiscrepancies.Count < 0,
					Enums.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners,
					Enums.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners);
			EndIf;
		ElsIf LineOfDiscrepancies.AmountIncludingVAT <> 0 Then
			PostingOption = ?(LineOfDiscrepancies.AmountIncludingVAT < 0,
				Enums.OptionsOfPostingReceiptAdjustingEntries.ReducePurchaseFromPartners,
				Enums.OptionsOfPostingReceiptAdjustingEntries.IncreasePurchaseFromPartners);
		EndIf;
	EndIf;
	
	Return PostingOption;
	
EndFunction

Procedure FillInTheDiscrepancies(UninvoicedReceiptDocumentIsUsed) Export
	
	// In the future, the date of the founding document will be required. The details must be filled in.
	If Not ValueIsFilled(DocumentBasis) Then
		Raise NStr("vi = 'Chưa điền trường ""Chứng từ-cơ sở""';
					|ru = 'Поле ""Документ-основание"" не заполнено';
					|en = '""Base document"" is required'; fa = '""Base document"" is required';
					|it = 'Поле ""Документ-основание"" не заполнено';
					|pl = '""Base document"" is required';
					|tr = '""Temel belge"" alanı doldurulmamış'");
	EndIf;
	
	Discrepancies.Clear();
	
	KeyFields = "
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Content,
	|	Package,
	|	PurchaseOrder,
	|	Warehouse,
	|	SalesOpportunity,
	|	Department,
	|	CostGroupNumber,
	|	ProductCostElement,
	|	ProductionStage,
	|	ToExpenseAs,
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	AssetsLiabilitiesDimension,
	|	DimensionOfRevenue,
	|	LineOfBusiness,
	|	HashAmountAccountSettings,
	|	CCDNumber,
	|	VATRate,
	|	FEACNCode,
	|	RowCode";
	
	TempTablesManager = New TempTablesManager;
	
	Documents.PurchaseAdjustment.CreateTemporaryTableOfSourceData(
		TempTablesManager, DocumentBasis, Ref);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = "
	|SELECT
	|	NewData.Products AS Products,
	|	NewData.Characteristic AS Characteristic,
	|	NewData.Purpose AS Purpose,
	|	NewData.Series AS Series,
	|	NewData.Content AS Content,
	|	NewData.Package AS Package,
	|	NewData.PurchaseOrder AS PurchaseOrder,
	|	NewData.Warehouse AS Warehouse,
	|	NewData.SalesOpportunity AS SalesOpportunity,
	|	NewData.Department AS Department,
	|	NewData.CostGroupNumber AS CostGroupNumber,
	|	NewData.ProductCostElement AS ProductCostElement,
	|	NewData.ProductionStage AS ProductionStage,
	|	NewData.ToExpenseAs AS ToExpenseAs,
	|	NewData.ExpenseItem AS ExpenseItem,
	|	NewData.DimensionOfExpenses AS DimensionOfExpenses,
	|	NewData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	NewData.DimensionOfRevenue AS DimensionOfRevenue,
	|	NewData.LineOfBusiness AS LineOfBusiness,
	|	NewData.GLAccountSettings AS GLAccountSettings,
	|	NewData.CCDNumber AS CCDNumber,
	|	NewData.FEACNCode AS FEACNCode,
	|	NewData.VATRate AS VATRate,
	|	CASE
	|		WHEN NewData.NumberOfPackages <> 0
	|			THEN NewData.NumberOfPackages
	|		WHEN NewData.Count = 0
	|			THEN 1
	|		ELSE NewData.Count
	|	END AS NumberOfPackages,
	|	CASE
	|		WHEN NewData.Count = 0
	|			THEN 1
	|		ELSE NewData.Count
	|	END AS Count,
	|	NewData.QuantityByGBRN AS QuantityByGBRN,
	|	NewData.Sum AS Sum,
	|	NewData.VATAmount AS VATAmount,
	|	NewData.AmountIncludingVAT AS AmountIncludingVAT,
	|	NewData.RowCode AS RowCode,
	|	NewData.LineNumber AS LineNumber
	|INTO NewDataFromTable
	|FROM
	|	&NewData AS NewData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewDataFromTable.Products,
	|	NewDataFromTable.Characteristic,
	|	NewDataFromTable.Purpose,
	|	NewDataFromTable.Series,
	|	NewDataFromTable.Content,
	|	CASE
	|		WHEN NewDataFromTable.Package = NewDataFromTable.Products.UnitOfMeasure
	|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		ELSE NewDataFromTable.Package
	|	END AS Package,
	|	NewDataFromTable.PurchaseOrder,
	|	NewDataFromTable.Warehouse,
	|	NewDataFromTable.SalesOpportunity,
	|	NewDataFromTable.Department AS Department,
	|	NewDataFromTable.CostGroupNumber AS CostGroupNumber,
	|	NewDataFromTable.ProductCostElement AS ProductCostElement,
	|	NewDataFromTable.ProductionStage AS ProductionStage,
	|	NewDataFromTable.ToExpenseAs AS ToExpenseAs,
	|	NewDataFromTable.ExpenseItem,
	|	NewDataFromTable.DimensionOfExpenses,
	|	NewDataFromTable.AssetsLiabilitiesDimension,
	|	NewDataFromTable.DimensionOfRevenue,
	|	NewDataFromTable.LineOfBusiness,
	|	MAX(NewDataFromTable.GLAccountSettings) AS GLAccountSettings,
	|	ISNULL(NewDataFromTable.GLAccountSettings.HashSum, """") AS HashAmountAccountSettings,
	|	NewDataFromTable.CCDNumber,
	|	NewDataFromTable.FEACNCode,
	|	NewDataFromTable.VATRate,
	|	SUM(NewDataFromTable.NumberOfPackages) AS NumberOfPackages,
	|	SUM(NewDataFromTable.Count) AS Count,
	|	SUM(NewDataFromTable.QuantityByGBRN) AS QuantityByGBRN,
	|	SUM(NewDataFromTable.Sum) AS Sum,
	|	SUM(NewDataFromTable.VATAmount) AS VATAmount,
	|	SUM(NewDataFromTable.AmountIncludingVAT) AS AmountIncludingVAT,
	|	NewDataFromTable.RowCode AS RowCode,
	|	MIN(NewDataFromTable.LineNumber) AS LineNumber
	|INTO NewData
	|FROM
	|	NewDataFromTable AS NewDataFromTable
	|
	|GROUP BY
	|	NewDataFromTable.Products,
	|	NewDataFromTable.Characteristic,
	|	NewDataFromTable.Purpose,
	|	NewDataFromTable.Series,
	|	NewDataFromTable.Content,
	|	CASE
	|		WHEN NewDataFromTable.Package = NewDataFromTable.Products.UnitOfMeasure
	|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		ELSE NewDataFromTable.Package
	|	END,
	|	NewDataFromTable.PurchaseOrder,
	|	NewDataFromTable.Warehouse,
	|	NewDataFromTable.SalesOpportunity,
	|	NewDataFromTable.Department,
	|	NewDataFromTable.CostGroupNumber,
	|	NewDataFromTable.ProductCostElement,
	|	NewDataFromTable.ProductionStage,
	|	NewDataFromTable.ToExpenseAs,
	|	NewDataFromTable.ExpenseItem,
	|	NewDataFromTable.DimensionOfExpenses,
	|	NewDataFromTable.AssetsLiabilitiesDimension,
	|	NewDataFromTable.DimensionOfRevenue,
	|	NewDataFromTable.LineOfBusiness,
	|	ISNULL(NewDataFromTable.GLAccountSettings.HashSum, """"),
	|	NewDataFromTable.CCDNumber,
	|	NewDataFromTable.FEACNCode,
	|	NewDataFromTable.VATRate,
	|	NewDataFromTable.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST(RawData.Products AS Catalog.Products) AS Products,
	|	CAST(RawData.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(RawData.Purpose AS Catalog.Assignments) AS Purpose,
	|	CAST(RawData.Series AS Catalog.ItemsBatches) AS Series,
	|	
	|	CASE WHEN RawData.Content <> UNDEFINED THEN
	|		RawData.Content
	|	ELSE
	|		""""
	|	END AS Content,
	|	
	|	CAST(RawData.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	CASE
	|		WHEN RawData.PurchaseOrder REFS Document.PurchaseOrder
	|			THEN CAST(RawData.PurchaseOrder AS Document.PurchaseOrder)
	|		WHEN RawData.PurchaseOrder REFS Document.SubcontractOrder2_5
	|			THEN CAST(RawData.PurchaseOrder AS Document.SubcontractOrder2_5)
	|		ELSE UNDEFINED
	|	END AS PurchaseOrder,
	|	
	|	CAST(RawData.Warehouse AS Catalog.Warehouses) AS Warehouse,
	|	CAST(RawData.SalesOpportunity AS Catalog.SalesOpportunitiesToCustomer) AS SalesOpportunity,
	|	CAST(RawData.Department AS Catalog.BusinessStructure) AS Department,
	|	CAST(RawData.CostGroupNumber AS NUMBER(10,0)) AS CostGroupNumber,
	|	CAST(RawData.ProductCostElement AS Catalog.ProductCostElements) AS ProductCostElement,
	|	CAST(RawData.ProductionStage AS Document.ProductionStage2_2) AS ProductionStage,
	|	CAST(RawData.ToExpenseAs AS BOOLEAN) AS ToExpenseAs,
	|	RawData.ExpenseItem AS ExpenseItem,
	|	RawData.DimensionOfExpenses AS DimensionOfExpenses,
	|	RawData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	RawData.DimensionOfRevenue AS DimensionOfRevenue,
	|	CAST(RawData.LineOfBusiness AS Catalog.LinesOfBusiness) AS LineOfBusiness,
	|	MAX(RawData.GLAccountSettings) AS GLAccountSettings,
	|	ISNULL(RawData.GLAccountSettings.HashSum, """") AS HashAmountAccountSettings,
	|	CAST(RawData.CCDNumber AS Catalog.CCDNumbers) AS CCDNumber,
	|	CAST(RawData.FEACNCode AS Catalog.FEACN) AS FEACNCode,
	|	CAST(RawData.VATRate AS Catalog.VATRates) AS VATRate,
	|	SUM(CASE WHEN RawData.NumberOfPackages <> UNDEFINED THEN
	|		CASE WHEN RawData.NumberOfPackages = 0 THEN
	|			1
	|		ELSE
	|			CAST(RawData.NumberOfPackages AS NUMBER(15, 3))
	|		END
	|	ELSE
	|		0
	|	END) AS NumberOfPackages,
	|	SUM(CASE WHEN RawData.Count <> UNDEFINED THEN
	|		CASE WHEN RawData.Count = 0 THEN
	|			1
	|		ELSE
	|			CAST(RawData.Count AS NUMBER(15, 3))
	|		END
	|	ELSE
	|		0
	|	END) AS Count,
	|	SUM(CASE
	|			WHEN RawData.QuantityByGBRN <> UNDEFINED
	|				THEN CAST(RawData.QuantityByGBRN AS NUMBER(15, 11))
	|			ELSE 0
	|		END) AS QuantityByGBRN,
	|	SUM(CASE WHEN RawData.Sum <> UNDEFINED THEN
	|		CAST(RawData.Sum AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END) AS Sum,
	|	
	|	SUM(CASE WHEN RawData.VATAmount <> UNDEFINED THEN
	|		CAST(RawData.VATAmount AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END) AS VATAmount,
	|	
	|	SUM(CASE WHEN RawData.AmountIncludingVAT <> UNDEFINED THEN
	|		CAST(RawData.AmountIncludingVAT AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END) AS AmountIncludingVAT,
	|	RawData.RowCode,
	|	MIN(RawData.LineNumber)	
	|
	|INTO RawDataForDiscrepancies
	|FROM
	|	RawData AS RawData
	|
	|GROUP BY
	|	RawData.Characteristic,
	|	RawData.Purpose,
	|	RawData.Series,
	|	RawData.Content,
	|	RawData.Package,
	|	RawData.PurchaseOrder,
	|	RawData.Warehouse,
	|	RawData.Products,
	|	RawData.SalesOpportunity,
	|	RawData.Department,
	|	RawData.CostGroupNumber,
	|	RawData.ProductCostElement,
	|	RawData.ProductionStage,
	|	RawData.ToExpenseAs,
	|	RawData.ExpenseItem,
	|	RawData.DimensionOfExpenses,
	|	RawData.AssetsLiabilitiesDimension,
	|	RawData.DimensionOfRevenue,
	|	RawData.LineOfBusiness,
	|	ISNULL(RawData.GLAccountSettings.HashSum, """"),
	|	RawData.CCDNumber,
	|	RawData.FEACNCode,
	|	RawData.VATRate,
	|	RawData.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RawData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewData.Products AS Products,
	|	NewData.Characteristic AS Characteristic,
	|	NewData.Purpose AS Purpose,
	|	NewData.Series AS Series,
	|	NewData.Content AS Content,
	|	NewData.Package AS Package,
	|	NewData.PurchaseOrder AS PurchaseOrder,
	|	NewData.Warehouse AS Warehouse,
	|	NewData.SalesOpportunity AS SalesOpportunity,
	|	NewData.Department AS Department,
	|	NewData.CostGroupNumber AS CostGroupNumber,
	|	NewData.ProductCostElement AS ProductCostElement,
	|	NewData.ProductionStage AS ProductionStage,
	|	NewData.ToExpenseAs AS ToExpenseAs,
	|	NewData.ExpenseItem AS ExpenseItem,
	|	NewData.DimensionOfExpenses AS DimensionOfExpenses,
	|	NewData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	NewData.DimensionOfRevenue AS DimensionOfRevenue,
	|	NewData.LineOfBusiness AS LineOfBusiness,
	|	NewData.HashAmountAccountSettings AS HashAmountAccountSettings,
	|	NewData.CCDNumber AS CCDNumber,
	|	NewData.FEACNCode AS FEACNCode,
	|	NewData.VATRate AS VATRate,
	|	NewData.Sum AS Sum,
	|	NewData.VATAmount AS VATAmount,
	|	NewData.AmountIncludingVAT AS AmountIncludingVAT,
	|	NewData.RowCode AS RowCode,
	|	NewData.LineNumber AS LineNumber
	|INTO DiscrepancyData
	|FROM
	|	NewData AS NewData
	|		INNER JOIN RawDataForDiscrepancies AS RawData
	|		ON NewData.Products = RawData.Products
	|			AND NewData.Characteristic = RawData.Characteristic
	|			AND NewData.Purpose = RawData.Purpose
	|			AND NewData.Series = RawData.Series
	|			AND NewData.Content = RawData.Content
	|			AND NewData.Package = RawData.Package
	|			AND NewData.PurchaseOrder = RawData.PurchaseOrder
	|			AND NewData.Warehouse = RawData.Warehouse
	|			AND NewData.SalesOpportunity = RawData.SalesOpportunity
	|			AND NewData.Department = RawData.Department
	|			AND NewData.CostGroupNumber = RawData.CostGroupNumber
	|			AND NewData.ProductCostElement = RawData.ProductCostElement
	|			AND NewData.ProductionStage = RawData.ProductionStage
	|			AND NewData.ToExpenseAs = RawData.ToExpenseAs
	|			AND NewData.ExpenseItem = RawData.ExpenseItem
	|			AND NewData.DimensionOfExpenses = RawData.DimensionOfExpenses
	|			AND NewData.AssetsLiabilitiesDimension = RawData.AssetsLiabilitiesDimension
	|			AND NewData.DimensionOfRevenue = RawData.DimensionOfRevenue
	|			AND NewData.LineOfBusiness = RawData.LineOfBusiness
	|			AND NewData.HashAmountAccountSettings = RawData.HashAmountAccountSettings
	|			AND NewData.CCDNumber = RawData.CCDNumber
	|			AND NewData.FEACNCode = RawData.FEACNCode
	|			AND NewData.VATRate = RawData.VATRate
	|			AND NewData.RowCode = RawData.RowCode
	|
	|UNION ALL
	|
	|SELECT
	|	RawData.Products,
	|	RawData.Characteristic,
	|	RawData.Purpose,
	|	RawData.Series,
	|	RawData.Content,
	|	RawData.Package,
	|	RawData.PurchaseOrder,
	|	RawData.Warehouse,
	|	RawData.SalesOpportunity,
	|	RawData.Department,
	|	RawData.CostGroupNumber,
	|	RawData.ProductCostElement AS ProductCostElement,
	|	RawData.ProductionStage,
	|	RawData.ToExpenseAs,
	|	RawData.ExpenseItem,
	|	RawData.DimensionOfExpenses,
	|	RawData.AssetsLiabilitiesDimension,
	|	RawData.DimensionOfRevenue,
	|	RawData.LineOfBusiness,
	|	RawData.HashAmountAccountSettings,
	|	RawData.CCDNumber,
	|	RawData.FEACNCode,
	|	RawData.VATRate,
	|	-RawData.Sum,
	|	-RawData.VATAmount,
	|	-RawData.AmountIncludingVAT,
	|	RawData.RowCode,
	|	RawData.LineNumber
	|FROM
	|	RawDataForDiscrepancies AS RawData
	|		INNER JOIN NewData AS NewData
	|		ON RawData.Products = NewData.Products
	|			AND RawData.Characteristic = NewData.Characteristic
	|			AND RawData.Purpose = NewData.Purpose
	|			AND RawData.Series = NewData.Series
	|			AND RawData.Content = NewData.Content
	|			AND RawData.Package = NewData.Package
	|			AND RawData.PurchaseOrder = NewData.PurchaseOrder
	|			AND RawData.Warehouse = NewData.Warehouse
	|			AND RawData.SalesOpportunity = NewData.SalesOpportunity
	|			AND RawData.Department = NewData.Department
	|			AND RawData.CostGroupNumber = NewData.CostGroupNumber
	|			AND RawData.ProductCostElement = NewData.ProductCostElement
	|			AND RawData.ProductionStage = NewData.ProductionStage
	|			AND RawData.ToExpenseAs = NewData.ToExpenseAs
	|			AND RawData.ExpenseItem = NewData.ExpenseItem
	|			AND RawData.DimensionOfExpenses = NewData.DimensionOfExpenses
	|			AND RawData.AssetsLiabilitiesDimension = NewData.AssetsLiabilitiesDimension
	|			AND RawData.DimensionOfRevenue = NewData.DimensionOfRevenue
	|			AND RawData.LineOfBusiness = NewData.LineOfBusiness
	|			AND RawData.HashAmountAccountSettings = NewData.HashAmountAccountSettings
	|			AND RawData.CCDNumber = NewData.CCDNumber
	|			AND RawData.FEACNCode = NewData.FEACNCode
	|			AND RawData.VATRate = NewData.VATRate
	|			AND RawData.RowCode = NewData.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyData.Products,
	|	DiscrepancyData.Characteristic,
	|	DiscrepancyData.Purpose,
	|	DiscrepancyData.Series,
	|	DiscrepancyData.Content,
	|	DiscrepancyData.Package,
	|	DiscrepancyData.PurchaseOrder,
	|	DiscrepancyData.Warehouse,
	|	DiscrepancyData.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
	|		AND &Period >= DiscrepancyData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages AS UseWarehouseManagemantSystemForGoodsSurplusesShortages,
	|	DiscrepancyData.SalesOpportunity,
	|	DiscrepancyData.Department,
	|	DiscrepancyData.CostGroupNumber,
	|	DiscrepancyData.ProductCostElement,
	|	DiscrepancyData.ProductionStage,
	|	DiscrepancyData.ToExpenseAs,
	|	DiscrepancyData.ExpenseItem,
	|	DiscrepancyData.DimensionOfExpenses,
	|	DiscrepancyData.AssetsLiabilitiesDimension,
	|	DiscrepancyData.DimensionOfRevenue,
	|	DiscrepancyData.LineOfBusiness,
	|	DiscrepancyData.HashAmountAccountSettings,
	|	DiscrepancyData.CCDNumber,
	|	DiscrepancyData.FEACNCode,
	|	DiscrepancyData.VATRate,
	|	SUM(DiscrepancyData.Sum),
	|	SUM(DiscrepancyData.VATAmount),
	|	SUM(DiscrepancyData.AmountIncludingVAT),
	|	CAST(DiscrepancyData.Products AS Catalog.Products).ItemsType AS ItemsType,
	|	CAST(DiscrepancyData.Products AS Catalog.Products).TracedGoods AS AccountingForTheRNPTIsMaintained,
	|	DiscrepancyData.RowCode AS RowCode,
	|	MIN(DiscrepancyData.LineNumber) AS LineNumber
	|FROM
	|	DiscrepancyData AS DiscrepancyData
	|
	|GROUP BY
	|	DiscrepancyData.Characteristic,
	|	DiscrepancyData.Purpose,
	|	DiscrepancyData.Series,
	|	DiscrepancyData.Content,
	|	DiscrepancyData.Package,
	|	DiscrepancyData.PurchaseOrder,
	|	DiscrepancyData.Warehouse,
	|	DiscrepancyData.Products,
	|	DiscrepancyData.SalesOpportunity,
	|	DiscrepancyData.Department,
	|	DiscrepancyData.CostGroupNumber,
	|	DiscrepancyData.ProductCostElement,
	|	DiscrepancyData.ProductionStage,
	|	DiscrepancyData.ToExpenseAs,
	|	DiscrepancyData.ExpenseItem,
	|	DiscrepancyData.DimensionOfExpenses,
	|	DiscrepancyData.AssetsLiabilitiesDimension,
	|	DiscrepancyData.DimensionOfRevenue,
	|	DiscrepancyData.LineOfBusiness,
	|	DiscrepancyData.HashAmountAccountSettings,
	|	DiscrepancyData.CCDNumber,
	|	DiscrepancyData.FEACNCode,
	|	DiscrepancyData.VATRate,
	|	DiscrepancyData.RowCode	
	|
	|HAVING
	|	CAST(SUM(DiscrepancyData.AmountIncludingVAT) AS NUMBER(31,2)) <> 0
	|	OR CAST(SUM(DiscrepancyData.VATAmount) AS NUMBER(31,2)) <> 0 
	|	ORDER BY
	|		MIN(DiscrepancyData.LineNumber)
	|";
	
	Query.SetParameter("NewData", Goods.Unload());
	Query.SetParameter("Period", Date);
	
	TableOfDiscrepanciesInAmounts = Query.Execute().Unload();
	
	TableOfDiscrepancies = Discrepancies.UnloadColumns();
	TableOfDiscrepancies.Columns.Add("HashAmountAccountSettings", Common.StringTypeDetails(50));
	TableOfDiscrepancies.Columns.Add("AccountingForTheRNPTIsMaintained", New TypeDescription("Boolean"));
	TableOfDiscrepancies.Columns.Add("UseWarehouseManagemantSystemForGoodsSurplusesShortages", New TypeDescription("Boolean"));
	
	AdjustmentPeriod_				= ?(ValueIsFilled(Date), Date, CurrentSessionDate());
	ReceiptPeriod				= Common.ObjectAttributeValue(DocumentBasis, "Date");
	LastPeriodAdjustment	= ReceiptPeriod < BegOfMonth(AdjustmentPeriod_);
	
	For Each TheseDiscrepancies In TableOfDiscrepanciesInAmounts Do
		NewDivergence = TableOfDiscrepancies.Add();
		FillPropertyValues(NewDivergence, TheseDiscrepancies);
		
		NewDivergence.PostingOption = VariantOfReflectionByLine(NewDivergence,
																	TheseDiscrepancies.ItemsType,
																	LastPeriodAdjustment,
																	UninvoicedReceiptDocumentIsUsed);
	EndDo;
	
	Query.SetParameter("AccountedDiscrepancies", TableOfDiscrepancies);
	Query.Text = "
	|DROP DiscrepancyData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountedDiscrepancies.Products AS Products,
	|	AccountedDiscrepancies.Characteristic AS Characteristic,
	|	AccountedDiscrepancies.Purpose AS Purpose,
	|	AccountedDiscrepancies.Series AS Series,
	|	AccountedDiscrepancies.Content AS Content,
	|	AccountedDiscrepancies.Package AS Package,
	|	AccountedDiscrepancies.PurchaseOrder AS PurchaseOrder,
	|	AccountedDiscrepancies.Warehouse AS Warehouse,
	|	AccountedDiscrepancies.SalesOpportunity AS SalesOpportunity,
	|	AccountedDiscrepancies.Department AS Department,
	|	AccountedDiscrepancies.CostGroupNumber AS CostGroupNumber,
	|	AccountedDiscrepancies.ProductCostElement AS ProductCostElement,
	|	AccountedDiscrepancies.ProductionStage AS ProductionStage,
	|	AccountedDiscrepancies.ToExpenseAs AS ToExpenseAs,
	|	AccountedDiscrepancies.ExpenseItem AS ExpenseItem,
	|	AccountedDiscrepancies.DimensionOfExpenses AS DimensionOfExpenses,
	|	AccountedDiscrepancies.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	AccountedDiscrepancies.DimensionOfRevenue AS DimensionOfRevenue,
	|	AccountedDiscrepancies.LineOfBusiness AS LineOfBusiness,
	|	AccountedDiscrepancies.HashAmountAccountSettings AS HashAmountAccountSettings,
	|	AccountedDiscrepancies.CCDNumber AS CCDNumber,
	|	AccountedDiscrepancies.FEACNCode AS FEACNCode,
	|	AccountedDiscrepancies.VATRate AS VATRate,
	|	AccountedDiscrepancies.VATAmount AS VATAmount,
	|	AccountedDiscrepancies.AmountIncludingVAT AS AmountIncludingVAT,
	|	AccountedDiscrepancies.RowCode AS RowCode,
	|	AccountedDiscrepancies.LineNumber AS LineNumber
	|INTO AccountedDiscrepancies
	|FROM
	|	&AccountedDiscrepancies AS AccountedDiscrepancies
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewData.Products AS Products,
	|	NewData.Characteristic AS Characteristic,
	|	NewData.Purpose AS Purpose,
	|	NewData.Series AS Series,
	|	NewData.Content AS Content,
	|	NewData.Package AS Package,
	|	NewData.PurchaseOrder AS PurchaseOrder,
	|	NewData.Warehouse AS Warehouse,
	|	NewData.SalesOpportunity AS SalesOpportunity,
	|	NewData.Department AS Department,
	|	NewData.CostGroupNumber AS CostGroupNumber,
	|	NewData.ProductCostElement AS ProductCostElement,
	|	NewData.ProductionStage AS ProductionStage,
	|	NewData.ToExpenseAs AS ToExpenseAs,
	|	NewData.ExpenseItem AS ExpenseItem,
	|	NewData.DimensionOfExpenses AS DimensionOfExpenses,
	|	NewData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	NewData.DimensionOfRevenue AS DimensionOfRevenue,
	|	NewData.LineOfBusiness AS LineOfBusiness,
	|	NewData.HashAmountAccountSettings AS HashAmountAccountSettings,
	|	NewData.CCDNumber AS CCDNumber,
	|	NewData.FEACNCode AS FEACNCode,
	|	NewData.VATRate AS VATRate,
	|	NewData.NumberOfPackages AS NumberOfPackages,
	|	NewData.Count AS Count,
	|	NewData.QuantityByGBRN AS QuantityByGBRN,
	|	NewData.VATAmount AS VATAmount,
	|	NewData.AmountIncludingVAT AS AmountIncludingVAT,
	|	NewData.RowCode AS RowCode,
	|	NewData.LineNumber AS LineNumber
	|INTO DiscrepancyData
	|FROM
	|	NewData AS NewData
	|
	|UNION ALL
	|
	|SELECT
	|	RawData.Products,
	|	RawData.Characteristic,
	|	RawData.Purpose,
	|	RawData.Series,
	|	RawData.Content,
	|	RawData.Package,
	|	RawData.PurchaseOrder,
	|	RawData.Warehouse,
	|	RawData.SalesOpportunity,
	|	RawData.Department AS Department,
	|	RawData.CostGroupNumber AS CostGroupNumber,
	|	RawData.ProductCostElement AS ProductCostElement,
	|	RawData.ProductionStage AS ProductionStage,
	|	RawData.ToExpenseAs AS ToExpenseAs,
	|	RawData.ExpenseItem,
	|	RawData.DimensionOfExpenses,
	|	RawData.AssetsLiabilitiesDimension,
	|	RawData.DimensionOfRevenue,
	|	RawData.LineOfBusiness,
	|	RawData.HashAmountAccountSettings,
	|	RawData.CCDNumber,
	|	RawData.FEACNCode,
	|	RawData.VATRate,
	|	-RawData.NumberOfPackages,
	|	-RawData.Count,
	|	-RawData.QuantityByGBRN,
	|	-RawData.VATAmount,
	|	-RawData.AmountIncludingVAT,
	|	RawData.RowCode,
	|	RawData.LineNumber
	|FROM
	|	RawDataForDiscrepancies AS RawData
	|
	|UNION ALL
	|
	|SELECT
	|	AccountedDiscrepancies.Products,
	|	AccountedDiscrepancies.Characteristic,
	|	AccountedDiscrepancies.Purpose,
	|	AccountedDiscrepancies.Series,
	|	AccountedDiscrepancies.Content,
	|	AccountedDiscrepancies.Package,
	|	AccountedDiscrepancies.PurchaseOrder,
	|	AccountedDiscrepancies.Warehouse,
	|	AccountedDiscrepancies.SalesOpportunity,
	|	AccountedDiscrepancies.Department,
	|	AccountedDiscrepancies.CostGroupNumber AS CostGroupNumber,
	|	AccountedDiscrepancies.ProductCostElement AS ProductCostElement,
	|	AccountedDiscrepancies.ProductionStage AS ProductionStage,
	|	AccountedDiscrepancies.ToExpenseAs,
	|	AccountedDiscrepancies.ExpenseItem,
	|	AccountedDiscrepancies.DimensionOfExpenses,
	|	AccountedDiscrepancies.AssetsLiabilitiesDimension,
	|	AccountedDiscrepancies.DimensionOfRevenue,
	|	AccountedDiscrepancies.LineOfBusiness,
	|	AccountedDiscrepancies.HashAmountAccountSettings,
	|	AccountedDiscrepancies.CCDNumber,
	|	AccountedDiscrepancies.FEACNCode,
	|	AccountedDiscrepancies.VATRate,
	|	0,
	|	0,
	|	0,
	|	-AccountedDiscrepancies.VATAmount,
	|	-AccountedDiscrepancies.AmountIncludingVAT,
	|	AccountedDiscrepancies.RowCode,
	|	AccountedDiscrepancies.LineNumber	
	|FROM
	|	AccountedDiscrepancies AS AccountedDiscrepancies
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyData.Products AS Products,
	|	DiscrepancyData.Characteristic AS Characteristic,
	|	DiscrepancyData.Purpose AS Purpose,
	|	DiscrepancyData.Series AS Series,
	|	DiscrepancyData.Content AS Content,
	|	DiscrepancyData.Package AS Package,
	|	DiscrepancyData.PurchaseOrder AS PurchaseOrder,
	|	DiscrepancyData.Warehouse AS Warehouse,
	|	DiscrepancyData.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
	|		AND &Period >= DiscrepancyData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages AS UseWarehouseManagemantSystemForGoodsSurplusesShortages,
	|	DiscrepancyData.SalesOpportunity AS SalesOpportunity,
	|	DiscrepancyData.Department AS Department,
	|	DiscrepancyData.CostGroupNumber AS CostGroupNumber,
	|	DiscrepancyData.ProductCostElement AS ProductCostElement,
	|	DiscrepancyData.ProductionStage,
	|	DiscrepancyData.ToExpenseAs AS ToExpenseAs,
	|	DiscrepancyData.ExpenseItem AS ExpenseItem,
	|	DiscrepancyData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DiscrepancyData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DiscrepancyData.DimensionOfRevenue AS DimensionOfRevenue,
	|	DiscrepancyData.LineOfBusiness AS LineOfBusiness,
	|	DiscrepancyData.HashAmountAccountSettings,
	|	DiscrepancyData.CCDNumber AS CCDNumber,
	|	DiscrepancyData.FEACNCode AS FEACNCode,
	|	DiscrepancyData.VATRate AS VATRate,
	|	SUM(DiscrepancyData.NumberOfPackages) AS NumberOfPackages,
	|	SUM(DiscrepancyData.Count) AS Count,
	|	SUM(DiscrepancyData.QuantityByGBRN) AS QuantityByGBRN,
	|	SUM(DiscrepancyData.VATAmount) AS VATAmount,
	|	SUM(DiscrepancyData.AmountIncludingVAT) AS AmountIncludingVAT,
	|	CAST(DiscrepancyData.Products AS Catalog.Products).ItemsType AS ItemsType,
	|	CAST(DiscrepancyData.Products AS Catalog.Products).TracedGoods AS AccountingForTheRNPTIsMaintained,
	|	DiscrepancyData.RowCode AS RowCode,
	|	MIN(DiscrepancyData.LineNumber) AS LineNumber 
	|INTO DataOfDiscrepanciesAreIntermediate
	|FROM
	|	DiscrepancyData AS DiscrepancyData
	|
	|GROUP BY
	|	DiscrepancyData.Characteristic,
	|	DiscrepancyData.Purpose,
	|	DiscrepancyData.Series,
	|	DiscrepancyData.Content,
	|	DiscrepancyData.Package,
	|	DiscrepancyData.PurchaseOrder,
	|	DiscrepancyData.Warehouse,
	|	DiscrepancyData.Products,
	|	DiscrepancyData.SalesOpportunity,
	|	DiscrepancyData.Department,
	|	DiscrepancyData.CostGroupNumber,
	|	DiscrepancyData.ProductCostElement,
	|	DiscrepancyData.ProductionStage,
	|	DiscrepancyData.ToExpenseAs,
	|	DiscrepancyData.ExpenseItem,
	|	DiscrepancyData.AssetsLiabilitiesDimension,
	|	DiscrepancyData.DimensionOfRevenue,
	|	DiscrepancyData.DimensionOfExpenses,
	|	DiscrepancyData.LineOfBusiness,
	|	DiscrepancyData.HashAmountAccountSettings,
	|	DiscrepancyData.CCDNumber,
	|	DiscrepancyData.FEACNCode,
	|	DiscrepancyData.VATRate,
	|	DiscrepancyData.RowCode
	|
	|HAVING
	|	CAST(SUM(DiscrepancyData.NumberOfPackages) AS NUMBER(15,3)) <> 0
	|	OR CAST(SUM(DiscrepancyData.Count) AS NUMBER(15,3)) <> 0
	|	OR CAST(SUM(DiscrepancyData.QuantityByGBRN) AS NUMBER(15,11)) <> 0
	|	OR CAST(SUM(DiscrepancyData.AmountIncludingVAT) AS NUMBER(31,2)) <> 0
	|	OR CAST(SUM(DiscrepancyData.VATAmount) AS NUMBER(31,2)) <> 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyData.Products,
	|	DiscrepancyData.Characteristic,
	|	DiscrepancyData.Purpose,
	|	DiscrepancyData.Series,
	|	DiscrepancyData.Content,
	|	DiscrepancyData.Package,
	|	DiscrepancyData.PurchaseOrder,
	|	DiscrepancyData.Warehouse,
	|	DiscrepancyData.UseWarehouseManagemantSystemForGoodsSurplusesShortages,
	|	DiscrepancyData.SalesOpportunity,
	|	DiscrepancyData.Department,
	|	DiscrepancyData.CostGroupNumber,
	|	DiscrepancyData.ProductCostElement AS ProductCostElement,
	|	DiscrepancyData.ProductionStage,
	|	DiscrepancyData.ToExpenseAs,
	|	DiscrepancyData.ExpenseItem,
	|	DiscrepancyData.DimensionOfExpenses,
	|	DiscrepancyData.AssetsLiabilitiesDimension,
	|	DiscrepancyData.DimensionOfRevenue,
	|	DiscrepancyData.LineOfBusiness,
	|	DiscrepancyData.HashAmountAccountSettings,
	|	DiscrepancyData.CCDNumber,
	|	DiscrepancyData.FEACNCode,
	|	DiscrepancyData.VATRate,
	|	DiscrepancyData.NumberOfPackages,
	|	DiscrepancyData.Count,
	|	DiscrepancyData.QuantityByGBRN,
	|	DiscrepancyData.VATAmount,
	|	DiscrepancyData.AmountIncludingVAT,
	|	DiscrepancyData.ItemsType,
	|	DiscrepancyData.AccountingForTheRNPTIsMaintained,
	|	DiscrepancyData.RowCode AS RowCode,
	|	MIN(DiscrepancyData.LineNumber)AS LineNumber 
	|FROM
	|	DataOfDiscrepanciesAreIntermediate AS DiscrepancyData
	|		LEFT JOIN NewDataFromTable AS TableData
	|		ON DiscrepancyData.Products = TableData.Products
	|			AND DiscrepancyData.Characteristic = TableData.Characteristic
	|			AND DiscrepancyData.RowCode = TableData.RowCode
	|			AND DiscrepancyData.Content = TableData.Content
	|
	|GROUP BY
	|	DiscrepancyData.Products,
	|	DiscrepancyData.Characteristic,
	|	DiscrepancyData.Purpose,
	|	DiscrepancyData.Series,
	|	DiscrepancyData.Content,
	|	DiscrepancyData.Package,
	|	DiscrepancyData.PurchaseOrder,
	|	DiscrepancyData.Warehouse,
	|	DiscrepancyData.UseWarehouseManagemantSystemForGoodsSurplusesShortages,
	|	DiscrepancyData.SalesOpportunity,
	|	DiscrepancyData.Department,
	|	DiscrepancyData.CostGroupNumber,
	|	DiscrepancyData.ProductCostElement,
	|	DiscrepancyData.ProductionStage,
	|	DiscrepancyData.ToExpenseAs,
	|	DiscrepancyData.ExpenseItem,
	|	DiscrepancyData.DimensionOfExpenses,
	|	DiscrepancyData.AssetsLiabilitiesDimension,
	|	DiscrepancyData.DimensionOfRevenue,
	|	DiscrepancyData.LineOfBusiness,
	|	DiscrepancyData.HashAmountAccountSettings,
	|	DiscrepancyData.CCDNumber,
	|	DiscrepancyData.FEACNCode,
	|	DiscrepancyData.VATRate,
	|	DiscrepancyData.NumberOfPackages,
	|	DiscrepancyData.Count,
	|	DiscrepancyData.QuantityByGBRN,
	|	DiscrepancyData.VATAmount,
	|	DiscrepancyData.AmountIncludingVAT,
	|	DiscrepancyData.ItemsType,
	|	DiscrepancyData.AccountingForTheRNPTIsMaintained,
	|	DiscrepancyData.RowCode,
	|	DiscrepancyData.LineNumber
	|
	|ORDER BY
	|	MIN(DiscrepancyData.LineNumber),
	|	DiscrepancyData.VATRate,
	|	DiscrepancyData.Department,
	|	DiscrepancyData.Warehouse,
	|	DiscrepancyData.CCDNumber,
	|	DiscrepancyData.Count";
	
	TheseDiscrepancies = Query.Execute().Select();
	
	While TheseDiscrepancies.Next() Do
		
		SearchParameters = New Structure(KeyFields);
		FillPropertyValues(SearchParameters, TheseDiscrepancies);
		FoundRows = TableOfDiscrepancies.FindRows(SearchParameters);
		
		RowFound = False;
		For Each NewDivergence In FoundRows Do
			NewCount = NewDivergence.Count + TheseDiscrepancies.Count;
			If (NewCount > 0 And NewDivergence.AmountIncludingVAT > 0)
				Or (NewCount < 0 And NewDivergence.AmountIncludingVAT < 0) Then
				NewDivergence.Count			= NewCount;
				NewDivergence.QuantityByGBRN	= NewDivergence.QuantityByGBRN + TheseDiscrepancies.QuantityByGBRN;
				NewDivergence.NumberOfPackages	= NewDivergence.NumberOfPackages + TheseDiscrepancies.NumberOfPackages;
				NewDivergence.LineNumber		= TheseDiscrepancies.LineNumber;
				RowFound = True;
				Break;
			EndIf;
		EndDo;
		
		If Not RowFound Then
			NewDivergence = TableOfDiscrepancies.Add();
			FillPropertyValues(NewDivergence, TheseDiscrepancies);
		EndIf;
		
		NewDivergence.Sum = NewDivergence.AmountIncludingVAT - ?(PriceIncludesVAT, 0, NewDivergence.VATAmount);
		NewDivergence.PostingOption = VariantOfReflectionByLine(NewDivergence,
																	TheseDiscrepancies.ItemsType,
																	LastPeriodAdjustment,
																	UninvoicedReceiptDocumentIsUsed);
		
	EndDo;
	AccountingAccountSettingsTable = TableOfDiscrepancies.Copy(, "GLAccountSettings,HashAmountAccountSettings");
	AccountingAccountSettingsTable.GroupBy("GLAccountSettings,HashAmountAccountSettings");
	
	Query.SetParameter("HashAmountOfAccountSettings", AccountingAccountSettingsTable.UnloadColumn("HashAmountAccountSettings"));
	Query.Text = "
	|DROP DiscrepancyData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewData.GLAccountSettings    AS GLAccountSettings,
	|	NewData.HashAmountAccountSettings AS HashAmountAccountSettings
	|FROM
	|	NewData AS NewData
	|WHERE
	|	NewData.HashAmountAccountSettings IN (&HashAmountOfAccountSettings)
	|
	|UNION ALL
	|
	|SELECT
	|	RawData.GLAccountSettings    AS GLAccountSettings,
	|	RawData.HashAmountAccountSettings AS HashAmountAccountSettings
	|FROM
	|	RawDataForDiscrepancies AS RawData
	|WHERE
	|	RawData.HashAmountAccountSettings IN (&HashAmountOfAccountSettings)
	|";
	Selection = Query.Execute().Select();
	
	SettingsCount = AccountingAccountSettingsTable.Count();
	For ReverseIndex = 1 To SettingsCount Do
		InvoiceSettingsBar = AccountingAccountSettingsTable[SettingsCount - ReverseIndex];
		TheStructureOfTheSearch = New Structure("HashAmountAccountSettings", InvoiceSettingsBar.HashAmountAccountSettings);
		
		Selection.Reset();
		If Selection.FindNext(TheStructureOfTheSearch) And ValueIsFilled(Selection.GLAccountSettings) Then
			InvoiceSettingsBar.GLAccountSettings = Selection.GLAccountSettings;
		Else
			AccountingAccountSettingsTable.Delete(InvoiceSettingsBar);
		EndIf;
	EndDo;
	
	If AccountingAccountSettingsTable.Count() > 0 Then
		AccountSettingsData = GLAccountSettingsServer.AccountSettingsData_(AccountingAccountSettingsTable.UnloadColumn("GLAccountSettings"));
	
		For Each InvoiceSettingsBar In AccountingAccountSettingsTable Do
			TheStructureOfTheSearch = New Structure("HashAmountAccountSettings", InvoiceSettingsBar.HashAmountAccountSettings);
			LinesOfDivergence = TableOfDiscrepancies.FindRows(TheStructureOfTheSearch);
			
			For Each DivergenceLine In LinesOfDivergence Do
				DivergenceLine.GLAccountSettings = GLAccountSettingsServer.NewAccountSettings_(AccountSettingsData[InvoiceSettingsBar.GLAccountSettings]);
			EndDo;
		EndDo;
	EndIf;
	TableOfDiscrepancies.Sort("LineNumber, Products, Characteristic, Series, Content, Package, PostingOption");
	Discrepancies.Load(TableOfDiscrepancies);
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Discrepancies, StructureOfActions);

EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
