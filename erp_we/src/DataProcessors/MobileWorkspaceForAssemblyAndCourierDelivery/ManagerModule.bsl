#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Prepares the table of goods according to the delivery order.
//
// Parameters:
//	OrderDocument - DocumentRef.SalesOrder - delivery order.
//	ResultAddress - String - the address in the temporary storage.
//
Procedure GoodsTable(OrderDocument, ResultAddress) Export
	
	QueryText = 
	"SELECT
	|	Goods.Products.SKU AS SKU,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.Count AS Count,
	|	Goods.Price AS Price,
	|	&ItemGroupingOfGoods AS Group,
	|	Goods.Products.PicturesFile AS PicturesFile,
	|	Goods.Products.ExpirationDate_ AS ExpirationDate_,
	|	Goods.Products.ShelfLifeUnitOfMeasure AS ShelfLifeUnitOfMeasure,
	|	Goods.PriceKind AS PriceKind,
	|	1 AS RowsCount,
	|	Goods.Package AS Package,
	|	&QueryTextUnitOfMeasureDescription AS UnitOfMeasure,
	|	Goods.NumberOfPackages * &QueryTextPackageWeight AS Weight,
	|	&QueryTextPackageWeight AS PackageWeight,
	|	CASE
	|		WHEN Goods.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Weight)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsAWeightProduct
	|INTO TTOrderItems
	|FROM
	|	Document.SalesOrder.Goods AS Goods
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Goods.Products = CatalogProducts.Ref
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON Goods.Package = PackagesAndUnitsOfMeasure.Ref
	|WHERE
	|	Goods.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(ItemsBarcodes.Barcode, """")	AS Barcode,
	|	TTOrderItems.Products						AS Products,
	|	TTOrderItems.Characteristic					AS Characteristic,
	|	TTOrderItems.Series							AS Series,
	|	TTOrderItems.Package							AS Package,
	|	CASE
	|		WHEN TTOrderItems.Package = ItemsBarcodes.Package
	|			THEN 0
	|		WHEN ItemsBarcodes.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE 4
	|	END											AS Priority
	|INTO ItemsBarcodes
	|FROM
	|	TTOrderItems AS TTOrderItems
	|		LEFT JOIN InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		ON TTOrderItems.Products = ItemsBarcodes.Products
	|			AND TTOrderItems.Characteristic = ItemsBarcodes.Characteristic
	|			AND TTOrderItems.Series = ItemsBarcodes.Series
	|			AND (TTOrderItems.Package = ItemsBarcodes.Package
	|				OR ItemsBarcodes.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT
	|	ISNULL(ItemsBarcodes.Barcode, """")	AS Barcode,
	|	TTOrderItems.Products						AS Products,
	|	TTOrderItems.Characteristic					AS Characteristic,
	|	TTOrderItems.Series							AS Series,
	|	TTOrderItems.Package							AS Package,
	|	CASE
	|		WHEN TTOrderItems.Package = ItemsBarcodes.Package
	|			THEN 2
	|		WHEN ItemsBarcodes.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 3
	|		ELSE 4
	|	END											AS Priority
	|FROM
	|	TTOrderItems AS TTOrderItems
	|		LEFT JOIN InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		ON TTOrderItems.Products = ItemsBarcodes.Products
	|			AND TTOrderItems.Characteristic = ItemsBarcodes.Characteristic
	|			AND (TTOrderItems.Package = ItemsBarcodes.Package
	|				OR ItemsBarcodes.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Package,
	|	Priority
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemsBarcodes.Products			AS Products,
	|	ItemsBarcodes.Characteristic		AS Characteristic,
	|	ItemsBarcodes.Series					AS Series,
	|	ItemsBarcodes.Package				AS Package,
	|	MIN(ItemsBarcodes.Priority)	AS Priority
	|INTO BarcodesPriority
	|FROM
	|	ItemsBarcodes AS ItemsBarcodes
	|
	|GROUP BY
	|	ItemsBarcodes.Products,
	|	ItemsBarcodes.Characteristic,
	|	ItemsBarcodes.Series,
	|	ItemsBarcodes.Package
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Package,
	|	Priority
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(ItemsBarcodes.Barcode)	AS Barcode,
	|	ItemsBarcodes.Products			AS Products,
	|	ItemsBarcodes.Characteristic		AS Characteristic,
	|	ItemsBarcodes.Series					AS Series,
	|	ItemsBarcodes.Package				AS Package
	|INTO Barcodes
	|FROM
	|	ItemsBarcodes AS ItemsBarcodes
	|		INNER JOIN BarcodesPriority AS BarcodesPriority
	|		ON ItemsBarcodes.Products = BarcodesPriority.Products
	|			AND ItemsBarcodes.Characteristic = BarcodesPriority.Characteristic
	|			AND ItemsBarcodes.Series = BarcodesPriority.Series
	|			AND ItemsBarcodes.Package = BarcodesPriority.Package
	|			AND ItemsBarcodes.Priority = BarcodesPriority.Priority
	|
	|GROUP BY
	|	ItemsBarcodes.Products,
	|	ItemsBarcodes.Characteristic,
	|	ItemsBarcodes.Series,
	|	ItemsBarcodes.Package
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTOrderItems.Group AS Group,
	|	TTOrderItems.Products AS Products,
	|	TTOrderItems.Characteristic AS Characteristic,
	|	TTOrderItems.Series AS Series,
	|	TTOrderItems.Count AS Count,
	|	TTOrderItems.Price AS Price,
	|	TTOrderItems.PicturesFile AS PicturesFile,
	|	TTOrderItems.ShelfLifeUnitOfMeasure AS ShelfLifeUnitOfMeasure,
	|	TTOrderItems.ExpirationDate_ AS ExpirationDate_,
	|	TTOrderItems.RowsCount AS RowsCount,
	|	ItemsBarcodes.Barcode AS Barcode,
	|	TTOrderItems.PriceKind AS PriceKind,
	|	TTOrderItems.SKU AS SKU,
	|	CASE
	|		WHEN TTOrderItems.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN TTOrderItems.Products.UnitOfMeasure
	|		ELSE TTOrderItems.Package
	|	END AS Package,
	|	CASE
	|		WHEN TTOrderItems.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN CASE
	|					WHEN TTOrderItems.Products.WeightDenominator = 0
	|						THEN 0
	|					ELSE TTOrderItems.Products.WeightNumerator / TTOrderItems.Products.WeightDenominator
	|				END
	|		ELSE TTOrderItems.PackageWeight
	|	END AS Weight,
	|	CASE
	|		WHEN TTOrderItems.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN TTOrderItems.Products.WeightUnitOfMeasure
	|		ELSE TTOrderItems.Package.WeightUnitOfMeasure
	|	END AS WeightUnitOfMeasure,
	|	TTOrderItems.ThisIsAWeightProduct AS ThisIsAWeightProduct
	|FROM
	|	TTOrderItems AS TTOrderItems
	|		LEFT JOIN Barcodes AS ItemsBarcodes
	|		ON TTOrderItems.Products = ItemsBarcodes.Products
	|			AND TTOrderItems.Characteristic = ItemsBarcodes.Characteristic
	|			AND TTOrderItems.Series = ItemsBarcodes.Series
	|			AND TTOrderItems.Package = ItemsBarcodes.Package";
	
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
	
	GroupingOfGoods = WarehousesServer.GroupingOfGoods(Common.ObjectAttributeValue(OrderDocument, "Warehouse"));
	
	QueryText = StrReplace(QueryText,
		"&ItemGroupingOfGoods",
		"Goods.Products." + GroupingOfGoods);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", OrderDocument);
	
	PutToTempStorage(Query.Execute().Unload(), ResultAddress);
	
EndProcedure

// Returns information about the goods recognized when scanning the barcode.
//
// Parameters:
//	Barcode - String - The barcode of the item that is used to search for the product.
//	PriceKind - CatalogRef.TypesOfPrices - price type of the product.
//
// Returns:
//	ValueTable:
//		* Barcode - String -
//		* Products - CatalogRef.Products -
//		* SKU - String -
//		* Characteristic - CatalogRef.ItemsCharacteristics -
//		* Series - CatalogRef.ItemsBatches -
//		* Package - CatalogRef.PackagesAndUnitsOfMeasure -
//		* Price - Number -
//		* ID - Number -
//		* PicturesFile - CatalogRef.ProductsAttachedFiles -
//		* Group - CatalogRef.Products -
//		* RowsCount - String -
//		* WeightUnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure -
//		* ExpirationDate_ - Number -
//		* ShelfLifeUnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure -
//		* PriceKind - CatalogRef.TypesOfPrices -
//
Function FindGoodsBySHK(Barcode, PriceKind) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ItemsBarcodes.Barcode				AS Barcode,
	|	ItemsBarcodes.Products			AS Products,
	|	CatalogProducts.SKU				AS SKU,
	|	ItemsBarcodes.Characteristic		AS Characteristic,
	|	ItemsBarcodes.Series					AS Series,
	|	CASE
	|		WHEN ItemsBarcodes.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN CatalogProducts.UnitOfMeasure
	|		ELSE ItemsBarcodes.Package
	|	END										AS Package,
	|	ItemsPrices.Price						AS Price,
	|	0											AS ID,
	|	CatalogProducts.PicturesFile			AS PicturesFile,
	|	CatalogProducts.Parent				AS Group,
	|	1											AS RowsCount,
	|	CatalogProducts.ExpirationDate_			AS ExpirationDate_,
	|	CatalogProducts.ShelfLifeUnitOfMeasure AS ShelfLifeUnitOfMeasure,
	|	CASE
	|		WHEN ItemsBarcodes.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN CatalogProducts.WeightUnitOfMeasure
	|		ELSE ItemsBarcodes.Package.WeightUnitOfMeasure
	|	END										AS WeightUnitOfMeasure,
	|	&PriceKind									AS PriceKind
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(, PriceKind = &PriceKind) AS ItemsPrices
	|		ON ItemsBarcodes.Products = ItemsPrices.Products
	|			AND ItemsBarcodes.Characteristic = ItemsPrices.Characteristic
	|			AND ItemsBarcodes.Package = ItemsPrices.Package
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON ItemsBarcodes.Products = CatalogProducts.Ref
	|WHERE
	|	ItemsBarcodes.Barcode = &Barcode";
	
	Query.SetParameter("PriceKind", PriceKind);
	Query.SetParameter("Barcode", Barcode);
	
	Goods = Query.Execute().Unload();
	
	CrntID = 1;
	
	For Each String In Goods Do
		String.ID = CrntID;
		CrntID = CrntID + 1;
	EndDo;
	
	Return Goods;
	
EndFunction

#EndRegion

#Region Private

Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	
EndProcedure

// Returns a representation of the delivery date and time period.
//
//	Parameters:
//		Parameters - Structure,ValueTableRow -  - Where:
//			* DeliveryDate - Date -
//			* DeliveryTimeFrom - Date -
//			* DeliveryTimeTo - Date -
//
//	Returns:
//		String - representation of the delivery date and time period.
//
Function DateTimeOfDeliveryPresentation(Parameters) Export
	
	// Example: 21.05 09:00-12:00
	
	CurrentDate = BegOfDay(CurrentSessionDate());
	DeliveryDate = BegOfDay(Parameters.DeliveryDate);
	
	Text = "";
	If ValueIsFilled(DeliveryDate)
		And CurrentDate <> DeliveryDate Then 
		Text = Text + Format(DeliveryDate,"DF=dd.MM") + " ";
	EndIf;

	Text = Text + Format(Parameters.DeliveryTimeFrom,"DF=HH:mm") + " ";
	Text = Text + "- ";
	Text = Text + Format(Parameters.DeliveryTimeTo,"DF=HH:mm") + " ";
	
	Return Text;
	
EndFunction

// Returns a representation of the remaining time until the desired delivery time.
//
//	Parameters:
//		Parameters - Structure,ValueTableRow -  - Where:
//			* DeliveryDate - Date -
//			* DeliveryTimeFrom - Date -
//			* DeliveryTimeTo - Date -
//			* LateArrival - Boolean - it is set to true if the delivery time has expired.
//
//	Returns:
//		String - representation of the remaining time until the desired delivery time.
//
Function ThereIsStillTimeForDelivery(Parameters) Export
	
	// Example: ost. 5 h 40 min
	
	CurrentDate = CurrentSessionDate();
	DeliveryDate = BegOfDay(Parameters.DeliveryDate) + Hour(Parameters.DeliveryTimeTo)*60*60 + Minute(Parameters.DeliveryTimeTo)*60;
	
	TimeDifference = DeliveryDate - CurrentDate;
	Parameters.LateArrival = (TimeDifference < 0);
	
	TimeDifference = ?(Parameters.LateArrival, -TimeDifference, TimeDifference);
	
	DaysCount = Int(TimeDifference/86400);
	
	If DaysCount <> 0 Then
		TimeDifference = TimeDifference%86400;
	EndIf;
	
	HoursCount = Int(TimeDifference/3600);
	
	If HoursCount <> 0 Then
		TimeDifference = TimeDifference%3600;
	EndIf;
	
	MinutesCount = Int(TimeDifference/60);
	
	Text = ?(Parameters.LateArrival, "late. ", "bal.");
	Text = Text + ?(DaysCount > 0, " " + DaysCount + " d", "");
	Text = Text + ?(HoursCount > 0, " " + HoursCount + " Ch", "");
	Text = Text + ?(MinutesCount > 0, " " + MinutesCount + " min", "");
	
	Return Text;
	
EndFunction

// Returns a representation of the order amount with the currency symbol or symbol code.
//
//	Parameters:
//		Parameters - Structure,ValueTableRow -  - Where:
//			* Currency - CatalogRef.Currencies
//			* DocumentAmount - Number
//
//	Returns:
//		String - representation of the order amount with a symbol or symbolic currency code.
//
Function SumPresentation(Parameters) Export
	
	Return SumPresentationTotal(Parameters.DocumentAmount, Parameters.Currency);
	
EndFunction

// Returns a representation of the order amount with the currency symbol or symbol code.
//
//	Parameters:
//		Parameters - Structure,ValueTableRow -  - Where:
//			* Currency - CatalogRef.Currencies
//			* DocumentAmount - Number
//
//	Returns:
//		String - representation of the order amount with a symbol or symbolic currency code.
//
Function AmountToPayPresentation(Parameters) Export
	
	Return SumPresentationTotal(Parameters.AmountToPay, Parameters.Currency);
	
EndFunction

// Returns a representation of the order amount with the currency symbol or symbol code.
//
//	Parameters:
//		Parameters - Structure,ValueTableRow - Where:
//			* Currency - CatalogRef.Currencies
//			* DocumentAmount - Number -
//
//	Returns:
//		String - representation of the order amount with a symbol or symbolic currency code.
//
Function Change_2Presentation(Parameters) Export
	
	Return SumPresentationTotal(Parameters.Change_2, Parameters.Currency);
	
EndFunction

Function SumPresentationTotal(Sum, Currency) Export
	
	Text = Format(Sum,"NFD=2; NZ=; NG=0");
	Text = Text + " " + CurrencyPresentation(Currency);
	
	Return TrimAll(Text);
	
EndFunction

Function WeightPresentation(Weight) Export
	
	// The weight should be in kilograms
	
	Query = New Query();
	
	Query.Text = "SELECT
	               |	PackagesAndUnitsOfMeasure.Description AS Description,
	               |	PackagesAndUnitsOfMeasure.Numerator AS Numerator,
	               |	PackagesAndUnitsOfMeasure.Denominator AS Denominator,
	               |	PackagesAndUnitsOfMeasure.Code AS Code,
	               |	PackagesAndUnitsOfMeasure.Numerator / PackagesAndUnitsOfMeasure.Denominator AS Repetition
	               |FROM
	               |	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	               |WHERE
	               |	PackagesAndUnitsOfMeasure.Code IN (""163 "", ""166 "", ""168 "")
	               |
	               |ORDER BY
	               |	Repetition DESC";
	
	Result = Query.Execute().Unload();
	
	Text = "";
	WeightBalance = Weight;
	For Each CurUnitOfMeasurement In Result Do
		
		WeightPerUnit = Int(WeightBalance/CurUnitOfMeasurement.Repetition);
		WeightBalance = WeightBalance%CurUnitOfMeasurement.Repetition;
		
		If WeightPerUnit <> 0 Then
			Text = " " + WeightPerUnit + " " + CurUnitOfMeasurement.Description;
		EndIf;
		
	EndDo;
	
	If WeightBalance <> 0 Then
		Text = Text + "," + Format(WeightBalance,"NG=0");
	EndIf;
	
	Return TrimAll(Text);
	
EndFunction

Function PaymentMethodPresentation(Parameters) Export
	
	// Example: Cash
	
	Text = "";
	
	If Parameters.AmountToPay > 0 Then
		If Parameters.PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
			Text = NStr("vi = 'bằng tiền mặt';
						|ru = 'наличными';
						|en = 'cash'; fa = 'cash';
						|it = 'in contanti';
						|pl = 'gotówką';
						|tr = 'nakit'");
		ElsIf Parameters.PaymentMethod = Enums.PaymentForms.BankAccountPayment Then
			Text = NStr("vi = 'bằng chuyển khoản';
						|ru = 'банковским переводом';
						|en = 'by bank transfer'; fa = 'by bank transfer';
						|it = 'bonifico bancario';
						|pl = 'przelewem bankowym';
						|tr = 'banka transferi ile'");
		ElsIf Parameters.PaymentMethod = Enums.PaymentForms.PaymentCard Then
			Text = NStr("vi = 'bằng thẻ ngân hàng';
						|ru = 'банковской картой';
						|en = 'by bank card'; fa = 'by bank card';
						|it = 'carta di credito';
						|pl = 'kartą bankową';
						|tr = 'banka kartı ile'");
		ElsIf Parameters.PaymentMethod = Enums.PaymentForms.EmptyRef() Then
			Text = NStr("vi = 'bất kỳ';
						|ru = 'любая';
						|en = 'any'; fa = 'any';
						|it = 'qualsiasi';
						|pl = 'jakakolwiek';
						|tr = 'herhangi'");
		EndIf;
	Else
		Text = NStr("vi = 'ĐÃ THANH TOÁN';
					|ru = 'ОПЛАЧЕНО';
					|en = 'PAID'; fa = 'PAID';
					|it = 'PAGATO';
					|pl = 'OPŁACONO';
					|tr = 'ÖDENDİ'");
	EndIf;
	
	Return Text;
	
EndFunction

// Returns a representation of currency in the form of the name or symbol.
//
//	Parameters:
//		Currency - CatalogRef.Currencies
//
//	Returns:
//		String - representation of a currency in the form of a name or symbol.
//
Function CurrencyPresentation(Currency) Export
	
	Text = "";
	
	If ValueIsFilled(Currency) Then
		
		CurrencyDetails = Common.ObjectAttributesValues(Currency, "Code, Description");
		
		If CurrencyDetails.Code = "643" Then
			Text = "₽";
		ElsIf CurrencyDetails.Code = "840" Then
			Text = "$";
		ElsIf CurrencyDetails.Code = "978" Then
			Text = "€";
		Else
			Text = CurrencyDetails.Description;
		EndIf;
	EndIf;
	
	Return Text;
	
EndFunction

// Returns a representation of currency in the form of the name or symbol.
//
//	Parameters:
//		ReferenceOrder - DocumentRef
//
//	Returns:
//		String - phone number.
//
Function PhoneNumberOfContactPersonFromDocument(ReferenceOrder) Export
	
	PhoneNumber = "";
	
	ContactPersons = Common.ObjectAttributesValues(ReferenceOrder, "ContactPerson, Partner");
	
	PhoneNumber = PhoneNumberOfContactPerson(ContactPersons.ContactPerson);
	
	If PhoneNumber = "" Then
		PhoneNumber = PhoneNumberOfContactPerson(ContactPersons.Partner);
	EndIf;
	
	Return PhoneNumber;
	
EndFunction

Function PhoneNumberOfContactPerson(ContactPerson) Export
	
	PhoneNumber = "";
	ContactInformationKinds = New Array;
	
	If TypeOf(ContactPerson) = Type("CatalogRef.ContactPersonsForPartners") Then
		ContactInformationKinds.Add(Catalogs.ContactInformationKinds.ContactPersonSMobilePhoneNumber);
		ContactInformationKinds.Add(Catalogs.ContactInformationKinds.ContactPersonSPhoneNumber);
	ElsIf TypeOf(ContactPerson) = Type("CatalogRef.Partners") Then
		ContactInformationKinds.Add(Catalogs.ContactInformationKinds.PartnerSPhoneNumber);
	ElsIf TypeOf(ContactPerson) = Type("CatalogRef.Persons") Then
		ContactInformationKinds.Add(Catalogs.ContactInformationKinds.MobilePhoneOfPerson);
	ElsIf TypeOf(ContactPerson) = Type("CatalogRef.Warehouses") Then
		ContactInformationKinds.Add(Catalogs.ContactInformationKinds.WarehousePhone);
	EndIf;
	
	For Each ContactInformationKind In ContactInformationKinds Do
		
		ContactInformationTable_ = ContactsManager.ObjectContactInformation(ContactPerson, 
																								ContactInformationKind,
																		,
																		False);
		If ContactInformationTable_.Count() Then
			ContactInformation = ContactInformationTable_[0];
			PhoneNumber = ContactInformation.Presentation;
			PhoneNumber = StringFunctionsClientServer.ReplaceCharsWithOther("()_- ", PhoneNumber, "");
			
		EndIf;
		
		If PhoneNumber <> "" Then
			Break;
		EndIf;
		
	EndDo;
	
	If StrLen(PhoneNumber) = 11 And Left(PhoneNumber,1) = "7" Then
		PhoneNumber = "+" + PhoneNumber;
	ElsIf StrLen(PhoneNumber) = 10 Then
		PhoneNumber = "+7" + PhoneNumber;
	EndIf;
	
	Return PhoneNumber;
	
EndFunction

Function AddressOwnerPresentation(Owner) Export
	
	AddressPresentation = "";
	ContactInformationKinds = New Array;
	
	If TypeOf(Owner) = Type("CatalogRef.Warehouses") Then
		ContactInformationKinds.Add(Catalogs.ContactInformationKinds.WarehouseAddress);
	EndIf;
	
	For Each ContactInformationKind In ContactInformationKinds Do
		
		ContactInformationTable_ = ContactsManager.ObjectContactInformation(Owner, 
																								ContactInformationKind,
																		,
																		False);
		If ContactInformationTable_.Count() Then
			ContactInformation = ContactInformationTable_[0];
			AddressPresentation = ContactInformation.Presentation;
			
		EndIf;
		
		If AddressPresentation <> "" Then
			Break;
		EndIf;
		
	EndDo;
	
	Return AddressPresentation;
	
EndFunction

Procedure OverrideCurProcessCommand(Form) Export
	
	OrderPaid = (Form.AmountToPay <=0);
	BuildAndDeliverySettings = WarehousesServer.WarehouseSettingsForAssemblyAndDelivery(Form.Warehouse);
	
	TitleText = NStr("vi = 'Hoàn thành giao hàng';
					|ru = 'Завершить доставку';
					|en = 'Complete delivery'; fa = 'Complete delivery';
					|it = 'Completare consegna';
					|pl = 'Zakończ dostawę';
					|tr = 'Teslimatı tamamla'");
	CurrentAction1 = "CompleteDelivery";
	
	If BuildAndDeliverySettings = Undefined Then
		Return;
	EndIf;
	
	YouNeedToIssueReceipt = (BuildAndDeliverySettings.MethodOfFiscalizationUponDelivery
		= Enums.MethodsOfFiscalizationUponDelivery.UponDelivery);
		
	FormName = Form.FormName;
	
	If OrderPaid Then
		
		If YouNeedToIssueReceipt Then
			If BuildAndDeliverySettings.CouriersUseAutonomousCREs Then
				TitleText = NStr("vi = 'Phiếu đã phát hành';
								|ru = 'Чек выдан';
								|en = 'Receipt is issued'; fa = 'رسید صادر شده است';
								|it = 'Scontrino emesso';
								|pl = 'Wydano paragon';
								|tr = 'Fiş verildi'");
				CurrentAction1 = "CompleteDelivery";
			ElsIf RemoteReceiptPenetrationIsAvailable() Then
				TitleText = NStr("vi = 'Tạo phiếu';
								|ru = 'Оформить чек';
								|en = 'Issue a receipt'; fa = 'Issue a receipt';
								|it = 'Emettere scontrino';
								|pl = 'Wystaw paragon';
								|tr = 'Fiş düzenle'");
				CurrentAction1 = "IssueReceipt";
			Else
				TitleText = NStr("vi = 'Hoàn thành giao hàng';
								|ru = 'Завершить доставку';
								|en = 'Complete delivery'; fa = 'Complete delivery';
								|it = 'Completare consegna';
								|pl = 'Zakończ dostawę';
								|tr = 'Teslimatı tamamla'");
				CurrentAction1 = "CompleteDelivery";
			EndIf;
		Else
			TitleText = NStr("vi = 'Phiếu đã phát hành';
							|ru = 'Чек выдан';
							|en = 'Receipt is issued'; fa = 'رسید صادر شده است';
							|it = 'Scontrino emesso';
							|pl = 'Wydano paragon';
							|tr = 'Fiş verildi'");
			CurrentAction1 = "CompleteDelivery";
		EndIf;
		
	Else
		
		If StrFind(FormName, "ReferenceCard") Then
			TitleText = NStr("vi = 'Tiếp nhận thanh toán';
							|ru = 'Принять оплату';
							|en = 'Accept payment'; fa = 'پذیرش پرداخت';
							|it = 'Accettare il pagamento';
							|pl = 'Przyjmij płatność';
							|tr = 'Ödemeyi kabul et'");
			CurrentAction1 = "AcceptPayment";
		Else
			If YouNeedToIssueReceipt Then
				If BuildAndDeliverySettings.CouriersUseAutonomousCREs Then
					TitleText = NStr("vi = 'Đã nhận thanh toán, phiếu đã phát hành';
									|ru = 'Оплата получена, чек выдан';
									|en = 'Payment received, receipt was issued'; fa = 'Payment received, receipt was issued';
									|it = 'Pagamento ricevuto, scontrino emesso';
									|pl = 'Płatność otrzymana, paragon wydany';
									|tr = 'Ödeme kabul edildi, fiş verildi'");
					CurrentAction1 = "AcceptPayment";
				ElsIf RemoteReceiptPenetrationIsAvailable() Then
					TitleText = NStr("vi = 'Đã nhận thanh toán, cần tạo phiếu';
									|ru = 'Оплата получена, оформить чек';
									|en = 'Payment received, issue a receipt'; fa = 'پرداخت دریافت شد، صدور رسید';
									|it = 'Pagamento ricevuto, emettere scontrino';
									|pl = 'Otrzymano opłatę, utwórz paragon';
									|tr = 'Ödeme kabul edildi, fiş düzenle'");
					CurrentAction1 = "AcceptPaymentAndIssueReceipt";
				Else
					TitleText = NStr("vi = 'Đã nhận thanh toán, kết thúc giao hàng';
									|ru = 'Оплата получена, завершить доставку';
									|en = 'Payment received, complete delivery'; fa = 'Payment received, complete delivery';
									|it = 'Pagamento ricevuto, completare consegna';
									|pl = 'Otrzymano płatność, zakończ dostawę';
									|tr = 'Ödeme kabul edildi, teslimatı tamamla'");
					CurrentAction1 = "AcceptPayment";
				EndIf;
			Else
				TitleText = NStr("vi = 'Đã nhận thanh toán, phiếu đã phát hành';
								|ru = 'Оплата получена, чек выдан';
								|en = 'Payment received, receipt was issued'; fa = 'Payment received, receipt was issued';
								|it = 'Pagamento ricevuto, scontrino emesso';
								|pl = 'Płatność otrzymana, paragon wydany';
								|tr = 'Ödeme kabul edildi, fiş verildi'");
				CurrentAction1 = "AcceptPayment";
			EndIf;
		EndIf;
		
	EndIf;
	
	Items = Form.Items;
	CommandButton = Items.ExecuteAProcessCommand;//FormButton
	CommandButton.Title = TitleText;
	Form.CurrentAction1 = CurrentAction1;
	
EndProcedure

Function RemoteReceiptPenetrationIsAvailable()
	
	Return RetailSalesServerCall.RemoteFiscalizationIsAvailable();
	
EndFunction

Function AvailablePaymentMethods_1(OrderParameters) Export
	
	PaymentMethods_ = New ValueList();
	BuildAndDeliverySettings = WarehousesServer.WarehouseSettingsForAssemblyAndDelivery(OrderParameters.Warehouse);
	
	CashAccount = CourierOrganizationSCashRegisterForICO(OrderParameters);
	If CashAccount <> Catalogs.CashAccounts.EmptyRef() Then
		PaymentMethods_.Add("CashPayment");
	EndIf;
	
	If CashAccount = Catalogs.CashAccounts.EmptyRef()
		Or Not ThereIsPKOVCheckoutCourier(OrderParameters.ReferenceOrder) Then
	
		AcquiringTerminalData = DataOfCourierOrganizationSAcquiringTerminal(OrderParameters);
		If AcquiringTerminalData <> Undefined
			And BuildAndDeliverySettings.CouriersUsePOSTerminals Then
			PaymentMethods_.Add("ByPaymentCard");
		EndIf;
		
		
	EndIf;
	
	Return PaymentMethods_;
	
EndFunction

Function ThereIsPKOVCheckoutCourier(ReferenceOrder)
	
	OrderParameters = Common.ObjectAttributesValues(ReferenceOrder, "Courier, Organization");
	CashAccount = CourierOrganizationSSalesRegister(OrderParameters);
	Result = False;
	
	If CashAccount = Catalogs.CashAccounts.EmptyRef() Then
		Return Result;
	EndIf;
	
	Query = New Query;
	
	Query.Text = "SELECT
	               |	SUM(CASE
	               |			WHEN CashAccountBalance.RecordType = VALUE(AccumulationRecordType.Receipt)
	               |				THEN CashAccountBalance.Sum
	               |			ELSE -CashAccountBalance.Sum
	               |		END) AS AmountPaid
	               |FROM
	               |	AccumulationRegister.CashAccountBalance AS CashAccountBalance
	               |WHERE
	               |	CashAccountBalance.ARAPObject.Object = &ReferenceOrder
	               |	AND CashAccountBalance.CashAccount = &CashAccount";
	
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	Query.SetParameter("CashAccount", CashAccount);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	
	If Selection.Next() 
		And Selection.AmountPaid <> NULL Then
		Result = Selection.AmountPaid > 0;
	EndIf;
	
	Return Result;
	
EndFunction


// The appointment or removal of an employee 
// 
// Parameters:
// 	ReferenceOrder - DefinedType.ReferenceOrderOnAssemblyAndDeliveryByCourier
// 	EmployeeType - String
// 	Employee - Undefined - LongDesc
// 	ExecuteWithoutCheckingCurEmployee - Boolean - LongDesc
// 	Error - Boolean - True if an error occurred 
Procedure AssignRemoveEmployee(ReferenceOrder,
									EmployeeType,
									Employee=Undefined,
									ExecuteWithoutCheckingCurEmployee = False, // For the dispatcher
									Error = False) Export
	
	Assign = ValueIsFilled(Employee);
	SessionEmployee = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	
	If Not ValueIsFilled(ReferenceOrder) Then
		Return;
	EndIf;
	
	FullObjectName = "Document." + ReferenceOrder.Metadata().Name;
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockItem = Block.Add(FullObjectName);
		LockItem.SetValue("Ref", ReferenceOrder);
		Block.Lock();
		
		CurrentEmployee = Common.ObjectAttributeValue(ReferenceOrder, EmployeeType);
		
		If Assign Then
			If ValueIsFilled(CurrentEmployee) Then
				If CurrentEmployee = Employee Then
					Return;
				ElsIf (Not ExecuteWithoutCheckingCurEmployee) Then
					ErrorText = NStr("vi = 'Không thể chỉ định nhân viên.';
									|ru = 'Не удалось назначить сотрудника.';
									|en = 'Cannot assign employee.'; fa = 'Cannot assign employee.';
									|it = 'Non è stato possibile assegnare il dipendente.';
									|pl = 'Nie udało się przydzielić pracownika.';
									|tr = 'Çalışan atanamadı.'");
					ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Đơn đặt hàng được chỉ định cho %1.';
																		|ru = 'Заказ назначен на %1.';
																		|en = 'The order has been assigned for %1.'; fa = 'The order has been assigned for %1.';
																		|it = 'Ordine assegnato a %1.';
																		|pl = 'Zamówienie jest przydzielone na %1.';
																		|tr = 'Sipariş %1 atandı.'"), CurrentEmployee);
					Common.MessageToUser(ErrorText);
					Error = True;
					Return;
				EndIf;
			EndIf;
		ElsIf ValueIsFilled(CurrentEmployee) Then
			If CurrentEmployee <> SessionEmployee 
				And (Not ExecuteWithoutCheckingCurEmployee) Then
				ErrorText = NStr("vi = 'Không thể bỏ nhân viên.';
								|ru = 'Не удалось снять сотрудника.';
								|en = 'Cannot release employee.'; fa = 'Cannot release employee.';
								|it = 'Non è stato possibile rimuovere il dipendente.';
								|pl = 'Nie udało się odwołać pracownika.';
								|tr = 'Çalışan kaldırılamadı.'");
				ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Đơn đặt hàng được chỉ định cho %1.';
																	|ru = 'Заказ назначен на %1.';
																	|en = 'The order has been assigned for %1.'; fa = 'The order has been assigned for %1.';
																	|it = 'Ordine assegnato a %1.';
																	|pl = 'Zamówienie jest przydzielone na %1.';
																	|tr = 'Sipariş %1 atandı.'"), CurrentEmployee);
				Common.MessageToUser(ErrorText);
				Error = True;
				Return;
			EndIf;
		Else 
			Return;
		EndIf;
		
		SetPrivilegedMode(True);
		OrderObject__ = ReferenceOrder.GetObject();
		OrderObject__[EmployeeType] = Employee;
		OrderObject__.Write(DocumentWriteMode.Write);
		SetPrivilegedMode(False);
		
		If EmployeeType = "picker" And Not Assign Then
			InformationRegisters.AssemblyAndDeliveryStatuses.RecordStatus(ReferenceOrder, Enums.AssemblyAndDeliveryStatuses.ForAssembly);
		EndIf;
		
		CommitTransaction();
		
	Except
		
		ErrorText = ErrorText + Chars.LF + BriefErrorDescription(ErrorInfo());
		Common.MessageToUser(ErrorText);
		
		RollbackTransaction();
		
		Error = True;
		
		If Assign Then
			ErrorText = NStr("vi = 'Không thể chỉ định nhân viên.';
							|ru = 'Не удалось назначить сотрудника.';
							|en = 'Cannot assign employee.'; fa = 'Cannot assign employee.';
							|it = 'Non è stato possibile assegnare il dipendente.';
							|pl = 'Nie udało się przydzielić pracownika.';
							|tr = 'Çalışan atanamadı.'");
		Else
			ErrorText = NStr("vi = 'Không thể bỏ nhân viên.';
							|ru = 'Не удалось снять сотрудника.';
							|en = 'Cannot release employee.'; fa = 'Cannot release employee.';
							|it = 'Non è stato possibile rimuovere il dipendente.';
							|pl = 'Nie udało się odwołać pracownika.';
							|tr = 'Çalışan kaldırılamadı.'");
		EndIf;
		
		ErrorText = ErrorText + Chars.LF + BriefErrorDescription(ErrorInfo());
		Common.MessageToUser(ErrorText);
		
	EndTry;
	
EndProcedure

Procedure SetStatusOfOrderBeingDelivered(ReferenceOrder) Export
	
	SessionEmployee = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	CurCourier = Common.ObjectAttributeValue(ReferenceOrder, "Courier");
	
	If SessionEmployee <> CurCourier Then
		
		ErrorText = NStr("vi = 'Không thể bắt đầu giao hàng.';
						|ru = 'Нельзя начать доставку.';
						|en = 'Delivery cannot start.'; fa = 'Delivery cannot start.';
						|it = 'Non avviare la consegna.';
						|pl = 'Nie można rozpocząć dostawy.';
						|tr = 'Teslimat başlatılamaz.'");
		ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Đơn đặt hàng được chỉ định cho: %1.';
															|ru = 'Заказ назначен на: %1.';
															|en = 'The order has been assigned for: %1.'; fa = 'The order has been assigned for: %1.';
															|it = 'Ordine assegnato a: %1.';
															|pl = 'Zamówienie jest przydzielone na: %1.';
															|tr = 'Sipariş: %1 atandı.'"), CurCourier);
		Common.MessageToUser(ErrorText);
		Return;
	EndIf;
	
	RegisterRecord = InformationRegisters.AssemblyAndDeliveryStatuses.CreateRecordManager();
	RegisterRecord.ReferenceOrder = ReferenceOrder;
	RegisterRecord.Read();
	
	If RegisterRecord.Selected() Then
		
		If RegisterRecord.Status = Enums.AssemblyAndDeliveryStatuses.ReadyForDelivery Then
		
			RegisterRecord.Status = Enums.AssemblyAndDeliveryStatuses.DeliveryInProgress;
			
			Try
				RegisterRecord.Write(True);
			Except
				ErrorText = NStr("vi = 'Không thể bắt đầu giao hàng.';
								|ru = 'Не удалось начать доставку.';
								|en = 'Cannot start delivery.'; fa = 'Cannot start delivery.';
								|it = 'Non è stato possibile avviare la consegna.';
								|pl = 'Nie udało się rozpocząć dostawy.';
								|tr = 'Teslimat başlatılamadı.'");
				ErrorText = ErrorText + Chars.LF + BriefErrorDescription(ErrorInfo());
				Common.MessageToUser(ErrorText);
			EndTry;
		Else
			ErrorText = NStr("vi = 'Không thể bắt đầu giao hàng.';
							|ru = 'Нельзя начать доставку.';
							|en = 'Delivery cannot start.'; fa = 'Delivery cannot start.';
							|it = 'Non avviare la consegna.';
							|pl = 'Nie można rozpocząć dostawy.';
							|tr = 'Teslimat başlatılamaz.'");
			ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Trạng thái đơn hàng: %1.';
																|ru = 'Статус заказа: %1.';
																|en = 'Order status: %1.'; fa = 'Order status: %1.';
																|it = 'Stato dell''ordine %1.';
																|pl = 'Status zamówienia: %1.';
																|tr = 'Sipariş durumu: %1.'"), RegisterRecord.Status);
			Common.MessageToUser(ErrorText);
		EndIf;
	Else
		ErrorText = NStr("vi = 'Không thể bắt đầu giao hàng.';
						|ru = 'Не удалось начать доставку.';
						|en = 'Cannot start delivery.'; fa = 'Cannot start delivery.';
						|it = 'Non è stato possibile avviare la consegna.';
						|pl = 'Nie udało się rozpocząć dostawy.';
						|tr = 'Teslimat başlatılamadı.'");
		Common.MessageToUser(ErrorText);
	EndIf;
	
EndProcedure

Procedure SetStatusOfOrderDelivered(ReferenceOrder) Export
	
	SessionEmployee = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	CurCourier = Common.ObjectAttributeValue(ReferenceOrder, "Courier");
	
	If SessionEmployee <> CurCourier Then
		ErrorText = NStr("vi = 'Không thể kết thúc giao hàng.';
						|ru = 'Нельзя завершить доставку.';
						|en = 'Delivery cannot be completed.'; fa = 'Delivery cannot be completed.';
						|it = 'Non completare la consegna.';
						|pl = 'Nie można zakończyć dostawy.';
						|tr = 'Teslimat tamamlanamaz.'");
		ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Đơn đặt hàng được chỉ định cho: %1.';
															|ru = 'Заказ назначен на: %1.';
															|en = 'The order has been assigned for: %1.'; fa = 'The order has been assigned for: %1.';
															|it = 'Ordine assegnato a: %1.';
															|pl = 'Zamówienie jest przydzielone na: %1.';
															|tr = 'Sipariş: %1 atandı.'"), CurCourier);
		Common.MessageToUser(ErrorText);
		Return;
	EndIf;
	
	RegisterRecord = InformationRegisters.AssemblyAndDeliveryStatuses.CreateRecordManager();
	RegisterRecord.ReferenceOrder = ReferenceOrder;
	RegisterRecord.Read();
	
	If RegisterRecord.Selected() Then
		
		If RegisterRecord.Status = Enums.AssemblyAndDeliveryStatuses.DeliveryInProgress Then
		
			RegisterRecord.Status = Enums.AssemblyAndDeliveryStatuses.Delivered_5;
			RegisterRecord.DeliveryDate = CurrentSessionDate();
			
			Try
				RegisterRecord.Write(True);
			Except
				ErrorText = NStr("vi = 'Không thể kết thúc giao hàng.';
								|ru = 'Не удалось завершить доставку.';
								|en = 'Cannot complete delivery.'; fa = 'Cannot complete delivery.';
								|it = 'Non è stato possibile completare la consegna.';
								|pl = 'Nie udało się zakończyć dostawy.';
								|tr = 'Teslimat tamamlanamadı.'");
				ErrorText = ErrorText + Chars.LF + BriefErrorDescription(ErrorInfo());
				Common.MessageToUser(ErrorText);
			EndTry;
		Else
			ErrorText = NStr("vi = 'Không thể kết thúc giao hàng.';
							|ru = 'Нельзя завершить доставку.';
							|en = 'Delivery cannot be completed.'; fa = 'Delivery cannot be completed.';
							|it = 'Non completare la consegna.';
							|pl = 'Nie można zakończyć dostawy.';
							|tr = 'Teslimat tamamlanamaz.'");
			ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Trạng thái đơn hàng: %1.';
																|ru = 'Статус заказа: %1.';
																|en = 'Order status: %1.'; fa = 'Order status: %1.';
																|it = 'Stato dell''ordine %1.';
																|pl = 'Status zamówienia: %1.';
																|tr = 'Sipariş durumu: %1.'"), RegisterRecord.Status);
			Common.MessageToUser(ErrorText);
		EndIf;
	Else
		ErrorText = NStr("vi = 'Không thể kết thúc giao hàng.';
						|ru = 'Не удалось завершить доставку.';
						|en = 'Cannot complete delivery.'; fa = 'Cannot complete delivery.';
						|it = 'Non è stato possibile completare la consegna.';
						|pl = 'Nie udało się zakończyć dostawy.';
						|tr = 'Teslimat tamamlanamadı.'");
		Common.MessageToUser(ErrorText);
	EndIf;
	
EndProcedure

Procedure SetStatusOfOrderCanceled(ReferenceOrder, CancellationReason, Cancel) Export
	
	RegisterRecord = InformationRegisters.AssemblyAndDeliveryStatuses.CreateRecordManager();
	RegisterRecord.ReferenceOrder = ReferenceOrder;
	RegisterRecord.Read();
	
	ErrorText = "";
	If RegisterRecord.Selected() Then
		
		If RegisterRecord.Status = Enums.AssemblyAndDeliveryStatuses.DeliveryInProgress Then
		
			RegisterRecord.Status = Enums.AssemblyAndDeliveryStatuses.RolledBack_;
			RegisterRecord.CancellationReason = CancellationReason;
			
			Try
				RegisterRecord.Write(True);
			Except
				ErrorText = NStr("vi = 'Không thể hủy bỏ giao hàng.';
								|ru = 'Не удалось отменить доставку.';
								|en = 'Cannot cancel delivery.'; fa = 'Cannot cancel delivery.';
								|it = 'Non è stato possibile annullare la consegna.';
								|pl = 'Nie udało się anulować dostawy.';
								|tr = 'Teslimat iptal edilemedi.'");
				ErrorText = ErrorText + Chars.LF + BriefErrorDescription(ErrorInfo());
				Common.MessageToUser(ErrorText);
			EndTry;
		Else
			ErrorText = NStr("vi = 'Không thể hủy giao hàng.';
							|ru = 'Нельзя отменить доставку.';
							|en = 'Delivery cannot be cancelled.'; fa = 'Delivery cannot be cancelled.';
							|it = 'Non annullare la consegna.';
							|pl = 'Nie można anulować dostawy.';
							|tr = 'Teslimat iptal edilemez.'");
			ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Trạng thái đơn hàng: %1.';
																|ru = 'Статус заказа: %1.';
																|en = 'Order status: %1.'; fa = 'Order status: %1.';
																|it = 'Stato dell''ordine %1.';
																|pl = 'Status zamówienia: %1.';
																|tr = 'Sipariş durumu: %1.'"), RegisterRecord.Status);
			Common.MessageToUser(ErrorText);
		EndIf;
	Else
		ErrorText = NStr("vi = 'Không thể hủy bỏ giao hàng.';
						|ru = 'Не удалось отменить доставку.';
						|en = 'Cannot cancel delivery.'; fa = 'Cannot cancel delivery.';
						|it = 'Non è stato possibile annullare la consegna.';
						|pl = 'Nie udało się anulować dostawy.';
						|tr = 'Teslimat iptal edilemedi.'");
		Common.MessageToUser(ErrorText);
	EndIf;
	
	HasError = ErrorText <> ""; 
	
	If HasError Then
		Cancel = True;
	EndIf;
	
EndProcedure


// Sets the status of the order.
// 
// Parameters:
// 	ReferenceOrder - DefinedType.ReferenceOrderOnAssemblyAndDeliveryByCourier
// Returns:
// 	Boolean - LongDesc
Function ToSetStatusOfOrderIsGoingTo(ReferenceOrder) Export
	
	SessionEmployee = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	CurMailFetcher = Common.ObjectAttributeValue(ReferenceOrder, "Picker");
	
	If SessionEmployee <> CurMailFetcher Then
		
		Warehouse = Common.ObjectAttributeValue(ReferenceOrder, "Warehouse");
		ReferenceDate = Common.ObjectAttributeValue(ReferenceOrder, "Date");
		WarehouseSettings = WarehousesServer.WarehouseSettingsForAssemblyAndDelivery(Warehouse, ReferenceDate);
		
		If Not WarehouseSettings.PickersCanAssignJobsToThemselves Then
			
			ErrorText = NStr("vi = 'Không thể bắt đầu đóng bộ.';
							|ru = 'Нельзя начать сборку.';
							|en = 'Kitting cannot start.'; fa = 'Kitting cannot start.';
							|it = 'Non avviare assemblaggio.';
							|pl = 'Nie można rozpocząć kompletacji.';
							|tr = 'Montaj başlatılamaz.'");
			Common.MessageToUser(ErrorText);
			Return False;
			
		EndIf;
	EndIf;
	
	RegisterRecord = InformationRegisters.AssemblyAndDeliveryStatuses.CreateRecordManager();
	RegisterRecord.ReferenceOrder = ReferenceOrder;
	RegisterRecord.Read();
	
	If RegisterRecord.Selected() Then
		
		If RegisterRecord.Status = Enums.AssemblyAndDeliveryStatuses.ForAssembly Then
		
			RegisterRecord.Status = Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress;
			
			Try
				RegisterRecord.Write(True);
				
				OrderObject__ = ReferenceOrder.GetObject();
				OrderObject__.Picker = SessionEmployee;
				OrderObject__.Write(DocumentWriteMode.Write);
				
			Except
				ErrorText = NStr("vi = 'Không thể bắt đầu gom hàng.';
								|ru = 'Не удалось начать сборку.';
								|en = 'Cannot start kitting.'; fa = 'Cannot start kitting.';
								|it = 'Non è stato possibile avviare l''assemblaggio.';
								|pl = 'Nie udało się rozpocząć kompletacji.';
								|tr = 'Montaj başlatılamadı.'");
				ErrorText = ErrorText + Chars.LF + BriefErrorDescription(ErrorInfo());
				Common.MessageToUser(ErrorText);
				Return False;
			EndTry;
		Else
			ErrorText = NStr("vi = 'Không thể bắt đầu đóng bộ.';
							|ru = 'Нельзя начать сборку.';
							|en = 'Kitting cannot start.'; fa = 'Kitting cannot start.';
							|it = 'Non avviare assemblaggio.';
							|pl = 'Nie można rozpocząć kompletacji.';
							|tr = 'Montaj başlatılamaz.'");
			ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Trạng thái đơn hàng: %1.';
																|ru = 'Статус заказа: %1.';
																|en = 'Order status: %1.'; fa = 'Order status: %1.';
																|it = 'Stato dell''ordine %1.';
																|pl = 'Status zamówienia: %1.';
																|tr = 'Sipariş durumu: %1.'"), RegisterRecord.Status);
			Common.MessageToUser(ErrorText);
			Return False;
		EndIf;
	Else
		ErrorText = NStr("vi = 'Không thể bắt đầu gom hàng.';
						|ru = 'Не удалось начать сборку.';
						|en = 'Cannot start kitting.'; fa = 'Cannot start kitting.';
						|it = 'Non è stato possibile avviare l''assemblaggio.';
						|pl = 'Nie udało się rozpocząć kompletacji.';
						|tr = 'Montaj başlatılamadı.'");
		Common.MessageToUser(ErrorText);
		Return False;
	EndIf;
	
	Return True;
EndFunction

// Setting the order status 
// 
// Parameters:
// 	ReferenceOrder - DefinedType.ReferenceOrderOnAssemblyAndDeliveryByCourier
Procedure SetStatusOfOrderCollected(ReferenceOrder, OrderStructure) Export
	
	SessionEmployee = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	CurMailFetcher = Common.ObjectAttributeValue(ReferenceOrder, "Picker");
	Warehouse = Common.ObjectAttributeValue(ReferenceOrder, "Warehouse");
	ReferenceDate = Common.ObjectAttributeValue(ReferenceOrder, "Date");
	
	WarehouseSettings = WarehousesServer.WarehouseSettingsForAssemblyAndDelivery(Warehouse, ReferenceDate);
	
	If SessionEmployee <> CurMailFetcher Then
		ErrorText = NStr("vi = 'Không thể kết thúc đóng bộ.';
						|ru = 'Нельзя завершить сборку.';
						|en = 'Kitting cannot be completed.'; fa = 'Kitting cannot be completed.';
						|it = 'Non completare l''assemblaggio.';
						|pl = 'Nie można zakończyć kompletacji.';
						|tr = 'Montaj tamamlanamaz.'");
		ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Đơn đặt hàng được chỉ định cho: %1.';
															|ru = 'Заказ назначен на: %1.';
															|en = 'The order has been assigned for: %1.'; fa = 'The order has been assigned for: %1.';
															|it = 'Ordine assegnato a: %1.';
															|pl = 'Zamówienie jest przydzielone na: %1.';
															|tr = 'Sipariş: %1 atandı.'"), CurMailFetcher);
		Common.MessageToUser(ErrorText);
		Return;
	EndIf;
	
	// Filling out the order
	
	OrderObject__ = ReferenceOrder.GetObject();
	RowsToProcess = New Array;
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, OrderObject__);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(OrderObject__);
	
	// Product no
	For Each ProductLineNo In OrderStructure.ProductNo Do
		
		ProductQuantity_ = ProductLineNo.Count;
		
		If ProductQuantity_ = 0 Then
			Continue;
		EndIf;
			
		For Each CommandLine_ In OrderObject__.Goods Do
			
			If CommandLine_.Products = ProductLineNo.Products And CommandLine_.Characteristic = ProductLineNo.Characteristic Then
				
				If CommandLine_.Count = ProductLineNo.Count Then
					CommandLine_.Canceled = True;
					CommandLine_.CancellationReason = Catalogs.ReasonsForSaleOrderCancellation.VarianceOnDimensionalGoodsShipment;
				Else
					
					NewRow = OrderObject__.Goods.Add();
					FillPropertyValues(NewRow, CommandLine_);
					NewRow.RowCode = 0;
					NewRow.Count = CommandLine_.Count - ProductLineNo.Count;
					NewRow.NumberOfPackages = CommandLine_.Count - ProductLineNo.Count;
					
					RowsToProcess.Add(NewRow);
					
					CommandLine_.Canceled = True;
					CommandLine_.CancellationReason = Catalogs.ReasonsForSaleOrderCancellation.VarianceOnDimensionalGoodsShipment;
					CommandLine_.Count = ProductLineNo.Count;
					CommandLine_.NumberOfPackages = ProductLineNo.Count;
					
					RowsToProcess.Add(CommandLine_);
					
				EndIf;
				
				ProductQuantity_ = 0;
				
			EndIf;
		EndDo;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		OrderObject__.Goods,
		Undefined);
	
	// Assembled
	RowsToProcess = New Array;
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(OrderObject__);
	ParametersFillInVATRate.ByShipmentDate = True;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckFillPackageByOwner");
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("FillInVATRateForReturnableContainers", OrderObject__.ToReturnReusablePackage);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	
	DocumentParameters = Documents.SalesOrder.DocumentParametersForSoftwareActions(OrderObject__);
	StringFields_ = "SupplyOption";
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	
	For Each LineCollected In OrderStructure.Assembled Do
		
		ProductQuantity_ = LineCollected.Count;
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Products", LineCollected.Products);
		FilterParameters.Insert("Characteristic", LineCollected.Characteristic);
		FilterParameters.Insert("Canceled", False);
		
		ArrayOfFound = OrderObject__.Goods.FindRows(FilterParameters);
		
		If ArrayOfFound.Count() = 0 Then
			// New line
			
			NewRow = OrderObject__.Goods.Add();
			FillPropertyValues(NewRow, LineCollected);
			NewRow.NumberOfPackages = NewRow.Count;
			NewRow.Warehouse = OrderObject__.Warehouse;
			
			RowsToProcess.Add(NewRow);
			
		Else 
			IDOfFoundString = 0;
			Cnt = 0;
			While IDOfFoundString < ArrayOfFound.Count() Do
				
				If Cnt = 0 Then
					OrderLine_2 = ArrayOfFound[IDOfFoundString];
					OrderLine_2.Count = ProductQuantity_;
					OrderLine_2.NumberOfPackages = ProductQuantity_;
					
					IDOfFoundString = IDOfFoundString + 1;
					RowsToProcess.Add(OrderLine_2);
					
				Else
					
					OrderObject__.Goods.Delete(ArrayOfFound[IDOfFoundString]);
					
				EndIf;
				
				Cnt = Cnt + 1;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		OrderObject__.Goods,
		Undefined);
	
	OrderObject__.Write(DocumentWriteMode.Posting);
	
	RegisterRecord = InformationRegisters.AssemblyAndDeliveryStatuses.CreateRecordManager();
	RegisterRecord.ReferenceOrder = ReferenceOrder;
	RegisterRecord.Read();
	
	If RegisterRecord.Selected() Then
		
		If RegisterRecord.Status = Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress Then
		
			If WarehouseSettings.StoreSupportsDeliveryByOwnCouriers Then
				RegisterRecord.Status = Enums.AssemblyAndDeliveryStatuses.ReadyForDelivery;
			Else
				RegisterRecord.Status = Enums.AssemblyAndDeliveryStatuses.Assembled_;
			EndIf;
			RegisterRecord.AssemblyDate = CurrentSessionDate();
			
			Try
				RegisterRecord.Write(True);
			Except
				ErrorText = NStr("vi = 'Không thể kết thúc đóng bộ.';
								|ru = 'Не удалось завершить сборку.';
								|en = 'Cannot complete kitting.'; fa = 'Cannot complete kitting.';
								|it = 'Non è stato possibile completare l''assemblaggio.';
								|pl = 'Nie udało się zakończyć kompletacji.';
								|tr = 'Montaj tamamlanamadı.'");
				ErrorText = ErrorText + Chars.LF + BriefErrorDescription(ErrorInfo());
				Common.MessageToUser(ErrorText);
			EndTry;
		Else
			ErrorText = NStr("vi = 'Không thể kết thúc đóng bộ.';
							|ru = 'Нельзя завершить сборку.';
							|en = 'Kitting cannot be completed.'; fa = 'Kitting cannot be completed.';
							|it = 'Non completare l''assemblaggio.';
							|pl = 'Nie można zakończyć kompletacji.';
							|tr = 'Montaj tamamlanamaz.'");
			ErrorText = ErrorText + Chars.LF + StrTemplate(NStr("vi = 'Trạng thái đơn hàng: %1.';
																|ru = 'Статус заказа: %1.';
																|en = 'Order status: %1.'; fa = 'Order status: %1.';
																|it = 'Stato dell''ordine %1.';
																|pl = 'Status zamówienia: %1.';
																|tr = 'Sipariş durumu: %1.'"), RegisterRecord.Status);
			Common.MessageToUser(ErrorText);
		EndIf;
	Else
		ErrorText = NStr("vi = 'Không thể kết thúc đóng bộ.';
						|ru = 'Не удалось завершить сборку.';
						|en = 'Cannot complete kitting.'; fa = 'Cannot complete kitting.';
						|it = 'Non è stato possibile completare l''assemblaggio.';
						|pl = 'Nie udało się zakończyć kompletacji.';
						|tr = 'Montaj tamamlanamadı.'");
		Common.MessageToUser(ErrorText);
	EndIf;
	
EndProcedure

Function EmployeeTypeCourier() Export
	Return "courier";
EndFunction

Function EmployeeTypeMailFetcher() Export
	Return "picker";
EndFunction

Function EmployeeTypeDispatcher() Export
	Return "dispatcher";
EndFunction

Function ThisIsCompletedStatus(Status) Export
	
	Return WarehousesServer.StatusOfOrdersCompleted().Find(Status) <> Undefined;
	
EndFunction

Procedure CancelTheOrder(ReferenceOrder, CancellationReason, Cancel = False) Export
	
	SetStatusOfOrderCanceled(ReferenceOrder, CancellationReason, Cancel);
	
EndProcedure

Procedure CompleteDelivery(ReferenceOrder) Export
	
	SetStatusOfOrderDelivered(ReferenceOrder);
	
EndProcedure

Function CourierOrganizationSSalesRegister(OrderParameters) Export
	
	CashAccount = Catalogs.CashAccounts.EmptyRef();
	
	Query = New Query;
	
	Query.Text = "SELECT TOP 1
	               |	CashAccounts.Ref AS Ref
	               |FROM
	               |	Catalog.CashAccounts AS CashAccounts
	               |WHERE
	               |	CashAccounts.DeletionMark = FALSE
	               |	AND CashAccounts.OperationalCashAccount = TRUE
	               |	AND CashAccounts.Individual = &Courier
	               |	AND CashAccounts.Owner = &Organization";
	
	Query.SetParameter("Courier", OrderParameters.Courier);
	Query.SetParameter("Organization", OrderParameters.Organization);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		CashAccount = Selection.Ref
	EndIf;
	
	Return CashAccount;
	
EndFunction

Function CourierOrganizationSCashRegisterForICO(OrderParameters) Export
	
	CashAccount = Catalogs.CashAccounts.EmptyRef();
	
	Query = New Query;
	
	Query.Text = "SELECT TOP 1
	               |	CashAccounts.Ref AS CashAccount
	               |FROM
	               |	Catalog.CashAccounts AS CashAccounts
	               |WHERE
	               |	CashAccounts.DeletionMark = FALSE
	               |	AND CashAccounts.OperationalCashAccount = TRUE
	               |	AND CashAccounts.Individual = &Courier
	               |	AND CashAccounts.Owner = &Organization
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	Documents.CashAccount AS CashAccount
	               |FROM
	               |	Document.SalesOrder AS Documents
	               |WHERE
	               |	Documents.Ref = &ReferenceOrder
	               |	AND Documents.CashAccount.OperationalCashAccount = FALSE
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	CashAccounts.Ref AS CashAccount
	               |FROM
	               |	Catalog.CashAccounts AS CashAccounts
	               |WHERE
	               |	CashAccounts.DeletionMark = FALSE
	               |	AND CashAccounts.OperationalCashAccount = FALSE
	               |	AND CashAccounts.Owner = &Organization
	               |";
	
	Query.SetParameter("Courier", OrderParameters.Courier);
	Query.SetParameter("ReferenceOrder", OrderParameters.ReferenceOrder);
	Query.SetParameter("Organization", OrderParameters.Organization);
	
	SetPrivilegedMode(True);
	Results = Query.ExecuteBatch();
	
	If Not Results[0].IsEmpty() Then
		CashAccount = Results[0].Unload()[0].CashAccount;
	ElsIf Not Results[1].IsEmpty() Then
		CashAccount = Results[1].Unload()[0].CashAccount; 
	ElsIf Not Results[2].IsEmpty() Then
		CashAccount = Results[2].Unload()[0].CashAccount; 
	EndIf;
	
	Return CashAccount;
	
EndFunction

Function NumberOfRowsPresentation(Parameters) Export
	
	Text = StringFunctionsClientServer.StringWithNumberForAnyLanguage(
		NStr("vi = ';%1 vị trí;;%1 vị trí;%1 vị trí;%1 vị trí';
			|ru = ';%1 позиция;;%1 позиции;%1 позиций;%1 позиции';
			|en = ';%1 position;;%1 positions;%1 of positions;%1 of position'; fa = ';%1 position;;%1 positions;%1 of positions;%1 of position';
			|it = '%1 posizione;;%1 posizione;%1 posizioni;%1 posizioni';
			|pl = ';%1 pozycja;;%1 pozycji;%1 pozycji;%1 pozycji';
			|tr = ';%1 pozisyon;;%1 pozisyonlar;%1 pozisyonun;%1 pozisyonlar'"), 
		Parameters.NumberOfRows,, "NG=0");
	
	Return TrimAll(Text);
	
EndFunction

Function PaymentStatusPresentation(Parameters) Export
	
	Text = "";
	
	If Parameters.PaymentStatus = 0 Then
		Text = NStr("vi = 'Chờ xác nhận';
					|ru = 'Ожидается подтверждение';
					|en = 'Pending confirmation'; fa = 'در انتظار تصدیق';
					|it = 'Conferma in attesa';
					|pl = 'Jest oczekiwane potwierdzenie';
					|tr = 'Onay bekleniyor'");
	Else
		Text = NStr("vi = 'Đã thanh toán';
					|ru = 'Оплачено';
					|en = 'Paid'; fa = 'پرداخت‌شده';
					|it = 'Pagato';
					|pl = 'Opłacono';
					|tr = 'Ödendi'");
	EndIf;
	
	Return Text;
	
EndFunction




Procedure CreateCourierCashRegister(ReferenceOrder, AmountToPay, Cancel) Export
	
	SetPrivilegedMode(True);
	
	DocumentPayments = Documents.CashAccountReceiptNote.CreateDocument();
	DocumentPayments.Fill(DocumentPaymentPurpose(ReferenceOrder));
	DocumentPayments.Date = Common.CurrentUserDate();
	
	If DocumentPayments.DocumentAmount = 0 Then
		Return;
	EndIf;
	
	DocumentPayments.DocumentAmount = AmountToPay;
	
	If Not ValueIsFilled(DocumentPayments.CashAccount) Then
		
		OrderParameters = Common.ObjectAttributesValues(ReferenceOrder, "Courier, Organization");
		OrderParameters.Insert("ReferenceOrder", ReferenceOrder);
		
		DocumentPayments.CashAccount = CourierOrganizationSCashRegisterForICO(OrderParameters) 
	EndIf;
	
	Try
		If DocumentPayments.CheckFilling() Then
			DocumentPayments.Write(DocumentWriteMode.Posting);
		Else
			Cancel = True;
		EndIf;
	Except
		Cancel = True;
		ErrorText = NStr("vi = 'Đã kết chuyển chứng từ %1 bị lỗi';
						|ru = 'Проведение документа %1 завершено с ошибкой';
						|en = 'An error occurred when posting document %1'; fa = 'An error occurred when posting document %1';
						|it = 'La pubblicazione del documento %1 è stata eseguita con errori';
						|pl = 'Zatwierdzenie dokumentu %1 zostało zakończone z błędem';
						|tr = 'Belge kaydetme %1 hata ile tamamlandı'");
		ErrorText = StrTemplate(ErrorText, DocumentPayments);
		WriteLogEvent(ErrorText,
					EventLogLevel.Error,,,
					DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Procedure CreateAcquiringOperation(ReferenceOrder, AmountToPay, Cancel) Export
	
	SetPrivilegedMode(True);
	
	DocumentPayments = Documents.PaymentCardTransaction.CreateDocument();
	DocumentPayments.Fill(DocumentPaymentPurpose(ReferenceOrder));
	DocumentPayments.Date = Common.CurrentUserDate();
	
	If DocumentPayments.DocumentAmount = 0 Then
		Return;
	EndIf;
	
	DocumentPayments.DocumentAmount = AmountToPay;
	
	DocumentPayments.Partner = ReferenceOrder.Partner;
	DocumentPayments.Counterparty = ReferenceOrder.Counterparty;
	
	AcquiringTerminalData = DataOfCourierOrganizationSAcquiringTerminal(ReferenceOrder);
	
	If AcquiringTerminalData <> Undefined Then
		DocumentPayments.AcquiringContract = AcquiringTerminalData.Contract;
		DocumentPayments.POSTerminal = AcquiringTerminalData.Terminal;
	EndIf;
	
	Try
		If DocumentPayments.CheckFilling() Then
			DocumentPayments.Write(DocumentWriteMode.Posting)
		EndIf;
	Except
		ErrorText = NStr("vi = 'Đã kết chuyển chứng từ %1 bị lỗi';
						|ru = 'Проведение документа %1 завершено с ошибкой';
						|en = 'An error occurred when posting document %1'; fa = 'An error occurred when posting document %1';
						|it = 'La pubblicazione del documento %1 è stata eseguita con errori';
						|pl = 'Zatwierdzenie dokumentu %1 zostało zakończone z błędem';
						|tr = 'Belge kaydetme %1 hata ile tamamlandı'");
		ErrorText = StrTemplate(ErrorText, DocumentPayments);
		WriteLogEvent(ErrorText,
					EventLogLevel.Error,,,
					DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Procedure IssueReceipt(ReferenceOrder, Cancel) Export
	
	Cancel = Not RetailSales.AddDocumentsByOrderToQueueOfKktChecks(ReferenceOrder);
	
EndProcedure

Function DataOfCourierOrganizationSAcquiringTerminal(OrderParameters) Export
	
	AcquiringTerminalData = Undefined;
	
	Query = New Query;
	
	Query.Text = "SELECT TOP 1
	               |	POSTerminals.Ref AS Terminal,
	               |	POSTerminals.Owner AS Contract,
	               |	POSTerminals.Owner.Counterparty AS Acquirer
	               |FROM
	               |	Catalog.POSTerminals AS POSTerminals
	               |WHERE
	               |	POSTerminals.DeletionMark = FALSE
	               |	AND POSTerminals.Individual = &Courier
	               |	AND POSTerminals.Owner.Organization = &Organization";
	
	Query.SetParameter("Courier", OrderParameters.Courier);
	Query.SetParameter("Organization", OrderParameters.Organization);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	If Not Result.IsEmpty() Then
		Data = Result.Unload()[0];
		AcquiringTerminalData = New Structure;
		AcquiringTerminalData.Insert("Terminal", Data.Terminal);
		AcquiringTerminalData.Insert("Contract", Data.Contract);
		AcquiringTerminalData.Insert("Acquirer", Data.Acquirer);
	EndIf;
	
	Return AcquiringTerminalData;
	
EndFunction

Function DocumentPaymentPurpose(ReferenceOrder)
	
	DocumentBasis = ReferenceOrder;
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	CustomerInvoice.Ref AS Ref,
	|	CustomerInvoice.Date AS Date
	|FROM
	|	Document.CustomerInvoice AS CustomerInvoice
	|WHERE
	|	CustomerInvoice.Posted
	|	AND CustomerInvoice.SalesOrder = &ReferenceOrder
	|
	|ORDER BY
	|	Date DESC";
	
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	If Not Result.IsEmpty() Then
		DocumentBasis = Result.Unload()[0].Ref;
	EndIf;
	
	Return DocumentBasis;
	
EndFunction

#EndRegion

#EndIf
