#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	InitializeDocument();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	For Each String In Goods Do
		If Not ValueIsFilled(String.VATRate) Then
			String.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
		EndIf;
	EndDo;

	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.DiscrepancyReportFollowingShipment);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	RoundingParameters = Documents.DiscrepancyReportFollowingShipment.TSParametersForRounding();
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters["Goods"]);
	RoundingParameters = Documents.DiscrepancyReportFollowingShipment.TSParametersForRounding("ByDocument");
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters["Goods"]);
	
	DiscrepancyReportFollowingShipmentLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If IsNew() And Not ValueIsFilled(Author) Then
		Author = Users.AuthorizedUser();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DiscrepancyReportFollowingShipmentLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.AuthorizedUser();
	FilledInBasedOnDocument = False;
	
	If ValueIsFilled(FillingData) Then
		
		If TypeOf(FillingData) = Type("Structure") Then
			
			If FillingData.Property("DocumentBasis") Then
				 
				DocumentBasis = FillingData.DocumentBasis;
				ArrayOfBases = Undefined;
				If TypeOf(DocumentBasis) = Type("Array") And ValueIsFilled(DocumentBasis) Then
					ArrayOfBases = DocumentBasis;
					DocumentBasis = FillingData.DocumentBasis[0];
				EndIf;
				
				BasisType = TypeOf(DocumentBasis);
				If  BasisType = Type("DocumentRef.CustomerInvoice")
						Or BasisType = Type("DocumentRef.GoodsShipmentFromStorage")
						Or BasisType = Type("DocumentRef.TransferOfGoodsToBailee")
						Or BasisType = Type("DocumentRef.ReturnOfGoodsToVendor")
						Or BasisType = Type("DocumentRef.GoodsShipmentToCustomer") Then
					FilledInBasedOnDocument = True;
					FillInOnTheBasis(DocumentBasis);
					
				ElsIf ValueIsFilled(ArrayOfBases) Then
					FilledInBasedOnDocument = True;
					FillBasedOnArray(ArrayOfBases, DocumentBasis);
				Else
					FillInByPicking(FillingData);
				EndIf;
			Else
				FillInByPicking(FillingData);
			EndIf;
		
		ElsIf TypeOf(FillingData) = Type("DocumentRef.CustomerInvoice")
			Or TypeOf(FillingData) = Type("DocumentRef.GoodsShipmentFromStorage")
			Or TypeOf(FillingData) = Type("DocumentRef.TransferOfGoodsToBailee")
			Or TypeOf(FillingData) = Type("DocumentRef.ReturnOfGoodsToVendor")
			Or TypeOf(FillingData) = Type("DocumentRef.GoodsShipmentToCustomer") Then
			
			FilledInBasedOnDocument = True;
			FillInOnTheBasis(FillingData);
			PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
			
		EndIf;
		
	EndIf;
	
	If Not FilledInBasedOnDocument  Then
		
		If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
			Then
		
			InitializeSalesConditions();
		
		EndIf;
		
	EndIf;
	
	InitializeDocument(FillingData);

	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate)
		And (Not ValueIsFilled(VATTaxation) Or Not GetFunctionalOption("ToUseTermsOfSales"))
		And Not (BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			Or BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale) Then
		VATTaxation = SettingsValueCached.VATTaxation(Organization, , Contract, , Date);
	ElsIf DiscrepanciesClientServer.VATIsNotRecorded(TypeOfBaseDocumentForNonConformanceCertificate)
		And Not DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate) Then
		VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	EndIf;
	DiscrepancyReportFollowingShipmentLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	DiscrepanciesServer.CheckTypeOfReportSBasisWhenCreatingIt(ThisObject);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		NotCheckedAttributeArray.Add("VATTaxation");
		NotCheckedAttributeArray.Add("Goods.VATRate");
	EndIf;
	
	AnExternalUserIsAuthorized = TMCommonUseClientServer.AnExternalUserIsAuthorized();
	BaseTypeImplementation         = DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate);
	BaseTypeShipmentToCustomer    = DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate);
	
	If AnExternalUserIsAuthorized Then
		NotCheckedAttributeArray.Add("Goods.Products");
		NotCheckedAttributeArray.Add("Goods.VATRate");
	ElsIf DiscrepanciesClientServer.VATIsNotRecorded(TypeOfBaseDocumentForNonConformanceCertificate) Then
		NotCheckedAttributeArray.Add("Goods.VATRate");
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.Price");
	NotCheckedAttributeArray.Add("Goods.Warehouse");
	NotCheckedAttributeArray.Add("Goods.Action");
	NotCheckedAttributeArray.Add("Goods.NumberOfPackagesByDocument");
	NotCheckedAttributeArray.Add("Goods.NumberOfPackages");
	NotCheckedAttributeArray.Add("Goods.CountByDocument");
	NotCheckedAttributeArray.Add("Goods.Count");
	NotCheckedAttributeArray.Add("Goods.DescriptionText");
	NotCheckedAttributeArray.Add("Goods.SaleOfGoodsAndServices");
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
	                                            ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.DiscrepancyReportFollowingShipment),
	                                            Cancel,
	                                            NotCheckedAttributeArray);
	
	//Checking that the implementation is on order
	
	NotCheckedAttributeArray.Add("Goods.SalesOrder");
	NotCheckedAttributeArray.Add("Goods.RowCode");
	
	If AnExternalUserIsAuthorized Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	DocumentImplementations.SaleOfGoodsAndServices
		|INTO BasisDocuments
		|FROM
		|	&BasisDocuments AS DocumentImplementations
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	BasisDocuments.SaleOfGoodsAndServices
		|FROM
		|	BasisDocuments AS BasisDocuments
		|WHERE
		|	NOT BasisDocuments.SaleOfGoodsAndServices IN(&BlankRefs)";
		
		BlankRefs = New Array;
		BlankRefs.Add(Documents.CustomerInvoice.EmptyRef());
		BlankRefs.Add(Documents.TransferOfGoodsToBailee.EmptyRef());
		
		Query.SetParameter("BasisDocuments", Goods.Unload(,"SaleOfGoodsAndServices"));
		Query.SetParameter("BlankRefs",       BlankRefs);
		
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			NumberOfBaseImplementations = 0;
		Else
			NumberOfBaseImplementations = QueryResult.Select().Count();
		EndIf;
		
		For CurIndex__ = 0 To Goods.Count()-1 Do
			
			CurrentRow = Goods[CurIndex__];
			
			If Not ValueIsFilled(CurrentRow.Products) And Not ValueIsFilled(CurrentRow.DescriptionText) Then
				ErrorText = NStr("vi = 'Chưa điền trường ""Mô tả bằng văn bản"" tại dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Текстовое описание"" в строке %LineNumber% списка ""Товары""';
								|en = 'Text description in line %LineNumber% of the Item list is not filled in'; fa = 'Text description in line %LineNumber% of the Item list is not filled in';
								|it = 'Il campo ""Testo della descrizione"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
								|pl = 'Nie wypełniono pola ""Текстовое описание"" w wierszu %LineNumber% listy ""Товары""';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Metin açıklaması"" alanı doldurulmamış'");
				ErrorText =  StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
				
				CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "DescriptionText"),
				,
				Cancel)
			EndIf;
			
			If NumberOfBaseImplementations > 1 And Not ValueIsFilled(CurrentRow.SaleOfGoodsAndServices) Then
				
				TransferCertificate = DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate);
				
				ErrorText = NStr("vi = 'Chưa điền trường ""%SaleOfGoodsAndServices%"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""%SaleOfGoodsAndServices%"" в строке %LineNumber% списка ""Товары""';
								|en = '""%SaleOfGoodsAndServices%"" field in line %LineNumber% of the Item list is not filled in'; fa = '""%SaleOfGoodsAndServices%"" field in line %LineNumber% of the Item list is not filled in';
								|it = 'Non è stato compilato il campo ""%SaleOfGoodsAndServices%"" nella riga %LineNumber% dell''elenco ""Merci""';
								|pl = 'Pole ""%SaleOfGoodsAndServices%"" nie jest wypełnione w wierszu %LineNumber% listy „Produkty”';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""%SaleOfGoodsAndServices%"" alanı doldurulmamış'");
				ErrorText = StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
				ErrorText = StrReplace(ErrorText, "%SaleOfGoodsAndServices%", ?(Not TransferCertificate, NStr("vi = 'Bán hàng';
																												|ru = 'Реализация';
																												|en = 'Sales'; fa = 'فروش';
																												|it = 'Vendita';
																												|pl = 'Realizacja';
																												|tr = 'Satış'"), NStr("vi = 'Chuyển giao';
																																	|ru = 'Передача';
																																	|en = 'Transfer'; fa = 'انتقال';
																																	|it = 'Consegna';
																																	|pl = 'Przekazywanie';
																																	|tr = 'Transfer'")));
				
				CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "SaleOfGoodsAndServices"),
				,
				Cancel);
			EndIf;
			
			If Not CurrentRow.FilledInBySale
				And Not ValueIsFilled(CurrentRow.NumberOfPackages) Then
			
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
		
	Else
		
		ArrayOfImplementationsByOrder = New Array;
		ChecksOnOrderAreRequired = False;
		
		If BaseTypeImplementation Then
			
			Query = New Query;
			Query.Text = "
			|SELECT
			|	DocumentImplementations.SaleOfGoodsAndServices
			|INTO BasisDocuments
			|FROM
			|	&BasisDocuments AS DocumentImplementations
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED DISTINCT
			|	BasisDocuments.SaleOfGoodsAndServices
			|FROM
			|	BasisDocuments AS BasisDocuments
			|		INNER JOIN Document.CustomerInvoice AS CustomerInvoice
			|		ON BasisDocuments.SaleOfGoodsAndServices = CustomerInvoice.Ref
			|WHERE
			|	CustomerInvoice.OrderSales
			|
			|UNION ALL
			|
			|SELECT DISTINCT
			|	BasisDocuments.SaleOfGoodsAndServices
			|FROM
			|	BasisDocuments AS BasisDocuments
			|		INNER JOIN Document.TransferOfGoodsToBailee AS GoodsHandover
			|		ON BasisDocuments.SaleOfGoodsAndServices = GoodsHandover.Ref
			|WHERE
			|	GoodsHandover.TransferByOrders
			|";
			
			Query.SetParameter("BasisDocuments", Goods.Unload(,"SaleOfGoodsAndServices"));
			
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
				ChecksOnOrderAreRequired = True;
				ArrayOfImplementationsByOrder = QueryResult.Unload().UnloadColumn("SaleOfGoodsAndServices");
				OrderPresentation = NStr("vi = 'Đơn hàng của khách';
										|ru = 'Заказ клиента';
										|en = 'Sales order'; fa = 'سفارش فروش';
										|it = 'Ordine del cliente';
										|pl = 'Zamówienie klienta';
										|tr = 'Satış siparişi'");
			EndIf;
		
		ElsIf BaseTypeShipmentToCustomer Then
			
			Query = New Query;
			Query.Text = "
			|SELECT
			|	DocumentImplementations.SaleOfGoodsAndServices
			|INTO BasisDocuments
			|FROM
			|	&BasisDocuments AS DocumentImplementations
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED DISTINCT
			|	BasisDocuments.SaleOfGoodsAndServices
			|FROM
			|	BasisDocuments AS BasisDocuments
			|		INNER JOIN Document.GoodsShipmentToCustomer AS GoodsShipmentToCustomer
			|		ON BasisDocuments.SaleOfGoodsAndServices = GoodsShipmentToCustomer.Ref
			|		INNER JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsToCustomerItems
			|		ON BasisDocuments.SaleOfGoodsAndServices = ShipmentOfItemsToCustomerItems.Ref
			|WHERE
			|	GoodsShipmentToCustomer.ShipmentByOrders
			|	AND CASE
			|		WHEN ShipmentOfItemsToCustomerItems.SalesOrder REFS Document.SalesOrder
			|			THEN NOT CAST(ShipmentOfItemsToCustomerItems.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
			|		WHEN ShipmentOfItemsToCustomerItems.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
			|			THEN NOT CAST(ShipmentOfItemsToCustomerItems.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
			|		ELSE
			|			TRUE
			|	END
			|";
			
			Query.SetParameter("BasisDocuments", Goods.Unload(,"SaleOfGoodsAndServices"));
			
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
				ChecksOnOrderAreRequired = True;
				ArrayOfImplementationsByOrder = QueryResult.Unload().UnloadColumn("SaleOfGoodsAndServices");
				OrderPresentation = NStr("vi = 'Đơn hàng của khách';
										|ru = 'Заказ клиента';
										|en = 'Sales order'; fa = 'سفارش فروش';
										|it = 'Ordine del cliente';
										|pl = 'Zamówienie klienta';
										|tr = 'Satış siparişi'");
			EndIf;

		ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider Then
			
			Query = New Query;
			Query.Text = "
			|SELECT
			|	DocumentImplementations.SaleOfGoodsAndServices
			|INTO BasisDocuments
			|FROM
			|	&BasisDocuments AS DocumentImplementations
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED DISTINCT
			|	BasisDocuments.SaleOfGoodsAndServices
			|FROM
			|	BasisDocuments AS BasisDocuments
			|		INNER JOIN Document.GoodsShipmentFromStorage AS GoodsShipmentFromStorage
			|		ON BasisDocuments.SaleOfGoodsAndServices = GoodsShipmentFromStorage.Ref
			|WHERE
			|	GoodsShipmentFromStorage.ByOrder
			|";
			
			Query.SetParameter("BasisDocuments", Goods.Unload(, "SaleOfGoodsAndServices"));
			
			QueryResult = Query.Execute();
			If Not QueryResult.IsEmpty() Then
				ChecksOnOrderAreRequired = True;
				ArrayOfImplementationsByOrder = QueryResult.Unload().UnloadColumn("SaleOfGoodsAndServices");
				OrderPresentation = NStr("vi = 'Đơn hàng của bên đặt gia công';
										|ru = 'Заказ давальца';
										|en = 'Subcontracting sales order'; fa = 'سفارش فروش پیمانکاری فرعی';
										|it = 'Ordine del committente';
										|pl = 'Zamówienie dostawcy';
										|tr = 'Sağlayıcı siparişi'");
			EndIf;
			
		EndIf;
		
		For CurIndex__ = 0 To Goods.Count()-1 Do
			
			CurrentRow = Goods[CurIndex__];
			
			If ChecksOnOrderAreRequired Then 
				If Not ValueIsFilled(CurrentRow["SalesOrder"]) And ValueIsFilled(CurrentRow.SaleOfGoodsAndServices)
					And ArrayOfImplementationsByOrder.Find(CurrentRow.SaleOfGoodsAndServices) <> Undefined Then
					
					ErrorText = StrTemplate(
									NStr("vi = 'Chưa điền trường ""%1"" trong dòng ""%2"" của danh sách ""Hàng hóa""';
										|ru = 'Не заполнено поле ""%1"" в строке %2 списка ""Товары""';
										|en = 'The ""%1"" field in line %2 of the ""Goods"" list is not filled'; fa = 'The ""%1"" field in line %2 of the ""Goods"" list is not filled';
										|it = 'Non è compilato il campo ""%1"" nella riga %2 dell''elenco ""Merci""';
										|pl = 'Nie wypełniono pola ""%1"" w wierszu ""%2"" listy ""Towary""';
										|tr = '""Ürünler"" listesinin %2 satırındaki ""%1"" alanı doldurulmamış'"),
									OrderPresentation,
									CurrentRow.LineNumber);
					
					CommonClientServer.MessageToUser(
					ErrorText,
					ThisObject,
					CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "SalesOrder"),
					,
					Cancel);
					
					ErrorText = NStr("vi = 'Chưa điền trường ""Mã dòng"" tại dòng %LineNumber% của danh sách ""Hàng hóa""';
									|ru = 'Не заполнено поле ""Код строки"" в строке %LineNumber% списка ""Товары""';
									|en = '""Line code"" in line %LineNumber% of the Item list is not filled in'; fa = '""Line code"" in line %LineNumber% of the Item list is not filled in';
									|it = 'Il campo ""Codice di riga"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
									|pl = 'Nie wypełniono pola ""Код строки"" w wierszu %LineNumber% listy ""Товары""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Satır kodu"" alanı doldurulmamış'");
					ErrorText =  StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
					
					CommonClientServer.MessageToUser(
					ErrorText,
					ThisObject,
					CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "SalesOrder"),
					,
					Cancel);
					
				EndIf;
			EndIf;
			
			If CurrentRow.FilledInBySale
				And Not ValueIsFilled(CurrentRow.NumberOfPackagesByDocument) Then
				
				ErrorText = NStr("vi = 'Chưa điền trường ""Số lượng theo chứng từ"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Количество по документу"" в строке %LineNumber% списка ""Товары""';
								|en = '""Quantity by document"" in line %LineNumber% of the Item list is not filled in'; fa = '""Quantity by document"" in line %LineNumber% of the Item list is not filled in';
								|it = 'Il campo ""Quantità per il documento"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
								|pl = 'Nie wypełniono pola ""Количество по документу"" w wierszu %LineNumber% listy ""Товары""';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Belge miktarı"" alanı doldurulmamış'");
				ErrorText =  StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
				
				CommonClientServer.MessageToUser(
					ErrorText,
					ThisObject,
					CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "NumberOfPackagesByDocument"),
					,
					Cancel);
				
			EndIf;
			
			If Not CurrentRow.FilledInBySale
				And Not ValueIsFilled(CurrentRow.Sum)
				And Not BusinessOperation = Enums.BusinessTransactions.TransferToToller2_5
				And Not BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
				And Not BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5
				And Not BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
				And Not BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
				
				ErrorText = NStr("vi = 'Chưa điền trường ""Số tiền"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Сумма"" в строке %LineNumber% списка ""Товары""';
								|en = '""Amount"" in line %LineNumber% of the ""Goods"" list is not filled in'; fa = '""Amount"" in line %LineNumber% of the ""Goods"" list is not filled in';
								|it = 'Il campo ""Totale"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
								|pl = 'Pole ""Wartość"" w wierszu %LineNumber% listy ""Wiersze pozycji"" nie jest wypełnione';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Tutar"" alanı doldurulmamış'");
				ErrorText =  StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
				
				CommonClientServer.MessageToUser(
					ErrorText,
					ThisObject,
					CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "Sum"),
					,
					Cancel);
				
			EndIf;
			
			If Status <> Enums.StatusesOfDiscrepancyReport.NotApproved 
				And (CurrentRow.NumberOfPackages - CurrentRow.NumberOfPackagesByDocument) <> 0 
				And Not ValueIsFilled(CurrentRow["Action"]) Then
				
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
				
			If Not CurrentRow.FilledInBySale
				And Not ValueIsFilled(CurrentRow.NumberOfPackages) Then
			
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
			
			If Not ValueIsFilled(CurrentRow.SaleOfGoodsAndServices)
				And Status <> Enums.StatusesOfDiscrepancyReport.NotApproved Then
				
				If TypeOfBaseDocumentForNonConformanceCertificate = TransferToCommissionAgent.TypeOfBasisOfAct() Then
					ColumnName = NStr("vi = 'Chuyển đi ký gửi';
										|ru = 'Передача на комиссию';
										|en = 'Consignment sales'; fa = 'فروش امانی';
										|it = 'Trasferimento in conto vendita';
										|pl = 'Przekazanie do komisu';
										|tr = 'Konsinye satış'");
				ElsIf BaseTypeImplementation Then
					ColumnName = NStr("vi = 'Bán hàng';
										|ru = 'Реализация';
										|en = 'Sales'; fa = 'فروش';
										|it = 'Vendita';
										|pl = 'Realizacja';
										|tr = 'Satış'");
				ElsIf BaseTypeShipmentToCustomer Then
					ColumnName = NStr("vi = 'Xuất kho cho khách';
										|ru = 'Отгрузка клиенту';
										|en = 'Outbound delivery — Wholesale'; fa = 'تحویل خروجی — عمده‌فروشی';
										|it = 'Spedizione al cliente';
										|pl = 'Wysyłka do klienta';
										|tr = 'Müşteriye sevkiyat'");
				Else
					ColumnName = NStr("vi = 'Trả lại hàng cho nhà cung cấp';
										|ru = 'Возврат поставщику';
										|en = 'Return to vendor'; fa = 'مرجوعی به تأمین‌کننده';
										|it = 'Reso al fornitore';
										|pl = 'Zwrot do dostawcy ';
										|tr = 'Tedarikçiye iade'");
				EndIf;
				
				ErrorText = StrTemplate(NStr("vi = 'Chưa điền trường ""%1"" trong dòng ""%2"" của danh sách ""Hàng hóa"" ';
											|ru = 'Не заполнено поле ""%1"" в строке ""%2"" списка ""Товары""';
											|en = '""%1"" is required in line %2 of the Item list'; fa = '""%1"" is required in line %2 of the Item list';
											|it = 'Il campo ""%1"" nella riga ""%2"" dell''elenco ""Merci"" non è compilato';
											|pl = 'Nie wypełniono pola ""%1"" w wierszu ""%2"" listy ""Товары""';
											|tr = '""Ürünler"" listesinin %2 satırındaki ""%1"" alanı doldurulmamış'"), ColumnName, CurrentRow.LineNumber);
				
				CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "SaleOfGoodsAndServices"),
				,
				Cancel);
				
			EndIf;
		
			NotCheckedAttributeArray.Add("Goods.Price");
			
			DocumentBasis = Undefined;
			MatchingProductsType = Common.ObjectsAttributeValue(Goods.UnloadColumn("Products"), "ItemsType");
			
			If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice
				Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer
				Then
				
				If Not ValueIsFilled(CurrentRow.Price) Then
				
					ErrorText = NStr("vi = 'Chưa điền trường ""Giá"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
									|ru = 'Не заполнено поле ""Цена"" в строке %LineNumber% списка ""Товары""';
									|en = '""Price"" in line %LineNumber% of the ""Goods"" list is not filled in'; fa = '""Price"" in line %LineNumber% of the ""Goods"" list is not filled in';
									|it = 'Il campo ""Prezzo"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
									|pl = 'Pole ""Cena"" w wierszu %LineNumber% listy ""Wiersze pozycji"" nie jest wypełnione';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Fiyat"" alanı doldurulmamış'");
					ErrorText =  StrReplace(ErrorText, "%LineNumber%", CurrentRow.LineNumber);
					
					If CurrentRow.FilledInBySale
						And TypeOfBaseDocumentForNonConformanceCertificate <>
							Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer Then
						
						If DocumentBasis <> CurrentRow.SaleOfGoodsAndServices Then
							DocumentBasis = CurrentRow.SaleOfGoodsAndServices;
							ValueOfDocumentDetails = Common.ObjectAttributesValues(DocumentBasis, "ToReturnReusablePackage, PackageDepositIsRequired");
						EndIf;

						If Not MatchingProductsType.Get(CurrentRow.Products) = Enums.ItemsTypes.ReusablePackage 
							Or MatchingProductsType.Get(CurrentRow.Products) = Enums.ItemsTypes.ReusablePackage 
								And (Not ValueOfDocumentDetails.ToReturnReusablePackage Or ValueOfDocumentDetails.PackageDepositIsRequired) Then
					
								CommonClientServer.MessageToUser(
								                   ErrorText,
								                   ThisObject,
								                   CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "Price"),
								                   ,
								                   Cancel);
							
						EndIf;
					Else
						CommonClientServer.MessageToUser(
						                   ErrorText,
						                   ThisObject,
						                   CommonClientServer.PathToTabularSection("Goods", CurrentRow.LineNumber, "Price"),
						                   ,
						                   Cancel);
					EndIf;
				EndIf;
			EndIf;
		
		EndDo;
		If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		 Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
		 	
		 	ErrorText = NStr("vi = 'Chưa điền trường ""Ấn định"" trong dòng %1 của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Назначение"" в строке %1 списка ""Товары""';
								|en = 'The ""Assignment"" field in line %1 of the ""Goods"" list is not filled'; fa = 'The ""Assignment"" field in line %1 of the ""Goods"" list is not filled';
								|it = 'Non è compilato il campo ""Assegnazione"" nella riga %1 dell''elenco ""Merci""';
								|pl = 'Nie wypełniono pola ""Przeznaczenie"" w wierszu %1 listy ""Towary""';
								|tr = '""Ürünler"" listesinin %1 satırındaki ""Varış Yeri"" alanı doldurulmamış'");
			
			RowsArray = Goods.FindRows(New Structure("Purpose", Catalogs.Assignments.EmptyRef()));
			For Each TableRow In RowsArray Do
				
				Common.MessageToUser(
					StrTemplate(ErrorText, TableRow.LineNumber),
					ThisObject,
					CommonClientServer.PathToTabularSection("Goods", TableRow.LineNumber, "Purpose"),,
					Cancel);
				
			EndDo;
			
		EndIf;
		NotCheckedAttributeArray.Add("Partner");
		If Not ValueIsFilled(Partner) Then
			
			If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor Then
				ErrorText = NStr("vi = 'Chưa điền trường ""Nhà cung cấp""';
								|ru = 'Поле ""Поставщик"" не заполнено';
								|en = '""Vendor"" is required'; fa = '""Vendor"" is required';
								|it = 'Il campo ""Fornitore"" non è compilato';
								|pl = 'Nie wypełniono pola ""Dostawca""';
								|tr = '""Tedarikçi"" alanı doldurulmadı'");
			ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
				  Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
				ErrorText = NStr("vi = 'Chưa điền trường ""Bên đặt gia công""';
								|ru = 'Поле ""Давалец"" не заполнено';
								|en = 'The ""Material provider"" field is not filled'; fa = 'The ""Material provider"" field is not filled';
								|it = 'Campo ""Fornitore"" non compilato';
								|pl = 'Pole ""Właściciel surowców"" nie jest wypełnione';
								|tr = '""Malzeme tedarikçisi"" alanı doldurulmamış'");
			Else
				ErrorText = NStr("vi = 'Chưa điền trường ""Khách hàng""';
								|ru = 'Поле ""Клиент"" не заполнено';
								|en = '""Customer"" is required'; fa = '""Customer"" is required';
								|it = 'Il campo ""Cliente"" non è compilato';
								|pl = 'Nie wypełniono pole ""Клиент""';
								|tr = '""Müşteri"" alanı doldurulmadı'");
			EndIf;
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,
				"Partner",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate) Then
		If Not ValueIsFilled(Terms) Or 
			 Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
			NotCheckedAttributeArray.Add("Contract");
		EndIf;
	ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate) Then
		NotCheckedAttributeArray.Add("Terms");
		NotCheckedAttributeArray.Add("Contract");
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(TypeOfBaseDocumentForNonConformanceCertificate) Then
		NotCheckedAttributeArray.Add("Terms");
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(TypeOfBaseDocumentForNonConformanceCertificate);
		If Not Handler.CustomerAgreementsAreApplicable() Then
			NotCheckedAttributeArray.Add("Terms");
		EndIf;
	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		  Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
		NotCheckedAttributeArray.Add("Terms");
	EndIf;
	
	If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice
		Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
			
		MetadataDetails = DiscrepanciesServer.DescriptionOfMetadataForCheckingPossibilityOfAddingSurplusToInvoice();
		MetadataDetails.NameOfInvoiceOrderField = "SalesOrder";
		MetadataDetails.NameOfOrderRegisterField  = "ReferenceOrder";
		MetadataDetails.NameOfOrderReportField = "SalesOrder";
		MetadataDetails.NameOfInvoiceField = "SaleOfGoodsAndServices";
		MetadataDetails.VerificationIndicator = "Issued_1";
		
		DiscrepanciesServer.CheckingPossibilityOfMakingSurplusInInvoice(ThisObject,
			"ShipmentAndReturnReferences", MetadataDetails, Cancel);

	ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer Then

		MetadataDetails = DiscrepanciesServer.DescriptionOfMetadataForCheckingPossibilityOfAddingSurplusToInvoice();
		MetadataDetails.NameOfInvoiceOrderField = "SalesOrder";
		MetadataDetails.NameOfOrderRegisterField  = "ReferenceOrder";
		MetadataDetails.NameOfOrderReportField = "SalesOrder";
		MetadataDetails.NameOfInvoiceField = "SaleOfGoodsAndServices";
		MetadataDetails.VerificationIndicator = "Shipped";
		
		DiscrepanciesServer.CheckingPossibilityOfMakingSurplusInInvoice(ThisObject,
			"ShipmentAndReturnReferences", MetadataDetails, Cancel);

	EndIf;
	
	If Not DiscrepanciesClientServer.VATIsNotRecorded(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		NotCheckedAttributeArray.Add("VATTaxation");
		NotCheckedAttributeArray.Add("Goods.VATRate");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		SalesServer.CheckCorrectnessOfSalesDocument(ThisObject,Cancel);
		
	Else
		PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject, Cancel);
	EndIf;
	
	DiscrepancyReportFollowingShipmentLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	DiscrepancyReportFollowingShipmentLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	DiscrepancyReportFollowingShipmentLocalization.UndoPosting(ThisObject, Cancel);
	
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
		If Not ValueIsFilled(BusinessOperation) Then
			If TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider Then
				BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5;
			ElsIf TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
				BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInOnTheBasis(Basis)
	
	Query = New Query;
	
	ThisIsTransferOfOwnership = False;
	
	If TypeOf(Basis) = Type("DocumentRef.CustomerInvoice") Then
		
		ThisIsTransferOfOwnership =
			(Common.ObjectAttributeValue(Basis, "BusinessOperation") =
				Enums.BusinessTransactions.TransferOfTitleToGoods);
		
		TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice;
		FilterByProductType = ProductsClientServer.SelectionByProductMultiTurnContainer();
		If ThisIsTransferOfOwnership Then
			Query.Text = QueryTextOnBasisOfImplementationTransferOfOwnership();
		Else
			Query.Text = RequestTextBasedOnImplementation();
		EndIf;
		Query.SetParameter("ItemsTypes", FilterByProductType);
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.GoodsShipmentToCustomer") Then
		
		TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer;
		Query.Text = QueryTextBasedOnShipmentOfItemsToCustomer();
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
		
		TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor;
		Query.Text = RequestTextBasedOnRefund();
		
	ElsIf TypeOf(Basis) = Type("DocumentRef.TransferOfGoodsToBailee") Then
		
		BusinessOperationFoundation = Common.ObjectAttributeValue(Basis, "BusinessOperation");
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperationFoundation);
		
		TypeOfBaseDocumentForNonConformanceCertificate = Handler.TypeOfBasisOfAct();
		Query.Text = QueryTextByTransferBasis();
		
	Else
		BusinessOperationFoundation =
			Common.ObjectAttributeValue(Basis, "BusinessOperation");
			
		If BusinessOperationFoundation = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
			TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider;
		ElsIf BusinessOperationFoundation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
			TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider;
		Else
			TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage;
		EndIf;
		Query.Text = RequestTextBasedOnShipmentFromStorage();
		
	EndIf;
	
	Query.SetParameter("Basis", Basis);
	QueryResult = Query.ExecuteBatch();
	
	DetailsOfFoundation = QueryResult[0].Select();
	DetailsOfFoundation.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOnOperation(Basis,
									"DiscrepancyReportFollowingShipment",
									DetailsOfFoundation.BusinessOperation);
	
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.StatusesOfCustomerInvoices.Shipped);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		DetailsOfFoundation.CustomerInvoice,
		DetailsOfFoundation.DocumentStatus,
		DetailsOfFoundation.ThereAreErrorsPosted,
		DetailsOfFoundation.ThereAreErrorsStatus,
		ArrayOfValidStatuses,
		DetailsOfFoundation.AgreementIsAvailableToExternalUsers);
	
	// Filling in the header
	FillPropertyValues(ThisObject, DetailsOfFoundation);
	
	If ThisIsTransferOfOwnership Then
		SamplePrimaryDocument = QueryResult[QueryResult.UBound()-2].Select();
		SamplePrimaryDocument.Next();
		
		If SamplePrimaryDocument.NumberOfOrdersPrimaryDocument > 0
			And SamplePrimaryDocument.NumberOfOrdersPrimaryDocument =
				SamplePrimaryDocument.RowsCount Then
			
			ErrorText = NStr("vi = 'Lệnh của chứng từ %Document% - chứng từ gốc. Nhập biên bản chênh lệch dựa trên cơ sở bị cấm.';
							|ru = 'Распоряжение документа %Document% - первичный документ. Ввод акта о расхождениях на основании запрещен.';
							|en = 'The ""%Document%"" document reference is a source document. Cannot generate a discrepancy report.'; fa = 'The ""%Document%"" document reference is a source document. Cannot generate a discrepancy report.';
							|it = 'The ""%Document%"" document reference is a source document. Cannot generate a discrepancy report.';
							|pl = 'The ""%Document%"" document reference is a source document. Cannot generate a discrepancy report.';
							|tr = 'Belge emri %Document%, birincil belgedir. Temel olarak, tutarsızlık raporunun girilmesi yasaktır.'");
			ErrorText = StrReplace(ErrorText, "%Document%", Basis);
			Raise ErrorText;
			
		ElsIf SamplePrimaryDocument.NumberOfOrdersPrimaryDocument > 0 Then
			
			ErrorText = NStr("vi = 'Biên bản chênh lệch không hỗ trợ công việc với nhập số dư hàng hóa. Các dòng chứng từ %Document%mà trong đó có lệnh - chứng từ gốc bị loại trừ khỏi biên bản chênh lệch.';
							|ru = 'Акт о расхождениях не поддерживает работу с вводом остатков товаров. Строки документа %Document%, в которых распоряжение - первичный документ исключены из акта о расхождениях.';
							|en = 'The discrepancy report does not support OB entry: goods. The ""%Document%"" document lines in which the reference is a source document are excluded from the discrepancy report.'; fa = 'The discrepancy report does not support OB entry: goods. The ""%Document%"" document lines in which the reference is a source document are excluded from the discrepancy report.';
							|it = 'The discrepancy report does not support OB entry: goods. The ""%Document%"" document lines in which the reference is a source document are excluded from the discrepancy report.';
							|pl = 'The discrepancy report does not support OB entry: goods. The ""%Document%"" document lines in which the reference is a source document are excluded from the discrepancy report.';
							|tr = 'Tutarsızlık raporu, ürün bakiyelerinin girişi ile çalışmayı desteklemez. Siparişin birincil belgesinin olduğu %Document% belgesinin satırları, tutarsızlık raporundan hariç tutulur.'");
			ErrorText = StrReplace(ErrorText, "%Document%", Basis);
			Common.MessageToUser(ErrorText);
			
		EndIf;
		
	EndIf;
	
	Goods.Load(QueryResult[QueryResult.UBound()-1].Unload());
	SetOfSeries.Load(QueryResult[QueryResult.UBound()].Unload());
	
EndProcedure

Procedure FillBasedOnArray(ArrayOfBases, Basis)
	
	TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer;
	Query = New Query;
	Query.Text = QueryTextBasedOnArrayOfOrdersForShipmentOfGoodsToClient();
	Query.SetParameter("ArrayOfBases", ArrayOfBases);
	QueryResult = Query.ExecuteBatch();
	
	If QueryResult[1].IsEmpty() Then
		Return;
	EndIf;
	
	DetailsOfFoundation = QueryResult[1].Select();
	DetailsOfFoundation.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOnOperation(Basis,
									"DiscrepancyReportFollowingShipment",
									DetailsOfFoundation.BusinessOperation);
	
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.StatusesOfCustomerInvoices.Shipped);
		
	// Filling in the header
	FillPropertyValues(ThisObject, DetailsOfFoundation);
	
	Goods.Load(QueryResult[2].Unload());
	SetOfSeries.Load(QueryResult[3].Unload());
	
EndProcedure

Function RequestTextBasedOnImplementation()
	
	Return
	"SELECT ALLOWED
	|	NOT CustomerInvoice.Posted AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN CustomerInvoice.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|			OR CustomerInvoice.Status = VALUE(Enum.StatusesOfCustomerInvoices.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsStatus,
	|	CustomerInvoice.Ref AS CustomerInvoice,
	|	CustomerInvoice.Status AS DocumentStatus,
	|	CustomerInvoice.Organization AS Organization,
	|	CustomerInvoice.Counterparty AS Counterparty,
	|	CustomerInvoice.Manager AS Manager,
	|	CustomerInvoice.VATTaxation AS VATTaxation,
	|	CustomerInvoice.Partner AS Partner,
	|	CustomerInvoice.Currency AS Currency,
	|	PRESENTATION(CustomerInvoice.Shipper) AS Shipper,
	|	CustomerInvoice.BusinessOperation AS BusinessOperation,
	|	CustomerInvoice.PriceIncludesVAT AS PriceIncludesVAT,
	|	CustomerInvoice.Contract AS Contract,
	|	CustomerInvoice.ContactPerson AS ContactPerson,
	|	CustomerInvoice.Terms AS Terms,
	|	CustomerInvoice.Department AS Department,
	|	CustomerInvoice.Terms.AvailableToExternalUsers AS AgreementIsAvailableToExternalUsers
	|FROM
	|	Document.CustomerInvoice AS CustomerInvoice
	|WHERE
	|	CustomerInvoice.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SalesOfGoodsServicesGoods.Products AS Products,
	|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	SalesOfGoodsServicesGoods.Series AS Series,
	|	SalesOfGoodsServicesGoods.Purpose AS Purpose,
	|	SalesOfGoodsServicesGoods.Purpose AS AssignmentSender,
	|	SalesOfGoodsServicesGoods.Package AS Package,
	|	SalesOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackages,
	|	SalesOfGoodsServicesGoods.Count AS Count,
	|	SalesOfGoodsServicesGoods.PriceKind AS PriceKind,
	|	CASE
	|		WHEN SalesOfGoodsServicesGoods.NumberOfPackages = 0
	|			THEN SalesOfGoodsServicesGoods.Price
	|		ELSE
	|			CAST(SalesOfGoodsServicesGoods.Sum / SalesOfGoodsServicesGoods.NumberOfPackages AS NUMBER(31,2))
	|	END AS Price,
	|	SalesOfGoodsServicesGoods.Sum AS Sum,
	|	SalesOfGoodsServicesGoods.VATRate AS VATRate,
	|	SalesOfGoodsServicesGoods.Warehouse AS Warehouse,
	|	SalesOfGoodsServicesGoods.Department AS Department,
	|	SalesOfGoodsServicesGoods.VATAmount AS VATAmount,
	|	SalesOfGoodsServicesGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	SalesOfGoodsServicesGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
	|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
	|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
	|	TRUE AS FilledInBySale,
	|	SalesOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackagesByDocument,
	|	SalesOfGoodsServicesGoods.Count AS CountByDocument,
	|	SalesOfGoodsServicesGoods.Sum AS SumByDocument,
	|	SalesOfGoodsServicesGoods.VATAmount AS VATAmountByDocument,
	|	SalesOfGoodsServicesGoods.AmountIncludingVAT AS AmountIncludingVATByDocument
	|FROM
	|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|	
	|WHERE
	|	SalesOfGoodsServicesGoods.Ref = &Basis
	|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
	|
	|ORDER BY
	|	SaleOfGoodsAndServices,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SalesOfGoodsServicesSeries.Series          AS Series,
	|	SalesOfGoodsServicesSeries.Count     AS Count,
	|	SalesOfGoodsServicesSeries.Count     AS CountByDocument,
	|	SalesOfGoodsServicesSeries.Products   AS Products,
	|	SalesOfGoodsServicesSeries.Characteristic AS Characteristic,
	|	SalesOfGoodsServicesSeries.Purpose     AS Purpose,
	|	SalesOfGoodsServicesSeries.Purpose     AS AssignmentSender,
	|	SalesOfGoodsServicesSeries.Warehouse          AS Warehouse,
	|	SalesOfGoodsServicesSeries.Ref         AS SaleOfGoodsAndServices,
	|	TRUE                                     AS FilledInBySale
	|FROM
	|	Document.CustomerInvoice.SetOfSeries AS SalesOfGoodsServicesSeries
	|WHERE
	|	SalesOfGoodsServicesSeries.Ref = &Basis
	|	AND SalesOfGoodsServicesSeries.Products.ItemsType IN(&ItemsTypes)
	|";
	
EndFunction 

Function QueryTextOnBasisOfImplementationTransferOfOwnership()
	
	Return
	"SELECT ALLOWED
	|	NOT CustomerInvoice.Posted AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN CustomerInvoice.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|			OR CustomerInvoice.Status = VALUE(Enum.StatusesOfCustomerInvoices.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsStatus,
	|	CustomerInvoice.Ref AS CustomerInvoice,
	|	CustomerInvoice.Status AS DocumentStatus,
	|	CustomerInvoice.Organization AS Organization,
	|	CustomerInvoice.Counterparty AS Counterparty,
	|	CustomerInvoice.Manager AS Manager,
	|	CustomerInvoice.VATTaxation AS VATTaxation,
	|	CustomerInvoice.Partner AS Partner,
	|	CustomerInvoice.Currency AS Currency,
	|	PRESENTATION(CustomerInvoice.Shipper) AS Shipper,
	|	CustomerInvoice.BusinessOperation AS BusinessOperation,
	|	CustomerInvoice.PriceIncludesVAT AS PriceIncludesVAT,
	|	CustomerInvoice.Contract AS Contract,
	|	CustomerInvoice.ContactPerson AS ContactPerson,
	|	CustomerInvoice.Terms AS Terms,
	|	CustomerInvoice.Department AS Department,
	|	CustomerInvoice.Terms.AvailableToExternalUsers AS AgreementIsAvailableToExternalUsers
	|FROM
	|	Document.CustomerInvoice AS CustomerInvoice
	|WHERE
	|	CustomerInvoice.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	MAX(Table.Ref) AS DocumentShipments,
	|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
	|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
	|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
	|	SalesOfGoodsServicesGoods.Products AS Products,
	|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose AS Purpose
	|INTO ShipmentDocumentsInAdvance
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS Table
	|	INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|		ON Table.Products = SalesOfGoodsServicesGoods.Products
	|			AND Table.Characteristic = SalesOfGoodsServicesGoods.Characteristic
	|			AND Table.RowCode = SalesOfGoodsServicesGoods.RowCode
	|			AND Table.Ref = SalesOfGoodsServicesGoods.SalesOrder
	|WHERE
	|	Table.Ref.Posted
	|	AND SalesOfGoodsServicesGoods.Ref = &Basis
	|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
	|
	|GROUP BY
	|	SalesOfGoodsServicesGoods.SalesOrder,
	|	SalesOfGoodsServicesGoods.Ref,
	|	SalesOfGoodsServicesGoods.RowCode,
	|	SalesOfGoodsServicesGoods.Products,
	|	SalesOfGoodsServicesGoods.Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(Table.Ref) AS DocumentShipments,
	|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
	|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
	|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
	|	SalesOfGoodsServicesGoods.Products AS Products,
	|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose AS Purpose
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS Table
	|	INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|		ON Table.Products = SalesOfGoodsServicesGoods.Products
	|			AND Table.Characteristic = SalesOfGoodsServicesGoods.Characteristic
	|			AND Table.RowCode = SalesOfGoodsServicesGoods.RowCode
	|			AND Table.Ref.CorrectedDocument = SalesOfGoodsServicesGoods.SalesOrder
	|WHERE
	|	Table.Ref.Posted
	|	AND SalesOfGoodsServicesGoods.Ref = &Basis
	|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
	|
	|GROUP BY
	|	SalesOfGoodsServicesGoods.SalesOrder,
	|	SalesOfGoodsServicesGoods.Ref,
	|	SalesOfGoodsServicesGoods.RowCode,
	|	SalesOfGoodsServicesGoods.Products,
	|	SalesOfGoodsServicesGoods.Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(Table.Ref) AS DocumentShipments,
	|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
	|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
	|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
	|	SalesOfGoodsServicesGoods.Products AS Products,
	|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose AS Purpose
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS Table
	|	INNER JOIN Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|		ON Table.Products = SalesOfGoodsServicesGoods.Products
	|			AND Table.Characteristic = SalesOfGoodsServicesGoods.Characteristic
	|			AND Table.RowCode = SalesOfGoodsServicesGoods.RowCode
	|			AND Table.SalesOrder = SalesOfGoodsServicesGoods.SalesOrder
	|WHERE
	|	Table.Ref.Posted
	|	AND SalesOfGoodsServicesGoods.Ref = &Basis
	|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
	|
	|GROUP BY
	|	SalesOfGoodsServicesGoods.SalesOrder,
	|	SalesOfGoodsServicesGoods.Ref,
	|	SalesOfGoodsServicesGoods.RowCode,
	|	SalesOfGoodsServicesGoods.Products,
	|	SalesOfGoodsServicesGoods.Characteristic,
	|	SalesOfGoodsServicesGoods.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ShipmentDocumentsInAdvance.DocumentShipments AS DocumentShipments,
	|	ShipmentDocumentsInAdvance.SalesOrder AS SalesOrder,
	|	ShipmentDocumentsInAdvance.SaleOfGoodsAndServices AS SaleOfGoodsAndServices,
	|	ShipmentDocumentsInAdvance.RowCode AS RowCode,
	|	ShipmentDocumentsInAdvance.Products AS Products,
	|	ShipmentDocumentsInAdvance.Characteristic AS Characteristic,
	|	ShipmentDocumentsInAdvance.Purpose AS Purpose
	|INTO ShippingDocuments
	|FROM
	|	ShipmentDocumentsInAdvance AS ShipmentDocumentsInAdvance
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON ShipmentDocumentsInAdvance.DocumentShipments = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	DocumentsRegistry.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesOfGoodsServicesGoods.LineNumber AS LineNumber,
	|	SalesOfGoodsServicesGoods.Products AS Products,
	|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ShipmentOfItemsByOrder.Ref IS NOT NULL
	|			THEN ShipmentOfItemsByOrder.Series
	|		WHEN ShipmentOfItemsOrder.Ref IS NOT NULL
	|			THEN ShipmentOfItemsOrder.Series
	|		WHEN ShipmentOfItemsOrderCorrection.Ref IS NOT NULL
	|			THEN ShipmentOfItemsOrderCorrection.Series
	|		ELSE
	|			SalesOfGoodsServicesGoods.Series
	|	END AS Series,
	|	SalesOfGoodsServicesGoods.Purpose AS Purpose,
	|	SalesOfGoodsServicesGoods.Purpose AS AssignmentSender,
	|	SalesOfGoodsServicesGoods.Package AS Package,
	|	SalesOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackages,
	|	SalesOfGoodsServicesGoods.Count AS Count,
	|	SalesOfGoodsServicesGoods.PriceKind AS PriceKind,
	|	CASE
	|		WHEN SalesOfGoodsServicesGoods.NumberOfPackages = 0
	|			THEN SalesOfGoodsServicesGoods.Price
	|		ELSE
	|			CAST(SalesOfGoodsServicesGoods.Sum / SalesOfGoodsServicesGoods.NumberOfPackages AS NUMBER(31,2))
	|	END AS Price,
	|	SalesOfGoodsServicesGoods.Sum AS Sum,
	|	SalesOfGoodsServicesGoods.VATRate AS VATRate,
	|	CASE
	|		WHEN ShipmentOfItemsByOrder.Ref IS NOT NULL
	|			THEN ShipmentOfItemsByOrder.Warehouse
	|		WHEN ShipmentOfItemsOrder.Ref IS NOT NULL
	|			THEN ShipmentOfItemsOrder.Warehouse
	|		WHEN ShipmentOfItemsOrderCorrection.Ref IS NOT NULL
	|			THEN ShipmentOfItemsOrderCorrection.Warehouse
	|		ELSE
	|			SalesOfGoodsServicesGoods.Warehouse
	|	END AS Warehouse,
	|	SalesOfGoodsServicesGoods.Department AS Department,
	|	SalesOfGoodsServicesGoods.VATAmount AS VATAmount,
	|	SalesOfGoodsServicesGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	SalesOfGoodsServicesGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	SalesOfGoodsServicesGoods.Ref AS SaleOfGoodsAndServices,
	|	SalesOfGoodsServicesGoods.SalesOrder AS SalesOrder,
	|	SalesOfGoodsServicesGoods.RowCode AS RowCode,
	|	TRUE AS FilledInBySale,
	|	SalesOfGoodsServicesGoods.NumberOfPackages AS NumberOfPackagesByDocument,
	|	SalesOfGoodsServicesGoods.Count AS CountByDocument,
	|	SalesOfGoodsServicesGoods.Sum AS SumByDocument,
	|	SalesOfGoodsServicesGoods.VATAmount AS VATAmountByDocument,
	|	SalesOfGoodsServicesGoods.AmountIncludingVAT AS AmountIncludingVATByDocument
	|INTO ItemsInAdvance
	|FROM
	|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|	LEFT JOIN ShippingDocuments AS ShippingDocuments
	|		ON SalesOfGoodsServicesGoods.SalesOrder = ShippingDocuments.SalesOrder
	|			AND SalesOfGoodsServicesGoods.Ref = ShippingDocuments.SaleOfGoodsAndServices
	|			AND SalesOfGoodsServicesGoods.RowCode = ShippingDocuments.RowCode
	|			AND SalesOfGoodsServicesGoods.Products = ShippingDocuments.Products
	|			AND SalesOfGoodsServicesGoods.Characteristic = ShippingDocuments.Characteristic
	|			AND SalesOfGoodsServicesGoods.Purpose = ShippingDocuments.Purpose
	|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsByOrder
	|		ON ShippingDocuments.DocumentShipments = ShipmentOfItemsByOrder.Ref
	|			AND SalesOfGoodsServicesGoods.Products = ShipmentOfItemsByOrder.Products
	|			AND SalesOfGoodsServicesGoods.Characteristic = ShipmentOfItemsByOrder.Characteristic
	|			AND SalesOfGoodsServicesGoods.Purpose = ShipmentOfItemsByOrder.Purpose
	|			AND SalesOfGoodsServicesGoods.RowCode = ShipmentOfItemsByOrder.RowCode
	|			AND SalesOfGoodsServicesGoods.SalesOrder = ShipmentOfItemsByOrder.SalesOrder
	|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsOrder
	|		ON ShippingDocuments.DocumentShipments = ShipmentOfItemsOrder.Ref
	|			AND SalesOfGoodsServicesGoods.Products = ShipmentOfItemsOrder.Products
	|			AND SalesOfGoodsServicesGoods.Characteristic = ShipmentOfItemsOrder.Characteristic
	|			AND SalesOfGoodsServicesGoods.Purpose = ShipmentOfItemsOrder.Purpose
	|			AND SalesOfGoodsServicesGoods.RowCode = ShipmentOfItemsOrder.RowCode
	|			AND SalesOfGoodsServicesGoods.SalesOrder = ShipmentOfItemsOrder.Ref
	|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsOrderCorrection
	|		ON ShippingDocuments.DocumentShipments = ShipmentOfItemsOrderCorrection.Ref
	|			AND SalesOfGoodsServicesGoods.Products = ShipmentOfItemsOrderCorrection.Products
	|			AND SalesOfGoodsServicesGoods.Characteristic = ShipmentOfItemsOrderCorrection.Characteristic
	|			AND SalesOfGoodsServicesGoods.Purpose = ShipmentOfItemsOrderCorrection.Purpose
	|			AND SalesOfGoodsServicesGoods.RowCode = ShipmentOfItemsOrderCorrection.RowCode
	|			AND SalesOfGoodsServicesGoods.SalesOrder = ShipmentOfItemsOrderCorrection.Ref.CorrectedDocument
	|WHERE
	|	SalesOfGoodsServicesGoods.Ref = &Basis
	|	AND SalesOfGoodsServicesGoods.Products.ItemsType IN(&ItemsTypes)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(CASE
	|		WHEN ItemsInAdvance.SalesOrder REFS Document.SourceDocument
	|			THEN 1
	|		ELSE
	|			0
	|	END) AS NumberOfOrdersPrimaryDocument,
	|	COUNT(*) AS RowsCount
	|FROM
	|	ItemsInAdvance AS ItemsInAdvance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemsInAdvance.Products AS Products,
	|	ItemsInAdvance.Characteristic AS Characteristic,
	|	ItemsInAdvance.Series AS Series,
	|	ItemsInAdvance.Purpose AS Purpose,
	|	ItemsInAdvance.AssignmentSender AS AssignmentSender,
	|	ItemsInAdvance.Package AS Package,
	|	ItemsInAdvance.NumberOfPackages AS NumberOfPackages,
	|	ItemsInAdvance.Count AS Count,
	|	ItemsInAdvance.PriceKind AS PriceKind,
	|	ItemsInAdvance.Price AS Price,
	|	ItemsInAdvance.Sum AS Sum,
	|	ItemsInAdvance.VATRate AS VATRate,
	|	ItemsInAdvance.Warehouse AS Warehouse,
	|	ItemsInAdvance.Department AS Department,
	|	ItemsInAdvance.VATAmount AS VATAmount,
	|	ItemsInAdvance.AmountIncludingVAT AS AmountIncludingVAT,
	|	ItemsInAdvance.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	ItemsInAdvance.SaleOfGoodsAndServices AS SaleOfGoodsAndServices,
	|	ItemsInAdvance.SalesOrder AS SalesOrder,
	|	ItemsInAdvance.RowCode AS RowCode,
	|	ItemsInAdvance.FilledInBySale AS FilledInBySale,
	|	ItemsInAdvance.NumberOfPackagesByDocument AS NumberOfPackagesByDocument,
	|	ItemsInAdvance.CountByDocument AS CountByDocument,
	|	ItemsInAdvance.SumByDocument AS SumByDocument,
	|	ItemsInAdvance.VATAmountByDocument AS VATAmountByDocument,
	|	ItemsInAdvance.AmountIncludingVATByDocument AS AmountIncludingVATByDocument
	|FROM
	|	ItemsInAdvance AS ItemsInAdvance
	|WHERE
	|	NOT ItemsInAdvance.SalesOrder REFS Document.SourceDocument
	|
	|ORDER BY
	|	SaleOfGoodsAndServices,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SalesOfGoodsServicesSeries.Series          AS Series,
	|	SalesOfGoodsServicesSeries.Count     AS Count,
	|	SalesOfGoodsServicesSeries.Count     AS CountByDocument,
	|	SalesOfGoodsServicesSeries.Products   AS Products,
	|	SalesOfGoodsServicesSeries.Characteristic AS Characteristic,
	|	SalesOfGoodsServicesSeries.Purpose     AS Purpose,
	|	SalesOfGoodsServicesSeries.Purpose     AS AssignmentSender,
	|	SalesOfGoodsServicesSeries.Warehouse          AS Warehouse,
	|	SalesOfGoodsServicesSeries.Ref         AS SaleOfGoodsAndServices,
	|	TRUE                                     AS FilledInBySale
	|FROM
	|	Document.CustomerInvoice.SetOfSeries AS SalesOfGoodsServicesSeries
	|WHERE
	|	SalesOfGoodsServicesSeries.Ref = &Basis
	|	AND SalesOfGoodsServicesSeries.Products.ItemsType IN(&ItemsTypes)
	|";
	
EndFunction 

Function QueryTextBasedOnShipmentOfItemsToCustomer()

	Return "
	|SELECT ALLOWED
	|	NOT GoodsShipmentToCustomer.Posted                             AS ThereAreErrorsPosted,
	|	FALSE                                                           AS ThereAreErrorsStatus,
	|	GoodsShipmentToCustomer.Ref                                  AS CustomerInvoice,
	|	UNDEFINED                                                   AS DocumentStatus,
	|	GoodsShipmentToCustomer.Organization                             AS Organization,
	|	GoodsShipmentToCustomer.Counterparty                              AS Counterparty,
	|	GoodsShipmentToCustomer.Manager                                AS Manager,
	|	GoodsShipmentToCustomer.VATTaxation                      AS VATTaxation,
	|	TRUE                                                         AS PriceIncludesVAT,
	|	GoodsShipmentToCustomer.Partner                                 AS Partner,
	|	GoodsShipmentToCustomer.Currency                                  AS Currency,
	|	PRESENTATION(GoodsShipmentToCustomer.Shipper)         AS Shipper,
	|	GoodsShipmentToCustomer.BusinessOperation                   AS BusinessOperation,
	|	GoodsShipmentToCustomer.Contract                                 AS Contract,
	|	GoodsShipmentToCustomer.ContactPerson                          AS ContactPerson,
	|	GoodsShipmentToCustomer.Terms                              AS Terms,
	|	GoodsShipmentToCustomer.Department                           AS Department,
	|	GoodsShipmentToCustomer.Terms.AvailableToExternalUsers AS AgreementIsAvailableToExternalUsers
	|FROM
	|	Document.GoodsShipmentToCustomer AS GoodsShipmentToCustomer
	|WHERE
	|	GoodsShipmentToCustomer.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ShipmentOfItemsToCustomerItems.Products         AS Products,
	|	ShipmentOfItemsToCustomerItems.Characteristic       AS Characteristic,
	|	ShipmentOfItemsToCustomerItems.Series                AS Series,
	|	ShipmentOfItemsToCustomerItems.Purpose           AS Purpose,
	|	ShipmentOfItemsToCustomerItems.Purpose           AS AssignmentSender,
	|	ShipmentOfItemsToCustomerItems.Package             AS Package,
	|	ShipmentOfItemsToCustomerItems.NumberOfPackages   AS NumberOfPackages,
	|	ShipmentOfItemsToCustomerItems.Count           AS Count,
	|	ShipmentOfItemsToCustomerItems.PriceKind              AS PriceKind,
	|	CASE
	|		WHEN ShipmentOfItemsToCustomerItems.NumberOfPackages = 0
	|			THEN ShipmentOfItemsToCustomerItems.Price
	|		ELSE
	|			CAST(ShipmentOfItemsToCustomerItems.Sum / ShipmentOfItemsToCustomerItems.NumberOfPackages AS NUMBER(31,2))
	|	END                                             AS Price,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT)             AS VATRate,
	|	ShipmentOfItemsToCustomerItems.Sum                AS Sum,
	|	ShipmentOfItemsToCustomerItems.Warehouse                AS Warehouse,
	|	ShipmentOfItemsToCustomerItems.Ref.Department AS Department,
	|	0                                                 AS VATAmount,
	|	0                                                 AS AmountIncludingVAT,
	|	ShipmentOfItemsToCustomerItems.BatchesIndicationStatus  AS BatchesIndicationStatus,
	|	ShipmentOfItemsToCustomerItems.Ref               AS SaleOfGoodsAndServices,
	|	CASE
	|		WHEN ShipmentOfItemsToCustomerItems.SalesOrder REFS Document.SalesOrder
	|				AND CAST(ShipmentOfItemsToCustomerItems.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|			THEN UNDEFINED
	|		WHEN ShipmentOfItemsToCustomerItems.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|				AND CAST(ShipmentOfItemsToCustomerItems.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|			THEN UNDEFINED
	|		ELSE
	|			ShipmentOfItemsToCustomerItems.SalesOrder
	|	END                                             AS SalesOrder,
	|	ShipmentOfItemsToCustomerItems.RowCode            AS RowCode,
	|	TRUE                                            AS FilledInBySale,
	|	ShipmentOfItemsToCustomerItems.NumberOfPackages   AS NumberOfPackagesByDocument,
	|	ShipmentOfItemsToCustomerItems.Count           AS CountByDocument,
	|	ShipmentOfItemsToCustomerItems.Sum                AS SumByDocument,
	|	0                                                 AS VATAmountByDocument,
	|	0                                                 AS AmountIncludingVATByDocument
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsToCustomerItems
	|WHERE
	|	ShipmentOfItemsToCustomerItems.Ref = &Basis
	|
	|ORDER BY
	|	SaleOfGoodsAndServices,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ShipmentOfItemsToCustomerOfSeries.Series          AS Series,
	|	ShipmentOfItemsToCustomerOfSeries.Count     AS Count,
	|	ShipmentOfItemsToCustomerOfSeries.Count     AS CountByDocument,
	|	ShipmentOfItemsToCustomerOfSeries.Products   AS Products,
	|	ShipmentOfItemsToCustomerOfSeries.Characteristic AS Characteristic,
	|	ShipmentOfItemsToCustomerOfSeries.Purpose     AS Purpose,
	|	ShipmentOfItemsToCustomerOfSeries.Purpose     AS AssignmentSender,
	|	ShipmentOfItemsToCustomerOfSeries.Warehouse          AS Warehouse,
	|	ShipmentOfItemsToCustomerOfSeries.Ref         AS SaleOfGoodsAndServices,
	|	TRUE                                     AS FilledInBySale
	|FROM
	|	Document.GoodsShipmentToCustomer.SetOfSeries AS ShipmentOfItemsToCustomerOfSeries
	|WHERE
	|	ShipmentOfItemsToCustomerOfSeries.Ref = &Basis
	|";

EndFunction

Function RequestTextBasedOnRefund()

	Return "
	|SELECT ALLOWED
	|	NOT ReturnOfGoodsToVendor.Posted AS ThereAreErrorsPosted,
	|	FALSE AS ThereAreErrorsStatus,
	|	ReturnOfGoodsToVendor.Ref AS CustomerInvoice,
	|	UNDEFINED AS DocumentStatus,
	|	ReturnOfGoodsToVendor.Organization,
	|	ReturnOfGoodsToVendor.Counterparty,
	|	ReturnOfGoodsToVendor.Manager,
	|	ReturnOfGoodsToVendor.VATTaxation,
	|	ReturnOfGoodsToVendor.Partner,
	|	ReturnOfGoodsToVendor.Currency,
	|	PRESENTATION(ReturnOfGoodsToVendor.Shipper) AS Shipper,
	|	ReturnOfGoodsToVendor.BusinessOperation,
	|	ReturnOfGoodsToVendor.PriceIncludesVAT,
	|	ReturnOfGoodsToVendor.Contract,
	|	ReturnOfGoodsToVendor.ContactPerson,
	|	ReturnOfGoodsToVendor.Terms,
	|	ReturnOfGoodsToVendor.Department,
	|	FALSE AS AgreementIsAvailableToExternalUsers
	|FROM
	|	Document.ReturnOfGoodsToVendor AS ReturnOfGoodsToVendor
	|WHERE
	|	ReturnOfGoodsToVendor.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ReturnOfGoodsToSupplier.Products,
	|	ReturnOfGoodsToSupplier.Characteristic,
	|	ReturnOfGoodsToSupplier.Series,
	|	ReturnOfGoodsToSupplier.Purpose,
	|	ReturnOfGoodsToSupplier.Purpose AS AssignmentSender,
	|	ReturnOfGoodsToSupplier.Package,
	|	ReturnOfGoodsToSupplier.NumberOfPackages,
	|	ReturnOfGoodsToSupplier.Count,
	|	ReturnOfGoodsToSupplier.Price AS Price,
	|	ReturnOfGoodsToSupplier.Sum,
	|	ReturnOfGoodsToSupplier.VATRate,
	|	ReturnOfGoodsToSupplier.Warehouse AS Warehouse,
	|	ReturnOfGoodsToSupplier.VATAmount,
	|	ReturnOfGoodsToSupplier.AmountIncludingVAT,
	|	ReturnOfGoodsToSupplier.BatchesIndicationStatus,
	|	ReturnOfGoodsToSupplier.Ref AS SaleOfGoodsAndServices,
	|	VALUE(Document.SalesOrder.EmptyRef) AS SalesOrder,
	|	TRUE AS FilledInBySale,
	|	ReturnOfGoodsToSupplier.NumberOfPackages AS NumberOfPackagesByDocument,
	|	ReturnOfGoodsToSupplier.Count AS CountByDocument,
	|	ReturnOfGoodsToSupplier.Sum AS SumByDocument,
	|	ReturnOfGoodsToSupplier.VATAmount AS VATAmountByDocument,
	|	ReturnOfGoodsToSupplier.AmountIncludingVAT AS AmountIncludingVATByDocument,
	|	ReturnOfGoodsToSupplier.DocumentInflow
	|FROM
	|	Document.ReturnOfGoodsToVendor.Goods AS ReturnOfGoodsToSupplier
	|WHERE
	|	ReturnOfGoodsToSupplier.Ref = &Basis
	|ORDER BY
	|	SaleOfGoodsAndServices,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ReturnOfGoodsToVendorSetOfSeries.Series AS Series,
	|	ReturnOfGoodsToVendorSetOfSeries.Count AS Count,
	|	ReturnOfGoodsToVendorSetOfSeries.Count AS CountByDocument,
	|	ReturnOfGoodsToVendorSetOfSeries.Products AS Products,
	|	ReturnOfGoodsToVendorSetOfSeries.Characteristic AS Characteristic,
	|	ReturnOfGoodsToVendorSetOfSeries.Purpose AS Purpose,
	|	ReturnOfGoodsToVendorSetOfSeries.Purpose AS AssignmentSender,
	|	ReturnOfGoodsToVendorSetOfSeries.Warehouse AS Warehouse,
	|	ReturnOfGoodsToVendorSetOfSeries.Ref AS SaleOfGoodsAndServices,
	|	TRUE AS FilledInBySale
	|FROM
	|	Document.ReturnOfGoodsToVendor.SetOfSeries AS ReturnOfGoodsToVendorSetOfSeries
	|WHERE
	|	ReturnOfGoodsToVendorSetOfSeries.Ref = &Basis";

EndFunction

Function RequestTextBasedOnShipmentFromStorage()
	
	Return "
	|SELECT ALLOWED
	|	GoodsShipmentFromStorage.Ref                                      AS CustomerInvoice,
	|	UNDEFINED                                                         AS DocumentStatus,
	|	GoodsShipmentFromStorage.Partner                                     AS Partner,
	|	GoodsShipmentFromStorage.Counterparty                                  AS Counterparty,
	|	GoodsShipmentFromStorage.Organization                                 AS Organization,
	|	GoodsShipmentFromStorage.Department                               AS Department,
	|	CASE
	|		WHEN GoodsShipmentFromStorage.BusinessOperation IN (
	|											VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5),
	|											VALUE(Enum.BusinessTransactions.ReturnToMaterialProvider2_5))
	|			THEN UNDEFINED
	|		WHEN TRUE
	|			THEN GoodsShipmentFromStorage.Terms
	|	END                                                                AS Terms,
	|	GoodsShipmentFromStorage.Contract                                     AS Contract,
	|	GoodsShipmentFromStorage.BusinessOperation                       AS BusinessOperation,
	|	GoodsShipmentFromStorage.Manager                                    AS Manager,
	|	GoodsShipmentFromStorage.Currency                                      AS Currency,
	|	VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATTaxation,
	|	PRESENTATION(GoodsShipmentFromStorage.Shipper)             AS Shipper,
	|	GoodsShipmentFromStorage.ContactPerson                              AS ContactPerson,
	|	FALSE                                                                 AS AgreementIsAvailableToExternalUsers,
	|	NOT GoodsShipmentFromStorage.Posted                                 AS ThereAreErrorsPosted,
	|	FALSE                                                                 AS ThereAreErrorsStatus
	|FROM
	|	Document.GoodsShipmentFromStorage AS GoodsShipmentFromStorage
	|WHERE
	|	GoodsShipmentFromStorage.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ShipmentOfGoodsFromStorageGoods.Products        AS Products,
	|	ShipmentOfGoodsFromStorageGoods.Characteristic      AS Characteristic,
	|	ShipmentOfGoodsFromStorageGoods.Package            AS Package,
	|	ShipmentOfGoodsFromStorageGoods.Purpose          AS Purpose,
	|	ShipmentOfGoodsFromStorageGoods.Purpose          AS AssignmentSender,
	|	ShipmentOfGoodsFromStorageGoods.Series               AS Series,
	|	ShipmentOfGoodsFromStorageGoods.NumberOfPackages  AS NumberOfPackages,
	|	ShipmentOfGoodsFromStorageGoods.Count          AS Count,
	|	ShipmentOfGoodsFromStorageGoods.Price                AS Price,
	|	VALUE(Catalog.VATRates.EmptyRef)        AS VATRate,
	|	ShipmentOfGoodsFromStorageGoods.Sum               AS Sum,
	|	ShipmentOfGoodsFromStorageGoods.Warehouse               AS Warehouse,
	|	0                                                  AS VATAmount,
	|	0                                                  AS AmountIncludingVAT,
	|	ShipmentOfGoodsFromStorageGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	ShipmentOfGoodsFromStorageGoods.Ref              AS SaleOfGoodsAndServices,
	|	ShipmentOfGoodsFromStorageGoods.SalesOrder        AS SalesOrder,
	|	ShipmentOfGoodsFromStorageGoods.RowCode           AS RowCode,
	|	ShipmentOfGoodsFromStorageGoods.DocumentInflow AS DocumentInflow,
	|	TRUE                                             AS FilledInBySale,
	|	ShipmentOfGoodsFromStorageGoods.NumberOfPackages  AS NumberOfPackagesByDocument,
	|	ShipmentOfGoodsFromStorageGoods.Count          AS CountByDocument,
	|	ShipmentOfGoodsFromStorageGoods.Sum               AS SumByDocument,
	|	0                                                  AS VATAmountByDocument,
	|	0                                                  AS AmountIncludingVATByDocument
	|FROM
	|	Document.GoodsShipmentFromStorage.Goods AS ShipmentOfGoodsFromStorageGoods
	|WHERE
	|	ShipmentOfGoodsFromStorageGoods.Ref = &Basis
	|
	|ORDER BY
	|	SaleOfGoodsAndServices,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ShipmentOfGoodsFromSeriesStorage.Products   AS Products,
	|	ShipmentOfGoodsFromSeriesStorage.Characteristic AS Characteristic,
	|	ShipmentOfGoodsFromSeriesStorage.Purpose     AS Purpose,
	|	ShipmentOfGoodsFromSeriesStorage.Purpose     AS AssignmentSender,
	|	ShipmentOfGoodsFromSeriesStorage.Series          AS Series,
	|	ShipmentOfGoodsFromSeriesStorage.Count     AS Count,
	|	ShipmentOfGoodsFromSeriesStorage.Count     AS CountByDocument,
	|	ShipmentOfGoodsFromSeriesStorage.Warehouse          AS Warehouse,
	|	ShipmentOfGoodsFromSeriesStorage.Ref         AS SaleOfGoodsAndServices,
	|	TRUE                                       AS FilledInBySale
	|FROM
	|	Document.GoodsShipmentFromStorage.SetOfSeries AS ShipmentOfGoodsFromSeriesStorage
	|WHERE
	|	ShipmentOfGoodsFromSeriesStorage.Ref = &Basis";
	
EndFunction

Function QueryTextByTransferBasis()
	
	Return "
	|SELECT ALLOWED
	|	GoodsHandover.Ref                                               AS CustomerInvoice,
	|	UNDEFINED                                                         AS DocumentStatus,
	|	GoodsHandover.Partner                                              AS Partner,
	|	GoodsHandover.Counterparty                                           AS Counterparty,
	|	GoodsHandover.Organization                                          AS Organization,
	|	GoodsHandover.Department                                        AS Department,
	|	GoodsHandover.Terms                                           AS Terms,
	|	GoodsHandover.Contract                                              AS Contract,
	|	GoodsHandover.BusinessOperation                                AS BusinessOperation,
	|	GoodsHandover.Manager                                             AS Manager,
	|	GoodsHandover.Currency                                               AS Currency,
	|	FALSE                                                                 AS PriceIncludesVAT,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)           AS VATTaxation,
	|	PRESENTATION(GoodsHandover.Shipper)                      AS Shipper,
	|	GoodsHandover.ContactPerson                                       AS ContactPerson,
	|	ISNULL(Terms1.AvailableToExternalUsers, FALSE)              AS AgreementIsAvailableToExternalUsers,
	|	NOT GoodsHandover.Posted                                          AS ThereAreErrorsPosted,
	|	FALSE                                                                 AS ThereAreErrorsStatus
	|FROM
	|	Document.TransferOfGoodsToBailee AS GoodsHandover
	|		LEFT JOIN Catalog.TermsOfSale AS Terms1
	|		ON GoodsHandover.Terms = Terms1.Ref
	|WHERE
	|	GoodsHandover.Ref = &Basis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT ALLOWED
	|	TransferGoods.Products           AS Products,
	|	TransferGoods.Characteristic         AS Characteristic,
	|	TransferGoods.Package               AS Package,
	|	TransferGoods.Purpose             AS Purpose,
	|	TransferGoods.AssignmentSender  AS AssignmentSender,
	|	TransferGoods.Series                  AS Series,
	|	TransferGoods.NumberOfPackages     AS NumberOfPackages,
	|	TransferGoods.Count             AS Count,
	|	TransferGoods.PriceKind                AS PriceKind,
	|	CASE
	|		WHEN TransferGoods.NumberOfPackages = 0
	|			THEN TransferGoods.Price
	|		ELSE
	|			CAST(TransferGoods.Sum / TransferGoods.NumberOfPackages AS NUMBER(31, 2))
	|	END                                 AS Price,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate,
	|	TransferGoods.Sum                  AS Sum,
	|	TransferGoods.Warehouse                  AS Warehouse,
	|	0                                     AS VATAmount,
	|	TransferGoods.Sum                  AS AmountIncludingVAT,
	|	TransferGoods.BatchesIndicationStatus    AS BatchesIndicationStatus,
	|	TransferGoods.Ref                 AS SaleOfGoodsAndServices,
	|	TransferGoods.SalesOrder           AS SalesOrder,
	|	TransferGoods.RowCode              AS RowCode,
	|	TRUE                                AS FilledInBySale,
	|	TransferGoods.NumberOfPackages     AS NumberOfPackagesByDocument,
	|	TransferGoods.Count             AS CountByDocument,
	|	TransferGoods.Sum                  AS SumByDocument,
	|	0                                     AS VATAmountByDocument,
	|	TransferGoods.Sum                  AS AmountIncludingVATByDocument
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS TransferGoods
	|WHERE
	|	TransferGoods.Ref = &Basis
	|
	|ORDER BY
	|	SaleOfGoodsAndServices,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TransferSeries.Products   AS Products,
	|	TransferSeries.Characteristic AS Characteristic,
	|	TransferSeries.Purpose     AS Purpose,
	|	TransferSeries.AssignmentSender AS AssignmentSender,
	|	TransferSeries.Series          AS Series,
	|	TransferSeries.Count     AS Count,
	|	TransferSeries.Count     AS CountByDocument,
	|	TransferSeries.Warehouse          AS Warehouse,
	|	TransferSeries.Ref         AS SaleOfGoodsAndServices,
	|	TRUE                       AS FilledInBySale
	|FROM
	|	Document.TransferOfGoodsToBailee.SetOfSeries AS TransferSeries
	|WHERE
	|	TransferSeries.Ref = &Basis";

EndFunction

Function QueryTextBasedOnArrayOfOrdersForShipmentOfGoodsToClient()
	
	QueryText = 
	"SELECT DISTINCT ALLOWED
	|	NestedQuery.Ref AS Ref
	|INTO TT_ShipmentsOfGoods
	|FROM
	|	(SELECT
	|		DocumentTable.Ref
	|	FROM
	|		Document.GoodsShipmentToCustomer AS DocumentTable
	|	WHERE
	|		DocumentTable.SalesOrder IN (&ArrayOfBases)
	|		AND DocumentTable.Posted
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableOfGoods.Ref
	|	FROM
	|		Document.GoodsShipmentToCustomer.Goods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.SalesOrder IN (&ArrayOfBases)
	|		AND TableOfGoods.Ref.Posted
	|	) AS NestedQuery
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED TOP 1
	|	NOT GoodsShipmentToCustomer.Posted                             AS ThereAreErrorsPosted,
	|	FALSE                                                           AS ThereAreErrorsStatus,
	|	GoodsShipmentToCustomer.Ref                                  AS CustomerInvoice,
	|	UNDEFINED                                                   AS DocumentStatus,
	|	GoodsShipmentToCustomer.Organization                             AS Organization,
	|	GoodsShipmentToCustomer.Counterparty                              AS Counterparty,
	|	GoodsShipmentToCustomer.Manager                                AS Manager,
	|	GoodsShipmentToCustomer.VATTaxation                      AS VATTaxation,
	|	GoodsShipmentToCustomer.Partner                                 AS Partner,
	|	GoodsShipmentToCustomer.Currency                                  AS Currency,
	|	PRESENTATION(GoodsShipmentToCustomer.Shipper)         AS Shipper,
	|	GoodsShipmentToCustomer.BusinessOperation                   AS BusinessOperation,
	|	TRUE                                                         AS PriceIncludesVAT,
	|	GoodsShipmentToCustomer.Contract                                 AS Contract,
	|	GoodsShipmentToCustomer.ContactPerson                          AS ContactPerson,
	|	GoodsShipmentToCustomer.Terms                              AS Terms,
	|	GoodsShipmentToCustomer.Department                           AS Department,
	|	GoodsShipmentToCustomer.Terms.AvailableToExternalUsers AS AgreementIsAvailableToExternalUsers
	|FROM
	|	Document.GoodsShipmentToCustomer AS GoodsShipmentToCustomer
	|WHERE
	|	GoodsShipmentToCustomer.Ref IN (SELECT TT.Ref FROM TT_ShipmentsOfGoods AS TT)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ShipmentOfItemsToCustomerItems.Products         AS Products,
	|	ShipmentOfItemsToCustomerItems.Characteristic       AS Characteristic,
	|	ShipmentOfItemsToCustomerItems.Series                AS Series,
	|	ShipmentOfItemsToCustomerItems.Purpose           AS Purpose,
	|	ShipmentOfItemsToCustomerItems.Purpose           AS AssignmentSender,
	|	ShipmentOfItemsToCustomerItems.Package             AS Package,
	|	ShipmentOfItemsToCustomerItems.NumberOfPackages   AS NumberOfPackages,
	|	ShipmentOfItemsToCustomerItems.Count           AS Count,
	|	ShipmentOfItemsToCustomerItems.PriceKind              AS PriceKind,
	|	CASE
	|		WHEN ShipmentOfItemsToCustomerItems.NumberOfPackages = 0
	|			THEN ShipmentOfItemsToCustomerItems.Price
	|		ELSE
	|			CAST(ShipmentOfItemsToCustomerItems.Sum / ShipmentOfItemsToCustomerItems.NumberOfPackages AS NUMBER(31,2))
	|	END                                             AS Price,
	|	ShipmentOfItemsToCustomerItems.Sum                AS Sum,
	|	ShipmentOfItemsToCustomerItems.Warehouse                AS Warehouse,
	|	ShipmentOfItemsToCustomerItems.Ref.Department AS Department,
	|	ShipmentOfItemsToCustomerItems.BatchesIndicationStatus  AS BatchesIndicationStatus,
	|	ShipmentOfItemsToCustomerItems.Ref               AS SaleOfGoodsAndServices,
	|	ShipmentOfItemsToCustomerItems.SalesOrder         AS SalesOrder,
	|	ShipmentOfItemsToCustomerItems.RowCode            AS RowCode,
	|	TRUE                                            AS FilledInBySale,
	|	ShipmentOfItemsToCustomerItems.NumberOfPackages   AS NumberOfPackagesByDocument,
	|	ShipmentOfItemsToCustomerItems.Count           AS CountByDocument,
	|	ShipmentOfItemsToCustomerItems.Sum                AS SumByDocument
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS ShipmentOfItemsToCustomerItems
	|WHERE
	|	ShipmentOfItemsToCustomerItems.Ref IN (SELECT TT.Ref FROM TT_ShipmentsOfGoods AS TT)
	|
	|ORDER BY
	|	SaleOfGoodsAndServices,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ShipmentOfItemsToCustomerOfSeries.Series          AS Series,
	|	ShipmentOfItemsToCustomerOfSeries.Count     AS Count,
	|	ShipmentOfItemsToCustomerOfSeries.Count     AS CountByDocument,
	|	ShipmentOfItemsToCustomerOfSeries.Products   AS Products,
	|	ShipmentOfItemsToCustomerOfSeries.Characteristic AS Characteristic,
	|	ShipmentOfItemsToCustomerOfSeries.Purpose     AS Purpose,
	|	ShipmentOfItemsToCustomerOfSeries.Purpose     AS AssignmentSender,
	|	ShipmentOfItemsToCustomerOfSeries.Warehouse          AS Warehouse,
	|	ShipmentOfItemsToCustomerOfSeries.Ref         AS SaleOfGoodsAndServices,
	|	TRUE                                     AS FilledInBySale
	|FROM
	|	Document.GoodsShipmentToCustomer.SetOfSeries AS ShipmentOfItemsToCustomerOfSeries
	|WHERE
	|	ShipmentOfItemsToCustomerOfSeries.Ref IN (SELECT TT.Ref FROM TT_ShipmentsOfGoods AS TT)
	|";
	
	Return QueryText;

EndFunction

Procedure InitializeDocument(FillingData = Undefined)
	
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
	Status      = Enums.StatusesOfDiscrepancyReport.NotApproved;
	
	CompleteVATTaxation();
	
EndProcedure

#Region SalesTermsAndConditions

Procedure InitializeSalesConditions()
	
	If DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(TypeOfBaseDocumentForNonConformanceCertificate);
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
Procedure FillInDefaultSalesConditions(ProductSegment = Undefined) Export
	
	Handler = Undefined;
	If DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(TypeOfBaseDocumentForNonConformanceCertificate);
		ToUseTermsOfSales = Handler.ToUseTermsOfSales();
	Else
		ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	EndIf;
	
	If ValueIsFilled(Partner) Or Not ToUseTermsOfSales Then
		
		SelectionOperation = ?(Handler = Undefined, Undefined, Handler.ContractBusinessTransaction());
		CustomerAgreementsAreApplicable = ?(Handler = Undefined, True, Handler.CustomerAgreementsAreApplicable());
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SelectedAgreement",   Terms);
		FilterParameters.Insert("BusinessTransactions", SelectionOperation);
		FilterParameters.Insert("EmptyDocumentLink", Documents.DiscrepancyReportFollowingShipment.EmptyRef());
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(Partner, FilterParameters, CustomerAgreementsAreApplicable);
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales 
				Or (Terms <> DefaultSalesTerms.Terms And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms, ProductSegment);
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
	
	If Not ValueIsFilled(VATTaxation)
		And ToUseTermsOfSales
		And Not DiscrepanciesClientServer.VATIsNotRecorded(TypeOfBaseDocumentForNonConformanceCertificate)
		And Not (DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate)) Then
		
		VATTaxation = SettingsValueCached.VATTaxation(Organization, , Contract, , Date);
		
	EndIf;
	
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
	If DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate) Then
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsBasedOnReportBaseType(TypeOfBaseDocumentForNonConformanceCertificate);
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Currency) Then
		Currency = SalesTermsAndConditions.Currency;
	EndIf;
	PriceIncludesVAT       = SalesTermsAndConditions.PriceIncludesVAT;
	ProductSegment   = SalesTermsAndConditions.ProductSegment;
	
	If Handler = Undefined Or Handler.CustomerAgreementsAreApplicable() Then
		BusinessOperation = SalesTermsAndConditions.BusinessOperation;
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
			Contract = SalesServer.GetDefaultContract(
				ThisObject,
				?(BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting,
					Enums.BusinessTransactions.SaleToCustomer,
					BusinessOperation));
		Else
			Contract = Handler.GetDefaultContract(ThisObject, False, False);
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(VATTaxation)
		And Not DiscrepanciesClientServer.VATIsNotRecorded(TypeOfBaseDocumentForNonConformanceCertificate)
		And Not (DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
			Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate)) Then
		
		VATTaxation = SettingsValueCached.VATTaxation(Organization, , Contract, , Date);
		
	EndIf;
	
EndProcedure

// Fills in the terms of sales under the agreement in the document
//
Procedure FillInTermsOfSalesUnderAgreement(ProductSegment) Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
	FillIn_TermsOfSales(SalesTermsAndConditions, ProductSegment);
	CompleteVATTaxation();
	
EndProcedure

#EndRegion

#Region PurchaseConditions

// Fills in the default purchase conditions in the return of goods to the supplier
//
Procedure FillInDefaultPurchaseConditions() Export
	
	If ValueIsFilled(Terms) Then
		Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
	EndIf;
	
	If ValueIsFilled (Partner) Then
		
		SelectionOperation = Undefined;
		If BusinessOperation =
				Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale Then
			SelectionOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale;
		ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
			  Or BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
			SelectionOperation = BusinessOperation;
		EndIf;
		
		FilterParameters = New Structure("BusinessTransactions", SelectionOperation);
		
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
			Terms = Undefined;
			
			If BusinessOperation = Enums.BusinessTransactions.TransferToMaterialProvider2_5
			 Or BusinessOperation = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
				
				Contract = PurchasesServer.GetDefaultContract(
							ThisObject,
							TollingSchemeClientServer.ContractBusinessTransaction());
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
EndProcedure

// Fills in the terms of sales under the agreement in the return of goods to the supplier
//
Procedure FillInTermsOfPurchaseUnderAgreement() Export
	
	PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms);
	FillInTermsOfPurchase(PurchaseConditions);
	CompleteVATTaxation();
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
EndProcedure

// Fills in the purchase conditions in the document
//
// Parameters:
//	PurchaseConditions - Structure - Structure to fill in
//
Procedure FillInTermsOfPurchase(Val PurchaseConditions) Export
	
	If PurchaseConditions = Undefined Then
		Return;
	EndIf;
	
	Currency = PurchaseConditions.Currency;
	PriceIncludesVAT = PurchaseConditions.PriceIncludesVAT;
	
	If ValueIsFilled(PurchaseConditions.Organization) And PurchaseConditions.Organization<>Organization Then
		Organization = PurchaseConditions.Organization;
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Counterparty) And PurchaseConditions.Counterparty <> Counterparty Then
		Counterparty = PurchaseConditions.Counterparty;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	BusinessOperation = PurchasesServer.GetRefundTransactionOnReceipt(PurchaseConditions.BusinessOperation);
		
	ContractBusinessTransaction = Undefined;
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsToVendor") Then
		ContractBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.PurchaseFromSupplier");
	ElsIf BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ReturnOfGoodsToConsignor") Then
		ContractBusinessTransaction = PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement");
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(TypeOfBaseDocumentForNonConformanceCertificate) Then
		ContractBusinessTransaction = PurchaseConditions.BusinessOperation;
	EndIf;
	
	AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
	AddlParameters.ARAPCurrency = Currency;
	Contract = PurchasesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, AddlParameters);
	
EndProcedure

#EndRegion

#EndRegion

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
	
	Status = Enums.StatusesOfDiscrepancyReport[NewStatus];
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.DiscrepancyReportFollowingShipment);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	Return CheckFilling();
	
EndFunction

Function TypeOfBasisForActOfDiscrepancyOnBusinessTransaction(BusinessTransaction)
	
	If BusinessTransaction = Enums.BusinessTransactions.ReturnOfGoodsToVendor 
		Or BusinessTransaction = Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
		
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor;
		
	ElsIf BusinessTransaction = Enums.BusinessTransactions.ShipGoodsReceivedFromStorageWithRightOfSale
		Or BusinessTransaction = Enums.BusinessTransactions.DeliveryForPrincipal Then
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentFromStorage;
	ElsIf BusinessTransaction = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee;
	ElsIf BusinessTransaction = Enums.BusinessTransactions.TransferToCommissionAgent Then
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToCommissionAgent;
	ElsIf BusinessTransaction = Enums.BusinessTransactions.TransferToToller2_5 Then
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor;
	ElsIf BusinessTransaction = Enums.BusinessTransactions.TransferToMaterialProvider2_5 Then
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider;
	ElsIf BusinessTransaction = Enums.BusinessTransactions.ReturnToMaterialProvider2_5 Then
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider;
	ElsIf BusinessTransaction = Enums.BusinessTransactions.GoodsShipmentToCustomer Then
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer;
	Else
		Return Enums.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice;
	EndIf;
	
EndFunction

#Region Other

Procedure CompleteVATTaxation()
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate)
		And Not BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		
		FillParameters = Documents.DiscrepancyReportFollowingShipment.ParametersForFillingInSalesVATTaxation(ThisObject);
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		FillParameters = Documents.DiscrepancyReportFollowingShipment.ParametersForFillingInVATTaxationPurchases(ThisObject);
		VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
