
#Region Public

// Procedure for selecting a supplier price condition from the selection form.
//
// Parameters:
//	CallbackDescription - CallbackDescription - 
//	Partner - CatalogRef.Partners, Undefined - the partner for which select the terms of suppliers' prices. If "Undefined", then it is selected in the form
//	PriceIncludesVAT - Boolean, Undefined - Selection by type of price, Undefined - no selection.
//
Procedure SelectVendorsPriceType(CallbackDescription, Partner = Undefined, PriceIncludesVAT = Undefined) Export
	
	Filter = New Structure;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Filter", Filter);
	OpeningParameters.Insert("ChoosingPartner", False);
	
	If Partner = Undefined Then
		OpeningParameters.ChoosingPartner = True;
	Else
		Filter.Insert("Owner", Partner);
	EndIf;
	
	If PriceIncludesVAT <> Undefined Then
		Filter.Insert("PriceIncludesVAT", PriceIncludesVAT);
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
	
	OpenForm(
		"Catalog.VendorPriceTypes.ChoiceForm",
		OpeningParameters,,,,,
		New CallbackDescription("SelectVendorsPriceTypeCompletion", PurchasesClient, AdditionalParameters));
	
EndProcedure

// Displays a notification to the user about the end of filling in prices for the supplier's price condition.
//
// Parameters:
//  PricesCalculated    - Boolean - Indicates that prices were calculated successfully in at least one line.
//  VendorPriceKind - CatalogRef.VendorPriceTypes - Type of supplier's price that was used for filling
//                                                            in prices.
//
Procedure NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, VendorPriceKind) Export

	If PricesCalculated Then
		ShowUserNotification(
			NStr("vi = 'Đơn giá điền';
				|ru = 'Цены заполнены';
				|en = 'Prices are filled out'; fa = 'Prices are filled out';
				|it = 'I prezzi sono compilati';
				|pl = 'Wypełniono ceny';
				|tr = 'Fiyatlar dolduruldu'"),
			,
			StrReplace(NStr("vi = 'Đã điền giá theo dạng giá nhà cung cấp ""%VendorPriceKind%""';
							|ru = 'Цены по виду цены поставщика ""%VendorPriceKind%"" заполнены';
							|en = 'Prices according to the ""%VendorPriceKind%"" vendor price type are filled in'; fa = 'Prices according to the ""%VendorPriceKind%"" vendor price type are filled in';
							|it = 'Prezzi per tipo di prezzi del fornitore ""%VendorPriceKind%""  compilati';
							|pl = 'Ceny wg rodzaju ceny dostawcy ""%VendorPriceKind%"" są wypełnione';
							|tr = '""%VendorPriceKind%"" tedarikçi fiyat türüne göre fiyatlar dolduruldu'"), "%VendorPriceKind%", VendorPriceKind),
			PictureLib.Information32);
	Else
		ShowUserNotification(
			NStr("vi = 'Chưa điền đơn giá';
				|ru = 'Цены не заполнены';
				|en = 'Prices are not filled in'; fa = 'Prices are not filled in';
				|it = 'I prezzi non sono compilati';
				|pl = 'Nie wypełniono ceny';
				|tr = 'Fiyatlar doldurulmadı'"),
			,
			StrReplace(NStr("vi = 'Chưa điền dòng đơn giá nào theo dạng giá của nhà cung cấp ""%VendorPriceKind%""';
							|ru = 'Ни в одной строке цены по виду цены поставщика ""%VendorPriceKind%"" не заполнены';
							|en = 'No lines have prices of the ""%VendorPriceKind%"" vendor price type filled in'; fa = 'No lines have prices of the ""%VendorPriceKind%"" vendor price type filled in';
							|it = 'I prezzi per tipo di prezzo del fornitore ""%VendorPriceKind%"" sono compilati in tutte le righe';
							|pl = 'W rządnym wierszu ceny wg rodzaju ceny dostawcy ""%VendorPriceKind%"" nie są wypełnione';
							|tr = 'Satırların hiçbirinde tedarikçi fiyat türüne göre fiyatlar %VendorPriceKind%"" doldurulmadı'"), "%VendorPriceKind%", VendorPriceKind),
			PictureLib.Information32);
	EndIf;
	
EndProcedure

// Checks whether the details required to fill in the prices in the document under the agreement with the supplier are complete.
//
// Parameters:
//  Document                    - DocumentObject - document for which checks are performed
//  TabularSectionName           - String - name of the table part to check
//  TabularSectionPresentation - String - representation of the table part for informing the user.
//
// Returns:
//  Boolean - False if the required data is not filled in.
//
Function ItIsNecessaryToFillInPricesByAgreement(Document, TabularSectionName, TabularSectionPresentation) Export

	If Not ValueIsFilled(Document.Terms) Then
		
		ShowMessageBox(,NStr("vi = 'Trong chứng từ chưa chỉ ra thỏa thuận với nhà cung cấp, hoặc không có thỏa thuận với nhà cung cấp. Không thể điền đơn giá';
							|ru = 'В документе не указано соглашение с поставщиком, или соглашения с поставщиком отсутствуют. Цены не могут быть заполнены';
							|en = 'Terms of purchase are not specified in the document, or there are no terms of purchase. Prices cannot be populated'; fa = 'Terms of purchase are not specified in the document, or there are no terms of purchase. Prices cannot be populated';
							|it = 'Il documento non indica un accordo con il fornitore o non ci sono accordi con il fornitore. I prezzi non possono essere compilati.';
							|pl = 'W dokumencie nie jest wskazana umowa z dostawcą lub umowy z dostawcą brakują. Ceny nie mogą być wypełnione';
							|tr = 'Belgede satın alma koşulları belirtilmiyor veya satın alma koşulları mevcut değil. Fiyatlar doldurulamıyor'"));
		Return False;
		
	ElsIf Not ValueIsFilled(Document.Currency) Then
		
		ShowMessageBox(,NStr("vi = 'Trong chứng từ chưa chỉ ra tiền tệ. Không thể điền đơn giá';
							|ru = 'В документе не указана валюта. Цены не могут быть заполнены';
							|en = 'Currency is not specified in the document. Prices cannot be populated'; fa = 'Currency is not specified in the document. Prices cannot be populated';
							|it = 'Nel documento non è indicata la valuta. I prezzi non possono essere compilati';
							|pl = 'W dokumencie nie jest wskazana waluta. Ceny nie mogą być wypełnione';
							|tr = 'Para birimi belgede belirtilmedi. Fiyatlar doldurulamaz'"));
		Return False;
		
	ElsIf Document[TabularSectionName].Count() = 0 Then
		
		WarningText = NStr("vi = 'Trong chứng từ, chưa điền bảng %TabularSectionPresentation%. Không thể điền đơn giá';
							|ru = 'В документе не заполнена таблица %TabularSectionPresentation%. Цены не могут быть заполнены';
							|en = 'Table %TabularSectionPresentation% in the document is not filled in. Cannot fill in the prices'; fa = 'Table %TabularSectionPresentation% in the document is not filled in. Cannot fill in the prices';
							|it = 'Nel documento non è compilata la tabella ""%TabularSectionPresentation%"". I prezzi non possono essere compilati';
							|pl = 'W dokumencie nie jest wypełniona tabela %TabularSectionPresentation%. Ceny nie mogą być wypełnione';
							|tr = 'Belgede %TabularSectionPresentation% tablosu doldurulmadı. Fiyatlar doldurulamaz'");
		WarningText = StrReplace(WarningText, "%TabularSectionPresentation%", TabularSectionPresentation);
		ShowMessageBox(,WarningText);
		Return False;
		
	Else
		
		Return True;
		
	EndIf;

EndFunction

// Checks whether the details required to fill in the prices in the document according to the supplier's price condition are filled in.
//
// Parameters:
//  Document                    - DocumentObject - document for which checks are performed
//  TabularSectionName           - String - name of the table part to check
//  TabularSectionPresentation - String - representation of the table part for informing the user.
//
// Returns:
//  Boolean - False if the required data is not filled in.
//
Function ItIsNecessaryToFillInPricesAccordingToSupplierSPriceType(Document, TabularSectionName, TabularSectionPresentation) Export

	If Not ValueIsFilled(Document.Currency) Then
		
		ShowMessageBox(,NStr("vi = 'Trong chứng từ, chưa chỉ ra tiền tệ. Không thể điền đơn giá';
							|ru = 'В документе не указана валюта. Цены не могут быть заполнены';
							|en = 'Currency is not specified in the document. Prices cannot be populated'; fa = 'Currency is not specified in the document. Prices cannot be populated';
							|it = 'Nel documento non è indicata la valuta. I prezzi non possono essere compilati';
							|pl = 'W dokumencie nie jest wskazana waluta. Ceny nie mogą być wypełnione';
							|tr = 'Para birimi belgede belirtilmedi. Fiyatlar doldurulamaz'"));
		Return False;
		
	ElsIf Document[TabularSectionName].Count() = 0 Then
		
		WarningText = NStr("vi = 'Trong chứng từ, chưa điền bảng %TabularSectionPresentation%. Không thể điền giá';
							|ru = 'В документе не заполнена таблица %TabularSectionPresentation%. Цены не могут быть заполнены';
							|en = 'Table %TabularSectionPresentation% in the document is not filled in. Cannot fill in the prices'; fa = 'Table %TabularSectionPresentation% in the document is not filled in. Cannot fill in the prices';
							|it = 'Nel documento non è compilata la tabella ""%TabularSectionPresentation%"". I prezzi non possono essere compilati';
							|pl = 'W dokumencie nie jest wypełniona tabela %TabularSectionPresentation%. Ceny nie mogą być wypełnione';
							|tr = 'Belgede %TabularSectionPresentation% tablosu doldurulmadı. Fiyatlar doldurulamaz'");
		WarningText = StrReplace(WarningText, "%TabularSectionPresentation%", TabularSectionPresentation);
		ShowMessageBox(,WarningText);
		Return False;
		
	Else
		
		Return True;
		
	EndIf;

EndFunction

#EndRegion

