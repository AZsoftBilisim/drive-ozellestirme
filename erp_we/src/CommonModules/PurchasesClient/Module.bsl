////////////////////////////////////////////////////////////////////////////////
// The module "Purchasing Customer" contains procedures and functions for 
// processing user actions in the process of working with purchase documents.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region ProceduresAndFunctionsForWorkingWithValueSelection

// Procedure-handler for the "initial Selection" event of the "Agreement" form element"
//
// Parameters:
//	Item                   - FormField - form element to process
//	StandardProcessing      - Boolean - 
//	Partner                   - CatalogRef.Partners - link to the partner for which you select an agreement
//	Document                  - DocumentRef - link to the previously selected agreement for initial positioning in the list
//	DocumentDate             - Date - date of the document where the agreement is selected
//	Available for purchase-Boolean - If True, only agreements with the available for Purchase flag set are selected
//	Commission-free agreements-Boolean - If True, only agreements with households are selected. operations " Purchasing from a supplier"
//	StructureOfAdditionalSelection - Structure, Undefined - 
//
Procedure StartSelectingSupplierAgreement(Item,
	                                         StandardProcessing,
	                                         Partner,
	                                         Document,
	                                         DocumentDate='00010101',
	                                         StructureOfAdditionalSelection = Undefined) Export

	StandardProcessing = False;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Document", Document);
	AdditionalParameters.Insert("Item", Item);
	AdditionalParameters.Insert("DocumentDate", DocumentDate);
	
	If Not ValueIsFilled(StructureOfAdditionalSelection) Then
		StructureOfAdditionalSelection = New Structure;
	EndIf;
	For Each ChoiceParameter In Item.ChoiceParameters Do
		StructureOfAdditionalSelection.Insert(StrReplace(ChoiceParameter.Name,"Filter.",""), ChoiceParameter.Value);
	EndDo;
	AdditionalParameters.Insert("StructureOfAdditionalSelection", StructureOfAdditionalSelection);
	
	If Not ValueIsFilled(Partner) Then
		
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("Filter", New Structure("Vendor", True));
		
		OpenForm(
			"Catalog.Partners.ChoiceForm",
			FilterStructure1 ,,,,,
			New CallbackDescription("StartSelectingSupplierAgreementSelectPartnerEnd", PurchasesClient, AdditionalParameters));
		
	Else
		StartSelectingSupplierAgreementSelectPartnerEnd(Partner, AdditionalParameters);
	EndIf;
	
EndProcedure

// Checks whether the details required to fill in the prices in the document under the agreement with the supplier are complete.
//
// Parameters:
//  Partner                 - CatalogRef.Partners -  the partner for which agreements are selected.
//  AdditionalParameters - Structure - additional parameters for the selection of agreements.
//
Procedure StartSelectingSupplierAgreementSelectPartnerEnd(Partner, AdditionalParameters) Export
	
	If Not ValueIsFilled(Partner) Then
		Return;
	EndIf;
	
	If ValueIsFilled(AdditionalParameters.StructureOfAdditionalSelection) Then
		FilterStructure1 = AdditionalParameters.StructureOfAdditionalSelection;
		FilterStructure1.Insert("Partner", Partner);
	Else
		FilterStructure1 = New Structure("Partner", Partner);
	EndIf;
	
	OpenForm (
		"Catalog.TermsOfPurchaseFromVendors.ChoiceForm",
		New Structure("DocumentDate,CurrentRow,Filter",
			AdditionalParameters.DocumentDate,
			AdditionalParameters.Document,
			FilterStructure1),
		AdditionalParameters.Item);
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForCheckingAbilityToPerformActions

// Checks whether the notification in the form is an event for changing payment documents
//
// Parameters:
//  EventName - String - name of the event from the procedure in the "message Processing" form.
//
// Returns:
//  Boolean - True if the notification is a payment.
//
Function SupplierPaymentDocumentsChanged(EventName) Export
	
	Return
		EventName = "Write_ExpenseReport"
		Or EventName = "Write_BankAccountIssue"
		Or EventName = "Write_BankAccountReceiptNote"
		Or EventName = "Write_CashVoucher"
		Or EventName = "Write_ARAPSettlement"
		Or EventName = "Write_DebtCancellation";
	
EndFunction

#EndRegion

#Region ProceduresForNotifyingUserOfCompletedActions

// Displays a notification to the user when the default purchase conditions are completed.
//
Procedure NotifyEndOfFillingInDefaultPurchaseConditions() Export

	ShowUserNotification(
		NStr("vi = 'Điều kiện mua hàng đã điền';
			|ru = 'Условия закупок заполнены';
			|en = 'Purchase conditions are filled in'; fa = 'Purchase conditions are filled in';
			|it = 'Condizioni di acquisto compilate';
			|pl = 'Warunki zakupów są wypełnione';
			|tr = 'Satın alma koşulları dolduruldu'"),
		,
		NStr("vi = 'Đã điền điều kiện mua hàng theo mặc định';
			|ru = 'Условия закупок по умолчанию заполнены';
			|en = 'Default purchase conditions are filled in'; fa = 'Default purchase conditions are filled in';
			|it = 'Condizioni di acquisto da impostazione predefinita compilate';
			|pl = 'Warunki zakupów domyślnie są wypełnione';
			|tr = 'Satın alma koşulları varsayılan olarak dolduruldu'"),
		PictureLib.Information32);

EndProcedure

// Displays a notification to the user when the purchase conditions are completed
//
Procedure NotifyEndOfFillingInTermsOfPurchase() Export

	ShowUserNotification(
		NStr("vi = 'Đã điền điều kiện mua hàng';
			|ru = 'Условия закупок заполнены';
			|en = 'Purchase conditions are filled in'; fa = 'Purchase conditions are filled in';
			|it = 'Condizioni di acquisto compilate';
			|pl = 'Warunki zakupów są wypełnione';
			|tr = 'Satın alma koşulları dolduruldu'"),
		,NStr("vi = 'Đã điền điều kiện mua hàng theo thỏa thuận với nhà cung cấp';
				|ru = 'Условия закупок по соглашению с поставщиком заполнены';
				|en = 'Terms of purchase are filled in'; fa = 'Terms of purchase are filled in';
				|it = 'Condizioni di acquisto in base ad accordo con il fornitore compilate';
				|pl = 'Warunki zakupów w porozumieniu z dostawcą są wypełnione';
				|tr = 'Satın alma koşulları satın alma koşullarına göre dolduruldu'"),
		PictureLib.Information32);

EndProcedure

// Displays a notification to the user about the end of filling in prices according to the agreement with the client.
//
// Parameters:
//	PricesCalculated - Boolean - Indicates that prices were calculated successfully in at least one line.
//	ErrorText - String - Description of the error when calculating prices.
//
Procedure NotifyAboutEndOfFillingInPricesUnderAgreement(PricesCalculated = True, ErrorText = "") Export

	If PricesCalculated Then
		ShowUserNotification(
			NStr("vi = 'Đã điền đơn giá';
				|ru = 'Цены заполнены';
				|en = 'Prices are filled out'; fa = 'Prices are filled out';
				|it = 'I prezzi sono compilati';
				|pl = 'Wypełniono ceny';
				|tr = 'Fiyatlar dolduruldu'"),
			,
			NStr("vi = 'Đã điền đơn giá theo thỏa thuận với nhà cung cấp';
				|ru = 'Цены по соглашению с поставщиком заполнены';
				|en = 'Prices according to terms of purchase are filled in'; fa = 'Prices according to terms of purchase are filled in';
				|it = 'Prezzi da accordo con il fornitore compilati';
				|pl = 'Ceny w porozumieniu z dostawcą są wypełnione';
				|tr = 'Satın alma koşullarına göre fiyatlar dolduruldu'"),
			PictureLib.Information32);
	Else
		MessageText = NStr("vi = 'Chưa điền đơn giá theo thỏa thuận với nhà cung cấp vào dòng nào.';
							|ru = 'Ни в одной строке цены по соглашению с поставщиком не заполнены.';
							|en = 'Prices according to the terms of purchase are not filled in any lines.'; fa = 'Prices according to the terms of purchase are not filled in any lines.';
							|it = 'I prezzi da accordo con i fornitori sono compilati in tutte le stringhe.';
							|pl = 'W żadnym wierszu ceny w porozumieniu z dostawcą nie są wypełnione.';
							|tr = 'Satırların hiçbirinde satın alma koşullarına göre fiyatlar doldurulmadı.'");
		If Not IsBlankString(ErrorText) Then
			MessageText = MessageText + Chars.LF + ErrorText;
		EndIf;

		ShowUserNotification(
			NStr("vi = 'Chưa điền đơn giá';
				|ru = 'Цены не заполнены';
				|en = 'Prices are not filled in'; fa = 'Prices are not filled in';
				|it = 'I prezzi non sono compilati';
				|pl = 'Nie wypełniono ceny';
				|tr = 'Fiyatlar doldurulmadı'"),
			,
			MessageText,
			PictureLib.Information32);
	EndIf;
	
EndProcedure

// Displays a notification to the user about the end of filling in the receipt dates for all PM lines.
//
// Parameters:
//	DateOfReceipt - Date - the shipment date for which the date was filled in in the table part
//	FillingSelectedRows - Boolean - affects the message text.
//
Procedure NotifyAboutEndOfFillingInReceiptDates(DateOfReceipt, FillingSelectedRows) Export

	If FillingSelectedRows Then
		
		ShowUserNotification(
			NStr("vi = 'Đã điền ngày tiếp nhận';
				|ru = 'Дата поступления заполнена';
				|en = 'Date of receipt filled in'; fa = 'Date of receipt filled in';
				|it = 'Data del versamento compilata';
				|pl = 'Data wpłaty jest wypełniona';
				|tr = 'Giriş tarihi dolduruldu'"),
			,
			StrReplace(NStr("vi = 'Đối với tất cả các dòng được chọn đã đặt ngày tiếp nhận %DateOfReceipt%';
							|ru = 'Для выделенных строк установлена дата поступления %DateOfReceipt%';
							|en = 'Date of receipt %DateOfReceipt% is set for the selected lines'; fa = 'Date of receipt %DateOfReceipt% is set for the selected lines';
							|it = 'Per le righe selezionate è stata impostata la data del versamento %DateOfReceipt%';
							|pl = 'Dla zaznaczonych wierszy jest określona data wpłaty %DateOfReceipt%';
							|tr = 'Seçili satırlar için, giriş tarihi %DateOfReceipt% olarak ayarlandı'"), "%DateOfReceipt%", Format(DateOfReceipt, "DLF=D")),
			PictureLib.Information32);
		
	Else
		
		ShowUserNotification(
			NStr("vi = 'Đã điền ngày tiếp nhận';
				|ru = 'Дата поступления заполнена';
				|en = 'Date of receipt filled in'; fa = 'Date of receipt filled in';
				|it = 'Data del versamento compilata';
				|pl = 'Data wpłaty jest wypełniona';
				|tr = 'Giriş tarihi dolduruldu'"),
			,
			StrReplace(NStr("vi = 'Đối với tất cả dòng đã đặt ngày tiếp nhận %DateOfReceipt%';
							|ru = 'Для всех строк установлена дата поступления %DateOfReceipt%';
							|en = 'Date of receipt %DateOfReceipt% is set for all lines'; fa = 'Date of receipt %DateOfReceipt% is set for all lines';
							|it = 'Data del versamento %DateOfReceipt% impostata per tutte le righe';
							|pl = 'Dla wszystkich wierszy jest określona data wpłaty %DateOfReceipt%';
							|tr = 'Tüm satırlar, %DateOfReceipt% giriş tarihi şeklinde ayarlandı'"), "%DateOfReceipt%", Format(DateOfReceipt, "DLF=D")),
			PictureLib.Information32);
		
	EndIf;
	
EndProcedure

// Displays a notification to the user about the end of re-filling of products after actual acceptance.
//
// Parameters:
//	HasChanges           - Boolean - If True, there are changes in the table part
//	RefilledQuantity - Boolean - If True, the quantity was re-filled at the actual acceptance.
//
Procedure NotifyAboutEndOfReplenishmentOfGoodsForAcceptance(HasChanges, RefilledQuantity) Export
	
	If HasChanges Then
		
		ShowUserNotification(
			NStr("vi = 'Đã điền lại số lượng';
				|ru = 'Количество перезаполнено';
				|en = 'Refilled quantity'; fa = 'Refilled quantity';
				|it = 'La quantità è ricompilata';
				|pl = 'Ponowne wypełnienie ilości.';
				|tr = 'Miktar yeniden dolduruldu'"),
			,
			NStr("vi = 'Trong các dòng điền lại số lượng.';
				|ru = 'В строках перезаполнено количество.';
				|en = 'Quantity is refilled in lines.'; fa = 'Quantity is refilled in lines.';
				|it = 'La quantità nelle righe è stata ricompilata.';
				|pl = 'W wierszach jest ponownie wypełnona ilość.';
				|tr = 'Satırlarda miktar yeniden dolduruldu.'"),
			PictureLib.Information32);
		
	Else
		
		If RefilledQuantity Then
			
			ShowUserNotification(
				NStr("vi = 'Không cần điền lại';
					|ru = 'Перезаполнение не требуется';
					|en = 'You do not need to refill'; fa = 'You do not need to refill';
					|it = 'Reseeding non richiesto';
					|pl = 'Ponowne wypełnienie nie jest potrzebne';
					|tr = 'Yeniden doldurma gerekmiyor'"),
				,
				NStr("vi = 'Không cần điền lại, bởi vì trong tất cả các dòng số lượng trùng với số lượng đã chỉ ra.';
					|ru = 'Перезаполнение не требуется, т.к. во всех строках количество совпадает с указанным.';
					|en = 'Repopulation is not required as the quantity in all lines matches the specified one.'; fa = 'Repopulation is not required as the quantity in all lines matches the specified one.';
					|it = 'Non è richiesta la ricompilazione, poiché in tutte le righe la quantità coincide con quella indicata.';
					|pl = 'Ponowne wypełnienie nie jest potrzebne, ponieważ we wszystkich wierszach ilość jest zbieżna ze wskazaną.';
					|tr = 'Yeniden doldurma gerekli değildir, çünkü tüm satırlarda miktar belirtilenle aynıdır.'"),
				PictureLib.Information32);
			
		Else
		
			ShowUserNotification(
				NStr("vi = 'Không cần điền lại';
					|ru = 'Перезаполнение не требуется';
					|en = 'You do not need to refill'; fa = 'You do not need to refill';
					|it = 'Reseeding non richiesto';
					|pl = 'Ponowne wypełnienie nie jest potrzebne';
					|tr = 'Yeniden doldurma gerekmiyor'"),
				,
				NStr("vi = 'Không theo một dòng nào chưa bắt đầu tiếp nhận.';
					|ru = 'Ни по одной строке не начата приемка.';
					|en = 'Receiving is not started in any line.'; fa = 'Receiving is not started in any line.';
					|it = 'Accettazione iniziata per tutte le righe';
					|pl = 'W źadnym wierszu odbiór nie jest rozpoczęty.';
					|tr = 'Hiçbir satır için kabul başlatılmadı.'"),
				PictureLib.Information32);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region ProceduresForProcessingUserCommands

// Generates a list of rooms to choose from GTE with the selection of the nomenclature, characteristics
//
// Parameters:
//	CurrentRow - FormDataCollectionItem - current row in the Products table
//	ChoiceList  - ValueList - the list of rooms to choose from GTE.
//
Procedure FillInListOfCCDNumberSelection(CurrentRow, ChoiceList) Export
	
	If CurrentRow = Undefined Or Not ValueIsFilled(CurrentRow.Products) Then
		ChoiceList.Clear();
	Else
		ValueList = PurchasesServerCall.FillInListOfCCDNumberSelection(
			CurrentRow.Products,
			CurrentRow.Characteristic,
			CurrentRow.OriginCountry);
		
		ChoiceList.Clear();
		For Each CurrRow In ValueList Do
			NewString = ChoiceList.Add();
			FillPropertyValues(NewString,CurrRow);
		EndDo; 
	EndIf;
	
EndProcedure

// Checks whether the details required to fill in the goods for acceptance are filled in.
//
// Parameters:
// 	CallbackDescription - CallbackDescription - 
// 	ThereAreAcceptedGoods - Boolean - indicates whether the accepted products are available.
//
// Returns:
// 	Boolean - False if the user refused to fill in.
//
Function QuestionAboutReFillingWithAcceptedGoods(CallbackDescription, ThereAreAcceptedGoods) Export
	
	ButtonsList = New ValueList();
	
	If ThereAreAcceptedGoods Then
		
		QueryText = NStr("vi = 'Không phải tất cả hàng hóa đều được tiếp nhận. Tính khi điền hàng hóa mà được tiếp nhận?';
						|ru = 'Не все товары приняты. Учитывать при заполнении товары, которые принимаются?';
						|en = 'Not all goods are received. Record goods which are being received while populating?'; fa = 'Not all goods are received. Record goods which are being received while populating?';
						|it = 'Non tutta la merce è stata ricevuta. Prendere in considerazione quando si compilano le merci che sono accettate?';
						|pl = 'Nie wszystkie wiersze pozycji są przyjęte. Uwzględniać podczas wypełnienia wiersze pozycji, które są przyjmowane?';
						|tr = 'Tüm ürünler kabul edilmedi. Kabul edilen ürünleri doldururken dikkate al?'");
		ButtonsList.Add("Consider", NStr("vi = 'Tính đến';
										|ru = 'Учитывать';
										|en = 'Record'; fa = 'ثبت';
										|it = 'Considerare';
										|pl = 'Record';
										|tr = 'Muhasebeleştir'"));
		ButtonsList.Add("DontConsider", NStr("vi = 'Không tính';
											|ru = 'Не учитывать';
											|en = 'Do not record'; fa = 'ثبت نشود';
											|it = 'Non considerare';
											|pl = 'Nie uwzględniać';
											|tr = 'Hesaba katma'"));
		
	Else
		
		QueryText = NStr("vi = 'Thiếu hàng tiếp nhận. Tính khi điền hàng hóa mà được tiếp nhận?';
						|ru = 'Отсутствуют принятые товары. Учитывать при заполнении товары, которые принимаются?';
						|en = 'No received goods. Record the goods being received during population?'; fa = 'No received goods. Record the goods being received during population?';
						|it = 'La merce ricevuta è mancante. Prendere in considerazione quando si compilano le merci che sono accettate?';
						|pl = 'Brak przyjętych towarów. Uwzględniać podczas wypełnienia wiersze pozycji, które są przyjmowane?';
						|tr = 'Kabul edilen ürün mevcut değil. Kabul edilen ürünleri doldururken dikkate al?'");
		ButtonsList.Add("Consider", NStr("vi = 'Tính đến';
										|ru = 'Учитывать';
										|en = 'Record'; fa = 'ثبت';
										|it = 'Considerare';
										|pl = 'Record';
										|tr = 'Muhasebeleştir'"));
		
	EndIf;
	
	ButtonsList.Add("NotReFill_", NStr("vi = 'Không điền lại';
										|ru = 'Не перезаполнять';
										|en = 'Do not refill'; fa = 'Do not refill';
										|it = 'Non ricompilare';
										|pl = 'Nie wypełniaj ponownie';
										|tr = 'Yeniden doldurma'"));
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
	ShowQueryBox(
		New CallbackDescription("QuestionAboutReFillingWithAcceptedGoodsCompletion", PurchasesClient, AdditionalParameters),
		QueryText,
		ButtonsList);
	
EndFunction

// Handler for completing the response to the question of re-filling with accepted products.
//
// Parameters:
//  UserAnswer           - String - the answer to the question selected by the user.
//  AdditionalParameters - Structure - advanced setting.
//
Procedure QuestionAboutReFillingWithAcceptedGoodsCompletion(UserAnswer, AdditionalParameters) Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("FillInAcceptedProducts", (UserAnswer = "Consider"));
	ReturnValue.Insert("Result", (UserAnswer <> "NotReFill_"));
	
	RunCallback(AdditionalParameters.CallbackDescription, ReturnValue);
	
EndProcedure

// Opens the report dynamics of changes in the supplier's price Nomenclature with selection from the form
//
// Parameters:
//	Form - ClientApplicationForm - the form of the document that opens the report.
//
Procedure OpenSupplierPriceDynamicsReport(Form) Export
	
	ItemList  = New ValueList;
	ListOfCharacteristics = New ValueList;
	For Each IDOfPriceTreeRow In Form.Items.PriceTree.SelectedRows Do
		TSRow = Form.PriceTree.FindByID(IDOfPriceTreeRow);
		ItemList.Add(TSRow.Products);
		If TSRow.ItemVariantsAreUsed Then
			If TSRow.GetParent() = Undefined Then
				For Each StringCharacteristic In TSRow.GetItems() Do
					If ListOfCharacteristics.FindByValue(StringCharacteristic.Characteristic) = Undefined Then
						ListOfCharacteristics.Add(StringCharacteristic.Characteristic);
					EndIf;
				EndDo;
			Else
				If ListOfCharacteristics.FindByValue(TSRow.Characteristic) = Undefined Then
					ListOfCharacteristics.Add(TSRow.Characteristic);
				EndIf;
			EndIf;
		Else
			If ListOfCharacteristics.FindByValue(
					PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef")) = Undefined Then
				ListOfCharacteristics.Add(PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
			EndIf;
		EndIf;
	EndDo;
	
	ListOfPriceTypes = New ValueList;
	For Each PriceTypeLine In SettingPricesClientServer.SelectedRowsInPriceViewTable(Form) Do
		ListOfPriceTypes.Add(PriceTypeLine.Ref, PriceTypeLine.Description);
	EndDo;
	
	Filter = New Structure;
	Filter.Insert("Products", ItemList);
	Filter.Insert("Characteristic", ListOfCharacteristics);
	Filter.Insert("VendorPriceKind", ListOfPriceTypes);
	Filter.Insert("Partner", Form.Object.Partner);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("PurposeUseKey", "TrendOfPriceChangesByNomenclatureChart");
	FormParameters.Insert("VariantKey", "TrendOfPriceChangesByNomenclatureChart");
	FormParameters.Insert("GenerateOnOpen", True);
	
	OpenForm("Report.PriceChangeTrendsOfVendorPartNumbers.Form",
	        FormParameters);
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfWorkingWithSupplierProductsInProcurementDocuments

// Opens the form for filling in an item for the supplier's item.
//
// Parameters:
// 	CallbackDescription     - CallbackDescription - description of the alert.
// 	GoodsAddressInStorage - String - address of products in storage.
// 	Form                  - ClientApplicationForm - owner of the form to open.
// 	FilterItemsType - Undefined, Array - Selection item type
Procedure OpenSupplierProductListForm(CallbackDescription, GoodsAddressInStorage, Form, FilterItemsType = Undefined) Export
	
	If GoodsAddressInStorage = Undefined Then
		
		ShowMessageBox(,NStr("vi = 'Không có dòng, trong đó đã chỉ ra mặt hàng của nhà cung cấp, tuy nhiên chưa chỉ ra mặt hàng';
							|ru = 'Отсутствуют строки, в которых указана номенклатура поставщика, но не указана номенклатура';
							|en = 'No lines are found that have vendor part numbers but no products'; fa = 'No lines are found that have vendor part numbers but no products';
							|it = 'Mancano le righe in cui è indicato l''articolo del fornitore ma non l''articolo stesso';
							|pl = 'Nie ma wierszy, w których jest wskazana nomenklatura dostawcy, ale nie są wskazane nomenklatury';
							|tr = 'Satıcı parça numaralarının belirtildiği ancak hiçbir öğenin belirtilmediği satırlar eksik'"));
		RunCallback(CallbackDescription, Undefined);
		Return;
		
	EndIf;
	
	FormParameters = New Structure("GoodsAddressInStorage", GoodsAddressInStorage);
	If ValueIsFilled(FilterItemsType) Then
		FormParameters.Insert("FilterItemsType",FilterItemsType);
	EndIf;
	
	OpenForm(
		"CommonForm.ItemsFillingByVendorPartNumbers",
		FormParameters,
		Form,,,,
		CallbackDescription);
	
EndProcedure

#EndRegion

#Region ProceduresAndFunctionsOfWorkingWithCCDNumbers

// Constructor for the collection of parameters for creating the default helpdesk 'Number' element.
//
// Returns:
//	Structure - a collection that contains the following properties:
//		* Code - String - the number of CCD.
//		* ProductData_8 - Structure - product information containing the following data:
//			** Products - CatalogRef.Products - information about the nomenclature.
//			** Characteristic - CatalogRef.ItemsCharacteristics - information about the characteristics of the Product.
//			** Package - CatalogRef.PackagesAndUnitsOfMeasure - information about the product packaging.
//			** KitCount - Number - amount of goods.
//			** AmountByProductBatchID - Number - the cost of the product.
//		* OriginCountry - CatalogRef.WorldCountries - information about the country of origin of the goods.
//		* Date - Date- document date.
//		* DocumentCurrency - CatalogRef.Currencies - the currency of the document.
//		* CreatingElementOfAnyType - Boolean - indicates that the Catalog item being created does not depend on the settings
//												for using traceability tracking and the item traceability attribute.
//		* ShowCostByDocument - Boolean - indicates whether the document uses summary indicators.
//		* UseTraceableImportedGoodsAccounting - Boolean - indicates whether tracking of traceable imported
//																	goods is used.
//
Function DefaultCCDNumberCreationParameters() Export
	
	ProductData_8 = New Structure;
	ProductData_8.Insert("Products",			PredefinedValue("Catalog.Products.EmptyRef"));
	ProductData_8.Insert("Characteristic",			PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	ProductData_8.Insert("Package",				PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	ProductData_8.Insert("KitCount",	0);
	ProductData_8.Insert("AmountByProductBatchID",			0);
	
	CreationParameters = New Structure;
	CreationParameters.Insert("Code",					"");
	CreationParameters.Insert("ProductData_8",			ProductData_8);
	CreationParameters.Insert("OriginCountry",	PredefinedValue("Catalog.WorldCountries.EmptyRef"));
	CreationParameters.Insert("Date",					Date(1, 1, 1));
	CreationParameters.Insert("DocumentCurrency",		PredefinedValue("Catalog.Currencies.EmptyRef"));
	CreationParameters.Insert("CreatingElementOfAnyType",	False);
	CreationParameters.Insert("ShowCostByDocument",	False);
	CreationParameters.Insert("UseTraceableImportedGoodsAccounting", False);
	
	Return CreationParameters;
	
EndFunction

// Returns the default parameters used to initialize the parameters for filling in the 'GTD Number' Catalog element.
//
// Returns:
//	Structure - a collection that contains the following properties:
//		* Date - Date- document date.
//		* DocumentCurrency - CatalogRef.Currencies - the currency of the document.
//		* FieldNameQuantity - String - the name of the field containing information about the number of product packages in the parameter collection
//										The (See ParametersForCreatingCCDNumber)
//                                 current line .
//		* NameOfAmountField - String - name of the field containing information about the amount of the item in the parameter collection
//									The (See ParametersForCreatingCCDNumber)
//                            current line .
//		* NameOfVATAmountField_ - String - name of the field containing information about the VAT amount of the item in the parameter collection
//										The (See ParametersForCreatingCCDNumber)
//                               current line .
//		* NameOfAmountFieldWithVAT - String - the name of the field that contains information about the amount including VAT of the item in the parameter collection
//										The (See ParametersForCreatingCCDNumber)
//                                current line .
//		* BasisOfCostOfAdmission - Boolean - a sign that the document is the basis for determining
//													the cost of receiving goods.
//		* UseTraceableImportedGoodsAccounting - Boolean - indicates whether tracking of traceable imported
//																	goods is used.
//
Function AdditionalParametersForCreatingCCDNumber() Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Date			",		Date(1, 1, 1));
	AdditionalParameters.Insert("DocumentCurrency",		PredefinedValue("Catalog.Currencies.EmptyRef"));
	AdditionalParameters.Insert("FieldNameQuantity",	"NumberOfPackages");
	AdditionalParameters.Insert("NameOfAmountField",		"Sum");
	AdditionalParameters.Insert("NameOfVATAmountField_",		"VATAmount");
	AdditionalParameters.Insert("NameOfAmountFieldWithVAT",	"AmountIncludingVAT");
	AdditionalParameters.Insert("BasisOfCostOfAdmission", True);
	AdditionalParameters.Insert("UseTraceableImportedGoodsAccounting", False);
	
	Return AdditionalParameters;
	
EndFunction

// Returns the parameters used during creation to fill in the directory element 'NomeraGTD'.
//
// Parameters:
//	CurrentRow - Structure, FormDataCollectionItem - collection containing product information:
//					* Products - CatalogRef.Products - information about the nomenclature.
//					* Characteristic - CatalogRef.ItemsCharacteristics - information about the characteristics of the Product.
//					* Package - CatalogRef.PackagesAndUnitsOfMeasure - information about the product packaging.
//					* OriginCountry - CatalogRef.WorldCountries - information about the country of origin of the goods.
//	EditText - String - the text of editing the field of the GTD Number form.
//	AdditionalParameters - See AdditionalParametersForCreatingCCDNumber.
//
// Returns:
//	See DefaultCCDNumberCreationParameters.
//
Function ParametersForCreatingCCDNumber(CurrentRow, EditText, AdditionalParameters = Undefined) Export
	
	If AdditionalParameters = Undefined Then
		AdditionalParameters = AdditionalParametersForCreatingCCDNumber();
	EndIf;
	
	CreationParameters	= DefaultCCDNumberCreationParameters();
	ProductData_8		= CreationParameters.ProductData_8;
	
	FillPropertyValues(CreationParameters, AdditionalParameters);
	
	CreationParameters.Code = EditText;

	If CurrentRow <> Undefined Then
		FillPropertyValues(ProductData_8, CurrentRow);
		FillPropertyValues(CreationParameters, CurrentRow);
		
		If CurrentRow.Property(AdditionalParameters.FieldNameQuantity) Then
			ProductData_8.KitCount = CurrentRow[AdditionalParameters.FieldNameQuantity];
		EndIf;
		
		If AdditionalParameters.BasisOfCostOfAdmission Then
			CreationParameters.ShowCostByDocument = True;
			
			If CurrentRow.Property(AdditionalParameters.NameOfVATAmountField_)
				And CurrentRow.Property(AdditionalParameters.NameOfAmountFieldWithVAT) Then
				
				ProductData_8.AmountByProductBatchID = CurrentRow[AdditionalParameters.NameOfAmountFieldWithVAT]
											- CurrentRow[AdditionalParameters.NameOfVATAmountField_];
				
			ElsIf CurrentRow.Property(AdditionalParameters.NameOfAmountField) Then
				ProductData_8.AmountByProductBatchID = CurrentRow[AdditionalParameters.NameOfAmountField];
			Else
				CreationParameters.ShowCostByDocument = False;
			EndIf;
		Else
			CreationParameters.ShowCostByDocument = False;
		EndIf;
	EndIf;
	
	Return CreationParameters;
	
EndFunction

// Opens the form for creating the directory item 'NomeraGTD'.
//
// Parameters:
//	Form - ClientApplicationForm - the form in which the command to create a GTD Number is called.
//	CreationParameters - See ParametersForCreatingCCDNumber
//
Procedure OpenFormForCreatingGTDNumber(Form, CreationParameters) Export
	
	FormParameters = New Structure("CreationParameters", CreationParameters);
	
	If CreationParameters.UseTraceableImportedGoodsAccounting Then
		FormName = "DataProcessor.SelectCCDNumbersToDocuments.Form.Form";
	Else
		FormName = "Catalog.CCDNumbers.Form.ItemForm";
	EndIf;
	
	OpenForm(FormName, FormParameters, Form, Form.UUID);
	
EndProcedure

// Checks that the form that performed the value selection notification is the form
// of the directory element 'NomeraGTD'.
//
// Parameters:
//	ChoiceSource - Arbitrary - the parameter of the event processing the selection of the form in which the value was selected.
//
// Returns:
//	Boolean - returns the value True if the selection of the directory element 'NomeraGTD' is made.
//
Function ThisIsIndicationOfCCDNumber(ChoiceSource) Export
	
	Return ChoiceSource.FormName = "Catalog.CCDNumbers.Form.ItemForm";
	
EndFunction

// Returns parameters for processing the selection of the form value of the directory element 'NomeraGTD'.
//
// Returns:
//	Structure - a collection that contains the following properties:
//		* TSName - String - the name of the tabular part in which the value of the GTD number is indicated.
//		* FieldNameCCDNumber - String - the name of the GTD number field in which the value is specified.
//		* FieldNameCountryOfOrigin - String - the name of the country of origin field, which indicates the country
//												of origin of the imported goods in accordance with the GTD.
//
Function ParametersForSpecifyingCCDNumber() Export
	
	ParametersForSpecifyingCCDNumber  = New Structure;
	ParametersForSpecifyingCCDNumber.Insert("TSName", "Goods");
	ParametersForSpecifyingCCDNumber.Insert("FieldNameCCDNumber", "CCDNumber");
	ParametersForSpecifyingCCDNumber.Insert("FieldNameCountryOfOrigin", "OriginCountry");
	
	Return ParametersForSpecifyingCCDNumber;
	
EndFunction

// Specifies the values of the CCD number and service Attributes in the tabular part of the form.
//
// Parameters:
//	Form - ClientApplicationForm - The Form in which the CCD number was initiated, which contains the following properties:
//		* Items - FormAllItems - form element.
//	CCDNumber - CatalogRef.CCDNumbers, Undefined - the value of the selection.
//	ParametersForSpecifyingCCDNumber - See ParametersForSpecifyingCCDNumber
//	CurrentData - Structure, FormDataCollectionItem - the data of the line in which the GTD number is indicated,
//																if the value is not passed, then the current
//																data of the table with the name parametersthe GTD number is used.Imyatch.
//	ProcessingActions - Structure - parameters of the actions that need to be performed to process the rows of the table part
//									in which the CCD numbers are filled in.
//
Procedure ProcessIndicationOfCCDNumber(Form,
										CCDNumber,
										ParametersForSpecifyingCCDNumber = Undefined,
										CurrentData = Undefined,
										ProcessingActions = Undefined) Export
	
	If Not ValueIsFilled(CCDNumber) Then
		Return;
	EndIf;
	
	If ParametersForSpecifyingCCDNumber = Undefined Then
		ParametersForSpecifyingCCDNumber = ParametersForSpecifyingCCDNumber();
	EndIf;
	
	TSName = ParametersForSpecifyingCCDNumber.TSName;
	
	If CurrentData = Undefined Then
		CurrentData = Form.Items[TSName].CurrentData;
	EndIf;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.CCDNumber = CCDNumber;
	
	If ProcessingActions = Undefined Then
		ProcessingActions = New Structure;
	EndIf;
	
	If CurrentData.Property("OriginCountry") Then
		CountryOfOriginFillingParameters = New Structure("CCDNumber", CCDNumber);
		
		ProcessingActions.Insert("FillInCountryOfOriginForCCDNumber", CountryOfOriginFillingParameters);
	EndIf;
	
	If CurrentData.Property("CCDNumberType") Then
		ParametersForFillingInCCDNumberType = New Structure("CCDNumber", CCDNumber);
		
		ProcessingActions.Insert("FillInCCDNumberType", ParametersForFillingInCCDNumberType);
	EndIf;
	
	If ProcessingActions.Count() > 0 Then
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, ProcessingActions, Undefined);
	EndIf;
	
EndProcedure

// Verifies that the form that performed the notification is a CCD number matching form.
//
// Parameters:
//	ChoiceSource - Arbitrary - the parameter of the event processing the selection of the form in which the value was selected.
//
// Returns:
//	Boolean - returns the value True if the selection of the directory element 'NomeraGTD' is made.
//
Function ThisIsSelectionOfCCDNumber(ChoiceSource) Export
	
	Return ChoiceSource.FormName = "DataProcessor.SelectCCDNumbersToDocuments.Form.Form";
	
EndFunction

// Displays a notification to the user about filling in the GTD numbers in the rows of the table part of the document.
//
// Parameters:
//	CCDNumbersFilledIn - Boolean - indicates that the table part has been filled in.
//	CCDNumber - CatalogRef.CCDNumbers - the value of the fill.
//
Procedure NotifyAboutFillingInGTNumbersInTabularPart(CCDNumbersFilledIn, CCDNumber = Undefined) Export
	
	If CCDNumbersFilledIn <> Undefined
		And CCDNumbersFilledIn Then
		
		NotificationText1 = NStr("vi = 'Đã điền số tờ khai hải quan';
								|ru = 'Номера ГТД заполнены';
								|en = 'CCD numbers are filled in'; fa = 'CCD numbers are filled in';
								|it = 'I numeri delle dichiarazioni doganali di carico sono compilati';
								|pl = 'Wprowadzono numery towarowej deklaracji celnej';
								|tr = 'GKB numarası dolduruldu'");
		
		ExplanationText = NStr("vi = 'Trong các dòng của chứng từ đã điền số tờ khai hải quan';
								|ru = 'В строках документа заполнены номера ГТД';
								|en = 'CCD numbers are filled in the document lines'; fa = 'CCD numbers are filled in the document lines';
								|it = 'Nelle righe del documento i numeri delle dichiarazioni doganali di carico sono compilati';
								|pl = 'W wierszach dokumentu wypełniono numery towarowej deklaracji celnej';
								|tr = 'Belgenin satırlarında GKB numarası dolduruldu'");
		
		If ValueIsFilled(CCDNumber) Then
			ExplanationText = NStr("vi = 'Trong các dòng của chứng từ đã điền số tờ khai hải quan %1';
									|ru = 'В строках документа заполнен номер ГТД %1';
									|en = 'The %1 CCD number is filled in document lines'; fa = 'The %1 CCD number is filled in document lines';
									|it = 'Nelle righe del documento è compilato il numero di Dichiarazione Doganale di Carico%1';
									|pl = 'W wierszach dokumentu jest wypełniony numerem LP %1';
									|tr = 'Belge satırlarında Gümrük Kargo Beyannamesi numarası dolduruldu %1'");
			ExplanationText = StrTemplate(ExplanationText, String(CCDNumber));
		EndIf;
		
		ShowUserNotification(NotificationText1, , ExplanationText, PictureLib.Information32);
		
	Else
		NotificationText1	= NStr("vi = 'Chưa điền số tờ khai hải quan';
									|ru = 'Номера ГТД не заполнены';
									|en = 'CCD numbers are required'; fa = 'CCD numbers are required';
									|it = 'I numeri delle dichiarazioni doganali di carico non sono compilati';
									|pl = 'Nie wypełniono numerów towarowej deklaracji celnej';
									|tr = 'GKB numarası doldurulmadı'");
		ExplanationText	= NStr("vi = 'Chưa điền số tờ khai hải quan tại bất kỳ dòng nào';
									|ru = 'Ни в одной строке номер ГТД не заполнен';
									|en = 'No lines have CCD numbers filled in'; fa = 'No lines have CCD numbers filled in';
									|it = 'Il numero della dichiarazione doganale di carico non è compilato in alcuna riga';
									|pl = 'W żadnym wierszu nie wypełniono numerów towarowej deklaracji celnej';
									|tr = 'Hiç bir satırda Gümrük Kargo Beyannamesi numarası doldurulmadı'");
		
		ShowUserNotification(NotificationText1, , ExplanationText, PictureLib.Information32);
	EndIf;
	
EndProcedure

#Region ProceduresAndFunctionsOfWorkingWithComponentsOfCCDRooms

// The service handler for auto-dialing the CCD Number.
//
// Parameters:
//	Text - String - the text of the search string.
//	ChoiceData - ValueList of Structure - a list of Catalog item data selections.
//	StandardProcessing - Boolean - this parameter is passed a sign of performing object data matching.
//										If you set this parameter
//										to False in the body of the handler procedure, the standard event processing will not be performed.
//	CurrentRef - CatalogRef.CCDNumbers - a link to the Cur element of the Catalog card of the CCD number.
//
Procedure CCDNumbersCodeOfComponentAutoSelection(Text, ChoiceData, StandardProcessing, CurrentRef = Undefined) Export
	
	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	SelectionData_ = New Structure;
	SelectionData_.Insert("CurrentRef",	CurrentRef);
	SelectionData_.Insert("CCDNumberType",	PredefinedValue("Enum.CCDNumberTypes.ProductBatchIDNumber"));
	SelectionData_.Insert("GetAdditionalData", True);
	
	SearchParameters = New Structure;
	SearchParameters.Insert("SearchString",	Text);
	SearchParameters.Insert("Filter",			SelectionData_);
	
	PurchasesServerCall.CCDNumbersProcessingReceiptOfSelectionData(ChoiceData, SearchParameters, StandardProcessing);
	
EndProcedure

#EndRegion

#Region WhenCreatingContractFromDocument

// Opens the form for creating a new Contract with partner data.
//
// Parameters:
//	Form - ClientApplicationForm - the form of the document.
//	Item - FormItems - a form field containing information about the Contract.
//	PathToContract - String - the path to the Attribute with the Contract data.
//	Partner - CatalogRef.Partners - partner data for creating a Contract.
//	StandardProcessing - Boolean - this parameter is passed a sign of performing object data matching.
//	NameOfAlertEvent - String - name of the notification event for the document form when the Contract is changed.
//
Procedure OpenContractCreationForm(Form, Item, PathToContract, Partner, StandardProcessing, NameOfAlertEvent = "WhenChangingAgreement") Export
	
	StandardProcessing = False;
	
	ContractFormName = "Catalog.CounterpartyContracts.Form.ItemForm";
	
	FormParameters = New Structure();
	ChoiceParameters = New Structure();
	
	NamesOfAdditionalSelectionParameters = New Array;
	NamesOfAdditionalSelectionParameters.Add("Terms");
	
	For Each ChoiceParameter In Item.ChoiceParameters Do
		If StrFind(ChoiceParameter.Name,"Filter.") <> 0
			Or NamesOfAdditionalSelectionParameters.Find(ChoiceParameter.Name) <> Undefined Then
			ChoiceParameters.Insert(StrReplace(ChoiceParameter.Name, "Filter.", ""), ChoiceParameter.Value);
		EndIf;
	EndDo;
	
	For Each ChoiceParameter In Item.ChoiceParameterLinks Do
		If StrFind(ChoiceParameter.Name,"Filter.") <> 0
			Or NamesOfAdditionalSelectionParameters.Find(ChoiceParameter.Name) <> Undefined Then
			ParameterValue = TMCommonUseClientServer.DataAlongWay(Form, ChoiceParameter.DataPath);
			KeyName = StrReplace(ChoiceParameter.Name, "Filter.", "");
			If Not ChoiceParameters.Property(KeyName) Then
				ChoiceParameters.Insert(KeyName, ParameterValue);
			EndIf;
		EndIf;
	EndDo;
	
	FormParameters.Insert("Filter",ChoiceParameters);
	
	CreationParameters = CommonClient.CopyRecursive(ChoiceParameters);
	CreationParameters.Insert("Partner", Partner);
	
	FormParameters.Insert("FillingValues",CreationParameters);
	FormParameters.Insert("FillingText", Item.EditText);
	FormParameters.Insert("VerificationWhenCreatingContract", True);
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("Object", Form);
	AdditionalParameters.Insert("Filter", ChoiceParameters);
	AdditionalParameters.Insert("Partner", Partner);
	AdditionalParameters.Insert("PathToContract", PathToContract);
	AdditionalParameters.Insert("NameOfAlertEvent", NameOfAlertEvent);
	
	NotificationOfCreationOfContract = New CallbackDescription("AfterContractIsCreatedEnd", PurchasesClient, AdditionalParameters);
	
	OpenForm(ContractFormName, FormParameters, Form, Form.UUID,,,NotificationOfCreationOfContract);
	
EndProcedure

// Processing the notification after creating the Contract from the document form.
//
//Parameters:
// Result - Structure:
//  *Contract - CatalogRef.CounterpartyContracts - a Contract has been CREATED.
// AdditionalParameters - Structure:
//  *Object - ClientApplicationForm - the form of the document.
//  *Partner - CatalogRef.Partners - The partner from the document.
//  *PathToContract - String - the path to the Attribute with the Contract data.
//  *NameOfAlertEvent - String - name of the form event when the Contract was changed.
//  *Contract - CatalogRef.CounterpartyContracts - the selected Contract.
//
Procedure AfterContractIsCreatedEnd(Result, AdditionalParameters) Export
	
	If TypeOf(AdditionalParameters) = Type("Structure")
		And AdditionalParameters.Property("Contract") And ValueIsFilled(AdditionalParameters.Contract)
		And AdditionalParameters.Property("Partner") Then
		ErrorMessage = "";
		SelectedContract = AdditionalParameters.Contract;
		If PurchasesServerCall.CheckSelectionAndPartnerData(SelectedContract, AdditionalParameters.Filter, AdditionalParameters.Partner, ErrorMessage) Then
			DocumentData = TMCommonUseClientServer.DataForAssignment(AdditionalParameters.Object,
				AdditionalParameters.PathToContract);
			DocumentData.Data[DocumentData.Name] = SelectedContract;
			Notify(AdditionalParameters.NameOfAlertEvent, DocumentData.Name, AdditionalParameters.Object);
		Else
			ShowMessageBox(,ErrorMessage);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. Should be used See PartnersProductsClient.ShowThePartnerSNomenclature
// Opens the supplier's item list form with selection by owner, item, characteristic, and package.
//
// Parameters:
//	Partner       - CatalogRef.Partners - owner of the supplier's item
//	Ref        - DocumentRef - link to the document from which the procedure is called
//	CurrentRow - FormDataCollectionItem - the current row in the Products table.
//
Procedure ShowSupplierProducts(Partner, Ref, CurrentRow) Export

	PartnersProductsClient.ShowThePartnerSNomenclature(Partner, Ref, CurrentRow, "");

EndProcedure

// Deprecated. Causes a check for the presence of a previously matched supplier's nomenclature in the information database.
// If a previously matched item is found, it warns the user about it.
//
// Parameters:
//   Object - FormDataCollection - the document to be checked for.
//   CallbackDescription - CallbackDescription - defines the procedure that will be called after the check is completed.
//   DoNotPerformValidationForUser - Boolean - flag that determines whether to perform verification.
//
Procedure CheckMatchedSupplierProducts(Object, CallbackDescription, DoNotPerformValidationForUser) Export

	RunCallback(CallbackDescription, Undefined);

EndProcedure

// Deprecated. Should be used See PartnersProductsClient.WhenSelectingPartnerProducts.
// When trying to select a supplier item in a row of the table, the user receives a message about the partner being empty.
//
// Parameters:
//	Object                - FormDataStructure - document for issuing error messages
//	Field                  - FormField - field where the user makes a selection
//	NameOfFieldToCheck   - String - name of the field to return the error for.
//	PartnerPresentation_ - String - the representation of the field for which you want to generate an error.
Procedure WhenSelectingSupplierProducts(Object, Field, NameOfFieldToCheck, PartnerPresentation_) Export
	
	PartnersProductsClient.WhenSelectingPartnerProducts(Object, Field, NameOfFieldToCheck, PartnerPresentation_);
		
EndProcedure

// Deprecated. Should be used See PartnersProductsClient.FillInPartnerProductSelectionList.
// Generates a list of the supplier's nomenclature selection with selection by nomenclature, characteristics, packaging.
//
// Parameters:
//	Partner       - CatalogRef.Partners - owner of the supplier's item
//	CurrentRow - FormDataCollectionItem - current row in the Products table
//	ChoiceList  - ValueList - list of supplier's item selection.
//
Procedure FillInSupplierProductSelectionList(Partner, CurrentRow, ChoiceList) Export
	
	PartnersProductsClient.FillInPartnerProductSelectionList(Partner, CurrentRow, ChoiceList);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region CompletionOfAsynchronousHandlers

// Handler for completing the selection of the supplier's price type.
//
// Parameters:
//  VendorPriceKind       - CatalogRef.VendorPriceTypes - the selected type of supplier prices.
//  AdditionalParameters - Structure - advanced setting:
//		* CallbackDescription - CallbackDescription -
Procedure SelectVendorsPriceTypeCompletion(VendorPriceKind, AdditionalParameters) Export
	
	RunCallback(AdditionalParameters.CallbackDescription, VendorPriceKind);
	
EndProcedure

#EndRegion

#EndRegion
