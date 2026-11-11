#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.ClearUnusedSeries(ThisObject, 
							ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.DiscrepancyReportFollowingReceipt));
								
	ItemsAndDimensionsSelectionParameters = Documents.DiscrepancyReportFollowingReceipt.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	CommissionAgentUsesInventoryAccountingByProductBatchID		= Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Terms);
	BusinessTransactionsProcurementInEAEUCountries	= PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.ImportFromEAEU);
	
	If BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5
		Or BusinessOperation = Enums.BusinessTransactions.ReceiptFromToller2_5
		Or (Not CommissionAgentUsesInventoryAccountingByProductBatchID
			And BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent) Then
		
		For Each RowOfGoods In Goods Do
			If ValueIsFilled(RowOfGoods.CCDNumber) Then
				RowOfGoods.CCDNumber = Undefined;
			EndIf;
		EndDo;
	ElsIf BusinessTransactionsProcurementInEAEUCountries.Find(BusinessOperation) <> Undefined Then
		AccountingForTraceableGoodsLocalization.ClearGTDUNumberOfTraceableGoodsInDocumentPurchaseOfGoodsServices(ThisObject);
	EndIf;
	
	If GetFunctionalOption("UseGoodsQualityControl")
		// With a separate purchase, the Act does not Register Records on the PH of Goods in warehouses, the Lot reference is not needed.
		// In addition, it is impossible to fill it out in a non-ordinary warehouse, since the Lot reference will be the document "Receipt of goods to the warehouse",
		//	to which there are no references in the act. 
			And Not PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BusinessOperation) Then
		
		// The mechanism of "Controlled Lot references".
		
		SetPrivilegedMode(True);
		Query = New Query();
		Query.Text =
			"SELECT DISTINCT
			|	TabPart.DocumentBasis AS DocumentBasis,
			|	TabPart.PurchaseOrder AS PurchaseOrder,
			|	CAST(TabPart.Warehouse AS Catalog.Warehouses) AS Warehouse
			|INTO TabPart
			|FROM
			|	&TabPart AS TabPart
			|INDEX BY
			|	DocumentBasis
			|;
			|///////////////////////
			|SELECT DISTINCT
			|	CASE
			|		WHEN NOT ISNULL(TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
			|					AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &Date, FALSE)
			|			THEN TabPart.DocumentBasis
			|		WHEN
			|			&GoodsReceiptOption IN(
			|				VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
			|				VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
			|				VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
			|			THEN &Terms
			|		WHEN &GoodsReceiptOption IN(
			|				VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
			|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
			|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
			|			THEN &Contract
			|		WHEN &GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
			|				OR TabPart.PurchaseOrder IN(
			|					UNDEFINED,
			|					VALUE(Document.MaterialProviderOrder2_5.EmptyRef),
			|					VALUE(Document.SubcontractOrder2_5.EmptyRef),
			|					VALUE(Document.PurchaseOrder.EmptyRef),
			|					VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef))
			|			THEN TabPart.DocumentBasis
			|		ELSE TabPart.PurchaseOrder
			|	END AS DocumentLots,
			|	TabPart.DocumentBasis AS DocumentBasis,
			|	TabPart.PurchaseOrder AS PurchaseOrder,
			|	TabPart.Warehouse AS Warehouse,
			|	CASE
			|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
			|			THEN ISNULL(Purchase.AdvanceHolder, &Partner)
			|		ELSE &Partner
			|	END AS Sender,
			|	&BusinessOperation AS BusinessOperation
			|FROM
			|	TabPart AS TabPart
			|		LEFT JOIN Document.VendorInvoice AS Purchase
			|		ON Purchase.Ref = TabPart.DocumentBasis";
		Query.SetParameter("GoodsReceiptOption", GoodsReceiptOption);
		Query.SetParameter("Terms", Terms);
		Query.SetParameter("Contract", Contract);
		Query.SetParameter("Partner", Partner);
		Query.SetParameter("BusinessOperation", BusinessOperation);
		Query.SetParameter("Date", Date);
		Indexes = "DocumentBasis,PurchaseOrder,Warehouse";
		Query.SetParameter("TabPart", Goods.Unload(, Indexes));
		DocumentsOfLotReference = Query.Execute().Unload();
		SetPrivilegedMode(False);
		
		QualityControl.FillInControlledLotReferencesInTablePart(
			ThisObject,
			Goods,
			DocumentsOfLotReference,
			Indexes);
	
	EndIf;
	
	DiscrepancyReportFollowingReceiptLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateControlledLotReferencesInTablePart(ThisObject);
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DiscrepancyReportFollowingReceiptLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FilledInBasedOnDocument = False;
	DoNotCheckPossibilityOfEntering  = False;
	
	If TypeOf(FillingData) = Type("DocumentRef.GoodsQualityControlCertificate") Then
		
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
		
		CreateReportAfterAcceptance = TypeOf(DocumentLots) = Type("DocumentRef.VendorInvoice")
			Or TypeOf(DocumentLots) = Type("DocumentRef.ReturnOfGoodsFromCustomer")
			Or TypeOf(DocumentLots) = Type("DocumentRef.ReceiptOfGoodsFromCustodian")
				And (BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian")
					Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent"))
			Or TypeOf(DocumentLots) = Type("DocumentRef.GoodsReceiptForStorage")
				And BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale");
		CreateReportAfterAcceptance = CreateReportAfterAcceptance
			And GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance");
		
		CreateReportAfterAcceptanceFromProcessor = False;
		CreateReportAfterAcceptanceFromProcessor = TypeOf(DocumentLots) = Type("DocumentRef.ReceiptOfGoodsFromCustodian")
			And (BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnFromProcessingCompany2_5")
				Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromToller2_5"));
		CreateReportAfterAcceptanceFromProcessor = CreateReportAfterAcceptanceFromProcessor
			And GetFunctionalOption("UseDiscrepancyReportFollowingReceiptFromSubcontractor2_5");
		CreateActAfterAcceptanceFromGiver = False;
		CreateActAfterAcceptanceFromGiver = TypeOf(DocumentLots) = Type("DocumentRef.GoodsReceiptForStorage")
			And BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5");
		CreateActAfterAcceptanceFromGiver = CreateActAfterAcceptanceFromGiver
			And GetFunctionalOption("UseCertificatesOfDiscrepanciesAfterAcceptanceForAcceptanceOfGiverSGoods2_5");
		If CreateReportAfterAcceptance
				Or CreateReportAfterAcceptanceFromProcessor
				Or CreateActAfterAcceptanceFromGiver Then
				
				FilledInBasedOnDocument = True;
				FillInOnTheBasis(DocumentLots, False);
				// The acceptance option field is used in Documents.actordifferencesexclusions.Fill in the fact.
				ReferenceOrder = DocumentBaseWhenFillingIn(DocumentLots);
				GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(ReferenceOrder, Contract);
				FillInFactOnQualityControlReport(FillingData);
			
		ElsIf TypeOf(DocumentLots) = Type("CatalogRef.CounterpartyContracts") Then
			
			Text = NStr("vi = 'Không hỗ trợ tạo Biên bản chênh lệch, khi việc nhập hàng vào kho được thực hiện theo hợp đồng. Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Создание Акта о расхождениях, когда приемка товаров на склад осуществлялась по договорам, не поддерживается. Ввод на основании документа запрещен.';
						|en = 'Cannot create a discrepancy report when the goods were received to the warehouse under contracts. Generation from such base documents is not allowed.'; fa = 'Cannot create a discrepancy report when the goods were received to the warehouse under contracts. Generation from such base documents is not allowed.';
						|it = 'Cannot create a discrepancy report when the goods were received to the warehouse under contracts. Generation from such base documents is not allowed.';
						|pl = 'Cannot create a discrepancy report when the goods were received to the warehouse under contracts. Generation from such base documents is not allowed.';
						|tr = 'Ürünlerin ambara kabulünün sözleşmelere göre yapıldığı durumlarda Tutarsızlık Tutanağı oluşturulması desteklenmez. Belgeye dayanarak giriş yapılması yasaktır.'");
			Raise Text;
			
		ElsIf TypeOf(DocumentLots) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			
			Text = NStr("vi = 'Không hỗ trợ tạo Biên bản chênh lệch, khi việc nhập hàng vào kho được thực hiện theo thỏa thuận. Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Создание Акта о расхождениях, когда приемка товаров на склад осуществлялась по соглашениям, не поддерживается. Ввод на основании документа запрещен.';
						|en = 'Cannot create a discrepancy report when the goods were received to the warehouse under agreements. Generation from such base documents is not allowed.'; fa = 'Cannot create a discrepancy report when the goods were received to the warehouse under agreements. Generation from such base documents is not allowed.';
						|it = 'Cannot create a discrepancy report when the goods were received to the warehouse under agreements. Generation from such base documents is not allowed.';
						|pl = 'Cannot create a discrepancy report when the goods were received to the warehouse under agreements. Generation from such base documents is not allowed.';
						|tr = 'Ürünlerin ambara kabulünün anlaşmalara göre yapıldığı durumlarda Tutarsızlık Tutanağı oluşturulması desteklenmez. Belgeye dayanarak giriş yapılması yasaktır.'");
			Raise Text;
			
		ElsIf TypeOf(DocumentLots) = Type("DocumentRef.RequestForGoodsQualityControl") Then
			
			Text = NStr("vi = 'Không hỗ trợ tạo Biên bản chênh lệch, khi kiểm soát chất lượng theo yêu cầu kiểm soát. Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Создание Акта о расхождениях, при контроле качества по заявкам на контроль, не поддерживается. Ввод на основании документа запрещен.';
						|en = 'Cannot create a discrepancy report if the quality control was performed under control requests. Generation from such base documents is not allowed.'; fa = 'Cannot create a discrepancy report if the quality control was performed under control requests. Generation from such base documents is not allowed.';
						|it = 'Cannot create a discrepancy report if the quality control was performed under control requests. Generation from such base documents is not allowed.';
						|pl = 'Cannot create a discrepancy report if the quality control was performed under control requests. Generation from such base documents is not allowed.';
						|tr = 'Kalite kontrol taleplerine göre kalite kontrol yapılırken Tutarsızlık Tutanağı oluşturulması desteklenmez. Belgeye dayanarak giriş yapılması yasaktır.'");
			Raise Text;
			
		ElsIf TypeOf(DocumentLots) = Type("DocumentRef.PurchaseOrder")
					Or TypeOf(DocumentLots) = Type("DocumentRef.SalesOrder")
					Or TypeOf(DocumentLots) = Type("DocumentRef.MaterialProviderOrder2_5")
					Or TypeOf(DocumentLots) = Type("DocumentRef.SubcontractOrder2_5")
					Or TypeOf(DocumentLots) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
			
			Text = NStr("vi = 'Không hỗ trợ tạo Biên bản chênh lệch, khi việc nhập hàng vào kho được thực hiện theo đơn hàng. Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Создание Акта о расхождениях, когда приемка товаров на склад осуществлялась по заказам, не поддерживается. Ввод на основании документа запрещен.';
						|en = 'Cannot create a discrepancy report when the goods were received to the warehouse under orders. Generation from such base documents is not allowed.'; fa = 'Cannot create a discrepancy report when the goods were received to the warehouse under orders. Generation from such base documents is not allowed.';
						|it = 'Cannot create a discrepancy report when the goods were received to the warehouse under orders. Generation from such base documents is not allowed.';
						|pl = 'Cannot create a discrepancy report when the goods were received to the warehouse under orders. Generation from such base documents is not allowed.';
						|tr = 'Ürünlerin ambara kabulünün siparişlere göre yapıldığı durumlarda Tutarsızlık Tutanağı oluşturulması desteklenmez. Belgeye dayanarak giriş yapılması yasaktır.'");
			Raise Text;
			
		ElsIf TypeOf(DocumentLots) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
			
			Text = NStr("vi = 'Không hỗ trợ tạo Biên bản chênh lệch cho lô hàng kiểm soát liên quan đến chứng từ ""Tiếp nhận hàng vào kho"". Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Создание Акта о расхождениях по контролируемой партии, связанной с документом ""Поступление товаров на склад"", не поддерживается. Ввод на основании документа запрещен.';
						|en = 'Cannot create a discrepancy report for a controlled lot related to the ""Warehouse receipt"" document. Generation from such base documents is not allowed.'; fa = 'Cannot create a discrepancy report for a controlled lot related to the ""Warehouse receipt"" document. Generation from such base documents is not allowed.';
						|it = 'Cannot create a discrepancy report for a controlled lot related to the ""Warehouse receipt"" document. Generation from such base documents is not allowed.';
						|pl = 'Cannot create a discrepancy report for a controlled lot related to the ""Warehouse receipt"" document. Generation from such base documents is not allowed.';
						|tr = 'Ürünlerin ambara girişi"" belgesiyle ilişkili kontrole tabi lot için Tutarsızlık Tutanağı oluşturulması desteklenmez. Belgeye dayanarak giriş yapılması yasaktır.'");
			Raise Text;
			
		Else
			Text = StrTemplate(NStr("vi = 'Đối với nghiệp vụ ""%1"" mà theo đó đã nhập hàng, không đề xuất tạo chứng từ. Việc nhập trên cơ sở chứng từ bị cấm.';
									|ru = 'Для операции ""%1"", по которой поступил товар, не предполагается создание документа. Ввод на основании документа запрещен.';
									|en = 'Cannot create the document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.'; fa = 'Cannot create the document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
									|it = 'Cannot create the document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
									|pl = 'Cannot create the document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
									|tr = 'Ürün girişinin yapıldığı ""%1"" işlemi için belge oluşturulması öngörülmemiştir. Belgeye dayanarak giriş yapılması yasaktır.""'"),
						BusinessOperation);
			Raise Text;
		EndIf;
	
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("DocumentBasis") 
			And (TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.VendorInvoice")
				Or TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.ReceiptOfGoodsFromCustodian")
				Or TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.GoodsReceiptForStorage")
				Or TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.ReturnOfGoodsFromCustomer")) Then
			
			If FillingData.Property("DoNotCheckPossibilityOfEntering")
				And FillingData.DoNotCheckPossibilityOfEntering Then
				DoNotCheckPossibilityOfEntering = True;
			EndIf;
			FilledInBasedOnDocument = True;
			FillInOnTheBasis(FillingData.DocumentBasis, DoNotCheckPossibilityOfEntering);
		ElsIf FillingData.Property("DocumentBasis") And FillingData.Property("BasisType")
			And TypeOf(FillingData.DocumentBasis) = Type("Array") Then
			
			If FillingData.Property("DoNotCheckPossibilityOfEntering")
				And FillingData.DoNotCheckPossibilityOfEntering Then
				DoNotCheckPossibilityOfEntering = True;
			EndIf;
			FilledInBasedOnDocument = True;
			FillInOnTheBasis(FillingData.DocumentBasis, DoNotCheckPossibilityOfEntering, FillingData.BasisType);

		Else
			FillInByPicking(FillingData);
		EndIf;
	
	ElsIf TypeOf(FillingData) = Type("DocumentRef.VendorInvoice")
		Or TypeOf(FillingData) = Type("DocumentRef.ReceiptOfGoodsFromCustodian")
		Or TypeOf(FillingData) = Type("DocumentRef.GoodsReceiptForStorage")
		Or TypeOf(FillingData) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		
		FilledInBasedOnDocument = True;
		FillInOnTheBasis(FillingData);
		PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
		
	EndIf;
	
	If Not FilledInBasedOnDocument Then
		If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer
			Or DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
			Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
			
			InitializeSalesConditions();
			
		Else
			InitializePurchaseConditions();
		EndIf;
	EndIf;
	
	InitializeDocument(FillingData);

	DiscrepancyReportFollowingReceiptLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	DiscrepanciesServer.CheckTypeOfReportSBasisWhenCreatingIt(ThisObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
		NotCheckedAttributeArray.Add("VATTaxation");
		NotCheckedAttributeArray.Add("Goods.VATRate");
	EndIf;
	
	If Status = Enums.StatusesOfDiscrepancyReport.NotApproved Then
		NotCheckedAttributeArray.Add("Goods.DocumentBasis");
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.Warehouse");
	NotCheckedAttributeArray.Add("Goods.Action");
	NotCheckedAttributeArray.Add("Goods.NumberOfPackagesByDocument");
	NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
	NotCheckedAttributeArray.Add("Goods.CountByDocument");
	NotCheckedAttributeArray.Add("Goods.Count");
	If (TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer
			And BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent)
		Or DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisRefundFromCommissionAgent(TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		NotCheckedAttributeArray.Add("Goods.Price");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.FieldNamesWithSuffix.Insert("Count", "CountByDocument");
	CheckParameters.FieldNamesWithSuffix.Insert("NumberOfPackages", "NumberOfPackagesByDocument");
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.DiscrepancyReportFollowingReceipt);
	ProductsServer.CheckSeriesCompletion(ThisObject,
											SeriesSpecificationParameters,
											Cancel,
											NotCheckedAttributeArray);
	
	// Checking that the receipts are on order
	
	NotCheckedAttributeArray.Add("Goods.PurchaseOrder");
	NotCheckedAttributeArray.Add("Goods.RowCode");
	
	ChecksOnOrderAreRequired = False;
	
	If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice
		Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
		Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage Then
		
		If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
			
			NotCheckedAttributeArray.Add("Goods.Price");
			
			DocumentBasis = Undefined;
			MatchingProductsType = Common.ObjectsAttributeValue(Goods.UnloadColumn("Products"), "ItemsType");		
		EndIf;	
			
		Query = New Query;
		
		If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then
			
			Query.Text = "
			|SELECT
			|	DocumentImplementations.DocumentBasis
			|INTO BasisDocuments
			|FROM
			|	&BasisDocuments AS DocumentImplementations
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	BasisDocuments.DocumentBasis AS Basis
			|FROM
			|	BasisDocuments AS BasisDocuments
			|		INNER JOIN Document.VendorInvoice AS VendorInvoice
			|		ON BasisDocuments.DocumentBasis = VendorInvoice.Ref
			|WHERE
			|	VendorInvoice.ReceiptUnderOrders";
			
		Else
			
			Query.Text =
			"SELECT
			|	DocumentImplementations.DocumentBasis AS DocumentBasis
			|
			|INTO BasisDocuments
			|FROM
			|	&BasisDocuments AS DocumentImplementations
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	BasisDocuments.DocumentBasis AS Basis
			|FROM
			|	BasisDocuments AS BasisDocuments
			|		INNER JOIN Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
			|		ON BasisDocuments.DocumentBasis = GoodsReceiptForStorage.Ref
			|WHERE
			|	GoodsReceiptForStorage.ReceiptUnderOrders";
			
		EndIf;
		
		Query.SetParameter("BasisDocuments", Goods.Unload( ,"DocumentBasis"));
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			ChecksOnOrderAreRequired = True;
			ArrayOfBasesByOrder = QueryResult.Unload().UnloadColumn("Basis");
		EndIf;
		
	EndIf;
	If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		ErrorTextOrderIsNotFilledIn =
			NStr("vi = 'Trường ""Nhà thầu đặt hàng"" không được điền vào dòng %LineNumber% của danh sách ""Sản phẩm""';
				|ru = 'Не заполнено поле ""Заказ давальца"" в строке %LineNumber% списка ""Товары""';
				|en = '""Subcontracting sales order"" is required in line %LineNumber% of the ""Goods"" list'; fa = '""Subcontracting sales order"" is required in line %LineNumber% of the ""Goods"" list';
				|it = 'Il campo ""Ordine del committente"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
				|pl = 'Nie jest wypełnione pole ""Zamówienie właściciela surowców"" w wierszu %LineNumber% listy ""Wiersze pozycji""';
				|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Sağlayıcı siparişi"" alanı doldurulmamış'");
	Else
		ErrorTextOrderIsNotFilledIn =
			NStr("vi = 'Chưa điền trường ""Đơn hàng của nhà cung cấp"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
				|ru = 'Не заполнено поле ""Заказ поставщика"" в строке %LineNumber% списка ""Товары""';
				|en = '""Purchase order"" is not populated in line %LineNumber% of the Item list'; fa = '""Purchase order"" is not populated in line %LineNumber% of the Item list';
				|it = 'Il campo ""Ordine del fornitore"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
				|pl = 'Nie wypełniono pola ""Заказ поставщика"" w wierszu %LineNumber% listy ""Товары""';
				|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Satın alma siparişi"" alanı doldurulmamış'");
	EndIf;
	For CurIndex__ = 0 To Goods.Count()-1 Do
		
		CurrentRow = Goods[CurIndex__];
		
		If ChecksOnOrderAreRequired Then 
			If Not ValueIsFilled(CurrentRow.PurchaseOrder) And ValueIsFilled(CurrentRow.DocumentBasis)
				And ArrayOfBasesByOrder.Find(CurrentRow.DocumentBasis) <> Undefined Then
				
				ErrorText =  StrReplace(ErrorTextOrderIsNotFilledIn, "%LineNumber%", CurrentRow["LineNumber"]);
				
				Common.MessageToUser(
				             ErrorText,
				             ThisObject,
				             CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "PurchaseOrder"),
				             ,
				             Cancel);
				
				ErrorText = NStr("vi = 'Chưa điền trường ""Mã dòng"" tại dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Код строки"" в строке %LineNumber% списка ""Товары""';
								|en = '""Line code"" in line %LineNumber% of the Item list is not filled in'; fa = '""Line code"" in line %LineNumber% of the Item list is not filled in';
								|it = 'Il campo ""Codice di riga"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
								|pl = 'Nie wypełniono pola ""Код строки"" w wierszu %LineNumber% listy ""Товары""';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Satır kodu"" alanı doldurulmamış'");
				ErrorText =  StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
				
				Common.MessageToUser(
				             ErrorText,
				             ThisObject,
				             CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "PurchaseOrder"),
				             ,
				             Cancel);
				
			EndIf;
		EndIf;
		
		If CurrentRow.FilledUsingBaseDocument And Not ValueIsFilled(CurrentRow.NumberOfPackagesByDocument) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Số lượng theo chứng từ"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
							|ru = 'Не заполнено поле ""Количество по документу"" в строке %LineNumber% списка ""Товары""';
							|en = '""Quantity by document"" in line %LineNumber% of the Item list is not filled in'; fa = '""Quantity by document"" in line %LineNumber% of the Item list is not filled in';
							|it = 'Il campo ""Quantità per il documento"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
							|pl = 'Nie wypełniono pola ""Количество по документу"" w wierszu %LineNumber% listy ""Товары""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Belge miktarı"" alanı doldurulmamış'");
			ErrorText =  StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
			
			Common.MessageToUser(
			                ErrorText,
			                ThisObject,
			                CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "NumberOfPackagesByDocument"),
			                ,
			                Cancel);
			
		EndIf;
		
		If Status <> Enums.StatusesOfDiscrepancyReport.NotApproved 
			And (CurrentRow.NumberOfPackages - CurrentRow.NumberOfPackagesByDocument) <> 0 
			And Not ValueIsFilled(CurrentRow["Action"]) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Cách khắc phục chênh lệch"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
							|ru = 'Не заполнено поле ""Как отработать расхождение"" в строке %LineNumber% списка ""Товары""';
							|en = 'Discrepancy treatment in line %LineNumber% is required'; fa = 'Discrepancy treatment in line %LineNumber% is required';
							|it = 'Il campo ""Come elaborare la divergenza"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
							|pl = 'Nie wypełniono pola ""Jak odzwierciedlać odchylenie"" w wierszu %LineNumber% listy ""Wiersze pozycji""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Tutarsızlık işleme şekli"" alanı doldurulmamış'");
			ErrorText =  StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
			
			Common.MessageToUser(
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
			
			Common.MessageToUser(
			                   ErrorText,
			                   ThisObject,
			                   CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "NumberOfPackages"),
			                   ,
			                   Cancel);
			
		EndIf;
		
		If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice Then 
			If Not ValueIsFilled(CurrentRow.Price) Then
			
				ErrorText = NStr("vi = 'Chưa điền trường ""Giá"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Цена"" в строке %LineNumber% списка ""Товары""';
								|en = '""Price"" in line %LineNumber% of the ""Goods"" list is not filled in'; fa = '""Price"" in line %LineNumber% of the ""Goods"" list is not filled in';
								|it = 'Il campo ""Prezzo"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
								|pl = 'Pole ""Cena"" w wierszu %LineNumber% listy ""Wiersze pozycji"" nie jest wypełnione';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Fiyat"" alanı doldurulmamış'");
				ErrorText =  StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
				
				If CurrentRow.FilledUsingBaseDocument Then				
					
					If DocumentBasis <> CurrentRow.DocumentBasis Then
						DocumentBasis = CurrentRow.DocumentBasis;
						ValueOfDocumentDetails = Common.ObjectAttributesValues(DocumentBasis, "ToReturnReusablePackage, PackageDepositIsRequired");
					EndIf;

					If Not MatchingProductsType.Get(CurrentRow.Products) = Enums.ItemsTypes.ReusablePackage 
						Or MatchingProductsType.Get(CurrentRow.Products) = Enums.ItemsTypes.ReusablePackage 
							And (Not ValueOfDocumentDetails.ToReturnReusablePackage Or ValueOfDocumentDetails.PackageDepositIsRequired) Then
				
						Common.MessageToUser(
						                   ErrorText,
						                   ThisObject,
						                   CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "Price"),
						                   ,
						                   Cancel);
						
					EndIf;
				Else
					
					Common.MessageToUser(
					                   ErrorText,
					                   ThisObject,
					                   CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "Price"),
					                   ,
					                   Cancel);
				EndIf; 			
			EndIf;	
		EndIf;	
		
	EndDo;
	If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider Then
		
		RowsArray = Goods.FindRows(New Structure("Purpose", Catalogs.Assignments.EmptyRef()));
		For Each TableRow In RowsArray Do
			
			ErrorText = StrTemplate(
							NStr("vi = 'Chưa điền trường ""Ấn định"" trong dòng %1 của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Назначение"" в строке %1 списка ""Товары""';
								|en = 'The ""Assignment"" field in line %1 of the ""Goods"" list is not filled'; fa = 'The ""Assignment"" field in line %1 of the ""Goods"" list is not filled';
								|it = 'Non è compilato il campo ""Assegnazione"" nella riga %1 dell''elenco ""Merci""';
								|pl = 'Nie wypełniono pola ""Przeznaczenie"" w wierszu %1 listy ""Towary""';
								|tr = '""Ürünler"" listesinin %1 satırındaki ""Varış Yeri"" alanı doldurulmamış'"),
							TableRow.LineNumber);
			
			Field = CommonClientServer.PathToTabularSection("Goods", TableRow.LineNumber, "Purpose");
			
			Common.MessageToUser(ErrorText, ThisObject, Field,, Cancel);
			
		EndDo;
		
	EndIf;
	NotCheckedAttributeArray.Add("Goods.Department");
	
	NotCheckedAttributeArray.Add("Partner");
	If Not ValueIsFilled(Partner) Then
		
		If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
			ErrorText = NStr("vi = 'Chưa điền trường ""Khách hàng""';
							|ru = 'Поле ""Клиент"" не заполнено';
							|en = '""Customer"" is required'; fa = '""Customer"" is required';
							|it = 'Il campo ""Cliente"" non è compilato';
							|pl = 'Nie wypełniono pole ""Клиент""';
							|tr = '""Müşteri"" alanı doldurulmadı'");
			
		ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Bên đặt gia công""';
							|ru = 'Поле ""Давалец"" не заполнено';
							|en = 'The ""Material provider"" field is not filled'; fa = 'The ""Material provider"" field is not filled';
							|it = 'Campo ""Fornitore"" non compilato';
							|pl = 'Pole ""Właściciel surowców"" nie jest wypełnione';
							|tr = '""Malzeme tedarikçisi"" alanı doldurulmamış'");
		
		Else
			ErrorText = NStr("vi = 'Chưa điền trường ""Nhà cung cấp""';
							|ru = 'Поле ""Поставщик"" не заполнено';
							|en = '""Vendor"" is required'; fa = '""Vendor"" is required';
							|it = 'Il campo ""Fornitore"" non è compilato';
							|pl = 'Nie wypełniono pola ""Dostawca""';
							|tr = '""Tedarikçi"" alanı doldurulmadı'");
		EndIf;
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"Partner",
			,
			Cancel);
		
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	ThisIsTraceableDocument = AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date);
	
	If (ThisIsTraceableDocument
			Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers"))
		And BusinessOperation <> Enums.BusinessTransactions.PurchaseByImport
		And BusinessOperation <> Enums.BusinessTransactions.ReturnFromProcessingCompany2_5
		And BusinessOperation <> Enums.BusinessTransactions.ReceiptFromToller2_5
		And BusinessOperation <> Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		
		CheckParameters = InventoriesServer.ParametersForCheckingFillingInOfCCDNumbers();
		CheckParameters.BusinessOperation = BusinessOperation;
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel, CheckParameters);
		
	EndIf;
	
	If ThisIsTraceableDocument Then
		AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject, Goods, Date);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.DiscrepancyReportFollowingReceipt.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		
		If Not ValueIsFilled(Terms) Or
			 Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
			NotCheckedAttributeArray.Add("Contract");
		EndIf;
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
		
		NotCheckedAttributeArray.Add("VATTaxation");
		
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage Then
		
		NotCheckedAttributeArray.Add("VATTaxation");
		NotCheckedAttributeArray.Add("Goods.VATRate");
		NotCheckedAttributeArray.Add("Goods.DimensionOfExpenses");
		
		If GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers")
			And BusinessOperation <> Enums.BusinessTransactions.PurchaseByImport Then
			
			InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel);
			
		EndIf;
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider Then
		
		NotCheckedAttributeArray.Add("VATTaxation");
		NotCheckedAttributeArray.Add("Goods.VATRate");
		NotCheckedAttributeArray.Add("Goods.DimensionOfExpenses");
	Else
		
		NotCheckedAttributeArray.Add("Contract");
		
		ArrayOfTwoWayOperations = PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections();
		If ArrayOfTwoWayOperations.Find(BusinessOperation) = Undefined Then
			ItemsTypes = New Array;
			ItemsTypes.Add(Enums.ItemsTypes.OperationService);
			ItemsTypes.Add(Enums.ItemsTypes.Work_5);
			ErrorText = NStr("vi = 'Chưa chỉ ra người nhận công việc (dịch vụ) tại dòng %1 của danh sách Hàng hóa';
							|ru = 'Не указан получатель работ (услуг) в строке %1 списка Товары';
							|en = 'Party receiving works (services) in line %1 of the Item list is not specified.'; fa = 'Party receiving works (services) in line %1 of the Item list is not specified.';
							|it = 'Il destinatario di lavori (servizi) non è specificato nella riga %1 dell''elenco Merci';
							|pl = 'Nie jest wskazany odbiorca robót (usług) w wierszu %1 listy Wiersze pozycji.';
							|tr = 'İşin (hizmet) alıcısı Ürünler listesinin %1 satırında belirtilmemiştir'");
			InventoriesServer.CheckFillingOfDivisionInTablePart(ThisObject, ItemsTypes, ErrorText, Cancel);
		Else
			NotCheckedAttributeArray.Add("Goods.Department");
		EndIf;
		
	EndIf;
	
	If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice
		Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
		Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage Then
		
		MetadataDetails = DiscrepanciesServer.DescriptionOfMetadataForCheckingPossibilityOfAddingSurplusToInvoice();
		MetadataDetails.NameOfInvoiceOrderField = "PurchaseOrder";
		MetadataDetails.NameOfOrderRegisterField  = "PurchaseOrder";
		MetadataDetails.NameOfOrderReportField = "PurchaseOrder";
		MetadataDetails.NameOfInvoiceField = "DocumentBasis";
		
		DiscrepanciesServer.CheckingPossibilityOfMakingSurplusInInvoice(ThisObject, "PurchaseOrders", MetadataDetails, Cancel);
		
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian Then
		MetadataDetails = DiscrepanciesServer.DescriptionOfMetadataForCheckingPossibilityOfAddingSurplusToInvoice();
		MetadataDetails.NameOfInvoiceOrderField = "ReferenceOrder";
		MetadataDetails.NameOfOrderRegisterField  = "DocumentInflow";
		MetadataDetails.NameOfOrderReportField = "PurchaseOrder";
		MetadataDetails.NameOfInvoiceField = "DocumentBasis";
		
		MetadataDetails.NamesOfUniquenessFields = "Products, Characteristic, Purpose, Series";
		MetadataDetails.NameOfFieldToView = "ToRegisterInvoicesByReference";
		
		DiscrepanciesServer.CheckingPossibilityOfMakingSurplusInInvoice(ThisObject, "GoodsToReceive", MetadataDetails, Cancel);
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor Then
		MetadataDetails = DiscrepanciesServer.DescriptionOfMetadataForCheckingPossibilityOfAddingSurplusToInvoice();
		MetadataDetails.NameOfInvoiceOrderField = "ReferenceOrder";
		MetadataDetails.NameOfOrderRegisterField  = "DocumentInflow";
		MetadataDetails.NameOfOrderReportField = "PurchaseOrder";
		MetadataDetails.NameOfInvoiceField = "DocumentBasis";
		
		MetadataDetails.NamesOfUniquenessFields = "Products, Characteristic, Purpose, Series";
		MetadataDetails.NameOfFieldToView = "ToRegisterInvoicesByReference";
		
		DiscrepanciesServer.CheckingPossibilityOfMakingSurplusInInvoice(ThisObject, "GoodsToReceive", MetadataDetails, Cancel);
		
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor Then
		
		MetadataDetails = DiscrepanciesServer.DescriptionOfMetadataForCheckingPossibilityOfAddingSurplusToInvoice();
		MetadataDetails.NameOfInvoiceOrderField = "ReferenceOrder";
		MetadataDetails.NameOfOrderRegisterField  = "PurchaseOrder";
		MetadataDetails.NameOfOrderReportField = "PurchaseOrder";
		MetadataDetails.NameOfInvoiceField = "DocumentBasis";
		
		MetadataDetails.NameOfFieldToView = "ToReceive";
		
		DiscrepanciesServer.CheckingPossibilityOfMakingSurplusInInvoice(ThisObject, "PurchaseOrders", MetadataDetails, Cancel);
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		MetadataDetails = DiscrepanciesServer.DescriptionOfMetadataForCheckingPossibilityOfAddingSurplusToInvoice();
		MetadataDetails.NameOfInvoiceOrderField = "RequestForReturnOfGoodsFromCustomer";
		MetadataDetails.NameOfOrderRegisterField  = "ReferenceOrder";
		MetadataDetails.NameOfOrderReportField = "PurchaseOrder";
		MetadataDetails.NameOfInvoiceField = "DocumentBasis";
		MetadataDetails.OrderInHeader = True;
		MetadataDetails.VerificationIndicator = "RegisteredOnReturns";
		
		DiscrepanciesServer.CheckingPossibilityOfMakingSurplusInInvoice(ThisObject, "ShipmentAndReturnReferences", MetadataDetails, Cancel);
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
		Undefined);
	
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
	
	If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		SalesServer.CheckCorrectnessOfSalesDocument(ThisObject,Cancel);
	Else
		PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject, Cancel);
	EndIf;
	
	DiscrepancyReportFollowingReceiptLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	DiscrepancyReportFollowingReceiptLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	DiscrepancyReportFollowingReceiptLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInByPicking(FilterStructure1)
	
	If FilterStructure1.Property("Organization") Then
		Organization = FilterStructure1.Organization;
	EndIf;
	
	If FilterStructure1.Property("Partner") Then
		Partner = FilterStructure1.Partner;
	EndIf;
	
	If FilterStructure1.Property("Counterparty") Then
		Counterparty = FilterStructure1.Counterparty;
	EndIf;
	
	If FilterStructure1.Property("Currency") Then
		Currency = FilterStructure1.Currency;
	EndIf;
	
	If FilterStructure1.Property("BusinessOperation") Then
		BusinessOperation = FilterStructure1.BusinessOperation;
		TypeOfBaseDocumentForNonConformanceCertificate = TypeOfBasisForActOfDiscrepancyOnBusinessTransaction(BusinessOperation);
	EndIf;
	
	If FilterStructure1.Property("TypeOfBaseDocumentForNonConformanceCertificate") Then
		TypeOfBaseDocumentForNonConformanceCertificate = FilterStructure1.TypeOfBaseDocumentForNonConformanceCertificate;
		If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider
		   And Not ValueIsFilled(BusinessOperation) Then
			BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInOnTheBasis(Basis, DoNotCheckPossibilityOfEntering = False, BasisType = Undefined)
	
	Query = New Query;
	
	If TypeOf(Basis) = Type("DocumentRef.VendorInvoice")
		Or BasisType = Type("DocumentRef.VendorInvoice")
			And TypeOf(Basis) = Type("Array") Then
		
		TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice;
		Query.Text = RequestTextBasedOnReceipt();
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsFromCustomer")
		Or BasisType = Type("DocumentRef.ReturnOfGoodsFromCustomer")
			And TypeOf(Basis) = Type("Array") Then
		
		TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer;
		Query.Text = RequestTextBasedOnRefund();
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReceiptOfGoodsFromCustodian")
		Or BasisType = Type("DocumentRef.ReceiptOfGoodsFromCustodian")
			And TypeOf(Basis) = Type("Array") Then
		
		CurrentBasis = ?(TypeOf(Basis) = Type("Array"), Basis[0], Basis);
		BusinessOperationFoundation = Common.ObjectAttributeValue(CurrentBasis, "BusinessOperation");
		Handler = Documents.ReceiptOfGoodsFromCustodian.ActionHandler(BusinessOperationFoundation);
		
		TypeOfBaseDocumentForNonConformanceCertificate = Handler.TypeOfBasisOfAct();
		Query.Text = TextOfRequestBasedOnReceiptFromCustodian();
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsReceiptForStorage")
		Or BasisType = Type("DocumentRef.GoodsReceiptForStorage")
			And TypeOf(Basis) = Type("Array") Then
		CurrentBasis = ?(TypeOf(Basis) = Type("Array"), Basis[0], Basis);
		BusinessOperationFoundation =
			Common.ObjectAttributeValue(CurrentBasis, "BusinessOperation");
		
		If BusinessOperationFoundation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider;
		Else
			TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage;
		EndIf;
		Query.Text = TextOfRequestOnBasisOfAcceptanceForStorage();
		
	EndIf;
	
	Query.SetParameter("Basis", Basis);
	QueryResult = Query.ExecuteBatch();
	
	DetailsOfFoundation = QueryResult[0].Select();
	DetailsOfFoundation.Next();
	
	If Not DoNotCheckPossibilityOfEntering Then
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOnOperation(Basis,
									"DiscrepancyReportFollowingReceipt",
									DetailsOfFoundation.BusinessOperation);
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(DetailsOfFoundation.DocumentBasis, 
		                                                        Undefined,
		                                                        DetailsOfFoundation.ThereAreErrorsPosted);
	EndIf;
	
	If TypeOf(Basis) = Type("DocumentRef.VendorInvoice")
		Or BasisType = Type("DocumentRef.VendorInvoice") Then
		
		If DetailsOfFoundation.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
			ErrorText = NStr("vi = 'Tạo chứng từ ""Biên bản chênh lệch sau khi tiếp nhận"" khi mua qua người tạm ứng không được chấp nhận.';
							|ru = 'Создание документа""Акт о расхождениях после поступления"" при закупке через подотчетное лицо не предусмотрено.';
							|en = 'Creation of ""Receipt discrepancy report"" document when purchasing through an advance holder is not provided.'; fa = 'Creation of ""Receipt discrepancy report"" document when purchasing through an advance holder is not provided.';
							|it = 'La generazione del documento ""Atto sulle discrepanze dopo l''arrivo"" con acquisto tramite una persona responsabile non è prevista.';
							|pl = 'Utworzenie dokumentu ""Protokół o odchyleniu po wpływie"" podczas zakupu przez osobę zaliczkobiorcę nie jest przewidziane.';
							|tr = 'Sorumlu bir kişi aracılığıyla yapılan satın alımlarda ""Teslim alındıktan sonra tutarsızlık raporu"" oluşturulmasına ilişkin bir hüküm bulunmamaktadır.'");
			Raise ErrorText;
		ElsIf DetailsOfFoundation.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal Then
			ErrorText = NStr("vi = 'Tạo chứng từ ""Biên bản chênh lệch sau khi tiếp nhận"" khi mua không được chấp nhận.';
							|ru = 'Создание документа ""Акт о расхождениях после поступления"" при закупке по регл. учету не предусмотрено.';
							|en = 'Creation of ""Receipt discrepancy report"" document when purchasing by local accounting is not provided.'; fa = 'Creation of ""Receipt discrepancy report"" document when purchasing by local accounting is not provided.';
							|it = 'La generazione del documento ""Atto sulle discrepanze dopo l''arrivo"" con acquisto in contabilità regolamentata non è prevista.';
							|pl = 'Utworzenie dokumentu ""Protokół o odchyleniu po wpływie"" podczas zakupu wg ewidencji reglamentowanej nie jest przewidziane.';
							|tr = 'Kayıtlı bir satın alma işleminde ""Makbuzdan sonra tutarsızlık raporu"" oluşturmak için herhangi bir hüküm bulunmamaktadır.'");
			Raise ErrorText;
		EndIf;
		
	EndIf;
		
	// Filling in the header
	FillPropertyValues(ThisObject, DetailsOfFoundation);

	SeparatePurchase = New Array;
	SeparatePurchase.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	SeparatePurchase.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	SeparatePurchase.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	SeparatePurchase.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	
	If SeparatePurchase.Find(BusinessOperation) <> Undefined Then
		DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries;
	EndIf;
	
	Goods.Load(QueryResult[1].Unload());
	SetOfSeries.Load(QueryResult[2].Unload());
	
EndProcedure

Procedure FillInFactOnQualityControlReport(ActOfFoundation)
	
	KeyOfFillingIsToControlQuality = "Products,Warehouse";
	
	Query = New Query();
	ControlledLotReference = Common.ObjectAttributeValue(ActOfFoundation, "ControlledLotReference");
	Query.SetParameter("ControlledLotReference", ControlledLotReference);
	Query.SetParameter("ActOfFoundation", ActOfFoundation);
	Query.SetParameter("DocumentWarehouses", Goods.Unload(, "Warehouse").UnloadColumn("Warehouse"));
	Query.Text =
		"SELECT DISTINCT
		|	Goods.Warehouse AS Warehouse
		|FROM
		|	Document.GoodsQualityControlCertificate.Goods AS Goods
		|WHERE
		|	Goods.Ref = &ActOfFoundation
		|		AND Goods.Warehouse IN(&DocumentWarehouses)
		|;
		|
		|/////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Products AS Products
		|FROM
		|	Document.GoodsQualityControlCertificate.Goods AS Goods
		|WHERE
		|	Goods.Ref = &ActOfFoundation
		|	AND Goods.Warehouse IN(&DocumentWarehouses)";
	ResultsPackage = Query.ExecuteBatch();
	Warehouses = ResultsPackage[0].Unload();
	GoodsOfQualityControlAct = ResultsPackage[1].Unload();
	
	ResultingTable = Goods.Unload(New Array).CopyColumns();
	ResultingSeriesTable = ResultingTable.CopyColumns();
	
	For Each TableRow In Warehouses Do
		
		FactOfAcceptance = Documents.DiscrepancyReportFollowingReceipt.FillActual(
			ThisObject,
			TableRow.Warehouse,
			Documents.GoodsQualityControlCertificate,
			ActOfFoundation);
			
		CommonClientServer.SupplementTable(FactOfAcceptance.ResultingTable, ResultingTable);
		CommonClientServer.SupplementTable(FactOfAcceptance.ResultingSeriesTable, ResultingSeriesTable);
		
	EndDo;
	
	DocumentGoods = Goods.Unload();
	Series_Document = SetOfSeries.Unload();
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(DocumentGoods, StructureOfActions);
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
	
	CurrentTable = ResultingTable;
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
	
	CurrentTable = ResultingSeriesTable;
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
	
	SeriesSpecificationParameters = Documents.DiscrepancyReportFollowingReceipt.SeriesSpecificationParameters(ThisObject);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	Documents.DiscrepancyReportFollowingReceipt.UpdateDependentDetailsAfterFillingInFactOfAcceptance(ThisObject);
	
EndProcedure

Function RequestTextBasedOnReceipt()

	Return "
	|SELECT TOP 1
	|	NOT VendorInvoice.Posted AS ThereAreErrorsPosted,
	|	VendorInvoice.Ref AS DocumentBasis,
	|	VendorInvoice.Organization,
	|	VendorInvoice.Counterparty,
	|	VendorInvoice.Manager,
	|	VendorInvoice.VATTaxation,
	|	VendorInvoice.Partner,
	|	VendorInvoice.Currency,
	|	VendorInvoice.BusinessOperation,
	|	VendorInvoice.PriceIncludesVAT,
	|	VendorInvoice.Contract,
	|	VendorInvoice.Terms,
	|	VendorInvoice.Department
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|WHERE
	|	VendorInvoice.Ref IN (&Basis)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED
	|	PurchaseOfGoodsServicesGoods.Products,
	|	PurchaseOfGoodsServicesGoods.PartnerProducts,
	|	PurchaseOfGoodsServicesGoods.Characteristic,
	|	PurchaseOfGoodsServicesGoods.Series,
	|	PurchaseOfGoodsServicesGoods.Purpose,
	|	PurchaseOfGoodsServicesGoods.Package,
	|	PurchaseOfGoodsServicesGoods.NumberOfPackages,
	|	PurchaseOfGoodsServicesGoods.Count,
	|	PurchaseOfGoodsServicesGoods.VendorPriceKind,
	|	CASE
	|		WHEN PurchaseOfGoodsServicesGoods.NumberOfPackages = 0
	|			THEN PurchaseOfGoodsServicesGoods.Price
	|		ELSE
	|			CAST(PurchaseOfGoodsServicesGoods.Sum / PurchaseOfGoodsServicesGoods.NumberOfPackages AS NUMBER(31,2))
	|	END AS Price,
	|	PurchaseOfGoodsServicesGoods.Sum,
	|	PurchaseOfGoodsServicesGoods.VATRate,
	|	PurchaseOfGoodsServicesGoods.Warehouse,
	|	PurchaseOfGoodsServicesGoods.VATAmount,
	|	PurchaseOfGoodsServicesGoods.AmountIncludingVAT,
	|	PurchaseOfGoodsServicesGoods.BatchesIndicationStatus,
	|	PurchaseOfGoodsServicesGoods.Ref AS DocumentBasis,
	|	PurchaseOfGoodsServicesGoods.PurchaseOrder AS PurchaseOrder,
	|	PurchaseOfGoodsServicesGoods.RowCode AS RowCode,
	|	TRUE AS FilledUsingBaseDocument,
	|	PurchaseOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackagesByDocument,
	|	PurchaseOfGoodsServicesGoods.Count AS CountByDocument,
	|	PurchaseOfGoodsServicesGoods.Sum AS SumByDocument,
	|	PurchaseOfGoodsServicesGoods.VATAmount AS VATAmountByDocument,
	|	PurchaseOfGoodsServicesGoods.AmountIncludingVAT AS AmountIncludingVATByDocument, 
	|	PurchaseOfGoodsServicesGoods.ExpenseItem AS ExpenseItem,
	|	PurchaseOfGoodsServicesGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	PurchaseOfGoodsServicesGoods.Certificate AS Certificate,
	|	PurchaseOfGoodsServicesGoods.SalesOpportunity AS SalesOpportunity,
	|	PurchaseOfGoodsServicesGoods.Department AS Department,
	|	PurchaseOfGoodsServicesGoods.CCDNumber AS CCDNumber,
	|	PurchaseOfGoodsServicesGoods.PassportNumber AS PassportNumber,
	|	PurchaseOfGoodsServicesGoods.ToExpenseAs AS ToExpenseAs
	|FROM
	|	Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|WHERE
	|	PurchaseOfGoodsServicesGoods.Ref IN (&Basis)
	|	AND PurchaseOfGoodsServicesGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|ORDER BY
	|	DocumentBasis,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT ALLOWED
	|	PurchaseOfGoodsServicesSeries.Series          AS Series,
	|	PurchaseOfGoodsServicesSeries.Count     AS Count,
	|	PurchaseOfGoodsServicesSeries.Count     AS CountByDocument,
	|	PurchaseOfGoodsServicesSeries.Products   AS Products,
	|	PurchaseOfGoodsServicesSeries.Characteristic AS Characteristic,
	|	PurchaseOfGoodsServicesSeries.Purpose     AS Purpose,
	|	PurchaseOfGoodsServicesSeries.Warehouse          AS Warehouse,
	|	PurchaseOfGoodsServicesSeries.Ref         AS DocumentBasis,
	|	TRUE                                      AS FilledUsingBaseDocument
	|FROM
	|	Document.VendorInvoice.SetOfSeries AS PurchaseOfGoodsServicesSeries
	|WHERE
	|	PurchaseOfGoodsServicesSeries.Ref IN (&Basis)
	|	AND PurchaseOfGoodsServicesSeries.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|";

EndFunction

Function TextOfRequestOnBasisOfAcceptanceForStorage()

	Return "
	|SELECT TOP 1
	|	NOT GoodsReceiptForStorage.Posted                                 AS ThereAreErrorsPosted,
	|	GoodsReceiptForStorage.Ref                                      AS DocumentBasis,
	|	GoodsReceiptForStorage.Organization                                 AS Organization,
	|	GoodsReceiptForStorage.Counterparty                                  AS Counterparty,
	|	GoodsReceiptForStorage.Manager                                    AS Manager,
	|	GoodsReceiptForStorage.Partner                                     AS Partner,
	|	GoodsReceiptForStorage.Currency                                      AS Currency,
	|	GoodsReceiptForStorage.BusinessOperation                       AS BusinessOperation,
	|	GoodsReceiptForStorage.Contract                                     AS Contract,
	|	GoodsReceiptForStorage.Terms                                  AS Terms,
	|	GoodsReceiptForStorage.Department                               AS Department,
	|	VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATTaxation
	|FROM
	|	Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
	|WHERE
	|	GoodsReceiptForStorage.Ref IN (&Basis)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT ALLOWED
	|	AcceptanceOfGoodsForStorageGoods.Products             AS Products,
	|	AcceptanceOfGoodsForStorageGoods.PartnerProducts   AS PartnerProducts,
	|	AcceptanceOfGoodsForStorageGoods.Characteristic           AS Characteristic,
	|	AcceptanceOfGoodsForStorageGoods.Series                    AS Series,
	|	AcceptanceOfGoodsForStorageGoods.Purpose               AS Purpose,
	|	AcceptanceOfGoodsForStorageGoods.Package                 AS Package,
	|	AcceptanceOfGoodsForStorageGoods.NumberOfPackages       AS NumberOfPackages,
	|	AcceptanceOfGoodsForStorageGoods.Count               AS Count,
	|	AcceptanceOfGoodsForStorageGoods.Ref.VendorPriceKind AS VendorPriceKind,
	|	CASE
	|		WHEN AcceptanceOfGoodsForStorageGoods.NumberOfPackages = 0
	|			THEN AcceptanceOfGoodsForStorageGoods.Price
	|		ELSE
	|			CAST(AcceptanceOfGoodsForStorageGoods.Sum / AcceptanceOfGoodsForStorageGoods.NumberOfPackages AS NUMBER(31,2))
	|	END                                                   AS Price,
	|	AcceptanceOfGoodsForStorageGoods.Sum                    AS Sum,
	|	VALUE(Catalog.VATRates.EmptyRef)             AS VATRate,
	|	AcceptanceOfGoodsForStorageGoods.Warehouse                    AS Warehouse,
	|	0                                                       AS VATAmount,
	|	0                                                       AS AmountIncludingVAT,
	|	AcceptanceOfGoodsForStorageGoods.BatchesIndicationStatus      AS BatchesIndicationStatus,
	|	AcceptanceOfGoodsForStorageGoods.Ref                   AS DocumentBasis,
	|	AcceptanceOfGoodsForStorageGoods.PurchaseOrder          AS PurchaseOrder,
	|	AcceptanceOfGoodsForStorageGoods.RowCode                AS RowCode,
	|	TRUE                                                  AS FilledUsingBaseDocument,
	|	AcceptanceOfGoodsForStorageGoods.NumberOfPackages       AS NumberOfPackagesByDocument,
	|	AcceptanceOfGoodsForStorageGoods.Count               AS CountByDocument,
	|	AcceptanceOfGoodsForStorageGoods.Sum                    AS SumByDocument,
	|	0                                                       AS VATAmountByDocument,
	|	0                                                       AS AmountIncludingVATByDocument,
	|	AcceptanceOfGoodsForStorageGoods.SalesOpportunity                   AS SalesOpportunity,
	|	AcceptanceOfGoodsForStorageGoods.CCDNumber                 AS CCDNumber
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS AcceptanceOfGoodsForStorageGoods
	|WHERE
	|	AcceptanceOfGoodsForStorageGoods.Ref IN (&Basis)
	|ORDER BY
	|	DocumentBasis,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT ALLOWED
	|	AcceptanceOfGoodsForStorageOfSeries.Series          AS Series,
	|	AcceptanceOfGoodsForStorageOfSeries.Count     AS Count,
	|	AcceptanceOfGoodsForStorageOfSeries.Count     AS CountByDocument,
	|	AcceptanceOfGoodsForStorageOfSeries.Products   AS Products,
	|	AcceptanceOfGoodsForStorageOfSeries.Characteristic AS Characteristic,
	|	AcceptanceOfGoodsForStorageOfSeries.Purpose     AS Purpose,
	|	AcceptanceOfGoodsForStorageOfSeries.Warehouse          AS Warehouse,
	|	AcceptanceOfGoodsForStorageOfSeries.Ref         AS DocumentBasis,
	|	TRUE                                       AS FilledUsingBaseDocument
	|FROM
	|	Document.GoodsReceiptForStorage.SetOfSeries AS AcceptanceOfGoodsForStorageOfSeries
	|WHERE
	|	AcceptanceOfGoodsForStorageOfSeries.Ref IN (&Basis)";
	
EndFunction

Function TextOfRequestBasedOnReceiptFromCustodian()
	
	Return "
	|SELECT TOP 1
	|	NOT ReceiptFromTheCustodian.Posted                                   AS ThereAreErrorsPosted,
	|	ReceiptFromTheCustodian.Ref                                        AS DocumentBasis,
	|	ReceiptFromTheCustodian.Organization                                   AS Organization,
	|	ReceiptFromTheCustodian.Counterparty                                    AS Counterparty,
	|	ReceiptFromTheCustodian.Manager                                      AS Manager,
	|	ReceiptFromTheCustodian.Partner                                       AS Partner,
	|	ReceiptFromTheCustodian.Currency                                        AS Currency,
	|	ReceiptFromTheCustodian.BusinessOperation                         AS BusinessOperation,
	|	FALSE                                                                 AS PriceIncludesVAT,
	|	ReceiptFromTheCustodian.Contract                                       AS Contract,
	|	ReceiptFromTheCustodian.Terms                                    AS Terms,
	|	ReceiptFromTheCustodian.Department                                 AS Department,
	|	VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATTaxation
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian AS ReceiptFromTheCustodian
	|WHERE
	|	ReceiptFromTheCustodian.Ref IN (&Basis)
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT ALLOWED
	|	CASE
	|		WHEN GoodsReceipts.Damage
	|			THEN GoodsReceipts.ProductsRecordingAsReceived
	|		ELSE GoodsReceipts.Products
	|	END AS Products,
	|	CASE
	|		WHEN GoodsReceipts.Damage
	|			THEN GoodsReceipts.CharacteristicRecordingAsReceived
	|		ELSE GoodsReceipts.Characteristic
	|	END AS Characteristic,
	|	GoodsReceipts.Series               AS Series,
	|	GoodsReceipts.Purpose          AS Purpose,
	|	GoodsReceipts.Package            AS Package,
	|	GoodsReceipts.NumberOfPackages  AS NumberOfPackages,
	|	GoodsReceipts.Count          AS Count,
	|	CASE
	|		WHEN GoodsReceipts.NumberOfPackages = 0
	|			THEN GoodsReceipts.Price
	|		ELSE
	|			CAST(GoodsReceipts.Sum / GoodsReceipts.NumberOfPackages AS NUMBER(31, 2))
	|	END                                 AS Price,
	|	GoodsReceipts.Sum               AS Sum,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate,
	|	ReceiptFromTheCustodian.Warehouse          AS Warehouse,
	|	0                                     AS VATAmount,
	|	GoodsReceipts.Sum               AS AmountIncludingVAT,
	|	GoodsReceipts.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	GoodsReceipts.Ref              AS DocumentBasis,
	|	UNDEFINED                          AS DocumentSalesOfGoodsAndServices,
	|	GoodsReceipts.RowCode           AS RowCode,
	|	TRUE                                AS FilledUsingBaseDocument,
	|	GoodsReceipts.NumberOfPackages  AS NumberOfPackagesByDocument,
	|	GoodsReceipts.Count          AS CountByDocument,
	|	GoodsReceipts.Sum               AS SumByDocument,
	|	0                                     AS VATAmountByDocument,
	|	GoodsReceipts.Sum               AS AmountIncludingVATByDocument,
	|	GoodsReceipts.ReferenceOrder        AS PurchaseOrder,
	|	GoodsReceipts.CCDNumber            AS CCDNumber
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsReceipts
	|		LEFT JOIN Document.ReceiptOfGoodsFromCustodian AS ReceiptFromTheCustodian
	|		ON GoodsReceipts.Ref = ReceiptFromTheCustodian.Ref
	|WHERE
	|	GoodsReceipts.Ref IN (&Basis)
	|ORDER BY
	|	DocumentBasis,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT ALLOWED
	|	SeriesReceipts.Series          AS Series,
	|	SeriesReceipts.Count     AS Count,
	|	SeriesReceipts.Count     AS CountByDocument,
	|	CASE
	|		WHEN GoodsReceipts.Damage
	|			THEN GoodsReceipts.ProductsRecordingAsReceived
	|		ELSE GoodsReceipts.Products
	|	END AS Products,
	|	CASE
	|		WHEN GoodsReceipts.Damage
	|			THEN GoodsReceipts.CharacteristicRecordingAsReceived
	|		ELSE GoodsReceipts.Characteristic
	|	END AS Characteristic,
	|	SeriesReceipts.Purpose     AS Purpose,
	|	ReceiptFromTheCustodian.Warehouse    AS Warehouse,
	|	SeriesReceipts.Ref         AS DocumentBasis,
	|	TRUE                          AS FilledUsingBaseDocument,
	|	MAX(GoodsReceipts.BatchesIndicationStatus) AS BatchesIndicationStatus
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.SetOfSeries AS SeriesReceipts
	|		LEFT JOIN Document.ReceiptOfGoodsFromCustodian AS ReceiptFromTheCustodian
	|		ON SeriesReceipts.Ref = ReceiptFromTheCustodian.Ref
	|		
	|		INNER JOIN Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsReceipts
	|		ON SeriesReceipts.Ref = GoodsReceipts.Ref
	|			AND SeriesReceipts.Products = GoodsReceipts.Products
	|			AND SeriesReceipts.Characteristic = GoodsReceipts.Characteristic
	|			AND SeriesReceipts.Purpose = GoodsReceipts.Purpose
	|WHERE
	|	SeriesReceipts.Ref IN (&Basis)
	|	AND GoodsReceipts.Ref IN (&Basis)
	|	AND SeriesReceipts.Count <> 0
	|
	|GROUP BY
	|	SeriesReceipts.Series,
	|	CASE
	|		WHEN GoodsReceipts.Damage
	|			THEN GoodsReceipts.ProductsRecordingAsReceived
	|		ELSE GoodsReceipts.Products
	|	END,
	|	CASE
	|		WHEN GoodsReceipts.Damage
	|			THEN GoodsReceipts.CharacteristicRecordingAsReceived
	|		ELSE GoodsReceipts.Characteristic
	|	END,
	|	SeriesReceipts.Purpose,
	|	ReceiptFromTheCustodian.Warehouse,
	|	SeriesReceipts.Ref,
	|	SeriesReceipts.Count
	|
	|HAVING
	|	MAX(GoodsReceipts.BatchesIndicationStatus) IN(2, 4, 6, 8, 10)";
	
EndFunction

Function RequestTextBasedOnRefund()

	Return "
	|SELECT TOP 1 ALLOWED
	|	NOT ReturnOfGoodsFromCustomer.Posted AS ThereAreErrorsPosted,
	|	ReturnOfGoodsFromCustomer.Ref AS DocumentBasis,
	|	ReturnOfGoodsFromCustomer.Organization,
	|	ReturnOfGoodsFromCustomer.Counterparty,
	|	ReturnOfGoodsFromCustomer.Manager,
	|	ReturnOfGoodsFromCustomer.VATTaxation,
	|	ReturnOfGoodsFromCustomer.Partner,
	|	ReturnOfGoodsFromCustomer.Currency,
	|	ReturnOfGoodsFromCustomer.BusinessOperation,
	|	ReturnOfGoodsFromCustomer.PriceIncludesVAT,
	|	ReturnOfGoodsFromCustomer.Contract,
	|	ReturnOfGoodsFromCustomer.ContactPerson,
	|	ReturnOfGoodsFromCustomer.Terms,
	|	ReturnOfGoodsFromCustomer.Department,
	|	FALSE AS AgreementIsAvailableToExternalUsers
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	|WHERE
	|	ReturnOfGoodsFromCustomer.Ref IN (&Basis)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	CASE
	|		WHEN ReturnOfGoodsFromCustomerGoods.Damage
	|			THEN ReturnOfGoodsFromCustomerGoods.ProductsRecordingAsReceived
	|		ELSE ReturnOfGoodsFromCustomerGoods.Products
	|	END AS Products,
	|	CASE
	|		WHEN ReturnOfGoodsFromCustomerGoods.Damage
	|			THEN ReturnOfGoodsFromCustomerGoods.CharacteristicRecordingAsReceived
	|		ELSE ReturnOfGoodsFromCustomerGoods.Characteristic
	|	END AS Characteristic,
	|	ReturnOfGoodsFromCustomerGoods.Series,
	|	ReturnOfGoodsFromCustomerGoods.Purpose AS Purpose,
	|	ReturnOfGoodsFromCustomerGoods.Package AS Package,
	|	ReturnOfGoodsFromCustomerGoods.NumberOfPackages AS NumberOfPackages,
	|	ReturnOfGoodsFromCustomerGoods.Count AS Count,
	|	ReturnOfGoodsFromCustomerGoods.Price AS Price,
	|	ReturnOfGoodsFromCustomerGoods.Sum AS Sum,
	|	ReturnOfGoodsFromCustomerGoods.VATRate AS VATRate,
	|	ReturnOfGoodsFromCustomerGoods.VATAmount AS VATAmount,
	|	ReturnOfGoodsFromCustomerGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	ReturnOfGoodsFromCustomerGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	ReturnOfGoodsFromCustomerGoods.Ref AS DocumentBasis,
	|	TRUE AS FilledUsingBaseDocument,
	|	ReturnOfGoodsFromCustomerGoods.NumberOfPackages AS NumberOfPackagesByDocument,
	|	ReturnOfGoodsFromCustomerGoods.Count AS CountByDocument,
	|	ReturnOfGoodsFromCustomerGoods.Sum AS SumByDocument,
	|	ReturnOfGoodsFromCustomerGoods.VATAmount AS VATAmountByDocument,
	|	ReturnOfGoodsFromCustomerGoods.AmountIncludingVAT AS AmountIncludingVATByDocument,
	|	ReturnOfGoodsFromCustomerGoods.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	ReturnOfGoodsFromCustomerGoods.RowCode AS RowCode,
	|	ReturnOfGoodsFromCustomerGoods.Warehouse AS Warehouse,
	|	ReturnOfGoodsFromCustomer.RequestForReturnOfGoodsFromCustomer AS PurchaseOrder,
	|	ReturnOfGoodsFromCustomerGoods.CCDNumber AS CCDNumber
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS ReturnOfGoodsFromCustomerGoods
	|		INNER JOIN Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	|		ON ReturnOfGoodsFromCustomerGoods.Ref = ReturnOfGoodsFromCustomer.Ref
	|WHERE
	|	ReturnOfGoodsFromCustomerGoods.Ref IN (&Basis)
	|ORDER BY
	|	DocumentBasis,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	SeriesTable.Count AS CountByDocument,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN SeriesTable.ProductsRecordingAsReceived
	|		ELSE SeriesTable.Products
	|	END AS Products,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN SeriesTable.CharacteristicRecordingAsReceived
	|		ELSE SeriesTable.Characteristic
	|	END AS Characteristic,
	|	SeriesTable.Warehouse AS Warehouse,
	|	SeriesTable.Ref AS DocumentBasis,
	|	TRUE AS FilledUsingBaseDocument,
	|	SeriesTable.Purpose AS Purpose,
	|	MAX(GoodsTable.BatchesIndicationStatus) AS BatchesIndicationStatus
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.SetOfSeries AS SeriesTable
	|		INNER JOIN Document.ReturnOfGoodsFromCustomer.Goods AS GoodsTable
	|		ON SeriesTable.Ref = GoodsTable.Ref
	|			AND SeriesTable.Products = GoodsTable.Products
	|			AND SeriesTable.Characteristic = GoodsTable.Characteristic
	|			AND SeriesTable.ProductsRecordingAsReceived = GoodsTable.ProductsRecordingAsReceived
	|			AND SeriesTable.CharacteristicRecordingAsReceived = GoodsTable.CharacteristicRecordingAsReceived
	|			AND SeriesTable.Purpose = GoodsTable.Purpose
	|WHERE
	|	SeriesTable.Ref IN (&Basis)
	|	AND GoodsTable.Ref IN (&Basis)
	|	AND SeriesTable.Count <> 0
	|
	|GROUP BY
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	SeriesTable.Series,
	|	SeriesTable.ProductsRecordingAsReceived,
	|	SeriesTable.CharacteristicRecordingAsReceived,
	|	SeriesTable.Purpose,
	|	GoodsTable.Damage,
	|	SeriesTable.Count,
	|	SeriesTable.Warehouse,
	|	SeriesTable.Ref
	|
	|HAVING
	|	MAX(GoodsTable.BatchesIndicationStatus) IN (2, 4, 6, 8, 10)";

EndFunction

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	
	If Not TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		ResponsiblePersonsServer.FillInManager_(ThisObject, False);
		If Not ValueIsFilled(Manager) Then
			Manager = Users.CurrentUser();
		EndIf;
		If Not ValueIsFilled(Department) Then
			Department = SettingsValueCached.UserDivision(Manager);
		EndIf;
	EndIf;
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	Status = Enums.StatusesOfDiscrepancyReport.NotApproved;
	
	If Not ValueIsFilled(GoodsReceiptOption) Then
		ReferenceOrder = DocumentBaseWhenFillingIn(FillingData);
		GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(ReferenceOrder, Contract);
	EndIf;
	
	If Not ValueIsFilled(Terms) Then
		
		If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer
			Or DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
			Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent Then
			
			Terms = Catalogs.TermsOfSale.EmptyRef();
			
		Else
			Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
		EndIf;
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.DiscrepancyReportFollowingReceipt.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	CompleteVATTaxation();
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

#Region PurchaseConditions

Procedure InitializePurchaseConditions()
	
	If Not GetFunctionalOption("UseTermsOfPurchases") Then
		FillInDefaultPurchaseConditions();
	EndIf;
	
EndProcedure

// Fills in the default purchase conditions in the report
//
Procedure FillInDefaultPurchaseConditions() Export
	
	If ValueIsFilled(Terms) Then
		Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
	EndIf;
	
	If ValueIsFilled (Partner) Then
		
		ArrayOfSelectionOperations = New Array;
		ArrayOfSelectionOperations.Add(Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
		ArrayOfSelectionOperations.Add(Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5);
		SelectionOperation = ?(ArrayOfSelectionOperations.Find(BusinessOperation) = Undefined,
							Undefined,
							BusinessOperation);
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SelectedAgreement",   Terms);
		FilterParameters.Insert("BusinessTransactions", SelectionOperation);
		
		DefaultPurchasingConditions = PurchasesServer.GetDefaultPurchaseTerms(Partner, FilterParameters);
		
		If DefaultPurchasingConditions <> Undefined Then
			
			If Terms <> DefaultPurchasingConditions.Terms
				And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
				
				Terms = DefaultPurchasingConditions.Terms;
				FillInTermsOfPurchase(DefaultPurchasingConditions);
				CompleteVATTaxation();
				
			Else
				Terms = DefaultPurchasingConditions.Terms;
			EndIf;
				
		Else
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
			
			If BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
				
				AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
				AddlParameters.ARAPCurrency = Currency;
				
				Contract = PurchasesServer.GetDefaultContract(
							ThisObject, 
							TollingSchemeClientServer.ContractBusinessTransaction(), 
							AddlParameters);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
EndProcedure

// Fills in the terms of sales under the agreement in the act
//
Procedure FillInTermsOfPurchaseUnderAgreement() Export
	
	PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms);
	FillInTermsOfPurchase(PurchaseConditions);
	CompleteVATTaxation();
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
EndProcedure

// Fills in the purchase conditions in the act
//
// Parameters:
//	PurchaseConditions - Structure - Structure to fill in.
//
Procedure FillInTermsOfPurchase(Val PurchaseConditions) Export
	
	If PurchaseConditions = Undefined Then
		Return;
	EndIf;
	
	Currency = PurchaseConditions.Currency;
	PriceIncludesVAT      = PurchaseConditions.PriceIncludesVAT;
	
	If ValueIsFilled(PurchaseConditions.Organization) And PurchaseConditions.Organization<>Organization Then
		Organization = PurchaseConditions.Organization;
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Counterparty) And PurchaseConditions.Counterparty <> Counterparty Then
		Counterparty = PurchaseConditions.Counterparty;
	EndIf;
	
	BusinessOperation = PurchaseConditions.BusinessOperation;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	ContractBusinessTransaction = ?(
				BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseFromVendorLocal")
				Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseViaAdvanceHolder"),
				PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier"),
				BusinessOperation);
				
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	AddlParameters.ARAPCurrency = Currency;
	Contract = PurchasesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, AddlParameters);
	
EndProcedure 

#EndRegion

#Region SalesTermsAndConditions

Procedure InitializeSalesConditions()
	
	If DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.HandlerForActionsBasedOnReportBaseType(TypeOfBaseDocumentForNonConformanceCertificate);
		ToUseTermsOfSales = Handler.ToUseTermsOfSales();
	Else
		ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	EndIf;
	
	If Not ToUseTermsOfSales Then
		FillInDefaultSalesConditions();
	EndIf;
	
EndProcedure

// Fills in the default sales terms in the document
//
Procedure FillInDefaultSalesConditions() Export
	
	Handler = Undefined;
	If DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.HandlerForActionsBasedOnReportBaseType(TypeOfBaseDocumentForNonConformanceCertificate);
		ToUseTermsOfSales = Handler.ToUseTermsOfSales();
	Else
		ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	EndIf;
	
	If ValueIsFilled(Partner) Or Not ToUseTermsOfSales Then
		
		BusinessTransactions = New Array();
		CustomerAgreementsAreApplicable = True;
		If Handler <> Undefined Then
			BusinessTransactions.Add(Handler.ContractBusinessTransaction());
			CustomerAgreementsAreApplicable = Handler.CustomerAgreementsAreApplicable();
		EndIf;
		
		FilterParameters = New Structure(
				"SelectedAgreement,
				|EmptyDocumentLink",
				Terms,
				Documents.DiscrepancyReportFollowingReceipt.EmptyRef());
		
		If BusinessTransactions.Count() > 0 Then
			FilterParameters.Insert("BusinessTransactions", BusinessTransactions);
		EndIf;
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
			Partner,
			FilterParameters,
			CustomerAgreementsAreApplicable);
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales 
				Or (Terms <> DefaultSalesTerms.Terms And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				CompleteVATTaxation();
			Else
				Terms = DefaultSalesTerms.Terms;
			EndIf;
			
		Else
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			Terms = Undefined;
		EndIf;
				
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
	CompleteVATTaxation();
	
EndProcedure

// Fills in the terms of sale in the document
//
// Parameters:
//	SalesTermsAndConditions       - Structure - Structure to fill in.
//	ProductSegment - CatalogRef.ProductSegments
//
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions, ProductSegment = Undefined) Export
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	Handler = Undefined;
	If DiscrepanciesClientServer.TypeOfBasisReceiptOfGoodsFromCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.ReceiptOfGoodsFromCustodian.HandlerForActionsBasedOnReportBaseType(TypeOfBaseDocumentForNonConformanceCertificate);
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Currency) Then
		Currency = SalesTermsAndConditions.Currency;
	EndIf;
	
	PriceIncludesVAT       = SalesTermsAndConditions.PriceIncludesVAT;
	ProductSegment   = SalesTermsAndConditions.ProductSegment;
	
	If Handler = Undefined Or Handler.CustomerAgreementsAreApplicable() Then
		BusinessOperation = SalesServer.GetRefundTransactionForSale(SalesTermsAndConditions.BusinessOperation);
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Organization) And SalesTermsAndConditions.Organization <> Organization Then
		Organization = SalesTermsAndConditions.Organization;
	EndIf;
	
	If Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.Counterparty) And SalesTermsAndConditions.Counterparty<>Counterparty Then
			Counterparty = SalesTermsAndConditions.Counterparty;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.ContactPerson) 
			And Not ValueIsFilled(ContactPerson) Then
			ContactPerson = SalesTermsAndConditions.ContactPerson;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
	If SalesTermsAndConditions.ContractsAreUsed <> Undefined And SalesTermsAndConditions.ContractsAreUsed Then
		
		If Handler = Undefined Then
			
			ContractBusinessTransaction = Undefined;
			If BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer Then
				ContractBusinessTransaction = Enums.BusinessTransactions.SaleToCustomer;
			ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
				ContractBusinessTransaction = Enums.BusinessTransactions.TransferToCommissionAgent;
			EndIf;
		
			Contract = SalesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, Currency);
			
		Else
			Contract = Handler.GetDefaultContract(ThisObject, True, False);
		EndIf;
		
	EndIf;

	CompleteVATTaxation();
	
EndProcedure

// Fills in the terms of sales under the agreement in the document
//
Procedure FillInTermsOfSalesUnderAgreement(ProductSegment = Undefined) Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
	FillIn_TermsOfSales(SalesTermsAndConditions, ProductSegment);
				CompleteVATTaxation();
	
EndProcedure

#EndRegion

Function DocumentBaseWhenFillingIn(FillingData)
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("DocumentBasis") Then
		DocumentBasis = FillingData.DocumentBasis;
	Else
		DocumentBasis = FillingData;
	EndIf;
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.ReturnOfGoodsFromCustomer")
			Or TypeOf(DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
		
		Return FillingData;
		
	ElsIf TypeOf(DocumentBasis) = Type("DocumentRef.GoodsReceiptForStorage")
		Or TypeOf(DocumentBasis) = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
		
		Return FillingData;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Other

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status to be set for the document
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	Status = Enums.StatusesOfDiscrepancyReport[NewStatus];
	
	Return CheckFilling();
	
EndFunction

Procedure CompleteVATTaxation()
	
	If DiscrepanciesClientServer.TypeOfBasisPurchaseOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		FillParameters = Documents.DiscrepancyReportFollowingReceipt.ParametersForFillingInVATTaxationPurchases(ThisObject);
		VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
		
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer Then
		
		FillParameters = Documents.DiscrepancyReportFollowingReceipt.ParametersForFillingInSalesVATTaxation(ThisObject);
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
		
	ElsIf DiscrepanciesClientServer.VATIsNotRecorded(TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
		
	EndIf;
	
EndProcedure

Function TypeOfBasisForActOfDiscrepancyOnBusinessTransaction(BusinessTransaction)
	
	If BusinessTransaction = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer
		Or BusinessTransaction = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustomer;
		
	ElsIf BusinessTransaction = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptForStorage;
	ElsIf BusinessTransaction = Enums.BusinessTransactions.ReturnFromCustodian Then
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian;
	ElsIf BusinessTransaction = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnFromCommissionAgent;
	ElsIf BusinessTransaction = Enums.BusinessTransactions.ReceiptFromToller2_5 Then
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsReceiptFromSubcontractor;
	ElsIf BusinessTransaction = Enums.BusinessTransactions.ReturnFromProcessingCompany2_5 Then
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromSubcontractor;
	ElsIf BusinessTransaction = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReceiptFromMaterialProvider;
	Else
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.VendorInvoice;
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
