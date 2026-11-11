#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function generates temporary document data
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	&Date					AS Date,
	|	&Organization			AS Organization,
	|	&CompanyRecipient	AS CompanyRecipient,
	|	&Department			AS Department,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	UNDEFINED			AS VATTaxation,
	|	&BusinessOperation	AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.Work_5) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Purpose					AS Purpose,
	|	0											AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.ProductsGroup				AS ProductsGroup,
	|	TableOfGoods.Department				AS ReceivingBusinessUnit,
	|	TableOfGoods.Count					AS Count,
	|	&FieldTextTableOfGoodsQuantityByGBRN_	AS QuantityByGBRN,
	|	0											AS AmountIncludingVAT,
	|	0											AS VATAmount,
	|	0											AS CommissionAmount,
	|	0											AS AmountVATRemuneration,
	|	&FieldTextTableOfGoodsCCDNumber_			AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	UNDEFINED								AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.ProductsGroup				AS ProductsGroup,
	|	TableOfGoods.ReceivingBusinessUnit		AS ReceivingBusinessUnit,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.QuantityByGBRN				AS QuantityByGBRN,
	|	Dimension.StorageLocation						AS Warehouse,
	|	VALUE(Catalog.VATRates.EmptyRef)	AS VATRate,
	|	TableOfGoods.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						AS VATAmount,
	|	TableOfGoods.CommissionAmount			AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration		AS AmountVATRemuneration,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TRUE										AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber						AS CCDNumber
	|INTO TableOfGoods
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
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ProductsGroup				AS ProductsGroup,
	|	TableTypesOfStocks_.ReceivingBusinessUnit		AS ReceivingBusinessUnit,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	VALUE(Catalog.Warehouses.EmptyRef)		AS OriginWarehouse,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	0												AS AmountIncludingVAT,
	|	0												AS VATAmount
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	TableTypesOfStocks_.ProductsGroup				AS ProductsGroup,
	|	TableTypesOfStocks_.ReceivingBusinessUnit		AS ReceivingBusinessUnit,
	|	UNDEFINED									AS SetAccountingDimension,
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic						AS Characteristic,
	|	Dimension.Series									AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	VALUE(Catalog.VATRates.EmptyRef)		AS VATRate,
	|	TableTypesOfStocks_.OriginWarehouse				AS OriginWarehouse,
	|	Dimension.StorageLocation							AS Warehouse,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount						AS VATAmount,
	|	&InventoryOwnerAttributesAreSpecifiedManually						AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTTypesOfStocks";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("CompanyRecipient", CompanyRecipient);
	Query.SetParameter("Department", Department);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("TableOfGoods", Goods);
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		Goods,
		Query.Text,
		"&FieldTextTableOfGoodsQuantityByGBRN_",
		"TableOfGoods",
		"QuantityByGBRN",
		"TableOfGoods.QuantityByGBRN",
		"0");
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		Goods,
		Query.Text,
		"&FieldTextTableOfGoodsCCDNumber_",
		"TableOfGoods",
		"CCDNumber",
		"TableOfGoods.CCDNumber",
		"VALUE(Catalog.CCDNumbers.EmptyRef)");
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.InternalAcceptanceCertificate - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes);
	
EndProcedure

// Fills in the Attributes that store information about the Inventory owner attributes and analytics of inventory items in the tabular part of the 'Services'
// document, and also fills in the tabular part of the 'Inventory types'.
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.InternalAcceptanceCertificate.CollectionOfTabularPartsOfGoods.
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
	
	Status = Enums.StatusesOfInternalAcceptanceCertificate[NewStatus];
	
	Return CheckFilling();
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not GetFunctionalOption("UseStatusesOfInternalWorksAcceptance")
		And Not ValueIsFilled(Status) Then
		Status = Enums.StatusesOfInternalAcceptanceCertificate.Accepted;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	InternalAcceptanceCertificateLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	InternalAcceptanceCertificateLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods");
	
	InternalAcceptanceCertificateLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		FillPropertyValues(ThisObject, FillingData);
		If FillingData.Property("HeaderAttributes") Then
			FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
		EndIf;
		
		If FillingData.Property("ObjectsOfBases") Then
			
			FillInByMapItems(FillingData.ObjectsOfBases);
			
			If FillingData.ObjectsOfBases.Count() = 1 Then
				DocumentBasis = FillingData.ObjectsOfBases[0];
			EndIf;
			
		EndIf;
		
		If FillingData.Property("Goods") Then
			For Each CurRow In FillingData.Goods Do
				FillPropertyValues(Goods.Add(), CurRow);
			EndDo;
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	InitializeDocument();
	
	InternalAcceptanceCertificateLocalization.Filling(ThisObject, FillingData, FillingText, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	#Region CheckingCharacteristics
	
	ParametersForCheckingCharacteristics = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, ParametersForCheckingCharacteristics);
	
	#EndRegion
	
	#Region VerifyingRecipients
	
	CheckRecipients(Cancel);
	
	#EndRegion
	
	If Not BusinessOperation = Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices Then
		NotCheckedAttributeArray.Add("CompanyRecipient");
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	InternalAcceptanceCertificateLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	InternalAcceptanceCertificateLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	InternalAcceptanceCertificateLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument()
	
	Date          = CurrentSessionDate();
	Organization   = SettingsValueCached.GetDefaultOrganization(Organization);
	EmployeeResponsible = Users.CurrentUser();
	
	If GetFunctionalOption("UseStatusesOfInternalWorksAcceptance") Then
		Status = Enums.StatusesOfInternalAcceptanceCertificate.Issued;
	Else
		Status = Enums.StatusesOfInternalAcceptanceCertificate.Accepted;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBranchOffices Then
		CompanyRecipient = SettingsValueCached.GetDefaultOrganization(CompanyRecipient);
	EndIf;
	
	FillParameters = Documents.InternalAcceptanceCertificate.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(TransferForActivity, FillParameters);
	
EndProcedure

Procedure FillInByMapItems(ObjectsOfBases)
	
	Query = New Query;
	Query.Text =
	// Recipients of output products (production without an order)
	"SELECT
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic,
	|	TableOfGoods.Purpose			AS Purpose,
	|	TableOfGoods.Count			AS Count
	|INTO TTProducts_1
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON TableOfGoods.Products = CatProducts.Ref
	|WHERE
	|	TableOfGoods.Ref IN(&ObjectsOfBases)
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND TableOfGoods.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)
	|
	|UNION ALL
	|
	// Recipients of by-products (production without an order)
	|SELECT
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic,
	|	TableOfGoods.Purpose			AS Purpose,
	|	TableOfGoods.Count			AS Count
	|FROM
	|	Document.BackflushProduction.SideAndIntermediateRelease AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON TableOfGoods.Products = CatProducts.Ref
	|WHERE
	|	TableOfGoods.Ref IN(&ObjectsOfBases)
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND TableOfGoods.DirectionOfProductionIssue = VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit)
	|
	|UNION ALL
	|
	// Recipients of output products (production stages)
	|SELECT
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic,
	|	TableOfGoods.Purpose			AS Purpose,
	|	TableOfGoods.Count			AS Count
	|FROM
	|	Document.ProductionStage2_2.ManufacturedProducts AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON TableOfGoods.Products = CatProducts.Ref
	|WHERE
	|	TableOfGoods.Ref IN(&ObjectsOfBases)
	|	AND TableOfGoods.Manufactured
	|	AND NOT TableOfGoods.Canceled
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND VALUETYPE(TableOfGoods.Recipient) = TYPE(Catalog.BusinessStructure)
	|	AND NOT TableOfGoods.ToExpenseAs
	|
	|UNION ALL
	|
	// Recipients of by-products (production stages)
	|SELECT
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic,
	|	TableOfGoods.Purpose			AS Purpose,
	|	TableOfGoods.Count			AS Count
	|FROM
	|	Document.ProductionStage2_2.SideAndIntermediateRelease AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON TableOfGoods.Products = CatProducts.Ref
	|WHERE
	|	TableOfGoods.Ref IN(&ObjectsOfBases)
	|	AND TableOfGoods.Manufactured
	|	AND NOT TableOfGoods.Canceled
	|	AND CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND VALUETYPE(TableOfGoods.Recipient) = TYPE(Catalog.BusinessStructure)
	|	AND NOT TableOfGoods.ToExpenseAs
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProducts_1.Products				AS Products,
	|	TTProducts_1.Characteristic				AS Characteristic,
	|	TTProducts_1.Purpose					AS Purpose,
	|	SUM(TTProducts_1.Count)			AS Count
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|
	|GROUP BY
	|	TTProducts_1.Purpose,
	|	TTProducts_1.Characteristic,
	|	TTProducts_1.Products";
	
	Query.SetParameter("ObjectsOfBases", ObjectsOfBases);
	Result = Query.Execute();
	Goods.Load(Result.Unload());
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.InternalAcceptanceCertificate.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.CustomerInvoice.CollectionOfTabularPartsOfGoods();
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting
								(BusinessOperation,
								Department,
								Department,
								Undefined);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Insert("Purpose", "Purpose");
	FieldsNames.Insert("BatchesIndicationStatus", Undefined);
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

Procedure CheckRecipients(Cancel)
	
	DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Department AS Department
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Department AS Department
	|FROM
	|	GoodsTable AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Department = &Department
	|";
	
	Query.SetParameter("GoodsTable", Goods.Unload(, "LineNumber, Department"));
	Query.SetParameter("Department", Department);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		MessageText = NStr("vi = 'Bộ phận nhận và bộ phận phát hành phải khác nhau.';
							|ru = 'Подразделение-получатель и выпускающее подразделение должны различаться.';
							|en = 'Receiving business unit and releasing business unit must be different.'; fa = 'Receiving business unit and releasing business unit must be different.';
							|it = 'Il reparto-destinatario e reparto di emissione devono essere diversi.';
							|pl = 'Dział-odbiorca i wyprodukujący dział powinny różnić się.';
							|tr = 'Alıcı departman ve üreten departman farklı olmalıdır.'");
		Field = CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "Department");
		
		CommonClientServer.MessageToUser(MessageText, DataKey , Field, "Object", Cancel);
		
	EndDo;
	
EndProcedure

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager		= TemporaryDocumentDataTables();
	RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject, TempTablesManager, Cancel, FillParameters);
		
		NamesOfGroupingColumns = "ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber";
		NamesOfSummationColumns = "Count, QuantityByGBRN";
		
		InventoryKinds.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
		
		If Not Cancel Then
			FillInDetailsOfRecipientOfInventoryOwnerAttributes();
		EndIf;
		
	EndIf;
	
EndProcedure

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
	FillParameters.ReversedDocument = ReversedDocument;
	
	SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
	AvailableStockTypes = New Array;
	AvailableStockTypes.Add(Enums.InventoryTypes.Work_5);
	SelectionOfStockTypes_.InventoryType = AvailableStockTypes;
	
	Return FillParameters;
	
EndFunction

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, CompanyRecipient, BusinessOperation, Department";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.ReceivingBusinessUnit AS ReceivingBusinessUnit,
	|	TableOfGoods.ProductsGroup AS ProductsGroup
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.ReceivingBusinessUnit AS ReceivingBusinessUnit,
	|		TableOfGoods.ProductsGroup AS ProductsGroup,
	|		TableOfGoods.Count AS Count,
	|		FALSE AS ThereIsNewManualLineOfInventoryOwnerAttributes
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.ReceivingBusinessUnit AS ReceivingBusinessUnit,
	|		TableTypesOfStocks_.ProductsGroup AS ProductsGroup,
	|		-TableTypesOfStocks_.Count AS Count,
	|		TableTypesOfStocks_.RowID = """" AS ThereIsNewManualLineOfInventoryOwnerAttributes
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.ReceivingBusinessUnit,
	|	TableOfGoods.ProductsGroup
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR MAX(TableOfGoods.ThereIsNewManualLineOfInventoryOwnerAttributes)";
	
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure FillInDetailsOfRecipientOfInventoryOwnerAttributes()
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	CAST(GoodsTable.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
	|	CAST(GoodsTable.Products AS Catalog.Products) AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.ProductsGroup AS ProductsGroup,
	|	GoodsTable.Count AS Count
	|INTO TTProducts_1
	|FROM
	|	&Goods AS GoodsTable
	|;
	|
	|SELECT
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.ProductsGroup AS ProductsGroup,
	|	SUM(GoodsTable.Count) AS Count
	|INTO TTTableProducts
	|FROM
	|	TTProducts_1 AS GoodsTable
	|GROUP BY
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Department,
	|	GoodsTable.ProductsGroup
	|;
	|
	|SELECT
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	SUM(GoodsTable.Count) AS Count
	|INTO TTTableItemsQuantityWithoutDistributableAnalytics
	|FROM
	|	TTProducts_1 AS GoodsTable
	|GROUP BY
	|	GoodsTable.ItemsLocationAttributes
	|;
	|
	// The Inventory owners attributes have already been grouped.
	|SELECT
	|	CAST(TableTypesOfStocks_.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN
	|INTO TTTableTypesOfStocks
	|FROM
	|	&InventoryKinds AS TableTypesOfStocks_
	|;
	|
	|SELECT
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	GoodsTable.Department AS ReceivingBusinessUnit,
	|	GoodsTable.ProductsGroup AS ProductsGroup,
	// The separation of the Analytics and CCD being written off from the TS types of supplies into TS Items.
	// Coefficient = Table Items.Quantity / Table of products grouped.Quantity. Quantity = Inventory view tables.Quantity * The coefficient.
	// The order of the operands is chosen differently to minimize rounding problems (the standard is "Rounding the results of operations in queries").
	|	CAST(GoodsTable.Count * TableTypesOfStocks_.Count / ItemsTableGrouped.Count AS NUMBER(15, 3)) AS Count,
	|	CAST(GoodsTable.Count * TableTypesOfStocks_.QuantityByGBRN / ItemsTableGrouped.Count AS NUMBER(23, 11)) AS QuantityByGBRN
	|INTO TTDistributionResult
	|FROM
	|	TTTableTypesOfStocks AS TableTypesOfStocks_
	|		INNER JOIN TTTableProducts AS GoodsTable
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = GoodsTable.ItemsLocationAttributes
	|
	|		INNER JOIN TTTableItemsQuantityWithoutDistributableAnalytics AS ItemsTableGrouped
	|		ON GoodsTable.ItemsLocationAttributes = ItemsTableGrouped.ItemsLocationAttributes
	|;
	|
	|SELECT
	|	AllocationResult.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AllocationResult.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	AllocationResult.CCDNumber AS CCDNumber,
	|	SUM(AllocationResult.Count) AS Count,
	|	SUM(AllocationResult.QuantityByGBRN) AS QuantityByGBRN
	|INTO TTIsResultOfDistributionToCheck
	|FROM
	|	TTDistributionResult AS AllocationResult
	|GROUP BY
	|	AllocationResult.ItemsLocationAttributes,
	|	AllocationResult.InventoryOwnerAttribute,
	|	AllocationResult.CCDNumber
	|
	|;
	|
	|SELECT
	|	AllocationResult.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AllocationResult.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	AllocationResult.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count - AllocationResult.Count AS DeviationQuantity,
	|	TableTypesOfStocks_.QuantityByGBRN - AllocationResult.QuantityByGBRN AS DeviationOfQuantityAccordingToProductBatchID
	|FROM
	|	TTIsResultOfDistributionToCheck AS AllocationResult
	|		INNER JOIN TTTableTypesOfStocks AS TableTypesOfStocks_
	|		ON AllocationResult.ItemsLocationAttributes = TableTypesOfStocks_.ItemsLocationAttributes
	|		AND AllocationResult.CCDNumber = TableTypesOfStocks_.CCDNumber
	|WHERE
	|	TableTypesOfStocks_.Count - AllocationResult.Count <> 0
	|	OR TableTypesOfStocks_.QuantityByGBRN - AllocationResult.QuantityByGBRN <> 0
	|;
	|
	|SELECT
	|	AllocationResult.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AllocationResult.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	AllocationResult.CCDNumber AS CCDNumber,
	|	AllocationResult.ReceivingBusinessUnit AS ReceivingBusinessUnit,
	|	AllocationResult.ProductsGroup AS ProductsGroup,
	|	AllocationResult.Count AS Count,
	|	AllocationResult.QuantityByGBRN AS QuantityByGBRN
	|FROM
	|	TTDistributionResult AS AllocationResult
	|ORDER BY
	// The priority of the distribution of the Balance of the rounding error on the lines, where the conversion ratio of the ProductBatchID differs from one.
	|	AllocationResult.Count - AllocationResult.QuantityByGBRN <> 0 DESC
	|";
	
	Query.SetParameter("Goods", Goods);
	Query.SetParameter("InventoryKinds", InventoryKinds);
	Query.TempTablesManager = New TempTablesManager;
	
	Result = Query.ExecuteBatch();
	TypesOfInventoryOwnersAttributesBalanceOfDistribution = Result[Result.UBound() - 1].Select();
	InventoryOwnersAttributesAreDistributed = Result[Result.UBound()].Unload();
	
	// The unallocated Balance resulting from a rounding error refers to the first occurrence
	// according to the corresponding analytics.
	FilterParameters = New Structure("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber");
	While TypesOfInventoryOwnersAttributesBalanceOfDistribution.Next() Do
		FillPropertyValues(FilterParameters, TypesOfInventoryOwnersAttributesBalanceOfDistribution);
		FoundRows = InventoryOwnersAttributesAreDistributed.FindRows(FilterParameters);
		If FoundRows.Count() > 0 Then
			RowToDistribution = FoundRows[0];
			RowToDistribution.Count = RowToDistribution.Count 
				+ TypesOfInventoryOwnersAttributesBalanceOfDistribution.DeviationQuantity;
			RowToDistribution.QuantityByGBRN = RowToDistribution.QuantityByGBRN 
				+ TypesOfInventoryOwnersAttributesBalanceOfDistribution.DeviationOfQuantityAccordingToProductBatchID;
		EndIf;
	EndDo;
	
	InventoryKinds.Load(InventoryOwnersAttributesAreDistributed);
	
	If BusinessOperation <> Enums.BusinessTransactions.WorkAcceptanceAndTransferBetweenBusinessUnits Then
		FillInRecipientSInventoryType();
	EndIf;
	
EndProcedure

Procedure FillInRecipientSInventoryType() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Inventories.LineNumber AS LineNumber,
	|	CAST(Inventories.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes,
	|	Inventories.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO Inventories
	|FROM
	|	&InventoryKinds AS Inventories
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inventories.LineNumber AS LineNumber,
	|	Inventories.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	&CompanyRecipient AS InventoryRecipientOrganization,
	|	VALUE(Enum.InventoryTypes.Work_5) AS InventoryType,
	|	UNDEFINED AS GoodsOwner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS Terms,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS PriceKind,
	|	&TransferForActivity AS VATTaxation,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	VALUE(Catalog.InventoryAccountingGroups.EmptyRef) AS FinancialAccountingGroup,
	|	VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef) AS ProductsGroup,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier) AS BusinessTransactionStockType
	|FROM
	|	Inventories AS Inventories
	|
	|ORDER BY
	|	LineNumber";
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(CompanyRecipient, Date);
	
	Query.SetParameter("InventoryKinds", InventoryKinds.Unload(, "LineNumber, ItemsLocationAttributes, InventoryOwnerAttribute"));
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	Query.SetParameter("CompanyRecipient", CompanyRecipient);
	Query.SetParameter("TransferForActivity", TransferForActivity);
	Query.SetParameter("Ref", Ref);
	
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

#EndRegion

#EndRegion

#EndIf
