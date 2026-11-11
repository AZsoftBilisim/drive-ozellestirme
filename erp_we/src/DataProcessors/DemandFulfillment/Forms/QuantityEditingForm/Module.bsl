#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CustomizeFormForIntendedUse();
	
	For Each String In Parameters.Rows Do
		
		NewRow = Inventories.Add();
		FillPropertyValues(NewRow, String);
		NewRow.AgreementCurrencyAmount = NewRow.PriceInTheCurrencyOfAgreement * NewRow.ToOrder;
		
	EndDo;
	
	RoundingDifference = Parameters.Count - Inventories.Total("ToOrder");
	If RoundingDifference > 0 Then
		
		RowFilter = New Structure("ThisIsInventory", True);
		RowsArray = Inventories.FindRows(RowFilter);
		
		If RowsArray.Count() > 0 Then
			TableRow = RowsArray[0];
			TableRow.ToOrder = TableRow.ToOrder + RoundingDifference;
		Else
			TableRow = Inventories.Add();
			FillPropertyValues(TableRow, Inventories[0],,"Demand");
			TableRow.LineNumber = 0;
			TableRow.Purpose = Undefined;
			TableRow.ToOrder = RoundingDifference;
		EndIf;
		
		TableRow.AgreementCurrencyAmount = TableRow.PriceInTheCurrencyOfAgreement * TableRow.ToOrder;
		
	EndIf;
	
	TreeLineNumber         = Parameters.RowSelected;
	SupplyType            = Parameters.SupplyType;
	MinimumDeliveryLot = Parameters.MinimumDeliveryLot;
	
	FillInServiceDetailsForProductRange();
	SetConditionalAppearance();
	
	If Inventories.Count() > 0 Then
		OrderPackage = Inventories[0].OrderPackage;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	For Each String In Inventories Do
		
		String.OrderPackage = ValueSelected;
		
	EndDo;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	CalculateTotals();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInventories

&AtClient
Procedure InventoriesSelection(Item, RowSelected, Field, StandardProcessing)
	If Field.Name = "InventoriesOrderPackage" Then
		UnitsOfMeasurement = New Array();
		UnitsOfMeasurement.Add(Item.CurrentData.UnitOfMeasure);
		
		ParametersOfSelectionForm = New Structure("Owner", Item.CurrentData.Products);
		FormParameters      = New Structure("Filter", ParametersOfSelectionForm);
		FormParameters.Insert("UnitsOfMeasurement", UnitsOfMeasurement);
		
		OpenForm("DataProcessor.DemandFulfillment.Form.SelectionFormOfPackageUnit", FormParameters, ThisForm, UUID);
	EndIf;
EndProcedure

&AtClient
Procedure InventoriesBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

&AtClient
Procedure InventoriesBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	Cancel = True;
EndProcedure

&AtClient
Procedure InventoriesToOrderOnChange(Item)
	CurrentRow = Items.Inventories.CurrentData;
	CurrentRow.AgreementCurrencyAmount = CurrentRow.ToOrder * CurrentRow.PriceInTheCurrencyOfAgreement;
	
	CalculateTotals();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Accept(Command)
	
	Response = GenerateResponseStructure(True);
	Close(Response);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	If SupplyType = Enums.SupplyTypes.Purchase Then
		Title = Title + NStr("vi = 'Đơn hàng đặt nhà cung cấp';
							|ru = 'Заказ поставщику';
							|en = 'Purchase order'; fa = 'سفارش خرید';
							|it = 'Ordine al fornitore';
							|pl = 'Zamówienie do dostawcy';
							|tr = 'Tedarikçi siparişi'");
	ElsIf SupplyType = Enums.SupplyTypes.Move Then
		Title = Title + NStr("vi = 'Đơn hàng điều chuyển nội bộ';
							|ru = 'Заказ на перемещение';
							|en = 'Transfer order'; fa = 'سفارش انتقال';
							|it = 'Ordine di trasferimento';
							|pl = 'Zamówienie przemieszczenia';
							|tr = 'Transfer emri'");
	ElsIf SupplyType = Enums.SupplyTypes.Production Then
		Title = Title + NStr("vi = 'Đơn hàng sản xuất';
							|ru = 'Заказ на производство';
							|en = 'Production order'; fa = 'سفارش تولید';
							|it = 'Ordine di produzione';
							|pl = 'Zlecenie produkcyjne';
							|tr = 'Üretim emri'");
	ElsIf SupplyType = Enums.SupplyTypes.AssemblyDisassembly Then
		Title = Title + NStr("vi = 'Đơn hàng đóng bộ/tách bộ';
							|ru = 'Заказ на сборку/разборку';
							|en = 'Kitting order'; fa = 'سفارش کیت‌سازی';
							|it = 'Ordine di assemblaggio/disassemblaggio';
							|pl = 'Zamówienie na montaż/demontaż';
							|tr = 'Montaj (demontaj) emri'");
	ElsIf SupplyType = Enums.SupplyTypes.ProductionByThirdParty Then
		Title = Title + NStr("vi = 'Đơn đặt hàng gia công';
							|ru = 'Заказ переработчику';
							|en = 'Subcontracting purchase order'; fa = 'سفارش خرید پیمانکاری فرعی';
							|it = 'Ordine al subfornitore';
							|pl = 'Zamówienie do przetwórcy';
							|tr = 'Fason satın alma siparişi'");
	EndIf;

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisForm, "InventoriesCharacteristic", "Inventories.ItemVariantsAreUsed");
	
	SetVisibilityOfOrderPackaging();

EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	ParametersForFillingInBankingDetails = New Structure;
	ParametersForFillingInBankingDetails.Insert("FillInFeatureAttribute",
	New Structure("Products", "ItemVariantsAreUsed"));
	ParametersForFillingInBankingDetails.Insert("FillInArticleAttribute",
	New Structure("Products", "SKU"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(Inventories, ParametersForFillingInBankingDetails);
	
EndProcedure

&AtServer
Procedure SetVisibilityOfOrderPackaging()
	
	UsePackages = GetFunctionalOption("UseItemPackages");
	
	Items.InventoriesOrderPackage.Visible = UsePackages;
	Items.OrderPackage.Visible = UsePackages;
	
	If Not UsePackages Then
		Return;
	EndIf;
	
	ShowPackaging = False;
	
	If Inventories.Count() > 0 Then
		SupplyType = Common.ObjectAttributeValue(Inventories[0].SupplyMethod, "SupplyType");
		
		If SupplyType = Enums.SupplyTypes.Purchase Then
			ShowPackaging = True;
		EndIf;
		
	EndIf;
	
	Items.InventoriesOrderPackage.Visible = ShowPackaging;
	Items.OrderPackage.Visible = ShowPackaging;
	
EndProcedure

&AtClient
Function PrepareStringStructure()
	
	StringStructure = New Structure("Products, Characteristic, ToOrder, OrderPackage, PackageNumerator, PackageDenominator, LineNumber, ThisIsInventory");
	
	Return StringStructure;
	
EndFunction

&AtClient
Function GenerateResponseStructure(HasChanges)
	
	Response  = New Structure;
	Rows = New Array;
	
	For Each LineStock In Inventories Do
		StringStructure = PrepareStringStructure();
		FillPropertyValues(StringStructure, LineStock);
		Rows.Add(StringStructure);
	EndDo;
	
	Response.Insert("HasChanges",     HasChanges);
	Response.Insert("Rows",            Rows);
	Response.Insert("TreeLineNumber", TreeLineNumber);
	Response.Insert("InTotal",             Inventories.Total("ToOrder"));
	
	Return Response;
	
EndFunction

&AtClient
Procedure CalculateTotals()
	
	TotalToOrder     = Inventories.Total("ToOrder");
	TotalDemand = Inventories.Total("Demand");
	TotalAmount       = Inventories.Total("AgreementCurrencyAmount");
	
EndProcedure

&AtServer
Procedure CustomizeFormForIntendedUse()
	
	If PurposeUseKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds() Then
		Items.InventoriesToOrder.Title = NStr("vi = 'Chuyển vào giấy đề nghị';
												|ru = 'В заявку';
												|en = 'To request'; fa = 'To request';
												|it = 'To request';
												|pl = 'To request';
												|tr = 'Başvuruya'");
		Items.OrderPackage.Title = NStr("vi = 'Đóng gói giấy đề nghị';
										|ru = 'Упаковка заявки';
										|en = 'Request packaging unit'; fa = 'Request packaging unit';
										|it = 'Request packaging unit';
										|pl = 'Request packaging unit';
										|tr = 'Talep paketleme ünitesi'");
	EndIf;
	
EndProcedure

#EndRegion