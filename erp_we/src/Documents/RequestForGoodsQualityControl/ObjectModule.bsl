
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array();
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel);
		
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RequestForGoodsQualityControl),
		Cancel,
		NotCheckedAttributeArray);
		
	WarehousesServer.CheckFillingOfPremises(ThisObject, NotCheckedAttributeArray, Cancel);
	WarehousesServer.CheckFillingOfCells(ThisObject, NotCheckedAttributeArray, Cancel);
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.CheckCompletenessOfProductLocations = True;
	CheckParameters.FieldsForCheckingCompleteness = "ControlledLotReference,QualityIsConfirmed,Purpose,Warehouse,Premise";
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	// Checking the filling of the packages of the nomenclature at the address warehouses
	WarehouseSelection_ = QualityControl.WarehouseSelection_(Goods.Unload(,"Warehouse,Premise"), Date);
	While WarehouseSelection_.Next() Do
		CheckParameters = ProductsServer.ParametersForCheckingFillingOfPackages();
		CheckParameters.SelectingRowsToCheck.Insert("Warehouse", WarehouseSelection_.Warehouse);
		CheckParameters.SelectingRowsToCheck.Insert("Premise", WarehouseSelection_.Premise);
		ProductsServer.CheckFillingOfPackages(
			ThisObject,
			NotCheckedAttributeArray,
			Cancel,
			CheckParameters);
	EndDo;
	
	If NotCheckedAttributeArray.Find("Goods.Package") = Undefined Then
		NotCheckedAttributeArray.Add("Goods.Package");
	EndIf;
	
	If Not ToScheduleGoodsUnlock Then
		NotCheckedAttributeArray.Add("QualityConfirmationDate");
	EndIf;
	
	If ReasonForGoodsLock <> Catalogs.GoodsLockReasons.InputQualityControlOfGoods Then
		NotCheckedAttributeArray.Add("Goods.ControlledLotReference");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	// The mechanism of "Controlled Lot references".
	// The application always makes Register Records for Goods in warehouses, so the Lot reference is always needed.
	KeyAttributes = QualityControl.DetailsOfDeterminingNeedForLotReferenceInDocument(Undefined, Undefined);
	QualityControl.FillInControlledLotReferenceBeforeWritingDocument(ThisObject, KeyAttributes);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateUpdateControlledLotReferenceWhenWritingDocument(ThisObject);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentBasis = Undefined;
	ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
	InitializeDocument();
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If TypeOf(FillingData) = Type("DocumentRef.VendorInvoice") Then
		FillInBasedOnPurchaseOfGoodsAndServices(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.VendorInvoice") Then
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
	EndIf;
	InitializeDocument(FillingData);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInBasedOnPurchaseOfGoodsAndServices(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, True, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập yêu cầu kiểm soát chất lượng hàng hóa. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению заявок на контроль качества товаров. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|tr = '%1 belgesine göre ürün kalite kontrol talebi düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInBasedOnReceiptOfGoodsAtWarehouse(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, True, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập yêu cầu kiểm soát chất lượng hàng hóa. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению заявок на контроль качества товаров. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|tr = '%1 belgesine göre ürün kalite kontrol talebi düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInBasedOnReceiptOfGoodsFromClient(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, True, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập yêu cầu kiểm soát chất lượng hàng hóa. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению заявок на контроль качества товаров. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|tr = '%1 belgesine göre ürün kalite kontrol talebi düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInBasedOnReceiptOfGoodsFromCustodian(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, True, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập yêu cầu kiểm soát chất lượng hàng hóa. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению заявок на контроль качества товаров. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|tr = '%1 belgesine göre ürün kalite kontrol talebi düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInBasedOnReturnOfGoodsFromCustomer(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, True, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập yêu cầu kiểm soát chất lượng hàng hóa. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению заявок на контроль качества товаров. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|tr = '%1 belgesine göre ürün kalite kontrol talebi düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInBasedOnAssemblyOfGoods(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, True, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập yêu cầu kiểm soát chất lượng hàng hóa. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению заявок на контроль качества товаров. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|tr = '%1 belgesine göre ürün kalite kontrol talebi düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure
Procedure FillInOnBasisOfAcceptanceOfGoodsForStorage(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, True, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập yêu cầu kiểm soát chất lượng hàng hóa. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению заявок на контроль качества товаров. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|tr = '%1 belgesine göre ürün kalite kontrol talebi düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure FillInBasedOnOtherGoodsRegistration(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, True, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập yêu cầu kiểm soát chất lượng hàng hóa. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению заявок на контроль качества товаров. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|tr = '%1 belgesine göre ürün kalite kontrol talebi düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure
Procedure FillInBasedOnRegisteredRecordsOfProductsAndMaterials(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, True, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập yêu cầu kiểm soát chất lượng hàng hóa. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению заявок на контроль качества товаров. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|tr = '%1 belgesine göre ürün kalite kontrol talebi düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure
Procedure FillInBasedOnMovementOfGoods(FillingData)
	
	Analysts = QualityControl.AnalystsOfReceivedGoods(FillingData);
	DataTable = QualityControl.AnalystBalances(Analysts, True, Undefined);
	If DataTable.Count() = 0 Then
		ExceptionText = NStr("vi = 'Theo chứng từ %1, không có tồn kho hàng hóa nhập để lập yêu cầu kiểm soát chất lượng hàng hóa. Không thể điền.';
							|ru = 'По документу %1 нет остатков поступивших товаров к оформлению заявок на контроль качества товаров. Заполнение невозможно.';
							|en = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.'; fa = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|it = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|pl = 'For the ""%1"" document, there are no remaining received goods for issuing requests for goods quality control. Population is unavailable.';
							|tr = '%1 belgesine göre ürün kalite kontrol talebi düzenlenecek giriş yapılmış ürün bakiyesi yok. Doldurma mümkün değil.'");
		ExceptionText = StrTemplate(ExceptionText, FillingData);
		Raise ExceptionText;
	EndIf;
	Goods.Load(DataTable);
	ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Organization = Common.ObjectAttributeValue(FillingData, "Organization");
	DocumentBasis = FillingData;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	ToScheduleGoodsUnlock = True;
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
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RequestForGoodsQualityControl);
		ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf