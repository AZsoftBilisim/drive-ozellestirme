#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Calculates the amount and date of receipt of non-canceled raw material delivery lines.
//
// Returns:
//  Structure - structure with the fields "Amount", "Data accesses".
//
Function CollateralOrderData() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Goods.Products    AS Products,
	|	Goods.Sum           AS Sum,
	|	Goods.DateOfReceipt AS DateOfReceipt
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SUM(Goods.Sum), 0)                               AS Sum,
	|	ISNULL(MAX(Goods.DateOfReceipt), DATETIME(1, 1, 1)) AS DateOfReceipt
	|FROM
	|	Goods AS Goods";
	
	Query.SetParameter("Goods", UsedMaterials.Unload(, "Products, Sum, DateOfReceipt"));
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return New Structure("Sum, DateOfReceipt", Selection.Sum, Selection.DateOfReceipt);
	
EndFunction

// Calculates the number of undelivered request lines
//
// Returns:
//  Number - the number of undelivered rows.
//
Function NumberOfOrderLines() Export
	
	Return ManufacturedProduct.FindRows(New Structure("Canceled", False)).Count();
	
EndFunction

// Calculates the amount of undelivered order lines
//
// Returns:
//  Number - the sum of the undelivered lines.
//
Function SumOfOrderedRows() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.AmountIncludingVAT    AS AmountIncludingVAT,
	|	Goods.Canceled     AS Canceled
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SUM(Goods.AmountIncludingVAT), 0) AS AmountIncludingVAT
	|FROM
	|	Goods AS Goods
	|WHERE
	|	NOT Goods.Canceled";
	
	Query.SetParameter("Goods", ManufacturedProduct.Unload(, "Products, AmountIncludingVAT, Canceled"));
	
	Upload0 = Query.Execute().Unload();
	
	SumOfOrderedRows = Upload0[0].AmountIncludingVAT;
	
	Return SumOfOrderedRows;
	
EndFunction

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
	
	If AdditionalParameters <> Undefined Then
		
		OrdersServer.AdjustOrderLines(ThisObject, AdditionalParameters);
		
	EndIf;
	
	Status = Enums.StatusesOfMaterialProviderOrders[NewStatus];
	
	Return CheckFilling();
	
EndFunction

// Corrects lines that had not been issued a receipt or warehouse warrant or there are differences in the measured products.
//
// Parameters:
// 		ParametersStructure - Structure - Structure of adjustment parameters, constructor: order Server.Structurecorrectionslist of orders().
//
// Returns:
// 		Structure
// 		* Number of rows - the Number of canceled / adjusted rows
// 		* Adoration amount - The amount of increase in the order due to excess shipment of measured goods.
//
Function AdjustOrderLines(ParametersStructure) Export
	
	If Not ParametersStructure.CancelUnprocessedLines
	   And Not (ParametersStructure.CorrectMeasuringGoods
			 Or ParametersStructure.AdjustTheMeasuredGoodsUponAcceptance) Then
		Return OrdersServer.ResultOfUndoingUnprocessedRows(Undefined)
	EndIf;
	
	NumberOfAdjustedRows = 0;
	
	AdjustProducts = 
		(ParametersStructure.CancelUnprocessedLines Or ParametersStructure.CorrectMeasuringGoods)
		And (ParametersStructure.TabularSectionName = "Goods" Or ParametersStructure.TabularSectionName = "ManufacturedProduct");
		
	AdjustMaterials = 
		ParametersStructure.CancelUnprocessedLines 
		Or ParametersStructure.AdjustTheMeasuredGoodsUponAcceptance
			And (ParametersStructure.TabularSectionName = "Goods"
			   Or ParametersStructure.TabularSectionName = "UsedMaterials");
	
	If Not ParametersStructure.CheckBalance Then
		
		PropertiesOfCanceledRow = New Structure;
		PropertiesOfCanceledRow.Insert("Canceled",            True);
		PropertiesOfCanceledRow.Insert("BatchesIndicationStatus", 0);
		PropertiesOfCanceledRow.Insert("CancellationReason",       ParametersStructure.CancellationReason);
		// Quality control
		PropertiesOfCanceledRow.Insert("ToControlQuality", False);
		PropertiesOfCanceledRow.Insert("QualityConfirmationDate", Undefined);
		
		If AdjustProducts Then
			
			For Each LineProducts_ In ManufacturedProduct Do
				
				If Not LineProducts_.Canceled Then
					FillPropertyValues(LineProducts_, PropertiesOfCanceledRow);
					NumberOfAdjustedRows = NumberOfAdjustedRows + 1;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If AdjustMaterials Then
			
			For Each LineProducts_ In UsedMaterials Do
				
				If Not LineProducts_.Canceled Then
					FillPropertyValues(LineProducts_, PropertiesOfCanceledRow);
					NumberOfAdjustedRows = NumberOfAdjustedRows + 1;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		Return OrdersServer.ResultOfUndoingUnprocessedRows(NumberOfAdjustedRows);
		
	EndIf;
	
	If AdjustProducts Then
		
		FillParameters = OrdersServer.FillOptionsForCancelingRows();
		FillParameters.RegisterManager  = AccumulationRegisters.ShipmentAndReturnReferences;
		FillParameters.TabularSectionName = "ManufacturedProduct";
		FillParameters.DataPaths.Insert("Purpose", "Purpose");
		
		CancellationOptions = OrdersServer.OptionsForCancelingOrderLines();
		CancellationOptions.CancellationReason = ?(ParametersStructure.CancelUnprocessedLines,
			ParametersStructure.CancellationReason, Catalogs.ReasonsForSaleOrderCancellation.VarianceOnDimensionalGoodsShipment);
		CancellationOptions.AdjustAmount = True;
		CancellationOptions.CancelOnlyMeasuredGoods = Not ParametersStructure.CancelUnprocessedLines
			And ParametersStructure.CorrectMeasuringGoods;
		CancellationOptions.CorrectMeasuringGoods = ParametersStructure.CorrectMeasuringGoods;
		
		NumberOfAdjustedRows = NumberOfAdjustedRows
			+ OrdersServer.UndoUnprocessedShippingLines(ThisObject, FillParameters, CancellationOptions).RowsCount;
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.MaterialProviderOrder2_5));
		ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.ManufacturedProduct);
		
	EndIf;
	
	If AdjustMaterials Then
		
		FillParameters = OrdersServer.FillOptionsForCancelingRows();
		FillParameters.RegisterManager  = AccumulationRegisters.PurchaseOrders;
		FillParameters.TabularSectionName = "UsedMaterials";
		
		CancellationOptions = OrdersServer.OptionsForCancelingOrderLines();
		CancellationOptions.AdjustAmount = True;
		CancellationOptions.CancelOnlyMeasuredGoods = Not ParametersStructure.CancelUnprocessedLines
			And ParametersStructure.AdjustTheMeasuredGoodsUponAcceptance;
		CancellationOptions.CorrectMeasuringGoods = ParametersStructure.AdjustTheMeasuredGoodsUponAcceptance;
		
		NumberOfAdjustedRowsUpTo = NumberOfAdjustedRows;
		NumberOfAdjustedRows = NumberOfAdjustedRows
			+ OrdersServer.CancelUnprocessedAcceptanceLines(ThisObject, FillParameters, CancellationOptions).RowsCount;
		
		If Not NumberOfAdjustedRowsUpTo = NumberOfAdjustedRows Then
			For Each LineProducts_ In UsedMaterials Do
				If LineProducts_.Canceled Then
					LineProducts_.ToControlQuality = False;
					LineProducts_.QualityConfirmationDate = Undefined;
				EndIf;
			EndDo;
		EndIf;
		
		SeriesSpecificationParameters = New FixedStructure(
			ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.MaterialProviderOrder2_5));
		ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.UsedMaterials);
		
	EndIf;
	
	Return OrdersServer.ResultOfUndoingUnprocessedRows(NumberOfAdjustedRows);
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	InitializeDocumentBeforeFilling();
	
	DateEmpty = '00010101';
	
	MaximumRowCodeMaterials = 0;
	ProductsMaximumRowCode = 0;
	Status						   = Enums.StatusesOfMaterialProviderOrders.NotApproved;
	DateOfShipment				   = DateEmpty;
	DateOfReceipt				   = DateEmpty;
	ApprovalDate			   = DateEmpty;
	NumberAccordingToPartnerData		   = "";
	DateAccordingToInformationFromPartner		   = DateEmpty;
	Purpose					   = Undefined;
	AssignmentMaterials			   = Undefined;
	Basis					   = Undefined;
	
	// If the order of the giver is copied with the old business transaction, then it is necessary to check the conformity of the product types.
	CheckProductTypes = False;
	If CopiedObject.BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5 Then
		
		CheckProductTypes = True;
		
		LinesToDelete = New Array;
		
		ItemsTypes =
			Common.ObjectsAttributeValue(
				ManufacturedProduct.Unload(, "Products").UnloadColumn("Products"),
				"ItemsType");
		
		ManufacturedProductsProduced =
			BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
			Or BusinessOperation = Enums.BusinessTransactions.Subcontracting2_5
			Or BusinessOperation = Enums.BusinessTransactions.RepairProductsFromProvidedMaterials2_5;
		
		WorksAreBeingCarriedOut =
			BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5
			Or BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
			Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5;
		
	EndIf;
	
	For Each TSRow In ManufacturedProduct Do
		
		If CheckProductTypes Then
			If ManufacturedProductsProduced
				And Not WorksAreBeingCarriedOut
					And ItemsTypes[TSRow.Products] = Enums.ItemsTypes.Work_5
				Or Not ManufacturedProductsProduced
					And WorksAreBeingCarriedOut
					And Not ItemsTypes[TSRow.Products] = Enums.ItemsTypes.Work_5 Then
				LinesToDelete.Add(TSRow);
				Continue;
			EndIf;
		EndIf;
		
		TSRow.RowCode    = 0;
		TSRow.DateOfShipment = DateEmpty;
		TSRow.Canceled = False;
		TSRow.CancellationReason = Catalogs.ReasonsForSaleOrderCancellation.EmptyRef();
		
	EndDo;
	
	If CheckProductTypes Then
		For Each CurrentData In LinesToDelete Do
			ManufacturedProduct.Delete(CurrentData);
		EndDo;
	EndIf;
	
	EmptyAssignment = Catalogs.Assignments.EmptyRef();
	For Each TSRow In UsedMaterials Do
		
		TSRow.RowCode       = 0;
		TSRow.DateOfReceipt = DateEmpty;
		TSRow.Purpose      = EmptyAssignment;
		TSRow.Canceled        = False;
		
	EndDo;
	
	InitializeDocument();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	MaterialProviderOrder2_5Localization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)

	InitializeDocumentBeforeFilling();
	
	Author = Users.CurrentUser();
	
	BasisType = TypeOf(FillingData);
	
	If BasisType = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
		FillInTransactionDocument(FillingData);
	ElsIf BasisType = Type("CatalogRef.Partners") Then
		FillInDocumentBasedOnPartner(FillingData);
	ElsIf BasisType = Type("DocumentRef.SubcontractOrder2_5") Then
		
		OrderData = Common.ObjectAttributesValues(FillingData, "Posted, Status");
		If Not OrderData.Posted Then
			Raise NStr("vi = 'Có thể nhập đơn hàng của người đặt gia công chỉ dựa trên đơn đặt hàng gia công được kết chuyển.';
						|ru = 'Ввод заказа давальца возможен только на основании проведенного заказа переработчику.';
						|en = 'You can generate a subcontracting sales order only based on a posted subcontracting purchase order.'; fa = 'You can generate a subcontracting sales order only based on a posted subcontracting purchase order.';
						|it = 'Ввод заказа давальца возможен только на основании проведенного заказа переработчику.';
						|pl = 'You can generate a subcontracting sales order only based on a posted subcontracting purchase order.';
						|tr = 'Tedarikçi siparişinin girişi sadece verilen fason üretici siparişi temelinde mümkündür.'");;
		EndIf;
		
		If GetFunctionalOption("UseTollingOrderStatuses2_5")
			And (OrderData.Status = Enums.TollingOrderStatuses.NotApproved
				Or OrderData.Status = Enums.TollingOrderStatuses.Closed) Then
			Raise NStr("vi = 'Có thể nhập đơn hàng của người đặt gia công chỉ trên cơ sở đơn đặt hàng gia công được thống nhất và chưa kết thúc.';
						|ru = 'Ввод заказа давальца возможен только на основании согласованного и не завершенного заказа переработчику.';
						|en = 'You can generate a subcontracting sales order only based on an approved and not closed subcontracting purchase order.'; fa = 'You can generate a subcontracting sales order only based on an approved and not closed subcontracting purchase order.';
						|it = 'Ввод заказа давальца возможен только на основании согласованного и не завершенного заказа переработчику.';
						|pl = 'You can generate a subcontracting sales order only based on an approved and not closed subcontracting purchase order.';
						|tr = 'Tedarikçi siparişinin girişi sadece verilen fason üretici siparişinde mutabık kalınmış ve tamamlanmamış sipariş temelinde mümkündür.'");;
		EndIf;
		
		FillInDocumentOnBasisOfSubcontractPurchaseOrder(FillingData);
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.MaterialProviderOrder2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	
	MaterialProviderOrder2_5Localization.Filling(ThisObject, FillingData, StandardProcessing);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	
	FilledAttributes = ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	If FilledAttributes.Property("Organization")
		Or FilledAttributes.Property("Warehouse") Then
		FillParameters = Documents.MaterialProviderOrder2_5.ParametersForFillingInVATTaxation_(ThisObject);
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	EndIf;
	
	// Warehouses could be filled according to statistics - we will transfer them to the document tables.
	If ValueIsFilled(Warehouse) Then
		WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
		WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, ManufacturedProduct, False);
	EndIf;
	
	If ValueIsFilled(WarehouseForReceipt) Then
		WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(WarehouseForReceipt);
		WarehousesServer.FillInWarehousesInTablePart(WarehouseForReceipt, WarehouseGroup_, UsedMaterials, False);
	EndIf;
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse",   False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	#Region Rounding
	
	RoundingParameters = Documents.MaterialProviderOrder2_5.TSParametersForRounding();
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters["ManufacturedProduct"]);
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters["UsedMaterials"]);
	
	#EndRegion
		
	OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "ManufacturedProduct", "ProductsMaximumRowCode");
	OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "UsedMaterials", "MaximumRowCodeMaterials");
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	If Not NotShipInInstallments Then
		
		NewShipmentDate = Date(1, 1, 1);
		
		If ManufacturedProduct.Count() > 0 Then
			
			If Status = Enums.StatusesOfMaterialProviderOrders.Approved
			 Or Status = Enums.StatusesOfMaterialProviderOrders.ToProduce Then
				
				FilterParameters = New Structure;
				FilterParameters.Insert("Canceled", False);
				RequirementsForProvision = ManufacturedProduct.FindRows(FilterParameters);
				
				If RequirementsForProvision.Count() > 0 Then
					
					TableOfRowsToProvide = ManufacturedProduct.Unload(RequirementsForProvision, "DateOfShipment");
					TableOfRowsToProvide.Sort("DateOfShipment Asc");
					NewShipmentDate = TableOfRowsToProvide[0].DateOfShipment;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		DateOfShipment = NewShipmentDate;
		
	Else
		ProvisionInDocumentsServer.FillInShippingDatesInTable(DateOfShipment, ManufacturedProduct, "DateOfShipment");
	EndIf;
	
	// We will set the date of approval, if the document is agreed
	If Not ValueIsFilled(ApprovalDate)
	   And Not Status = Enums.StatusesOfMaterialProviderOrders.NotApproved Then
		ApprovalDate = CurrentSessionDate();
		ARAPAccountingServer.WhenChangingApprovalDate(ThisObject);
	EndIf;
	
	If ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments Then
		PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);
	Else
		PaymentID = Undefined;
	EndIf; 
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	ExecutionScheduleInContract = False;
	If ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		And ValueIsFilled(Contract) Then
		ExecutionScheduleInContract = Common.ObjectAttributeValue(Contract, "ExecutionScheduleIsSpecified");
	EndIf;
	
	If ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
		Or ExecutionScheduleInContract Then
		AmountPrepaymentBeforeGoodsIssue = 0;
		AmountOfPrepaymentBeforeShipment = 0;
	Else
		SalesServer.FillInAdvancePrepaymentAmounts(ThisObject);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.MaterialProviderOrder2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	StructureOfCollateralData = CollateralOrderData();
	
	DocumentAmount = SumOfOrderedRows();
	DepositValue = StructureOfCollateralData.Sum;
	
	If PaymentMethod <> Enums.PaymentForms.CashAccountPayment_ Then
		AttributesArray = New Array;
		AttributesArray.Add("CashAccount");
		CashServer.ClearUnusedProps(ThisObject, AttributesArray, New Array);
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.MaterialProviderOrder2_5);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.ManufacturedProduct);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters.UsedMaterials);
	
	#Region FillingAppointments
	
	// The appointment is checked only after checking the completion of the document,
	// since it is not guaranteed that all key Attributes
	// affecting the selection of appointments will be filled in before the check.
	If WriteMode = DocumentWriteMode.Posting Then
		
		DestinationPattern  = Documents.MaterialProviderOrder2_5.DestinationPattern(ThisObject);
		VerificationDetails_1 = "LineOfBusiness,Partner,Contract";
		
		Catalogs.Assignments.CheckFillBeforeRecording(Purpose, DestinationPattern, ThisObject, VerificationDetails_1, Cancel);
		
		DestinationTemplateMaterials = Documents.MaterialProviderOrder2_5.DestinationTemplateMaterials(ThisObject);
		
		If Catalogs.Assignments.PatternsAreEqual(DestinationPattern, DestinationTemplateMaterials) Then
			AssignmentMaterials = Purpose;
		Else
			Catalogs.Assignments.CheckFillBeforeRecording(
				AssignmentMaterials, DestinationTemplateMaterials, ThisObject, VerificationDetails_1, Cancel);
		EndIf;
		
		FillInEmptyAssignments();
		
	EndIf;
	
	#EndRegion
	
	If WriteMode = DocumentWriteMode.Posting Then
		TMCommonUse.FillInDocumentIDs(
			ThisObject, Metadata.Documents.MaterialProviderOrder2_5.TabularSections.ManufacturedProduct.Name);
	EndIf;
	
	MaterialProviderOrder2_5Localization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DestinationPattern          = Documents.MaterialProviderOrder2_5.DestinationPattern(ThisObject);
	DestinationTemplateMaterials = Documents.MaterialProviderOrder2_5.DestinationTemplateMaterials(ThisObject);
	VATActivityType        = VATAccountingERP.TypeOfVATTaxationActivity(VATTaxation);
	
	Catalogs.Assignments.OnWriteDocument(Purpose, DestinationPattern, ThisObject, Partner, VATActivityType);
	Catalogs.Assignments.OnWriteDocument(
		AssignmentMaterials, DestinationTemplateMaterials, ThisObject, Partner, VATActivityType);
	
	MaterialProviderOrder2_5Localization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	///////////////////////////////////////////////////////////////////////////
	// Auxiliary variable
	
	StatusOfDocumentIsConsistentAndHigher = False
		Or Status = Enums.StatusesOfMaterialProviderOrders.Approved
		Or Status = Enums.StatusesOfMaterialProviderOrders.ToProduce
		Or Status = Enums.StatusesOfMaterialProviderOrders.ToShip
		Or Status = Enums.StatusesOfMaterialProviderOrders.Closed;
	
	StatusOfDocumentForProductionAndAbove = False
		Or Status = Enums.StatusesOfMaterialProviderOrders.ToProduce
		Or Status = Enums.StatusesOfMaterialProviderOrders.ToShip
		Or Status = Enums.StatusesOfMaterialProviderOrders.Closed;
	
	NotCheckedAttributeArray = New Array;
	
	///////////////////////////////////////////////////////////////////////////
	// Checking the details

#Region TS__CharacteristicsQuantity

	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	
	CheckParameters.TSName = "ManufacturedProduct";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
		ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		
	CheckParameters.TSName = "UsedMaterials";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
		ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	QuantityVerificationParameters = Documents.MaterialProviderOrder2_5.TSParametersForRounding();
	
	ProductsServer.CheckQuantityFilling(
		ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters.ManufacturedProduct);
		
	ProductsServer.CheckQuantityFilling(
		ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters.UsedMaterials);
		
#EndRegion

#Region TS__Series
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.MaterialProviderOrder2_5);
	
	ParametersArray = New Array;
	ParametersArray.Add(SeriesSpecificationParameters.ManufacturedProduct);
	ParametersArray.Add(SeriesSpecificationParameters.UsedMaterials);
	ProductsServer.CheckSeriesCompletion(ThisObject,
		ParametersArray,
		Cancel,
		NotCheckedAttributeArray);
		
#EndRegion

#Region ProductsShipmentDateWarehouse
	
	NotCheckedAttributeArray.Add("ManufacturedProduct.DateOfShipment");
	
	EmbeddingParameters = Documents.MaterialProviderOrder2_5.AvailableRemainingEmbeddingOptions();
	ErrorsTable = ProvisionInDocumentsServer.TableOfFillingErrors(ThisObject, EmbeddingParameters);
	
	DateOfShipmentRequired_  = False;
	WarehouseIsRequired          = False;
	TextTemplateShipmentDate = NStr("vi = 'Chưa điền cột ""Ngày giao hàng"" trong dòng %LineNumber%của danh sách ""Thành phẩm""';
									|ru = 'Не заполнена колонка ""Дата отгрузки"" в строке %LineNumber% списка ""Выпускаемая продукция""';
									|en = 'Column ""Shipment date"" in line %LineNumber% of the ""Released products"" list is not filled in'; fa = 'Column ""Shipment date"" in line %LineNumber% of the ""Released products"" list is not filled in';
									|it = 'Non è compilata la colonna ""Data di spedizione"" nella riga %LineNumber% dell''elenco ""Prodotti in fabbricazione""';
									|pl = 'Nie wypełniono kolumny ""Data wysyłki"" w wierszu %LineNumber% listy ""Wypuszczane wiersze pozycji""';
									|tr = '""İmal edilen ürünler"" listesinin %LineNumber% satırında ""sevkiyat tarihi"" sütunu eksik'");
	WarehouseTextTemplate        = NStr("vi = 'Chưa điền cột ""Kho bãi"" trong dòng %LineNumber% của danh sách ""Thành phẩm""';
										|ru = 'Не заполнена колонка ""Склад"" в строке %LineNumber% списка ""Выпускаемая продукция""';
										|en = 'Column ""Warehouse"" in line %LineNumber% of the ""Released products"" list is not filled in'; fa = 'Column ""Warehouse"" in line %LineNumber% of the ""Released products"" list is not filled in';
										|it = 'Non è compilata la colonna ""Magazzino"" nella riga %LineNumber% dell''elenco ""Prodotti in fabbricazione""';
										|pl = 'Nie wypełniono kolumny ""Magazyn"" w wierszu %LineNumber% listy ""Wypuszczane wiersze pozycji""';
										|tr = '""İmal edilen ürünler"" listesinin %LineNumber% satırında ""Ambar"" sütunu doldurulmadı'");
	
	For CurIndex__ = 0 To ErrorsTable.Count() - 1 Do
		
		ErrorString = ErrorsTable[CurIndex__];
		
		If ErrorString.DateOfShipmentRequired_ And Not NotShipInInstallments And ErrorString.ShipmentDateNotFilledIn Then
			
			ErrorText   = StrReplace(TextTemplateShipmentDate, "%LineNumber%", ErrorString.LineNumber);
			PathToTop = CommonClientServer.PathToTabularSection("ManufacturedProduct", ErrorString.LineNumber, "DateOfShipment");
			Common.MessageToUser(ErrorText, ThisObject, PathToTop, , Cancel);
			
		EndIf;
		
		If ErrorString.WarehouseIsRequired And ValueIsFilled(Warehouse) And ErrorString.WarehouseIsNotFull Then
			
			ErrorText   = StrReplace(WarehouseTextTemplate, "%LineNumber%", ErrorString.LineNumber);
			PathToTop = CommonClientServer.PathToTabularSection("ManufacturedProduct", ErrorString.LineNumber, "Warehouse");
			Common.MessageToUser(ErrorText, ThisObject, PathToTop, , Cancel);
			
		EndIf;
		WarehouseIsRequired = WarehouseIsRequired Or ErrorString.WarehouseIsRequired;
		DateOfShipmentRequired_ = DateOfShipmentRequired_ Or ErrorString.DateOfShipmentRequired_;
		
	EndDo;
	
#EndRegion

#Region TS__ReasonForCancellationPriceAndAmount
	NotCheckedAttributeArray.Add("ManufacturedProduct.CancellationReason");
	
	For CurIndex__ = 0 To ManufacturedProduct.Count() - 1 Do
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
									|ru = 'в строке %LineNumber% списка ""Товары""';
									|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'w wierszu %LineNumber% listy ""Towary""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", ManufacturedProduct[CurIndex__].LineNumber);
		
		CurRow = ManufacturedProduct[CurIndex__];
		ErrorAddress = StrTemplate(
			NStr("vi = 'trong dòng %1 của danh sách ""Thành phẩm"".';
				|ru = 'в строке %1 списка ""Выпускаемая продукция"".';
				|en = 'in line %1 of the ""Released products"" list.'; fa = 'in line %1 of the ""Released products"" list.';
				|it = 'nella riga dell''elenco %1 ""Prodotti in fabbricazione"".';
				|pl = 'w wierszu %1 listy ""Wypuszczane wiersze pozycji"".';
				|tr = '""imal edilen ürünler"" listesinin %1 satırında'"),
			CurRow.LineNumber);
			
		// The date of shipment in pm Products must be at least the date of the document
		If Not NotShipInInstallments
			And ValueIsFilled(CurRow.DateOfShipment)
			And CurRow.DateOfShipment < BegOfDay(Date) Then
			
			ErrorText = NStr("vi = 'Ngày giao hàng %1 phải có ít nhất là ngày chứng từ %2';
							|ru = 'Дата отгрузки %1 должна быть не меньше даты документа %2';
							|en = 'Shipment date %1 must be not less than document date %2'; fa = 'Shipment date %1 must be not less than document date %2';
							|it = 'La data della spedizione %1 non deve essere inferiore alla data del documento %2';
							|pl = 'Data wysyłki %1 powinna być mniejsza niż data dokumentu %2';
							|tr = '%1 sevkiyatının tarihi, %2 belgesinin tarihinden daha önce olmamalıdır.'");
			ErrorText = StrTemplate(ErrorText, ErrorAddress, Format(Date,"DLF=DD"));
			KTCHPath     = CommonClientServer.PathToTabularSection("ManufacturedProduct", CurRow.LineNumber, "DateOfShipment");
			
			Common.MessageToUser(ErrorText, ThisObject, KTCHPath, , Cancel);
			
		EndIf;
		
		// The reason for cancellation is required in the lines with the Canceled sign
		If GetFunctionalOption("UseReasonsForSalesOrderCancellations")
			And CurRow.Canceled
			And Not ValueIsFilled(CurRow.CancellationReason) Then
			
			ErrorText = NStr("vi = 'Cần xác định lý do hủy %1';
							|ru = 'Необходимо указать причину отмены %1';
							|en = '%1 cancellation reason is required'; fa = '%1 cancellation reason is required';
							|it = 'È necessario specificare il motivo di annullamento %1';
							|pl = 'Należy wskazać przyczynę anulowania %1';
							|tr = '%1 iptal nedeni belirtilmelidir'");
			KTCHPath     = CommonClientServer.PathToTabularSection("ManufacturedProduct", CurRow.LineNumber, "CancellationReason");
			
			Common.MessageToUser(StrTemplate(ErrorText, ErrorAddress), ThisObject, KTCHPath, , Cancel);
			
		EndIf;
		
	EndDo;
#EndRegion

#Region TS__DateOfReceipt
	
	NotCheckedAttributeArray.Add("UsedMaterials.DateOfReceipt");
	
	For CurIndex__ = 0 To UsedMaterials.Count() - 1 Do
		
		CurRow = UsedMaterials[CurIndex__];
		
		ErrorAddress =
			StrTemplate(NStr("vi = 'trong dòng %1 của danh sách ""Nguyên vật liệu để sản xuất"".';
							|ru = 'в строке %1 списка ""Сырье и материалы для производства""';
							|en = 'in line %1 of the ""Raw and consumable materials for production"" list'; fa = 'in line %1 of the ""Raw and consumable materials for production"" list';
							|it = 'nella riga %1 dell''elenco ""Materie prime e materiali per la produzione""';
							|pl = 'w wierszu %1 listy ""Materiały do produkcji""';
							|tr = '""üretim için hammaddeler ve malzemeler"" listesinin %1 satırında'"), CurRow.LineNumber);
		
		// The date of receipt in the TS Materials is required only for orders in the Status Agreed and higher.
		If StatusOfDocumentIsConsistentAndHigher
		   And Not OneDateReceipt 
		   And Not ValueIsFilled(CurRow.DateOfReceipt)
		   And Not CurRow.Canceled
		   And CurRow.Action <> Enums.ActionsOnMaterialsToSubcontract.UseAvailable Then
			
			ErrorText = NStr("vi = 'Cột thiếu ""Ngày nhận""%1';
							|ru = 'Не заполнена колонка ""Дата поступления"" %1';
							|en = 'The ""Date of receipt"" column is not filled in%1'; fa = 'The ""Date of receipt"" column is not filled in%1';
							|it = 'La colonna ""Data dell''arrivo"" non è compilata %1';
							|pl = 'Nie wypełniono kolumny ""Дата поступления"" %1';
							|tr = '""Teslim alım tarihi"" sütunu eksik %1'");
			KTCHPath =
				CommonClientServer.PathToTabularSection("UsedMaterials", CurRow.LineNumber, "DateOfReceipt");
			
			Common.MessageToUser(
				StrTemplate(ErrorText, ErrorAddress), ThisObject, KTCHPath, , Cancel);
			
		EndIf;
		
		// The date of receipt of PM Goods must be at least the date of the document
		If Not NotShipInInstallments 
			And ValueIsFilled(CurRow.DateOfReceipt) 
			And CurRow.DateOfReceipt < BegOfDay(Date)
			And Not CurRow.Canceled
			And CurRow.Action <> Enums.ActionsOnMaterialsToSubcontract.UseAvailable Then
			
			ErrorText = NStr("vi = 'Ngày tiếp nhận không được nhỏ hơn ngày chứng từ %1%2';
							|ru = 'Дата поступления должна быть не меньше даты документа %1 %2';
							|en = 'Date of receipt cannot be less than document date %1 %2'; fa = 'Date of receipt cannot be less than document date %1 %2';
							|it = 'La data dell''arrivo non deve essere inferiore alla data del documento %1 %2';
							|pl = 'Data wpłaty powinna być nie mniejsza niż data dokumentu %1 %2';
							|tr = 'Kabul tarihi, %2 %1belgesinin tarihinden önce olmamalıdır'");
			ErrorText = StrTemplate(ErrorText, Format(Date, "DLF=DD"), ErrorAddress);
			KTCHPath =
				CommonClientServer.PathToTabularSection("UsedMaterials", CurRow.LineNumber, "DateOfReceipt");
			
			Common.MessageToUser(ErrorText, ThisObject, KTCHPath, , Cancel);
			
		EndIf;
		
	EndDo;
	
#EndRegion

#Region Doc_DateOfReceipt
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Canceled", False);
	FilterStructure1.Insert("Action", Enums.ActionsOnMaterialsToSubcontract.AcceptVMI);
	
	ThereAreVerifiableLines = UsedMaterials.FindRows(FilterStructure1).Count() > 0;
	
	If Not OneDateReceipt
	 Or Not StatusOfDocumentIsConsistentAndHigher
	 Or Not ThereAreVerifiableLines Then
		
		NotCheckedAttributeArray.Add("DateOfReceipt");
		
	EndIf;
	
	If OneDateReceipt
	   And ValueIsFilled(DateOfReceipt)
	   And DateOfReceipt < BegOfDay(Date) And UsedMaterials.Count() > 0
	   And ThereAreVerifiableLines Then
		
		ErrorText = NStr("vi = 'Ngày tiếp nhận không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата поступления должна быть не меньше даты документа %Date%';
						|en = 'Date of receipt cannot be before the document date: %Date%'; fa = 'Date of receipt cannot be before the document date: %Date%';
						|it = 'La data dell''arrivo non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data wpłaty powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Kabul tarihi, belgenin %Date% tarihinden daha önce olmamalıdır '");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		Common.MessageToUser(ErrorText, ThisObject, "DateOfReceipt", , Cancel);
		
	EndIf;
	
#EndRegion

#Region Doc_DateOfShipment
	
	AllLinesAreCanceled = TMCommonUse.AllLinesAreCanceled(ThisObject, "ManufacturedProduct", "Canceled");
	
	If NotShipInInstallments
		And ValueIsFilled(DateOfShipment)
		And DateOfShipment < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày giao hàng không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата отгрузки должна быть не меньше даты документа %Date%';
						|en = 'Shipment date cannot be less than document date%Date%'; fa = 'Shipment date cannot be less than document date%Date%';
						|it = 'La data della spedizione non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Sevkiyat tarihi, belgenin %Date% tarihinden daha önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		Common.MessageToUser(ErrorText, ThisObject, "DateOfShipment", , Cancel);
		
	EndIf;

	If Not DateOfShipmentRequired_ Or Not NotShipInInstallments Then
		NotCheckedAttributeArray.Add("DateOfShipment");
	EndIf;
	
	If Not NotShipInInstallments Or AllLinesAreCanceled Then
		NotCheckedAttributeArray.Add("Warehouse");
	EndIf;
	
#EndRegion

#Region Doc_ApprovalDate
	
	// The validity period of the order must be at least the date of the document
	If Status = Enums.StatusesOfMaterialProviderOrders.NotApproved
	   And ValueIsFilled(ApprovalDate)
	   And ApprovalDate < BegOfDay(Date) Then
		
		ErrorText = StrTemplate(
						NStr("vi = 'Ngày thống nhất không được nhỏ hơn ngày chứng từ %1';
							|ru = 'Дата согласования должна быть не меньше даты документа %1';
							|en = 'Date of approval must not be less than the %1 document date'; fa = 'Date of approval must not be less than the %1 document date';
							|it = 'La data di accordo non deve essere precedente alla data del documento %1';
							|pl = 'Data uzgodnienia powinna być nie mniejsza niż data dokumentu %1';
							|tr = 'Anlaşma tarihi, %1belgesinin tarihinden önce olmamalıdır'"),
						Format(Date, "DLF=DD"));
		
		Common.MessageToUser(ErrorText, ThisObject, "ApprovalDate",, Cancel);
		
	EndIf;
	
#EndRegion

#Region ManufacturedProductsWarehouse
	
	If Not WarehouseIsRequired
		Or BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		NotCheckedAttributeArray.Add("Warehouse");
	EndIf;
	
#EndRegion

#Region Doc_DateOfShipmentAndReceipt
	
	MinimumReceiptDate = DateOfShipment;
	
	If OneDateReceipt
	   And ValueIsFilled(DateOfReceipt)
	   And DateOfReceipt > MinimumReceiptDate Then
		MinimumReceiptDate = DateOfReceipt;
	Else
		For Each ContentLine In UsedMaterials Do
			If ValueIsFilled(ContentLine.DateOfReceipt)
			   And ContentLine.DateOfReceipt > MinimumReceiptDate Then
				MinimumReceiptDate = ContentLine.DateOfReceipt;
			EndIf;
		EndDo;
	EndIf;
	
	If NotShipInInstallments
		And ValueIsFilled(MinimumReceiptDate)
		And ValueIsFilled(DateOfShipment)
		And MinimumReceiptDate > DateOfShipment Then
		
		ErrorText = NStr("vi = 'Ngày giao hàng phải không ít hơn ngày nhận nguyên vật liệu';
						|ru = 'Дата отгрузки должна быть не меньше даты поступления материалов';
						|en = 'Shipment date should not be earlier than the date of material receipt'; fa = 'Shipment date should not be earlier than the date of material receipt';
						|it = 'La data della spedizione non deve essere inferiore alla data dell''arrivo dei materiali';
						|pl = 'Data wysyłki powinna być nie mniejsza niż data wpływu materiałów';
						|tr = 'Sevkiyat tarihi, malzemelerin teslim alım tarihinden önce olmamalıdır'");
		Common.MessageToUser(ErrorText, ThisObject, "DateOfShipment", , Cancel);
		
	EndIf;
	
	If OneDateReceipt Then
		
		DateToCheck = DateOfReceipt;
		
		If NotShipInInstallments Then
			CheckDate = DateOfShipment;
		Else
			
			CheckDate = Date(3999, 1, 1);
			For Each ProductionLine In ManufacturedProduct Do
				CheckDate = Min(ProductionLine.DateOfShipment, CheckDate);
			EndDo;
			
		EndIf;
		
		If ValueIsFilled(DateToCheck)
		   And ValueIsFilled(CheckDate)
		   And DateToCheck > CheckDate Then
			
			ErrorText = NStr("vi = 'Ngày tiếp nhận vật liệu phải nhỏ hơn ngày giao hàng';
							|ru = 'Дата поступления материалов должна быть меньше даты отгрузки продукции';
							|en = 'Date of material receipt must be less than shipment date'; fa = 'Date of material receipt must be less than shipment date';
							|it = 'La data dell''arrivo dei materiali deve essere inferiore alla data della spedizione prodotti';
							|pl = 'Data wpływu materiałów powinna być mniejsza niż daty wysyłki produkcji';
							|tr = 'Malzemelerin teslim alım tarihi, ürünlerin sevkiyat tarihinden önce olmalıdır'");
			Common.MessageToUser(ErrorText, ThisObject, "DateOfReceipt", , Cancel);
			
		EndIf;
		
	Else
		
		ProductShipmentDates = New Map;
		FilterSpecifications = New Structure("BillOfMaterials");
		
		If NotShipInInstallments Then
			CheckDate = DateOfShipment;
		Else
			CheckDate = Date(1, 1, 1);
		EndIf;
		
		For Each ContentLine In UsedMaterials Do
			
			DateToCheck = ContentLine.DateOfReceipt;
			
			If Not NotShipInInstallments Then
				
				If ProductShipmentDates[ContentLine.BillOfMaterials] = Undefined Then
					
					FilterSpecifications.BillOfMaterials = ContentLine.BillOfMaterials;
					
					PickedRows = ManufacturedProduct.FindRows(FilterSpecifications);
					For Each SelectedString In PickedRows Do
						CheckDate = Max(CheckDate, SelectedString.DateOfShipment);
					EndDo;
					
					ProductShipmentDates.Insert(ContentLine.BillOfMaterials, CheckDate);
					
				Else
					CheckDate = ProductShipmentDates[ContentLine.BillOfMaterials];
				EndIf;
				
			EndIf;
			
			If ValueIsFilled(DateToCheck)
			   And ValueIsFilled(CheckDate)
			   And DateToCheck > CheckDate Then
				
				ErrorText = NStr("vi = 'Ngày tiếp nhận nguyên liệu phải nhỏ hơn ngày giao sản phẩm tại dòng %1 của danh sách Nguyên vật liệu';
								|ru = 'Дата поступления материалов должна быть меньше даты отгрузки продукции в строке %1 списка Сырье и материалы';
								|en = 'The materials receipt date must be less than the manufactured products shipment date in line %1 of the Raw and consumable materials list'; fa = 'The materials receipt date must be less than the manufactured products shipment date in line %1 of the Raw and consumable materials list';
								|it = 'La data di arrivo dei materiali deve essere precedente alla data di spedizione di prodotti nella riga %1 dell''elenco Materie prime e materiali';
								|pl = 'Data wpływu materiałów powinna być mniejsza niż data wysyłki produkcji w wierszu %1 listy Surowce i materiały';
								|tr = 'Malzemelerin teslim alım tarihi, hammaddeler ve malzemeler listesinin %1 satırındaki ürünlerin sevkiyat tarihinden önce olmalıdır'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText, ContentLine.LineNumber);
				KTCHPath 	= CommonClientServer.PathToTabularSection("UsedMaterials", ContentLine.LineNumber, "DateOfReceipt");
				
				Common.MessageToUser(ErrorText, ThisObject, KTCHPath, , Cancel);
					
			
			EndIf;
			
		EndDo;
		
	EndIf;
	
#EndRegion

#Region Doc_Department
	
	NotCheckedAttributeArray.Add("Department");
	
	If Status <> Enums.StatusesOfMaterialProviderOrders.NotApproved
	   And Status <> Enums.StatusesOfMaterialProviderOrders.Approved
	   And Not ValueIsFilled(Department) Then 
		
		ErrorText = NStr("vi = 'Cần chỉ ra bộ phận';
						|ru = 'Необходимо указать подразделение';
						|en = 'Specify business unit'; fa = 'Specify business unit';
						|it = 'È necessario indicare reparto';
						|pl = 'Należy podać dział';
						|tr = 'Departman belirleyin.'");
		Common.MessageToUser(ErrorText, ThisObject, "Department", , Cancel);
		
	EndIf;
	
#EndRegion

#Region Doc_ProcessingService
	
	If BusinessOperation = Enums.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5
		Or BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5 Then
		NotCheckedAttributeArray.Add("VATRate");
		NotCheckedAttributeArray.Add("ProcessingService");
	EndIf;
	
#EndRegion

#Region Doc_FinishedProductBeingRepaired
	
	If Not BusinessOperation = Enums.BusinessTransactions.PerformRMUsingProvidedMaterials2_5
		Or Not GetFunctionalOption("UseItemVariants")
		Or Not Catalogs.Products.ItemVariantsAreUsed(UnderRepairProduct) Then
		NotCheckedAttributeArray.Add("UnderRepairVariant");
	EndIf;
	
	NotCheckedAttributeArray.Add("UnderRepairBatch"); // series can be specified, or you can not specify
	
#EndRegion

#Region Delivery
	GoodsDelivery.CheckDeliveryDetails(ThisObject, NotCheckedAttributeArray, Cancel);
#EndRegion

	RecipientVerificationParameters = New Structure;
	RecipientVerificationParameters.Insert("ToExpenseAs", True);
	RecipientVerificationParameters.Insert("Recipient",       Catalogs.BusinessStructure.EmptyRef());
	
	ErrorText = NStr("vi = 'Chưa điền trường ""Người nhận"" trong dòng %1 của danh sách ""Thành phẩm""';
					|ru = 'Не заполнено поле ""Получатель"" в строке %1 списка ""Продукция""';
					|en = 'The ""Recipient"" field is not filled in line %1 of the ""Manufactured products"" list'; fa = 'The ""Recipient"" field is not filled in line %1 of the ""Manufactured products"" list';
					|it = 'Non è compilato il campo ""Destinatario"" nella stringa %1 dell''elenco ""Prodotti""';
					|pl = 'Nie jest wypełnione pole ""Odbiorca"" w wierszu %1 listy ""Produkcja""';
					|tr = '""İmal edilen ürünler"" listesinin %1 satırındaki ""Alıcı"" alanı doldurulmamış'");
	
	RowsArray = ManufacturedProduct.FindRows(RecipientVerificationParameters);
	For Each TableRow In RowsArray Do
		
		Common.MessageToUser(
			StrTemplate(ErrorText, TableRow.LineNumber),
			ThisObject,
			CommonClientServer.PathToTabularSection("ManufacturedProduct", TableRow.LineNumber, "Recipient"),,
			Cancel);
		
	EndDo;
	
	ItemsAndDimensionsSelectionParameters = Documents.MaterialProviderOrder2_5.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(
		ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	QualityConfirmationDateRequired_ =
		Status = Enums.StatusesOfMaterialProviderOrders.ToProduce
			Or Status = Enums.StatusesOfMaterialProviderOrders.ToShip
			Or Status = Enums.StatusesOfMaterialProviderOrders.Closed;
		
	QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"UsedMaterials",
		NStr("vi = 'Nguyên vật liệu để sản xuất';
			|ru = 'Сырье и материалы для производства';
			|en = 'Raw and consumable materials for production'; fa = 'مواد اولیه و مصرفی برای تولید';
			|it = 'Materie prime e materiali per la produzione';
			|pl = 'Materiały do produkcji';
			|tr = 'Üretim için hammaddeler ve malzemeler'"),
		".DateOfReceipt",
		QualityConfirmationDateRequired_);
	
	///////////////////////////////////////////////////////////////////////////
	// Exclude checked the details of the further verification
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	///////////////////////////////////////////////////////////////////////////
	// The verification of the remaining details
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	StructureOfCollateralData = CollateralOrderData();
	
	DocumentAmount = SumOfOrderedRows();
	DepositValue = StructureOfCollateralData.Sum;
	
	PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject, Cancel);
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	
	If StatusOfDocumentForProductionAndAbove Then
		SalesServer.CheckShipmentBan(Partner, Cancel);
	EndIf;
	
	MaterialProviderOrder2_5Localization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
	MaterialProviderOrder2_5Localization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	
	MaterialProviderOrder2_5Localization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocumentBeforeFilling()
	
	If Not ValueIsFilled(BusinessOperation)
		Or BusinessOperation = Enums.BusinessTransactions.TollManufacturing2_5 Then
		BusinessOperation        = Enums.BusinessTransactions.Subcontracting2_5;
	EndIf;
	
	ProductionProcessType = TollingScheme.TypeOfProductionProcessOfOperation(BusinessOperation);
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Currency                       = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
	Organization                  = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse                        = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	WarehouseForReceipt             = SettingsValueCached.GetDefaultWarehouse(WarehouseForReceipt);
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Contract,
		?(ValueIsFilled(BankAccount), Undefined, BankAccount),
		?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
		CounterpartyBankAccount);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, BankAccount);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization = Organization;
	ParametersStructure.PaymentMethod = PaymentMethod;
	ParametersStructure.CashAccount		= CashAccount;
	
	CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	Priority = SettingsValueCached.GetDefaultPriority(Priority);
	
	SelectingTypeOfPrices = New Structure("Owner, AvailableForPurchase", Partner, True);
	PriceTypeMaterials = Catalogs.VendorPriceTypes.DefaultPriceType(PriceTypeMaterials, SelectingTypeOfPrices);
	
	If Not GetFunctionalOption("UseStatusesOfMaterialProviderOrders2_5") Then
		Status = Enums.StatusesOfMaterialProviderOrders.Closed;
	Else
		Status = Enums.StatusesOfMaterialProviderOrders.Approved;
	EndIf;
	
	ProvisionInDocumentsServer.FillInDefaultSecurityOption(ManufacturedProduct, True);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.MaterialProviderOrder2_5));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.ManufacturedProduct);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.UsedMaterials);
	
	// Clearing the destination when copying.
	EmptyAssignment = Catalogs.Assignments.EmptyRef();
	For Each TableRow In UsedMaterials Do
		TableRow.Purpose = EmptyAssignment;
	EndDo;
	
	StructureOfActions = New Structure;
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(UsedMaterials, StructureOfActions);
	
	FillParameters = Documents.MaterialProviderOrder2_5.ParametersForFillingInVATTaxation_(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = ValueIsFilled(FillingData);
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.ProcessTSString(ThisObject, StructureOfActions, CachedValues);
	
	If Not CachedValues.ProcessedRows.Count() = 0 Then
		
		TableProduction = ManufacturedProduct.Unload();
		TableProduction.FillValues(VATRate, "VATRate");
		
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		BatchProcessingOfTablePartServer.TreatTS(TableProduction, StructureOfActions, Undefined);
		
		ManufacturedProduct.Load(TableProduction);
		
	EndIf;
	
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption();
	
EndProcedure

Procedure FillInTransactionDocument(FillingData)
	
	SalesOpportunity  = FillingData;
	Partner = Common.ObjectAttributeValue(FillingData, "Partner");
	
EndProcedure

Procedure FillInDocumentBasedOnPartner(FillingData)
	
	If Not ValueIsFilled(FillingData) Then
		Return;
	EndIf;
	
	Partner = FillingData;
	
	PartnerDetails_ = Common.ObjectAttributesValues(Partner, "Client, Vendor");
	
	If Not PartnerDetails_.Client
	 Or Not PartnerDetails_.Vendor Then
		
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			ErrorText = NStr("vi = 'Việc nhập trên cơ sở được phép chỉ đối với các đối tác mà họ đồng thời là khách hàng và nhà cung cấp.';
							|ru = 'Ввод на основании доступен только для контрагентов, которые одновременно являются и клиентом, и поставщиком.';
							|en = 'Generation is available only for counterparties who are customers and vendors at the same time.'; fa = 'Generation is available only for counterparties who are customers and vendors at the same time.';
							|it = 'L''inserimento nella base è disponibile solo per le controparti che sono allo stesso tempo clienti e fornitori.';
							|pl = 'Wprowadzenie na podstawie jest dostępne tylko dla kontrahentów, którzy jednocześnie są zarówno nabywcą, jak i dostawcą.';
							|tr = 'Temele göre giriş yalnızca hem müşteri hem de tedarikçi olan cari hesaplar için geçerlidir.'");
		Else
			ErrorText = NStr("vi = 'Việc nhập trên cơ sở được phép chỉ đối với bạn hàng mà họ là khách hàng và nhà cung cấp.';
							|ru = 'Ввод на основании доступен только для партнеров, которые одновременно являются и клиентом, и поставщиком.';
							|en = 'Generation is available only for partners who are customers and vendors at the same time.'; fa = 'Generation is available only for partners who are customers and vendors at the same time.';
							|it = 'L''inserimento nella base è disponibile solo per i partner che sono allo stesso tempo clienti e fornitori.';
							|pl = 'Wprowadzenie na podstawie jest dostępne tylko dla partnerów, którzy jednocześnie są zarówno nabywcą, jak i dostawcą.';
							|tr = 'Temele göre giriş yalnızca hem müşteri hem de tedarikçi olan iş ortakları için geçerlidir.'");
		EndIf;
		
		Raise ErrorText;
		
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
EndProcedure

#Region FillingInBySubcontractPurchaseOrder

Procedure FillInDocumentOnBasisOfSubcontractPurchaseOrder(FillingData)
	
	Query = New Query;
	If Common.DebugMode() Then
		Query.TempTablesManager = New TempTablesManager;
	EndIf;
	
	Query.Text = FillInQueryTextOnBasisOfSubcontractedPurchaseOrder();
	Query.SetParameter("Basis", FillingData);
	
	Result = Query.ExecuteBatch();
	
	HeaderAttributes                 = Result[Result.UBound() - 5].Select();
	TableOfManufacturedProductsAtGiver      = Result[Result.UBound() - 4].Unload();
	TableOfManufacturedProductsFromProcessor = Result[Result.UBound() - 3].Unload();
	TableServices                  = Result[Result.UBound() - 2].Unload();
	TableMaterialsFromGiver      = Result[Result.UBound() - 1].Unload();
	TableMaterialsFromProcessor = Result[Result.UBound()].Unload();
	
	If HeaderAttributes.Next() Then
		FillPropertyValues(ThisObject, HeaderAttributes);
		PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
		
		If Not ValueIsFilled(Organization) Then
			Common.MessageToUser(NStr("vi = 'Chưa tìm thấy doanh nghiệp-người nhận gia công. Hãy kiểm tra sự tương ứng ""MST"", ""MĐK"" trong các danh mục doanh nghiệp và đối tác.';
										|ru = 'Не найдена организация-переработчик. Проверьте соответствие ""ИНН"", ""КПП"" в справочниках организаций и контаргентов.';
										|en = 'Cannot find the subcontractor company. Check whether ""TIN"" and ""KPP"" of the Companies and Counterparties catalogs match.'; fa = 'Cannot find the subcontractor company. Check whether ""TIN"" and ""KPP"" of the Companies and Counterparties catalogs match.';
										|it = 'Не найдена организация-переработчик. Проверьте соответствие ""ИНН"", ""КПП"" в справочниках организаций и контаргентов.';
										|pl = 'Cannot find the subcontractor company. Check whether ""TIN"" and ""KPP"" of the Companies and Counterparties catalogs match.';
										|tr = 'Fason üretici iş yeri bulunamadı. İş yerlerinin ve cari hesapların kataloglarındaki ""VKN"" ve ""KPP"" uyumluluğunu kontrol edin.'"));
		EndIf;
		
		If Not ValueIsFilled(Counterparty) Then
			Common.MessageToUser(NStr("vi = 'Chưa tìm thấy đối tác-người đặt gia công. Hãy kiểm tra sự tương ứng ""MST"", ""MĐK"" trong các doanh nghiệp và đối tác.';
										|ru = 'Не найден контрагент-давалец. Проверьте соответствие ""ИНН"", ""КПП"" в справочниках организаций и контаргентов.';
										|en = 'Cannot find the material provider counterparty. Check whether ""TIN"" and ""KPP"" of the Companies and Counterparties catalogs match.'; fa = 'Cannot find the material provider counterparty. Check whether ""TIN"" and ""KPP"" of the Companies and Counterparties catalogs match.';
										|it = 'Не найден контрагент-давалец. Проверьте соответствие ""ИНН"", ""КПП"" в справочниках организаций и контаргентов.';
										|pl = 'Cannot find the material provider counterparty. Check whether ""TIN"" and ""KPP"" of the Companies and Counterparties catalogs match.';
										|tr = 'Tedarikçi cari hesabı bulunamadı. İş yerlerinin ve cari hesapların kataloglarındaki ""VKN"" ve ""KPP"" uyumluluğunu kontrol edin.'"));
		EndIf;
		
	EndIf;
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	#Region ManufacturedProduct
	
	ToDistributeManufacturedProductsOfProcessorToManufacturedProductsOfGiver(TableOfManufacturedProductsAtGiver, TableOfManufacturedProductsFromProcessor, TableServices);
	ManufacturedProduct.Load(TableOfManufacturedProductsAtGiver);
	If ManufacturedProduct.Count() = 0 Then
		Common.MessageToUser(NStr("vi = 'Đã tạo đơn hàng của người đặt gia công cho tất cả sản phẩm của đơn đặt hàng gia công.';
									|ru = 'Заказы давальца уже оформлены на всю продукцию заказа переработчику.';
									|en = 'Subcontracting sales orders are already registered for all products of the subcontracting purchase order.'; fa = 'Subcontracting sales orders are already registered for all products of the subcontracting purchase order.';
									|it = 'Заказы давальца уже оформлены на всю продукцию заказа переработчику.';
									|pl = 'Subcontracting sales orders are already registered for all products of the subcontracting purchase order.';
									|tr = 'Tedarikçinin siparişleri, fason üretici satın alma siparişinin tüm imal edilen ürünleri için zaten düzenlenmiştir.'"));
	EndIf;
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(ThisObject, Documents.MaterialProviderOrder2_5);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages", BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	StructureOfActions.Insert("RecalculatePriceByAmount",        "Count");
	LinesToFillInSpecification = New Array;
	RowsToProcess = New Array;
	ItemData_3 = New Array;
	
	For Each CurrentData In ManufacturedProduct Do
		
		CurrentData.VATRate = VATRate;
		
		If NotShipInInstallments Then
			CurrentData.DateOfShipment = DateOfShipment;
		EndIf;
		
		If Not ValueIsFilled(CurrentData.BillOfMaterials) Then
			
			ItemData_3.Add(Documents.MaterialProviderOrder2_5.ItemData_3(ThisObject, CurrentData));
			LinesToFillInSpecification.Add(CurrentData);
			
		EndIf;
		
		RowsToProcess.Add(CurrentData);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		ManufacturedProduct,
		CachedValues);
	
	ProductDataManagement.FillInSpecificationInLines(
		LinesToFillInSpecification, ItemData_3, BOMSelectionParameters,, True);
	
	#EndRegion
	
	#Region UsedMaterials
	
	DistributeMaterialsOfProcessorToMaterialsOfGiver(TableMaterialsFromGiver, TableMaterialsFromProcessor);
	UsedMaterials.Load(TableMaterialsFromGiver);
	If UsedMaterials.Count() = 0 Then
		Common.MessageToUser(NStr("vi = 'Đã tạo đơn hàng của người đặt gia công cho tất cả nguyên vật liệu của đơn đặt hàng gia công.';
									|ru = 'Заказы давальца уже оформлены на все материалы заказа переработчику.';
									|en = 'Subcontracting sales orders are already registered for all materials of the subcontracting purchase order.'; fa = 'Subcontracting sales orders are already registered for all materials of the subcontracting purchase order.';
									|it = 'Заказы давальца уже оформлены на все материалы заказа переработчику.';
									|pl = 'Subcontracting sales orders are already registered for all materials of the subcontracting purchase order.';
									|tr = 'Tedarikçinin siparişleri, fason üretici satın alma siparişinin tüm malzemeleri için zaten düzenlenmiştir.'"));
	EndIf;
	
	Specifications = ManufacturedProduct.UnloadColumn("BillOfMaterials");
	Specifications = CommonClientServer.CollapseArray(Specifications);
	
	For Each CurrentData In UsedMaterials Do
		
		If OneDateReceipt Then
			CurrentData.DateOfReceipt = DateOfReceipt;
		EndIf;
		
		If Specifications.Count() = 1 Then
			CurrentData.BillOfMaterials = Specifications[0];
		ElsIf Specifications.Find(CurrentData.BillOfMaterials) = Undefined Then
			CurrentData.BillOfMaterials = Undefined;
		EndIf;
		
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages", BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	StructureOfActions.Insert("RecalculatePriceByAmount",       "Count");
	StructureOfActions.Insert("FillInActionForRecyclableMaterials");
	
	BatchProcessingOfTablePartServer.TreatTS(UsedMaterials, StructureOfActions, CachedValues);
	
	#EndRegion
	
EndProcedure

Function FillInQueryTextOnBasisOfSubcontractedPurchaseOrder()
	
	QueryText =
	"SELECT ALLOWED
	|	OrderData.Ref AS Ref
	|INTO GeneratedOrders
	|FROM
	|	Document.MaterialProviderOrder2_5 AS OrderData
	|WHERE
	|	OrderData.Basis = &Basis
	|	AND OrderData.Posted
	|	AND NOT OrderData.Status = VALUE(Enum.StatusesOfMaterialProviderOrders.NotApproved)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Order specifications by Expense group numbers
	|SELECT ALLOWED
	|	ManufacturedProducts.CostGroupNumber AS CostGroupNumber,
	|	ManufacturedProducts.BillOfMaterials      AS BillOfMaterials
	|INTO OrderSpecifications
	|FROM
	|	Document.SubcontractOrder2_5.ManufacturedProducts AS ManufacturedProducts
	|WHERE
	|	ManufacturedProducts.Ref = &Basis
	|	AND ManufacturedProducts.Ref.GroupCosts IN(
	|		VALUE(Enum.CostGroupingsInTollingOrder.ByProductBOM),
	|		VALUE(Enum.CostGroupingsInTollingOrder.ByProductBOMAndAssignments))
	|	AND NOT ManufacturedProducts.Canceled
	|
	|GROUP BY
	|	ManufacturedProducts.CostGroupNumber,
	|	ManufacturedProducts.BillOfMaterials
	|
	|INDEX BY
	|	CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MIN(OrderData.Organization) AS Organization,
	|	MIN(OrderData.Counterparty)  AS Counterparty,
	|	MIN(OrderData.Partner)     AS Partner,
	|	MIN(OrderData.Contract)     AS Contract,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.Warehouse) = 1
	|			THEN MIN(OrderData.Warehouse)
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END                             AS Warehouse,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.WarehouseForReceipt) = 1
	|			THEN MIN(OrderData.WarehouseForReceipt)
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END                             AS WarehouseForReceipt,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.Department) = 1
	|			THEN MIN(OrderData.Department)
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END                             AS Department,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.VATRate) = 1
	|			THEN MIN(OrderData.VATRate)
	|		ELSE VALUE(Catalog.VATRates.EmptyRef)
	|	END                             AS VATRate,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.LineOfBusiness) = 1
	|			THEN MIN(OrderData.LineOfBusiness)
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END                             AS LineOfBusiness,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.FinancialAccountingGroup) = 1
	|			THEN MIN(OrderData.FinancialAccountingGroup)
	|		ELSE VALUE(Catalog.FinancialAccountingGroupsOfARAP.EmptyRef)
	|	END                             AS FinancialAccountingGroup,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.BankAccount) = 1
	|			THEN MIN(OrderData.BankAccount)
	|		ELSE VALUE(Catalog.CompaniesBankAccounts.EmptyRef)
	|	END                             AS BankAccount,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.CounterpartyBankAccount) = 1
	|			THEN MIN(OrderData.CounterpartyBankAccount)
	|		ELSE VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|	END                             AS CounterpartyBankAccount,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.CashAccount) = 1
	|			THEN MIN(OrderData.CashAccount)
	|		ELSE VALUE(Catalog.CashAccounts.EmptyRef)
	|	END                             AS CashAccount,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.Shipper) = 1
	|			THEN MIN(OrderData.Shipper)
	|		ELSE VALUE(Catalog.Counterparties.EmptyRef)
	|	END                             AS Shipper,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.GoodsRecipient) = 1
	|			THEN MIN(OrderData.GoodsRecipient)
	|		ELSE VALUE(Catalog.Counterparties.EmptyRef)
	|	END                             AS GoodsRecipient,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.ShipperBankAccount) = 1
	|			THEN MIN(OrderData.ShipperBankAccount)
	|		ELSE VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|	END                             AS ShipperBankAccount,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.GoodsRecipientBankAccount) = 1
	|			THEN MIN(OrderData.GoodsRecipientBankAccount)
	|		ELSE VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|	END                             AS GoodsRecipientBankAccount,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.ContactPerson) = 1
	|			THEN MIN(OrderData.ContactPerson)
	|		ELSE VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
	|	END                             AS ContactPerson,
	|	CASE
	|		WHEN COUNT(DISTINCT OrderData.ProcessingService) = 1
	|			THEN MIN(OrderData.ProcessingService)
	|		ELSE """"
	|	END                             AS ProcessingService
	|INTO AttributesOfGeneratedOrder
	|FROM
	|	GeneratedOrders AS GeneratedOrders
	|	
	|	INNER JOIN Document.MaterialProviderOrder2_5 AS OrderData
	|	ON OrderData.Ref = GeneratedOrders.Ref
	|
	|HAVING
	|	MIN(OrderData.Organization) IS NOT NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CASE
	|		WHEN OrderDetails.Organization IS NULL
	|			THEN CatCompanies.Ref
	|		ELSE OrderDetails.Organization
	|	END                                    AS Organization,
	|	CASE
	|		WHEN OrderDetails.Counterparty IS NULL
	|			THEN CatCounterparties.Ref
	|		ELSE OrderDetails.Counterparty
	|	END                                    AS Counterparty,
	|	CASE
	|		WHEN OrderDetails.Partner IS NULL
	|			THEN CatCounterparties.Partner
	|		ELSE OrderDetails.Partner
	|	END                                    AS Partner,
	|	CASE
	|		WHEN OrderDetails.Contract IS NULL
	|			THEN CatContracts.Ref
	|		ELSE OrderDetails.Contract
	|	END                                    AS Contract,
	|	CASE
	|		WHEN OrderDetails.CounterpartyBankAccount IS NULL
	|			AND ISNULL(CatContracts.BankAccount, VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)) = 
	|				VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|			THEN CatBankAccounts.Ref
	|		WHEN OrderDetails.CounterpartyBankAccount IS NULL
	|			THEN CatContracts.BankAccount
	|		ELSE OrderDetails.CounterpartyBankAccount
	|	END                                    AS CounterpartyBankAccount,
	|	OrderDetails.Warehouse                    AS Warehouse,
	|	OrderDetails.WarehouseForReceipt         AS WarehouseForReceipt,
	|	CASE
	|		WHEN OrderDetails.Department IS NULL
	|			THEN CatContracts.Department
	|		ELSE OrderDetails.Department
	|	END                                    AS Department,
	|	CASE
	|		WHEN OrderDetails.LineOfBusiness IS NULL
	|			AND CatContracts.LineOfBusiness IS NULL
	|			THEN SubcontractOrder.LineOfBusiness
	|		WHEN CatContracts.LineOfBusiness IS NULL
	|			THEN OrderDetails.LineOfBusiness
	|		ELSE CatContracts.LineOfBusiness
	|	END                                    AS LineOfBusiness,
	|	CASE
	|		WHEN CatContracts.FinancialAccountingGroup IS NULL
	|			THEN OrderDetails.FinancialAccountingGroup
	|		ELSE CatContracts.FinancialAccountingGroup
	|	END                                    AS FinancialAccountingGroup,
	|	OrderDetails.VATRate                AS VATRate,
	|	OrderDetails.BankAccount           AS BankAccount,
	|	OrderDetails.CashAccount                    AS CashAccount,
	|	OrderDetails.Shipper         AS Shipper,
	|	OrderDetails.GoodsRecipient          AS GoodsRecipient,
	|	OrderDetails.ContactPerson           AS ContactPerson,
	|	OrderDetails.ShipperBankAccount AS ShipperBankAccount,
	|	OrderDetails.GoodsRecipientBankAccount  AS GoodsRecipientBankAccount,
	|	OrderDetails.ProcessingService      AS ProcessingService,
	|	SubcontractOrder.Date                  AS Date,
	|	SubcontractOrder.SalesOpportunity                AS SalesOpportunity,
	|	SubcontractOrder.Currency                AS Currency,
	|	SubcontractOrder.VATTaxation    AS VATTaxation,
	|	SubcontractOrder.PriceIncludesVAT       AS PriceIncludesVAT,
	|	SubcontractOrder.Ref                AS Basis,
	|	SubcontractOrder.NotShipInInstallments    AS OneDateReceipt,
	|	SubcontractOrder.DateOfShipment          AS DateOfReceipt,
	|	SubcontractOrder.OneDateReceipt AS NotShipInInstallments,
	|	SubcontractOrder.DateOfReceipt       AS DateOfShipment,
	|	SubcontractOrder.LeaveProductsAtSubcontractor AS KeepManufacturedProductsForSubcontracting,
	|	SubcontractOrder.Number                 AS NumberAccordingToPartnerData,
	|	SubcontractOrder.Date                  AS DateAccordingToInformationFromPartner,
	|	SubcontractOrder.ApprovalDate      AS ApprovalDate
	|FROM
	|	Document.SubcontractOrder2_5 AS SubcontractOrder
	|	
	|	LEFT JOIN AttributesOfGeneratedOrder AS OrderDetails
	|	ON TRUE
	|	
	|	LEFT JOIN Catalog.Counterparties AS Toller
	|	ON Toller.Ref = SubcontractOrder.Counterparty
	|	
	|	LEFT JOIN Catalog.Companies AS CatCompanies
	|	ON CatCompanies.TIN = Toller.TIN
	|	AND CatCompanies.CRTR = Toller.CRTR
	|	AND NOT CatCompanies.DeletionMark
	|	
	|	LEFT JOIN Catalog.Companies AS MaterialProvider
	|	ON MaterialProvider.Ref = SubcontractOrder.Organization
	|	
	|	LEFT JOIN Catalog.Counterparties AS CatCounterparties
	|	ON CatCounterparties.TIN = MaterialProvider.TIN
	|	AND CatCounterparties.CRTR = MaterialProvider.CRTR
	|	AND NOT CatCounterparties.DeletionMark
	|	
	|	LEFT JOIN Catalog.CounterpartyContracts AS MaterialProviderContract
	|	ON MaterialProviderContract.Ref = SubcontractOrder.Contract
	|
	|	LEFT JOIN Catalog.CounterpartyContracts AS CatContracts
	|	ON CatContracts.Organization = CatCompanies.Ref
	|	AND CatContracts.Counterparty = CatCounterparties.Ref
	|	AND CatContracts.Number = MaterialProviderContract.Number
	|	AND CatContracts.Date = MaterialProviderContract.Date
	|	AND CatContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND NOT CatContracts.DeletionMark
	|
	|	LEFT JOIN Catalog.CompaniesBankAccounts AS MaterialProviderAccount
	|	ON MaterialProviderAccount.Ref = SubcontractOrder.BankAccount
	|
	|	LEFT JOIN Catalog.CounterpartyBankAccounts AS CatBankAccounts
	|	ON CatBankAccounts.Owner = CatCounterparties.Ref
	|	AND CatBankAccounts.AccountNumber = MaterialProviderAccount.AccountNumber
	|	AND CatBankAccounts.BankBIC = MaterialProviderAccount.BankBIC
	|	AND NOT CatBankAccounts.Closed
	|	AND NOT CatBankAccounts.DeletionMark
	|
	|WHERE
	|	SubcontractOrder.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Output products of the giver of the order
	|SELECT ALLOWED
	|	ManufacturedProducts.Products      AS Products,
	|	ManufacturedProducts.Characteristic    AS Characteristic,
	|	ManufacturedProducts.CostGroupNumber AS CostGroupNumber,
	|	CASE
	|		WHEN ManufacturedProducts.Ref.GroupCosts IN(
	|				VALUE(Enum.CostGroupingsInTollingOrder.ByProductBOM),
	|				VALUE(Enum.CostGroupingsInTollingOrder.ByProductBOMAndAssignments))
	|			THEN ManufacturedProducts.BillOfMaterials
	|		ELSE VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|	END                             AS BillOfMaterials,
	|	SUM(ManufacturedProducts.Count) AS Count
	|FROM
	|	Document.SubcontractOrder2_5.ManufacturedProducts AS ManufacturedProducts
	|WHERE
	|	ManufacturedProducts.Ref = &Basis
	|	AND NOT ManufacturedProducts.Canceled
	|
	|GROUP BY
	|	ManufacturedProducts.Products,
	|	ManufacturedProducts.Characteristic,
	|	ManufacturedProducts.CostGroupNumber,
	|	CASE
	|		WHEN ManufacturedProducts.Ref.GroupCosts IN(
	|				VALUE(Enum.CostGroupingsInTollingOrder.ByProductBOM),
	|				VALUE(Enum.CostGroupingsInTollingOrder.ByProductBOMAndAssignments))
	|			THEN ManufacturedProducts.BillOfMaterials
	|		ELSE VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|	END
	|
	|UNION ALL
	|
	// By-products of the giver of the order
	|SELECT
	|	SideAndIntermediateRelease.Products      AS Products,
	|	SideAndIntermediateRelease.Characteristic    AS Characteristic,
	|	SideAndIntermediateRelease.CostGroupNumber AS CostGroupNumber,
	|	ISNULL(OrderSpecifications.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef)) AS BillOfMaterials,
	|	SUM(SideAndIntermediateRelease.Count) AS Count
	|FROM
	|	Document.SubcontractOrder2_5.SideAndIntermediateRelease AS SideAndIntermediateRelease
	|	
	|	LEFT JOIN OrderSpecifications AS OrderSpecifications
	|	ON OrderSpecifications.CostGroupNumber = SideAndIntermediateRelease.CostGroupNumber
	|
	|WHERE
	|	SideAndIntermediateRelease.Ref = &Basis
	|	AND NOT SideAndIntermediateRelease.Canceled
	|
	|GROUP BY
	|	SideAndIntermediateRelease.Products,
	|	SideAndIntermediateRelease.Characteristic,
	|	SideAndIntermediateRelease.CostGroupNumber,
	|	ISNULL(OrderSpecifications.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef))
	|
	|UNION ALL
	|
	// Output products of the giver of the stage
	|SELECT
	|	ManufacturedProducts.Products      AS Products,
	|	ManufacturedProducts.Characteristic    AS Characteristic,
	|	References.CostGroupNumber    AS CostGroupNumber,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
	|	SUM(ManufacturedProducts.Count) AS Count
	|FROM
	|	Document.SubcontractOrder2_5.References AS References
	|	
	|	INNER JOIN Document.ProductionStage2_2.ManufacturedProducts AS ManufacturedProducts
	|	ON ManufacturedProducts.Ref = References.ReferenceOrder
	|WHERE
	|	References.Ref = &Basis
	|	AND NOT ManufacturedProducts.Canceled
	|
	|GROUP BY
	|	ManufacturedProducts.Products,
	|	ManufacturedProducts.Characteristic,
	|	References.CostGroupNumber
	|
	|UNION ALL
	|
	// By-products of the giver of the stage
	|SELECT
	|	SideAndIntermediateRelease.Products      AS Products,
	|	SideAndIntermediateRelease.Characteristic    AS Characteristic,
	|	References.CostGroupNumber    AS CostGroupNumber,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
	|	SUM(SideAndIntermediateRelease.Count) AS Count
	|FROM
	|	Document.SubcontractOrder2_5.References AS References
	|	
	|	INNER JOIN Document.ProductionStage2_2.SideAndIntermediateRelease AS SideAndIntermediateRelease
	|	ON SideAndIntermediateRelease.Ref = References.ReferenceOrder
	|WHERE
	|	References.Ref = &Basis
	|	AND NOT SideAndIntermediateRelease.Canceled
	|
	|GROUP BY
	|	SideAndIntermediateRelease.Products,
	|	SideAndIntermediateRelease.Characteristic,
	|	References.CostGroupNumber
	|
	|ORDER BY
	|	CostGroupNumber,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Manufactured products of the processor
	|SELECT ALLOWED
	|	ManufacturedProduct.Products      AS Products,
	|	ManufacturedProduct.Characteristic    AS Characteristic,
	|	SUM(ManufacturedProduct.Count) AS Count,
	|	SUM(ManufacturedProduct.Sum)      AS Sum,
	|	SUM(ManufacturedProduct.VATAmount)   AS VATAmount,
	|	SUM(ManufacturedProduct.AmountIncludingVAT)  AS AmountIncludingVAT
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS ManufacturedProduct
	|WHERE
	|	ManufacturedProduct.Ref IN (
	|		SELECT
	|			GeneratedOrders.Ref
	|		FROM
	|			GeneratedOrders AS GeneratedOrders)
	|	AND NOT ManufacturedProduct.Canceled
	|
	|GROUP BY
	|	ManufacturedProduct.Products,
	|	ManufacturedProduct.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Services
	|SELECT ALLOWED
	|	Services.CostGroupNumber AS CostGroupNumber,
	|	SUM(Services.Sum)      AS Sum,
	|	SUM(Services.VATAmount)   AS VATAmount,
	|	SUM(Services.AmountIncludingVAT)  AS AmountIncludingVAT
	|FROM
	|	Document.SubcontractOrder2_5.Services AS Services
	|WHERE
	|	Services.Ref = &Basis
	|	AND NOT Services.Canceled
	|
	|GROUP BY
	|	Services.CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Materials of the giver of the order
	|SELECT ALLOWED
	|	MaterialsAndWorks.Products      AS Products,
	|	MaterialsAndWorks.Characteristic    AS Characteristic,
	|	ISNULL(OrderSpecifications.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef)) AS BillOfMaterials,
	|	SUM(MaterialsAndWorks.Count) AS Count,
	|	SUM(MaterialsAndWorks.Sum)      AS Sum
	|FROM
	|	Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS MaterialsAndWorks
	|	
	|	LEFT JOIN OrderSpecifications AS OrderSpecifications
	|	ON OrderSpecifications.CostGroupNumber = MaterialsAndWorks.CostGroupNumber
	|	
	|WHERE
	|	MaterialsAndWorks.Ref = &Basis
	|	AND NOT MaterialsAndWorks.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT MaterialsAndWorks.Canceled
	|
	|GROUP BY
	|	ISNULL(OrderSpecifications.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef)),
	|	MaterialsAndWorks.Products,
	|	MaterialsAndWorks.Characteristic
	|
	|UNION ALL
	|
	// Stage Giver Materials
	|SELECT
	|	MaterialsAndWorks.Products      AS Products,
	|	MaterialsAndWorks.Characteristic    AS Characteristic,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
	|	SUM(MaterialsAndWorks.Count) AS Count,
	|	0                                  AS Sum
	|FROM
	|	Document.SubcontractOrder2_5.References AS References
	|	
	|	INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS MaterialsAndWorks
	|	ON MaterialsAndWorks.Ref = References.ReferenceOrder
	|WHERE
	|	References.Ref = &Basis
	|	AND NOT MaterialsAndWorks.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT MaterialsAndWorks.Canceled
	|
	|GROUP BY
	|	MaterialsAndWorks.Products,
	|	MaterialsAndWorks.Characteristic
	|
	|ORDER BY
	|	BillOfMaterials,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// Materials of the processor
	|SELECT
	|	MaterialsAndWorks.Products      AS Products,
	|	MaterialsAndWorks.Characteristic    AS Characteristic,
	|	SUM(MaterialsAndWorks.Count) AS Count,
	|	SUM(MaterialsAndWorks.Sum)      AS Sum
	|FROM
	|	Document.MaterialProviderOrder2_5.UsedMaterials AS MaterialsAndWorks
	|WHERE
	|	MaterialsAndWorks.Ref IN (
	|		SELECT
	|			GeneratedOrders.Ref
	|		FROM
	|			GeneratedOrders AS GeneratedOrders)
	|	AND NOT MaterialsAndWorks.Canceled
	|
	|GROUP BY
	|	MaterialsAndWorks.Products,
	|	MaterialsAndWorks.Characteristic
	|
	|ORDER BY
	|	Products,
	|	Characteristic
	|";
	
	Return QueryText;
	
EndFunction

Procedure ToDistributeManufacturedProductsOfProcessorToManufacturedProductsOfGiver(GiverHasManufacturedProducts, ManufacturedProductsFromProcessor, TableServices)
	
	// We will distribute the amounts of processing services by products.
	GiverHasManufacturedProducts.Columns.Add(
		"Sum",
		CurrencyRateOperations.MoneyFieldTypeDescription(AllowedSign.Nonnegative));
	GiverHasManufacturedProducts.Columns.Add(
		"VATAmount",
		CurrencyRateOperations.MoneyFieldTypeDescription(AllowedSign.Nonnegative));
	GiverHasManufacturedProducts.Columns.Add(
		"AmountIncludingVAT",
		CurrencyRateOperations.MoneyFieldTypeDescription(AllowedSign.Nonnegative));
	
	GiverHasManufacturedProducts.Indexes.Add("CostGroupNumber");
	
	CostGroups = New Map;
	For Each CurService_ In TableServices Do
		
		Filter = New Structure("CostGroupNumber", CurService_.CostGroupNumber);
		FoundRows = GiverHasManufacturedProducts.FindRows(Filter);
		
		CountTotal = CostGroups.Get(CurService_.CostGroupNumber);
		If CountTotal = Undefined Then
			
			CountTotal = 0;
			For Each CurrentManufacturedProducts In FoundRows Do
				CountTotal = CountTotal + CurrentManufacturedProducts.Count;
			EndDo;
			
			CostGroups.Insert(CurService_.CostGroupNumber, CountTotal);
			
		EndIf;
		
		If ValueIsFilled(CountTotal) Then
			
			AmountOfServices     = CurService_.Sum;
			VATAmountOfServices  = CurService_.VATAmount;
			AmountWithVATOfServices = CurService_.AmountIncludingVAT;
			For Each CurrentManufacturedProducts In FoundRows Do
				
				AmountOfManufacturedProducts             = Round(AmountOfServices * CurrentManufacturedProducts.Count / CountTotal, 2);
				TheAmountOfNdtproducts          = Round(VATAmountOfServices * CurrentManufacturedProducts.Count / CountTotal, 2);
				AmountWithVATOfManufacturedProducts         = Round(AmountWithVATOfServices * CurrentManufacturedProducts.Count / CountTotal, 2);
				CurrentManufacturedProducts.Sum     = CurrentManufacturedProducts.Sum + AmountOfManufacturedProducts;
				CurrentManufacturedProducts.VATAmount  = CurrentManufacturedProducts.VATAmount + TheAmountOfNdtproducts;
				CurrentManufacturedProducts.AmountIncludingVAT = CurrentManufacturedProducts.AmountIncludingVAT + AmountWithVATOfManufacturedProducts;
				
				CountTotal = CountTotal - CurrentManufacturedProducts.Count;
				AmountOfServices      = AmountOfServices - AmountOfManufacturedProducts;
				VATAmountOfServices   = VATAmountOfServices - TheAmountOfNdtproducts;
				AmountWithVATOfServices  = AmountWithVATOfServices - AmountWithVATOfManufacturedProducts;
				
				If CountTotal = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	GiverHasManufacturedProducts.Indexes.Clear();
	GiverHasManufacturedProducts.GroupBy("Products, Characteristic, BillOfMaterials", "Count, Sum, VATAmount, AmountIncludingVAT");
	
	// We will take into account already completed orders.
	GiverHasManufacturedProducts.Indexes.Add("Products, Characteristic");
	
	For Each CurrentManufacturedProductsOfProcessor In ManufacturedProductsFromProcessor Do
		
		QuantityAtProcessor = CurrentManufacturedProductsOfProcessor.Count;
		AmountFromProcessor      = CurrentManufacturedProductsOfProcessor.Sum;
		AmountOfProcessorSNDSU   = CurrentManufacturedProductsOfProcessor.VATAmount;
		AmountOfProcessorSSDSU  = CurrentManufacturedProductsOfProcessor.AmountIncludingVAT;
		
		Filter =
			New Structure(
				"Products, Characteristic",
				CurrentManufacturedProductsOfProcessor.Products,
				CurrentManufacturedProductsOfProcessor.Characteristic);
		
		For Each CurrentManufacturedProducts In GiverHasManufacturedProducts.FindRows(Filter) Do
			
			If CurrentManufacturedProducts.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(QuantityAtProcessor, CurrentManufacturedProducts.Count);
			Sum      = Min(AmountFromProcessor, CurrentManufacturedProducts.Sum);
			VATAmount   = Min(AmountOfProcessorSNDSU, CurrentManufacturedProducts.VATAmount);
			AmountIncludingVAT  = Min(AmountOfProcessorSSDSU, CurrentManufacturedProducts.AmountIncludingVAT);
			
			CurrentManufacturedProducts.Count = CurrentManufacturedProducts.Count - Count;
			CurrentManufacturedProducts.Sum      = CurrentManufacturedProducts.Sum - Sum;
			CurrentManufacturedProducts.VATAmount   = CurrentManufacturedProducts.VATAmount - VATAmount;
			CurrentManufacturedProducts.AmountIncludingVAT  = CurrentManufacturedProducts.AmountIncludingVAT - AmountIncludingVAT;
			
			QuantityAtProcessor = QuantityAtProcessor - Count;
			AmountFromProcessor      = AmountFromProcessor - Sum;
			AmountOfProcessorSNDSU   = AmountOfProcessorSNDSU - VATAmount;
			AmountOfProcessorSSDSU  = AmountOfProcessorSSDSU - AmountIncludingVAT;
			
			If QuantityAtProcessor = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	GiverHasManufacturedProducts.Indexes.Clear();
	
	Filter = New Structure("Count", 0);
	For Each CurrentData In GiverHasManufacturedProducts.FindRows(Filter) Do
		GiverHasManufacturedProducts.Delete(CurrentData);
	EndDo;
	
EndProcedure

Procedure DistributeMaterialsOfProcessorToMaterialsOfGiver(MaterialsFromGiver, MaterialsFromProcessor)
	
	// We will take into account already completed orders.
	MaterialsFromGiver.Indexes.Add("Products, Characteristic");
	
	For Each CurrentMaterialOfProcessor In MaterialsFromProcessor Do
		
		QuantityAtProcessor = CurrentMaterialOfProcessor.Count;
		AmountFromProcessor      = CurrentMaterialOfProcessor.Sum;
		
		Filter =
			New Structure(
				"Products, Characteristic",
				CurrentMaterialOfProcessor.Products,
				CurrentMaterialOfProcessor.Characteristic);
		
		For Each CurrentMaterial In MaterialsFromGiver.FindRows(Filter) Do
			
			If CurrentMaterial.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(QuantityAtProcessor, CurrentMaterial.Count);
			Sum      = Min(AmountFromProcessor, CurrentMaterial.Sum);
			
			CurrentMaterial.Count = CurrentMaterial.Count - Count;
			CurrentMaterial.Sum      = CurrentMaterial.Sum - Sum;
			
			QuantityAtProcessor = QuantityAtProcessor - Count;
			AmountFromProcessor      = AmountFromProcessor - Sum;
			
			If QuantityAtProcessor = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	MaterialsFromGiver.Indexes.Clear();
	
	Filter = New Structure("Count", 0);
	For Each CurrentData In MaterialsFromGiver.FindRows(Filter) Do
		MaterialsFromGiver.Delete(CurrentData);
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Other

Procedure FillInEmptyAssignments()
	
	Table = New ValueTable();
	Table.Columns.Add("IndexOf",       New TypeDescription("Number"));
	Table.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	
	For Counter = 1 To UsedMaterials.Count() Do
		
		String = UsedMaterials[Counter - 1];
		
		If Not ValueIsFilled(String.Purpose) Then
			NewRow = Table.Add();
			FillPropertyValues(NewRow, String);
			NewRow.IndexOf = Counter - 1;
		EndIf;
		
	EndDo;
	
	If Table.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	Table.IndexOf       AS IndexOf,
	|	Table.Products AS Products
	|INTO TTProducts_1
	|FROM
	|	&Table AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|//////////////////////////////
	|SELECT
	|	Table.IndexOf AS IndexOf
	|FROM
	|	TTProducts_1 AS Table
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = Table.Products
	|WHERE
	|	CatProducts.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)";
		
	Query.SetParameter("Table", Table);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		UsedMaterials[Selection.IndexOf].Purpose = AssignmentMaterials;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
