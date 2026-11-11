#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.OtherGoodsRecordingAsReceived - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.OtherGoodsRecordingAsReceived.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
	If DocumentTables <> Undefined Then
		FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables);
		AdditionalProperties.Insert("TablesOfFillingOfTypesOfStocksAtExchange", DocumentTables);
	Else
		ParameterName = "DocumentTables";
		
		ExceptionText = NStr("vi = 'Để điền dạng vật tư, không chuyển tham số ""%1"".';
							|ru = 'Для заполнения видов запасов не передан параметр ""%1"".';
							|en = 'The ""%1"" parameter is not transferred to fill in the inventory owner attributes.'; fa = 'The ""%1"" parameter is not transferred to fill in the inventory owner attributes.';
							|it = 'Per la compilazione dei tipi di scorte non è indicato il parametro ""%1"".';
							|pl = 'Do wypełnienia rodzajów zapasów nie przekazano parametru ""%1"".';
							|tr = 'Stok türlerini tamamlamak için ""%1"" parametresi geçilmemiştir.'");
		ExceptionText = StrTemplate(ExceptionText, ParameterName);
		
		Raise ExceptionText;
	EndIf;
	
	FillStockTypes(Cancel);
	AdditionalProperties.Delete("TablesOfFillingOfTypesOfStocksAtExchange");
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
 	Var HeaderAttributes;
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("DocumentRef.InventoryConsumption") Then
		
		Operation = Common.ObjectAttributeValue(FillingData, "BusinessOperation");
		
		If Operation = Enums.BusinessTransactions.GoodsConsumptionOnDemand Then
			
			FillInDocumentBasedOnWriteOffForExpenses(FillingData);
	
		ElsIf Operation = Enums.BusinessTransactions.TransferToOperation Then
			
			FillInDocumentOnBasisOfTransferIntoOperation(FillingData);
			
		Else
			
			ExceptionText = NStr("vi = 'Không thể nhập trên cơ sở giao dịch ""%1"".';
								|ru = 'Ввод на основании операции ""%1"" не предусмотрен.';
								|en = 'Generation from operation ""%1"" is not allowed.'; fa = 'Generation from operation ""%1"" is not allowed.';
								|it = 'L''inserimento in base all''operazione ""%1"" non è previsto.';
								|pl = 'Wprowadzanie oparte na operacji „%1” nie jest dostępne.';
								|tr = '""%1"" işlemine dayalı bir giriş yoktur.'");
			ExceptionText = StrTemplate(ExceptionText, String(Operation));
			
			Raise ExceptionText;
			
		EndIf;
	ElsIf FillInDataType = Type("DocumentRef.DisposeFixedAssets2_4") Then
		
		FillOutDocumentBasedOnFAWriteOff(FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.PhysicalCountOfInventoryInOperation")
		Or TypeOf(FillingData) = Type("Structure")
			And FillingData.Property("DocumentBasis")
			And TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.PhysicalCountOfInventoryInOperation") Then
		
		FillInOnBasisOfInventoryOfInventoryItemsOfOperation(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.OtherGoodsRecordingAsReceived") Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Goods") Then
		
		If FillingData.Property("HeaderAttributes") Then
			FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
		EndIf;
		
		For Each CollectionItem In FillingData.Goods Do
			RowData = Goods.Add();
			FillPropertyValues(RowData, CollectionItem);
		EndDo;
		
	EndIf;
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.OtherGoodsRecordingAsReceived.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InitializeDocument(FillingData);
	
	RecalculateNumberOfRNPT();
	
	OtherGoodsRecordingAsReceivedLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
	
	SetOfSeries.Clear();
	InventoryKinds.Clear();
	
	For Each TSRow In Goods Do
		TSRow.InventoryOwnerAttribute = Undefined;
	EndDo;
	
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	
	InitializeDocument();
	
	RecalculateNumberOfRNPT();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	OtherGoodsRecordingAsReceivedLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf; 
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromProduction And Not DeletionMark Then
		MessageText = NStr("vi = 'Cấm ghi lại chứng từ, bởi vì giao dịch ""Trả lại từ sản xuất"" vẫn chưa được sử dụng.
								|Đang lập chứng từ trả lại nguyên vật liệu trong biểu mẫu ""Sản xuất - Nhận và trả lại nguyên vật liệu"".';
								|ru = 'Запись документа запрещена, т.к. операция ""Возврат из производства"" больше не используется.
								|Возврат материалов оформляется в форме ""Производство - Получение и возврат материалов"".';
								|en = 'It is prohibited to save the document as operation ""Return from production"" is not used.
								|Material return is registered in form ""Production — Receipt and return of materials"".'; fa = 'It is prohibited to save the document as operation ""Return from production"" is not used.
								|Material return is registered in form ""Production — Receipt and return of materials"".';
								|it = 'La scrittura del documento è vietata, perché l''operazione ""Reso dalla produzione"" non viene più utilizzata.
								|Il reso dei materiali viene formalizzato sotto forma ""Produzione - Ricevimento e reso dei materiali"".';
								|pl = 'Zapisanie dokumentu jest zabronione, ponieważ operacja ""Zwrot z produkcji"" nie jest więcej już stosowana.
								|Zwrot materiałówsporządza się w formie ""Produkcja - Odbiór i zwrot materiałów"".';
								|tr = '""Üretimden iade"" işlemi artık kullanılmadığı için belgenin kaydedilmesi yasaktır. 
								| Malzemelerin iadesi ""Üretim - Malzemelerin teslim alınması ve iadesi"" şeklinde gerçekleştirilir.'");
		Common.MessageToUser(MessageText, Ref,,, Cancel);	
	EndIf;
	ProductsServer.ClearUnusedSeries(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.OtherGoodsRecordingAsReceived));
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps		= New Array;
	ArrayOfOperationDetails	= New Array;
	
	Documents.OtherGoodsRecordingAsReceived.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
		
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		InventoryKinds.Clear();
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.OtherGoodsRecordingAsReceived.AccountingAccountSettings_(BusinessOperation));
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.OtherGoodsRecordingAsReceived.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	If BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation Then
		
		If Not Cancel And Not IsNew() And WriteMode <> DocumentWriteMode.Write Then
			PrepareDataForFormationOfTaskByEndOfMonthBeforeRecording();
		EndIf;
		
	EndIf;
	// The mechanism of "Controlled Lot references".
	KeyAttributes = QualityControl.DetailsOfDeterminingNeedForLotReferenceInDocument(Warehouse, BusinessOperation);
	QualityControl.FillInControlledLotReferenceBeforeWritingDocument(ThisObject, KeyAttributes);
	
	OtherGoodsRecordingAsReceivedLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateUpdateControlledLotReferenceWhenWritingDocument(ThisObject);
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	OtherGoodsRecordingAsReceivedLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var ArrayOfAllProps;
	Var ArrayOfOperationDetails;
	
	Documents.OtherGoodsRecordingAsReceived.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	NotCheckedAttributeArray = New Array;
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	// Checking the quantity including goods.
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	// Checking the characteristics, including goods.
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.OtherGoodsRecordingAsReceived);
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		SeriesSpecificationParameters,
		Cancel,
		NotCheckedAttributeArray);
		
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters = Documents.OtherGoodsRecordingAsReceived.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
		
	OperationsWhereYouDonTNeedToFillOutDivision = Documents.OtherGoodsRecordingAsReceived.OperationsWhereYouDonTNeedToFillOutDivision();
	If OperationsWhereYouDonTNeedToFillOutDivision.Find(BusinessOperation) <> Undefined Then
		NotCheckedAttributeArray.Add("Department");
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date);
	
	If (ThisIsTraceableDocument
			Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers"))
		And BusinessOperation <> Enums.BusinessTransactions.InventoryConsumptionReverseTransaction Then
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel);
		
	EndIf;
	
	If ThisIsTraceableDocument Then
		AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject, Goods, Date);
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	If BusinessOperation <> Enums.BusinessTransactions.PutOutOfOperation Then
		NotCheckedAttributeArray.Add("Goods.Lot");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation Then
		
		CheckParameters = InventoryInOperationServer.InventoryControlParameters();
		CheckParameters.PresentationOfTS = NStr("vi = 'Hàng hóa';
												|ru = 'Товары';
												|en = 'Goods'; fa = 'کالاها';
												|it = 'Articoli';
												|pl = 'Goods';
												|tr = 'Ürünler'");
		CheckParameters.PropsNameQuantity = "NumberOfPackages";
		InventoryInOperationServer.CheckInventoryRecords(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		
		CheckParameters = InventoryInOperationServer.ParametersForCheckingAccountingForIndividuals();
		CheckParameters.PresentationOfTS = NStr("vi = 'Hàng hóa';
												|ru = 'Товары';
												|en = 'Goods'; fa = 'کالاها';
												|it = 'Articoli';
												|pl = 'Goods';
												|tr = 'Ürünler'");
		InventoryInOperationServer.CheckAccountingForIndividuals(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		
	EndIf;
	
	If Not SubjectToExcise Then
		NotCheckedAttributeArray.Add("BusinessUnitProduction");
	Else
		ControlParameters = ExcisableGoodsAccounting.ControlParametersForFillingExcisableItems();
		ControlParameters.ErrorTextTemplate =
			NStr("vi = 'Đã cấm ghi tăng hàng hóa chịu thuế TTĐB ""%Products%"" mà được chỉ ra trong dòng %LineNumber% của danh sách ""%TabularSectionPresentation%"" vào kho bán lẻ ""%Warehouse%""';
				|ru = 'Запрещено оприходование подакцизного товара ""%Products%"", указанного в строке %LineNumber% списка ""%TabularSectionPresentation%"" на розничный склад ""%Warehouse%""';
				|en = 'Cannot receive the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list  in the ""%Warehouse%"" retail warehouse'; fa = 'Cannot receive the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list  in the ""%Warehouse%"" retail warehouse';
				|it = 'Cannot receive the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list  in the ""%Warehouse%"" retail warehouse';
				|pl = 'Cannot receive the ""%Products%"" excisable goods specified in line %LineNumber% of the ""%TabularSectionPresentation%"" list  in the ""%Warehouse%"" retail warehouse';
				|tr = '""%TabularSectionPresentation%"" listesinin %LineNumber% satırında belirtilen tüketim vergisine tabi ""%Products%"" ürününün ""%Warehouse%"" perakende ambarına envanter girişi yasaktır'");
		ControlParameters.CheckingWarehouse = True;
		ExcisableGoodsAccounting.ControlOfFillingExcisableItems(ThisObject, ControlParameters, Cancel);
	EndIf;
	QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Wiersze pozycji';
			|tr = 'Ürünler'"),
		"DateOfReceipt");
		
	QualityControl.ProcessingVerificationOfCorrectnessOfConnectionWithBatches(
		ThisObject,
		SeriesSpecificationParameters.LinkFields,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Towary';
			|tr = 'Ürünler'"),
		Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	OtherGoodsRecordingAsReceivedLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	If BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation Then
		CreateTasksForEndOfMonthWhenRecording();
	EndIf;
	OtherGoodsRecordingAsReceivedLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	OtherGoodsRecordingAsReceivedLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//    Table - See AccessManagement.AccessValuesSetsTable
Procedure FillAccessValuesSets(Table) Export
	
	TabRow = Table.Add();
	TabRow.AccessValue = Organization;
	
	TabRow = Table.Add();
	TabRow.AccessValue = Warehouse;
	
	TabRow = Table.Add();
	TabRow.AccessValue = Department;
	
EndProcedure

#Region InitializationAndFilling

Procedure FillOutDocumentBasedOnFAWriteOff(Val DocumentBasis)
	
	QueryText = 
	"SELECT
	|	VALUE(Enum.BusinessTransactions.RegistrationAtFADisposal) AS BusinessOperation,
	|	Document.Department AS Department,
	|	Document.Organization AS Organization,
	|	Document.Ref AS DocumentBasis,
	|	Document.RetirementItem AS RetirementItem
	|FROM
	|	Document.DisposeFixedAssets2_4 AS Document
	|WHERE
	|	Document.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Count AS Count,
	|	Goods.Count AS NumberOfPackages,
	|	Goods.FixedAsset AS FixedAsset,
	|	UNDEFINED AS Package,
	|	UNDEFINED AS Purpose
	|FROM
	|	Document.DisposeFixedAssets2_4.RecordedAsReceivedTangibleAssets AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.Count > 0";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", DocumentBasis);
	
	ResultsArray = Query.ExecuteBatch();
	
	HeaderSelection = ResultsArray[0].Select();
	HeaderSelection.Next();
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	Goods.Load(ResultsArray[1].Unload());
	
EndProcedure

Procedure FillInOnBasisOfInventoryOfInventoryItemsOfOperation(Val FillingData)
	
	If TypeOf(FillingData) = Type("Structure") Then
		DocumentBasis = FillingData.DocumentBasis;
		ArrayOfLineNumbers = FillingData.ArrayOfLineNumbers;
		ReportErrors = FillingData.ReportErrors;
	Else
		DocumentBasis = FillingData;
		ArrayOfLineNumbers = Undefined;
		ReportErrors = True;
	EndIf;
	
	BusinessOperation = Enums.BusinessTransactions.PutOutOfOperation;
	
	ActionCompleted = Documents.OtherGoodsRecordingAsReceived.FillInOnBasisOfInventoryOfInventoryItemsOfOperation(ThisObject, ArrayOfLineNumbers);
	
	If Not ActionCompleted And ReportErrors Then
		
		ErrorText = NStr("vi = 'Trong chứng từ %1 không có các dòng cần trả lại';
						|ru = 'В документе %1 отсутствуют строки требующие возврата';
						|en = 'There are no lines that require return in the %1 document'; fa = 'There are no lines that require return in the %1 document';
						|it = 'Nel documento %1 mancano le stringhe che richiedono il reso';
						|pl = 'W dokumencie %1 brak wierszy wymagających zwrotu';
						|tr = '%1Belgesinde iade edilmesi gereken satır yok'");
		ErrorText = StrTemplate(ErrorText, DocumentBasis);
		Common.MessageToUser(ErrorText,, "Object.DocumentBasis");
		
	EndIf; 
	
EndProcedure

Procedure FillInDocumentBasedOnWriteOffForExpenses(Val DocumentBasis)
	
	Query = New Query("SELECT
	|	VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction) AS BusinessOperation,
	|	InventoryConsumption.Ref AS DocumentBasis,
	|	InventoryConsumption.Warehouse AS Warehouse,
	|	InventoryConsumption.Department AS Department,
	|	InventoryConsumption.LineOfBusiness AS LineOfBusiness,
	|	InventoryConsumption.Organization AS Organization,
	|	NOT InventoryConsumption.Posted AS ThereAreErrorsPosted
	|FROM
	|	Document.InventoryConsumption AS InventoryConsumption
	|WHERE
	|	InventoryConsumption.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	&Ref AS ExpenseAs,
	|	CASE WHEN Goods.BatchesIndicationStatus <> 10 THEN
	|			Goods.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END AS Series,
	|	CASE
	|		WHEN VALUETYPE(Assignments.OrderDocument) = TYPE(Document.InventoryConsumptionOrder)
	|			OR VALUETYPE(Assignments.OrderDocument) = TYPE(Document.RMOrder)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE Goods.Purpose
	|	END AS Purpose,
	|	Goods.Package AS Package,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Count AS Count,
	|	Goods.ExpenseItem AS ExpenseAndIncomeItem,
	|	Goods.DimensionOfExpenses AS DimensionOfExpenses
	|FROM
	|	Document.InventoryConsumption.Goods AS Goods
	|		LEFT JOIN Catalog.Assignments AS Assignments
	|		ON Goods.Purpose = Assignments.Ref
	|WHERE
	|	Goods.Ref = &Ref
	|	AND NOT Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Series AS Series,
	|	Table.Count AS Count,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	CASE
	|		WHEN VALUETYPE(Assignments.OrderDocument) = TYPE(Document.InventoryConsumptionOrder)
	|			OR VALUETYPE(Assignments.OrderDocument) = TYPE(Document.RMOrder)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE Table.Purpose
	|	END AS Purpose
	|FROM
	|	Document.InventoryConsumption.SetOfSeries AS Table
	|		LEFT JOIN Catalog.Assignments AS Assignments
	|		ON Table.Purpose = Assignments.Ref
	|WHERE
	|	Table.Ref = &Ref
	|	AND NOT (Table.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|	AND Table.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= Table.Ref.Date)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Series AS Series,
	|	SUM(Table.Count) AS Count,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	CASE
	|		WHEN VALUETYPE(Assignments.OrderDocument) = TYPE(Document.InventoryConsumptionOrder)
	|			OR VALUETYPE(Assignments.OrderDocument) = TYPE(Document.RMOrder)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE Table.Purpose
	|	END AS Purpose
	|FROM
	|	Document.InventoryConsumption.Goods AS Table
	|		LEFT JOIN Catalog.Assignments AS Assignments
	|		ON Table.Purpose = Assignments.Ref
	|WHERE
	|	Table.Ref = &Ref
	|	AND NOT Table.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND Table.BatchesIndicationStatusSender = 10
	|	AND NOT (Table.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|	AND Table.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= Table.Ref.Date)
	|GROUP BY
	|	Table.Series,
	|	Table.Products,
	|	Table.Characteristic,
	|	CASE
	|		WHEN VALUETYPE(Assignments.OrderDocument) = TYPE(Document.InventoryConsumptionOrder)
	|			OR VALUETYPE(Assignments.OrderDocument) = TYPE(Document.RMOrder)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE Table.Purpose
	|	END");
	
	Query.SetParameter("Ref", DocumentBasis);
	
	ResultsArray = Query.ExecuteBatch();
	HeaderSelection = ResultsArray[0].Select();
	HeaderSelection.Next();
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(DocumentBasis, , HeaderSelection.ThereAreErrorsPosted);
	FillPropertyValues(ThisObject, HeaderSelection);
	Goods.Load(ResultsArray[1].Unload());
	SetOfSeries.Load(ResultsArray[2].Unload());
	
EndProcedure

Procedure FillInDocumentOnBasisOfTransferIntoOperation(DocumentBasis)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	VALUE(Enum.BusinessTransactions.PutOutOfOperation) AS BusinessOperation,
	|	InventoryConsumption.Ref AS DocumentBasis,
	|	InventoryConsumption.Warehouse AS Warehouse,
	|	InventoryConsumption.Department AS Department,
	|	InventoryConsumption.Organization AS Organization,
	|	InventoryConsumption.LineOfBusiness AS LineOfBusiness,
	|	NOT InventoryConsumption.Posted AS ThereAreErrorsPosted
	|
	|FROM
	|	Document.InventoryConsumption AS InventoryConsumption
	|
	|WHERE
	|	InventoryConsumption.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|
	|	CASE
	|		WHEN Goods.Ref.ExpenseLineOfBusinessIsSpecifiedInList
	|			THEN Goods.LineOfBusiness
	|		ELSE Goods.Ref.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	CASE
	|		WHEN Goods.BatchesIndicationStatusSender <> 10
	|			THEN Goods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|
	|	&Ref AS TransferToOperation,
	|	Goods.Package AS Package,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Count AS Count,
	|	Goods.Lot AS Lot,
	|	Goods.AssetID AS AssetID,
	|	Goods.Individual AS Individual
	|FROM
	|	Document.InventoryConsumption.Goods AS Goods
	|
	|WHERE
	|	Goods.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Series AS Series,
	|	SetOfSeries.Count AS Count,
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Purpose AS Purpose,
	|	SetOfSeries.Characteristic AS Characteristic
	|FROM
	|	Document.InventoryConsumption.SetOfSeries AS SetOfSeries
	|
	|WHERE
	|	SetOfSeries.Ref = &Ref
	|		AND NOT (SetOfSeries.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND SetOfSeries.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= SetOfSeries.Ref.Date)
	|	
	|UNION ALL
	|	
	|SELECT
	|	Goods.Series AS Series,
	|	SUM(Goods.Count) AS Count,
	|	Goods.Products AS Products,
	|	Goods.Purpose AS Purpose,
	|	Goods.Characteristic AS Characteristic
	|FROM
	|	Document.InventoryConsumption.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|		AND Goods.BatchesIndicationStatusSender = 10
	|		AND NOT (Goods.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Goods.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= Goods.Ref.Date)
	|GROUP BY
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Purpose,
	|	Goods.Characteristic";
	
	Query.SetParameter("Ref", DocumentBasis);
	
	ResultsArray = Query.ExecuteBatch();
	
	HeaderSelection = ResultsArray[0].Select();
	HeaderSelection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(DocumentBasis, , HeaderSelection.ThereAreErrorsPosted);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	Goods.Load(ResultsArray[ResultsArray.UBound()-1].Unload());
	SetOfSeries.Load(ResultsArray[ResultsArray.UBound()].Unload());
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)

	EmployeeResponsible = Users.CurrentUser();
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	Warehouse         = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	If Not ValueIsFilled(PriceKind) Then
		StorageForFilling = Warehouse;
		If TypeOf(FillingData) = Type("Structure")
				And FillingData.Property("Warehouse") Then
				StorageForFilling = FillingData.Warehouse;
		EndIf;
		PriceKind = Catalogs.Warehouses.AccountingPriceType(StorageForFilling);
	EndIf;
	If Not ValueIsFilled(Currency) Then
		Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(
			Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind).PriceCurrency);
	EndIf;
	
	GoodsReceiptOption = Constants.GoodsReceiptOption.Get();
	
	If Not (TypeOf(FillingData) = Type("Structure") And FillingData.Property("Goods"))
			And Not FillingData = Undefined Then
		StructureOfFillingPrices = New Structure("Date,Currency,PriceKind", Date, Currency, PriceKind);
		StructureOfRecalculation = New Structure("RecalculateAmount", "NumberOfPackages");
		EnterprisePricesFillingServer.FillInPrices(Goods, , StructureOfFillingPrices, StructureOfRecalculation);
	EndIf;
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	If Cancel Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	TempTablesManager = TemporaryDocumentDataTables();
	
	If BusinessOperation <> Enums.BusinessTransactions.InventoryConsumptionReverseTransaction Then
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, Goods);
	Else // household. operation - Reverse write-offs for expenses.
		RefillInventoryKinds = Not Posted
									Or InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject)
									Or CheckChangesToDocumentDetails(TempTablesManager)
									Or CheckProductChanges_(TempTablesManager);
		
		If RefillInventoryKinds Then
			FillParameters = ParametersForFillingInventoryTypes();
			
			InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																	TempTablesManager,
																	Cancel,
																	FillParameters);
			
			InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, InventoryOwnerAttributeShipment, OriginWarehouse,
								|DocumentSalesOfGoodsAndServices, ExpenseItem, DimensionOfExpenses, ItemsLocationAttributesShipment",
								"Count, QuantityByGBRN");
			
			FillInExpenseItemOfInventoryTypes();
		EndIf;
		
	EndIf;

EndProcedure

// The procedure fills in the item and expense analysis of the document's inventory types.
//
Procedure FillInExpenseItemOfInventoryTypes()
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In Goods Do
		
		GoodsQuantity = RowOfGoods.Count;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.ExpenseItem	= RowOfGoods.ExpenseAndIncomeItem;
			NewRow.DimensionOfExpenses	= RowOfGoods.DimensionOfExpenses;
			NewRow.Count			= Count;
			NewRow.QuantityByGBRN	= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			InventoryLine.Count	= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			
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

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.NameOfRemainderTable = "GoodsWrittenOffAsExpenses";
	FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
	FillParameters.ReversedDocument = ReversedDocument;
	If GetFunctionalOption("UseExcisableGoods")
		And BusinessOperation <> Enums.BusinessTransactions.InventoryConsumptionReverseTransaction Then
		FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
	EndIf;
	Return FillParameters;
	
EndFunction

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.OtherGoodsRecordingAsReceived.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.OtherGoodsRecordingAsReceived.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Warehouse,
																		Department,
																		Undefined);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.BatchesIndicationStatus = "BatchesIndicationStatusRecipient";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#Region Other

// The function creates a temporary data table of the document.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	QueryTexts = New Array;
	
	PartOfTheRequestText = 
	"SELECT
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.InventoryConsumptionReverseTransaction) AS BusinessOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	&Warehouse AS Warehouse,
	|	TableOfGoods.ExpenseAs AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.ExpenseAndIncomeItem AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	TableOfGoods.Purpose AS Purpose,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.ExpenseItem AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfGoods.SalesOpportunity AS SalesOpportunity,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.CommissionAmount AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration AS AmountVATRemuneration,
	|	CASE
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS SelectTypesOfStocks,
	|	Dimension.DimensionKey AS AnalysisOfAccountingForProductList,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON TableOfGoods.Products = CatProducts.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON TableOfGoods.Products = Dimension.Products
	|			AND TableOfGoods.Characteristic = Dimension.Characteristic
	|			AND TableOfGoods.Series = Dimension.Series
	|			AND TableOfGoods.Warehouse = Dimension.StorageLocation
	|			AND TableOfGoods.Purpose = Dimension.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Series AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	TableTypesOfStocks_.OriginWarehouse AS OriginWarehouse,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Products AS ProductsRecordingAsReceived,
	|	Dimension.Characteristic AS CharacteristicRecordingAsReceived,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.OriginWarehouse AS OriginWarehouse,
	|	Dimension.StorageLocation AS Warehouse,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.SalesOpportunity AS SalesOpportunity,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	FALSE AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes";
	QueryTexts.Add(PartOfTheRequestText);
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems());
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
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN Document.OtherGoodsRecordingAsReceived AS SavedData
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
	|	OR &RefillInventoryKinds";
	QueryTexts.Add(PartOfTheRequestText);
	
	TempTablesManager	= New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	Query.SetParameter("Ref",				Ref);
	Query.SetParameter("Posted",			Posted);
	Query.SetParameter("Date",				Date);
	Query.SetParameter("Organization",		Organization);
	Query.SetParameter("Warehouse",				Warehouse);
	Query.SetParameter("TableOfGoods",		TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",	InventoryKinds);
	RegistrationCountry				= SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	UseExcisableGoods	= GetFunctionalOption("UseExcisableGoods")
		And BusinessOperation <> Enums.BusinessTransactions.InventoryConsumptionReverseTransaction;
	
	Query.SetParameter("Country",							RegistrationCountry);
	Query.SetParameter("SubjectToExcise",				SubjectToExcise);
	Query.SetParameter("BusinessUnitProduction",		BusinessUnitProduction);
	Query.SetParameter("UseExcisableGoods",	UseExcisableGoods);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Date, Organization";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.DocumentSalesOfGoodsAndServices			AS DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.ExpenseItem				AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses			AS DimensionOfExpenses
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		TableOfGoods.DocumentSalesOfGoodsAndServices			AS DocumentSalesOfGoodsAndServices,
	|		TableOfGoods.ExpenseItem				AS ExpenseItem,
	|		TableOfGoods.DimensionOfExpenses			AS DimensionOfExpenses,
	|		TableOfGoods.Count					AS Count
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.DocumentSalesOfGoodsAndServices			AS DocumentSalesOfGoodsAndServices,
	|		TableTypesOfStocks_.ExpenseItem				AS ExpenseItem,
	|		TableTypesOfStocks_.DimensionOfExpenses			AS DimensionOfExpenses,
	|		-TableTypesOfStocks_.Count					AS Count
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.DocumentSalesOfGoodsAndServices,
	|	TableOfGoods.ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0";
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure RecalculateNumberOfRNPT()
	
	ExcludedTransactions = New Array;
	ExcludedTransactions.Add(Enums.BusinessTransactions.EmptyRef());
	ExcludedTransactions.Add(Enums.BusinessTransactions.InventoryConsumptionReverseTransaction);
	
	If ExcludedTransactions.Find(BusinessOperation) = Undefined Then
		RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												ThisObject);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	EndIf;
	
EndProcedure

Procedure PrepareDataForFormationOfTaskByEndOfMonthBeforeRecording()
	
	AdditionalProperties.Insert("TablesData",
		New Structure("TempTablesManager", New TempTablesManager));
	
	QueryText = 
	"SELECT
	|	TableBeforeWrite.Ref.Date AS Period,
	|	TableBeforeWrite.Ref.Organization AS Organization,
	|	TableBeforeWrite.Lot AS Lot,
	|	TableBeforeWrite.Sum AS Sum
	|INTO OtherGoodsRecordingAsReceived_BeforeWrite
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.Goods AS TableBeforeWrite
	|WHERE
	|	TableBeforeWrite.Ref = &Ref
	|	AND TableBeforeWrite.Ref.Posted";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TablesData.TempTablesManager;
	Query.SetParameter("Ref", Ref);
	Query.Execute();
	
EndProcedure

Procedure CreateTasksForEndOfMonthWhenRecording()
	
	If DocumentsPosting.DocumentProperties(ThisObject).IsNew Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT DISTINCT
	|	Table.Period AS Period,
	|	Table.Organization AS Organization,
	|	Table.Lot AS Lot,
	|	&Ref AS Document
	|INTO OtherGoodsRecordingAsReceivedUpdate
	|FROM
	|	(SELECT
	|		TableBeforeWrite.Period AS Period,
	|		TableBeforeWrite.Organization AS Organization,
	|		TableBeforeWrite.Lot AS Lot
	|	FROM
	|		OtherGoodsRecordingAsReceived_BeforeWrite AS TableBeforeWrite
	|			LEFT JOIN Document.OtherGoodsRecordingAsReceived.Goods AS TableWhenWriting
	|			ON (TableWhenWriting.Lot = TableBeforeWrite.Lot)
	|				AND (TableWhenWriting.Ref = &Ref)
	|	WHERE
	|		(TableWhenWriting.Ref IS NULL
	|				OR TableWhenWriting.Sum <> TableBeforeWrite.Sum)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableWhenWriting.Ref.Date,
	|		TableWhenWriting.Ref.Organization,
	|		TableWhenWriting.Lot
	|	FROM
	|		Document.OtherGoodsRecordingAsReceived.Goods AS TableWhenWriting
	|			LEFT JOIN OtherGoodsRecordingAsReceived_BeforeWrite AS TableBeforeWrite
	|			ON TableWhenWriting.Lot = TableBeforeWrite.Lot
	|				AND (TableWhenWriting.Ref = &Ref)
	|	WHERE
	|		(TableWhenWriting.Ref IS NULL
	|				OR TableWhenWriting.Sum <> TableBeforeWrite.Sum)) AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP OtherGoodsRecordingAsReceived_BeforeWrite";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = AdditionalProperties.TablesData.TempTablesManager;
	Query.SetParameter("Ref", Ref);
	Selection = Query.ExecuteBatch()[0].Select();
	Selection.Next();
	
	AdditionalProperties.TablesData.Insert("OtherGoodsRecordingAsReceivedUpdate", Selection.Count > 0);
	
	NonCurrentAssets.GenerateTaskRegisterEntries(ThisObject, AdditionalProperties.TablesData);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
