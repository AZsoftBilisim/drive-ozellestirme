#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DocumentsKinds = Parameters.DocumentsKinds;
		
	CreateTreeOfDocumentTypes(DocumentsKinds);
	Items.SelectionByTypeOfDocuments.InitialTreeView = InitialTreeView.ExpandAllLevels;
	SetConditionalAppearance();
EndProcedure
////////////////////////////////////////////////////////////////////////////////////////////////////
// EVENT HANDLERS FOR THE FORM'S SAMPLE DOCUMENT VIEW TABLES

&AtServer
Procedure AddRowOfDocumentTypesTree(MetadataObject, UpperLevelRow)

	LineDetailedRecords = UpperLevelRow.Rows.Add();
	LineDetailedRecords.MetadataObjectName = MetadataObject.Name;
	LineDetailedRecords.FullMetadataName = MetadataObject.FullName();
	LineDetailedRecords.Presentation = MetadataObject.Synonym; 
	If LineDetailedRecords.MetadataObjectName = "PriceSetup" Then
		Presentation = LineDetailedRecords.Presentation;
		LineDetailedRecords.Presentation = Presentation + NStr("vi = ' (Được tùy chỉnh bởi bộ lọc - ""Kết xuất chứng từ Đặt bảng giá"")';
																|ru = ' (Настраивается отбором - ""Выгружать документ Установка цен номенклатуры"")';
																|en = ' (Configured using the ""Export Price setup document"" filter)'; fa = ' (Configured using the ""Export Price setup document"" filter)';
																|it = ' (Настраивается отбором - ""Выгружать документ Установка цен номенклатуры"")';
																|pl = ' (Configured using the ""Export Price setup document"" filter)';
																|tr = ' (şu filtre ile ayarlanır: ""Ürün fiyatını belirleme"" belgesini dışa aktar"")'");
	EndIf;
EndProcedure

&AtServer
Procedure CreateTreeOfDocumentTypes(ArrayOfSelectedValues_)

	SelectionTree_ = FormAttributeToValue("SelectionTreeByDocumentType", Type("ValueTree"));
	SelectionTree_.Rows.Clear();
	
	MetaDocuments = Metadata.Documents;
	
	UpperLevelRow = SelectionTree_.Rows.Add();
	UpperLevelRow.Presentation = NStr("vi = 'Mua hàng';
										|ru = 'Закупки';
										|en = 'Purchasing'; fa = 'تدارکات';
										|it = 'Закупки';
										|pl = 'Zakupy';
										|tr = 'Satın alımlar'");
	
	AddRowOfDocumentTypesTree(MetaDocuments.ReturnOfGoodsToVendor, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.PurchaseOrder, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.ApplicationForImportationOfGoods, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.PurchaseAdjustment, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.VendorInvoice, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.VendorInvoiceServicesAndAssets, UpperLevelRow); 
	UpperLevelRow = SelectionTree_.Rows.Add();
	UpperLevelRow.Presentation = NStr("vi = 'Ngân quỹ';
										|ru = 'Казначейство';
										|en = 'Treasury'; fa = 'خزانه‌داری';
										|it = 'Казначейство';
										|pl = 'Środki pieniężne';
										|tr = 'Hazine'");
	
	AddRowOfDocumentTypesTree(MetaDocuments.ExpenseReport, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.DepositCashIntoCashRegister, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.ARAPSettlement, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.CashWithdrawalFromCashRegister, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.PaymentRequest, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.ARAPAdjustment, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.LoanAndDepositInterestCharge, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.PaymentCardTransaction, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.BankReportOnAcquiringTransactions, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.BankAccountReceiptNote, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.CashAccountReceiptNote, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.CashVoucher, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.BankAccountIssue, UpperLevelRow);
	UpperLevelRow = SelectionTree_.Rows.Add();  
	UpperLevelRow.Presentation = NStr("vi = 'Bán hàng';
										|ru = 'Продажи';
										|en = 'Sales'; fa = 'فروش';
										|it = 'Продажи';
										|pl = 'Sprzedaż';
										|tr = 'Satış'");
	AddRowOfDocumentTypesTree(MetaDocuments.GiftCertificateCancellation, UpperLevelRow); 	
	AddRowOfDocumentTypesTree(MetaDocuments.CustomerInvoiceServices, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.ReturnOfGiftCards, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.ReturnOfGoodsFromCustomer, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.IntercompanyGoodsReturn, UpperLevelRow);
	 
	AddRowOfDocumentTypesTree(MetaDocuments.SalesOrder, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.CashRegisterShift, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.SaleAdjustment, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.GoodsShipmentToCustomer, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.ConsignmentReportFromCustomer, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.WriteOffReportFromCommissionAgent, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.CommissionReportIntercompany, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.CommissionWriteOffReportIntercompany, UpperLevelRow);
 	AddRowOfDocumentTypesTree(MetaDocuments.ConsignmentReportToVendor, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.PurchaseInvoiceConsignmentStockLost, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.RetailReturnsReport, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.RetailSalesReport, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.CustomerInvoiceIntercompany, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.TransferOfGoodsToBailee, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.GiftCertificateSale, UpperLevelRow);
    AddRowOfDocumentTypesTree(MetaDocuments.CustomerInvoice, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.CustomerInvoiceServicesAndAssets, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.CustomerCommercialInvoice, UpperLevelRow);
	UpperLevelRow = SelectionTree_.Rows.Add();
	UpperLevelRow.Presentation = NStr("vi = 'Sản xuất';
										|ru = 'Производство';
										|en = 'Manufacturing'; fa = 'تولید';
										|it = 'Производство';
										|pl = 'Produkcja';
										|tr = 'Üretim'");
	
	AddRowOfDocumentTypesTree(MetaDocuments.MovementOfProductsAndMaterials, UpperLevelRow);
    AddRowOfDocumentTypesTree(MetaDocuments.MaterialProviderOrder2_5, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.ReportToMaterialProvider2_5, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.SubcontractorReport2_5, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.GoodsShipmentFromStorage, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.TransferOfGoodsToBailee, UpperLevelRow); 
		
	AddRowOfDocumentTypesTree(MetaDocuments.ReceiptOfGoodsFromCustodian, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.GoodsReceiptForStorage, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.BackflushProduction, UpperLevelRow);
	
	UpperLevelRow = SelectionTree_.Rows.Add();
	UpperLevelRow.Presentation = NStr("vi = 'Kho bãi';
										|ru = 'Склад';
										|en = 'Warehouse'; fa = 'Warehouse';
										|it = 'Склад';
										|pl = 'Warehouse';
										|tr = 'Ambar'");
	
	AddRowOfDocumentTypesTree(MetaDocuments.InventoryConsumption, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.RedemptionOfGoodsFromStorage, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.TransferOrder, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.PhysicalCountReport, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.PhysicalCountOfInventoryInOperation, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.ReportOnVMIAdjustment, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.InventorySurplusRecognition, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.InventoryTransfer, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.GoodsMisgrading, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.InventoryRecount, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.OtherGoodsRecordingAsReceived, UpperLevelRow); 
	AddRowOfDocumentTypesTree(MetaDocuments.AssemblyFromComponents, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.Decomissioning, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.WriteOffOfGoodsShortages, UpperLevelRow);
			
	
	UpperLevelRow = SelectionTree_.Rows.Add();
	UpperLevelRow.Presentation = NStr("vi = 'Khác';
										|ru = 'Прочее';
										|en = 'Other'; fa = 'سایر';
										|it = 'Прочее';
										|pl = 'Other';
										|tr = 'Diğer'");
	AddRowOfDocumentTypesTree(MetaDocuments.ReversingEntry, UpperLevelRow);
	AddRowOfDocumentTypesTree(MetaDocuments.PriceSetup, UpperLevelRow);  
	
	For Each UpperLevelRow In SelectionTree_.Rows Do
		SelectedAllItems = True;    
		PartOfElementsSelected = False;
		For Each LineDetailedRecords In UpperLevelRow.Rows Do
			If ArrayOfSelectedValues_.Find(LineDetailedRecords.MetadataObjectName) = Undefined Then
				SelectedAllItems = False;
			Else
				LineDetailedRecords.Check = 1;  
				PartOfElementsSelected = True;
			EndIf;
			LineDetailedRecords.PictureIndex = -1;
		EndDo;
		If SelectedAllItems Then
			UpperLevelRow.Check = 1;
		ElsIf PartOfElementsSelected Then
		     UpperLevelRow.Check = 2;
		EndIf;
		UpperLevelRow.PictureIndex = 0;  
	EndDo;
	
	ValueToFormAttribute(SelectionTree_, "SelectionTreeByDocumentType");
	
EndProcedure

&AtClient
Procedure ClearMark1(Command)
	
	FillInMarks(False);
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	FillInMarks(True);
	
EndProcedure

&AtServer
Procedure FillInMarks(MarkValue, ItemID = Undefined)
	If ItemID <> Undefined Then
		TreeItem = SelectionTreeByDocumentType.FindByID(ItemID);
		LowerLevelElements = TreeItem.GetItems();
		For Each LowerLevelElement In LowerLevelElements Do
			LowerLevelElement.Check = MarkValue;
		EndDo;
	Else
		TopLevelElements = SelectionTreeByDocumentType.GetItems();
		For Each TopLevelItem In TopLevelElements Do
			TopLevelItem.Check = MarkValue;
			LowerLevelElements = TopLevelItem.GetItems();
			For Each LowerLevelElement In LowerLevelElements Do
				LowerLevelElement.Check = MarkValue;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionByTypeOfDocumentsCheckOnChange(Item)
	
	CurrentData = Items.SelectionByTypeOfDocuments.CurrentData;
	If CurrentData <> Undefined Then
		
		CurrentData.Check = CurrentData.Check % 2;
		
		If CurrentData.GetParent() = Undefined Then
			MarkValue = CurrentData.Check;
			FillInMarks(MarkValue, CurrentData.GetID()); 
		Else
			String = Items.SelectionByTypeOfDocuments.CurrentRow; 
			PutMarksHierarchicallyOnServer(String);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure PutMarksHierarchicallyOnServer(String)
	DataElement = SelectionTreeByDocumentType.FindByID(String);
	SetMarksUp(DataElement);
EndProcedure

// Recursive maintenance of hierarchical marks with three States in the tree. 
//
// Parameters:
//    RowData - FormDataTreeItem - the tag is stored in the numeric column "Tag".
//
&AtServer
Procedure SetMarksUp(RowData) Export
	RowParent = RowData.GetParent();
	If RowParent <> Undefined Then
		AllTrue = True;
		NotAllFalse = False;
		For Each Child In RowParent.GetItems() Do
			AllTrue = AllTrue And (Child.Check = 1);
			NotAllFalse = NotAllFalse Or Boolean(Child.Check);
		EndDo;
		If AllTrue Then
			RowParent.Check = 1;
		ElsIf NotAllFalse Then
			RowParent.Check = 2;
		Else
			RowParent.Check = 0;
		EndIf;
		SetMarksUp(RowParent);
	EndIf;
EndProcedure

&AtClient
Procedure WriteClose(Command)
	
	FormClosingParameters = New Structure();
	FormClosingParameters.Insert("AddressOfTableInTemporaryStorage", CreateTableOfSelectedValues());
	FormClosingParameters.Insert("NameOfTableToFillIn",          "DocumentsKinds");
		
	NotifyChoice(FormClosingParameters);
	
EndProcedure

&AtServer
Function CreateTableOfSelectedValues()

	TableOfSelectedValues = New ValueTable;
	TableOfSelectedValues.Columns.Add("MetadataObjectName"); 
	TableOfSelectedValues.Columns.Add("DocumentType");
	TableOfSelectedValues.Columns.Add("Presentation");
	TableOfSelectedValues.Columns.Add("Use");
	
	TopLevelElements = SelectionTreeByDocumentType.GetItems();
	For Each TopLevelItem In TopLevelElements Do
		ElementsOfDetailedRecords = TopLevelItem.GetItems();
		For Each DetailedRecordsElement In ElementsOfDetailedRecords Do
			If Not DetailedRecordsElement.Check Then
				Continue;
			EndIf;
			NewRow = TableOfSelectedValues.Add();
			NewRow.MetadataObjectName = DetailedRecordsElement.MetadataObjectName; 
			NewRow.Presentation = DetailedRecordsElement.Presentation;
			NewRow.Use = True;
		EndDo;
	EndDo;
	If TableOfSelectedValues.Count() > 0 Then
		Filter = New Structure;
		Filter.Insert("MetadataObjectName","PriceSetup"); 
		Found_Strings = TableOfSelectedValues.FindRows(Filter);
		If Found_Strings.Count() = 0 Then
			NewRow = TableOfSelectedValues.Add();
			NewRow.MetadataObjectName = "PriceSetup";
			NewRow.Presentation = "Set prices_ ofproductitem";
			NewRow.Use = True;  
		EndIf;
	EndIf;
	Return PutToTempStorage(TableOfSelectedValues, UUID);

EndFunction
&AtClient
Procedure UpdateDecorationWarning(MetadataObjectName, GroupName)  
	Items.WarningGroup.Visible = True;
	DocumentIsNotIncludedInArray = True;
	ArrayOfDependentDocuments = New Array;
	ArrayOfDependentDocuments.Add("invoices1"); 
	ArrayOfDependentDocuments.Add("taxinvoice");
	ArrayOfDependentDocuments.Add("adjusting");
	ArrayOfDependentDocuments.Add("sales");
	ArrayOfDependentDocuments.Add("purchases");
		
	For Each ArrayRow In ArrayOfDependentDocuments Do
		If Not Find(Lower(GroupName), ArrayRow) = 0 
			Or Not Find(Lower(MetadataObjectName), ArrayRow) = 0 Then
			Items.WarningDecoration.Title = NStr("vi = 'Cảnh báo! Việc ghi nhận tất cả các loại hóa đơn GTGT và điều chỉnh 
			|sẽ được thực hiện để trao đổi khi sẵn có chứng từ-cơ sở 
			|được ghi nhận. Hãy lưu ý điều này khi thiết lập bộ lọc';
			|ru = 'Предупреждение! Регистрация всех типов счетов-фактур и корректировок 
			|будет осуществляться для обмена только при наличии зарегистрированного  
			|документа-основания. Учитывайте это при установке отборов';
			|en = 'Warning. All types of tax invoices and adjustments 
			|will be registered for exchange only if there is a registered 
			|base document. Keep this in mind when setting filters'; fa = 'Warning. All types of tax invoices and adjustments 
			|will be registered for exchange only if there is a registered 
			|base document. Keep this in mind when setting filters';
			|it = 'Предупреждение! Регистрация всех типов счетов-фактур и корректировок 
			|будет осуществляться для обмена только при наличии зарегистрированного  
			|документа-основания. Учитывайте это при установке отборов';
			|pl = 'Warning. All types of tax invoices and adjustments 
			|will be registered for exchange only if there is a registered 
			|base document. Keep this in mind when setting filters';
			|tr = 'Предупреждение! Регистрация всех типов счетов-фактур и корректировок 
			|будет осуществляться для обмена только при наличии зарегистрированного  
			|документа-основания. Учитывайте это при установке отборов'");
			DocumentIsNotIncludedInArray = False;
			Return
		EndIf;
	EndDo;
	Items.WarningGroup.Visible = Not DocumentIsNotIncludedInArray;
EndProcedure

&AtClient
Procedure SelectionByTypeOfDocumentsOnChange(Item)
	If Item.CurrentData.Check = 1 Then  
		 GroupName = Item.CurrentData.Presentation;
	     MetadataObjectName = Item.CurrentData.MetadataObjectName;
		 UpdateDecorationWarning(MetadataObjectName, GroupName) 
	Else 
		 Items.WarningGroup.Visible = False;
	EndIf;
EndProcedure

&AtClient
Procedure GroupBy(Command)
	SelectionTree_ = SelectionTreeByDocumentType.GetItems();
	TreeName = "SelectionByTypeOfDocuments"; 
	Expand = CollapseTheTree; 
	For Each CollectionItem In SelectionTree_ Do
		NestedCollectionElements = CollectionItem;
		If Expand = True Then
			Items[TreeName].Expand(CollectionItem.GetID());
		Else
			Items[TreeName].Collapse(CollectionItem.GetID());
		EndIf;
	EndDo;
	CollapseTheTree = Not CollapseTheTree;
EndProcedure

#EndRegion

#Region Private

Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();  
	
	Item = ConditionalAppearance.Items.Add();
  	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectionByTypeOfDocuments.Name);                               
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectionTreeByDocumentType.MetadataObjectName");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Font", New Font(,,True,,));  
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectionByTypeOfDocuments.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectionTreeByDocumentType.Presentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList; 
	ListOfUnavailableItems = New ValueList;
	PriceSettingRepresentation = NStr("vi = 'Đặt bảng giá (Được tùy chỉnh bởi bộ lọc - ""Kết xuất chứng từ Đặt bảng giá"")';
										|ru = 'Установка цен номенклатуры (Настраивается отбором - ""Выгружать документ Установка цен номенклатуры"")';
										|en = 'Price setup (Configured using the ""Export Price setup document"" filter)'; fa = 'Price setup (Configured using the ""Export Price setup document"" filter)';
										|it = 'Установка цен номенклатуры (Настраивается отбором - ""Выгружать документ Установка цен номенклатуры"")';
										|pl = 'Price setup (Configured using the ""Export Price setup document"" filter)';
										|tr = 'Ürün fiyatını belirleme (şu filtre ile ayarlanır: ""Ürün fiyatını belirleme"" belgesini dışa aktar"")'");
	ListOfUnavailableItems.Add(PriceSettingRepresentation);
	ListOfUnavailableItems.Add("Other");
	ItemFilter.RightValue = ListOfUnavailableItems;
  	Item.Appearance.SetParameterValue("ReadOnly", True);  
	
EndProcedure

#EndRegion