#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array();
	
	// Items.Action.
	If Status = Enums.StatusesOfQualityControlCertificates.InProgress
			Or Status = Enums.StatusesOfQualityControlCertificates.AwaitingDecision Then
		NotCheckedAttributeArray.Add("Goods.Action");
	EndIf;
	
	// Items.The result of the Quality check.
	If Status = Enums.StatusesOfQualityControlCertificates.InProgress Then
		NotCheckedAttributeArray.Add("Goods.QualityCheckResult");
	EndIf;
	
	// Items.Characteristics.
	// Items.Characterization of arrival.
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.FieldNamesWithSuffix.Insert("Products", "ProductsRecordingAsReceived");
	CheckParameters.FieldNamesWithSuffix.Insert("Characteristic", "CharacteristicRecordingAsReceived");
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		CheckParameters);
	
	// Items.Series.
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsQualityControlCertificate),
		Cancel,
		NotCheckedAttributeArray);
		
	// Goods.The room.
	// Goods.Cell.
	WarehousesServer.CheckFillingOfPremises(ThisObject, NotCheckedAttributeArray, Cancel);
	WarehousesServer.CheckFillingOfCells(ThisObject, NotCheckedAttributeArray, Cancel);
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.CheckCompletenessOfProductLocations = True;
	CheckParameters.FieldsForCheckingCompleteness = "Action,Purpose,Warehouse,Premise";
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	// Checking the filling of the packages of the nomenclature at the address warehouses
	WarehouseSelection_ = QualityControl.WarehouseSelection_(Goods.Unload(,"Warehouse,Premise"), Date);
	While WarehouseSelection_.Next() Do
		CheckParameters = ProductsServer.ParametersForCheckingFillingOfPackages();
		CheckParameters.SelectingRowsToCheck.Insert("Warehouse", WarehouseSelection_.Warehouse);
		CheckParameters.SelectingRowsToCheck.Insert("Premise", WarehouseSelection_.Premise);
		FieldNamesWithSuffix = New Structure();
		FieldNamesWithSuffix.Insert("Products", "ProductsRecordingAsReceived");
		FieldNamesWithSuffix.Insert("Package", "PackagingReceipt");
		CheckParameters.FieldNamesWithSuffix = FieldNamesWithSuffix;
		ProductsServer.CheckFillingOfPackages(
			ThisObject,
			NotCheckedAttributeArray,
			Cancel,
			CheckParameters);
	EndDo;
	If NotCheckedAttributeArray.Find("Goods.Package") = Undefined Then
		NotCheckedAttributeArray.Add("Goods.Package");
	EndIf;
	If NotCheckedAttributeArray.Find("Goods.PackagingReceipt") = Undefined Then
		NotCheckedAttributeArray.Add("Goods.PackagingReceipt");
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.ProductsRecordingAsReceived");
	NotCheckedAttributeArray.Add("Goods.ForAssignment");
	
	AssignmentTypes = Common.ObjectsAttributeValue(Goods.UnloadColumn("Purpose"), "AssignmentType");
	MessageTemplateForPurpose = NStr("vi = 'Trên dòng %1 của danh sách ""Hàng hóa"", hàng hóa có chất lượng ban đầu là hàng của bên gia công, hàng hóa có chất lượng khác phải là ""Theo mục đích""';
									|ru = 'В строке %1 списка ""Товары"" товар исходного качества давальческий, товар другого качества должен быть ""Под назначение""';
									|en = 'In line %1 of the ""Goods"" list, the item of original quality is provided by the material provider. The nonconforming product must be assigned'; fa = 'In line %1 of the ""Goods"" list, the item of original quality is provided by the material provider. The nonconforming product must be assigned';
									|it = 'In line %1 of the ""Goods"" list, the item of original quality is provided by the material provider. The nonconforming product must be assigned';
									|pl = 'In line %1 of the ""Goods"" list, the item of original quality is provided by the material provider. The nonconforming product must be assigned';
									|tr = '""Ürünler"" listesi %1 satırında orijinal kalitedeki ürün fason ürün, diğer kalitedeki ürün ""Atamaya göre"" olmalıdır.'");
	
	MessageTemplateNotFilledIn = NStr("vi = 'Chưa điền cột Mặt hàng (ghi tăng) trong dòng %1 danh sách ""Hàng hóa"".';
										|ru = 'Не заполнена колонка Номенклатура (оприходование) в строке %1 списка ""Товары"".';
										|en = 'The ""Items (recording as received)"" column in line %1 of the ""Goods"" list is not filled in.'; fa = 'The ""Items (recording as received)"" column in line %1 of the ""Goods"" list is not filled in.';
										|it = 'The ""Items (recording as received)"" column in line %1 of the ""Goods"" list is not filled in.';
										|pl = 'The ""Items (recording as received)"" column in line %1 of the ""Goods"" list is not filled in.';
										|tr = '""Ürünler"" listesi %1 satırında Öğe (kayda alma) sütunu doldurulmamış.'");
	MessageTemplateIsSame = NStr("vi = 'Trên dòng %1 của danh sách ""Hàng hóa"", hàng hóa có chất lượng ban đầu trùng với hàng hóa có chất lượng khác';
								|ru = 'В строке %1 списка ""Товары"" товар исходного качества совпадает с товаром другого качества';
								|en = 'In line %1 of the ""Goods"" list, the item of original quality matches the nonconforming product'; fa = 'In line %1 of the ""Goods"" list, the item of original quality matches the nonconforming product';
								|it = 'In line %1 of the ""Goods"" list, the item of original quality matches the nonconforming product';
								|pl = 'In line %1 of the ""Goods"" list, the item of original quality matches the nonconforming product';
								|tr = '""Ürünler"" listesi %1 satırında orijinal kalitedeki ürün, diğer kalitedeki ürünle aynı.'");
	TemplateNumberOfEntries = NStr("vi = 'Số lượng mặt hàng chất lượng ban đầu ""%WriteOffProducts_%"" trong dòng ""%LineNumber%"" của danh sách ""Hàng hóa"" khác với số lượng mặt hàng chất lượng khác ""%RegistrationProducts%"" bởi ""%Count%"" của đơn vị lưu trữ';
									|ru = 'Количество номенклатуры исходного качества ""%WriteOffProducts_%"" в строке ""%LineNumber%"" списка ""Товары"" отличается от количества номенклатуры другого качества ""%RegistrationProducts%"" на ""%Count%"" единиц хранения';
									|en = 'Quantity of the ""%WriteOffProducts_%"" items of original quality in line %LineNumber% of the ""Goods"" list is different from the quantity of the ""%RegistrationProducts%"" nonconforming product by ""%Count%"" stock UOM'; fa = 'Quantity of the ""%WriteOffProducts_%"" items of original quality in line %LineNumber% of the ""Goods"" list is different from the quantity of the ""%RegistrationProducts%"" nonconforming product by ""%Count%"" stock UOM';
									|it = 'Quantity of the ""%WriteOffProducts_%"" items of original quality in line %LineNumber% of the ""Goods"" list is different from the quantity of the ""%RegistrationProducts%"" nonconforming product by ""%Count%"" stock UOM';
									|pl = 'Quantity of the ""%WriteOffProducts_%"" items of original quality in line %LineNumber% of the ""Goods"" list is different from the quantity of the ""%RegistrationProducts%"" nonconforming product by ""%Count%"" stock UOM';
									|tr = '""Ürünler"" listesi ""%LineNumber%"" satırındaki orijinal kalitedeki ""%WriteOffProducts_%"" öğesinin miktarı, diğer kalitedeki ""%RegistrationProducts%"" öğesinin miktarından ""%Count%"" depolama birimi kadar farklı.'");

	For IndexOf = 0 To Goods.Count() - 1 Do
		
		TableRow = Goods[IndexOf];
		Field = StrTemplate("Goods[%1].ProductsRecordingAsReceived", IndexOf);
		
		// Goods.ProductsRecordingAsReceived
		If (TableRow.Action = Enums.ActionsOnGoodsInQualityControlCertificate.ChangeQuality
				Or TableRow.Action = Enums.ActionsOnGoodsInQualityControlCertificate.RegisterStockQualityChange) Then
				
			If Not ValueIsFilled(TableRow.ProductsRecordingAsReceived) Then
				
				PathToTop = CommonClientServer.PathToTabularSection(
					"Goods",
					TableRow.LineNumber,
					"ProductsRecordingAsReceived");
				
				Common.MessageToUser(
					StrTemplate(MessageTemplateNotFilledIn, IndexOf + 1),
					ThisObject,
					PathToTop,
					,
					Cancel);
			EndIf;
			
			If ValueIsFilled(TableRow.Products)
					And TableRow.Products = TableRow.ProductsRecordingAsReceived Then
					
				PathToTop = CommonClientServer.PathToTabularSection(
					"Goods",
					TableRow.LineNumber,
					"ProductsRecordingAsReceived");
					
				Common.MessageToUser(
					StrTemplate(MessageTemplateIsSame, IndexOf + 1),
					ThisObject,
					PathToTop,
					,
					Cancel);
					
			EndIf;
			
			// Goods.ForAssignment
			If Not TableRow.ForAssignment
					And AssignmentTypes.Get(TableRow.Purpose) = Enums.AssignmentTypes.Giveaway2_5 Then
				
				PathToTop = CommonClientServer.PathToTabularSection(
					"Goods",
					TableRow.LineNumber,
					"ForAssignment");
				
				Common.MessageToUser(
					StrTemplate(MessageTemplateForPurpose, IndexOf + 1),
					ThisObject,
					PathToTop,
					,
					Cancel);
				
			EndIf;
			
			// Goods.CountRecordingAsReceived
			If TableRow.Count <> TableRow.CountRecordingAsReceived
					And ValueIsFilled(TableRow.ProductsRecordingAsReceived) Then
					
				NumberOfDivergence = TableRow.Count - TableRow.CountRecordingAsReceived;
				NumberOfDivergence = Max(NumberOfDivergence, -NumberOfDivergence);
				
				PresentationOfWriteOffProducts = ProductsClientServer.ProductPresentation(
					TableRow.Products,
					TableRow.Characteristic,
					TableRow.Package,
					TableRow.Series,
					TableRow.Purpose);
				PresentationOfRegistrationNomenclature = ProductsClientServer.ProductPresentation(
					TableRow.ProductsRecordingAsReceived,
					TableRow.CharacteristicRecordingAsReceived,
					TableRow.PackagingReceipt);
				
				MessageText = StrReplace(TemplateNumberOfEntries, "%LineNumber%", IndexOf + 1);
				MessageText = StrReplace(MessageText, "%WriteOffProducts_%", PresentationOfWriteOffProducts);
				MessageText = StrReplace(MessageText, "%RegistrationProducts%", PresentationOfRegistrationNomenclature);
				MessageText = StrReplace(MessageText, "%Count%", NumberOfDivergence);
				
				Field = CommonClientServer.PathToTabularSection("Goods", IndexOf + 1, "NumberOfPackages");
				Common.MessageToUser(
					MessageText,
					ThisObject,
					Field,
					"Object",
					Cancel);
					
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If GetFunctionalOption("UseReusablePackage") Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	TableOfGoods.Products,
		|	TableOfGoods.ProductsRecordingAsReceived,
		|	TableOfGoods.LineNumber
		|INTO TableOfGoods
		|FROM
		|	&TableOfGoods AS TableOfGoods
		|INDEX BY
		|	Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TableOfGoods.LineNumber AS LineNumber,
		|	CAST(TableOfGoods.Products AS Catalog.Products).ItemsType AS ProductsTypeOfProducts,
		|	CAST(TableOfGoods.ProductsRecordingAsReceived AS Catalog.Products).ItemsType AS ProductsDescriptionProductsType
		|FROM
		|	TableOfGoods AS TableOfGoods
		|WHERE
		|	CAST(TableOfGoods.Products AS Catalog.Products).ItemsType <> CAST(TableOfGoods.ProductsRecordingAsReceived AS Catalog.Products).ItemsType
		|
		|ORDER BY
		|	LineNumber";
		
		TableOfGoods = Goods.Unload(New Array(), "LineNumber,Products,ProductsRecordingAsReceived");
		For Each TableRow In Goods Do
			
			If TableRow.Action = Enums.ActionsOnGoodsInQualityControlCertificate.ChangeQuality
					Or TableRow.Action = Enums.ActionsOnGoodsInQualityControlCertificate.RegisterStockQualityChange Then
				
				FillPropertyValues(TableOfGoods.Add(), TableRow);
				
			EndIf;
			
		EndDo;
		Query.SetParameter("TableOfGoods", TableOfGoods);
		
		Selection = Query.Execute().Select();
		
		ErrorText = NStr("vi = 'Tại dòng %LineNumber% trong danh sách ""Hàng hóa"" không trùng kiểu mặt hàng. Mặt hàng chất lượng ban đầu có kiểu %ProductsTypeOfProducts%, mặt hàng chất lượng khác có kiểu %ProductsDescriptionProductsType%.';
						|ru = 'В строке %LineNumber% списка ""Товары"" не совпадают типы номенклатуры. У номенклатуры исходного качества тип %ProductsTypeOfProducts%, другого качества - %ProductsDescriptionProductsType%.';
						|en = 'Item types do not match in line %LineNumber% of the Item list. Items of the original quality are of the ""%ProductsTypeOfProducts%'' type; nonconforming product is of the ""%ProductsDescriptionProductsType%"" type.'; fa = 'Item types do not match in line %LineNumber% of the Item list. Items of the original quality are of the ""%ProductsTypeOfProducts%'' type; nonconforming product is of the ""%ProductsDescriptionProductsType%"" type.';
						|it = 'Item types do not match in line %LineNumber% of the Item list. Items of the original quality are of the ""%ProductsTypeOfProducts%'' type; nonconforming product is of the ""%ProductsDescriptionProductsType%"" type.';
						|pl = 'Item types do not match in line %LineNumber% of the Item list. Items of the original quality are of the ""%ProductsTypeOfProducts%'' type; nonconforming product is of the ""%ProductsDescriptionProductsType%"" type.';
						|tr = '""Ürünler"" listesi %LineNumber% satırında öğe türleri eşleşmiyor. Orijinal kalitedeki öğenin türü %ProductsTypeOfProducts%, diğer kalitedeki öğenin türü %ProductsDescriptionProductsType%.'");
		
		While Selection.Next() Do
			ErrorMessage = StrReplace(ErrorText, "%LineNumber%", Selection.LineNumber); 
			ErrorMessage = StrReplace(ErrorMessage, "%ProductsTypeOfProducts%", Selection.ProductsTypeOfProducts); 
			ErrorMessage = StrReplace(ErrorMessage, "%ProductsDescriptionProductsType%", Selection.ProductsDescriptionProductsType); 
			
			Field = CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "ProductsRecordingAsReceived");
			Common.MessageToUser(
				ErrorMessage,
				ThisObject,
				Field,
				,
				Cancel);
		EndDo;
		
	EndIf;
	
	// Type of item registration.
	TableToCheck_ = Goods.Unload(, "Products,ProductsRecordingAsReceived");
	TableToCheck_.Columns.Add("LineNumber", Common.TypeDescriptionNumber(15));
	For IndexOf = 0 To Goods.Count() - 1 Do
		TableRow = Goods[IndexOf];
		If TableRow.Action = Enums.ActionsOnGoodsInQualityControlCertificate.ChangeQuality
				Or TableRow.Action = Enums.ActionsOnGoodsInQualityControlCertificate.RegisterStockQualityChange Then
			NewRow = TableToCheck_.Add();
			FillPropertyValues(NewRow, TableRow);
			NewRow.LineNumber = IndexOf + 1;
		EndIf;
	EndDo;
	
	ProductsServer.CheckTypeOfProductDescription(ThisObject, Cancel, "Goods", TableToCheck_);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentBasis = Undefined;
	InitializeDocument();
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.VendorInvoice") Then
		FillInBasedOnPurchaseOfGoodsAndServices(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		FillInBasedOnReceiptOfGoodsAtWarehouse(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsReceiptFromCustomer") Then
		FillInBasedOnReceiptOfGoodsFromClient(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
		FillInBasedOnReceiptOfGoodsFromCustodian(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		FillInBasedOnReturnOfGoodsFromCustomer(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.AssemblyFromComponents") Then
		FillInBasedOnAssemblyOfGoods(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.GoodsReceiptForStorage") Then
		FillInOnBasisOfAcceptanceOfGoodsForStorage(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.OtherGoodsRecordingAsReceived") Then
		FillInBasedOnOtherGoodsRegistration(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.MovementOfProductsAndMaterials") Then
		FillInBasedOnRegisteredRecordsOfProductsAndMaterials(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.InventoryTransfer") Then
		FillInBasedOnMovementOfGoods(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.RequestForGoodsQualityControl") Then
		FillInBasedOnApplicationForQualityControlOfGoods(FillingData);
	ElsIf TypeOf(FillingData) = Type("Structure") And FillingData.Property("AccordingToResearchDocuments")
			And TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.RequestForGoodsQualityControl") Then
		FillInOnBasisOfApplicationForQualityControlOfGoodsForResearch(FillingData);
	ElsIf TypeOf(FillingData) = Type("Structure") And FillingData.Property("DocumentResearch")
			And TypeOf(FillingData.DocumentResearch) = Type("DocumentRef.GoodsQualityResearch") Then
		FillOutGoodsQualityStudyBasedOn(FillingData);
	EndIf;
	
	InitializeDocument(FillingData);
	
EndProcedure

#EndRegion

#Region Internal

#Region EmbeddedMechanisms

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
	
	Status = Enums.StatusesOfQualityControlCertificates[NewStatus];
	
	Return CheckFilling();
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInBasedOnPurchaseOfGoodsAndServices(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập chứng từ kiểm soát chất lượng. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению актов контроля качества. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|tr = '%1 belgesine göre kalite kontrol tutanağı düzenlenecek giriş yapılmış ürün stoku yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ControlledLotReference = Analysts[0].ControlledLotReference;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInBasedOnReceiptOfGoodsAtWarehouse(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập chứng từ kiểm soát chất lượng. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению актов контроля качества. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|tr = '%1 belgesine göre kalite kontrol tutanağı düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ControlledLotReference = Analysts[0].ControlledLotReference;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInBasedOnReceiptOfGoodsFromClient(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập chứng từ kiểm soát chất lượng. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению актов контроля качества. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|tr = '%1 belgesine göre kalite kontrol tutanağı düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ControlledLotReference = Analysts[0].ControlledLotReference;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInBasedOnReceiptOfGoodsFromCustodian(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập chứng từ kiểm soát chất lượng. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению актов контроля качества. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|tr = '%1 belgesine göre kalite kontrol tutanağı düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ControlledLotReference = Analysts[0].ControlledLotReference;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInBasedOnReturnOfGoodsFromCustomer(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập chứng từ kiểm soát chất lượng. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению актов контроля качества. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|tr = '%1 belgesine göre kalite kontrol tutanağı düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ControlledLotReference = Analysts[0].ControlledLotReference;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInBasedOnAssemblyOfGoods(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập chứng từ kiểm soát chất lượng. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению актов контроля качества. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|tr = '%1 belgesine göre kalite kontrol tutanağı düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ControlledLotReference = Analysts[0].ControlledLotReference;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInOnBasisOfAcceptanceOfGoodsForStorage(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập chứng từ kiểm soát chất lượng. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению актов контроля качества. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|tr = '%1 belgesine göre kalite kontrol tutanağı düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ControlledLotReference = Analysts[0].ControlledLotReference;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInBasedOnOtherGoodsRegistration(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập chứng từ kiểm soát chất lượng. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению актов контроля качества. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|tr = '%1 belgesine göre kalite kontrol tutanağı düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ControlledLotReference = Analysts[0].ControlledLotReference;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure
Procedure FillInBasedOnRegisteredRecordsOfProductsAndMaterials(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập chứng từ kiểm soát chất lượng. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению актов контроля качества. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|tr = '%1 belgesine göre kalite kontrol tutanağı düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ControlledLotReference = Analysts[0].ControlledLotReference;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure
Procedure FillInBasedOnMovementOfGoods(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập chứng từ kiểm soát chất lượng. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению актов контроля качества. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing quality control certificates. Population is unavailable.';
							|tr = '%1 belgesine göre kalite kontrol tutanağı düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ControlledLotReference = Analysts[0].ControlledLotReference;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInBasedOnApplicationForQualityControlOfGoods(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa để lập chứng từ kiểm soát chất lượng. Không thể điền.';
							|ru = 'По документу %1 нет остатков товаров к оформлению актов контроля качества. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining goods for issuing quality control certificates. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining goods for issuing quality control certificates. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining goods for issuing quality control certificates. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining goods for issuing quality control certificates. Population is unavailable.';
							|tr = '%1 belgesine göre kalite kontrol tutanağı düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ControlledLotReference = Analysts[0].ControlledLotReference;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillOutGoodsQualityStudyBasedOn(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData.DocumentBasis);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	If FillingData.Control = Enums.QualityControl.Selective Then
		DataTable = GoodsResearch.ResultsOfGoodsStudiedSelectiveControl(DataTable, FillingData.DocumentResearch);
	Else
		DataTable = GoodsResearch.ResultsOfGoodsStudiedAreContinuousControl(DataTable, FillingData.DocumentResearch);
	EndIf;
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa để lập chứng từ kiểm soát chất lượng. Không thể điền.';
							|ru = 'По документу %1 нет остатков товаров к оформлению актов контроля качества. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining goods for issuing quality control certificates. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining goods for issuing quality control certificates. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining goods for issuing quality control certificates. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining goods for issuing quality control certificates. Population is unavailable.';
							|tr = '%1 belgesine göre kalite kontrol tutanağı düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, Ref);
		Raise ExceptionText;
	EndIf;
	For Each TSRow In DataTable Do
		Filter = New Structure;
		Filter.Insert("Products", TSRow.Products);
		Filter.Insert("Characteristic", TSRow.Characteristic);
		Filter.Insert("Series", TSRow.Series);
		Filter.Insert("Purpose", TSRow.Purpose);
		Filter.Insert("Warehouse", TSRow.Warehouse);
		Filter.Insert("QualityCheckResult", TSRow.QualityCheckResult);
		Filter.Insert("Action", TSRow.Action);
		FoundRows = Goods.FindRows(Filter);
		If FoundRows.Count() = 0 Then
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, TSRow);
			NewRow.RowID = New UUID();
			RowID = NewRow.RowID;
		Else
			RowID = FoundRows[0].RowID;
		EndIf;
		NewRow = ResearchResults.Add();
		FillPropertyValues(NewRow, TSRow);
		NewRow.RowID = RowID;
	EndDo;
	ControlledLotReference = Analysts[0].ControlledLotReference;
	Organization = Common.ObjectAttributeValue(FillingData.DocumentBasis, "Organization");
	DocumentBasis = FillingData.DocumentBasis;
	Date = CurrentSessionDate();
	
EndProcedure

Procedure FillInOnBasisOfApplicationForQualityControlOfGoodsForResearch(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData.DocumentBasis);
	DataTable = QualityControl.AnalystBalances(Analysts, False, Undefined);
	DataTable = GoodsResearch.ResultsOfGoodsExaminedAccordingToControlApplication(DataTable, FillingData.AccordingToResearchDocuments);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa để lập chứng từ kiểm soát chất lượng. Không thể điền.';
							|ru = 'По документу %1 нет остатков товаров к оформлению актов контроля качества. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining goods for issuing quality control certificates. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining goods for issuing quality control certificates. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining goods for issuing quality control certificates. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining goods for issuing quality control certificates. Population is unavailable.';
							|tr = '%1 belgesine göre kalite kontrol tutanağı düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, Ref);
		Raise ExceptionText;
	EndIf;
	For Each TSRow In DataTable Do
		Filter = New Structure;
		Filter.Insert("Products", TSRow.Products);
		Filter.Insert("Characteristic", TSRow.Characteristic);
		Filter.Insert("Series", TSRow.Series);
		Filter.Insert("Purpose", TSRow.Purpose);
		Filter.Insert("Warehouse", TSRow.Warehouse);
		Filter.Insert("QualityCheckResult", TSRow.QualityCheckResult);
		Filter.Insert("Action", TSRow.Action);
		FoundRows = Goods.FindRows(Filter);
		If FoundRows.Count() = 0 Then
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, TSRow);
			NewRow.RowID = New UUID();
			RowID = NewRow.RowID;
		Else
			RowID = FoundRows[0].RowID;
		EndIf;
		NewRow = ResearchResults.Add();
		FillPropertyValues(NewRow, TSRow);
		NewRow.RowID = RowID;
	EndDo;
	ControlledLotReference = Analysts[0].ControlledLotReference;
	Organization = Common.ObjectAttributeValue(FillingData.DocumentBasis, "Organization");
	DocumentBasis = FillingData.DocumentBasis;
	Date = CurrentSessionDate();
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	If Not ValueIsFilled(Status) Then
		Status = Enums.StatusesOfQualityControlCertificates.InProgress;
	EndIf;
	If Goods.Count() = 0 Then
		Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Else
		QualityControl.FillCleanWarehouseRoomAccordingToTabularPartOfDocument(ThisObject);
	EndIf;
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Department = SettingsValueCached.UserDivision(EmployeeResponsible, Department);
	Author = Users.CurrentUser();
	EmployeeResponsible = Users.CurrentUser();
	
	If Goods.Count() > 0 Then
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsQualityControlCertificate);
		ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	EndIf;
	Documents.GoodsQualityControlCertificate.FillInDetailsFromParty(ThisObject);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
