#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.InventoryAssignmentAdjustment - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode) Export
	
	FillParameters = ParametersForFillingInventoryTypes(False);
	FillParameters.DocumentMakesBothArrivalAndExpenditure = WriteMode = DocumentWriteMode.Posting;
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.InventoryAssignmentAdjustment.CollectionOfTabularPartsOfGoods.
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

// Parameters:
// FillingData - Structure:
//  * HeaderAttributes - Structure - details of the document header.
//  * Goods - ValueTable - goods to transfer to the document.
Procedure Filling(FillingData, StandardProcessing)
	
	If ValueIsFilled(FillingData) Then
	
		If TypeOf(FillingData) = Type("Structure") Then
			
			If FillingData.Property("HeaderAttributes") Then
				FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
			ElsIf FillingData.Property("OperationKind")
				And ValueIsFilled(FillingData.OperationKind) Then
				OperationKind = FillingData.OperationKind;
			Else
				OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve;
			EndIf;
			
			If FillingData.Property("Goods") Then
				FillInProductsTable(FillingData.Goods);
				
				If FillingData.Goods.Columns.Find("NumberOfPackages") = Undefined Then
					StructureOfActions = New Structure();
					StructureOfActions.Insert(
						"RecalculateNumberOfPackages",
						BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
						BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
				EndIf;
				
			EndIf;
			
			If Not ValueIsFilled(Date) Then
				Date = CurrentSessionDate();
			EndIf;
			
		Else
			
			OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve;
			
		EndIf;
		
		OrderDocument = Undefined;
		If TypeOf(FillingData) <> Type("Structure")
			And TypeOf(FillingData) <> Type("DocumentRef.GoodsIssueNote") Then
			
			OrderDocument = FillingData;
			
		EndIf;
		
		If ValueIsFilled(OrderDocument) Then
			
			Purpose = Documents.InventoryAssignmentAdjustment.OrderAssignment(OrderDocument);
			Organization = Common.ObjectAttributeValue(OrderDocument, "Organization");
			PurposeForCompletingDocument = Purpose;
			GoodsFilter = Undefined;
			
			ManagerOfDocument = Common.ObjectManagerByRef(OrderDocument);
			If TypeOf(OrderDocument) = Type("DocumentRef.SubcontractOrder2_5")
				Or TypeOf(OrderDocument) = Type("DocumentRef.ProductionStage2_2")
				Or TypeOf(OrderDocument) = Type("DocumentRef.MaterialProviderOrder2_5")
				Or False Then
				
				DocumentData = ManagerOfDocument.DocumentDataForCreatingDestinationAdjustment(OrderDocument,
					New Structure("IDInStorage,ThisIsWithdrawalOfReserve", New UUID, True));
				GoodsFilter = GetFromTempStorage(DocumentData.AddressOfGoods);
				DeleteFromTempStorage(DocumentData.AddressOfGoods);
				If DocumentData.Assignments.Count() = 1 Then
					PurposeForCompletingDocument = DocumentData.Assignments[0];
					Purpose = PurposeForCompletingDocument;
					OrderDocument = Common.ObjectAttributeValue(Purpose, "OrderDocument");
					OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve;
				Else
					PurposeForCompletingDocument = DocumentData.Assignments;
					Purpose = Undefined;
					OrderDocument = Undefined;
					OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments;
				EndIf;
				
			EndIf;
			If TypeOf(OrderDocument) = Type("DocumentRef.MaterialProviderOrder2_5")
				Or False Then
				OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.ReservationAndAdjustment;
			EndIf;
			Documents.InventoryAssignmentAdjustment.FillInUsingBaseDocument(
				PurposeForCompletingDocument, Undefined, Ref, OperationKind, Goods, GoodsFilter);
			
			If Goods.Count() = 0 Then
				
				MessageText = NStr("vi = 'Không có dữ liệu để điền theo ""%OrderDocument%"" .';
									|ru = 'Нет данных для заполнения по ""%OrderDocument%"" .';
									|en = 'No data for population under ""%OrderDocument%"".'; fa = 'No data for population under ""%OrderDocument%"".';
									|it = 'Nessun dato da compilare per ""%OrderDocument%"".';
									|pl = 'Brak danych do wypełnienia według ""%OrderDocument%"" .';
									|tr = '""%OrderDocument%"" göre doldurmak için veri mevcut değil.'");
				MessageText = StrReplace(MessageText, "%OrderDocument%", String(FillingData));
				Common.MessageToUser(MessageText);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	InventoryAssignmentAdjustmentLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	If OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments Then
		Purpose = Undefined;
		OrderDocument = Undefined;
	EndIf;
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.CheckCompletenessOfProductLocations = True;
	CheckParameters.FieldsForCheckingCompleteness = "InitialAssignment,NewAssignment,Warehouse,Premise";
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryAssignmentAdjustment),
												Cancel,
												NotCheckedAttributeArray);
												
	WarehousesServer.CheckFillingOfCells(ThisObject, NotCheckedAttributeArray, Cancel);
	WarehousesServer.CheckFillingOfPremises(ThisObject, NotCheckedAttributeArray, Cancel);
	
	NotCheckedAttributeArray.Add("Goods.NewAssignment");
	NotCheckedAttributeArray.Add("Goods.InitialAssignment");
	
	If OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments
		Or OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.AdvancedAssignmentAdjustment Then
		NotCheckedAttributeArray.Add("Organization");
	EndIf;
	CheckTypeOfAppointments(Cancel);
	CheckFillingOfNewAssignment(Cancel);
	
	// Checking the filling of the packages of the nomenclature at the address warehouses
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.Warehouse,
	|	Goods.Premise
	|INTO WarehousesAndPremises
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	WarehousesAndPremises.Warehouse,
	|	WarehousesAndPremises.Premise
	|FROM
	|	WarehousesAndPremises AS WarehousesAndPremises
	|		INNER JOIN InformationRegister.SettingsOfBinLocationWarehouses AS SettingsOfBinLocationWarehouses
	|		ON (SettingsOfBinLocationWarehouses.UseBinLocationWarehousing)
	|			AND (SettingsOfBinLocationWarehouses.StartDateOfUsingWarehouseBinSystem <= &Date)
	|			AND (SettingsOfBinLocationWarehouses.Warehouse = WarehousesAndPremises.Warehouse)
	|			AND (SettingsOfBinLocationWarehouses.Premise = WarehousesAndPremises.Premise)
	|			AND (NOT WarehousesAndPremises.Premise = VALUE(Catalog.Warerooms.EmptyRef)
	|				OR (NOT SettingsOfBinLocationWarehouses.Warehouse.UseWarerooms
	|					OR &Date < SettingsOfBinLocationWarehouses.Warehouse.StartDateOfWareroomUse))";
	Query.SetParameter("Goods", Goods.Unload(,"Warehouse, Premise"));
	Query.SetParameter("Date",
		?(ValueIsFilled(Date),Date,CurrentSessionDate()));
	
	WarehouseSelection_ = Query.Execute().Select();
	
	While WarehouseSelection_.Next() Do
		CheckParameters = ProductsServer.ParametersForCheckingFillingOfPackages();
		CheckParameters.SelectingRowsToCheck.Insert("Warehouse", WarehouseSelection_.Warehouse);
		CheckParameters.SelectingRowsToCheck.Insert("Premise", WarehouseSelection_.Premise);
		ProductsServer.CheckFillingOfPackages(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	EndDo;
	
	// Checking that one of the two destination fields is filled in
	EmptyAssignment = Catalogs.Assignments.EmptyRef();
	TheStructureOfTheSearch = New Structure("InitialAssignment, NewAssignment", EmptyAssignment, EmptyAssignment);
	FoundRows = Goods.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() > 0 Then
		
		MessageTemplate = NStr("vi = 'Chưa điền mục đích trong cột ""Mục đích ban đầu"" và ""Mục đích mới"" trong dòng %LineNumber%. 
			|Cần điền một trong các cột (hoặc cả hai).';
			|ru = 'Не заполнено назначение в колонках ""Исходное назначение"" и ""Новое назначение"" в строке %LineNumber%. 
			|Необходимо заполнить одну из колонок (либо обе).';
			|en = 'Assignment in columns ""Initial assignment"" and ""New assignment"" in line %LineNumber% is not filled in. 
			|Fill in one of the columns (or both).'; fa = 'Assignment in columns ""Initial assignment"" and ""New assignment"" in line %LineNumber% is not filled in. 
			|Fill in one of the columns (or both).';
			|it = 'L''assegnazione non è compilata nelle colonne ""Assegnazione iniziale"" e ""Nuova assegnazione"" nella riga %LineNumber%. 
			|È necessario compilare una delle colonne (o entrambe).';
			|pl = 'Nie wypełniono przeznaczenia w kolumnach ""Początkowe przeznaczenie"" i ""Nowe przeznaczenie"" w wierszu %LineNumber%. 
			|Należy wypełnić jedną z kolumn (lub obie).';
			|tr = 'Atama, %LineNumber%satırdaki ""Orijinal atama"" ve ""Yeni atama"" sütunlarında doldurulmadı. 
			|Sütunlardan biri (veya her ikisi) doldurulmalı.'");
		
		For Each String In FoundRows Do
			MessageText = StrReplace(MessageTemplate, "%LineNumber%", String.LineNumber);
			Common.MessageToUser(MessageText, , , "Object", Cancel)
		EndDo;
		
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.QualityConfirmationDate");
	For Each TableRow In Goods Do
		
		If ValueIsFilled(TableRow.ControlledLotReference)
				And TableRow.SubjectToUnlocking
				And Not ValueIsFilled(TableRow.QualityConfirmationDate) Then
		
			ErrorText = StrTemplate(
				NStr("vi = 'Tại dòng %1 trong danh sách Hàng hóa, cột ""Kiểm tra chất lượng đến"" chưa được điền.';
					|ru = 'В строке %1 списка Товары не заполнена колонка ""Проверить качество до"".';
					|en = 'The ""Check quality before"" column in line %1 of the ""Goods"" list is not filled.'; fa = 'The ""Check quality before"" column in line %1 of the ""Goods"" list is not filled.';
					|it = 'The ""Check quality before"" column in line %1 of the ""Goods"" list is not filled.';
					|pl = 'The ""Check quality before"" column in line %1 of the ""Goods"" list is not filled.';
					|tr = 'Ürünler listesi %1 satırında ''Kaliteyi kontrol et (son tarih)'' sütunu doldurulmamış.'"),
				TableRow.LineNumber);
			Field = CommonClientServer.PathToTabularSection(
				"Goods",
				TableRow.LineNumber,
				"QualityConfirmationDate");
		
		Common.MessageToUser(ErrorText, ThisObject, Field, , Cancel);
		
		EndIf;
		
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	InventoryAssignmentAdjustmentLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Or AdditionalProperties.Property("SoftwareDocumentCreation") Then
		Return;
	EndIf;
	
	CheckRightOfDocument(Cancel);
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	ProductsServer.ClearUnusedSeries(ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryAssignmentAdjustment));
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryKinds");
	
	InventoryAssignmentAdjustmentLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	If BinLocationWarehousingIsUsed() Then
		ThisObject.AdditionalProperties.Insert("BinLocationWarehousingIsUsed");
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.Posting);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	InventoryAssignmentAdjustmentLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.UndoPosting);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	InventoryAssignmentAdjustmentLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.MutualAdjustment Then
		
		OperationKind               = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve;
		Purpose                = Undefined;
		InventoryOwnerAttributesAreSpecifiedManually = False;
		
		Goods.Clear();
		InventoryKinds.Clear();
		
	EndIf;
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "InventoryKinds");

	InitializeDocument();

EndProcedure

#EndRegion

#Region Private

Procedure CheckRightOfDocument(Cancel)
	
	If Not Documents.InventoryAssignmentAdjustment.ChangeOptionAvailable(Ref) Then
		ExceptionString = NStr("vi = 'Không đủ quyền để Ghi chứng từ với hành động ""%1"".';
								|ru = 'Недостаточно прав доступа для записи документа с действием ""%1"".';
								|en = 'Insufficient access rights to save the document with action ""%1"".'; fa = 'Insufficient access rights to save the document with action ""%1"".';
								|it = 'Permessi insufficienti per accedere alla registrazione del documento con l''effetto ""%1"".';
								|pl = 'Niewystarczające uprawnienia dostępu do zapisu dokumentu z działaniem ""%1"".';
								|tr = '""%1"" eylemini içeren belge kaydı için yetersiz yetki.'");
		ExceptionString = StringFunctionsClientServer.SubstituteParametersToString(ExceptionString, OperationKind);
		Raise ExceptionString;
	EndIf;
	
EndProcedure

#Region InitializationAndFilling

Procedure FillInProductsTable(TableOfGoods)
	
	Goods.Load(TableOfGoods);
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.InventoryAssignmentAdjustment));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	Author = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EmployeeResponsible = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region FillChecking

Procedure CheckFillingOfNewAssignment(Cancel)
	
	AssignmentType = Common.ObjectAttributeValue(Purpose, "AssignmentType");
	
	ThisIsGiverAssignment =
		AssignmentType = Enums.AssignmentTypes.ProvidedMaterialsForStage22
		
		
		Or AssignmentType = Enums.AssignmentTypes.Giveaway2_5;
		
	If ThisIsGiverAssignment
			And Not OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.AdvancedAssignmentAdjustment Then
		
		DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
		Table = Goods.UnloadColumns("LineNumber, InitialAssignment, NewAssignment");
		For Each LineProducts_ In Goods Do
			
			If Not LineProducts_.NewAssignment.IsEmpty() And Not LineProducts_.InitialAssignment.IsEmpty() Then
				
				FillPropertyValues(Table.Add(), LineProducts_);
				
			EndIf;
			
		EndDo;
		
		If Table.Count() > 0 Then
			
			Query = New Query();
			Query.Text =
			"SELECT
			|	Table.LineNumber AS LineNumber,
			|	Table.InitialAssignment AS InitialAssignment,
			|	Table.NewAssignment AS NewAssignment
			|INTO TTTable
			|FROM
			|	&Table AS Table
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Table.LineNumber AS LineNumber,
			|	Table.OriginalContract AS OriginalContract,
			|	Table.NewContract AS NewContract,
			|	Table.OriginalType AS OriginalType,
			|	Table.NewType AS NewType
			|FROM
			|	(SELECT
			|		Table.LineNumber AS LineNumber,
			|		Table.InitialAssignment AS InitialAssignment,
			|		Table.NewAssignment AS NewAssignment,
			|		
			|		ISNULL(
			|			CASE
			|				WHEN VALUETYPE(Table.InitialAssignment.OrderDocument) = TYPE(Document.MaterialProviderOrder2_5)
			|					THEN CAST(Table.InitialAssignment.OrderDocument AS Document.MaterialProviderOrder2_5).Partner
			|			END,
			|			ISNULL(Table.InitialAssignment.Partner, VALUE(Catalog.Partners.EmptyRef))) AS SourcePartner,
			|		
			|		ISNULL(
			|			CASE
			|				WHEN VALUETYPE(Table.InitialAssignment.OrderDocument) = TYPE(Document.MaterialProviderOrder2_5)
			|					THEN CAST(Table.InitialAssignment.OrderDocument AS Document.MaterialProviderOrder2_5).Contract
			|			END,
			|			ISNULL(Table.InitialAssignment.Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef))) AS OriginalContract,
			|		
			|		ISNULL(Table.InitialAssignment.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) AS OriginalType,
			|		
			|		ISNULL(
			|			CASE
			|				WHEN VALUETYPE(Table.NewAssignment.OrderDocument) = TYPE(Document.MaterialProviderOrder2_5)
			|					THEN CAST(Table.NewAssignment.OrderDocument AS Document.MaterialProviderOrder2_5).Partner
			|			END,
			|			ISNULL(Table.NewAssignment.Partner, VALUE(Catalog.Partners.EmptyRef))) AS NewPartner,
			|		
			|		ISNULL(
			|			CASE
			|				WHEN VALUETYPE(Table.NewAssignment.OrderDocument) = TYPE(Document.MaterialProviderOrder2_5)
			|					THEN CAST(Table.NewAssignment.OrderDocument AS Document.MaterialProviderOrder2_5).Contract
			|			END,
			|			ISNULL(Table.NewAssignment.Contract, VALUE(Catalog.CounterpartyContracts.EmptyRef))) AS NewContract,
			|		
			|		ISNULL(Table.NewAssignment.AssignmentType, VALUE(Enum.AssignmentTypes.EmptyRef)) AS NewType
			|	FROM
			|		TTTable AS Table) AS Table
			|WHERE
			|	NOT CASE
			// Transfer under one Contract is acceptable.
			
			
			|		WHEN Table.OriginalType IN(
			
			
			|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
			|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
			|			THEN Table.NewType IN(
			
			
			|						VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
			|						VALUE(Enum.AssignmentTypes.Giveaway2_5))
			|					AND Table.SourcePartner = Table.NewPartner
			|					AND Table.OriginalContract = Table.NewContract
			|				OR Table.NewType = VALUE(Enum.AssignmentTypes.Own)
			|		WHEN Table.NewType IN(
			
			
			|				VALUE(Enum.AssignmentTypes.ProvidedMaterialsForStage22),
			|				VALUE(Enum.AssignmentTypes.Giveaway2_5))
			|			THEN Table.OriginalType = VALUE(Enum.AssignmentTypes.Own)
			|		ELSE TRUE
			|	END";
			
			Query.SetParameter("Table", Table);
			Selection = Query.Execute().Select();
			
			While Selection.Next() Do
				
				
				OriginalTypeNewGivers = Selection.OriginalType = Enums.AssignmentTypes.ProvidedMaterialsForStage22
						
						
						Or Selection.OriginalType = Enums.AssignmentTypes.Giveaway2_5;
						
				NewTypeNewGivers = Selection.NewType = Enums.AssignmentTypes.ProvidedMaterialsForStage22
						
						
						Or Selection.NewType = Enums.AssignmentTypes.Giveaway2_5;
				
				MessageText = "";
				
				
				If MessageText <> "" Then
					
				ElsIf OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve
						Or OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments Then
					
					If Selection.OriginalType = Enums.AssignmentTypes.ProvidedMaterialsForStage22 Then
						
						MessageText = NStr("vi = 'Đối với nguyên vật liệu đặt riêng theo công đoạn sản xuất (%1) cho phép đặt riêng theo công đoạn sản xuất của hợp đồng này hoặc hợp đồng nói chung. Trong dòng %2 đã chỉ định mục đích theo hợp đồng khác (%3)';
											|ru = 'Для материалов, обособленных под производственный этап (%1) допускается обособление под производственные этапы этого же договора или под договор в целом. В строке %2 указано назначение по другому договору (%3)';
											|en = 'Materials assigned for the production stage (%1) can be assigned for the production stages of the same contract or the whole contract. In line %2, the assignment for another contract is specified (%3)'; fa = 'Materials assigned for the production stage (%1) can be assigned for the production stages of the same contract or the whole contract. In line %2, the assignment for another contract is specified (%3)';
											|it = 'Materials assigned for the production stage (%1) can be assigned for the production stages of the same contract or the whole contract. In line %2, the assignment for another contract is specified (%3)';
											|pl = 'Materials assigned for the production stage (%1) can be assigned for the production stages of the same contract or the whole contract. In line %2, the assignment for another contract is specified (%3)';
											|tr = 'Üretim aşaması (%1) altında ayrılmış malzemeler için, aynı sözleşmenin üretim aşamaları veya bir bütün olarak sözleşme kapsamında ayrılmasına izin verilmektedir. %2 satırındaki başka sözleşme (%3) kapsamında atama belirtilmiştir'");
						
						
					ElsIf Selection.OriginalType = Enums.AssignmentTypes.Giveaway2_5 Then
						
						MessageText = NStr("vi = 'Đối với hàng hóa đặt riêng theo hợp đồng (%1) cho phép đặt riêng theo công đoạn sản xuất của hợp đồng này. Trong dòng %2 có chỉ định mục đích theo hợp đồng khác (%3)';
											|ru = 'Для товаров, обособленных под договор (%1) допускается обособление под производственные этапы этого же договора. В строке %2 указано назначение по другому договору (%3)';
											|en = 'Items assigned for the contract (%1) can be assigned for production stages of the same contract. In line %2, the assignment for another contract (%3) is specified'; fa = 'Items assigned for the contract (%1) can be assigned for production stages of the same contract. In line %2, the assignment for another contract (%3) is specified';
											|it = 'Items assigned for the contract (%1) can be assigned for production stages of the same contract. In line %2, the assignment for another contract (%3) is specified';
											|pl = 'Items assigned for the contract (%1) can be assigned for production stages of the same contract. In line %2, the assignment for another contract (%3) is specified';
											|tr = 'Sözleşme (%1) altında ayrılmış ürünler için, aynı sözleşmenin üretim aşamaları kapsamında ayrılmasına izin verilmektedir. %2  satırındaki başka sözleşme (%3) kapsamında atama belirtilmiştir'");
						
					EndIf;
					
					MessageText = StrTemplate(MessageText, Selection.OriginalContract, Selection.LineNumber, Selection.NewContract);
					
				Else
					
					If Selection.NewType = Enums.AssignmentTypes.ProvidedMaterialsForStage22 Then
						
						MessageText = NStr("vi = 'Không cho phép đặt riêng theo công đoạn sản xuất trong hợp đồng (%1) từ số dư đặt riêng theo hợp đồng khác (hoặc các công đoạn sản xuất). Trong dòng %2 đã chỉ ra mục đích theo hợp đồng khác (%3)';
											|ru = 'Не допускается обособление под производственные этапы договора (%1) из остатков обособленных под другой договор (или производственные этапы). В строке %2 указано назначение по другому договору (%3)';
											|en = 'Cannot assign for the contract production stages (%1) from the inventory assigned for another contract or production stages. In line %2, the assignment for another contract (%3) is specified'; fa = 'Cannot assign for the contract production stages (%1) from the inventory assigned for another contract or production stages. In line %2, the assignment for another contract (%3) is specified';
											|it = 'Non è ammessa la separazione di materiali per le fasi di produzione del contratto (%1) dai residui di materiali separati per un altro contratto ( o per altre fasi di produzione). Nella riga %2 è indicata l''assegnazione relativa a un altro contratto (%3)';
											|pl = 'Nie jest dopuszczalne oddzielenie dla etapów produkcyjnych umowy (%1) z sald, oddzielonych dla innej umowy (lub etapów produkcyjnych). W wierszu %2 jest podane przeznaczenie według innej umowy (%3)';
											|tr = 'Sözleşmenin (%1) üretim aşamaları kapsamında, başka bir sözleşme (veya üretim aşamaları) kapsamında ayrılan bakiyelerden ayrıştırılmasına izin verilmez. Satırda %2, başka bir sözleşme kapsamındaki atama belirtildi (%3)'");
						
						
					ElsIf Selection.NewType = Enums.AssignmentTypes.Giveaway2_5 Then
						
						MessageText = NStr("vi = 'Không cho phép đặt riêng theo hợp đồng (%1) từ số dư đặt riêng theo các hợp đồng với bên đặt gia công (hoặc các công đoạn sản xuất). Trong dòng %2 đã chỉ ra mục đích theo hợp đồng khác (%3)';
											|ru = 'Не допускается обособление под договор (%1) из остатков обособленных под другие договоры с давальцем (или производственные этапы). В строке %2 указано назначение по другому договору (%3)';
											|en = 'Cannot assign for the contract (%1) from the inventory assigned for other subcontracting agreements or production stages. In line %2, assignment under another contract (%3) is specified'; fa = 'Cannot assign for the contract (%1) from the inventory assigned for other subcontracting agreements or production stages. In line %2, assignment under another contract (%3) is specified';
											|it = 'Non è ammessa la separazione di materiali per contratto (%1) dai residui di materiali separati per altri contratti con il committente (o per altre fasi di produzione). Nella riga %2 è indicata l''assegnazione relativa a un altro contratto (%3)';
											|pl = 'Nie jest dopuszczalne oddzielenie dla umowy (%1) z sald oddzielnych dla innych umów z dostawcą (lub etapów produkcyjnych). W wierszu %2 jest podane przeznaczenie według innej umowy (%3)';
											|tr = 'Müşteri ile yapılan diğer sözleşmeler (veya üretim aşamaları) kapsamında ayrılan bakiyelerden sözleşme (%1) kapsamında ayrım yapılmasına izin verilmez. Satırda %2, başka bir sözleşme kapsamındaki atama belirtildi(%3)'");
						
					EndIf;
					
					MessageText = StrTemplate(MessageText, Selection.NewContract, Selection.LineNumber, Selection.OriginalContract);
					
				EndIf;
				
				Field = CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "NewAssignment");
				Common.MessageToUser(MessageText, DataKey, Field, "Object", Cancel);
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return;
	
EndProcedure

#EndRegion

#Region InventoryKinds

Function TemporaryDocumentDataTables(OnEmptyAssignment)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	|	VALUE(Catalog.Users.EmptyRef) AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.GoodsAssignmentAdjustments) AS BusinessOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|		OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END AS QuantityByGBRN,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	TableOfGoods.InitialAssignment AS Purpose,
	|	TableOfGoods.NewAssignment AS NewAssignment,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TRUE AS SelectTypesOfStocks,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber
	|INTO TableOfGoodsWithPackagingUnits
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	CASE
	|		WHEN &OnEmptyAssignment
	|			THEN TableOfGoods.NewAssignment = VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE TableOfGoods.NewAssignment <> VALUE(Catalog.Assignments.EmptyRef)
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoodsWithPackagingUnits.LineNumber AS LineNumber,
	|	TableOfGoodsWithPackagingUnits.Products AS Products,
	|	TableOfGoodsWithPackagingUnits.Characteristic AS Characteristic,
	|	TableOfGoodsWithPackagingUnits.Series AS Series,
	|	TableOfGoodsWithPackagingUnits.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoodsWithPackagingUnits.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoodsWithPackagingUnits.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableOfGoodsWithPackagingUnits.Count AS Count,
	|	TableOfGoodsWithPackagingUnits.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfGoodsWithPackagingUnits.Warehouse AS Warehouse,
	|	TableOfGoodsWithPackagingUnits.SalesOpportunity AS SalesOpportunity,
	|	TableOfGoodsWithPackagingUnits.Purpose AS Purpose,
	|	TableOfGoodsWithPackagingUnits.NewAssignment AS NewAssignment,
	|	TableOfGoodsWithPackagingUnits.VATRate AS VATRate,
	|	TableOfGoodsWithPackagingUnits.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoodsWithPackagingUnits.VATAmount AS VATAmount,
	|	TableOfGoodsWithPackagingUnits.CommissionAmount AS CommissionAmount,
	|	TableOfGoodsWithPackagingUnits.AmountVATRemuneration AS AmountVATRemuneration,
	|	TableOfGoodsWithPackagingUnits.SelectTypesOfStocks AS SelectTypesOfStocks,
	|	TableOfGoodsWithPackagingUnits.CCDNumber AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TableOfGoodsWithPackagingUnits AS TableOfGoodsWithPackagingUnits
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackingTable_
	|		ON TableOfGoodsWithPackagingUnits.Package = PackingTable_.Ref
	|		AND (PackingTable_.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem))
	|WHERE
	|	PackingTable_.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(Subquery.LineNumber),
	|	Subquery.Products,
	|	Subquery.Characteristic,
	|	Subquery.Series,
	|	Subquery.BatchesIndicationStatus,
	|	Subquery.ItemsLocationAttributes,
	|	Subquery.ItemsLocationAttributesReceipt,
	|	MIN(Subquery.Count),
	|	MIN(Subquery.QuantityByGBRN),
	|	Subquery.Warehouse,
	|	Subquery.SalesOpportunity,
	|	Subquery.Purpose,
	|	Subquery.NewAssignment,
	|	Subquery.VATRate,
	|	Subquery.AmountIncludingVAT,
	|	Subquery.VATAmount,
	|	Subquery.CommissionAmount,
	|	Subquery.AmountVATRemuneration,
	|	Subquery.SelectTypesOfStocks,
	|	Subquery.CCDNumber
	|FROM
	|	(SELECT
	|		MIN(TableOfGoodsWithPackagingUnits.LineNumber) AS LineNumber,
	|		TableOfGoodsWithPackagingUnits.Products AS Products,
	|		TableOfGoodsWithPackagingUnits.Characteristic AS Characteristic,
	|		TableOfGoodsWithPackagingUnits.Package AS Package,
	|		TableOfGoodsWithPackagingUnits.Series AS Series,
	|		TableOfGoodsWithPackagingUnits.BatchesIndicationStatus AS BatchesIndicationStatus,
	|		TableOfGoodsWithPackagingUnits.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoodsWithPackagingUnits.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|		SUM(TableOfGoodsWithPackagingUnits.Count) AS Count,
	|		SUM(TableOfGoodsWithPackagingUnits.QuantityByGBRN) AS QuantityByGBRN,
	|		TableOfGoodsWithPackagingUnits.Warehouse AS Warehouse,
	|		TableOfGoodsWithPackagingUnits.SalesOpportunity AS SalesOpportunity,
	|		TableOfGoodsWithPackagingUnits.Purpose AS Purpose,
	|		TableOfGoodsWithPackagingUnits.NewAssignment AS NewAssignment,
	|		TableOfGoodsWithPackagingUnits.VATRate AS VATRate,
	|		TableOfGoodsWithPackagingUnits.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoodsWithPackagingUnits.VATAmount AS VATAmount,
	|		TableOfGoodsWithPackagingUnits.CommissionAmount AS CommissionAmount,
	|		TableOfGoodsWithPackagingUnits.AmountVATRemuneration AS AmountVATRemuneration,
	|		TableOfGoodsWithPackagingUnits.SelectTypesOfStocks AS SelectTypesOfStocks,
	|		TableOfGoodsWithPackagingUnits.CCDNumber AS CCDNumber
	|	FROM
	|		TableOfGoodsWithPackagingUnits AS TableOfGoodsWithPackagingUnits
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackingTable_
	|			ON TableOfGoodsWithPackagingUnits.Package = PackingTable_.Ref
	|			AND (PackingTable_.PackageType = VALUE(Enum.TypesOfItemsPackages.CargoItem))
	|	GROUP BY
	|		TableOfGoodsWithPackagingUnits.Products,
	|		TableOfGoodsWithPackagingUnits.Characteristic,
	|		TableOfGoodsWithPackagingUnits.Package,
	|		TableOfGoodsWithPackagingUnits.Series,
	|		TableOfGoodsWithPackagingUnits.BatchesIndicationStatus,
	|		TableOfGoodsWithPackagingUnits.ItemsLocationAttributes,
	|		TableOfGoodsWithPackagingUnits.ItemsLocationAttributesReceipt,
	|		TableOfGoodsWithPackagingUnits.Warehouse,
	|		TableOfGoodsWithPackagingUnits.SalesOpportunity,
	|		TableOfGoodsWithPackagingUnits.Purpose,
	|		TableOfGoodsWithPackagingUnits.NewAssignment,
	|		TableOfGoodsWithPackagingUnits.VATRate,
	|		TableOfGoodsWithPackagingUnits.AmountIncludingVAT,
	|		TableOfGoodsWithPackagingUnits.VATAmount,
	|		TableOfGoodsWithPackagingUnits.CommissionAmount,
	|		TableOfGoodsWithPackagingUnits.AmountVATRemuneration,
	|		TableOfGoodsWithPackagingUnits.SelectTypesOfStocks,
	|		TableOfGoodsWithPackagingUnits.CCDNumber) AS Subquery
	|GROUP BY
	|	Subquery.Products,
	|	Subquery.Characteristic,
	|	Subquery.Series,
	|	Subquery.BatchesIndicationStatus,
	|	Subquery.ItemsLocationAttributes,
	|	Subquery.ItemsLocationAttributesReceipt,
	|	Subquery.Warehouse,
	|	Subquery.SalesOpportunity,
	|	Subquery.Purpose,
	|	Subquery.NewAssignment,
	|	Subquery.VATRate,
	|	Subquery.AmountIncludingVAT,
	|	Subquery.VATAmount,
	|	Subquery.CommissionAmount,
	|	Subquery.AmountVATRemuneration,
	|	Subquery.SelectTypesOfStocks,
	|	Subquery.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|		OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.OriginWarehouse AS OriginWarehouse,
	|	Dimension.StorageLocation AS Warehouse,
	|	TableTypesOfStocks_.SalesOpportunity AS SalesOpportunity,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|		LEFT JOIN Catalog.InventoryKinds AS CatInventoryOwnerAttribute
	|		ON (CatInventoryOwnerAttribute.Ref = TableTypesOfStocks_.InventoryOwnerAttribute)
	|WHERE
	|	NOT (CatInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND CatInventoryOwnerAttribute.GoodsOwner = UNDEFINED)
	|
	|INDEX BY
	|	ItemsLocationAttributes";
		
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
		And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
		And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
		AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
		Goods);
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Date", Date);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds.Unload(New Structure("NewAssignmentIsEmpty", OnEmptyAssignment)));
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("OnEmptyAssignment", OnEmptyAssignment);
	
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
	|WHERE
	|	TableOfGoods.Products.ItemsType <> VALUE(Enum.ItemsTypes.OperationService)
	|;
	|");
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	RowFilter = New Structure("NewAssignment", Catalogs.Assignments.EmptyRef());
	LinesWithEmptyAssignment = Goods.FindRows(RowFilter);
	
	ThereIsEmptyPurpose      = LinesWithEmptyAssignment.Count() > 0;
	ThereIsFilledPurpose = LinesWithEmptyAssignment.Count() <> Goods.Count();
	
	RefillInventoryKinds = InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	InventoryTypesAreOverfilled = False;
	
	If ThereIsEmptyPurpose Then
		
		FillInEmptyInventoryTypeAssignmentAttribute(LinesWithEmptyAssignment);
		
		TempTablesManager = TemporaryDocumentDataTables(True);
		
		If Not Posted
			Or RefillInventoryKinds
			Or CheckChangesToDocumentDetails(TempTablesManager)
			Or CheckProductChanges_(TempTablesManager) Then
			
			InventoryTypesAreOverfilled = True;
			
			If ThereIsFilledPurpose Then
				TypesOfStocksByFilledPurpose = InventoryKinds.Unload(New Structure("NewAssignmentIsEmpty", False));
				
				InventoryKinds.Clear();
			EndIf;
			
			FillParameters = ParametersForFillingInventoryTypes(True);
			InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
												TempTablesManager,
												Cancel,
												FillParameters);
			
			For Each RowOfTables In InventoryKinds Do
				RowOfTables.NewAssignmentIsEmpty = True;
			EndDo;
			
			If ThereIsFilledPurpose Then
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfStocksByFilledPurpose);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ThereIsFilledPurpose Then
		
		TempTablesManager = TemporaryDocumentDataTables(False);
		
		If Not Posted
			Or RefillInventoryKinds
			Or CheckChangesToDocumentDetails(TempTablesManager)
			Or CheckProductChanges_(TempTablesManager) Then
			
			InventoryTypesAreOverfilled = True;
			
			If ThereIsEmptyPurpose Then
				TypesOfStocksByEmptyDestination = InventoryKinds.Unload(New Structure("NewAssignmentIsEmpty", True));
				
				InventoryKinds.Clear();
			EndIf;
		
			FillParameters = ParametersForFillingInventoryTypes(False);
			
			InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
												TempTablesManager,
												Cancel,
												FillParameters);
			
			If ThereIsEmptyPurpose Then
				TMCommonUse.AddRowsToTable(InventoryKinds, TypesOfStocksByEmptyDestination);
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If InventoryTypesAreOverfilled Then
		NamesOfGroupingColumns		= "ItemsLocationAttributes, ItemsLocationAttributesReceipt,
										|InventoryOwnerAttributeGoodsReceipt, InventoryOwnerAttribute, NewAssignmentIsEmpty, CCDNumber";
		NamesOfSummationColumns	= "Count, QuantityByGBRN";
		
		InventoryKinds.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
		
		FillInAnalyticsInventoryTypesRegistration();
	EndIf;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|		TableOfGoods.Count AS Count
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|		-TableTypesOfStocks_.Count AS Count
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesReceipt
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure FillInEmptyInventoryTypeAssignmentAttribute(GoodsWithEmptyDestination)
	
	If Not InventoryOwnerAttributesAreSpecifiedManually Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	TableTypesOfStocks_ = InventoryKinds.Unload();
	TableTypesOfStocks_.Indexes.Add("ItemsLocationAttributes");
	
	For Each LineProducts_ In GoodsWithEmptyDestination Do
		
		GoodsQuantity = LineProducts_.Count;
		
		TheStructureOfTheSearch.ItemsLocationAttributes = LineProducts_.ItemsLocationAttributes;
		
		For Each InventoryLine In TableTypesOfStocks_.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = TableTypesOfStocks_.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.NewAssignmentIsEmpty	= True;
			NewRow.Count				= Count;
			NewRow.QuantityByGBRN		= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = TableTypesOfStocks_.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		TableTypesOfStocks_.Delete(TableRow);
	EndDo;
	
	InventoryKinds.Load(TableTypesOfStocks_);
	
EndProcedure

Procedure FillInAnalyticsInventoryTypesRegistration()
	
	TableTypesOfStocks_ = InventoryKinds.Unload();
	TableTypesOfStocks_.Indexes.Add("ItemsLocationAttributes");
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	InventoryTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	InventoryTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute
	|INTO TTTableInventory
	|FROM
	|	&InventoryKinds AS InventoryTable
	|
	|INDEX BY
	|	InventoryOwnerAttribute
	|;
	|
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	InventoryTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DataOfInventory.Organization					AS Organization,
	|	VALUE(Enum.InventoryTypes.OwnGoods)	AS InventoryType,
	|	ProductData_1.FinancialAccountingGroup	AS FinancialAccountingGroup
	|FROM
	|	TTTableInventory AS InventoryTable
	|		INNER JOIN Catalog.InventoryKinds AS DataOfInventory
	|		ON InventoryTable.InventoryOwnerAttribute = DataOfInventory.Ref
	|		
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|		ON InventoryTable.ItemsLocationAttributes = Keys.Ref
	|		
	|		INNER JOIN Catalog.Products AS ProductData_1
	|		ON Keys.Products = ProductData_1.Ref
	|
	|WHERE
	|	DataOfInventory.SaleOfAnotherCompanyInventory = TRUE";
	
	ColumnsNames = "ItemsLocationAttributes, InventoryOwnerAttribute";
	
	Query.SetParameter("InventoryKinds", InventoryKinds.Unload(, ColumnsNames));
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		DefaultColumnNames = ColumnsNames + ", " + "InventoryOwnerAttributeGoodsReceipt";
		
		DefaultStockTypes = TableTypesOfStocks_.CopyColumns(DefaultColumnNames);
		DefaultStockTypes.Indexes.Add(ColumnsNames);
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			NewRow = DefaultStockTypes.Add();
			FillPropertyValues(NewRow, Selection);
			
			NewRow.InventoryOwnerAttributeGoodsReceipt = Catalogs.InventoryKinds.DocumentInventoryView(
													Selection.Organization,
													,
													Selection);
		EndDo;
	Else
		DefaultStockTypes = Undefined;
	EndIf;
	
	RowFilter = New Structure(ColumnsNames);
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In Goods Do
		
		GoodsQuantity = RowOfGoods.Count;
		
		TheStructureOfTheSearch.ItemsLocationAttributes = RowOfGoods.ItemsLocationAttributes;
		
		For Each InventoryLine In TableTypesOfStocks_.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = TableTypesOfStocks_.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.ItemsLocationAttributesReceipt = RowOfGoods.ItemsLocationAttributesReceipt;
			
			If DefaultStockTypes = Undefined Then
				NewRow.InventoryOwnerAttributeGoodsReceipt = InventoryLine.InventoryOwnerAttribute;
			Else
				FillPropertyValues(RowFilter, NewRow);
				
				LoginData = DefaultStockTypes.Find(RowFilter);
				
				If LoginData <> Undefined Then
					NewRow.InventoryOwnerAttributeGoodsReceipt = LoginData.InventoryOwnerAttributeGoodsReceipt;
				EndIf;
			EndIf;
			
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
	ArrayOfRowsToDelete_1 = TableTypesOfStocks_.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		TableTypesOfStocks_.Delete(TableRow);
	EndDo;

	InventoryKinds.Load(TableTypesOfStocks_);
	
EndProcedure

Function ParametersForFillingInventoryTypes(OnEmptyAssignment)
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
	If Not OnEmptyAssignment Then
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	EndIf;
	Return FillParameters;
	
EndFunction

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.InventoryAssignmentAdjustment.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.InventoryAssignmentAdjustment.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.GoodsAssignmentAdjustments,
					Undefined,
					Undefined,
					Undefined);
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Arbitrary = "Warehouse";
	FieldsNames.Purpose = "InitialAssignment";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
	FieldsNames.Purpose = "NewAssignment";
	FieldsNames.ItemsLocationAttributes = "ItemsLocationAttributesReceipt";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#Region Other

Function BinLocationWarehousingIsUsed()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	TSGoods.Warehouse AS Warehouse,
		|	TSGoods.Premise AS Premise
		|INTO TSGoods
		|FROM
		|	&TSGoods AS TSGoods
		|
		|INDEX BY
		|	Warehouse,
		|	Premise
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	1 AS Field1
		|FROM
		|	InformationRegister.SettingsOfBinLocationWarehouses AS SettingsOfBinLocationWarehouses
		|		INNER JOIN TSGoods AS TSGoods
		|		ON SettingsOfBinLocationWarehouses.Warehouse = TSGoods.Warehouse
		|			AND SettingsOfBinLocationWarehouses.Premise = TSGoods.Premise
		|WHERE
		|	SettingsOfBinLocationWarehouses.UseBinLocationWarehousing
		|	AND SettingsOfBinLocationWarehouses.StartDateOfUsingWarehouseBinSystem <= &Date
		|	AND (NOT SettingsOfBinLocationWarehouses.Premise = VALUE(Catalog.Warerooms.EmptyRef)
		|			OR (NOT SettingsOfBinLocationWarehouses.Warehouse.UseWarerooms
		|				OR &Date < SettingsOfBinLocationWarehouses.Warehouse.StartDateOfWareroomUse))";
		
	Query.SetParameter("TSGoods", Goods.Unload(,"Warehouse, Premise"));
	Query.SetParameter("Date",
		?(ValueIsFilled(Date), Date, CurrentSessionDate()));
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Procedure CheckTypeOfAppointments(Cancel)
	
	If ValueIsFilled(Purpose)
		And Common.ObjectAttributeValue(Purpose, "AssignmentType") = Enums.AssignmentTypes.DeliveryForPrincipal Then
		MessageText = NStr("vi = 'Trong giá trị điều chỉnh không cho phép dùng giá trị này';
							|ru = 'В корректировке назначения нельзя использовать назначение данного типа.';
							|en = 'You cannot use an assignment of this type in the assignment adjustment.'; fa = 'You cannot use an assignment of this type in the assignment adjustment.';
							|it = 'Nella correzione della destinazione non si può usare la destinazione di questo tipo.';
							|pl = 'W korekcie przeznaczenia nie można wykorzystywać przeznaczenia danego typu.';
							|tr = 'Bu tür bir atamayı, bir atama ayarlamasında kullanılamaz.'");
		Common.MessageToUser(MessageText, , "Purpose", "Object", Cancel);
	EndIf;
	
	ThisIsWithdrawalOfReserve = OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserve;
	
	ThisIsWithdrawalOfReserveForManyPurposes = OperationKind = Enums.KindsOfAssignmentAdjustmentOperations.RemoveFromReserveForMultipleAssignments;
	
	TemplateForMultiPurposeReserveWithdrawalMessage  = NStr("vi = 'Trong cột ""Đích"" trong hàng %1, không thể sử dụng mục đích của loại này.';
															|ru = 'В колонке ""Назначение"" в строке %1 нельзя использовать назначение данного типа.';
															|en = 'In the ""Assignment"" column, in the line %1, you cannot use this type of assignment.'; fa = 'In the ""Assignment"" column, in the line %1, you cannot use this type of assignment.';
															|it = 'Nella colonna ""Destinazione"" nella riga %1 non si può usare questo tipo di destinazione.';
															|pl = 'W kolumnie ""Przeznaczenie"" w wierszu %1 nie można używać przeznaczenie danego typu.';
															|tr = 'Bu tür bir atama, %1 satırın atama sütununda kullanılamaz.'");
	ReserveWithdrawalMessageTemplate = NStr("vi = 'Trong cột ""Giá trị mới"" trong hàng %1, không thể sử dụng mục đích của loại này.';
											|ru = 'В колонке ""Новое назначение"" в строке %1 нельзя использовать назначение данного типа.';
											|en = 'In the ""New assignment"" column, in the line %1, you cannot use this type of assignment.'; fa = 'In the ""New assignment"" column, in the line %1, you cannot use this type of assignment.';
											|it = 'Nella colonna ""Nuova destinazione"" nella riga %1 non si può usare questo tipo di destinazione.';
											|pl = 'W kolumnie ""Nowe przeznaczenie"" w wierszu %1 nie można używać przeznaczenia danego typu.';
											|tr = 'Bu tür bir atama %1 satırın ""Yeni atama"" sütununda kullanılmamalı.'");
	ResurgationMessageTemplate = NStr("vi = 'Trong cột ""Giá trị ban đầu"" trong dòng %1, không thể sử dụng giá trị loại này.';
										|ru = 'В колонке ""Исходное назначение"" в строке %1 нельзя использовать назначение данного типа.';
										|en = 'In the ""Initial assignment"" column, in the line %1, you cannot use this type of assignment.'; fa = 'In the ""Initial assignment"" column, in the line %1, you cannot use this type of assignment.';
										|it = 'Nella colonna ""Valore di riferimento"" nella riga %1 non si può usare questo tipo di destinazione.';
										|pl = 'W kolumnie ""Przeznaczenie źródłowe"" w wierszu %1 nie można używać przeznaczenia danego typu.';
										|tr = 'Bu tür bir atama, %1satırın ""Orijinal atama"" sütununda kullanılmamalı.'");
	
	If ThisIsWithdrawalOfReserveForManyPurposes Then
		MessageTemplate = TemplateForMultiPurposeReserveWithdrawalMessage;
		NameOfPurposeField = "InitialAssignment";
	ElsIf ThisIsWithdrawalOfReserve Then
		MessageTemplate = ReserveWithdrawalMessageTemplate;
		NameOfPurposeField = "NewAssignment";
	Else
		MessageTemplate = ResurgationMessageTemplate;
		NameOfPurposeField = "InitialAssignment";
	EndIf;
	
	DataKey = TMCommonUse.DataKeyForMessageToUser(ThisObject);
	
	Query = New Query("
	|SELECT
	|	Goods.NameOfPurposeField  AS PurposeField,
	|	Goods.LineNumber        AS LineNumber
	|INTO GoodsTable
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	Goods.NameOfPurposeField
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber
	|FROM
	|	GoodsTable
	|
	|	LEFT JOIN Catalog.Assignments AS AssignmentsData
	|		ON GoodsTable.PurposeField = AssignmentsData.Ref
	|WHERE
	|	AssignmentsData.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|");
	
	Query.Text = StrReplace(Query.Text, "NameOfPurposeField", NameOfPurposeField);
	Query.SetParameter("Goods", Goods.Unload(,"LineNumber, "+NameOfPurposeField));
	ProductData_9 = Query.Execute().Select();
	
	While ProductData_9.Next() Do
		MessageText = StrTemplate(MessageTemplate, ProductData_9.LineNumber);
		Field = CommonClientServer.PathToTabularSection("Goods", ProductData_9.LineNumber, NameOfPurposeField);
		Common.MessageToUser(MessageText, DataKey, Field, "Object", Cancel);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
