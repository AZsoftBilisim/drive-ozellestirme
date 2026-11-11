#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates the "document execution Status" report by executing a batch of queries. 
// 
// Parameters:
// IncomingDocuments - ValueList of DocumentRef - List of links to documents.
// ReportTable - SpreadsheetDocument - Table document of the report.
//
Procedure GenerateDocumentExecutionStateReport(IncomingDocuments, ReportTable) Export
	
	ReportTable.FitToPage = True;
	ReportTable.PrintParametersName = "PRINT_OPTIONS_DocumentFulfillmentStatus";
	
	TableName = Common.TableNameByRef(IncomingDocuments[0].Value);
	ObjectManager = Common.ObjectManagerByFullName(TableName);
	ParametersStructure = ObjectManager.StructureStateOfDocumentExecution(); //See InitializeDocumentExecutionStructureState
	
	Template = GetTemplate("Template");
	
	Query = New Query;
	
	// Setting the request parameters.
	Query.SetParameter("DocumentsArray", IncomingDocuments.UnloadValues());
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	
	Query.SetParameter("TextOfWriteOffFieldOnWay", NStr("vi = 'Đã ghi giảm hàng đi đường';
														|ru = 'Списано в пути';
														|en = 'Written off in transit'; fa = 'Written off in transit';
														|it = 'Written off in transit';
														|pl = 'Written off in transit';
														|tr = 'Yol için kayıttan düşüldü'"));
	Query.SetParameter("TextOfIncomingFromPathField", NStr("vi = 'Đã trả lại từ hàng đi đường';
															|ru = 'Возвращено из пути';
															|en = 'Returned from transit'; fa = 'Returned from transit';
															|it = 'Returned from transit';
															|pl = 'Returned from transit';
															|tr = 'Yoldan geri döndürüldü'"));
	
	// Formation of request texts.
	QueryTexts = New ValueList;
	QueryTexts.Add(QueryTextTTDocuments(TableName, ParametersStructure), "TTDocuments");
	QueryTexts.Add(QueryTextTableDocuments(ParametersStructure), "TableDocuments");
	QueryTexts.Add(QueryTextTTOrderingNHC(), "TTOrderingOfNHC");
	QueryTexts.Add(QueryTextTTOrderingNH(), "TTOrderingOfNH");
	
	TotalTables = 0;
	DisplayCalculationTable = False;
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	If ParametersStructure.DisplayCalculationsWithCustomersTable <> 0
		 And YouHaveRightToAccessDataSet("CustomersARAPAccounting", ParametersStructure) Then
		
		QueryTexts.Add(QueryTextTTCalculationObjects_(TableName, ParametersStructure), "TTCalculationObjects_");
		If Not (NewOnlineARAPAccounting) Then
			Query.SetParameter("Shipment", NStr("vi = 'Xuất kho';
												|ru = 'Отгрузка';
												|en = 'Shipment'; fa = 'ارسال';
												|it = 'Spedizione';
												|pl = 'Wysyłka';
												|tr = 'Sevkiyat'"));
			QueryTexts.Add(QueryTextTTDataOnSettlementsWithCustomers(TableName, ParametersStructure), "TTDataOnSettlementsWithCustomers");
			QueryTexts.Add(QueryTextTableCustomersARAPAccounting(ParametersStructure), "TableSettlementsWithCustomers");
		EndIf;
		DisplayCalculationTable = True;
		TotalTables = TotalTables + 1;
	EndIf;
	
	If ParametersStructure.DisplayCalculationsWithSuppliersTable <> 0
		 And YouHaveRightToAccessDataSet("VendorsARAPAccounting", ParametersStructure) Then
		
		If Not DisplayCalculationTable Then
			QueryTexts.Add(QueryTextTTCalculationObjects_(TableName, ParametersStructure), "TTCalculationObjects_");
		EndIf;
		
		If Not (NewOnlineARAPAccounting) Then
			Query.SetParameter("Inpayment", NStr("vi = 'Tiếp nhận';
												|ru = 'Поступление';
												|en = 'Receipt'; fa = 'دریافت';
												|it = 'Arrivo';
												|pl = 'Wpływ';
												|tr = 'Tahsilat'"));
			QueryTexts.Add(QueryTextTTDataOnSettlementsWithSuppliers(TableName, ParametersStructure), "TTDataOnSettlementsWithSuppliers");
			QueryTexts.Add(QueryTextTableVendorsARAPAccounting(ParametersStructure), "TableSettlementsWithSuppliers");
		EndIf;
		DisplayCalculationTable = True;
		TotalTables = TotalTables + 1;
	EndIf;
	
	If DisplayCalculationTable Then
		
		If Not NewOnlineARAPAccounting Then
			QueryTexts.Add(QueryTextTablePaymentSchedules(TableName, ParametersStructure), "PaymentScheduleTable");
		EndIf;
		If ParametersStructure.ThisIsOrder Then
			QueryTexts.Add(QueryTextTableSubordinateDocuments(TableName, ParametersStructure), "TableSubordinateDocuments");
		EndIf;
		
	EndIf;
	
	If ParametersStructure.OutputTablesSupply <> 0 Then
		Query.SetParameter("ArrayOfStatusesWithoutShipment", StatusesWithoutShipment(TableName));
		
		QueryTextTableUnsecuredGoods = QueryTextTableUnsecuredGoods(TableName, ParametersStructure);
		QueryTextTableSupplyState = QueryTextTableSupplyState(TableName, ParametersStructure);
		
		QueryTexts.Add(QueryTextTableUnsecuredGoods, "TableUnsecuredGoods");
		QueryTexts.Add(QueryTextTableSupplyState, "TableStateOfProvision");
		TotalTables = TotalTables + 1;
		
	EndIf;
	
	If ParametersStructure.DisplayShipmentTables <> 0 And YouHaveRightToAccessDataSet("Shipment", ParametersStructure) Then
		Query.SetParameter("UseAdvancedFeaturesOfSalesOrder",
			GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
		
		QueryTexts.Add(QueryTextTTGoodsForIssue(ParametersStructure), "TTGoodsForShipment");
		If ParametersStructure.ThisIsOrder Then
			QueryTexts.Add(QueryTextTTProductsOrderShipped(TableName, ParametersStructure, QueryTexts), "TTProductsOrderShipped");
		EndIf;
		If ParametersStructure.ThisIsAnInvoice Then
			QueryTexts.Add(QueryTextTTGoodsOrderInvoiceShipped(TableName, ParametersStructure), "TTGoodsOrderInvoiceShipped");
		EndIf;
		QueryTexts.Add(QueryTextTableShipment(ParametersStructure), "ShippingTable");
		QueryTexts.Add(QueryTextTableShipped(ParametersStructure), "TableShipped");
		TotalTables = TotalTables + 1;
		
	EndIf;
	
	If ParametersStructure.DisplayDeliveryTables <> 0
	   And YouHaveRightToAccessDataSet("Delivery", ParametersStructure)
	   And Not GetFunctionalOption("NotUseDeliveryManagement25") Then
		
		Query.SetParameter("DeliveryType", Enums.DeliveryTypes.OutgoingInfo);
		Query.SetParameter("UseAdvancedFeaturesOfSalesOrder",
			GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
		
		QueryText = QueryTextTTDeliveryOrderLines(TableName, ParametersStructure);
		QueryTexts.Add(QueryText, "TTDeliveryOrderLines");
		
		QueryText = QueryTextTTDeliveryTurnover(ParametersStructure);
		QueryTexts.Add(QueryText, "TTDeliveryTurnover");
		
		QueryText = QueryTextTableDelivery(ParametersStructure);
		QueryTexts.Add(QueryText, "TableDelivery");
		
		QueryText = QueryTextTableDelivered(ParametersStructure);
		QueryTexts.Add(QueryText, "TableDelivered");
		
		TotalTables = TotalTables + 1;
		
	EndIf;
	
	If GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle")
		And ParametersStructure.ToDisplayPPPTable Then
		
		CommonClientServer.SupplementList(QueryTexts, QueryTextsOfTemporaryPPPTables());
		QueryTexts.Add(QueryTextTableOfPPP(ParametersStructure), "TableOfPPS");
		QueryTexts.Add(QueryTextIsTableOfPPPFormalized(ParametersStructure), "TableOfPPSIssued");
		TotalTables = TotalTables + 1;
		
	EndIf;
	
	If ParametersStructure.DisplayOrderedTable_ Then
		
		QueryTexts.Add(QueryTextTableOrdered(TableName, ParametersStructure), "TableOrdered");
		
	EndIf;
	
	If ParametersStructure.DisplayReceiptTables <> 0 And YouHaveRightToAccessDataSet("Inpayment", ParametersStructure) Then
		QueryTexts.Add(QueryTextTTGoodsArrival(ParametersStructure), "TTGoodsArrival");
		If ParametersStructure.ThisIsOrder Then
			QueryTexts.Add(QueryTextTTGoodsOrdersArrivalOrder(TableName, ParametersStructure, QueryTexts), "TTGoodsOrdersArrivalOrder");
		EndIf;
		If ParametersStructure.ThisIsAnInvoice Then
			QueryTexts.Add(QueryTextTTGoodsOrdersReceiptInvoice(TableName, ParametersStructure), "TTGoodsOrdersReceiptInvoice");
		EndIf;
		QueryTexts.Add(QueryTextTableInpayment(ParametersStructure), "ReceiptTable");
		QueryTexts.Add(QueryTextTableReceived(ParametersStructure), "TableReceived");
		TotalTables = TotalTables + 1;
		Query.SetParameter("ListOfSeparatePurchaseBusinessTransactions", PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections());
	EndIf;
	
	If ParametersStructure.DisplayTableOfServicesToGiverForRegistration <> 0
		And YouHaveRightToAccessDataSet("ServicesOfMaterialProviderForRegistration", ParametersStructure) Then
		QueryTexts.Add(QueryTextTTProductsOrderedByGiver(), "TTProductsOrderedByGiver");
		QueryTexts.Add(QueryTextTableServicesOfMaterialProviderForRegistration(), "TableOfServicesToGiverForRegistration");
		TotalTables = TotalTables + 1;
	EndIf;
	
	If ParametersStructure.DisplayTablesCanceledShipment <> 0 Then
		
		QueryTextTableTTCanceled = QueryTextTableShipmentHasBeenCanceledTT(TableName, ParametersStructure);
		QueryTextTableCanceled = QueryTextTableCanceledShipment(TableName, ParametersStructure);
		
		QueryTexts.Add(QueryTextTableTTCanceled, "ShipmentHasBeenCanceledTT");
		QueryTexts.Add(QueryTextTableCanceled, "TableCanceledShipment");

		TotalTables = TotalTables + 1;
		
	EndIf;
	
	If ParametersStructure.DisplayTablesCanceledReceipt <> 0 Then
		
		QueryTextTableCanceled = QueryTextTableCanceledReceipt(TableName, ParametersStructure);
		QueryTexts.Add(QueryTextTableCanceled, "TableCanceledReceipt");
		TotalTables = TotalTables + 1;
		
	EndIf;
	
	If ParametersStructure.OutputTablesReturn <> 0
		And YouHaveRightToAccessDataSet("ReturnsOfGoods", ParametersStructure) Then
		
		QueryTextTableReturnOfGoods = QueryTextTableReturnOfGoods(TableName, ParametersStructure);
		QueryTextTableReturnedItems = QueryTextTableReturnedItems(TableName, ParametersStructure);
		
		QueryTexts.Add(QueryTextTTReturnedGoods(ParametersStructure), "TTReturnItems");
		QueryTexts.Add(QueryTextTTItemsToBeReturned(ParametersStructure), "TTItemsForReturn");
		
		QueryTexts.Add(QueryTextTableReturnOfGoods, "TableReturnOfGoods");
		QueryTexts.Add(QueryTextTableReturnedItems, "TableOfReturnedItems");
		
		TotalTables = TotalTables + 1;
		
	EndIf;
	If ParametersStructure.DisplayProductsForProcessingTableInReportToProcessor_ <> 0 
		And YouHaveRightToAccessDataSet("ProductsToBeProcessedInReportToProcessor", ParametersStructure) Then
		QueryTexts.Add(QueryTextTableProductsToBeProcessedInReportToProcessor(ParametersStructure), "TableProductsForProcessingInReportToProcessor");
		TotalTables = TotalTables + 1;
	EndIf;
	If ParametersStructure.DisplayRawMaterialsTableAtProcessor_ <> 0
		And YouHaveRightToAccessDataSet("RawMaterialsFromProcessor", ParametersStructure) Then
		
		QueryTextTableRawMaterialsFromProcessor(QueryTexts, ParametersStructure);
		
		TotalTables = TotalTables + 1;
		
	EndIf;
	If ParametersStructure.DisplayTableForOrder <> 0 Then
		ObjectManager.AddQueryTextOfTableToOrder(QueryTexts, "DocumentsArray");
		TotalTables = TotalTables + 1;
	EndIf;
	
	For Each QueryText In QueryTexts Do
		If IsBlankString(QueryText.Value) Then
			QueryTexts.Delete(QueryText);
		EndIf;
	EndDo; 
	
	// Initialization of query tables.
	Query.TempTablesManager = New TempTablesManager;
	ResultTables = GetTableOfQueryResults(Query, QueryTexts);
	
	If NewOnlineARAPAccounting Then
		
		CustomersARAPAccounting =
			ParametersStructure.DisplayCalculationsWithCustomersTable <> 0
			And AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting);
		
		VendorsARAPAccounting =
			ParametersStructure.DisplayCalculationsWithSuppliersTable <> 0
			And AccessRight("Read", Metadata.AccumulationRegisters.VendorsARAPAccounting);
		
		If CustomersARAPAccounting
			Or VendorsARAPAccounting Then
			CalculationsTables = GetCalculationData(Query.TempTablesManager, CustomersARAPAccounting, VendorsARAPAccounting);
		EndIf;
		
	EndIf;
	
	// Output of the results to a tabular document.
	DocumentTypeNumber = 0;
	DocumentsTable = ResultTables.TableDocuments.Rows;
	
	For Each LineDocument In DocumentsTable Do
		
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			ReportTable.PutHorizontalPageBreak();
		EndIf;
		
		HasData = False;
		
		OutputReportHeader(ReportTable, Template, LineDocument);
		For TableNumber = 1 To TotalTables Do
			
			If ParametersStructure.DisplayCalculationsWithCustomersTable = TableNumber Then
				
				If NewOnlineARAPAccounting
					And CustomersARAPAccounting Then
					HasData = DisplayTableOfCalculationsForPaymentsShipments(ReportTable, Template, LineDocument.Ref, CalculationsTables, True)
						Or HasData;
				Else
				HasData = OutputCalculationTable(ReportTable, Template, LineDocument.Ref, ResultTables, "TableSettlementsWithCustomers")
					Or HasData;
				EndIf;
				HasData = DisplaySubordinateDocumentsTable(ReportTable, Template, LineDocument.Ref, ResultTables) 
					Or HasData;
				
			ElsIf ParametersStructure.DisplayCalculationsWithSuppliersTable = TableNumber Then
				
				If NewOnlineARAPAccounting
					And VendorsARAPAccounting Then
					HasData = DisplayTableOfCalculationsForPaymentsShipments(ReportTable, Template, LineDocument.Ref, CalculationsTables, False)
						Or HasData;
				Else
				HasData = OutputCalculationTable(ReportTable, Template, LineDocument.Ref, ResultTables, "TableSettlementsWithSuppliers")
					Or HasData;
				EndIf;
				HasData = DisplaySubordinateDocumentsTable(ReportTable, Template, LineDocument.Ref, ResultTables)
					Or HasData;
					
			ElsIf ParametersStructure.DisplayOrderedTable_ = TableNumber Then
				
				HasData = DisplayOrderedTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure)
					Or HasData;
				
			ElsIf ParametersStructure.DisplayTableForOrder = TableNumber Then
				
				HasData = OutputTableToOrder(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure)
					Or HasData;
				
			ElsIf ParametersStructure.DisplayReceiptTables = TableNumber Then
				
				ThereIsDataReceipt = DisplayReceiptTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure);
				ThereIsDataReceipt = OutputTableReceived(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure)
					Or ThereIsDataReceipt;
				ThereIsDataReceipt = DisplayCanceledReceiptTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure) 
					Or ThereIsDataReceipt;
				
				HasData = ThereIsDataReceipt Or HasData;
				
			ElsIf ParametersStructure.DisplayShipmentTables = TableNumber Then
				
				ThereIsDataShipment = DisplayShipmentTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure);
				ThereIsDataShipment = DisplayShippedTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure) 
					Or ThereIsDataShipment;
				ThereIsDataShipment = DisplayCanceledShipmentTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure)
					Or ThereIsDataShipment;
				
				HasData = ThereIsDataShipment Or HasData;
				
			ElsIf ParametersStructure.DisplayDeliveryTables = TableNumber Then
				
				ThereIsDataDelivery = DisplayDeliveryTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure);
				ThereIsDataDelivery = DisplayDeliveredTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure)
					Or ThereIsDataDelivery;
				
				If ThereIsDataDelivery Then
					PrintLastLine(ReportTable, Template);
				EndIf; 
				
				HasData = ThereIsDataDelivery Or HasData;
				
			ElsIf ParametersStructure.ToDisplayPPPTable = TableNumber Then
				
				ThereIsPPPData = DisplayPPPTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure);
				ThereIsPPPData = DisplayTableOfPPPFormalized(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure)
					Or ThereIsPPPData;
				
				If ThereIsPPPData Then
					PrintLastLine(ReportTable, Template);
				EndIf; 
				
				HasData = ThereIsPPPData
					Or HasData;
				
			ElsIf ParametersStructure.OutputTablesSupply = TableNumber Then	
				
				ThereIsDataSupply = DisplayUnsecuredGoodsTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure);
				ThereIsDataSupply = DisplaySoftwareStateTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure)
					Or ThereIsDataSupply;
					
				If ThereIsDataSupply Then
					PrintLastLine(ReportTable, Template);
				EndIf;
				
				HasData = ThereIsDataSupply Or HasData;
				
			ElsIf ParametersStructure.OutputTablesReturn = TableNumber Then
				
				ThereIsDataReturn = DisplayReturnOfGoodsTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure);
				ThereIsDataReturn = DisplayReturnedItemsTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure)
					Or ThereIsDataReturn;
				ThereIsDataReturn = DisplayCanceledReceiptTable(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure)
					Or ThereIsDataReturn;
				If ThereIsDataReturn Then
					PrintLastLine(ReportTable, Template);
				EndIf;
				
				HasData = ThereIsDataReturn Or HasData;
			ElsIf ParametersStructure.DisplayTableOfServicesToGiverForRegistration = TableNumber Then	
			
				ThereAreDataGivers = DisplayTableServicesToGiverForRegistration(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure);
				If ThereAreDataGivers Then
					PrintLastLine(ReportTable, Template);
				EndIf;
				HasData = ThereAreDataGivers Or HasData;
			ElsIf ParametersStructure.DisplayProductsForProcessingTableInReportToProcessor_ = TableNumber Then	
				
				HasData = DisplayProductsForProcessingTableInReportToProcessor(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure);
				If HasData Then
					PrintLastLine(ReportTable, Template);
				EndIf;
				
			ElsIf ParametersStructure.DisplayRawMaterialsTableAtProcessor_ = TableNumber Then	
			
				HasData = DisplayRawMaterialsTableAtProcessor(ReportTable, Template, LineDocument.Ref, ResultTables, ParametersStructure);
				If HasData Then
					PrintLastLine(ReportTable, Template);
				EndIf;
			EndIf;
			
		EndDo;
		
		OutputTableNoData(ReportTable, Template, LineDocument, HasData);
		
	EndDo;
	
EndProcedure

// Parameters:
// 	Query - Query
// 	QueryTexts - ValueList
// 	
// Returns:
// 	Structure:
// 		* TableDocuments                                  - ValueTree:
// 			** Ref - DocumentRef
// 		* TableSettlementsWithSuppliers                       - ValueTree
// 		* TableSettlementsWithCustomers                          - ValueTree
// 		* PaymentScheduleTable                              - ValueTree
// 		* TableSubordinateDocuments                       - ValueTree
// 		* TableUnsecuredGoods                       - ValueTree
// 		* TableStateOfProvision                       - ValueTree
// 		* ShippingTable                                   - ValueTree
// 		* TableShipped                                  - ValueTree
// 		* TableOfPPS                                        - ValueTree
// 		* TableOfPPSIssued                               - ValueTree
// 		* TableOrdered                                   - ValueTree
// 		* ReceiptTable                                - ValueTree
// 		* TableReceived                                  - ValueTree
// 		* TableOfServicesToGiverForRegistration                  - ValueTree
// 		* TableProductsForProcessingInReportToProcessor   - ValueTree
// 		* TableCanceledShipment                           - ValueTree
// 		* TableCanceledReceipt                        - ValueTree
// 		* TableReturnOfGoods                             - ValueTree
// 		* TableOfReturnedItems                          - ValueTree
//
Function GetTableOfQueryResults(Query, QueryTexts)

	Return TMCommonUse.UploadResultsOfQuery(Query, QueryTexts, QueryResultIteration.ByGroups);
	
EndFunction

// Initializes the status structure of the document.
// 
// Returns:
//  Structure - Initialize The Document Execution Structure State:
// * DisplayCalculationsWithCustomersTable - Number -
// * DisplayCalculationsWithSuppliersTable - Number -
// * OutputTablesSupply - Number -
// * DisplayShipmentTables - Number -
// * DisplayDeliveryTables - Number -
// * OutputTablesReturn - Number -
// * DisplayReceiptTables - Number -
// * DisplayTablesCanceledShipment - Number -
// * DisplayTablesCanceledReceipt - Number -
// * ToDisplayPPPTable - Number -
// * DisplayOrderedTable_ - Number -
// * DisplayTableOfServicesToGiverForRegistration - Number -
// * DisplayProductsForProcessingTableInReportToProcessor_ - Number -
// * DisplayRawMaterialsTableAtProcessor_ - Number -
// * ThisIsOrder - Boolean -
// * ThisIsAnInvoice - Boolean -
// * ThisIsArrivalOfGoods - Boolean -
// * WarehouseInHeader - Boolean -
// * ThereAreSummaryShipmentIndicators - Boolean -
// * ThereAreSummaryIndicatorsOfReceipt - Boolean -
// * ThereAreReasonsToCancelShipment - Boolean -
// * ThereAreReasonsForCancelingAdmission - Boolean -
// * NameTSGoodsShipment - String -
// * NameTSGoodsArrival - String -
// * FieldNameShipmentDate - String -
// * WarehouseFieldName - String -
// * NameOfRecipientWarehouseField - String -
// * NameOfAmountField - String -
// * RegisterNameShipmentOfServices - Undefined -
// * NameOfServiceReceiptRegister - Undefined -
// * NameOfInvoiceForOrdersField - String, Undefined -
// * StructureOfAdditionalRequests - Structure, Undefined -
// * ActionDecryptionQuantityShipped - Undefined -
// * ActionDecryptionQuantityReceived - Undefined -
// * TextProductServiceShipment - String -
// * TextProductServiceReceipt - String -
// * TextCanceledShipment - String -
// * TextCanceledReceipt - String -
Function InitializeDocumentExecutionStructureState() Export
	
	StructureState = New Structure;
	
	StructureState.Insert("DisplayCalculationsWithCustomersTable",           0); // 0 - do not output, another value indicates the order of output of the table
	StructureState.Insert("DisplayCalculationsWithSuppliersTable",        0);
	StructureState.Insert("OutputTablesSupply",                 0);
	StructureState.Insert("DisplayShipmentTables",                    0);
	StructureState.Insert("DisplayDeliveryTables",                    0);
	StructureState.Insert("OutputTablesReturn",                     0);
	StructureState.Insert("DisplayReceiptTables",                 0);
	StructureState.Insert("DisplayTablesCanceledShipment",            0);
	StructureState.Insert("DisplayTablesCanceledReceipt",         0);
	StructureState.Insert("ToDisplayPPPTable",                         0);
	StructureState.Insert("DisplayOrderedTable_",                    0);
	StructureState.Insert("DisplayTableForOrder",                     0);
	StructureState.Insert("DisplayTableOfServicesToGiverForRegistration",                 0);
	StructureState.Insert("DisplayProductsForProcessingTableInReportToProcessor_", 0);
	StructureState.Insert("DisplayRawMaterialsTableAtProcessor_", 0);
	StructureState.Insert("ThisIsOrder",                                   False);
	StructureState.Insert("ThisIsAnInvoice",                               False);
	StructureState.Insert("ThisIsArrivalOfGoods",                      False);

	StructureState.Insert("WarehouseInHeader",                                False);
	
	StructureState.Insert("ThereAreSummaryShipmentIndicators",             False);
	StructureState.Insert("ThereAreSummaryIndicatorsOfReceipt",          False);
	StructureState.Insert("ThereAreReasonsToCancelShipment",                  False);
	StructureState.Insert("ThereAreReasonsForCancelingAdmission",               False);
	
	StructureState.Insert("NameTSGoodsShipment",                        "Goods");
	StructureState.Insert("NameTSGoodsArrival",                     "Goods");
	StructureState.Insert("FieldNameShipmentDate",                        "DateOfShipment");
	StructureState.Insert("WarehouseFieldName",                               "Warehouse");
	StructureState.Insert("NameOfRecipientWarehouseField",                     "Warehouse");
	StructureState.Insert("NameOfAmountField",                               "AmountIncludingVAT");
	
	StructureState.Insert("RegisterNameShipmentOfServices",                   Undefined);
	StructureState.Insert("NameOfServiceReceiptRegister",                Undefined);
	StructureState.Insert("NameOfInvoiceForOrdersField",                  Undefined);
	
	StructureState.Insert("StructureOfAdditionalRequests",                       Undefined);
	
	StructureState.Insert("ActionDecryptionQuantityShipped",     Undefined);
	StructureState.Insert("ActionDecryptionQuantityReceived",     Undefined);
	
	StructureState.Insert("SuffixOfTemplateForProductsTableInReportToProcessor", "");
	StructureState.Insert("SuffixOfTemplateTableRawMaterialsAtProcessor", "");
	
	StructureState.Insert("TextProductServiceShipment",    NStr("vi = 'Hàng hóa (dịch vụ)';
																|ru = 'Товар (услуга)';
																|en = 'Goods (service)'; fa = 'Goods (service)';
																|it = 'Merce (servizio)';
																|pl = 'Towar (usługa)';
																|tr = 'Ürün (hizmet)'"));
	StructureState.Insert("TextProductServiceReceipt", NStr("vi = 'Hàng hóa (dịch vụ)';
															|ru = 'Товар (услуга)';
															|en = 'Goods (service)'; fa = 'Goods (service)';
															|it = 'Merce (servizio)';
															|pl = 'Towar (usługa)';
															|tr = 'Ürün (hizmet)'"));
	StructureState.Insert("TextCanceledShipment",     NStr("vi = 'Đã hủy bỏ (%1%)';
															|ru = 'Отменено (%1%)';
															|en = 'Canceled (%1%)'; fa = 'Canceled (%1%)';
															|it = 'Annullato (%1%)';
															|pl = 'Anulowano (%1%)';
															|tr = 'İptal edildi (%1%)'"));
	StructureState.Insert("TextCanceledReceipt",  NStr("vi = 'Đã hủy bỏ (%1%)';
														|ru = 'Отменено (%1%)';
														|en = 'Canceled (%1%)'; fa = 'Canceled (%1%)';
														|it = 'Annullato (%1%)';
														|pl = 'Anulowano (%1%)';
														|tr = 'İptal edildi (%1%)'"));
	
	Return StructureState
	
EndFunction

#Region StandardSubsystems
// StandardSubsystems.ReportsOptions

// Placement settings in the report panel.
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings
//   DescriptionOfReport - ValueTreeRow - The settings of this report
//       that have already been generated using the Report Options function.The description of the report() and ready to be changed.
//       See "Properties for changing" procedures variationreferences.Set up Report Variants().
//
// Description:
//   See ReportsOptionsOverridable.CustomizeReportsOptions
//
// Auxiliary methods:
//	Setting the variant = Report variationsreferences.Description of the variant (Settings, Report settings, "<Variant Name>");
//	Report variationsreferences.Set the output mode of the Report panel (Settings, Report settings, True/False);
//
// Examples:
//
//  1. Setting the description of the option.
//	Option Setups = Report variationsreferences.Description of the variant (Settings, Report settings, "<Variant Name>");
//	Option settings.Description = NStr("ru = '<Description>'");
//
//  2. Disabling the report option.
//	Option Setups = Report variationsreferences.Description of the variant (Settings, Report settings, "<Variant Name>");
//	Option settings.Enabled = False;
//
Procedure CustomizeReportOptions(Settings, DescriptionOfReport) Export
	
	// Disabling contextual options
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddOrderFulfillmentStateCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.DocumentFulfillmentStatus.FullName();
		ReportCommand.Presentation = NStr("vi = 'Trạng thái thực hiện';
											|ru = 'Состояние выполнения';
											|en = 'Fulfillment state'; fa = 'وضعیت اجرا';
											|it = 'Stato di esecuzione';
											|pl = 'Stan wykonania';
											|tr = 'Yürütme durumu'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		ReportCommand.FunctionalOptions = "UseAdvancedFeaturesOfSalesOrder";
		
		ReportCommand.HasVisibilityConditions = True;
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand,
			"ThisIsOrderAsInvoice",
			False, 
			DataCompositionComparisonType.Equal);
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddGiverSOrderFulfillmentStateCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.DocumentFulfillmentStatus.FullName();
		ReportCommand.Presentation = NStr("vi = 'Trạng thái thực hiện';
											|ru = 'Состояние выполнения';
											|en = 'Fulfillment state'; fa = 'وضعیت اجرا';
											|it = 'Stato di esecuzione';
											|pl = 'Stan wykonania';
											|tr = 'Yürütme durumu'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddRefundRequestCompletionStateCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.DocumentFulfillmentStatus.FullName();
		ReportCommand.Presentation = NStr("vi = 'Trạng thái thực hiện';
											|ru = 'Состояние выполнения';
											|en = 'Fulfillment state'; fa = 'وضعیت اجرا';
											|it = 'Stato di esecuzione';
											|pl = 'Stan wykonania';
											|tr = 'Yürütme durumu'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		ReportCommand.FunctionalOptions = "UseAdvancedFeaturesOfSalesOrder";
		
		ReportCommand.HasVisibilityConditions = True;
		AttachableCommands.AddCommandVisibilityCondition(ReportCommand,
			"ThisIsOrderAsInvoice",
			False, 
			DataCompositionComparisonType.Equal);
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddStateOfActImplementationCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Handler = "ReportManagementTMClient.StateOfImplementationOfAct";
		ReportCommand.Manager = Metadata.Reports.DocumentFulfillmentStatus.FullName();
		ReportCommand.Presentation = NStr("vi = 'Trạng thái thực hiện';
											|ru = 'Состояние выполнения';
											|en = 'Fulfillment state'; fa = 'وضعیت اجرا';
											|it = 'Stato di esecuzione';
											|pl = 'Stan wykonania';
											|tr = 'Yürütme durumu'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddCommandStateOfExecutionOfInternalOrders(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.DocumentFulfillmentStatus.FullName();
		ReportCommand.Presentation = NStr("vi = 'Trạng thái thực hiện';
											|ru = 'Состояние выполнения';
											|en = 'Fulfillment state'; fa = 'وضعیت اجرا';
											|it = 'Stato di esecuzione';
											|pl = 'Stan wykonania';
											|tr = 'Yürütme durumu'");
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddOrderFulfillmentStateCommandToHandler(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.DocumentFulfillmentStatus.FullName();
		ReportCommand.Presentation = NStr("vi = 'Trạng thái thực hiện';
											|ru = 'Состояние выполнения';
											|en = 'Fulfillment state'; fa = 'وضعیت اجرا';
											|it = 'Stato di esecuzione';
											|pl = 'Stan wykonania';
											|tr = 'Yürütme durumu'");
		
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddStateOfExecutionDocumentCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.DocumentFulfillmentStatus.FullName();
		ReportCommand.Presentation = NStr("vi = 'Trạng thái thực hiện';
											|ru = 'Состояние выполнения';
											|en = 'Fulfillment state'; fa = 'وضعیت اجرا';
											|it = 'Stato di esecuzione';
											|pl = 'Stan wykonania';
											|tr = 'Yürütme durumu'");
		ReportCommand.MultipleChoice = True;
		ReportCommand.Importance = "Important";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
// 	ValueTableRow
Function AddContractExecutionStateCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.DocumentFulfillmentStatus) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.DocumentFulfillmentStatus.FullName();
		ReportCommand.Presentation = NStr("vi = 'Trạng thái thực hiện';
											|ru = 'Состояние выполнения';
											|en = 'Execution state'; fa = 'Execution state';
											|it = 'Stato di esecuzione';
											|pl = 'Stan wykonania';
											|tr = 'Yürütme durumu'");
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Important";
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand, 
			"ContractSchedule", 
			,
			DataCompositionComparisonType.Filled);
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#EndRegion

#Region Private

#Region QueriesTexts

Function QueryTextTTDocuments(TableName, ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTTDocuments") Then
		
		Return StructureOfAdditionalRequests.QueryTextTTDocuments;
	EndIf;
	
	QueryText = "
	|SELECT ALLOWED
	|	Document.Ref AS DocumentRef,
	|	VALUETYPE(Document.Ref) AS DocumentType,
	|	Document.Date AS DocumentDate,
	|	Document.Posted AS Posted,
	|	Document.Number AS DocumentNumber
	|INTO
	|	TTDocuments
	|FROM
	|	&TableName AS Document
	|WHERE
	|	Document.Ref IN (&DocumentsArray);
	|	
	|";
	QueryText = StrReplace(QueryText, "&TableName", TableName);
	
	Return QueryText
	
EndFunction

Function QueryTextTableDocuments(ParametersStructure)
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableDocuments") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableDocuments;
	EndIf;
	
	QueryText = "
	|SELECT
	|	Documents.DocumentRef AS Ref,
	|	Documents.DocumentDate AS DocumentDate,
	|	Documents.Posted AS DocumentPosted,
	|	Documents.DocumentNumber AS DocumentNumber
	|FROM
	|	TTDocuments AS Documents;
	|";
	
	Return QueryText
	
EndFunction

Function QueryTextTableSubordinateDocuments(TableName, ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableSubordinateDocuments") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableSubordinateDocuments;
	EndIf;
	
	QueryText = "";
	ArrayOfRequestTexts = New Array();
	
	If (TableName = "Document.SalesOrder" 
			Or TableName = "Document.RequestForReturnOfGoodsFromCustomer")
		And AccessRight("Read", Metadata.Documents.CustomerInvoice) Then
		
		QueryText = "
		|SELECT ALLOWED DISTINCT
		|	TTDocuments.DocumentRef AS Document,
		|	VALUE(Enum.ARAPObjectSettings.ByARAPDocuments) AS ARAPObjectSettings,
		|	TSImplementationDocument.Ref.Currency AS Currency,
		|	TSImplementationDocument.Ref.DocumentAmount AS DocumentAmount,
		|	TSImplementationDocument.Ref AS SubordinateDocument
		|FROM
		|	Document.CustomerInvoice.Goods AS TSImplementationDocument
		|		INNER JOIN TTDocuments AS TTDocuments 
		|		ON TSImplementationDocument.SalesOrder = TTDocuments.DocumentRef
		|WHERE
		|	TTDocuments.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|	AND NOT TSImplementationDocument.Ref.DeletionMark
		|";

		ArrayOfRequestTexts.Add(QueryText);
	EndIf;
	
	If (TableName = "Document.SalesOrder" 
			Or TableName = "Document.RequestForReturnOfGoodsFromCustomer") 
		And AccessRight("Read", Metadata.Documents.CustomerInvoiceServices) Then
			
		QueryText = "
			|SELECT ALLOWED DISTINCT
			|	TTDocuments.DocumentRef AS Document,
			|	VALUE(Enum.ARAPObjectSettings.ByARAPDocuments) AS ARAPObjectSettings,
			|	TSImplementationDocument.Ref.Currency AS Currency,
			|	TSImplementationDocument.Ref.DocumentAmount AS DocumentAmount,
			|	TSImplementationDocument.Ref AS SubordinateDocument
			|FROM
			|	Document.CustomerInvoiceServices.Services AS TSImplementationDocument
			|		INNER JOIN TTDocuments AS TTDocuments 
			|		ON TSImplementationDocument.SalesOrder = TTDocuments.DocumentRef
			|WHERE
			|	TTDocuments.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
			|	AND NOT TSImplementationDocument.Ref.DeletionMark";
			
		ArrayOfRequestTexts.Add(QueryText);
	EndIf;
	
	If TableName = "Document.PurchaseOrder" 
		And AccessRight("Read", Metadata.Documents.VendorInvoice) Then
		
		QueryText = "
		|SELECT ALLOWED DISTINCT
		|	TTDocuments.DocumentRef AS Document,
		|	VALUE(Enum.ARAPObjectSettings.ByARAPDocuments) AS ARAPObjectSettings,
		|	TSImplementationDocument.Ref.Currency AS Currency,
		|	TSImplementationDocument.Ref.DocumentAmount AS DocumentAmount,
		|	TSImplementationDocument.Ref AS SubordinateDocument
		|FROM
		|	Document.VendorInvoice.Goods AS TSImplementationDocument
		|		INNER JOIN TTDocuments AS TTDocuments 
		|		ON TSImplementationDocument.PurchaseOrder = TTDocuments.DocumentRef
		|WHERE
		|	TTDocuments.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|	AND NOT TSImplementationDocument.Ref.DeletionMark
		|";

		ArrayOfRequestTexts.Add(QueryText);
	EndIf;

	
	If TableName = "Document.MaterialProviderOrder2_5"
		And AccessRight("Read", Metadata.Documents.ReportToMaterialProvider2_5) Then

		QueryText = "
		|SELECT ALLOWED DISTINCT
		|	TTDocuments.DocumentRef                         AS Document,
		|	VALUE(Enum.ARAPObjectSettings.ByARAPDocuments) AS ARAPObjectSettings,
		|	TSImplementationDocument.Ref.Currency                AS Currency,
		|	TSImplementationDocument.Ref.DocumentAmount        AS DocumentAmount,
		|	TSImplementationDocument.Ref                       AS SubordinateDocument
		|FROM
		|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS TSImplementationDocument
		|		INNER JOIN TTDocuments AS TTDocuments 
		|		ON TSImplementationDocument.MaterialProviderOrder = TTDocuments.DocumentRef
		|WHERE
		|	TTDocuments.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|	AND NOT TSImplementationDocument.Ref.DeletionMark";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;
	
	If TableName = "Document.SubcontractOrder2_5"
	   And AccessRight("Read", Metadata.Documents.SubcontractorReport2_5) Then
		
		QueryText = "
		|SELECT ALLOWED DISTINCT
		|	TTDocuments.DocumentRef AS Document,
		|	VALUE(Enum.ARAPObjectSettings.ByARAPDocuments) AS ARAPObjectSettings,
		|	DocumentTable.Currency AS Currency,
		|	DocumentTable.DocumentAmount AS DocumentAmount,
		|	DocumentTable.Ref AS SubordinateDocument
		|FROM
		|	Document.SubcontractorReport2_5 AS DocumentTable
		|		INNER JOIN TTDocuments AS TTDocuments 
		|		ON DocumentTable.SubcontractOrder = TTDocuments.DocumentRef
		|WHERE
		|	DocumentTable.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
		|	AND NOT DocumentTable.DeletionMark
		|";
	
		ArrayOfRequestTexts.Add(QueryText);
	EndIf;
	NumberOfRequests_ = ArrayOfRequestTexts.Count();
	If NumberOfRequests_ Then
		While NumberOfRequests_ > 1 Do
			NumberOfRequests_ = NumberOfRequests_ - 1;
			ArrayOfRequestTexts[NumberOfRequests_] = StrReplace(ArrayOfRequestTexts[NumberOfRequests_], "ALLOWED", "");
		EndDo;
		
		ReplacementText = StrConcat(ArrayOfRequestTexts, Chars.LF + "UNION ALL" + Chars.LF);

		QueryText = "
			|//////////////////////////////////////////////////////
			|&ReplacementText
			|
			|TOTALS
			|	MAX(ARAPObjectSettings),
			|	MAX(Currency)
			|BY
			|	Document;
			|";
			
			QueryText = StrReplace(QueryText, "&ReplacementText", ReplacementText);
	EndIf;
	
	Return QueryText
	
EndFunction

Function QueryTextTableUnsecuredGoods(TableName, ParametersStructure)
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableUnsecuredGoods") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableUnsecuredGoods;
	EndIf;
	
	QueryText =  "
	|SELECT ALLOWED
	|	TTDocuments.DocumentRef AS Document,
	|	DocumentGoods.LineNumber AS LineNumber,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.NumberOfPackages AS Count,
	|	CASE 
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
	|	THEN
	|		DocumentGoods.Products.UnitOfMeasure
	|	ELSE
	|		DocumentGoods.Package
	|	END AS Package,
	|	&NameOfAmountField AS Sum
	|FROM
	|	&TableName AS DocumentGoods
	|	INNER JOIN TTDocuments AS TTDocuments
	|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
	|	LEFT JOIN TTOrderingOfNH AS TTOrdering
	|	ON DocumentGoods.Ref = TTOrdering.Document
	|		AND DocumentGoods.Products = TTOrdering.Products
	|		AND DocumentGoods.Characteristic = TTOrdering.Characteristic
	|WHERE
	|	DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.NotRequired)
	|	AND NOT DocumentGoods.Canceled
	|
	|ORDER BY
	|	TTOrdering.Order
	|TOTALS BY
	|	Document;
	|";
	
	QueryText = StrReplace(QueryText, "&TableName", TableName + "." + ParametersStructure.NameTSGoodsShipment);
	QueryText = StrReplace(QueryText, "&NameOfAmountField", ?(ParametersStructure.ThereAreSummaryShipmentIndicators, "DocumentGoods." + ParametersStructure.NameOfAmountField, 0));
	
	Return QueryText
	
EndFunction

Function QueryTextTableSupplyState(TableName, ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableSupplyState") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableSupplyState;
	EndIf;
	
	QueryText =  "
	|SELECT ALLOWED
	|	TTDocuments.DocumentRef AS Document,
	|	DocumentGoods.LineNumber AS LineNumber,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.Series AS Series,
	|	DocumentGoods.NumberOfPackages AS Count,
	|	CASE 
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
	|	THEN
	|		DocumentGoods.Products.UnitOfMeasure
	|	ELSE
	|		DocumentGoods.Package
	|	END AS Package,
	|	&FieldNameShipmentDate AS DateOfShipment,
	|	DocumentGoods.SupplyOption AS Action,
	|	&NameOfAmountField AS Sum
	|FROM
	|	&TableName AS DocumentGoods
	|	INNER JOIN TTDocuments AS TTDocuments
	|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
	|	LEFT JOIN TTOrderingOfNHC AS TTOrdering
	|	ON DocumentGoods.Ref = TTOrdering.Document
	|		AND DocumentGoods.Products = TTOrdering.Products
	|		AND DocumentGoods.Characteristic = TTOrdering.Characteristic
	|		AND DocumentGoods.Series = TTOrdering.Series
	|WHERE
	|	(DocumentGoods.SupplyOption IN(
	|		VALUE(Enum.SupplyOptions.ToSupply),
	|		VALUE(Enum.SupplyOptions.ReserveAsReceived),
	|		VALUE(Enum.SupplyOptions.FromWarehouse))
	|	OR CASE WHEN DocumentGoods.Ref.Status IN (&ArrayOfStatusesWithoutShipment) THEN
	|		DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	END)
	|	AND NOT DocumentGoods.Canceled
	|
	|ORDER BY
	|	TTOrdering.Order
	|TOTALS BY
	|	Document;
	|";
	
	QueryText = StrReplace(QueryText, "&TableName", TableName + "." + ParametersStructure.NameTSGoodsShipment);
	QueryText = StrReplace(QueryText, "&NameOfAmountField", ?(ParametersStructure.ThereAreSummaryShipmentIndicators, "DocumentGoods." + ParametersStructure.NameOfAmountField, 0));
	QueryText = StrReplace(QueryText, "&FieldNameShipmentDate", "DocumentGoods." + ParametersStructure.FieldNameShipmentDate);
	
	Return QueryText
	
EndFunction

Function QueryTextTTGoodsForIssue(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTTGoodsForIssue") Then
		
		Return StructureOfAdditionalRequests.QueryTextTTGoodsForIssue;
	EndIf;
	
	QueryText = "";
	ArrayOfRequestTexts = New Array();
	
	If ParametersStructure.ThereIsRightToShipmentTable Then
		
		QueryText =
		"SELECT ALLOWED
		|	Subquery.DocumentShipments AS DocumentShipments,
		|	Subquery.Products AS Products,
		|	Subquery.Characteristic AS Characteristic,
		|	Subquery.Warehouse AS Warehouse,
		|	Subquery.Series AS Series,
		|	Subquery.AdvancedWarehousingOnShipment AS AdvancedWarehousingOnShipment,
		|	SUM(Subquery.ToShip) AS ToShip,
		|	SUM(Subquery.AssemblyInProgress) AS AssemblyInProgress,
		|	SUM(Subquery.Assembled) AS Assembled,
		|	SUM(Subquery.ApplyAppearance) AS ApplyAppearance,
		|	SUM(Subquery.Issued_1) AS Issued_1,
		|	SUM(Subquery.Ship) AS Ship,
		|	SUM(Subquery.Shipped) AS Shipped
		|INTO TTGoodsForShipment
		|FROM
		|	(SELECT
		|		GoodsForIssueBalance.DocumentShipments AS DocumentShipments,
		|		GoodsForIssueBalance.Products AS Products,
		|		GoodsForIssueBalance.Characteristic AS Characteristic,
		|		GoodsForIssueBalance.Warehouse AS Warehouse,
		|		GoodsForIssueBalance.Series AS Series,
		|		GoodsForIssueBalance.ToShipReceipt AS ToShip,
		|		GoodsForIssueBalance.AssemblyInProgressClosingBalance AS AssemblyInProgress,
		|		GoodsForIssueBalance.AssembledClosingBalance AS Assembled,
		|		GoodsForIssueBalance.ToRegisterClosingBalance AS ApplyAppearance,
		|		GoodsForIssueBalance.ToRegisterExpense AS Issued_1,
		|		GoodsForIssueBalance.ToShipClosingBalance AS Ship,
		|		GoodsForIssueBalance.ToShipExpense AS Shipped,
		|		CASE
		|			WHEN GoodsForIssueBalance.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|			AND &CurrentDate >= GoodsForIssueBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
		|				THEN TRUE
		|			ELSE FALSE
		|		END AS AdvancedWarehousingOnShipment
		|	FROM
		|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(,,,, DocumentShipments IN
		|			(SELECT
		|				TTDocuments.DocumentRef
		|			FROM
		|				TTDocuments AS TTDocuments)) AS GoodsForIssueBalance
		|
		|	UNION ALL
		|
		|	SELECT
		|		TableGoodsForShipment.DocumentShipments AS DocumentShipments,
		|		TableGoodsForShipment.Products AS Products,
		|		TableGoodsForShipment.Characteristic AS Characteristic,
		|		TableGoodsForShipment.Warehouse AS Warehouse,
		|		TableGoodsForShipment.Series AS Series,
		|		-TableGoodsForShipment.ToShip AS ToShip,
		|		0 AS AssemblyInProgress,
		|		0 AS Assembled,
		|		0 AS ApplyAppearance,
		|		0 AS Issued_1,
		|		0 AS Ship,
		|		0 AS Shipped,
		|		CASE
		|			WHEN TableGoodsForShipment.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|			AND &CurrentDate >= TableGoodsForShipment.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
		|				THEN TRUE
		|			ELSE FALSE
		|		END AS AdvancedWarehousingOnShipment
		|	FROM
		|		AccumulationRegister.GoodsForIssue AS TableGoodsForShipment
		|	WHERE
		|		TableGoodsForShipment.DocumentShipments IN
		|			(SELECT
		|				TTDocuments.DocumentRef
		|			FROM
		|				TTDocuments AS TTDocuments)
		|		AND TableGoodsForShipment.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		AND VALUETYPE(TableGoodsForShipment.Recorder) IN (TYPE(Document.WriteOffOfShippedGoods),
		|			TYPE(Document.GoodsReceiptFromCustomer))) AS Subquery
		|GROUP BY
		|	Subquery.DocumentShipments,
		|	Subquery.Products,
		|	Subquery.Characteristic,
		|	Subquery.Warehouse,
		|	Subquery.Series,
		|	Subquery.AdvancedWarehousingOnShipment";
		
		ArrayOfRequestTexts.Add(QueryText);
		
	EndIf;

	If ParametersStructure.Property("ThereIsRightOfAccessRegisterShipmentOfServices") 
		And ParametersStructure.ThereIsRightOfAccessRegisterShipmentOfServices 
		And ParametersStructure.RegisterNameShipmentOfServices = "ShipmentAndReturnReferences" Then
		
		QueryText = "
		|SELECT ALLOWED
		|	ShippingOrdersTurnover.ReferenceOrder AS DocumentShipments,
		|	ShippingOrdersTurnover.Products AS Products,
		|	ShippingOrdersTurnover.Characteristic AS Characteristic,
		|	ShippingOrdersTurnover.Warehouse AS Warehouse,
		|	ShippingOrdersTurnover.Series AS Series,
		|	MAX(FALSE) AS AdvancedWarehousingOnShipment,
		|	SUM(ShippingOrdersTurnover.OrderedQuantityTurnover) AS ToShip,
		|	SUM(0) AS AssemblyInProgress,
		|	SUM(0) AS Assembled,
		|	SUM(ShippingOrdersTurnover.QuantityToBeShippedTurnover) -
		|		SUM(ShippingOrdersTurnover.ShippedQuantityTurnover) AS ApplyAppearance,
		|	SUM(ShippingOrdersTurnover.ShippedQuantityTurnover) AS Issued_1,
		|	SUM(0) AS Ship,
		|	SUM(0) AS Shipped
		|FROM
		|	#ShipmentOrdersTurnoverExpanded AS ShippingOrdersTurnover
		|	
		|GROUP BY
		|	ShippingOrdersTurnover.ReferenceOrder,
		|	ShippingOrdersTurnover.Products,
		|	ShippingOrdersTurnover.Characteristic,
		|	ShippingOrdersTurnover.Warehouse,
		|	ShippingOrdersTurnover.Series
		|
		|HAVING
		|	SUM(ShippingOrdersTurnover.OrderedQuantityTurnover) <> 0
		|	OR (SUM(ShippingOrdersTurnover.QuantityToBeShippedTurnover) -
		|		SUM(ShippingOrdersTurnover.ShippedQuantityTurnover)) <> 0
		|	OR SUM(ShippingOrdersTurnover.ShippedQuantityTurnover) <> 0
		|";
		
		// Subquery #Order of Offload Turnaround Expanded
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"ReferenceOrder IN
			|		(SELECT
			|				TTDocuments.DocumentRef
			|			FROM
			|				TTDocuments AS TTDocuments)
			|		AND Products.ItemsType IN
			|			(VALUE(Enum.ItemsTypes.OperationService),
			|			VALUE(Enum.ItemsTypes.Work_5))";
		TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Warehouse, Series";
		TableFormationParameters.Indicators = "Ordered, ToShip, Shipped";
		TableFormationParameters.Resources = "Count, Sum";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		QueryText = StrReplace(QueryText,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		ArrayOfRequestTexts.Add(QueryText);
	EndIf;

	If ParametersStructure.Property("ThereIsRightOfAccessRegisterShipmentOfServices") 
		And ParametersStructure.ThereIsRightOfAccessRegisterShipmentOfServices 
		And ParametersStructure.RegisterNameShipmentOfServices = "InventoryConsumptionOrders" Then
		
		QueryText = "
		|SELECT ALLOWED
		|	InventoryConsumptionOrdersBalance.InventoryConsumptionOrder AS DocumentShipments,
		|	InventoryConsumptionOrdersBalance.Products AS Products,
		|	InventoryConsumptionOrdersBalance.Characteristic AS Characteristic,
		|	InventoryConsumptionOrdersBalance.Warehouse AS Warehouse,
		|	InventoryConsumptionOrdersBalance.Series AS Series,
		|	FALSE AS AdvancedWarehousingOnShipment,
		|	InventoryConsumptionOrdersBalance.OrderedReceipt AS ToShip,
		|	0 AS AssemblyInProgress,
		|	0 AS Assembled,
		|	InventoryConsumptionOrdersBalance.ToRegisterClosingBalance AS ApplyAppearance,
		|	InventoryConsumptionOrdersBalance.ToRegisterExpense AS Issued_1,
		|	0 AS Ship,
		|	0 AS Shipped
		|FROM
		|	AccumulationRegister.InventoryConsumptionOrders.BalanceAndTurnovers(
		|			,
		|			,
		|			,
		|			,
		|			InventoryConsumptionOrder IN
		|				(SELECT
		|					TTDocuments.DocumentRef
		|				FROM
		|					TTDocuments AS TTDocuments)
		|			AND Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		)AS InventoryConsumptionOrdersBalance
		|";
		
		ArrayOfRequestTexts.Add(QueryText);
	EndIf;

	NumberOfRequests_ = ArrayOfRequestTexts.Count();
	If NumberOfRequests_ Then
		While NumberOfRequests_ > 1 Do
			NumberOfRequests_ = NumberOfRequests_ - 1;
			ArrayOfRequestTexts[NumberOfRequests_] = StrReplace(ArrayOfRequestTexts[NumberOfRequests_], "ALLOWED", "");
		EndDo;
		
		ReplacementText = StrConcat(ArrayOfRequestTexts, Chars.LF + "UNION ALL" + Chars.LF);

		QueryText = "
			|//////////////////////////////////////////////////////
			|&ReplacementText;";
			
			QueryText = StrReplace(QueryText, "&ReplacementText", ReplacementText);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextTTProductsOrderShipped(TableName,ParametersStructure, QueryTexts)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTTProductsOrderShipped") Then
		
		Return StructureOfAdditionalRequests.QueryTextTTProductsOrderShipped;
	EndIf;
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(&NameOfAmountField) AS AmountIncludingVAT,
	|	DocumentGoods.Series AS Series,
	|	CASE
	|		WHEN DocumentGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE &WarehouseLocation
	|	END AS Warehouse,
	|	TTDocuments.DocumentRef AS Ref
	|,&TTGoodsNotShipped
	|FROM
	|	&TableName AS DocumentGoods
	|		INNER JOIN TTDocuments AS TTDocuments
	|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
	|WHERE
	|	NOT DocumentGoods.Canceled
	|	AND DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND TTDocuments.Posted
	|	AND NOT DocumentGoods.Ref.Status IN (&ArrayOfStatusesWithoutShipment)
	|GROUP BY
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Series,
	|	CASE
	|		WHEN DocumentGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE &WarehouseLocation
	|	END,
	|	TTDocuments.DocumentRef
	|";
	
	QueryText = StrReplace(QueryText, "&TableName", TableName + "." + ParametersStructure.NameTSGoodsShipment);
	
	ThereAreSummaryIndicators = ParametersStructure.ThereAreSummaryShipmentIndicators;
	QueryText = StrReplace(QueryText, "&NameOfAmountField", ?(ThereAreSummaryIndicators, "DocumentGoods." + ParametersStructure.NameOfAmountField, 0));
	
	If ParametersStructure.WarehouseInHeader Then
		QueryText = StrReplace(QueryText, "&WarehouseLocation", "DocumentGoods.Ref." + ParametersStructure.WarehouseFieldName);
	Else
		QueryText = StrReplace(QueryText, "&WarehouseLocation", "DocumentGoods.Warehouse");
	EndIf;
	If (TableName = "Document.SalesOrder"
			Or TableName = "Document.RequestForReturnOfGoodsFromCustomer")
		And (AccessRight("Read", Metadata.Documents.CustomerInvoice)
			Or AccessRight("Read", Metadata.Documents.TransferOfGoodsToBailee)) Then
		
		QueryText = StrReplace(QueryText, ",&TTGoodsNotShipped", "INTO TTPreOrderGoodsShipped");
		
		If AccessRight("Read", Metadata.Documents.CustomerInvoice) Then
			QueryText = QueryText + "
			|
			|UNION ALL
			|
			|SELECT
			|	DocumentGoods.Products,
			|	DocumentGoods.Characteristic,
			|	SUM(DocumentGoods.Count),
			|	SUM(DocumentGoods.AmountIncludingVAT),
			|	DocumentGoods.Series,
			|	DocumentGoods.Warehouse,
			|	TTDocuments.DocumentRef
			|FROM
			|	Document.CustomerInvoice.Goods AS DocumentGoods
			|		INNER JOIN TTDocuments AS TTDocuments
			|		ON (TTDocuments.DocumentRef = DocumentGoods.SalesOrder)
			|WHERE
			|	DocumentGoods.Ref.Posted
			|	AND DocumentGoods.RowCode = 0
			|	AND DocumentGoods.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferOfTitleToGoods)
			|
			|GROUP BY
			|	DocumentGoods.Products,
			|	DocumentGoods.Characteristic,
			|	DocumentGoods.Package,
			|	DocumentGoods.Series,
			|	DocumentGoods.Warehouse,
			|	TTDocuments.DocumentRef";
		EndIf;
		
		If AccessRight("Read", Metadata.Documents.GoodsShipmentToCustomer) Then
			
			QueryText = QueryText +
				TMCommonUse.QuerySeparatorInJoin() +
				"SELECT
				|	DocumentGoods.Products,
				|	DocumentGoods.Characteristic,
				|	SUM(DocumentGoods.Count),
				|	SUM(DocumentGoods.Sum),
				|	DocumentGoods.Series,
				|	DocumentGoods.Warehouse,
				|	TTDocuments.DocumentRef
				|FROM
				|	Document.GoodsShipmentToCustomer.Goods AS DocumentGoods
				|		INNER JOIN TTDocuments AS TTDocuments
				|		ON (TTDocuments.DocumentRef = DocumentGoods.SalesOrder)
				|WHERE
				|	DocumentGoods.Ref.Posted
				|	AND DocumentGoods.RowCode = 0
				|
				|GROUP BY
				|	DocumentGoods.Products,
				|	DocumentGoods.Characteristic,
				|	DocumentGoods.Package,
				|	DocumentGoods.Series,
				|	DocumentGoods.Warehouse,
				|	TTDocuments.DocumentRef";
			
		EndIf;
		
		If AccessRight("Read", Metadata.Documents.TransferOfGoodsToBailee) Then
			QueryText = QueryText + "
			|
			|UNION ALL
			|
			|SELECT
			|	DocumentGoods.Products,
			|	DocumentGoods.Characteristic,
			|	SUM(DocumentGoods.Count),
			|	SUM(DocumentGoods.Sum),
			|	DocumentGoods.Series,
			|	DocumentGoods.Warehouse,
			|	TTDocuments.DocumentRef
			|FROM
			|	Document.TransferOfGoodsToBailee.Goods AS DocumentGoods
			|		INNER JOIN TTDocuments AS TTDocuments
			|		ON (TTDocuments.DocumentRef = DocumentGoods.SalesOrder)
			|WHERE
			|	DocumentGoods.Ref.Posted
			|	AND DocumentGoods.RowCode = 0
			|
			|GROUP BY
			|	DocumentGoods.Products,
			|	DocumentGoods.Characteristic,
			|	DocumentGoods.Package,
			|	DocumentGoods.Series,
			|	DocumentGoods.Warehouse,
			|	TTDocuments.DocumentRef";
		EndIf;
		QueryText = QueryText + ";";
		
		QueryTexts.Add(QueryText, "TTPreOrderGoodsShipped");
		
		QueryText = "
		|SELECT
		|	Products_From_Orders.Products AS Products,
		|	Products_From_Orders.Characteristic AS Characteristic,
		|	SUM(Products_From_Orders.Count) AS Count,
		|	SUM(Products_From_Orders.AmountIncludingVAT) AS AmountIncludingVAT,
		|	Products_From_Orders.Series AS Series,
		|	Products_From_Orders.Warehouse AS Warehouse,
		|	Products_From_Orders.Ref AS Ref
		|INTO TTGoodsNotShipped
		|FROM
		|	TTPreOrderGoodsShipped AS Products_From_Orders
		|GROUP BY
		|	Products_From_Orders.Products,
		|	Products_From_Orders.Characteristic,
		|	Products_From_Orders.Series,
		|	Products_From_Orders.Warehouse,
		|	Products_From_Orders.Ref;
		|";
	ElsIf TableName = "Document.SubcontractOrder2_5"
			And AccessRight("Read", Metadata.Documents.TransferOfGoodsToBailee) Then
		
		QueryText = StrReplace(QueryText, ",&TTGoodsNotShipped", "INTO TTPreOrderGoodsShipped");
		
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	SUM(DocumentGoods.Count),
		|	0,
		|	DocumentGoods.Series,
		|	DocumentGoods.Warehouse,
		|	TTDocuments.DocumentRef
		|FROM
		|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS DocumentGoods
		|	
		|	INNER JOIN TTDocuments AS TTDocuments
		|	ON TTDocuments.DocumentRef = DocumentGoods.Ref.SubcontractOrder
		|
		|WHERE
		|	DocumentGoods.Ref.Posted
		|	AND NOT DocumentGoods.Canceled
		|	AND DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Package,
		|	DocumentGoods.Series,
		|	DocumentGoods.Warehouse,
		|	TTDocuments.DocumentRef
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	SUM(DocumentGoods.Count),
		|	SUM(DocumentGoods.Sum),
		|	DocumentGoods.Series,
		|	DocumentGoods.Warehouse,
		|	TTDocuments.DocumentRef
		|FROM
		|	Document.TransferOfGoodsToBailee.Goods AS DocumentGoods
		|		INNER JOIN TTDocuments AS TTDocuments
		|		ON (TTDocuments.DocumentRef = DocumentGoods.SalesOrder)
		|WHERE
		|	DocumentGoods.Ref.Posted
		|	AND DocumentGoods.RowCode = 0
		|
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Package,
		|	DocumentGoods.Series,
		|	DocumentGoods.Warehouse,
		|	TTDocuments.DocumentRef
		|;";
		
		QueryTexts.Add(QueryText, "TTPreOrderGoodsShipped");
		
		QueryText = "
		|SELECT
		|	Products_From_Orders.Products AS Products,
		|	Products_From_Orders.Characteristic AS Characteristic,
		|	SUM(Products_From_Orders.Count) AS Count,
		|	SUM(Products_From_Orders.AmountIncludingVAT) AS AmountIncludingVAT,
		|	Products_From_Orders.Series AS Series,
		|	Products_From_Orders.Warehouse AS Warehouse,
		|	Products_From_Orders.Ref AS Ref
		|INTO TTGoodsNotShipped
		|FROM
		|	TTPreOrderGoodsShipped AS Products_From_Orders
		|GROUP BY
		|	Products_From_Orders.Products,
		|	Products_From_Orders.Characteristic,
		|	Products_From_Orders.Series,
		|	Products_From_Orders.Warehouse,
		|	Products_From_Orders.Ref;
		|";
	ElsIf TableName = "Document.MaterialProviderOrder2_5"
		And AccessRight("Read", Metadata.Documents.ReportToMaterialProvider2_5) Then
		
		QueryText = StrReplace(QueryText, ",&TTGoodsNotShipped", "INTO TTPreOrderGoodsShipped");
		
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	SUM(DocumentGoods.Count),
		|	SUM(DocumentGoods.AmountIncludingVAT),
		|	DocumentGoods.Series,
		|	DocumentGoods.Warehouse,
		|	TTDocuments.DocumentRef
		|FROM
		|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS DocumentGoods
		|	
		|	INNER JOIN TTDocuments AS TTDocuments
		|	ON TTDocuments.DocumentRef = DocumentGoods.MaterialProviderOrder
		|
		|WHERE
		|	DocumentGoods.Ref.Posted
		|	AND DocumentGoods.RowCode = 0
		|
		|GROUP BY
		|	DocumentGoods.Products,
		|	DocumentGoods.Characteristic,
		|	DocumentGoods.Package,
		|	DocumentGoods.Series,
		|	DocumentGoods.Warehouse,
		|	TTDocuments.DocumentRef
		|;";
		
		QueryTexts.Add(QueryText, "TTPreOrderGoodsShipped");
		
		QueryText = "
		|SELECT
		|	Products_From_Orders.Products AS Products,
		|	Products_From_Orders.Characteristic AS Characteristic,
		|	SUM(Products_From_Orders.Count) AS Count,
		|	SUM(Products_From_Orders.AmountIncludingVAT) AS AmountIncludingVAT,
		|	Products_From_Orders.Series AS Series,
		|	Products_From_Orders.Warehouse AS Warehouse,
		|	Products_From_Orders.Ref AS Ref
		|INTO TTGoodsNotShipped
		|FROM
		|	TTPreOrderGoodsShipped AS Products_From_Orders
		|GROUP BY
		|	Products_From_Orders.Products,
		|	Products_From_Orders.Characteristic,
		|	Products_From_Orders.Series,
		|	Products_From_Orders.Warehouse,
		|	Products_From_Orders.Ref;
		|";
	ElsIf Not TableName = "Document.InventoryConsumptionOrder"
		And Not TableName = "Document.RMOrder"
		And Not ParametersStructure.ThereAreSummaryShipmentIndicators Then
		
		QueryText = "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	GoodsForIssue.Products     AS Products,
		|	GoodsForIssue.Characteristic   AS Characteristic,
		|	GoodsForIssue.Series            AS Series,
		|	GoodsForIssue.Warehouse            AS Warehouse,
		|	GoodsForIssue.DocumentShipments AS Ref,
		|	GoodsForIssue.ToShipReceipt AS Count,
		|	0 AS AmountIncludingVAT
		|INTO TTGoodsNotShipped
		|FROM
		|	AccumulationRegister.GoodsForIssue.Turnovers(,,,
		|		DocumentShipments IN(
		|			SELECT
		|				TTDocuments.DocumentRef
		|			FROM
		|				TTDocuments AS TTDocuments)) AS GoodsForIssue
		|WHERE
		|	GoodsForIssue.ToShipReceipt > 0
		|;
		|";
		
	Else
		QueryText = StrReplace(QueryText, ",&TTGoodsNotShipped", "INTO TTGoodsNotShipped");
		QueryText = QueryText + ";";
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextTTGoodsOrderInvoiceShipped(TableName,ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTTGoodsOrderInvoiceShipped") Then
		
		Return StructureOfAdditionalRequests.QueryTextTTGoodsOrderInvoiceShipped;
	EndIf;
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(&NameOfAmountField) AS AmountIncludingVAT,
	|	DocumentGoods.Series AS Series,
	|	&WarehouseLocation AS Warehouse,
	|	TTDocuments.DocumentRef AS Ref
	|INTO TTGoodsNotShipped
	|FROM
	|	&TableName AS DocumentGoods
	|		INNER JOIN TTDocuments AS TTDocuments
	|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
	|WHERE
	|	TTDocuments.Posted
	|	AND &AddConditions
	|GROUP BY
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Series,
	|	&WarehouseLocation,
	|	TTDocuments.DocumentRef
	|;
	|";
	
	QueryText = StrReplace(QueryText, "&TableName", TableName + "." + ParametersStructure.NameTSGoodsShipment);
	If ParametersStructure.WarehouseInHeader Then
		QueryText = StrReplace(QueryText, "&WarehouseLocation", "DocumentGoods.Ref." + ParametersStructure.WarehouseFieldName);
	Else
		QueryText = StrReplace(QueryText, "&WarehouseLocation", "DocumentGoods.Warehouse");
	EndIf;
	
	ThereAreSummaryIndicators = ParametersStructure.ThereAreSummaryShipmentIndicators;
	QueryText = StrReplace(QueryText, "&NameOfAmountField", ?(ThereAreSummaryIndicators, "DocumentGoods." + ParametersStructure.NameOfAmountField, 0));
	
	NameOfInvoiceForOrdersField = ParametersStructure.NameOfInvoiceForOrdersField;
	QueryText = StrReplace(QueryText, "AND &AddConditions", "AND NOT DocumentGoods.Ref." + NameOfInvoiceForOrdersField);
	Return QueryText;
	
EndFunction

Function QueryTextTableShipment(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableShipment") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableShipment;
	EndIf;
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TTGoodsNotShipped.Ref AS Document,
	|	TTGoodsForShipment.Warehouse AS Warehouse,
	|	TTGoodsForShipment.Products AS Products,
	|	TTGoodsForShipment.Characteristic AS Characteristic,
	|	TTGoodsNotShipped.AmountIncludingVAT AS AmountIncludingVAT,
	|	TTGoodsNotShipped.Series AS Series,
	|	TTGoodsForShipment.ToShip AS ToShip,
	|	TTGoodsForShipment.AssemblyInProgress AS AssemblyInProgress,
	|	TTGoodsForShipment.Assembled AS Assembled,
	|	TTGoodsForShipment.ApplyAppearance AS ApplyAppearance,
	|	TTGoodsForShipment.Issued_1 AS Issued_1,
	|	TTGoodsForShipment.Ship AS Ship,
	|	TTGoodsForShipment.Shipped AS Shipped,
	|	TTGoodsForShipment.AdvancedWarehousingOnShipment AS AdvancedWarehousingOnShipment
	|FROM
	|	TTGoodsForShipment AS TTGoodsForShipment
	|		LEFT JOIN TTGoodsNotShipped AS TTGoodsNotShipped
	|		ON TTGoodsForShipment.DocumentShipments = TTGoodsNotShipped.Ref
	|			AND TTGoodsForShipment.Products = TTGoodsNotShipped.Products
	|			AND TTGoodsForShipment.Characteristic = TTGoodsNotShipped.Characteristic
	|			AND TTGoodsForShipment.Warehouse = TTGoodsNotShipped.Warehouse
	|			AND TTGoodsForShipment.Series = TTGoodsNotShipped.Series
	|		LEFT JOIN TTOrderingOfNHC AS TTOrdering
	|		ON TTGoodsForShipment.DocumentShipments = TTOrdering.Document
	|			AND TTGoodsForShipment.Products = TTOrdering.Products
	|			AND TTGoodsForShipment.Characteristic = TTOrdering.Characteristic
	|			AND TTGoodsNotShipped.Series = TTOrdering.Series
	|WHERE
	|	NOT TTGoodsNotShipped.Products IS NULL 
	|	AND (TTGoodsForShipment.Ship <> 0
	|			OR TTGoodsForShipment.ApplyAppearance <> 0)
	|
	|ORDER BY
	|	TTOrdering.Order
	|TOTALS
	|	MAX(AdvancedWarehousingOnShipment)
	|BY
	|	Document,
	|	Warehouse
	|;
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableShipped(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableShipped") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableShipped;
	EndIf;
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TTGoodsNotShipped.Ref AS Document,
	|	TTGoodsNotShipped.Products AS Products,
	|	TTGoodsNotShipped.Characteristic AS Characteristic,
	|	TTGoodsNotShipped.Products.UnitOfMeasure AS Package,
	|	SUM(TTGoodsNotShipped.Count) AS Count,
	|	SUM(TTGoodsNotShipped.AmountIncludingVAT) AS Sum,
	|	TTGoodsNotShipped.Series AS Series
	|FROM
	|	TTGoodsNotShipped AS TTGoodsNotShipped
	|		LEFT JOIN TTGoodsForShipment AS TTGoodsForShipment
	|		ON (TTGoodsForShipment.DocumentShipments = TTGoodsNotShipped.Ref)
	|			AND (TTGoodsForShipment.Products = TTGoodsNotShipped.Products)
	|			AND (TTGoodsForShipment.Characteristic = TTGoodsNotShipped.Characteristic)
	|			AND (TTGoodsForShipment.Warehouse = TTGoodsNotShipped.Warehouse)
	|			AND (TTGoodsForShipment.Series = TTGoodsNotShipped.Series)
	|		LEFT JOIN TTOrderingOfNHC AS TTOrdering
	|		ON TTGoodsNotShipped.Ref = TTOrdering.Document
	|			AND TTGoodsNotShipped.Products = TTOrdering.Products
	|			AND TTGoodsNotShipped.Characteristic = TTOrdering.Characteristic
	|			AND TTGoodsNotShipped.Series = TTOrdering.Series
	|WHERE
	|	(TTGoodsForShipment.Ship = 0
	|	AND TTGoodsForShipment.ApplyAppearance = 0)
	|		OR TTGoodsForShipment.DocumentShipments IS NULL
	|GROUP BY
	|	TTGoodsNotShipped.Ref,
	|	TTGoodsNotShipped.Products,
	|	TTGoodsNotShipped.Characteristic,
	|	TTGoodsNotShipped.Series
	|
	|ORDER BY
	|	MIN(TTOrdering.Order)
	|TOTALS BY
	|	Document;
	|";
	Return QueryText;
	
EndFunction

Function QueryTextsOfTemporaryPPPTables()
	
	Result = New ValueList();
	
	// Series Table
	QueryText =
	"SELECT ALLOWED
	|	RegisterRecordTable.ReferenceOrder AS ReferenceOrder,
	|	RegisterRecordTable.RowCode AS RowCode,
	|	MAX(RegisterRecordTable.Series) AS Series
	|INTO TTTableSeries
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences AS RegisterRecordTable
	|WHERE
	|	RegisterRecordTable.ReferenceOrder IN
	|		(SELECT
	|			TTDocuments.DocumentRef
	|		FROM
	|			TTDocuments AS TTDocuments)
	|	AND Factor IN
	|		(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
	|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
	|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))
	|GROUP BY
	|	RegisterRecordTable.ReferenceOrder,
	|	RegisterRecordTable.RowCode
	|
	|INDEX BY
	|	ReferenceOrder,
	|	RowCode";
	
	Result.Add(QueryText + Common.QueryBatchSeparator(), "TTTableSeries");
	
	// selection table by orders
	QueryText =
	"SELECT ALLOWED DISTINCT
	|	RegisterRecordTable.ReferenceOrder AS ReferenceOrder
	|INTO TTOfRegisteredRecordsOrders
	|FROM
	|	#OrdersForShipmentRegisteredRecordsExpanded AS RegisterRecordTable
	|
	|INDEX BY
	|	ReferenceOrder";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN
		|		(SELECT
		|				TTDocuments.DocumentRef
		|			FROM
		|				TTDocuments AS TTDocuments)
		|	AND Products.ItemsType NOT IN
		|		(VALUE(Enum.ItemsTypes.OperationService),
		|		VALUE(Enum.ItemsTypes.Work_5))
		|	AND (CAST(Recorder AS Document.CustomerInvoice).BusinessOperation =
		|		VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|	OR VALUETYPE(Recorder) = TYPE(Document.GoodsShipmentToCustomer))"; // @query-part
	TableFormationParameters.Group = "Recorder, ReferenceOrder";
	TableFormationParameters.Indicators = "Issued_1, Shipped";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.PhysicalTable = True;
	
	OrdersForShipmentRegisteredRecordsExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#OrdersForShipmentRegisteredRecordsExpanded",
		OrdersForShipmentRegisteredRecordsExpanded);
	
	Result.Add(QueryText + Common.QueryBatchSeparator(), "RegisteredRecordsOfOrders");
	
	// Shipment Table
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN
		|		(SELECT
		|			TTDocuments.DocumentRef
		|		FROM
		|			TTDocuments AS TTDocuments)
		|	AND Products.ItemsType NOT IN
		|		(VALUE(Enum.ItemsTypes.OperationService),
		|		VALUE(Enum.ItemsTypes.Work_5))
		|	AND Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)"; // @query-part
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, Series";
	TableFormationParameters.Indicators = "ToShip, Shipped, WrittenOffBeforeTransferOfTitleToGoods, ReceivedBeforeTransferOfTitleToGoods, Accepted";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.OnlyAllowed = True;
	TableFormationParameters.TempTableName = "TTOrdersTurnoverShipment";
	TableFormationParameters.Indexes = "ReferenceOrder, Products, Characteristic, Series";
	
	QueryText =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Result.Add(QueryText + Common.QueryBatchSeparator(), "TTOrdersTurnoverShipment");
	
	// Design Table
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	QueryText =
	"SELECT ALLOWED
	|	TableOfRevolutions.ReferenceOrder AS ReferenceOrder,
	|	TableOfRevolutions.Products AS Products,
	|	TableOfRevolutions.Characteristic AS Characteristic,
	|	CASE
	|		WHEN TableOfRevolutions.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN ISNULL(TTTableSeries.Series, VALUE(Catalog.ItemsBatches.EmptyRef))
	|		ELSE TableOfRevolutions.Series
	|	END AS Series,
	|	SUM(TableOfRevolutions.ForRegistrationQuantityTurnover) AS ForRegistrationQuantityTurnover,
	|	SUM(TableOfRevolutions.IssuedQuantityTurnover) AS IssuedQuantityTurnover,
	|	SUM(TableOfRevolutions.DeductedToPPPQuantityTurnover) AS DeductedToPPPQuantityTurnover,
	|	SUM(TableOfRevolutions.RegisteredUpToPPPQuantityTurnover) AS RegisteredUpToPPPQuantityTurnover,
	|	SUM(TableOfRevolutions.QuantityAccepted_Turnover) AS QuantityAccepted_Turnover,
	|	SUM(TableOfRevolutions.IssuedAmountTurnover) AS IssuedAmountTurnover
	|INTO TTOrdersTurnoverRegistration
	|FROM
	|	#ShipmentOrdersTurnoverExpanded AS TableOfRevolutions
	|		LEFT JOIN TTTableSeries AS TTTableSeries
	|		ON TableOfRevolutions.ReferenceOrder = TTTableSeries.ReferenceOrder
	|		AND TableOfRevolutions.RowCode = TTTableSeries.RowCode
	|GROUP BY
	|	TableOfRevolutions.ReferenceOrder,
	|	TableOfRevolutions.Products,
	|	TableOfRevolutions.Characteristic,
	|	CASE
	|		WHEN TableOfRevolutions.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN ISNULL(TTTableSeries.Series, VALUE(Catalog.ItemsBatches.EmptyRef))
	|		ELSE TableOfRevolutions.Series
	|	END
	|
	|INDEX BY
	|	ReferenceOrder,
	|	Products,
	|	Characteristic,
	|	Series";
	
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN
		|		(SELECT
		|			TTDocuments.DocumentRef
		|		FROM
		|			TTDocuments AS TTDocuments)
		|	AND Products.ItemsType NOT IN
		|		(VALUE(Enum.ItemsTypes.OperationService),
		|		VALUE(Enum.ItemsTypes.Work_5))
		|	AND CASE
		|		WHEN Factor IN
		|		(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods),
		|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ReceivedBeforeTransferOfTitleToGoods),
		|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted))
		|			THEN Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE TRUE
		|	END"; // @query-part
	TableFormationParameters.Group = "ReferenceOrder, RowCode, Products, Characteristic, Series";
	TableFormationParameters.Indicators = "ToRegister, Issued_1, WrittenOffBeforeTransferOfTitleToGoods, ReceivedBeforeTransferOfTitleToGoods, Accepted";
	TableFormationParameters.Resources = "Count, Sum";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	Result.Add(QueryText + Common.QueryBatchSeparator(), "TTOrdersTurnoverRegistration");
	
	Return Result;
	
EndFunction

Function QueryTextTableOfPPP(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableOfPPP") Then
		Return StructureOfAdditionalRequests.QueryTextTableOfPPP;
	EndIf;
	
	QueryText =
	"SELECT ALLOWED
	|	OrdersTurnoverShipment.ReferenceOrder AS Document,
	|	OrdersTurnoverShipment.Products AS Products,
	|	OrdersTurnoverShipment.Characteristic AS Characteristic,
	|	OrdersTurnoverShipment.Series AS Series,
	|
	|	SUM(ISNULL(OrdersTurnoverRegistration.ForRegistrationQuantityTurnover, 0)
	|		- ISNULL(OrdersTurnoverRegistration.IssuedQuantityTurnover, 0)) AS ApplyAppearance,
	|
	|	SUM(ISNULL(OrdersTurnoverRegistration.IssuedQuantityTurnover, 0)) AS Issued_1,
	|
	|	SUM(OrdersTurnoverShipment.QuantityToBeShippedTurnover
	|		- OrdersTurnoverShipment.ShippedQuantityTurnover) AS Ship,
	|
	|	SUM(OrdersTurnoverShipment.ShippedQuantityTurnover
	|		- ISNULL(OrdersTurnoverShipment.QuantityAccepted_Turnover, 0)
	|		- ISNULL(OrdersTurnoverShipment.DeductedToPPPQuantityTurnover, 0)
	|		+ ISNULL(OrdersTurnoverShipment.RegisteredUpToPPPQuantityTurnover, 0)) AS Shipped,
	|
	|	SUM((OrdersTurnoverShipment.ShippedQuantityTurnover
	|		- ISNULL(OrdersTurnoverShipment.QuantityAccepted_Turnover, 0)
	|		- ISNULL(OrdersTurnoverShipment.DeductedToPPPQuantityTurnover, 0)
	|		+ ISNULL(OrdersTurnoverShipment.RegisteredUpToPPPQuantityTurnover, 0))
	|		- (ISNULL(OrdersTurnoverRegistration.IssuedQuantityTurnover, 0)
	|		+ ISNULL(OrdersTurnoverRegistration.QuantityAccepted_Turnover, 0)
	|		+ ISNULL(OrdersTurnoverRegistration.DeductedToPPPQuantityTurnover, 0)
	|		- ISNULL(OrdersTurnoverRegistration.RegisteredUpToPPPQuantityTurnover, 0))) AS ToTransferOfOwnership
	|FROM
	|	TTOrdersTurnoverShipment AS OrdersTurnoverShipment
	|		LEFT JOIN TTOrdersTurnoverRegistration AS OrdersTurnoverRegistration
	|		ON OrdersTurnoverShipment.ReferenceOrder = OrdersTurnoverRegistration.ReferenceOrder
	|		AND OrdersTurnoverShipment.Products = OrdersTurnoverRegistration.Products
	|		AND OrdersTurnoverShipment.Characteristic = OrdersTurnoverRegistration.Characteristic
	|		AND OrdersTurnoverShipment.Series = OrdersTurnoverRegistration.Series
	|		LEFT JOIN TTOrderingOfNHC AS TTOrdering
	|		ON OrdersTurnoverShipment.ReferenceOrder = TTOrdering.Document
	|			AND OrdersTurnoverShipment.Products = TTOrdering.Products
	|			AND OrdersTurnoverShipment.Characteristic = TTOrdering.Characteristic
	|			AND OrdersTurnoverShipment.Series = TTOrdering.Series
	|WHERE
	|	OrdersTurnoverShipment.ReferenceOrder IN
	|		(SELECT
	|			RegisteredRecordsOfOrders.ReferenceOrder AS ReferenceOrder
	|		FROM
	|			TTOfRegisteredRecordsOrders AS RegisteredRecordsOfOrders)
	|	AND OrdersTurnoverShipment.ShippedQuantityTurnover
	|		- ISNULL(OrdersTurnoverRegistration.IssuedQuantityTurnover, 0) <> 0
	|GROUP BY
	|	OrdersTurnoverShipment.ReferenceOrder,
	|	OrdersTurnoverShipment.Products,
	|	OrdersTurnoverShipment.Characteristic,
	|	OrdersTurnoverShipment.Series
	|HAVING
	|	SUM((OrdersTurnoverShipment.ShippedQuantityTurnover
	|		- ISNULL(OrdersTurnoverShipment.QuantityAccepted_Turnover, 0)
	|		- ISNULL(OrdersTurnoverShipment.DeductedToPPPQuantityTurnover, 0)
	|		+ ISNULL(OrdersTurnoverShipment.RegisteredUpToPPPQuantityTurnover, 0))
	|		- (ISNULL(OrdersTurnoverRegistration.IssuedQuantityTurnover, 0)
	|		+ ISNULL(OrdersTurnoverRegistration.QuantityAccepted_Turnover, 0)
	|		+ ISNULL(OrdersTurnoverRegistration.DeductedToPPPQuantityTurnover, 0)
	|		- ISNULL(OrdersTurnoverRegistration.RegisteredUpToPPPQuantityTurnover, 0))) <> 0
	|
	|ORDER BY
	|	MIN(TTOrdering.Order)
	|TOTALS
	|BY
	|	Document";
	
	Return QueryText + Common.QueryBatchSeparator();
	
EndFunction

Function QueryTextIsTableOfPPPFormalized(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextIsTableOfPPPFormalized") Then
		Return StructureOfAdditionalRequests.QueryTextIsTableOfPPPFormalized;
	EndIf;
	
	QueryText =
	"SELECT ALLOWED
	|	OrdersTurnoverShipment.ReferenceOrder AS Document,
	|	OrdersTurnoverShipment.Products AS Products,
	|	OrdersTurnoverShipment.Characteristic AS Characteristic,
	|	OrdersTurnoverShipment.Series AS Series,
	|	SUM(OrdersTurnoverRegistration.IssuedQuantityTurnover) AS Count,
	|	SUM(OrdersTurnoverRegistration.IssuedAmountTurnover) AS Sum
	|FROM
	|	TTOrdersTurnoverShipment AS OrdersTurnoverShipment
	|		INNER JOIN TTOrdersTurnoverRegistration AS OrdersTurnoverRegistration
	|		ON OrdersTurnoverShipment.ReferenceOrder = OrdersTurnoverRegistration.ReferenceOrder
	|		AND OrdersTurnoverShipment.Products = OrdersTurnoverRegistration.Products
	|		AND OrdersTurnoverShipment.Characteristic = OrdersTurnoverRegistration.Characteristic
	|		AND OrdersTurnoverShipment.Series = OrdersTurnoverRegistration.Series
	|		LEFT JOIN TTOrderingOfNHC AS TTOrdering
	|		ON OrdersTurnoverShipment.ReferenceOrder = TTOrdering.Document
	|			AND OrdersTurnoverShipment.Products = TTOrdering.Products
	|			AND OrdersTurnoverShipment.Characteristic = TTOrdering.Characteristic
	|			AND OrdersTurnoverShipment.Series = TTOrdering.Series
	|WHERE
	|	OrdersTurnoverShipment.ReferenceOrder IN
	|		(SELECT
	|			RegisteredRecordsOfOrders.ReferenceOrder AS ReferenceOrder
	|		FROM
	|			TTOfRegisteredRecordsOrders AS RegisteredRecordsOfOrders)
	|GROUP BY
	|	OrdersTurnoverShipment.ReferenceOrder,
	|	OrdersTurnoverShipment.Products,
	|	OrdersTurnoverShipment.Characteristic,
	|	OrdersTurnoverShipment.Series
	|HAVING
	|	SUM(OrdersTurnoverShipment.ShippedQuantityTurnover -
	|		OrdersTurnoverShipment.QuantityAccepted_Turnover -
	|		OrdersTurnoverShipment.DeductedToPPPQuantityTurnover +
	|		OrdersTurnoverShipment.RegisteredUpToPPPQuantityTurnover -
	|		(OrdersTurnoverRegistration.IssuedQuantityTurnover +
	|		OrdersTurnoverRegistration.QuantityAccepted_Turnover +
	|		OrdersTurnoverRegistration.DeductedToPPPQuantityTurnover -
	|		OrdersTurnoverRegistration.RegisteredUpToPPPQuantityTurnover)) = 0
	|	AND SUM(OrdersTurnoverRegistration.IssuedAmountTurnover) > 0
	|
	|ORDER BY
	|	MIN(TTOrdering.Order)
	|TOTALS
	|BY
	|	Document";
	
	Return QueryText + Common.QueryBatchSeparator();
	
EndFunction

Function QueryTextTTGoodsArrival(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTTGoodsArrival") Then
		
		Return StructureOfAdditionalRequests.QueryTextTTGoodsArrival;
	EndIf;
	
	QueryText  = "";
	QueryTexts = New Array;
	
	If ParametersStructure.ThereIsRightToReceiptTable Then
		
		QueryTexts.Add(
		"SELECT
		|	GoodsToReceive.DocumentInflow AS DocumentInflow,
		|	GoodsToReceive.Products AS Products,
		|	GoodsToReceive.Characteristic AS Characteristic,
		|	GoodsToReceive.Warehouse AS Warehouse,
		|	FALSE AS SeparatePurchase,
		|	0 AS ToReceive,
		|	GoodsToReceive.AcceptsClosingBalance AS Accepts,
		|	GoodsToReceive.GoodsReceiptNotesToRegisterExpense AS Accepted,
		|	0 AS ApplyAppearance,
		|	0 AS Issued_1,
		|	GoodsToReceive.GoodsReceiptNotesToRegisterClosingBalance AS Accept,
		|	GoodsToReceive.GoodsReceiptNotesToRegisterExpense AS Received
		|FROM
		|	AccumulationRegister.GoodsToReceive.BalanceAndTurnovers(
		|			,,,,
		|			DocumentInflow IN
		|				(SELECT
		|					TTDocuments.DocumentRef
		|				FROM
		|					TTDocuments AS TTDocuments)
		|			AND BusinessOperation NOT IN (&ListOfSeparatePurchaseBusinessTransactions)) AS GoodsToReceive
		|");
		
		QueryTexts.Add(
		"SELECT //In case of separate purchase operations, instead of information on the order, information about the execution of the document Receipt of goods is displayed
		|	GoodsToReceive.DocumentInflow AS DocumentInflow,
		|	GoodsToReceive.Products AS Products,
		|	GoodsToReceive.Characteristic AS Characteristic,
		|	GoodsToReceive.Warehouse AS Warehouse,
		|	TRUE AS SeparatePurchase,
		|	0 AS ToReceive,
		|	0 AS Accepts,
		|	GoodsToReceive.ToRegisterReceiptsByReferenceExpense AS Accepted,
		|	0 AS ApplyAppearance,
		|	0 AS Issued_1,
		|	GoodsToReceive.ToRegisterReceiptsByReferenceClosingBalance AS Accept,
		|	GoodsToReceive.ToRegisterReceiptsByReferenceExpense AS Received
		|FROM
		|	AccumulationRegister.GoodsToReceive.BalanceAndTurnovers(
		|			,,,,
		|			DocumentInflow IN
		|				(SELECT
		|					TTDocuments.DocumentRef
		|				FROM
		|					TTDocuments AS TTDocuments)
		|			AND BusinessOperation IN (&ListOfSeparatePurchaseBusinessTransactions)) AS GoodsToReceive
		|");
		
	EndIf;
	
	If ParametersStructure.ThereIsRightToAccessOrdersToSuppliers Then
		
		QueryTexts.Add(
		"SELECT
		|	PurchaseOrders.PurchaseOrder            AS DocumentInflow,
		|	PurchaseOrders.Products               AS Products,
		|	PurchaseOrders.Characteristic             AS Characteristic,
		|	PurchaseOrders.Warehouse                      AS Warehouse,
		|	CASE
		|		WHEN PurchaseOrders.PurchaseOrder REFS Document.PurchaseOrder
		|			AND CAST(PurchaseOrders.PurchaseOrder AS Document.PurchaseOrder).BusinessOperation IN (&ListOfSeparatePurchaseBusinessTransactions)
		|			THEN TRUE
		|		ELSE
		|			FALSE
		|	END                                        AS SeparatePurchase,
		|	CASE
		|		WHEN VALUETYPE(PurchaseOrder) = TYPE(Document.SubcontractOrder2_5)
		|			AND PurchaseOrders.RowCode = 0
		|			THEN 0
		|		WHEN VALUETYPE(PurchaseOrder) = TYPE(Document.SubcontractOrder2_5)
		|			THEN PurchaseOrders.ToReceiveReceipt
		|		WHEN TRUE
		|			THEN PurchaseOrders.ToRegisterReceipt
		|	END                                        AS ToReceive,
		|	0                                            AS Accepts,
		|	0                                            AS Accepted,
		|	CASE
		|		WHEN VALUETYPE(PurchaseOrder) = TYPE(Document.SubcontractOrder2_5)
		|			THEN PurchaseOrders.ToReceiveClosingBalance
		|		WHEN TRUE
		|			THEN PurchaseOrders.ToRegisterClosingBalance
		|	END                                        AS ApplyAppearance,
		|	CASE
		|		WHEN VALUETYPE(PurchaseOrder) = TYPE(Document.SubcontractOrder2_5)
		|			THEN PurchaseOrders.ToReceiveExpense
		|		WHEN TRUE
		|			THEN PurchaseOrders.ToRegisterExpense
		|	END                                        AS Issued_1,
		|	0                                            AS Accept,
		|	0                                            AS Received
		|FROM
		|	AccumulationRegister.PurchaseOrders.BalanceAndTurnovers(
		|				,,,,
		|				CASE
		|					WHEN VALUETYPE(PurchaseOrder) = TYPE(Document.SubcontractOrder2_5)
		|						THEN Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|					ELSE TRUE
		|				END
		|				AND
		|				PurchaseOrder IN
		|					(SELECT
		|						TTDocuments.DocumentRef
		|					FROM
		|						TTDocuments AS TTDocuments)) AS PurchaseOrders
		|");
		
	EndIf;
	
	If Not QueryTexts.Count() = 0 Then
		
		QueryText =
		"
		|SELECT ALLOWED
		|	GoodsToReceive.DocumentInflow AS DocumentInflow,
		|	GoodsToReceive.Products AS Products,
		|	GoodsToReceive.Characteristic AS Characteristic,
		|	GoodsToReceive.Warehouse AS Warehouse,
		|	MAX(GoodsToReceive.SeparatePurchase) AS SeparatePurchase,
		|	SUM(GoodsToReceive.ToReceive) AS ToReceive,
		|	SUM(GoodsToReceive.Accepts) AS Accepts,
		|	SUM(GoodsToReceive.Accepted) AS Accepted,
		|	SUM(GoodsToReceive.ApplyAppearance) AS ApplyAppearance,
		|	SUM(GoodsToReceive.Issued_1) AS Issued_1,
		|	SUM(GoodsToReceive.Accept) AS Accept,
		|	SUM(GoodsToReceive.Received) AS Received,
		|	CASE
		|		WHEN GoodsToReceive.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|				AND &CurrentDate >= GoodsToReceive.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS AdvancedWarehousingOnGoodsReceipt
		|INTO TTGoodsArrival
		|FROM
		|	&NestedQuery AS GoodsToReceive
		|
		|GROUP BY
		|	GoodsToReceive.DocumentInflow,
		|	GoodsToReceive.Products,
		|	GoodsToReceive.Characteristic,
		|	GoodsToReceive.Warehouse,
		|	CASE
		|		WHEN GoodsToReceive.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|				AND &CurrentDate >= GoodsToReceive.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|			THEN TRUE
		|		ELSE FALSE
		|	END
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = StrReplace(QueryText, "&NestedQuery", "(" + StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin()) + ")");
		
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextTTGoodsOrdersArrivalOrder(TableName,ParametersStructure,QueryTexts)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTTGoodsOrdersArrivalOrder") Then
		
		Return StructureOfAdditionalRequests.QueryTextTTGoodsOrdersArrivalOrder;
	EndIf;
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(&NameOfAmountField) AS AmountIncludingVAT,
	|	&WarehouseLocation AS Warehouse,
	|	TTDocuments.DocumentRef AS Ref
	|INTO TTGoodsReceiptWithoutPooling
	|FROM
	|	&TableName AS DocumentGoods
	|		INNER JOIN TTDocuments AS TTDocuments
	|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
	|WHERE
	|	NOT DocumentGoods.Canceled
	|	AND TTDocuments.Posted
	|	AND &AddConditions
	|GROUP BY
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	&WarehouseLocation,
	|	TTDocuments.DocumentRef
	|";
	
	If TableName = "Document.PurchaseOrder" Then
		If AccessRight("Read", Metadata.Documents.VendorInvoice) Then
		
			QueryText = QueryText + "
			|
			|UNION ALL
			|
			|SELECT
			|	DocumentGoods.Products,
			|	DocumentGoods.Characteristic,
			|	SUM(DocumentGoods.Count),
			|	SUM(DocumentGoods.AmountIncludingVAT),
			|	DocumentGoods.Warehouse,
			|	TTDocuments.DocumentRef
			|FROM
			|	Document.VendorInvoice.Goods AS DocumentGoods
			|		INNER JOIN TTDocuments AS TTDocuments
			|		ON (TTDocuments.DocumentRef = DocumentGoods.PurchaseOrder)
			|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
			|		ON DocumentGoods.Ref = DocumentsRegistry.ReversedDocument
			|			AND DocumentsRegistry.Posted
			|			AND NOT DocumentsRegistry.AdditionalRecord
			|WHERE
			|	DocumentGoods.Ref.Posted
			|	AND DocumentGoods.RowCode = 0
			|	AND DocumentsRegistry.Ref IS NULL
			|
			|GROUP BY
			|	DocumentGoods.Products,
			|	DocumentGoods.Characteristic,
			|	DocumentGoods.Package,
			|	DocumentGoods.Warehouse,
			|	TTDocuments.DocumentRef
			|";
		EndIf;
		
		If AccessRight("Read", Metadata.Documents.GoodsReceiptForStorage) Then
		
			QueryText = QueryText + "
			|
			|UNION ALL
			|
			|SELECT
			|	DocumentGoods.Products,
			|	DocumentGoods.Characteristic,
			|	SUM(DocumentGoods.Count),
			|	SUM(DocumentGoods.Sum),
			|	DocumentGoods.Warehouse,
			|	TTDocuments.DocumentRef
			|FROM
			|	Document.GoodsReceiptForStorage.Goods AS DocumentGoods
			|		INNER JOIN TTDocuments AS TTDocuments
			|		ON (TTDocuments.DocumentRef = DocumentGoods.PurchaseOrder)
			|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
			|		ON DocumentGoods.Ref = DocumentsRegistry.ReversedDocument
			|			AND DocumentsRegistry.Posted
			|			AND NOT DocumentsRegistry.AdditionalRecord
			|WHERE
			|	DocumentGoods.Ref.Posted
			|	AND DocumentGoods.RowCode = 0
			|	AND DocumentsRegistry.Ref IS NULL
			|
			|GROUP BY
			|	DocumentGoods.Products,
			|	DocumentGoods.Characteristic,
			|	DocumentGoods.Package,
			|	DocumentGoods.Warehouse,
			|	TTDocuments.DocumentRef
			|";
		EndIf;
		
		If AccessRight("Read", Metadata.Documents.DiscrepancyReportFollowingReceipt) Then
		
			QueryText = QueryText + "
			|
			|UNION ALL
			|
			|SELECT
			|	DocumentGoods.Products,
			|	DocumentGoods.Characteristic,
			|	SUM(DocumentGoods.Count - DocumentGoods.CountByDocument),
			|	SUM(DocumentGoods.Sum - DocumentGoods.SumByDocument),
			|	DocumentGoods.Warehouse,
			|	TTDocuments.DocumentRef
			|FROM
			|	Document.DiscrepancyReportFollowingReceipt.Goods AS DocumentGoods
			|		INNER JOIN TTDocuments AS TTDocuments
			|		ON (TTDocuments.DocumentRef = DocumentGoods.PurchaseOrder)
			|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
			|		ON DocumentGoods.Ref = DocumentsRegistry.ReversedDocument
			|			AND DocumentsRegistry.Posted
			|			AND NOT DocumentsRegistry.AdditionalRecord
			|WHERE
			|	DocumentGoods.Ref.Posted
			|	AND DocumentGoods.Action <>
			|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.Register_)
			|	AND DocumentsRegistry.Ref IS NULL
			|
			|GROUP BY
			|	DocumentGoods.Products,
			|	DocumentGoods.Characteristic,
			|	DocumentGoods.Package,
			|	DocumentGoods.Warehouse,
			|	TTDocuments.DocumentRef
			|";
		EndIf;
		
	EndIf;
	
	QueryText = QueryText + ";";
	
	QueryText = StrReplace(QueryText, "&TableName", TableName + "." + ParametersStructure.NameTSGoodsArrival);
	
	ThereAreSummaryIndicators = ParametersStructure.ThereAreSummaryIndicatorsOfReceipt;
	QueryText = StrReplace(QueryText, "&NameOfAmountField", ?(ThereAreSummaryIndicators, "DocumentGoods." + ParametersStructure.NameOfAmountField, 0));
	
	If ParametersStructure.WarehouseInHeader Then
		QueryText = StrReplace(QueryText, "&WarehouseLocation", "DocumentGoods.Ref." + ParametersStructure.NameOfRecipientWarehouseField);
	Else
		QueryText = StrReplace(QueryText, "&WarehouseLocation", "DocumentGoods.Warehouse");
	EndIf;
	
	If TableName = "Document.PurchaseOrder" Then
		QueryText = StrReplace(QueryText, "AND &AddConditions", "
			|	AND DocumentGoods.Ref.Status IN (
			|		VALUE(Enum.PurchaseOrderStatuses.Confirmed_),
			|		VALUE(Enum.PurchaseOrderStatuses.Closed))");
	ElsIf TableName = "Document.SubcontractOrder2_5"
		Or False Then
		QueryText = StrReplace(QueryText, "AND &AddConditions", "
			|	AND DocumentGoods.Ref.Status IN (
			|		VALUE(Enum.TollingOrderStatuses.ForFulfillment),
			|		VALUE(Enum.TollingOrderStatuses.Closed))");
	Else
		
		QueryText = StrReplace(QueryText, "AND &AddConditions", "");
		
	EndIf;
	
	QueryTexts.Add(QueryText, "TTGoodsReceiptWithoutPooling");

	QueryText = "
		   	|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
	       	|	TTGoodsReceiptWithoutPooling.Products AS Products,
	       	|	TTGoodsReceiptWithoutPooling.Characteristic AS Characteristic,
		    |	SUM(TTGoodsReceiptWithoutPooling.Count) AS Count,
		    |	SUM(TTGoodsReceiptWithoutPooling.AmountIncludingVAT) AS AmountIncludingVAT,
		    |	TTGoodsReceiptWithoutPooling.Warehouse AS Warehouse,
		    |	TTGoodsReceiptWithoutPooling.Ref AS Ref
		    |INTO TTGoodsNewArrival
		    |FROM
		    |	TTGoodsReceiptWithoutPooling AS TTGoodsReceiptWithoutPooling
		    |
		    |GROUP BY
		    |	TTGoodsReceiptWithoutPooling.Products,
		    |	TTGoodsReceiptWithoutPooling.Characteristic,
		    |	TTGoodsReceiptWithoutPooling.Warehouse,
		    |	TTGoodsReceiptWithoutPooling.Ref
			|;
			|";

	Return QueryText;
	
EndFunction

Function QueryTextTTGoodsOrdersReceiptInvoice(TableName,ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTTGoodsOrdersReceiptInvoice") Then
		
		Return StructureOfAdditionalRequests.QueryTextTTGoodsOrdersReceiptInvoice;
	EndIf;
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(&NameOfAmountField) AS AmountIncludingVAT,
	|	&WarehouseLocation AS Warehouse,
	|	TTDocuments.DocumentRef AS Ref
	|INTO TTGoodsNewArrival
	|FROM
	|	&TableName AS DocumentGoods
	|		INNER JOIN TTDocuments AS TTDocuments
	|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
	|WHERE
	|	TTDocuments.Posted
	|	AND &AddConditions
	|GROUP BY
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	&WarehouseLocation,
	|	TTDocuments.DocumentRef
	|;
	|";
	
	QueryText = StrReplace(QueryText, "&TableName", TableName + "." + ParametersStructure.NameTSGoodsArrival);
	If ParametersStructure.WarehouseInHeader Then
		QueryText = StrReplace(QueryText, "&WarehouseLocation", "DocumentGoods.Ref." + ParametersStructure.NameOfRecipientWarehouseField);
	Else
		QueryText = StrReplace(QueryText, "&WarehouseLocation", "DocumentGoods.Warehouse");
	EndIf;
	
	ThereAreSummaryIndicators = ParametersStructure.ThereAreSummaryIndicatorsOfReceipt;
	QueryText = StrReplace(QueryText, "&NameOfAmountField", ?(ThereAreSummaryIndicators, "DocumentGoods." + ParametersStructure.NameOfAmountField, 0));
	
	NameOfInvoiceForOrdersField = ParametersStructure.NameOfInvoiceForOrdersField;
	If ValueIsFilled(NameOfInvoiceForOrdersField) Then
		QueryText = StrReplace(QueryText, "AND &AddConditions", "AND NOT DocumentGoods.Ref." + NameOfInvoiceForOrdersField);
	Else
		QueryText = StrReplace(QueryText, "AND &AddConditions", "");
	EndIf;
	Return QueryText;
	
EndFunction

Function QueryTextTableOrdered(TableName, ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableOrdered") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableOrdered;
	EndIf;
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
	|	THEN
	|		DocumentGoods.Products.UnitOfMeasure
	|	ELSE
	|		DocumentGoods.Package
	|	END AS Package,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(DocumentGoods.NumberOfPackages) AS NumberOfPackages,
	|	SUM(&NameOfAmountField) AS Sum,
	|	&WarehouseLocation AS Warehouse,
	|	TTDocuments.DocumentRef AS Document
	|FROM
	|	&TableName AS DocumentGoods
	|		INNER JOIN TTDocuments AS TTDocuments
	|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
	|		LEFT JOIN TTOrderingOfNH AS TTOrdering
	|		ON DocumentGoods.Ref = TTOrdering.Document
	|			AND DocumentGoods.Products = TTOrdering.Products
	|			AND DocumentGoods.Characteristic = TTOrdering.Characteristic
	|WHERE
	|	NOT DocumentGoods.Canceled
	|	AND TTDocuments.Posted
	|	AND &AddConditions
	|GROUP BY
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Package,
	|	&WarehouseLocation,
	|	TTDocuments.DocumentRef
	|
	|ORDER BY
	|	MIN(TTOrdering.Order)
	|TOTALS BY
	|	Document
	|";
	
	QueryText = QueryText + ";";
	
	QueryText = StrReplace(QueryText, "&TableName", TableName + "." + ParametersStructure.NameTSGoodsArrival);
	
	ThereAreSummaryIndicators = ParametersStructure.ThereAreSummaryIndicatorsOfReceipt;
	QueryText = StrReplace(QueryText, "&NameOfAmountField", ?(ThereAreSummaryIndicators, "DocumentGoods." + ParametersStructure.NameOfAmountField, 0));
	
	If ParametersStructure.WarehouseInHeader Then
		QueryText = StrReplace(QueryText, "&WarehouseLocation", "DocumentGoods.Ref." + ParametersStructure.NameOfRecipientWarehouseField);
	Else
		QueryText = StrReplace(QueryText, "&WarehouseLocation", "DocumentGoods.Warehouse");
	EndIf;
	
	If TableName = "Document.PurchaseOrder" Then
		QueryText = StrReplace(QueryText, "AND &AddConditions", "AND NOT DocumentGoods.Ref.Status IN (VALUE(Enum.PurchaseOrderStatuses.Confirmed_),
			|	VALUE(Enum.PurchaseOrderStatuses.Closed))");
	Else
		QueryText = StrReplace(QueryText, "AND &AddConditions", "");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextTableInpayment(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableInpayment") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableInpayment;
	EndIf;
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TTGoodsNewArrival.Ref AS Document,
	|	TTGoodsArrival.Warehouse AS Warehouse,
	|	TTGoodsArrival.Products AS Products,
	|	TTGoodsArrival.Characteristic AS Characteristic,
	|	TTGoodsNewArrival.AmountIncludingVAT AS AmountIncludingVAT,
	|	TTGoodsArrival.ToReceive AS ToReceive,
	|	TTGoodsArrival.Accepts AS Accepts,
	|	TTGoodsArrival.Accepted AS Accepted,
	|	TTGoodsArrival.ApplyAppearance AS ApplyAppearance,
	|	TTGoodsArrival.Issued_1 AS Issued_1,
	|	TTGoodsArrival.Accept AS Accept,
	|	TTGoodsArrival.Received AS Received,
	|	TTGoodsArrival.AdvancedWarehousingOnGoodsReceipt AS AdvancedWarehousingOnGoodsReceipt,
	|	TTGoodsArrival.SeparatePurchase AS SeparatePurchase
	|FROM
	|	TTGoodsArrival AS TTGoodsArrival
	|		LEFT JOIN TTGoodsNewArrival AS TTGoodsNewArrival
	|		ON TTGoodsArrival.DocumentInflow = TTGoodsNewArrival.Ref
	|			AND TTGoodsArrival.Products = TTGoodsNewArrival.Products
	|			AND TTGoodsArrival.Characteristic = TTGoodsNewArrival.Characteristic
	|			AND TTGoodsArrival.Warehouse = TTGoodsNewArrival.Warehouse
	|		LEFT JOIN TTOrderingOfNH AS TTOrdering
	|		ON TTGoodsArrival.DocumentInflow = TTOrdering.Document
	|			AND TTGoodsArrival.Products = TTOrdering.Products
	|			AND TTGoodsArrival.Characteristic = TTOrdering.Characteristic
	|WHERE
	|	NOT TTGoodsNewArrival.Products IS NULL 
	|	AND (TTGoodsArrival.Accept <> 0
	|			OR TTGoodsArrival.ApplyAppearance <> 0)
	|
	|ORDER BY
	|	TTOrdering.Order
	|TOTALS
	|	MAX(AdvancedWarehousingOnGoodsReceipt),
	|	MAX(SeparatePurchase)
	|BY
	|	Document,
	|	Warehouse
	|;
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTableReceived(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableReceived") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableReceived;
	EndIf;
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TTGoodsNewArrival.Ref AS Document,
	|	TTGoodsNewArrival.Products AS Products,
	|	TTGoodsNewArrival.Characteristic AS Characteristic,
	|	TTGoodsNewArrival.Products.UnitOfMeasure AS Package,
	|	TTGoodsNewArrival.Count AS Count,
	|	TTGoodsNewArrival.AmountIncludingVAT AS Sum
	|FROM
	|	TTGoodsNewArrival AS TTGoodsNewArrival
	|		LEFT JOIN TTGoodsArrival AS TTGoodsArrival
	|		ON (TTGoodsArrival.DocumentInflow = TTGoodsNewArrival.Ref)
	|			AND (TTGoodsArrival.Products = TTGoodsNewArrival.Products)
	|			AND (TTGoodsArrival.Characteristic = TTGoodsNewArrival.Characteristic)
	|			AND (TTGoodsArrival.Warehouse = TTGoodsNewArrival.Warehouse)
	|		LEFT JOIN TTOrderingOfNH AS TTOrdering
	|		ON TTGoodsNewArrival.Ref = TTOrdering.Document
	|			AND TTGoodsNewArrival.Products = TTOrdering.Products
	|			AND TTGoodsNewArrival.Characteristic = TTOrdering.Characteristic
	|WHERE
	|	(TTGoodsArrival.Accept = 0
	|	AND TTGoodsArrival.ApplyAppearance = 0)
	|		OR TTGoodsArrival.DocumentInflow IS NULL
	|
	|ORDER BY
	|	TTOrdering.Order
	|TOTALS BY
	|	Document;
	|";
	Return QueryText;
	
EndFunction

Function QueryTextTableShipmentHasBeenCanceledTT(TableName, ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableShipmentHasBeenCanceledTT") Then
		Return StructureOfAdditionalRequests.QueryTextTableShipmentHasBeenCanceledTT;
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED
	|	TTDocuments.DocumentRef AS Document,
	|	DocumentGoods.LineNumber AS LineNumber,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.NumberOfPackages AS Count,
	|	CASE
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DocumentGoods.Products.UnitOfMeasure
	|		ELSE DocumentGoods.Package
	|	END AS Package,
	|	&FieldNameReasonForCancellation AS CancellationReason,
	|	&NameOfAmountField AS Sum
	|INTO ShipmentHasBeenCanceledTT
	|FROM
	|	&TableName AS DocumentGoods
	|		INNER JOIN TTDocuments AS TTDocuments
	|		ON TTDocuments.DocumentRef = DocumentGoods.Ref
	|WHERE
	|	DocumentGoods.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	ShipmentReferences.ReferenceOrder AS Document,
	|	""-"" AS LineNumber,
	|	ShipmentReferences.Products AS Products,
	|	ShipmentReferences.Characteristic AS Characteristic,
	|	SUM(ShipmentReferences.CountTurnover) AS Count,
	|	ShipmentReferences.Products.UnitOfMeasure AS Package,
	|	CASE
	|		WHEN Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods)
	|			THEN &TextOfWriteOffFieldOnWay
	|		ELSE &TextOfIncomingFromPathField
	|	END AS CancellationReason,
	|	SUM(ShipmentReferences.SumTurnover) AS Sum
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences.Turnovers(,,, ReferenceOrder IN
	|		(SELECT
	|			TTDocuments.DocumentRef AS DocumentRef
	|		FROM
	|			TTDocuments AS TTDocuments)
	|	AND Factor IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods),
	|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted))) AS ShipmentReferences
	|GROUP BY
	|	ShipmentReferences.ReferenceOrder,
	|	ShipmentReferences.Products,
	|	ShipmentReferences.Characteristic,
	|	CASE
	|		WHEN Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods)
	|			THEN &TextOfWriteOffFieldOnWay
	|		ELSE &TextOfIncomingFromPathField
	|	END,
	|	ShipmentReferences.Products.UnitOfMeasure";
	
	QueryText = StrReplace(QueryText, "&TableName", TableName + "." + ParametersStructure.NameTSGoodsShipment);
	QueryText = StrReplace(QueryText, "&NameOfAmountField", ?(ParametersStructure.ThereAreSummaryShipmentIndicators, "DocumentGoods." + ParametersStructure.NameOfAmountField, 0));
	QueryText = StrReplace(QueryText, "&FieldNameReasonForCancellation", ?(ParametersStructure.ThereAreReasonsToCancelShipment, "DocumentGoods.CancellationReason", """"""));
	
	Return QueryText + Common.QueryBatchSeparator();
	
EndFunction

Function QueryTextTableCanceledShipment(TableName, ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableCanceledShipment") Then
		Return StructureOfAdditionalRequests.QueryTextTableCanceledShipment;
	EndIf;
	
	QueryText = 
	"SELECT
	|	ShipmentHasBeenCanceledTT.Document AS Document,
	|	ShipmentHasBeenCanceledTT.LineNumber AS LineNumber,
	|	ShipmentHasBeenCanceledTT.Products AS Products,
	|	ShipmentHasBeenCanceledTT.Characteristic AS Characteristic,
	|	ShipmentHasBeenCanceledTT.Count AS Count,
	|	ShipmentHasBeenCanceledTT.Package AS Package,
	|	ShipmentHasBeenCanceledTT.CancellationReason AS CancellationReason,
	|	ShipmentHasBeenCanceledTT.Sum AS Sum
	|FROM
	|	ShipmentHasBeenCanceledTT AS ShipmentHasBeenCanceledTT
	|		LEFT JOIN TTOrderingOfNH AS TTOrdering
	|		ON ShipmentHasBeenCanceledTT.Document = TTOrdering.Document
	|			AND ShipmentHasBeenCanceledTT.Products = TTOrdering.Products
	|			AND ShipmentHasBeenCanceledTT.Characteristic = TTOrdering.Characteristic
	|
	|ORDER BY
	|	LineNumber,
	|	TTOrdering.Order
	|TOTALS
	|BY
	|	Document";
	
	Return QueryText + Common.QueryBatchSeparator();
	
EndFunction

Function QueryTextTableCanceledReceipt(TableName, ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableCanceledReceipt") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableCanceledReceipt;
	EndIf;
	
	QueryText =  "
	|SELECT ALLOWED
	|	TTDocuments.DocumentRef AS Document,
	|	DocumentGoods.LineNumber AS LineNumber,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.NumberOfPackages AS Count,
	|	CASE 
	|		WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) 
	|	THEN
	|		DocumentGoods.Products.UnitOfMeasure
	|	ELSE
	|		DocumentGoods.Package
	|	END AS Package,
	|	&FieldNameReasonForCancellation AS CancellationReason,
	|	&NameOfAmountField AS Sum
	|FROM
	|	&TableName AS DocumentGoods
	|	INNER JOIN TTDocuments AS TTDocuments
	|	ON TTDocuments.DocumentRef = DocumentGoods.Ref
	|	LEFT JOIN TTOrderingOfNH AS TTOrdering
	|	ON DocumentGoods.Ref = TTOrdering.Document
	|		AND DocumentGoods.Products = TTOrdering.Products
	|		AND DocumentGoods.Characteristic = TTOrdering.Characteristic
	|WHERE
	|	DocumentGoods.Canceled
	|
	|ORDER BY
	|	TTOrdering.Order
	|TOTALS BY
	|	Document;
	|";
	
	QueryText = StrReplace(QueryText, "&TableName", TableName + "." + ParametersStructure.NameTSGoodsArrival);
	QueryText = StrReplace(QueryText, "&NameOfAmountField", ?(ParametersStructure.ThereAreSummaryIndicatorsOfReceipt, "DocumentGoods." + ParametersStructure.NameOfAmountField, 0));
	QueryText = StrReplace(QueryText, "&FieldNameReasonForCancellation", ?(ParametersStructure.ThereAreReasonsForCancelingAdmission, "DocumentGoods.CancellationReason", """"""));
	
	Return QueryText
	
EndFunction

Function QueryTextTTItemsToBeReturned(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTTGoodsForIssue") Then
		
		Return StructureOfAdditionalRequests.QueryTextTTGoodsForIssue;
	EndIf;
	
	QueryText = "
	|SELECT
	|	RequestsBalance.Request AS Request,
	|	RequestsBalance.Products AS Products,
	|	RequestsBalance.Characteristic AS Characteristic,
	|	RequestsBalance.Warehouse AS Warehouse,
	|	SUM(RequestsBalance.ToRegister) AS ToRegister,
	|	SUM(RequestsBalance.Accepts) AS Accepts,
	|	SUM(RequestsBalance.Accepted) AS Accepted,
	|	SUM(RequestsBalance.ApplyAppearance) AS ApplyAppearance,
	|	SUM(RequestsBalance.Issued_1) AS Issued_1,
	|	SUM(RequestsBalance.Accept) AS Accept,
	|	SUM(RequestsBalance.Received) AS Received,
	|	CASE
	|		WHEN RequestsBalance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND &CurrentDate >= RequestsBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnGoodsReceipt
	|INTO TTItemsForReturn
	|FROM
	|	(SELECT
	|		GoodsToReceive.DocumentInflow AS Request,
	|		GoodsToReceive.Products AS Products,
	|		GoodsToReceive.Characteristic AS Characteristic,
	|		GoodsToReceive.Warehouse AS Warehouse,
	|		0 AS ToRegister,
	|		GoodsToReceive.AcceptsClosingBalance AS Accepts,
	|		GoodsToReceive.GoodsReceiptNotesToRegisterExpense AS Accepted,
	|		0 AS ApplyAppearance,
	|		0 AS Issued_1,
	|		GoodsToReceive.GoodsReceiptNotesToRegisterClosingBalance AS Accept,
	|		GoodsToReceive.GoodsReceiptNotesToRegisterExpense AS Received
	|	FROM
	|		AccumulationRegister.GoodsToReceive.BalanceAndTurnovers(
	|				,
	|				,
	|				,
	|				,
	|				DocumentInflow IN
	|					(SELECT
	|						TTDocuments.DocumentRef
	|					FROM
	|						TTDocuments AS TTDocuments)) AS GoodsToReceive
	|	
	|	UNION ALL
	|
	|	SELECT
	|		ItemsToBeReturned.ReferenceOrder AS Request,
	|		ItemsToBeReturned.Products AS Products,
	|		ItemsToBeReturned.Characteristic AS Characteristic,
	|		ItemsToBeReturned.ReferenceOrder.Warehouse AS Warehouse,
	|		ItemsToBeReturned.QuantityRequestedForReturnTurnover AS ToRegister,
	|		0,
	|		0,
	|		(ItemsToBeReturned.ForRegistrationOnReturnsQuantityTurnover -
	|			ItemsToBeReturned.IssuedByReturnsQuantityTurnover) AS ApplyAppearance,
	|		ItemsToBeReturned.IssuedByReturnsQuantityTurnover AS Issued_1,
	|		0,
	|		0
	|	FROM
	|		#RequestsForReturnOfGoodsTurnoverExpanded AS ItemsToBeReturned
	|	WHERE
	|		(ItemsToBeReturned.ForRegistrationOnReturnsQuantityTurnover -
	|			ItemsToBeReturned.IssuedByReturnsQuantityTurnover) <> 0
	|		OR ItemsToBeReturned.IssuedByReturnsQuantityTurnover <> 0) AS RequestsBalance
	|
	|GROUP BY
	|	RequestsBalance.Request,
	|	RequestsBalance.Products,
	|	RequestsBalance.Characteristic,
	|	RequestsBalance.Warehouse,
	|	CASE
	|		WHEN RequestsBalance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND &CurrentDate >= RequestsBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|;";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN
		|		(SELECT
		|				TTDocuments.DocumentRef
		|			FROM
		|				TTDocuments AS TTDocuments)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic";
	TableFormationParameters.Indicators = "RequestedForReturn, ToRegisterForReturns, RegisteredOnReturns";
	TableFormationParameters.Resources = "Count";
	
	RequestsForReturnOfGoodsTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#RequestsForReturnOfGoodsTurnoverExpanded",
		RequestsForReturnOfGoodsTurnoverExpanded);
	
	Return QueryText
	
EndFunction

Function QueryTextTTReturnedGoods(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTTReturnedGoods") Then
		
		Return StructureOfAdditionalRequests.QueryTextTTReturnedGoods;
	EndIf;
	
	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CASE
	|		WHEN DocumentGoods.Damage
	|			THEN DocumentGoods.ProductsRecordingAsReceived
	|		ELSE DocumentGoods.Products
	|	END AS Products,
	|	CASE
	|		WHEN DocumentGoods.Damage
	|			THEN DocumentGoods.CharacteristicRecordingAsReceived
	|		ELSE DocumentGoods.Characteristic
	|	END AS Characteristic,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(DocumentGoods.AmountIncludingVAT) AS AmountIncludingVAT,
	|	TTDocuments.DocumentRef AS Ref
	|INTO TTReturnItems
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS DocumentGoods
	|		INNER JOIN TTDocuments AS TTDocuments
	|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
	|WHERE
	|	NOT DocumentGoods.Canceled
	|	AND TTDocuments.Posted
	|	AND NOT DocumentGoods.Ref.Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon), 
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected))
	|GROUP BY
	|	CASE
	|		WHEN DocumentGoods.Damage
	|			THEN DocumentGoods.ProductsRecordingAsReceived
	|		ELSE DocumentGoods.Products
	|	END,
	|	CASE
	|		WHEN DocumentGoods.Damage
	|			THEN DocumentGoods.CharacteristicRecordingAsReceived
	|		ELSE DocumentGoods.Characteristic
	|	END,
	|	DocumentGoods.Damage,
	|	DocumentGoods.Ref.BusinessOperation,
	|	TTDocuments.DocumentRef
	|;
	|";
	Return QueryText
	
	
EndFunction

Function QueryTextTableReturnOfGoods(TableName, ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableReturnOfGoods") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableReturnOfGoods;
	EndIf;
	
	QueryText = "SELECT ALLOWED
	|	TTItemsForReturn.Request AS Document,
	|	TTItemsForReturn.Warehouse AS Warehouse,
	|	TTItemsForReturn.Accepts AS Accepts,
	|	TTItemsForReturn.Accepted AS Accepted,
	|	TTItemsForReturn.ToRegister AS ToRegister,
	|	TTItemsForReturn.Issued_1 AS Issued_1,
	|	TTItemsForReturn.ApplyAppearance AS ApplyAppearance,
	|	TTItemsForReturn.Accept AS Accept,
	|	TTItemsForReturn.Received AS Received,
	|	TTItemsForReturn.AdvancedWarehousingOnGoodsReceipt AS AdvancedWarehousingOnGoodsReceipt,
	|	TTItemsForReturn.Products AS Products,
	|	TTItemsForReturn.Characteristic AS Characteristic
	|FROM
	|	TTItemsForReturn AS TTItemsForReturn
	|		LEFT JOIN TTReturnItems AS TTReturnItems
	|		ON TTItemsForReturn.Request = TTReturnItems.Ref
	|			AND TTItemsForReturn.Products = TTReturnItems.Products
	|			AND TTItemsForReturn.Characteristic = TTReturnItems.Characteristic
	|		LEFT JOIN TTOrderingOfNH AS TTOrdering
	|		ON TTItemsForReturn.Request = TTOrdering.Document
	|			AND TTItemsForReturn.Products = TTOrdering.Products
	|			AND TTItemsForReturn.Characteristic = TTOrdering.Characteristic
	|WHERE
	|	NOT TTReturnItems.Products IS NULL 
	|	AND (TTItemsForReturn.Accept <> 0
	|			OR TTItemsForReturn.ApplyAppearance <> 0
	|			OR TTItemsForReturn.Issued_1 <> TTItemsForReturn.Received
	|				AND TTItemsForReturn.AdvancedWarehousingOnGoodsReceipt)
	|
	|ORDER BY
	|	TTOrdering.Order
	|TOTALS
	|	MAX(AdvancedWarehousingOnGoodsReceipt)
	|BY
	|	Document,
	|	Warehouse
	|;";
	
	Return QueryText
	
	
EndFunction

Function QueryTextTableReturnedItems(TableName, ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableReturnedItems") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableReturnedItems;
	EndIf;
	
	QueryText =" 
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TTReturnItems.Ref AS Document,
	|	TTReturnItems.Products AS Products,
	|	TTReturnItems.Characteristic AS Characteristic,
	|	TTReturnItems.Products.UnitOfMeasure AS Package,
	|	TTReturnItems.Count AS Count,
	|	TTReturnItems.AmountIncludingVAT AS Sum
	|FROM
	|	TTReturnItems AS TTReturnItems
	|		LEFT JOIN TTItemsForReturn AS TTItemsForReturn
	|		ON (TTItemsForReturn.Request = TTReturnItems.Ref)
	|			AND (TTItemsForReturn.Products = TTReturnItems.Products)
	|			AND (TTItemsForReturn.Characteristic = TTReturnItems.Characteristic)
	|		LEFT JOIN TTOrderingOfNH AS TTOrdering
	|		ON TTReturnItems.Ref = TTOrdering.Document
	|			AND TTReturnItems.Products = TTOrdering.Products
	|			AND TTReturnItems.Characteristic = TTOrdering.Characteristic
	|WHERE
	|	(TTItemsForReturn.Accept = 0
	|	AND TTItemsForReturn.ApplyAppearance = 0
	|	AND (TTItemsForReturn.Issued_1 = TTItemsForReturn.Received
	|		OR NOT TTItemsForReturn.AdvancedWarehousingOnGoodsReceipt))
	|		OR TTItemsForReturn.Request IS NULL
	|
	|ORDER BY
	|	TTOrdering.Order
	|TOTALS BY
	|	Document;
	|";
	
	Return QueryText
	
EndFunction

Function QueryTextTTProductsOrderedByGiver()
	
	QueryText = 
	"
	|SELECT
	|	GiverSOrder2_5Products.Products AS Products,
	|	GiverSOrder2_5Products.Characteristic AS Characteristic,
	|	MAX(GiverSOrder2_5Products.Package) AS Package,
	|	SUM(GiverSOrder2_5Products.Count) AS Count,
	|	SUM(GiverSOrder2_5Products.AmountIncludingVAT) AS Sum,
	|	GiverSOrder2_5Products.Ref AS Ref,
	|	MIN(GiverSOrder2_5Products.LineNumber) AS LineNumber
	|INTO TTProductsOrderedByGiver
	|FROM
	|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS GiverSOrder2_5Products
	|WHERE
	|	GiverSOrder2_5Products.Ref IN(&DocumentsArray)
	|	AND NOT GiverSOrder2_5Products.Canceled
	|
	|GROUP BY
	|	GiverSOrder2_5Products.Products,
	|	GiverSOrder2_5Products.Characteristic,
	|	GiverSOrder2_5Products.Ref
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic
	|;";

	Return QueryText;
	
EndFunction

Function QueryTextTableServicesOfMaterialProviderForRegistration()
	
	QueryText = 
	"
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ShippingOrdersTurnover.ReferenceOrder                                                       AS Document,
	|	ShippingOrdersTurnover.Products                                                       AS Products,
	|	ShippingOrdersTurnover.Characteristic                                                     AS Characteristic,
	|	CASE
	|		WHEN NestedQuery.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN NestedQuery.Products.UnitOfMeasure
	|		ELSE NestedQuery.Package
	|	END                                                                                    AS Package,
	|	(ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
	|		ShippingOrdersTurnover.IssuedQuantityTurnover) * ISNULL(&QueryTextPackagingFactor, 1) AS Count,
	|	CASE
	|		WHEN (ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
	|		ShippingOrdersTurnover.IssuedQuantityTurnover) = NestedQuery.Count
	|			THEN NestedQuery.Sum
	|		ELSE CAST(NestedQuery.Sum
	|			/ NestedQuery.Count
	|			* (ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
	|				ShippingOrdersTurnover.IssuedQuantityTurnover) AS NUMBER(31, 2))
	|	END                                                                                    AS Sum,
	|	TTOrdering.Order                                                                 AS LineNumber
	|FROM
	|	#ShipmentOrdersTurnoverExpanded AS ShippingOrdersTurnover
	|
	|		LEFT JOIN TTProductsOrderedByGiver AS NestedQuery
	|		ON ShippingOrdersTurnover.ReferenceOrder   = NestedQuery.Ref
	|			AND ShippingOrdersTurnover.Products   = NestedQuery.Products
	|			AND ShippingOrdersTurnover.Characteristic = NestedQuery.Characteristic
	|		LEFT JOIN TTOrderingOfNH AS TTOrdering
	|		ON ShippingOrdersTurnover.ReferenceOrder = TTOrdering.Document
	|			AND ShippingOrdersTurnover.Products = TTOrdering.Products
	|			AND ShippingOrdersTurnover.Characteristic = TTOrdering.Characteristic
	|WHERE
	|	(ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
	|		ShippingOrdersTurnover.IssuedQuantityTurnover) > 0
	|
	|ORDER BY
	|	TTOrdering.Order
	|TOTALS BY
	|	Document
	|;";
	
	// Subquery #Order of Offload Turnaround Expanded
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"(ReferenceOrder, Products, Characteristic) IN
		|		(SELECT
		|				Ref,
		|				Products,
		|				Characteristic
		|			FROM
		|				TTProductsOrderedByGiver)
		|		AND VALUETYPE(ReferenceOrder) = TYPE(Document.MaterialProviderOrder2_5)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"NestedQuery.Package",
			"NestedQuery.Products"));
	
	Return QueryText;
	
EndFunction

Function QueryTextTableProductsToBeProcessedInReportToProcessor(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
	   And StructureOfAdditionalRequests.Property("QueryTextTableProductsToBeProcessedInReportToProcessor") Then
		Return StructureOfAdditionalRequests.QueryTextTableProductsToBeProcessedInReportToProcessor;
	EndIf;
	
	QueryText = "";
	
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableRawMaterialsFromProcessor(QueryTexts, ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
	   And StructureOfAdditionalRequests.Property("TableRawMaterialsAtProcessor") Then
	   	
		QueryText = StructureOfAdditionalRequests.TableRawMaterialsAtProcessor;
		
		QueryTexts.Add(QueryText, "TableRawMaterialsAtProcessor");
		
		Return;
		
	EndIf;

	QueryText =  
	// 0
	"SELECT
	|	NestedQuery.Document,
	|	NestedQuery.Toller,
	|	NestedQuery.LineNumber,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	CASE
	|		WHEN NestedQuery.NumberOfUnits > 1
	|			THEN 1
	|		ELSE ISNULL(&QueryTextPackagingFactor, 1)
	|	END AS PackagingFactor,
	|	CASE
	|		WHEN NestedQuery.NumberOfUnits > 1
	|			THEN NestedQuery.Products.UnitOfMeasure
	|		ELSE NestedQuery.Package
	|	END AS Package,
	|	SUM(NestedQuery.Count) AS Count
	|INTO DocumentGoods
	|FROM
	|	(SELECT
	|		TTDocuments.DocumentRef AS Document,
	|		TableDocument.Partner AS Toller,
	|		DocumentGoods.Products AS Products,
	|		DocumentGoods.Characteristic AS Characteristic,
	|		CASE
	|			WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN DocumentGoods.Products.UnitOfMeasure
	|			ELSE DocumentGoods.Package
	|		END AS Package,
	|		MIN(DocumentGoods.LineNumber) AS LineNumber,
	|		SUM(DocumentGoods.Count) AS Count,
	|		COUNT(DISTINCT DocumentGoods.Package) AS NumberOfUnits
	|	FROM
	|		TTDocuments AS TTDocuments
	|			INNER JOIN Document.SubcontractOrder2_5 AS TableDocument
	|			ON (TableDocument.Ref = TTDocuments.DocumentRef)
	|			INNER JOIN Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS DocumentGoods
	|			ON TTDocuments.DocumentRef = DocumentGoods.Ref
	|				AND NOT DocumentGoods.Canceled
	|	
	|	GROUP BY
	|		TTDocuments.DocumentRef,
	|		TableDocument.Partner,
	|		DocumentGoods.Products,
	|		DocumentGoods.Characteristic,
	|		CASE
	|			WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN DocumentGoods.Products.UnitOfMeasure
	|			ELSE DocumentGoods.Package
	|		END
	|
	|
	|	UNION ALL
	|
	|	SELECT
	|		TTDocuments.DocumentRef AS Document,
	|		TableDocument.Partner AS Toller,
	|		DocumentGoods.Products AS Products,
	|		DocumentGoods.Characteristic AS Characteristic,
	|		CASE
	|			WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN DocumentGoods.Products.UnitOfMeasure
	|			ELSE DocumentGoods.Package
	|		END AS Package,
	|		MIN(DocumentGoods.LineNumber) AS LineNumber,
	|		SUM(DocumentGoods.Count) AS Count,
	|		COUNT(DISTINCT DocumentGoods.Package) AS NumberOfUnits
	|	FROM
	|		TTDocuments AS TTDocuments
	|			INNER JOIN Document.SubcontractOrder2_5 AS TableDocument
	|			ON (TableDocument.Ref = TTDocuments.DocumentRef)
	|			INNER JOIN Document.ProductionStage2_2 AS ProductionStage
	|			ON TableDocument.Ref = ProductionStage.SubcontractOrder
	|			INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS DocumentGoods
	|			ON ProductionStage.Ref = DocumentGoods.Ref
	|				AND NOT DocumentGoods.Canceled
	|
	|	GROUP BY
	|		TTDocuments.DocumentRef,
	|		TableDocument.Partner,
	|		DocumentGoods.Products,
	|		DocumentGoods.Characteristic,
	|		CASE
	|			WHEN DocumentGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN DocumentGoods.Products.UnitOfMeasure
	|			ELSE DocumentGoods.Package
	|		END
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Document,
	|	NestedQuery.Toller,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.LineNumber,
	|	CASE
	|		WHEN NestedQuery.NumberOfUnits > 1
	|			THEN 1
	|		ELSE ISNULL(&QueryTextPackagingFactor, 1)
	|	END,
	|	CASE
	|		WHEN NestedQuery.NumberOfUnits > 1
	|			THEN NestedQuery.Products.UnitOfMeasure
	|		ELSE NestedQuery.Package
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"NestedQuery.Package",
		"NestedQuery.Products"));
		
	QueryTexts.Add(QueryText, "TT_DocumentGoods");
	
	QueryText = "
	|SELECT DISTINCT
	|	DocumentGoods.Toller,
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic
	|INTO TT_Goods
	|FROM
	|	DocumentGoods AS DocumentGoods
	|
	|INDEX BY
	|	Toller,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	QueryTexts.Add(QueryText, "TT_Goods");
	
	QueryText = "
	// 2
	|SELECT
	|	DimensionOfProductItem.DimensionKey AS DimensionKey,
	|	DimensionOfProductItem.Products AS Products,
	|	DimensionOfProductItem.Characteristic AS Characteristic,
	|	CAST(DimensionOfProductItem.StorageLocation AS Catalog.Partners) AS Toller
	|INTO DimensionOfProductItem
	|FROM
	|	InformationRegister.ItemsLocationAttributes AS DimensionOfProductItem
	|WHERE
	|	(DimensionOfProductItem.Products, DimensionOfProductItem.Characteristic, DimensionOfProductItem.StorageLocation) IN
	|			(SELECT
	|				TT_Goods.Products,
	|				TT_Goods.Characteristic,
	|				TT_Goods.Toller
	|			FROM
	|				TT_Goods)
	|
	|INDEX BY
	|	DimensionKey
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	QueryTexts.Add(QueryText, "TT_DimensionOfProductItem");
	
	QueryText = "
	// 3
	|SELECT ALLOWED TOP 0
	|	DimensionOfProductItem.Toller AS Toller,
	|	DimensionOfProductItem.Products AS Products,
	|	DimensionOfProductItem.Characteristic AS Characteristic,
	|	0 AS Count
	|INTO TableBalance
	|FROM
	|	DimensionOfProductItem AS DimensionOfProductItem
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	QueryTexts.Add(QueryText, "TT_TableBalance");
	
	QueryText = "
	// 4
	|SELECT
	|	NestedQuery.Toller,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	SUM(NestedQuery.Ordered - NestedQuery.Issued_1) AS Demand
	|INTO TableNeed
	|FROM
	|	(
	|	SELECT
	|		TT_Goods.Toller AS Toller,
	|		TT_Goods.Products AS Products,
	|		TT_Goods.Characteristic AS Characteristic,
	|		OrderOfMaterials.Count AS Ordered,
	|		0 AS Issued_1
	|	FROM
	|		TT_Goods AS TT_Goods
	|			INNER JOIN Document.SubcontractOrder2_5.SupplyWithMaterialsAndWorks AS OrderOfMaterials
	|			ON OrderOfMaterials.Products = TT_Goods.Products
	|				AND OrderOfMaterials.Characteristic = TT_Goods.Characteristic
	|				AND OrderOfMaterials.Ref.Partner = TT_Goods.Toller
	|				AND OrderOfMaterials.Ref.Posted
	|				AND OrderOfMaterials.Ref.GroupCosts <> VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TT_Goods.Toller AS Toller,
	|		TT_Goods.Products AS Products,
	|		TT_Goods.Characteristic AS Characteristic,
	|		OrderOfMaterials.Count AS Ordered,
	|		0 AS Issued_1
	|	FROM
	|		TT_Goods AS TT_Goods
	|			INNER JOIN Document.SubcontractOrder2_5 AS DocSubcontractOrder
	|			ON DocSubcontractOrder.Partner = TT_Goods.Toller
	|				AND DocSubcontractOrder.GroupCosts = VALUE(Enum.CostGroupingsInTollingOrder.ByProductionStages)
	|				AND DocSubcontractOrder.Posted
	|			INNER JOIN Document.ProductionStage2_2 AS DocStage
	|			ON DocSubcontractOrder.Ref = DocStage.SubcontractOrder
	|			INNER JOIN Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS OrderOfMaterials
	|			ON OrderOfMaterials.Ref = DocStage.Ref
	|				AND OrderOfMaterials.Products = TT_Goods.Products
	|				AND OrderOfMaterials.Characteristic = TT_Goods.Characteristic
	|				AND NOT OrderOfMaterials.Canceled
	|
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Toller,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic
	|
	|INDEX BY
	|	Toller,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	QueryTexts.Add(QueryText, "TT_TableNeed");
	
	QueryText = "
	// 5
	|SELECT
	|	DocumentGoods.Document AS Document,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.Products.Presentation AS ProductsPresentation,
	|	DocumentGoods.Characteristic.Presentation AS CharacteristicPresentation,
	|	DocumentGoods.Package AS Package,
	|	ISNULL(TableBalance.Count, 0) * DocumentGoods.PackagingFactor AS InStock,
	|	ISNULL(TableNeed.Demand, 0) * DocumentGoods.PackagingFactor AS Demand,
	|	CASE
	|		WHEN ISNULL(TableNeed.Demand, 0) >= 0
	|			THEN (ISNULL(TableBalance.Count, 0) - ISNULL(TableNeed.Demand, 0)) * DocumentGoods.PackagingFactor
	|		ELSE 0
	|	END AS Surplus
	|FROM
	|	DocumentGoods AS DocumentGoods
	|		LEFT JOIN TableNeed AS TableNeed
	|		ON (TableNeed.Products = DocumentGoods.Products)
	|			AND (TableNeed.Characteristic = DocumentGoods.Characteristic)
	|			AND (TableNeed.Toller = DocumentGoods.Toller)
	|		LEFT JOIN TableBalance AS TableBalance
	|		ON (TableBalance.Products = DocumentGoods.Products)
	|			AND (TableBalance.Characteristic = DocumentGoods.Characteristic)
	|			AND (TableBalance.Toller = DocumentGoods.Toller)
	|		LEFT JOIN TTOrderingOfNH AS TTOrdering
	|		ON DocumentGoods.Document = TTOrdering.Document
	|			AND DocumentGoods.Products = TTOrdering.Products
	|			AND DocumentGoods.Characteristic = TTOrdering.Characteristic
	|
	|ORDER BY
	|	TTOrdering.Order
	|
	|TOTALS BY
	|	Document
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryTexts.Add(QueryText, "TableRawMaterialsAtProcessor");
	
EndProcedure

Function QueryTextTTOrderingNHC()

	QueryText =
	"SELECT ALLOWED
	|	TTDocuments.DocumentRef AS Document,
	|	MIN(DocumentGoods.LineNumber) AS Order,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.Series AS Series
	|INTO TTOrderingOfNHC
	|FROM
	|	Document.SalesOrder.Goods AS DocumentGoods
	|		INNER JOIN TTDocuments AS TTDocuments
	|		ON (TTDocuments.DocumentRef = DocumentGoods.Ref)
	|
	|GROUP BY
	|	TTDocuments.DocumentRef,
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Series
	|
	|INDEX BY
	|	Document,
	|	Products,
	|	Characteristic,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";

	Return QueryText;

EndFunction

Function QueryTextTTOrderingNH()

	QueryText =
	"SELECT ALLOWED
	|	TTOrderingOfNHC.Document AS Document,
	|	MIN(TTOrderingOfNHC.Order) AS Order,
	|	TTOrderingOfNHC.Products AS Products,
	|	TTOrderingOfNHC.Characteristic AS Characteristic
	|INTO TTOrderingOfNH
	|FROM
	|	TTOrderingOfNHC AS TTOrderingOfNHC
	|
	|GROUP BY
	|	TTOrderingOfNHC.Document,
	|	TTOrderingOfNHC.Products,
	|	TTOrderingOfNHC.Characteristic
	|
	|INDEX BY
	|	Document,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";

	Return QueryText;

EndFunction


#Region DeliveryRequestTests

Function QueryTextTTDeliveryOrderLines(TableName, ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	If ValueIsFilled(StructureOfAdditionalRequests)
	   And StructureOfAdditionalRequests.Property("TTDeliveryOrderLines") Then
		Return StructureOfAdditionalRequests.TTDeliveryOrderLines;
	EndIf;
	
	QueriesTexts = New Array; // Array of String
	
	QueryText =
	"SELECT DISTINCT
	|	ShipmentReferences.Recorder AS DocumentRef,
	|	ShipmentReferences.ReferenceOrder AS ReferenceOrder,
	|	ShipmentReferences.RowCode AS RowCode
	|INTO TTDeliveryOrderLines
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences AS ShipmentReferences
	|WHERE
	|	ShipmentReferences.Recorder IN
	|		(SELECT
	|			TTDocuments.DocumentRef AS DocumentRef
	|		FROM
	|			TTDocuments AS TTDocuments)
	|	AND ShipmentReferences.RowCode <> 0
	|	AND &ConditionsForRTiU";
	
	If TableName = "Document.CustomerInvoice" Then
		
		ConditionsForRTiU = "(NOT CAST(ShipmentReferences.Recorder AS Document.CustomerInvoice).OrderSales
		|	OR ISNULL(CAST(ShipmentReferences.ReferenceOrder AS Document.SalesOrder).ThisIsOrderAsInvoice, NOT &UseAdvancedFeaturesOfSalesOrder))";
		
	Else
		
		ConditionsForRTiU = "TRUE";
		
	EndIf;
	QueryText = StrReplace(QueryText, "&ConditionsForRTiU", ConditionsForRTiU);
	
	QueriesTexts.Add(QueryText);
	
	If TableName = "Document.CustomerInvoice"
	 Or TableName = "Document.SalesOrder"
	 Or TableName = "Document.GoodsShipmentToCustomer" Then
		
		QueryText =
		"SELECT DISTINCT
		|	LinesBeyondOrder.ReferenceOrder,
		|	LinesBeyondOrder.ReferenceOrder,
		|	LinesBeyondOrder.RowCode
		|FROM
		|	AccumulationRegister.Delivery AS LinesBeyondOrder
		|WHERE
		|	LinesBeyondOrder.ReferenceOrder IN
		|		(SELECT
		|			TTDocuments.DocumentRef AS DocumentRef
		|		FROM
		|			TTDocuments AS TTDocuments)
		|	AND &ConditionsForRTiU";
		
		If TableName = "Document.CustomerInvoice" Then
			
			ConditionsForRTiU = "(NOT CAST(LinesBeyondOrder.Recorder AS Document.CustomerInvoice).OrderSales
			|	OR ISNULL(CAST(LinesBeyondOrder.ReferenceOrder AS Document.SalesOrder).ThisIsOrderAsInvoice, NOT &UseAdvancedFeaturesOfSalesOrder))";
			
		Else
			
			ConditionsForRTiU = "TRUE";
			
		EndIf;
		QueryText = StrReplace(QueryText, "&ConditionsForRTiU", ConditionsForRTiU);
		
		QueriesTexts.Add(QueryText);
		
	EndIf;
	
	QueryText = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin(True))
		+ Common.QueryBatchSeparator();
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDeliveryTurnover(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	If ValueIsFilled(StructureOfAdditionalRequests)
	   And StructureOfAdditionalRequests.Property("TTDeliveryTurnover") Then
		Return StructureOfAdditionalRequests.QueryTextTableDelivery;
	EndIf;
	
	QueryText =
	"SELECT
	|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
	|	DeliveryTurnover.RowCode AS RowCode,
	|	DeliveryTurnover.Products AS Products,
	|	DeliveryTurnover.Characteristic AS Characteristic,
	|	DeliveryTurnover.Series AS Series,
	|	DeliveryTurnover.ToDeliverTurnover AS ToDeliverTurnover,
	|	DeliveryTurnover.ToTripTurnover AS ToTripTurnover,
	|	DeliveryTurnover.InTripTurnover AS InTripTurnover,
	|	DeliveryTurnover.InTransitTurnover AS InTransitTurnover,
	|	DeliveryTurnover.DeliveredTurnover AS DeliveredTurnover,
	|	DeliveryTurnover.CanceledTurnover AS CanceledTurnover
	|INTO TTDeliveryTurnover
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(
	|			,
	|			,
	|			,
	|			DeliveryType = &DeliveryType
	|				AND Arm = 1
	|				AND (ReferenceOrder, RowCode) IN
	|					(SELECT
	|						TTDeliveryOrderLines.ReferenceOrder AS ReferenceOrder,
	|						TTDeliveryOrderLines.RowCode AS RowCode
	|					FROM
	|						TTDeliveryOrderLines AS TTDeliveryOrderLines)) AS DeliveryTurnover";
	
	QueryText = QueryText + Common.QueryBatchSeparator();
	Return QueryText;
	
EndFunction

Function QueryTextTableDelivery(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	If ValueIsFilled(StructureOfAdditionalRequests)
	   And StructureOfAdditionalRequests.Property("QueryTextTableDelivery") Then
		Return StructureOfAdditionalRequests.QueryTextTableDelivery;
	EndIf;
	
	QueryText =
	"SELECT
	|	TTDeliveryOrderLines.DocumentRef AS Document,
	|	TTDeliveryTurnover.Products AS Products,
	|	TTDeliveryTurnover.Characteristic AS Characteristic,
	|	TTDeliveryTurnover.Series AS Series,
	|	COUNT(*) AS NumberOfGoodsRows,
	|	SUM(TTDeliveryTurnover.ToDeliverTurnover) AS ToDeliverTurnover,
	|	SUM(TTDeliveryTurnover.ToTripTurnover) AS ToTripTurnover,
	|	SUM(TTDeliveryTurnover.InTripTurnover) AS InTripTurnover,
	|	SUM(TTDeliveryTurnover.InTransitTurnover) AS InTransitTurnover,
	|	SUM(TTDeliveryTurnover.DeliveredTurnover) AS DeliveredTurnover,
	|	SUM(TTDeliveryTurnover.CanceledTurnover) AS CanceledTurnover,
	|	SUM(TTDeliveryTurnover.ToDeliverTurnover) - SUM(TTDeliveryTurnover.ToTripTurnover) AS ToPlan,
	|	SUM(TTDeliveryTurnover.ToTripTurnover) - SUM(TTDeliveryTurnover.InTripTurnover) + SUM(TTDeliveryTurnover.CanceledTurnover) AS ApplyAppearance,
	|	SUM(TTDeliveryTurnover.InTripTurnover) - SUM(TTDeliveryTurnover.CanceledTurnover) AS Issued_1
	|FROM
	|	TTDeliveryOrderLines AS TTDeliveryOrderLines
	|		INNER JOIN TTDeliveryTurnover AS TTDeliveryTurnover
	|		ON TTDeliveryOrderLines.ReferenceOrder = TTDeliveryTurnover.ReferenceOrder
	|			AND TTDeliveryOrderLines.RowCode = TTDeliveryTurnover.RowCode
	|		LEFT JOIN TTOrderingOfNHC AS TTOrdering
	|		ON TTDeliveryTurnover.ReferenceOrder = TTOrdering.Document
	|			AND TTDeliveryTurnover.Products = TTOrdering.Products
	|			AND TTDeliveryTurnover.Characteristic = TTOrdering.Characteristic
	|			AND TTDeliveryTurnover.Series = TTOrdering.Series
	|GROUP BY
	|	TTDeliveryOrderLines.DocumentRef,
	|	TTDeliveryTurnover.Products,
	|	TTDeliveryTurnover.Characteristic,
	|	TTDeliveryTurnover.Series
	|HAVING
	|	SUM(TTDeliveryTurnover.ToDeliverTurnover) <> SUM(TTDeliveryTurnover.DeliveredTurnover)
	|
	|ORDER BY
	|	MIN(TTOrdering.Order)
	|TOTALS
	|	SUM(NumberOfGoodsRows),
	|	SUM(ToDeliverTurnover),
	|	SUM(ToTripTurnover),
	|	SUM(InTripTurnover),
	|	SUM(InTransitTurnover),
	|	SUM(DeliveredTurnover)
	|
	|BY
	|	Document";
	
	QueryText = QueryText + Common.QueryBatchSeparator();
	Return QueryText;
	
EndFunction

Function QueryTextTableDelivered(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	If ValueIsFilled(StructureOfAdditionalRequests)
	   And StructureOfAdditionalRequests.Property("QueryTextTableDelivered") Then
		Return StructureOfAdditionalRequests.QueryTextTableDelivery;
	EndIf;
	
	QueryText =
	"SELECT
	|	TTDeliveryOrderLines.DocumentRef AS Document,
	|	TTDeliveryTurnover.Products AS Products,
	|	TTDeliveryTurnover.Characteristic AS Characteristic,
	|	TTDeliveryTurnover.Series AS Series,
	|	CAST(TTDeliveryTurnover.Products AS Catalog.Products).UnitOfMeasure AS Package,
	|	COUNT(*) AS NumberOfGoodsRows,
	|	SUM(TTDeliveryTurnover.DeliveredTurnover) AS DeliveredTurnover
	|FROM
	|	TTDeliveryOrderLines AS TTDeliveryOrderLines
	|		INNER JOIN TTDeliveryTurnover AS TTDeliveryTurnover
	|		ON TTDeliveryOrderLines.ReferenceOrder = TTDeliveryTurnover.ReferenceOrder
	|			AND TTDeliveryOrderLines.RowCode = TTDeliveryTurnover.RowCode
	|		LEFT JOIN TTOrderingOfNHC AS TTOrdering
	|		ON TTDeliveryTurnover.ReferenceOrder = TTOrdering.Document
	|			AND TTDeliveryTurnover.Products = TTOrdering.Products
	|			AND TTDeliveryTurnover.Characteristic = TTOrdering.Characteristic
	|			AND TTDeliveryTurnover.Series = TTOrdering.Series
	|GROUP BY
	|	TTDeliveryOrderLines.DocumentRef,
	|	TTDeliveryTurnover.Products,
	|	TTDeliveryTurnover.Characteristic,
	|	TTDeliveryTurnover.Series
	|HAVING
	|	SUM(TTDeliveryTurnover.ToDeliverTurnover) = SUM(TTDeliveryTurnover.DeliveredTurnover)
	|
	|ORDER BY
	|	MIN(TTOrdering.Order)
	|TOTALS
	|	SUM(NumberOfGoodsRows)
	|
	|BY
	|	Document";
	
	QueryText = QueryText + Common.QueryBatchSeparator();
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region DataOutput

// Parameters:
// 	ReportTable - SpreadsheetDocument
// 	Template - SpreadsheetDocument
// 	Selection - ValueTableRow - must contain:
// 		* Ref - DocumentRef
// 		* DocumentNumber - String
// 		* DocumentDate - Date
//
Procedure OutputReportHeader(ReportTable, Template, Selection)
	
	Area = Template.GetArea("Title");
	
	ParametersStructure = New Structure;
	If TypeOf(Selection.Ref) = Type("DocumentRef.ContractSchedule") Then
		ParametersStructure.Insert("DocumentName", String(Selection.Ref));
	ElsIf TypeOf(Selection.Ref) = Type("DocumentRef.GoodsReceiptForStorage")
			And Common.ObjectAttributeValue(Selection.Ref, "BusinessOperation") = 
				Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		ParametersStructure.Insert(
			"DocumentName",
			StrTemplate(NStr("vi = '%1 %2 ngày %3';
							|ru = '%1 %2 от %3';
							|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
							|it = '%1 %2 del %3';
							|pl = '%1 %2 z dnia %3';
							|tr = '%3 tarihli %1 %2'"),
					  TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage(),
					  Selection.DocumentNumber,
					  Format(Selection.DocumentDate, "DLF=D")));
	Else
		ParametersStructure.Insert("DocumentName", TMCommonUse.GetDocumentPresentation(Selection.Ref, 
		Selection.DocumentNumber, 
		Selection.DocumentDate));
	EndIf;
	Area.Parameters.Fill(ParametersStructure);
	Area.Parameters.ParametersStructure = New Structure("OrderDocument, Action", Selection.Ref, "OpenValue");
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Taxi Then
		HeaderArea_ = Area.Areas.HeaderArea_; // SpreadsheetDocumentRange
		HeaderArea_.TextColor = StyleColors.TextColorReportTitleInTaxi;
	EndIf;
	
	ReportTable.Put(Area);
	
EndProcedure

Function DisplaySubordinateDocumentsTable(ReportTable, Template, Document, ResultTables)
	
	If Not ResultTables.Property("TableSubordinateDocuments") Then
		Return False;
	EndIf;
	
	SubordinateDocuments = ResultTables.TableSubordinateDocuments.Rows.Find(Document, "Document");
	If SubordinateDocuments = Undefined Then
		Return False;
	EndIf;
	
	AreaName = "ARAPObjectSettings";
	Area = Template.GetArea(AreaName);
	Area.Parameters.Fill(SubordinateDocuments);
	ReportTable.Put(Area);
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);

	Title = NStr("vi = 'Đối tượng hạch toán (%1%)';
				|ru = 'Объекты расчетов (%1%)';
				|en = 'AR/AP objects (%1%)'; fa = 'AR/AP objects (%1%)';
				|it = 'Oggetti dei calcoli (%1%)';
				|pl = 'Obiekty rozliczeń (%1%)';
				|tr = 'Alacak/Borç nesnesi (%1%)'");
	TitleStructure = New Structure("Title", 
							StrReplace(Title, "%1%", SubordinateDocuments.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	AreaName = "StringSubordinateDocument";
	Area = Template.GetArea(AreaName);
	
	For Each LineDocument In SubordinateDocuments.Rows Do
		Area.Parameters.PresentationOfDocument = String(LineDocument.SubordinateDocument)
			+ " " + NStr("vi = 'với số tiền';
						|ru = 'на сумму';
						|en = 'in the amount of'; fa = 'به مبلغ';
						|it = 'per l''importo di';
						|pl = 'na kwotę';
						|tr = 'tutarında'") + " " + Format(LineDocument.DocumentAmount,"NFD=2") + " " 
			+ LineDocument.Currency;
		Area.Parameters.ParametersStructure = New Structure("OrderDocument, Action", 
			LineDocument.SubordinateDocument,
			"OpenValue");
		ReportTable.Put(Area);
	EndDo;
	
	ReportTable.EndRowGroup();
	
	Return True;
	
EndFunction

Function DisplayUnsecuredGoodsTable(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableUnsecuredGoods") Then
		Return False;
	EndIf;
	
	UnsecuredGoods = ResultTables.TableUnsecuredGoods.Rows.Find(Document, "Document");
	If UnsecuredGoods = Undefined Then
		Return False;
	EndIf;
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	Title = NStr("vi = 'Hàng hóa và dịch vụ không đảm bảo (%1%)';
				|ru = 'Необеспеченные товары и услуги (%1%)';
				|en = 'Not supplied goods and services (%1%)'; fa = 'Not supplied goods and services (%1%)';
				|it = 'Merci e servizi non garantiti (%1%)';
				|pl = 'Niezabezpieczone wiersze pozycji i usługi (%1%)';
				|tr = 'Tedarik edilmeyen ürün ve hizmetler (%1%)'");
	TitleStructure = New Structure("Title", 
							StrReplace(Title, "%1%", UnsecuredGoods.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	If ParametersStructure.ThereAreSummaryShipmentIndicators Then
		AreaNameTableHeader = "TableHeaderNotProvided";
		AreaNameTableRow = "TableRowNotProvided";
		NameOfTableAreaString = "TableNotProvidedRow";
	Else
		AreaNameTableHeader = "TableHeaderIsNotSecuredWithoutAmounts";
		AreaNameTableRow = "TableRowIsNotSecuredWithoutSums";
		NameOfTableAreaString = "TableNotSecuredRowWithNoAmounts";
	EndIf;
	
	Area = Template.GetArea(AreaNameTableHeader);
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceShipment;
	ReportTable.Put(Area);
	
	Area = Template.GetArea(AreaNameTableRow);
	RowArea = Area.Areas[NameOfTableAreaString]; // SpreadsheetDocumentRange

	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In UnsecuredGoods.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
					RowGoods.Products,
					RowGoods.Characteristic);
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	ReportTable.EndRowGroup();
	
	Return True
	
EndFunction

Function DisplaySoftwareStateTable(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableStateOfProvision") Then
		Return False;
	EndIf;
	
	ToProvideGoods = ResultTables.TableStateOfProvision.Rows.Find(Document, "Document");
	If ToProvideGoods = Undefined Then
		Return False;
	EndIf;
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	Title = NStr("vi = 'Đảm bảo (%1%)';
				|ru = 'Обеспечение (%1%)';
				|en = 'Supply (%1%)'; fa = 'Supply (%1%)';
				|it = 'Garanzia (%1%)';
				|pl = 'Zaopatrzenie (%1%)';
				|tr = 'Tedarik (%1%)'");
	TitleStructure = New Structure("Title", 
							StrReplace(Title, "%1%", ToProvideGoods.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	If ParametersStructure.ThereAreSummaryShipmentIndicators Then
		AreaNameTableHeader = "HeaderOfSecurityTable";
		AreaNameTableRow = "RowOfSecurityTable";
		NameOfTableAreaString = "TableSupplyRow";
	Else
		AreaNameTableHeader = "HeaderOfSecurityTableWithoutAmounts";
		AreaNameTableRow = "TableRowCollateralWithoutAmounts";
		NameOfTableAreaString = "TableSupplyRowWithoutSums";
	EndIf;
	
	Area = Template.GetArea(AreaNameTableHeader);
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceShipment;
	ReportTable.Put(Area);
	
	Area = Template.GetArea(AreaNameTableRow);
	RowArea = Area.Areas[NameOfTableAreaString]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In ToProvideGoods.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
					RowGoods.Products,
					RowGoods.Characteristic,
					,
					RowGoods.Series);
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	If YouHaveRightToAccessDataSet("SoftwareAdditionally", ParametersStructure) Then
		AreaName = "TableRowProvisionOptional";
		Area = Template.GetArea(AreaName);
		Area.Parameters.ParametersStructure = New Structure("OrderDocument, Action", 
			Common.ObjectAttributeValue(Document, "Ref"), "OpenSoftwareState");
		ReportTable.Put(Area);
	EndIf;
	
	ReportTable.EndRowGroup();
	
	Return True;
	
EndFunction

Function DisplayShipmentTable(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("ShippingTable") Then
		Return False;
	EndIf;
	
	ShippingGoods = ResultTables.ShippingTable.Rows.Find(Document, "Document");
	If ShippingGoods = Undefined Then
		Return False;
	EndIf;
	
	For Each ShipmentOfGoodsByWarehouse In ShippingGoods.Rows Do
		
		DisplayShipmentTableByWarehouse(ReportTable, Template, ShipmentOfGoodsByWarehouse, ParametersStructure);
		
	EndDo;
	
	Return True;
	
EndFunction

Function DisplayShippedTable(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableShipped") Then
		Return False;
	EndIf;
	
	ShippedGoods_0 = ResultTables.TableShipped.Rows.Find(Document, "Document");
	If ShippedGoods_0 = Undefined Then
		Return False;
	EndIf;
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	Title = NStr("vi = 'Đã giao hàng (%1%)';
				|ru = 'Отгружено (%1%)';
				|en = 'Shipped (%1%)'; fa = 'Shipped (%1%)';
				|it = 'Spedito (%1%)';
				|pl = 'Wysłano (%1%)';
				|tr = 'Sevk edildi (%1%)'");
	TitleStructure = New Structure("Title", 
							StrReplace(Title, "%1%", ShippedGoods_0.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	If ParametersStructure.ThereAreSummaryShipmentIndicators Then
		AreaNameTableHeader = "HeaderOfShippedTable";
		AreaNameTableRow = "TableRowShipped";
		NameOfTableAreaString = "TableShippedRow";
	Else
		AreaNameTableHeader = "HeaderOfTableShippedWithoutAmounts";
		AreaNameTableRow = "TableRowShippedWithoutAmounts";
		NameOfTableAreaString = "TableShippedRowWithoutAmounts";
	EndIf;
	
	Area = Template.GetArea(AreaNameTableHeader);
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceShipment;
	ReportTable.Put(Area);
	
	Area = Template.GetArea(AreaNameTableRow);
	RowArea = Area.Areas[NameOfTableAreaString]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In ShippedGoods_0.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
					RowGoods.Products,
					RowGoods.Characteristic,
					,
					RowGoods.Series);
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		If ParametersStructure.ActionDecryptionQuantityShipped <> Undefined Then
			DecryptionQuantity = New Structure("Products,Characteristic,Series");
			FillPropertyValues(DecryptionQuantity, RowGoods);
			DecryptionQuantity.Insert("Document", Document);
			DecryptionQuantity.Insert("Action", ParametersStructure.ActionDecryptionQuantityShipped);
			Area.Parameters.DecryptionQuantity = DecryptionQuantity;
		EndIf; 
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
	Return True;
	
EndFunction

Function DisplayDeliveryTable(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableDelivery") Then
		Return False;
	EndIf;
	
	GoodsWithDelivery = ResultTables.TableDelivery.Rows.Find(Document, "Document");
	If GoodsWithDelivery = Undefined Then
		Return False;
	EndIf;
	
	GoodsQuantity = GoodsWithDelivery.Rows.Count();
	NumberOfGoodsPerLine = String(GoodsQuantity);
	TotalForDelivery = GoodsWithDelivery.ToDeliverTurnover;
	TotalForTrip = GoodsWithDelivery.ToTripTurnover;
	TotalOfTrip = GoodsWithDelivery.InTripTurnover;
	TotalDelivered = GoodsWithDelivery.DeliveredTurnover;
	
	If TotalForDelivery > TotalForTrip Then
		
		TitleTemplate1 = NStr("ru = 'Ожидается планирование доставки (%1)';
								|vi = 'Pending delivery planning (%1)';
								|en = 'Pending delivery planning (%1)'; fa = 'Pending delivery planning (%1)';
								|it = 'Pending delivery planning (%1)';
								|pl = 'Pending delivery planning (%1)';
								|tr = 'Teslimat planlaması bekleniyor (%1)'");
		
	ElsIf TotalForDelivery =  TotalForTrip
	        And TotalOfTrip = 0 Then
		
		TitleTemplate1 = NStr("ru = 'Готово к доставке (%1)';
								|vi = 'Ready for delivery (%1)';
								|en = 'Ready for delivery (%1)'; fa = 'Ready for delivery (%1)';
								|it = 'Ready for delivery (%1)';
								|pl = 'Ready for delivery (%1)';
								|tr = 'Teslimata hazır (%1)'");
		
	ElsIf TotalForDelivery = TotalForTrip
	        And TotalOfTrip > 0
	        And TotalForTrip > TotalDelivered Then
		
		TitleTemplate1 = NStr("ru = 'В процессе доставки (%1)';
								|vi = 'Under delivery (%1)';
								|en = 'Under delivery (%1)'; fa = 'Under delivery (%1)';
								|it = 'Under delivery (%1)';
								|pl = 'Under delivery (%1)';
								|tr = 'Teslimat sürecinde (%1)'");
		
	ElsIf TotalForDelivery = TotalForTrip
	        And TotalForTrip = TotalDelivered Then
		
		TitleTemplate1 = NStr("ru = 'Доставлено (%1)';
								|vi = 'Delivered (%1)';
								|en = 'Delivered (%1)'; fa = 'Delivered (%1)';
								|it = 'Delivered (%1)';
								|pl = 'Delivered (%1)';
								|tr = 'Teslim edildi (%1)'");
		
	Else
		
		TitleTemplate1 = NStr("ru = 'Некорректное состояние доставки';
								|vi = 'Incorrect delivery state';
								|en = 'Incorrect delivery state'; fa = 'Incorrect delivery state';
								|it = 'Incorrect delivery state';
								|pl = 'Incorrect delivery state';
								|tr = 'Geçersiz teslimat durumu'");
		
	EndIf;
	
	DeliveryHeader = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, NumberOfGoodsPerLine);
	TitleStructure = New Structure("Title", DeliveryHeader);
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	Area = Template.GetArea("DeliveryTableHeader");
	Area.Parameters.TextProductService = NStr("ru = 'Товар';
												|vi = 'Goods';
												|en = 'Goods'; fa = 'کالاها';
												|it = 'Goods';
												|pl = 'Goods';
												|tr = 'Mal'");
	ReportTable.Put(Area);
	
	Area = Template.GetArea("DeliveryTableRow");
	RowArea = Area.Areas["DeliveryRowTable"]; // SpreadsheetDocumentRange
	EvenString = False;
	
	For Each RowGoods In GoodsWithDelivery.Rows Do
		
		If EvenString Then
			BackColor = StyleColors.FieldAlternativeBackColor;
		Else
			BackColor = StyleColors.FieldBackColor;
		EndIf;
		RowArea.BackColor = BackColor;
		
		Area.Parameters.Fill(RowGoods);
		
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
			RowGoods.Products,
			RowGoods.Characteristic,
			,
			RowGoods.Series);
		
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
	Return True;
	
EndFunction

Function DisplayDeliveredTable(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableDelivered") Then
		Return False;
	EndIf;
	
	GoodsWithDelivery = ResultTables.TableDelivered.Rows.Find(Document, "Document");
	If GoodsWithDelivery = Undefined Then
		Return False;
	EndIf;
	
	GoodsQuantity = GoodsWithDelivery.Rows.Count();
	NumberOfGoodsPerLine = String(GoodsQuantity);
	
	TitleTemplate1 = NStr("ru = 'Доставлено (%1)';
							|vi = 'Delivered (%1)';
							|en = 'Delivered (%1)'; fa = 'Delivered (%1)';
							|it = 'Delivered (%1)';
							|pl = 'Delivered (%1)';
							|tr = 'Teslim edildi (%1)'");
	DeliveryHeader = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, NumberOfGoodsPerLine);
	TitleStructure = New Structure("Title", DeliveryHeader);
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	Area = Template.GetArea("TableHeaderDelivered");
	Area.Parameters.TextProductService = NStr("ru = 'Товар';
												|vi = 'Goods';
												|en = 'Goods'; fa = 'کالاها';
												|it = 'Goods';
												|pl = 'Goods';
												|tr = 'Mal'");
	ReportTable.Put(Area);
	
	Area = Template.GetArea("TableRowDelivered");
	RowArea = Area.Areas["TableDeliveredRow"]; // SpreadsheetDocumentRange
	EvenString = False;
	
	For Each RowGoods In GoodsWithDelivery.Rows Do
		
		If EvenString Then
			BackColor = StyleColors.FieldAlternativeBackColor;
		Else
			BackColor = StyleColors.FieldBackColor;
		EndIf;
		RowArea.BackColor = BackColor;
		
		Area.Parameters.Fill(RowGoods);
		
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
			RowGoods.Products,
			RowGoods.Characteristic,
			,
			RowGoods.Series);
		
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
	Return True;
	
EndFunction

Function DisplayPPPTable(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableOfPPS") Then
		Return False;
	EndIf;
	
	ItemsToTransferOwnership = ResultTables.TableOfPPS.Rows.Find(Document, "Document");
	If ItemsToTransferOwnership = Undefined Then
		Return False;
	EndIf;
	
	DisplayTableOfTransferOfOwnership(ReportTable, Template, ItemsToTransferOwnership, ParametersStructure);
	
	Return True;
	
EndFunction

Function DisplayTableOfPPPFormalized(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableOfPPSIssued") Then
		Return False;
	EndIf;
	
	ItemsToTransferOwnership = ResultTables.TableOfPPSIssued.Rows.Find(Document, "Document");
	If ItemsToTransferOwnership = Undefined Then
		Return False;
	EndIf;
	
	ToDisplayTableOfTransferOfOwnershipFormalized(ReportTable, Template, ItemsToTransferOwnership, ParametersStructure);
	
	Return True;
	
EndFunction

Function DisplayReceiptTable(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("ReceiptTable") Then
		Return False;
	EndIf;
	
	ReceiptOfGoods_ = ResultTables.ReceiptTable.Rows.Find(Document, "Document");
	If ReceiptOfGoods_ = Undefined Then
		Return False;
	EndIf;
	
	For Each ReceiptOfGoodsInWarehouse In ReceiptOfGoods_.Rows Do
		
		DisplayReceiptTableForWarehouse(ReportTable, Template, ReceiptOfGoodsInWarehouse, ParametersStructure);
		
	EndDo;
	
	Return True;
	
EndFunction

Function OutputTableReceived(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableReceived") Then
		Return False;
	EndIf;
	
	GoodsReceived = ResultTables.TableReceived.Rows.Find(Document, "Document");
	If GoodsReceived = Undefined Then
		Return False;
	EndIf;
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	Title = NStr("vi = 'Đã tiếp nhận (%1%)';
				|ru = 'Поступило (%1%)';
				|en = 'Received (%1%)'; fa = 'Received (%1%)';
				|it = 'Ricevuto (%1%)';
				|pl = 'Wpłynęło (%1%)';
				|tr = 'Geldi (%1%)'");
	TitleStructure = New Structure("Title", 
							StrReplace(Title, "%1%", GoodsReceived.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	If ParametersStructure.ThereAreSummaryIndicatorsOfReceipt Then
		AreaNameTableHeader = "HeaderOfReceivedTable";
		AreaNameTableRow = "TableRowReceived";
		NameOfTableAreaString = "TableReceivedRow";
	Else
		AreaNameTableHeader = "TableHeaderReceivedWithoutAmounts";
		AreaNameTableRow = "TableRowReceivedWithoutAmounts";
		NameOfTableAreaString = "TableReceivedRowWithoutAmounts";
	EndIf;
	
	Area = Template.GetArea(AreaNameTableHeader);
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceReceipt;
	ReportTable.Put(Area);
	
	Area = Template.GetArea(AreaNameTableRow);
	RowArea = Area.Areas[NameOfTableAreaString]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In GoodsReceived.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
					RowGoods.Products,
					RowGoods.Characteristic);
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		If ParametersStructure.ActionDecryptionQuantityReceived <> Undefined Then
			DecryptionQuantity = New Structure("Products,Characteristic,Series");
			FillPropertyValues(DecryptionQuantity, RowGoods);
			DecryptionQuantity.Insert("Document", Document);
			DecryptionQuantity.Insert("Action", ParametersStructure.ActionDecryptionQuantityReceived);
			Area.Parameters.DecryptionQuantity = DecryptionQuantity;
		EndIf; 
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
	Return True;
	
EndFunction

Function DisplayOrderedTable(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableOrdered") Then
		Return False;
	EndIf;
	
	GoodsReceived = ResultTables.TableOrdered.Rows.Find(Document, "Document");
	If GoodsReceived = Undefined Then
		Return False;
	EndIf;
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	Title = NStr("vi = 'Đã đặt hàng (%1%)';
				|ru = 'Заказано (%1%)';
				|en = 'Ordered (%1%)'; fa = 'Ordered (%1%)';
				|it = 'Ordinato (%1%)';
				|pl = 'Zamówiono (%1%)';
				|tr = 'Sipariş edilenler (%1%)'");
	TitleStructure = New Structure("Title", 
							StrReplace(Title, "%1%", GoodsReceived.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	If ParametersStructure.ThereAreSummaryIndicatorsOfReceipt Then
		AreaNameTableHeader = "HeaderOfReceivedTable";
		AreaNameTableRow = "TableRowReceived";
		NameOfTableAreaString = "TableReceivedRow";
	Else
		AreaNameTableHeader = "TableHeaderReceivedWithoutAmounts";
		AreaNameTableRow = "TableRowReceivedWithoutAmounts";
		NameOfTableAreaString = "TableReceivedRowWithoutAmounts";
	EndIf;
	
	Area = Template.GetArea(AreaNameTableHeader);
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceReceipt;
	ReportTable.Put(Area);
	
	Area = Template.GetArea(AreaNameTableRow);
	RowArea = Area.Areas[NameOfTableAreaString]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In GoodsReceived.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
					RowGoods.Products,
					RowGoods.Characteristic);
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		If ValueIsFilled(RowGoods.Package) Then
			Area.Parameters.Count = RowGoods.NumberOfPackages;
		EndIf;
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
	Return True;
	
EndFunction

Function OutputTableToOrder(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableToOrder") Then
		Return False;
	EndIf;
	
	Goods = ResultTables.TableToOrder.Rows.Find(Document, "Document");
	If Goods = Undefined Then
		Return False;
	EndIf;
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	Title = NStr("ru = 'К заказу (%1%)';
				|vi = 'To order (%1%)';
				|en = 'To order (%1%)'; fa = 'To order (%1%)';
				|it = 'To order (%1%)';
				|pl = 'To order (%1%)';
				|tr = 'Sipariş eklenecek  (%1%)'");
	TitleStructure = New Structure("Title", 
							StrReplace(Title, "%1%", Goods.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	AreaNameTableHeader = "HeaderOfTableForOrder";
	AreaNameTableRow = "TableRowForOrder";
	NameOfTableAreaString = "TableToOrderRow";
	
	Area = Template.GetArea(AreaNameTableHeader);
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceReceipt;
	ReportTable.Put(Area);
	
	Area = Template.GetArea(AreaNameTableRow);
	RowArea = Area.Areas[NameOfTableAreaString]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In Goods.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		Area.Parameters.Package = RowGoods.PackagePresentation;
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
					RowGoods.ProductsPresentation,
					RowGoods.CharacteristicPresentation,
					RowGoods.PackagePresentation,,
					RowGoods.PurposePresentation);
					
		If ValueIsFilled(RowGoods.WarehousePresentation) Then
			Recipient = RowGoods.WarehousePresentation;
		ElsIf ValueIsFilled(RowGoods.DepartmentPresentation) Then
			Recipient = RowGoods.DepartmentPresentation
		EndIf;
		
		If ValueIsFilled(Recipient) Then
			PresentationOfProductsForPrinting = PresentationOfProductsForPrinting + " / " + Recipient;
		EndIf;
		
		PresentationOfPartnerAgreement = "";
		If ValueIsFilled(RowGoods.PartnerPresentation)
			And ValueIsFilled(RowGoods.TermsPresentation) Then
			PresentationOfPartnerAgreement = StrTemplate(" / %1 / %2)",
				RowGoods.PartnerPresentation,
				RowGoods.TermsPresentation);
		ElsIf ValueIsFilled(RowGoods.PartnerPresentation) Then
			PresentationOfPartnerAgreement = StrTemplate(" / %1", RowGoods.PartnerPresentation);
		EndIf;
		
		PresentationOfProductsForPrinting = PresentationOfProductsForPrinting + PresentationOfPartnerAgreement;
		
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
	Return True;
	
EndFunction

Procedure DisplayShipmentTableByWarehouse(ReportTable, Template, GoodsInStock_, ParametersStructure)
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	If ValueIsFilled(GoodsInStock_.Warehouse) Then 
		TableHeading = NStr("vi = 'Đang giao hàng đến kho ""%OriginWarehouse%"" (%1%)';
							|ru = 'В процессе отгрузки на складе ""%OriginWarehouse%"" (%1%)';
							|en = 'While shipping in warehouse ""%OriginWarehouse%"" (%1%)'; fa = 'While shipping in warehouse ""%OriginWarehouse%"" (%1%)';
							|it = 'In fase di spedizione nel magazzino ""%OriginWarehouse%"" (%1%)';
							|pl = 'W trakcie wysyłki na magazynie ""%OriginWarehouse%"" (%1%)';
							|tr = '""%OriginWarehouse%"" ambarda sevkiyat sürecinde (%1%)'");
		TableHeading = StrReplace(TableHeading, "%OriginWarehouse%", GoodsInStock_.Warehouse);
	Else
		TableHeading = NStr("vi = 'Dịch vụ và công việc đang cần lập chứng từ (%1%)';
							|ru = 'Услуги и работы в процессе оформления (%1%)';
							|en = 'Services and labor under registration (%1%)'; fa = 'Services and labor under registration (%1%)';
							|it = 'Servizi e lavori nel processo di registrazione (%1%)';
							|pl = 'Usługi i prace w procesie tworzenia (%1%)';
							|tr = 'Hizmet ve işler kayıt sürecinde (%1%)'");
	EndIf;
	TitleStructure = New Structure("Title", 
							StrReplace(TableHeading, "%1%", GoodsInStock_.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	If ParametersStructure.ThisIsAnInvoice Then
		HeaderOfShipmentTable = "HeaderOfShipmentInvoiceTable";
		RowOfShipmentTable = "RowOfShipmentInvoiceTable";
		TableShipmentRow = "TableShipmentLineInvoice";
	ElsIf Not (ParametersStructure.ThisIsOrder And GoodsInStock_.AdvancedWarehousingOnShipment) Then
		HeaderOfShipmentTable = "HeaderOfShipmentWithoutOrderTable";
		RowOfShipmentTable = "TableRowShipmentWithoutOrder";
		TableShipmentRow = "TableShipmentRowWithoutOrder";
	Else
		HeaderOfShipmentTable = "HeaderOfShipmentTable";
		RowOfShipmentTable = "RowOfShipmentTable";
		TableShipmentRow = "TableShipmentRow";
	EndIf;
		
	ReportTable.StartRowGroup();
	
	AreaName = HeaderOfShipmentTable;
	Area = Template.GetArea(AreaName);
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceShipment;
	ReportTable.Put(Area);
	
	AreaName = RowOfShipmentTable;
	Area = Template.GetArea(AreaName);
	NameOfCommandLine = TableShipmentRow;
	RowArea = Area.Areas[NameOfCommandLine]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In GoodsInStock_.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
					RowGoods.Products,
					RowGoods.Characteristic,
					,
					RowGoods.Series);
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure DisplayTableOfTransferOfOwnership(ReportTable, Template, ProductsByDocument, ParametersStructure)
	
	Area = Template.GetArea("TableHeading");
	
	TableHeading = NStr("vi = 'Đang chờ chuyển giao quyền sở hữu ([Count])';
						|ru = 'Ожидает перехода права собственности ([Count])';
						|en = 'Awaits transfer of title to goods ([Count])'; fa = 'Awaits transfer of title to goods ([Count])';
						|it = 'Awaits transfer of title to goods ([Count])';
						|pl = 'Awaits transfer of title to goods ([Count])';
						|tr = 'Mülkiyet hakkının devri bekleniyor ([Count])'");
	
	TemplateParameters = New Structure;
	TemplateParameters.Insert("Count", ProductsByDocument.Rows.Count());
	
	TableHeading = StringFunctionsClientServer.InsertParametersIntoString(
		TableHeading,
		TemplateParameters);
	
	TitleStructure = New Structure("Title", TableHeading);
	Area.Parameters.Fill(TitleStructure);
	
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	Area = Template.GetArea("HeaderOfPPPTable");
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceShipment;
	ReportTable.Put(Area);
	
	Area = Template.GetArea("LineOfPPPTable");
	NameOfCommandLine = "PPPTableRow";
	RowArea = Area.Areas[NameOfCommandLine]; // SpreadsheetDocumentRange
	
	EvenString = False;
	
	For Each RowGoods In ProductsByDocument.Rows Do
		
		If EvenString Then
			BackColor = StyleColors.FieldAlternativeBackColor;
		Else
			BackColor = StyleColors.FieldBackColor;
		EndIf;
		
		Area.Parameters.Fill(RowGoods);
		
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
			RowGoods.Products,
			RowGoods.Characteristic,,
			RowGoods.Series);
		
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		RowArea.BackColor = BackColor;
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure ToDisplayTableOfTransferOfOwnershipFormalized(ReportTable, Template, ProductsByDocument, ParametersStructure)
	
	Area = Template.GetArea("TableHeading");
	
	TableHeading = NStr("vi = 'Đã lập chứng từ chuyển giao quyền sở hữu ([Count])';
						|ru = 'Оформлен переход права собственности ([Count])';
						|en = 'Transfer of title to goods is registered ([Count])'; fa = 'Transfer of title to goods is registered ([Count])';
						|it = 'Transfer of title to goods is registered ([Count])';
						|pl = 'Transfer of title to goods is registered ([Count])';
						|tr = 'Mülkiyet hakkının devri oluşturuldu ([Count])'");
	
	TemplateParameters = New Structure;
	TemplateParameters.Insert("Count", ProductsByDocument.Rows.Count());
	
	TableHeading = StringFunctionsClientServer.InsertParametersIntoString(
		TableHeading,
		TemplateParameters);
	
	TitleStructure = New Structure("Title", TableHeading);
	Area.Parameters.Fill(TitleStructure);
	
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	Area = Template.GetArea("HeaderOfPPSTableIsIssued");
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceShipment;
	ReportTable.Put(Area);
	
	Area = Template.GetArea("LineOfPPSTableIsIssued");
	NameOfCommandLine = "PPSTableLineFormalized";
	RowArea = Area.Areas[NameOfCommandLine]; // SpreadsheetDocumentRange
	
	EvenString = False;
	
	For Each RowGoods In ProductsByDocument.Rows Do
		
		If EvenString Then
			BackColor = StyleColors.FieldAlternativeBackColor;
		Else
			BackColor = StyleColors.FieldBackColor;
		EndIf;
		
		Area.Parameters.Fill(RowGoods);
		
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
			RowGoods.Products,
			RowGoods.Characteristic,,
			RowGoods.Series);
		
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		RowArea.BackColor = BackColor;
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure DisplayReceiptTableForWarehouse(ReportTable, Template, GoodsInStock_, ParametersStructure)
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	If ValueIsFilled(GoodsInStock_.Warehouse) Then 
		TableHeading = NStr("vi = 'Đang tiếp nhận vào kho ""%OriginWarehouse%"" (%1%)';
							|ru = 'В процессе поступления на склад ""%OriginWarehouse%"" (%1%)';
							|en = 'Goods received / Invoicing reconciliation ""%OriginWarehouse%"" (%1%)'; fa = 'Goods received / Invoicing reconciliation ""%OriginWarehouse%"" (%1%)';
							|it = 'In fase di arrivo al magazzino ""%OriginWarehouse%"" (%1%)';
							|pl = 'W trakcie przyjęcia do magazynu ""%OriginWarehouse%"" (%1%)';
							|tr = '""%OriginWarehouse%"" ambara giriş sürecinde (%1%)'");
		TableHeading = StrReplace(TableHeading, "%OriginWarehouse%", GoodsInStock_.Warehouse);
	Else
		TableHeading = NStr("vi = 'Dịch vụ và công việc đang cần lập chứng từ (%1%)';
							|ru = 'Услуги и работы в процессе оформления (%1%)';
							|en = 'Services and labor under registration (%1%)'; fa = 'Services and labor under registration (%1%)';
							|it = 'Servizi e lavori nel processo di registrazione (%1%)';
							|pl = 'Usługi i prace w procesie tworzenia (%1%)';
							|tr = 'Hizmet ve işler kayıt sürecinde (%1%)'");
	EndIf;
	TitleStructure = New Structure("Title", 
							StrReplace(TableHeading, "%1%", GoodsInStock_.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	AreaNameTableHeader = "HeaderReceiptTable";
	AreaNameTableRow = "RowOfReceiptTable";
	NameOfTableAreaString = "ReceiptTableRow";
	
	If ParametersStructure.ThisIsOrder Or ParametersStructure.ThisIsArrivalOfGoods Then
		If GoodsInStock_.AdvancedWarehousingOnGoodsReceipt Or GoodsInStock_.SeparatePurchase Then
			AreaNameTableHeader = "HeaderReceiptTable";
			AreaNameTableRow = "RowOfReceiptTable";
			NameOfTableAreaString = "ReceiptTableRow";
		Else
			AreaNameTableHeader = "HeaderReceiptTableWithoutOrder";
			AreaNameTableRow = "TableRowReceiptWithoutOrder";
			NameOfTableAreaString = "ReceiptTableRowWithoutOrder";
		EndIf;
	ElsIf ParametersStructure.ThisIsAnInvoice Then
		AreaNameTableHeader = "HeaderReceiptTableInvoice";
		AreaNameTableRow = "RowOfReceiptInvoiceTable";
		NameOfTableAreaString = "ReceiptTableRowInvoice";
	EndIf;
	
	ReportTable.StartRowGroup();
	
	Area = Template.GetArea(AreaNameTableHeader);
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceReceipt;
	ReportTable.Put(Area);
	
	Area = Template.GetArea(AreaNameTableRow);
	RowArea = Area.Areas[NameOfTableAreaString]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In GoodsInStock_.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
					RowGoods.Products,
					RowGoods.Characteristic);
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Function DisplayCanceledShipmentTable(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableCanceledShipment") Then
		Return False;
	EndIf;
	
	CancelledGoods = ResultTables.TableCanceledShipment.Rows.Find(Document, "Document");
	If CancelledGoods = Undefined Then
		Return False;
	EndIf;
	
	Return OutputTable_Canceled(
				ReportTable, 
				Template, 
				CancelledGoods, 
				ParametersStructure, 
				ParametersStructure.ThereAreReasonsToCancelShipment,
				ParametersStructure.TextCanceledShipment);
	
EndFunction

Function DisplayCanceledReceiptTable(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableCanceledReceipt") Then
		Return False;
	EndIf;
	
	CancelledGoods = ResultTables.TableCanceledReceipt.Rows.Find(Document, "Document");
	If CancelledGoods = Undefined Then
		Return False;
	EndIf;
	
	Return OutputTable_Canceled(
				ReportTable, 
				Template, 
				CancelledGoods, 
				ParametersStructure, 
				ParametersStructure.ThereAreReasonsForCancelingAdmission,
				ParametersStructure.TextCanceledReceipt,
				False);
	
EndFunction

Function OutputTable_Canceled(ReportTable, Template, CancelledGoods, ParametersStructure, UseCancellationReasons, TableHeading, Shipment = True)
	
	ThereAreSummaryIndicators = Shipment And ParametersStructure.ThereAreSummaryShipmentIndicators
	                             Or Not Shipment And ParametersStructure.ThereAreSummaryIndicatorsOfReceipt;

	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	TitleStructure = New Structure("Title", 
							StrReplace(TableHeading, "%1%", CancelledGoods.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	If UseCancellationReasons And ThereAreSummaryIndicators Then
		AreaNameTableHeader = "TableHeaderCanceled";
		AreaNameTableRow = "TableRowCanceled";
		NameOfTableAreaString = "TableCanceledRow";
	ElsIf Not UseCancellationReasons And ThereAreSummaryIndicators Then
		AreaNameTableHeader = "TableHeaderCanceledForNoReason";
		AreaNameTableRow = "TableRowCanceledForNoReason";
		NameOfTableAreaString = "TableCancelledRowForNoReason";
	Else
		AreaNameTableHeader = "TableHeaderCanceledForNoReasonNoAmounts";
		AreaNameTableRow = "TableRowCancelledForNoReasonWithNoAmounts";
		NameOfTableAreaString = "TableCancelledRowForNoReasonNoAmounts";
	EndIf;
	
	Area = Template.GetArea(AreaNameTableHeader);
	Area.Parameters.TextProductService = ?(Shipment, ParametersStructure.TextProductServiceShipment, ParametersStructure.TextProductServiceReceipt);
	ReportTable.Put(Area);
	
	Area = Template.GetArea(AreaNameTableRow);
	RowArea = Area.Areas[NameOfTableAreaString]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In CancelledGoods.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
					RowGoods.Products,
					RowGoods.Characteristic);
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
	Return True;
	
EndFunction

Function DisplayReturnOfGoodsTable(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableReturnOfGoods") Then
		Return False;
	EndIf;
	
	ReceiptOfGoods_ = ResultTables.TableReturnOfGoods.Rows.Find(Document, "Document");
	If ReceiptOfGoods_ = Undefined Then
		Return False;
	EndIf;
	
	For Each ReturnOfGoodsByWarehouse In ReceiptOfGoods_.Rows Do
		
		DisplayReturnOfGoodsByWarehouseTable(ReportTable, Template, ReturnOfGoodsByWarehouse, ParametersStructure);
		
	EndDo;
	
	Return True;
	
EndFunction

Procedure DisplayReturnOfGoodsByWarehouseTable(ReportTable, Template, ReturnOfGoodsByWarehouse, ParametersStructure)
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	If ValueIsFilled(ReturnOfGoodsByWarehouse.Warehouse) Then 
		TableHeading = NStr("vi = 'Đang trả lại vào kho ""%OriginWarehouse%"" (%1%)';
							|ru = 'В процессе возврата на склад ""%OriginWarehouse%"" (%1%)';
							|en = 'While returning to warehouse ""%OriginWarehouse%"" (%1%)'; fa = 'While returning to warehouse ""%OriginWarehouse%"" (%1%)';
							|it = 'In fase di restituzione al magazzino ""%OriginWarehouse%"" (%1%)';
							|pl = 'W procesie zwrotu do magazynu ""%OriginWarehouse%"" (%1%)';
							|tr = '""%OriginWarehouse%"" ambara iade sürecinde (%1%)'");
		TableHeading = StrReplace(TableHeading, "%OriginWarehouse%", ReturnOfGoodsByWarehouse.Warehouse);
	EndIf;
	TitleStructure = New Structure("Title", 
							StrReplace(TableHeading, "%1%", ReturnOfGoodsByWarehouse.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	If ParametersStructure.ThisIsAnInvoice Then
		AreaNameTableHeader = "HeaderOfReturnTable";
		AreaNameTableRow = "TableRowReturn";
		NameOfTableAreaString = "TableReturnRow";
	ElsIf Not (ParametersStructure.ThisIsOrder And ReturnOfGoodsByWarehouse.AdvancedWarehousingOnGoodsReceipt) Then
		AreaNameTableHeader = "HeaderOfRefundWithoutOrderTable";
		AreaNameTableRow = "TableRowReturnWithoutOrder";
		NameOfTableAreaString = "TableReturnRowWithoutOrder";
	Else
		AreaNameTableHeader = "HeaderOfReturnTable";
		AreaNameTableRow = "TableRowReturn";
		NameOfTableAreaString = "TableReturnRow";
	EndIf;
	
	Area = Template.GetArea(AreaNameTableHeader);
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceReceipt;
	ReportTable.Put(Area);
	
	Area = Template.GetArea(AreaNameTableRow);
	RowArea = Area.Areas[NameOfTableAreaString]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In ReturnOfGoodsByWarehouse.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
					RowGoods.Products,
					RowGoods.Characteristic);
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
EndProcedure

Function DisplayReturnedItemsTable(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableOfReturnedItems") Then
		Return False;
	EndIf;
	
	ReturnedItems = ResultTables.TableOfReturnedItems.Rows.Find(Document, "Document");
	If ReturnedItems = Undefined Then
		Return False;
	EndIf;
	
	TableHeading = NStr("vi = 'Khách hàng đã trả lại hàng hóa (%1%)';
						|ru = 'Возвращено товаров клиентом (%1%)';
						|en = 'Goods returned by a customer (%1%)'; fa = 'Goods returned by a customer (%1%)';
						|it = 'Merce restituita dal cliente (%1%)';
						|pl = 'Zwrócono towarów przez klienta (%1%)';
						|tr = 'Müşteri tarafından iade edilen ürünler (%1%)'");
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	TitleStructure = New Structure("Title", 
							StrReplace(TableHeading, "%1%", ReturnedItems.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	AreaName = "TableHeaderReturned";
	Area = Template.GetArea(AreaName);
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceReceipt;
	ReportTable.Put(Area);
	
	AreaName = "TableRowReturned";
	Area = Template.GetArea(AreaName);
	NameOfCommandLine = "TableReturnedRow";
	RowArea = Area.Areas[NameOfCommandLine]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In ReturnedItems.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
					RowGoods.Products,
					RowGoods.Characteristic);
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
	Return True;
	
EndFunction

Procedure PrintLastLine(ReportTable, Template)
	
	Area = Template.GetArea("TableRowLast");
	ReportTable.Put(Area);
	
EndProcedure

Procedure OutputTableNoData(ReportTable, Template, Selection, HasData)
	
	If HasData Then
		Return
	EndIf;
	
	If Not Selection.DocumentPosted Then
		MessageText = NStr("vi = 'Chứng từ không được kết chuyển. Không có dữ liệu để điền.';
							|ru = 'Документ не проведен. Нет данных для заполнения.';
							|en = 'Document is not posted. No data for population.'; fa = 'Document is not posted. No data for population.';
							|it = 'Il documento non è registrato. Nessu dato da compilare.';
							|pl = 'Dokument niezaksięgowany. Brak danych do wypełnienia.';
							|tr = 'Belge kaydedilmedi. Doldurulacak veri yok.'");
	Else
		MessageText = NStr("vi = 'Không có dữ liệu để điền.';
							|ru = 'Нет данных для заполнения.';
							|en = 'No data for population.'; fa = 'No data for population.';
							|it = 'Nessun dato da compilare.';
							|pl = 'Brak danych do wypełnienia.';
							|tr = 'Doldurulacak veri yok.'");
	EndIf;
	
	Area = Template.GetArea("TableRowNoData");
	Area.Parameters.MessageText = MessageText;
	ReportTable.Put(Area);
	
	PrintLastLine(ReportTable, Template);
	
EndProcedure

Function DisplayTableServicesToGiverForRegistration(ReportTable, Template, Document, ResultTables, ParametersStructure)
	
	If Not ResultTables.Property("TableOfServicesToGiverForRegistration") Then
		Return False;
	EndIf;
	
	ServicesOfMaterialProviderForRegistration = ResultTables.TableOfServicesToGiverForRegistration.Rows.Find(Document, "Document");
	If ServicesOfMaterialProviderForRegistration = Undefined Then
		Return False;
	EndIf;
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	Title = NStr("vi = 'Dịch vụ dành cho người thuê gia công cần lập chứng từ (%1%)';
				|ru = 'Услуги давальцу к оформлению (%1%)';
				|en = 'Services to material provider for registration (%1%)'; fa = 'Services to material provider for registration (%1%)';
				|it = 'Servizi al cliente in registrazione (%1%)';
				|pl = 'Usługi dla właściciela surowców do utworzenia (%1%)';
				|tr = 'Tedarikçiye düzenlenecek hizmetler (%1%)'");
	TitleStructure = New Structure("Title", 
							StrReplace(Title, "%1%", ServicesOfMaterialProviderForRegistration.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	AreaName = "HeaderOfTableServicesToGiverForRegistration";
	Area = Template.GetArea(AreaName);
	ReportTable.Put(Area);
	
	AreaName = "RowOfTableServicesToGiverForRegistration";
	Area = Template.GetArea(AreaName);
	NameOfCommandLine = "TableServicesToGiverForRegistrationLine";
	RowArea = Area.Areas[NameOfCommandLine]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In ServicesOfMaterialProviderForRegistration.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		PresentationOfProductsForPrinting = ProductsClientServer.ProductPresentation(
		RowGoods.Products,
		RowGoods.Characteristic);
		Area.Parameters.OwnGoods = PresentationOfProductsForPrinting;
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
	Return True
	
EndFunction

Function DisplayProductsForProcessingTableInReportToProcessor(ReportTable, Template, Document, ResultTables, ParametersStructure)

	If Not ResultTables.Property("TableProductsForProcessingInReportToProcessor") Then
		Return False;
	EndIf;
	
	ProductsForRegistration_ = ResultTables.TableProductsForProcessingInReportToProcessor.Rows.Find(Document, "Document");
	If ProductsForRegistration_ = Undefined Then
		Return False;
	EndIf;
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	Title = NStr("vi = 'Sản phẩm và dịch vụ cần lập trong bảng kê dành cho bên nhận gia công (%1%)';
				|ru = 'Продукция и услуги к оформлению в отчете переработчику (%1%)';
				|en = 'Manufactured products and services for registration in subcontractor report (%1%)'; fa = 'Manufactured products and services for registration in subcontractor report (%1%)';
				|it = 'Produzione e servizi in formalizzazione nel report dell''elaboratore (%1%)';
				|pl = 'Produkcja i usługi do rejestracji w raporcie do przetwórcy (%1%)';
				|tr = 'Alınan fason hizmetleri bildiriminde düzenlecenek imal edilen ürünler ve hizmetler (%1%)'");
	TitleStructure = New Structure("Title", 
							StrReplace(Title, "%1%", ProductsForRegistration_.Rows.Count()));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	TemplateSuffix_ = ParametersStructure.SuffixOfTemplateForProductsTableInReportToProcessor;
	
	ReportTable.StartRowGroup();
	
	AreaName = "HeaderOfTableForProcessingInReportToProcessor" + TemplateSuffix_;
	Area = Template.GetArea(AreaName);
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceReceipt;
	ReportTable.Put(Area);
	
	AreaName = "RowInTableForProcessingInReportToProcessor" + TemplateSuffix_;
	Area = Template.GetArea(AreaName);
	
	NameOfCommandLine = "TableForProcessingInReportToProcessorLine" + TemplateSuffix_;
	RowArea = Area.Areas[NameOfCommandLine]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In ProductsForRegistration_.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		Area.Parameters.OwnGoods = ProductsClientServer.ProductPresentation(
					RowGoods.ProductsPresentation,
					RowGoods.CharacteristicPresentation,
					,
					RowGoods.SeriesPresentation);
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
	Return True;

EndFunction

Function DisplayRawMaterialsTableAtProcessor(ReportTable, Template, Document, ResultTables, ParametersStructure)

	If Not ResultTables.Property("TableRawMaterialsAtProcessor") Then
		Return False;
	EndIf;
	
	RawMaterialsFromProcessor = ResultTables.TableRawMaterialsAtProcessor.Rows.Find(Document, "Document");
	If RawMaterialsFromProcessor = Undefined Then
		Return False;
	EndIf;
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	
	Title = NStr("vi = 'Nguyên vật liệu tại nơi gia công (%1%)';
				|ru = 'Сырье и материалы у переработчика (%1%)';
				|en = 'Raw and consumable materials held by subcontractor (%1%)'; fa = 'Raw and consumable materials held by subcontractor (%1%)';
				|it = 'Materie prime e materiali presso l''elaboratore (%1%)';
				|pl = 'Surowce i materiały u przetwórcy (%1%)';
				|tr = 'Fason üreticide hammaddeler ve sarf malzemeleri (%1%)'");
	TitleStructure = New Structure;
	TitleStructure.Insert(
		"Title",
		StrReplace(Title, "%1%", RawMaterialsFromProcessor.Rows.Count()));
	
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	TemplateSuffix_ = ParametersStructure.SuffixOfTemplateTableRawMaterialsAtProcessor;
	
	ReportTable.StartRowGroup();
	
	AreaName = "HeaderOfRawMaterialsTableAtProcessor" + TemplateSuffix_;
	Area = Template.GetArea(AreaName);
	Area.Parameters.TextProductService = ParametersStructure.TextProductServiceShipment;
	ReportTable.Put(Area);
	
	AreaName = "RowOfRawMaterialsTableAtProcessor" + TemplateSuffix_;
	Area = Template.GetArea(AreaName);
	
	NameOfCommandLine = "TableRawMaterialsAtProcessorRow" + TemplateSuffix_;
	RowArea = Area.Areas[NameOfCommandLine]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowGoods In RawMaterialsFromProcessor.Rows Do
		
		Area.Parameters.Fill(RowGoods);
		Area.Parameters.OwnGoods = ProductsClientServer.ProductPresentation(
					RowGoods.ProductsPresentation,
					RowGoods.CharacteristicPresentation);
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo;
	
	ReportTable.EndRowGroup();
	
	Return True;

EndFunction

#EndRegion

#Region MutualSettlementsStatus

Function QueryTextTTCalculationObjects_(TableName, ParametersStructure)
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTTCalculationObjects_") Then
		
		Return StructureOfAdditionalRequests.QueryTextTTCalculationObjects_;
	EndIf;
	
	QueryText = "
	|SELECT
	|	Documents.DocumentRef AS Document,
	|	
	|	CASE
	|		WHEN Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|			THEN Documents.DocumentRef.Contract
	|		WHEN (Documents.DocumentType = TYPE(Document.CustomerInvoice)
	|			OR Documents.DocumentType = TYPE(Document.CustomerInvoiceServices))
	|			AND (Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|				OR Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
	|			THEN Documents.DocumentRef
	|		WHEN (Documents.DocumentType = TYPE(Document.SalesOrder) 
	|			OR Documents.DocumentType = TYPE(Document.RequestForReturnOfGoodsFromCustomer))
	|			AND (Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
	|				OR Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
	|			THEN Documents.DocumentRef
	|		WHEN (Documents.DocumentType = TYPE(Document.SalesOrder) 
	|			OR Documents.DocumentType = TYPE(Document.RequestForReturnOfGoodsFromCustomer))
	|			AND Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
	|			THEN Documents.DocumentRef.Contract
	|		WHEN Documents.DocumentType = TYPE(Document.PurchaseOrder) 
	|			AND Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
	|				OR Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			THEN Documents.DocumentRef
	|		WHEN Documents.DocumentType = TYPE(Document.PurchaseOrder)
	|			AND Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
	|			THEN Documents.DocumentRef.Contract
	|		WHEN Documents.DocumentType = TYPE(Document.VendorInvoice)
	|			AND (Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|			OR Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
	|			THEN Documents.DocumentRef
	|		WHEN Documents.DocumentType = TYPE(Document.ReportToMaterialProvider2_5)
	|			AND Documents.DocumentRef.ARAPObjectSettings IN (
	|											VALUE(Enum.ARAPObjectSettings.ByARAPDocuments),
	|											VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
	|			THEN Documents.DocumentRef
	|		WHEN Documents.DocumentType = TYPE(Document.MaterialProviderOrder2_5)
	|			AND Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			THEN Documents.DocumentRef
	|		WHEN Documents.DocumentType = TYPE(Document.SubcontractorReport2_5)
	|			AND Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|			THEN Documents.DocumentRef
	|		WHEN Documents.DocumentType = TYPE(Document.SubcontractOrder2_5)
	|			AND Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|			THEN Documents.DocumentRef
	|	END AS ARAPObject,
	|	CASE
	|		WHEN Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|			AND Documents.DocumentType <> TYPE(Document.ContractSchedule)
	|			THEN FALSE
	|		WHEN Documents.DocumentType = TYPE(Document.ContractSchedule)
	|		THEN TRUE
	|		WHEN (Documents.DocumentType = TYPE(Document.CustomerInvoice)
	|			OR Documents.DocumentType = TYPE(Document.CustomerInvoiceServices))
	|			AND (Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|				OR Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|				OR Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
	|		THEN TRUE
	|		WHEN Documents.DocumentType = TYPE(Document.VendorInvoice)
	|			AND (Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)
	|				OR Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|				OR Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
	|		THEN TRUE
	|		WHEN (Documents.DocumentType = TYPE(Document.SalesOrder)
	|			OR Documents.DocumentType = TYPE(Document.RequestForReturnOfGoodsFromCustomer))
	|			AND (Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
	|				OR Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
	|		THEN TRUE
	|		WHEN Documents.DocumentType = TYPE(Document.PurchaseOrder) 
	|			AND (Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
	|				OR Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
	|		THEN TRUE
	|		WHEN Documents.DocumentType = TYPE(Document.ReportToMaterialProvider2_5)
	|			AND Documents.DocumentRef.ARAPObjectSettings IN (
	|											VALUE(Enum.ARAPObjectSettings.ByARAPDocuments),
	|											VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
	|				THEN TRUE
	|		WHEN Documents.DocumentType = TYPE(Document.MaterialProviderOrder2_5)
	|			AND Documents.DocumentRef.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
	|				THEN TRUE
	|		ELSE FALSE
	|	END AS ScheduleIsRequired, 
	|	Documents.DocumentRef.ARAPObjectSettings AS ARAPObjectSettings
	|FROM
	|	TTDocuments AS Documents
	|";
	
	If TableName = "Document.CustomerInvoice" Then
		QueryText = QueryText + "
			|UNION ALL
			|
			|SELECT
			|	TTDocuments.DocumentRef,
			|	Document.Ref,
			|	TRUE,
			|	Document.ARAPObjectSettings
			|FROM
			|	Document.CustomerInvoice AS Document
			|	INNER JOIN TTDocuments AS TTDocuments
			|		ON Document.Ref = TTDocuments.DocumentRef
			|WHERE
			|	(Document.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
			|		OR Document.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
			|	AND NOT Document.OrderSales
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	TTDocuments.DocumentRef,
			|	Document.SalesOrder,
			|	TRUE,
			|	Document.Ref.ARAPObjectSettings
			|FROM
			|	Document.CustomerInvoice.Goods AS Document
			|	INNER JOIN TTDocuments AS TTDocuments
			|		ON Document.Ref = TTDocuments.DocumentRef
			|WHERE
			|	(Document.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
			|		OR Document.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
			|	AND Document.Ref.OrderSales
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	TTDocuments.DocumentRef,
			|	Document.Ref.Contract,
			|	FALSE,
			|	Document.Ref.ARAPObjectSettings
			|FROM
			|	Document.CustomerInvoice.Goods AS Document
			|	INNER JOIN TTDocuments AS TTDocuments
			|		ON Document.Ref = TTDocuments.DocumentRef
			|WHERE
			|	Document.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|	AND NOT Document.Ref.OrderSales
			|";
	EndIf;
	
	If TableName = "Document.VendorInvoice" Then
		QueryText = QueryText + "
			|UNION ALL
			|
			|SELECT
			|	TTDocuments.DocumentRef,
			|	Document.Ref,
			|	TRUE,
			|	Document.ARAPObjectSettings
			|FROM
			|	Document.VendorInvoice AS Document
			|	INNER JOIN TTDocuments AS TTDocuments
			|		ON Document.Ref = TTDocuments.DocumentRef
			|WHERE
			|	(Document.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
			|		OR Document.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
			|	AND NOT Document.ReceiptUnderOrders
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	TTDocuments.DocumentRef,
			|	Document.PurchaseOrder,
			|	TRUE,
			|	Document.Ref.ARAPObjectSettings
			|FROM
			|	Document.VendorInvoice.Goods AS Document
			|	INNER JOIN TTDocuments AS TTDocuments
			|		ON Document.Ref = TTDocuments.DocumentRef
			|WHERE
			|	(Document.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
			|		OR Document.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
			|	AND Document.Ref.ReceiptUnderOrders
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	TTDocuments.DocumentRef,
			|	Document.Ref.Contract,
			|	FALSE,
			|	Document.Ref.ARAPObjectSettings
			|FROM
			|	Document.VendorInvoice.Goods AS Document
			|	INNER JOIN TTDocuments AS TTDocuments
			|		ON Document.Ref = TTDocuments.DocumentRef
			|WHERE
			|	Document.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|	AND NOT Document.Ref.ReceiptUnderOrders
			|";
	EndIf;
	
	If TableName = "Document.CustomerInvoiceServices" Then
		QueryText = QueryText + "
			|UNION ALL
			|
			|SELECT
			|	TTDocuments.DocumentRef,
			|	Document.Ref,
			|	TRUE,
			|	Document.ARAPObjectSettings
			|FROM
			|	Document.CustomerInvoiceServices AS Document
			|	INNER JOIN TTDocuments AS TTDocuments
			|		ON Document.Ref = TTDocuments.DocumentRef
			|WHERE
			|	(Document.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
			|		OR Document.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
			|	AND NOT Document.InvoiceByOrders
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	TTDocuments.DocumentRef,
			|	Document.SalesOrder,
			|	TRUE,
			|	Document.Ref.ARAPObjectSettings
			|FROM
			|	Document.CustomerInvoiceServices.Services AS Document
			|	INNER JOIN TTDocuments AS TTDocuments
			|		ON Document.Ref = TTDocuments.DocumentRef
			|WHERE
			|	(Document.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
			|		OR Document.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
			|	AND Document.Ref.InvoiceByOrders
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	TTDocuments.DocumentRef,
			|	Document.Ref.Contract,
			|	FALSE,
			|	Document.Ref.ARAPObjectSettings
			|FROM
			|	Document.CustomerInvoiceServices.Services AS Document
			|	INNER JOIN TTDocuments AS TTDocuments
			|		ON Document.Ref = TTDocuments.DocumentRef
			|WHERE
			|	Document.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
			|		AND NOT Document.Ref.InvoiceByOrders 
			|";
	EndIf;
	
	
	If TableName = "Document.ReportToMaterialProvider2_5" Then
		QueryText = QueryText + "
			|UNION ALL
			|
			|SELECT DISTINCT
			|	TTDocuments.DocumentRef,
			|	ReportsToGiver.MaterialProviderOrder,
			|	TRUE,
			|	ReportsToGiver.Ref.ARAPObjectSettings
			|FROM
			|	Document.ReportToMaterialProvider2_5.ManufacturedProduct AS ReportsToGiver
			|		INNER JOIN TTDocuments AS TTDocuments
			|		ON ReportsToGiver.Ref = TTDocuments.DocumentRef
			|WHERE
			|	ReportsToGiver.Ref.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
			|";
	EndIf;

	TextOfRequestForCalculationObjects = "
	|	SELECT DISTINCT ALLOWED
	|	Document AS Document,
	|	ARAPObject AS CalculationObjectObject,
	|	CatalogData.Ref AS ARAPObject,
	|	CatalogData.ARAPCurrency AS Currency,
	|	ScheduleIsRequired AS ScheduleIsRequired,
	|	ARAPObjectSettings AS ARAPObjectSettings
	|INTO ARAPObjects
	|	FROM
	|	&QueryTable AS ARAPObjectTable
	|	INNER JOIN Catalog.ARAPObjects AS CatalogData
	|		ON ARAPObjectTable.ARAPObject = CatalogData.Object
	|INDEX BY
	|	ARAPObject
	|;";
	
	TextOfRequestForCalculationObjects = StrReplace(TextOfRequestForCalculationObjects, "&QueryTable", "("+ QueryText +")");
	
	Return TextOfRequestForCalculationObjects;
	
EndFunction

#Region TypesOfSettlementRecordsAreFilledIn

Function QueryTextTTCommunicationOrdersINVOICES(TheseAreSettlementsWithCustomers)
	
	QueryText = "
		|SELECT
		|	ARAPObjects.Document AS Document,
		|	ARAPObjects.ARAPObject AS SourceObjectOfCalculations_,
		|	ARAPObjects.CalculationObjectObject AS OriginalARAPObjectIsObject,
		|	ARAPObjectsInvoices.Ref AS ARAPObject,
		|	ARAPObjects.Currency AS Currency,
		|	ARAPObjects.ARAPObjectSettings AS ARAPObjectSettings,
		|	ARAPObjects.ARAPObject AS ARAPObjectOrder,
		|	SUM(CAST(CASE
		|				WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|					THEN CASE
		|							WHEN ARAPObjectsInvoices.AmountARAP = 0
		|								THEN CASE
		|										WHEN ARAPObjectsInvoices.Sum = 0
		|											THEN 0
		|										ELSE CustomersARAPAccounting.ToShip / ARAPObjectsInvoices.Sum
		|									END
		|							ELSE CustomersARAPAccounting.ToShip / ARAPObjectsInvoices.AmountARAP
		|						END
		|				ELSE 0
		|			END AS NUMBER(20, 10))) AS OrderShare
		|INTO TTCommunicationOfOrdersInvoicesSettlementsWithCustomers
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
		|		INNER JOIN ARAPObjects AS ARAPObjects
		|		ON CustomersARAPAccounting.ARAPObject = ARAPObjects.ARAPObject
		|			AND (CustomersARAPAccounting.Active)
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjectsInvoices
		|		ON CustomersARAPAccounting.Recorder = ARAPObjectsInvoices.Object
		|			AND (NOT ARAPObjectsInvoices.DeletionMark)
		|			AND ARAPObjectsInvoices.Ref <> CustomersARAPAccounting.ARAPObject
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjectsOfOrders
		|		ON ARAPObjects.ARAPObject = ARAPObjectsOfOrders.Ref
		|
		|GROUP BY
		|	ARAPObjects.Document,
		|	ARAPObjects.ARAPObject,
		|	ARAPObjects.CalculationObjectObject,
		|	ARAPObjectsInvoices.Ref,
		|	ARAPObjects.Currency,
		|	ARAPObjects.ARAPObjectSettings
		|
		|HAVING
		|	SUM(CAST(CASE
		|				WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|					THEN CASE
		|							WHEN ARAPObjectsInvoices.AmountARAP = 0
		|								THEN CASE
		|										WHEN ARAPObjectsInvoices.Sum = 0
		|											THEN 0
		|										ELSE CustomersARAPAccounting.ToShip / ARAPObjectsInvoices.Sum
		|									END
		|							ELSE CustomersARAPAccounting.ToShip / ARAPObjectsInvoices.AmountARAP
		|						END
		|				ELSE 0
		|			END AS NUMBER(20, 10))) <> 0
		|
		|UNION ALL
		|
		|SELECT
		|	ARAPObjects.Document AS Document,
		|	ARAPObjects.ARAPObject AS SourceObjectOfCalculations_,
		|	ARAPObjects.CalculationObjectObject AS OriginalARAPObjectIsObject,
		|	ARAPObjects.ARAPObject AS ARAPObject,
		|	ARAPObjects.Currency AS Currency,
		|	ARAPObjects.ARAPObjectSettings AS ARAPObjectSettings,
		|	ARAPObjects.ARAPObject AS ARAPObjectOrder,
		|	1 AS OrderShare
		|FROM
		|	ARAPObjects AS ARAPObjects
		|";
	
	If Not TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText, "CustomersARAPAccounting", "VendorsARAPAccounting");
		QueryText = StrReplace(QueryText, "ToShip", "ToReceive");
		QueryText = StrReplace(QueryText, "Receipt", "Expense");
	EndIf;
	
	Return QueryText
	
EndFunction

Function QueryTextForPaymentsByDueDate(TheseAreSettlementsWithCustomers)
	
	QueryText = " 
	|SELECT
	|	ARAPObjects.Document                     AS Document,
	|	ARAPObjects.SourceObjectOfCalculations_       AS ARAPObject,
	|	ARAPObjects.OriginalARAPObjectIsObject AS CalculationObjectObject,
	|	CalculationsByTerms.DocumentRecorder          AS DocumentRecorder,
	|	ARAPObjects.ARAPObjectSettings              AS ARAPObjectSettings,
	|	CalculationsByTerms.Currency                       AS Currency,
	|	SUM(CASE
	|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.PaymentPrepaymentIncrease)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentIncrease)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfInvoicePrepaymentIncrease)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentIncrease)
	|				THEN CalculationsByTerms.Prepayment
	|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.RefundDecreasesPrepayment)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentDecrease)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentDecrease)
	|				THEN - Prepayment
	|			ELSE 0
	|		END * ARAPObjects.OrderShare)     AS SumReal,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, DAY) AS DateFact,
	|	SUM(CASE
	|		WHEN ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.Invoice)
	|			AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease) 
	|			THEN CalculationsByTerms.Debt
	|		ELSE 0
	|	END)                                      AS ApplyingPrepayment,
	|	SUM(CASE
	|			WHEN ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.Invoice)
	|				AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease) 
	|				THEN CalculationsByTerms.Debt
	|			ELSE 0
	|	END * ARAPObjects.OrderShare) AS ScheduleAdjustment
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|		INNER JOIN TTCommunicationOfOrdersInvoicesSettlementsWithCustomers AS ARAPObjects
	|		ON ARAPObjects.ARAPObject = CalculationsByTerms.ARAPObject
	|WHERE
	|	CalculationsByTerms.ARAPObject IN
	|			(SELECT
	|				T.ARAPObject
	|			FROM
	|				TTCommunicationOfOrdersInvoicesSettlementsWithCustomers AS T)
	|
	|GROUP BY
	|	CalculationsByTerms.DocumentRecorder,
	|	CalculationsByTerms.Currency,
	|	ARAPObjects.Document,
	|	ARAPObjects.SourceObjectOfCalculations_,
	|	ARAPObjects.OriginalARAPObjectIsObject,
	|	ARAPObjects.ARAPObjectSettings,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, DAY)
	|
	|HAVING
	|	SUM(CASE
	|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.PaymentPrepaymentIncrease)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentIncrease)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfInvoicePrepaymentIncrease)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentIncrease)
	|				THEN CalculationsByTerms.Prepayment
	|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.RefundDecreasesPrepayment)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentDecrease)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentDecrease)
	|				THEN - Prepayment
	|			ELSE 0
	|		END * ARAPObjects.OrderShare) <> 0
	|	OR SUM(CASE
	|		WHEN ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.Invoice)
	|			AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease) 
	|			THEN CalculationsByTerms.Debt
	|		ELSE 0
	|	END) <> 0
	|	OR SUM(CASE
	|			WHEN ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.Invoice)
	|				AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease) 
	|				THEN CalculationsByTerms.Debt
	|			ELSE 0
	|	END * ARAPObjects.OrderShare) <> 0
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText, "CustomersARAPAccounting", "VendorsARAPAccounting");
	EndIf;
	
	Return QueryText
	
EndFunction

Function QueryTextForPaymentsAccordingToPlan(TheseAreSettlementsWithCustomers)
	
	QueryText = " 
	|SELECT
	|	ARAPObjects.Document AS Document,
	|	ARAPObjects.ARAPObjectSettings AS ARAPObjectSettings,
	|	CASE 
	|		WHEN VALUETYPE(PaymentPlan_.DocumentRecorder) IN (&TypesOfPaymentDocuments)
	|			THEN PaymentPlan_.DocumentRecorder
	|		ELSE PaymentPlan_.DocumentPayments
	|	END AS DocumentRecorder,
	|	PaymentPlan_.ARAPObject AS ARAPObject,
	|	PaymentPlan_.Currency AS Currency,
	|	SUM(CASE
	|			WHEN PaymentPlan_.UnallocatedAdvancePayment
	|					AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND NOT VALUETYPE(PaymentPlan_.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					AND PaymentPlan_.AmountDue > 0
	|				THEN PaymentPlan_.AmountDue
	|			WHEN PaymentPlan_.UnallocatedAdvancePayment
	|					AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND VALUETYPE(PaymentPlan_.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					AND PaymentPlan_.AmountDue < 0
	|				THEN PaymentPlan_.AmountDue
	|			ELSE 0
	|		END) AS SumReal,
	|	SUM(CASE
	|			WHEN PaymentPlan_.UnallocatedAdvancePayment
	|				AND NOT VALUETYPE(PaymentPlan_.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|				AND NOT VALUETYPE(PaymentPlan_.DocumentRecorder) IN (&TypesOfPaymentDocuments)
	|				AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND PaymentPlan_.AmountDue < 0
	|			THEN -PaymentPlan_.AmountDue
	|		ELSE 0
	|	END) AS ApplyingPrepayment,
	|	SUM(CASE
	|			WHEN PaymentPlan_.UnallocatedAdvancePayment
	|					AND NOT VALUETYPE(PaymentPlan_.DocumentRecorder) IN (&TypesOfPaymentDocuments)
	|					AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND PaymentPlan_.AmountDue < 0
	|				THEN -PaymentPlan_.AmountDue
	|			ELSE 0
	|	END) AS ScheduleAdjustment
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS PaymentPlan_
	|		INNER JOIN TTCommunicationOfOrdersInvoicesSettlementsWithCustomers AS ARAPObjects
	|		ON ARAPObjects.ARAPObject = PaymentPlan_.ARAPObject
	|WHERE
	|	PaymentPlan_.ARAPObject IN
	|			(SELECT
	|				T.ARAPObject
	|			FROM
	|				TTCommunicationOfOrdersInvoicesSettlementsWithCustomers AS T)
	|
	|GROUP BY
	|	ARAPObjects.Document,
	|	ARAPObjects.ARAPObjectSettings,
	|	PaymentPlan_.ARAPObject,
	|	PaymentPlan_.Currency,
	|	CASE 
	|		WHEN VALUETYPE(PaymentPlan_.DocumentRecorder) IN (&TypesOfPaymentDocuments)
	|			THEN PaymentPlan_.DocumentRecorder
	|		ELSE PaymentPlan_.DocumentPayments
	|	END
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText, "CustomersARAPAccounting", "VendorsARAPAccounting");
	EndIf;
	
	Return QueryText
	
EndFunction

Function QueryTextByPayments(TheseAreSettlementsWithCustomers)
	
	QueryText = " 
	|SELECT
	|	CalculationData.Document                    AS Document,
	|	MAX(CalculationData.ARAPObject)    AS ARAPObject,
	|	CalculationData.CalculationObjectObject        AS CalculationObjectObject,
	|	CalculationData.DocumentRecorder         AS DocumentRecorder,
	|	CalculationData.ARAPObjectSettings             AS ARAPObjectSettings,
	|	CalculationData.Currency                      AS Currency,
	|	CalculationData.ShipmentPaymentOption       AS ShipmentPaymentOption,
	|	CalculationData.DatePlan                    AS DatePlan,
	|	
	|	SUM(CalculationData.SumPlan)            AS SumPlan,
	|	SUM(CalculationData.ScheduleAdjustment) AS ScheduleAdjustment,
	|	
	|	CalculationData.DateFact                    AS DateFact,
	|	MAX(CalculationData.Period)            AS Period,
	|	SUM(CalculationData.SumReal)            AS SumReal,
	|	
	|	SUM(0)                                   AS Balance,
	|	SUM(0)                                   AS BalanceIsOverdue,
	|	SUM(0)                                   AS DaysOverdue_3,
	|	
	|	FALSE                                       AS ScheduleIsRequired
	|FROM (
	|	// Payment plan
	|	SELECT
	|		ARAPObjects.Document         AS Document,
	|		ARAPObjects.ARAPObject   AS ARAPObject,
	|		ARAPObjects.CalculationObjectObject AS CalculationObjectObject,
	|		PaymentPlan_.DocumentRecorder    AS DocumentRecorder,
	|		ARAPObjects.ARAPObjectSettings  AS ARAPObjectSettings,
	|		ARAPObjects.Currency           AS Currency,
	|		PaymentPlan_.PaymentOption          AS ShipmentPaymentOption,
	|		PaymentPlan_.PlannedRepaymentDate AS DatePlan,
	|		CASE
	|			WHEN PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND PaymentPlan_.AmountDue > 0
	|				THEN PaymentPlan_.AmountDue
	|			// Write-Off Of Shipped Goods
	|			WHEN PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND PaymentPlan_.AmountDue < 0
	|				THEN PaymentPlan_.AmountDue
	|			ELSE 0
	|		END                            AS SumPlan,
	|		CASE
	|			// Shipment
	|			WHEN NOT PaymentPlan_.UnallocatedAdvancePayment
	|					AND NOT VALUETYPE(PaymentPlan_.DocumentRecorder) IN (&TypesOfPaymentDocuments)
	|					AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -PaymentPlan_.AmountDue
	|			// Offsetting the advance
	|			WHEN PaymentPlan_.UnallocatedAdvancePayment
	|					AND NOT VALUETYPE(PaymentPlan_.DocumentRecorder) IN (&TypesOfPaymentDocuments)
	|					AND VALUETYPE(PaymentPlan_.DocumentRecorder) <> TYPE(Document.ReversingEntry)
	|					AND VALUETYPE(PaymentPlan_.DocumentRecorder) <> TYPE(Document.ARAPAdjustment)
	|					AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND PaymentPlan_.AmountDue < 0
	|				THEN -PaymentPlan_.AmountDue
	|			ELSE 0
	|		END                            AS ScheduleAdjustment,
	|		CASE
	|			// Prepayment_
	|			WHEN PaymentPlan_.UnallocatedAdvancePayment
	|					AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND NOT VALUETYPE(PaymentPlan_.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					AND PaymentPlan_.AmountDue > 0
	|				THEN BEGINOFPERIOD(PaymentPlan_.Period, DAY)
	|			// Return or storno of the advance
	|			WHEN PaymentPlan_.UnallocatedAdvancePayment
	|					AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND (VALUETYPE(PaymentPlan_.DocumentRecorder) IN (&TypesOfPaymentDocuments)
	|						OR VALUETYPE(PaymentPlan_.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|						OR VALUETYPE(PaymentPlan_.DocumentRecorder) = TYPE(Document.ARAPAdjustment))
	|					AND PaymentPlan_.AmountDue < 0
	|				THEN BEGINOFPERIOD(PaymentPlan_.Period, DAY)
	|			ELSE DATETIME(1, 1, 1)
	|		END                            AS DateFact,
	|		BEGINOFPERIOD(PaymentPlan_.Period, DAY) AS Period,
	|		CASE
	|			// Prepayment_
	|			WHEN PaymentPlan_.UnallocatedAdvancePayment
	|					AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND NOT VALUETYPE(PaymentPlan_.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					AND PaymentPlan_.AmountDue > 0
	|				THEN PaymentPlan_.AmountDue
	|			// Return or storno of the advance
	|			WHEN PaymentPlan_.UnallocatedAdvancePayment
	|					AND PaymentPlan_.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND (VALUETYPE(PaymentPlan_.DocumentRecorder) IN (&TypesOfPaymentDocuments)
	|						OR VALUETYPE(PaymentPlan_.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|						OR VALUETYPE(PaymentPlan_.DocumentRecorder) = TYPE(Document.ARAPAdjustment))
	|					AND PaymentPlan_.AmountDue < 0
	|				THEN PaymentPlan_.AmountDue
	|			ELSE 0
	|		END                            AS SumReal
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS PaymentPlan_
	|			INNER JOIN ARAPObjects AS ARAPObjects
	|			ON PaymentPlan_.ARAPObject = ARAPObjects.ARAPObject
	|
	|	UNION ALL
	|
	|	// Actual shipments and post-payments
	|	SELECT
	|		ARAPObjects.Document                                           AS Document,
	|		ARAPObjects.SourceObjectOfCalculations_                             AS ARAPObject,
	|		ARAPObjects.OriginalARAPObjectIsObject                       AS CalculationObjectObject,
	|		CalculationsByTerms.DocumentRecorder                                AS DocumentRecorder,
	|		ARAPObjects.ARAPObjectSettings                                    AS ARAPObjectSettings,
	|		ARAPObjects.Currency                                             AS Currency,
	|		VALUE(Enum.CustomerPaymentControlOptions.EmptyRef) AS ShipmentPaymentOption,
	|		CalculationsByTerms.PlannedRepaymentDate                             AS DatePlan,
	|		0                                                                  AS SumPlan,
	|		// We take into account the new shipment arrears
	|		CASE
	|			// We do not consider debt recovery in case of storno payments to be an adjustment
	|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtDebtIncrease)
	|				AND CalculationsByTerms.BusinessOperation IN (VALUE(Enum.BusinessTransactions.RestoreDebtPrepaymentUponARAPAccountingStorno),
	|															VALUE(Enum.BusinessTransactions.DebtOffsetUponARAPAccountingStorno),
	|															VALUE(Enum.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno))
	|				THEN 0
	|			WHEN CalculationsByTerms.SettlementRecordType IN (VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtIncrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfInvoiceDebtIncrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtDebtIncrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.RefundIncreasesDebt))
	|				THEN CalculationsByTerms.Debt
	|			// The credited advances reduce the adjustment, since they are already taken into account in the planned payments
	|			WHEN ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType <> VALUE(Enum.ARAPObjectTypes.Invoice)
	|				AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease) 
	|				THEN -CalculationsByTerms.Debt
	|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtDebtDecrease)
	|				AND VALUETYPE(CalculationsByTerms.DocumentRecorder) = TYPE(Document.ARAPAccountingScheduleAdjustment)
	|				THEN -CalculationsByTerms.Debt
	|			ELSE 0
	|		END * ARAPObjects.OrderShare                                 AS ScheduleAdjustment,
	|		// We take payments only for part of the debt, since the advance is taken into account in the payment plan
	|		CASE 
	|			WHEN CASE
	|					WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.PaymentDebtDecrease)
	|							OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsDebtDecrease)
	|							OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.InvoiceAdjustmentDebtDecrease)
	|							OR ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|								AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease)
	|						THEN CalculationsByTerms.Debt
	|					WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.RefundIncreasesDebt)
	|							OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsDebtIncrease)
	|						THEN -CalculationsByTerms.Debt
	|					WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtDebtIncrease)
	|						AND CalculationsByTerms.BusinessOperation IN (VALUE(Enum.BusinessTransactions.RestoreDebtPrepaymentUponARAPAccountingStorno),
	|															VALUE(Enum.BusinessTransactions.DebtOffsetUponARAPAccountingStorno),
	|															VALUE(Enum.BusinessTransactions.PrepaymentOffsetUponARAPAccountingStorno))
	|						THEN -CalculationsByTerms.Debt
	|					ELSE 0
	|				END * ARAPObjects.OrderShare <> 0
	|				THEN BEGINOFPERIOD(CalculationsByTerms.Period, DAY)
	|			ELSE DATETIME(1, 1, 1)
	|		END                                                              AS DateFact,
	|		BEGINOFPERIOD(CalculationsByTerms.Period, DAY)                        AS Period,
	|		CASE
	|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.PaymentDebtDecrease)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsDebtDecrease)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.InvoiceAdjustmentDebtDecrease)
	|					OR ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|						AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease)
	|				THEN CalculationsByTerms.Debt
	|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.RefundIncreasesDebt)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsDebtIncrease)
	|				THEN -CalculationsByTerms.Debt
	|			// Storno of the credited payment
	|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtDebtIncrease)
	|				AND CalculationsByTerms.BusinessOperation = VALUE(Enum.BusinessTransactions.RestoreDebtPrepaymentUponARAPAccountingStorno)
	|				THEN -CalculationsByTerms.Debt
	|			ELSE 0
	|		END * ARAPObjects.OrderShare                                 AS SumReal
	|	FROM
	|		TTCommunicationOfOrdersInvoicesSettlementsWithCustomers AS ARAPObjects
	|			INNER JOIN AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|			ON ARAPObjects.ARAPObject = CalculationsByTerms.ARAPObject
	|	) AS CalculationData
	|	
	|GROUP BY
	|	CalculationData.Document,
	|	CalculationData.CalculationObjectObject,
	|	CalculationData.DocumentRecorder,
	|	CalculationData.ARAPObjectSettings,
	|	CalculationData.Currency,
	|	CalculationData.ShipmentPaymentOption,
	|	CalculationData.DatePlan,
	|	CalculationData.DateFact
	|
	|HAVING
	|	(SUM(CalculationData.SumPlan) <> 0
	|		OR SUM(CalculationData.ScheduleAdjustment) <> 0
	|		OR SUM(CalculationData.SumReal) <> 0)
	|
	|ORDER BY
	|	DatePlan,
	|	ShipmentPaymentOption,
	|	DateFact
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText, "CustomersARAPAccounting", "VendorsARAPAccounting");
	EndIf;
	
	Return QueryText
	
EndFunction

Function QueryTextForShipmentsByTime(TheseAreSettlementsWithCustomers)
	
	QueryText = " 
	|SELECT
	|	ARAPObjects.Document                     AS Document,
	|	ARAPObjects.SourceObjectOfCalculations_       AS ARAPObject,
	|	ARAPObjects.OriginalARAPObjectIsObject AS CalculationObjectObject,
	|	CalculationsByTerms.DocumentRecorder          AS DocumentRecorder,
	|	ARAPObjects.ARAPObjectSettings              AS ARAPObjectSettings,
	|	CalculationsByTerms.Currency                       AS Currency,
	|	SUM(CASE
	|			WHEN CalculationsByTerms.SettlementRecordType IN (VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtIncrease), VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfInvoiceDebtIncrease))
	|				THEN CalculationsByTerms.Debt
	|			ELSE 0
	|		END * ARAPObjects.OrderShare)               AS SumReal,
	|	SUM(CASE
	|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease) 
	|				THEN -CalculationsByTerms.Debt
	|			ELSE 0
	|	END) AS ApplyingPrepayment,
	|	SUM(CASE
	|			WHEN CalculationsByTerms.SettlementRecordType IN (
	|				VALUE(Enum.TypesOfSettlementRecords.PaymentPrepaymentIncrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentIncrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentIncrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfInvoicePrepaymentIncrease))
	|				THEN CalculationsByTerms.Prepayment
	|			ELSE 0
	|	END) AS ScheduleAdjustment,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, DAY) AS DateFact,
	|	4                                                     AS ShipmentPaymentOption
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|		INNER JOIN TTCommunicationOfOrdersInvoicesSettlementsWithCustomers AS ARAPObjects
	|		ON ARAPObjects.ARAPObject = CalculationsByTerms.ARAPObject
	|WHERE
	|	CalculationsByTerms.ARAPObject IN
	|			(SELECT
	|				T.ARAPObject
	|			FROM
	|				TTCommunicationOfOrdersInvoicesSettlementsWithCustomers AS T)
	|
	|GROUP BY
	|	ARAPObjects.Document,
	|	ARAPObjects.SourceObjectOfCalculations_,
	|	ARAPObjects.OriginalARAPObjectIsObject ,
	|	ARAPObjects.ARAPObjectSettings,
	|	CalculationsByTerms.DocumentRecorder,
	|	CalculationsByTerms.Currency,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, DAY)
	|
	|HAVING
	|	SUM(CASE
	|			WHEN CalculationsByTerms.SettlementRecordType IN (VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtIncrease), VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfInvoiceDebtIncrease))
	|				THEN CalculationsByTerms.Debt
	|			ELSE 0
	|		END * ARAPObjects.OrderShare) <> 0
	|	OR SUM(CASE
	|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease) 
	|				THEN -CalculationsByTerms.Debt
	|			ELSE 0
	|	END) <> 0
	|	OR SUM(CASE
	|			WHEN CalculationsByTerms.SettlementRecordType IN (
	|				VALUE(Enum.TypesOfSettlementRecords.PaymentPrepaymentIncrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentIncrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentIncrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfInvoicePrepaymentIncrease))
	|				THEN CalculationsByTerms.Prepayment
	|			ELSE 0
	|	END) <> 0
	|
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText, "CustomersARAPAccounting", "VendorsARAPAccounting");
	EndIf;
	
	Return QueryText
	
EndFunction

Function QueryTextForShipmentsAccordingToPlan(TheseAreSettlementsWithCustomers)
	
	QueryText = " 
	|SELECT
	|	ARAPObjects.Document AS Document,
	|	ARAPObjects.ARAPObjectSettings AS ARAPObjectSettings,
	|	ShipmentPlan.DocumentRecorder AS DocumentRecorder,
	|	ShipmentPlan.ARAPObject AS ARAPObject,
	|	ShipmentPlan.Currency AS Currency,
	|	SUM(CASE
	|			WHEN NOT ShipmentPlan.UnallocatedAdvancePayment
	|					AND ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND NOT VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					AND ShipmentPlan.Sum > 0
	|				THEN ShipmentPlan.Sum
	|			WHEN NOT ShipmentPlan.UnallocatedAdvancePayment
	|					AND ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					AND ShipmentPlan.Sum < 0
	|				THEN ShipmentPlan.Sum
	|			ELSE 0
	|		END) AS SumReal, 
	|	SUM(CASE
	|			WHEN ShipmentPlan.UnallocatedAdvancePayment
	|					AND ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND NOT VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					AND ShipmentPlan.Sum < 0
	|				THEN ShipmentPlan.Sum
	|			ELSE 0
	|	END) AS ApplyingPrepayment,
	|	SUM(CASE
	|			WHEN ShipmentPlan.UnallocatedAdvancePayment
	|				AND ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND NOT VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|				AND ShipmentPlan.Sum > 0 
	|				THEN ShipmentPlan.Sum
	|			ELSE 0
	|	END) AS ScheduleAdjustment,
	|	BEGINOFPERIOD(ShipmentPlan.Period, DAY) AS DateFact
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingPlannedShipments AS ShipmentPlan
	|		INNER JOIN TTCommunicationOfOrdersInvoicesSettlementsWithCustomers AS ARAPObjects
	|		ON ARAPObjects.ARAPObject = ShipmentPlan.ARAPObject
	|WHERE
	|	ShipmentPlan.ARAPObject IN
	|			(SELECT
	|				T.ARAPObject
	|			FROM
	|				TTCommunicationOfOrdersInvoicesSettlementsWithCustomers AS T)
	|
	|GROUP BY
	|	ARAPObjects.Document,
	|	ARAPObjects.ARAPObjectSettings,
	|	ShipmentPlan.ARAPObject,
	|	ShipmentPlan.Currency,
	|	ShipmentPlan.DocumentRecorder,
	|	BEGINOFPERIOD(ShipmentPlan.Period, DAY)
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText, "CustomersARAPAccountingPlannedShipments", "VendorsARAPAccountingPlannedDeliveries");
		QueryText = StrReplace(QueryText, "CustomersARAPAccounting", "VendorsARAPAccounting");
	EndIf;
	
	Return QueryText
	
EndFunction

Function QueryTextForShipments(TheseAreSettlementsWithCustomers)
	
	QueryText = " 
	|SELECT
	|	CalculationData.Document                    AS Document,
	|	MAX(CalculationData.ARAPObject)    AS ARAPObject,
	|	CalculationData.CalculationObjectObject        AS CalculationObjectObject,
	|	CalculationData.DocumentRecorder         AS DocumentRecorder,
	|	CalculationData.ARAPObjectSettings             AS ARAPObjectSettings,
	|	CalculationData.Currency                      AS Currency,
	|	CalculationData.ShipmentPaymentOption       AS ShipmentPaymentOption,
	|	CalculationData.DatePlan                    AS DatePlan,
	|	
	|	SUM(CalculationData.SumPlan)            AS SumPlan,
	|	SUM(CalculationData.ScheduleAdjustment) AS ScheduleAdjustment,
	|	
	|	CalculationData.DateFact                    AS DateFact,
	|	MAX(CalculationData.Period)            AS Period,
	|	SUM(CalculationData.SumReal)            AS SumReal,
	|	
	|	SUM(0)                                   AS Balance,
	|	SUM(0)                                   AS BalanceIsOverdue,
	|	SUM(0)                                   AS DaysOverdue_3
	|	
	|FROM (
	|	// Shipment plan
	|	SELECT
	|		ARAPObjects.Document                 AS Document,
	|		ARAPObjects.ARAPObject           AS ARAPObject,
	|		ARAPObjects.CalculationObjectObject     AS CalculationObjectObject,
	|		ShipmentPlan.DocumentRecorder         AS DocumentRecorder,
	|		ARAPObjects.ARAPObjectSettings          AS ARAPObjectSettings,
	|		ARAPObjects.Currency                   AS Currency,
	|		CASE
	|			WHEN VALUETYPE(ShipmentPlan.DocumentPlan) = TYPE(Document.ContractSchedule)
	|				THEN 2
	|			ELSE 3
	|		END                                    AS ShipmentPaymentOption,
	|		ShipmentPlan.PlannedRepaymentDate      AS DatePlan,
	|		CASE
	|			WHEN ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND ShipmentPlan.Sum > 0
	|				THEN ShipmentPlan.Sum
	|			// Write-Off Of Shipped Goods
	|			WHEN ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND ShipmentPlan.Sum < 0
	|				THEN ShipmentPlan.Sum
	|			ELSE 0
	|		END                                    AS SumPlan,
	|		CASE
	|			// Advance payment
	|			WHEN ShipmentPlan.UnallocatedAdvancePayment
	|				AND ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND NOT VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|				AND ShipmentPlan.Sum > 0 
	|				THEN -ShipmentPlan.Sum
	|			// Storno advance
	|			WHEN ShipmentPlan.UnallocatedAdvancePayment
	|				AND ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND (VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					OR VALUETYPE(ShipmentPlan.DocumentRecorder) IN (&TypesOfPaymentDocuments)
	|					OR VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ARAPAdjustment))
	|				AND ShipmentPlan.Sum < 0 
	|				THEN -ShipmentPlan.Sum
	|			ELSE 0
	|		END                                    AS ScheduleAdjustment,
	|		CASE
	|			// Shipment
	|			WHEN NOT ShipmentPlan.UnallocatedAdvancePayment
	|					AND ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND NOT VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					AND ShipmentPlan.Sum > 0
	|			// Prepayment offset reduces the amount of the fact, since this request only shipments in debt
	|				OR ShipmentPlan.UnallocatedAdvancePayment
	|					AND ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND NOT VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					AND NOT VALUETYPE(ShipmentPlan.DocumentRecorder) IN (&TypesOfPaymentDocuments)
	|					AND NOT VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ARAPAdjustment)
	|					// There is no actual debt on the way to the sale, so we do not reduce the shipment amount received from scheduled shipments
	|					AND NOT (&ConditionImplementationOnWay)
	|					AND ShipmentPlan.Sum < 0
	|			// Storno Shipment
	|				OR NOT ShipmentPlan.UnallocatedAdvancePayment
	|					AND ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					AND ShipmentPlan.Sum < 0
	|				THEN BEGINOFPERIOD(ShipmentPlan.Period, DAY)
	|			ELSE DATETIME(1, 1, 1)
	|		END                                    AS DateFact,
	|		BEGINOFPERIOD(ShipmentPlan.Period, DAY) AS Period,
	|		CASE
	|			// Shipment
	|			WHEN NOT ShipmentPlan.UnallocatedAdvancePayment
	|					AND ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND NOT VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					AND ShipmentPlan.Sum > 0
	|				THEN ShipmentPlan.Sum
	|			// Prepayment offset reduces the amount of the fact, since this request only shipments in debt
	|			WHEN ShipmentPlan.UnallocatedAdvancePayment
	|					AND ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND NOT VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					AND NOT VALUETYPE(ShipmentPlan.DocumentRecorder) IN (&TypesOfPaymentDocuments)
	|					AND NOT VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ARAPAdjustment)
	|					// There is no actual debt on the way to the sale, so we do not reduce the shipment amount received from scheduled shipments
	|					AND NOT (&ConditionImplementationOnWay)
	|					AND ShipmentPlan.Sum < 0
	|				THEN ShipmentPlan.Sum
	|			// Storno Shipment
	|			WHEN NOT ShipmentPlan.UnallocatedAdvancePayment
	|					AND ShipmentPlan.RecordType = VALUE(AccumulationRecordType.Expense)
	|					AND VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.ReversingEntry)
	|					AND ShipmentPlan.Sum < 0
	|				THEN ShipmentPlan.Sum
	|			ELSE 0
	|		END                                    AS SumReal
	|	FROM
	|		ARAPObjects AS ARAPObjects
	|			INNER JOIN AccumulationRegister.CustomersARAPAccountingPlannedShipments AS ShipmentPlan
	|			ON ARAPObjects.ARAPObject = ShipmentPlan.ARAPObject
	|
	|	UNION ALL
	|
	|	// Actual payments and shipments
	|	SELECT
	|		ARAPObjects.Document                     AS Document,
	|		ARAPObjects.SourceObjectOfCalculations_       AS ARAPObject,
	|		ARAPObjects.OriginalARAPObjectIsObject AS CalculationObjectObject,
	|		CalculationsByTerms.DocumentRecorder          AS DocumentRecorder,
	|		ARAPObjects.ARAPObjectSettings              AS ARAPObjectSettings,
	|		ARAPObjects.Currency                       AS Currency,
	|		CASE
	|			WHEN ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|				AND (CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtIncrease)) 
	|				THEN 5
	|			ELSE 0
	|		END                                        AS ShipmentPaymentOption,
	|		CASE
	|			WHEN ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|				AND (CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtIncrease)) 
	|				THEN CalculationsByTerms.OccurrenceDate
	|			ELSE CalculationsByTerms.PlannedRepaymentDate
	|		END                                        AS DatePlan,
	|		0                                            AS SumPlan,
	|		CASE
	|			WHEN CalculationsByTerms.SettlementRecordType IN (
	|				VALUE(Enum.TypesOfSettlementRecords.PaymentPrepaymentIncrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentIncrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentIncrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfInvoicePrepaymentIncrease))
	|				THEN CalculationsByTerms.Prepayment
	|			WHEN CalculationsByTerms.SettlementRecordType IN (
	|				VALUE(Enum.TypesOfSettlementRecords.RefundDecreasesPrepayment), 
	|				VALUE(Enum.TypesOfSettlementRecords.TransferOfSettlementsPrepaymentDecrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfDebtPrepaymentDecrease), 
	|				VALUE(Enum.TypesOfSettlementRecords.InvoiceAdjustmentPrepaymentDecrease))
	|				THEN -CalculationsByTerms.Prepayment
	|			WHEN ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|				AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease) 
	|				THEN -CalculationsByTerms.Debt
	|			WHEN ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|				AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtIncrease) 
	|				THEN CalculationsByTerms.Debt
	|			ELSE 0
	|		END * ARAPObjects.OrderShare           AS ScheduleAdjustment,
	|		CASE 
	|			WHEN (ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|					OR CalculationsByTerms.ReversingEntry)
	|				AND (CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease)
	|					OR CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtIncrease))
	|				AND CalculationsByTerms.Debt <> 0
	|				THEN CalculationsByTerms.OccurrenceDate
	|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentPrepaymentDecrease)
	|				AND CalculationsByTerms.Prepayment  <> 0
	|				THEN BEGINOFPERIOD(CalculationsByTerms.Period, DAY)
	|			ELSE DATETIME(1, 1, 1)
	|		END                                        AS DateFact,
	|		BEGINOFPERIOD(CalculationsByTerms.Period, DAY) AS Period,
	|		CASE
	|			WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentPrepaymentDecrease)
	|				THEN CalculationsByTerms.Prepayment
	|			WHEN (ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|					OR CalculationsByTerms.ReversingEntry)
	|				AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtDecrease) 
	|				THEN -CalculationsByTerms.Debt
	|			WHEN (ARAPObjects.SourceObjectOfCalculations_.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.Invoice)
	|					OR CalculationsByTerms.ReversingEntry)
	|				AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtIncrease) 
	|				THEN CalculationsByTerms.Debt
	|			ELSE 0
	|		END * ARAPObjects.OrderShare           AS SumReal
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|			INNER JOIN TTCommunicationOfOrdersInvoicesSettlementsWithCustomers AS ARAPObjects
	|			ON CalculationsByTerms.ARAPObject = ARAPObjects.ARAPObject
	|	) AS CalculationData
	|	
	|GROUP BY
	|	CalculationData.Document,
	|	CalculationData.CalculationObjectObject,
	|	CalculationData.DocumentRecorder,
	|	CalculationData.ARAPObjectSettings,
	|	CalculationData.Currency,
	|	CalculationData.ShipmentPaymentOption,
	|	CalculationData.DatePlan,
	|	CalculationData.DateFact
	|
	|HAVING
	|	(SUM(CalculationData.SumPlan) <> 0
	|		OR SUM(CalculationData.ScheduleAdjustment) <> 0
	|		OR SUM(CalculationData.SumReal) <> 0
	|			AND CalculationData.ShipmentPaymentOption <> 4
	|		OR SUM(CalculationData.SumReal) > 0
	|			AND CalculationData.ShipmentPaymentOption = 4)
	|
	|ORDER BY
	|	DatePlan,
	|	ShipmentPaymentOption,
	|	DateFact
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText, "CustomersARAPAccountingPlannedShipments", "VendorsARAPAccountingPlannedDeliveries");
		QueryText = StrReplace(QueryText, "CustomersARAPAccounting", "VendorsARAPAccounting");
		QueryText = StrReplace(QueryText, "&ConditionImplementationOnWay", "FALSE");
	Else
		QueryText = StrReplace(QueryText, "&ConditionImplementationOnWay", "
			|						CASE WHEN VALUETYPE(ShipmentPlan.DocumentRecorder) = TYPE(Document.CustomerInvoice)
			|							THEN CAST(ShipmentPlan.DocumentRecorder AS Document.CustomerInvoice).Status = VALUE(Enum.StatusesOfCustomerInvoices.InTransit)
			|							ELSE FALSE
			|						END");
	EndIf;
	
	Return QueryText
	
EndFunction

Function QueryTextBeingPaid(TheseAreSettlementsWithCustomers)
	
	QueryText = " 
	|SELECT
	|	ARAPObjects.Document                                                AS Document,
	|	ARAPObjects.SourceObjectOfCalculations_                                  AS ARAPObject,
	|	ARAPObjects.OriginalARAPObjectIsObject                            AS CalculationObjectObject,
	|	ARAPObjects.ARAPObjectSettings                                         AS ARAPObjectSettings,
	|	ARAPObjects.Currency                                                  AS Currency,
	|	VALUE(Enum.CustomerPaymentControlOptions.EmptyRef)      AS ShipmentPaymentOption,
	|	SUM(SettlementBalances.BeingPaidBalance * ARAPObjects.OrderShare) AS SumReal
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(,
	|		(ARAPObject, Currency) IN (SELECT T.ARAPObject, T.Currency FROM TTCommunicationOfOrdersInvoicesSettlementsWithCustomers AS T)) AS SettlementBalances
	|		INNER JOIN TTCommunicationOfOrdersInvoicesSettlementsWithCustomers AS ARAPObjects
	|		ON SettlementBalances.ARAPObject = ARAPObjects.ARAPObject
	|GROUP BY
	|	ARAPObjects.Document,
	|	ARAPObjects.SourceObjectOfCalculations_,
	|	ARAPObjects.OriginalARAPObjectIsObject,
	|	ARAPObjects.ARAPObjectSettings,
	|	ARAPObjects.Currency
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText, "CustomerPaymentControlOptions", "OptionsForControllingPaymentToSupplier");
		QueryText = StrReplace(QueryText, "CustomersARAPAccounting", "VendorsARAPAccounting");
	EndIf;
	
	Return QueryText
	
EndFunction

Function TypesOfPaymentDocuments()
	
	TypesList = New ValueList;
	TypesList.Add(Type("DocumentRef.BankAccountReceiptNote"));
	TypesList.Add(Type("DocumentRef.BankAccountIssue"));
	TypesList.Add(Type("DocumentRef.CashAccountReceiptNote"));
	TypesList.Add(Type("DocumentRef.CashVoucher"));
	TypesList.Add(Type("DocumentRef.PaymentCardTransaction"));
	
	
	Return TypesList;
	
EndFunction

Function GetCalculationData(TempTableManager, CustomersARAPAccounting, VendorsARAPAccounting)
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("TypesOfPaymentDocuments", TypesOfPaymentDocuments());
	Query.SetParameter("ReportData", 4);
	
	QueryTexts = New Array;
	
	If CustomersARAPAccounting Then
		
		QueryTexts.Add(QueryTextTTCommunicationOrdersINVOICES(True));
		QueryTexts.Add(QueryTextForPaymentsByDueDate(True));
		QueryTexts.Add(QueryTextForPaymentsAccordingToPlan(True));
		QueryTexts.Add(QueryTextByPayments(True));
		QueryTexts.Add(QueryTextForShipmentsByTime(True));
		QueryTexts.Add(QueryTextForShipmentsAccordingToPlan(True));
		QueryTexts.Add(QueryTextForShipments(True));
		QueryTexts.Add(QueryTextBeingPaid(True));
		
	EndIf;
	
	If VendorsARAPAccounting Then
		
		QueryTexts.Add(QueryTextTTCommunicationOrdersINVOICES(False));
		QueryTexts.Add(QueryTextForPaymentsByDueDate(False));
		QueryTexts.Add(QueryTextForPaymentsAccordingToPlan(False));
		QueryTexts.Add(QueryTextByPayments(False));
		QueryTexts.Add(QueryTextForShipmentsByTime(False));
		QueryTexts.Add(QueryTextForShipmentsAccordingToPlan(False));
		QueryTexts.Add(QueryTextForShipments(False));
		QueryTexts.Add(QueryTextBeingPaid(False));
		
	EndIf;
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	QueryResult = Query.ExecuteBatch();
	
	CalculationData = New Structure;
	DataToOutput = New Structure;
	PackageIndex = 0;
	If CustomersARAPAccounting Then
		CalculationData.Insert("PaymentsByDueDate",   QueryResult[1].Unload());
		CalculationData.Insert("PaymentsAccordingToPlan",    QueryResult[2].Unload());
		CalculationData.Insert("Payments",           QueryResult[3].Unload());
		CalculationData.Insert("ShipmentsByTime", QueryResult[4].Unload());
		CalculationData.Insert("ShipmentsAccordingToPlan",  QueryResult[5].Unload());
		CalculationData.Insert("Shipments",         QueryResult[6].Unload());
		CalculationData.Insert("BeingPaid",     QueryResult[7].Unload());
		DataToOutput.Insert("SettlementsWithPaymentClients", ProcessDataBeforeOutput(CalculationData, True, True));
		DataToOutput.Insert("SettlementsWithShippingCustomers", ProcessDataBeforeOutput(CalculationData, False, True));
		PackageIndex = 8;
	EndIf;
	
	If VendorsARAPAccounting Then
		CalculationData.Insert("PaymentsByDueDate",   QueryResult[PackageIndex + 1].Unload());
		CalculationData.Insert("PaymentsAccordingToPlan",    QueryResult[PackageIndex + 2].Unload());
		CalculationData.Insert("Payments",           QueryResult[PackageIndex + 3].Unload());
		CalculationData.Insert("ShipmentsByTime", QueryResult[PackageIndex + 4].Unload());
		CalculationData.Insert("ShipmentsAccordingToPlan",  QueryResult[PackageIndex + 5].Unload());
		CalculationData.Insert("Shipments",         QueryResult[PackageIndex + 6].Unload());
		CalculationData.Insert("BeingPaid",     QueryResult[PackageIndex + 7].Unload());
		DataToOutput.Insert("SettlementsWithPaymentProviders", ProcessDataBeforeOutput(CalculationData, True, False));
		DataToOutput.Insert("SettlementsWithShippingSuppliers", ProcessDataBeforeOutput(CalculationData, False, False));
	EndIf;
	
	Return DataToOutput;
	
EndFunction

Function ProcessDataBeforeOutput(CalculationData, TheseArePayments, TheseAreSettlementsWithClient)
	
	CalculationTable = CalculationData[?(TheseArePayments, "Payments", "Shipments")];
	Plan = CalculationData[?(TheseArePayments, "PaymentsAccordingToPlan", "ShipmentsAccordingToPlan")];
	Real = CalculationData[?(TheseArePayments, "PaymentsByDueDate", "ShipmentsByTime")];
	
	Real.Indexes.Add("Document, ARAPObject, DocumentRecorder");
	TableOfDiscrepancies = Real.Copy();
	ARAPObjectsWithPlan = New Map;
	For Each PlanRow In Plan Do
		NewRow = TableOfDiscrepancies.Add();
		FillPropertyValues(NewRow, PlanRow);
		NewRow.SumReal = ?(TheseArePayments, -NewRow.SumReal, 0);
		NewRow.ApplyingPrepayment          = -NewRow.ApplyingPrepayment;
		NewRow.ScheduleAdjustment = -NewRow.ScheduleAdjustment;
		If ARAPObjectsWithPlan[PlanRow.ARAPObject] = Undefined Then
			ARAPObjectsWithPlan[PlanRow.ARAPObject] = True;
		EndIf;
	EndDo;
	If Not TheseArePayments Then
		For Each CalculationLine_ In CalculationTable Do
			NewRow = TableOfDiscrepancies.Add();
			FillPropertyValues(NewRow, CalculationLine_);
			NewRow.SumReal            = -NewRow.SumReal;
			NewRow.ApplyingPrepayment          = 0;
			NewRow.ScheduleAdjustment = 0;
		EndDo;
	EndIf;
	
	TableOfDiscrepancies.GroupBy("Document, ARAPObject, DocumentRecorder, ARAPObjectSettings", "SumReal, ApplyingPrepayment, ScheduleAdjustment");
	Filter = New Structure("Document, ARAPObject, DocumentRecorder"); 
	
	CalculationTable.Indexes.Add("Document, ARAPObject, ShipmentPaymentOption, DatePlan, DocumentRecorder");
	SelectionByStageAndRecorders = New Structure("Document, ARAPObject, ShipmentPaymentOption, DatePlan, DocumentRecorder");
	
	If TheseArePayments Then
		
		For Each AdditionalPaymentLine In TableOfDiscrepancies Do
			If ARAPObjectsWithPlan[AdditionalPaymentLine.ARAPObject]= Undefined Then
				Continue;
			EndIf;
			FillPropertyValues(Filter, AdditionalPaymentLine);
			If AdditionalPaymentLine.SumReal > 0 Then
				FactLines = Real.FindRows(Filter);
				If FactLines.Count() > 0 Then
					// Payment over the plan
					NewRow = CalculationTable.Add();
					FillPropertyValues(NewRow, FactLines[0]);
					NewRow.SumReal = AdditionalPaymentLine.SumReal;
					NewRow.ScheduleAdjustment = AdditionalPaymentLine.SumReal;
					NewRow.ShipmentPaymentOption = ?(
						TheseAreSettlementsWithClient,
						Enums.CustomerPaymentControlOptions.EmptyRef(),
						Enums.OptionsForControllingPaymentToSupplier.EmptyRef());
				EndIf;
			EndIf;
			// The difference in the offsetting of the advance payment for details from advances on orders or Contracts
			If AdditionalPaymentLine.ApplyingPrepayment <> 0
				And (AdditionalPaymentLine.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice
					Or AdditionalPaymentLine.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice) Then
				FactLines = CalculationTable.FindRows(Filter);
				DiscrepancyAmount = -AdditionalPaymentLine.ApplyingPrepayment;
				For Each FactString In FactLines Do
					AmountToBeDebited_ = Min(DiscrepancyAmount, FactString.ScheduleAdjustment);
					FactString.ScheduleAdjustment = FactString.ScheduleAdjustment - AmountToBeDebited_;
					DiscrepancyAmount = DiscrepancyAmount - AmountToBeDebited_;
					If DiscrepancyAmount = 0 Then
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
	Else
		
		AdvancePaymentLinesInExcessOfShipmentPlan = New Array;
		For Each AdditionalShippingLine In TableOfDiscrepancies Do
			If ARAPObjectsWithPlan[AdditionalShippingLine.ARAPObject]= Undefined Then
				Continue;
			EndIf;
			If AdditionalShippingLine.ScheduleAdjustment > 0 Then
				AdvancePaymentLinesInExcessOfShipmentPlan.Add(AdditionalShippingLine);
			EndIf;
		EndDo;
		For Each AdditionalShippingLine In TableOfDiscrepancies Do
			If ARAPObjectsWithPlan[AdditionalShippingLine.ARAPObject]= Undefined Then
				Continue;
			EndIf;
			// The difference in advance credits is in plan and fact
			If AdditionalShippingLine.ApplyingPrepayment < 0 Then
				// We will reduce the correction of the advance that formed the discrepancy
				AmountOfDiscrepancyAdjustments = -AdditionalShippingLine.ApplyingPrepayment;
				For Each AdvancePaymentLineInExcessOfShipmentPlan In AdvancePaymentLinesInExcessOfShipmentPlan Do
					FillPropertyValues(Filter, AdvancePaymentLineInExcessOfShipmentPlan);
					AdjustmentLines = CalculationTable.FindRows(Filter);
					For Each AdjustmentLine In AdjustmentLines Do
						AmountToDeductAdjustments = Min(AmountOfDiscrepancyAdjustments, AdjustmentLine.ScheduleAdjustment, AdvancePaymentLineInExcessOfShipmentPlan.ScheduleAdjustment);
						AdjustmentLine.ScheduleAdjustment = AdjustmentLine.ScheduleAdjustment - AmountToDeductAdjustments;
						AdvancePaymentLineInExcessOfShipmentPlan.ScheduleAdjustment = AdvancePaymentLineInExcessOfShipmentPlan.ScheduleAdjustment - AmountToDeductAdjustments;
						AmountOfDiscrepancyAdjustments = AmountOfDiscrepancyAdjustments - AmountToDeductAdjustments;
						
						// Find the actual shipment lines that accounted for this discrepancy
						FillPropertyValues(SelectionByStageAndRecorders, AdjustmentLine);
						SelectionByStageAndRecorders.DocumentRecorder = AdditionalShippingLine.DocumentRecorder;
						FactLines = CalculationTable.FindRows(SelectionByStageAndRecorders);
						DiscrepancyAmount = AmountToDeductAdjustments;
						For Each FactString In FactLines Do
							AmountToBeDebited_ = Min(DiscrepancyAmount, FactString.SumReal);
							FactString.SumReal = FactString.SumReal - AmountToBeDebited_;
							DiscrepancyAmount = DiscrepancyAmount - AmountToBeDebited_;
							If DiscrepancyAmount = 0 Then
								Break;
							EndIf;
						EndDo;
						If AmountOfDiscrepancyAdjustments = 0 Then
							Break;
						EndIf;
					EndDo;
				EndDo;
			EndIf;
		EndDo;
		For Each AdditionalShippingLine In TableOfDiscrepancies Do
			If ARAPObjectsWithPlan[AdditionalShippingLine.ARAPObject]= Undefined Then
				Continue;
			EndIf;
			FillPropertyValues(Filter, AdditionalShippingLine);
			// The difference in the offsetting of the advance payment for details from advances on orders or Contracts
			If (AdditionalShippingLine.SumReal <> 0 
					And TheseArePayments
						Or AdditionalShippingLine.SumReal > 0
							And Not TheseArePayments)
				And (AdditionalShippingLine.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice
					Or AdditionalShippingLine.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice) Then
				FactLines = CalculationTable.FindRows(Filter);
				DiscrepancyAmount = AdditionalShippingLine.SumReal;
				For Each FactString In FactLines Do
					If AdditionalShippingLine.SumReal < 0 Then
						AmountToBeDebited_ = Min(-DiscrepancyAmount, FactString.SumReal);
						FactString.SumReal = FactString.SumReal - AmountToBeDebited_;
						AdditionalShippingLine.SumReal = AdditionalShippingLine.SumReal + AmountToBeDebited_;
					Else
						AmountToAccrue = AdditionalShippingLine.SumReal;
						FactString.SumReal = FactString.SumReal + AmountToAccrue;
						AdditionalShippingLine.SumReal = AdditionalShippingLine.SumReal - AmountToAccrue;
					EndIf;
					If AdditionalShippingLine.SumReal = 0 Then
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		// The positive Balance of the amount of the fact is a shipment in excess of the plan
		TableOfDiscrepancies.GroupBy("Document, ARAPObject", "SumReal");
		For Each LineBeyondPlan In TableOfDiscrepancies Do
			CalculationRows = Real.FindRows(New Structure("Document, ARAPObject, ShipmentPaymentOption", LineBeyondPlan.Document, LineBeyondPlan.ARAPObject, 4));
			If CalculationRows.Count() > 0 
				And LineBeyondPlan.SumReal > 0 Then
				NewRow = CalculationTable.Add();
				FillPropertyValues(NewRow, CalculationRows[0]);
				NewRow.SumReal = LineBeyondPlan.SumReal;
				NewRow.ScheduleAdjustment = 0;
				NewRow.DateFact = Date(1, 1, 1);
			EndIf;
		EndDo;
		
	EndIf;
	
	If TheseArePayments Then
		For Each LineIsBeingPaid In CalculationData.BeingPaid Do
			NewRow = CalculationTable.Add();
			FillPropertyValues(NewRow, LineIsBeingPaid);
		EndDo;
	EndIf;
	
	CalculationTable.Indexes.Add("Document, ARAPObject, DatePlan, ShipmentPaymentOption");
	
	GroupingByDocument = CalculationTable.Copy(, "Document, ARAPObject, CalculationObjectObject, Currency, ARAPObjectSettings, SumPlan, SumReal, ScheduleAdjustment");
	GroupingByDocument.GroupBy("Document, ARAPObject, CalculationObjectObject, Currency, ARAPObjectSettings", "SumPlan, SumReal, ScheduleAdjustment");
	
	GroupingByShipmentPaymentStage = CalculationTable.Copy(, "Document, ARAPObject, Currency, ARAPObjectSettings, DatePlan, ShipmentPaymentOption, SumPlan, SumReal, ScheduleAdjustment");
	GroupingByShipmentPaymentStage.GroupBy("Document, ARAPObject, Currency, ARAPObjectSettings, DatePlan, ShipmentPaymentOption", "SumPlan, SumReal, ScheduleAdjustment");
	GroupingByShipmentPaymentStage.Indexes.Add("Document, ARAPObject");
	GroupingByShipmentPaymentStage.Indexes.Add("Document, ARAPObject, DatePlan");
	
	SelectionOfShipmentPaymentStage = New Structure("Document, ARAPObject, DatePlan, ShipmentPaymentOption");
	FilterDocument_ = New Structure("Document, ARAPObject");
	
	// Lines beyond the plan are irrelevant for documents without a plan
	For Each DocumentLine In GroupingByDocument Do
		If DocumentLine.SumPlan = 0 Then
			FillPropertyValues(FilterDocument_, DocumentLine);
			LinesOfStagesOfShipmentPayment = GroupingByShipmentPaymentStage.FindRows(FilterDocument_);
			For Each ShippingPaymentStageLine In LinesOfStagesOfShipmentPayment Do
				If ShippingPaymentStageLine.ShipmentPaymentOption = 4
					Or TheseArePayments 
						And Not ValueIsFilled(ShippingPaymentStageLine.DatePlan) Then
					FillPropertyValues(SelectionOfShipmentPaymentStage, ShippingPaymentStageLine);
					DetailedRecords = CalculationTable.FindRows(SelectionOfShipmentPaymentStage);
					For Each TableRow In DetailedRecords Do
						CalculationTable.Delete(TableRow);
					EndDo;
					DocumentLine.SumReal = DocumentLine.SumReal - ShippingPaymentStageLine.SumReal;
					DocumentLine.ScheduleAdjustment = DocumentLine.ScheduleAdjustment - ShippingPaymentStageLine.ScheduleAdjustment;
					GroupingByShipmentPaymentStage.Delete(ShippingPaymentStageLine);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	// Lines without a shipment payment option must be combined with plan lines that have negative adjustments
	// so that the adjustment tends to 0 for the final line. If the fact line remains, then the default shipment payment option is set
	// If the payment plan has not been changed in the implementation, then the payment option will be inherited for the actual debt repayment schedule
	// If the advance payment did not specify a repayment date other than the scheduled shipment date, the shipment option will be inherited
	FactLines = New Array;
	For Each CalculationLine_ In GroupingByShipmentPaymentStage Do
		If Not ValueIsFilled(CalculationLine_.ShipmentPaymentOption) Then
			FactLines.Add(CalculationLine_);
		EndIf;
	EndDo;
	
	SelectionOfPlannedLines = New Structure("Document, ARAPObject, DatePlan");
	
	For Each FactString In FactLines Do
		If FactString.ScheduleAdjustment > 0 Then
			FillPropertyValues(SelectionOfPlannedLines, FactString);
			PlanLines = GroupingByShipmentPaymentStage.FindRows(SelectionOfPlannedLines);
			// If there are lines of the planned schedule on the current scheduled date, then we will transfer to them the amounts of adjustments, Balances and the fact of the current line
			For Each PlanRow In PlanLines Do
				If ValueIsFilled(PlanRow.ShipmentPaymentOption)
					And PlanRow.ScheduleAdjustment < 0 Then
					
					// We limit the possible reduction of the amounts of the actual line to the amount of reduction of the planned schedule
					TransferAmount_ = Min(FactString.ScheduleAdjustment, - PlanRow.ScheduleAdjustment);
					FactString.ScheduleAdjustment = FactString.ScheduleAdjustment - TransferAmount_;
					PlanRow.ScheduleAdjustment = PlanRow.ScheduleAdjustment + TransferAmount_;
					
					AmountOfFactTransfer = Min(TransferAmount_, FactString.SumReal);
					PlanRow.SumReal = PlanRow.SumReal + AmountOfFactTransfer;
					FactString.SumReal = FactString.SumReal - AmountOfFactTransfer;
					
					// We will find the fact lines and indicate to them the payment option for the shipment in accordance with the plan line
					FillPropertyValues(SelectionOfShipmentPaymentStage, FactString);
					DetailedFactLines = CalculationTable.FindRows(SelectionOfShipmentPaymentStage);
					
					For Each DetailedFactLine In DetailedFactLines Do
						If DetailedFactLine.SumReal > 0 Then
							If DetailedFactLine.SumReal <= TransferAmount_ Then
								DetailedFactLine.ShipmentPaymentOption = PlanRow.ShipmentPaymentOption;
								TransferAmount_ = TransferAmount_ - DetailedFactLine.SumReal;
							ElsIf TransferAmount_ = 0 Then
								Break;
							Else
								NewRow = CalculationTable.Insert(CalculationTable.IndexOf(DetailedFactLine) + 1);
								FillPropertyValues(NewRow, DetailedFactLine);
								DetailedFactLine.ShipmentPaymentOption = PlanRow.ShipmentPaymentOption;
								DetailedFactLine.SumReal = TransferAmount_;
								NewRow.SumReal = NewRow.SumReal - TransferAmount_;
								TransferAmount_ = 0;
							EndIf;
						EndIf;
					EndDo;
					
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	CalculationTable.GroupBy(
		"Currency, ShipmentPaymentOption, DatePlan, DateFact, DaysOverdue_3, Document, ARAPObject, CalculationObjectObject, ARAPObjectSettings",
		"ScheduleAdjustment, Balance, BalanceIsOverdue, SumPlan, SumReal");
	
	CalculationTable.Sort("DatePlan, ShipmentPaymentOption, DateFact");
	
	Result = New ValueTree;
	For Each Column In CalculationTable.Columns Do
		Result.Columns.Add(Column.Name, Column.ValueType);
	EndDo;
	// Tree structure:
	//		Document string - grouping by fields: Document, Account objectcounts
	//			Row of the Loading fee step - grouping by fields: DataPlan, variant of the loading fee
	//				Fact line - actual dates and amounts of payments or shipments
	
	For Each DocumentLine In GroupingByDocument Do
		
		TreeLineByDocument = Result.Rows.Add();
		FillPropertyValues(TreeLineByDocument, DocumentLine);
		
		FillPropertyValues(FilterDocument_, DocumentLine);
		LinesOfStagesOfShipmentPayment = GroupingByShipmentPaymentStage.FindRows(FilterDocument_);
		
		For Each ShippingPaymentStageLine In LinesOfStagesOfShipmentPayment Do
			
			If ShippingPaymentStageLine.SumPlan = 0
				And ShippingPaymentStageLine.SumReal = 0
				And ShippingPaymentStageLine.ScheduleAdjustment = 0 Then
				Continue;
			EndIf;
			
			TreeLineByShipmentPaymentStage = TreeLineByDocument.Rows.Add();
			FillPropertyValues(TreeLineByShipmentPaymentStage, ShippingPaymentStageLine);
			
			FillPropertyValues(SelectionOfShipmentPaymentStage, ShippingPaymentStageLine);
			DetailedRecords = CalculationTable.FindRows(SelectionOfShipmentPaymentStage);
			
			If Not ValueIsFilled(TreeLineByShipmentPaymentStage.ShipmentPaymentOption) 
				And TypeOf(TreeLineByShipmentPaymentStage.ShipmentPaymentOption) <> Type("EnumRef.CustomerPaymentControlOptions")
				And TypeOf(TreeLineByShipmentPaymentStage.ShipmentPaymentOption) <> Type("EnumRef.OptionsForControllingPaymentToSupplier") Then
				TreeLineByShipmentPaymentStage.ShipmentPaymentOption = 1;
			EndIf;
			
			For Each TableRow In DetailedRecords Do
				
				If ValueIsFilled(TableRow.DateFact)
					And (TableRow.SumPlan <> 0
						Or TableRow.SumReal <> 0
						Or TableRow.ScheduleAdjustment <> 0) Then
					TreeRow = TreeLineByShipmentPaymentStage.Rows.Add();
					FillPropertyValues(TreeRow, TableRow);
					If Not ValueIsFilled(TreeRow.ShipmentPaymentOption) Then
						TreeRow.ShipmentPaymentOption = TreeLineByShipmentPaymentStage.ShipmentPaymentOption;
					EndIf;
					If TreeLineByDocument.SumPlan = 0 Then
						TreeRow.SumPlan = TreeRow.ScheduleAdjustment;
						TreeRow.ScheduleAdjustment = 0;
					EndIf;
				EndIf;
				
			EndDo;
			
			If TreeLineByDocument.SumPlan = 0 Then
				TreeLineByShipmentPaymentStage.SumPlan = TreeLineByShipmentPaymentStage.ScheduleAdjustment;
				TreeLineByShipmentPaymentStage.ScheduleAdjustment = 0;
			EndIf;
			
		EndDo;
		
		If TreeLineByDocument.SumPlan = 0 Then
			TreeLineByDocument.SumPlan = TreeLineByDocument.ScheduleAdjustment;
			TreeLineByDocument.ScheduleAdjustment = 0;
		EndIf;
		
	EndDo;
	
	// Calculation of Balances
	For Each TreeLineByDocument In Result.Rows Do
		
		For Each TreeLineByShipmentPaymentStage In TreeLineByDocument.Rows Do
			
			TreeLineByShipmentPaymentStage.Balance = Max(
				TreeLineByShipmentPaymentStage.SumPlan
					+ TreeLineByShipmentPaymentStage.ScheduleAdjustment
					- TreeLineByShipmentPaymentStage.SumReal,
				0);
			If TreeLineByShipmentPaymentStage.Balance > 0
				And ValueIsFilled(TreeLineByShipmentPaymentStage.DatePlan)
				And TreeLineByShipmentPaymentStage.DatePlan < BegOfDay(CurrentSessionDate()) Then
				
				TreeLineByShipmentPaymentStage.BalanceIsOverdue = TreeLineByShipmentPaymentStage.Balance;
				TreeLineByShipmentPaymentStage.DaysOverdue_3 = TMCommonUse.DateDiff(
					TreeLineByShipmentPaymentStage.DatePlan,
					BegOfDay(CurrentSessionDate()),
					Enums.Periodicity.Day);
				
			EndIf;
			
		EndDo;
		
		TreeLineByDocument.Balance           = TreeLineByDocument.Rows.Total("Balance");
		TreeLineByDocument.BalanceIsOverdue = TreeLineByDocument.Rows.Total("BalanceIsOverdue");
		
	EndDo;
	
	Return Result;
	
EndFunction

Function DisplayTableOfCalculationsForPaymentsShipments(ReportTable, Template, Document, ResultTables, TheseAreSettlementsWithClient)
	
	Var TableOfPayment, ShipmentTable;
	
	NameOfPaymentTable = ?(
		TheseAreSettlementsWithClient,
		"SettlementsWithPaymentClients",
		"SettlementsWithPaymentProviders");
	ShipmentTableName = ?(
		TheseAreSettlementsWithClient,
		"SettlementsWithShippingCustomers",
		"SettlementsWithShippingSuppliers");
	
	ThereIsTableOfPayments = ResultTables.Property(NameOfPaymentTable, TableOfPayment);
	ThereIsShipmentTable = ResultTables.Property(ShipmentTableName, ShipmentTable);
	If Not (ThereIsTableOfPayments
			Or ThereIsShipmentTable) Then
		Return False;
	EndIf;
	
	PaymentByDocument = ?(
		ThereIsTableOfPayments,
		TableOfPayment.Rows.FindRows(New Structure("Document", Document)),
		Undefined);
	ShipmentsByDocument = ?(
		ThereIsShipmentTable,
		ShipmentTable.Rows.FindRows(New Structure("Document", Document)),
		Undefined);
	If PaymentByDocument = Undefined
		And ShipmentsByDocument = Undefined Then
		Return False;
	EndIf;
	
	ARAPObjects = New Array;
	// For payment orders, Advance payment on orders, debt on invoices and Advance payment on Contracts, debt on invoices 
	// , we do not display settlement objects orders and Contracts from the invoice, and we do not display invoice settlement objects from the order, since they are already taken into account in the order,
	If PaymentByDocument <> Undefined Then
		For Each PaymentsByARAPObject In PaymentByDocument Do
			If PaymentsByARAPObject.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice
					And PaymentsByARAPObject.Document <> PaymentsByARAPObject.CalculationObjectObject
				Or PaymentsByARAPObject.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice
					And PaymentsByARAPObject.Document <> PaymentsByARAPObject.CalculationObjectObject
					And TypeOf(PaymentsByARAPObject.CalculationObjectObject) <> Type("CatalogRef.CounterpartyContracts") Then
				Continue;
			EndIf;
			ARAPObjects.Add(PaymentsByARAPObject.ARAPObject);
		EndDo;
	EndIf;
	If ShipmentsByDocument <> Undefined Then
		For Each ShipmentsAccordingToPaymentARAPObject In ShipmentsByDocument Do
			If ShipmentsAccordingToPaymentARAPObject.ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice
					And ShipmentsAccordingToPaymentARAPObject.Document <> ShipmentsAccordingToPaymentARAPObject.CalculationObjectObject 
				Or ShipmentsAccordingToPaymentARAPObject.ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice
					And ShipmentsAccordingToPaymentARAPObject.Document <> ShipmentsAccordingToPaymentARAPObject.CalculationObjectObject
					And TypeOf(ShipmentsAccordingToPaymentARAPObject.CalculationObjectObject) <> Type("CatalogRef.CounterpartyContracts") Then
				Continue;
			EndIf;
			ARAPObjects.Add(ShipmentsAccordingToPaymentARAPObject.ARAPObject);
		EndDo;
	EndIf;
	ARAPObjects = CommonClientServer.CollapseArray(ARAPObjects);
	
	OutputIndentation_ = False;
	HasData = False;
	For Each ARAPObject In ARAPObjects Do
		
		PaymentsByARAPObject = Undefined;
		If TableOfPayment <> Undefined Then
			PaymentLinesForARAPObject = TableOfPayment.Rows.FindRows(New Structure("Document, ARAPObject", Document, ARAPObject));
			If PaymentLinesForARAPObject.Count() > 0 Then
				PaymentsByARAPObject = PaymentLinesForARAPObject[0];
			EndIf;
		EndIf;
		ShipmentsAccordingToPaymentARAPObject = Undefined;
		If ShipmentTable <> Undefined Then
			ShippingLinesByARAPObject = ShipmentTable.Rows.FindRows(New Structure("Document, ARAPObject", Document, ARAPObject));
			If ShippingLinesByARAPObject.Count() > 0 Then
				ShipmentsAccordingToPaymentARAPObject = ShippingLinesByARAPObject[0];
			EndIf;
		EndIf;
		
		ARAPObjectHasBeenDerived = False;
		If PaymentsByARAPObject <> Undefined Then
			If PaymentsByARAPObject.Rows.Count() > 0 Then
				DisplayShipmentPaymentTableByARAPObject(ReportTable, Template, PaymentsByARAPObject, OutputIndentation_, False, TheseAreSettlementsWithClient, True);
				ARAPObjectHasBeenDerived = True;
				HasData = True;
			EndIf;
		EndIf;
		If ShipmentsAccordingToPaymentARAPObject <> Undefined Then
			If ShipmentsAccordingToPaymentARAPObject.Rows.Count() > 0 Then
				DisplayShipmentPaymentTableByARAPObject(ReportTable, Template, ShipmentsAccordingToPaymentARAPObject, OutputIndentation_, True, TheseAreSettlementsWithClient, Not ARAPObjectHasBeenDerived);
				HasData = True;
			EndIf;
		EndIf;
		OutputIndentation_ = True;
	EndDo;
	
	Return HasData;
	
EndFunction

// Displays a table on payment or shipment in a tabular document
// 
// Parameters:
//  ReportTable - SpreadsheetDocument - Tabular document for output
//  Template - SpreadsheetDocument - report layout
//  CalculationsForDocument - ValueTree - Data to output to the report
//  OutputIndentation_ - Boolean - Display an indent before the current table
//  ThisIsShipment - Boolean - The payment or shipment table is displayed
//  TheseAreSettlementsWithClient - Boolean - Settlements with the client or supplier
Procedure DisplayShipmentPaymentTableByARAPObject(ReportTable, Template, CalculationsForDocument, OutputIndentation_, ThisIsShipment, TheseAreSettlementsWithClient, DisplayARAPObject)
	
	If OutputIndentation_ Then
		
		AreaName = "TableRowLast";
		Area = Template.GetArea(AreaName);
		Area.Parameters.Fill(CalculationsForDocument);
		ReportTable.Put(Area);
		
	EndIf;
	
	If Not ThisIsShipment Then
	
		AreaName = "ARAPObjectSettings";
		Area = Template.GetArea(AreaName);
		Area.Parameters.Fill(CalculationsForDocument);
		ReportTable.Put(Area);
		
	EndIf;
	
	If DisplayARAPObject Then
		AreaName = "ARAPObject";
		Area = Template.GetArea(AreaName);
		Area.Parameters.Fill(CalculationsForDocument);
		Area.Parameters.ParametersStructure = New Structure("OrderDocument, Action", CalculationsForDocument.ARAPObject, "OpenValue");
		ReportTable.Put(Area);
	EndIf;
	
	If ThisIsShipment Then
		If TheseAreSettlementsWithClient Then
			TableHeading = NStr("vi = 'Xuất kho cho khách';
								|ru = 'Отгрузки клиенту';
								|en = 'Shipments to customer'; fa = 'Shipments to customer';
								|it = 'Отгрузки клиенту';
								|pl = 'Shipments to customer';
								|tr = 'Müşteriye sevkiyatlar'");
		Else
			TableHeading = NStr("vi = 'Giao hàng từ nhà cung cấp';
								|ru = 'Поставки от поставщика';
								|en = 'Deliveries from vendor'; fa = 'Deliveries from vendor';
								|it = 'Поставки от поставщика';
								|pl = 'Deliveries from vendor';
								|tr = 'Tedarikçi tedariği'");
		EndIf;
	Else
		If TheseAreSettlementsWithClient Then
			TableHeading = NStr("vi = 'Thanh toán của khách hàng';
								|ru = 'Оплаты клиента';
								|en = 'Payments from customer'; fa = 'Payments from customer';
								|it = 'Оплаты клиента';
								|pl = 'Payments from customer';
								|tr = 'Müşteri ödemeleri'");
		Else
			TableHeading = NStr("vi = 'Thanh toán cho nhà cung cấp';
								|ru = 'Оплаты поставщику';
								|en = 'Payments to vendor'; fa = 'Payments to vendor';
								|it = 'Оплаты поставщику';
								|pl = 'Payments to vendor';
								|tr = 'Tedarikçi ödemeleri'");
		EndIf;
	EndIf; 
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	TitleStructure = New Structure("Title", TableHeading);
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	AreaName = "HeaderOfCalculationsTable";
	Area = Template.GetArea(AreaName);
	Area.Parameters.TitlePaymentShipment = ?(
		ThisIsShipment,
		?(TheseAreSettlementsWithClient,
			NStr("vi = 'Xuất kho (thực tế)';
				|ru = 'Отгрузка (факт)';
				|en = 'Shipment (actual)'; fa = 'ارسال (واقعی)';
				|it = 'Отгрузка (факт)';
				|pl = 'Wysyłka (fakt) ';
				|tr = 'Sevkiyat (gerçek)'"),
			NStr("vi = 'Giao hàng (thực tế)';
				|ru = 'Поставка (факт)';
				|en = 'Delivery (actual)'; fa = 'Delivery (actual)';
				|it = 'Поставка (факт)';
				|pl = 'Delivery (actual)';
				|tr = 'Tedarik (bilgiler)'")),
		NStr("vi = 'Thanh toán (thực tế)';
			|ru = 'Оплата (факт)';
			|en = 'Payment (actual)'; fa = 'پرداخت (واقعی)';
			|it = 'Оплата (факт)';
			|pl = 'Płatność (fakt)';
			|tr = 'Ödeme (gerçek)'"));
	Area.Parameters.TitleShipmentPaymentStage = ?(
		ThisIsShipment,
		?(TheseAreSettlementsWithClient,
			NStr("vi = 'Giai đoạn giao hàng';
				|ru = 'Этап отгрузки';
				|en = 'Shipment step'; fa = 'Shipment step';
				|it = 'Этап отгрузки';
				|pl = 'Shipment step';
				|tr = 'Sevkiyat aşaması'"),
			NStr("vi = 'Giai đoạn giao hàng';
				|ru = 'Этап поставки';
				|en = 'Delivery step'; fa = 'Delivery step';
				|it = 'Этап поставки';
				|pl = 'Delivery step';
				|tr = 'Tedarik aşaması'")),
		NStr("vi = 'Giai đoạn thanh toán';
			|ru = 'Этап оплаты';
			|en = 'Payment milestone'; fa = 'نقطه عطف پرداخت';
			|it = 'Этап оплаты';
			|pl = 'Etap płatności';
			|tr = 'Ödeme aşaması'"));
	ReportTable.Put(Area);
	
	AreaName = "RowOfCalculationTable";
	Area = Template.GetArea(AreaName);
	NameOfCommandLine = "TableCalculationsRow";
	RowArea = Area.Areas[NameOfCommandLine]; // SpreadsheetDocumentRange
	
	EvenString = False;
	
	For Each ShippingPaymentStageLine In CalculationsForDocument.Rows Do
		
		// If there are fact lines, then immediately in the line of the payment/shipment stage we indicate the first date of the fact with the amount
		CombineFactLineWithShipmentPaymentStageLine = False;
		// The Balance is displayed in the last line of the fact at the stage of payment/shipment
		Balance = Undefined;
		If ShippingPaymentStageLine.Rows.Count() > 0 Then
			Balance = New Structure;
			Balance.Insert("Balance",           ShippingPaymentStageLine.Balance);
			Balance.Insert("BalanceIsOverdue", ShippingPaymentStageLine.BalanceIsOverdue);
			Balance.Insert("DaysOverdue_3",    ShippingPaymentStageLine.DaysOverdue_3);
			CombineFactLineWithShipmentPaymentStageLine = True;
		Else
			
			OutputCalculationLine(Area, RowArea, ShippingPaymentStageLine, ReportTable, EvenString, TheseAreSettlementsWithClient); 
			
		EndIf;
		
		For Each FactString In ShippingPaymentStageLine.Rows Do
			
			If CombineFactLineWithShipmentPaymentStageLine Then 
				FillPropertyValues(FactString, ShippingPaymentStageLine, "SumPlan, ScheduleAdjustment");
				CombineFactLineWithShipmentPaymentStageLine = False;
			EndIf;
			
			If ShippingPaymentStageLine.Rows.IndexOf(FactString) + 1 = ShippingPaymentStageLine.Rows.Count() Then
				FillPropertyValues(FactString, Balance);
			EndIf;
			
			OutputCalculationLine(Area, RowArea, FactString, ReportTable, EvenString, TheseAreSettlementsWithClient);
			
		EndDo;
		
	EndDo;
	
	AreaName = "TableRowCalculationsTotal";
	Area = Template.GetArea(AreaName);
	
	Area.Parameters.Fill(CalculationsForDocument);
	Area.Parameters.AmountPlanTotal = CalculationsForDocument.SumPlan;
	Area.Parameters.AmountFactTotal = CalculationsForDocument.SumReal;
	Area.Parameters.ScheduleAdjustmentTotal = CalculationsForDocument.ScheduleAdjustment;
	Area.Parameters.Balance_Total = CalculationsForDocument.Balance;
	Area.Parameters.BalanceOverdueTotal = CalculationsForDocument.BalanceIsOverdue;
	
	ReportTable.Put(Area);
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure OutputCalculationLine(Area, RowArea, CalculationLine_, ReportTable, EvenString, TheseAreSettlementsWithClient)
	
	If EvenString Then
		BackColor = StyleColors.FieldAlternativeBackColor;
	Else
		BackColor = StyleColors.FieldBackColor;
	EndIf;
	
	Area.Parameters.Fill(CalculationLine_);
	Area.Parameters.DaysOverdue_3 = ?(
		ValueIsFilled(CalculationLine_.DaysOverdue_3),
		StrTemplate("%1 %2",
			Format(CalculationLine_.DaysOverdue_3,"NZ=; NG="),
				TMCommonUseClientServer.InPlural(
					NStr("vi = 'ngày';
						|ru = 'дня';
						|en = 'Day'; fa = 'روز';
						|it = 'del giorno';
						|pl = 'dnia';
						|tr = 'gün'"),
					NStr("vi = 'ngày';
						|ru = 'дня';
						|en = 'day'; fa = 'روز';
						|it = 'del giorno';
						|pl = 'dnia';
						|tr = 'gün'"),
					NStr("vi = 'ngày';
						|ru = 'дней';
						|en = 'days'; fa = 'روز';
						|it = 'di giorni';
						|pl = 'dni';
						|tr = 'günler'"),
			CalculationLine_.DaysOverdue_3)),
		"");
	
	If CalculationLine_.ShipmentPaymentOption = Enums.CustomerPaymentControlOptions.EmptyRef()
		Or CalculationLine_.ShipmentPaymentOption = Enums.OptionsForControllingPaymentToSupplier.EmptyRef() Then
		If ValueIsFilled(CalculationLine_.DatePlan) Then
			Area.Parameters.ShipmentPaymentOption = NStr("vi = 'Thanh toán theo lịch biểu hóa đơn';
														|ru = 'Оплата по графику накладной';
														|en = 'Payment according to the invoice schedule'; fa = 'Payment according to the invoice schedule';
														|it = 'Оплата по графику накладной';
														|pl = 'Payment according to the invoice schedule';
														|tr = 'Fatura programına göre ödeme'");
		ElsIf ValueIsFilled(CalculationLine_.DateFact) Then
			Area.Parameters.ShipmentPaymentOption = NStr("vi = 'Thanh toán vượt kế hoạch';
														|ru = 'Оплата сверх плана';
														|en = 'Payment in excess of the plan'; fa = 'Payment in excess of the plan';
														|it = 'Оплата сверх плана';
														|pl = 'Payment in excess of the plan';
														|tr = 'Planı aşan ödeme'");
		Else
			Area.Parameters.ShipmentPaymentOption = NStr("ru = 'Оплачивается';
														|vi = 'Being paid';
														|en = 'Being paid'; fa = 'در حال پرداخت';
														|it = 'Being paid';
														|pl = 'Being paid';
														|tr = 'Ödenecek tutar'");
		EndIf;
	ElsIf TypeOf(CalculationLine_.ShipmentPaymentOption) = Type("Number") Then 
		If CalculationLine_.ShipmentPaymentOption = 1 Then
			Area.Parameters.ShipmentPaymentOption = ?(
			TheseAreSettlementsWithClient,
			NStr("vi = 'Giao hàng theo lịch thanh toán trả trước';
				|ru = 'Отгрузка по графику погашения аванса';
				|en = 'Shipment according to the advance repayment schedule'; fa = 'Shipment according to the advance repayment schedule';
				|it = 'Отгрузка по графику погашения аванса';
				|pl = 'Shipment according to the advance repayment schedule';
				|tr = 'Peşin ödeme planına göre sevkiyat'"),
			NStr("vi = 'Giao hàng theo lịch thanh toán trả trước';
				|ru = 'Поставка по графику погашения аванса';
				|en = 'Delivery according to the advance repayment schedule'; fa = 'Delivery according to the advance repayment schedule';
				|it = 'Поставка по графику погашения аванса';
				|pl = 'Delivery according to the advance repayment schedule';
				|tr = 'Peşin ödeme planına göre tedarik'"));
		ElsIf CalculationLine_.ShipmentPaymentOption = 2 Then
			Area.Parameters.ShipmentPaymentOption = ?(
			TheseAreSettlementsWithClient,
			NStr("vi = 'Giao hàng theo lịch biểu thực hiện hợp đồng';
				|ru = 'Отгрузка по графику исполнения договора';
				|en = 'Shipment under contract schedule'; fa = 'Shipment under contract schedule';
				|it = 'Отгрузка по графику исполнения договора';
				|pl = 'Shipment under contract schedule';
				|tr = 'Sözleşme programına göre sevkiyat'"),
			NStr("vi = 'Giao hàng theo lịch biểu thực hiện hợp đồng';
				|ru = 'Поставка по графику исполнения договора';
				|en = 'Delivery under the contract schedule'; fa = 'Delivery under the contract schedule';
				|it = 'Поставка по графику исполнения договора';
				|pl = 'Delivery under the contract schedule';
				|tr = 'Sözleşme programına göre tedarik'"));
		ElsIf CalculationLine_.ShipmentPaymentOption = 3 Then
			Area.Parameters.ShipmentPaymentOption = ?(
			TheseAreSettlementsWithClient,
			NStr("vi = 'Giao hàng theo lịch biểu của đơn hàng';
				|ru = 'Отгрузка по графику заказа';
				|en = 'Shipment under the order schedule'; fa = 'Shipment under the order schedule';
				|it = 'Отгрузка по графику заказа';
				|pl = 'Shipment under the order schedule';
				|tr = 'Sipariş programına göre sevkiyat'"),
			NStr("vi = 'Giao hàng theo lịch biểu của đơn hàng';
				|ru = 'Поставка по графику заказа';
				|en = 'Delivery under the order schedule'; fa = 'Delivery under the order schedule';
				|it = 'Поставка по графику заказа';
				|pl = 'Delivery under the order schedule';
				|tr = 'Sipariş programına göre tedarik'"));
		ElsIf CalculationLine_.ShipmentPaymentOption = 4 Then
			Area.Parameters.ShipmentPaymentOption = ?(
			TheseAreSettlementsWithClient,
			NStr("vi = 'Giao hàng vượt quá kế hoạch';
				|ru = 'Отгрузка сверх плана';
				|en = 'Shipment in excess of the plan'; fa = 'Shipment in excess of the plan';
				|it = 'Отгрузка сверх плана';
				|pl = 'Shipment in excess of the plan';
				|tr = 'Planı aşan sevkiyatlar'"),
			NStr("vi = 'Giao hàng vượt quá kế hoạch';
				|ru = 'Поставка сверх плана';
				|en = 'Delivery in excess of the plan'; fa = 'Delivery in excess of the plan';
				|it = 'Поставка сверх плана';
				|pl = 'Delivery in excess of the plan';
				|tr = 'Planı aşan tedarik'"));
			// For the line over the order, we do not display the fact date, since the date of the last invoice
			// is not guaranteed to be the one in which there were lines over the order.
			Area.Parameters.DateFact = "";
		ElsIf CalculationLine_.ShipmentPaymentOption = 5 Then
			Area.Parameters.ShipmentPaymentOption = ?(
			TheseAreSettlementsWithClient,
			NStr("vi = 'Giao hàng';
				|ru = 'Отгрузка';
				|en = 'Shipment'; fa = 'ارسال';
				|it = 'Отгрузка';
				|pl = 'Shipment';
				|tr = 'Sevkiyat'"),
			NStr("vi = 'Giao hàng';
				|ru = 'Поставка';
				|en = 'Delivery'; fa = 'تحویل';
				|it = 'Поставка';
				|pl = 'Delivery';
				|tr = 'Tedarik'"));
		EndIf;
	EndIf;
	
	RowArea.BackColor = BackColor;
	
	ReportTable.Put(Area);
	EvenString = Not EvenString;

EndProcedure

#EndRegion

Function QueryTextTablePaymentSchedules(TableName, ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("PaymentScheduleTable") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableCustomersARAPAccounting;
	EndIf;
	
	If ParametersStructure.ThisIsOrder Then
		
		PaymentAmount = "DocumentPaymentScheduleSteps.PaymentAmount + DocumentPaymentScheduleSteps.PackageDepositValue";
		If TableName = "Document.SubcontractOrder2_5"
			Or False Then
			PaymentAmount = "DocumentPaymentScheduleSteps.PaymentAmount";
		EndIf; 
		If TableName = "Document.MaterialProviderOrder2_5"
			Or False Then
			PaymentAmount = "DocumentPaymentScheduleSteps.PaymentAmount";
		EndIf; 
		QueryText = "
		|SELECT ALLOWED
		|	DocumentPaymentScheduleSteps.Ref AS Document,
		|	DocumentPaymentScheduleSteps.LineNumber,
		|	PRESENTATION(DocumentPaymentScheduleSteps.PaymentOption) AS PaymentOption,
		|	DocumentPaymentScheduleSteps.PaymentDate,
		|	&PaymentAmount AS PaymentAmount
		|FROM
		|	&TableName AS DocumentPaymentScheduleSteps
		|		INNER JOIN ARAPObjects AS ARAPObjects
		|		ON (ARAPObjects.CalculationObjectObject = DocumentPaymentScheduleSteps.Ref)
		|		AND ARAPObjects.ScheduleIsRequired";
		
		QueryText = StrReplace(QueryText, "&PaymentAmount", PaymentAmount);
		QueryText = StrReplace(QueryText, "&TableName", TableName + ".PaymentScheduleSteps");
		
	ElsIf ParametersStructure.ThisIsAnInvoice Then
		
		If ValueIsFilled(StructureOfAdditionalRequests)
			And StructureOfAdditionalRequests.Property("TableScheduleOfPaymentByInvoice") Then
			
			QueryText = StructureOfAdditionalRequests.TableScheduleOfPaymentByInvoice;
			
		ElsIf TableName = "Document.CustomerInvoice"
			Or TableName = "Document.CustomerInvoiceServices" 
			Or TableName = "Document.VendorInvoice"
			Or TableName = "Document.SubcontractorReport2_5"
			Or TableName = "Document.ReportToMaterialProvider2_5"
			Then
			
			QueryText = "
			|SELECT
			|	DocumentPaymentScheduleSteps.Ref                       AS Document,
			|	DocumentPaymentScheduleSteps.LineNumber                  AS LineNumber,
			|	PRESENTATION(DocumentPaymentScheduleSteps.PaymentOption) AS PaymentOption,
			|	DocumentPaymentScheduleSteps.PaymentDate                  AS PaymentDate,
			|	DocumentPaymentScheduleSteps.PaymentAmount                 AS PaymentAmount
			|FROM
			|	&TableName AS DocumentPaymentScheduleSteps
			|		INNER JOIN ARAPObjects AS ARAPObjects
			|		ON (ARAPObjects.CalculationObjectObject = DocumentPaymentScheduleSteps.Ref)
			|		AND ARAPObjects.ScheduleIsRequired";

			QueryText = StrReplace(QueryText, "&TableName", TableName + ".PaymentScheduleSteps");
			
		Else
			
			QueryText = "
			|SELECT ALLOWED
			|	DocumentInvoice.Ref AS Document,
			|	1 AS LineNumber,
			|	PRESENTATION(VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment))  AS PaymentOption,
			|	DocumentInvoice.PaymentDate AS PaymentDate,
			|	DocumentInvoice.DocumentAmount AS PaymentAmount
			|FROM
			|	&TableName AS DocumentInvoice
			|		INNER JOIN ARAPObjects AS ARAPObjects
			|		ON (ARAPObjects.CalculationObjectObject = DocumentInvoice.Ref)
			|		AND ARAPObjects.ScheduleIsRequired";

			QueryText = StrReplace(QueryText, "&TableName", TableName);
		
		EndIf;
		
		If TableName = "Document.CustomerInvoice"
			Or TableName = "Document.CustomerInvoiceServices" Then
			
			QueryText = QueryText + RequestTextForPaymentSchedulePaymentObject("SalesOrder");
			QueryText = QueryText + RequestTextForPaymentSchedulePaymentObject("RequestForReturnOfGoodsFromCustomer");
			
		EndIf;
		
		If TableName = "Document.VendorInvoice" Then
			
			QueryText = QueryText + RequestTextForPaymentSchedulePaymentObject("PurchaseOrder");
			
		EndIf;
		
	ElsIf ParametersStructure.Property("ThisIsContract") And ParametersStructure.ThisIsContract Then
		
		QueryText = "
		|SELECT ALLOWED
		|	DocumentPaymentScheduleSteps.Ref.Contract AS Document,
		|	DocumentPaymentScheduleSteps.LineNumber,
		|	DocumentPaymentScheduleSteps.PaymentOption AS PaymentOption,
		|	DocumentPaymentScheduleSteps.PaymentDate AS PaymentDate,
		|	DocumentPaymentScheduleSteps.PaymentAmount AS PaymentAmount
		|FROM
		|	&TableName AS DocumentPaymentScheduleSteps
		|		INNER JOIN ARAPObjects AS ARAPObjects
		|		ON ARAPObjects.CalculationObjectObject = DocumentPaymentScheduleSteps.Ref.Contract
		|";
		
		QueryText = StrReplace(QueryText, "&TableName", TableName + ".PaymentScheduleSteps");
		
	EndIf;
	
	QueryText = QueryText + "
	|
	|TOTALS BY
	|	Ref;";
	
	Return QueryText

EndFunction

Function RequestTextForPaymentSchedulePaymentObject(DocumentName)

	If Not AccessRight("Read", Metadata.Documents.Find(DocumentName)) Then
		Return "";
	EndIf;
	
	QueryText = "
	|UNION ALL
	|
	|SELECT
	|	DocumentPaymentScheduleSteps.Ref AS Document,
	|	DocumentPaymentScheduleSteps.LineNumber,
	|	PRESENTATION(DocumentPaymentScheduleSteps.PaymentOption) AS PaymentOption,
	|	DocumentPaymentScheduleSteps.PaymentDate,
	|	DocumentPaymentScheduleSteps.PaymentAmount + DocumentPaymentScheduleSteps.PackageDepositValue AS PaymentAmount
	|FROM
	|	&TableName AS DocumentPaymentScheduleSteps
	|		INNER JOIN ARAPObjects AS ARAPObjects
	|		ON (ARAPObjects.CalculationObjectObject = DocumentPaymentScheduleSteps.Ref)
	|		AND ARAPObjects.ScheduleIsRequired";
		
	QueryText = StrReplace(QueryText, "&TableName","Document." + DocumentName + ".PaymentScheduleSteps");
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDataOnSettlementsWithCustomers(TableName, ParametersStructure)
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("TTDataOnSettlementsWithCustomers") Then
		
		Return StructureOfAdditionalRequests.TTDataOnSettlementsWithCustomers;
	EndIf;
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SettlementsData.ARAPObject AS ARAPObject,
	|	SettlementsData.Period AS Period,
	|	SUM(SettlementsData.PaymentPlan) AS PaymentPlan,
	|	SUM(SettlementsData.PaymentFact) AS PaymentFact
	|INTO TTDataOnSettlementsWithCustomers
	|FROM
	|	(SELECT
	|		CustomersARAPAccounting.ARAPObject AS ARAPObject,
	|		BEGINOFPERIOD(CASE WHEN CustomersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|					THEN CustomersARAPAccounting.RecorderDate
	|					ELSE CustomersARAPAccounting.Period
	|					END, DAY) AS Period,
	|		CustomersARAPAccounting.BusinessOperation AS BusinessOperation,
	|		CASE
	|			WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			AND NOT CustomersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|			AND NOT CustomersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
	|			AND NOT CustomersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|				THEN CustomersARAPAccounting.AmountDue
	|			WHEN CustomersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|				AND NOT CustomersARAPAccounting.ARAPObject.Object = CustomersARAPAccounting.Recorder
	|				AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND CustomersARAPAccounting.Recorder REFS Document.CustomerInvoice
	|					THEN -CustomersARAPAccounting.AmountDue
	|			WHEN CustomersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|					THEN CASE
	|							WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|							THEN CustomersARAPAccounting.AmountDue
	|							ELSE -CustomersARAPAccounting.AmountDue
	|					END
	|			ELSE 0
	|		END AS PaymentPlan,
	|		CASE
	|			WHEN CustomersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|				THEN CASE
	|					WHEN CustomersARAPAccounting.CorARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
	|						AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						THEN -CustomersARAPAccounting.Sum
	|					WHEN CustomersARAPAccounting.CorARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
	|						AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|						THEN CustomersARAPAccounting.Sum
	|					ELSE CustomersARAPAccounting.Sum
	|				END
	|			ELSE CASE
	|					WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						OR CustomersARAPAccounting.Recorder REFS Document.SaleAdjustment
	|						OR CustomersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
	|					THEN 0
	|					ELSE CustomersARAPAccounting.Sum
	|				END
	|		END AS PaymentFact
	|	FROM
	|		ARAPObjects AS ARAPObjects
	|		LEFT JOIN Catalog.ARAPObjects AS CatalogARAPObjects
	|			ON ARAPObjects.CalculationObjectObject = CatalogARAPObjects.Object
	|			AND NOT CatalogARAPObjects.DeletionMark
	|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|		ON CatalogARAPObjects.Ref = CustomersARAPAccounting.ARAPObject
	|	WHERE 
	|		CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
	|	) AS SettlementsData
	|
	|	GROUP BY
	|	SettlementsData.Period,
	|	SettlementsData.ARAPObject
	|;";
	
	Return QueryText;

EndFunction

Function QueryTextTableCustomersARAPAccounting(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableCustomersARAPAccounting") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableCustomersARAPAccounting;
	EndIf;
	
	QueryText = "
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ARAPObjects.Document AS Document,
		|	CustomersARAPAccounting.ARAPObject.Object AS ARAPObject,
		|	ARAPObjects.ARAPObjectSettings AS ARAPObjectSettings,
		|	CustomersARAPAccounting.Currency AS Currency,
		|	ARAPObjects.ScheduleIsRequired AS ScheduleIsRequired,
		|	CASE
		|		WHEN DataOnXOCalculations.PaymentPlan > 0
		|			THEN CAST(""PaymentOnSchedule"" AS STRING(150))
		|		WHEN DataOnXOCalculations.PaymentPlan < 0
		|			THEN CAST(""SettlementOfPrepayment"" AS STRING(150))
		|		ELSE CASE
		|			WHEN DataOnXOCalculations.PaymentFact <> 0
		|				THEN CAST(""NotScheduledPayment"" AS STRING(150))
		|			ELSE CAST(""Shipment"" AS STRING(150))
		|		END
		|	END AS ShipmentPaymentStage,
		|	CustomersARAPAccounting.Period AS PaymentDate,
		|	CASE WHEN ARAPObjects.ScheduleIsRequired
		|			THEN ISNULL(DataOnXOCalculations.PaymentPlan, 0)
		|			ELSE 0
		|	END AS PaymentPlan,
		|	ISNULL(DataOnXOCalculations.PaymentFact, 0) AS PaymentFact,
		|	CASE
		|		WHEN CustomersARAPAccounting.Period < &CurrentDate
		|		AND CustomersARAPAccounting.AmountDueClosingBalance > 0
		|			THEN CustomersARAPAccounting.AmountDueClosingBalance
		|		ELSE 0
		|	END AS Overdue_Payment,
		|	CASE
		|		WHEN ISNULL(CustomersARAPAccountingBalance.AmountDueBalance, 0) - ISNULL(SettlementsWithCustomersTurnover.AmountDueExpense, 0) > 0
		|			THEN ISNULL(CustomersARAPAccountingBalance.AmountDueBalance, 0) - ISNULL(SettlementsWithCustomersTurnover.AmountDueExpense, 0)
		|		ELSE 0
		|	END AS PaymentOverdueTotal,
		|	CustomersARAPAccounting.ToShipExpense AS ShippingPlan,
		|	CustomersARAPAccounting.ToShipReceipt AS ShippingFact,
		|	CASE
		|		WHEN CustomersARAPAccounting.Period < &CurrentDate
		|		AND CustomersARAPAccounting.ToShipClosingBalance < 0
		|			THEN -CustomersARAPAccounting.ToShipClosingBalance
		|		ELSE 0
		|	END AS ShipmentOverdue_,
		|	CASE
		|		WHEN ISNULL(-CustomersARAPAccountingBalance.ToShipBalance, 0) - ISNULL(SettlementsWithCustomersTurnover.ToShipReceipt,
		|			0) > 0
		|			THEN ISNULL(-CustomersARAPAccountingBalance.ToShipBalance, 0) - ISNULL(SettlementsWithCustomersTurnover.ToShipReceipt,
		|				0)
		|		ELSE 0
		|	END AS ShipmentOverdueTotal
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.BalanceAndTurnovers(
		|			,
		|			,
		|			Day,
		|			,
		|			ARAPObject IN
		|				(SELECT
		|					ARAPObjects.ARAPObject
		|				FROM
		|					ARAPObjects AS ARAPObjects)) AS CustomersARAPAccounting
		|		LEFT JOIN ARAPObjects AS ARAPObjects
		|		ON (ARAPObjects.ARAPObject = CustomersARAPAccounting.ARAPObject)
		|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(
		|				&CurrentDate,
		|				ARAPObject IN
		|					(SELECT
		|						ARAPObjects.ARAPObject
		|					FROM
		|						ARAPObjects AS ARAPObjects)) AS CustomersARAPAccountingBalance
		|		ON CustomersARAPAccounting.ARAPObject = CustomersARAPAccountingBalance.ARAPObject
		|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Turnovers(
		|				&CurrentDate,
		|				,
		|				,
		|				ARAPObject IN
		|					(SELECT
		|						ARAPObjects.ARAPObject
		|					FROM
		|						ARAPObjects AS ARAPObjects)) AS SettlementsWithCustomersTurnover
		|		ON (CustomersARAPAccounting.ARAPObject = CustomersARAPAccountingBalance.ARAPObject)
		|		LEFT JOIN TTDataOnSettlementsWithCustomers AS DataOnXOCalculations
		|		ON CustomersARAPAccounting.ARAPObject = DataOnXOCalculations.ARAPObject
		|		AND CustomersARAPAccounting.Period = DataOnXOCalculations.Period
		|ORDER BY
		|	CustomersARAPAccounting.Period
		|TOTALS
		|	MAX(ARAPObjectSettings),
		|	MAX(Currency),
		|	MAX(ScheduleIsRequired),
		|	SUM(PaymentPlan),
		|	SUM(PaymentFact),
		|	MAX(PaymentOverdueTotal),
		|	SUM(ShippingPlan),
		|	SUM(ShippingFact),
		|	MAX(ShipmentOverdueTotal)
		|BY
		|	Document,
		|	ARAPObject
		|;";


	Return QueryText
	
EndFunction

Function QueryTextTTDataOnSettlementsWithSuppliers(TableName, ParametersStructure)
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("TTDataOnSettlementsWithSuppliers") Then
		
		Return StructureOfAdditionalRequests.TTDataOnSettlementsWithSuppliers;
	EndIf;
	
	QueryText = "
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	SettlementsData.ARAPObject AS ARAPObject,
		|	SettlementsData.Period AS Period,
		|	SUM(SettlementsData.PaymentPlan) AS PaymentPlan,
		|	SUM(SettlementsData.PaymentFact) AS PaymentFact
		|INTO TTDataOnSettlementsWithSuppliers
		|FROM
		|	(SELECT
		|		VendorsARAPAccounting.ARAPObject AS ARAPObject,
		|		BEGINOFPERIOD(CASE WHEN VendorsARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
		|					THEN VendorsARAPAccounting.RecorderDate
		|					ELSE VendorsARAPAccounting.Period
		|				END, DAY) AS Period,
		|		CASE
		|			WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|			AND NOT VendorsARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
		|			AND NOT VendorsARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
		|				THEN VendorsARAPAccounting.AmountDue
		|			WHEN VendorsARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
		|				AND NOT VendorsARAPAccounting.ARAPObject.Object = VendorsARAPAccounting.Recorder
		|				AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|					THEN -VendorsARAPAccounting.AmountDue
		|			WHEN VendorsARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
		|					THEN CASE
		|							WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|							THEN VendorsARAPAccounting.AmountDue
		|							ELSE -VendorsARAPAccounting.AmountDue
		|					END
		|			ELSE 0
		|		END AS PaymentPlan,
		|		CASE
		|			WHEN VendorsARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
		|				THEN CASE
		|						WHEN NOT VendorsARAPAccounting.CorARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
		|							THEN VendorsARAPAccounting.Sum
		|							ELSE -VendorsARAPAccounting.Sum
		|						END
		|				ELSE CASE
		|						WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|							OR VendorsARAPAccounting.Recorder REFS Document.PurchaseAdjustment
		|							THEN 0
		|							ELSE VendorsARAPAccounting.Sum
		|						END
		|			END AS PaymentFact
		|	FROM
		|		ARAPObjects AS ARAPObjects
		|		LEFT JOIN Catalog.ARAPObjects AS CatalogARAPObjects
		|			ON ARAPObjects.CalculationObjectObject = CatalogARAPObjects.Object
		|			AND NOT CatalogARAPObjects.DeletionMark
		|		LEFT JOIN AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
		|		ON CatalogARAPObjects.Ref = VendorsARAPAccounting.ARAPObject
		|	WHERE 
		|		VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
		|	) AS SettlementsData
		|	GROUP BY
		|	SettlementsData.Period,
		|	SettlementsData.ARAPObject
		|;";
	
	Return QueryText;

EndFunction

Function QueryTextTableVendorsARAPAccounting(ParametersStructure)
	
	StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
	
	If ValueIsFilled(StructureOfAdditionalRequests)
		And StructureOfAdditionalRequests.Property("QueryTextTableVendorsARAPAccounting") Then
		
		Return StructureOfAdditionalRequests.QueryTextTableVendorsARAPAccounting;
	EndIf;
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ARAPObjects.Document AS Document,
	|	VendorsARAPAccounting.ARAPObject.Object AS ARAPObject,
	|	ARAPObjects.ARAPObjectSettings AS ARAPObjectSettings,
	|	VendorsARAPAccounting.Currency AS Currency,
	|	ARAPObjects.ScheduleIsRequired,
	|	CASE
	|		WHEN DataOnXOCalculations.PaymentPlan > 0
	|			THEN CAST(""PaymentOnSchedule"" AS STRING(150))
	|		WHEN DataOnXOCalculations.PaymentPlan < 0
	|			THEN CAST(""SettlementOfPrepayment"" AS STRING(150))
	|		ELSE CASE
	|			WHEN DataOnXOCalculations.PaymentFact <> 0
	|				THEN CAST(""NotScheduledPayment"" AS STRING(150))
	|			ELSE CAST(""Inpayment"" AS STRING(150))
	|		END
	|	END AS ShipmentPaymentStage,
	|	VendorsARAPAccounting.Period AS PaymentDate,
	|	ISNULL(DataOnXOCalculations.PaymentPlan, 0) AS PaymentPlan,
	|	ISNULL(DataOnXOCalculations.PaymentFact, 0) AS PaymentFact,
	|	CASE
	|		WHEN VendorsARAPAccounting.Period < &CurrentDate
	|				AND VendorsARAPAccounting.AmountDueClosingBalance < 0
	|			THEN -VendorsARAPAccounting.AmountDueClosingBalance
	|		ELSE 0
	|	END AS Overdue_Payment,
	|	CASE
	|		WHEN ISNULL(SettlementsWithSuppliersTurnover.AmountDueReceipt, 0) + ISNULL(VendorsARAPAccountingBalance.AmountDueBalance, 0) < 0
	|			THEN -(ISNULL(SettlementsWithSuppliersTurnover.AmountDueReceipt, 0) + ISNULL(VendorsARAPAccountingBalance.AmountDueBalance, 0))
	|		ELSE 0
	|	END AS PaymentOverdueTotal,
	|	VendorsARAPAccounting.ToReceiveExpense AS ShippingFact,
	|	VendorsARAPAccounting.ToReceiveReceipt AS ShippingPlan,
	|	CASE
	|		WHEN VendorsARAPAccounting.Period < &CurrentDate
	|				AND VendorsARAPAccounting.ToReceiveClosingBalance > 0
	|			THEN VendorsARAPAccounting.ToReceiveClosingBalance
	|		ELSE 0
	|	END AS ShipmentOverdue_,
	|	CASE
	|		WHEN ISNULL(VendorsARAPAccountingBalance.ToReceiveBalance, 0) - ISNULL(SettlementsWithSuppliersTurnover.ToReceiveExpense, 0) > 0 THEN
	|			ISNULL(VendorsARAPAccountingBalance.ToReceiveBalance, 0) - ISNULL(SettlementsWithSuppliersTurnover.ToReceiveExpense, 0)
	|		ELSE
	|			0
	|	END AS ShipmentOverdueTotal
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.BalanceAndTurnovers(
	|			,
	|			,
	|			Day,
	|			,
	|			ARAPObject IN
	|				(SELECT
	|					ARAPObjects.ARAPObject
	|				FROM
	|					ARAPObjects AS ARAPObjects)) AS VendorsARAPAccounting
	|		LEFT JOIN ARAPObjects AS ARAPObjects
	|		ON (ARAPObjects.ARAPObject = VendorsARAPAccounting.ARAPObject)
	|		LEFT JOIN AccumulationRegister.VendorsARAPAccounting.Balance(
	|				&CurrentDate,
	|				ARAPObject IN
	|					(SELECT
	|						ARAPObjects.ARAPObject
	|					FROM
	|						ARAPObjects AS ARAPObjects)) AS VendorsARAPAccountingBalance
	|		ON VendorsARAPAccounting.ARAPObject = VendorsARAPAccountingBalance.ARAPObject
	|		LEFT JOIN AccumulationRegister.VendorsARAPAccounting.Turnovers(
	|				&CurrentDate,
	|				,
	|				,
	|				ARAPObject IN
	|					(SELECT
	|						ARAPObjects.ARAPObject
	|					FROM
	|						ARAPObjects AS ARAPObjects)) AS SettlementsWithSuppliersTurnover
	|		ON VendorsARAPAccounting.ARAPObject = VendorsARAPAccountingBalance.ARAPObject
	|		LEFT JOIN TTDataOnSettlementsWithSuppliers AS DataOnXOCalculations
	|		ON VendorsARAPAccounting.ARAPObject = DataOnXOCalculations.ARAPObject
	|		AND VendorsARAPAccounting.Period = DataOnXOCalculations.Period
	|ORDER BY
	|	VendorsARAPAccounting.Period
	|TOTALS
	|	MAX(Currency),
	|	MAX(ARAPObjectSettings),
	|	SUM(PaymentPlan),
	|	SUM(PaymentFact),
	|	MAX(PaymentOverdueTotal),
	|	SUM(ShippingPlan),
	|	SUM(ShippingFact),
	|	MAX(ShipmentOverdueTotal),
	|	MAX(ScheduleIsRequired)
	|BY
	|	Document,
	|	ARAPObject
	|;";
	
	Return QueryText
	
EndFunction

Function OutputCalculationTable(ReportTable, Template, Document, ResultTables, TableName)
	Var CalculationTable;
	
	If Not ResultTables.Property(TableName, CalculationTable) Then
		Return False;
	EndIf;
	
	DocumentArrears = CalculationTable.Rows.Find(Document, "Document");
	If DocumentArrears = Undefined Then
		Return False;
	EndIf;
	
	ThisIsShipment = (TableName = "TableSettlementsWithCustomers");
	
	OutputIndentation_ = False;
	For Each DebtOnObjectOfSettlements In DocumentArrears.Rows Do 
		
		ScheduleIsRequired = DebtOnObjectOfSettlements.ScheduleIsRequired;
		
		If ScheduleIsRequired Then
			
			If Not ResultTables.Property("PaymentScheduleTable") Then
				Return False;
			EndIf;
			
			PaymentSchedule = ResultTables.PaymentScheduleTable.Rows.Find(DebtOnObjectOfSettlements.ARAPObject, "Document");
			If PaymentSchedule = Undefined Then
				Return False;
			EndIf;
			
			DateOfPreviousStage = Date(1,1,1);
			StageName_ = "";
			ScheduledPaymentsForDay = 0;
			
			For Each PaymentScheduleStage In PaymentSchedule.Rows Do
				
				PaymentDate = BegOfDay(PaymentScheduleStage.PaymentDate);
				
				If DateOfPreviousStage = PaymentDate Then
					ScheduledPaymentsForDay = ScheduledPaymentsForDay + PaymentScheduleStage.PaymentAmount;
					If StrOccurrenceCount(StageName_, PaymentScheduleStage.PaymentOption) = 0 Then
						StageName_  = ?(IsBlankString(StageName_), PaymentScheduleStage.PaymentOption, StageName_ + Chars.LF + PaymentScheduleStage.PaymentOption);
					EndIf;
				Else
					ScheduledPaymentsForDay = PaymentScheduleStage.PaymentAmount;
					StageName_ = PaymentScheduleStage.PaymentOption;
				EndIf;
				DateOfPreviousStage = PaymentDate;
				
				FoundCalculationLines = DebtOnObjectOfSettlements.Rows.FindRows(New Structure("PaymentDate, PaymentPlan",
				                                                                            PaymentDate,
				                                                                            ScheduledPaymentsForDay));
				
				If FoundCalculationLines.Count() > 0 Then
					For Each FoundCalculationString In FoundCalculationLines Do
						If TrimAll(FoundCalculationString.ShipmentPaymentStage) = "PaymentOnSchedule" Then
							FoundCalculationString.ShipmentPaymentStage = StageName_;
							Break;
						EndIf;
					EndDo;
				EndIf;
			EndDo;
			
			DistributePaymentsAccordingToSchedule(DebtOnObjectOfSettlements.Rows, PaymentSchedule.Rows);
			
		EndIf;
		
		DisplayCalculationTableForCalculationObject(ReportTable, Template, DebtOnObjectOfSettlements, OutputIndentation_, ThisIsShipment);
		OutputIndentation_ = True;
	EndDo;
	
	Return True;
	
EndFunction

Procedure DisplayCalculationTableForCalculationObject(ReportTable, Template, DocumentArrears, OutputIndentation_, ThisIsShipment)
	
	If OutputIndentation_ Then
		
		AreaName = "TableRowLast";
		Area = Template.GetArea(AreaName);
		Area.Parameters.Fill(DocumentArrears);
		ReportTable.Put(Area);
		
	EndIf;
	
	AreaName = "ARAPObjectSettings";
	Area = Template.GetArea(AreaName);
	Area.Parameters.Fill(DocumentArrears);
	ReportTable.Put(Area);
	
	AreaName = "ARAPObject";
	Area = Template.GetArea(AreaName);
	Area.Parameters.Fill(DocumentArrears);
	Area.Parameters.ParametersStructure = New Structure("OrderDocument, Action", DocumentArrears.ARAPObject, "OpenValue");
	ReportTable.Put(Area);
	
	If ThisIsShipment Then
		TableHeading = NStr("vi = 'Công nợ của khách hàng ';
							|ru = 'Задолженность клиента';
							|en = 'Payments reconciliation'; fa = 'Payments reconciliation';
							|it = 'Debito del cliente';
							|pl = 'Zadłużenie klienta';
							|tr = 'Müşterinin açık hesap kalemleri'");
	Else
		TableHeading = NStr("vi = 'Nợ của chúng tôi';
							|ru = 'Наша задолженность';
							|en = 'Payments / Invoices reconciliation'; fa = 'Payments / Invoices reconciliation';
							|it = 'Nostro debito';
							|pl = 'Nasze zadłużenie';
							|tr = 'Bizim borçlar'");
	EndIf; 
	
	AreaName = "TableHeading";
	Area = Template.GetArea(AreaName);
	TitleStructure = New Structure("Title", TableHeading);
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	AreaName = "HeaderOfDebtTable";
	Area = Template.GetArea(AreaName);
	Area.Parameters.TitleShipmentReceipt = ?(ThisIsShipment, NStr("vi = 'Xuất kho';
																	|ru = 'Отгрузка';
																	|en = 'Shipment'; fa = 'ارسال';
																	|it = 'Spedizione';
																	|pl = 'Wysyłka';
																	|tr = 'Sevkiyat'"), NStr("vi = 'Tiếp nhận';
																							|ru = 'Поступление';
																							|en = 'Receipt'; fa = 'دریافت';
																							|it = 'Arrivo';
																							|pl = 'Wpływ';
																							|tr = 'Tahsilat'"));
	Area.Parameters.TitlePaymentStage = ?(ThisIsShipment, NStr("vi = 'Giai đoạn thanh toán / giao hàng';
																|ru = 'Этап оплаты/отгрузки';
																|en = 'Payment/shipment step'; fa = 'Payment/shipment step';
																|it = 'Fase di pagamento/di spedizione';
																|pl = 'Etap płatności/wysyłki';
																|tr = 'Ödemeler/sevkiyatlar aşaması'"), NStr("vi = 'Giai đoạn thanh toán / tiếp nhận';
																									|ru = 'Этап оплаты/поступления';
																									|en = 'Payment/receipt step'; fa = 'Payment/receipt step';
																									|it = 'Fase di pagamento/di arrivo';
																									|pl = 'Etap płatności/wpływu';
																									|tr = 'Ödemeler/tahsilatlar aşaması'"));
	ReportTable.Put(Area);
	
	AreaName = "RowOfDebtTable";
	Area = Template.GetArea(AreaName);
	NameOfCommandLine = "TableDebtRow";
	RowArea = Area.Areas[NameOfCommandLine]; // SpreadsheetDocumentRange
	
	EvenString = False;
	FieldAlternativeBackColor = StyleColors.FieldAlternativeBackColor;
	FieldBackColor               = StyleColors.FieldBackColor;
	
	For Each RowArrears In DocumentArrears.Rows Do
		
		Area.Parameters.Fill(RowArrears);
		Area.Parameters.ShipmentPaymentStage = StageOfPaymentForShipmentByLine(RowArrears.ShipmentPaymentStage);
		
		RowArea.BackColor = ?(EvenString, FieldAlternativeBackColor, FieldBackColor);
		
		ReportTable.Put(Area);
		EvenString = Not EvenString;
		
	EndDo; 
	
	AreaName = "TableRowDebtTotal";
	Area = Template.GetArea(AreaName);
	
	Area.Parameters.Fill(DocumentArrears);
	Area.Parameters.PaymentPlanTotal = DocumentArrears.PaymentPlan;
	Area.Parameters.PaymentFactTotal = DocumentArrears.PaymentFact;
	Area.Parameters.ShipmentPlanTotal = DocumentArrears.ShippingPlan;
	Area.Parameters.ShipmentFactTotal = DocumentArrears.ShippingFact;
	
	ReportTable.Put(Area);
	
	ReportTable.EndRowGroup();
	
EndProcedure

Procedure DistributePaymentsAccordingToSchedule(Payments, ScheduleStages)
	
	NumberOfStagesOfPaymentSchedule = ScheduleStages.Count();
	If NumberOfStagesOfPaymentSchedule = 0 Then
		Return;
	EndIf;
	
	ArrayOfRowsWithActualPayments = New Array;
	ThereArePaymentsNotOnSchedule = False;
	For Each Payment In Payments Do
		If Payment.PaymentFact <> 0 Then
			ArrayOfRowsWithActualPayments.Add(Payment);
			If Payment.ShipmentPaymentStage = "NotScheduledPayment" Then
				ThereArePaymentsNotOnSchedule = True;
			EndIf;
		EndIf;
	EndDo;
	
	If Not ThereArePaymentsNotOnSchedule Then
		Return;
	EndIf;
	
	CurLineOfPaymentSchedule = 0;
	For Each LineWithActualPayment In ArrayOfRowsWithActualPayments Do
		
		If CurLineOfPaymentSchedule > NumberOfStagesOfPaymentSchedule - 1 Then
			Return;
		EndIf;
		
		If LineWithActualPayment.PaymentFact = ScheduleStages[CurLineOfPaymentSchedule].PaymentAmount Then
			
			If TrimAll(LineWithActualPayment.ShipmentPaymentStage) = "NotScheduledPayment" Then
				LineWithActualPayment.ShipmentPaymentStage = ScheduleStages[CurLineOfPaymentSchedule].PaymentOption;
			EndIf;
			
			CurLineOfPaymentSchedule = CurLineOfPaymentSchedule + 1;
			
		ElsIf LineWithActualPayment.PaymentFact < ScheduleStages[CurLineOfPaymentSchedule].PaymentAmount Then
			
			If TrimAll(LineWithActualPayment.ShipmentPaymentStage) = "NotScheduledPayment" Then
				LineWithActualPayment.ShipmentPaymentStage = ScheduleStages[CurLineOfPaymentSchedule].PaymentOption;
			EndIf;
			ScheduleStages[CurLineOfPaymentSchedule].PaymentAmount = ScheduleStages[CurLineOfPaymentSchedule].PaymentAmount - LineWithActualPayment.PaymentFact;
			
		Else
			
			RemainsToAllocate = LineWithActualPayment.PaymentFact;
			ArrayOfPaymentTypesByPayment = New Array;
			
			While RemainsToAllocate >= ScheduleStages[CurLineOfPaymentSchedule].PaymentAmount Do
				RemainsToAllocate = RemainsToAllocate - ScheduleStages[CurLineOfPaymentSchedule].PaymentAmount;
				
				StepPaymentOption = ScheduleStages[CurLineOfPaymentSchedule].PaymentOption;
				If ArrayOfPaymentTypesByPayment.Find(StepPaymentOption) = Undefined Then
					ArrayOfPaymentTypesByPayment.Add(ScheduleStages[CurLineOfPaymentSchedule].PaymentOption);
				EndIf;
				 
				CurLineOfPaymentSchedule = CurLineOfPaymentSchedule + 1;
				If CurLineOfPaymentSchedule > NumberOfStagesOfPaymentSchedule - 1 Then
					Break;
				EndIf;
			EndDo;
			
			If RemainsToAllocate > 0 And (Not CurLineOfPaymentSchedule > NumberOfStagesOfPaymentSchedule - 1) Then
				ScheduleStages[CurLineOfPaymentSchedule].PaymentAmount = ScheduleStages[CurLineOfPaymentSchedule].PaymentAmount - RemainsToAllocate;
				StepPaymentOption = ScheduleStages[CurLineOfPaymentSchedule].PaymentOption;
				If ArrayOfPaymentTypesByPayment.Find(StepPaymentOption) = Undefined Then
					ArrayOfPaymentTypesByPayment.Add(ScheduleStages[CurLineOfPaymentSchedule].PaymentOption);
				EndIf;
			EndIf;
			
			If ArrayOfPaymentTypesByPayment.Count() = 1
				And TrimAll(LineWithActualPayment.ShipmentPaymentStage) = "NotScheduledPayment" Then
				
				LineWithActualPayment.ShipmentPaymentStage = ArrayOfPaymentTypesByPayment[0];
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function StageOfPaymentForShipmentByLine(IDOfShipmentPaymentStage)
	
	If IDOfShipmentPaymentStage = "PaymentOnSchedule" Then
		Return NStr("vi = 'Thanh toán theo lịch trình';
					|ru = 'Оплата по графику';
					|en = 'Payment on schedule'; fa = 'Payment on schedule';
					|it = 'Pagamento secondo il grafico';
					|pl = 'Płatność wg harmonogramu';
					|tr = 'Programa göre ödeme'");
	ElsIf IDOfShipmentPaymentStage = "NotScheduledPayment" Then
		Return NStr("vi = 'Thanh toán ngoài lịch trình';
					|ru = 'Оплата не по графику';
					|en = 'Not scheduled payment'; fa = 'Not scheduled payment';
					|it = 'Pagamento in tempi non previsti dal grafico';
					|pl = 'Płatność nie wg harmonogramu';
					|tr = 'Ödeme programa göre değil'");
	ElsIf IDOfShipmentPaymentStage = "Shipment" Then
		Return NStr("vi = 'Xuất kho';
					|ru = 'Отгрузка';
					|en = 'Shipment'; fa = 'ارسال';
					|it = 'Spedizione';
					|pl = 'Wysyłka';
					|tr = 'Sevkiyat'");
	ElsIf IDOfShipmentPaymentStage = "Inpayment" Then
		Return NStr("vi = 'Tiếp nhận';
					|ru = 'Поступление';
					|en = 'Receipt'; fa = 'دریافت';
					|it = 'Arrivo';
					|pl = 'Wpływ';
					|tr = 'Tahsilat'");
	ElsIf IDOfShipmentPaymentStage = "SettlementOfPrepayment" Then
		Return NStr("vi = 'Chuyển ứng trước';
					|ru = 'Перенос аванса';
					|en = 'Prepayment offset'; fa = 'تهاتر پیش‌پرداخت';
					|it = 'Trasferimento del pagamento anticipato';
					|pl = 'Przeniesienie zaliczki';
					|tr = 'Avans transferi'");
	Else
		Return IDOfShipmentPaymentStage;
	EndIf;
	
EndFunction

#EndRegion

#Region Other

Function YouHaveRightToAccessDataSet(DataSetName, ParametersStructure)
	
	HasAccessRight = False;
	
	If DataSetName = "CustomersARAPAccounting" Then
		
		HasAccessRight = AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting);
		
	ElsIf DataSetName = "ReturnsOfGoods" Then
		
		HasAccessRight = AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences);
		HasAccessRight = HasAccessRight And AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
		
	ElsIf DataSetName = "VendorsARAPAccounting" Then
		
		HasAccessRight = AccessRight("Read", Metadata.AccumulationRegisters.VendorsARAPAccounting);
		
	ElsIf DataSetName = "Shipment" Then
		
		HasAccessRight = AccessRight("Read", Metadata.AccumulationRegisters.GoodsForIssue);
		ParametersStructure.Insert("ThereIsRightToShipmentTable", HasAccessRight);
		
		If ParametersStructure.RegisterNameShipmentOfServices = "ShipmentAndReturnReferences" Then
			
			ThereIsRightOfAccessRegisterShipmentOfServices = AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences);
			HasAccessRight = HasAccessRight Or ThereIsRightOfAccessRegisterShipmentOfServices;
			ParametersStructure.Insert("ThereIsRightOfAccessRegisterShipmentOfServices", ThereIsRightOfAccessRegisterShipmentOfServices);
			
		ElsIf ParametersStructure.RegisterNameShipmentOfServices = "InventoryConsumptionOrders" Then
			
			ThereIsRightOfAccessRegisterShipmentOfServices = AccessRight("Read", Metadata.AccumulationRegisters.InventoryConsumptionOrders);
			HasAccessRight = HasAccessRight Or ThereIsRightOfAccessRegisterShipmentOfServices;
			ParametersStructure.Insert("ThereIsRightOfAccessRegisterShipmentOfServices", ThereIsRightOfAccessRegisterShipmentOfServices);
			
		EndIf;
	
	ElsIf DataSetName = "Delivery" Then
		
		HasAccessRight = AccessRight("Read", Metadata.AccumulationRegisters.Delivery);
		HasAccessRight = HasAccessRight
			And AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences);
		
	ElsIf DataSetName = "Inpayment" Then
		
		HasAccessRight = AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
		ParametersStructure.Insert("ThereIsRightToReceiptTable", HasAccessRight);
		
		ThereIsRightToAccessOrdersToSuppliers = AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders);
		ParametersStructure.Insert("ThereIsRightToAccessOrdersToSuppliers", ThereIsRightToAccessOrdersToSuppliers);
		
		If ParametersStructure.NameOfServiceReceiptRegister = "PurchaseOrders" Then
			
			HasAccessRight = HasAccessRight Or ThereIsRightToAccessOrdersToSuppliers;
			ParametersStructure.Insert("ThereIsRightOfAccessRegisterOfReceiptOfServices", ThereIsRightToAccessOrdersToSuppliers);
			
		ElsIf ParametersStructure.NameOfServiceReceiptRegister = "AssemblyOrders" Then
			
			ThereIsRightOfAccessRegisterOfReceiptOfServices = AccessRight("Read", Metadata.AccumulationRegisters.AssemblyOrders);
			HasAccessRight = HasAccessRight And ThereIsRightOfAccessRegisterOfReceiptOfServices;
			ParametersStructure.Insert("ThereIsRightOfAccessRegisterOfReceiptOfServices", ThereIsRightOfAccessRegisterOfReceiptOfServices);
			
		ElsIf ParametersStructure.NameOfServiceReceiptRegister = "TransferOrders" Then
			
			ThereIsRightOfAccessRegisterOfReceiptOfServices = AccessRight("Read", Metadata.AccumulationRegisters.TransferOrders);
			HasAccessRight = HasAccessRight And ThereIsRightOfAccessRegisterOfReceiptOfServices;
			ParametersStructure.Insert("ThereIsRightOfAccessRegisterOfReceiptOfServices", ThereIsRightOfAccessRegisterOfReceiptOfServices);
			
		EndIf;
		
	ElsIf DataSetName = "SoftwareAdditionally" Then
		
		HasAccessRight = AccessRight("View", Metadata.DataProcessors.OrderSupplyForecast);
		
	ElsIf DataSetName = "ServicesOfMaterialProviderForRegistration" Then
		
		HasAccessRight =
			AccessRight("Read", Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
			And True;
	ElsIf DataSetName = "ProductsToBeProcessedInReportToProcessor" Then
		
		StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
		
		HasAccessRight = ValueIsFilled(StructureOfAdditionalRequests)
						   And StructureOfAdditionalRequests.Property("QueryTextTableProductsToBeProcessedInReportToProcessor")
						   Or False;
		
	ElsIf DataSetName = "RawMaterialsFromProcessor" Then
		
		StructureOfAdditionalRequests = ParametersStructure.StructureOfAdditionalRequests;
		
		HasAccessRight = ValueIsFilled(StructureOfAdditionalRequests)
						   And StructureOfAdditionalRequests.Property("TableRawMaterialsAtProcessor")
						   Or False;
	EndIf;
	
	Return HasAccessRight;
	
EndFunction

Function StatusesWithoutShipment(TableName)
	
	ArrayOfStatuses = New Array();
	
	ArrayOfStatuses.Add(Enums.SalesOrderStatuses.NotApproved);
	
	ArrayOfStatuses.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon);
	ArrayOfStatuses.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn);
	ArrayOfStatuses.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected);
	ArrayOfStatuses.Add(Enums.InternalOrderStatuses.AwaitingApproval);
	ArrayOfStatuses.Add(Enums.RMOrderStatuses.Created);
	Return ArrayOfStatuses
	
EndFunction

#EndRegion

#EndRegion

#EndIf
