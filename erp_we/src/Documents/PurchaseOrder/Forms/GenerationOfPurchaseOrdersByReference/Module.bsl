#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	DocumentBasis  = Parameters.DocumentBasis;
	
	DetailsOfFoundation = Common.ObjectAttributesValues(DocumentBasis,
		"Presentation,DateOfShipment,NotShipInInstallments");
	
	Title = DetailsOfFoundation.Presentation;
	DateOfShipment = ?(DetailsOfFoundation.NotShipInInstallments, DetailsOfFoundation.DateOfShipment, Undefined);
	PeggedOrder = Documents.SalesOrder.SeparateProvision(DocumentBasis);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	FillInTheProducts();
	CalculateNumberOfOrders();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_PurchaseOrder" Then

		Ref = GeneralPurposeTMServerCall.ObjectAttributeValue(Source, "Ref");
		UpdateOrderStates(Ref);

	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers 

&AtClient
Procedure OnlyOrderLinesToSupplyOnChange(Item)
	
	ClearMessages();
	FillInTheProducts();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOrders

&AtClient
Procedure OrdersOnChange(Item)
	ProvisionInDocumentsClient.CheckToRunBackgroundInventoryAllocationJob();
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure GoodsSelectedOnChange(Item)
	CalculateNumberOfOrders();
EndProcedure

&AtClient
Procedure GoodsVendorOnChange(Item)
	CalculateNumberOfOrders();
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectRowsExecute()

	For Each OwnGoods In Goods Do
		OwnGoods.Selected = True;
	EndDo;

	CalculateNumberOfOrders();

EndProcedure

&AtClient
Procedure ClearRowsExecute()

	For Each OwnGoods In Goods Do
		OwnGoods.Selected = False;
	EndDo;

	CalculateNumberOfOrders();

EndProcedure

&AtClient
Procedure CreateOrders(Command)

	ClearMessages();

	If Goods.Count() = 0 Then

		CommonClientServer.MessageToUser(NStr("vi = 'Không có dòng để tạo đơn hàng!';
												|ru = 'Отсутствуют строки для формирования заказов!';
												|en = 'To create a Purchase order, add at least one item.'; fa = 'To create a Purchase order, add at least one item.';
												|it = 'Non ci sono righe per generare gli ordini!';
												|pl = 'Brak wiersza do utworzenia zamówień!';
												|tr = 'Sipariş oluşturmak için satır mevcut değil!'"));

	ElsIf OrdersCount = 0 And Goods.Count() > 0 Then

		CommonClientServer.MessageToUser(
				NStr("vi = 'Để lập đơn hàng, cần chỉ ra nhà cung cấp và đánh dấu ít nhất một dòng!';
					|ru = 'Для формирования заказов необходимо указать поставщиков и отметить хотя бы одну строку!';
					|en = 'To create Purchase orders, select at least one item and choose vendors.'; fa = 'To create Purchase orders, select at least one item and choose vendors.';
					|it = 'Per generare gli ordini è necessario specificare i fornitori e contrassegnare almeno una riga!';
					|pl = 'Aby utworzyć zamówienia należy wskazać dostawców i anulować co najmniej jeden wiersz!';
					|tr = 'Sipariş oluşturmak için tedarikçileri belirtmeniz ve en az bir satırı işaretlemeniz gerekir!'"),
				,
				CommonClientServer.PathToTabularSection("Goods", 1, "Selected"),
				,);
	Else

		BeforeCreatingOrdersServer();

	EndIf;

EndProcedure

&AtClient
Procedure OrdersSelection(Item, RowSelected, Field, StandardProcessing)
	OpenForm("Document.PurchaseOrder.ObjectForm", New Structure("Key", Item.CurrentData.Ref), ThisForm);
EndProcedure

&AtClient
Procedure FillInTheSupplier(Command)
	
	FilterStructure1 = New Structure("Vendor", True);
	ParametersStructure = New Structure("Filter,Vendor", FilterStructure1, True);	
	
	NumberOfChosen = NumberOfSelectedRowsProducts();
	
	ClearMessages();
	
	If NumberOfChosen = 0 And Goods.Count()>0 Then 
		CommonClientServer.MessageToUser(NStr("vi = 'Để điền nhà cung cấp, hãy chọn ít nhất một dòng!';
												|ru = 'Для заполнения поставщиков выберите хотя бы одну строку!';
												|en = 'To populate vendors, select at least one item.'; fa = 'To populate vendors, select at least one item.';
												|it = 'Per compilare i fornitori selezionare almeno una riga!';
												|pl = 'Aby wypełnić dostawców wybierz co najmniej jeden wiersz!';
												|tr = 'Tedarikçileri doldurmak için en az bir satır seçin!'"),
				,
				CommonClientServer.PathToTabularSection("Goods", 1, "Selected"),
				,);
	ElsIf Goods.Count()=0 And NumberOfChosen=0 Then
		CommonClientServer.MessageToUser(NStr("vi = 'Không có dòng để điền nhà cung cấp!';
												|ru = 'Отсутствуют строки для заполнения поставщиков!';
												|en = 'To populate vendors, add at least one item.'; fa = 'To populate vendors, add at least one item.';
												|it = 'Non ci sono righe per compilare i fornitori!';
												|pl = 'Brak wiersza do wypełnienia dostawców!';
												|tr = 'Tedarikçiler için doldurulacak satır yok!'"));
	Else
		SelectedSupplier = Undefined;

		OpenForm("Catalog.Partners.ChoiceForm", ParametersStructure, ThisForm,,,, New CallbackDescription("FillInTheSupplierCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
        Return;
	EndIf;
	
	FillInThisSnippet(SelectedSupplier);
EndProcedure

&AtClient
Procedure FillInTheSupplierCompletion(Result, AdditionalParameters) Export
    
    SelectedSupplier = Result;
    
    FillInThisSnippet(SelectedSupplier);

EndProcedure

&AtClient
Procedure FillInThisSnippet(Val SelectedSupplier)
    
    Var RowGoods;
    
    If ValueIsFilled(SelectedSupplier) Then
        For Each RowGoods In Goods Do
            If RowGoods.Selected Then
                RowGoods.Vendor = SelectedSupplier;
            EndIf; 
        EndDo;
    EndIf;
    CalculateNumberOfOrders();

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVendor.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsProductsUnitOfMeasure.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsWarehouse.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVendor.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("ReadOnly", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVendor.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Vendor");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chỉ ra nhà cung cấp>';
													|ru = '<укажите поставщика>';
													|en = '<Specify Vendor>'; fa = '<Specify Vendor>';
													|it = '<specificare fornitore>';
													|pl = '<wskaż dostawcę>';
													|tr = '<tedarikçiyi belirtin>.'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVendor.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Vendor");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.NumberOfPackages");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Goods.Selected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

EndProcedure

&AtServer
Procedure FillInTheProducts()
	
	CreationParameters = Documents.PurchaseOrder.CreationParametersBasedOnProvidingOrder();
	ManagerOfDocument = Common.ObjectManagerByRef(DocumentBasis);
	TempTablesManager = New TempTablesManager;
	ManagerOfDocument.GoodsOfDocumentForCreatingSecuringOrder(
		DocumentBasis,
		CreationParameters,
		TempTablesManager);
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("OnlyOrderLinesToSupply", OnlyOrderLinesToSupply);
	Query.Text =
	"SELECT
	|	Tab.LineNumber AS LineNumber,
	|	Tab.Products AS Products,
	|	Tab.Characteristic AS Characteristic,
	|	Tab.Warehouse AS Warehouse,
	|	Tab.Department AS Department,
	|	Tab.Purpose AS Purpose,
	|	Tab.Package AS Package,
	|	Tab.NumberOfUnitsPerDocument AS Count,
	|	Tab.CountByDocument AS NumberOfPackages
	|INTO GoodsTable
	|FROM
	|	DocumentGoods AS Tab
	|WHERE
	|	NOT &OnlyOrderLinesToSupply
	|		OR Tab.SupplyOption IN(
	|			VALUE(Enum.SupplyOptions.ToSupply),
	|			VALUE(Enum.SupplyOptions.ReserveAsReceived))
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inflow.Products AS Products,
	|	Inflow.Characteristic AS Characteristic,
	|	MAX(Inflow.Ref.Date) AS Date
	|INTO NewArrivals
	|FROM
	|	GoodsTable AS BaseGoods
	|		LEFT JOIN Document.VendorInvoice.Goods AS Inflow
	|		ON BaseGoods.Products = Inflow.Products
	|			AND BaseGoods.Characteristic = Inflow.Characteristic
	|WHERE
	|	BaseGoods.NumberOfPackages > 0
	|
	|GROUP BY
	|	Inflow.Products,
	|	Inflow.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inflow.Products AS Products,
	|	Inflow.Characteristic AS Characteristic,
	|	MAX(Inflow.Ref.Date) AS Date,
	|	MAX(Inflow.Ref) AS Ref
	|INTO SendingLink
	|FROM
	|	Document.VendorInvoice.Goods AS Inflow
	|WHERE
	|	(Inflow.Products, Inflow.Characteristic, Inflow.Ref.Date) IN
	|			(SELECT
	|				NewArrivals.Products AS Products,
	|				NewArrivals.Characteristic AS Characteristic,
	|				NewArrivals.Date AS Date
	|			FROM
	|				NewArrivals)
	|
	|GROUP BY
	|	Inflow.Products,
	|	Inflow.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inflow.Products AS Products,
	|	Inflow.Characteristic AS Characteristic,
	|	MAX(Inflow.Ref.Date) AS Date
	|INTO PreAdmission
	|FROM
	|	SendingLink AS SendingLink
	|		INNER JOIN Document.VendorInvoice.Goods AS Inflow
	|		ON SendingLink.Products = Inflow.Products
	|			AND SendingLink.Characteristic = Inflow.Characteristic
	|			AND SendingLink.Ref <> Inflow.Ref
	|
	|GROUP BY
	|	Inflow.Products,
	|	Inflow.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inflow.Products AS Products,
	|	Inflow.Characteristic AS Characteristic,
	|	MAX(Inflow.Ref.Date) AS Date,
	|	MAX(Inflow.Ref) AS Ref
	|INTO BeforeSendingLink
	|FROM
	|	Document.VendorInvoice.Goods AS Inflow
	|WHERE
	|	(Inflow.Products, Inflow.Characteristic, Inflow.Ref.Date) IN
	|			(SELECT
	|				PreAdmission.Products AS Products,
	|				PreAdmission.Characteristic AS Characteristic,
	|				PreAdmission.Date AS Date
	|			FROM
	|				PreAdmission)
	|
	|GROUP BY
	|	Inflow.Products,
	|	Inflow.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inflow.Products AS Products,
	|	Inflow.Characteristic AS Characteristic,
	|	MAX(Inflow.Ref.Date) AS Date
	|INTO FirstReceipts
	|FROM
	|	BeforeSendingLink AS BeforeSendingLink
	|		INNER JOIN Document.VendorInvoice.Goods AS Inflow
	|		ON BeforeSendingLink.Products = Inflow.Products
	|			AND BeforeSendingLink.Characteristic = Inflow.Characteristic
	|			AND BeforeSendingLink.Date > Inflow.Ref.Date
	|
	|GROUP BY
	|	Inflow.Products,
	|	Inflow.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inflow.Products AS Products,
	|	Inflow.Characteristic AS Characteristic,
	|	MAX(Inflow.Ref.Date) AS Date,
	|	MAX(Inflow.Ref) AS Ref
	|INTO FirstArrivalsRef
	|FROM
	|	Document.VendorInvoice.Goods AS Inflow
	|WHERE
	|	(Inflow.Products, Inflow.Characteristic, Inflow.Ref.Date) IN
	|			(SELECT
	|				FirstReceipts.Products AS Products,
	|				FirstReceipts.Characteristic AS Characteristic,
	|				FirstReceipts.Date AS Date
	|			FROM
	|				FirstReceipts)
	|
	|GROUP BY
	|	Inflow.Products,
	|	Inflow.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FirstArrivalsRef.Products AS Products,
	|	FirstArrivalsRef.Characteristic AS Characteristic,
	|	MAX(FirstArrivalsRef.Ref.Partner) AS Partner,
	|	MAX(SendingLink.Ref.Partner) AS Partner1,
	|	MAX(BeforeSendingLink.Ref.Partner) AS Partner2
	|INTO TTSuppliers
	|FROM
	|	FirstArrivalsRef AS FirstArrivalsRef
	|		FULL JOIN SendingLink AS SendingLink
	|			FULL JOIN BeforeSendingLink AS BeforeSendingLink
	|			ON SendingLink.Products = BeforeSendingLink.Products
	|				AND SendingLink.Characteristic = BeforeSendingLink.Characteristic
	|		ON (SendingLink.Characteristic = BeforeSendingLink.Characteristic)
	|			AND FirstArrivalsRef.Products = SendingLink.Products
	|
	|GROUP BY
	|	FirstArrivalsRef.Products,
	|	FirstArrivalsRef.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
	|		VALUE(Catalog.VATRates.EmptyRef))) AS VATRate,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Department AS Department,
	|	CASE WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService) THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|		END AS ToExpenseAs,
	|	Goods.Purpose AS Purpose,
	|	Goods.Package AS Package,
	|	Goods.Count AS Count,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	CASE
	|		WHEN Vendors.Partner = Vendors.Partner1
	|				OR Vendors.Partner = Vendors.Partner2
	|			THEN Vendors.Partner
	|		ELSE CASE
	|				WHEN Vendors.Partner1 = Vendors.Partner2
	|					THEN Vendors.Partner1
	|			END
	|	END AS Vendor
	|FROM
	|	GoodsTable AS Goods
	|		LEFT JOIN TTSuppliers AS Vendors
	|		ON Goods.Products = Vendors.Products
	|			AND Goods.Characteristic = Vendors.Characteristic
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Period,
	|			Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
	|		ON Goods.Products = ProductsVATRates.Products
	|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Period, Country = &RegistrationCountry) AS BasicVATRates
	|		ON (TRUE)
	|
	|ORDER BY
	|	Goods.LineNumber";
	
	AttributesValues = Common.ObjectAttributesValues(DocumentBasis, "Date,Organization");
	Query.SetParameter("Period", AttributesValues.Date);
	Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(AttributesValues.Organization));
	
	SetPrivilegedMode(True);
	Goods.Load(Query.Execute().Unload());
	
	If Goods.Count() = 0 Then
		
		ErrorText = NStr("vi = 'Không có hàng hóa khả dụng để điền.';
						|ru = 'Нет товаров, доступных для заполнения.';
						|en = 'No available items to populate.'; fa = 'No available items to populate.';
						|it = 'Non ci sono merci da compilare disponibili.';
						|pl = 'Brak towarów, dostępnych do wypełnienia.';
						|tr = 'Doldurulacak mal bulunmamaktadır.'");
		Common.MessageToUser(ErrorText);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure CalculateNumberOfOrders()
	If GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments") Then
		SelectedItemsCount = Goods.Unload(New Structure("Selected", True), "Vendor");
		SelectedItemsCount.GroupBy("Vendor");
	Else
		SelectedItemsCount = Goods.Unload(New Structure("Selected", True), "Vendor,Warehouse");
		SelectedItemsCount.GroupBy("Vendor,Warehouse");
	EndIf;
	
	Count = SelectedItemsCount.Count();
	
	For Each CurRow In SelectedItemsCount Do
		If Not ValueIsFilled(CurRow.Vendor) And Count>0 Then
			Count = Count-1;
		EndIf;
	EndDo;
	OrdersCount = Count;
EndProcedure

&AtServer
Procedure BeforeCreatingOrdersServer()
	
	ThereAreCapProps = Common.HasObjectAttribute("Warehouse", DocumentBasis.Metadata());
	
	If ThereAreCapProps Then
	
		DetailsOfFillingInForm = Common.ObjectAttributesValues(DocumentBasis,
																			"Organization, Warehouse");
		IsFolder = Common.ObjectAttributeValue(DetailsOfFillingInForm.Warehouse,
																		"IsFolder");
		UseOfWarehouses = UseWarehousesInTheTablePart();
		
		If UseOfWarehouses.PurchasesWarehousesAreUsed And UseOfWarehouses.SalesWarehousesAreUsed Then

			Vendors = Goods.Unload(New Structure("Selected", True), "Vendor");
			Vendors.GroupBy("Vendor");

		ElsIf Not UseOfWarehouses.PurchasesWarehousesAreUsed And UseOfWarehouses.SalesWarehousesAreUsed Then

			If IsFolder Then

				Vendors = Goods.Unload(New Structure("Selected", True), "Vendor,Warehouse");
				Vendors.GroupBy("Vendor,Warehouse");

			Else

				Vendors = Goods.Unload(New Structure("Selected", True), "Vendor");
				Vendors.GroupBy("Vendor");

			EndIf;
		ElsIf UseOfWarehouses.PurchasesWarehousesAreUsed And Not UseOfWarehouses.SalesWarehousesAreUsed Then

			Vendors = Goods.Unload(New Structure("Selected", True), "Vendor");
			Vendors.GroupBy("Vendor");

		ElsIf Not UseOfWarehouses.PurchasesWarehousesAreUsed And Not UseOfWarehouses.SalesWarehousesAreUsed Then

			Vendors = Goods.Unload(New Structure("Selected", True), "Vendor");
			Vendors.GroupBy("Vendor");

		EndIf;
	
	Else
		
		Vendors = Goods.Unload(New Structure("Selected", True), "Vendor,Warehouse");
		Vendors.GroupBy("Vendor, Warehouse");
		
	EndIf;
	
	ErrorsCount =0;
	
	For CurIndex__ = 0 To Goods.Count()-1 Do
		
		If Goods[CurIndex__].Vendor = Catalogs.Partners.EmptyRef() And Goods[CurIndex__].Selected = True Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền cột ""Nhà cung cấp"" tại dòng %1 trong danh sách ""Hàng hóa""';
					|ru = 'Не заполнена колонка ""Поставщик"" в строке %1 списка ""Товары""';
					|en = 'The ""Vendor"" column in line %1 of the ""Goods"" list is not filled in'; fa = 'The ""Vendor"" column in line %1 of the ""Goods"" list is not filled in';
					|it = 'La colonna ""Fornitore"" nella riga %1 dell''elenco ""Merci"" non è compilata';
					|pl = 'Nie wypełniono kolumny ""Dostawca"" w wierszu %1 listy ""Wiersze pozycji""';
					|tr = '""Ürünler"" listesi %1satırındaki ""Tedarikçi"" sütunu eksik'"),
				CurIndex__+1);
			
			Common.MessageToUser(
				ErrorText,
				,
				CommonClientServer.PathToTabularSection("Goods", CurIndex__+1, "Vendor"));

			ErrorsCount = ErrorsCount + 1;

		EndIf;
	EndDo;
	
	If ErrorsCount =0 Then

		CreateOrdersServer(Vendors);

	EndIf;
	
EndProcedure

&AtServer
Procedure CreateOrdersServer(Vendors)
	
	Items.Pages.CurrentPage = Items.OrdersPage;
	
	UseOfWarehouses = UseWarehousesInTheTablePart();
	
	FoundationDocumentData = StructureOfFoundationDocumentOnServer(UseOfWarehouses);

	DateOfOrders = CurrentSessionDate();
	For Each CurRow In Vendors Do

		OrderDocument = Documents.PurchaseOrder.CreateDocument();
		OrderDocument.Date = DateOfOrders;
		
		Filter = New Structure;
		Filter.Insert("Vendor", CurRow.Vendor);
		Filter.Insert("Selected",    True);
		If Vendors.Columns.Count()=2 Then
			Filter.Insert("Warehouse", CurRow.Warehouse);
		EndIf;
		
		ProductLines_3 = Goods.FindRows(Filter);
		FoundationDocumentData.Insert("Goods", OrderDocument.Goods.Unload());
		
		For Each RowGoods In ProductLines_3 Do

			FillPropertyValues(FoundationDocumentData.Goods.Add(), RowGoods);

		EndDo;
		
		OrderDocument.Partner = CurRow.Vendor;
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(CurRow.Vendor, OrderDocument.Counterparty);

		OrderDocument.Fill(FoundationDocumentData);
		If Vendors.Columns.Count() = 2 Then
			OrderDocument.Warehouse = CurRow.Warehouse;
		EndIf;
		
		PartnersProductsServer.FillInPartnerProductsByProductsInTable(OrderDocument.Goods,CurRow.Vendor);
		OrderDocument.Write(DocumentWriteMode.Write);

		OrdersRow = Orders.Add();
		OrdersRow.Ref   = OrderDocument.Ref;
		OrdersRow.Picture = 2;
	
	EndDo;
	
EndProcedure

&AtServer
Function StructureOfFoundationDocumentOnServer(UseOfWarehouses)
	
	ThereAreCapProps = Common.HasObjectAttribute("Warehouse", DocumentBasis.Metadata());

	FieldsStructure = New Structure;
	FieldsStructure.Insert("Organization", "Organization");
	FieldsStructure.Insert("Department", "Department");
	FieldsStructure.Insert("DocumentBasis", "Ref");
	FieldsStructure.Insert("LineOfBusiness");
	
	If ThereAreCapProps Then
		FieldsStructure.Insert("Warehouse", "Warehouse");
		FieldsStructure.Insert("SalesOpportunity", "SalesOpportunity");
		FieldsStructure.Insert("WarehouseIsGroup", "Warehouse.IsFolder");
		FieldsStructure.Insert("Priority", "Priority");
	EndIf;
	
	DetailsOfFillingInForm = Common.ObjectAttributesValues(DocumentBasis, FieldsStructure);
	
	If ThereAreCapProps Then
		
		WarehouseIsGroup = DetailsOfFillingInForm.WarehouseIsGroup;
		
		If Not UseOfWarehouses.PurchasesWarehousesAreUsed Then
			
			If WarehouseIsGroup Then
				
				FieldsString = "Organization, DocumentBasis, Department, SalesOpportunity, Priority, LineOfBusiness";
				
			Else
				
				FieldsString = "Organization, DocumentBasis, Department, Warehouse, SalesOpportunity, Priority, LineOfBusiness";
				
			EndIf;
			
		Else
			
			FieldsString = "Organization, DocumentBasis, Department, Warehouse, SalesOpportunity, Priority, LineOfBusiness";
			
		EndIf;
		
	Else
		
		FieldsString = "Organization, DocumentBasis, Department, LineOfBusiness";
		
	EndIf;	
		
	DetailsOfFoundation = New Structure(FieldsString);
	FillPropertyValues(DetailsOfFoundation, DetailsOfFillingInForm, FieldsString);

	Return DetailsOfFoundation;

EndFunction 

&AtServer
Procedure UpdateOrderStates(LinkToOrder)
	
	FoundRow = Orders.FindRows (New Structure("Ref",LinkToOrder));
	
	If FoundRow.Count() = 0 Then
		Return
	EndIf;
	
	OrderDetails = Common.ObjectAttributesValues(LinkToOrder,"DeletionMark,Posted");
	
	If OrderDetails.DeletionMark Then
		FoundRow[0].Picture = 1;
	ElsIf OrderDetails.Posted Then
		FoundRow[0].Picture = 0;
	Else
		FoundRow[0].Picture = 2;
	EndIf;
	
EndProcedure

&AtServer
Function UseWarehousesInTheTablePart()
	
	UseOfWarehouses = New Structure("PurchasesWarehousesAreUsed, SalesWarehousesAreUsed",
							GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments"),
							GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments"));
	
	Return UseOfWarehouses;
	
EndFunction

&AtServer
Function NumberOfSelectedRowsProducts()

	Return Goods.Unload(New Structure("Selected", True)).Count();

EndFunction 

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
