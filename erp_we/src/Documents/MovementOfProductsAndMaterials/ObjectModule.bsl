#If Not MobileStandaloneServer Then
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
	
	Status = Enums.StatusesOfProductsAndMaterialMovement[NewStatus];
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.MovementOfProductsAndMaterials);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	Return CheckFilling();
	
EndFunction

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.MovementOfProductsAndMaterials - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode) Export
	
	FillParameters = ParametersForFillingInventoryTypes(False, WriteMode);
	
	If WriteMode = DocumentWriteMode.UndoPosting Then
		FillParameters.DocumentMakesBothArrivalAndExpenditure = False;
	EndIf;
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
	If ByReferences
		And WriteMode = DocumentWriteMode.UndoPosting
		And TypeOf(Recipient) = Type("CatalogRef.BusinessStructure") Then
		
		DocumentObject.AdditionalProperties.Insert("ItIsNecessaryToControlRemnantsOfGoods", False);
		
	EndIf;
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.MovementOfProductsAndMaterials.CollectionOfTabularPartsOfGoods.
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

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.MovementOfProductsAndMaterials.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
		
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	For Each RowData In Goods Do
		If ByReferences And ValueIsFilled(ReferenceOrder)
			And BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom
			And Not ValueIsFilled(RowData.ReferenceOrder) Then
			
			RowData.ReferenceOrder = ReferenceOrder;
			
		ElsIf Not ValueIsFilled(RowData.ReferenceOrder)
			And RowData.ReferenceOrder <> Undefined Then
			
			RowData.ReferenceOrder = Undefined;
			
		EndIf;
	EndDo;
	
	// Rounding up the quantity if the movement is not through the storerooms
	If (TypeOf(Sender) <> Type("CatalogRef.Warehouses")	
			Or Not ValueIsFilled(Sender)
			Or Not Common.ObjectAttributeValue(Sender, "ShopFloorStockroom"))
		And (TypeOf(Recipient) <> Type("CatalogRef.Warehouses")	
			Or Not ValueIsFilled(Recipient)
			Or Not Common.ObjectAttributeValue(Recipient, "ShopFloorStockroom")) Then
		
		ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
		
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.MovementOfProductsAndMaterials);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	// Filling in PM types of reserves
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	KeyAttributes = QualityControl.DetailsOfDeterminingNeedForLotReferenceInDocument(Recipient, BusinessOperation);
	QualityControl.FillInControlledLotReferenceBeforeWritingDocument(ThisObject, KeyAttributes);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	MovementOfProductsAndMaterialsLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateUpdateControlledLotReferenceWhenWritingDocument(ThisObject);
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	MovementOfProductsAndMaterialsLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocumentBeforeFilling();
	
	ReferenceOrder = DocumentBaseWhenFillingIn(FillingData);
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(ReferenceOrder);
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("Basis") Then
		
		If TypeOf(FillingData.Basis) = Type("DocumentRef.SalesOrder") Then
			CompleteProductReleaseBasedOnCustomerOrder(FillingData);
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("ObjectsOfBases") Then
		
		BasisObject = FillingData.ObjectsOfBases[0];
		
		If FillingData.ObjectsOfBases.Count() = 1 Then
			DocumentBasis = BasisObject;
		EndIf;
		
		If TypeOf(BasisObject) = Type("DocumentRef.VendorInvoice") Then
			
			CompleteTransferOfMaterialsBasedOnAcquisition(FillingData.ObjectsOfBases);
			
		ElsIf TypeOf(BasisObject) = Type("DocumentRef.MaterialProviderOrder2_5") Then
			
			If FillingData.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
				FillInTransferOfMaterialsBasedOnOrderOfGiver(FillingData.ObjectsOfBases);
			ElsIf FillingData.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
				FillInOutputBasedOnGiverSOrder(FillingData.ObjectsOfBases);
			Else
				Raise StrTemplate(NStr("vi = 'Không cho phép điền trên cơ sở chứng từ %1 với giao dịch kinh tế
					|""%2"". Hãy liên hệ với người quản trị.';
					|ru = 'Заполнение на основании документа %1 с хозяйственной операцией
					|""%2"" не предусмотрено. Обратитесь к администратору.';
					|en = 'Population on the %1 document basis with the 
					|""%2"" business transaction is not provided. Please contact the administrator.'; fa = 'Population on the %1 document basis with the 
					|""%2"" business transaction is not provided. Please contact the administrator.';
					|it = 'La compilazione sulla base del documento %1 con l''operazione commerciale ""
					|""%2 non è prevista. Contattare amministratore.';
					|pl = 'Wypełnienie na podstawie dokumentu %1 z operacją gospodarczą 
					|""%2"" nie jest przewidziane. Zwróć się do administratora.';
					|tr = '%1 belgesi temelinde ""%2"" ticari işlemi
					| ile doldurulması öngörülmedi. Yöneticiye başvurun.'"), BasisObject, FillingData.BusinessOperation);
			EndIf;
			

		Else
			Raise StrTemplate(NStr("vi = 'Điền vào trên cơ sở chứng từ %1 không được cung cấp. Liên hệ với quản trị viên của bạn.';
									|ru = 'Заполнение на основании документа %1 не предусмотрено. Обратитесь к администратору.';
									|en = 'Population on the %1 document basis is not provided. Please contact the administrator.'; fa = 'Population on the %1 document basis is not provided. Please contact the administrator.';
									|it = 'La compilazione in base al documento %1 non è prevista. Contattare amministratore.';
									|pl = 'Wypełnienie na podstawie dokumentu %1 nie jest przewidziane. Zwróć się do administratora.';
									|tr = '%1 belgesi temelinde doldurulması öngörülmedi. Yöneticiye başvurun.'"), BasisObject);
		EndIf; 
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.MovementOfProductsAndMaterials);
		ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
		
	ElsIf TypeOf(FillingData) = Type("Structure") And FillingData.Property("Goods") Then
		
		FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
		
		For Each String In FillingData.Goods Do
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, String);
			NewRow.AssignmentSender = NewRow.Purpose;
		EndDo;
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.MovementOfProductsAndMaterials);
		ProductsServer.FillInSeriesByFEFO(ThisObject,SeriesSpecificationParameters, False);
	
	ElsIf TypeOf(FillingData) = Type("DocumentRef.MovementOfProductsAndMaterials") Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	Else
		
		// Filling in according to orders.
		
		FillingStructure = Undefined;
		If TypeOf(FillingData) = Type("Array") Then // input command based on
			
			FillingStructure = New Structure("AnArrayOfOrders", FillingData);
			
		ElsIf TypeOf(FillingData) = Type("Structure") Then
			
			If FillingData.Property("DefineOrders") Then
				
				FillingStructure = FillingData;
				FillingStructure.Insert("AnArrayOfOrders", DefineOrders(FillingData.HeaderAttributes));
				
			ElsIf FillingData.Property("AnArrayOfOrders") Then // from the special invoice form
				
				FillingStructure = FillingData;
				
			ElsIf FillingData.Property("HeaderAttributes") Then
				
				FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
				
			Else
				
				FillInByPicking(FillingData);
				
			EndIf;
			
		EndIf;
		
		If FillingStructure <> Undefined Then
			
			FillingStructure.HeaderAttributes.Insert("GoodsReceiptOption", GoodsReceiptOption);
			FillInByReferences(FillingStructure);
			
		EndIf;
		
	EndIf;
	
	MovementOfProductsAndMaterialsLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	InitializeDocument(FillingData);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	NotCheckedAttributeArray = New Array;
	NotCheckedAttributeArray.Add("Sender");
	NotCheckedAttributeArray.Add("Recipient");
	NotCheckedAttributeArray.Add("Goods");
	If Not InternalSubcontracting Then
		NotCheckedAttributeArray.Add("MaterialProviderCompany");
	EndIf;
	DisableCheckingForFillingInBusinessTransaction(NotCheckedAttributeArray);
	
	FieldsPresentation = Documents.MovementOfProductsAndMaterials.FieldsPresentation(ThisObject);
	
	CheckHeaderDetails_(FieldsPresentation, Cancel);
	CheckProducts(FieldsPresentation, Cancel);
	CheckComplianceOfInvoiceAndStages(FieldsPresentation.Goods, Cancel);
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.CheckPossibilityOfRounding = 
		(TypeOf(Sender) <> Type("CatalogRef.Warehouses")	
			Or Not ValueIsFilled(Sender)
			Or Not Common.ObjectAttributeValue(Sender, "ShopFloorStockroom"))
		And (TypeOf(Recipient) <> Type("CatalogRef.Warehouses")	
	   		Or Not ValueIsFilled(Recipient)
			Or Not Common.ObjectAttributeValue(Recipient, "ShopFloorStockroom"));
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	
	// Checking the filling of the series, including the series.
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.MovementOfProductsAndMaterials);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray);
	
	CheckCorrectnessOfIndicationOfExcisableItems(Cancel);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
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
			|pl = 'Wiersze pozycji';
			|tr = 'Ürünler'"),
		Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	MovementOfProductsAndMaterialsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.Posting);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	MovementOfProductsAndMaterialsLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.UndoPosting);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	MovementOfProductsAndMaterialsLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InitializeDocumentBeforeFilling();
	
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
	InventoryOwnerAttributesAreSpecifiedManually = False;
	InventoryKinds.Clear();
	SetOfSeries.Clear();
	
	Documents.MovementOfProductsAndMaterials.UntieFromOrders(ThisObject);
	
	For Each TSRow In Goods Do
		TSRow.RowID = "";
	EndDo;
	
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption();
	
	InitializeDocument();
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	MovementOfProductsAndMaterialsLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocumentBeforeFilling()
	
	Author = Users.CurrentUser();
	
	If GetFunctionalOption("UseStatusesOfProductsAndMaterialsMovements") Then
		Status = Enums.StatusesOfProductsAndMaterialMovement.Shipped;
	Else
		Status = Enums.StatusesOfProductsAndMaterialMovement.Accepted;
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	TransactionList = Documents.MovementOfProductsAndMaterials.TransactionList();
	If TransactionList.Count() = 1 Then
		BusinessOperation = TransactionList[0].Value;
	EndIf;
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	If BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
		PriceKind        = Catalogs.TypesOfPrices.TypeOfPricePlannedCostOfInventory(PriceKind);
	ElsIf BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
		PriceKind = Catalogs.Warehouses.AccountingPriceType(Sender);
	EndIf;
	
	If Not ValueIsFilled(Currency) Then
		Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Catalogs.TypesOfPrices.GetPriceTypeDetails(PriceKind).PriceCurrency);
	EndIf;
	
	FieldsPresentation = Documents.MovementOfProductsAndMaterials.FieldsPresentation(ThisObject);
	If FieldsPresentation.SenderType = "Department" Then
		Sender = SettingsValueCached.UserDivision(EmployeeResponsible, Sender);
	ElsIf FieldsPresentation.SenderType = "Storeroom" Then
		Department = SettingsValueCached.UserDivision(EmployeeResponsible);
		Sender = SettingsValueCached.GetDefaultShopPantry(Department, Sender);
	Else
		Sender = SettingsValueCached.GetDefaultWarehouse(Sender);
	EndIf;
	
	If FieldsPresentation.TypeRecipient = "Department" Then
		Recipient = SettingsValueCached.UserDivision(EmployeeResponsible, Recipient);
	ElsIf FieldsPresentation.TypeRecipient = "Storeroom" Then
		Department = SettingsValueCached.UserDivision(EmployeeResponsible);
		Recipient = SettingsValueCached.GetDefaultShopPantry(Department, Recipient);
	Else
		Recipient = SettingsValueCached.GetDefaultWarehouse(Recipient);
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
		Or BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction Then
		ByReferences = True;
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom
		Or BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProducts
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
		ByReferences = False;
	EndIf;
	
	If Not LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(LineOfBusiness) Then
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
	EndIf;
	
	FillParameters = Documents.MovementOfProductsAndMaterials.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(VATTaxation, FillParameters);
	
	StructureOfActions = New Structure;
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Function DefineOrders(HeaderAttributes)

	QueryText = 
	"SELECT ALLOWED
	|	TableBalance.ReferenceOrder
	|FROM
	|	AccumulationRegister.OrdersOfMaterialsForProduction.Balance(
	|			,
	|			Department = &Department
	|				AND Warehouse = &Warehouse) AS TableBalance
	|WHERE
	|	TableBalance.ReferenceOrder.Organization = &Organization
	|	AND TableBalance.ToRegisterBalance <> 0";
	
	Query = New Query(QueryText);
	Query.SetParameter("Organization", HeaderAttributes.Organization);
	Query.SetParameter("Department", HeaderAttributes.Recipient);
	Query.SetParameter("Warehouse", HeaderAttributes.Sender);
	
	AnArrayOfOrders = Query.Execute().Unload().UnloadColumn("ReferenceOrder");
	
	Return AnArrayOfOrders;

EndFunction

Procedure FillInByPicking(FilterStructure1)
	
	FilterStructure1.Property("Organization", Organization);
	
	If FilterStructure1.Property("BusinessOperation", BusinessOperation) Then
		
		FieldsPresentation = Documents.MovementOfProductsAndMaterials.FieldsPresentation(ThisObject);
		
		If FieldsPresentation.SenderType = "Warehouse" Then
			FilterStructure1.Property("Warehouse", Sender);
		ElsIf FieldsPresentation.TypeRecipient = "Warehouse" Then
			FilterStructure1.Property("Warehouse", Recipient);
		EndIf;
		
		If FieldsPresentation.SenderType = "Department" Then
			FilterStructure1.Property("Department", Sender);
		ElsIf FieldsPresentation.TypeRecipient = "Department" Then
			FilterStructure1.Property("Department", Recipient);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInByReferences(FillingStructure)
	
	If FillingStructure.HeaderAttributes.BusinessOperation <> Enums.BusinessTransactions.MaterialTransferToProduction
		And FillingStructure.HeaderAttributes.BusinessOperation <> Enums.BusinessTransactions.TransferOfMaterialsToStoreroom
		And FillingStructure.HeaderAttributes.BusinessOperation <> Enums.BusinessTransactions.TransferOfProductsFromProduction
		And FillingStructure.HeaderAttributes.BusinessOperation <> Enums.BusinessTransactions.TransferOfProductsFromStoreroom
		And FillingStructure.HeaderAttributes.BusinessOperation <> Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
		And FillingStructure.HeaderAttributes.BusinessOperation <> Enums.BusinessTransactions.ReturnOfMaterialsFromStoreroom Then
		Raise StrTemplate(NStr("vi = 'Điền vào theo hướng dẫn cho hoạt động ""%1"" không được cung cấp.';
								|ru = 'Заполнение по распоряжениям для операции ""%1"" не предусмотрено.';
								|en = 'Population by references for the ""%1"" operation is not provided.'; fa = 'Population by references for the ""%1"" operation is not provided.';
								|it = 'La compilazione per disposizioni per l''operazione ""%1"" non è prevista.';
								|pl = 'Wypełnienie według zamówień dla operacji ""%1"" nie jest przewidziane.';
								|tr = '""%1"" işlemi için talimatlara göre doldurma sağlanmadı.'"), FillingStructure.HeaderAttributes.BusinessOperation);
	EndIf;
	
	AnArrayOfOrders = FillingStructure.AnArrayOfOrders;
	
	FillParameters = Documents.MovementOfProductsAndMaterials.DocumentFillingParameters();
	FillPropertyValues(FillParameters, FillingStructure);
	Date = CurrentSessionDate();
	
	Documents.MovementOfProductsAndMaterials.InitializeFillingParameters(FillParameters,
		FillingStructure.HeaderAttributes, AnArrayOfOrders);
	
	InvoiceTable = Goods.Unload();
	
	Documents.MovementOfProductsAndMaterials.FillInByOrdersOrders(InvoiceTable, Ref, FillParameters);
	
	If FillParameters.FillByWarehouseDocument Then
		InvoiceTable.Columns.Count.Name        = "QuantityBeforeChange_";
		ColumnQuantityInOrder_ = InvoiceTable.Columns.NoteQuantity; // ValueTableColumn
		ColumnQuantityInOrder_.Name = "Count";
	Else
		InvoiceTable.Columns.Count.Name        = "QuantityBeforeChange_";
		ColumnQuantityInOrder = InvoiceTable.Columns.QuantityInOrder; // ValueTableColumn
		ColumnQuantityInOrder.Name = "Count";
	EndIf;
	
	InvoicesServer.DeleteEmptyLines(InvoiceTable, "Count");
	
	Goods.Load(InvoiceTable);
	
	Documents.MovementOfProductsAndMaterials.FillInHeaderOfOrderDocument(ThisObject, FillParameters, AnArrayOfOrders);
	
	If FillParameters.FillByWarehouseDocument Then
		If FillParameters.BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
			Or FillParameters.BusinessOperation = Enums.BusinessTransactions.TransferOfMaterialsToStoreroom Then
			// Transfer of warehouse series from orders for the recipient
			FiltersSettings = Documents.MovementOfProductsAndMaterials.GetSelectionSettings_(FillParameters.HeaderAttributes);
			Documents.MovementOfProductsAndMaterials.FillInShippingInstructions(
				ThisObject, ?(FiltersSettings <> Undefined, FiltersSettings.TableFilters, Undefined));
		EndIf;
	ElsIf FillParameters.BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
		Documents.MovementOfProductsAndMaterials.FillSeriesByProductionStages(ThisObject);
	EndIf;
	
	Documents.MovementOfProductsAndMaterials.UpdateDependentDetailsOfTablePart(Goods, FillParameters);
	
EndProcedure

Procedure CompleteTransferOfMaterialsBasedOnAcquisition(AnArrayOfOrders)
	
	Query = New Query(
		"SELECT
		|	VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom) AS BusinessOperation,
		|	MAX(DocumentTable.Organization),
		|	MAX(GoodsTable.Warehouse) AS Sender,
		|	MAX(DocumentTable.LineOfBusiness) AS LineOfBusiness,
		|	COUNT(DISTINCT DocumentTable.Organization) AS NumberOfOrganizations,
		|	COUNT(DISTINCT GoodsTable.Warehouse) AS NumberOfWarehouses
		|FROM
		|	Document.VendorInvoice AS DocumentTable
		|		LEFT JOIN Document.VendorInvoice.Goods AS GoodsTable
		|		ON GoodsTable.Ref = DocumentTable.Ref
		|			AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|WHERE
		|	DocumentTable.Ref IN (&AnArrayOfOrders)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PurchaseOfGoodsServicesGoods.Warehouse,
		|	PurchaseOfGoodsServicesGoods.Products,
		|	PurchaseOfGoodsServicesGoods.Characteristic,
		|	PurchaseOfGoodsServicesGoods.Purpose AS Purpose,
		|	PurchaseOfGoodsServicesGoods.Purpose AS AssignmentSender,
		|	PurchaseOfGoodsServicesGoods.Package,
		|	PurchaseOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackages,
		|	PurchaseOfGoodsServicesGoods.Count AS Count,
		|	PurchaseOfGoodsServicesGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
		|	PurchaseOfGoodsServicesGoods.BatchesIndicationStatus AS BatchesIndicationStatusSender,
		|	PurchaseOfGoodsServicesGoods.Series AS Series
		|FROM
		|	Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
		|WHERE
		|	PurchaseOfGoodsServicesGoods.Ref IN (&AnArrayOfOrders)
		|	AND PurchaseOfGoodsServicesGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PurchaseOfGoodsServicesSeries.Warehouse,
		|	PurchaseOfGoodsServicesSeries.Series,
		|	PurchaseOfGoodsServicesSeries.Count,
		|	PurchaseOfGoodsServicesSeries.Products,
		|	PurchaseOfGoodsServicesSeries.Characteristic,
		|	PurchaseOfGoodsServicesSeries.Purpose AS Purpose,
		|	PurchaseOfGoodsServicesSeries.Purpose AS AssignmentSender
		|FROM
		|	Document.VendorInvoice.SetOfSeries AS PurchaseOfGoodsServicesSeries
		|WHERE
		|	PurchaseOfGoodsServicesSeries.Ref IN (&AnArrayOfOrders)
		|	AND PurchaseOfGoodsServicesSeries.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods))");
	
	Query.SetParameter("AnArrayOfOrders", AnArrayOfOrders);
	
	QueryResult = Query.ExecuteBatch();
	
	SampleBankingDetails = QueryResult[0].Select();
	If Not SampleBankingDetails.Next() Then
		Return;
	EndIf;
	
	// Checking the header and tabular part
	If SampleBankingDetails.NumberOfOrganizations > 1 Then
		ErrorText = NStr("vi = 'Không thể sắp xếp việc chuyển giao chứng từ cho các Doanh nghiệp khác nhau.';
						|ru = 'Невозможно оформить передачу материалов по разным организациям.';
						|en = 'Cannot register material transfer for different companies.'; fa = 'Cannot register material transfer for different companies.';
						|it = 'È impossibile formalizzare la consegna dei materiali per società diverse.';
						|pl = 'Niemożliwe jest zorganizowanie przekazania materiałów według różnych firm.';
						|tr = 'Farklı iş yerlerine göre malzeme transferini düzenlemeniz mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	
	If SampleBankingDetails.NumberOfWarehouses > 1 Then
		ErrorText = NStr("vi = 'Không thể sắp xếp việc chuyển giao nguyên liệu, bởi vì các vật liệu đã đến các kho khác nhau.';
						|ru = 'Невозможно оформить передачу материалов, т.к материалы поступили на разные склады.';
						|en = 'Cannot register material transfer as materials were delivered to different warehouses.'; fa = 'Cannot register material transfer as materials were delivered to different warehouses.';
						|it = 'È impossibile formalizzare la consegna dei materiali, perché i materiali sono arrivati nei magazzini diversi.';
						|pl = 'Niemożliwe jest zorganizowanie transferu materiałów, ponieważ materiały trafiły do różnych magazynów.';
						|tr = 'Malzemeler farklı ambarlara geldiğinden dolayı malzeme transferini düzenlemeniz mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	
	BaseGoods = QueryResult[1].Unload();
	If BaseGoods.Count() = 0 Then
		ErrorText = NStr("vi = 'Tiếp nhận không chứa hàng hóa. Nhập dựa trên là không thể.';
						|ru = 'Поступление не содержит товаров. Ввод на основании невозможен.';
						|en = 'Receipt does not contain any goods. Cannot generate any documents from it.'; fa = 'Receipt does not contain any goods. Cannot generate any documents from it.';
						|it = 'L''arrivo non contiene merci. L''immissione in base alla causale non è possibile.';
						|pl = 'Wpływ nie zawiera towarów. Wprowadzanie na podstawie nie jest możliwe.';
						|tr = 'Makbuz, ürün içermemektedir. Temele dayalı giriş mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	
	FillPropertyValues(ThisObject, SampleBankingDetails);
	
	// Splitting lines, filling in series with status 10.
	RowIndexes = New Array();
	
	For Each LineProducts_ In BaseGoods Do
		If LineProducts_.BatchesIndicationStatus = 10 Then
			RowIndexes.Insert(0, BaseGoods.IndexOf(LineProducts_));
		EndIf;
	EndDo;
	
	BaseSeries = QueryResult[2].Unload();
	
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

Procedure FillInTransferOfMaterialsBasedOnOrderOfGiver(AnArrayOfOrders)
	
	Query = New Query();
	Texts = New Array();
	QueryText =
		"SELECT
		|	VALUE(Enum.BusinessTransactions.TransferOfMaterialsToStoreroom) AS BusinessOperation,
		|	MAX(Attributes.Organization)                                          AS Organization,
		|	MAX(Attributes.WarehouseForReceipt)                                     AS Sender,
		|	MAX(Attributes.VATTaxation)                                   AS ConsumptionForActivity,
		|	MAX(Attributes.LineOfBusiness)                              AS LineOfBusiness,
		|	MAX(Attributes.ThereAreErrorsPosted)                                   AS ThereAreErrorsPosted,
		|	MAX(Attributes.ThereAreErrorsStatus)                                     AS ThereAreErrorsStatus,
		|	COUNT(DISTINCT Attributes.Organization)                              AS NumberOfOrganizations,
		|	COUNT(DISTINCT Attributes.WarehouseForReceipt)                         AS NumberOfWarehouses,
		|	COUNT(DISTINCT Attributes.VATTaxation)                       AS NumberOfTaxOptions
		|FROM
		|	(SELECT
		|		MaterialProviderOrder.Organization                             AS Organization,
		|		MaterialProviderOrder.WarehouseForReceipt                        AS WarehouseForReceipt,
		|		MaterialProviderOrder.VATTaxation                      AS VATTaxation,
		|		MaterialProviderOrder.LineOfBusiness                 AS LineOfBusiness,
		|		NOT MaterialProviderOrder.Posted                             AS ThereAreErrorsPosted,
		|		NOT MaterialProviderOrder.Status IN (&ArrayOfValidStatuses) AS ThereAreErrorsStatus 
		|	FROM
		|		Document.MaterialProviderOrder2_5 AS MaterialProviderOrder
		|	WHERE
		|		MaterialProviderOrder.Ref IN(&GiverSOrders)
		|		AND NOT MaterialProviderOrder.WarehouseForReceipt.IsFolder
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		MaterialProviderOrder.Organization                             AS Organization,
		|		TabularPartMaterials.Warehouse                         AS WarehouseForReceipt,
		|		MaterialProviderOrder.VATTaxation                      AS VATTaxation,
		|		MaterialProviderOrder.LineOfBusiness                 AS LineOfBusiness,
		|		NOT MaterialProviderOrder.Posted                             AS ThereAreErrorsPosted,
		|		NOT MaterialProviderOrder.Status IN (&ArrayOfValidStatuses) AS ThereAreErrorsStatus 
		|	FROM
		|		Document.MaterialProviderOrder2_5 AS MaterialProviderOrder
		|			INNER JOIN Document.MaterialProviderOrder2_5.UsedMaterials AS TabularPartMaterials
		|			ON MaterialProviderOrder.Ref = TabularPartMaterials.Ref
		|	WHERE
		|		MaterialProviderOrder.Ref IN(&GiverSOrders)
		|		AND MaterialProviderOrder.WarehouseForReceipt.IsFolder
		|	) AS Attributes
		|;
		|
		|/////////////////////////////////////////////////
		|SELECT
		|	Goods.Products         AS Products,
		|	Goods.Characteristic       AS Characteristic,
		|	Goods.Warehouse                AS Warehouse,
		|	Goods.Purpose           AS Purpose,
		|	SUM(Goods.Count)    AS Count,
		|	
		|	MIN(Goods.Package)    AS Package,
		|	MIN(Goods.LineNumber) AS LineNumber
		|INTO TTProducts_1
		|FROM
		|	Document.MaterialProviderOrder2_5.UsedMaterials AS Goods
		|WHERE
		|	Goods.Ref IN(&GiverSOrders)
		|
		|GROUP BY
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Warehouse,
		|	Goods.Purpose
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose
		|";
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT ALLOWED
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose
		|			FROM
		|				TTProducts_1 AS Filter)) AS Inventories";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	Texts.Add(QueryText);
	
	QueryText =
		"SELECT
		|	Goods.Products   AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Warehouse          AS Warehouse,
		|	Goods.Purpose     AS Purpose,
		|	Goods.Purpose     AS AssignmentSender,
		|	
		|	CASE
		// no more than the quantity specified in the order is transmitted.
		|		WHEN Calculation.QuantityForShipAction > Goods.Count
		|			THEN Goods.Count
		|		ELSE Calculation.QuantityForShipAction
		|	END AS Count,
		|	
		|	Goods.Package               AS Package,
		|	Goods.LineNumber            AS LineNumber,
		|
		|	CASE
		// no more than the quantity specified in the order is transmitted.
		|		WHEN Calculation.QuantityForShipAction > Goods.Count
		|			THEN Goods.Count
		|		ELSE Calculation.QuantityForShipAction
		|	END / ISNULL(&QueryTextPackagingFactor, 1) AS NumberOfPackages
		|FROM
		|	TTProducts_1 AS Goods
		|		
		|		INNER JOIN CalculationOfBalancesForSettingActions AS Calculation
		|		ON Goods.Products   = Calculation.Products
		|		 AND Goods.Characteristic = Calculation.Characteristic
		|		 AND Goods.Warehouse          = Calculation.Warehouse
		|		 AND Goods.Purpose     = Calculation.Purpose
		|WHERE
		|	Calculation.QuantityForShipAction > 0
		|	
		|ORDER BY
		|	LineNumber";
	Texts.Add(QueryText);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToProduce);
	ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToShip);
	ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.Closed);
	
	Query.SetParameter("GiverSOrders", AnArrayOfOrders);
	Query.SetParameter("ArrayOfValidStatuses", ArrayOfValidStatuses);
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Goods.Package",
		"Goods.Products"));
	
	Result = Query.ExecuteBatch();
	
	Attributes = Result[0].Select();
	
	If Not Attributes.Next() Then
		Return;
	EndIf;
	
	If Attributes.NumberOfOrganizations > 1 Then
		ErrorText = NStr("vi = 'Không thể sắp xếp việc chuyển giao chứng từ cho các Doanh nghiệp khác nhau.';
						|ru = 'Невозможно оформить передачу материалов по разным организациям.';
						|en = 'Cannot register material transfer for different companies.'; fa = 'Cannot register material transfer for different companies.';
						|it = 'È impossibile formalizzare la consegna dei materiali per società diverse.';
						|pl = 'Niemożliwe jest zorganizowanie przekazania materiałów według różnych firm.';
						|tr = 'Farklı iş yerlerine göre malzeme transferini düzenlemeniz mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	If Attributes.NumberOfWarehouses > 1 Then
		ErrorText = NStr("vi = 'Không thể hoàn tBiên bảnệc chuyển giao vật liệu vì vật liệu đến kho khác nhau.';
						|ru = 'Невозможно оформить передачу материалов, т.к. материалы поступили на разные склады.';
						|en = 'Cannot register material transfer as materials were delivered to different warehouses.'; fa = 'Cannot register material transfer as materials were delivered to different warehouses.';
						|it = 'È impossibile formalizzare la consegna dei materiali, perché i materiali sono arrivati nei magazzini diversi.';
						|pl = 'Niemożliwe jest zorganizowanie transferu materiałów, ponieważ materiały przybyły do różnych magazynów.';
						|tr = 'Malzemeler farklı ambarlara geldiğinden dolayı malzeme transferini düzenlemeniz mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	If Attributes.ThereAreErrorsStatus Then
		ErrorText = NStr("vi = 'Để thực hiện chuyển nhượng trong sản xuất, lệnh phải ở trạng thái của hàng hóa, sản xuất, giao hàng, trực tuyến.';
						|ru = 'Для оформления передачи в производстово заказ должен быть в статусе ""К производству"", ""К отгрузке"" или ""Закрыт"".';
						|en = 'To register transfer to production, the order must be in the ""For production"", ""To ship"", or ""Closed"" status.'; fa = 'To register transfer to production, the order must be in the ""For production"", ""To ship"", or ""Closed"" status.';
						|it = 'Per formalizzare la consegna in produzione, l''ordine deve avere lo stato ""Da produrre"", ""Da spedire"" o ""Chiuso"".';
						|pl = 'Aby zarejestrować przeniesienie do zlecenia produkcyjnego, musi mieć status ""Do produkcji"", ""Do wysyłki"" lub ""Zamknięty"".';
						|tr = 'Üretime transferin düzenlenmesi için siparişin ""Üretilecek"", ""Sevk edilecek"" veya ""Kapalı"" durumunda olması gerekmektedir.'");
		Raise ErrorText;
	EndIf;
	If Result[Result.UBound()].IsEmpty() Then
		ErrorText = NStr("vi = 'Việc nhận nguyên liệu từ nhà thầu không được chính thức hóa hoặc tất cả các nguyên vật liệu đã được chuyển giao. Nhập trên cơ sở là không thể.';
						|ru = 'Поступление сырья от давальца не оформлено или все материалы уже переданы. Ввод на основании невозможен.';
						|en = 'No ""Goods receipt — Subcontracting services delivered"" is registered, or all materials are already transferred. Generation from base documents is not available.'; fa = 'No ""Goods receipt — Subcontracting services delivered"" is registered, or all materials are already transferred. Generation from base documents is not available.';
						|it = 'L''arrivo delle materie prime dal committente non è formalizzato o tutti i materiali sono già stati consegnati. L''immissione in base alla causale non è possibile.';
						|pl = 'Odbiór surowców od dostawcy nie jest rejestrowany lub wszystkie materiały zostały już przesłane. Wprowadzanie na podstawie nie jest możliwe.';
						|tr = '""Ambar giriş fişi - Fason müşterisinden alınan"" düzenlenmedi veya tüm malzemeler halihazırda transfer edildi. Temele dayalı giriş mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	If Attributes.NumberOfTaxOptions > 1 Then
		ErrorText = NStr("vi = 'Không thể hoàn thành một chứng từ vì Đơn đặt hàng được lựa chọn được phát hành cho các hoạt động Thuế GTGT khác nhau.';
						|ru = 'Невозможно оформить один документ, т.к. выбранные заказы оформлены под разную деятельность по НДС.';
						|en = 'Cannot register one document as the selected orders are registered for different activity on VAT.'; fa = 'Cannot register one document as the selected orders are registered for different activity on VAT.';
						|it = 'È impossibile formalizzare un documento, perché gli ordini selezionati sono formalizzati per le attività diverse per l''IVA.';
						|pl = 'Nie można wydać jednego dokumentu, ponieważ wybrane zamówienia są wydawane dla różnych czynności związanych z VAT.';
						|tr = 'Seçili siparişler, farklı KDV faaliyetleri kapsamında düzenlendiğinden dolayı tek belge düzenlemeniz mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	
	FillPropertyValues(ThisObject, Attributes);
	
	Goods.Load(Result[Result.UBound()].Unload());
	
EndProcedure

Procedure FillInOutputBasedOnGiverSOrder(AnArrayOfOrders)
	
	Query = New Query(
	"SELECT
	|	DocumentData.BusinessOperation              AS BusinessOperation,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.Recipient                         AS Recipient,
	|	DocumentData.LineOfBusiness            AS LineOfBusiness,
	|	DocumentData.VATTaxation                 AS VATTaxation,
	|	DocumentData.ThereAreErrorsPosted                 AS ThereAreErrorsPosted,
	|	DocumentData.ThereAreErrorsStatus                   AS ThereAreErrorsStatus,
	|	DocumentData.NumberOfOrganizations              AS NumberOfOrganizations,
	|	DocumentData.NumberOfWarehouses                  AS NumberOfWarehouses,
	|	DocumentData.NumberOfTaxOptions AS NumberOfTaxOptions,
	|	DocumentData.NumberOfActivities  AS NumberOfActivities
	|FROM
	|	(SELECT
	|		VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom) AS BusinessOperation,
	|		MAX(MaterialProviderOrder2_5.Organization)                                   AS Organization,
	|		MAX(TabularPartOfProducts.Warehouse)                                  AS Recipient,
	|	
	|		MAX(CASE
	|					WHEN MaterialProviderOrder2_5.LineOfBusiness.CostAccounting
	|						THEN MaterialProviderOrder2_5.LineOfBusiness
	|					ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|				END)                                                           AS LineOfBusiness,
	|	
	|		MAX(MaterialProviderOrder2_5.VATTaxation)                            AS VATTaxation,
	|		MAX(NOT MaterialProviderOrder2_5.Posted)                                   AS ThereAreErrorsPosted,
	|		MAX(CASE
	|					WHEN MaterialProviderOrder2_5.Status IN (&ArrayOfValidStatuses)
	|						THEN FALSE
	|					ELSE TRUE
	|				END)                                                           AS ThereAreErrorsStatus,
	|		COUNT(DISTINCT MaterialProviderOrder2_5.Organization)                       AS NumberOfOrganizations,
	|		COUNT(DISTINCT TabularPartOfProducts.Warehouse)                      AS NumberOfWarehouses,
	|		COUNT(DISTINCT MaterialProviderOrder2_5.VATTaxation)                AS NumberOfTaxOptions,
	|	
	|		COUNT(DISTINCT CASE
	|								WHEN MaterialProviderOrder2_5.LineOfBusiness.CostAccounting
	|									THEN MaterialProviderOrder2_5.LineOfBusiness
	|								ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|							END)                                               AS NumberOfActivities
	|	FROM
	|		Document.MaterialProviderOrder2_5 AS MaterialProviderOrder2_5
	|			INNER JOIN Document.MaterialProviderOrder2_5.ManufacturedProduct AS TabularPartOfProducts
	|			ON MaterialProviderOrder2_5.Ref = TabularPartOfProducts.Ref
	|			 AND NOT TabularPartOfProducts.Canceled
	|	WHERE
	|		MaterialProviderOrder2_5.Ref IN(&GiverSOrders)
	|	) AS DocumentData
	|WHERE
	|	DocumentData.Organization <> UNDEFINED
	|;
	|
	|/////////////////////////////////////////////////
	|SELECT
	|	Goods.Products         AS Products,
	|	Goods.Characteristic       AS Characteristic,
	|	Goods.Warehouse                AS Warehouse,
	|	TabDocuments.Purpose     AS Purpose,
	|	SUM(Goods.Count)    AS Count,
	|	
	|	MIN(Goods.Package)    AS Package,
	|	MIN(Goods.LineNumber) AS LineNumber
	|INTO TTProducts_1
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS Goods
	|		
	|		LEFT JOIN Document.MaterialProviderOrder2_5 AS TabDocuments
	|		ON TabDocuments.Ref = Goods.Ref
	|WHERE
	|	Goods.Ref IN(&GiverSOrders)
	|	AND NOT Goods.Canceled
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Warehouse,
	|	TabDocuments.Purpose
	|	
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose
	|;
	|
	|//////////////////////////////////////////////
	|SELECT ALLOWED
	|	Inventories.Products AS Products,
	|	Inventories.Characteristic AS Characteristic,
	|	Inventories.Warehouse AS Warehouse,
	|	Inventories.Purpose AS Purpose,
	|	Inventories.OrderDocument AS OrderDocument,
	|	Inventories.LockedInStockBalance AS LockedInStockBalance,
	|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
	|	Inventories.ToUnlockBalance AS ToUnlockBalance,
	|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
	|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
	|INTO InventoryAndNeedsBalanceOfControlledLotsReference
	|FROM
	|	AccumulationRegister.InventoryAndDemands.Balance(,
	|		(Products, Characteristic, Warehouse, Purpose) IN(
	|			SELECT
	|				FilterOfProducts_.Products AS Products,
	|				FilterOfProducts_.Characteristic AS Characteristic,
	|				FilterOfProducts_.Warehouse AS Warehouse,
	|				FilterOfProducts_.Purpose AS Purpose
	|			FROM
	|				TTProducts_1 AS FilterOfProducts_)) AS Inventories
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose
	|;
	|
	|////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Inventories.Products AS Products,
	|	Inventories.Characteristic AS Characteristic,
	|	Inventories.Warehouse AS Warehouse,
	|	Inventories.Purpose AS Purpose,
	|	Inventories.InStockBalance AS InStockBalance,
	|	Inventories.LockedInStockBalance AS LockedInStockBalance,
	|	Inventories.OrderedBalance AS OrderedBalance,
	|	Inventories.Received_1Balance AS Received_1Balance,
	|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
	|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
	|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
	|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
	|	Inventories.ToSupplyBalance AS ToSupplyBalance,
	|	Inventories.NotProvideBalance AS NotProvideBalance
	|INTO InventoryAndDemandsBalance
	|FROM
	|	AccumulationRegister.InventoryAndDemands.Balance(,
	|		(Products, Characteristic, Warehouse, Purpose) IN(
	|			SELECT
	|				FilterOfProducts_.Products AS Products,
	|				FilterOfProducts_.Characteristic AS Characteristic,
	|				FilterOfProducts_.Warehouse AS Warehouse,
	|				FilterOfProducts_.Purpose AS Purpose
	|			FROM
	|				TTProducts_1 AS FilterOfProducts_)) AS Inventories
	|;
	|
	|//////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Purpose AS Purpose,
	|	Goods.Purpose AS AssignmentSender,
	|	
	|	CASE
	|		WHEN
	|			Calculation.NotProvided_ReserveAsNeeded
	|				+ Calculation.NotProvided_Postpone
	|				+ Calculation.Supply_CIsNotProvided > Goods.Count
	// no more than the quantity specified in the order is transmitted.
	|			THEN Goods.Count
	|		ELSE
	|			Calculation.NotProvided_ReserveAsNeeded
	|				+ Calculation.NotProvided_Postpone
	|				+ Calculation.Supply_CIsNotProvided
	|	END AS Count,
	|	
	|	Goods.Package AS Package,
	|	Goods.LineNumber AS LineNumber,
	|	
	|	CASE
	|		WHEN
	|			Calculation.NotProvided_ReserveAsNeeded
	|				+ Calculation.NotProvided_Postpone
	|				+ Calculation.Supply_CIsNotProvided > Goods.Count
	// no more than the quantity specified in the order is transmitted.
	|			THEN Goods.Count
	|		ELSE
	|			Calculation.NotProvided_ReserveAsNeeded
	|				+ Calculation.NotProvided_Postpone
	|				+ Calculation.Supply_CIsNotProvided
	|	END / ISNULL(&QueryTextPackagingFactor, 1) AS NumberOfPackages
	|FROM
	|	SubstitutionInventoryAllocation AS Calculation
	|		
	|	INNER JOIN TTProducts_1 AS Goods
	|	ON Goods.Products = Calculation.Products
	|	AND Goods.Characteristic = Calculation.Characteristic
	|	AND Goods.Warehouse = Calculation.Warehouse
	|	AND Goods.Purpose = Calculation.Purpose
	|WHERE
	|	Calculation.NotProvided_ReserveAsNeeded
	|		+ Calculation.NotProvided_Postpone
	|		+ Calculation.Supply_CIsNotProvided > 0
	|ORDER BY
	|	LineNumber");
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForInventoryAllocation();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Result = "SubstitutionInventoryAllocation"; // @query-part-1
	
	ProvisionInDocumentsServer.InventoryAllocation(Query.Text, TablesNames, False);
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToProduce);
	ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.ToShip);
	ArrayOfValidStatuses.Add(Enums.StatusesOfMaterialProviderOrders.Closed);
	
	Query.SetParameter("GiverSOrders", AnArrayOfOrders);
	Query.SetParameter("ArrayOfValidStatuses", ArrayOfValidStatuses);
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Goods.Package",
		"Goods.Products"));
	
	Result = Query.ExecuteBatch();
	
	Attributes = Result[0].Select();
	
	If Not Attributes.Next() Then
		Return;
	EndIf;
	
	If Attributes.NumberOfOrganizations > 1 Then
		ErrorText = NStr("vi = 'Không thể phát hành sản phẩm cho các Doanh nghiệp khác nhau.';
						|ru = 'Невозможно оформить выпуск продукции по разным организациям.';
						|en = 'Cannot register product release by different companies.'; fa = 'Cannot register product release by different companies.';
						|it = 'È impossibile formalizzare l''emissione dei prodotti per società diverse.';
						|pl = 'Niemożliwe jest sporządzenie wyprodukowania produkcji według różnych firm.';
						|tr = 'Farklı iş yerlerine göre ürün sürümü düzenlemeniz mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	If Attributes.NumberOfWarehouses > 1 Then
		ErrorText = NStr("vi = 'Không thể hoàn thành một chứng từ vì sản phẩm phải được phát hành đến các kho khác nhau.';
						|ru = 'Невозможно оформить один документ, т.к. продукция должна быть выпущена на разные склады.';
						|en = 'Cannot register one document as the products should be released to different warehouses.'; fa = 'Cannot register one document as the products should be released to different warehouses.';
						|it = 'È impossibile formalizzare un documento, perché i prodotti devono essere emessi nei diversi magazzini.';
						|pl = 'Niemożliwe jest sporządzenie jednego dokumentu ponieważ wiersze pozycji powinny być wydane do różnych magazynów.';
						|tr = 'İmal edilen ürünlerin farklı ambarlara üretilmesi gerektiğinden dolayı tek belge düzenlemeniz mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	If Attributes.ThereAreErrorsStatus Then
		ErrorText = NStr("vi = 'Để phát hành một hàng hóa, lệnh phải ở trạng thái của sản xuất, sản xuất, giao hàng, trực tuyến.';
						|ru = 'Для оформления выпуска продукции заказ должен быть в статусе ""К производству"", ""К отгрузке"" или ""Закрыт"".';
						|en = 'To register the product release, the order must be in the ""For production"", ""To ship"", or ""Closed"" status.'; fa = 'To register the product release, the order must be in the ""For production"", ""To ship"", or ""Closed"" status.';
						|it = 'Per formalizzare l''emissione dei prodotti l''ordine deve avere lo stato ""Da produrre"", ""Da spedire"" o ""Chiuso"".';
						|pl = 'W celu sporządzenia wyprodukowania produkcji zamówienie powinno być w statusie ""К производству"", ""К отгрузке"" lub ""Закрыт"".';
						|tr = 'İmal edilen ürün çıkışının düzenlenmesi için siparişin ""Üretilecek"", ""Sevk edilecek"" veya ""Kapalı"" durumunda olması gerekmektedir.'");
		Raise ErrorText;
	EndIf;
	If Result[Result.UBound()].IsEmpty() Then
		ErrorText = NStr("vi = 'Tất cả các sản phẩm đã được xuất xưởng, nhập trên cơ sở là không cần thiết.';
						|ru = 'Вся продукция уже выпущена, ввод на основании не требуется.';
						|en = 'All products have already been released. Generation from base documents is not required.'; fa = 'All products have already been released. Generation from base documents is not required.';
						|it = 'Tutti i prodotti sono già stati emessi, l''inserimento in base alla causale non è richiesto.';
						|pl = 'Wszystkie wiersze pozycji są już wyprodukowane, wprowadzenie na podstawie nie jest wymagane.';
						|tr = 'Tüm ürünler zaten üretildi, temele dayalı giriş yapılması gerekmemektedir.'");
		Raise ErrorText;
	EndIf;
	If Attributes.NumberOfTaxOptions > 1 Then
		ErrorText = NStr("vi = 'Không thể hoàn thành một chứng từ vì Đơn đặt hàng được lựa chọn được phát hành cho các hoạt động Thuế GTGT khác nhau.';
						|ru = 'Невозможно оформить один документ, т.к. выбранные заказы оформлены под разную деятельность по НДС.';
						|en = 'Cannot register one document as the selected orders are registered for different activity on VAT.'; fa = 'Cannot register one document as the selected orders are registered for different activity on VAT.';
						|it = 'È impossibile formalizzare un documento, perché gli ordini selezionati sono formalizzati per le attività diverse per l''IVA.';
						|pl = 'Nie można wydać jednego dokumentu, ponieważ wybrane zamówienia są wydawane dla różnych czynności związanych z VAT.';
						|tr = 'Seçili siparişler, farklı KDV faaliyetleri kapsamında düzenlendiğinden dolayı tek belge düzenlemeniz mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	If Attributes.NumberOfActivities > 1 Then
		ErrorText = NStr("vi = 'Không thể tạo chứng từ vì đơn đặt hàng lựa chọn được lập cho các lĩnh vực kinh doanh khác nhau.';
						|ru = 'Невозможно оформить один документ, т.к. выбранные заказы оформлены под разные направления деятельности.';
						|en = 'Cannot register one document as the selected orders are registered for different lines of business.'; fa = 'Cannot register one document as the selected orders are registered for different lines of business.';
						|it = 'È impossibile formalizzare un documento, perché gli ordini selezionati sono formalizzati per i settori delle attività diversi.';
						|pl = 'Niemożliwe jest sporządzenie jednego dokumentu, ponieważ wybrane zamówienia są sporządzone dla różnych rodzajów działalności.';
						|tr = 'Seçili siparişler, farklı iş kolları kapsamında düzenlendiğinden dolayı tek belge düzenlemeniz mümkün değildir.'");
		Raise ErrorText;
	EndIf;
	
	FillPropertyValues(ThisObject, Attributes);
	
	Goods.Load(Result[Result.UBound()].Unload());
	
EndProcedure


Procedure CompleteProductReleaseBasedOnCustomerOrder(FillingData)
	
	SalesOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom) AS BusinessOperation,
		|	&SalesOrder AS DocumentBasis,
		|	SalesOrder.Organization AS Organization,
		|	SalesOrder.Warehouse AS Recipient,
		|	SalesOrder.VATTaxation AS ProductionIssueForActivity,
		|	CASE
		|		WHEN SalesOrder.LineOfBusiness.CostAccounting
		|			THEN SalesOrder.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref = &SalesOrder");
	
	Query.SetParameter("SalesOrder", SalesOrder);
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	FillPropertyValues(ThisObject, Attributes);
	
	Recipient = FillingData.Warehouse;
	
	// Filling in the tabular part.
	Goods.Load(GetFromTempStorage(FillingData.AddressGoods));
	DeleteFromTempStorage(FillingData.AddressGoods);
	
	For Each RowData In Goods Do
		RowData.AssignmentSender = RowData.Purpose;
	EndDo;
	
EndProcedure

Function DocumentBaseWhenFillingIn(FillingData)
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("ObjectsOfBases") Then
		
		Return FillingData.ObjectsOfBases[0];
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Goods")
		And TypeOf(FillingData.Goods) = Type("ValueTable")
		And FillingData.Goods.Columns.Find("ReferenceOrder") <> Undefined Then
		
		Return FillingData.Goods[0].ReferenceOrder;
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("AnArrayOfOrders") Then
		
		Return FillingData.AnArrayOfOrders[0];
		
	ElsIf TypeOf(FillingData) = Type("Array") Then
		
		Return FillingData[0];
		
	EndIf;
	
	Return Undefined;
	
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
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&InternalSubcontracting AS InternalSubcontracting,
	|	&MaterialProviderCompany AS MaterialProviderCompany,
	|	&Warehouse AS Warehouse,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Recipient
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Manager
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom)
	|			THEN &ProductionOfExcisableItemsIsUsed
	|		ELSE FALSE
	|	END AS SubjectToExcise,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfProductsFromStoreroom)
	|			THEN ISNULL(CatalogWarehouses.Department, VALUE(Catalog.BusinessStructure.EmptyRef))
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS BusinessUnitProduction,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON BusinessStructure.Ref = &Recipient
	|		
	|		LEFT JOIN Catalog.Warehouses AS CatalogWarehouses
	|		ON &Warehouse = CatalogWarehouses.Ref
	|
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	&InternalSubcontracting AS InternalSubcontracting,
	|	&MaterialProviderCompany AS MaterialProviderCompany,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose AS AssignmentRecipient,
	|	TableOfGoods.AssignmentSender AS Purpose,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatusSender AS BatchesIndicationStatus,
	|	TableOfGoods.BatchesIndicationStatusRecipient AS BatchesIndicationStatusRecipient,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE
	|		WHEN &PackagingUnitsInInventoryOwnerAttributes
	|			THEN TableOfGoods.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END										AS Package,
	|	CASE
	|		WHEN &PackagingUnitsInInventoryOwnerAttributes
	|			THEN TableOfGoods.NumberOfPackages
	|		ELSE 0
	|	END										AS NumberOfPackages,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END AS QuantityByGBRN,
	|	TableOfGoods.Sum AS Sum,
	|	TableOfGoods.RowID AS RowID,
	|	TableOfGoods.ReferenceOrder AS ReferenceOrder,
	|	TableOfGoods.RowCode AS RowCode,
	|	TableOfGoods.ProductsGroup,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.InternalSubcontracting AS InternalSubcontracting,
	|	TableOfGoods.MaterialProviderCompany AS MaterialProviderCompany,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.BatchesIndicationStatusRecipient,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.NumberOfPackages AS NumberOfPackages,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfGoods.Sum AS Sum,
	|	&Warehouse AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TableOfGoods.RowID AS RowID,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.AssignmentRecipient AS AssignmentRecipient,
	|	TableOfGoods.ProductsGroup,
	|	TableOfGoods.ReferenceOrder AS ReferenceOrder,
	|	TableOfGoods.RowCode AS RowCode,
	|	TRUE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Package AS Package,
	|	TableTypesOfStocks_.NumberOfPackages AS NumberOfPackages,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.Sum AS Sum,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	&Warehouse AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	TableTypesOfStocks_.Series,
	|	TableTypesOfStocks_.ProductsGroup,
	|	TableTypesOfStocks_.AssignmentRecipient,
	|	TableTypesOfStocks_.ReferenceOrder AS ReferenceOrder,
	|	TableTypesOfStocks_.RowCode AS RowCode,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Package AS Package,
	|	TableTypesOfStocks_.NumberOfPackages AS NumberOfPackages,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.Sum AS Sum,
	|	TableTypesOfStocks_.OriginWarehouse AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.SalesOpportunity AS SalesOpportunity,
	|	TableTypesOfStocks_.Series AS RecipientSeries,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.AssignmentRecipient AS AssignmentRecipient,
	|	TableTypesOfStocks_.ReferenceOrder AS ReferenceOrder,
	|	TableTypesOfStocks_.RowCode AS RowCode,
	|	TableTypesOfStocks_.ProductsGroup AS ProductsGroup
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes";
	
	ProductionOfExcisableItemsIsUsed = ExcisableGoodsAccounting.ProductionOfExcisableItemsIsUsed(
													Organization, Date);
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("InternalSubcontracting", InternalSubcontracting);
	Query.SetParameter("MaterialProviderCompany",    MaterialProviderCompany);
	Query.SetParameter("Warehouse", Sender);
	Query.SetParameter("Manager", EmployeeResponsible);
	Query.SetParameter("Recipient", Recipient);
	Query.SetParameter("ByReferences", ByReferences);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers", GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities", GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds.Unload());
	Query.SetParameter("PackagingUnitsInInventoryOwnerAttributes", PackagingUnitsInInventoryOwnerAttributes);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("ProductionOfExcisableItemsIsUsed", ProductionOfExcisableItemsIsUsed);
	
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

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date";
	AttributesNames = "Organization, Date, InternalSubcontracting, MaterialProviderCompany";
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager		= TemporaryDocumentDataTables();
	RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes(True);
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber", "Count, QuantityByGBRN");
		
		ControlOfFillingOfExcisableInventoryOwnerAttributes(Cancel);
		FillOutAnalyticsForAllTypesOfInventory(TempTablesManager, Cancel);
		
		If Not Cancel Then
			FillInRecipientSInventoryType();
		EndIf;
		
	EndIf;
	
EndProcedure

Function ParametersForFillingInventoryTypes(FillingStockTypes = False, WriteMode = Undefined)
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	If BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
		
		FillParameters.SelectionOfStockTypes_.InventoryType.Clear();
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
		
		FillParameters.WhenSelectingByIntercampanyExcludeOrganizations = CompanyRecipient;
		FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
		
	Else
		
		If BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
			
			FillParameters.ProductOwnerInHeader = Not FillingStockTypes;
			FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault =
				UserRightsCached.AllowRetroactiveReleaseRegistration();
			FillParameters.TableOfDetailsOfStockTypesByDefault = ?(FillingStockTypes,
																			TableOfDetailsOfStockTypesDefaultFilling(),
																			TableOfDetailsOfInventoryTypesByDefault());
			
		EndIf;
		
		If Not BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom
			And Not BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction Then
			FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
		EndIf;
		
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
		
		// We turn off the selection by intercampany because the transfer of products / materials by stage should be issued only from
		// the organization of the stage.
		If BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
			Or BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction Then
			
			If WriteMode = Undefined
				Or (WriteMode <> Undefined
					And WriteMode <> DocumentWriteMode.UndoPosting) Then
				FillParameters.SelectTypesOfStocksForIntercampany = False;
			EndIf;
			
		EndIf;
		If InternalSubcontracting
			And (BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction
				Or BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
				Or BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction) Then
			FillParameters.SelectionOfStockTypes_.MaterialProviderCompany = MaterialProviderCompany;
		EndIf;
		If GetFunctionalOption("UseExcisableGoods") Then
			FillParameters.SelectionOfStockTypes_.SubjectToExcise.Clear();
		EndIf;
		
	EndIf;
	
	FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
	FillParameters.ReversedDocument = ReversedDocument;
	
	Return FillParameters;
	
EndFunction

Function TableOfDetailsOfStockTypesDefaultFilling()
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	TableOfGoods.LineNumber                AS LineNumber,
		|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
		|	TableOfGoods.Purpose                 AS Purpose
		|INTO TTTableOfGoods
		|FROM
		|	&TableOfGoods AS TableOfGoods;
		|
		|SELECT
		|	TableOfGoods.LineNumber                    AS LineNumber,
		|	TableOfGoods.ItemsLocationAttributes     AS ItemsLocationAttributes,
		|	&Organization                                  AS Organization,
		|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
		|	VALUE(Catalog.CCDNumbers.EmptyRef)   AS CCDNumber,
		|	CASE
		|		WHEN CatAssignments.AssignmentType IN (
		|			VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
		|			VALUE(Enum.AssignmentTypes.Giveaway2_5))
		|			THEN CatAssignments.Partner
		|		WHEN TRUE
		|			THEN &Organization
		|	END                                         AS GoodsOwner,
		|	CASE
		|		WHEN CatAssignments.Contract IS NOT NULL
		|			THEN CatAssignments.Contract.Counterparty
		|		WHEN TRUE
		|			THEN VALUE(Catalog.Counterparties.EmptyRef)
		|	END                                         AS Counterparty,
		|	CatAssignments.Contract                         AS Contract,
		|	CASE
		|		WHEN CatAssignments.AssignmentType IN (
		|			VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
		|			VALUE(Enum.AssignmentTypes.Giveaway2_5))
		|			THEN VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
		|		WHEN TRUE
		|			THEN VALUE(Enum.InventoryTypes.OwnGoods)
		|	END                                         AS InventoryType
		|FROM
		|	TTTableOfGoods AS TableOfGoods
		|
		|	LEFT JOIN Catalog.Assignments AS CatAssignments
		|	ON CatAssignments.Ref = TableOfGoods.Purpose
		|";
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("TableOfGoods", Goods.Unload(, "LineNumber, ItemsLocationAttributes, Purpose"));
	
	Return Query.Execute().Unload();
	
EndFunction

Function TableOfDetailsOfInventoryTypesByDefault()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	&Organization									AS Organization,
	|	VALUE(Catalog.InventoryKinds.EmptyRef)	AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)		AS CCDNumber,
	|	CASE
	|		WHEN CatAssignments.AssignmentType IN (
	|			VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|			VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN CatAssignments.Partner
	|		WHEN TRUE
	|			THEN &Organization
	|	END											AS GoodsOwner,
	|	CASE
	|		WHEN CatAssignments.Contract IS NOT NULL
	|			THEN CatAssignments.Contract.Counterparty
	|		WHEN TRUE
	|			THEN UNDEFINED
	|	END											AS Counterparty,
	|	CatAssignments.Contract							AS Contract,
	|	CASE
	|		WHEN CatAssignments.AssignmentType IN (
	|			VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|			VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|			THEN VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		WHEN TRUE
	|			THEN VALUE(Enum.InventoryTypes.OwnGoods)
	|	END											AS InventoryType
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS TableOfGoods
	|
	|	LEFT JOIN Catalog.Assignments AS CatAssignments
	|	ON CatAssignments.Ref = TableOfGoods.Purpose
	|
	|WHERE
	|	TableOfGoods.Ref = &Ref
	|";
	
	Query.SetParameter("Ref",			Ref);
	Query.SetParameter("Organization",	Organization);
	
	Return InventoriesServer.TableOfDetailsOfInventoryTypesByDefaultRequest(Query);
	
EndFunction

Procedure FillInRecipientSInventoryType() Export
			
	Query = New Query;
	Query.Text =
	"SELECT
	|	Inventories.LineNumber AS LineNumber,
	|	Inventories.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Inventories.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Inventories.ProductsGroup AS ProductsGroup
	|INTO Inventories
	|FROM
	|	&InventoryKinds AS Inventories
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inventories.LineNumber AS LineNumber,
	|	CatInventoryKinds.Ref AS InventoryOwnerAttribute,
	|	&CompanyRecipient AS InventoryRecipientOrganization,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	UNDEFINED AS GoodsOwner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Terms,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS PriceKind,
	|	&VATTaxation AS VATTaxation,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	Keys.Products.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Inventories.ProductsGroup AS ProductsGroup,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier) AS BusinessTransactionStockType
	|FROM
	|	Inventories AS Inventories
	|		INNER JOIN Catalog.InventoryKinds AS CatInventoryKinds
	|		ON (CatInventoryKinds.Ref = Inventories.InventoryOwnerAttribute)
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|		ON (Keys.Ref = Inventories.ItemsLocationAttributes)
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices)
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("InventoryKinds", InventoryKinds.Unload(, "LineNumber, ItemsLocationAttributes, InventoryOwnerAttribute, ProductsGroup"));
	Query.SetParameter("TaxationOfOrganization", VATAccountingERP.AccountingParametersForOrganization(Organization, Date).BasicTaxationVATSales);
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("CompanyRecipient", CompanyRecipient);
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
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
		If Not ValueIsFilled(RecipientInventoryOwnerAttribute) Then
			
			StockAttributes = Common.ObjectAttributesValues(Inventory.InventoryOwnerAttribute, "SaleOfAnotherCompanyInventory, Organization");
			RecipientInventoryOwnerAttribute = ?(
				StockAttributes.SaleOfAnotherCompanyInventory,
				Catalogs.InventoryKinds.DocumentInventoryView(
					StockAttributes.Organization,,
					Inventory.InventoryOwnerAttribute),
				Inventory.InventoryOwnerAttribute);
		EndIf;
		Inventory.RecipientInventoryOwnerAttribute = RecipientInventoryOwnerAttribute;
	EndDo;
	
EndProcedure

Procedure FillOutAnalyticsForAllTypesOfInventory(TempTablesManager, Cancel)
	
	If Cancel Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes                AS ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributes.Products   AS Products,
	|	TableOfGoods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatusRecipient = 14
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                                                    AS Series,
	|	TableOfGoods.AssignmentRecipient                      AS AssignmentRecipient,
	|	ISNULL(TableOfGoods.AssignmentRecipient.AssignmentType,
	|		VALUE(Enum.AssignmentTypes.EmptyRef))  AS TypeOfDestinationCor,
	|	TableOfGoods.ProductsGroup                           AS ProductsGroup,
	|	TableOfGoods.ReferenceOrder                              AS ReferenceOrder,
	|	TableOfGoods.RowCode                                 AS RowCode,
	|	TableOfGoods.Package                                  AS Package,
	|	SUM(TableOfGoods.Count)                         AS Count,
	|	SUM(TableOfGoods.NumberOfPackages)                 AS NumberOfPackages,
	|	SUM(TableOfGoods.Sum)                              AS Sum
	|FROM
	|	TableOfGoods AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatusRecipient = 14
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	TableOfGoods.AssignmentRecipient,
	|	ISNULL(TableOfGoods.AssignmentRecipient.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)),
	|	TableOfGoods.ReferenceOrder,
	|	TableOfGoods.RowCode,
	|	TableOfGoods.ProductsGroup,
	|	TableOfGoods.Package
	|
	|ORDER BY
	|	ItemsLocationAttributes,
	|	Count DESC
	|";
	
	SampleProducts_ = Query.Execute().Select();
	
	FilterOfProducts_ = New Structure("ItemsLocationAttributes");
	
	InventoryTypes =
		Common.ObjectsAttributeValue(
			InventoryKinds.UnloadColumn("InventoryOwnerAttribute"),
			"InventoryType");
	
	While SampleProducts_.Next() Do
		
		GoodsQuantity         = SampleProducts_.Count;
		NumberOfPackagesOfGoods = SampleProducts_.NumberOfPackages;
		GoodsAmount              = SampleProducts_.Sum;
		
		FillPropertyValues(FilterOfProducts_, SampleProducts_);
		
		For Each InventoryLine In InventoryKinds.FindRows(FilterOfProducts_) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			FillPropertyValues(NewRow, SampleProducts_, "Series, ProductsGroup, AssignmentRecipient, ReferenceOrder, RowCode, Package");
			If BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
				And (InventoryTypes[NewRow.InventoryOwnerAttribute] = Enums.InventoryTypes.MaterialOfMaterialProvider
					Or InventoryTypes[NewRow.InventoryOwnerAttribute] = Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider
					Or InventoryTypes[NewRow.InventoryOwnerAttribute] = Enums.InventoryTypes.ProductsOfMaterialProvider)
				And Not SampleProducts_.TypeOfDestinationCor = Enums.AssignmentTypes.ProvidedMaterialsForStage22
				And Not SampleProducts_.TypeOfDestinationCor = Enums.AssignmentTypes.Giveaway2_5 Then
				
				ErrorText = NStr("vi = 'Việc tiết kiệm nguyên vật liệu gia công ""%1"" trong kho ""%2"" phải được tách biệt theo mục đích gia công. Cần đặt dấu hộp kiểm tương ứng trong dòng của phần bảng lệnh.';
								|ru = 'Экономия давальческого материала ""%1"" на склад ""%2"" должна обосабливаться под давальческое назначение. Необходимо установить соответствующее назначение в строке табличной части распоряжения.';
								|en = 'The savings of the ""%1"" material provided to the ""%2"" warehouse must be assigned for the provider assignment. Set the corresponding assignment in the reference table row.'; fa = 'The savings of the ""%1"" material provided to the ""%2"" warehouse must be assigned for the provider assignment. Set the corresponding assignment in the reference table row.';
								|it = 'Il risparmio di materiali del fornitore ""%1"" nel magazzino ""%2"" deve essere separato su assegnazione del fornitore. Impostare l''assegnazione corrispondente nella stringa della parte tabellare della disposizione.';
								|pl = 'Oszczędność materiału, dostarczanego przez właściciela surowców ""%1"" do magazynu ""%2"" powinna być oddzielana dla przeznaczenia powierzonego. Należy ustawić odpowiednie przeznaczenie w wierszu sekcji tabelarycznej zamówienia.';
								|tr = '""%2"" ambarına ""%1"" tedarikçi malzemesinden yapılan tasarruflar, tedarikçi ataması altında ayrılmalıdır. İlgili atamayı, talimatın tablo bölümü satırında yapılandırmanız gerekmektedir.'");
				ErrorText =
					StrTemplate(
						ErrorText,
						ProductsClientServer.ProductPresentation(
							SampleProducts_.Products,
							SampleProducts_.Characteristic,,
							SampleProducts_.Series),
						Recipient);
				
				Common.MessageToUser(ErrorText, SampleProducts_.ReferenceOrder, "UnusedMaterials",, Cancel);
				
				Continue;
				
			EndIf;
			NewRow.Count			= Count;
			NewRow.QuantityByGBRN	= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			NewRow.NumberOfPackages	= Count * NumberOfPackagesOfGoods / GoodsQuantity;
			NewRow.Sum				= Count * GoodsAmount / GoodsQuantity;
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			NumberOfPackagesOfGoods = NumberOfPackagesOfGoods - NewRow.NumberOfPackages;
			GoodsAmount = GoodsAmount - NewRow.Sum;
			
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

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.MovementOfProductsAndMaterials.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.MovementOfProductsAndMaterials.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Sender,
																		Recipient,
																		Undefined);
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Insert("BatchesIndicationStatus", "BatchesIndicationStatusSender");
	FieldsNames.Insert("Purpose", "AssignmentSender");
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

Procedure ControlOfFillingOfExcisableInventoryOwnerAttributes(Cancel)
	
	If Cancel
		Or TypeOf(Recipient) = Type("CatalogRef.BusinessStructure")
		Or Not GetFunctionalOption("UseExcisableGoods") Then
		
		Return;
		
	EndIf;
	
	WarehouseStore = Common.ObjectAttributeValue(Recipient, "WarehouseStore");
	
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

#EndRegion

#Region FillChecking

Procedure CheckHeaderDetails_(FieldsPresentation, Cancel)

	If Not ValueIsFilled(Sender) Then
		MessageText = StrTemplate(NStr("vi = 'Trường ""%1"" chưa điền';
										|ru = 'Поле ""%1"" не заполнено';
										|en = '""%1"" is required'; fa = '""%1"" is required';
										|it = 'Il campo ""%1"" non è compilato';
										|pl = 'Pole ""%1"" nie jest wypełnione';
										|tr = '""%1"" alanı doldurulmadı'"), FieldsPresentation.Sender);
		CommonClientServer.MessageToUser(MessageText, ThisObject, "Sender",, Cancel); 
	EndIf; 
	If Not ValueIsFilled(Recipient) Then
		MessageText = StrTemplate(NStr("vi = 'Trường ""%1"" chưa điền';
										|ru = 'Поле ""%1"" не заполнено';
										|en = '""%1"" is required'; fa = '""%1"" is required';
										|it = 'Il campo ""%1"" non è compilato';
										|pl = 'Pole ""%1"" nie jest wypełnione';
										|tr = '""%1"" alanı doldurulmadı'"), FieldsPresentation.Recipient);
		CommonClientServer.MessageToUser(MessageText, ThisObject, "Recipient",, Cancel); 
	EndIf; 
	If Goods.Count() = 0 Then
		MessageText = StrTemplate(NStr("vi = 'Không có hàng nào được nhập trong danh sách ""%1""';
										|ru = 'Не введено ни одной строки в список ""%1""';
										|en = 'No line is entered into the ""%1"" list'; fa = 'No line is entered into the ""%1"" list';
										|it = 'Non è immessa alcuna riga nell''elenco ""%1""';
										|pl = 'Nie wprowadzono żadnego wiersza do listy ""%1""';
										|tr = '""%1"" listesine herhangi satır girilmedi'"), FieldsPresentation.Goods);
		CommonClientServer.MessageToUser(MessageText, ThisObject, "Goods",, Cancel); 
	EndIf;
	
	If Sender = Recipient And ValueIsFilled(Sender)
		And Not BusinessOperation = Enums.BusinessTransactions.TransferOfSemiFinishedProductsBetweenBranchOffices Then
		If FieldsPresentation.SenderType = "Warehouse" 
				And FieldsPresentation.TypeRecipient = "Storeroom"
			Or FieldsPresentation.SenderType = "Storeroom" 
				And FieldsPresentation.TypeRecipient = "Warehouse" Then
			MessageText = NStr("vi = 'Kho bãi và kho ở xưởng nên khác nhau';
								|ru = 'Склад и цеховая кладовая должны быть разными';
								|en = 'Warehouse and shop floor stockroom must be different'; fa = 'Warehouse and shop floor stockroom must be different';
								|it = 'Il magazzino e il deposito del reparto devono differire';
								|pl = 'Magazyn i magazyn spiżarni powinni różnić się';
								|tr = 'Ambar ve atölye deposu farklı olmalıdır'");
		Else
			MessageText = NStr("vi = 'Người gửi và người nhận phải khác nhau';
								|ru = 'Отправитель и получатель должны быть разными';
								|en = 'Sender and recipient should be different'; fa = 'Sender and recipient should be different';
								|it = 'Il mittente e il destinatario devono differire';
								|pl = 'Nadawcy i odbiorca powinny różnić się';
								|tr = 'Gönderici ve alıcı farklı olmalıdır'");
		EndIf;
		Common.MessageToUser(MessageText, ThisObject, "Sender",, Cancel); 
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
		PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject,Cancel);
	EndIf;
	If InternalSubcontracting Then
		
		If ValueIsFilled(MaterialProviderCompany)
			And MaterialProviderCompany = Organization Then
			
			MessageText = NStr("vi = 'Doanh nghiệp-người đặt gia công trùng với doanh nghiệp=người nhận gia công.';
								|ru = 'Организация-давалец совпадает с организацией-переработчиком.';
								|en = 'Material provider company and the subcontractor company are the same.'; fa = 'Material provider company and the subcontractor company are the same.';
								|it = 'Организация-давалец совпадает с организацией-переработчиком.';
								|pl = 'Material provider company and the subcontractor company are the same.';
								|tr = 'Tedarikçi iş yeri, fason üretici iş yeri ile aynıdır.'");
			Common.MessageToUser(MessageText, ThisObject, "MaterialProviderCompany",, Cancel);
			
		EndIf;
	
		If ValueIsFilled(MaterialProviderCompany)
			And Not MaterialProviderCompany = Organization
			And Catalogs.Companies.OrganizationsAreInterconnectedByOrganizationalStructure(Organization, MaterialProviderCompany) Then
			
			MessageText = NStr("vi = 'Doanh nghiệp đặt gia công không được phép có quan hệ với doanh nghiệp nhận gia công theo cấu trúc tổ chức.';
								|ru = 'Организация-давалец не должна быть взаимосвязана с организацией-переработчиком по организационной структуре.';
								|en = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.'; fa = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.';
								|it = 'Организация-давалец не должна быть взаимосвязана с организацией-переработчиком по организационной структуре.';
								|pl = 'Material provider company must not be interrelated to the subcontractor company by the organizational structure.';
								|tr = 'Tedarikçi iş yeri, iş yeri yapısı bakımından fason üretici iş yeri ile bağlantılı olmamalıdır.'");
			Common.MessageToUser(MessageText, ThisObject, "MaterialProviderCompany",, Cancel);
			
		EndIf;
		
		CheckStructure = Catalogs.Companies.CountriesOfRegistrationAndCurrenciesOfRegulatedAccountingCoincide(Organization, MaterialProviderCompany);
		
		If Not CheckStructure.CurrenciesDoNotMatch Then
			ErrorText = NStr("vi = 'Tiền tệ của kế toán tài chính ""%1"" và ""%2"" cần trùng nhau.';
							|ru = 'Валюты регламентированного учета ""%1"" и ""%2"" должны совпадать.';
							|en = 'The %1 and %2 local accounting currencies must be the same.'; fa = 'The %1 and %2 local accounting currencies must be the same.';
							|it = 'Валюты регламентированного учета ""%1"" и ""%2"" должны совпадать.';
							|pl = 'The %1 and %2 local accounting currencies must be the same.';
							|tr = '""%1"" ve ""%2"" yerel muhasebe para birimleri eşleşmelidir.'");
			ErrorText = StrTemplate(ErrorText, Organization, MaterialProviderCompany);
			Common.MessageToUser(ErrorText, ThisObject, "MaterialProviderCompany",, Cancel);
		EndIf;
		
		If Not CheckStructure.CountriesMatch Then
			ErrorText = NStr("vi = 'Trang đăng ký ""%1"" và ""%2"" cần trùng nhau.';
							|ru = 'Страны регистрации ""%1"" и ""%2"" должны совпадать.';
							|en = 'The %1 and %2 countries of residence must be the same.'; fa = 'The %1 and %2 countries of residence must be the same.';
							|it = 'Страны регистрации ""%1"" и ""%2"" должны совпадать.';
							|pl = 'The %1 and %2 countries of residence must be the same.';
							|tr = '""%1"" ve ""%2"" kayıt ülkeleri eşleşmelidir.'");
			ErrorText = StrTemplate(ErrorText, Organization, MaterialProviderCompany);
			Common.MessageToUser(ErrorText, ThisObject, "MaterialProviderCompany",, Cancel);
		EndIf;
		
	EndIf;
EndProcedure

Procedure CheckProducts(FieldsPresentation, Cancel)
	
	CheckLineCode = ByReferences
		And (BusinessOperation = Enums.BusinessTransactions.TransferOfProductsFromProduction
			Or BusinessOperation = Enums.BusinessTransactions.ReturnOfMaterialsFromProduction
			Or BusinessOperation = Enums.BusinessTransactions.MaterialTransferToProduction);
	
	MessageTemplate = NStr("vi = 'Không được phép vượt quá số lượng hàng hóa theo kế hoạch cho kỳ trong dòng %1 của danh sách ""%2"".';
							|ru = 'Не допускается превышение запланированного количества товара по этапу в строке %1 списка ""%2"".';
							|en = 'Cannot exceed the planned goods quantity for the stage in line %1 of the ""%2"" list.'; fa = 'Cannot exceed the planned goods quantity for the stage in line %1 of the ""%2"" list.';
							|it = 'Non è consentito superare la quantità di merci pianificata per la fase nella riga %1 dell''elenco ""%2"".';
							|pl = 'Nie jest dopuszczalne przekroczenie zaplanowanej ilości towaru według etapu w wierszu %1 listy ""%2"".';
							|tr = '""%2"" listesinin %1 satırındaki aşamaya göre planlanan ürün miktarının aşılmasına izin verilmemektedir.'");
	MessageTemplateEmptyOrder = NStr("vi = 'Đơn hàng không được điền vào dòng %1 của danh sách ""%2"".';
									|ru = 'В строке %1 списка ""%2"" не заполнено распоряжение.';
									|en = 'Reference in line %1 of list ""%2"" is not filled in.'; fa = 'Reference in line %1 of list ""%2"" is not filled in.';
									|it = 'Nella riga %1 dell''elenco ""%2"" la disposizione non è compilata.';
									|pl = 'W wierszu %1 listy ""%2"" nie wypełniono zamówienia.';
									|tr = '""%2"" listesinin %1 satırında sipariş doldurulmadı.'");
	
	For Each RowData In Goods Do
		
		If CheckLineCode
			And RowData.RowCode = 0
			And ValueIsFilled(RowData.ReferenceOrder) Then
			
			MessageText = StrTemplate(MessageTemplate, Format(RowData.LineNumber, "NG="), FieldsPresentation.Goods);
			Field = CommonClientServer.PathToTabularSection("Goods", RowData.LineNumber, "Products");
			CommonClientServer.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If ByReferences
			And Not ValueIsFilled(ReferenceOrder)
			And Not ValueIsFilled(RowData.ReferenceOrder) Then
			
			MessageText = StrTemplate(MessageTemplateEmptyOrder, Format(RowData.LineNumber, "NG="), FieldsPresentation.Goods);
			Field = CommonClientServer.PathToTabularSection("Goods", RowData.LineNumber, "ReferenceOrder");
			CommonClientServer.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckComplianceOfInvoiceAndStages(SynonymForTablePart, Cancel)
	
	Query = New Query();
	Query.Text =
		"SELECT
		|	LinesAndParts.ReferenceOrder AS ReferenceOrder,
		|	LinesAndParts.LineNumber  AS LineNumber
		|INTO TTLinesAndParts
		|FROM
		|	&LinesAndParts AS LinesAndParts
		|
		|INDEX BY
		|	ReferenceOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	LinesAndParts.LineNumber                                         AS LineNumber,
		|	REFPRESENTATION(LinesAndParts.ReferenceOrder)                   AS ReferenceOrder,
		|	REFPRESENTATION(MAX(ProductionStage.MaterialProviderCompany)) AS MaterialProviderCompany,
		|	MAX(NOT ProductionStage.InternalSubcontracting = &InternalSubcontracting) AS ErrorInternalProcessing,
		|	MAX(NOT ProductionStage.MaterialProviderCompany = &MaterialProviderCompany)       AS ErrorCompanyGiver
		|FROM
		|	TTLinesAndParts AS LinesAndParts
		|	
		|	INNER JOIN Document.ProductionStage2_2 AS ProductionStage
		|	ON ProductionStage.Ref = LinesAndParts.ReferenceOrder
		|
		|WHERE
		|	&InternalSubcontracting
		|		AND NOT ProductionStage.InternalSubcontracting
		|	OR NOT &MaterialProviderCompany = VALUE(Catalog.Companies.EmptyRef)
		|		AND NOT ProductionStage.MaterialProviderCompany = &MaterialProviderCompany
		|
		|GROUP BY
		|	LinesAndParts.LineNumber,
		|	LinesAndParts.ReferenceOrder
		|";
	
	Query.SetParameter("InternalSubcontracting", InternalSubcontracting);
	Query.SetParameter("MaterialProviderCompany",    MaterialProviderCompany);
	Query.SetParameter("LinesAndParts",        Goods.Unload(, "LineNumber, ReferenceOrder"));
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		Field = CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "ReferenceOrder");
		
		If Selection.ErrorInternalProcessing Then
			
			MessageTemplate = NStr("vi = 'Hộp kiểm gia công nội bộ của chứng từ không tương ứng với lệnh ""%1"" trong dòng ""%2"" của danh sách ""%3"".';
									|ru = 'Флаг внутренней переработки документа не соотвествует распоряжению ""%1"" в строке ""%2"" списка ""%3"".';
									|en = 'The internal document subcontracting flag does not correspond to the ""%1"" reference in line %2 of the ""%3"" list.'; fa = 'The internal document subcontracting flag does not correspond to the ""%1"" reference in line %2 of the ""%3"" list.';
									|it = 'Флаг внутренней переработки документа не соотвествует распоряжению ""%1"" в строке ""%2"" списка ""%3"".';
									|pl = 'The internal document subcontracting flag does not correspond to the ""%1"" reference in line %2 of the ""%3"" list.';
									|tr = 'Dahili belge işleme onay kutusu, ""%3"" listesinin ""%2"" satırındaki ""%1"" talimatı ile uyuşmamaktadır.'");
			
			MessageText = StrTemplate(
				MessageTemplate,
				Selection.ReferenceOrder,
				Format(Selection.LineNumber, "NG="),
				SynonymForTablePart);
				
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
		If Selection.ErrorCompanyGiver Then
			
			MessageTemplate = NStr("vi = 'Doanh nghiệp-người đặt gia công chứng từ ""%1"" không tương ứng với doanh nghiệp-người đặt gia công ""%2"" mà được chỉ ra trong lệnh ""%3"" trong dòng ""%4"" của danh sách ""%5"".';
									|ru = 'Организация-давалец документа ""%1"" не соотвествует организации-давальцу ""%2"", указанной в распоряжении ""%3"" в строке ""%4"" списка ""%5"".';
									|en = 'The material provider company of the ""%1"" document does not correspond to the ""%2"" material provider company specified in the ""%3"" reference in line %4 of the ""%5"" list.'; fa = 'The material provider company of the ""%1"" document does not correspond to the ""%2"" material provider company specified in the ""%3"" reference in line %4 of the ""%5"" list.';
									|it = 'Организация-давалец документа ""%1"" не соотвествует организации-давальцу ""%2"", указанной в распоряжении ""%3"" в строке ""%4"" списка ""%5"".';
									|pl = 'The material provider company of the ""%1"" document does not correspond to the ""%2"" material provider company specified in the ""%3"" reference in line %4 of the ""%5"" list.';
									|tr = '""%5"" listesinin ""%4"" satırında ""%3"" belirtilen talimatındaki ""%2"" tedarikçi iş yeri, ""%1"" belgesinin tedarikçi iş yeri ile uyuşmamaktadır.'");
			
			MessageText = StrTemplate(
				MessageTemplate,
				MaterialProviderCompany,
				Selection.MaterialProviderCompany,
				Selection.ReferenceOrder,
				Format(Selection.LineNumber, "NG="),
				SynonymForTablePart);
				
			Common.MessageToUser(MessageText, ThisObject, Field, "", Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure
Procedure DisableCheckingForFillingInBusinessTransaction(NotCheckedAttributeArray)

	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.MovementOfProductsAndMaterials.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	For Each ArrayElement In ArrayOfAllProps Do
		
		// If the account details are not used for a business transaction, we exclude this account from verification.
		If ArrayOfOperationDetails.Find(ArrayElement) = Undefined Then
			NotCheckedAttributeArray.Add(ArrayElement);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckCorrectnessOfIndicationOfExcisableItems(Cancel)
	
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	
	If Not UseExcisableGoods
		Or BusinessOperation <> Enums.BusinessTransactions.TransferOfProductsFromStoreroom Then
		
		Return;
		
	EndIf;
	
	QueryTexts = New Array;
	
	PartOfTheRequestText = 
	"SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	TableOfGoods.Purpose	AS Purpose,
	|	TableOfGoods.Products	AS Products
	|INTO TTTableOfGoods
	|FROM
	|	&Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber	AS LineNumber,
	|	TableOfGoods.Products	AS Products
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.Assignments AS CatalogAssignments
	|		ON TableOfGoods.Purpose = CatalogAssignments.Ref
	|
	|WHERE
	|	CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND NOT (ISNULL(CatalogAssignments.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) IN (
	|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
	|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
	|	)
	|
	|INDEX BY
	|	Products";
	QueryTexts.Add(PartOfTheRequestText);
	QueryTexts.Add(ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems());
	
	PartOfTheRequestText = 
	"SELECT
	|	ErrorsTable.LineNumber						AS LineNumber,
	|	ErrorsTable.ExcisableItemIsSpecified			AS ExcisableItemIsSpecified,
	|	ErrorsTable.SenderRetailWarehouseIsSpecified	AS SenderRetailWarehouseIsSpecified,
	|	ErrorsTable.RecipientRetailWarehouseIsSpecified	AS RecipientRetailWarehouseIsSpecified
	|FROM
	|	(SELECT
	|		TableOfGoods.LineNumber	AS LineNumber,
	|		CASE
	|			WHEN NOT &ProductionOfExcisableItemsIsUsed
	|					AND ISNULL(Category_Data.ExcisableGoods, FALSE)
	|				THEN TRUE
	|			ELSE FALSE
	|		END						AS ExcisableItemIsSpecified,
	|		CASE
	|			WHEN &ProductionOfExcisableItemsIsUsed
	|					AND ISNULL(Category_Data.ExcisableGoods, FALSE)
	|					AND ISNULL(CatalogWarehousesSender.WarehouseStore, UNDEFINED) = VALUE(Enum.TypesOfWarehouses.RetailStore)
	|				THEN TRUE
	|			ELSE FALSE
	|		END						AS SenderRetailWarehouseIsSpecified,
	|		CASE
	|			WHEN &ProductionOfExcisableItemsIsUsed
	|					AND ISNULL(Category_Data.ExcisableGoods, FALSE)
	|					AND ISNULL(CatalogWarehousesRecipient.WarehouseStore, UNDEFINED) = VALUE(Enum.TypesOfWarehouses.RetailStore)
	|				THEN TRUE
	|			ELSE FALSE
	|		END						AS RecipientRetailWarehouseIsSpecified
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|			LEFT JOIN TTExciseCategoriesOfItems AS Category_Data
	|			ON TableOfGoods.Products = Category_Data.Products
	|			
	|			LEFT JOIN Catalog.Warehouses AS CatalogWarehousesSender
	|			ON &Sender = CatalogWarehousesSender.Ref
	|			
	|			LEFT JOIN Catalog.Warehouses AS CatalogWarehousesRecipient
	|			ON &Recipient = CatalogWarehousesRecipient.Ref
	|	
	|	) AS ErrorsTable
	|
	|WHERE
	|	(ErrorsTable.ExcisableItemIsSpecified
	|		OR ErrorsTable.SenderRetailWarehouseIsSpecified
	|		OR ErrorsTable.RecipientRetailWarehouseIsSpecified
	|	)
	|
	|ORDER BY
	|	LineNumber";
	QueryTexts.Add(PartOfTheRequestText);
	
	UnloadedColumns =
		"LineNumber,
		|Purpose,
		|Products";
	
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization);
	ProductionOfExcisableItemsIsUsed = ExcisableGoodsAccounting.ProductionOfExcisableItemsIsUsed(
													Organization, Date);
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Date",			Date);
	Query.SetParameter("Organization",	Organization);
	Query.SetParameter("Country",			RegistrationCountry);
	Query.SetParameter("Sender",	Sender);
	Query.SetParameter("Recipient",		Recipient);
	Query.SetParameter("Goods",			Goods.Unload(, UnloadedColumns));
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	Query.SetParameter("ProductionOfExcisableItemsIsUsed", ProductionOfExcisableItemsIsUsed);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	MessageTemplateIndicatesExcisableItem = NStr("vi = 'Trong dòng %1 danh sách ""Sản phẩm"" có chỉ định sản phẩm chịu thuế TTĐB.
		|Cấm chọn mặt hàng này, vì chính sách kế toán tài chính của doanh nghiệp ""%2"" không cho phép sản xuất sản phẩm chịu thuế TTĐB.';
		|ru = 'В строке %1 списка ""Продукция"" указана подакцизная продукция.
		|Выбор такой номенклатуры запрещен, так как учетная политика финансового учета организации ""%2"" не предусматривает производство подакцизной продукции.';
		|en = 'Excisable products are specified in line %1 of the ""Manufactured products"" list.
		|Cannot select this item, as the financial accounting policy of the ""%2"" company does not allow producing excisable products.'; fa = 'Excisable products are specified in line %1 of the ""Manufactured products"" list.
		|Cannot select this item, as the financial accounting policy of the ""%2"" company does not allow producing excisable products.';
		|it = 'Excisable products are specified in line %1 of the ""Manufactured products"" list.
		|Cannot select this item, as the financial accounting policy of the ""%2"" company does not allow producing excisable products.';
		|pl = 'Excisable products are specified in line %1 of the ""Manufactured products"" list.
		|Cannot select this item, as the financial accounting policy of the ""%2"" company does not allow producing excisable products.';
		|tr = '""İmal edilen ürünler"" listesinin %1 satırında tüketim vergisine tabi imal edilen ürünler belirtildi.
		|""%2"" iş yerinin mali muhasebe bölümünün muhasebe politikasında tüketim vergisine tabi ürünlerin üretimi öngörülmediğinden, bu tür bir öğenin seçilmesi yasaktır.'");
	
	MessageTemplateIndicatesRetailPantry = NStr("vi = 'Trong dòng %1 danh sách ""Sản phẩm"" có chỉ định hàng hóa chịu thuế TTĐB.
		|Cấm xuất xưởng sản phẩm chịu thuế TTĐB vào kho bán lẻ.';
		|ru = 'В строке %1 списка ""Продукция"" указан подакцизный товар.
		|Выпуск подакцизной продукции на розничный склад запрещен.';
		|en = 'Excisable goods are specified in line %1 of the ""Manufactured products"" list.
		|Cannot release excisable goods to a retail warehouse.'; fa = 'Excisable goods are specified in line %1 of the ""Manufactured products"" list.
		|Cannot release excisable goods to a retail warehouse.';
		|it = 'Excisable goods are specified in line %1 of the ""Manufactured products"" list.
		|Cannot release excisable goods to a retail warehouse.';
		|pl = 'Excisable goods are specified in line %1 of the ""Manufactured products"" list.
		|Cannot release excisable goods to a retail warehouse.';
		|tr = '""İmal edilen ürünler"" listesinin %1 satırında tüketim vergisine tabi ürün belirtildi.
		|Tüketim vergisine tabi imal edilen ürünlerin perakende ambarına verilmesi yasaktır.'");
	
	MessageTemplateIndicatesRetailWarehouse = NStr("vi = 'Trong dòng %1 danh sách ""Sản phẩm"" có chỉ định hàng hóa chịu thuế TTĐB.
		|Cấm chuyển hàng hóa chịu thuế TTĐB vào kho bán lẻ.';
		|ru = 'В строке %1 списка ""Продукция"" указан подакцизный товар.
		|Запрещена передача подакцизной продукции на розничные склады.';
		|en = 'Excisable goods are specified in line %1 of the ""Manufactured products"" list.
		|Cannot transfer excisable goods to retail warehouses.'; fa = 'Excisable goods are specified in line %1 of the ""Manufactured products"" list.
		|Cannot transfer excisable goods to retail warehouses.';
		|it = 'Excisable goods are specified in line %1 of the ""Manufactured products"" list.
		|Cannot transfer excisable goods to retail warehouses.';
		|pl = 'Excisable goods are specified in line %1 of the ""Manufactured products"" list.
		|Cannot transfer excisable goods to retail warehouses.';
		|tr = '""İmal edilen ürünler"" listesinin %1 satırında tüketim vergisine tabi ürün belirtildi.
		|Tüketim vergisine tabi imal edilen ürünlerin perakende ambarlarına taşınması yasaktır.'");
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		FieldName			= "Products";
		MessageText	= "";
		
		If Selection.ExcisableItemIsSpecified Then
			MessageText	= StrTemplate(MessageTemplateIndicatesExcisableItem,
										Selection.LineNumber,
										Organization);
		ElsIf Selection.SenderRetailWarehouseIsSpecified Then
			MessageText	= StrTemplate(MessageTemplateIndicatesRetailPantry,
										Selection.LineNumber);
		ElsIf Selection.RecipientRetailWarehouseIsSpecified Then
			MessageText	= StrTemplate(MessageTemplateIndicatesRetailWarehouse,
										Selection.LineNumber);
		EndIf;
		
		If Not IsBlankString(MessageText) Then
			Field = CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, FieldName);
			
			Common.MessageToUser(MessageText, ThisObject , Field, "", Cancel);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

// Parameters:
// 	Table - See AccessManagement.AccessValuesSetsTable
//
Procedure FillAccessValuesSets(Table) Export
	
	TabRow = Table.Add();
	TabRow.AccessValue = Organization;
	
	TabRow = Table.Add();
	TabRow.AccessValue = Sender;
	
	TabRow = Table.Add();
	TabRow.AccessValue = Recipient;
	
EndProcedure

// The function checks for changes in the "Products" table part relative to the "inventory Types" table part of the document.
//
// Parameters:
//	TempTablesManager - TempTablesManager
//
// Returns:
//	Boolean - The truth is that the goods have been changed
//           False - the products are not changed.
//
Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.Purpose AS Purpose,
	|		TableOfGoods.ProductsGroup AS ProductsGroup,
	|		TableOfGoods.ReferenceOrder AS ReferenceOrder,
	|		TableOfGoods.RowCode AS RowCode,
	|		TableOfGoods.Package AS Package,
	|		(CASE TableOfGoods.BatchesIndicationStatusRecipient
	|			WHEN 14 THEN TableOfGoods.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef) END) AS Series,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.NumberOfPackages AS NumberOfPackages,
	|		TableOfGoods.Sum AS Sum
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
	|		TableTypesOfStocks_.ProductsGroup AS ProductsGroup,
	|		TableTypesOfStocks_.ReferenceOrder AS ReferenceOrder,
	|		TableTypesOfStocks_.RowCode AS RowCode,
	|		TableTypesOfStocks_.Package AS Package,
	|		TableTypesOfStocks_.RecipientSeries AS Series,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.NumberOfPackages AS NumberOfPackages,
	|		-TableTypesOfStocks_.Sum AS Sum
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Purpose,
	|	TableOfGoods.ProductsGroup,
	|	TableOfGoods.ReferenceOrder,
	|	TableOfGoods.RowCode,
	|	TableOfGoods.Package,
	|	TableOfGoods.Series
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.NumberOfPackages) <> 0
	|	OR SUM(TableOfGoods.Sum) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
