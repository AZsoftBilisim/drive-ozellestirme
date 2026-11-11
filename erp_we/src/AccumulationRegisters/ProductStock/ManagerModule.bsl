#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Warehouse)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.ProductStock.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.41";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("e0ca9ea7-01a0-4ba0-888a-ba5aac55c94f");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.ProductStock.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	CommentText1 = New Array;
	CommentText1.Add(NStr("vi = 'Cập nhật bản ghi kết chuyển theo biểu ghi tích lũy ""Hàng hóa trong kho"" đối với các chứng từ sau:';
							|ru = 'Обновляет движения по регистру накопления ""Товары на складах"" для документов:';
							|en = 'Updates register records in the ""Goods in warehouses"" accumulation register for the following documents:'; fa = 'Updates register records in the ""Goods in warehouses"" accumulation register for the following documents:';
							|it = 'Updates register records in the ""Goods in warehouses"" accumulation register for the following documents:';
							|pl = 'Updates register records in the ""Goods in warehouses"" accumulation register for the following documents:';
							|tr = '""Ambarlardaki ürünler"" birikim kaydındaki belgelere ilişkin hareketleri günceller:'"));
	CommentText1.Add(NStr("ru = '- ""Акт о расхождениях после отгрузки"";';
							|vi = '- Sales dispute';
							|en = '- Sales dispute'; fa = '- Sales dispute';
							|it = '- Sales dispute';
							|pl = '- Sales dispute';
							|tr = '- ""Sevkiyat sonrası tutarsızlık raporu"";'"));
	CommentText1.Add(NStr("ru = '- ""Акт о расхождениях после перемещения"";';
							|vi = '- Stock transfer discrepancy report';
							|en = '- Stock transfer discrepancy report'; fa = '- Stock transfer discrepancy report';
							|it = '- Stock transfer discrepancy report';
							|pl = '- Stock transfer discrepancy report';
							|tr = '- ""Stok transferi tutarsızlık raporu"";'"));
	CommentText1.Add(NStr("vi = '- ""Biên bản chênh lệch sau khi nhập hàng"";';
							|ru = '- ""Акт о расхождениях после приемки"";';
							|en = '- Receipt discrepancy report'; fa = '- Receipt discrepancy report';
							|it = '- Receipt discrepancy report';
							|pl = '- Receipt discrepancy report';
							|tr = '- ""Stok farkları raporu"";'"));
	CommentText1.Add(NStr("ru = '- ""Движение продукции и материалов"";';
							|vi = '- Movement of products and materials';
							|en = '- Movement of products and materials'; fa = '- Movement of products and materials';
							|it = '- Movement of products and materials';
							|pl = '- Movement of products and materials';
							|tr = '- ""İmal edilen ürün ve malzeme hareketi"";'"));
	CommentText1.Add(NStr("ru = '- ""Ордер на перемещение товаров"";';
							|vi = '- Internal stock transfer';
							|en = '- Internal stock transfer'; fa = '- Internal stock transfer';
							|it = '- Internal stock transfer';
							|pl = '- Internal stock transfer';
							|tr = '- ""Dahili stok transferi"";'"));
	CommentText1.Add(NStr("ru = '- ""Перемещение товаров"".';
							|vi = '- Goods transfer';
							|en = '- Goods transfer'; fa = '- Goods transfer';
							|it = '- Goods transfer';
							|pl = '- Goods transfer';
							|tr = '- ""Ürünlerin transferi"";'"));
	
	Comment = StrConcat(CommentText1, Chars.LF);
	
	Handler.Comment = Comment;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.DiscrepancyReportFollowingShipment.FullName());
	ItemsToRead.Add(Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName());
	ItemsToRead.Add(Metadata.Documents.DiscrepancyReportFollowingTransfer.FullName());
	ItemsToRead.Add(Metadata.Documents.MovementOfProductsAndMaterials.FullName());
	ItemsToRead.Add(Metadata.Documents.GoodsTransferNote.FullName());
	ItemsToRead.Add(Metadata.Documents.TransferOfGoodsToBailee.FullName());
	ItemsToRead.Add(Metadata.Documents.InventoryTransfer.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.ProductStock.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.ProductStock.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	DocumentsList	= DocumentsToUpdate();
	FullRegisterName	= Metadata.AccumulationRegisters.ProductStock.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = StrConcat(DocumentsList, ",");
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	RegisterName = "ProductStock";
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.GetQueryTexts = True;
	
	Recorders = New Array;
	RecordersCertificatesAfterAcceptance = New Array;
	
	For Each FullDocumentName In DocumentsList Do
		DocumentName = StrSplit(FullDocumentName, ".")[1];
		QueryTexts = Documents[DocumentName].DocumentDataForPosting(Undefined, RegisterName, AddlParameters);
		
		CommonTemporaryTables = Undefined;
		If FullDocumentName = "Document.DiscrepancyReportFollowingReceipt" Then
			CommonTemporaryTables = New Array();
			Documents.DiscrepancyReportFollowingReceipt.QueryTextDocumentData(CommonTemporaryTables);
			For Each Item In QueryTexts Do
				// The peculiarity of the formation of query texts is in the mechanics of the warehouse.
				// Further, the text is not perceived by the mechanics of rechecking.
				Item.Value = StrReplace(Item.Value, "(Goods.Warehouse)", "Goods.Warehouse");
				Item.Value = StrReplace(Item.Value, "(Goods.Purpose)", "Goods.Purpose");
				Item.Value = StrReplace(Item.Value, "(Goods.Products)", "Goods.Products");
				Item.Value = StrReplace(Item.Value, "(SetOfSeries.Warehouse)", "SetOfSeries.Warehouse");
				Item.Value = StrReplace(Item.Value, "(SetOfSeries.Purpose)", "SetOfSeries.Purpose");
				Item.Value = StrReplace(Item.Value, "(SetOfSeries.Products)", "SetOfSeries.Products");
			EndDo;
		ElsIf FullDocumentName = "Document.InventoryTransfer" Then
			CommonTemporaryTables = New Array();
			Documents.InventoryTransfer.QueryTextDocumentData(CommonTemporaryTables);
			For Each Item In QueryTexts Do
				// The peculiarity of the formation of query texts is in the mechanics of the warehouse.
				// Further, the text is not perceived by the mechanics of rechecking.
				Item.Value = StrReplace(Item.Value, "(HeaderData_.DestinationWarehouse)", "HeaderData_.DestinationWarehouse");
				Item.Value = StrReplace(Item.Value, "(GoodsTable.Purpose)", "GoodsTable.Purpose");
				Item.Value = StrReplace(Item.Value, "(GoodsTable.Products)", "GoodsTable.Products");
				Item.Value = StrReplace(Item.Value, "(DocumentGoods.Products)", "DocumentGoods.Products");
				Item.Value = StrReplace(Item.Value, "(DocumentGoods.AssignmentSender)", "DocumentGoods.AssignmentSender");
				Item.Value = StrReplace(Item.Value, "(HeaderData_.SourceWarehouse)", "HeaderData_.SourceWarehouse");
			EndDo;
		EndIf;
		
		RecordersByDocumentType = DocumentsPosting.CallLoggers(
			QueryTexts,
			FullRegisterName,
			FullDocumentName,
			CommonTemporaryTables);
		
		If FullDocumentName = "Document.DiscrepancyReportFollowingReceipt" Then
			CommonClientServer.SupplementArray(RecordersCertificatesAfterAcceptance, RecordersByDocumentType);
		Else
			CommonClientServer.SupplementArray(Recorders, RecordersByDocumentType);
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DocumentTable.Ref AS Recorder
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt AS DocumentTable
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt.Goods AS GoodsTable
	|		ON DocumentTable.Ref = GoodsTable.Ref
	|WHERE
	|	DocumentTable.Posted
	|	AND DocumentTable.Ref IN (&Recorders)
	|	AND GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration)
	|	AND DocumentTable.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice)
	|	AND GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|	AND GoodsTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= DocumentTable.Date
	|	AND (NOT GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|		OR (GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|			AND GoodsTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue > DocumentTable.Date))";
	
	Query.SetParameter("Recorders", RecordersCertificatesAfterAcceptance);
	
	CommonClientServer.SupplementArray(
		Recorders,
		Query.Execute().Unload().UnloadColumn("Recorder"));
	
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
	
EndProcedure

// An update handler.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	DocumentsList	= DocumentsToUpdate();
	FullRegisterName	= Metadata.AccumulationRegisters.ProductStock.FullName();
	
	AdditionalParameters = InfobaseUpdateTM.AdditionalOptionsForOverwritingRegisteredRecordsFromQueue();
	AdditionalParameters.UpdatedData = Parameters.UpdatedData;
	
	ProcessingCompleted = InfobaseUpdateTM.OverwriteRegisteredRecordsFromQueue(DocumentsList,
																						FullRegisterName,
																						Parameters.Queue,
																						AdditionalParameters);
	
	Parameters.ProcessingCompleted = ProcessingCompleted;
	
EndProcedure

Function DocumentsToUpdate()
	
	DocumentsList = New Array;
	DocumentsList.Add("Document.DiscrepancyReportFollowingShipment");
	DocumentsList.Add("Document.DiscrepancyReportFollowingReceipt");
	DocumentsList.Add("Document.DiscrepancyReportFollowingTransfer");
	DocumentsList.Add("Document.MovementOfProductsAndMaterials");
	DocumentsList.Add("Document.GoodsTransferNote");
	DocumentsList.Add("Document.TransferOfGoodsToBailee");
	DocumentsList.Add("Document.InventoryTransfer");
	
	Return DocumentsList;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
