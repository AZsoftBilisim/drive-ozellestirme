#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.DiscrepancyReportFollowingTransfer);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	RoundingParameters = ProductsServer.ParametersForRoundingNumberOfUnitProducts();
	RoundingParameters.FieldNameQuantitySuffix = "CountByDocument";
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters);
	
	If GetFunctionalOption("UseGoodsQualityControl") Then
		
		// The mechanism of "Controlled Lot references".
		
		SetPrivilegedMode(True);
		Query = New Query();
		Query.Text =
			"SELECT DISTINCT
			|	TabPart.DocumentBasis AS DocumentBasis,
			|	TabPart.OrderDocument AS OrderDocument,
			|	CAST(TabPart.ControlledLotOfTheSender AS Catalog.ControlledLots) AS ControlledLotOfTheSender,
			|	CAST(&DestinationWarehouse AS Catalog.Warehouses) AS Warehouse
			|INTO TabPart
			|FROM
			|	&TabPart AS TabPart
			|INDEX BY
			|	DocumentBasis
			|;
			|///////////////////////
			|SELECT DISTINCT
			|	CASE
			|		WHEN TabPart.ControlledLotOfTheSender <> VALUE(Catalog.ControlledLots.EmptyRef)
			|			THEN TabPart.ControlledLotOfTheSender.Lot
			|		WHEN NOT ISNULL(TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
			|					AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &Date, FALSE)
			|			THEN TabPart.DocumentBasis
			|		WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
			|				OR TabPart.OrderDocument = VALUE(Document.TransferOrder.EmptyRef)
			|			THEN TabPart.DocumentBasis
			|		ELSE TabPart.OrderDocument
			|	END AS DocumentLots,
			|	TabPart.DocumentBasis AS DocumentBasis,
			|	TabPart.OrderDocument AS OrderDocument,
			|	TabPart.ControlledLotOfTheSender AS ControlledLotOfTheSender,
			|	&BusinessOperation AS BusinessOperation,
			|	&Sender AS Sender
			|FROM
			|	TabPart AS TabPart
			|		LEFT JOIN Document.VendorInvoice AS Purchase
			|		ON Purchase.Ref = TabPart.DocumentBasis";
		Query.SetParameter("GoodsReceiptOption", GoodsReceiptOption);
		Query.SetParameter("Date", Date);
		Query.SetParameter("BusinessOperation", BusinessOperation);
		Query.SetParameter("Sender", SourceWarehouse);
		Query.SetParameter("DestinationWarehouse", DestinationWarehouse);
		Indexes = "DocumentBasis,OrderDocument,ControlledLotOfTheSender";
		Query.SetParameter("TabPart", Goods.Unload(, Indexes));
		DocumentsOfLotReference = Query.Execute().Unload();
		SetPrivilegedMode(False);
		
		QualityControl.FillInControlledLotReferencesInTablePart(
			ThisObject,
			Goods,
			DocumentsOfLotReference,
			Indexes);
			
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Status = Enums.StatusesOfDiscrepancyReport.NotApproved Then
		NotCheckedAttributeArray.Add("Goods.DocumentBasis");
	EndIf;
	
	NotCheckedAttributeArray.Add("CompanyRecipient");
	
	NotCheckedAttributeArray.Add("Goods.Action");
	NotCheckedAttributeArray.Add("Goods.NumberOfPackagesByDocument");
	NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
	NotCheckedAttributeArray.Add("Goods.CountByDocument");
	NotCheckedAttributeArray.Add("Goods.Count");
	NotCheckedAttributeArray.Add("Goods.DescriptionText");
	NotCheckedAttributeArray.Add("Goods.Series");
	
	NotCheckedAttributeArray.Add("Goods.Warehouse");
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.FieldNamesWithSuffix.Insert("Count", "CountByDocument");
	CheckParameters.FieldNamesWithSuffix.Insert("NumberOfPackages", "NumberOfPackagesByDocument");
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	If ValueIsFilled(SourceWarehouse) And SourceWarehouse = DestinationWarehouse Then

		CommonClientServer.MessageToUser(NStr("vi = 'Một kho không thể vừa là nơi gửi vừa là nơi nhận. Hãy thay đổi một trong các kho.';
												|ru = 'Один склад не может быть как отправителем, так и получателем. Измените один из складов.';
												|en = 'The same warehouse cannot be both shipping and receiving. Change one of the warehouses.'; fa = 'The same warehouse cannot be both shipping and receiving. Change one of the warehouses.';
												|it = 'Un magazzino non può essere sia mittente che destinatario. Modificare uno dei magazzini.';
												|pl = 'Jeden magazyn nie może być zarówno nadawcą, jak i odbiorcą. Zmień jeden z magazynów.';
												|tr = 'Bir depo hem gönderici hem de alıcı olamaz. Depolardan birini değiştirin.'"),
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
		
		ErrorText = NStr("vi = 'Doanh nghiệ-người nhận phải có quan hệ với doanh nghiệp-người gửi theo cơ cấu tổ chức.';
						|ru = 'Организация-получатель должна быть взаимосвязана с организацией-отправителем по организационной структуре.';
						|en = 'Receiving company should be connected with a shipping company by the organizational structure.'; fa = 'Receiving company should be connected with a shipping company by the organizational structure.';
						|it = 'La società-destinatario deve essere interconnessa con la società-mittente per la struttura organizzativa.';
						|pl = 'Firma odbiorca powinna być wzajemnie powiązana z firmą nadawcą według struktury organizacyjnej.';
						|tr = 'Alıcı iş yeri, organizasyon yapısı bakımından gönderici iş yeri ile bağlantılı olmalıdır.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"CompanyRecipient",
			,
			Cancel);
		
		EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.DiscrepancyReportFollowingTransfer);
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
	                                            SeriesSpecificationParameters,
	                                            Cancel,
	                                            NotCheckedAttributeArray);
	
	// Checking that the bases are on order
	
	NotCheckedAttributeArray.Add("Goods.OrderDocument");
	NotCheckedAttributeArray.Add("Goods.RowCode");

	Query = New Query;
	Query.Text = "
	|SELECT
	|	BasisDocuments.DocumentBasis
	|INTO BasisDocuments
	|FROM
	|	&BasisDocuments AS BasisDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BasisDocuments.DocumentBasis
	|FROM
	|	BasisDocuments AS BasisDocuments
	|		INNER JOIN Document.InventoryTransfer AS InventoryTransfer
	|		ON BasisDocuments.DocumentBasis = InventoryTransfer.Ref
	|WHERE
	|	InventoryTransfer.TransferAgainstOrders";
	
	Query.SetParameter("BasisDocuments", Goods.Unload(,"DocumentBasis"));
	
	QueryResult = Query.Execute();
	ChecksOnOrderAreRequired = True;
	If QueryResult.IsEmpty() Then
		ChecksOnOrderAreRequired = False;
	Else
		ArrayOfImplementationsByOrder = QueryResult.Unload().UnloadColumn("DocumentBasis");
	EndIf;
	
	For CurIndex__ = 0 To Goods.Count()-1 Do
		
		CurrentRow = Goods[CurIndex__];
		
		If ChecksOnOrderAreRequired Then 
			If Not ValueIsFilled(CurrentRow.OrderDocument) And ValueIsFilled(CurrentRow.DocumentBasis)
				And ArrayOfImplementationsByOrder.Find(CurrentRow.DocumentBasis) <> Undefined Then
				
				ErrorText = NStr("vi = 'Chưa điền trường ""Đơn hàng"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Заказ"" в строке %LineNumber% списка ""Товары""';
								|en = '""Order"" in line %LineNumber% of the Item list is not filled in'; fa = '""Order"" in line %LineNumber% of the Item list is not filled in';
								|it = 'Il campo ""Ordine"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
								|pl = 'Nie wypełniono pola ""Заказ"" w wierszu %LineNumber% listy ""Товары""';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Sipariş"" alanı doldurulmamış'");
				ErrorText =  StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
				
				CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "OrderDocument"),
				,
				Cancel);
				
				ErrorText = NStr("vi = 'Chưa điền trường ""Mã dòng"" tại dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Код строки"" в строке %LineNumber% списка ""Товары""';
								|en = '""Line code"" in line %LineNumber% of the Item list is not filled in'; fa = '""Line code"" in line %LineNumber% of the Item list is not filled in';
								|it = 'Il campo ""Codice di riga"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
								|pl = 'Nie wypełniono pola ""Код строки"" w wierszu %LineNumber% listy ""Товары""';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Satır kodu"" alanı doldurulmamış'");
				ErrorText = StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
				
				CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "OrderDocument"),
				,
				Cancel);
				
			EndIf;
		EndIf;
		
		If Status <> Enums.StatusesOfDiscrepancyReport.NotApproved 
			And (CurrentRow.NumberOfPackages - CurrentRow.NumberOfPackagesByDocument) <> 0 
			And Not ValueIsFilled(CurrentRow.Action) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Cách thức phản ánh chênh lệch"" tại dòng %LineNumber% trong danh sách ""Hàng hóa""';
							|ru = 'Не заполнено поле ""Как отражать расхождение"" в строке %LineNumber% списка ""Товары""';
							|en = '""How to record discrepancy"" field in line %LineNumber% of the Item list is not filled in'; fa = '""How to record discrepancy"" field in line %LineNumber% of the Item list is not filled in';
							|it = 'Il campo ""Come riportare la divergenza"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
							|pl = 'Nie wypełniono pola ""Jak odzwierciedlać odchylenie"" w wierszu %LineNumber% listy ""Wiersze pozycji""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Tutarsızlık yansıtma şekli"" alanı doldurulmamış'");
			ErrorText =  StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "Action"),
				,
				Cancel);
			
		EndIf;
			
		If Not CurrentRow.FilledUsingBaseDocument And Not ValueIsFilled(CurrentRow.NumberOfPackages) Then
		
			ErrorText = NStr("vi = 'Chưa điền trường ""Số lượng thực tế"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
							|ru = 'Не заполнено поле ""Количество факт"" в строке %LineNumber% списка ""Товары""';
							|en = '""Quantity actual"" is not populated in line %LineNumber% of the Item list'; fa = '""Quantity actual"" is not populated in line %LineNumber% of the Item list';
							|it = 'Il campo ""Quantità di fatto"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
							|pl = 'Nie wypełniono pola ""Количество факт"" w wierszu %LineNumber% listy ""Товары""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Gerçekleşenlerin miktarı"" alanı doldurulmamış'");
			ErrorText =  StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
			
			CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "NumberOfPackages"),
			,
			Cancel);
		
		EndIf;

	EndDo;
	
	MetadataDetails = DiscrepanciesServer.DescriptionOfMetadataForCheckingPossibilityOfAddingSurplusToInvoice();
	MetadataDetails.NameOfInvoiceOrderField = "TransferOrder";
	MetadataDetails.NameOfOrderRegisterField  = "TransferOrder";
	MetadataDetails.NameOfOrderReportField = "OrderDocument";
	MetadataDetails.NameOfInvoiceField = "DocumentBasis";
	
	DiscrepanciesServer.CheckingPossibilityOfMakingSurplusInInvoice(ThisObject, "TransferOrders", MetadataDetails, Cancel);
	
	QualityControl.ProcessingVerificationOfDocumentCompletionOfMove(
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
		"Date");
	
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
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("AnArrayOfOrders") Then
			FillInOnTheBasis(FillingData.AnArrayOfOrders);
		Else
			FillInSelectionDocument(FillingData);
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.InventoryTransfer") Then
		
		FillInOnTheBasis(FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsQualityControlCertificate") Then
		
		SetPrivilegedMode(True);
		AttributesOfReport = Common.ObjectAttributesValues(
			FillingData,
			"ControlledLotReference,Status");
		QualityControl.RaiseExceptionWhenCreatingBasedOnAct(AttributesOfReport);
		LinkToLotReference = AttributesOfReport.ControlledLotReference;
		PartyDetails = Common.ObjectAttributesValues(LinkToLotReference, "Lot,BusinessOperation");
		DocumentLots = PartyDetails.Lot;
		LastCorrectiveDocument = DocumentCorrection.LastCorrectiveDocument(DocumentLots);
		If LastCorrectiveDocument <> Undefined Then
			DocumentLots = LastCorrectiveDocument.Ref;
		EndIf;
		BusinessOperation = PartyDetails.BusinessOperation;
		
		SetPrivilegedMode(False);
		
		CreateActAfterMoving = TypeOf(DocumentLots) = Type("DocumentRef.InventoryTransfer")
			And GetFunctionalOption("UseNonConformanceCertificatesFollowingTransfer");
		
		If CreateActAfterMoving Then
				
				FillInOnTheBasis(DocumentLots);
				FillInFactOnQualityControlReport(FillingData);
			
		ElsIf TypeOf(DocumentLots) = Type("DocumentRef.TransferOrder") Then
			
			Text = NStr("vi = 'Không hỗ trợ tạo Biên bản chênh lệch, khi việc nhập hàng vào kho được thực hiện theo đơn hàng. Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Создание Акта о расхождениях, когда приемка товаров на склад осуществлялась по заказам, не поддерживается. Ввод на основании документа запрещен.';
						|en = 'Cannot create a discrepancy report when the goods were received to the warehouse under orders. Generation from such base documents is not allowed.'; fa = 'Cannot create a discrepancy report when the goods were received to the warehouse under orders. Generation from such base documents is not allowed.';
						|it = 'Cannot create a discrepancy report when the goods were received to the warehouse under orders. Generation from such base documents is not allowed.';
						|pl = 'Cannot create a discrepancy report when the goods were received to the warehouse under orders. Generation from such base documents is not allowed.';
						|tr = 'Ürünlerin ambara kabulünün siparişlere göre yapıldığı durumlarda Tutarsızlık Tutanağı oluşturulması desteklenmez. Belgeye dayanarak giriş yapılması yasaktır.'");
			Raise Text;
			
		ElsIf TypeOf(DocumentLots) = Type("DocumentRef.RequestForGoodsQualityControl") Then
			
			Text = NStr("vi = 'Không hỗ trợ tạo Biên bản chênh lệch, khi kiểm soát chất lượng theo yêu cầu kiểm soát. Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Создание Акта о расхождениях, при контроле качества по заявкам на контроль, не поддерживается. Ввод на основании документа запрещен.';
						|en = 'Cannot create a discrepancy report if the quality control was performed under control requests. Generation from such base documents is not allowed.'; fa = 'Cannot create a discrepancy report if the quality control was performed under control requests. Generation from such base documents is not allowed.';
						|it = 'Cannot create a discrepancy report if the quality control was performed under control requests. Generation from such base documents is not allowed.';
						|pl = 'Cannot create a discrepancy report if the quality control was performed under control requests. Generation from such base documents is not allowed.';
						|tr = 'Kalite kontrol taleplerine göre kalite kontrol yapılırken Tutarsızlık Tutanağı oluşturulması desteklenmez. Belgeye dayanarak giriş yapılması yasaktır.'");
			Raise Text;
			
		Else
			Text = StrTemplate(NStr("vi = 'Đối với nghiệp vụ ""%1"" mà theo đó đã nhập hàng, không đề xuất tạo chứng từ. Việc nhập trên cơ sở chứng từ bị cấm.';
									|ru = 'Для операции ""%1"", по которой поступил товар, не предполагается создание документа. Ввод на основании документа запрещен.';
									|en = 'Cannot create the document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.'; fa = 'Cannot create the document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
									|it = 'Cannot create the document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
									|pl = 'Cannot create the document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
									|tr = 'Ürün girişinin yapıldığı "" %1 "" işlemi için belge oluşturulması öngörülmemiştir. Belgeye dayanarak giriş yapılması yasaktır.'"),
				BusinessOperation);
			Raise Text;
		EndIf;
	
	EndIf;
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInFactOnQualityControlReport(ActOfFoundation)
	
	KeyOfFillingIsToControlQuality = "Products";
	
	Query = New Query();
	Query.SetParameter("ActOfFoundation", ActOfFoundation);
	Query.SetParameter("DocumentWarehouses", DestinationWarehouse);
	Query.Text =
		"SELECT DISTINCT
		|	Goods.Products AS Products
		|FROM
		|	Document.GoodsQualityControlCertificate.Goods AS Goods
		|WHERE
		|	Goods.Ref = &ActOfFoundation
		|	AND Goods.Warehouse IN(&DocumentWarehouses)";
	GoodsOfQualityControlAct = Query.Execute().Unload();
	
	FactOfAcceptance = Documents.DiscrepancyReportFollowingTransfer.FillActual(
		ThisObject,
		DestinationWarehouse,
		Documents.GoodsQualityControlCertificate,
		ActOfFoundation);
		
	DocumentGoods = Goods.Unload();
	Series_Document = SetOfSeries.Unload();
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(DocumentGoods, StructureOfActions);
	DocumentGoods.Columns.Delete("ControlledLotOfTheSender");
	DocumentGoods.Columns.Delete("SubjectToUnlocking");
	DocumentGoods = DocumentGoods.Copy(New Structure("ToControlQuality", False));
	
	SearchKey = New Structure(KeyOfFillingIsToControlQuality);
	GoodsOfQualityControlAct.Indexes.Add(KeyOfFillingIsToControlQuality);
	For IndexOf = 0 To DocumentGoods.Count() - 1 Do
		LineProducts_ = DocumentGoods[IndexOf];
		FillPropertyValues(SearchKey, LineProducts_);
		LineProducts_.ToControlQuality = GoodsOfQualityControlAct.FindRows(SearchKey).Count() > 0;
	EndDo;
	DocumentGoods = DocumentGoods.Copy(New Structure("ToControlQuality", False));
	DocumentGoods.Indexes.Add(KeyOfFillingIsToControlQuality);
	
	// Goods and series whose quality is not controlled by the Master Data and they were not in the quality control report are filled in according to the document,
	// the rest after the fact (according to the quality control report).
	Goods.Clear();
	CurrentReceiverTable = Goods;
	
	CurrentTable = FactOfAcceptance.ResultingTable;
	For IndexOf = 0 To CurrentTable.Count() - 1 Do
		TableRow = CurrentTable[IndexOf];
		FillPropertyValues(SearchKey, TableRow);
		If DocumentGoods.FindRows(SearchKey).Count() = 0 Then
			FillPropertyValues(CurrentReceiverTable.Add(), TableRow);
		EndIf;
	EndDo;
	
	CurrentTable = DocumentGoods;
	For IndexOf = 0 To CurrentTable.Count() - 1 Do
		TableRow = CurrentTable[IndexOf];
		FillPropertyValues(CurrentReceiverTable.Add(), TableRow);
	EndDo;
	
	SetOfSeries.Clear();
	CurrentReceiverTable = SetOfSeries;
	
	CurrentTable = FactOfAcceptance.ResultingSeriesTable;
	For IndexOf = 0 To CurrentTable.Count() - 1 Do
		TableRow = CurrentTable[IndexOf];
		FillPropertyValues(SearchKey, TableRow);
		If DocumentGoods.FindRows(SearchKey).Count() = 0 Then
			FillPropertyValues(CurrentReceiverTable.Add(), TableRow);
		EndIf;
	EndDo;
	
	CurrentTable = Series_Document;
	For IndexOf = 0 To CurrentTable.Count() - 1 Do
		TableRow = CurrentTable[IndexOf];
		FillPropertyValues(SearchKey, TableRow);
		If DocumentGoods.FindRows(SearchKey).Count() > 0 Then
			FillPropertyValues(CurrentReceiverTable.Add(), TableRow);
		EndIf;
	EndDo;
	
	SeriesSpecificationParameters = Documents.DiscrepancyReportFollowingTransfer.SeriesSpecificationParameters(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	SuffixRecalculationParameters = "ByDocument";
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateNumberOfSuffixPacks", SuffixRecalculationParameters);
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Procedure FillInSelectionDocument(FilterStructure1)
	
	If FilterStructure1.Property("Organization") Then
		Organization = FilterStructure1.Organization;
	EndIf;
	
	If FilterStructure1.Property("CompanyRecipient") Then
		CompanyRecipient = FilterStructure1.CompanyRecipient;
	EndIf;
	
	If FilterStructure1.Property("SourceWarehouse") Then
		SourceWarehouse = FilterStructure1.SourceWarehouse;
	EndIf;
	
	If FilterStructure1.Property("DestinationWarehouse") Then
		DestinationWarehouse = FilterStructure1.DestinationWarehouse;
	EndIf;
	
	If FilterStructure1.Property("BusinessOperation") Then
		BusinessOperation = FilterStructure1.BusinessOperation;
	EndIf;
	
EndProcedure

Procedure FillInOnTheBasis(Basis1)
	
	Query = New Query;
	
	Query.Text = Documents.DiscrepancyReportFollowingTransfer.RequestTextBasedOnMove();
	
	Query.SetParameter("Basis1", Basis1);
	QueryResult = Query.ExecuteBatch();
	
	DetailsOfFoundation = QueryResult[0].Select();
	DetailsOfFoundation.Next();

	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.GoodsTransferStatuses.Shipped);
	ArrayOfValidStatuses.Add(Enums.GoodsTransferStatuses.Accepted);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		DetailsOfFoundation.DocumentBasis,
		DetailsOfFoundation.DocumentStatus,
		DetailsOfFoundation.ThereAreErrorsPosted,
		DetailsOfFoundation.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
		
	// Filling in the header
	FillPropertyValues(ThisObject, DetailsOfFoundation);
	
	Goods.Load(QueryResult[1].Unload());
	SetOfSeries.Load(QueryResult[2].Unload());
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Author            = Users.CurrentUser();
	Manager         = Users.CurrentUser();
	Department    = SettingsValueCached.UserDivision(Manager);
	
	Organization      = SettingsValueCached.GetDefaultOrganization(Organization);
	SourceWarehouse = SettingsValueCached.GetDefaultWarehouse(SourceWarehouse);
	
	ReferenceOrder = DocumentBaseWhenFillingIn(FillingData);
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(ReferenceOrder);
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInSenderSControlledLotReference", CacheQualityControl);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	StructureOfActions.Insert("FillInUnblockableDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject,
		Documents.DiscrepancyReportFollowingTransfer);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

Function DocumentBaseWhenFillingIn(FillingData)
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("AnArrayOfOrders") Then
		
		Return FillingData.AnArrayOfOrders[0];
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.InventoryTransfer") Then
		
		Return FillingData;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

// Sets the status for the document object.
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders.
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	Status = Enums.StatusesOfDiscrepancyReport[NewStatus];
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.DiscrepancyReportFollowingTransfer);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	Return CheckFilling();
	
EndFunction

#EndRegion

#EndIf
#EndIf
