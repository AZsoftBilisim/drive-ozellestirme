#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	TMCommonUse.ChangeDocumentConsistencyAttribute(ThisObject, WriteMode, Enums.ProductPricingStatuses.NotApproved);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If GetFunctionalOption("UseApprovalOfItemPrices") 
	 And Status = Enums.ProductPricingStatuses.Approved
	 And Not UserRightsCached.PriceSetupWithoutApproval() Then
		
		ErrorText = NStr("vi = 'Không đủ quyền đặt bảng giá mà chưa được thống nhất';
						|ru = 'Нет прав на установку цен номенклатуры без согласования';
						|en = 'No rights for product pricing without approval'; fa = 'No rights for product pricing without approval';
						|it = 'Mancano i diritti di impostare i prezzi degli articoli senza concordamento';
						|pl = 'Brak uprawnień do ustalania cen nomenklatury bez zatwierdzenia';
						|tr = 'Ürün fiyatlarını mutabık kalınmadan yapılandırma yetkisi bulunmamaktadır'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			Ref,
			,
			,
			Cancel);
			
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If TypeOf(FillingData) = Type("DocumentRef.VendorInvoice") Then
		
		InformationOnReceiptOfGoodsServices(
			FillingData,
			FillingData);
	
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		
		InformationOnReceiptOfGoods(
			FillingData,
			FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsReceiptForStorage") Then
			
		InstructionsForAcceptanceOfGoodsForStorage(
			FillingData,
			FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.PurchaseOrder") Then
		
		FillInByOrderToSupplier(
			FillingData,
			FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsDamage") Then
		
		InformationOnDamageToGoods(
			FillingData,
			FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.AssemblyFromComponents") Then
		
		InstructionsForAssemblingProducts(
			FillingData,
			FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.OtherGoodsRecordingAsReceived") Then
		
		FillInForOtherItems(
			FillingData,
			FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ProductRangeChange") Then
		
		RecommendationsForChangingAssortment(
			FillingData,
			FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.StandardCosting2_2") Then
		Documents.StandardCosting2_2.FillInDocumentSettingProductPrices(ThisObject, FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.MovementOfProductsAndMaterials") Then
		
		InstructionsForMovementOfProductsAndMaterials(
			FillingData,
			FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.OBEntry") Then
		
		InstructionsForEnteringBalances(
			FillingData,
			FillingData);
			
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("ProductsTable") Then
			
			FillInAccordingToProductTable(
				FillingData);
			
		EndIf;
		
	EndIf;
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
	"Document.PriceSetup.ObjectModule.Posting");
	
	SetProductPriceBlocking(Cancel);
	If Cancel Then
		Return;
	EndIf; 
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	NumberOfProcessedData = (Goods.Count() + Goods2_5.Count()) / 10;
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, NumberOfProcessedData);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetProductPriceBlocking(Cancel);
	If Cancel Then
		Return;
	EndIf; 
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	If PriceManagementSystemServerCall.UsePriceManagementSystem25(CurrentSessionDate()) Then
		If Goods.Count() > 0  Then
			Goods.Clear();
		EndIf;
	Else
		If Goods2_5.Count() > 0  Then
			Goods2_5.Clear();
		EndIf;
	EndIf;
	
	InitializeDocument();
	Approved = False;
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//    Table - See AccessManagement.AccessValuesSetsTable
Procedure FillAccessValuesSets(Table) Export
	
	If TypesOfPrices.Count() = 0 Then
		
		String = Table.Add();
		String.AccessValue = Enums.AdditionalAccessValues.AccessAllowed;
		
	Else
	
		For Each DifferentTypesOfPrices In TypesOfPrices Do
			String = Table.Add();
			String.AccessValue = DifferentTypesOfPrices.PriceKind;
		EndDo;
		
	EndIf;
	 
EndProcedure

// Forced controlled blocking of the item price register measurements is set
Procedure SetProductPriceBlocking(Cancel)
	
	If Cancel 
		Or Not Metadata.InformationRegisters.ItemsPrices.EnableTotalsSliceFirst
			And Not Metadata.InformationRegisters.ItemsPrices.EnableTotalsSliceLast Then
		Return;
	EndIf; 
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.ItemsPrices");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = ThisObject.Goods;
		LockItem.UseFromDataSource("Products", "Products");
		
		LockItem = Block.Add("InformationRegister.ItemsPrices25");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = ThisObject.Goods;
		LockItem.UseFromDataSource("Products", "Products");
		Block.Lock();
		
	Except
		
		Cancel = True;
		
		MessageText = NStr(
		"vi = 'Không thể thay đổi bản ghi kết chuyển của chứng từ ""%1"" 
		|do nguyên nhân:
		|%2';
		|ru = 'Не удалось изменить движения документа ""%1"" 
		|по причине:
		|%2';
		|en = 'Cannot change document ""%1"" records.
		|Reason:
		|%2'; fa = 'Cannot change document ""%1"" records.
		|Reason:
		|%2';
		|it = 'Non è stato possibile modificare il movimento del documento ""%1""
		|a causa di:
		|%2';
		|pl = 'Nie udało się zmienić ruchu dokumentu ""%1"" 
		|z powodu:
		|%2';
		|tr = '""%1"" belge kaydının değiştirilememe 
		|nedeni:
		|%2'");
		MessageText = StrTemplate(
			MessageText,
			TrimAll(ThisObject),
			DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(
			NStr("vi = 'Phong tỏa được quản lý';
				|ru = 'Управляемая блокировка';
				|en = 'Managed lock'; fa = 'Managed lock';
				|it = 'Gestione blocco';
				|pl = 'Sterowane blokowanie';
				|tr = 'Kontrollü kilit'"),
			EventLogLevel.Error,
			,
			,
			MessageText);
		
		CommonClientServer.MessageToUser(MessageText,,,, Cancel);
		
	EndTry; 
	
EndProcedure

#Region InitializationAndFilling

// Procedure for filling out a document based on a request for the return of goods from the client.
//
// Parameters:
//	DocumentBasis - DocumentRef.RequestForReturnOfGoodsFromCustomer - Link to the application
//	FillingData - Structure - Data for filling in the document.
//	
Procedure InformationOnReceiptOfGoodsServices(
	Val DocumentBasis,
	FillingData)
	
	// Fill in the data of the document header.
	Query = New Query(
	"SELECT ALLOWED
	|	TypesOfPrices.Ref,
	|	TypesOfPrices.SetPriceDuringGeneration,
	|	TypesOfPrices.DeletionMark
	|INTO TypesOfPrices
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	TypesOfPrices.SetPriceDuringGeneration
	|	AND TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid)
	|	AND NOT TypesOfPrices.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseOfGoodsServicesGoods.Products AS Products,
	|	PurchaseOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	PurchaseOfGoodsServicesGoods.Series,
	|	PurchaseOfGoodsServicesGoods.Package AS Package,
	|	TypesOfPrices.Ref AS PriceKind,
	|	0 AS Price
	|FROM
	|	Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|		LEFT JOIN TypesOfPrices AS TypesOfPrices
	|		ON TRUE
	|WHERE
	|	PurchaseOfGoodsServicesGoods.Ref = &Ref");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập bảng giá trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить установку цен номенклатуры на основании документа %1';
				|en = 'It is not required to enter pricing of products based on document %1'; fa = 'It is not required to enter pricing of products based on document %1';
				|it = 'Non è necessario immettere l''impostazione prezzi di nomenclatura in base al documento %1';
				|pl = 'Nie trzeba wprowadzać ustalenia cen nomenklatury na podstawie dokumentu %1';
				|tr = '%1 belgesi temelinde öğe fiyatı girmeniz gerekli değildir'"),
			DocumentBasis);
		Raise Text;
	Else
		
		ThisObject.DocumentBasis = DocumentBasis;
		UploadProducts(QueryResult.Unload());
		
	EndIf;
	
EndProcedure

// Procedure for filling out a document based on entering the remaining balance.
// 
// Parameters:
//    DocumentBasis - DocumentRef.OBEntry - Link to the document entering balances
//    FillingData - Structure - Data for filling in the document.
//
Procedure InstructionsForEnteringBalances(
    Val DocumentBasis,
    FillingData)
    
    // Fill in the data of the document header.
    Query = New Query(
    "SELECT ALLOWED
    |	TypesOfPrices.Ref,
    |	TypesOfPrices.SetPriceDuringGeneration,
    |	TypesOfPrices.DeletionMark
    |INTO TypesOfPrices
    |FROM
    |	Catalog.TypesOfPrices AS TypesOfPrices
    |WHERE
    |	TypesOfPrices.SetPriceDuringGeneration
    |	AND TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid)
    |	AND NOT TypesOfPrices.DeletionMark
    |;
    |
    |////////////////////////////////////////////////////////////////////////////////
    |SELECT
    |	EnteringProductBalances.Products AS Products,
    |	EnteringProductBalances.Characteristic AS Characteristic,
    |	EnteringProductBalances.Series,
    |	EnteringProductBalances.Package AS Package,
    |	TypesOfPrices.Ref AS PriceKind,
    |	0 AS Price
    |FROM
    |	Document.OBEntry.Goods AS EnteringProductBalances
    |		LEFT JOIN TypesOfPrices AS TypesOfPrices
    |		ON TRUE
    |WHERE
    |	EnteringProductBalances.Ref = &Ref");
    Query.SetParameter("Ref", DocumentBasis);
    
    QueryResult = Query.Execute();
    If QueryResult.IsEmpty() Then
        Text = StringFunctionsClientServer.SubstituteParametersToString(
            NStr("vi = 'Không cần nhập bảng giá trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить установку цен номенклатуры на основании документа %1';
				|en = 'It is not required to enter pricing of products based on document %1'; fa = 'It is not required to enter pricing of products based on document %1';
				|it = 'Non è necessario immettere l''impostazione prezzi di nomenclatura in base al documento %1';
				|pl = 'Nie trzeba wprowadzać ustalenia cen nomenklatury na podstawie dokumentu %1';
				|tr = '%1 belgesi temelinde öğe fiyatı girmeniz gerekli değildir'"),
            DocumentBasis);
        Raise Text;
    Else
        
        ThisObject.DocumentBasis = DocumentBasis;
        UploadProducts(QueryResult.Unload());
        
    EndIf;
    
EndProcedure

// Procedure for filling out a document based on the receipt of goods
//
// Parameters:
//	DocumentBasis - DocumentRef.ReceiptOfGoodsToWarehouse - Link to receipt
//	FillingData - Structure - Data for filling in the document.
//	
Procedure InformationOnReceiptOfGoods(
	Val DocumentBasis,
	FillingData)
	
	// Fill in the data of the document header.
	Query = New Query(
	"SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Package AS Package,
	|	TypesOfPrices.Ref AS PriceKind,
	|	0 AS Price
	|FROM
	|	Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsTable
	|		LEFT JOIN Catalog.TypesOfPrices AS TypesOfPrices
	|		ON (TypesOfPrices.SetPriceDuringGeneration)
	|		AND (NOT TypesOfPrices.DeletionMark)
	|		AND (TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid))
	|WHERE
	|	GoodsTable.Ref = &Ref");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập bảng giá trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить установку цен номенклатуры на основании документа %1';
				|en = 'It is not required to enter pricing of products based on document %1'; fa = 'It is not required to enter pricing of products based on document %1';
				|it = 'Non è necessario immettere l''impostazione prezzi di nomenclatura in base al documento %1';
				|pl = 'Nie trzeba wprowadzać ustalenia cen nomenklatury na podstawie dokumentu %1';
				|tr = '%1 belgesi temelinde öğe fiyatı girmeniz gerekli değildir'"),
			DocumentBasis);
		Raise Text;
	Else
		
		ThisObject.DocumentBasis = DocumentBasis;
		UploadProducts(QueryResult.Unload());
		
	EndIf;
	
EndProcedure

// Procedure for filling out a document based on the acceptance of goods for storage.
//
// Parameters:
//	DocumentBasis - DocumentRef.RequestForReturnOfGoodsFromCustomer - Link to the application
//	FillingData - Structure - Data for filling in the document.
//	
Procedure InstructionsForAcceptanceOfGoodsForStorage(Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query(
	"SELECT
	|	AcceptanceOfGoodsForStorageGoods.Products AS Products,
	|	AcceptanceOfGoodsForStorageGoods.Characteristic AS Characteristic,
	|	AcceptanceOfGoodsForStorageGoods.Series,
	|	AcceptanceOfGoodsForStorageGoods.Package AS Package,
	|	TypesOfPrices.Ref AS PriceKind,
	|	0 AS Price
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS AcceptanceOfGoodsForStorageGoods
	|		LEFT JOIN Catalog.TypesOfPrices AS TypesOfPrices
	|		ON (TypesOfPrices.SetPriceDuringGeneration)
	|		AND (NOT TypesOfPrices.DeletionMark)
	|		AND (TypesOfPrices.Status = VALUE(Enum.StatusesOfPriceTypeValidity.Valid))
	|WHERE
	|	AcceptanceOfGoodsForStorageGoods.Ref = &Ref");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập bảng giá trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить установку цен номенклатуры на основании документа %1';
				|en = 'It is not required to enter pricing of products based on document %1'; fa = 'It is not required to enter pricing of products based on document %1';
				|it = 'Non è necessario immettere l''impostazione prezzi di nomenclatura in base al documento %1';
				|pl = 'Nie trzeba wprowadzać ustalenia cen nomenklatury na podstawie dokumentu %1';
				|tr = '%1 belgesi temelinde öğe fiyatı girmeniz gerekli değildir'"),
			DocumentBasis);
		Raise Text;
	Else
		
		ThisObject.DocumentBasis = DocumentBasis;
		UploadProducts(QueryResult.Unload());
		
	EndIf;
	
EndProcedure

// Procedure for filling out a document based on a request for the return of goods from the client.
//
// Parameters:
//	DocumentBasis - DocumentRef.RequestForReturnOfGoodsFromCustomer - Link to the application
//	FillingData - Structure - Data for filling in the document.
//	
Procedure FillInByOrderToSupplier(
	Val DocumentBasis,
	FillingData)
	
	// Fill in the data of the document header.
	Query = New Query(
	"SELECT
	|	PurchaseOrderGoods.Products   AS Products,
	|	PurchaseOrderGoods.Characteristic AS Characteristic,
	|	PurchaseOrderGoods.Package       AS Package
	|FROM
	|	Document.PurchaseOrder.Goods AS PurchaseOrderGoods
	|WHERE
	|	PurchaseOrderGoods.Ref = &Ref");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập bảng giá trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить установку цен номенклатуры на основании документа %1';
				|en = 'It is not required to enter pricing of products based on document %1'; fa = 'It is not required to enter pricing of products based on document %1';
				|it = 'Non è necessario immettere l''impostazione prezzi di nomenclatura in base al documento %1';
				|pl = 'Nie trzeba wprowadzać ustalenia cen nomenklatury na podstawie dokumentu %1';
				|tr = '%1 belgesi temelinde öğe fiyatı girmeniz gerekli değildir'"),
			DocumentBasis);
		Raise Text;
	Else
		
		ThisObject.DocumentBasis = DocumentBasis;
		UploadProducts(QueryResult.Unload());
		
	EndIf;
	
EndProcedure

// Procedure for filling out a document based on a request for the return of goods from the client.
//
// Parameters:
//	DocumentBasis - DocumentRef.RequestForReturnOfGoodsFromCustomer - Link to the application
//	FillingData - Structure - Data for filling in the document.
//	
Procedure InformationOnDamageToGoods(
	Val DocumentBasis,
	FillingData)
	
	// Fill in the data of the document header.
	Query = New Query(
	"SELECT
	|	GoodsDamageGoods.ProductsRecordingAsReceived AS Products,
	|	GoodsDamageGoods.CharacteristicRecordingAsReceived AS Characteristic,
	|	GoodsDamageGoods.Series,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package
	|FROM
	|	Document.GoodsDamage.Goods AS GoodsDamageGoods
	|WHERE
	|	GoodsDamageGoods.Ref = &Ref");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập bảng giá trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить установку цен номенклатуры на основании документа %1';
				|en = 'It is not required to enter pricing of products based on document %1'; fa = 'It is not required to enter pricing of products based on document %1';
				|it = 'Non è necessario immettere l''impostazione prezzi di nomenclatura in base al documento %1';
				|pl = 'Nie trzeba wprowadzać ustalenia cen nomenklatury na podstawie dokumentu %1';
				|tr = '%1 belgesi temelinde öğe fiyatı girmeniz gerekli değildir'"),
			DocumentBasis);
		Raise Text;
	Else
		
		ThisObject.DocumentBasis = DocumentBasis;
		UploadProducts(QueryResult.Unload());
		
	EndIf;
	
EndProcedure

// Procedure for filling out a document based on the product Assembly.
//
// Parameters:
//	DocumentBasis - DocumentRef.RequestForReturnOfGoodsFromCustomer - Link to the application
//	FillingData - Structure - Data for filling in the document.
//	
Procedure InstructionsForAssemblingProducts(
	Val DocumentBasis,
	FillingData)
	
	// Fill in the data of the document header.
	Query = New Query(
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series,
	|	Goods.Package AS Package
	|FROM
	|	Document.AssemblyFromComponents.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.DisassemblyIntoComponents)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentAssemblyFromComponents.Products AS Products,
	|	DocumentAssemblyFromComponents.Characteristic AS Characteristic,
	|	DocumentAssemblyFromComponents.Series,
	|	DocumentAssemblyFromComponents.Package AS Package
	|FROM
	|	Document.AssemblyFromComponents AS DocumentAssemblyFromComponents
	|WHERE
	|	DocumentAssemblyFromComponents.Ref = &Ref
	|	AND DocumentAssemblyFromComponents.BusinessOperation = VALUE(Enum.BusinessTransactions.AssemblyFromComponents)");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập bảng giá trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить установку цен номенклатуры на основании документа %1';
				|en = 'It is not required to enter pricing of products based on document %1'; fa = 'It is not required to enter pricing of products based on document %1';
				|it = 'Non è necessario immettere l''impostazione prezzi di nomenclatura in base al documento %1';
				|pl = 'Nie trzeba wprowadzać ustalenia cen nomenklatury na podstawie dokumentu %1';
				|tr = '%1 belgesi temelinde öğe fiyatı girmeniz gerekli değildir'"),
			DocumentBasis);
		Raise Text;
	Else
		
		ThisObject.DocumentBasis = DocumentBasis;
		UploadProducts(QueryResult.Unload());
		
	EndIf;
	
EndProcedure

// Procedure for filling out a document based on other goods registration.
//
// Parameters:
//	DocumentBasis - DocumentRef.RequestForReturnOfGoodsFromCustomer - Link to the application
//	FillingData - Structure - Data for filling in the document.
//	
Procedure FillInForOtherItems(
	Val DocumentBasis,
	FillingData)
	
	// Fill in the data of the document header.
	Query = New Query(
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series,
	|	Goods.Package AS Package
	|FROM
	|	Document.OtherGoodsRecordingAsReceived.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập bảng giá trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить установку цен номенклатуры на основании документа %1';
				|en = 'It is not required to enter pricing of products based on document %1'; fa = 'It is not required to enter pricing of products based on document %1';
				|it = 'Non è necessario immettere l''impostazione prezzi di nomenclatura in base al documento %1';
				|pl = 'Nie trzeba wprowadzać ustalenia cen nomenklatury na podstawie dokumentu %1';
				|tr = '%1 belgesi temelinde öğe fiyatı girmeniz gerekli değildir'"),
			DocumentBasis);
		Raise Text;
	Else
		
		ThisObject.DocumentBasis = DocumentBasis;
		UploadProducts(QueryResult.Unload());
		
	EndIf;
	
EndProcedure

// Procedure for filling in a document based on changes in the product range.
//
// Parameters:
//	DocumentBasis - DocumentRef.ProductRangeChange - link to the document
//	FillingData - Structure - Data for filling in the document.
//	
Procedure RecommendationsForChangingAssortment(
	Val DocumentBasis,
	FillingData)
	
	ProductRangeServer.CheckNeedToSetPricesBasedOn(FillingData.Ref);
	
	PackageResultPriceTypesAndProducts = ProductRangeServer.ResultOfPackageTypesOfPricesAndProductsForInstallationByAssortment(FillingData.Ref);
	TableOfPriceTypes   = PackageResultPriceTypesAndProducts[1].Unload();
	TableOfGoods    = PackageResultPriceTypesAndProducts[0].Unload();
	
	If TableOfPriceTypes.Count() = 0 Then
		
		ErrorText = NStr("vi = 'Không có dạng giá hợp lệ để đặt bảng giá.
		|Không cần lập chứng từ. 
		|Không thể điền chứng từ.';
		|ru = 'Нет доступных видов цен для установки цен номенклатуры.
		|Оформление документа не требуется. 
		|Заполнение документа не выполнено.';
		|en = 'There are no available price types for product pricing.
		|It is not required to generate a document.
		|Document population is not completed.'; fa = 'There are no available price types for product pricing.
		|It is not required to generate a document.
		|Document population is not completed.';
		|it = 'Non ci sono tipologie di prezzi disponibili per impostare i prezzi degli articoli.
		|Non è necessario emettere il documento. 
		|La compilazione del documento non è stata effettuata.';
		|pl = 'Brak dostępnych rodzajów cen do ustalenia cen nomenklatury.
		|Przetwarzanie dokumentu nie jest wymagane. 
		|Wypełnienie dokumentu nie jest wykonane.';
		|tr = 'Öğe fiyatlarının yapılandırılması için mevcut fiyat türü bulunmamaktadır.
		|Belgenin oluşturulması gerekmemektedir. 
		|Belge doldurulmadı.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, FillingData.Ref);
		
		Raise ErrorText;
		
	Else	
		
		ThisObject.DocumentBasis = DocumentBasis;
		TypesOfPrices.Load(TableOfPriceTypes);
		UploadProducts(TableOfGoods);
		
	EndIf;
	
EndProcedure

Procedure InstructionsForMovementOfProductsAndMaterials(Val DocumentBasis, FillingData)
	
	// Fill in the data of the document header.
	Query = New Query(
	"SELECT
	|	Goods.Products           AS Products,
	|	Goods.Characteristic         AS Characteristic,
	|	Goods.Series                  AS Series,
	|	Goods.Package               AS Package
	|FROM
	|	Document.MovementOfProductsAndMaterials.Goods AS Goods
	|WHERE
	|	Goods.Ref = &Ref");
	Query.SetParameter("Ref", DocumentBasis);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Không cần nhập bảng giá trên cơ sở chứng từ %1';
				|ru = 'Не требуется вводить установку цен номенклатуры на основании документа %1';
				|en = 'It is not required to enter pricing of products based on document %1'; fa = 'It is not required to enter pricing of products based on document %1';
				|it = 'Non è necessario immettere l''impostazione prezzi di nomenclatura in base al documento %1';
				|pl = 'Nie trzeba wprowadzać ustalenia cen nomenklatury na podstawie dokumentu %1';
				|tr = '%1 belgesi temelinde öğe fiyatı girmeniz gerekli değildir'"),
			DocumentBasis);
		Raise Text;
	Else
		
		ThisObject.DocumentBasis = DocumentBasis;
		UploadProducts(QueryResult.Unload());
		
	EndIf;
	
EndProcedure

// Initializes the setting of item prices.
//
Procedure InitializeDocument(FillingData = Undefined)

	EmployeeResponsible = Users.CurrentUser();

	If Not GetFunctionalOption("UseApprovalOfItemPrices")
	 Or UserRightsCached.PriceSetupWithoutApproval() Then
		Status = Enums.ProductPricingStatuses.Approved;
	Else
	    Status = Enums.ProductPricingStatuses.NotApproved;
	EndIf;
	
EndProcedure

Procedure FillInAccordingToProductTable(FillingData)
	
	ProductsTable = GetFromTempStorage(FillingData.ProductsTable); // ValueTable
	UploadProducts(ProductsTable);
	
	ProductsTable.GroupBy("PriceKind");
	
	TypesOfPrices.Load(ProductsTable);
	
	Date = FillingData.Date;
		
EndProcedure

Procedure UploadProducts(GoodsTable)
	
	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	If UsePriceManagementSystem25 Then
		If GoodsTable.Columns.Find("Package") = Undefined Then
			GoodsTable.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		EndIf;
		
		If GoodsTable.Columns.Find("Series") = Undefined Then
			GoodsTable.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
		EndIf;
		
		If GoodsTable.Columns.Find("Characteristic") = Undefined Then
			GoodsTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		EndIf;
	
		SettingsStructure = New Structure();
		SettingsStructure.Insert("TableOfGoods", GoodsTable);
		SettingsStructure.Insert("NameOfDataLayoutSchemaTemplate", "Template2_5");
		SettingsStructure.Insert("SettingsComposer", Undefined);
		SettingsStructure.Insert("KeepRecordsOfQualityCertificates", False);
		SettingsStructure.Insert("ExternalDataSourceSelectionIsUsed", True);
		SettingsStructure.Insert("RequiredFields"   , New Array);

		SettingsStructure.RequiredFields.Add("Products");
		SettingsStructure.RequiredFields.Add("Characteristic");
		SettingsStructure.RequiredFields.Add("PricingVariant");
		SettingsStructure.RequiredFields.Add("Series");
		SettingsStructure.RequiredFields.Add("PricingBatch");
		SettingsStructure.RequiredFields.Add("Package");
		SettingsStructure.RequiredFields.Add("PricingPackage");
		SettingsStructure.RequiredFields.Add("PriceKind");
		
		ResultStructure1 = DataProcessors.GoodsSelectionByPicking.PrepareDataStructure(SettingsStructure);
		
		Goods2_5.Load(ResultStructure1.TableOfGoods);
	Else
		Goods.Load(GoodsTable);
	EndIf;
		
EndProcedure


#EndRegion

#EndRegion

#Region Public

#EndRegion

#EndIf
