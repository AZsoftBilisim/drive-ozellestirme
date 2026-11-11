#Region Public

// Procedure for selecting a price type from a single selection form.
//
// Parameters:
//	FillParameters - See NewFillOptionsSelectPriceType
Procedure ChooseTypeOfPrices(FillParameters) Export
	
	CallbackDescription = FillParameters.CallbackDescription;
	PriceIncludesVAT = FillParameters.PriceIncludesVAT;
	UseWhileSellingToCustomers = FillParameters.UseWhileSellingToCustomers;
	UseForIntercompanySales = FillParameters.UseForIntercompanySales;
	UseWhileTransferringProductsToMaterialProvider = FillParameters.UseWhileTransferringProductsToMaterialProvider;
	PriceTypePriceList_ = PriceManagementSystemServerCall.PriceTypePriceList_(PriceIncludesVAT);
	If PriceTypePriceList_ <> Undefined Then
		RunCallback(CallbackDescription, PriceTypePriceList_);
		Return;
	EndIf;
	
	StructureFilter = New Structure;
	StructureFilter.Insert("Status", PredefinedValue("Enum.StatusesOfPriceTypeValidity.Valid"));
	StructureFilter.Insert("DeletionMark", False);
	If PriceIncludesVAT <> Undefined Then
			StructureFilter.Insert("PriceIncludesVAT", PriceIncludesVAT);
	EndIf;
	If UseWhileSellingToCustomers <> Undefined Then
		StructureFilter.Insert("UseWhileSellingToCustomers", UseWhileSellingToCustomers);
	EndIf;
	If UseForIntercompanySales <> Undefined Then
		StructureFilter.Insert("UseForIntercompanySales", UseForIntercompanySales);
	EndIf;
	If UseWhileTransferringProductsToMaterialProvider <> Undefined Then
		StructureFilter.Insert("UseWhileTransferringProductsToMaterialProvider", UseWhileTransferringProductsToMaterialProvider);
	EndIf;
	OpenForm(
		"Catalog.TypesOfPrices.ChoiceForm",
		New Structure("Filter", StructureFilter),,,,,
		CallbackDescription);
		
EndProcedure

// The question on the conversion price when you change the document date.
//
// Parameters:
//	Document - DocumentObject - for which checks are performed
//	ResultNotification - CallbackDescription - notification of the result of a question, 
//			False if the required data is not filled in or the user answered the question in the negative.
//	TSName -String - Name of the table part, the default value is "Products".
//	CheckTerms - Boolean - indicates whether the agreement needs to be verified,
//	QueryText - String - question text.
//
Procedure AskQuestionAboutRecalculatingPriceWhenDateChanges(
			Document,
			ResultNotification,
			TSName="Goods",
			CheckTerms = True,
			QueryText = "") Export
	
	If CheckTerms And Not ValueIsFilled(Document.Terms)
		Or Not ValueIsFilled(Document.Currency)
		Or Document[TSName].Count() = 0 Then
		RunCallback(ResultNotification, False);
		Return;
	EndIf;
	
	AnswersOptions = New ValueList;
	AnswersOptions.Add(True, NStr("vi = 'Điền lại';
									|ru = 'Перезаполнить';
									|en = 'Refill'; fa = 'پرکردن مجدد';
									|it = 'Ricompilare';
									|pl = 'Refill';
									|tr = 'Yeniden doldur'"));
	AnswersOptions.Add(False, NStr("vi = 'Không điền lại';
									|ru = 'Не перезаполнять';
									|en = 'Do not refill'; fa = 'Do not refill';
									|it = 'Non ricompilare';
									|pl = 'Nie wypełniaj ponownie';
									|tr = 'Yeniden doldurma'"));
	
	ShowQueryBox(
		ResultNotification,
		?(ValueIsFilled(QueryText), QueryText, NStr("vi = 'Điền giá theo điều kiện bán hàng?';
													|ru = 'Перезаполнить цены по условиям продаж?';
													|en = 'Refill prices by sales terms and conditions?'; fa = 'Refill prices by sales terms and conditions?';
													|it = 'Refill prices by sales terms and conditions?';
													|pl = 'Refill prices by sales terms and conditions?';
													|tr = 'Satış şartlarına göre fiyatlar yeniden doldurulsun mu?'")),
		AnswersOptions);
	
EndProcedure

// The question of conversion price upon change of the agreement.
//
// Parameters:
//	Document - DocumentObject - for which checks are performed
//	ResultNotification - CallbackDescription - notification of the result of a question, 
//			False if the required data is not filled in or the user answered the question in the negative.
//	TSName -String - Name of the table part, the default value is "Products".
//
//
Procedure AskQuestionAboutRecalculatingPriceWhenChangingAgreement_(Document, ResultNotification, TSName="Goods") Export
	
	If Not ValueIsFilled(Document.Terms)
		Or Document[TSName].Count() = 0 Then
		RunCallback(ResultNotification, False);
		Return;
	EndIf;
	
	AnswersOptions = New ValueList;
	AnswersOptions.Add(True, NStr("vi = 'Điền lại';
									|ru = 'Перезаполнить';
									|en = 'Refill'; fa = 'پرکردن مجدد';
									|it = 'Ricompilare';
									|pl = 'Refill';
									|tr = 'Yeniden doldur'"));
	AnswersOptions.Add(False, NStr("vi = 'Không điền lại';
									|ru = 'Не перезаполнять';
									|en = 'Do not refill'; fa = 'Do not refill';
									|it = 'Non ricompilare';
									|pl = 'Nie wypełniaj ponownie';
									|tr = 'Yeniden doldurma'"));
	
	ShowQueryBox(ResultNotification, NStr("vi = 'Điền giá theo điều kiện bán hàng?';
											|ru = 'Перезаполнить цены по условиям продаж?';
											|en = 'Refill prices by sales terms and conditions?'; fa = 'Refill prices by sales terms and conditions?';
											|it = 'Refill prices by sales terms and conditions?';
											|pl = 'Refill prices by sales terms and conditions?';
											|tr = 'Satış şartlarına göre fiyatlar yeniden doldurulsun mu?'"), AnswersOptions);
	
EndProcedure

// The question of recalculating prices when changing the contract.
//
// Parameters:
//	Document - DocumentObject - for which checks are performed
//	ResultNotification - CallbackDescription - notification of the result of a question, 
//			False if the required data is not filled in or the user answered the question in the negative.
//	TSName -String - Name of the table part, the default value is "Products".
//
//
Procedure AskQuestionAboutRecalculatingPriceWhenChangingAgreement(Document, ResultNotification, TSName="Goods") Export
	
	If Not ValueIsFilled(Document.Terms)
		Or Document[TSName].Count() = 0 Then
		RunCallback(ResultNotification, False);
		Return;
	EndIf;
	
	AnswersOptions = New ValueList;
	AnswersOptions.Add(True, NStr("vi = 'Điền lại';
									|ru = 'Перезаполнить';
									|en = 'Refill'; fa = 'پرکردن مجدد';
									|it = 'Ricompilare';
									|pl = 'Refill';
									|tr = 'Yeniden doldur'"));
	AnswersOptions.Add(False, NStr("vi = 'Không điền lại';
									|ru = 'Не перезаполнять';
									|en = 'Do not refill'; fa = 'Do not refill';
									|it = 'Non ricompilare';
									|pl = 'Nie wypełniaj ponownie';
									|tr = 'Yeniden doldurma'"));
	
	ShowQueryBox(ResultNotification, NStr("vi = 'Điền giá theo điều kiện bán hàng?';
											|ru = 'Перезаполнить цены по условиям продаж?';
											|en = 'Refill prices by sales terms and conditions?'; fa = 'Refill prices by sales terms and conditions?';
											|it = 'Refill prices by sales terms and conditions?';
											|pl = 'Refill prices by sales terms and conditions?';
											|tr = 'Satış şartlarına göre fiyatlar yeniden doldurulsun mu?'"), AnswersOptions);
	
EndProcedure


// Checks whether the details required to fill in prices in the document are filled in by type of price.
//
// Parameters:
//   Document                    - DocumentObject - the object that checks are performed on.
//   TabularSectionName           - String - name of the table part to check.
//   TabularSectionPresentation - String - representation of the table part for informing the user.
//
// Returns:
//   Boolean - False if the required data is not filled in.
//
Function ItIsNecessaryToFillInPricesByTypeOfPrices(Document, TabularSectionName, TabularSectionPresentation) Export

	If Not ValueIsFilled(Document.Currency) Then
		
		ShowMessageBox(,NStr("vi = 'Trong chứng từ, chưa chỉ ra tiền tệ. Không thể điền đơn giá.';
							|ru = 'В документе не указана валюта. Цены не могут быть заполнены.';
							|en = 'Currency is not specified in the document. Prices cannot be populated.'; fa = 'Currency is not specified in the document. Prices cannot be populated.';
							|it = 'All''interno del documento non è indicata la valuta. I prezzi non possono essere compilati.';
							|pl = 'Dokument nie zawiera waluty. Ceny nie mogą być wypełnione.';
							|tr = 'Para birimi belgede belirtilmedi. Fiyatlar doldurulamaz.'"));
		Return False;
		
	ElsIf Document[TabularSectionName].Count() = 0 Then
		
		WarningText = NStr("vi = 'Trong chứng từ, chưa điền danh sách %TabularSectionPresentation%. Không thể điền giá.';
							|ru = 'В документе не заполнен список %TabularSectionPresentation%. Цены не могут быть заполнены.';
							|en = 'The %TabularSectionPresentation% list in the document is not filled in. Cannot fill in the prices.'; fa = 'The %TabularSectionPresentation% list in the document is not filled in. Cannot fill in the prices.';
							|it = 'All''interno del documento non è compilato l''elenco %TabularSectionPresentation%. I prezzi non possono essere compilati.';
							|pl = 'Dokument nie zawiera wypełnionej listy %TabularSectionPresentation%. Ceny nie mogą być wypełnione.';
							|tr = 'Belgede %TabularSectionPresentation% listesi doldurulmadı. Fiyatlar doldurulamaz.'");
		WarningText = StrReplace(WarningText, "%TabularSectionPresentation%", TabularSectionPresentation);
		ShowMessageBox(,WarningText);
		Return False;
		
	EndIf;
	
	Return True;

EndFunction

// Checks whether the details required to fill in the prices in the document under the agreement with the client are complete.
//
// Parameters:
//	Document                    - DocumentObject - object that checks are performed on
//	TabularSectionName           - String - name of the table part to check
//	TabularSectionPresentation - String - representation of the table part for informing the user.
//
// Returns:
//	Boolean - False if the required data is not filled in.
//
Function ItIsNecessaryToFillInPricesByAgreement(Document, TabularSectionName, TabularSectionPresentation) Export

	If Not ValueIsFilled(Document.Terms) Then
		
		ShowMessageBox(,NStr("vi = 'Trong chứng từ chưa chỉ ra thỏa thuận với khách hàng. Không thể điền giá.';
							|ru = 'В документе не указано соглашение с клиентом. Цены не могут быть заполнены.';
							|en = 'Customer agreement is not specified in the document. Prices cannot be filled in.'; fa = 'Customer agreement is not specified in the document. Prices cannot be filled in.';
							|it = 'All''interno del documento non è indicato l''accordo con il cliente. I prezzi non posso essere compilati.';
							|pl = 'Dokument nie określa umowy z klientem. Ceny nie mogą być wypełnione.';
							|tr = 'Bu belgede satış koşulları mevcut değil. Fiyatlar doldurulamıyor.'"));
		Return False;
		
	ElsIf Not ValueIsFilled(Document.Currency) Then
		
		ShowMessageBox(,NStr("vi = 'Trong chứng từ, chưa chỉ ra tiền tệ. Không thể điền đơn giá.';
							|ru = 'В документе не указана валюта. Цены не могут быть заполнены.';
							|en = 'Currency is not specified in the document. Prices cannot be populated.'; fa = 'Currency is not specified in the document. Prices cannot be populated.';
							|it = 'All''interno del documento non è indicata la valuta. I prezzi non possono essere compilati.';
							|pl = 'Dokument nie zawiera waluty. Ceny nie mogą być wypełnione.';
							|tr = 'Para birimi belgede belirtilmedi. Fiyatlar doldurulamaz.'"));
		Return False;
		
	ElsIf Document[TabularSectionName].Count() = 0 Then
		
		WarningText = NStr("vi = 'Trong chứng từ, chưa điền danh sách %TabularSectionPresentation%. Không thể điền đơn giá.';
							|ru = 'В документе не заполнен список %TabularSectionPresentation%. Цены не могут быть заполнены.';
							|en = 'The %TabularSectionPresentation% list in the document is not filled in. Cannot fill in the prices.'; fa = 'The %TabularSectionPresentation% list in the document is not filled in. Cannot fill in the prices.';
							|it = 'All''interno del documento non è compilato l''elenco %TabularSectionPresentation%. I prezzi non possono essere compilati.';
							|pl = 'Dokument nie zawiera wypełnionej listy %TabularSectionPresentation%. Ceny nie mogą być wypełnione.';
							|tr = 'Belgede %TabularSectionPresentation% listesi doldurulmadı. Fiyatlar doldurulamaz.'");
		WarningText = StrReplace(WarningText, "%TabularSectionPresentation%", TabularSectionPresentation);
		ShowMessageBox(, WarningText);
		Return False;
		
	EndIf;
	
	Return True;
		
EndFunction

// Checks the completeness of the details required to fill in the prices in the document under the contract with the commission agent.
//
// Parameters:
//	Document            - FormDataStructure - object that checks are performed on
//	FillParameters - See EnterprisePricesFillingServer.NewParametersForCheckingTypeOfContractPrices
//
// Returns:
//	Boolean - False if the required data is not filled in.
//
Function YouNeedToFillInPricesByType(Document, FillParameters) Export
	
	Result = True;
	
	If Not ValueIsFilled(Document.Contract) Then
		
		ShowMessageBox(,NStr("vi = 'Trong chứng từ chưa chỉ ra hợp đồng với người nhận ký gửi. Không thể điền đơn giá.';
							|ru = 'В документе не указан договор с комиссионером. Цены не могут быть заполнены.';
							|en = 'The contract with a consignee is not specified in the document. Prices cannot be filled in.'; fa = 'The contract with a consignee is not specified in the document. Prices cannot be filled in.';
							|it = 'Nel documento non è indicato l''accordo con il commissionario. I prezzi non possono essere compilati.';
							|pl = 'Dokument nie zawiera kontraktu z komisantem. Ceny nie mogą byś wypełnione.';
							|tr = 'Belge, konsinye ile yapılan sözleşmeyi göstermemektedir. Fiyatlar doldurulamaz.'"));
		Result = False;
		
	ElsIf Not ValueIsFilled(FillParameters.PriceKind) Then
		
		PriceKind = ?(FillParameters.FieldPriceType = "SalesPriceType", NStr("vi = 'dạng giá bán hàng';
																			|ru = 'вид цен продажи';
																			|en = 'sales price type'; fa = 'sales price type';
																			|it = 'tipo di prezzi di vendita';
																			|pl = 'rodzaj ceny sprzedaży';
																			|tr = 'satış fiyat türü'"), NStr("vi = 'dạng giá theo kế toán';
																												|ru = 'учетный вид цен';
																												|en = 'accounting price type'; fa = 'accounting price type';
																												|it = 'tipo di prezzo contabile';
																												|pl = 'ewidencyjny rodzaj ceny';
																												|tr = 'muhasebe fiyat türü'"));
		WarningText = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Trong hợp đồng chưa chỉ ra %1. Không thể điền đơn giá.';
																					|ru = 'В договоре не указан %1. Цены не могут быть заполнены.';
																					|en = '%1 is not specified in the contract. Cannot fill in the prices.'; fa = '%1 is not specified in the contract. Cannot fill in the prices.';
																					|it = 'Nell''accordo non è indicato %1. I prezzi non possono essere compilati.';
																					|pl = 'Kontrakt nie zawiera %1. Ceny nie mogą być wypełnione.';
																					|tr = 'Sözleşmede %1 belirtilmedi. Fiyatlar doldurulamaz.'"), PriceKind);
		ShowMessageBox(,WarningText);
		Result = False;
		
	ElsIf Not FillParameters.PriceIncludesVAT = Undefined And Not Document.PriceIncludesVAT = FillParameters.PriceIncludesVAT Then
		
		WarningText = NStr("vi = 'Dấu hiệu ""Đơn giá gồm thuế GTGT"" khác nhau ở dạng giá hợp đồng và chứng từ. Không thể điền đơn giá.';
							|ru = 'Признак ""Цена включает НДС"" различается в виде цен договора и документа. Цены не могут быть заполнены.';
							|en = 'The ""Price includes VAT"" flag differs in the price type of the contract and the document. Cannot fill in the prices.'; fa = 'The ""Price includes VAT"" flag differs in the price type of the contract and the document. Cannot fill in the prices.';
							|it = 'Il segno ""Prezzo IVA inclusa"" distingue tra il prezzo dell''accordo e quello del documento. I prezzi non possono essere compilati.';
							|pl = 'Oznaka ""Cena zawiera VAT"" różni się w rodzaju cen kontraktu i dokumentu. Ceny nie mogą być wypełnione.';
							|tr = '""Fiyata KDV dahildir"" bayrağı sözleşme ve belge fiyatlarında farklıdır. Fiyatlar doldurulamaz.'");
		ShowMessageBox(, WarningText);
		Return False;
		
	ElsIf Document[FillParameters.TabularSectionName].Count() = 0 Then
		
		WarningText = NStr("vi = 'Trong chứng từ chưa điền danh sách %TabularSectionPresentation%. Không thể điền đơn giá.';
							|ru = 'В документе не заполнен список %TabularSectionPresentation%. Цены не могут быть заполнены.';
							|en = 'The %TabularSectionPresentation% list in the document is not filled in. Cannot fill in the prices.'; fa = 'The %TabularSectionPresentation% list in the document is not filled in. Cannot fill in the prices.';
							|it = 'All''interno del documento non è compilato l''elenco %TabularSectionPresentation%. I prezzi non possono essere compilati.';
							|pl = 'Dokument nie zawiera wypełnionej listy %TabularSectionPresentation%. Ceny nie mogą być wypełnione.';
							|tr = 'Belgede %TabularSectionPresentation% listesi doldurulmadı. Fiyatlar doldurulamaz.'");
		WarningText = StrReplace(WarningText, "%TabularSectionPresentation%", FillParameters.TabularSectionPresentation);
		ShowMessageBox(, WarningText);
		Return False;
		
	EndIf;
	
	Return Result;
	
EndFunction

#Region Constructors

// Constructor for parameters of the select view Method.
//
// Returns:
//	Structure - A complete list of possible parameters, some may be optional to fill in:
//		* CallbackDescription - CallbackDescription, Undefined - notification to be processed after selecting the price type
//		* PriceIncludesVAT 							- Boolean, Undefined - selection when choosing a price
//		* UseWhileSellingToCustomers 					- Boolean, Undefined - selection when choosing a price
//		* UseForIntercompanySales - Boolean, Undefined - selection when choosing a price
//		* OwnerOfAnIndividualPriceType			- CatalogRef.TermsOfSale,
//													- CatalogRef.Partners,
//													- CatalogRef.StoreFormats,
//													- CatalogRef.Warehouses,
//													- Undefined
//		* UseWhileTransferringProductsToMaterialProvider 	- Boolean, Undefined - selection when choosing a price.
//
Function NewFillOptionsSelectPriceType() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("CallbackDescription", Undefined);
	ParametersStructure.Insert("PriceIncludesVAT", Undefined);
	ParametersStructure.Insert("UseWhileSellingToCustomers", Undefined);
	ParametersStructure.Insert("UseForIntercompanySales", Undefined);
	ParametersStructure.Insert("OwnerOfAnIndividualPriceType", Undefined);
	ParametersStructure.Insert("UseWhileTransferringProductsToMaterialProvider", Undefined);
	Return ParametersStructure; 
	
EndFunction

#EndRegion

#EndRegion
