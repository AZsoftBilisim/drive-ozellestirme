#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.InventorySurplusRecognition - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	InitializeDocument();
	
	For Each TSRow In Goods Do
		TSRow.InventoryOwnerAttribute = Undefined;
	EndDo;
	
	ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
											ThisObject);
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																					Goods);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods");
	
	InventorySurplusRecognitionLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	AdditionalProperties.Insert("FillInTablePart", True);
	DocumentBasis = Undefined;
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("DiscrepancyCertificate") 
			And FillingData.Property("BasisOfAct") Then
			
			If TypeOf(FillingData.DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
				FillInDocumentOnBasisOfAcceptanceCertificate(FillingData);
			ElsIf TypeOf(FillingData.DiscrepancyCertificate) = Type("DocumentRef.DiscrepancyReportFollowingTransfer") Then
				FillInDocumentOnMovementActBasis(FillingData);
			EndIf;
			
			AdditionalProperties.FillInTablePart = False;
			DocumentBasis = FillingData.DiscrepancyCertificate;
			
		ElsIf FillingData.Property("WizardOfCorrectingCompanyStockBalance") Then
			
			FillInDocumentAccordingToCorrectionAssistant(FillingData);
			AdditionalProperties.FillInTablePart = False;
			
		ElsIf Documents.ReconcileOpeningBalancesByWarehouses.FillInRegistrationOfSurplusGoodsBasedOnReconciliation(ThisObject, FillingData) Then
			
			AdditionalProperties.FillInTablePart = False;
			
		Else
			
			FillPropertyValues(ThisObject, FillingData);
			AdditionalProperties.FillInTablePart = Not FillingData.Property("DoNotFillInWrongPart");
			
		EndIf;
	
	ElsIf TypeOf(FillingData) = Type("DocumentRef.InventorySurplusRecognition") Then
		
		AdditionalProperties.FillInTablePart = False;
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	ElsIf Documents.AllRefsType().ContainsType(TypeOf(FillingData))
		And FillingData <> Undefined Then
	
		If TypeOf(FillingData) = Type("DocumentRef.InventoryRecount") Then 
			ResultingStructure = Common.ObjectAttributesValues(FillingData, "Status, Warehouse");
			If ResultingStructure.Status <> Enums.InventoryRecountStatuses.Completed2 Then 
				MessageText = NStr("vi = 'Chứng từ ""%DocumentRecalculate%"" đang có trạng thái ""%StatusOfRecalculation%"". Cho phép nhập chứng từ ""%DocumentAct%"" trên cơ sở chỉ đối với trạng thái ""%StatusCompleted_%"".';
									|ru = 'Документ ""%DocumentRecalculate%"" находится в статусе ""%StatusOfRecalculation%"". Ввод документа ""%DocumentAct%"" на основании разрешен только в статусе ""%StatusCompleted_%"".';
									|en = 'Document ""%DocumentRecalculate%"" is in status ""%StatusOfRecalculation%"".  ""%DocumentAct%"" can only be generated from base documents in status ""%StatusCompleted_%"".'; fa = 'Document ""%DocumentRecalculate%"" is in status ""%StatusOfRecalculation%"".  ""%DocumentAct%"" can only be generated from base documents in status ""%StatusCompleted_%"".';
									|it = 'Il documento ""%DocumentRecalculate%"" è nello stato ""%StatusOfRecalculation%"". Immissione del documento ""%DocumentAct%"" in base alla casuale è consentita solo nello stato di ""%StatusCompleted_%"".';
									|pl = 'Dokument ""%DocumentRecalculate%"" ma status ""%StatusOfRecalculation%"". Wprowadzenie dokumentu ""%DocumentAct%"" na podstawie jest dozwolony tylko ze statusem ""%StatusCompleted_%"".';
									|tr = '""%DocumentRecalculate%"" belgesi ""%StatusOfRecalculation%"" durumundadır. ""%DocumentAct%"" esaslı belge girişine yalnız ""%StatusCompleted_%"" durumunda izin verildi.'");
				MessageText = StrReplace(MessageText, "%DocumentRecalculate%", FillingData);
				MessageText = StrReplace(MessageText, "%DocumentAct%", Metadata.Documents.InventorySurplusRecognition.Synonym);
				MessageText = StrReplace(MessageText, "%StatusCompleted_%", Enums.InventoryRecountStatuses.Completed2);
				MessageText = StrReplace(MessageText, "%StatusOfRecalculation%", ResultingStructure.Status);
				Raise MessageText;
			EndIf;
			Warehouse = ResultingStructure.Warehouse;
			InventoryRecount = FillingData;
		EndIf;
		
		If Not ValueIsFilled(Warehouse) And Common.HasObjectAttribute("Warehouse", FillingData.Metadata()) Then
			Warehouse = Common.ObjectAttributeValue(FillingData, "Warehouse");
		EndIf;
		
		DocumentBasis = FillingData;
	
	EndIf;
	
	InventorySurplusRecognitionLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventorySurplusRecognition.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InitializeDocument(FillingData);
	
	If AdditionalProperties.FillInTablePart Then
		FillInTablePart(DocumentBasis);
	EndIf;
	
	AdditionalProperties.Delete("FillInTablePart");
	
	ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
											ThisObject);
	AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																					Goods);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
	ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventorySurplusRecognition));
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(Enums.BusinessTransactions.GoodsRecordingAsReceived, Warehouse, Department, Undefined);
		InformationRegisters.ItemsLocationAttributes.FillInCollection(Goods, PlacesOfAccounting);
		
		FillOutTypesOfDocumentInventory();
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods");
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventorySurplusRecognition.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InventorySurplusRecognitionLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	InventorySurplusRecognitionLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventorySurplusRecognition),
		Cancel,
		NotCheckedAttributeArray);
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date);
	
	If ThisIsTraceableDocument
		Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers") Then
		
		CheckParameters = InventoriesServer.ParametersForCheckingFillingInOfCCDNumbers();
		CheckParameters.AllowTraceableItemWithoutCCDNumbers = True;
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel, CheckParameters);
		
	EndIf;
	
	If ThisIsTraceableDocument Then
		AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject, Goods, Date);
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	If Not SubjectToExcise Then
		NotCheckedAttributeArray.Add("BusinessUnitProduction");
	Else
		ControlParameters = ExcisableGoodsAccounting.ControlParametersForFillingExcisableItems();
		ControlParameters.ErrorTextTemplate =
			NStr("vi = 'Cấm ghi tăng hàng hóa chịu thuế TTĐB ""%Products%"" đã chỉ định trong dòng %LineNumber% của danh sách ""%TabularSectionPresentation%"" trong kho bán lẻ ""%Warehouse%""';
				|ru = 'Запрещено оприходование подакцизного товара ""%Products%"", указанного в строке %LineNumber% списка ""%TabularSectionPresentation%"" на розничный склад ""%Warehouse%""';
				|en = 'Cannot receive the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list in the ""%Warehouse%"" retail warehouse'; fa = 'Cannot receive the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list in the ""%Warehouse%"" retail warehouse';
				|it = 'Cannot receive the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list in the ""%Warehouse%"" retail warehouse';
				|pl = 'Cannot receive the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list in the ""%Warehouse%"" retail warehouse';
				|tr = '""%TabularSectionPresentation%"" listesinin %LineNumber% satırında belirtilen tüketim vergisine tabi ""%Products%"" ürününün ""%Warehouse%"" perakende ambarına envanter girişi yasaktır'");
		ControlParameters.CheckingWarehouse = True;
		ExcisableGoodsAccounting.ControlOfFillingExcisableItems(ThisObject, ControlParameters, Cancel);
	EndIf;
	QualityControl.ProcessingVerificationOfFillingInSurplusDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Wiersze pozycji';
			|tr = 'Ürünler'"));
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.InventorySurplusRecognition.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes,
		ItemsAndDimensionsSelectionParameters);
	
	InventorySurplusRecognitionLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	InventorySurplusRecognitionLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	InventorySurplusRecognitionLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInTablePart(DocumentBasis = Undefined) Export
	
	Query = New Query;
	
	UseWarehouseManagemantSystemForGoodsSurplusesShortages = WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Warehouse);
	
	If UseWarehouseManagemantSystemForGoodsSurplusesShortages Then 
		
		If TypeOf(DocumentBasis) = Type("DocumentRef.InventoryRecount") Then
			
			Query.Text =
			"SELECT
			|	BaseGoods.Recorder				AS Ref,
			|	BaseGoods.Products			AS Products,
			|	BaseGoods.Characteristic			AS Characteristic,
			|	BaseGoods.Purpose				AS Purpose,
			|	BaseGoods.Series					AS Series,
			|	SUM(BaseGoods.ToCertificateRegistration)	AS Count
			|INTO GoodsReadyForRegistration
			|FROM
			|	AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages AS BaseGoods
			|
			|WHERE
			|	BaseGoods.Active
			|	AND BaseGoods.Recorder = &DocumentBasis
			|	AND BaseGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
			|
			|GROUP BY
			|	BaseGoods.Recorder,
			|	BaseGoods.Products,
			|	BaseGoods.Characteristic,
			|	BaseGoods.Purpose,
			|	BaseGoods.Series
			|
			|INDEX BY
			|	Ref,
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	Series
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 1
			|SELECT DISTINCT
			|	CompletedDocuments_4.Ref AS Ref
			|INTO CompletedDocuments_4
			|FROM
			|	Document.InventorySurplusRecognition.Goods AS DecoratedProducts
			|		INNER JOIN Document.InventorySurplusRecognition AS CompletedDocuments_4
			|		ON DecoratedProducts.Ref = CompletedDocuments_4.Ref
			|
			|WHERE
			|	CompletedDocuments_4.Posted
			|	AND CompletedDocuments_4.Ref <> &CurrentDocument
			|	AND (CompletedDocuments_4.InventoryRecount, DecoratedProducts.Products, DecoratedProducts.Characteristic,
			|		DecoratedProducts.Purpose, DecoratedProducts.Series) IN
			|			(SELECT
			|				GoodsForRegistration.Ref			AS Ref,
			|				GoodsForRegistration.Products		AS Products,
			|				GoodsForRegistration.Characteristic	AS Characteristic,
			|				GoodsForRegistration.Purpose		AS Purpose,
			|				GoodsForRegistration.Series				AS Series
			|			FROM
			|				GoodsReadyForRegistration AS GoodsForRegistration)
			|
			|INDEX BY
			|	Ref
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 2
			|SELECT DISTINCT
			|	DecoratedProducts.Products					AS Products,
			|	DecoratedProducts.Characteristic				AS Characteristic,
			|	DecoratedProducts.Purpose					AS Purpose,
			|	DecoratedProducts.Series							AS Series,
			|	SUM(DecoratedProducts.ToCertificateRegistrationExpense)	AS Count
			|INTO DecoratedProducts
			|FROM
			|	AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Turnovers(,
			|			,
			|			Recorder,
			|			Warehouse = &Warehouse
			|				AND (Products, Characteristic, Purpose, Series) IN
			|						(SELECT
			|							GoodsForRegistration.Products		AS Products,
			|							GoodsForRegistration.Characteristic	AS Characteristic,
			|							GoodsForRegistration.Purpose		AS Purpose,
			|							GoodsForRegistration.Series				AS Series
			|						FROM
			|							GoodsReadyForRegistration AS GoodsForRegistration)
			|	
			|	) AS DecoratedProducts
			|
			|WHERE
			|	DecoratedProducts.Recorder IN
			|			(SELECT
			|				CompletedDocuments_4.Ref AS Ref
			|			FROM
			|				CompletedDocuments_4 AS CompletedDocuments_4)
			|
			|GROUP BY
			|	DecoratedProducts.Products,
			|	DecoratedProducts.Characteristic,
			|	DecoratedProducts.Purpose,
			|	DecoratedProducts.Series
			|
			|HAVING
			|	SUM(DecoratedProducts.ToCertificateRegistrationExpense) > 0
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	Series
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 3
			|SELECT
			|	BaseGoods.Products	AS Products,
			|	BaseGoods.Characteristic	AS Characteristic,
			|	BaseGoods.Purpose		AS Purpose,
			|	BaseGoods.Series			AS Series,
			|	BaseGoods.Count - ISNULL(DecoratedProducts.Count, 0) AS Count
			|INTO BalanceOfGoodsToBeProcessed
			|FROM
			|	GoodsReadyForRegistration AS BaseGoods
			|		LEFT JOIN DecoratedProducts AS DecoratedProducts
			|		ON BaseGoods.Products = DecoratedProducts.Products
			|			AND BaseGoods.Characteristic = DecoratedProducts.Characteristic
			|			AND BaseGoods.Purpose = DecoratedProducts.Purpose
			|			AND BaseGoods.Series = DecoratedProducts.Series
			|
			|WHERE
			|	BaseGoods.Count - ISNULL(DecoratedProducts.Count, 0) > 0
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	Series
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 4
			|SELECT
			|	GoodsForRegistration.Products		AS Products,
			|	GoodsForRegistration.Characteristic	AS Characteristic,
			|	GoodsForRegistration.Purpose		AS Purpose,
			|	GoodsForRegistration.Series				AS Series,
			|	SUM(GoodsForRegistration.Count)	AS Count
			|INTO GoodsForRegistration
			|FROM
			|	(SELECT
			|		GoodsForRegistration.Products				AS Products,
			|		GoodsForRegistration.Characteristic			AS Characteristic,
			|		GoodsForRegistration.Purpose				AS Purpose,
			|		GoodsForRegistration.Series						AS Series,
			|		GoodsForRegistration.ToCertificateRegistrationBalance	AS Count
			|	FROM
			|		AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Balance(,
			|				Warehouse = &Warehouse
			|					AND (Products, Characteristic, Purpose, Series) IN
			|							(SELECT
			|								GoodsForRegistration.Products		AS Products,
			|								GoodsForRegistration.Characteristic	AS Characteristic,
			|								GoodsForRegistration.Purpose		AS Purpose,
			|								GoodsForRegistration.Series				AS Series
			|							FROM
			|								BalanceOfGoodsToBeProcessed AS GoodsForRegistration)) AS GoodsForRegistration
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsForRegistration.Products		AS Products,
			|		GoodsForRegistration.Characteristic	AS Characteristic,
			|		GoodsForRegistration.Purpose		AS Purpose,
			|		GoodsForRegistration.Series				AS Series,
			|		GoodsForRegistration.ToCertificateRegistration	AS Count
			|	FROM
			|		AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages AS GoodsForRegistration
			|	
			|	WHERE
			|		GoodsForRegistration.Active
			|		AND GoodsForRegistration.Recorder = &CurrentDocument) AS GoodsForRegistration
			|
			|GROUP BY
			|	GoodsForRegistration.Products,
			|	GoodsForRegistration.Characteristic,
			|	GoodsForRegistration.Purpose,
			|	GoodsForRegistration.Series
			|
			|HAVING
			|	SUM(GoodsForRegistration.Count) > 0
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	Series
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 5
			|SELECT
			|	GoodsForRegistration.Products		AS Products,
			|	GoodsForRegistration.Characteristic	AS Characteristic,
			|	GoodsForRegistration.Series				AS Series,
			|	GoodsForRegistration.Purpose		AS Purpose,
			|	CASE
			|		WHEN GoodsForRegistration.Count > BalanceOfGoodsToBeProcessed.Count
			|			THEN BalanceOfGoodsToBeProcessed.Count
			|		ELSE GoodsForRegistration.Count
			|	END								AS Count
			|FROM
			|	GoodsForRegistration AS GoodsForRegistration
			|		INNER JOIN BalanceOfGoodsToBeProcessed AS BalanceOfGoodsToBeProcessed
			|		ON GoodsForRegistration.Products = BalanceOfGoodsToBeProcessed.Products
			|			AND GoodsForRegistration.Characteristic = BalanceOfGoodsToBeProcessed.Characteristic
			|			AND GoodsForRegistration.Purpose = BalanceOfGoodsToBeProcessed.Purpose
			|			AND GoodsForRegistration.Series = BalanceOfGoodsToBeProcessed.Series";
			
		Else
			
			Query.Text =
			"SELECT
			|	GoodsForRegistration.Products		AS Products,
			|	GoodsForRegistration.Characteristic	AS Characteristic,
			|	GoodsForRegistration.Purpose		AS Purpose,
			|	GoodsForRegistration.Series				AS Series,
			|	SUM(GoodsForRegistration.Count)	AS Count
			|INTO GoodsForRegistration
			|FROM
			|	(SELECT
			|		GoodsForRegistration.Products				AS Products,
			|		GoodsForRegistration.Characteristic			AS Characteristic,
			|		GoodsForRegistration.Purpose				AS Purpose,
			|		GoodsForRegistration.Series						AS Series,
			|		GoodsForRegistration.ToCertificateRegistrationBalance	AS Count
			|	FROM
			|		AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages.Balance(, Warehouse = &Warehouse) AS GoodsForRegistration
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		GoodsForRegistration.Products		AS Products,
			|		GoodsForRegistration.Characteristic	AS Characteristic,
			|		GoodsForRegistration.Purpose		AS Purpose,
			|		GoodsForRegistration.Series				AS Series,
			|		GoodsForRegistration.ToCertificateRegistration	AS Count
			|	FROM
			|		AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages AS GoodsForRegistration
			|	
			|	WHERE
			|		GoodsForRegistration.Active
			|		AND GoodsForRegistration.Recorder = &CurrentDocument) AS GoodsForRegistration
			|
			|GROUP BY
			|	GoodsForRegistration.Products,
			|	GoodsForRegistration.Characteristic,
			|	GoodsForRegistration.Purpose,
			|	GoodsForRegistration.Series
			|
			|HAVING
			|	SUM(GoodsForRegistration.Count) > 0
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	Series
			|;
			|
			|//////////////////////////////////////////////////////////////////////////////// 1
			|SELECT DISTINCT
			|	GoodsForRegistration.Products		AS Products,
			|	GoodsForRegistration.Characteristic	AS Characteristic,
			|	GoodsForRegistration.Series				AS Series,
			|	GoodsForRegistration.Purpose		AS Purpose,
			|	GoodsForRegistration.Count		AS Count
			|FROM
			|	GoodsForRegistration AS GoodsForRegistration
			|		LEFT JOIN AccumulationRegister.GoodsForRegistrationOfSurplusesAndShortages AS BaseGoods
			|		ON BaseGoods.Active
			|			AND BaseGoods.Recorder = &DocumentBasis
			|			AND GoodsForRegistration.Products = BaseGoods.Products
			|			AND GoodsForRegistration.Characteristic = BaseGoods.Characteristic
			|			AND GoodsForRegistration.Purpose = BaseGoods.Purpose
			|			AND GoodsForRegistration.Series = BaseGoods.Series
			|
			|WHERE
			|	NOT BaseGoods.Products IS NULL";
			
		EndIf;
		
		Query.SetParameter("Warehouse", Warehouse);
		Query.SetParameter("CurrentDocument", Ref);
		
	Else
		
		// There will only be a recalculation in the non-standard warehouse of the documentation
		Query.Text = 
		"SELECT
		|	ConversionProducts.Products	AS Products,
		|	ConversionProducts.Characteristic	AS Characteristic,
		|	ConversionProducts.Series			AS Series,
		|	ConversionProducts.Purpose		AS Purpose,
		|	ConversionProducts.ControlledLotReference AS ControlledLotReference,
		|	SUM(ConversionProducts.CountReal - ConversionProducts.Count)	AS Count
		|FROM
		|	Document.InventoryRecount.Goods AS ConversionProducts
		|
		|WHERE
		|	ConversionProducts.Ref = &DocumentBasis
		|
		|GROUP BY
		|	ConversionProducts.Products,
		|	ConversionProducts.Characteristic,
		|	ConversionProducts.Purpose,
		|	ConversionProducts.Series,
		|	ConversionProducts.ControlledLotReference
		|
		|HAVING
		|	SUM(ConversionProducts.CountReal - ConversionProducts.Count) > 0";
		
	EndIf;
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	If Not Result.IsEmpty() Then
		
		Goods.Load(Result.Unload());
		
		If ValueIsFilled(PriceKind) Then
			ColumnsByValue = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
			
			FillParameters	= New Structure;
			FillParameters.Insert("Date",				Date);
			FillParameters.Insert("Organization",			Organization);
			FillParameters.Insert("Currency",				Currency);
			FillParameters.Insert("PriceKind",				PriceKind);
			FillParameters.Insert("ColumnsByValue",	ColumnsByValue);
			
			StructureOfActions = New Structure("RecalculateAmount", "Count");
			
			EnterprisePricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, StructureOfActions);
		EndIf;
		
		StructureOfActions = New Structure();
		CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
		StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
		
	ElsIf ValueIsFilled(DocumentBasis) Then
		
		MessageText = NStr("vi = 'Trong chứng từ ""%DocumentBasis%"" không có hàng hóa cần lập chứng từ ghi tăng.';
							|ru = 'В документе ""%DocumentBasis%"" отсутствуют товары, по которым необходимо оформить оприходование.';
							|en = 'Goods for which recording as received registration is required are absent in document ""%DocumentBasis%"".'; fa = 'Goods for which recording as received registration is required are absent in document ""%DocumentBasis%"".';
							|it = 'Nel documento ""%DocumentBasis%"" non ci sono prodotti per i quali è necessario formalizzare la registrazione in contabilità.';
							|pl = 'W dokumencie ""%DocumentBasis%"" nie ma towarów, według których należy sporządzić rejestrowanie.';
							|tr = '""%DocumentBasis%"" belgesinde, envanter girişi düzenlemesinin gerekli olduğu hiçbir ürün yoktur.'");
		MessageText = StrReplace(MessageText, "%DocumentBasis%", DocumentBasis);
		
		CommonClientServer.MessageToUser(MessageText, ThisObject);
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Author         = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse         = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	
	If Not ValueIsFilled(PriceKind) Then
		PriceKind = Catalogs.Warehouses.AccountingPriceType(Warehouse);
	EndIf;
	If Not ValueIsFilled(Currency) Then
		Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(
			Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind).PriceCurrency);
	EndIf;
	
	If Not ValueIsFilled(FillingData) And TypeOf(Basis) = Type("DocumentRef.ReconcileOpeningBalancesByWarehouses") Then
		Basis = Undefined;
	EndIf;
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

Procedure FillInDocumentOnBasisOfAcceptanceCertificate(FillingData);
	
	AcceptanceReportType = TypeOfDiscrepancyReportAcceptance(FillingData.DiscrepancyCertificate);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DiscrepancyReportFollowingReceipt.Organization AS Organization,
	|	DiscrepancyReportFollowingReceipt.Manager AS EmployeeResponsible,
	|	DiscrepancyReportFollowingReceipt.Department AS Department,
	|	&Warehouse AS Warehouse,
	|	&Basis AS Basis
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt AS DiscrepancyReportFollowingReceipt
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|;";
	
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	Query.SetParameter("Warehouse",            FillingData.Warehouse);
	
	If AcceptanceReportType Then
		Query.SetParameter("Basis", FillingData.DiscrepancyCertificate);
	Else
		Query.SetParameter("Basis", FillingData.BasisOfAct);
	EndIf;
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	HeaderSelection = QueryResult.Select();
	If HeaderSelection.Next() Then
		FillPropertyValues(ThisObject, HeaderSelection);
	EndIf;
	
	// Filling in PM
	
	Query.Text =  "
	|SELECT
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument AS Count,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatus,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Price AS Price,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CCDNumber AS CCDNumber,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Sum - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SumByDocument AS Sum
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &Ref
	|	AND (CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis = &Basis
	|		OR &AcceptanceReportType)
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument > 0
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse = &Warehouse
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome)
	|
	|ORDER BY
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.LineNumber";
	
	Query.SetParameter("Ref", FillingData.DiscrepancyCertificate);
	Query.SetParameter("Warehouse", FillingData.Warehouse);
	Query.SetParameter("Basis", FillingData.BasisOfAct);
	Query.SetParameter("AcceptanceReportType", AcceptanceReportType);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	If Not Result.IsEmpty() Then
		
		Goods.Load(Result.Unload());
		
		If ValueIsFilled(PriceKind) And Goods.Count() > 0 Then
			
			FillParameters = New Structure;
			ColumnsByValue = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
			
			FillParameters.Insert("Date",				Date);
			FillParameters.Insert("Organization",			Organization);
			FillParameters.Insert("Currency",				Currency);
			FillParameters.Insert("PriceKind",				PriceKind);
			FillParameters.Insert("ColumnsByValue",	ColumnsByValue);
			
			StructureOfActions = New Structure("RecalculateAmount", "Count");
			
			EnterprisePricesFillingServer.FillInPrices(
				Goods,,
				FillParameters, 
				StructureOfActions);
			
		EndIf;
		
	ElsIf ValueIsFilled(FillingData.DiscrepancyCertificate) Then  
		
		MessageText = NStr("vi = 'Trong chứng từ ""%DocumentBasis%"" không có hàng hóa cần lập chứng từ ghi tăng.';
							|ru = 'В документе ""%DocumentBasis%"" отсутствуют товары, по которым необходимо оформить оприходование.';
							|en = 'Goods for which recording as received registration is required are absent in document ""%DocumentBasis%"".'; fa = 'Goods for which recording as received registration is required are absent in document ""%DocumentBasis%"".';
							|it = 'Nel documento ""%DocumentBasis%"" non ci sono prodotti per i quali è necessario formalizzare la registrazione in contabilità.';
							|pl = 'W dokumencie ""%DocumentBasis%"" nie ma towarów, według których należy sporządzić rejestrowanie.';
							|tr = '""%DocumentBasis%"" belgesinde, envanter girişi düzenlemesinin gerekli olduğu hiçbir ürün yoktur.'");
		MessageText = StrReplace(MessageText, "%DocumentBasis%", FillingData.DiscrepancyCertificate);
		CommonClientServer.MessageToUser(MessageText, ThisObject);
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnMovementActBasis(FillingData);
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DiscrepancyReportFollowingReceipt.Organization AS Organization,
	|	DiscrepancyReportFollowingReceipt.Manager AS EmployeeResponsible,
	|	DiscrepancyReportFollowingReceipt.Department AS Department,
	|	&Warehouse AS Warehouse,
	|	&Basis AS Basis
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer AS DiscrepancyReportFollowingReceipt
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|;";
	
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	Query.SetParameter("Warehouse",            FillingData.Warehouse);
	
	Query.SetParameter("Basis", FillingData.BasisOfAct);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	HeaderSelection = QueryResult.Select();
	If HeaderSelection.Next() Then
		FillPropertyValues(ThisObject, HeaderSelection);
	EndIf;
	
	// Filling in PM
	
	Query.Text =  "
	|SELECT
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument AS Count,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.BatchesIndicationStatus
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &Ref
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis = &Basis
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument > 0
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref.DestinationWarehouse = &Warehouse
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|
	|ORDER BY
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.LineNumber";
	
	Query.SetParameter("Ref", FillingData.DiscrepancyCertificate);
	Query.SetParameter("Warehouse", FillingData.Warehouse);
	Query.SetParameter("Basis", FillingData.BasisOfAct);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	If Not Result.IsEmpty() Then
		
		Goods.Load(Result.Unload());
		
		If ValueIsFilled(PriceKind) And Goods.Count() > 0 Then
			
			FillParameters = New Structure;
			ColumnsByValue = New Structure("Package", Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
			
			FillParameters.Insert("Date",				Date);
			FillParameters.Insert("Currency",				Currency);
			FillParameters.Insert("PriceKind",				PriceKind);
			FillParameters.Insert("ColumnsByValue",	ColumnsByValue);
			
			StructureOfActions = New Structure("RecalculateAmount", "Count");
			
			EnterprisePricesFillingServer.FillInPrices(
				Goods,,
				FillParameters, 
				StructureOfActions);
			
		EndIf;
		
	ElsIf ValueIsFilled(FillingData.DiscrepancyCertificate) Then  
		
		MessageText = NStr("vi = 'Trong chứng từ ""%DocumentBasis%"" không có hàng hóa cần lập chứng từ ghi tăng.';
							|ru = 'В документе ""%DocumentBasis%"" отсутствуют товары, по которым необходимо оформить оприходование.';
							|en = 'Goods for which recording as received registration is required are absent in document ""%DocumentBasis%"".'; fa = 'Goods for which recording as received registration is required are absent in document ""%DocumentBasis%"".';
							|it = 'Nel documento ""%DocumentBasis%"" non ci sono prodotti per i quali è necessario formalizzare la registrazione in contabilità.';
							|pl = 'W dokumencie ""%DocumentBasis%"" nie ma towarów, według których należy sporządzić rejestrowanie.';
							|tr = '""%DocumentBasis%"" belgesinde, envanter girişi düzenlemesinin gerekli olduğu hiçbir ürün yoktur.'");
		MessageText = StrReplace(MessageText, "%DocumentBasis%", FillingData.DiscrepancyCertificate);
		CommonClientServer.MessageToUser(MessageText, ThisObject);
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentAccordingToCorrectionAssistant(FillingData)
	
	Date = FillingData.Date;
	For Each Page1 In FillingData.Goods Do
		FillPropertyValues(Goods.Add(), Page1);
	EndDo;
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillOutTypesOfDocumentInventory()
	
	If TypeOf(Basis) = Type("DocumentRef.ReconcileOpeningBalancesByWarehouses") Then
		Return; // types of stocks are filled according to the data of the foundation document
	EndIf;
	
	QueryTexts = New Array;
	
	PartOfTheRequestText = 
	"SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTOriginalProductTable
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|INDEX BY
	|	Products
	|";
	QueryTexts.Add(PartOfTheRequestText);
	RequestTextParameters = ExcisableGoodsAccounting.ParametersOfQueryTextTTExciseCategoriesOfItems();
	RequestTextParameters.ProductTableName_ = "TTOriginalProductTable";
	
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(, RequestTextParameters));
	PartOfTheRequestText = 
	"SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	&Organization AS Organization,
	|	VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived) AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS TaxationOfOrganization,
	|	UNDEFINED AS GoodsOwner,
	|	CASE
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN &SubjectToExcise
	|		ELSE FALSE
	|	END AS SubjectToExcise,
	|	CASE
	|		WHEN ISNULL(Category_Data.ExcisableGoods, FALSE)
	|			THEN &BusinessUnitProduction
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS BusinessUnitProduction,
	|	VALUE(Catalog.VendorPriceTypes.EmptyRef) AS PriceKind
	|INTO OriginalProductTable
	|FROM
	|	TTOriginalProductTable AS TableOfGoods
	|		LEFT JOIN Document.InventorySurplusRecognition AS SavedData
	|		ON SavedData.Ref = &Ref
	|		
	|		LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|		ON TableOfGoods.Products = Category_Data.Products
	|WHERE
	|	TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|	OR SavedData.Ref IS NULL
	|	OR SavedData.Organization <> &Organization
	|	OR SavedData.SubjectToExcise <> &SubjectToExcise
	|	OR SavedData.BusinessUnitProduction <> &BusinessUnitProduction
	|	OR &RefillInventoryKinds
	|;
	|
	|///////////////////////////////////////////////////
	|DROP TTOriginalProductTable";
	QueryTexts.Add(PartOfTheRequestText);
	
	TempTablesManager	= New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Ref",			Ref);
	Query.SetParameter("Posted",		Posted);
	Query.SetParameter("Organization",	Organization);
	Query.SetParameter("TableOfGoods",	Goods.Unload(, "LineNumber, Products, InventoryOwnerAttribute"));
	RegistrationCountry				= SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	UseExcisableGoods	= GetFunctionalOption("UseExcisableGoods");
	
	Query.SetParameter("Date",							Date);
	Query.SetParameter("Country",							RegistrationCountry);
	Query.SetParameter("SubjectToExcise",				SubjectToExcise);
	Query.SetParameter("BusinessUnitProduction",		BusinessUnitProduction);
	Query.SetParameter("UseExcisableGoods",	UseExcisableGoods);
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	Query.Execute();
	
	InventoriesServer.FillStockTypesByDefault(TempTablesManager, Goods);
	
EndProcedure

#EndRegion

#Region Other

Function TypeOfDiscrepancyReportAcceptance(DiscrepancyCertificate)
	
	TypeOfBaseDocumentForNonConformanceCertificate = Common.ObjectAttributeValue(DiscrepancyCertificate,
		"TypeOfBaseDocumentForNonConformanceCertificate");
	
	TypesOfGroundsForCertificateOfDiscrepancyAcceptance = New Array;
	TypesOfGroundsForCertificateOfDiscrepancyAcceptance.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage);
	TypesOfGroundsForCertificateOfDiscrepancyAcceptance.Add(Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider);
	Return TypesOfGroundsForCertificateOfDiscrepancyAcceptance.Find(TypeOfBaseDocumentForNonConformanceCertificate) <> Undefined;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
