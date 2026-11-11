#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.SaleAdjustment - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part
// The 'Discrepancies' of the document, and also fills in the tabular parts of the 'Views of the order of entry', 'Views of the order of entry'
// and 'Views of the order of correction of the pens'.
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.SaleAdjustment.CollectionOfTabularPartsOfGoods.
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
	
	SetPrivilegedMode(True);
	If WriteMode = DocumentWriteMode.Posting 
		And ValueIsFilled(DocumentBasis)
		And Not Common.ObjectAttributeValue(DocumentBasis,"Posted") Then
		SalesServer.ReportErrorsOnUnverifiedBasis(DocumentBasis, Cancel);
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	CheckChainOfCorrectionsBeforeRecording(Cancel, WriteMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	DocumentAmount = GetDocumentAmount();
	
	TMCommonUse.ChangeDocumentConsistencyAttribute(
		ThisObject,
		WriteMode);
		
	RegistrationParameters = Documents.SaleAdjustment.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	RegistrationParameters = Documents.SaleAdjustment.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	SetPrivilegedMode(False);
	
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
	
	// We will clear the unused document details.
	ArrayOfAllProps		= New Array;
	ArrayOfOperationDetails	= New Array;
	
	Documents.SaleAdjustment.FillInNamesOfDetailsOnBasis(
		DocumentBasis,
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		AdjustingEntryType);
	
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
		
	If SaleAdjustment2_5 
		And SaleAdjustmentLocalization.NotAdjustTaxBaseOfPreviousPeriod(Organization, Date) Then
		AdjustTaxBaseOfPreviousPeriod = Not RecordInProfitLossOfPreviousYears;
	EndIf;
	
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
		
		InventoryOwnerAttributesRevenueAdjustment.Clear();
		InventoryOwnerAttributesGoodsReceipt.Clear();
		InventoryOwnerAttributesConsumption.Clear();
		
	EndIf;
	
	TSRow = "Goods,Discrepancies,InventoryOwnerAttributesRevenueAdjustment,InventoryOwnerAttributesGoodsReceipt,InventoryOwnerAttributesConsumption,ARAPAdjustment";
	TMCommonUse.FillInDocumentIDs(ThisObject, TSRow);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SaleAdjustment);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.Goods);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.Discrepancies);
	
	For Each TSRow In Goods Do
		If AdjustmentKind <> Enums.BusinessTransactions.SaleOfOverdeliveredGoods
			And AdjustmentKind <> Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods Then
			
			TSRow.PostingOption = Enums.CreditNoteRecordingOptions.EmptyRef();
			
		EndIf;
	EndDo;
	
	RecordInOtherIncome	= False;
	ToExpenseAs		= False;
	
	If AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated Then
		RecordInOtherIncome = True;
	ElsIf AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
		ToExpenseAs = True;
	Else
		For Each TSRow In Discrepancies Do
			If TSRow.PostingOption = Enums.CreditNoteRecordingOptions.RecordInOtherIncome Then
				RecordInOtherIncome = True;
			ElsIf TSRow.PostingOption = Enums.CreditNoteRecordingOptions.ToExpenseAs Then
				ToExpenseAs = True;
			EndIf;
		EndDo;
	EndIf;
	
	If Not RecordInOtherIncome Then
		BusinessUnit = Catalogs.BusinessStructure.EmptyRef();
	EndIf;
	
	If Not ToExpenseAs Then
		BusinessUnitExpenses = Catalogs.BusinessStructure.EmptyRef();
	EndIf;
	
	OptionsForSelection = Documents.SaleAdjustment.ParametersForDeterminingAvailabilityOfSelectionOfArticlesAndAnalytics();
	OptionsForSelection.BusinessOperation	= AdjustmentKind;
	OptionsForSelection.AdjustingEntryType			= AdjustingEntryType;
	OptionsForSelection.DocumentBasis		= DocumentBasis;
	OptionsForSelection.DocumentDate			= Date;
	OptionsForSelection.RecordInOtherIncome	= RecordInOtherIncome;
	OptionsForSelection.ToExpenseAs			= ToExpenseAs;
	OptionsForSelection.SaleAdjustment2_5 = SaleAdjustment2_5;
	OptionsForSelection.RecordInProfitLossOfPreviousYears = RecordInProfitLossOfPreviousYears;
	OptionsForSelection.AdjustTaxBaseOfPreviousPeriod = AdjustTaxBaseOfPreviousPeriod;
	
	ItemsAndDimensionsSelectionParameters = Documents.SaleAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FillInOptionForRegistrationOfSale();
	
	If AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated
		Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
		
		PriceIncludesVAT = True;
		
	EndIf;
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
	If Not ValueIsFilled(AdjustingEntryType) Then
		AdjustingEntryType = Enums.AdjustingEntryTypes.StandardAdjustment;
	EndIf;

	If AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods 
		Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties
		Or AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection Then
		
		BonusPointsServer.FillInBonusPointsReturnItemsFromCustomer(ThisObject);
		
	Else
		
		BonusPointAccrual.Clear();
		PaymentWithBonusPoints.Clear();
		
	EndIf;
	
	SetLineCodeInRowsOfTablePart();
	
	SaleAdjustmentLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.CustomerInvoice") Then
		
		ServicesForSaleOfGoodsServices(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CustomerInvoiceServices") Then
		
		FillInActOfWorkPerformed(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		
		ActivitiesForSaleOfServicesOfOtherAssets(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.SourceDocument") Then
		
		FillInPrimaryDocument(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		
		FillInReportToGiver(FillingData, FillingData);
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DiscrepancyCertificate")
		And FillingData.Property("SaleOfGoodsAndServices")
		And FillingData.Property("Operation") Then
		
		FillInCertificateOfDiscrepanciesAfterShipment(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("SaleOfGoodsAndServices") Then
		
		ServicesForSaleOfGoodsServices(FillingData.DocumentBasis,
											FillingData,
											FillingData.DesignParameters);
		
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")And FillingData.Property("BusinessOperation") Then
		If FillingData.BusinessOperation = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated Then
			FillingData.Insert("AdjustmentKind", Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated);
		ElsIf FillingData.BusinessOperation = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
			FillingData.Insert("AdjustmentKind", Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated);
		ElsIf FillingData.BusinessOperation = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods Then
			FillingData.Insert("AdjustmentKind", Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods);
		ElsIf FillingData.BusinessOperation = Enums.BusinessTransactions.SaleOfOverdeliveredGoods Then
			FillingData.Insert("AdjustmentKind", Enums.BusinessTransactions.SaleOfOverdeliveredGoods);
		ElsIf FillingData.BusinessOperation = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties
			Or FillingData.BusinessOperation = Enums.BusinessTransactions.ErrorCorrection Then
			FillingData.Insert("AdjustmentKind", FillingData.BusinessOperation);
			FillingData.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
		Else
			FillingData.Insert("AdjustmentKind", Enums.BusinessTransactions.ErrorCorrection);
		EndIf;
		If FillingData.BusinessOperation = Enums.BusinessTransactions.AdjustBeforeEnteringBalance Then
			BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
			DocumentBasis = Documents.SourceDocument.EmptyRef();
		EndIf;
	EndIf;
	
	InitializeDocument(FillingData);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	SaleAdjustmentLocalization.Filling(ThisObject, FillingData, StandardProcessing);

	DocumentBaseParameter	= DocumentBasis;
	DateParameter				= Date;
	AdjustmentTypeParameter	= AdjustmentKind;
	
	If TypeOf(FillingData) = Type("Structure") Then
		If Not ValueIsFilled(DocumentBaseParameter) Then
			FillingData.Property("DocumentBasis", DocumentBaseParameter);
		EndIf;
		If Not ValueIsFilled(DateParameter)
			And Not FillingData.Property("Date", DateParameter) Then
			
			DateParameter = CurrentSessionDate();
			
		EndIf;
		If Not ValueIsFilled(AdjustmentTypeParameter)
			And Not FillingData.Property("AdjustmentKind", AdjustmentTypeParameter) Then
			
			AdjustmentTypeParameter = Enums.BusinessTransactions.ErrorCorrection;
			
		EndIf;
	EndIf;
	
	OptionsForSelection = Documents.SaleAdjustment.ParametersForDeterminingAvailabilityOfSelectionOfArticlesAndAnalytics();
	OptionsForSelection.BusinessOperation	= AdjustmentTypeParameter;
	OptionsForSelection.AdjustingEntryType			= AdjustingEntryType;
	OptionsForSelection.DocumentBasis		= DocumentBaseParameter;
	OptionsForSelection.DocumentDate			= DateParameter;
	OptionsForSelection.SaleAdjustment2_5 = SaleAdjustment2_5;
	OptionsForSelection.RecordInProfitLossOfPreviousYears = RecordInProfitLossOfPreviousYears;
	OptionsForSelection.AdjustTaxBaseOfPreviousPeriod = AdjustTaxBaseOfPreviousPeriod;
	
	ItemsAndDimensionsSelectionParameters = Documents.SaleAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);

	If AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods 
		Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties
		Or AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection Then
		
		BonusPointsServer.FillInBonusPointsReturnItemsFromCustomer(ThisObject);
		
	Else
		
		BonusPointAccrual.Clear();
		PaymentWithBonusPoints.Clear();
		
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ArrayOfAllProps			= New Array;
	ArrayOfOperationDetails		= New Array;
	NotCheckedAttributeArray	= New Array;
	
	Documents.SaleAdjustment.FillInNamesOfDetailsOnBasis(
		DocumentBasis,
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		AdjustingEntryType);
	
	For Each ArrayElement In ArrayOfAllProps Do
		If ArrayOfOperationDetails.Find(ArrayElement) = Undefined Then
			NotCheckedAttributeArray.Add(ArrayElement);
		EndIf;
	EndDo;
	
	If AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated
		Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
		
		NotCheckedAttributeArray.Add("DocumentBasis");
		
	EndIf;
	
	If Not ValueIsFilled(Terms) 
		Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		
		NotCheckedAttributeArray.Add("Contract");
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	ReferenceDocumentDateForCertificate = '00010101';
	
	If ValueIsFilled(DocumentBasis) Then
		
		ReferenceDocumentDateForCertificate = Common.ObjectAttributeValue(DocumentBasis, "Date");
		DocumentDate = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
		
		LastPeriodAdjustment	= BegOfYear(DocumentDate) > BegOfYear(ReferenceDocumentDateForCertificate);
		OtherAssetServiceAdjustment	= TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets")
											Or AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
	
		If OtherAssetServiceAdjustment
			And Not LastPeriodAdjustment Then
			
			NotCheckedAttributeArray.Add("BusinessUnit");
			NotCheckedAttributeArray.Add("BusinessUnitExpenses");
			
		EndIf;
		
		If TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice")
			And (AdjustmentKind = Enums.BusinessTransactions.AdjustmentUnderApprovalOfParties
				Or AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection) Then
				
			CheckFillingOutCostDeterminationMethod(ReferenceDocumentDateForCertificate, DocumentDate, Cancel);
			
		EndIf;
		
		If Date < ReferenceDocumentDateForCertificate Then
			ErrorText = NStr("vi = 'Ngày chứng từ không cần nhỏ hơn ngày chứng từ cơ sở.';
							|ru = 'Дата документа не должна быть меньше даты документа основания.';
							|en = 'The document date must be later than the base document date.'; fa = 'The document date must be later than the base document date.';
							|it = 'Дата документа не должна быть меньше даты документа основания.';
							|pl = 'The document date must be later than the base document date.';
							|tr = 'Belge tarihi, temel belge tarihinden daha önce olmamalıdır.'");
			Common.MessageToUser(ErrorText,, "Object.Date",, Cancel);
		EndIf;
		
	EndIf;
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
		DocumentBasisBusinessOperation = Documents.SaleAdjustment.EconomicOperationOfFoundationDocument(DocumentBasis);
		
		If Not ConsignmentSalesServer.SalesViaCommissionAgent(DocumentBasisBusinessOperation) Then
			NotCheckedAttributeArray.Add("CustomerCounterparty");
			NotCheckedAttributeArray.Add("CustomerPartner");
			NotCheckedAttributeArray.Add("CustomerContract");
		EndIf;
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
		NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
		NotCheckedAttributeArray.Add("Discrepancies.NumberOfPackages");
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument")
		Or TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		
		NotCheckedAttributeArray.Add("Goods.Count");
		NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
		
		NotCheckedAttributeArray.Add("Discrepancies.Count");
		NotCheckedAttributeArray.Add("Discrepancies.NumberOfPackages");
		If ValueIsFilled(Contract)
			And Common.ObjectAttributeValue(Contract, "ContractType") = Enums.ContractTypes.ReceiptForTolling2_5 Then
			NotCheckedAttributeArray.Add("Terms");
		EndIf;
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		NotCheckedAttributeArray.Add("Terms");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		Or BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		
		NotCheckedAttributeArray.Add("Partner");
		
		If Not ValueIsFilled(Partner) Then
			ErrorText = NStr("vi = 'Chưa điền trường ""Bên đặt gia công""';
							|ru = 'Поле ""Давалец"" не заполнено';
							|en = 'The ""Material provider"" field is not filled'; fa = 'The ""Material provider"" field is not filled';
							|it = 'Campo ""Fornitore"" non compilato';
							|pl = 'Pole ""Właściciel surowców"" nie jest wypełnione';
							|tr = '""Malzeme tedarikçisi"" alanı doldurulmamış'");
			Common.MessageToUser(ErrorText, ThisObject, "Partner",, Cancel);
		EndIf;
		
	EndIf;
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument")
		Or VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
		
		NotCheckedAttributeArray.Add("Goods.VATRate");
		NotCheckedAttributeArray.Add("Discrepancies.VATRate");
		
	EndIf;
	
	If AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices Then
		NotCheckedAttributeArray.Add("Goods.Content");
		NotCheckedAttributeArray.Add("Discrepancies.Content");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
	
		ReflectionsOptionsWithMandatoryWarehouse =
			Documents.SaleAdjustment.ReflectionsOptionsWithMandatoryWarehouse();
		
		If AdjustmentKind =
				PredefinedValue("Enum.BusinessTransactions.SaleOfOverdeliveredGoods")
				Or AdjustmentKind =
					PredefinedValue("Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods") Then
			
			For Each TSRow In Goods Do
				
				If ReflectionsOptionsWithMandatoryWarehouse.FindByValue(TSRow.PostingOption) <> Undefined Then
					
					If Not ValueIsFilled(Warehouse) Then
						CheckedAttributes.Add("Warehouse");
						Break;
					
					ElsIf Not ValueIsFilled(TSRow.Warehouse) Then
					
						ErrorText = NStr("vi = 'Chưa điền cột ""Nơi gửi"" tại dòng %LineNumber% của danh sách ""Hàng hóa""';
										|ru = 'Не заполнена колонка ""Отправитель"" в строке %LineNumber% списка ""Товары""';
										|en = 'The ""Sender"" column in line %LineNumber% of the ""Goods"" list is not filled'; fa = 'The ""Sender"" column in line %LineNumber% of the ""Goods"" list is not filled';
										|it = 'The ""Sender"" column in line %LineNumber% of the ""Goods"" list is not filled';
										|pl = 'The ""Sender"" column in line %LineNumber% of the ""Goods"" list is not filled';
										|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Gönderici"" sütunu eksik'");
						ErrorText =  StrReplace(ErrorText, "%LineNumber%", TSRow.LineNumber);
						
						Common.MessageToUser(
							ErrorText,
							ThisObject,
							CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "Warehouse"),
							,
							Cancel);
					
					EndIf;
					
				EndIf;
				
			EndDo;
		
		Else
		
			For Each TSRow In Discrepancies Do
				
				If ReflectionsOptionsWithMandatoryWarehouse.FindByValue(TSRow.PostingOption) <> Undefined Then
					
					If Not ValueIsFilled(Warehouse) Then
						CheckedAttributes.Add("Warehouse");
						Break;
					
					ElsIf Not ValueIsFilled(TSRow.Warehouse) Then
					
						ErrorText = NStr("vi = 'Chưa điền cột ""Nơi gửi"" tại dòng %LineNumber% danh sách ""Chênh lệch""';
										|ru = 'Не заполнена колонка ""Отправитель"" в строке %LineNumber% списка ""Расхождения""';
										|en = 'The ""Sender"" column in line %LineNumber% of the ""Discrepancies"" list is not filled in'; fa = 'The ""Sender"" column in line %LineNumber% of the ""Discrepancies"" list is not filled in';
										|it = 'The ""Sender"" column in line %LineNumber% of the ""Discrepancies"" list is not filled in';
										|pl = 'The ""Sender"" column in line %LineNumber% of the ""Discrepancies"" list is not filled in';
										|tr = '""Siparişler"" listesinin %LineNumber% satırında ""Gönderici"" sütunu doldurulmadı'");
						ErrorText =  StrReplace(ErrorText, "%LineNumber%", TSRow.LineNumber);
						
						Common.MessageToUser(
							ErrorText,
							ThisObject,
							CommonClientServer.PathToTabularSection("Discrepancies", TSRow.LineNumber, "Warehouse"),
							,
							Cancel);
					
					EndIf;
					
				EndIf;
				
			EndDo;
		
		EndIf;
		
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.Warehouse");
	
	If Not SaleByOrders Then
		NotCheckedAttributeArray.Add("Goods.SalesOrder");
		NotCheckedAttributeArray.Add("Discrepancies.SalesOrder");
	EndIf;
	
	ResultsOfDiscrepancyCheck = CheckFillingForDiscrepancies(NotCheckedAttributeArray, Cancel);
	
	If Not SubjectToExcise Then
		NotCheckedAttributeArray.Add("BusinessUnitProduction");
	EndIf;
	
	RecordInOtherIncome	= ResultsOfDiscrepancyCheck.RecordInOtherIncome
		Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated;
	ToExpenseAs		= ResultsOfDiscrepancyCheck.ToExpenseAs
		Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument") Then
		NotCheckedAttributeArray.Add("Goods.Content");
		NotCheckedAttributeArray.Add("Goods.Products");
		NotCheckedAttributeArray.Add("Goods.Characteristic");
		NotCheckedAttributeArray.Add("Goods.Series");
		NotCheckedAttributeArray.Add("Goods.PostingOption");
		NotCheckedAttributeArray.Add("Goods.IncomeItem");
		NotCheckedAttributeArray.Add("Goods.DimensionOfRevenue");
		
		NotCheckedAttributeArray.Add("Discrepancies.Content");
		NotCheckedAttributeArray.Add("Discrepancies.Products");
		NotCheckedAttributeArray.Add("Discrepancies.Characteristic");
		NotCheckedAttributeArray.Add("Discrepancies.Series");
		NotCheckedAttributeArray.Add("Discrepancies.PostingOption");
		NotCheckedAttributeArray.Add("Discrepancies.IncomeItem");
		NotCheckedAttributeArray.Add("Discrepancies.DimensionOfRevenue");
		
		AdjustmentTable = Documents.SaleAdjustment.AdjustmentDataBeforeEnteringBalances(ThisObject,
								AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices);
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(
			ThisObject,
			Documents.SaleAdjustment);
		
		ParametersForSpecifyingSeriesOfItems = SeriesSpecificationParameters.Goods;
		ParametersForSpecifyingSeriesOfItems.NameTSGoods	= "AdjustmentTable";
		ParametersForSpecifyingSeriesOfItems.TSSeriesName		= "AdjustmentTable";
		
		DocumentData = New Structure;
		DocumentData.Insert("Object",					ThisObject);
		DocumentData.Insert("SeriesSpecificationParameters",	ParametersForSpecifyingSeriesOfItems);
		DocumentData.Insert("AdjustmentTable",	AdjustmentTable);
		
		Documents.SaleAdjustment.CheckAttributesFilling(DocumentData, CheckedAttributes, Cancel);
		
	Else
		
		If TypeOf(DocumentBasis) <> Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
			ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
		EndIf;
		
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
		
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "Discrepancies";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,
															NotCheckedAttributeArray,
															Cancel,
															CheckParameters);
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SaleAdjustment);
		
		ParametersCollection = New Array;
		ParametersCollection.Add(SeriesSpecificationParameters.Goods);
		ParametersCollection.Add(SeriesSpecificationParameters.Discrepancies);
		
		ProductsServer.CheckSeriesCompletion(ThisObject,
													ParametersCollection,
													Cancel,
													NotCheckedAttributeArray);
		
		OptionsForSelection = Documents.SaleAdjustment.ParametersForDeterminingAvailabilityOfSelectionOfArticlesAndAnalytics();
		OptionsForSelection.BusinessOperation	= AdjustmentKind;
		OptionsForSelection.AdjustingEntryType			= AdjustingEntryType;
		OptionsForSelection.DocumentBasis		= DocumentBasis;
		OptionsForSelection.DocumentDate			= Date;
		OptionsForSelection.RecordInOtherIncome	= RecordInOtherIncome;
		OptionsForSelection.ToExpenseAs			= ToExpenseAs;
		OptionsForSelection.SaleAdjustment2_5 = SaleAdjustment2_5;
		OptionsForSelection.RecordInProfitLossOfPreviousYears = RecordInProfitLossOfPreviousYears;
		OptionsForSelection.AdjustTaxBaseOfPreviousPeriod = AdjustTaxBaseOfPreviousPeriod;
		
		ItemsAndDimensionsSelectionParameters = Documents.SaleAdjustment.ItemsAndDimensionsSelectionParameters(OptionsForSelection);
		IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	EndIf;
	
	If SaleAdjustment2_5 And BegOfYear(ReferenceDocumentDateForCertificate) < BegOfYear(Date) Then
		NotCheckedAttributeArray.Add("IncomeItem");
		NotCheckedAttributeArray.Add("DimensionOfRevenue");
		NotCheckedAttributeArray.Add("ExpenseItem");
		NotCheckedAttributeArray.Add("DimensionOfExpenses");
	EndIf;
	
	CheckCompletionOfDebtAdjustmentTable(Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel
		And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		
		Cancel = True;
		
	EndIf;
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject,Cancel);
	
	VATAccountingLocalization.CheckServicesAtCommitteeSVATRate(ThisObject, Cancel, "Goods", BaseDocumentDate());
	
	SaleAdjustmentLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RegistrationParameters = Documents.SaleAdjustment.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
	RegistrationParameters = Documents.SaleAdjustment.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	
	SaleAdjustmentLocalization.Posting(ThisObject, Cancel, PostingMode);
	If Not Cancel Then
		ExcisableGoodsAccounting.CreateTaskToRecordAmountOfExciseTax(ThisObject);
	EndIf;
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RegistrationParameters = Documents.SaleAdjustment.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
	RegistrationParameters = Documents.SaleAdjustment.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	
	SaleAdjustmentLocalization.UndoPosting(ThisObject, Cancel);
	
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
	Approved = False;
	SaleAdjustment2_5 = True;
	
	InventoryOwnerAttributesRevenueAdjustment.Clear();
	InventoryOwnerAttributesGoodsReceipt.Clear();
	InventoryOwnerAttributesConsumption.Clear();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TSRow = "Discrepancies,InventoryOwnerAttributesRevenueAdjustment,InventoryOwnerAttributesGoodsReceipt,InventoryOwnerAttributesConsumption";
	TMCommonUse.ClearDocumentIDs(ThisObject, TSRow);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	
	If ValueIsFilled(DocumentBasis) Then
		ParametersFillInVATRate.Date = Common.ObjectAttributeValue(DocumentBasis, "Date");
	EndIf;
	
	StructureOfActions = New Structure;
	CacheDiscrepancies = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	CacheProducts = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", ParametersFillInVATRate);
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
	
	SaleAdjustmentLocalization.OnCopy(ThisObject, CopiedObject);
	Author = Users.CurrentUser();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	SaleAdjustmentLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region Initialization_And_Filling

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	SaleAdjustment2_5 = True;
	
	If TypeOf(FillingData) <> Type("Structure")
		Or Not FillingData.Property("Currency") Then
		
		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		EndIf;
		
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure")
		Or Not FillingData.Property("ARAPCurrency") Then
		
		If Not ValueIsFilled(ARAPCurrency) Then
			ARAPCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		EndIf;
		
	EndIf;
	
	If Not GetFunctionalOption("UseDeedsOfTransfer")
		Or Not ValueIsFilled(SaleRegistrationOption) Then
		
		SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoice;
		
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
		
		ReferenceDocumentDateForCertificate = Common.ObjectAttributeValue(FillingData.DocumentBasis, "Date");
		DocumentDate = ?(ValueIsFilled(Date), Date, CurrentSessionDate());

		DateOfCourse = ReferenceDocumentDateForCertificate;
		
		If BegOfYear(DocumentDate) > BegOfYear(ReferenceDocumentDateForCertificate) Then
			RecordInProfitLossOfPreviousYears = True;
		EndIf;
		
	Else
		DateOfCourse = CurrentSessionDate();
	EndIf;
	
	If Not ValueIsFilled(BusinessOperation)
		And TypeOf(FillingData) = Type("Structure") And FillingData.Property("DocumentBasis") Then
		
		BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
		
		If TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.CustomerInvoice")
			And FillingData.Property("EconomicOperationOfFoundation")
			And FillingData.EconomicOperationOfFoundation =
				Enums.BusinessTransactions.TransferOfTitleToGoods Then
			
			BusinessOperation = FillingData.EconomicOperationOfFoundation;
		ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
			BusinessOperation = Common.ObjectAttributeValue(FillingData.DocumentBasis, "BusinessOperation");
		EndIf;
		
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
	
	If TypeOf(FillingData) = Type("Structure") 
		And FillingData.Property("EconomicOperationOfFoundation")
		And ConsignmentSalesServer.SalesViaCommissionAgent(FillingData.EconomicOperationOfFoundation) Then
		ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, Currency, ARAPCurrency, Organization, DateOfCourse, FillingData.CustomerContract);
	Else
		ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, Currency, ARAPCurrency, Organization, DateOfCourse, Contract);
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure")
			And CommonClientServer.HasAttributeOrObjectProperty(FillingData, "DocumentBasis") Then
		BasisOfFillingData = FillingData.DocumentBasis;
	ElsIf Common.IsReference(TypeOf(FillingData)) Then
		BasisOfFillingData = FillingData;
	Else
		BasisOfFillingData = Undefined;
	EndIf;
	ResponsiblePersonsServer.InstallManager(ThisObject, BasisOfFillingData);
	
EndProcedure

Procedure ServicesForSaleOfGoodsServices(Val DocumentBasis, FillingData, DesignParameters = Undefined)
	
	MetadataDocumentBase = DocumentBasis.Metadata();
	
	If Not AccessRight("Update", MetadataDocumentBase) Then
		ErrorText = NStr("vi = 'Ở người sử dụng không đủ quyền điều chỉnh chứng từ ""';
						|ru = 'У пользователя недостаточно прав на корректировку документа ""';
						|en = 'User is not authorized to adjust document ""'; fa = 'User is not authorized to adjust document ""';
						|it = 'Utente non ha i diritti sufficienti per eseguire la rettifica del documento ""';
						|pl = 'Użytkownik ma niewystarczające uprawnienia na zapis korygujący dokumentu ""';
						|tr = 'Kullanıcının "" "" belgesini düzeltmek için yeterli hakkı yok'")
						+ MetadataDocumentBase.Synonym + """.";
		
		Raise ErrorText;
	EndIf;
	
	EnterOnBasisOfUnverified = False;
	If Not DesignParameters = Undefined
		And TypeOf(DesignParameters) = Type("Structure") Then
		
		DesignParameters.Property("EnterOnBasisOfUnverified", EnterOnBasisOfUnverified);
		EnterOnBasisOfUnverified = ?(EnterOnBasisOfUnverified = Undefined, False, EnterOnBasisOfUnverified);
		
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("DocumentBasis", DocumentBasis);
	
	If Not ValueIsFilled(DocumentBasis) Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	DocumentData.Ref						   AS DocumentBasis,
	|	DocumentData.Partner						   AS Partner,
	|	DocumentData.Counterparty					   AS Counterparty,
	|	DocumentData.Terms					   AS Terms,
	|	DocumentData.PaymentSchedule				   AS PaymentSchedule,
	|	DocumentData.Organization					   AS Organization,
	|	DocumentData.Contract						   AS Contract,
	|	DocumentData.Warehouse						   AS Warehouse,
	|	DocumentData.Status						   AS Status,
	|	DocumentData.Currency						   AS Currency,
	|	DocumentData.ARAPCurrency		   AS ARAPCurrency,
	|	DocumentData.VATTaxation			   AS VATTaxation,
	|	DocumentData.Department				   AS Department,
	|	DocumentData.LineOfBusiness		   AS LineOfBusiness,
	|	DocumentData.SalesOpportunity						   AS SalesOpportunity,
	|	DocumentData.PriceIncludesVAT				   AS PriceIncludesVAT,
	|	DocumentData.OrderSales			   AS SaleByOrders,
	|	DocumentData.IssuiedBy					   AS IssuiedBy,
	|	DocumentData.IssuiedByJobTitle			   AS IssuiedByJobTitle,
	|	DocumentData.GoodsRecipient				   AS GoodsRecipient,
	|	DocumentData.Shipper			   AS Shipper,
	|	DocumentData.CompanyBankAccount	   AS CompanyBankAccount,
	|	DocumentData.CounterpartyBankAccount	   AS CounterpartyBankAccount,
	|	DocumentData.ShipperBankAccount AS ShipperBankAccount,
	|	DocumentData.GoodsRecipientBankAccount  AS GoodsRecipientBankAccount,
	|	DocumentData.DeliveryAddress 				   AS DeliveryAddress,
	|	DocumentData.PowerOfAttorneyNumber			   AS PowerOfAttorneyNumber,
	|	DocumentData.PowerOfAttorneyDate			   AS PowerOfAttorneyDate,
	|	DocumentData.LetterOfAuthorityIssuedBy			   AS LetterOfAuthorityIssuedBy,
	|	DocumentData.PowerOfAttorneyPerson			   AS PowerOfAttorneyPerson,
	|	DocumentData.PaymentMethod					   AS PaymentMethod,
	|	DocumentData.ARAPObjectSettings				   AS ARAPObjectSettings,
	|	DocumentData.SaleRegistrationOption       AS SaleRegistrationOption,
	|	DocumentData.Basis	 			       AS Basis,
	|	DocumentData.ReferenceDocumentDateForPrintForms	 			   AS ReferenceDocumentDateForPrintForms,
	|	DocumentData.BaseDocumentNumber				   AS BaseDocumentNumber,
	|	DocumentData.CustomerCounterparty			   AS CustomerCounterparty,
	|	DocumentData.CustomerPartner				   AS CustomerPartner,
	|	DocumentData.CustomerContract				   AS CustomerContract,
	|	DocumentData.UISStateContractStep			   AS UISStateContractStep,
	|	
	|	NOT DocumentData.Posted
	|		AND NOT &EnterOnBasisOfUnverified AS ThereAreErrorsPosted,
	|	
	|	CASE WHEN DocumentData.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped) THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS ThereAreErrorsStatus,
	|	
	|	CASE WHEN DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.SaleToCustomer),
	|		VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|		VALUE(Enum.BusinessTransactions.SalesViaCommissionAgent),
	|		VALUE(Enum.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit),
	|		VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
	|	THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS ThereAreErrorsOperation,
	|	
	|	DocumentData.BusinessOperation AS EconomicOperationOfFoundation
	|
	|FROM
	|	Document.CustomerInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentBasis
	|");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("EnterOnBasisOfUnverified", EnterOnBasisOfUnverified);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập điều chỉnh bán hàng trên cơ sở chứng từ %1.';
				|ru = 'Не требуется вводить корректировку реализации на основании документа %1.';
				|en = 'Generating sales adjustment from base document %1 is not required.'; fa = 'Generating sales adjustment from base document %1 is not required.';
				|it = 'Non è necessario immettere la rettifica per realizzo in base al documento %1.';
				|pl = 'Nie wymaga się wprowadzać zapis korygujący realizacji na podstawie dokumentu %1.';
				|tr = '%1belgesine dayalı bir satış düzeltmesi girilmesine gerek yoktur.'"),
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
			NStr("vi = 'Để bán hàng với giao dịch ""%1"" không cần nhập điều chỉnh.';
				|ru = 'Для реализации с операцией ""%1"" не требуется вводить корректировку.';
				|en = 'No need to enter a sales adjustment for transaction ""%1"".'; fa = 'No need to enter a sales adjustment for transaction ""%1"".';
				|it = 'Non è necessario immettere la rettifica per il realizzo con operazione ""%1"".';
				|pl = 'Dla realizacji z operacja ""%1"" nie jest wymagane wprowadzenia zapisu korygującego.';
				|tr = '""%1"" işlemine sahip satışlar bir düzeltme girilmesini gerektirmez.'"),
			Selection.EconomicOperationOfFoundation);
		Raise Text;
	EndIf;
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfCustomerInvoices.Shipped);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.DocumentBasis,
		Selection.Status,
		Selection.ThereAreErrorsPosted,
		Selection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(FillingData, Selection);
	FillPropertyValues(ThisObject, Selection,
		"Organization, Partner, Counterparty, Warehouse, Currency, ARAPCurrency, SaleRegistrationOption, UISStateContractStep,
		|Basis, ReferenceDocumentDateForPrintForms, BaseDocumentNumber, Terms, Contract");
	
	Documents.SaleAdjustment.FillInProductsBasedOnSourceData(Selection.DocumentBasis, Goods, Discrepancies);
	
	// Filling in the series indication statuses
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SaleAdjustment);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.Goods);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.Discrepancies);
	
EndProcedure

Procedure FillInActOfWorkPerformed(Val DocumentBasis, FillingData)
	
	MetadataDocumentBase = DocumentBasis.Metadata();
	
	If Not AccessRight("Update", MetadataDocumentBase) Then
		ErrorText = NStr("vi = 'Ở người sử dụng không đủ quyền điều chỉnh chứng từ ""';
						|ru = 'У пользователя недостаточно прав на корректировку документа ""';
						|en = 'User is not authorized to adjust document ""'; fa = 'User is not authorized to adjust document ""';
						|it = 'Utente non ha i diritti sufficienti per eseguire la rettifica del documento ""';
						|pl = 'Użytkownik ma niewystarczające uprawnienia na zapis korygujący dokumentu ""';
						|tr = 'Kullanıcının "" "" belgesini düzeltmek için yeterli hakkı yok'")
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
	|	DocumentData.Ref					AS DocumentBasis,
	|	DocumentData.Partner					AS Partner,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentData.Terms				AS Terms,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.PaymentSchedule			AS PaymentSchedule,
	|	DocumentData.Organization				AS Organization,
	|	DocumentData.Contract					AS Contract,
	|	DocumentData.Currency					AS Currency,
	|	DocumentData.ARAPCurrency	AS ARAPCurrency,
	|	DocumentData.VATTaxation		AS VATTaxation,
	|	DocumentData.Department			AS Department,
	|	DocumentData.SalesOpportunity					AS SalesOpportunity,
	|	DocumentData.PriceIncludesVAT			AS PriceIncludesVAT,
	|	DocumentData.InvoiceByOrders			AS SaleByOrders,
	|	DocumentData.PaymentMethod				AS PaymentMethod,
	|	DocumentData.ARAPObjectSettings			AS ARAPObjectSettings,
	|	DocumentData.UISStateContractStep		AS UISStateContractStep,
	|	NOT DocumentData.Posted				AS ThereAreErrorsPosted,
	|	DocumentData.Basis				AS Basis,
	|	DocumentData.ReferenceDocumentDateForPrintForms 			AS ReferenceDocumentDateForPrintForms,
	|	DocumentData.BaseDocumentNumber			AS BaseDocumentNumber
	|
	|FROM
	|	Document.CustomerInvoiceServices AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentBasis
	|");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	QueryResult = Query.Execute();
	
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
	FillPropertyValues(ThisObject, Selection, "Organization, Counterparty, Partner, Currency, ARAPCurrency, UISStateContractStep, Terms, Contract, Basis, ReferenceDocumentDateForPrintForms, BaseDocumentNumber");
	
	FillingData.Insert("PaymentDate", SalesServer.GetLatestDateOnSchedule(CurrentSessionDate(), Selection.PaymentSchedule, Selection.Terms));
	
	Documents.SaleAdjustment.FillInProductsBasedOnSourceData(Selection.DocumentBasis, Goods, Discrepancies);
	
EndProcedure

Procedure FillInCertificateOfDiscrepanciesAfterShipment(Val ParametersStructure, FillingData)
	
	DocumentaryImplementation			= ParametersStructure.SaleOfGoodsAndServices;
	DocumentActOnDiscrepancies	= ParametersStructure.DiscrepancyCertificate;
	AdjustmentKind					= ParametersStructure.Operation;
	
	MetadataDocumentBase = DocumentaryImplementation.Metadata();
	If Not AccessRight("Update", MetadataDocumentBase) Then
		ErrorText = NStr("vi = 'Ở người sử dụng không đủ quyền điều chỉnh chứng từ ""';
						|ru = 'У пользователя недостаточно прав на корректировку документа ""';
						|en = 'User is not authorized to adjust document ""'; fa = 'User is not authorized to adjust document ""';
						|it = 'Utente non ha i diritti sufficienti per eseguire la rettifica del documento ""';
						|pl = 'Użytkownik ma niewystarczające uprawnienia na zapis korygujący dokumentu ""';
						|tr = 'Kullanıcının "" "" belgesini düzeltmek için yeterli hakkı yok'")
			+ MetadataDocumentBase.Synonym + """.";
		Raise ErrorText;
	EndIf;
	
	If Not ValueIsFilled(DocumentaryImplementation)
		Or Not ValueIsFilled(DocumentActOnDiscrepancies) Then
		
		Return;
		
	EndIf;
	
	ThisIsReturnToPath = CommonClientServer.StructureProperty(ParametersStructure, "ThisIsReturnToPath", False);
	
	FillingData = New Structure;
	FillingData.Insert("DocumentBasis", DocumentaryImplementation);
	FillingData.Insert("ThisIsReturnToPath", ThisIsReturnToPath);
	
	Query = New Query("
	|SELECT
	|	DocumentData.Ref AS DocumentBasis,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.Terms.PaymentSchedule AS PaymentSchedule,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Warehouse AS Warehouse,
	|	DocumentData.Status AS Status,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Department AS Department,
	|	DocumentData.SalesOpportunity AS SalesOpportunity,
	|	DocumentData.PriceIncludesVAT AS PriceIncludesVAT,
	|	DocumentData.OrderSales AS SaleByOrders,
	|	DocumentData.IssuiedBy AS IssuiedBy,
	|	DocumentData.IssuiedByJobTitle AS IssuiedByJobTitle,
	|	DocumentData.GoodsRecipient AS GoodsRecipient,
	|	DocumentData.Shipper AS Shipper,
	|	DocumentData.CompanyBankAccount AS CompanyBankAccount,
	|	DocumentData.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	DocumentData.ShipperBankAccount AS ShipperBankAccount,
	|	DocumentData.GoodsRecipientBankAccount AS GoodsRecipientBankAccount,
	|	DocumentData.DeliveryAddress AS DeliveryAddress,
	|	DocumentData.PowerOfAttorneyNumber AS PowerOfAttorneyNumber,
	|	DocumentData.PowerOfAttorneyDate AS PowerOfAttorneyDate,
	|	DocumentData.LetterOfAuthorityIssuedBy AS LetterOfAuthorityIssuedBy,
	|	DocumentData.PowerOfAttorneyPerson AS PowerOfAttorneyPerson,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.PaymentMethod AS PaymentMethod,
	|	NOT DocumentData.Posted AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN DocumentData.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsStatus,
	|	CASE WHEN DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.SaleToCustomer),
	|		VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
	|		VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods))
	|	THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS ThereAreErrorsOperation,
	|	DocumentData.BusinessOperation AS EconomicOperationOfFoundation,
	|	DiscrepancyReportFollowingShipment.DiscrepanciesPostingMethod AS DiscrepanciesPostingMethod,
	|	DiscrepancyReportFollowingShipment.Ref AS DiscrepancyReportFollowingShipmentBaseDocument,
	|	CASE
	|		WHEN DiscrepancyReportFollowingShipment.Status IN (VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion), VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsStatusActDiscrepancies,
	|	NOT DiscrepancyReportFollowingShipment.Posted AS ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
	|	DiscrepancyReportFollowingShipment.Status AS StatusActOfDivergence
	|FROM
	|	Document.CustomerInvoice AS DocumentData
	|		INNER JOIN Document.DiscrepancyReportFollowingShipment AS DiscrepancyReportFollowingShipment
	|		ON (TRUE)
	|WHERE
	|	DocumentData.Ref = &DocumentBasis
	|	AND DiscrepancyReportFollowingShipment.Ref = &DiscrepancyReportFollowingShipmentBaseDocument");
	
	Query.SetParameter("DocumentBasis", DocumentaryImplementation);
	Query.SetParameter("DiscrepancyReportFollowingShipmentBaseDocument", DocumentActOnDiscrepancies);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không cần nhập điều chỉnh bán hàng trên cơ sở chứng từ %1.';
						|ru = 'Не требуется вводить корректировку реализации на основании документа %1.';
						|en = 'Generating sales adjustment from base document %1 is not required.'; fa = 'Generating sales adjustment from base document %1 is not required.';
						|it = 'Non è necessario immettere la rettifica per realizzo in base al documento %1.';
						|pl = 'Nie wymaga się wprowadzać zapis korygujący realizacji na podstawie dokumentu %1.';
						|tr = '%1belgesine dayalı bir satış düzeltmesi girilmesine gerek yoktur.'"),
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
			NStr("vi = 'Để bán hàng với giao dịch ""%1"" không cần nhập điều chỉnh.';
				|ru = 'Для реализации с операцией ""%1"" не требуется вводить корректировку.';
				|en = 'No need to enter a sales adjustment for transaction ""%1"".'; fa = 'No need to enter a sales adjustment for transaction ""%1"".';
				|it = 'Non è necessario immettere la rettifica per il realizzo con operazione ""%1"".';
				|pl = 'Dla realizacji z operacja ""%1"" nie jest wymagane wprowadzenia zapisu korygującego.';
				|tr = '""%1"" işlemine sahip satışlar bir düzeltme girilmesini gerektirmez.'"),
			Selection.EconomicOperationOfFoundation);
		Raise Text;
	EndIf;
	
	If Selection.DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments
		And Selection.EconomicOperationOfFoundation <> Enums.BusinessTransactions.TransferOfTitleToGoods
		Then
		
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
	
	If Selection.EconomicOperationOfFoundation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		AdditionalProperties.Insert("EconomicOperationOfFoundation", Selection.EconomicOperationOfFoundation);
	EndIf;
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfDiscrepancyReport.ForCompletion);
	ArrayOfValidStatuses.Add(Enums.StatusesOfDiscrepancyReport.Processed_);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.DiscrepancyReportFollowingShipmentBaseDocument,
		Selection.StatusActOfDivergence,
		Selection.ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
		Selection.ThereAreErrorsStatusActDiscrepancies,
		ArrayOfValidStatuses);
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfCustomerInvoices.Shipped);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.DocumentBasis,
		Selection.Status,
		Selection.ThereAreErrorsPosted,
		Selection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(FillingData, Selection);
	FillPropertyValues(ThisObject, Selection, 
		"Organization, Counterparty, Partner, Warehouse, Currency, ARAPCurrency, 
		|DocumentBasis, DiscrepancyReportFollowingShipmentBaseDocument, PriceIncludesVAT, VATTaxation, Terms, Contract");
	
	FillingData.Insert("PaymentDate", SalesServer.GetLatestDateOnSchedule(CurrentSessionDate(), Selection.PaymentSchedule, Selection.Terms));
	
	Documents.SaleAdjustment.FillInGoodsAccordingToAcceptanceCertificate(ThisObject, ThisIsReturnToPath);
	
	// Filling in the series indication statuses
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SaleAdjustment);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.Goods);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.Discrepancies);
	
EndProcedure

Procedure ActivitiesForSaleOfServicesOfOtherAssets(Val DocumentBasis, FillingData)
	
	MetadataDocumentBase = DocumentBasis.Metadata();
	
	If Not AccessRight("Update", MetadataDocumentBase) Then
		ErrorText = NStr("vi = 'Ở người sử dụng không đủ quyền điều chỉnh chứng từ ""';
						|ru = 'У пользователя недостаточно прав на корректировку документа ""';
						|en = 'User is not authorized to adjust document ""'; fa = 'User is not authorized to adjust document ""';
						|it = 'Utente non ha i diritti sufficienti per eseguire la rettifica del documento ""';
						|pl = 'Użytkownik ma niewystarczające uprawnienia na zapis korygujący dokumentu ""';
						|tr = 'Kullanıcının "" "" belgesini düzeltmek için yeterli hakkı yok'")
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
	|	DocumentData.Ref					AS DocumentBasis,
	|	DocumentData.Partner					AS Partner,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentData.Terms				AS Terms,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.PaymentSchedule			AS PaymentSchedule,
	|	DocumentData.Organization				AS Organization,
	|	DocumentData.Contract					AS Contract,
	|	DocumentData.Currency					AS Currency,
	|	DocumentData.ARAPCurrency	AS ARAPCurrency,
	|	DocumentData.VATTaxation		AS VATTaxation,
	|	DocumentData.Department			AS Department,
	|	DocumentData.PriceIncludesVAT			AS PriceIncludesVAT,
	|	FALSE									AS SaleByOrders,
	|	DocumentData.PaymentMethod				AS PaymentMethod,
	|	DocumentData.ARAPObjectSettings			AS ARAPObjectSettings,
	|
	|	DocumentData.Basis				AS Basis,
	|	DocumentData.ReferenceDocumentDateForPrintForms			AS ReferenceDocumentDateForPrintForms,
	|	DocumentData.BaseDocumentNumber			AS BaseDocumentNumber,
	|
	|	NOT DocumentData.Posted				AS ThereAreErrorsPosted,
	|	
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer) THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS ThereAreErrorsOperation,
	|	
	|	DocumentData.BusinessOperation AS EconomicOperationOfFoundation
	|
	|FROM
	|	Document.CustomerInvoiceServicesAndAssets AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentBasis
	|");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không cần nhập điều chỉnh bán hàng trên cơ sở chứng từ %1.';
						|ru = 'Не требуется вводить корректировку реализации на основании документа %1.';
						|en = 'Generating sales adjustment from base document %1 is not required.'; fa = 'Generating sales adjustment from base document %1 is not required.';
						|it = 'Non è necessario immettere la rettifica per realizzo in base al documento %1.';
						|pl = 'Nie wymaga się wprowadzać zapis korygujący realizacji na podstawie dokumentu %1.';
						|tr = '%1belgesine dayalı bir satış düzeltmesi girilmesine gerek yoktur.'"),
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
			NStr("vi = 'Để bán hàng với giao dịch ""%1"" không cần nhập điều chỉnh.';
				|ru = 'Для реализации с операцией ""%1"" не требуется вводить корректировку.';
				|en = 'No need to enter a sales adjustment for transaction ""%1"".'; fa = 'No need to enter a sales adjustment for transaction ""%1"".';
				|it = 'Non è necessario immettere la rettifica per il realizzo con operazione ""%1"".';
				|pl = 'Dla realizacji z operacja ""%1"" nie jest wymagane wprowadzenia zapisu korygującego.';
				|tr = '""%1"" işlemine sahip satışlar bir düzeltme girilmesini gerektirmez.'"),
			Selection.EconomicOperationOfFoundation);
		Raise Text;
	EndIf;
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.DocumentBasis,
		, // Status
		Selection.ThereAreErrorsPosted);
	
	FillPropertyValues(FillingData, Selection);
	FillPropertyValues(ThisObject, Selection, 
		"Organization, Counterparty, Partner, Currency, ARAPCurrency, Basis, ReferenceDocumentDateForPrintForms, BaseDocumentNumber, Terms, Contract");
	
	FillingData.Insert("PaymentDate", SalesServer.GetLatestDateOnSchedule(CurrentSessionDate(), Selection.PaymentSchedule, Selection.Terms));
	
	Documents.SaleAdjustment.FillInProductsBasedOnSourceData(Selection.DocumentBasis, Goods, Discrepancies);
	
EndProcedure

Procedure FillInPrimaryDocument(Val DocumentBasis, FillingData)
	
	MetadataDocumentBase = DocumentBasis.Metadata();
	
	If Not AccessRight("Read", MetadataDocumentBase) Then
		ErrorText = NStr("vi = 'Người sử dụng không đủ quyền điều chỉnh chứng từ ""';
						|ru = 'У пользователя недостаточно прав на корректировку документа ""';
						|en = 'User is not authorized to adjust document ""'; fa = 'User is not authorized to adjust document ""';
						|it = 'Utente non ha i diritti sufficienti per eseguire la rettifica del documento ""';
						|pl = 'Użytkownik ma niewystarczające uprawnienia na zapis korygujący dokumentu ""';
						|tr = 'Kullanıcının "" "" belgesini düzeltmek için yeterli hakkı yok'")
						+ MetadataDocumentBase.Synonym + """.";
		
		Raise ErrorText;
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("DocumentBasis", DocumentBasis);
	
	If Not ValueIsFilled(DocumentBasis) Then
		Return;
	EndIf;
	
	QueryTextTheseGrounds = 
	"SELECT
	|	DocumentData.Ref					AS DocumentBasis,
	|	DocumentData.Partner					AS Partner,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentData.LineOfBusiness	AS LineOfBusiness,
	|	DocumentData.Organization				AS Organization,
	|	DocumentData.Contract					AS Contract,
	|	DocumentData.Currency					AS Currency,
	|	DocumentData.ARAPCurrency	AS ARAPCurrency,
	|	DocumentData.VATTaxation		AS VATTaxation,
	|	DocumentData.Department			AS Department,
	|	DocumentData.ARAPObjectSettings			AS ARAPObjectSettings,
	|	NOT DocumentData.Posted				AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN DocumentData.SourceDocumentType = VALUE(Enum.SourceDocumentTypes.SaleToCustomer)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsOperation,
	|	DocumentData.SourceDocumentType	AS EconomicOperationOfFoundation,
	|	ISNULL(PreviousDocument.AdjustingEntryType, 
	|		&AdjustingEntryType)AS AdjustingEntryType,
	|	ISNULL(PreviousDocument.Ref.Terms, VALUE(Catalog.TermsOfSale.EmptyRef)) AS Terms,
	|	ISNULL(PreviousDocument.Ref.Warehouse, VALUE(Catalog.Warehouses.EmptyRef)) AS Warehouse
	|FROM
	|	Document.SourceDocument AS DocumentData
	|	LEFT JOIN 
	|		TTPreviousAdjustment AS PreviousDocument 
	|		ON TRUE
	|WHERE
	|	DocumentData.Ref = &DocumentBasis";
	
	QueryTexts = New Array;
	QueryTexts.Add(Documents.SaleAdjustment.QueryTextTTPreviousAdjustmentData());
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
					NStr("vi = 'Không cần nhập điều chỉnh bán hàng trên cơ sở chứng từ %1.';
						|ru = 'Не требуется вводить корректировку реализации на основании документа %1.';
						|en = 'Generating sales adjustment from base document %1 is not required.'; fa = 'Generating sales adjustment from base document %1 is not required.';
						|it = 'Non è necessario immettere la rettifica per realizzo in base al documento %1.';
						|pl = 'Nie wymaga się wprowadzać zapis korygujący realizacji na podstawie dokumentu %1.';
						|tr = '%1belgesine dayalı bir satış düzeltmesi girilmesine gerek yoktur.'"),
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
					NStr("vi = 'Đối với chứng từ gốc có kiểu ""%1"" không cần nhập điều chỉnh.';
						|ru = 'Для первичного документа с типом ""%1"" не требуется вводить корректировку.';
						|en = 'Do not enter adjustment for the %1 source document type.'; fa = 'Do not enter adjustment for the %1 source document type.';
						|it = 'Per il documento primario con tipo ""%1"" non è richiesto l''inserimento della correzione.';
						|pl = 'Dla dokumentu źródłowego z typem ""%1"" nie jest wymagane wprowadzenie korekty.';
						|tr = 'Türü ""%1"" olan bir birincil belge için bir düzeltme girmeye gerek yoktur.'"),
					Selection.EconomicOperationOfFoundation);
		
		Raise Text;
	EndIf;
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.DocumentBasis,
		Undefined,
		Selection.ThereAreErrorsPosted);
	
	FillPropertyValues(FillingData, Selection);
	FillPropertyValues(ThisObject, Selection);
	
	BaseStructure = Documents.SaleAdjustment.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, BaseStructure);
	
	Documents.SaleAdjustment.FillInProductsBasedOnSourceData(Selection.DocumentBasis, Goods, Discrepancies);

	// Filling in the series indication statuses
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SaleAdjustment);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.Goods);
	
EndProcedure

Procedure FillInReportToGiver(Val DocumentBasis, FillingData)
	
	MetadataDocumentBase = DocumentBasis.Metadata();
	
	If Not AccessRight("Update", MetadataDocumentBase) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Người sử dụng không đủ quyền chỉnh sửa chứng từ ""%1""';
							|ru = 'У пользователя недостаточно прав на корректировку документа ""%1""';
							|en = 'User is not authorized to adjust document ""%1""'; fa = 'User is not authorized to adjust document ""%1""';
							|it = 'L''utente non ha sufficienti diritti per rettificare il documento ""%1""';
							|pl = 'Użytkownik nie ma wystarczających praw do korekty dokumentu ""%1""';
							|tr = 'Kullanıcının ""%1"" belgesini düzeltmek için yeterli hakkı yok'"),
						MetadataDocumentBase.Synonym);
		
		Raise ErrorText;
	EndIf;
	
	FillingData = New Structure;
	FillingData.Insert("DocumentBasis", DocumentBasis);
	
	If Not ValueIsFilled(DocumentBasis) Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	DocumentData.Ref					AS DocumentBasis,
	|	DocumentData.Warehouse					AS Warehouse,
	|	DocumentData.Partner					AS Partner,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentData.LineOfBusiness	AS LineOfBusiness,
	|	DocumentData.Organization				AS Organization,
	|	DocumentData.Contract					AS Contract,
	|	DocumentData.SalesOpportunity					AS SalesOpportunity,
	|	DocumentData.Currency					AS Currency,
	|	DocumentData.ARAPCurrency	AS ARAPCurrency,
	|	DocumentData.VATTaxation		AS VATTaxation,
	|	DocumentData.Department			AS Department,
	|	DocumentData.PriceIncludesVAT			AS PriceIncludesVAT,
	|	DocumentData.ReportOnOrders			AS SaleByOrders,
	|	DocumentData.PaymentMethod				AS PaymentMethod,
	|	DocumentData.ARAPObjectSettings			AS ARAPObjectSettings,
	|	DocumentData.PaymentSchedule			AS PaymentSchedule,
	|
	|	NOT DocumentData.Posted				AS ThereAreErrorsPosted,
	|	DocumentData.BusinessOperation	AS BusinessOperation
	|
	|FROM
	|	Document.ReportToMaterialProvider2_5 AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentBasis
	|");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Không cần nhập điều chỉnh bán hàng trên cơ sở chứng từ %1.';
						|ru = 'Не требуется вводить корректировку реализации на основании документа %1.';
						|en = 'Generating sales adjustment from base document %1 is not required.'; fa = 'Generating sales adjustment from base document %1 is not required.';
						|it = 'Non è necessario immettere la rettifica per realizzo in base al documento %1.';
						|pl = 'Nie wymaga się wprowadzać zapis korygujący realizacji na podstawie dokumentu %1.';
						|tr = '%1belgesine dayalı bir satış düzeltmesi girilmesine gerek yoktur.'"),
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
	FillPropertyValues(ThisObject, Selection);
	Documents.SaleAdjustment.FillInProductsBasedOnSourceData(Selection.DocumentBasis, Goods, Discrepancies);
	
EndProcedure

Procedure SetLineCodeInRowsOfTablePart()
	
	// For TS lines that differ from the Reflection Option = Return to the path, fill in the line code. Since
	// Receipt of goods from the client will be created according to these lines
	SearchParameters = New Structure;
	SearchParameters.Insert("PostingOption", Enums.CreditNoteRecordingOptions.ReturnToTransit);
	SearchParameters.Insert("RowCode", 0);
	
	StringsWithoutKey = Discrepancies.FindRows(SearchParameters);
	CurrentCode = MaximumRowCode;
	
	For Each TSRow In StringsWithoutKey Do
		CurrentCode = CurrentCode + 1;
		TSRow.RowCode = CurrentCode;
	EndDo;
	
	MaximumRowCode = CurrentCode;
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	If AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets
		Or TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		InventoryOwnerAttributesRevenueAdjustment.Clear();
		InventoryOwnerAttributesGoodsReceipt.Clear();
		InventoryOwnerAttributesConsumption.Clear();
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	PickUpExcisableItems	= False;
	ReferenceDocumentDateForCertificate				= BaseDocumentDate();
	PickUpExcisableItems = GetFunctionalOption("UseExcisableGoods")
									And BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
	If PickUpExcisableItems Then
		ExciseAccrualPeriod = ReferenceDocumentDateForCertificate;
	EndIf;
	AdditionalProperties.Insert("WriteDownAmountOfExciseTax", False);
	// Types of inventory to be registered
	If AdjustmentKind = Enums.BusinessTransactions.SaleOfOverdeliveredGoods
		Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated
		Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
		
		InventoryOwnerAttributesGoodsReceipt.Clear();
		
	Else
		
		UseShipmentWithDeferredTransferOfTitle2_5 =
			TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice")
			And GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5")
			And (BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
				Or BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods);
		
		ThereAreWriteOffLines = False;
		
		If PickUpExcisableItems Then
			RowFilter = New Structure("PostingOption",
										Enums.CreditNoteRecordingOptions.ToExpenseAs);
			ThereAreWriteOffLines = Discrepancies.FindRows(RowFilter).Count() > 0;
			
			ArrayOfReflectionOptions = New Array;
			ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.ToExpenseAs);
			
			TempTablesManager = TemporaryDataTablesOfDocumentRegistration(ArrayOfReflectionOptions, False);
			If Not Posted
				Or RefillInventoryKinds
				Or CheckChangesToDocumentDetails(TempTablesManager)
				Or CheckChangesToProductsRegistration(TempTablesManager) Then
				
				AdditionalProperties.Insert("WriteDownAmountOfExciseTax", True);
				
				RowFilter = New Structure("ToIncomeExpenses", False);
				TypesOfReturnStocks = InventoryOwnerAttributesGoodsReceipt.Unload(RowFilter);
				
				If AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices Then
					InventoryOwnerAttributesGoodsReceipt.Clear();
					
					TableTypesOfStocksRegistration = TableToFillInInventoryOwnerAttributes(TempTablesManager);
					
					If TableTypesOfStocksRegistration.Count() > 0 Then
						InventoriesServer.FillStockTypesByDefault(TempTablesManager, TableTypesOfStocksRegistration);
						FillInAdditionalColumnsOfInventoryTypes(TableTypesOfStocksRegistration, ArrayOfReflectionOptions);
					EndIf;
				Else
					FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
					FillParameters.NameOfRemainderTable = "SoldGoods";
					FillParameters.NameTSTypesOfStocks = "InventoryOwnerAttributesGoodsReceipt";
					FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
					FillParameters.WithoutSelectionByCCDNumbers = True;
					FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
					If BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
						Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
						Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
						Or BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
						Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
						FillParameters.SelectionOfStockTypes_.InventoryType.Clear();
						FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
					EndIf;
					InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																			TempTablesManager,
																			Cancel,
																			FillParameters);
					
					NamesOfGroupingColumns		= "ItemsLocationAttributes, InventoryOwnerAttribute, CorInventoryOwnerAttribute, CCDNumber, Warehouse,
													|OriginWarehouse, InventoryOwnerAttributeShipment, VATRate, PartnerProducts,
													|CostDefiningMethod";
					NamesOfSummationColumns	= "Count, QuantityByGBRN, AmountIncludingVAT, VATAmount,
													|Cost_, CostExcludingVAT_, CostLocal, ExciseTaxAmount,
													|CDCost, TDCost";
					
					InventoryOwnerAttributesGoodsReceipt.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
					
					FillInAdditionalStockTypes(InventoryOwnerAttributesGoodsReceipt, ArrayOfReflectionOptions, True, True);
				EndIf;
				
				TMCommonUse.AddRowsToTable(InventoryOwnerAttributesGoodsReceipt, TypesOfReturnStocks);
			EndIf;
		EndIf;
		ArrayOfReflectionOptions = New Array;
		ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.ReduceSale);
		ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount);
		ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock);
		If Not PickUpExcisableItems Then
			ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.ToExpenseAs);
		EndIf;
		ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.ReturnToTransit);
		
		TempTablesManager = TemporaryDataTablesOfDocumentRegistration(ArrayOfReflectionOptions,
																				UseShipmentWithDeferredTransferOfTitle2_5);
		
		If Not Posted
			Or RefillInventoryKinds
			Or CheckChangesToDocumentDetails(TempTablesManager)
			Or CheckChangesToProductsRegistration(TempTablesManager) Then
			
			If ThereAreWriteOffLines Then
				RowFilter = New Structure("ToIncomeExpenses", True);
				TypesOfInventoryOwnersAttributesOfWriteOffLines = InventoryOwnerAttributesGoodsReceipt.Unload(RowFilter);
			EndIf;
			
			If AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices Then
				InventoryOwnerAttributesGoodsReceipt.Clear();
				
				TableTypesOfStocksRegistration = TableToFillInInventoryOwnerAttributes(TempTablesManager);
				
				If TableTypesOfStocksRegistration.Count() > 0 Then
					InventoriesServer.FillStockTypesByDefault(TempTablesManager, TableTypesOfStocksRegistration);
					FillInAdditionalColumnsOfInventoryTypes(TableTypesOfStocksRegistration, ArrayOfReflectionOptions);
					FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
					FillParameters.NameTSTypesOfStocks = "InventoryOwnerAttributesGoodsReceipt";
					If PickUpExcisableItems Then
						FillParameters.ExciseAccrualPeriod = ExciseAccrualPeriod;
						FillParameters.CalculateAmountOfExciseTax = True;
						ExcisableGoodsAccounting.CalculateAmountOfExciseTax(ThisObject, FillParameters, , Cancel);
					EndIf;
				EndIf;
			Else
				If ThereAreWriteOffLines Then
					InventoryOwnerAttributesGoodsReceipt.Clear();
				EndIf;
				
				FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
				FillParameters.NameOfRemainderTable = "SoldGoods";
				FillParameters.NameTSTypesOfStocks = "InventoryOwnerAttributesGoodsReceipt";
				FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
				FillParameters.CreditNoteAdjustmentAfterTransferOfOwnership = UseShipmentWithDeferredTransferOfTitle2_5;
				FillParameters.WithoutSelectionByCCDNumbers = True;
				FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
				If PickUpExcisableItems Then
					AdditionalProperties.Insert("WriteDownAmountOfExciseTax", True);
					FillParameters.ExciseAccrualPeriod = ExciseAccrualPeriod;
					FillParameters.CalculateAmountOfExciseTax = True;
					FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
				EndIf;
				If BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
					Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
					Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
					Or BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
					Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
					FillParameters.SelectionOfStockTypes_.InventoryType.Clear();
					FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
				EndIf;
				InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																		TempTablesManager,
																		Cancel,
																		FillParameters);
				ExcisableGoodsAccounting.CalculateAmountOfExciseTax(ThisObject, FillParameters, , Cancel);
				NamesOfGroupingColumns		= "ItemsLocationAttributes, InventoryOwnerAttribute, CorInventoryOwnerAttribute, CCDNumber, Warehouse,
												|OriginWarehouse, InventoryOwnerAttributeShipment, VATRate, PartnerProducts,
												|CostDefiningMethod";
				NamesOfSummationColumns	= "Count, QuantityByGBRN, AmountIncludingVAT, VATAmount,
												|Cost_, CostExcludingVAT_, CostLocal,
												|ExciseTaxAmount,
												|CDCost, TDCost, VATAmountCompl, VATAmountMan";
				
				InventoryOwnerAttributesGoodsReceipt.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
				
				FillInAdditionalStockTypes(InventoryOwnerAttributesGoodsReceipt, ArrayOfReflectionOptions, True, True);
			EndIf;
			
			If ThereAreWriteOffLines Then
				TMCommonUse.AddRowsToTable(InventoryOwnerAttributesGoodsReceipt, TypesOfInventoryOwnersAttributesOfWriteOffLines);
			EndIf;
		EndIf;
		
	EndIf;
	
	// Types of inventory to be written off
	If AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods 
		Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated
		Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
		
		InventoryOwnerAttributesConsumption.Clear();
		
	Else
		
		ArrayOfReflectionOptions = New Array;
		ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.RecordInOtherIncome);
		
		TempTablesManager = TemporaryDataTablesForWriteOffDocument(ArrayOfReflectionOptions);
		
		RowFilter = New Structure("PostingOption",
										Enums.CreditNoteRecordingOptions.RecordInOtherIncome);
		TableOfDiscrepancies = Discrepancies.Unload(RowFilter);
		TableOfDiscrepancies.Columns.Add("InventoryOwnerAttribute", New TypeDescription("CatalogRef.InventoryKinds"));
		
		If TableOfDiscrepancies.Count() > 0 Then
			InventoriesServer.FillStockTypesByDefault(TempTablesManager, TableOfDiscrepancies);
		EndIf;
		
		ChangedGoodsToReflectOnOtherIncome = False;
		
		If CheckChangesInGoodsReflectOnOtherIncome(TempTablesManager) Then
			ChangedGoodsToReflectOnOtherIncome = True;
		EndIf;
		
		ArrayOfReflectionOptions = New Array;
		ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.IncreaseSale);
		ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount);
		ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock);
		
		TempTablesManager = TemporaryDataTablesForWriteOffDocument(ArrayOfReflectionOptions);
		
		ChangedDocumentDetails = CheckChangesToDocumentDetails(TempTablesManager);
		
		If Not Posted
			Or RefillInventoryKinds
			Or ChangedDocumentDetails
			Or ChangedGoodsToReflectOnOtherIncome
			Or CheckChangesInItemsDebited(TempTablesManager) Then
			
			FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
			FillParameters.NameTSTypesOfStocks = "InventoryOwnerAttributesConsumption";
			FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
			FillParameters.WithoutSelectionByCCDNumbers = True;
			FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
			FillParameters.ThereIsTableOfInventoryTypes = True;
			FillParameters.NameOfInventoryTypeTable = "TTInventoryTypesRegistration";
			If BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
				Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
				Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
				Or BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
				Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
				FillParameters.SelectionOfStockTypes_.InventoryType.Clear();
				FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
			Else
				FillParameters.PeriodOfFoundationDocument = ReferenceDocumentDateForCertificate;
				FillParameters.SelectionOfStockTypes_.VATTaxation = VATTaxation;
				
				TaxationOfSales			=
					VATAccountingERP.AccountingParametersForOrganization(Organization, Date).BasicTaxationVATSales;
				TaxationOfSalesGrounds	=
					VATAccountingERP.AccountingParametersForOrganization(Organization, ReferenceDocumentDateForCertificate).BasicTaxationVATSales;
				
				TaxationOfSelection = ?(TaxationOfSales = TaxationOfSalesGrounds,
											VATTaxation,
											TaxationOfSales);
				
				VATAccountingERP.ParametersForFillingTypesOfStocksForTaxation(
					FillParameters.SelectionOfStockTypes_,
					Organization,
					Date,
					TaxationOfSelection);
				VATAccountingERP.SetParametersForFillingInventoryTypesForCommissionSales(FillParameters);
				InventoriesServer.ToSupplementSelectionOfInventoryOwnerAttributesByTypeOfInventory(FillParameters.SelectionOfStockTypes_,
																	Enums.InventoryTypes.Work_5);
			EndIf;
			If PickUpExcisableItems Then
				
				AdditionalProperties.Insert("WriteDownAmountOfExciseTax", True);
				FillParameters.CalculateAmountOfExciseTax = True;
				FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
				FillParameters.FillExcisableItemsWithDefaultInventoryOwnerAttributes = True;
				FillParameters.ExciseAccrualPeriod = ExciseAccrualPeriod;
				If AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices
					And Not SubjectToExcise Then
					FillParameters.SelectionOfStockTypes_.SubjectToExcise.Add(False);
				EndIf;
				
			EndIf;
			InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																	TempTablesManager,
																	Cancel,
																	FillParameters);
			
			If TableOfDiscrepancies.Count() > 0 Then
				For Each Page1 In TableOfDiscrepancies Do
					If Not ValueIsFilled(Page1.InventoryOwnerAttribute) Then
						Continue;
					EndIf;
					
					TypesOfInventoryWriteOffRow = InventoryOwnerAttributesConsumption.Add();
					FillPropertyValues(TypesOfInventoryWriteOffRow, Page1);
				EndDo;
				
				ArrayOfReflectionOptions.Add(Enums.CreditNoteRecordingOptions.RecordInOtherIncome);
			EndIf;
			
			NamesOfSummationColumns = "Count, QuantityByGBRN, AmountIncludingVAT, VATAmount";
			NamesOfSummationColumns = NamesOfSummationColumns + ", ExciseTaxAmount";
			ExcisableGoodsAccounting.CalculateAmountOfExciseTax(ThisObject, FillParameters, , Cancel);
			InventoryOwnerAttributesConsumption.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CorInventoryOwnerAttribute, CCDNumber, Warehouse, VATRate, PartnerProducts",
										NamesOfSummationColumns);
			
			FillInAdditionalStockTypes(InventoryOwnerAttributesConsumption, ArrayOfReflectionOptions);
			
		EndIf;
		
	EndIf;
	
	// Types of inventory for revenue adjustment (without quantity change)
	If AdjustmentKind = Enums.BusinessTransactions.SaleOfOverdeliveredGoods
		Or AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods
		Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated
		Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
		
		InventoryOwnerAttributesRevenueAdjustment.Clear();
		
	Else
		
		TempTablesManager = TemporaryDataTablesOfRevenueAdjustmentDocument();
		ChangedDocumentDetails = CheckChangesToDocumentDetails(TempTablesManager);
		
		If Not Posted
			Or RefillInventoryKinds
			Or ChangedDocumentDetails
			Or CheckChangeOfGoodsRevenueAdjustment(TempTablesManager) Then
			
			FillOutInventoryTypesRevenueAdjustment(TempTablesManager);
			
		EndIf;
		
	EndIf;
	If PickUpExcisableItems
		And Not AdditionalProperties.WriteDownAmountOfExciseTax
		And LineOfBusiness <> Common.ObjectAttributeValue(Ref, "LineOfBusiness") Then
			AdditionalProperties.Insert("WriteDownAmountOfExciseTax", True);
	EndIf;
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = New Array;
	AttributesNames.Add("Date");
	AttributesNames.Add("SubjectToExcise");
	AttributesNames.Add("BusinessUnitProduction");
	AttributesNames = StrConcat(AttributesNames, ",");
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Procedure FillInAdditionalStockTypes(InventoryKinds, ArrayOfReflectionOptions, FillInTypeOfShipmentInventory = False, ToFillInCost = False) Export
	
	FillingCorKindOfStocks = False;
	FillingCorKindOfStocks =
		(BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
			Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
			Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
			Or BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
			Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5)
		And (Not ArrayOfReflectionOptions.Find(Enums.CreditNoteRecordingOptions.IncreaseSale) = Undefined
		Or Not ArrayOfReflectionOptions.Find(Enums.CreditNoteRecordingOptions.ReduceSale) = Undefined);
		
	If FillingCorKindOfStocks Then
		
		ItemItemAccountingAnalyst =
			Common.ObjectsAttributeValue(
				CommonClientServer.CollapseArray(InventoryKinds.UnloadColumn("ItemsLocationAttributes")),
				"Products");
		
		FinancialAccountingGroupSources = New Array;
		For Each KeyAndValue In ItemItemAccountingAnalyst Do
			FinancialAccountingGroupSources.Add(KeyAndValue.Value);
		EndDo;
		FinancialAccountingGroupSources = CommonClientServer.CollapseArray(FinancialAccountingGroupSources);
		
		FinancialAccountingGroupItemAccountingAnalyst =
			Common.ObjectsAttributeValue(FinancialAccountingGroupSources, "FinancialAccountingGroup");
		
		CorTypesOfFinancialAccountingGroupStocks = New Map;
		
		DocumentAttributes = New Structure;
		DocumentAttributes.Insert("Organization",                Organization);
		DocumentAttributes.Insert("GoodsOwner",             Partner);
		DocumentAttributes.Insert("Counterparty",                 Counterparty);
		DocumentAttributes.Insert("Terms",                 Catalogs.TermsOfPurchaseFromVendors.EmptyRef());
		DocumentAttributes.Insert("Contract",                    Contract);
		DocumentAttributes.Insert("Currency",                     Catalogs.Currencies.EmptyRef());
		DocumentAttributes.Insert("TaxationOfOrganization", Enums.VATTaxationTypes.EmptyRef());
		DocumentAttributes.Insert("BusinessOperation",      Enums.BusinessTransactions.TollManufacturing2_5);
		DocumentAttributes.Insert("InventoryType",                 Enums.InventoryTypes.ProductsOfMaterialProvider);
		DocumentAttributes.Insert("FinancialAccountingGroup",     Catalogs.InventoryAccountingGroups.EmptyRef());
		
	EndIf;
	NamesOfGroupingColumns		= "ItemsLocationAttributes, SetAccountingDimension, Warehouse, Package, SalesOrder,
									|CorItemsLocationAttributes, FEACNCode, ARAPObject,
									|ExpenseItem, DimensionOfExpenses, AssetsLiabilitiesDimension, ToExpenseAs,
									|CostDefiningMethod";
	NamesOfSummationColumns	= "Count, NumberOfPackages, AmountIncludingVAT, VATAmount, AmountARAP,
									|Cost_, CostExcludingVAT_, CostLocal,
									|CDCost, TDCost,  AmountExcludingVATCompl, AmountExcludingVATMan,
									|VATAmountCompl, VATAmountMan";
	UnloadedColumns			= NamesOfGroupingColumns + ", " + NamesOfSummationColumns;
	
	GoodsTable = Discrepancies.UnloadColumns(UnloadedColumns);
	GoodsTable.Columns.Add("ToIncomeExpenses");
	
	For Each LineOfDiscrepancies In Discrepancies Do
		
		ConsiderLine = False;
		
		For Each PostingOption In ArrayOfReflectionOptions Do
			
			If LineOfDiscrepancies.PostingOption = PostingOption Then
				ConsiderLine = True;
				Break;
			EndIf;
			
		EndDo;
		
		If ConsiderLine Then
			
			RowOfGoods = GoodsTable.Add();
			FillPropertyValues(RowOfGoods, LineOfDiscrepancies);
			
			If LineOfDiscrepancies.Count < 0 Then
				RowOfGoods.Count			= -LineOfDiscrepancies.Count;
				RowOfGoods.NumberOfPackages	= -LineOfDiscrepancies.NumberOfPackages;
				RowOfGoods.AmountARAP	= -LineOfDiscrepancies.AmountARAP;
				RowOfGoods.AmountExcludingVATCompl		= -LineOfDiscrepancies.AmountExcludingVATCompl;
				RowOfGoods.AmountExcludingVATMan		= -LineOfDiscrepancies.AmountExcludingVATMan;
				RowOfGoods.VATAmountCompl			= -LineOfDiscrepancies.VATAmountCompl;
				RowOfGoods.VATAmountMan			= -LineOfDiscrepancies.VATAmountMan;
			EndIf;
			
			RowOfGoods.ToIncomeExpenses =
				LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.ToExpenseAs
				Or LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.RecordInOtherIncome;
			RowOfGoods.SetAccountingDimension = LineOfDiscrepancies.SetAccountingDimension;
		EndIf;
		
	EndDo;
	
	NamesOfGroupingColumns = NamesOfGroupingColumns + ", " + "ToIncomeExpenses";
	
	GoodsTable.GroupBy(NamesOfGroupingColumns , NamesOfSummationColumns);
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	AnalyticsPropertiesToFillIn = "ItemsLocationAttributes, CorItemsLocationAttributes";
	
	For Each RowOfGoods In GoodsTable Do
		
		GoodsQuantity			= RowOfGoods.Count;
		NumberOfPackages			= RowOfGoods.NumberOfPackages;
		AmountOfMutualSettlementsOfGoods	= RowOfGoods.AmountARAP;
		AmountExcludingVATCompl				= RowOfGoods.AmountExcludingVATCompl;
		AmountExcludingVATMan				= RowOfGoods.AmountExcludingVATMan;
		
		InventoryCost		= RowOfGoods.Cost_;
		CostOfGoodsExcludingVAT	= RowOfGoods.CostExcludingVAT_;
		CostOfLocalGoods	= RowOfGoods.CostLocal;
		CostOfPDGoods		= RowOfGoods.CDCost;
		CostOfTDGoods		= RowOfGoods.TDCost;
		TheStructureOfTheSearch.ItemsLocationAttributes = RowOfGoods.ItemsLocationAttributes;
		
		// The Attribute is filled in for documents created on the basis of the implementation of Service products of operations
		// Client realizationand property rights transition.
		// According to the coralitik of the Inventory Inventory, inventory selection is carried out, and therefore it is necessary to normalize
		// the analyst values after selection.
		If FillInTypeOfShipmentInventory
			And ValueIsFilled(RowOfGoods.CorItemsLocationAttributes) Then
			
			TheStructureOfTheSearch.ItemsLocationAttributes = RowOfGoods.CorItemsLocationAttributes;
			
		EndIf;
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			FillPropertyValues(NewRow, RowOfGoods, AnalyticsPropertiesToFillIn);
			
			NewRow.Package				= RowOfGoods.Package;
			NewRow.SalesOrder			= RowOfGoods.SalesOrder;
			NewRow.ARAPObject			= RowOfGoods.ARAPObject;
			NewRow.FEACNCode				= RowOfGoods.FEACNCode;
			NewRow.ToIncomeExpenses			= RowOfGoods.ToIncomeExpenses;
			NewRow.SetAccountingDimension	= RowOfGoods.SetAccountingDimension;
			
			NewRow.ExpenseItem           = RowOfGoods.ExpenseItem;
			NewRow.DimensionOfExpenses        = RowOfGoods.DimensionOfExpenses;
			NewRow.AssetsLiabilitiesDimension = RowOfGoods.AssetsLiabilitiesDimension;
			NewRow.ToExpenseAs         = RowOfGoods.ToExpenseAs;
			
			If ToFillInCost Then
				NewRow.CostDefiningMethod = RowOfGoods.CostDefiningMethod;
			EndIf;
			
			NewRow.NumberOfPackages		= ?(GoodsQuantity <> 0,
													NumberOfPackages * Count / GoodsQuantity,
													0);
			NewRow.Count				= Count;
			NewRow.QuantityByGBRN		= Count * InventoryLine.QuantityByGBRN
													/ InventoryLine.Count;
			NewRow.AmountIncludingVAT				= ?(InventoryLine.Count <> 0,
													Count * InventoryLine.AmountIncludingVAT / InventoryLine.Count,
													0);
			NewRow.VATAmount				= ?(InventoryLine.Count <> 0,
													Count * InventoryLine.VATAmount / InventoryLine.Count,
													0);
			
			NewRow.VATAmountCompl = ?(InventoryLine.Count <> 0,
				Count * RowOfGoods.VATAmountCompl / InventoryLine.Count,
				0);
			
			NewRow.VATAmountMan = ?(InventoryLine.Count <> 0,
				Count * RowOfGoods.VATAmountMan / InventoryLine.Count,
				0);
			
			NewRow.AmountARAP		= ?(GoodsQuantity <> 0,
													Count * AmountOfMutualSettlementsOfGoods / GoodsQuantity,
													0);
			If ToFillInCost
				And RowOfGoods.CostDefiningMethod = Enums.WaysToCalculateReturnCost.Manually Then
				
				NewRow.Cost_		= ?(Count = GoodsQuantity,
														InventoryCost,
														Count * InventoryCost / GoodsQuantity);
				NewRow.CostExcludingVAT_	= ?(Count = GoodsQuantity,
														CostOfGoodsExcludingVAT,
														Count * CostOfGoodsExcludingVAT / GoodsQuantity);
				NewRow.CostLocal	= ?(Count = GoodsQuantity,
														CostOfLocalGoods,
														Count * CostOfLocalGoods / GoodsQuantity);
				NewRow.CDCost		= ?(Count = GoodsQuantity,
														CostOfPDGoods,
														Count * CostOfPDGoods / GoodsQuantity);
				NewRow.TDCost		= ?(Count = GoodsQuantity,
														CostOfTDGoods,
														Count * CostOfTDGoods / GoodsQuantity);
				InventoryLine.Cost_		= InventoryLine.Cost_ - NewRow.Cost_;
				InventoryLine.CostExcludingVAT_	= InventoryLine.CostExcludingVAT_ - NewRow.CostExcludingVAT_;
				InventoryLine.CostLocal		= InventoryLine.CostLocal - NewRow.CostLocal;
				InventoryLine.CDCost		= InventoryLine.CDCost - NewRow.CDCost;
				InventoryLine.TDCost		= InventoryLine.TDCost - NewRow.TDCost;
			ElsIf ToFillInCost Then
				
				NewRow.ExciseTaxAmount = Count * InventoryLine.ExciseTaxAmount / InventoryLine.Count;
				
				InventoryLine.ExciseTaxAmount = InventoryLine.ExciseTaxAmount - NewRow.ExciseTaxAmount;
			EndIf;
			
			NewRow.AmountExcludingVATCompl			= ?(GoodsQuantity <> 0,
													Count * AmountExcludingVATCompl / GoodsQuantity,
													0);
													
			NewRow.AmountExcludingVATMan			= ?(GoodsQuantity <> 0,
													Count * AmountExcludingVATMan / GoodsQuantity,
													0);
													
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.AmountIncludingVAT			= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount			= InventoryLine.VATAmount - NewRow.VATAmount;
			InventoryLine.VATAmountCompl = InventoryLine.VATAmountCompl - NewRow.VATAmountCompl;
			InventoryLine.VATAmountMan = InventoryLine.VATAmountMan - NewRow.VATAmountMan;
			
			// For new types of inventory, the type of inventory is loaded = This
			// field is reserved for backward compatibility with older documents.
			If FillInTypeOfShipmentInventory
				And Not ValueIsFilled(NewRow.InventoryOwnerAttributeShipment) Then
				NewRow.InventoryOwnerAttributeShipment = InventoryLine.InventoryOwnerAttribute;
			EndIf;
			If FillingCorKindOfStocks Then
				
				StringProducts = ItemItemAccountingAnalyst.Get(InventoryLine.ItemsLocationAttributes);
				FinancialAccountingGroupStrings          = FinancialAccountingGroupItemAccountingAnalyst.Get(StringProducts);
				CorInventoryOwnerAttribute      = CorTypesOfFinancialAccountingGroupStocks.Get(FinancialAccountingGroupStrings);
				
				If Not ValueIsFilled(CorInventoryOwnerAttribute) Then
					
					DocumentAttributes.FinancialAccountingGroup = FinancialAccountingGroupStrings;
					CorInventoryOwnerAttribute =
						Catalogs.InventoryKinds.DocumentInventoryView(
							Organization,
							Enums.BusinessTransactions.TollManufacturing2_5,
							DocumentAttributes);
					
					CorTypesOfFinancialAccountingGroupStocks.Insert(FinancialAccountingGroupStrings, CorInventoryOwnerAttribute);
					
				EndIf;
				
				NewRow.CorInventoryOwnerAttribute = CorInventoryOwnerAttribute;
				
			EndIf;
			GoodsQuantity			= GoodsQuantity - NewRow.Count;
			NumberOfPackages			= NumberOfPackages - NewRow.NumberOfPackages;
			AmountOfMutualSettlementsOfGoods	= AmountOfMutualSettlementsOfGoods - NewRow.AmountARAP;
			AmountExcludingVATCompl				= AmountExcludingVATCompl - NewRow.AmountExcludingVATCompl;
			AmountExcludingVATMan				= AmountExcludingVATMan - NewRow.AmountExcludingVATMan;
			
			If ToFillInCost
				And RowOfGoods.CostDefiningMethod = Enums.WaysToCalculateReturnCost.Manually Then
				
				InventoryCost		= InventoryCost - NewRow.Cost_;
				CostOfGoodsExcludingVAT	= CostOfGoodsExcludingVAT - NewRow.CostExcludingVAT_;
				CostOfLocalGoods	= CostOfLocalGoods - NewRow.CostLocal;
				CostOfPDGoods		= CostOfPDGoods - NewRow.CDCost;
				CostOfTDGoods		= CostOfTDGoods - NewRow.TDCost;
			EndIf;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure FillInAdditionalColumnsOfInventoryTypes(TableTypesOfStocks_, ReflectionOptions)
	
	NamesOfGroupingColumns		= "ItemsLocationAttributes, SetAccountingDimension, CCDNumber, Warehouse, Package,
									|SalesOrder, VATRate, FEACNCode, ARAPObject, PartnerProducts,
									|CostDefiningMethod";
	NamesOfSummationColumns	= "Count, NumberOfPackages, QuantityByGBRN, AmountIncludingVAT, VATAmount,
									|AmountARAP, Cost_, CostExcludingVAT_, CostLocal,
									|CDCost, TDCost, AmountExcludingVATCompl, AmountExcludingVATMan,
									|VATAmountCompl, VATAmountMan";

	UnloadedColumns			= "LineNumber" + ", " + NamesOfGroupingColumns + ", " + NamesOfSummationColumns;
	
	GoodsTable = Discrepancies.UnloadColumns(UnloadedColumns);
	GoodsTable.Columns.Add("InventoryOwnerAttribute");
	GoodsTable.Columns.Add("ToIncomeExpenses");
	
	UseTraceableImportedGoodsAccounting = AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(
														Date);

	ProductProductTypes			= VATAccountingERPInternal.ProductProductTypes();
	ComplianceOfProductWithType	= Common.ObjectsAttributesValues(
													Discrepancies.UnloadColumn("Products"),
													"ItemsType, TracedGoods");

	For Each LineOfDiscrepancies In Discrepancies Do
		ProductData_1 = ComplianceOfProductWithType.Get(LineOfDiscrepancies.Products);
		
		If ReflectionOptions.Find(LineOfDiscrepancies.PostingOption) = Undefined
			Or (ProductProductTypes.Find(ProductData_1.ItemsType) = Undefined
				And Not (UseTraceableImportedGoodsAccounting
					And ProductData_1.ItemsType = Enums.ItemsTypes.Work_5
					And ProductData_1.TracedGoods)) Then
			
			Continue;
			
		EndIf;
		
		RowOfGoods = GoodsTable.Add();
		FillPropertyValues(RowOfGoods, LineOfDiscrepancies);
		
		If LineOfDiscrepancies.NumberOfPackages < 0 Then
			RowOfGoods.Count			= -LineOfDiscrepancies.Count;
			RowOfGoods.NumberOfPackages	= -LineOfDiscrepancies.NumberOfPackages;
			RowOfGoods.QuantityByGBRN		= -LineOfDiscrepancies.QuantityByGBRN;
			RowOfGoods.VATAmount				= -LineOfDiscrepancies.VATAmount;
			RowOfGoods.VATAmountCompl			= -LineOfDiscrepancies.VATAmountCompl;
			RowOfGoods.VATAmountMan			= -LineOfDiscrepancies.VATAmountMan;
			RowOfGoods.AmountIncludingVAT				= -LineOfDiscrepancies.AmountIncludingVAT;
			RowOfGoods.AmountARAP	= -LineOfDiscrepancies.AmountARAP;
			RowOfGoods.AmountExcludingVATCompl		= -LineOfDiscrepancies.AmountExcludingVATCompl;
			RowOfGoods.AmountExcludingVATMan		= -LineOfDiscrepancies.AmountExcludingVATMan;
		EndIf;

		RowStocks = TableTypesOfStocks_.Find(LineOfDiscrepancies.LineNumber, "LineNumber");
		
		RowOfGoods.InventoryOwnerAttribute = RowStocks.InventoryOwnerAttribute;
		
		RowOfGoods.ToIncomeExpenses =
			LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.ToExpenseAs
			Or LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.RecordInOtherIncome;
	EndDo;
	
	NamesOfGroupingColumns = NamesOfGroupingColumns + ", " + "InventoryOwnerAttribute, ToIncomeExpenses";
	
	GoodsTable.GroupBy(NamesOfGroupingColumns , NamesOfSummationColumns);
	
	For Each RowOfGoods In GoodsTable Do
		NewRow = InventoryOwnerAttributesGoodsReceipt.Add();
		FillPropertyValues(NewRow, RowOfGoods);
		
		NewRow.InventoryOwnerAttributeShipment	= NewRow.InventoryOwnerAttribute;
		NewRow.OriginWarehouse		= NewRow.Warehouse;
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryOwnerAttributesGoodsReceipt.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryOwnerAttributesGoodsReceipt.Delete(TableRow);
	EndDo;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.SaleAdjustment.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.SaleAdjustment.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	DivergenceTable = DocumentTables.Discrepancies;
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Insert("Arbitrary", "Warehouse");
	FieldsNames.Insert("Work_5", "Department");
	
	If TypeOf(DocumentBasis) <> Type("DocumentRef.CustomerInvoiceServicesAndAssets")
		And AdjustingEntryType <> Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets Then
		
		SynchronizeAnalytics = False;
		FillInCorOfInventoryLocationAttributeAccounting = False;
		
		If TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice")
			Or AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices Then
			
			If TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
				SetPrivilegedMode(True);
				DocumentBasisBusinessOperation = Common.ObjectAttributeValue(
															DocumentBasis,
															"BusinessOperation");
				
				FillInCorOfInventoryLocationAttributeAccounting =
					BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
					Or BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods;
			Else
				DocumentBasisBusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
			EndIf;
			
			If ConsignmentSalesServer.SalesViaCommissionAgent(DocumentBasisBusinessOperation) Then
				PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
								DocumentBasisBusinessOperation,
								Warehouse,
								Department,
								Partner,
								Contract);
			ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice")
				And GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5") Then
				
				// Creating a collection of search strings to fill in corresponding analytics.
				DiscrepancyOptions = New Array;
				
				If BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
					DiscrepancyOptions.Add(Enums.CreditNoteRecordingOptions.ReduceSaleIncludeDuringPhysicalInventoryCount);
					DiscrepancyOptions.Add(Enums.CreditNoteRecordingOptions.ReduceSaleIncreaseWarehouseStock);
					DiscrepancyOptions.Add(Enums.CreditNoteRecordingOptions.IncreaseSaleIncludeDuringPhysicalInventoryCount);
					DiscrepancyOptions.Add(Enums.CreditNoteRecordingOptions.IncreaseSaleReduceWarehouseStock);
				Else
					DiscrepancyOptions.Add(Enums.CreditNoteRecordingOptions.ReturnToTransit);
				EndIf;
				
				For Each SignificanceOfDiscrepancy In DiscrepancyOptions Do
					If DivergenceTable.Find(SignificanceOfDiscrepancy, "PostingOption") <> Undefined Then
						SynchronizeAnalytics = True;
						
						Break;
					EndIf;
				EndDo;
				
				If SynchronizeAnalytics Then
					If BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
						CorAnalyticsFieldNames = FieldsNames;
						CorAnalyticsFieldNames.BatchesIndicationStatus = "BatchesIndicationStatusInWarehouses";
					Else
						CorAnalyticsFieldNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
						CorAnalyticsFieldNames.Work_5				= "Department";
						CorAnalyticsFieldNames.BatchesIndicationStatus	= "BatchesIndicationStatusOfGoodsTransferred";
					EndIf;
					
					CorAnalyticsFieldNames.ItemsLocationAttributes = "CorItemsLocationAttributes";
					
					PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
									AdjustmentKind,
									Contract,
									Department,
									Partner);
					
					InformationRegisters.ItemsLocationAttributes.FillInCollection(DivergenceTable,
																					PlacesOfAccounting,
																					CorAnalyticsFieldNames);
				EndIf;
				
				If BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
					AccountingWarehouse = Contract;
					
					FieldsNames.Arbitrary			= "";
					FieldsNames.BatchesIndicationStatus	= "BatchesIndicationStatusOfGoodsTransferred";
				Else
					AccountingWarehouse = Warehouse;
					
					FieldsNames.BatchesIndicationStatus = "BatchesIndicationStatusInWarehouses";
				EndIf;
				
				FieldsNames.ItemsLocationAttributes = "ItemsLocationAttributes";
				
				PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
								AdjustmentKind,
								AccountingWarehouse,
								Department,
								Partner);
				
			Else
				PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
								AdjustmentKind,
								Warehouse,
								Department,
								Partner);
			EndIf;
		ElsIf BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
			Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
			Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
			Or BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
			Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
			
			If BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
				Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
				Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5 Then
				
				WarehouseDetails = Common.ObjectAttributesValues(Warehouse, "IsFolder, SelectGroup");
				
				If Not (WarehouseDetails.IsFolder
					And WarehouseDetails.SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices) Then
					FieldsNames.Insert("Arbitrary", "");
				EndIf;
				
			EndIf;
			
			PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
							DocumentBasisBusinessOperation,
							Warehouse,
							Department,
							Partner);
		Else
			PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
							AdjustmentKind,
							Warehouse,
							Department,
							Partner);
		EndIf;
		
		InformationRegisters.ItemsLocationAttributes.FillInCollection(DivergenceTable, PlacesOfAccounting, FieldsNames);
		InformationRegisters.SetAccountingDimension.FillInCollection(DivergenceTable);
		
		If Not SynchronizeAnalytics
			And FillInCorOfInventoryLocationAttributeAccounting Then
			
			AccountingAnalytics = DivergenceTable.UnloadColumn("ItemsLocationAttributes");
			DivergenceTable.LoadColumn(AccountingAnalytics, "CorItemsLocationAttributes");
			
		ElsIf SynchronizeAnalytics Then
			For Each TSRow In DivergenceTable Do
				ItemsLocationAttributes = ?(DiscrepancyOptions.Find(TSRow.PostingOption) = Undefined,
												TSRow.ItemsLocationAttributes,
												TSRow.CorItemsLocationAttributes);
				
				TSRow.CorItemsLocationAttributes	= TSRow.ItemsLocationAttributes;
				TSRow.ItemsLocationAttributes		= ItemsLocationAttributes;
			EndDo;
		Else
			For Each TSRow In DivergenceTable Do
				TSRow.CorItemsLocationAttributes = Undefined;
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

///////////////////////////////////////////////////////////////////////////////
// WriteOff

Function TemporaryDataTablesForWriteOffDocument(ArrayOfReflectionOptions)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Date														AS Date,
	|	&Organization												AS Organization,
	|	UNDEFINED												AS Partner,
	|	UNDEFINED												AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)	AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)		AS Contract,
	|	&Currency														AS Currency,
	|	&VATTaxation											AS VATTaxation,
	|	&BusinessOperation										AS BusinessOperation,
	|	FALSE														AS ThereAreTransactionsInTablePart,
	|	&ActivitiesAreSubjectToUTII									AS ActivitiesAreSubjectToUTII,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END														AS Department,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Manager
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END														AS Manager,
	|	CASE
	|		WHEN SalesOpportunitiesToCustomer.EnabledGoodsAssignmentInSalesOpportunity
	|				AND &GenerateInventoryOwnerAttributesBySalesOpportunities
	|			THEN &SalesOpportunity
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END														AS SalesOpportunity,
	|	UNDEFINED												AS DocumentSalesOfGoodsAndServices,
	|	&SubjectToExcise											AS SubjectToExcise,
	|	&BusinessUnitProduction									AS BusinessUnitProduction,
	|	VALUE(Enum.InventoryTypes.OwnGoods)					AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON BusinessStructure.Ref = &Department
	|		
	|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		ON SalesOpportunitiesToCustomer.Ref = &SalesOpportunity
	|
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber											AS LineNumber,
	|	TableOfGoods.PostingOption										AS PostingOption,
	|	TableOfGoods.Products											AS Products,
	|	TableOfGoods.Characteristic										AS Characteristic,
	|	TableOfGoods.Series												AS Series,
	|	TableOfGoods.BatchesIndicationStatus									AS BatchesIndicationStatus,
	|	TableOfGoods.Purpose											AS Purpose,
	|	TableOfGoods.ItemsLocationAttributes							AS ItemsLocationAttributes,
	|	TableOfGoods.PartnerProducts									AS PartnerProducts,
	|	TableOfGoods.Count											AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				OR &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END																AS QuantityByGBRN,
	|	TableOfGoods.Warehouse												AS Warehouse,
	|	TableOfGoods.FEACNCode												AS FEACNCode,
	|	TableOfGoods.VATRate											AS VATRate,
	|	TableOfGoods.Sum + (TableOfGoods.VATAmount * &PriceIncludesVAT)	AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount												AS VATAmount,
	|	TableOfGoods.VATAmountCompl											AS VATAmountCompl,
	|	TableOfGoods.VATAmountMan											AS VATAmountMan,
	|	TableOfGoods.AmountARAP									AS AmountARAP,
	|	&SalesOpportunity																AS SalesOpportunity,
	|	TableOfGoods.SalesOrder											AS SalesOrder,
	|	TableOfGoods.RowCode											AS RowCode,
	|	TableOfGoods.AmountExcludingVATCompl										AS AmountExcludingVATCompl,
	|	TableOfGoods.AmountExcludingVATMan										AS AmountExcludingVATMan,
	|	CASE
	|		WHEN &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|			THEN VALUE(Catalog.CCDNumbers.EmptyRef)
	|		ELSE TableOfGoods.CCDNumber
	|	END	AS CCDNumber,
	|	TableOfGoods.ExpenseItem AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfGoods.ToExpenseAs AS ToExpenseAs
	|
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|WHERE
	|	TableOfGoods.PostingOption IN(&ArrayOfReflectionOptions)
	|	AND NOT TableOfGoods.Count = 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber		AS LineNumber,
	|	GoodsFromOrder.Ref.Purpose	AS Purpose
	|INTO TTProductsToOrder
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Document.SalesOrder.Goods AS GoodsFromOrder
	|		ON TableOfGoods.SalesOrder = GoodsFromOrder.Ref
	|			AND TableOfGoods.RowCode = GoodsFromOrder.RowCode
	|			AND TableOfGoods.Products = GoodsFromOrder.Products
	|			AND TableOfGoods.Characteristic = GoodsFromOrder.Characteristic
	|
	|WHERE
	|	&SaleByOrders
	|	AND TableOfGoods.SalesOrder <> UNDEFINED
	|	AND GoodsFromOrder.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND GoodsFromOrder.WithAssignment
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber		AS LineNumber,
	|	GoodsFromOrder.Ref.Purpose	AS Purpose
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS GoodsFromOrder
	|		ON TableOfGoods.SalesOrder = GoodsFromOrder.Ref
	|			AND TableOfGoods.RowCode = GoodsFromOrder.RowCode
	|			AND TableOfGoods.Products = GoodsFromOrder.Products
	|			AND TableOfGoods.Characteristic = GoodsFromOrder.Characteristic
	|
	|WHERE
	|	&SaleByOrders
	|	AND TableOfGoods.SalesOrder <> UNDEFINED
	|	AND GoodsFromOrder.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND GoodsFromOrder.WithAssignment
	|
	|INDEX BY
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.PostingOption				AS PostingOption,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.PartnerProducts 		AS PartnerProducts,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.QuantityByGBRN				AS QuantityByGBRN,
	|	CASE
	|		WHEN &SalesViaCommissionAgent
	|			THEN Dimension.StorageLocation
	|		ELSE TableOfGoods.Warehouse
	|	END										AS Warehouse,
	|	TableOfGoods.SalesOrder					AS SalesOrder,
	|	TableOfGoods.FEACNCode						AS FEACNCode,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						AS VATAmount,
	|	TableOfGoods.VATAmountCompl					AS VATAmountCompl,
	|	TableOfGoods.VATAmountMan					AS VATAmountMan,
	|	TableOfGoods.AmountARAP			AS AmountARAP,
	|	0											AS CommissionAmount,
	|	0											AS AmountVATRemuneration,
	|	&SalesOpportunity										AS SalesOpportunity,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TRUE										AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber						AS CCDNumber,
	|	TableOfGoods.AmountExcludingVATCompl				AS AmountExcludingVATCompl,
	|	TableOfGoods.AmountExcludingVATMan				AS AmountExcludingVATMan,
	|
	|	TableOfGoods.ExpenseItem AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfGoods.ToExpenseAs AS ToExpenseAs
	|
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	CatalogProducts.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|											VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.PostingOption				AS PostingOption,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.PartnerProducts 		AS PartnerProducts,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.QuantityByGBRN				AS QuantityByGBRN,
	|	Dimension.StorageLocation						AS Warehouse,
	|	TableOfGoods.SalesOrder					AS SalesOrder,
	|	TableOfGoods.FEACNCode						AS FEACNCode,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						AS VATAmount,
	|	TableOfGoods.VATAmountCompl					AS VATAmountCompl,
	|	TableOfGoods.VATAmountMan					AS VATAmountMan,
	|	TableOfGoods.AmountARAP			AS AmountARAP,
	|	0											AS CommissionAmount,
	|	0											AS AmountVATRemuneration,
	|	&SalesOpportunity										AS SalesOpportunity,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TRUE										AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber						AS CCDNumber,
	|	TableOfGoods.AmountExcludingVATCompl				AS AmountExcludingVATCompl,
	|	TableOfGoods.AmountExcludingVATMan				AS AmountExcludingVATMan,
	|
	|	TableOfGoods.ExpenseItem AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfGoods.ToExpenseAs AS ToExpenseAs
	|
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ToIncomeExpenses				AS ToIncomeExpenses,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.PartnerProducts 		AS PartnerProducts,	
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute				AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.FEACNCode						AS FEACNCode,
	|	TableTypesOfStocks_.VATRate					AS VATRate,
	|	VALUE(Catalog.Warehouses.EmptyRef)		AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse						AS Warehouse,
	|	TableTypesOfStocks_.SalesOrder					AS SalesOrder,
	|	&SalesOpportunity											AS SalesOpportunity,
	|	TableTypesOfStocks_.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END											AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount						AS VATAmount,
	|	TableTypesOfStocks_.VATAmountCompl					AS VATAmountCompl,
	|	TableTypesOfStocks_.VATAmountMan					AS VATAmountMan,
	|	TableTypesOfStocks_.AmountARAP			AS AmountARAP,
	|	FALSE											AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.AmountExcludingVATCompl				AS AmountExcludingVATCompl,
	|	TableTypesOfStocks_.AmountExcludingVATMan				AS AmountExcludingVATMan,
	|	TableTypesOfStocks_.ExciseTaxAmount					AS ExciseTaxAmount,
	|
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.ToExpenseAs AS ToExpenseAs
	|
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	99999 AS LineNumber,
	|	&Date AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.ToIncomeExpenses AS ToIncomeExpenses,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.PartnerProducts AS PartnerProducts,	
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.FEACNCode AS FEACNCode,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.SalesOrder AS SalesOrder,
	|	&SalesOpportunity AS SalesOpportunity,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.VATAmountCompl AS VATAmountCompl,
	|	TableTypesOfStocks_.VATAmountMan AS VATAmountMan,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	TableTypesOfStocks_.ExciseTaxAmount AS ExciseTaxAmount,
	|
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.ToExpenseAs AS ToExpenseAs
	|INTO TTInventoryTypesRegistration
	|FROM
	|	&InventoryOwnerAttributesGoodsReceipt AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ToIncomeExpenses				AS ToIncomeExpenses,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.PartnerProducts 		AS PartnerProducts,	
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic						AS Characteristic,
	|	Dimension.Series									AS Series,
	|	CASE
	|		WHEN &UseExcisableGoods
	|		AND TableTypesOfStocks_.ToIncomeExpenses
	|		AND NOT VALUE(Enum.CreditNoteRecordingOptions.RecordInOtherIncome) IN
	|		(&ArrayOfReflectionOptions)
	|			THEN VALUE(Catalog.InventoryKinds.EmptyRef)
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute				AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.FEACNCode						AS FEACNCode,
	|	TableTypesOfStocks_.VATRate					AS VATRate,
	|	TableTypesOfStocks_.OriginWarehouse				AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse						AS Warehouse,
	|	TableTypesOfStocks_.SalesOrder					AS SalesOrder,
	|	TableTypesOfStocks_.SalesOpportunity						AS SalesOpportunity,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount						AS VATAmount,
	|	TableTypesOfStocks_.VATAmountCompl					AS VATAmountCompl,
	|	TableTypesOfStocks_.VATAmountMan					AS VATAmountMan,
	|	TableTypesOfStocks_.AmountARAP			AS AmountARAP,
	|	FALSE											AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.AmountExcludingVATCompl				AS AmountExcludingVATCompl,
	|	TableTypesOfStocks_.AmountExcludingVATMan				AS AmountExcludingVATMan,
	|	TableTypesOfStocks_.ExciseTaxAmount					AS ExciseTaxAmount,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.ToExpenseAs AS ToExpenseAs
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ToIncomeExpenses				AS ToIncomeExpenses,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.PartnerProducts 		AS PartnerProducts,	
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic						AS Characteristic,
	|	Dimension.Series									AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute				AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.FEACNCode						AS FEACNCode,
	|	TableTypesOfStocks_.VATRate					AS VATRate,
	|	TableTypesOfStocks_.OriginWarehouse				AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse						AS Warehouse,
	|	TableTypesOfStocks_.SalesOrder					AS SalesOrder,
	|	TableTypesOfStocks_.SalesOpportunity						AS SalesOpportunity,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount						AS VATAmount,
	|	TableTypesOfStocks_.VATAmountCompl					AS VATAmountCompl,
	|	TableTypesOfStocks_.VATAmountMan					AS VATAmountMan,
	|	TableTypesOfStocks_.AmountARAP			AS AmountARAP,
	|	TRUE											AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.AmountExcludingVATCompl				AS AmountExcludingVATCompl,
	|	TableTypesOfStocks_.AmountExcludingVATMan				AS AmountExcludingVATMan,
	|	TableTypesOfStocks_.ExciseTaxAmount					AS ExciseTaxAmount,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.ToExpenseAs AS ToExpenseAs
	|FROM
	|	TTInventoryTypesRegistration AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Products,
	|	Characteristic,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.PartnerProducts AS PartnerProducts,	
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS CurViewOfStocks,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND &ToReturnReusablePackage
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsReusablePackage,
	|	DocumentDataTable.Organization AS Organization,
	|	DocumentDataTable.BusinessOperation AS BusinessOperation,
	|	DocumentDataTable.InventoryType AS InventoryType,
	|	DocumentDataTable.Terms AS Terms,
	|	DocumentDataTable.Currency AS Currency,
	|	DocumentDataTable.VATTaxation AS VATTaxation,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS TaxationOfOrganization,
	|	UNDEFINED AS GoodsOwner,
	|	DocumentDataTable.Counterparty AS Counterparty,
	|	DocumentDataTable.Contract AS Contract,
	|	TableOfGoods.ExpenseItem AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableOfGoods.ToExpenseAs AS ToExpenseAs
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE
	|	
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON TableOfGoods.Products = CatProducts.Ref";
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.SourceDocument")
		Or TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoiceServices") Then
		ToReturnReusablePackage = False;
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		ToReturnReusablePackage = False;
	Else
		ToReturnReusablePackage = Common.ObjectAttributeValue(DocumentBasis,"ToReturnReusablePackage");
	EndIf;
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Ref",								Ref);
	Query.SetParameter("Date",								Date);
	Query.SetParameter("Currency",								Currency);
	Query.SetParameter("Organization",						Organization);
	Query.SetParameter("Manager",							Manager);
	Query.SetParameter("Department",						Department);
	Query.SetParameter("SalesOpportunity",								SalesOpportunity);
	Query.SetParameter("VATTaxation",					VATTaxation);
	Query.SetParameter("PriceIncludesVAT",					?(PriceIncludesVAT, 0, 1));
	Query.SetParameter("SaleByOrders",					SaleByOrders);
	Query.SetParameter("BusinessOperation",				Enums.BusinessTransactions.SaleToCustomer);
	Query.SetParameter("ActivitiesAreSubjectToUTII",			(VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToUTII));
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers", GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities",	GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.SetParameter("AdjustingEntryType",					AdjustingEntryType);
	Query.SetParameter("TableOfGoods",						Discrepancies);
	Query.SetParameter("TableTypesOfStocks_",					InventoryOwnerAttributesConsumption);
	Query.SetParameter("ArrayOfReflectionOptions",			ArrayOfReflectionOptions);
	Query.SetParameter("InventoryOwnerAttributesGoodsReceipt",			InventoryOwnerAttributesGoodsReceipt);
	Query.SetParameter("ToReturnReusablePackage", 			ToReturnReusablePackage);
	Query.SetParameter("SalesViaCommissionAgent", 
								ConsignmentSalesServer.SalesViaCommissionAgent(
								Documents.SaleAdjustment.EconomicOperationOfFoundationDocument(DocumentBasis)));
	Query.SetParameter("SubjectToExcise",
								?(BusinessOperation = Enums.BusinessTransactions.SaleToCustomer,
									SubjectToExcise,
									False));
	Query.SetParameter("BusinessUnitProduction",
								?(BusinessOperation = Enums.BusinessTransactions.SaleToCustomer,
									BusinessUnitProduction,
									Catalogs.BusinessStructure.EmptyRef()));
	UseExcisableGoods = ?(BusinessOperation = Enums.BusinessTransactions.SaleToCustomer,
		GetFunctionalOption("UseExcisableGoods"), False);
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Function CheckChangesInItemsDebited(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.Warehouse							AS Warehouse,
	|		TableOfGoods.SalesOrder						AS SalesOrder,
	|		TableOfGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|		CASE
	|			WHEN &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|				THEN TableOfGoods.CCDNumber
	|			ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|		END											AS CCDNumber,
	|		TableOfGoods.FEACNCode							AS FEACNCode,
	|		TableOfGoods.VATRate						AS VATRate,
	|		TableOfGoods.Count						AS Count,
	|		TableOfGoods.AmountIncludingVAT						AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount							AS VATAmount,
	|		TableOfGoods.VATAmountCompl						AS VATAmountCompl,
	|		TableOfGoods.VATAmountMan						AS VATAmountMan,
	|		TableOfGoods.AmountARAP				AS AmountARAP,
	|		TableOfGoods.AmountExcludingVATCompl					AS AmountExcludingVATCompl,
	|		TableOfGoods.AmountExcludingVATMan					AS AmountExcludingVATMan	
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.Warehouse						AS Warehouse,
	|		TableTypesOfStocks_.SalesOrder					AS SalesOrder,
	|		TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		CASE
	|			WHEN &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|				THEN TableTypesOfStocks_.CCDNumber
	|			ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|		END											AS CCDNumber,
	|		TableTypesOfStocks_.FEACNCode						AS FEACNCode,
	|		TableTypesOfStocks_.VATRate					AS VATRate,
	|		-TableTypesOfStocks_.Count					AS Count,
	|		-TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount					AS VATAmount,
	|		-TableTypesOfStocks_.VATAmountCompl				AS VATAmountCompl,
	|		-TableTypesOfStocks_.VATAmountMan					AS VATAmountMan,
	|		-TableTypesOfStocks_.AmountARAP			AS AmountARAP,
	|		-TableTypesOfStocks_.AmountExcludingVATCompl				AS AmountExcludingVATCompl,
	|		-TableTypesOfStocks_.AmountExcludingVATMan				AS AmountExcludingVATMan	
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	WHERE
	|		NOT TableTypesOfStocks_.ToIncomeExpenses
	|		AND NOT TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.CCDNumber,
	|	TableOfGoods.FEACNCode,
	|	TableOfGoods.VATRate
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.VATAmountCompl) <> 0
	|	OR SUM(TableOfGoods.VATAmountMan) <> 0
	|	OR SUM(TableOfGoods.AmountARAP) <> 0
	|	OR SUM(TableOfGoods.AmountExcludingVATCompl) <> 0
	|	OR SUM(TableOfGoods.AmountExcludingVATMan) <> 0
	|");
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("AdjustingEntryType", AdjustingEntryType);

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Function CheckChangesInGoodsReflectOnOtherIncome(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.Warehouse							AS Warehouse,
	|		TableOfGoods.SalesOrder						AS SalesOrder,
	|		TableOfGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate						AS VATRate,
	|		TableOfGoods.Count						AS Count,
	|		TableOfGoods.AmountIncludingVAT						AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount							AS VATAmount,
	|		TableOfGoods.VATAmountCompl						AS VATAmountCompl,
	|		TableOfGoods.VATAmountMan						AS VATAmountMan,
	|		TableOfGoods.AmountExcludingVATCompl					AS AmountExcludingVATCompl,
	|		TableOfGoods.AmountExcludingVATMan					AS AmountExcludingVATMan	
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.Warehouse						AS Warehouse,
	|		TableTypesOfStocks_.SalesOrder					AS SalesOrder,
	|		TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate					AS VATRate,
	|		-TableTypesOfStocks_.Count					AS Count,
	|		-TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount					AS VATAmount,
	|		-TableTypesOfStocks_.VATAmountCompl				AS VATAmountCompl,
	|		-TableTypesOfStocks_.VATAmountMan					AS VATAmountMan,
	|		-TableTypesOfStocks_.AmountExcludingVATCompl				AS AmountExcludingVATCompl,
	|		-TableTypesOfStocks_.AmountExcludingVATMan				AS AmountExcludingVATMan	
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	WHERE
	|		TableTypesOfStocks_.ToIncomeExpenses
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.VATAmountCompl) <> 0
	|	OR SUM(TableOfGoods.VATAmountMan) <> 0
	|	OR SUM(TableOfGoods.AmountExcludingVATCompl) <> 0
	|	OR SUM(TableOfGoods.AmountExcludingVATMan) <> 0	
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// RecordingAsReceived
Function TemporaryDataTablesOfDocumentRegistration(ArrayOfReflectionOptions, UseShipmentWithDeferredTransferOfTitle2_5)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Date														AS Date,
	|	&Organization												AS Organization,
	|	&Warehouse														AS Warehouse,
	|	&Partner													AS Partner,
	|	&Counterparty													AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)	AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)		AS Contract,
	|	&Currency														AS Currency,
	|	&VATTaxation											AS VATTaxation,
	|	&BusinessOperation										AS BusinessOperation,
	|	FALSE														AS ThereAreTransactionsInTablePart,
	|	&ActivitiesAreSubjectToUTII									AS ActivitiesAreSubjectToUTII,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END														AS Department,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Manager
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END														AS Manager,
	|	CASE
	|		WHEN SalesOpportunitiesToCustomer.EnabledGoodsAssignmentInSalesOpportunity
	|				AND &GenerateInventoryOwnerAttributesBySalesOpportunities
	|			THEN &SalesOpportunity
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END														AS SalesOpportunity,
	|	&DocumentSalesOfGoodsAndServices											AS DocumentSalesOfGoodsAndServices,
	|	&SubjectToExcise											AS SubjectToExcise,
	|	&BusinessUnitProduction									AS BusinessUnitProduction,
	|	VALUE(Enum.InventoryTypes.OwnGoods)					AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON BusinessStructure.Ref = &Department
	|		
	|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		ON SalesOpportunitiesToCustomer.Ref = &SalesOpportunity
	|
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber												AS LineNumber,
	|	TableOfGoods.PostingOption											AS PostingOption,
	|	TableOfGoods.Products												AS Products,
	|	TableOfGoods.Characteristic											AS Characteristic,
	|	TableOfGoods.Series													AS Series,
	|	TableOfGoods.BatchesIndicationStatus										AS BatchesIndicationStatus,
	|	TableOfGoods.PartnerProducts										AS PartnerProducts,
	|	TableOfGoods.ItemsLocationAttributes								AS BasicAnalytics,
	|	CASE
	|		WHEN &UseShipmentWithDeferredTransferOfTitle2_5
	|				AND TableOfGoods.CorItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|			THEN TableOfGoods.CorItemsLocationAttributes
	|		ELSE TableOfGoods.ItemsLocationAttributes
	|	END																	AS ItemsLocationAttributes,
	|	-TableOfGoods.Count												AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				OR &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|			THEN 0
	|		ELSE -TableOfGoods.QuantityByGBRN
	|	END																	AS QuantityByGBRN,
	|	TableOfGoods.Warehouse													AS Warehouse,
	|	CASE
	|		WHEN &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|			THEN VALUE(Enum.WaysToCalculateReturnCost.FromSalesDocument)
	|		ELSE TableOfGoods.CostDefiningMethod
	|	END																	AS CostDefiningMethod,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)		AS ItemsLocationAttributesShipment,
	|	TableOfGoods.SalesOrder												AS SalesOrder,
	|	TableOfGoods.ARAPObject											AS ARAPObject,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)						AS SalesOpportunity,
	|	TableOfGoods.Purpose												AS Purpose,
	|	TableOfGoods.FEACNCode													AS FEACNCode,
	|	TableOfGoods.VATRate												AS VATRate,
	|	-(TableOfGoods.Sum + (TableOfGoods.VATAmount * &PriceIncludesVAT))	AS AmountIncludingVAT,
	|	-TableOfGoods.VATAmount												AS VATAmount,
	|	-TableOfGoods.VATAmountCompl											AS VATAmountCompl,
	|	-TableOfGoods.VATAmountMan												AS VATAmountMan,
	|	-TableOfGoods.AmountARAP										AS AmountARAP,
	|	0																		AS CommissionAmount,
	|	0																		AS AmountVATRemuneration,
	|	TableOfGoods.Cost_											AS Cost_,
	|	TableOfGoods.CostExcludingVAT_										AS CostExcludingVAT_,
	|	TableOfGoods.CostLocal										AS CostLocal,
	|	TableOfGoods.CDCost											AS CDCost,
	|	TableOfGoods.TDCost											AS TDCost,
	|	FALSE																	AS SelectTypesOfStocks,
	|	TableOfGoods.RowCode												AS RowCode,
	|	CASE
	|		WHEN &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|			THEN VALUE(Catalog.CCDNumbers.EmptyRef)
	|		ELSE TableOfGoods.CCDNumber
	|	END																	AS CCDNumber,
	|	TableOfGoods.ExpenseItem											AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses										AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension									AS AssetsLiabilitiesDimension,
	|	TableOfGoods.ToExpenseAs											AS ToExpenseAs,
	|	-TableOfGoods.AmountExcludingVATCompl											AS AmountExcludingVATCompl,
	|	-TableOfGoods.AmountExcludingVATMan											AS AmountExcludingVATMan
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|WHERE
	|	TableOfGoods.PostingOption IN(&ArrayOfReflectionOptions)
	|	AND NOT TableOfGoods.Count = 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					 AS LineNumber,
	|	TableOfGoods.PostingOption				 AS PostingOption,
	|	TableOfGoods.Products					 AS Products,
	|	TableOfGoods.Characteristic				 AS Characteristic,
	|	TableOfGoods.Purpose					 AS Purpose,
	|	Dimension.Series								 AS Series,
	|	TableOfGoods.BatchesIndicationStatus			 AS BatchesIndicationStatus,
	|	TableOfGoods.PartnerProducts 		 AS PartnerProducts,
	|	TableOfGoods.BasicAnalytics			 AS BasicAnalytics,
	|	TableOfGoods.ItemsLocationAttributes	 AS ItemsLocationAttributes,
	|	TableOfGoods.Count					 AS Count,
	|	TableOfGoods.QuantityByGBRN				 AS QuantityByGBRN,
	|	TableOfGoods.Warehouse						 AS Warehouse,
	|	&DocumentSalesOfGoodsAndServices							 AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CostDefiningMethod AS CostDefiningMethod,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)AS ItemsLocationAttributesShipment,
	|	TableOfGoods.SalesOrder					 AS SalesOrder,
	|	TableOfGoods.ARAPObject				 AS ARAPObject,
	|	TableOfGoods.FEACNCode						 AS FEACNCode,
	|	TableOfGoods.VATRate					 AS VATRate,
	|	TableOfGoods.AmountIncludingVAT					 AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						 AS VATAmount,
	|	TableOfGoods.VATAmountCompl					 AS VATAmountCompl,
	|	TableOfGoods.VATAmountMan					 AS VATAmountMan,
	|	TableOfGoods.AmountARAP			 AS AmountARAP,
	|	0											 AS CommissionAmount,
	|	0											 AS AmountVATRemuneration,
	|	TableOfGoods.Cost_				 AS Cost_,
	|	TableOfGoods.CostExcludingVAT_			 AS CostExcludingVAT_,
	|	TableOfGoods.CostLocal			 AS CostLocal,
	|	TableOfGoods.CDCost				 AS CDCost,
	|	TableOfGoods.TDCost				 AS TDCost,
	|	TableOfGoods.SalesOpportunity						 AS SalesOpportunity,
	|	TableOfGoods.SelectTypesOfStocks			 AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber						 AS CCDNumber,
	|
	|	TableOfGoods.ExpenseItem				 AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses			 AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension		 AS AssetsLiabilitiesDimension,
	|	TableOfGoods.ToExpenseAs				 AS ToExpenseAs,
	|	TableOfGoods.AmountExcludingVATCompl 				 AS AmountExcludingVATCompl,
	|	TableOfGoods.AmountExcludingVATMan				 AS AmountExcludingVATMan
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|
	|WHERE
	|	CatalogProducts.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|											VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber					 AS LineNumber,
	|	TableOfGoods.PostingOption				 AS PostingOption,
	|	TableOfGoods.Products					 AS Products,
	|	TableOfGoods.Characteristic				 AS Characteristic,
	|	TableOfGoods.Purpose					 AS Purpose,
	|	TableOfGoods.Series						 AS Series,
	|	TableOfGoods.BatchesIndicationStatus			 AS BatchesIndicationStatus,
	|	TableOfGoods.PartnerProducts 		 AS PartnerProducts,
	|	TableOfGoods.BasicAnalytics			 AS BasicAnalytics,
	|	TableOfGoods.ItemsLocationAttributes	 AS ItemsLocationAttributes,
	|	TableOfGoods.Count					 AS Count,
	|	TableOfGoods.QuantityByGBRN				 AS QuantityByGBRN,
	|	Dimension.StorageLocation						 AS Warehouse,
	|	&DocumentSalesOfGoodsAndServices							 AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.CostDefiningMethod AS CostDefiningMethod,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)AS ItemsLocationAttributesShipment,
	|	TableOfGoods.SalesOrder					 AS SalesOrder,
	|	TableOfGoods.ARAPObject				 AS ARAPObject,
	|	TableOfGoods.FEACNCode						 AS FEACNCode,
	|	TableOfGoods.VATRate					 AS VATRate,
	|	TableOfGoods.AmountIncludingVAT					 AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						 AS VATAmount,
	|	TableOfGoods.VATAmountCompl					 AS VATAmountCompl,
	|	TableOfGoods.VATAmountMan					 AS VATAmountMan,
	|	TableOfGoods.AmountARAP			 AS AmountARAP,
	|	0											 AS CommissionAmount,
	|	0											 AS AmountVATRemuneration,
	|	TableOfGoods.Cost_				 AS Cost_,
	|	TableOfGoods.CostExcludingVAT_			 AS CostExcludingVAT_,
	|	TableOfGoods.CostLocal			 AS CostLocal,
	|	TableOfGoods.CDCost				 AS CDCost,
	|	TableOfGoods.TDCost				 AS TDCost,
	|	TableOfGoods.SalesOpportunity						 AS SalesOpportunity,
	|	TableOfGoods.SelectTypesOfStocks			 AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber						 AS CCDNumber,
	|
	|	TableOfGoods.ExpenseItem				 AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses			 AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension		 AS AssetsLiabilitiesDimension,
	|	TableOfGoods.ToExpenseAs				 AS ToExpenseAs,
	|	TableOfGoods.AmountExcludingVATCompl 				 AS AmountExcludingVATCompl,
	|	TableOfGoods.AmountExcludingVATMan				 AS AmountExcludingVATMan
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	TableTypesOfStocks_.ToIncomeExpenses					AS ToIncomeExpenses,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS BasicAnalytics,
	|	CASE
	|		WHEN &UseShipmentWithDeferredTransferOfTitle2_5
	|				AND TableTypesOfStocks_.CorItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|			THEN TableTypesOfStocks_.CorItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.ItemsLocationAttributes
	|	END												AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	TableTypesOfStocks_.FEACNCode							AS FEACNCode,
	|	TableTypesOfStocks_.VATRate						AS VATRate,
	|	TableTypesOfStocks_.OriginWarehouse					AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse							AS Warehouse,
	|	TableTypesOfStocks_.SalesOrder						AS SalesOrder,
	|	TableTypesOfStocks_.ARAPObject					AS ARAPObject,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	TableTypesOfStocks_.PartnerProducts 			AS PartnerProducts,	
	|	TableTypesOfStocks_.Count						AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END												AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT						AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount							AS VATAmount,
	|	TableTypesOfStocks_.VATAmountCompl						AS VATAmountCompl,
	|	TableTypesOfStocks_.VATAmountMan						AS VATAmountMan,
	|	TableTypesOfStocks_.AmountARAP				AS AmountARAP,
	|	TableTypesOfStocks_.Cost_					AS Cost_,
	|	TableTypesOfStocks_.CostExcludingVAT_				AS CostExcludingVAT_,
	|	TableTypesOfStocks_.CostLocal				AS CostLocal,
	|	TableTypesOfStocks_.CDCost					AS CDCost,
	|	TableTypesOfStocks_.TDCost					AS TDCost,
	|	TableTypesOfStocks_.CostDefiningMethod	AS CostDefiningMethod,
	|	FALSE												AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.AmountExcludingVATCompl					AS AmountExcludingVATCompl,
	|	TableTypesOfStocks_.AmountExcludingVATMan					AS AmountExcludingVATMan,
	|	TableTypesOfStocks_.ExciseTaxAmount						AS ExciseTaxAmount,
	|	TableTypesOfStocks_.ExpenseItem					AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses				AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.ToExpenseAs					AS ToExpenseAs
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|WHERE
	|	NOT &SelectionOfStocksAccordingToDivergenceOption
	|		OR TableTypesOfStocks_.ToIncomeExpenses = &FilterToIncomeExpenses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	TableTypesOfStocks_.ToIncomeExpenses					AS ToIncomeExpenses,
	|	TableTypesOfStocks_.BasicAnalytics				AS BasicAnalytics,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	Dimension.Products								AS Products,
	|	Dimension.Characteristic							AS Characteristic,
	|	Dimension.Series										AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CorInventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|	UNDEFINED 										AS RecipientInventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)AS ItemsLocationAttributesShipment,
	|	&DocumentSalesOfGoodsAndServices									AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.CostDefiningMethod	AS CostDefiningMethod,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	TableTypesOfStocks_.FEACNCode							AS FEACNCode,
	|	TableTypesOfStocks_.VATRate						AS VATRate,
	|	TableTypesOfStocks_.OriginWarehouse					AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse							AS Warehouse,
	|	TableTypesOfStocks_.SalesOrder						AS SalesOrder,
	|	TableTypesOfStocks_.ARAPObject					AS ARAPObject,
	|	TableTypesOfStocks_.SalesOpportunity							AS SalesOpportunity,
	|	TableTypesOfStocks_.PartnerProducts				AS PartnerProducts,
	|	TableTypesOfStocks_.Count						AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN					AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT						AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount							AS VATAmount,
	|	TableTypesOfStocks_.VATAmountCompl						AS VATAmountCompl,
	|	TableTypesOfStocks_.VATAmountMan						AS VATAmountMan,
	|	TableTypesOfStocks_.AmountARAP				AS AmountARAP,
	|	TableTypesOfStocks_.Cost_					AS Cost_,
	|	TableTypesOfStocks_.CostExcludingVAT_				AS CostExcludingVAT_,
	|	TableTypesOfStocks_.CostLocal				AS CostLocal,
	|	TableTypesOfStocks_.CDCost					AS CDCost,
	|	TableTypesOfStocks_.TDCost					AS TDCost,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually		AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.AmountExcludingVATCompl					AS AmountExcludingVATCompl,
	|	TableTypesOfStocks_.AmountExcludingVATMan					AS AmountExcludingVATMan,
	|	TableTypesOfStocks_.ExciseTaxAmount						AS ExciseTaxAmount,
	|	TableTypesOfStocks_.ExpenseItem					AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses				AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.ToExpenseAs					AS ToExpenseAs
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	Products,
	|	Characteristic,
	|	Series";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Ref",								Ref);
	Query.SetParameter("Date",								Date);
	Query.SetParameter("Currency",								Currency);
	Query.SetParameter("Organization",						Organization);
	Query.SetParameter("Partner",							Partner);
	Query.SetParameter("Counterparty",							Counterparty);
	Query.SetParameter("Manager",							Manager);
	Query.SetParameter("Department",						Department);
	Query.SetParameter("SalesOpportunity",								SalesOpportunity);
	Query.SetParameter("Warehouse",								Warehouse);
	Query.SetParameter("VATTaxation",					VATTaxation);
	Query.SetParameter("PriceIncludesVAT",					?(PriceIncludesVAT, 0, 1));
	Query.SetParameter("BusinessOperation",				AdjustmentKind);
	Query.SetParameter("ActivitiesAreSubjectToUTII",			(VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToUTII));
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers", GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities",	GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.SetParameter("TableOfGoods",						Discrepancies);
	Query.SetParameter("TableTypesOfStocks_",					InventoryOwnerAttributesGoodsReceipt);
	Query.SetParameter("ArrayOfReflectionOptions",			ArrayOfReflectionOptions);
	Query.SetParameter("DocumentSalesOfGoodsAndServices",					DocumentBasis);
	Query.SetParameter("SaleByOrders",					SaleByOrders);
	Query.SetParameter("AdjustingEntryType",					AdjustingEntryType);
	ThereIsWriteOffOption =
		ArrayOfReflectionOptions.Find(Enums.CreditNoteRecordingOptions.ToExpenseAs) <> Undefined;
	
	SelectionOfStocksAccordingToDivergenceOption = Not ThereIsWriteOffOption
										Or (ThereIsWriteOffOption
											And ArrayOfReflectionOptions.Count() = 1);
	
	Query.SetParameter("SubjectToExcise",
								?(BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
										And Not ThereIsWriteOffOption,
									SubjectToExcise,
									False));
	Query.SetParameter("BusinessUnitProduction",
								?(BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
										And Not ThereIsWriteOffOption,
									BusinessUnitProduction,
									Catalogs.BusinessStructure.EmptyRef()));
	Query.SetParameter("FilterToIncomeExpenses",				ThereIsWriteOffOption);
	Query.SetParameter("SelectionOfStocksAccordingToDivergenceOption",	SelectionOfStocksAccordingToDivergenceOption);
	Query.SetParameter("UseShipmentWithDeferredTransferOfTitle2_5",
								UseShipmentWithDeferredTransferOfTitle2_5);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Function CheckChangesToProductsRegistration(TempTablesManager)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		CASE
	|			WHEN TableOfGoods.PostingOption IN (
	|					VALUE(Enum.CreditNoteRecordingOptions.ToExpenseAs),
	|					VALUE(Enum.CreditNoteRecordingOptions.RecordInOtherIncome))
	|				THEN TRUE
	|			ELSE FALSE
	|		END											AS ToIncomeExpenses,
	|		TableOfGoods.SalesOrder						AS SalesOrder,
	|		TableOfGoods.ARAPObject					AS ARAPObject,
	|		TableOfGoods.BasicAnalytics				AS ItemsLocationAttributes,
	|		CASE
	|			WHEN &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|				THEN TableOfGoods.CCDNumber
	|			ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|		END											AS CCDNumber,
	|		TableOfGoods.FEACNCode							AS FEACNCode,
	|		TableOfGoods.VATRate						AS VATRate,
	|		TableOfGoods.Count						AS Count,
	|		TableOfGoods.AmountIncludingVAT						AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount							AS VATAmount,
	|		TableOfGoods.VATAmountCompl						AS VATAmountCompl,
	|		TableOfGoods.VATAmountMan						AS VATAmountMan,
	|		TableOfGoods.AmountARAP				AS AmountARAP,
	|		TableOfGoods.Cost_					AS Cost_,
	|		TableOfGoods.CostExcludingVAT_				AS CostExcludingVAT_,
	|		TableOfGoods.CostLocal				AS CostLocal,
	|		TableOfGoods.CDCost					AS CDCost,
	|		TableOfGoods.TDCost					AS TDCost,
	|		TableOfGoods.CostDefiningMethod	AS CostDefiningMethod,
	|		TableOfGoods.AmountExcludingVATCompl					AS AmountExcludingVATCompl,
	|		TableOfGoods.AmountExcludingVATMan					AS AmountExcludingVATMan
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ToIncomeExpenses					AS ToIncomeExpenses,
	|		TableTypesOfStocks_.SalesOrder						AS SalesOrder,
	|		TableTypesOfStocks_.ARAPObject					AS ARAPObject,
	|		TableTypesOfStocks_.BasicAnalytics				AS ItemsLocationAttributes,
	|		CASE
	|			WHEN &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|				THEN TableTypesOfStocks_.CCDNumber
	|			ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|		END												AS CCDNumber,
	|		TableTypesOfStocks_.FEACNCode							AS FEACNCode,
	|		TableTypesOfStocks_.VATRate						AS VATRate,
	|		-TableTypesOfStocks_.Count						AS Count,
	|		-TableTypesOfStocks_.AmountIncludingVAT						AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount						AS VATAmount,
	|		-TableTypesOfStocks_.VATAmountCompl					AS VATAmountCompl,
	|		-TableTypesOfStocks_.VATAmountMan						AS VATAmountMan,
	|		-TableTypesOfStocks_.AmountARAP				AS AmountARAP,
	|		-TableTypesOfStocks_.Cost_					AS Cost_,
	|		-TableTypesOfStocks_.CostExcludingVAT_				AS CostExcludingVAT_,
	|		-TableTypesOfStocks_.CostLocal				AS CostLocal,
	|		-TableTypesOfStocks_.CDCost					AS CDCost,
	|		-TableTypesOfStocks_.TDCost					AS TDCost,
	|		TableTypesOfStocks_.CostDefiningMethod	AS CostDefiningMethod,
	|		-TableTypesOfStocks_.AmountExcludingVATCompl					AS AmountExcludingVATCompl,
	|		-TableTypesOfStocks_.AmountExcludingVATMan					AS AmountExcludingVATMan
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.ARAPObject,
	|	TableOfGoods.ToIncomeExpenses,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.CCDNumber,
	|	TableOfGoods.FEACNCode,
	|	TableOfGoods.VATRate
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.VATAmountCompl) <> 0
	|	OR SUM(TableOfGoods.VATAmountMan) <> 0
	|	OR SUM(TableOfGoods.AmountARAP) <> 0
	|	OR SUM(TableOfGoods.Cost_) <> 0
	|	OR SUM(TableOfGoods.CostExcludingVAT_) <> 0
	|	OR SUM(TableOfGoods.CostLocal) <> 0
	|	OR SUM(TableOfGoods.CDCost) <> 0
	|	OR SUM(TableOfGoods.TDCost) <> 0
	|	OR SUM(TableOfGoods.AmountExcludingVATCompl) <> 0
	|	OR SUM(TableOfGoods.AmountExcludingVATMan) <> 0";
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("AdjustingEntryType", AdjustingEntryType);
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Function TableToFillInInventoryOwnerAttributes(TempTablesManager)
	
	QueryTexts = New Array;
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(TempTablesManager));
	PartOfTheRequestText = 
	"SELECT
	|	TableOfGoods.LineNumber						AS LineNumber,
	|	TableOfGoods.Products						AS Products,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)	AS CurViewOfStocks,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)	AS InventoryOwnerAttribute,
	|	DocumentDataTable.Organization				AS Organization,
	|	DocumentDataTable.BusinessOperation	AS BusinessOperation,
	|	FALSE											AS ThisIsReusablePackage,
	|	DocumentDataTable.Terms				AS Terms,
	|	VALUE(Catalog.Currencies.EmptyRef)		AS Currency,
	|	DocumentDataTable.VATTaxation		AS VATTaxation,
	|	DocumentDataTable.VATTaxation		AS TaxationOfOrganization,
	|	DocumentDataTable.Partner					AS GoodsOwner,
	|	DocumentDataTable.Counterparty				AS Counterparty,
	|	DocumentDataTable.Contract					AS Contract,
	|	CASE
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN DocumentDataTable.SubjectToExcise
	|		ELSE FALSE
	|	END											AS SubjectToExcise,
	|	CASE
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN DocumentDataTable.BusinessUnitProduction
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END											AS BusinessUnitProduction,
	|	DocumentDataTable.InventoryType				AS InventoryType
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE
	|		
	|		LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|		ON TableOfGoods.Products = Category_Data.Products
	|";
	QueryTexts.Add(PartOfTheRequestText);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	
	Query.SetParameter("Date",	BaseDocumentDate());
	Query.SetParameter("Country",	RegistrationCountry);
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Result = Query.ExecuteBatchWithIntermediateData();
	
	Return Result[Result.UBound()].Unload();
	
EndFunction

///////////////////////////////////////////////////////////////////////////////
// Revenue adjustment

Function TemporaryDataTablesOfRevenueAdjustmentDocument()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&VATTaxation AS VATTaxation,
	|	CASE
	|		WHEN ISNULL(BusinessStructure.OptionOfAssignedAccountingOfGoods, UNDEFINED) = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Manager
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END AS Manager,
	|	&SubjectToExcise AS SubjectToExcise,
	|	&BusinessUnitProduction AS BusinessUnitProduction,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON BusinessStructure.Ref = &Department
	|
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.PartnerProducts	AS PartnerProducts,
	|	TableOfGoods.SetAccountingDimension AS SetAccountingDimension,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE
	|		WHEN TableOfGoods.RowCode = 0
	|			THEN TableOfGoods.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.SalesOrder AS SalesOrder,
	|	TableOfGoods.ARAPObject AS ARAPObject,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.FEACNCode AS FEACNCode,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Sum + TableOfGoods.VATAmount * &PriceIncludesVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.VATAmountCompl AS VATAmountCompl,
	|	TableOfGoods.VATAmountMan AS VATAmountMan,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	TableOfGoods.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	TableOfGoods.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	CASE
	|		WHEN &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.StandardAdjustment)
	|			THEN VALUE(Catalog.CCDNumbers.EmptyRef)
	|		ELSE TableOfGoods.CCDNumber
	|	END AS CCDNumber,
	|
	|	TableOfGoods.ExpenseItem				 AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses			 AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension		 AS AssetsLiabilitiesDimension,
	|	TableOfGoods.ToExpenseAs				 AS ToExpenseAs,
	|	TableOfGoods.Count					 AS Count
	|
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	(TableOfGoods.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.IncreaseSale)
	|			OR TableOfGoods.PostingOption = VALUE(Enum.CreditNoteRecordingOptions.ReduceSale))
	|	AND (NOT &BusinessOperation IN(
	|			VALUE(Enum.BusinessTransactions.ReportToMaterialProvider2_5),
	|			VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|			VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|			VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|		OR TableOfGoods.Count = 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.FEACNCode AS FEACNCode,
	|	TableTypesOfStocks_.PartnerProducts AS PartnerProducts,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.SalesOrder AS SalesOrder,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.VATAmountCompl AS VATAmountCompl,
	|	TableTypesOfStocks_.VATAmountMan AS VATAmountMan,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|	FALSE AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	TableTypesOfStocks_.AmountExcludingVATMan AS AmountExcludingVATMan,
	|
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.ToExpenseAs AS ToExpenseAs
	|
	|INTO TableTypesOfStocks_
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.PartnerProducts AS PartnerProducts,	
	|	TableOfGoods.SetAccountingDimension AS SetAccountingDimension,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.SalesOrder AS SalesOrder,
	|	TableOfGoods.ARAPObject AS ARAPObject,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.FEACNCode AS FEACNCode,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.VATAmountCompl AS VATAmountCompl,
	|	TableOfGoods.VATAmountMan AS VATAmountMan,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.ExpenseItem				 AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses			 AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension		 AS AssetsLiabilitiesDimension,
	|	TableOfGoods.ToExpenseAs				 AS ToExpenseAs,
	|	TableOfGoods.AmountExcludingVATCompl				 AS AmountExcludingVATCompl,
	|	TableOfGoods.AmountExcludingVATMan				 AS AmountExcludingVATMan
	|
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|WHERE
	|	CatalogProducts.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.PartnerProducts AS PartnerProducts,	
	|	TableOfGoods.SetAccountingDimension AS SetAccountingDimension,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.SalesOrder AS SalesOrder,
	|	TableOfGoods.ARAPObject AS ARAPObject,
	|	Dimension.StorageLocation AS Warehouse,
	|	TableOfGoods.FEACNCode AS FEACNCode,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.VATAmountCompl AS VATAmountCompl,
	|	TableOfGoods.VATAmountMan AS VATAmountMan,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.ExpenseItem				 AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses			 AS DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension		 AS AssetsLiabilitiesDimension,
	|	TableOfGoods.ToExpenseAs				 AS ToExpenseAs,
	|	TableOfGoods.AmountExcludingVATCompl				 AS AmountExcludingVATCompl,
	|	TableOfGoods.AmountExcludingVATMan				 AS AmountExcludingVATMan
	|
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND TableOfGoods.Count = 0";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Date",					Date);
	Query.SetParameter("Organization",			Organization);
	Query.SetParameter("AdjustmentKind",		AdjustmentKind);
	Query.SetParameter("BusinessOperation",	BusinessOperation);
	Query.SetParameter("Manager",				Manager);
	Query.SetParameter("Department",			Department);
	Query.SetParameter("VATTaxation",		VATTaxation);
	Query.SetParameter("PriceIncludesVAT",		?(PriceIncludesVAT, 0, 1));
	Query.SetParameter("TableOfGoods",			Discrepancies);
	Query.SetParameter("TableTypesOfStocks_",		InventoryOwnerAttributesRevenueAdjustment);
	Query.SetParameter("AdjustingEntryType",		AdjustingEntryType);
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers",
								GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	Query.SetParameter("SubjectToExcise",
								?(BusinessOperation = Enums.BusinessTransactions.SaleToCustomer,
									SubjectToExcise,
									False));
	Query.SetParameter("BusinessUnitProduction",
								?(BusinessOperation = Enums.BusinessTransactions.SaleToCustomer,
									BusinessUnitProduction,
									Catalogs.BusinessStructure.EmptyRef()));
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Function CheckChangeOfGoodsRevenueAdjustment(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.SalesOrder	AS SalesOrder,
	|		TableOfGoods.FEACNCode		AS FEACNCode,
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		CASE
	|			WHEN &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|				THEN TableOfGoods.CCDNumber
	|			ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|		END						AS CCDNumber,
	|		TableOfGoods.VATRate	AS VATRate,
	|		TableOfGoods.AmountIncludingVAT	AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount		AS VATAmount,
	|		TableOfGoods.VATAmountCompl	AS VATAmountCompl,
	|		TableOfGoods.VATAmountMan	AS VATAmountMan,
	|		TableOfGoods.AmountARAP	AS AmountARAP,
	|		TableOfGoods.AmountExcludingVATCompl		AS AmountExcludingVATCompl,
	|		TableOfGoods.AmountExcludingVATMan		AS AmountExcludingVATMan
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.SalesOrder	AS SalesOrder,
	|		TableTypesOfStocks_.FEACNCode		AS FEACNCode,
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		CASE
	|			WHEN &AdjustingEntryType = VALUE(Enum.AdjustingEntryTypes.AdjustmentByGoodsAndServices)
	|				THEN TableTypesOfStocks_.CCDNumber
	|			ELSE VALUE(Catalog.CCDNumbers.EmptyRef)
	|		END							AS CCDNumber,
	|		TableTypesOfStocks_.VATRate	AS VATRate,
	|		-TableTypesOfStocks_.AmountIncludingVAT	AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount	AS VATAmount,
	|		-TableTypesOfStocks_.VATAmountCompl AS VATAmountCompl,
	|		-TableTypesOfStocks_.VATAmountMan	AS VATAmountMan,
	|		-TableTypesOfStocks_.AmountARAP	AS AmountARAP,
	|		-TableTypesOfStocks_.AmountExcludingVATCompl		AS AmountExcludingVATCompl,
	|		-TableTypesOfStocks_.AmountExcludingVATMan		AS AmountExcludingVATMan
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.FEACNCode,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.CCDNumber,
	|	TableOfGoods.VATRate
	|
	|HAVING
	|	SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.VATAmountCompl) <> 0
	|	OR SUM(TableOfGoods.VATAmountMan) <> 0
	|	OR SUM(TableOfGoods.AmountARAP) <> 0
	|	OR SUM(TableOfGoods.AmountExcludingVATCompl) <> 0
	|	OR SUM(TableOfGoods.AmountExcludingVATMan) <> 0
	|");
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("AdjustingEntryType", AdjustingEntryType);
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure FillOutInventoryTypesRevenueAdjustment(TempTablesManager)
	
	InventoryOwnerAttributesRevenueAdjustment.Clear();
	
	If AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByGoodsAndServices Then
		FillInInventoryTypesRevenueAdjustmentsAdjustmentsBeforeEnteringBalances(TempTablesManager);
	Else
		FillInInventoryTypesRevenueAdjustmentRegularAdjustments(TempTablesManager);
	EndIf;
	
EndProcedure

Procedure FillInInventoryTypesRevenueAdjustmentsAdjustmentsBeforeEnteringBalances(TempTablesManager)
	
	QueryTexts = New Array;
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(TempTablesManager));
	PartOfTheRequestText =
	"SELECT
	|	MIN(TableOfGoods.LineNumber)				AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableOfGoods.SetAccountingDimension			AS SetAccountingDimension,
	|	TableOfGoods.Products						AS Products,
	|	TableOfGoods.PartnerProducts				AS PartnerProducts,
	|	TableOfGoods.CCDNumber							AS CCDNumber,
	|	TableOfGoods.Package							AS Package,
	|	TableOfGoods.VATRate						AS VATRate,
	|	TableOfGoods.Warehouse							AS Warehouse,
	|	TableOfGoods.FEACNCode							AS FEACNCode,
	|	TableOfGoods.SalesOrder						AS SalesOrder,
	|	TableOfGoods.ARAPObject					AS ARAPObject,
	|	SUM(TableOfGoods.AmountIncludingVAT)					AS AmountIncludingVAT,
	|	SUM(TableOfGoods.VATAmount)					AS VATAmount,
	|	SUM(TableOfGoods.VATAmountCompl)				AS VATAmountCompl,
	|	SUM(TableOfGoods.VATAmountMan)				AS VATAmountMan,
	|	SUM(TableOfGoods.AmountARAP)		AS AmountARAP,
	|	SUM(TableOfGoods.AmountExcludingVATCompl)			AS AmountExcludingVATCompl,
	|	SUM(TableOfGoods.AmountExcludingVATMan)			AS AmountExcludingVATMan,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)	AS InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)	AS CurViewOfStocks,
	|	FALSE											AS ThisIsReusablePackage,
	|	DocumentDataTable.Organization				AS Organization,
	|	&AdjustmentKind								AS BusinessOperation,
	|	CASE
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN DocumentDataTable.SubjectToExcise
	|		ELSE FALSE
	|	END											AS SubjectToExcise,
	|	CASE
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN DocumentDataTable.BusinessUnitProduction
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END											AS BusinessUnitProduction,
	|	VALUE(Enum.InventoryTypes.OwnGoods)		AS InventoryType,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.Currencies.EmptyRef)		AS Currency,
	|	DocumentDataTable.VATTaxation		AS VATTaxation,
	|	DocumentDataTable.VATTaxation		AS TaxationOfOrganization,
	|	UNDEFINED									AS GoodsOwner,
	|	UNDEFINED									AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE
	|		
	|		LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|		ON TableOfGoods.Products = Category_Data.Products
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.SetAccountingDimension,
	|	TableOfGoods.Products,
	|	TableOfGoods.CCDNumber,
	|	TableOfGoods.Package,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.FEACNCode,
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.ARAPObject,
	|	TableOfGoods.PartnerProducts,
	|	CASE
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN DocumentDataTable.SubjectToExcise
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN DocumentDataTable.BusinessUnitProduction
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END,
	|	DocumentDataTable.Organization,
	|	DocumentDataTable.VATTaxation
	|
	|HAVING
	|	SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.VATAmountCompl) <> 0
	|	OR SUM(TableOfGoods.VATAmountMan) <> 0
	|	OR SUM(TableOfGoods.AmountARAP) <> 0
	|	OR SUM(TableOfGoods.AmountExcludingVATCompl) <> 0
	|	OR SUM(TableOfGoods.AmountExcludingVATMan) <> 0";
	
	QueryTexts.Add(PartOfTheRequestText);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("AdjustmentKind",	AdjustmentKind);
	Query.SetParameter("AdjustingEntryType",	AdjustingEntryType);
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	
	Query.SetParameter("Date",	BaseDocumentDate());
	Query.SetParameter("Country",	RegistrationCountry);
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	QueryResult = Query.ExecuteBatchWithIntermediateData();
	
	If QueryResult[QueryResult.UBound()].IsEmpty() Then
		Return;
	EndIf;
	
	TableOfRegistrationProducts = QueryResult[QueryResult.UBound()].Unload();
	
	InventoriesServer.FillStockTypesByDefault(TempTablesManager, TableOfRegistrationProducts);
	InventoryOwnerAttributesRevenueAdjustment.Load(TableOfRegistrationProducts);
	
EndProcedure

Procedure FillInInventoryTypesRevenueAdjustmentRegularAdjustments(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = "
	|SELECT
	|	DocumentsData.Ref AS Ref,
	|	DocumentsData.AdjustmentKind AS BusinessOperation
	|
	|INTO DocumentDataTable_
	|FROM
	|	Document.SaleAdjustment AS DocumentsData
	|
	|WHERE
	|	DocumentsData.Ref = &Ref
	|;";
	Query.SetParameter("Ref", Ref);
	Query.Execute();
	
	Query.Text = Documents.SaleAdjustment.QueryTextTTTypesOfStocks();
	
	Documents.SaleAdjustment.SetTTStockOptions(
		Query,
		False, // ConvertToLocalCurrency
		False, // IncludingBeforeAdjustment
		DocumentBasis);
	
	Query.Execute();
	
	Query.Text = "
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.SetAccountingDimension,
	|	TableOfGoods.Package,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.FEACNCode,
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.ARAPObject,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.PartnerProducts
	|INTO TableOfProductsTotal
	|FROM
	|	TableOfGoods AS TableOfGoods
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.SetAccountingDimension,
	|	TableOfGoods.Package,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.FEACNCode,
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.ARAPObject,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.PartnerProducts
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	SetAccountingDimension,
	|	Package,
	|	VATRate
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	InventoryKinds.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.VATRate,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.FEACNCode,
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.ARAPObject,
	|	TableOfGoods.PartnerProducts,
	|	SUM(InventoryKinds.Count),
	|	InventoryKinds.ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses,
	|	InventoryKinds.AssetsLiabilitiesDimension
	|
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|
	|	LEFT JOIN TableOfProductsTotal AS TableOfGoods
	|	ON
	|		InventoryKinds.ItemsLocationAttributes = TableOfGoods.ItemsLocationAttributes
	|		AND InventoryKinds.SetAccountingDimension = TableOfGoods.SetAccountingDimension
	|		AND InventoryKinds.Package = TableOfGoods.Package
	|		AND InventoryKinds.VATRate = TableOfGoods.VATRate
	|		AND InventoryKinds.ExpenseItem = TableOfGoods.ExpenseItem
	|		AND InventoryKinds.DimensionOfExpenses = TableOfGoods.DimensionOfExpenses
	|		AND InventoryKinds.AssetsLiabilitiesDimension = TableOfGoods.AssetsLiabilitiesDimension
	|
	|GROUP BY
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	InventoryKinds.Package,
	|	InventoryKinds.InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber,
	|	InventoryKinds.VATRate,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.FEACNCode,
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.ARAPObject,
	|	InventoryKinds.ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses,
	|	InventoryKinds.AssetsLiabilitiesDimension,
	|	TableOfGoods.PartnerProducts
	|
	|HAVING
	|	SUM(InventoryKinds.Count) > 0
	|
	|TOTALS BY
	|	InventoryKinds.ItemsLocationAttributes,
	|	InventoryKinds.SetAccountingDimension,
	|	InventoryKinds.Package,
	|	InventoryKinds.VATRate,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.PartnerProducts,
	|	TableOfGoods.FEACNCode,
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.ARAPObject,
	|	InventoryKinds.ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses,
	|	InventoryKinds.AssetsLiabilitiesDimension
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.SetAccountingDimension,
	|	TableOfGoods.Package,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.FEACNCode,
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.ARAPObject,
	|	TableOfGoods.PartnerProducts,
	|	SUM(TableOfGoods.AmountIncludingVAT),
	|	SUM(TableOfGoods.VATAmount),
	|	SUM(TableOfGoods.VATAmountCompl),
	|	SUM(TableOfGoods.VATAmountMan),
	|	SUM(TableOfGoods.AmountARAP),
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension
	|FROM
	|	TableOfGoods AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.SetAccountingDimension,
	|	TableOfGoods.Package,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.Warehouse,
	|	TableOfGoods.FEACNCode,
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.ARAPObject,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses,
	|	TableOfGoods.AssetsLiabilitiesDimension,
	|	TableOfGoods.PartnerProducts
	|;
	|";
	
	ResultsArray = Query.ExecuteBatch();
	InventoryKindTree = ResultsArray[1].Unload(QueryResultIteration.ByGroups); // ValueTable
	TableOfDiscrepancies = ResultsArray[2].Unload();
	
	InventoryKindTree.Columns.Add("AmountIncludingVAT");
	InventoryKindTree.Columns.Add("VATAmount");
	InventoryKindTree.Columns.Add("AmountARAP");
	InventoryKindTree.Columns.Add("VATAmountCompl");
	InventoryKindTree.Columns.Add("VATAmountMan");
	
	FilterStructure1 = New Structure("ItemsLocationAttributes, SetAccountingDimension, Package, VATRate, SalesOrder, ARAPObject, FEACNCode,
		|ExpenseItem, DimensionOfExpenses, AssetsLiabilitiesDimension, PartnerProducts");
	
	For Each LinesByProductName In InventoryKindTree.Rows Do
		For Each LinesBySetProductType In LinesByProductName.Rows Do
			For Each RowsByPackages In LinesBySetProductType.Rows Do
				For Each LinesByVATRates In RowsByPackages.Rows Do
					For Each RowsByWarehouse In LinesByVATRates.Rows Do
						For Each LinesAccordingToPartnerSProductList In RowsByWarehouse.Rows Do
							For Each LinesByHSCodes In LinesAccordingToPartnerSProductList.Rows Do
								For Each LinesForOrders In LinesByHSCodes.Rows Do
									For Each RowsByCalculationObjects In LinesForOrders.Rows Do
										For Each LineByArticles In RowsByCalculationObjects.Rows Do
											For Each ExpenseAnalyticsLine In LineByArticles.Rows Do
												For Each LineAnalyticsOfAssetsLiabilities In ExpenseAnalyticsLine.Rows Do
													
													AllocationBase = LineAnalyticsOfAssetsLiabilities.Rows.UnloadColumn("Count");
													
													FillPropertyValues(FilterStructure1, LineAnalyticsOfAssetsLiabilities);
													LinesOfDivergence = TableOfDiscrepancies.FindRows(FilterStructure1);
													If LinesOfDivergence.Count() = 0 Then
														Continue;
													EndIf;
													
													If LinesOfDivergence[0].AmountIncludingVAT <> 0 Then
														DistributedAmounts = Common.DistributeAmountInProportionToCoefficients(LinesOfDivergence[0].AmountIncludingVAT, AllocationBase);
														LineAnalyticsOfAssetsLiabilities.Rows.LoadColumn(DistributedAmounts, "AmountIncludingVAT");
													EndIf;
													
													If LinesOfDivergence[0].VATAmount <> 0 Then
														DistributedAmounts = Common.DistributeAmountInProportionToCoefficients(LinesOfDivergence[0].VATAmount, AllocationBase);
														LineAnalyticsOfAssetsLiabilities.Rows.LoadColumn(DistributedAmounts, "VATAmount");
													EndIf;
													
													If LinesOfDivergence[0].AmountARAP <> 0 Then
														DistributedAmounts = Common.DistributeAmountInProportionToCoefficients(LinesOfDivergence[0].AmountARAP, AllocationBase);
														LineAnalyticsOfAssetsLiabilities.Rows.LoadColumn(DistributedAmounts, "AmountARAP");
													EndIf;
													
													If LinesOfDivergence[0].VATAmountCompl <> 0 Then
														DistributedAmounts = Common.DistributeAmountInProportionToCoefficients(LinesOfDivergence[0].VATAmountCompl, AllocationBase);
														LineAnalyticsOfAssetsLiabilities.Rows.LoadColumn(DistributedAmounts, "VATAmountCompl");
													EndIf;
													
													If LinesOfDivergence[0].VATAmountMan <> 0 Then
														DistributedAmounts = Common.DistributeAmountInProportionToCoefficients(LinesOfDivergence[0].VATAmountMan, AllocationBase);
														LineAnalyticsOfAssetsLiabilities.Rows.LoadColumn(DistributedAmounts, "VATAmountMan");
													EndIf;
													
													For Each DataOfTypesOfStocks In LineAnalyticsOfAssetsLiabilities.Rows Do
															NewRow = InventoryOwnerAttributesRevenueAdjustment.Add();
															FillPropertyValues(NewRow, DataOfTypesOfStocks);
													EndDo;
												
												EndDo;
											EndDo;
										EndDo;
									EndDo;
								EndDo;
							EndDo;
						EndDo;
					EndDo;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Function CheckFillingForDiscrepancies(NotCheckedAttributeArray, Cancel)
	
	AmountForOtherIncome		= 0;
	AmountForOtherExpenses	= 0;
	RecordInOtherIncome	= False;
	ToExpenseAs		= False;
	
	For Each LineOfDiscrepancies In Discrepancies Do
		
		If LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.RecordInOtherIncome Then
			RecordInOtherIncome = True;
			AmountForOtherIncome = AmountForOtherIncome + ?(LineOfDiscrepancies.AmountIncludingVAT < 0, -LineOfDiscrepancies.AmountIncludingVAT, LineOfDiscrepancies.AmountIncludingVAT);
		ElsIf LineOfDiscrepancies.PostingOption = Enums.CreditNoteRecordingOptions.ToExpenseAs Then
			ToExpenseAs = True;
			AmountForOtherExpenses = AmountForOtherExpenses + ?(LineOfDiscrepancies.AmountIncludingVAT < 0, -LineOfDiscrepancies.AmountIncludingVAT, LineOfDiscrepancies.AmountIncludingVAT);
		EndIf;
		
	EndDo;
	
	If AdjustmentKind = Enums.BusinessTransactions.SaleOfOverdeliveredGoods
		Or AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods Then
		
		NotCheckedAttributeArray.Add("Discrepancies.PostingOption");
		
	Else
		NotCheckedAttributeArray.Add("Goods.PostingOption");
	EndIf;
	
	If AmountForOtherIncome = 0 Then
		NotCheckedAttributeArray.Add("BusinessUnit");
	EndIf;
	
	If AmountForOtherExpenses = 0 Then
		NotCheckedAttributeArray.Add("BusinessUnitExpenses");
	EndIf;
	
	Result = New Structure("RecordInOtherIncome, ToExpenseAs", RecordInOtherIncome, ToExpenseAs);
	
	Return Result;
	
EndFunction

Procedure CheckCompletionOfDebtAdjustmentTable(Cancel)
	
	If AdjustmentKind <> Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
		Return;
	EndIf;
	
	ErrorTemplate	= NStr("vi = 'Tại dòng ""%1"" số tiền ghi giảm lớn hơn số tiền bán hàng';
							|ru = 'В строке ""%1"" сумма уменьшения больше суммы продажи';
							|en = 'In the ""%1"" line the decrease amount is greater than the sales amount'; fa = 'In the ""%1"" line the decrease amount is greater than the sales amount';
							|it = 'Nella riga ""%1"" l''importo di riduzione è maggiore dell''importo di vendita';
							|pl = 'W wierszu ""%1"" kwota zmniejszenia jest większa niż kwota sprzedaży';
							|tr = '""%1"" satırında azalma miktarı satış miktarından fazla'");
	DataKey	= TMCommonUse.DataKeyForMessageToUser(ThisObject);
	
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

Procedure CheckFillingOutCostDeterminationMethod(ReferenceDocumentDateForCertificate, DocumentDate, Cancel)
	
	UseCostAccounting = CalculationOfCostCached.CostCalculationIsPossible(DocumentDate);
	CostAccountingAtBase = CalculationOfCostCached.CostCalculationIsPossible(ReferenceDocumentDateForCertificate);
	
	If Not UseCostAccounting
		Or CostAccountingAtBase Then
		Return;
	EndIf;
	
	ErrorTemplate	= NStr("vi = 'Trong dòng ""%1"" chưa chỉ ra phương thức tính toán giá vốn.';
							|ru = 'В строке ""%1"" не указан способ расчета себестоимости.';
							|en = 'The cost calculation method is not specified in line %1.'; fa = 'The cost calculation method is not specified in line %1.';
							|it = 'В строке ""%1"" не указан способ расчета себестоимости.';
							|pl = 'The cost calculation method is not specified in line %1.';
							|tr = '""%1"" satırında maliyet hesaplama yöntemi belirtilmedi.'");
	DataKey	= TMCommonUse.DataKeyForMessageToUser(ThisObject);
	
	For Each TableRow In Discrepancies Do
		
		If TableRow.Count < 0
			And Not ValueIsFilled(TableRow.CostDefiningMethod)
			And Not TableRow.PostingOption = Enums.CreditNoteRecordingOptions.ToExpenseAs Then
			
			ErrorMessage = StrTemplate(ErrorTemplate, TableRow.LineNumber);
			
			Field = CommonClientServer.PathToTabularSection("Discrepancies",
																	TableRow.LineNumber,
																	"MethodForDeterminingTheCostOfALine");
																	
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
	
	AttributesRow = Documents.SaleAdjustment.KeyAttributesOFRelationshipOfTableRows(AdjustmentOfPurchaseOfOtherAssetServices);
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

Function GetDocumentAmount()
	
	If AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfSalesIncreaseInDebtConsolidated
		Or AdjustmentKind = Enums.BusinessTransactions.AdjustmentOfImplementationDebtReductionConsolidated Then
		
		TotalAmount__ = ARAPAdjustment.Total("AdjustmentSum");
		
	ElsIf ValueIsFilled(DocumentBasis)
		And TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoice") Then
		
		SetPrivilegedMode(True);
		FoundationDocumentData = Common.ObjectAttributesValues(DocumentBasis,
			"ToReturnReusablePackage, PackageDepositIsRequired");
		
		ToReturnReusablePackage = FoundationDocumentData.ToReturnReusablePackage;
		PackageDepositIsRequired = FoundationDocumentData.PackageDepositIsRequired;
		SetPrivilegedMode(False);
		
		Query = New Query("
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.AmountIncludingVAT AS AmountIncludingVAT
		|INTO
		|	Goods
		|FROM
		|	&Goods AS Goods
		|;
		|SELECT
		|	ISNULL(SUM(Goods.AmountIncludingVAT),0) AS AmountIncludingVAT
		|FROM
		|	Goods AS Goods
		|WHERE
		|	Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|	OR (Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) 
		|		AND (NOT &ToReturnReusablePackage OR &PackageDepositIsRequired))
		|");
		
		Query.SetParameter("Goods", Goods.Unload(,"Products,AmountIncludingVAT"));
		Query.SetParameter("ToReturnReusablePackage", ToReturnReusablePackage);
		Query.SetParameter("PackageDepositIsRequired", PackageDepositIsRequired);
		
		Upload0 = Query.Execute().Unload();
		TotalAmount__ = Upload0[0].AmountIncludingVAT;
	Else
		
		TotalAmount__ = PriceManagementSystemClientServer.GetDocumentAmount(Goods, PriceIncludesVAT)
		
	EndIf;
	
	Return TotalAmount__;
	
EndFunction

Procedure FillInOptionForRegistrationOfSale()
	
	If Not ValueIsFilled(SaleRegistrationOption) Then
		If Not GetFunctionalOption("UseDeedsOfTransfer") Then
			SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoice;
		Else
			Query = New Query(
			"SELECT
			|	Goods.Products AS Products
			|INTO
			|	TTProducts_1
			|FROM
			|	&Goods AS Goods
			|;
			|SELECT
			|	Goods.Products.Ref
			|FROM
			|	TTProducts_1 AS Goods
			|WHERE
			|	Goods.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer)");
			
			Query.SetParameter("Goods", Goods.Unload(,"Products"));
			QueryResult = Query.Execute();
			
			If QueryResult.IsEmpty() Then
				SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoice;
			EndIf;
			
			If QueryResult.Unload().Count() = Goods.Count() Then
				SaleRegistrationOption = Enums.SalesRegistrationOptions.DeedOfTransfer;
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(SaleRegistrationOption) Then
			SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoice;
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
				|tr = 'Düzeltme belgesi kaydedilmedi veya iptal edildi.
				|Belgenin kaydedilmesi mümkün değildir.'");
		Common.MessageToUser(ErrorText,,,, Cancel);
		
	EndIf;
	
	// Define the verification parameters
	Attributes = Documents.SaleAdjustment.ParametersForGettingDocumentBeingCorrected();
	FillPropertyValues(Attributes, ThisObject);
	CheckParameters = InformationRegisters.DocumentCorrections.DocumentCorrectionVerificationParameters();
	FillPropertyValues(CheckParameters, ThisObject,, "CorrectedDocument");
	CheckParameters.CorrectedDocument = Documents.SaleAdjustment.CorrectedDocument(Attributes);
	
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

Function VariantOfReflectionByLine(LineOfDiscrepancies, ItemsType, OtherAssetServiceAdjustment, LastPeriodAdjustment, AdjustingGiver)
	
	PostingOption = Undefined;
	
	If OtherAssetServiceAdjustment Then
		
		If LastPeriodAdjustment Then
		
			If LineOfDiscrepancies.AmountIncludingVAT < 0 Then
				PostingOption = Enums.CreditNoteRecordingOptions.ToExpenseAs;
			Else
				PostingOption = Enums.CreditNoteRecordingOptions.RecordInOtherIncome;
			EndIf;
			
		Else
			
			PostingOption = Enums.CreditNoteRecordingOptions.RecordInOtherIncome;
			
		EndIf;
	ElsIf AdjustingGiver Then
		
		If LineOfDiscrepancies.NumberOfPackages > 0 Then
			PostingOption = Enums.CreditNoteRecordingOptions.IncreaseSale;
		ElsIf LineOfDiscrepancies.NumberOfPackages < 0 Then
			PostingOption = Enums.CreditNoteRecordingOptions.ReduceSale;
		ElsIf LineOfDiscrepancies.AmountIncludingVAT < 0
			Or (LineOfDiscrepancies.AmountIncludingVAT = 0 And LineOfDiscrepancies.VATAmount < 0) Then
			PostingOption = Enums.CreditNoteRecordingOptions.ReduceSale;
		Else
			PostingOption = Enums.CreditNoteRecordingOptions.IncreaseSale;
		EndIf;
	ElsIf (ItemsType <> Enums.ItemsTypes.OwnGoods
		And ItemsType <> Enums.ItemsTypes.ReusablePackage)
		Or LineOfDiscrepancies.NumberOfPackages = 0 Then
		
		If LineOfDiscrepancies.AmountIncludingVAT < 0
			Or (LineOfDiscrepancies.AmountIncludingVAT = 0 And LineOfDiscrepancies.VATAmount < 0)
			Or (LineOfDiscrepancies.AmountIncludingVAT = 0 And LineOfDiscrepancies.VATAmount = 0
				And LineOfDiscrepancies.NumberOfPackages < 0) Then
			PostingOption = Enums.CreditNoteRecordingOptions.ReduceSale;
		Else
			PostingOption = Enums.CreditNoteRecordingOptions.IncreaseSale;
		EndIf;
		
	EndIf;
	
	Return PostingOption;
	
EndFunction

// Fills in the VAT Amount (Local) and VAT Amount (Man) columns in the tabular part of the document Discrepancy.
//
Procedure FillInVATAmountsLocalMans() Export
	
	DateOfCourse = CurrentSessionDate();
	
	ThisIsBugFix = AdjustmentKind = Enums.BusinessTransactions.ErrorCorrection
		And ValueIsFilled(DocumentBasis);
	
	If ThisIsBugFix Then
		
		Query = New Query;
		Query.SetParameter("DocumentBasis", DocumentBasis);
		Query.Text =
		"SELECT
		|	CAST(CASE
		|		WHEN SUM(BaseGoods.VATAmount) = 0
		|			THEN 0
		|		ELSE SUM(BaseGoods.VATAmountCompl) / SUM(BaseGoods.VATAmount)
		|	END AS NUMBER(10, 6)) AS LocalCoefficient,
		|	CAST(CASE
		|		WHEN SUM(BaseGoods.VATAmount) = 0
		|			THEN 0
		|		ELSE SUM(BaseGoods.VATAmountMan) / SUM(BaseGoods.VATAmount)
		|	END AS NUMBER(10, 6)) AS ManSCoefficient
		|FROM
		|	Document.CustomerInvoice.Goods AS BaseGoods
		|WHERE
		|	BaseGoods.Ref = &DocumentBasis";
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		LocalCoefficient = Selection.LocalCoefficient;
		ManSCoefficient = Selection.ManSCoefficient;
		
	ElsIf ValueIsFilled(Date) Then
		DateOfCourse = Date;
	EndIf;
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	BaseCurrency = SettingsValueCached.DefaultBaseCurrency();
	
	ForeignCurrencyTransaction = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
	
	For Each TSRow In Discrepancies Do
		
		AmountExcludingVAT = TSRow.AmountIncludingVAT - TSRow.VATAmount;
		
		If ARAPCurrency = LocalAccountingCurrency Then
			
			TSRow.VATAmountCompl = TSRow.VATAmount;
			
		ElsIf ForeignCurrencyTransaction Then
			
			If ThisIsBugFix Then
				
				AmountExcludingVATCompl = AmountExcludingVAT * LocalCoefficient;
				
			Else
				
				AmountExcludingVATCompl = ProcessingOfExchangeRatesTM.ConvertToCurrency(AmountExcludingVAT,
					BaseCurrency,
					ARAPCurrency,
					LocalAccountingCurrency,
					DateOfCourse);
				
			EndIf;
			
			TSRow.VATAmountCompl = PriceManagementSystemClientServer.CalculateVATAmount(
				AmountExcludingVATCompl,
				TSRow.VATRate,
				False);
			
		Else
			
			If ThisIsBugFix Then
				
				AmountIncludingVATCompl = TSRow.AmountIncludingVAT * LocalCoefficient;
				
			Else
					
				AmountIncludingVATCompl = ProcessingOfExchangeRatesTM.ConvertToCurrency(TSRow.AmountIncludingVAT,
					BaseCurrency,
					ARAPCurrency,
					LocalAccountingCurrency,
					DateOfCourse);
				
			EndIf;
			
			TSRow.VATAmountCompl = VATAccountingERPClientServer.CalculateVATAmount(
				AmountIncludingVATCompl,
				TSRow.VATRate,
				True);
			
		EndIf;
		
		If ARAPCurrency = ManagementAccountingCurrency Then
			
			TSRow.VATAmountMan = TSRow.VATAmount;
			
		ElsIf ForeignCurrencyTransaction Then
			
			If ThisIsBugFix Then
				
				AmountExcludingVATMan = AmountExcludingVAT * ManSCoefficient;
				
			Else
				
				AmountExcludingVATMan = ProcessingOfExchangeRatesTM.ConvertToCurrency(AmountExcludingVAT,
					BaseCurrency,
					ARAPCurrency,
					ManagementAccountingCurrency,
					DateOfCourse);
				
			EndIf;
			
			TSRow.VATAmountMan = PriceManagementSystemClientServer.CalculateVATAmount(
				AmountExcludingVATMan,
				TSRow.VATRate,
				False);
			
		Else
			
			If ThisIsBugFix Then
				
				AmountIncludingVATMan = TSRow.AmountIncludingVAT * ManSCoefficient;
				
			Else
					
				AmountIncludingVATMan = ProcessingOfExchangeRatesTM.ConvertToCurrency(TSRow.AmountIncludingVAT,
					BaseCurrency,
					ARAPCurrency,
					ManagementAccountingCurrency,
					DateOfCourse);
				
			EndIf;
			
			TSRow.VATAmountMan = VATAccountingERPClientServer.CalculateVATAmount(
				AmountIncludingVATMan,
				TSRow.VATRate,
				True);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInTheDiscrepancies() Export
	
	Discrepancies.Clear();
	
	If AdjustmentKind = Enums.BusinessTransactions.SaleOfOverdeliveredGoods
		Or AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods Then
		FillInProductDiscrepancies();
	Else
		FillInDiscrepanciesByDifference();
	EndIf;
	
	ThisIsTransferOfOwnership =
		BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
		Or AdditionalProperties.Property("EconomicOperationOfFoundation")
			And AdditionalProperties.EconomicOperationOfFoundation =
				Enums.BusinessTransactions.TransferOfTitleToGoods;
	
	If ThisIsTransferOfOwnership Then
		FillInVATAmountsLocalMans();
	EndIf;
	
EndProcedure

Procedure FillInDiscrepanciesByDifference()
	
	SetPrivilegedMode(True);
	
	KeyFields = "
	|	BaseDocumentLineCode,
	|	ProductsInSet,
	|	ItemVariantOfSet,
	|	Products,
	|	PartnerProducts,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Content,
	|	Package,
	|	SalesOrder,
	|	Warehouse,
	|	Department,
	|	VATRate,
	|	FEACNCode,
	|	IncomeItem,
	|	DimensionOfRevenue,
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	AssetsLiabilitiesDimension,
	|	ToExpenseAs";
	
	TempTablesManager = New TempTablesManager;
	
	ReferenceDocumentDateForCertificate = Common.ObjectAttributeValue(DocumentBasis, "Date");
	DocumentDate = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
	LastPeriodAdjustment = BegOfYear(DocumentDate) > BegOfYear(ReferenceDocumentDateForCertificate);
	OtherAssetServiceAdjustment = TypeOf(DocumentBasis) = Type("DocumentRef.CustomerInvoiceServicesAndAssets")
										Or AdjustingEntryType = Enums.AdjustingEntryTypes.AdjustmentByServicesAndOtherAssets;
	AdjustingGiver = False;
	AdjustingGiver =
		BusinessOperation = Enums.BusinessTransactions.ReportToMaterialProvider2_5
		Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
		Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5
		Or BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5;
	Documents.SaleAdjustment.CreateTemporaryTableOfSourceData(TempTablesManager,
																				DocumentBasis, Ref);
	
	BusinessTransactionParameter = Undefined;
	If ValueIsFilled(BusinessOperation) Then
		BusinessTransactionParameter = BusinessOperation;
	ElsIf AdditionalProperties.Property("EconomicOperationOfFoundation") Then
		BusinessTransactionParameter = AdditionalProperties.EconomicOperationOfFoundation;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("BusinessOperation", BusinessTransactionParameter);
	Query.SetParameter("NewData", Goods.Unload());
	Query.SetParameter("OtherAssetServiceAdjustment", OtherAssetServiceAdjustment);
	Query.SetParameter("CurPeriodAdjustment", Not LastPeriodAdjustment);
	Query.SetParameter("SaleAdjustment2_5", SaleAdjustment2_5);
	Query.SetParameter("RecordInProfitLossOfPreviousYears", RecordInProfitLossOfPreviousYears);
	Query.SetParameter("AdjustTaxBaseOfPreviousPeriod", AdjustTaxBaseOfPreviousPeriod);
	
	Query.Text =
	"SELECT
	|	NewData.LineNumber AS LineNumber,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN NewData.RowCode
	|		ELSE 0
	|	END AS BaseDocumentLineCode,
	|	NewData.ProductsInSet AS ProductsInSet,
	|	NewData.ItemVariantOfSet AS ItemVariantOfSet,
	|	NewData.Products AS Products,
	|	NewData.PartnerProducts AS PartnerProducts,
	|	NewData.Characteristic AS Characteristic,
	|	NewData.Purpose AS Purpose,
	|	NewData.Series AS Series,
	|	NewData.Content AS Content,
	|	NewData.Package AS Package,
	|	NewData.SalesOrder AS SalesOrder,
	|	NewData.Warehouse AS Warehouse,
	|	NewData.Department AS Department,
	|	NewData.VATRate AS VATRate,
	|	NewData.FEACNCode AS FEACNCode,
	|	CASE
	|		WHEN &OtherAssetServiceAdjustment
	|			AND (&CurPeriodAdjustment
	|				OR &SaleAdjustment2_5
	|					AND (NOT &RecordInProfitLossOfPreviousYears
	|						OR &AdjustTaxBaseOfPreviousPeriod))
	|			THEN NewData.IncomeItem
	|		ELSE
	|			VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|	END AS IncomeItem,
	|	CASE
	|		WHEN &OtherAssetServiceAdjustment
	|			AND (&CurPeriodAdjustment
	|				OR &SaleAdjustment2_5
	|					AND (NOT &RecordInProfitLossOfPreviousYears
	|						OR &AdjustTaxBaseOfPreviousPeriod))
	|			THEN NewData.DimensionOfRevenue
	|		ELSE
	|			UNDEFINED
	|	END AS DimensionOfRevenue,
	|	CASE
	|		WHEN NewData.NumberOfPackages = 0
	|			THEN
	|				CASE
	|					WHEN NewData.Count = 0
	|				THEN 1
	|				ELSE NewData.Count
	|			END
	|		ELSE NewData.NumberOfPackages
	|	END AS NumberOfPackages,
	|	CASE
	|		WHEN NewData.Count = 0
	|			THEN 1
	|		ELSE NewData.Count
	|	END AS Count,
	|	NewData.Sum AS Sum,
	|	NewData.VATAmount AS VATAmount,
	|	NewData.AmountIncludingVAT AS AmountIncludingVAT,
	|	NewData.ExpenseItem AS ExpenseItem,
	|	NewData.DimensionOfExpenses AS DimensionOfExpenses,
	|	NewData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	NewData.ToExpenseAs AS ToExpenseAs
	|
	|INTO NewDataFromTable
	|FROM
	|	&NewData AS NewData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewDataFromTable.BaseDocumentLineCode,
	|	NewDataFromTable.ProductsInSet,
	|	NewDataFromTable.ItemVariantOfSet,
	|	NewDataFromTable.Products,
	|	NewDataFromTable.PartnerProducts,
	|	NewDataFromTable.Characteristic,
	|	NewDataFromTable.Purpose,
	|	NewDataFromTable.Series,
	|	NewDataFromTable.Content,
	|	NewDataFromTable.Package,
	|	NewDataFromTable.SalesOrder,
	|	NewDataFromTable.Warehouse,
	|	NewDataFromTable.Department,
	|	NewDataFromTable.VATRate,
	|	NewDataFromTable.FEACNCode,
	|	NewDataFromTable.IncomeItem,
	|	NewDataFromTable.DimensionOfRevenue,
	|	SUM(NewDataFromTable.NumberOfPackages) AS NumberOfPackages,
	|	SUM(NewDataFromTable.Count) AS Count,
	|	SUM(NewDataFromTable.Sum) AS Sum,
	|	SUM(NewDataFromTable.VATAmount) AS VATAmount,
	|	SUM(NewDataFromTable.AmountIncludingVAT) AS AmountIncludingVAT,
	|	NewDataFromTable.ExpenseItem AS ExpenseItem,
	|	NewDataFromTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	NewDataFromTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	NewDataFromTable.ToExpenseAs AS ToExpenseAs
	|INTO NewData
	|FROM
	|	NewDataFromTable AS NewDataFromTable
	|
	|GROUP BY
	|	NewDataFromTable.BaseDocumentLineCode,
	|	NewDataFromTable.ProductsInSet,
	|	NewDataFromTable.ItemVariantOfSet,
	|	NewDataFromTable.Products,
	|	NewDataFromTable.PartnerProducts,
	|	NewDataFromTable.Characteristic,
	|	NewDataFromTable.Purpose,
	|	NewDataFromTable.Series,
	|	NewDataFromTable.Content,
	|	NewDataFromTable.Package,
	|	NewDataFromTable.SalesOrder,
	|	NewDataFromTable.Warehouse,
	|	NewDataFromTable.Department,
	|	NewDataFromTable.VATRate,
	|	NewDataFromTable.FEACNCode,
	|	NewDataFromTable.IncomeItem,
	|	NewDataFromTable.DimensionOfRevenue,
	|	NewDataFromTable.ExpenseItem,
	|	NewDataFromTable.DimensionOfExpenses,
	|	NewDataFromTable.AssetsLiabilitiesDimension,
	|	NewDataFromTable.ToExpenseAs
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CAST(CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN RawData.RowCode
	|		ELSE 0
	|	END AS NUMBER(10, 0)) AS BaseDocumentLineCode,
	|	CAST(RawData.ProductsInSet AS Catalog.Products) AS ProductsInSet,
	|	CAST(RawData.ItemVariantOfSet AS Catalog.ItemsCharacteristics) AS ItemVariantOfSet,
	|	CAST(RawData.Products AS Catalog.Products) AS Products,
	|	CAST(RawData.PartnerProducts AS Catalog.ProductCrossReferences) AS PartnerProducts,
	|	CAST(RawData.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(RawData.Purpose AS Catalog.Assignments) AS Purpose,
	|	CAST(RawData.Series AS Catalog.ItemsBatches) AS Series,
	|	CASE
	|		WHEN RawData.Content <> UNDEFINED
	|			THEN RawData.Content
	|		ELSE """"
	|	END AS Content,
	|	CAST(RawData.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	RawData.SalesOrder,
	|	CAST(RawData.Warehouse AS Catalog.Warehouses) AS Warehouse,
	|	CAST(RawData.Department AS Catalog.BusinessStructure) AS Department,
	|	CAST(RawData.FEACNCode AS Catalog.FEACN) AS FEACNCode,
	|	CAST(RawData.VATRate AS Catalog.VATRates) AS VATRate,
	|	CASE
	|		WHEN &OtherAssetServiceAdjustment
	|			AND (&CurPeriodAdjustment
	|				OR &SaleAdjustment2_5
	|					AND (NOT &RecordInProfitLossOfPreviousYears
	|						OR &AdjustTaxBaseOfPreviousPeriod))
	|			THEN CAST(RawData.IncomeItem AS ChartOfCharacteristicTypes.IncomeItems)
	|		ELSE
	|			VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|	END AS IncomeItem,
	|	CASE
	|		WHEN &OtherAssetServiceAdjustment
	|			AND (&CurPeriodAdjustment
	|				OR &SaleAdjustment2_5
	|					AND (NOT &RecordInProfitLossOfPreviousYears
	|						OR &AdjustTaxBaseOfPreviousPeriod))
	|			THEN RawData.DimensionOfRevenue
	|		ELSE
	|			UNDEFINED
	|	END AS DimensionOfRevenue,
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
	|			WHEN RawData.Sum <> UNDEFINED
	|				THEN CAST(RawData.Sum AS NUMBER(31,2))
	|			ELSE 0
	|		END) AS Sum,
	|	SUM(CASE
	|			WHEN RawData.VATAmount <> UNDEFINED
	|				THEN CAST(RawData.VATAmount AS NUMBER(31,2))
	|			ELSE 0
	|		END) AS VATAmount,
	|	SUM(CASE
	|			WHEN RawData.AmountIncludingVAT <> UNDEFINED
	|				THEN CAST(RawData.AmountIncludingVAT AS NUMBER(31,2))
	|			ELSE 0
	|		END) AS AmountIncludingVAT,
	|
	|	RawData.ExpenseItem AS ExpenseItem,
	|	RawData.DimensionOfExpenses AS DimensionOfExpenses,
	|	RawData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	RawData.ToExpenseAs AS ToExpenseAs
	|
	|INTO RawDataForDiscrepancies
	|FROM
	|	RawData AS RawData
	|
	|GROUP BY
	|	CAST(CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
	|			THEN RawData.RowCode
	|		ELSE 0
	|	END AS NUMBER(10, 0)),
	|	RawData.ProductsInSet,
	|	RawData.ItemVariantOfSet,
	|	RawData.Products,
	|	RawData.PartnerProducts,
	|	RawData.Characteristic,
	|	RawData.Purpose,
	|	RawData.Series,
	|	RawData.Content,
	|	RawData.Package,
	|	RawData.SalesOrder,
	|	RawData.Warehouse,
	|	RawData.Department,
	|	RawData.FEACNCode,
	|	RawData.VATRate,
	|	CASE
	|		WHEN &OtherAssetServiceAdjustment
	|			AND (&CurPeriodAdjustment
	|				OR &SaleAdjustment2_5
	|					AND (NOT &RecordInProfitLossOfPreviousYears
	|						OR &AdjustTaxBaseOfPreviousPeriod))
	|			THEN CAST(RawData.IncomeItem AS ChartOfCharacteristicTypes.IncomeItems)
	|		ELSE
	|			VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef)
	|	END,
	|	CASE
	|		WHEN &OtherAssetServiceAdjustment
	|			AND (&CurPeriodAdjustment
	|				OR &SaleAdjustment2_5
	|					AND (NOT &RecordInProfitLossOfPreviousYears
	|						OR &AdjustTaxBaseOfPreviousPeriod))
	|			THEN RawData.DimensionOfRevenue
	|		ELSE
	|			UNDEFINED
	|	END,
	|	RawData.ExpenseItem,
	|	RawData.DimensionOfExpenses,
	|	RawData.AssetsLiabilitiesDimension,
	|	RawData.ToExpenseAs
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RawData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewData.BaseDocumentLineCode AS BaseDocumentLineCode,
	|	NewData.ProductsInSet AS ProductsInSet,
	|	NewData.ItemVariantOfSet AS ItemVariantOfSet,
	|	NewData.Products AS Products,
	|	NewData.PartnerProducts AS PartnerProducts,
	|	NewData.Characteristic AS Characteristic,
	|	NewData.Purpose AS Purpose,
	|	NewData.Series AS Series,
	|	NewData.Content AS Content,
	|	NewData.Package AS Package,
	|	NewData.SalesOrder AS SalesOrder,
	|	NewData.Warehouse AS Warehouse,
	|	NewData.Department AS Department,
	|	NewData.VATRate AS VATRate,
	|	NewData.FEACNCode AS FEACNCode,
	|	NewData.IncomeItem AS IncomeItem,
	|	NewData.DimensionOfRevenue AS DimensionOfRevenue,
	|	NewData.Sum AS Sum,
	|	NewData.VATAmount AS VATAmount,
	|	NewData.AmountIncludingVAT AS AmountIncludingVAT,
	|
	|	NewData.ExpenseItem AS ExpenseItem,
	|	NewData.DimensionOfExpenses AS DimensionOfExpenses,
	|	NewData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	NewData.ToExpenseAs AS ToExpenseAs
	|
	|INTO DiscrepancyData
	|FROM
	|	NewData AS NewData
	|		INNER JOIN RawDataForDiscrepancies AS RawData
	|		ON NewData.BaseDocumentLineCode = RawData.BaseDocumentLineCode
	|			AND NewData.Products = RawData.Products
	|			AND NewData.PartnerProducts = RawData.PartnerProducts
	|			AND NewData.Characteristic = RawData.Characteristic
	|			AND NewData.Purpose = RawData.Purpose
	|			AND NewData.ProductsInSet = RawData.ProductsInSet
	|			AND NewData.ItemVariantOfSet = RawData.ItemVariantOfSet
	|			AND NewData.Series = RawData.Series
	|			AND NewData.Content = RawData.Content
	|			AND NewData.Package = RawData.Package
	|			AND NewData.SalesOrder = RawData.SalesOrder
	|			AND NewData.Warehouse = RawData.Warehouse
	|			AND NewData.Department = RawData.Department
	|			AND NewData.VATRate = RawData.VATRate
	|			AND NewData.FEACNCode = RawData.FEACNCode
	|			AND NewData.IncomeItem = RawData.IncomeItem
	|			AND NewData.DimensionOfRevenue = RawData.DimensionOfRevenue
	|			AND NewData.ExpenseItem = RawData.ExpenseItem
	|			AND NewData.DimensionOfExpenses = RawData.DimensionOfExpenses
	|			AND NewData.AssetsLiabilitiesDimension = RawData.AssetsLiabilitiesDimension
	|
	|UNION ALL
	|
	|SELECT
	|	RawData.BaseDocumentLineCode,
	|	RawData.ProductsInSet,
	|	RawData.ItemVariantOfSet,
	|	RawData.Products,
	|	RawData.PartnerProducts,
	|	RawData.Characteristic,
	|	RawData.Purpose,
	|	RawData.Series,
	|	RawData.Content,
	|	RawData.Package,
	|	RawData.SalesOrder,
	|	RawData.Warehouse,
	|	RawData.Department,
	|	RawData.VATRate,
	|	RawData.FEACNCode,
	|	RawData.IncomeItem,
	|	RawData.DimensionOfRevenue,
	|	-RawData.Sum,
	|	-RawData.VATAmount,
	|	-RawData.AmountIncludingVAT,
	|	RawData.ExpenseItem AS ExpenseItem,
	|	RawData.DimensionOfExpenses AS DimensionOfExpenses,
	|	RawData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	RawData.ToExpenseAs AS ToExpenseAs

	|FROM
	|	RawDataForDiscrepancies AS RawData
	|		INNER JOIN NewData AS NewData
	|		ON RawData.BaseDocumentLineCode = NewData.BaseDocumentLineCode
	|			AND RawData.Products = NewData.Products
	|			AND RawData.PartnerProducts = NewData.PartnerProducts
	|			AND RawData.Characteristic = NewData.Characteristic
	|			AND RawData.Purpose = NewData.Purpose
	|			AND RawData.ProductsInSet = NewData.ProductsInSet
	|			AND RawData.ItemVariantOfSet = NewData.ItemVariantOfSet
	|			AND RawData.Series = NewData.Series
	|			AND RawData.Content = NewData.Content
	|			AND RawData.Package = NewData.Package
	|			AND RawData.SalesOrder = NewData.SalesOrder
	|			AND RawData.Warehouse = NewData.Warehouse
	|			AND RawData.Department = NewData.Department
	|			AND RawData.VATRate = NewData.VATRate
	|			AND RawData.FEACNCode = NewData.FEACNCode
	|			AND RawData.IncomeItem = NewData.IncomeItem
	|			AND RawData.DimensionOfRevenue = NewData.DimensionOfRevenue
	|			AND NewData.ExpenseItem = RawData.ExpenseItem
	|			AND NewData.DimensionOfExpenses = RawData.DimensionOfExpenses
	|			AND NewData.AssetsLiabilitiesDimension = RawData.AssetsLiabilitiesDimension
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyData.BaseDocumentLineCode,
	|	DiscrepancyData.ProductsInSet,
	|	DiscrepancyData.ItemVariantOfSet,
	|	DiscrepancyData.Products,
	|	DiscrepancyData.PartnerProducts,
	|	DiscrepancyData.Characteristic,
	|	DiscrepancyData.Purpose,
	|	DiscrepancyData.Series,
	|	DiscrepancyData.Content,
	|	DiscrepancyData.Package,
	|	DiscrepancyData.SalesOrder,
	|	DiscrepancyData.Warehouse,
	|	DiscrepancyData.Department,
	|	DiscrepancyData.VATRate,
	|	DiscrepancyData.FEACNCode,
	|	DiscrepancyData.IncomeItem,
	|	DiscrepancyData.DimensionOfRevenue,
	|	SUM(DiscrepancyData.Sum) AS Sum,
	|	SUM(DiscrepancyData.VATAmount) AS VATAmount,
	|	SUM(DiscrepancyData.AmountIncludingVAT) AS AmountIncludingVAT,
	|	CAST(DiscrepancyData.Products AS Catalog.Products).ItemsType AS ItemsType,
	|
	|	DiscrepancyData.ExpenseItem AS ExpenseItem,
	|	DiscrepancyData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DiscrepancyData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DiscrepancyData.ToExpenseAs AS ToExpenseAs
	|
	|INTO DataOfDiscrepanciesAreIntermediate
	|FROM
	|	DiscrepancyData AS DiscrepancyData
	|
	|GROUP BY
	|	DiscrepancyData.BaseDocumentLineCode,
	|	DiscrepancyData.ProductsInSet,
	|	DiscrepancyData.ItemVariantOfSet,
	|	DiscrepancyData.Products,
	|	DiscrepancyData.PartnerProducts,
	|	DiscrepancyData.Characteristic,
	|	DiscrepancyData.Purpose,
	|	DiscrepancyData.Series,
	|	DiscrepancyData.Content,
	|	DiscrepancyData.Package,
	|	DiscrepancyData.SalesOrder,
	|	DiscrepancyData.Warehouse,
	|	DiscrepancyData.Department,
	|	DiscrepancyData.VATRate,
	|	DiscrepancyData.FEACNCode,
	|	DiscrepancyData.IncomeItem,
	|	DiscrepancyData.DimensionOfRevenue,
	|	DiscrepancyData.ExpenseItem,
	|	DiscrepancyData.DimensionOfExpenses,
	|	DiscrepancyData.AssetsLiabilitiesDimension,
	|	DiscrepancyData.ToExpenseAs,
	|	CAST(DiscrepancyData.Products AS Catalog.Products).ItemsType
	|
	|HAVING
	|	CAST(SUM(DiscrepancyData.AmountIncludingVAT) AS NUMBER(31,2)) <> 0
	|	OR CAST(SUM(DiscrepancyData.VATAmount) AS NUMBER(31,2)) <> 0;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyData.BaseDocumentLineCode AS BaseDocumentLineCode,
	|	DiscrepancyData.ProductsInSet AS ProductsInSet,
	|	DiscrepancyData.ItemVariantOfSet AS ItemVariantOfSet,
	|	DiscrepancyData.Products AS Products,
	|	DiscrepancyData.PartnerProducts AS PartnerProducts,
	|	DiscrepancyData.Characteristic AS Characteristic,
	|	DiscrepancyData.Purpose AS Purpose,
	|	DiscrepancyData.Series AS Series,
	|	DiscrepancyData.Content AS Content,
	|	DiscrepancyData.Package AS Package,
	|	DiscrepancyData.SalesOrder AS SalesOrder,
	|	DiscrepancyData.Warehouse AS Warehouse,
	|	DiscrepancyData.Department AS Department,
	|	DiscrepancyData.VATRate AS VATRate,
	|	DiscrepancyData.FEACNCode AS FEACNCode,
	|	DiscrepancyData.IncomeItem AS IncomeItem,
	|	DiscrepancyData.DimensionOfRevenue AS DimensionOfRevenue,
	|	DiscrepancyData.Sum AS Sum,
	|	DiscrepancyData.VATAmount AS VATAmount,
	|	DiscrepancyData.AmountIncludingVAT AS AmountIncludingVAT,
	|	DiscrepancyData.ItemsType AS ItemsType,
	|	MIN(TableData.LineNumber) AS LineNumber,
	|
	|	DiscrepancyData.ExpenseItem AS ExpenseItem,
	|	DiscrepancyData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DiscrepancyData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DiscrepancyData.ToExpenseAs AS ToExpenseAs
	|
	|FROM
	|	DataOfDiscrepanciesAreIntermediate AS DiscrepancyData
	|		LEFT JOIN NewDataFromTable AS TableData
	|		ON DiscrepancyData.BaseDocumentLineCode = TableData.BaseDocumentLineCode
	|			AND DiscrepancyData.Products = TableData.Products
	|			AND DiscrepancyData.PartnerProducts = TableData.PartnerProducts
	|			AND DiscrepancyData.Characteristic = TableData.Characteristic
	|			AND DiscrepancyData.Purpose = TableData.Purpose
	|			AND DiscrepancyData.ProductsInSet = TableData.ProductsInSet
	|			AND DiscrepancyData.ItemVariantOfSet = TableData.ItemVariantOfSet
	|			AND DiscrepancyData.Series = TableData.Series
	|			AND DiscrepancyData.Content = TableData.Content
	|			AND DiscrepancyData.Package = TableData.Package
	|			AND DiscrepancyData.SalesOrder = TableData.SalesOrder
	|			AND DiscrepancyData.Warehouse = TableData.Warehouse
	|			AND DiscrepancyData.Department = TableData.Department
	|			AND DiscrepancyData.VATRate = TableData.VATRate
	|			AND DiscrepancyData.FEACNCode = TableData.FEACNCode
	|			AND DiscrepancyData.IncomeItem = TableData.IncomeItem
	|			AND DiscrepancyData.DimensionOfRevenue = TableData.DimensionOfRevenue
	|			AND TableData.ExpenseItem = DiscrepancyData.ExpenseItem
	|			AND TableData.DimensionOfExpenses = DiscrepancyData.DimensionOfExpenses
	|			AND TableData.AssetsLiabilitiesDimension = DiscrepancyData.AssetsLiabilitiesDimension
	|
	|GROUP BY
	|	DiscrepancyData.BaseDocumentLineCode,
	|	DiscrepancyData.ProductsInSet,
	|	DiscrepancyData.ItemVariantOfSet,
	|	DiscrepancyData.Products,
	|	DiscrepancyData.PartnerProducts,
	|	DiscrepancyData.Characteristic,
	|	DiscrepancyData.Purpose,
	|	DiscrepancyData.Series,
	|	DiscrepancyData.Content,
	|	DiscrepancyData.Package,
	|	DiscrepancyData.SalesOrder,
	|	DiscrepancyData.Warehouse,
	|	DiscrepancyData.Department,
	|	DiscrepancyData.VATRate,
	|	DiscrepancyData.FEACNCode,
	|	DiscrepancyData.IncomeItem,
	|	DiscrepancyData.DimensionOfRevenue,
	|	DiscrepancyData.Sum,
	|	DiscrepancyData.VATAmount,
	|	DiscrepancyData.AmountIncludingVAT,
	|	DiscrepancyData.ItemsType,
	|
	|	DiscrepancyData.ExpenseItem,
	|	DiscrepancyData.DimensionOfExpenses,
	|	DiscrepancyData.AssetsLiabilitiesDimension,
	|	DiscrepancyData.ToExpenseAs

	|
	|ORDER BY
	|	LineNumber
	|";
	
	TableOfDiscrepanciesInAmounts = Query.Execute().Unload();
	
	For Each TheseDiscrepancies In TableOfDiscrepanciesInAmounts Do
		
		NewDivergence = Discrepancies.Add();
		FillPropertyValues(NewDivergence, TheseDiscrepancies);
		NewDivergence.PostingOption = VariantOfReflectionByLine(
			NewDivergence,
			TheseDiscrepancies.ItemsType,
			OtherAssetServiceAdjustment,
			LastPeriodAdjustment,
			AdjustingGiver);
		
	EndDo;
	
	Query.Text = "
	|DROP DiscrepancyData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccountedDiscrepancies.BaseDocumentLineCode AS BaseDocumentLineCode,
	|	AccountedDiscrepancies.ProductsInSet AS ProductsInSet,
	|	AccountedDiscrepancies.ItemVariantOfSet AS ItemVariantOfSet,
	|	AccountedDiscrepancies.Products AS Products,
	|	AccountedDiscrepancies.PartnerProducts AS PartnerProducts,
	|	AccountedDiscrepancies.Characteristic AS Characteristic,
	|	AccountedDiscrepancies.Purpose AS Purpose,
	|	AccountedDiscrepancies.Series AS Series,
	|	AccountedDiscrepancies.Content AS Content,
	|	AccountedDiscrepancies.Package AS Package,
	|	AccountedDiscrepancies.SalesOrder AS SalesOrder,
	|	AccountedDiscrepancies.Warehouse AS Warehouse,
	|	AccountedDiscrepancies.Department AS Department,
	|	AccountedDiscrepancies.VATRate AS VATRate,
	|	AccountedDiscrepancies.FEACNCode AS FEACNCode,
	|	AccountedDiscrepancies.IncomeItem AS IncomeItem,
	|	AccountedDiscrepancies.DimensionOfRevenue AS DimensionOfRevenue,
	|	AccountedDiscrepancies.Sum AS Sum,
	|	AccountedDiscrepancies.VATAmount AS VATAmount,
	|	AccountedDiscrepancies.AmountIncludingVAT AS AmountIncludingVAT,
	|
	|	AccountedDiscrepancies.ExpenseItem AS ExpenseItem,
	|	AccountedDiscrepancies.DimensionOfExpenses AS DimensionOfExpenses,
	|	AccountedDiscrepancies.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	AccountedDiscrepancies.ToExpenseAs AS ToExpenseAs
	|
	|INTO AccountedDiscrepancies
	|FROM
	|	&AccountedDiscrepancies AS AccountedDiscrepancies
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewData.BaseDocumentLineCode AS BaseDocumentLineCode,
	|	NewData.ProductsInSet AS ProductsInSet,
	|	NewData.ItemVariantOfSet AS ItemVariantOfSet,
	|	NewData.Products AS Products,
	|	NewData.PartnerProducts AS PartnerProducts,
	|	NewData.Characteristic AS Characteristic,
	|	NewData.Purpose AS Purpose,
	|	NewData.Series AS Series,
	|	NewData.Content AS Content,
	|	NewData.Package AS Package,
	|	NewData.SalesOrder AS SalesOrder,
	|	NewData.Warehouse AS Warehouse,
	|	NewData.Department AS Department,
	|	NewData.VATRate AS VATRate,
	|	NewData.FEACNCode AS FEACNCode,
	|	NewData.IncomeItem AS IncomeItem,
	|	NewData.DimensionOfRevenue AS DimensionOfRevenue,
	|	NewData.NumberOfPackages AS NumberOfPackages,
	|	NewData.Count AS Count,
	|	NewData.Sum AS Sum,
	|	NewData.VATAmount AS VATAmount,
	|	NewData.AmountIncludingVAT AS AmountIncludingVAT,
	|
	|	NewData.ExpenseItem AS ExpenseItem,
	|	NewData.DimensionOfExpenses AS DimensionOfExpenses,
	|	NewData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	NewData.ToExpenseAs AS ToExpenseAs
	|
	|INTO DiscrepancyData
	|FROM
	|	NewData AS NewData
	|
	|UNION ALL
	|
	|SELECT
	|	RawData.BaseDocumentLineCode,
	|	RawData.ProductsInSet,
	|	RawData.ItemVariantOfSet,
	|	RawData.Products,
	|	RawData.PartnerProducts,
	|	RawData.Characteristic,
	|	RawData.Purpose,
	|	RawData.Series,
	|	RawData.Content,
	|	RawData.Package,
	|	RawData.SalesOrder,
	|	RawData.Warehouse,
	|	RawData.Department,
	|	RawData.VATRate,
	|	RawData.FEACNCode,
	|	RawData.IncomeItem,
	|	RawData.DimensionOfRevenue,
	|	-RawData.NumberOfPackages,
	|	-RawData.Count,
	|	-RawData.Sum,
	|	-RawData.VATAmount,
	|	-RawData.AmountIncludingVAT,
	|
	|	RawData.ExpenseItem AS ExpenseItem,
	|	RawData.DimensionOfExpenses AS DimensionOfExpenses,
	|	RawData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	RawData.ToExpenseAs AS ToExpenseAs
	|FROM
	|	RawDataForDiscrepancies AS RawData
	|
	|UNION ALL
	|
	|SELECT
	|	AccountedDiscrepancies.BaseDocumentLineCode,
	|	AccountedDiscrepancies.ProductsInSet,
	|	AccountedDiscrepancies.ItemVariantOfSet,
	|	AccountedDiscrepancies.Products,
	|	AccountedDiscrepancies.PartnerProducts,
	|	AccountedDiscrepancies.Characteristic,
	|	AccountedDiscrepancies.Purpose,
	|	AccountedDiscrepancies.Series,
	|	AccountedDiscrepancies.Content,
	|	AccountedDiscrepancies.Package,
	|	AccountedDiscrepancies.SalesOrder,
	|	AccountedDiscrepancies.Warehouse,
	|	AccountedDiscrepancies.Department,
	|	AccountedDiscrepancies.VATRate,
	|	AccountedDiscrepancies.FEACNCode,
	|	AccountedDiscrepancies.IncomeItem,
	|	AccountedDiscrepancies.DimensionOfRevenue,
	|	0,
	|	0,
	|	-AccountedDiscrepancies.Sum,
	|	-AccountedDiscrepancies.VATAmount,
	|	-AccountedDiscrepancies.AmountIncludingVAT,
	|
	|	AccountedDiscrepancies.ExpenseItem AS ExpenseItem,
	|	AccountedDiscrepancies.DimensionOfExpenses AS DimensionOfExpenses,
	|	AccountedDiscrepancies.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	AccountedDiscrepancies.ToExpenseAs AS ToExpenseAs
	|
	|FROM
	|	AccountedDiscrepancies AS AccountedDiscrepancies
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyData.BaseDocumentLineCode,
	|	DiscrepancyData.ProductsInSet,
	|	DiscrepancyData.ItemVariantOfSet,
	|	DiscrepancyData.Products,
	|	DiscrepancyData.PartnerProducts,
	|	DiscrepancyData.Characteristic,
	|	DiscrepancyData.Purpose,
	|	DiscrepancyData.Series,
	|	DiscrepancyData.Content,
	|	DiscrepancyData.Package,
	|	DiscrepancyData.SalesOrder,
	|	DiscrepancyData.Warehouse,
	|	DiscrepancyData.Department,
	|	DiscrepancyData.VATRate,
	|	DiscrepancyData.FEACNCode,
	|	DiscrepancyData.IncomeItem,
	|	DiscrepancyData.DimensionOfRevenue,
	|	SUM(DiscrepancyData.NumberOfPackages),
	|	SUM(DiscrepancyData.Count),
	|	SUM(DiscrepancyData.Sum),
	|	SUM(DiscrepancyData.VATAmount),
	|	SUM(DiscrepancyData.AmountIncludingVAT),
	|	CAST(DiscrepancyData.Products AS Catalog.Products).ItemsType AS ItemsType,
	|
	|	DiscrepancyData.ExpenseItem AS ExpenseItem,
	|	DiscrepancyData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DiscrepancyData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DiscrepancyData.ToExpenseAs AS ToExpenseAs
	|FROM
	|	DiscrepancyData AS DiscrepancyData
	|
	|GROUP BY
	|	DiscrepancyData.BaseDocumentLineCode,
	|	DiscrepancyData.ProductsInSet,
	|	DiscrepancyData.ItemVariantOfSet,
	|	DiscrepancyData.Products,
	|	DiscrepancyData.PartnerProducts,
	|	DiscrepancyData.Characteristic,
	|	DiscrepancyData.Purpose,
	|	DiscrepancyData.Series,
	|	DiscrepancyData.Content,
	|	DiscrepancyData.Package,
	|	DiscrepancyData.SalesOrder,
	|	DiscrepancyData.Warehouse,
	|	DiscrepancyData.Department,
	|	DiscrepancyData.VATRate,
	|	DiscrepancyData.FEACNCode,
	|	DiscrepancyData.IncomeItem,
	|	DiscrepancyData.DimensionOfRevenue,
	|
	|	DiscrepancyData.ExpenseItem,
	|	DiscrepancyData.DimensionOfExpenses,
	|	DiscrepancyData.AssetsLiabilitiesDimension,
	|	DiscrepancyData.ToExpenseAs,
	|	CAST(DiscrepancyData.Products AS Catalog.Products).ItemsType
	|
	|HAVING
	|	CAST(SUM(DiscrepancyData.NumberOfPackages) AS NUMBER(15,3)) <> 0
	|	OR CAST(SUM(DiscrepancyData.Count) AS NUMBER(15,3)) <> 0
	|
	|ORDER BY 
	|	DiscrepancyData.Products,
	|	DiscrepancyData.Characteristic
	|";
	
	Query.SetParameter("AccountedDiscrepancies", Discrepancies.Unload());
	
	TheseDiscrepancies = Query.Execute().Select();
	While TheseDiscrepancies.Next() Do
		
		SearchParameters = New Structure(KeyFields);
		FillPropertyValues(SearchParameters, TheseDiscrepancies);
		
		FoundRows = Discrepancies.FindRows(SearchParameters);
		If FoundRows.Count() = 0 Then
			NewDivergence = Discrepancies.Add();
			FillPropertyValues(NewDivergence, TheseDiscrepancies);
		Else
			NewDivergence = FoundRows.Get(0);
			NewDivergence.Count = NewDivergence.Count + TheseDiscrepancies.Count;
			NewDivergence.NumberOfPackages = NewDivergence.NumberOfPackages + TheseDiscrepancies.NumberOfPackages;
		EndIf;
		
		NewDivergence.Sum = NewDivergence.AmountIncludingVAT - ?(PriceIncludesVAT, 0, NewDivergence.VATAmount);
		NewDivergence.PostingOption = VariantOfReflectionByLine(
			NewDivergence,
			TheseDiscrepancies.ItemsType,
			OtherAssetServiceAdjustment,
			LastPeriodAdjustment,
			AdjustingGiver);
		
	EndDo;
	
EndProcedure

Procedure FillInProductDiscrepancies()
	
	Query = New Query;
	
	Query.SetParameter("TableOfGoods", Goods.Unload());
	Query.SetParameter("ThisIsReturn", AdjustmentKind = Enums.BusinessTransactions.ReturnOfUnderdeliveredGoods);
	Query.SetParameter("PriceIncludesVAT", PriceIncludesVAT);
	Query.Text =
	"SELECT
	|	TableOfGoods.ProductsInSet AS ProductsInSet,
	|	TableOfGoods.ItemVariantOfSet AS ItemVariantOfSet,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.Content AS Content,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.SalesOrder AS SalesOrder,
	|	TableOfGoods.RowCode AS RowCode,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.Department AS Department,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.PostingOption AS PostingOption,
	|	
	|	CASE WHEN &ThisIsReturn THEN
	|		-TableOfGoods.NumberOfPackages
	|	ELSE
	|		TableOfGoods.NumberOfPackages
	|	END AS NumberOfPackages,
	|	
	|	CASE WHEN &ThisIsReturn THEN
	|		-TableOfGoods.Count
	|	ELSE
	|		TableOfGoods.Count
	|	END AS Count,
	|	
	|	CASE WHEN &ThisIsReturn THEN
	|		-TableOfGoods.Sum
	|	ELSE
	|		TableOfGoods.Sum
	|	END AS Sum,
	|	
	|	CASE WHEN &ThisIsReturn THEN
	|		-TableOfGoods.VATAmount
	|	ELSE
	|		TableOfGoods.VATAmount
	|	END AS VATAmount,
	|	
	|	CASE WHEN &ThisIsReturn THEN
	|		-TableOfGoods.AmountIncludingVAT
	|	ELSE
	|		TableOfGoods.AmountIncludingVAT
	|	END AS AmountIncludingVAT
	|
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyData.ProductsInSet,
	|	DiscrepancyData.ItemVariantOfSet,
	|	DiscrepancyData.Products,
	|	DiscrepancyData.Characteristic,
	|	DiscrepancyData.Purpose,
	|	DiscrepancyData.Series,
	|	DiscrepancyData.Content,
	|	DiscrepancyData.Package,
	|	DiscrepancyData.SalesOrder,
	|	DiscrepancyData.RowCode,
	|	DiscrepancyData.Warehouse,
	|	DiscrepancyData.Department,
	|	DiscrepancyData.VATRate,
	|	DiscrepancyData.PostingOption,
	|	SUM(DiscrepancyData.NumberOfPackages),
	|	SUM(DiscrepancyData.Count),
	|	SUM(DiscrepancyData.VATAmount),
	|	SUM(DiscrepancyData.AmountIncludingVAT),
	|	
	|	CASE WHEN &PriceIncludesVAT THEN
	|		SUM(DiscrepancyData.AmountIncludingVAT)
	|	ELSE
	|		SUM(DiscrepancyData.AmountIncludingVAT) - SUM(DiscrepancyData.VATAmount)
	|	END AS Sum,
	|	
	|	CAST(DiscrepancyData.Products AS Catalog.Products).ItemsType AS ItemsType
	|FROM
	|	TableOfGoods AS DiscrepancyData
	|
	|GROUP BY
	|	DiscrepancyData.ProductsInSet,
	|	DiscrepancyData.ItemVariantOfSet,
	|	DiscrepancyData.Products,
	|	DiscrepancyData.Characteristic,
	|	DiscrepancyData.Purpose,
	|	DiscrepancyData.Series,
	|	DiscrepancyData.Content,
	|	DiscrepancyData.Package,
	|	DiscrepancyData.SalesOrder,
	|	DiscrepancyData.RowCode,
	|	DiscrepancyData.Warehouse,
	|	DiscrepancyData.Department,
	|	DiscrepancyData.VATRate,
	|	DiscrepancyData.PostingOption
	|";
	
	TheseDiscrepancies = Query.Execute().Unload();
	Discrepancies.Load(TheseDiscrepancies);
	
EndProcedure

Function BaseDocumentDate()

	ReferenceDocumentDateForCertificate = Date;
	
	If ValueIsFilled(DocumentBasis) Then
		ReferenceDocumentDateForCertificate = Common.ObjectAttributeValue(DocumentBasis, "Date");
	EndIf;
	
	Return ReferenceDocumentDateForCertificate;

EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
