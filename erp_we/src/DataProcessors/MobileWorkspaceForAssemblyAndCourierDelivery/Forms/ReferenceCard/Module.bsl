#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("ReferenceOrder", ReferenceOrder);
	ShowProductPhotos = Parameters.ShowProductPhotos;
	
	SetConditionalAppearance();
	Employee = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	EmployeeType = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.EmployeeTypeCourier();
	UpdateFormData();
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CreateMenu_();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CancelTheOrder(Command)

	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ReferenceOrder", ReferenceOrder);
	
	CallbackDescriptionOnClose = New CallbackDescription("CancelTheOrderCompletion", ThisForm);
		
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.SelectCancellationReason",
		FormOpenParameters,
		ThisForm,,,,
		CallbackDescriptionOnClose,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure
	
&AtClient
Procedure ExecuteAProcessCommand(Command)
	
	If CurrentAction1 = "CompleteDelivery" Then
		CompleteDelivery(ReferenceOrder);
		Notify("UpdateListOfOrders");
	ElsIf CurrentAction1 = "AcceptPayment" Then
		AcceptPayment();
	ElsIf CurrentAction1 = "IssueReceipt" Then
		IssueReceipt(ReferenceOrder);
	EndIf;
	
EndProcedure

&AtClient
Procedure TheDecorationsShowTheShippingAddressClick(Item)
	
	ShowMap(DeliveryAddressPresentation);
	
EndProcedure

&AtClient
Procedure DecorationToShowTheAddressOfTheStoreClick(Item)
	
	StoreAddress = AddressOwnerPresentation(Warehouse);
	ShowMap(StoreAddress);
	
EndProcedure

&AtClient
Procedure DecorationCallTheBuyerClick(Item)
	
	Telephone("Customer");
	
EndProcedure

&AtClient
Procedure DecorationCallTheCollectorClick(Item)
	
	Telephone("Picker", Picker);
	
EndProcedure

&AtClient
Procedure DecorationCallTheCourierClick(Item)
	
	Telephone("Courier", Courier);
	
EndProcedure

&AtClient
Procedure DecorationCallTheDispatcherClick(Item)
	
	Telephone("Warehouse", Warehouse);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToInfo(Command)
	
	If CurrentTab = 1 Then
		GoToTab(0);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToProducts(Command)
	
	If Not ProductsLoaded Then
		FillInTheProducts();
		CreateGroupTables();
		SoftwareInterfaceFormation();
	EndIf;
	
	ProductsLoaded = True;
	
	If CurrentTab = 0 Then
		GoToTab(1);
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeTheHierarchy(Command)
	
	ToUseGrouping = Not ToUseGrouping;
	
	SoftwareInterfaceFormation();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetVisibility1()
	
	DeliveryCommandsAreAvailable = DeliveryCommandsAreAvailable();
	Items.FooterGroup.Visible = DeliveryCommandsAreAvailable;
	Items.GroupCommandToCancel.Visible = DeliveryCommandsAreAvailable;
	Items.GroupInformationCollector.Visible = ValueIsFilled(Picker);
	Items.GroupInformationFrame8.Visible = ValueIsFilled(Picker);
	Items.GroupInformationTheCourier.Visible = ValueIsFilled(Courier);
	Items.GroupInformationPayment.Visible = (AmountToPay>0);
	Items.GroupInformationFrame2.Visible = (AmountToPay>0);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
EndProcedure

&AtServer
Function DeliveryCommandsAreAvailable()
	
	Return Common.ObjectAttributeValue(Users.CurrentUser(), "Individual") = Courier
			And WarehousesServer.StatusesOfOrdersDeliveredByCourier().Find(Status) <> Undefined;

EndFunction

&AtServer
Procedure UpdateFormData()
	
	Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
	
	Query = New Query();
	QueryText = "SELECT
	|	AssemblyAndDeliveryStatuses.ReferenceOrder AS ReferenceOrder,
	|	AssemblyAndDeliveryStatuses.Status AS Status,
	|	Documents.Warehouse AS Warehouse,
	|	Documents.Courier AS Courier,
	|	Documents.Number AS Number,
	|	Documents.DateOfShipment AS DeliveryDate,
	|	Documents.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	Documents.DeliveryTimeTo AS DeliveryTimeTo,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	Documents.DeliveryAddress AS DeliveryAddressPresentation,
	|	Documents.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	Documents.AdditionalDeliveryInformation AS Comment,
	|	Documents.Currency AS Currency,
	|	Documents.PaymentMethod AS PaymentMethod,
	|	CASE
	|		WHEN Documents.ContactPerson = VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
	|			THEN Partners.Description
	|		ELSE ContactPersons.Description
	|	END AS ContactPersonPresentation,
	|	Documents.Picker AS Picker,
	|	Documents.Courier.Description AS CourierName,
	|	Documents.Picker.Description AS MailCollectorName,
	|	Documents.Warehouse.Description AS WarehouseName,
	|	Documents.Organization AS Organization
	|INTO TemporaryDisposalTable
	|FROM
	|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	|		INNER JOIN Document.SalesOrder AS Documents
	|		ON CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.SalesOrder) = Documents.Ref
	|		LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersons
	|		ON Documents.ContactPerson = ContactPersons.Ref
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON Documents.Partner = Partners.Ref
	|WHERE
	|	Documents.Ref = &Ref
	|	AND Documents.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	AssemblyAndDeliveryStatuses.ReferenceOrder,
	|	AssemblyAndDeliveryStatuses.Status,
	|	Documents.Warehouse,
	|	Documents.Courier,
	|	Documents.Number,
	|	Documents.Date,
	|	Documents.DeliveryTimeFrom,
	|	Documents.DeliveryTimeTo,
	|	Documents.DocumentAmount,
	|	Documents.DeliveryAddress,
	|	Documents.DeliveryAddressFieldValues,
	|	Documents.AdditionalDeliveryInformation,
	|	Documents.Currency,
	|	Documents.PaymentMethod,
	|	CASE
	|		WHEN Documents.ContactPerson = VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
	|			THEN Partners.Description
	|		ELSE ContactPersons.Description
	|	END,
	|	Documents.Picker,
	|	Documents.Courier.Description,
	|	Documents.Picker.Description,
	|	Documents.Warehouse.Description,
	|	Documents.Organization
	|FROM
	|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	|		INNER JOIN Document.CustomerInvoice AS Documents
	|		ON CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.CustomerInvoice) = Documents.Ref
	|		LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersons
	|		ON Documents.ContactPerson = ContactPersons.Ref
	|		LEFT JOIN Catalog.Partners AS Partners
	|		ON Documents.Partner = Partners.Ref
	|WHERE
	|	Documents.Ref = &Ref
	|	AND Documents.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CashAccounts.Owner AS Organization,
	|	CashAccounts.Ref AS CashAccount
	|INTO CheckoutTemporaryTable
	|FROM
	|	TemporaryDisposalTable AS DisposalTable
	|		INNER JOIN Catalog.CashAccounts AS CashAccounts
	|		ON DisposalTable.Organization = CashAccounts.Owner
	|WHERE
	|	CashAccounts.DeletionMark = FALSE
	|	AND CashAccounts.OperationalCashAccount = TRUE
	|	AND CashAccounts.Individual = &Employee
	|GROUP BY
	|	CashAccounts.Owner,
	|	DisposalTable.Status,
	|	CashAccounts.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DisposalTable.ReferenceOrder AS ReferenceOrder,
	|	DisposalTable.Status AS Status,
	|	SUM(ISNULL(CustomersARAPAccounting.AmountDueBalance, 0)) AS AmountToPay
	|INTO TemporaryTableForPaymentIntermediate
	|FROM
	|	TemporaryDisposalTable AS DisposalTable
	|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(, ARAPObject.Object = &Ref) AS
	|			CustomersARAPAccounting
	|		ON DisposalTable.ReferenceOrder = CustomersARAPAccounting.ARAPObject.Object
	|GROUP BY
	|	DisposalTable.ReferenceOrder,
	|	DisposalTable.Status
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableForPayment.ReferenceOrder AS ReferenceOrder,
	|	TemporaryTableForPayment.AmountToPay AS AmountToPay,
	|	SUM(CASE
	|		WHEN CashAccountBalance.CashAccount = CashAccountsTable.CashAccount
	|		AND NOT TemporaryTableForPayment.Status IN (&Delivered_5)
	|			THEN CASE
	|				WHEN CashAccountBalance.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN CashAccountBalance.Sum
	|				ELSE -CashAccountBalance.Sum
	|			END
	|		ELSE 0
	|	END) AS AmountToBePaidCourier
	|INTO TemporaryTableForPayment
	|FROM
	|	TemporaryTableForPaymentIntermediate AS TemporaryTableForPayment
	|		LEFT JOIN AccumulationRegister.CashAccountBalance AS CashAccountBalance
	|		ON TemporaryTableForPayment.ReferenceOrder = CashAccountBalance.ARAPObject.Object
	|		LEFT JOIN CheckoutTemporaryTable AS CashAccountsTable
	|		ON CashAccountBalance.Organization = CashAccountsTable.Organization
	|GROUP BY
	|	TemporaryTableForPayment.ReferenceOrder,
	|	TemporaryTableForPayment.AmountToPay
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Documents.ReferenceOrder AS ReferenceOrder,
	|	Documents.Status AS Status,
	|	Documents.Warehouse AS Warehouse,
	|	Documents.Courier AS Courier,
	|	Documents.Number AS Number,
	|	Documents.DeliveryDate AS DeliveryDate,
	|	Documents.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	Documents.DeliveryTimeTo AS DeliveryTimeTo,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	Documents.DeliveryAddressPresentation AS DeliveryAddressPresentation,
	|	Documents.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	Documents.Comment AS Comment,
	|	Documents.Currency AS Currency,
	|	Documents.PaymentMethod AS PaymentMethod,
	|	Documents.ContactPersonPresentation AS ContactPersonPresentation,
	|	Documents.Picker AS Picker,
	|	Documents.CourierName AS CourierName,
	|	Documents.MailCollectorName AS MailCollectorName,
	|	Documents.WarehouseName AS WarehouseName,
	|	Documents.Organization AS Organization,
	|	TableForPayment.AmountToPay + TableForPayment.AmountToBePaidCourier AS AmountToPay
	|FROM
	|	TemporaryDisposalTable AS Documents
	|		LEFT JOIN TemporaryTableForPayment AS TableForPayment
	|		ON Documents.ReferenceOrder = TableForPayment.ReferenceOrder
	|ORDER BY
	|	DeliveryDate,
	|	DeliveryTimeTo
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TemporaryDisposalTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP CheckoutTemporaryTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TemporaryTableForPaymentIntermediate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TemporaryTableForPayment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series,
	|	Goods.NumberOfPackages AS Count,
	|	Goods.Package AS Package,
	|	&QueryTextUnitOfMeasureDescription AS UnitOfMeasure,
	|	Goods.NumberOfPackages * &QueryTextPackageWeight AS Weight,
	|	&QueryTextPackageWeight AS PackageWeight,
	|	Goods.Sum / Goods.NumberOfPackages AS Price,
	|	Goods.AmountIncludingVAT AS AmountIncludingVAT,
	|	Goods.Products.PicturesFile AS PicturesFile,
	|	CASE
	|		WHEN
	|			CatalogProducts.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsAWeightProduct,
	|	CatalogProducts.Description AS ProductsPresentation
	|FROM
	|	Document.SalesOrder.Goods AS Goods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON Goods.Products = CatalogProducts.Ref
	|		INNER JOIN Catalog.ItemKinds AS CatalogItemKinds
	|		ON CatalogProducts.ProductKind = CatalogItemKinds.Ref
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON Goods.Package = PackagesAndUnitsOfMeasure.Ref
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.Ref.Posted
	|	AND NOT Goods.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	Goods.NumberOfPackages,
	|	Goods.Package,
	|	&QueryTextUnitOfMeasureDescription,
	|	Goods.NumberOfPackages * &QueryTextPackageWeight,
	|	&QueryTextPackageWeight,
	|	Goods.Sum / Goods.NumberOfPackages,
	|	Goods.AmountIncludingVAT,
	|	Goods.Products.PicturesFile AS PicturesFile,
	|	CASE
	|		WHEN
	|			CatalogProducts.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CatalogProducts.Description
	|FROM
	|	Document.CustomerInvoice.Goods AS Goods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON Goods.Products = CatalogProducts.Ref
	|		INNER JOIN Catalog.ItemKinds AS CatalogItemKinds
	|		ON CatalogProducts.ProductKind = CatalogItemKinds.Ref
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON Goods.Package = PackagesAndUnitsOfMeasure.Ref
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.Ref.Posted";
	
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Ref", ReferenceOrder);
	Query.SetParameter("Delivered_5", WarehousesServer.StatusOfOrdersCompleted());
	
	QueryText = StrReplace(QueryText, 
		"&QueryTextPackageWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"PackagesAndUnitsOfMeasure", 
			"CatalogProducts"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description",
			"Goods.Package",
			"Goods.Products"));
	
	Query.Text = QueryText;
	
	Results = Query.ExecuteBatch();
	
	Goods.Clear();
	
	If Results[4].IsEmpty() Then
		Return;
	EndIf;
	
	DataFromOrder = Results[4].Unload()[0];
	
	FillPropertyValues(ThisForm, DataFromOrder);
	
	DateTimeOfDeliveryPresentation = Module.DateTimeOfDeliveryPresentation(ThisForm);
	ThereIsStillTimeForDelivery = Module.ThereIsStillTimeForDelivery(ThisForm);
	DocumentAmountPresentation = Module.SumPresentation(ThisForm);
	
	If AmountToPay > 0 Then
		AmountToPayPresentation = Module.AmountToPayPresentation(ThisForm);
		PaymentMethodPresentation = Module.PaymentMethodPresentation(ThisForm);
	Else
		AmountToPayPresentation = "Paid";
		PaymentMethodPresentation = "";
	EndIf;
	
	Products_From_Orders = Results[9].Unload();
	Items.TeamProducts.Title = StrTemplate(NStr("vi = 'Hàng hóa (%1)';
												|ru = 'Товары (%1)';
												|en = 'Goods (%1)'; fa = 'Goods (%1)';
												|it = 'Prodotti (%1)';
												|pl = 'Towary (%1)';
												|tr = 'Ürünler (%1)'"), Products_From_Orders.Count());
		
	NumberOfRows = Products_From_Orders.Count();
	Weight = Products_From_Orders.Total("Weight");
	WeightPresentation = Module.WeightPresentation(Weight);
	
	Items.DecorationRoom.Title = New FormattedString(DataFromOrder.Number,
		StyleFonts.TextFontSelectedAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	Items.DecorationStatus.Title = New FormattedString(String(DataFromOrder.Status),
		StyleFonts.TextFontAssemblyAndDelivery,
		?(Module.ThisIsCompletedStatus(Status),
			StyleColors.CompleteStatusTextColorAssemblyAndDelivery,
			StyleColors.InProgressStatusTextColorAssemblyAndDelivery));
		
	Items.DecorationDateTimeOfDeliveryPresentation.Title = New FormattedString(DateTimeOfDeliveryPresentation,
		StyleFonts.TextFontSelectedAssemblyAndDelivery, 
		StyleColors.TextColorMainKittingAndDelivery);
	
	Items.DecorationTimeLeftForDelivery.Title = New FormattedString(ThereIsStillTimeForDelivery,
		StyleFonts.ReducedTextFontAssemblyAndDelivery,
		?(LateArrival, StyleColors.NegativeValuesTextColor, StyleColors.TextColorMainKittingAndDelivery));
	
	Items.DecorationDeliveryAddress.Title = New FormattedString(DeliveryAddressPresentation,
		StyleFonts.TextFontAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	Items.DecorationContactPerson.Title = New FormattedString(ContactPersonPresentation,
		StyleFonts.TextFontAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	Items.DecorationAmountToBePaidPresentation.Title = New FormattedString(AmountToPayPresentation,
		StyleFonts.TextFontSelectedAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	Items.DecorationIsAFormOfPayment.Title = New FormattedString(PaymentMethodPresentation,
		StyleFonts.TextFontAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	Items.DecorationComment.Title = New FormattedString(Comment, 
		StyleFonts.TextFontAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	Items.DecorationNumberOfPositions.Title = New FormattedString(Format(NumberOfRows, "NG=0"),
		StyleFonts.TextFontAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	Items.DecorationWeight.Title = New FormattedString(WeightPresentation,
		StyleFonts.TextFontAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
	
	Items.DecorationAmountOfTheDocument.Title = New FormattedString(DocumentAmountPresentation,
		StyleFonts.TextFontAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	Items.DecorationStorePresentation.Title = New FormattedString(DataFromOrder.WarehouseName,
		StyleFonts.TextFontAssemblyAndDelivery,
		StyleColors.TextColorMainKittingAndDelivery);
		
	If ValueIsFilled(Picker) Then
		Items.SceneryCollector.Title = New FormattedString(DataFromOrder.MailCollectorName,
			StyleFonts.TextFontAssemblyAndDelivery,
			StyleColors.TextColorMainKittingAndDelivery);
	EndIf;
		
	If ValueIsFilled(Courier) Then
		Items.DecorationCourier.Title = New FormattedString(DataFromOrder.CourierName,
			StyleFonts.TextFontAssemblyAndDelivery,
			StyleColors.TextColorMainKittingAndDelivery);
	EndIf;
		
	OverrideCurProcessCommand();
	
EndProcedure

&AtClient
Procedure ShowMap(AddressPresentation)
	
	If Not ValueIsFilled(AddressPresentation) Then
		ErrorText = NStr("vi = 'Chưa chỉ ra địa chỉ.';
						|ru = 'Не указан адрес.';
						|en = 'Address is not specified.'; fa = 'Address is not specified.';
						|it = 'Indirizzo non indicato.';
						|pl = 'Nie podano adresu.';
						|tr = 'Adres belirtilmedi.'");
		CommonClient.MessageToUser(ErrorText);
		Return;
	EndIf;
 
#If MobileClient Then
	ListOfLocations = New ValueList;
	ListOfLocations.Add(GetAddressCoordinates(AddressPresentation)); 
	ShowOnMap(ListOfLocations);
 #EndIf
	 
 EndProcedure

&AtClient
Function GetAddressCoordinates(AddressPresentation)
	
	Coordinates = New Structure();
	
#If MobileClient Then
		
	Coordinates = Undefined;
	AddressDataStructure = New Structure();
	AddressDataStructure.Insert("Presentation", AddressPresentation);
	
	AddressData = New AddressData(AddressDataStructure);
	Coordinates = GetLocationByAddress(AddressData);
	
 #EndIf
	 
	Return Coordinates;
	
EndFunction

&AtServer
Function PhoneNumberOfContactPersonFromDocument(ReferenceOrder)
	
	Return DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.PhoneNumberOfContactPersonFromDocument(ReferenceOrder);
	
EndFunction

&AtServer
Function PhoneNumberOfContactPerson(ContactPerson)
	
	Return DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.PhoneNumberOfContactPerson(ContactPerson);

EndFunction

&AtClient
Procedure Telephone(SubscriberType_, Subscriber = Undefined)
	
#If MobileClient Then
		
	If Not TelephonyTools.NumberDialingSupported() Then
		Return;
	EndIf;
	
	If SubscriberType_ = "Customer" Then
		PhoneNumber = PhoneNumberOfContactPersonFromDocument(ReferenceOrder);
	Else
		PhoneNumber = PhoneNumberOfContactPerson(Subscriber);
	EndIf;
	
	If PhoneNumber <> "" Then
		TelephonyTools.DialNumber(PhoneNumber, False);
	Else
		ErrorText = NStr("vi = 'Chưa chỉ ra số điện thoại.';
						|ru = 'Не указан номер телефона.';
						|en = 'The phone number is not specified.'; fa = 'The phone number is not specified.';
						|it = 'Numero di telefono non indicato.';
						|pl = 'Nie podano numeru telefonu.';
						|tr = 'Telefon numarası belirtilmedi.'");
		CommonClient.MessageToUser(ErrorText);
		Error = True;
	EndIf;
	
#EndIf
	
EndProcedure

&AtServer
Function AddressOwnerPresentation(Owner)
	
	Return DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.AddressOwnerPresentation(Owner);
	
EndFunction

&AtClient
Procedure GoToTab(TabCode = 0)
	
	CurrentTab = TabCode;
	CreateMenu_();
	
EndProcedure

&AtClient
Procedure CreateMenu_()
	
	If CurrentTab = 0 Then
		
		NameOfFrameElement    = "FrameInformation";
		NameOfCommandElement  = "TeamInformation_3";
		PageElementName = "InformationPage";

	Else
			
		NameOfFrameElement    = "FrameProducts";
		NameOfCommandElement  = "TeamProducts";
		PageElementName = "GoodsPage";
		
	EndIf;
	
	Items.FrameInformation.Picture = PictureLib.BorderMenuWhite;
	Items.TeamInformation_3.TextColor = WebColors.DarkGray;
	
	Items.FrameProducts.Picture = PictureLib.BorderMenuWhite;
	Items.TeamProducts.TextColor = WebColors.DarkGray;
	
	Items[NameOfFrameElement].Picture = PictureLib.BorderMenuBlack;
	Items[NameOfCommandElement].TextColor = WebColors.Black;
	Items.GroupPages.CurrentPage = Items[PageElementName];
	
EndProcedure

&AtClient
Procedure CancelTheOrderCompletion(Result, Var_Parameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	UpdateOrderForm();
	Notify("UpdateListOfOrders");
	
EndProcedure

&AtServer
Procedure UpdateOrderForm()
	
	UpdateFormData();
	
	FillInTheProducts();
	CreateGroupTables();
	SoftwareInterfaceFormation();
	
	SetVisibility1();
	
EndProcedure

&AtServer
Procedure OverrideCurProcessCommand()
	
	DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.OverrideCurProcessCommand(ThisForm);
	
EndProcedure

&AtServer
Procedure CompleteDelivery(ReferenceOrder)
	
	Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
	Module.CompleteDelivery(ReferenceOrder);
	UpdateOrderForm();
	
EndProcedure

&AtClient
Procedure AcceptPayment()
	
	AvailablePaymentMethods_ = AvailablePaymentMethods_1(ReferenceOrder);
	
	If AvailablePaymentMethods_.Count() = 0 Then
		
		ErrorText = NStr("vi = 'Không có phương thức tiếp nhận thanh toán hợp lệ nào.';
						|ru = 'Не доступен ни один способ приема оплаты.';
						|en = 'No payment method is available.'; fa = 'No payment method is available.';
						|it = 'Non è disponibile nessun metodo di ricezione del pagamento.';
						|pl = 'Nie jest dostępna ani jedna metoda przyjmowania płatności.';
						|tr = 'Hiç bir ödeme yöntemi erişilebilir değil.'");
		CommonClient.MessageToUser(ErrorText);
		Return;
		
	ElsIf AvailablePaymentMethods_.Count() = 1 Then
		
		OpenPaymentMethodForm(AvailablePaymentMethods_[0].Value);
		
	Else
		
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("AvailablePaymentMethods_", AvailablePaymentMethods_);
		FormOpenParameters.Insert("PaymentMethod", PaymentMethod);
		FormOpenParameters.Insert("AmountToPay", AmountToPay);
		FormOpenParameters.Insert("Currency", Currency);
		FormOpenParameters.Insert("Warehouse", Warehouse);
		
		CallbackDescriptionOnClose = New CallbackDescription("SelectPaymentMethodCompletion", ThisForm);
			
		OpenForm(
			"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.SelectPaymentMethod",
			FormOpenParameters,
			ThisForm,,,,
			CallbackDescriptionOnClose,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectPaymentMethodCompletion(Result, Var_Parameters) Export
	
	If Result <> Undefined Then
		OpenPaymentMethodForm(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenPaymentMethodFormCompletion(Result, Var_Parameters) Export
	
	If Result <> Undefined
		And Result = True Then
		Notify("UpdateListOfOrders");
	EndIf;
	
	UpdateOrderForm();
	
EndProcedure

&AtClient
Procedure OpenPaymentMethodForm(PaymentMethod_)

	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ReferenceOrder", ReferenceOrder);
	FormOpenParameters.Insert("AmountToPay", AmountToPay);
	FormOpenParameters.Insert("Currency", Currency);
	FormOpenParameters.Insert("Warehouse", Warehouse);
	
	CallbackDescriptionOnClose = New CallbackDescription("OpenPaymentMethodFormCompletion", ThisForm);
		
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.Payment" + PaymentMethod_,
		FormOpenParameters,
		ThisForm,,,,
		CallbackDescriptionOnClose,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtServer
Function AvailablePaymentMethods_1(ReferenceOrder)
	
	Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
	Return Module.AvailablePaymentMethods_1(ThisForm);
	
EndFunction

&AtServer
Procedure IssueReceipt(ReferenceOrder)
	
	Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
	
	Cancel = False;
	Module.IssueReceipt(ReferenceOrder, Cancel);
	
	If Not Cancel Then
		Module.CompleteDelivery(ReferenceOrder);
	EndIf;
	
	UpdateOrderForm();
	
EndProcedure

&AtClient
Procedure UpdateForm(Command)

	UpdateOrderForm();

EndProcedure

&AtServer
Procedure FillInTheProducts()
	
	StorageAddress = PutToTempStorage(Undefined, UUID);
	
	DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.GoodsTable(ReferenceOrder, StorageAddress);
	Goods.Load(GetFromTempStorage(StorageAddress));
	
	Cnt = 1;
	For Each String In Goods Do
		String.ID = Cnt;
		Cnt = Cnt + 1;
	EndDo;
	
EndProcedure

&AtServer
Procedure CreateProductCardOnForm(SectionName, ProductID, Parent)
	
	FilterParameters = New Structure("ID", ProductID);
	RowsArray = ThisForm[SectionName].FindRows(FilterParameters);
	
	OrderLine = Undefined;
	If RowsArray.Count() > 0 Then
		OrderLine = RowsArray[0];
	Else
		Return;
	EndIf;
	
	// PRODUCT CARD
	GoodsProfile = Items.Add("GoodsProfile" + SectionName + ProductID, Type("FormGroup"), Parent);
	GoodsProfile.Type                 = FormGroupType.UsualGroup;
	GoodsProfile.Group         = ChildFormItemsGroup.Vertical; 
	GoodsProfile.ShowTitle = False;
	
	// PRODUCT CARD 2 Without margins
	ProductCardContainer = Items.Add("GoodsProfile2" + SectionName + ProductID, Type("FormGroup"), GoodsProfile);
	ProductCardContainer.Type                = FormGroupType.UsualGroup;
	ProductCardContainer.Group        = ChildFormItemsGroup.AlwaysHorizontal; 
	ProductCardContainer.ShowTitle = False;
	
	// PRODUCT CARD Left part
	ProductCardLeftSide = Items.Add("ProductCardLev" + SectionName + ProductID, Type("FormGroup"), ProductCardContainer);
	ProductCardLeftSide.Type                = FormGroupType.UsualGroup;
	ProductCardLeftSide.Group        = ChildFormItemsGroup.AlwaysHorizontal; 
	ProductCardLeftSide.ShowTitle = False;
	ProductCardLeftSide.Width = 4;
	
	// PRODUCT CARD Right side
	ProductCardRightSide = Items.Add("ProductCard" + SectionName + ProductID, Type("FormGroup"), ProductCardContainer);
	ProductCardRightSide.Type                = FormGroupType.UsualGroup;
	ProductCardRightSide.Group        = ChildFormItemsGroup.Vertical; 
	ProductCardRightSide.ShowTitle = False;
	
	// PRODUCT CARD Upper area
	ProductCardTop = Items.Add("ProductCardEdit" + SectionName + ProductID, Type("FormGroup"), ProductCardRightSide);
	ProductCardTop.Type                = FormGroupType.UsualGroup;
	ProductCardTop.Group        = ChildFormItemsGroup.AlwaysHorizontal; 
	ProductCardTop.ShowTitle = False;
	ProductCardTop.Representation = UsualGroupRepresentation.None;
	
	// PRODUCT CARD Lower area
	ProductCardBottom = Items.Add("ProductCardEdit_" + SectionName + ProductID, Type("FormGroup"), ProductCardRightSide);
	ProductCardBottom.Type                = FormGroupType.UsualGroup;
	ProductCardBottom.Group        = ChildFormItemsGroup.AlwaysHorizontal; 
	ProductCardBottom.ShowTitle = False;
	ProductCardBottom.Representation = UsualGroupRepresentation.None;
	ProductCardBottom.HorizontalStretch = True;
	
	// PRODUCT PHOTO
	If ShowProductPhotos Then
		AttributesToBeAdded = New Array;
		AttributeType = New TypeDescription("String");
		FormAttribute = New FormAttribute("Photo_" + SectionName + ProductID, AttributeType);
		
		AttributesToBeAdded.Add(FormAttribute);
		
		// Forcing the form to create new details
		ChangeAttributes(AttributesToBeAdded);
		
		// The output of the props on the form (if necessary)
		InputField = Items.Add("Photo_" + SectionName + ProductID, Type("FormField"), ProductCardLeftSide);
		InputField.Type = FormFieldType.PictureField;
		InputField.DataPath = "Photo_" + SectionName + ProductID;
		InputField.PictureSize = PictureSize.Proportionally;
		InputField.Width = 4;
		InputField.Height = 2;
		InputField.HorizontalStretch = False;
		InputField.TitleLocation = FormItemTitleLocation.None;
		InputField.Border = StyleBorders.BorderNoBorder;
		
		// Accessing the form details from the code
		If Not OrderLine.PicturesFile.IsEmpty() Then
			LinkToDDF = FilesOperations.FileData(OrderLine.PicturesFile, ThisObject.UUID).RefToBinaryFileData;
			ThisForm["Photo_" + SectionName + ProductID] = LinkToDDF;
		EndIf;
	EndIf;
	
	// Name of item
	Command = Commands.Add(
	"ProductItemName" + SectionName + "_" + ProductID); //Command name
	Command.Title = ProductsClientServer.ProductPresentation(OrderLine.Products, OrderLine.Characteristic,,OrderLine.Series);
	Command.Action = "ProductSelection"; //Name of the associated procedure
	FormButton = Items.Add("ProductButton" + SectionName + ProductID, Type("FormButton"), ProductCardTop);
	FormButton.CommandName = "ProductItemName" + SectionName + "_" + ProductID; 
	FormButton.Type        = FormButtonType.UsualButton; 
	FormButton.Font      = StyleFonts.TextFontSelectedAssemblyAndDelivery;
	FormButton.TextColor = WebColors.Black;
	FormButton.ShapeRepresentation = ButtonShapeRepresentation.None;
	FormButton.HorizontalAlignInGroup = ItemHorizontalLocation.Left;
	FormButton.TitleHeight = 2;
	FormButton.HorizontalStretch = True;
	
	// Amount of goods
	Command = Commands.Add(
	"ProductQuantity__" + SectionName + "_" + ProductID); //Command name
	Command.Title = String(OrderLine.Count) + " " + String(OrderLine.Package);
	Command.Action  = "ProductSelection"; //Name of the associated procedure
	
	FormButton = Items.Add("ProductQuantityButton" + SectionName + ProductID, Type("FormButton"), ProductCardTop);
	FormButton.CommandName = "ProductQuantity__" + SectionName + "_" + ProductID; 
	FormButton.Type        = FormButtonType.UsualButton; 
	FormButton.Font      = StyleFonts.TextFontSelectedAssemblyAndDelivery;
	FormButton.TextColor = WebColors.LimeGreen;
	FormButton.ShapeRepresentation = ButtonShapeRepresentation.None;
	FormButton.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	FormButton.VerticalAlignInGroup = ItemVerticalAlign.Top;
	
	// Product weight
	If OrderLine.ThisIsAWeightProduct Or OrderLine.Weight = 0 Then
		TitleWeight = "";
	Else 
		TitleWeight = String(OrderLine.Weight) + " " + String(OrderLine.WeightUnitOfMeasure);
	EndIf;
	
	Command = Commands.Add(
	"ProductWeight_" + SectionName + "_" + ProductID); //Command name
	Command.Title = TitleWeight;
	Command.Action  = "ProductSelection"; //Name of the associated procedure
	
	FormButton = Items.Add("ButtonItemWeight" + SectionName + ProductID, Type("FormButton"), ProductCardBottom);
	FormButton.CommandName = "ProductWeight_" + SectionName + "_" + ProductID; 
	FormButton.Type        = FormButtonType.UsualButton; 
	FormButton.Font      = StyleFonts.TextFontSelectedAssemblyAndDelivery;
	FormButton.TextColor = WebColors.Gray;
	FormButton.ShapeRepresentation = ButtonShapeRepresentation.None;
	FormButton.HorizontalAlignInGroup = ItemHorizontalLocation.Left;
	If TitleWeight = "" Then
		FormButton.Visible = False;
	EndIf;
	
	// Price of goods
	Command = Commands.Add(
	"ProductPrice" + SectionName + "_" + ProductID); //Command name
	Command.Title = String(OrderLine.Price) + " " + Currency;
	Command.Action  = "ProductSelection"; //Name of the associated procedure
	
	FormButton = Items.Add("ProductPriceButton" + SectionName + ProductID, Type("FormButton"), ProductCardBottom);
	FormButton.CommandName = "ProductPrice" + SectionName + "_" + ProductID; 
	FormButton.Type        = FormButtonType.UsualButton; 
	FormButton.Font      = StyleFonts.TextFontSelectedAssemblyAndDelivery;
	FormButton.TextColor = WebColors.Gray;
	FormButton.ShapeRepresentation = ButtonShapeRepresentation.None;
	FormButton.HorizontalAlignInGroup = ItemHorizontalLocation.Right;
	
	// Line INDENTATION
	Line = Items.Add("Line" + SectionName + ProductID, Type("FormDecoration"), GoodsProfile);
	Line.Type = FormDecorationType.Picture;
	Line.Picture = PictureLib.BorderGray;
	Line.HorizontalStretch = True;
	Line.PictureSize = PictureSize.Stretch;
	Line.Height = 0;
	
EndProcedure

&AtServer
Function CreateGroupOnForm(SectionName, GroupIdentifier, Var_Title)
	
	ProductGroup_1 = Items.Add(
	"ProductGroup_1" + SectionName + String(GroupIdentifier),
	Type("FormGroup"),
	Items[SectionName]);
		
	ProductGroup_1.Type                     = FormGroupType.UsualGroup;
	ProductGroup_1.Behavior               = UsualGroupBehavior.Collapsible;
	ProductGroup_1.TitleTextColor     = WebColors.Gray;
	ProductGroup_1.TitleFont          = StyleFonts.TextFontAssemblyAndDelivery;
	ProductGroup_1.Group             = ChildFormItemsGroup.Vertical;
	ProductGroup_1.Title               = Var_Title;
	
	Return ProductGroup_1; 
	
EndFunction

&AtServer
Procedure CreateGroupTables()
	
	If ProductGroups_2.Count() = 0 Then
		TabVal = Goods.Unload(,"Group, RowsCount");
		TabVal.GroupBy("Group", "RowsCount");
		ProductGroups_2.Load(TabVal);
		
		Cnt = 1;
		For Each String In ProductGroups_2 Do
			String.ID = Cnt;
			Cnt = Cnt + 1;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure SoftwareInterfaceFormation()
	
	If ToUseGrouping Then
		Items.FormChangeTheHierarchy.Picture = PictureLib.List16AssemblyAndDelivery;
	Else
		Items.FormChangeTheHierarchy.Picture = PictureLib.HierarchicalList;
	EndIf;
	
	For Each RowGoods In Goods Do
			DeleteProductCardOnServer("Goods", RowGoods.ID);
	EndDo;
	
	If ToUseGrouping Then
		For Each EGroups In ProductGroups_2 Do
			
			ProductGroup_1 = Items.Find("ProductGroup_1" + "GoodsPage" + String(EGroups.ID));
			If ProductGroup_1 = Undefined Then
				ProductGroup_1 = CreateGroupOnForm("GoodsPage", EGroups.ID, EGroups.Group);
			EndIf;
			
			For Each OrderLine In Goods Do
				
				If OrderLine.Group <> EGroups.Group Then
					Continue;
				EndIf;
				
				ID = StrReplace(String(OrderLine.ID),Chars.NBSp,"");
				CreateProductCardOnForm("Goods", ID, ProductGroup_1);
				
			EndDo;
			
		EndDo;
		
	Else
		
		For Each OrderLine In Goods Do
			
			ID = StrReplace(String(OrderLine.ID),Chars.NBSp,"");
			CreateProductCardOnForm("Goods", ID, Items.GoodsPage);
			
		EndDo;
		
	EndIf;
	
	
EndProcedure

&AtServer
Procedure DeleteProductCardOnServer(SectionName, ProductID)
	
	Item = Items.Find("GoodsProfile" + SectionName + ProductID);
	If Item = Undefined Then
		Return;
	EndIf;
	
	// Delete Form Elements
	Items.Delete(Items.Find("GoodsProfile" + SectionName + ProductID));
	
	// Delete Form Commands
	Commands.Delete(Commands.Find("ProductItemName" + SectionName + "_" + ProductID));
	Commands.Delete(Commands.Find("ProductQuantity__" + SectionName + "_" + ProductID));
	Commands.Delete(Commands.Find("ProductWeight_" + SectionName + "_" + ProductID));
	Commands.Delete(Commands.Find("ProductPrice" + SectionName + "_" + ProductID));

	// To remove the details
	If ShowProductPhotos Then
		AttributesToDeleteArray = New Array();
		AttributesToDeleteArray.Add("Photo_" + SectionName + ProductID); 
		ChangeAttributes(, AttributesToDeleteArray);
	Else
		ChangeAttributes();
	EndIf;
	
EndProcedure

#EndRegion
