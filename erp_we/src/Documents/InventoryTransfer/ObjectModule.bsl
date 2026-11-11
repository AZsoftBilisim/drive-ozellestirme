#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
// 		NewStatus - String - Name of the status that will be set for orders
// 		AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
// 		Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export

	Status= Enums.GoodsTransferStatuses[NewStatus];
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryTransfer);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	Return CheckFilling();

EndFunction

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.InventoryTransfer - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode) Export
	
	FillParameters = ParametersForFillingInventoryTypes("Organization");
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillParameters = ParametersForFillingInventoryTypes("CompanyRecipient");
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		
		SenderParameters	= ParametersForFillingInventoryTypes("Organization");
		RecipientParameters		= ParametersForFillingInventoryTypes("CompanyRecipient");
		
		If TMCommonUseClientServer.StructuresAreEqual(SenderParameters, RecipientParameters) Then
			FillParameters = SenderParameters;
		Else
			FillParameters = New Array;
			FillParameters.Add(SenderParameters);
			FillParameters.Add(RecipientParameters);
		EndIf;
		
	EndIf;
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure

// Fills the given dimensions of the item. Used in the leftovers report for organizations.
//
Procedure FillInProductTrackingForm() Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();

EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.InventoryTransfer.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
	If DocumentTables <> Undefined Then
		FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables);
		AdditionalProperties.Insert("TablesOfFillingOfTypesOfStocksAtExchange", DocumentTables);
	EndIf;
	
	FillStockTypes(Cancel);
	AdditionalProperties.Delete("TablesOfFillingOfTypesOfStocksAtExchange");
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("Basis") Then
			
			If TypeOf(FillingData.Basis) = Type("DocumentRef.GoodsQualityControlCertificate") Then
				FillInCertificateOfQualityControl(FillingData);
			ElsIf TypeOf(FillingData.Basis) = Type("DocumentRef.GoodsReceiptForStorage") Then
				InstructionsForAcceptanceOfGoodsForStorage(FillingData);
			ElsIf TypeOf(FillingData.Basis) = Type("DocumentRef.VendorInvoice") Then
				InstructionsForPurchasingGoods(FillingData);
			EndIf;
	
		ElsIf FillingData.Property("AnArrayOfOrders") Then
			
			FillInFromOrder(FillingData);
			
		ElsIf FillingData.Property("DiscrepancyCertificate") 
			And FillingData.Property("InventoryTransfer") Then
			
			FillInDocumentOnBasisOfActOfDiscrepanciesAfterMoving(FillingData);
			
		ElsIf FillingData.Property("Goods") Then
			
			FillInSelectionDocument(FillingData);
			
		EndIf;
		
		If FillingData.Property("Warehouse") Then
			SourceWarehouse = FillingData.Warehouse;
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		InformationOnReceiptOfGoods(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ApplicationForCollateral") Then
		FillInDocumentBasedOnSupplyRequest(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.InventoryTransfer") Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	If Not GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
		BusinessOperation = Enums.BusinessTransactions.InventoryTransfer;
	EndIf;
	
	InventoryTransferLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	Documents.TransferOrder.CheckAndClearOrganization(ThisObject, CompanyRecipient);
	Documents.TransferOrder.CheckAndClearOrganization(ThisObject, Organization);
	
	InitializeDocument(FillingData);
	
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	// A feature.
	RowsToProcess = New Array();
	For Each RowData In Goods Do
		If TransferAgainstOrders 
			And ValueIsFilled(TransferOrder) 
			And Not ValueIsFilled(RowData.TransferOrder) Then
		
			// If the transfer is on order, then you need to fill in an empty order
			RowData.TransferOrder = TransferOrder;
			RowsToProcess.Add(RowData);
			
		EndIf;
	EndDo;
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	ProductsServer.ClearUnusedSeries(ThisObject,ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryTransfer));
	
	FillInTransactionInProductsTable();
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		InformationRegisters.SetAccountingDimension.FillInCollection(Goods);
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.InventoryTransfer.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	// The mechanism of "Controlled Lot references".
	KeyAttributes = QualityControl.DetailsOfDeterminingNeedForLotReferenceInDocument(DestinationWarehouse, BusinessOperation);
	QualityControl.FillInControlledLotReferenceBeforeWritingDocument(ThisObject, KeyAttributes);
	
	If GetFunctionalOption("UseGoodsQualityControl") Then
		
		// The filling is controlled by the party.
		For Each TableRow In Goods Do
			If ValueIsFilled(TableRow.ControlledLotOfTheSender) Then
				TableRow.ControlledLotReference = TableRow.ControlledLotOfTheSender;
			Else
				TableRow.ControlledLotReference = ControlledLotReference;
			EndIf;
		EndDo;
		
	EndIf;
	
	InventoryTransferLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)

	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.InventoryTransfer.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation, 
		ArrayOfAllProps, 
		ArrayOfOperationDetails);
	
	NotCheckedAttributeArray = New Array;

	If Not LockedGoodsTransfer Then
		NotCheckedAttributeArray.Add("ControlledLotOfTheSender");
	EndIf;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);

	If ValueIsFilled(SourceWarehouse) And SourceWarehouse = DestinationWarehouse Then

		CommonClientServer.MessageToUser(NStr("vi = 'Một kho không thể vừa là nơi gửi vừa là nơi nhận. Hãy thay đổi một trong các kho.';
												|ru = 'Один склад не может быть как отправителем, так и получателем. Измените один из складов.';
												|en = 'The same warehouse cannot be both shipping and receiving. Change one of the warehouses.'; fa = 'The same warehouse cannot be both shipping and receiving. Change one of the warehouses.';
												|it = 'Un magazzino non può essere sia mittente che destinatario. Modificare uno dei magazzini.';
												|pl = 'Jeden magazyn nie może być zarówno nadawcą, jak i odbiorcą. Zmień jeden z magazynów.';
												|tr = 'Bir ambar hem gönderici hem de alıcı olamaz. Ambarlardan birini değiştir.'"),
				ThisObject,
				"SourceWarehouse",
				,
				Cancel);

	EndIf;

	// The receiving organization must be interconnected with the sending organization by organizational structure.
	If BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices
		And ValueIsFilled(Organization)
		And ValueIsFilled(CompanyRecipient)
		And Not Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Organization, CompanyRecipient) Then
		
		ErrorText = NStr("vi = 'Doanh nghiệp nhận hàng phải có quan hệ với doanh nghiệp gửi hàng theo cơ cấu tổ chức.';
						|ru = 'Организация-получатель должна быть взаимосвязана с организацией-отправителем по организационной структуре.';
						|en = 'Receiving company should be connected with a shipping company by the organizational structure.'; fa = 'Receiving company should be connected with a shipping company by the organizational structure.';
						|it = 'La società-destinatario deve essere interconnessa con la società-mittente per la struttura organizzativa.';
						|pl = 'Firma odbiorca powinna być wzajemnie powiązana z firmą nadawcą według struktury organizacyjnej.';
						|tr = 'Alıcı-iş yeri, organizasyon yapısı bakımından gönderen-iş yeri ile bağlantılı olmalıdır.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"CompanyRecipient",
			,
			Cancel);
		
	EndIf;

	// If the invoice is for an order, then the line code must be filled in.
	If Not ValueIsFilled(TransferOrder) Then
		NotCheckedAttributeArray.Add("Goods.RowCode");
	EndIf;

	// Checking the indication of characteristics.
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryTransfer),
												Cancel,
												NotCheckedAttributeArray);
	
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	GoodsDelivery.CheckDeliveryDetails(ThisObject, NotCheckedAttributeArray, Cancel, TransferAgainstOrders);
	
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName = "Goods";
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(
		ThisObject, 
		TransferForActivity, 
		CheckParameters, 
		Cancel);
	
	If Not TransferAgainstOrders
			Or ValueIsFilled(TransferOrder) Then // the transfer order will be filled in before the document is recorded
			
		NotCheckedAttributeArray.Add("Goods.TransferOrder");
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	QualityControl.ProcessingVerificationOfDocumentCompletionOfMove(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Goods'; fa = 'کالاها';
			|it = 'Goods';
			|pl = 'Goods';
			|tr = 'Ürünler'"),
		"DateOfReceipt");
		
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	InventoryTransferLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.Posting);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
	InventoryTransferLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.UndoPosting);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	
	InventoryTransferLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	DocumentBasis    = Undefined;
	TransferOrder   = Undefined;
	TransferAgainstOrders = False;
	InventoryOwnerAttributesAreSpecifiedManually = False;
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
	
	For Each TSRow In Goods Do
		
		TSRow.RowCode             = 0;
		TSRow.TransferOrder    = Documents.TransferOrder.EmptyRef();
		TSRow.SalesOpportunity                = Catalogs.SalesOpportunitiesToCustomer.EmptyRef();
		TSRow.Purpose            = Undefined;
		TSRow.RowID   = "";
		TSRow.AssignmentSender = Undefined;
		
	EndDo;

	InventoryKinds.Clear();
	SetOfSeries.Clear();
	
	InitializeDocument();
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	InventoryTransferLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateUpdateControlledLotReferenceWhenWritingDocument(ThisObject);
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	InventoryTransferLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//    Table - See AccessManagement.AccessValuesSetsTable
Procedure FillAccessValuesSets(Table) Export

	TabRow = Table.Add();
	TabRow.SetNumber     = 1;
	TabRow.AccessValue = Organization;

	TabRow = Table.Add();
	TabRow.SetNumber     = 1;
	TabRow.AccessValue = SourceWarehouse;

	TabRow = Table.Add();
	TabRow.SetNumber     = 2;
	TabRow.AccessValue = Organization;

	TabRow = Table.Add();
	TabRow.SetNumber     = 2;
	TabRow.AccessValue = DestinationWarehouse;

EndProcedure

#Region InitializationAndFilling

Procedure FillInFromOrder(FillingStructure)
	
	AnArrayOfOrders = FillingStructure.AnArrayOfOrders;
	
	FillParameters = Documents.InventoryTransfer.DocumentFillingParameters();
	FillPropertyValues(FillParameters, FillingStructure);
	Documents.InventoryTransfer.InitializeFillingParameters(FillParameters, FillingStructure.HeaderAttributes,
		AnArrayOfOrders);
	
	InvoiceTable = Documents.InventoryTransfer.TableDataAndDocument(Ref);
	
	Documents.InventoryTransfer.FillInByOrdersOrders(InvoiceTable, Ref, FillParameters, PackageBarcodes);
	
	If FillParameters.FillByWarehouseDocument Then
		InvoiceTable.Columns.Count.Name        = "QuantityBeforeChange_";
		InvoiceTable.Columns.NoteQuantity.Name = "Count";
	Else
		InvoiceTable.Columns.Count.Name        = "QuantityBeforeChange_";
		InvoiceTable.Columns.QuantityInOrder.Name = "Count";
	EndIf;
	
	InvoicesServer.DeleteEmptyLines(InvoiceTable, "Count");
	
	Goods.Load(InvoiceTable);
	
	Documents.InventoryTransfer.FillInHeaderOfOrderDocument(ThisObject, FillParameters, FillingStructure.AnArrayOfOrders);
	
	Documents.InventoryTransfer.UpdateDependentDetailsOfTablePart(Goods, FillParameters);
	
EndProcedure

Procedure FillInCertificateOfQualityControl(FillingData)
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Documents.GoodsQualityControlCertificate.GoodsToCreateBasedOn(
		Query,
		FillingData.Basis,
		FillingData.Warehouse,
		Enums.ActionsOnGoodsInQualityControlCertificate.RegisterGoodsTransfer);
	
	Query.SetParameter("DocumentBasis", FillingData.Basis);
	Query.Text =
		"SELECT
		|	Header.Organization AS Organization,
		|	Header.Department AS Department,
		|	Header.Status AS Status
		|FROM
		|	Document.GoodsQualityControlCertificate AS Header
		|WHERE
		|	Header.Ref = &DocumentBasis
		|;
		|
		|////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Purpose AS AssignmentSender,
		|	CASE
		|		WHEN Goods.BatchesIndicationStatus IN(10,14)
		|			THEN Goods.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END AS Series,
		|	Goods.Package AS Package,
		|	SUM(Goods.Count) AS Count,
		|	SUM(Goods.NumberOfPackages) AS NumberOfPackages
		|FROM
		|	Goods AS Goods
		|GROUP BY
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	CASE
		|		WHEN Goods.BatchesIndicationStatus IN(10,14)
		|			THEN Goods.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END,
		|	Goods.Package
		|;
		|
		|/////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Purpose AS AssignmentSender,
		|	Goods.Series AS Series,
		|	SUM(Goods.Count) AS Count
		|FROM
		|	Goods AS Goods
		|WHERE
		|	NOT Goods.BatchesIndicationStatus IN(10,14)
		|	AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	AND NOT (Goods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|		AND &DocumentDate <= Goods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue)
		|GROUP BY
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	Goods.Series";
	
	ResultsPackage = Query.ExecuteBatch();
	HeaderAttributes = ResultsPackage[0].Select();
	HeaderAttributes.Next();
	
	QualityControl.RaiseExceptionWhenCreatingBasedOnAct(HeaderAttributes);
	BaseGoods = ResultsPackage[1].Unload();
	BaseSeries = ResultsPackage[2].Unload();
	
	If BaseGoods.Count() = 0 Then
		ErrorText = NStr("vi = 'Chứng từ %Document% không có hàng hóa với thao tác ""Lập chứng từ điều chuyển"". Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Документ %Document% не содержит товаров c действием ""Оформить перемещение"". Ввод на основании документа запрещен.';
						|en = 'The ""%Document%"" document does not have any goods with the ""Register transfer"" action. Generation from such base documents is not allowed.'; fa = 'The ""%Document%"" document does not have any goods with the ""Register transfer"" action. Generation from such base documents is not allowed.';
						|it = 'The ""%Document%"" document does not have any goods with the ""Register transfer"" action. Generation from such base documents is not allowed.';
						|pl = 'The ""%Document%"" document does not have any goods with the ""Register transfer"" action. Generation from such base documents is not allowed.';
						|tr = '%Document% belgesi ""Transfer düzenle"" eylemine sahip ürün içermemektedir. Belgeye dayanarak giriş yapılması yasaktır.'");
		ErrorText = StrReplace(ErrorText, "%Document%", FillingData.Basis);
		Raise ErrorText;
	EndIf;
	
	FillPropertyValues(ThisObject, HeaderAttributes, "Organization,Department");
	DocumentBasis = FillingData.Basis;
	SourceWarehouse = FillingData.Warehouse;
	
	Goods.Load(BaseGoods);
	SetOfSeries.Load(BaseSeries);
	
EndProcedure

Procedure InstructionsForPurchasingGoods(FillingData)
	
	QueryText =
	"SELECT
	|	DocumentInflow.Ref        AS Ref,
	|	DocumentInflow.Organization   AS Organization,
	|	DocumentInflow.SalesOpportunity        AS SalesOpportunity,
	|	DocumentInflow.Warehouse         AS SourceWarehouse,
	|	DocumentInflow.Department AS Department,
	|	DocumentInflow.LineOfBusiness AS LineOfBusiness,
	|	NOT DocumentInflow.Posted   AS ThereAreErrorsPosted
	|FROM
	|	Document.VendorInvoice AS DocumentInflow
	|WHERE
	|	DocumentInflow.Ref = &DocumentBasis
	|
	|////////////////////////////////////////////////
	|;
	|SELECT
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Purpose          AS Purpose,
	|	Goods.Warehouse               AS Warehouse,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count          AS Count,
	|	Goods.NumberOfPackages  AS NumberOfPackages,
	|	Goods.Package            AS Package,
	|	Goods.Purpose          AS AssignmentSender
	|FROM
	|	Document.VendorInvoice.Goods AS Goods
	|WHERE
	|	Goods.Ref = &DocumentBasis
	|	AND Goods.Products.ItemsType IN(
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND Goods.Warehouse = &Warehouse
	|	AND NOT Goods.ToExpenseAs
	|;
	|
	|////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products   AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose     AS Purpose,
	|	SetOfSeries.Warehouse          AS Warehouse,
	|	SetOfSeries.Series          AS Series,
	|	SetOfSeries.Count     AS Count
	|FROM
	|	Document.VendorInvoice.SetOfSeries AS SetOfSeries
	|WHERE
	|	SetOfSeries.Ref = &DocumentBasis
	|	AND SetOfSeries.Warehouse = &Warehouse";
	
	Query       = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("DocumentBasis", FillingData.Basis);
	Query.SetParameter("Warehouse",             FillingData.Warehouse);
	
	ResultsPackage = Query.ExecuteBatch();
	BaseGoods  = ResultsPackage[1].Unload();
	
	If BaseGoods.Count() = 0 Then
		ErrorText = NStr("vi = 'Chứng từ %Document% không có hàng hóa. Cấm nhập trên cơ sở chứng từ này.';
						|ru = 'Документ %Document% не содержит товаров. Ввод на основании документа запрещен.';
						|en = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.'; fa = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.';
						|it = 'Il documento %Document% non contiene merci. L''immissione in base al documento non è consentita.';
						|pl = 'Dokument %Document% nie zawiera towarów. Wprowadzenie na podstawie dokumentu jest zakazane.';
						|tr = '%Document% belgesi hiçbir ürün içermemektedir. Belgeye dayalı giriş yapılmasına izin verilmez.'");
		ErrorText = StrReplace(ErrorText, "%Document%", FillingData.Basis);
		
		Raise ErrorText;
	EndIf;
	
	Header = ResultsPackage[0].Select();
	Header.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(Header.Ref, Undefined, Header.ThereAreErrorsPosted);
	
	// Filling in the header.
	FillPropertyValues(ThisObject, Header);
	DocumentBasis = FillingData.Basis;
	SourceWarehouse  = FillingData.Warehouse;
	
	// Splitting lines, filling in series with status 10.
	RowIndexes = New Array();
	
	For Each LineProducts_ In BaseGoods Do
		If LineProducts_.BatchesIndicationStatus = 10 Then
			RowIndexes.Insert(0, BaseGoods.IndexOf(LineProducts_));
		EndIf;
	EndDo;
	
	BaseSeries = ResultsPackage[2].Unload();
	
	If RowIndexes.Count() > 0 Then
		SeriesKey = "Products, Characteristic, Warehouse, Purpose";
		InvoicesServer.MoveSeriesFromTableToRows(BaseGoods, RowIndexes, BaseSeries, SeriesKey);
	EndIf;
	
	Goods.Load(BaseGoods);
	
	For Each RowSeries In BaseSeries Do
		If RowSeries.Count > 0 Then
			NewRow = SetOfSeries.Add();
			FillPropertyValues(NewRow, RowSeries);
			NewRow.AssignmentSender = NewRow.Purpose;
		EndIf;
	EndDo;
	
EndProcedure

Procedure InstructionsForAcceptanceOfGoodsForStorage(FillingData)
	
	QueryText =
	"SELECT
	|	DocumentInflow.Ref        AS Ref,
	|	DocumentInflow.Organization   AS Organization,
	|	DocumentInflow.SalesOpportunity        AS SalesOpportunity,
	|	DocumentInflow.Warehouse         AS SourceWarehouse,
	|	DocumentInflow.Department AS Department,
	|	DocumentInflow.LineOfBusiness AS LineOfBusiness,
	|	NOT DocumentInflow.Posted   AS ThereAreErrorsPosted
	|FROM
	|	Document.GoodsReceiptForStorage AS DocumentInflow
	|WHERE
	|	DocumentInflow.Ref = &DocumentBasis
	|
	|////////////////////////////////////////////////
	|;
	|SELECT
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Purpose          AS Purpose,
	|	Goods.Warehouse               AS Warehouse,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count          AS Count,
	|	Goods.NumberOfPackages  AS NumberOfPackages,
	|	Goods.Package            AS Package,
	|	Goods.Purpose          AS AssignmentSender
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS Goods
	|WHERE
	|	Goods.Ref = &DocumentBasis
	|	AND Goods.Products.ItemsType IN(
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND Goods.Warehouse = &Warehouse
	|;
	|
	|////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products   AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose     AS Purpose,
	|	SetOfSeries.Warehouse          AS Warehouse,
	|	SetOfSeries.Series          AS Series,
	|	SetOfSeries.Count     AS Count
	|FROM
	|	Document.GoodsReceiptForStorage.SetOfSeries AS SetOfSeries
	|WHERE
	|	SetOfSeries.Ref = &DocumentBasis
	|	AND SetOfSeries.Warehouse = &Warehouse";
	
	Query       = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("DocumentBasis", FillingData.Basis);
	Query.SetParameter("Warehouse",             FillingData.Warehouse);
	
	ResultsPackage = Query.ExecuteBatch();
	BaseGoods  = ResultsPackage[1].Unload();
	
	If BaseGoods.Count() = 0 Then
		ErrorText = NStr("vi = 'Chứng từ %Document% không có hàng hóa. Cấm nhập trên cơ sở chứng từ này.';
						|ru = 'Документ %Document% не содержит товаров. Ввод на основании документа запрещен.';
						|en = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.'; fa = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.';
						|it = 'Il documento %Document% non contiene merci. L''immissione in base al documento non è consentita.';
						|pl = 'Dokument %Document% nie zawiera towarów. Wprowadzenie na podstawie dokumentu jest zakazane.';
						|tr = '%Document% belgesi hiçbir ürün içermemektedir. Belgeye dayalı giriş yapılmasına izin verilmez.'");
		ErrorText = StrReplace(ErrorText, "%Document%", FillingData.Basis);
		
		Raise ErrorText;
	EndIf;
	
	Header = ResultsPackage[0].Select();
	Header.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(Header.Ref, Undefined, Header.ThereAreErrorsPosted);
	
	// Filling in the header.
	FillPropertyValues(ThisObject, Header);
	DocumentBasis = FillingData.Basis;
	SourceWarehouse  = FillingData.Warehouse;
	
	// Splitting lines, filling in series with status 10.
	RowIndexes = New Array();
	
	For Each LineProducts_ In BaseGoods Do
		If LineProducts_.BatchesIndicationStatus = 10 Then
			RowIndexes.Insert(0, BaseGoods.IndexOf(LineProducts_));
		EndIf;
	EndDo;
	
	BaseSeries = ResultsPackage[2].Unload();
	
	If RowIndexes.Count() > 0 Then
		SeriesKey = "Products, Characteristic, Warehouse, Purpose";
		InvoicesServer.MoveSeriesFromTableToRows(BaseGoods, RowIndexes, BaseSeries, SeriesKey);
	EndIf;
	
	Goods.Load(BaseGoods);
	
	For Each RowSeries In BaseSeries Do
		If RowSeries.Count > 0 Then
			NewRow = SetOfSeries.Add();
			FillPropertyValues(NewRow, RowSeries);
			NewRow.AssignmentSender = NewRow.Purpose;
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInDocumentOnBasisOfActOfDiscrepanciesAfterMoving(Val FillingData)
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT
	|	InventoryTransfer.Ref,
	|	NOT InventoryTransfer.Posted AS ThereAreErrorsPosted,
	|	InventoryTransfer.CompanyBankAccount,
	|	InventoryTransfer.PriceKind,
	|	InventoryTransfer.Department,
	|	InventoryTransfer.SalesOpportunity,
	|	CASE
	|		WHEN NOT &ThisIsOvershooting THEN
	|			InventoryTransfer.Organization
	|		ELSE
	|			InventoryTransfer.CompanyRecipient
	|	END AS Organization,
	|	CASE
	|		WHEN NOT &ThisIsOvershooting THEN
	|			InventoryTransfer.CompanyRecipient
	|		ELSE
	|			InventoryTransfer.Organization
	|	END AS CompanyRecipient,
	|	CASE
	|		WHEN NOT &ThisIsOvershooting THEN
	|			InventoryTransfer.SourceWarehouse
	|		ELSE
	|			InventoryTransfer.DestinationWarehouse
	|	END AS SourceWarehouse,
	|	CASE
	|		WHEN NOT &ThisIsOvershooting THEN
	|			InventoryTransfer.DestinationWarehouse
	|		ELSE
	|			InventoryTransfer.SourceWarehouse
	|	END AS DestinationWarehouse,
	|	InventoryTransfer.LineOfBusiness,
	|	InventoryTransfer.LockedGoodsTransfer,
	|	InventoryTransfer.ControlledLotOfTheSender,
	|	InventoryTransfer.BusinessOperation,
	|	InventoryTransfer.DataVersion,
	|	InventoryTransfer.DeletionMark,
	|	InventoryTransfer.TransferOrder,
	|	InventoryTransfer.Comment,
	|	InventoryTransfer.EmployeeResponsible,
	|	InventoryTransfer.Status,
	|	InventoryTransfer.DeliveryMethod,
	|	InventoryTransfer.DeliveryZone,
	|	InventoryTransfer.CarrierPartner,
	|	InventoryTransfer.DeliveryAddress,
	|	InventoryTransfer.DeliveryAddressFieldValues,
	|	InventoryTransfer.DeliveryAddressOfCarrier,
	|	InventoryTransfer.DeliveryAddressOfCarrierFieldValues,
	|	InventoryTransfer.AdditionalDeliveryInformation,
	|	InventoryTransfer.DeliveryTimeFrom,
	|	InventoryTransfer.DeliveryTimeTo,
	|	InventoryTransfer.DocumentBasis,
	|	InventoryTransfer.Director,
	|	InventoryTransfer.ChiefAccountant,
	|	InventoryTransfer.InventoryOwnerAttributesAreSpecifiedManually,
	|	InventoryTransfer.TransferForActivity,
	|	InventoryTransfer.ReusablePackageFillingStatus,
	|	InventoryTransfer.TransferOfNonConformanceCertificate,
	|	InventoryTransfer.SpecialTransportationConditions,
	|	InventoryTransfer.SpecialTransportationConditionsDescription,
	|	InventoryTransfer.GoodsReceiptOption
	|FROM
	|	Document.InventoryTransfer AS InventoryTransfer
	|WHERE
	|	InventoryTransfer.Ref = &DocumentBasis
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyReportFollowingTransferGoods.Products AS Products,
	|	DiscrepancyReportFollowingTransferGoods.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingTransferGoods.OrderDocument AS TransferOrder,
	|	CASE
	|		WHEN DiscrepancyReportFollowingTransferGoods.CountByDocument = 0
	|			THEN 0
	|		ELSE DiscrepancyReportFollowingTransferGoods.RowCode
	|	END AS RowCode,
	|	DiscrepancyReportFollowingTransferGoods.Purpose AS Purpose,
	|	DiscrepancyReportFollowingTransferGoods.AssignmentSender AS AssignmentSender,
	|	DiscrepancyReportFollowingTransferGoods.Series AS Series,
	|	DiscrepancyReportFollowingTransferGoods.Package AS Package,
	|	SUM(DiscrepancyReportFollowingTransferGoods.Count) AS Count,
	|	SUM(DiscrepancyReportFollowingTransferGoods.NumberOfPackages) AS NumberOfPackages
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS DiscrepancyReportFollowingTransferGoods
	|WHERE
	|	DiscrepancyReportFollowingTransferGoods.Ref = &DiscrepancyCertificate
	|	AND &Patch
	|	AND DiscrepancyReportFollowingTransferGoods.Action IN
	|		(VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered))
	|	AND DiscrepancyReportFollowingTransferGoods.NumberOfPackages > 0
	|GROUP BY
	|	DiscrepancyReportFollowingTransferGoods.Products,
	|	DiscrepancyReportFollowingTransferGoods.Characteristic,
	|	DiscrepancyReportFollowingTransferGoods.OrderDocument,
	|	CASE
	|		WHEN DiscrepancyReportFollowingTransferGoods.CountByDocument = 0
	|			THEN 0
	|		ELSE DiscrepancyReportFollowingTransferGoods.RowCode
	|	END,
	|	DiscrepancyReportFollowingTransferGoods.Purpose,
	|	DiscrepancyReportFollowingTransferGoods.AssignmentSender,
	|	DiscrepancyReportFollowingTransferGoods.Series,
	|	DiscrepancyReportFollowingTransferGoods.Package
	|
	|UNION ALL
	|
	|SELECT
	|	DiscrepancyReportFollowingTransferGoods.Products AS Products,
	|	DiscrepancyReportFollowingTransferGoods.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingTransferGoods.OrderDocument AS TransferOrder,
	|	DiscrepancyReportFollowingTransferGoods.RowCode AS RowCode,
	|	DiscrepancyReportFollowingTransferGoods.Purpose AS Purpose,
	|	DiscrepancyReportFollowingTransferGoods.AssignmentSender AS AssignmentSender,
	|	DiscrepancyReportFollowingTransferGoods.Series AS Series,
	|	DiscrepancyReportFollowingTransferGoods.Package AS Package,
	|	SUM(DiscrepancyReportFollowingTransferGoods.CountByDocument) AS Count,
	|	SUM(DiscrepancyReportFollowingTransferGoods.NumberOfPackagesByDocument) AS NumberOfPackages
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS DiscrepancyReportFollowingTransferGoods
	|WHERE
	|	DiscrepancyReportFollowingTransferGoods.Ref = &DiscrepancyCertificate
	|	AND &Patch
	|	AND DiscrepancyReportFollowingTransferGoods.Action NOT IN
	|		(VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered))
	|	AND DiscrepancyReportFollowingTransferGoods.NumberOfPackagesByDocument > 0
	|GROUP BY
	|	DiscrepancyReportFollowingTransferGoods.Products,
	|	DiscrepancyReportFollowingTransferGoods.Characteristic,
	|	DiscrepancyReportFollowingTransferGoods.OrderDocument,
	|	DiscrepancyReportFollowingTransferGoods.RowCode,
	|	DiscrepancyReportFollowingTransferGoods.Purpose,
	|	DiscrepancyReportFollowingTransferGoods.AssignmentSender,
	|	DiscrepancyReportFollowingTransferGoods.Series,
	|	DiscrepancyReportFollowingTransferGoods.Package
	|
	|UNION ALL
	|
	|SELECT
	|	DiscrepancyReportFollowingTransferGoods.Products AS Products,
	|	DiscrepancyReportFollowingTransferGoods.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingTransferGoods.OrderDocument AS TransferOrder,
	|	DiscrepancyReportFollowingTransferGoods.RowCode AS RowCode,
	|	DiscrepancyReportFollowingTransferGoods.Purpose AS Purpose,
	|	DiscrepancyReportFollowingTransferGoods.AssignmentSender AS AssignmentSender,
	|	DiscrepancyReportFollowingTransferGoods.Series AS Series,
	|	DiscrepancyReportFollowingTransferGoods.Package AS Package,
	|	SUM(DiscrepancyReportFollowingTransferGoods.CountByDocument -
	|		DiscrepancyReportFollowingTransferGoods.Count) AS Count,
	|	SUM(DiscrepancyReportFollowingTransferGoods.NumberOfPackagesByDocument -
	|		DiscrepancyReportFollowingTransferGoods.NumberOfPackages) AS NumberOfPackages
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS DiscrepancyReportFollowingTransferGoods
	|WHERE
	|	DiscrepancyReportFollowingTransferGoods.Ref = &DiscrepancyCertificate
	|	AND
	|	NOT &ThisIsOvershooting
	|	AND
	|	NOT &Patch
	|	AND
	|		DiscrepancyReportFollowingTransferGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|	AND DiscrepancyReportFollowingTransferGoods.NumberOfPackagesByDocument -
	|		DiscrepancyReportFollowingTransferGoods.NumberOfPackages > 0
	|GROUP BY
	|	DiscrepancyReportFollowingTransferGoods.Products,
	|	DiscrepancyReportFollowingTransferGoods.Characteristic,
	|	DiscrepancyReportFollowingTransferGoods.OrderDocument,
	|	DiscrepancyReportFollowingTransferGoods.RowCode,
	|	DiscrepancyReportFollowingTransferGoods.Purpose,
	|	DiscrepancyReportFollowingTransferGoods.AssignmentSender,
	|	DiscrepancyReportFollowingTransferGoods.Series,
	|	DiscrepancyReportFollowingTransferGoods.Package
	|
	|UNION ALL
	|
	|SELECT
	|	DiscrepancyReportFollowingTransferGoods.Products,
	|	DiscrepancyReportFollowingTransferGoods.Characteristic,
	|	UNDEFINED AS TransferOrder,
	|	0 AS RowCode,
	|	DiscrepancyReportFollowingTransferGoods.AssignmentSender,
	|	DiscrepancyReportFollowingTransferGoods.Purpose,
	|	DiscrepancyReportFollowingTransferGoods.Series,
	|	DiscrepancyReportFollowingTransferGoods.Package,
	|	SUM(DiscrepancyReportFollowingTransferGoods.Count -
	|		DiscrepancyReportFollowingTransferGoods.CountByDocument),
	|	SUM(DiscrepancyReportFollowingTransferGoods.NumberOfPackages -
	|		DiscrepancyReportFollowingTransferGoods.NumberOfPackagesByDocument)
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS DiscrepancyReportFollowingTransferGoods
	|WHERE
	|	DiscrepancyReportFollowingTransferGoods.Ref = &DiscrepancyCertificate
	|	AND &ThisIsOvershooting
	|	AND
	|	NOT &Patch
	|	AND
	|		DiscrepancyReportFollowingTransferGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered)
	|	AND DiscrepancyReportFollowingTransferGoods.NumberOfPackages -
	|		DiscrepancyReportFollowingTransferGoods.NumberOfPackagesByDocument > 0
	|GROUP BY
	|	DiscrepancyReportFollowingTransferGoods.Products,
	|	DiscrepancyReportFollowingTransferGoods.Characteristic,
	|	DiscrepancyReportFollowingTransferGoods.Purpose,
	|	DiscrepancyReportFollowingTransferGoods.AssignmentSender,
	|	DiscrepancyReportFollowingTransferGoods.Series,
	|	DiscrepancyReportFollowingTransferGoods.Package
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyReportFollowingTransferSetOfSeries.Products AS Products,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Series AS Series,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Purpose AS Purpose,
	|	DiscrepancyReportFollowingTransferSetOfSeries.AssignmentSender AS AssignmentSender,
	|	SUM(DiscrepancyReportFollowingTransferSetOfSeries.Count) AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.SetOfSeries AS DiscrepancyReportFollowingTransferSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingTransferSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND &Patch
	|	AND DiscrepancyReportFollowingTransferSetOfSeries.Action IN
	|		(VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered))
	|	AND DiscrepancyReportFollowingTransferSetOfSeries.Count > 0
	|GROUP BY
	|	DiscrepancyReportFollowingTransferSetOfSeries.Products,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Series,
	|	DiscrepancyReportFollowingTransferSetOfSeries.AssignmentSender,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	DiscrepancyReportFollowingTransferSetOfSeries.Products AS Products,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Series AS Series,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Purpose AS Purpose,
	|	DiscrepancyReportFollowingTransferSetOfSeries.AssignmentSender AS AssignmentSender,
	|	SUM(DiscrepancyReportFollowingTransferSetOfSeries.CountByDocument) AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.SetOfSeries AS DiscrepancyReportFollowingTransferSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingTransferSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND &Patch
	|	AND DiscrepancyReportFollowingTransferSetOfSeries.Action NOT IN
	|		(VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered))
	|	AND DiscrepancyReportFollowingTransferSetOfSeries.CountByDocument > 0
	|GROUP BY
	|	DiscrepancyReportFollowingTransferSetOfSeries.Products,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Series,
	|	DiscrepancyReportFollowingTransferSetOfSeries.AssignmentSender,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	DiscrepancyReportFollowingTransferSetOfSeries.Products AS Products,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Series AS Series,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Purpose AS Purpose,
	|	DiscrepancyReportFollowingTransferSetOfSeries.AssignmentSender AS AssignmentSender,
	|	SUM(DiscrepancyReportFollowingTransferSetOfSeries.CountByDocument -
	|		DiscrepancyReportFollowingTransferSetOfSeries.Count) AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.SetOfSeries AS DiscrepancyReportFollowingTransferSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingTransferSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND
	|	NOT &ThisIsOvershooting
	|	AND
	|	NOT &Patch
	|	AND
	|		DiscrepancyReportFollowingTransferSetOfSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|	AND DiscrepancyReportFollowingTransferSetOfSeries.CountByDocument - DiscrepancyReportFollowingTransferSetOfSeries.Count > 0
	|GROUP BY
	|	DiscrepancyReportFollowingTransferSetOfSeries.Products,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Series,
	|	DiscrepancyReportFollowingTransferSetOfSeries.AssignmentSender,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	DiscrepancyReportFollowingTransferSetOfSeries.Products,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Series,
	|	DiscrepancyReportFollowingTransferSetOfSeries.AssignmentSender,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Purpose,
	|	SUM(DiscrepancyReportFollowingTransferSetOfSeries.Count - DiscrepancyReportFollowingTransferSetOfSeries.CountByDocument)
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.SetOfSeries AS DiscrepancyReportFollowingTransferSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingTransferSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND &ThisIsOvershooting
	|	AND
	|	NOT &Patch
	|	AND
	|		DiscrepancyReportFollowingTransferSetOfSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered)
	|	AND DiscrepancyReportFollowingTransferSetOfSeries.Count - DiscrepancyReportFollowingTransferSetOfSeries.CountByDocument > 0
	|GROUP BY
	|	DiscrepancyReportFollowingTransferSetOfSeries.Products,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Series,
	|	DiscrepancyReportFollowingTransferSetOfSeries.AssignmentSender,
	|	DiscrepancyReportFollowingTransferSetOfSeries.Purpose
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DiscrepancyReportFollowingTransferGoods.OrderDocument AS TransferOrder
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS DiscrepancyReportFollowingTransferGoods
	|WHERE
	|	DiscrepancyReportFollowingTransferGoods.Ref = &DiscrepancyCertificate
	|	AND
	|	NOT &ThisIsOvershooting
	|	AND
	|		DiscrepancyReportFollowingTransferGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|	AND DiscrepancyReportFollowingTransferGoods.NumberOfPackagesByDocument -
	|		DiscrepancyReportFollowingTransferGoods.NumberOfPackages > 0
	|	AND DiscrepancyReportFollowingTransferGoods.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DiscrepancyReportFollowingTransferGoods.OrderDocument AS TransferOrder
	|FROM
	|	Document.DiscrepancyReportFollowingTransfer.Goods AS DiscrepancyReportFollowingTransferGoods
	|WHERE
	|	DiscrepancyReportFollowingTransferGoods.Ref = &DiscrepancyCertificate
	|	AND NOT &ThisIsOvershooting
	|	AND &Patch
	|	AND DiscrepancyReportFollowingTransferGoods.NumberOfPackages > 0
	|	AND DiscrepancyReportFollowingTransferGoods.OrderDocument <> VALUE(Document.TransferOrder.EmptyRef)");
	
	Query.SetParameter("DocumentBasis",  FillingData.InventoryTransfer);
	Query.SetParameter("DiscrepancyCertificate",   FillingData.DiscrepancyCertificate);
	Query.SetParameter("ThisIsOvershooting", FillingData.ThisIsOvershooting);
	Query.SetParameter("Patch",        FillingData.Patch);
	
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection = QueryBatch[0].Select();
	
	HeaderSelection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.Ref,
		,
		HeaderSelection.ThereAreErrorsPosted,
		,
		);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	TransferOfNonConformanceCertificate = FillingData.InventoryTransfer;
	
	If FillingData.Patch Then
		
		Patch = True;
		
		// The original document.
		CorrectedDocument = FillingData.InventoryTransfer;
		
		// The current document being corrected (the original one, or the last of the adjustments).
		ReversedDocument = FillingData.CorrectedDocument;
		
	EndIf;
	
	Goods.Load(QueryBatch[1].Unload());
	SetOfSeries.Load(QueryBatch[2].Unload());
	SampleOrders = QueryBatch[3].Select();
	
	ItemsInSelectionOrders = SampleOrders.Count();
	If ItemsInSelectionOrders > 0 Then
		TransferAgainstOrders = True;
		If ItemsInSelectionOrders = 1 Then
			SampleOrders.Next();
			TransferOrder = SampleOrders.TransferOrder;
		EndIf;
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	If Not LockedGoodsTransfer Then
		ControlledLotOfTheSender = Catalogs.ControlledLots.EmptyRef();
	EndIf;
	
	PriceKind = Catalogs.Warehouses.AccountingPriceType(SourceWarehouse);
	Status = Metadata().Attributes.Status.FillValue;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization = Organization;
	FillParameters.Date = Date;
	FillParameters.Warehouse = DestinationWarehouse;
	FillParameters.MovementOfGoodsInWarehouses = True;
	If BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices Then
		FillParameters.MovementBetweenBranches = True;
	EndIf;
	VATAccountingERP.FillInTypeOfActivityVAT(TransferForActivity, FillParameters);
	
	If Not GetFunctionalOption("UseGoodsTransferStatuses") 
		Or Patch Then
		Status = Enums.GoodsTransferStatuses.Accepted;
	EndIf;
	
	ReferenceOrder = DocumentBaseWhenFillingIn(FillingData);
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(ReferenceOrder);
	
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	// Filling in the series indication statuses
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryTransfer);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

Procedure InformationOnReceiptOfGoods(DocumentInflow)
	
	QueryText =
	"SELECT
	|	Header.Ref AS Ref,
	|	Header.Organization AS Organization,
	|	Header.SalesOpportunity AS SalesOpportunity,
	|	Header.Warehouse AS SourceWarehouse,
	|	Header.Department AS Department,
	|	Header.LineOfBusiness AS LineOfBusiness,
	|	NOT Header.Posted AS ThereAreErrorsPosted
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse AS Header
	|WHERE
	|	Header.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count AS Count,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Package AS Package,
	|	Goods.Purpose AS AssignmentSender
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.Goods AS Goods
	|WHERE
	|	Goods.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products AS Products,
	|	SetOfSeries.Characteristic AS Characteristic,
	|	SetOfSeries.Purpose AS Purpose,
	|	SetOfSeries.Series AS Series,
	|	SetOfSeries.Count AS Count
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.SetOfSeries AS SetOfSeries
	|WHERE
	|	SetOfSeries.Ref = &DocumentBasis";
	
	Query = New Query(QueryText);
	Query.SetParameter("DocumentBasis", DocumentInflow);
	ResultsPackage = Query.ExecuteBatch();
	
	BaseGoods = ResultsPackage[1].Unload();
	If BaseGoods.Count() = 0 Then

		ErrorText = NStr("vi = 'Chứng từ %Document% không có hàng hóa. Cấm nhập trên cơ sở chứng từ này.';
						|ru = 'Документ %Document% не содержит товаров. Ввод на основании документа запрещен.';
						|en = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.'; fa = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.';
						|it = 'Il documento %Document% non contiene merci. L''immissione in base al documento non è consentita.';
						|pl = 'Dokument %Document% nie zawiera towarów. Wprowadzenie na podstawie dokumentu jest zakazane.';
						|tr = '%Document% belgesi hiçbir ürün içermemektedir. Belgeye dayalı giriş yapılmasına izin verilmez.'");
		ErrorText = StrReplace(ErrorText, "%Document%", DocumentInflow);
	
		Raise ErrorText;
		
	EndIf;
	
	HeaderAttributes = ResultsPackage[0].Select();
	HeaderAttributes.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderAttributes.Ref,
		,
		HeaderAttributes.ThereAreErrorsPosted,);
		
	// Filling in the header.
	FillPropertyValues(ThisObject, HeaderAttributes);
	DocumentBasis = DocumentInflow;
	SourceWarehouse  = Common.ObjectAttributeValue(DocumentInflow, "Warehouse");
	
	// Splitting lines, filling in series with status 10.
	RowIndexes = New Array();
	For Each LineProducts_ In BaseGoods Do
		
		If LineProducts_.BatchesIndicationStatus = 10 Then
			RowIndexes.Insert(0, BaseGoods.IndexOf(LineProducts_));
		EndIf;
		
	EndDo;
	
	BaseSeries = ResultsPackage[2].Unload();
	
	If RowIndexes.Count() > 0 Then
		
		SeriesKey = "Products, Characteristic, Warehouse, Purpose";
		InvoicesServer.MoveSeriesFromTableToRows(BaseGoods, RowIndexes, BaseSeries, SeriesKey);
		
	EndIf;
	
	Goods.Load(BaseGoods);
	
	For Each RowSeries In BaseSeries Do
		If RowSeries.Count > 0 Then
			NewRow = SetOfSeries.Add();
			FillPropertyValues(NewRow, RowSeries);
			NewRow.AssignmentSender = NewRow.Purpose;
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInDocumentBasedOnSupplyRequest(ApplicationForCollateral)
	
	ReceivingParameters = Documents.ApplicationForCollateral.ParametersForReceivingFillInDataBasedOn();
	ReceivingParameters.ItemsType = ProductsServer.SupportedDocumentItemTypes(Ref);
	FillingData = Documents.ApplicationForCollateral.FillingDataBasedOn(
		ApplicationForCollateral,
		ReceivingParameters);
	
	// Safe filling of the header:
	HeaderProperties = New Structure;
	HeaderProperties.Insert("Organization");
	HeaderProperties.Insert("Department");
	HeaderProperties.Insert("Warehouse");
	HeaderProperties.Insert("LineOfBusiness");
	FillPropertyValues(HeaderProperties, FillingData.Header);
	FillPropertyValues(ThisObject, HeaderProperties);
	
	DocumentBasis = ApplicationForCollateral;
	DestinationWarehouse = HeaderProperties.Warehouse;
	
	// Filling PM:
	Goods.Load(FillingData.Goods);
	
EndProcedure

Function DocumentBaseWhenFillingIn(FillingData)
	
	Basis = Undefined;
	
	If TypeOf(FillingData) <> Type("Structure") Then
		Return Basis;
	EndIf;
	
	If FillingData.Property("AnArrayOfOrders") Then
		
		Basis = FillingData.AnArrayOfOrders[0];
		
	ElsIf FillingData.Property("Goods")
		And TypeOf(FillingData.Goods) = Type("ValueTable") And FillingData.Goods.Columns.Find("TransferOrder") <> Undefined Then
		
		Basis = FillingData.Goods[0].TransferOrder;
		
	EndIf;
	
	Return Basis;
	
EndFunction

#EndRegion

#Region InventoryKinds

// This function generates temporary document data.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Date															AS Date,
	|	&Organization													AS Organization,
	|	&CompanyRecipient											AS CompanyRecipient,
	|	&Warehouse															AS SourceWarehouse,
	|	&DestinationWarehouse												AS DestinationWarehouse,
	|	&Warehouse															AS Warehouse,
	|	&Status															AS Status,
	|	UNDEFINED													AS Partner,
	|	UNDEFINED													AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)		AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)			AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef)						AS Currency,
	|	&TransferForActivity										AS VATTaxation,
	|	&TransferForActivity										AS TransferForActivity,
	|	&BusinessOperation											AS BusinessOperation,
	|	TRUE															AS ThereAreTransactionsInTablePart,
	|	CASE
	|		WHEN &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|				AND NOT &EnabledGoodsAssignmentInSalesOpportunity
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END															AS Department,
	|	CASE
	|		WHEN &OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|				AND NOT &EnabledGoodsAssignmentInSalesOpportunity
	|			THEN &Manager
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END															AS Manager,
	|	CASE
	|		WHEN &EnabledGoodsAssignmentInSalesOpportunity
	|				AND &GenerateInventoryOwnerAttributesBySalesOpportunities
	|			THEN &SalesOpportunity
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END															AS SalesOpportunity,
	|	VALUE(Enum.InventoryTypes.OwnGoods)						AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatusSender AS BatchesIndicationStatus,
	|	TableOfGoods.BatchesIndicationStatusRecipient AS BatchesIndicationStatusRecipient,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END										AS QuantityByGBRN,
	|	&Warehouse										AS Warehouse,
	|	TableOfGoods.SalesOpportunity						AS SalesOpportunity,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.AssignmentSender		AS AssignmentSender,
	|	TableOfGoods.TransferOrder			AS TransferOrder,
	|	TableOfGoods.RowCode					AS RowCode,
	|	&FieldTextTableOfGoodsCCDNumber_			AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	CASE WHEN GoodsFromOrder.WithAssignment
	|		AND GoodsFromOrder.Purpose = VALUE(Catalog.Assignments.EmptyRef) THEN
	|		OrderDocument.Purpose
	|	WHEN GoodsFromOrder.WithAssignment THEN
	|		TableOfGoods.Purpose
	|	ELSE
	|		VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose
	|INTO TTProductsToOrder
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Document.TransferOrder AS OrderDocument
	|		ON TableOfGoods.TransferOrder = OrderDocument.Ref
	|		
	|		INNER JOIN Document.TransferOrder.Goods AS GoodsFromOrder
	|		ON TableOfGoods.TransferOrder	= GoodsFromOrder.Ref
	|			AND TableOfGoods.RowCode			= GoodsFromOrder.RowCode
	|			AND TableOfGoods.Products		= GoodsFromOrder.Products
	|			AND TableOfGoods.Characteristic		= GoodsFromOrder.Characteristic
	|
	|WHERE
	|	TableOfGoods.TransferOrder <> VALUE(Document.TransferOrder.EmptyRef)
	|
	|INDEX BY
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber						AS LineNumber,
	|	TableOfGoods.Products						AS Products,
	|	TableOfGoods.Characteristic					AS Characteristic,
	|	TableOfGoods.Series							AS Series,
	|	TableOfGoods.BatchesIndicationStatus				AS BatchesIndicationStatus,
	|	TableOfGoods.BatchesIndicationStatusRecipient	AS BatchesIndicationStatusRecipient,
	|	TableOfGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableOfGoods.Count						AS Count,
	|	TableOfGoods.QuantityByGBRN					AS QuantityByGBRN,
	|	&Warehouse											AS Warehouse,
	|	VALUE(Catalog.VATRates.EmptyRef)		AS VATRate,
	|	0												AS AmountIncludingVAT,
	|	0												AS VATAmount,
	|	0												AS CommissionAmount,
	|	0												AS AmountVATRemuneration,
	|	CASE
	|		WHEN TableOfGoods.SalesOpportunity <> VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|			THEN TableOfGoods.SalesOpportunity
	|		ELSE &SalesOpportunity
	|	END											AS SalesOpportunity,
	|	ISNULL(ProductsUnderOrder.Purpose, TableOfGoods.Purpose) AS Purpose,
	|	TableOfGoods.Purpose						AS DestinationRecipient,
	|	TRUE											AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber							AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN 	TTProductsToOrder AS ProductsUnderOrder
	|		ON TableOfGoods.LineNumber = ProductsUnderOrder.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute			AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END											AS QuantityByGBRN,
	|	VALUE(Catalog.Warehouses.EmptyRef)		AS OriginWarehouse,
	|	&Warehouse											AS Warehouse,
	|	TableTypesOfStocks_.SalesOpportunity						AS SalesOpportunity,
	|	TableTypesOfStocks_.Series						AS Series,
	|	&InventoryOwnerAttributesAreSpecifiedManually						AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic						AS Characteristic,
	|	Dimension.Series									AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute			AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	TableTypesOfStocks_.OriginWarehouse				AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse						AS Warehouse,
	|	TableTypesOfStocks_.SalesOpportunity						AS SalesOpportunity,
	|	TableTypesOfStocks_.Series						AS RecipientSeries,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually	AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	SeparateAccountingForTransaction = Common.ObjectAttributeValue(SalesOpportunity, "EnabledGoodsAssignmentInSalesOpportunity");
	SeparateAccountingForTransaction = ?(ValueIsFilled(SeparateAccountingForTransaction), SeparateAccountingForTransaction, False);
	OptionOfAssignedAccountingOfGoods = Common.ObjectAttributeValue(Department, "OptionOfAssignedAccountingOfGoods");
	
	Query.SetParameter("EnabledGoodsAssignmentInSalesOpportunity",					SeparateAccountingForTransaction);
	Query.SetParameter("Ref",												Ref);
	Query.SetParameter("Date",												Date);
	Query.SetParameter("Organization",										Organization);
	Query.SetParameter("CompanyRecipient",								CompanyRecipient);
	Query.SetParameter("DestinationWarehouse",									DestinationWarehouse);
	Query.SetParameter("Warehouse",												SourceWarehouse);
	Query.SetParameter("SalesOpportunity",												SalesOpportunity);
	Query.SetParameter("Manager",											EmployeeResponsible);
	Query.SetParameter("Department",										Department);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually",							InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("OptionOfAssignedAccountingOfGoods",					OptionOfAssignedAccountingOfGoods);
	Query.SetParameter("TransferForActivity",							TransferForActivity);
	Query.SetParameter("BusinessOperation",								BusinessOperation);
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers",	GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities",					GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.SetParameter("TableOfGoods",										TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",									InventoryKinds);
	Query.SetParameter("Status",												Status);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		TableOfGoods,
		Query.Text,
		"&FieldTextTableOfGoodsQuantityByGBRN_",
		"TableOfGoods",
		"QuantityByGBRN",
		"TableOfGoods.QuantityByGBRN",
		"0");
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		TableOfGoods,
		Query.Text,
		"&FieldTextTableOfGoodsCCDNumber_",
		"TableOfGoods",
		"CCDNumber",
		"TableOfGoods.CCDNumber",
		"VALUE(Catalog.CCDNumbers.EmptyRef)");
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus = 14
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfGoods.Warehouse,
	|
	|	DocumentDataTable.Department,
	|	DocumentDataTable.Manager,
	|	DocumentDataTable.SalesOpportunity,
	|	TableOfGoods.Purpose AS Purpose,
	|
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|
	|	TableOfGoods.Count AS Count
	|	
	|INTO TableOfProductsAndAnalytics
	|FROM
	|	TableOfGoods AS TableOfGoods
	|
	|	LEFT JOIN
	|		DocumentDataTable AS DocumentDataTable
	|	ON
	|		TRUE
	|;
	|");
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, CompanyRecipient, Date, DestinationWarehouse, SourceWarehouse, BusinessOperation, TransferForActivity, Status";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfGoods.SalesOpportunity AS SalesOpportunity,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	(SELECT
	|		TableOfGoods.SalesOpportunity AS SalesOpportunity,
	|		TableOfGoods.DestinationRecipient AS Purpose,
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		(CASE TableOfGoods.BatchesIndicationStatusRecipient
	|			WHEN 14
	|				THEN TableOfGoods.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef) END) AS Series,
	|		TableOfGoods.Count AS Count
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.SalesOpportunity AS SalesOpportunity,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.RecipientSeries AS Series,
	|		-TableTypesOfStocks_.Count AS Count
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.SalesOpportunity,
	|	TableOfGoods.Purpose,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Series
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0";
	
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure FillInAssignmentOfStockTypes()
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In Goods Do
		
		If Not ValueIsFilled(RowOfGoods.Purpose) Then
			Continue;
		EndIf;
		
		GoodsQuantity = RowOfGoods.Count;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.Purpose			= RowOfGoods.Purpose;
			NewRow.Count			= Count;
			NewRow.QuantityByGBRN	= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
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

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager		= TemporaryDocumentDataTables();
	RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
	
		FillParameters = ParametersForFillingInventoryTypes("Organization");
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, SalesOpportunity, InventoryOwnerAttribute, CCDNumber", "Count, QuantityByGBRN");
		ControlOfFillingOfExcisableInventoryOwnerAttributes(Cancel);
		If Not Cancel Then
			FillInAssignmentOfStockTypes();
			FillInRecipientSInventoryType();
			FillInAdditionalStockTypes();
		EndIf;
		
	ElsIf Not Cancel Then
		LineNotFilledIn = InventoryKinds.Find(Catalogs.InventoryKinds.EmptyRef(), "RecipientInventoryOwnerAttribute");
		
		If LineNotFilledIn <> Undefined Then
			FillInRecipientSInventoryType();
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInRecipientSInventoryType() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Inventories.LineNumber					AS LineNumber,
	|	Inventories.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Inventories.InventoryOwnerAttribute					AS InventoryOwnerAttribute
	|INTO Inventories
	|FROM
	|	&InventoryKinds AS Inventories
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inventories.LineNumber AS LineNumber,
	|	InventoryKinds.Ref AS InventoryOwnerAttribute,
	|	&CompanyRecipient AS InventoryRecipientOrganization,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	UNDEFINED AS GoodsOwner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Terms,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS PriceKind,
	|	&TransferForActivity AS VATTaxation,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	Keys.Products.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
	|	FALSE AS SubjectToExcise,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS BusinessUnitProduction,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier) AS BusinessTransactionStockType
	|FROM
	|	Inventories AS Inventories
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON InventoryKinds.Ref = Inventories.InventoryOwnerAttribute
	|		
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|		ON Keys.Ref = Inventories.ItemsLocationAttributes
	|WHERE
	|	&ThisIsInternalTransferOfGoods
	|
	|UNION ALL
	|
	|SELECT
	|	Inventories.LineNumber,
	|	InventoryKinds.Ref,
	|	&Organization,
	|	VALUE(Enum.InventoryTypes.OwnGoods),
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	UNDEFINED,
	|	CASE
	|		WHEN &TransferForActivity <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TransferForActivity
	|		ELSE InventoryKinds.VATTaxation
	|	END,
	|	&TaxationOfOrganization,
	|	InventoryKinds.FinancialAccountingGroup,
	|	InventoryKinds.ProductsGroup,
	|	InventoryKinds.SubjectToExcise,
	|	InventoryKinds.BusinessUnitProduction,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|FROM
	|	Inventories AS Inventories
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON (InventoryKinds.Ref = Inventories.InventoryOwnerAttribute)
	|WHERE
	|	NOT &ThisIsInternalTransferOfGoods
	|	AND InventoryKinds.VATTaxation <> &TransferForActivity
	|	AND &TransferForActivity <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|
	|UNION ALL
	|
	|SELECT
	|	Inventories.LineNumber,
	|	InventoryKinds.Ref,
	|	InventoryKinds.Organization,
	|	InventoryKinds.InventoryType,
	|	InventoryKinds.GoodsOwner,
	|	InventoryKinds.Counterparty,
	|	InventoryKinds.Contract,
	|	InventoryKinds.Terms,
	|	InventoryKinds.Currency,
	|	InventoryKinds.PriceKind,
	|	InventoryKinds.VATTaxation,
	|	&TaxationOfOrganization,
	|	InventoryKinds.FinancialAccountingGroup,
	|	InventoryKinds.ProductsGroup,
	|	FALSE AS SubjectToExcise,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS BusinessUnitProduction,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|FROM
	|	Inventories AS Inventories
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON (InventoryKinds.Ref = Inventories.InventoryOwnerAttribute)
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|		ON (Keys.Ref = Inventories.ItemsLocationAttributes)
	|WHERE
	|	InventoryKinds.SaleOfAnotherCompanyInventory
	|	AND NOT &ThisIsInternalTransferOfGoods
	|	AND (InventoryKinds.VATTaxation = &TransferForActivity
	|			OR &TransferForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			OR InventoryKinds.InventoryType <> VALUE(Enum.InventoryTypes.OwnGoods))
	|
	|ORDER BY
	|	LineNumber";
	
	ThisIsInternalTransferOfGoods = BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsBetweenBranchOffices;
	ParameterOrganization = ?(ThisIsInternalTransferOfGoods, CompanyRecipient, Organization);	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(ParameterOrganization, Date);
	NamesOfColumnsToUpload = "LineNumber, ItemsLocationAttributes, InventoryOwnerAttribute";
	
	Query.SetParameter("Ref",						Ref);
	Query.SetParameter("Organization",				Organization);
	Query.SetParameter("CompanyRecipient",		CompanyRecipient);
	Query.SetParameter("TransferForActivity",	TransferForActivity);
	Query.SetParameter("InventoryKinds",				InventoryKinds.Unload(, NamesOfColumnsToUpload));
	Query.SetParameter("ThisIsInternalTransferOfGoods", ThisIsInternalTransferOfGoods);
	Query.SetParameter("TaxationOfOrganization",
								AccountingParametersForOrganization.BasicTaxationVATSales);
	
	TypesOfStocksOfRecipient = New Map;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		RecipientInventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(
								Selection.InventoryRecipientOrganization,
								Selection.BusinessTransactionStockType,
								Selection);
		TypesOfStocksOfRecipient.Insert(Selection.LineNumber, RecipientInventoryOwnerAttribute);
	EndDo;
	
	For Each Inventory In InventoryKinds Do
		RecipientInventoryOwnerAttribute = TypesOfStocksOfRecipient[Inventory.LineNumber];
		Inventory.RecipientInventoryOwnerAttribute = ?(RecipientInventoryOwnerAttribute = Undefined, Inventory.InventoryOwnerAttribute, RecipientInventoryOwnerAttribute);
	EndDo;
	
EndProcedure

Procedure FillInAdditionalStockTypes()
	
	GroupingColumns	= "ItemsLocationAttributes, BatchesIndicationStatusRecipient, Series";
	TotalingColumns	= "Count";
	
	GoodsTable = Goods.Unload(, GroupingColumns + ", " + TotalingColumns);
	GoodsTable.GroupBy(GroupingColumns, TotalingColumns);
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In GoodsTable Do
		Resources = New Structure;
		Resources.Insert("NumberOfProductsPerLine_", RowOfGoods.Count);
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Resources);
	EndDo;
	
	RowFilter = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(RowFilter);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure
Procedure ControlOfFillingOfExcisableInventoryOwnerAttributes(Cancel)
	
	If Cancel
		Or Not GetFunctionalOption("UseExcisableGoods") Then
		
		Return;
		
	EndIf;
	
	WarehouseStore = Common.ObjectAttributeValue(DestinationWarehouse, "WarehouseStore");
	
	If WarehouseStore <> Enums.TypesOfWarehouses.RetailStore Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|INDEX BY
	|	InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		INNER JOIN Catalog.InventoryKinds AS CatalogInventoryKinds
	|		ON TableTypesOfStocks_.InventoryOwnerAttribute = CatalogInventoryKinds.Ref
	|
	|WHERE
	|	CatalogInventoryKinds.SubjectToExcise";
	
	UnloadedColumns = "ItemsLocationAttributes, InventoryOwnerAttribute";
	
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds.Unload(, UnloadedColumns));
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	CheckTable = QueryResult.Unload();
	CheckTable.Indexes.Add("ItemsLocationAttributes");
	
	ErrorMessage_Template = NStr("vi = 'Trong dòng %1 danh sách ""Hàng hóa"" đã chỉ định hàng hóa chịu thuế TTĐB.
		|Cấm điều chuyển hàng hóa chịu thuế TTĐB trong kho bán lẻ.';
		|ru = 'В строке %1 списка ""Товары"" указан подакцизный товар.
		|Запрещено перемещение подакцизных товаров на розничные склады.';
		|en = 'Excisable goods are specified in line %1 of the ""Goods"" list.
		|Cannot transfer excisable goods to retail warehouses.'; fa = 'Excisable goods are specified in line %1 of the ""Goods"" list.
		|Cannot transfer excisable goods to retail warehouses.';
		|it = 'Excisable goods are specified in line %1 of the ""Goods"" list.
		|Cannot transfer excisable goods to retail warehouses.';
		|pl = 'Excisable goods are specified in line %1 of the ""Goods"" list.
		|Cannot transfer excisable goods to retail warehouses.';
		|tr = '""Ürünler"" listesinin %1 satırında tüketim vergisine tabi ürünler gösterilmektedir.
		|Tüketim vergisine tabi ürünlerin perakende ambarlara taşınması yasaktır.'");
	
	For Each TSRow In Goods Do
		FoundRow = CheckTable.Find(TSRow.ItemsLocationAttributes, "ItemsLocationAttributes");
		
		If FoundRow = Undefined Then
			Continue;
		EndIf;
		
		MessageText = StrTemplate(ErrorMessage_Template, TSRow.LineNumber);
		
		Field = CommonClientServer.PathToTabularSection("Goods", TSRow.LineNumber, "Products");
		
		Common.MessageToUser(MessageText, ThisObject , Field, "", Cancel);
	EndDo;
	
EndProcedure
Procedure FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Resources)
	
	For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
		
		If InventoryLine.Count = 0 Then
			Continue;
		EndIf;
		
		QuantityPerRow = Min(Resources.NumberOfProductsPerLine_, InventoryLine.Count);
		
		NewRow = InventoryKinds.Add();
		FillPropertyValues(NewRow, InventoryLine);
		
		If RowOfGoods.BatchesIndicationStatusRecipient = 14 Then
			NewRow.Series = RowOfGoods.Series;
		Else
			NewRow.Series = Undefined;
		EndIf;
		
		NewRow.Count			= QuantityPerRow;
		NewRow.QuantityByGBRN	= QuantityPerRow * InventoryLine.QuantityByGBRN / InventoryLine.Count;
		
		Resources.NumberOfProductsPerLine_ = Resources.NumberOfProductsPerLine_ - NewRow.Count;
		
		InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
		InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
		
		If Resources.NumberOfProductsPerLine_ = 0 Then
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.InventoryTransfer.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.InventoryTransfer.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.InventoryTransfer,
					SourceWarehouse,
					Department,
					Undefined);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Insert("BatchesIndicationStatus", "BatchesIndicationStatusSender");
	FieldsNames.Insert("Purpose", "AssignmentSender");
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInTransactionInProductsTable()
	
	If Not TransferAgainstOrders Then
		For Each LineProducts_ In Goods Do
			LineProducts_.SalesOpportunity = SalesOpportunity;
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)
	
	FillPropertyValues(ThisObject, FillingData);
	
	For Each String In FillingData.Goods Do
		NewRow = Goods.Add();
		FillPropertyValues(NewRow, String);
		
		NewRow.AssignmentSender = NewRow.Purpose;
	EndDo;
	
EndProcedure

Function ParametersForFillingInventoryTypes(CompanyFieldName1)
	
	WithoutIntercompani = Not (Constants.TransferGoodsOfOtherCompanies.Get()
						And BusinessOperation = Enums.BusinessTransactions.InventoryTransfer);
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.SelectTypesOfStocksForIntercampany = Not WithoutIntercompani;
	
	If BusinessOperation <> Enums.BusinessTransactions.InventoryTransfer Then
		FillParameters.CompanyFieldName1 = CompanyFieldName1;
		FillParameters.WhenSelectingByIntercampanyExcludeOrganizations = CompanyRecipient;
		FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
		
		FillParameters.SelectionOfStockTypes_.InventoryType = New Array;
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	Else
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
		If GetFunctionalOption("UseExcisableGoods") Then
			FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
		EndIf;
	EndIf;
	
	FillParameters.ReversedDocument = ReversedDocument;
	FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
