#Region Public

// Open the managed discount mark-up assignment form.
//
// Parameters:
//  AddressInTempStorage - String - Address of additional data in temporary storage.
//  ClosingNotification1 - CallbackDescription - Notification of closure.
//
Procedure OpenManagedDiscountMarkUpAssignmentForm(AddressInTempStorage, ClosingNotification1) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressInTempStorage", AddressInTempStorage);
	OpenForm("CommonForm.AutomaticDiscountMarkupCalculation", 
		FormParameters,
		,
		,
		,
		,
		ClosingNotification1,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

// This procedure resets the Skidcounted flag and makes the columns in the table part unavailable.
//
// Parameters:
//  Form - ClientApplicationForm - object form.
//
Procedure ResetDiscountsCalculatedFlag(Form) Export
	
	Form.Object.DiscountsAreCalculated = False;
	
EndProcedure

// Offer the user to calculate discounts.
//
// Parameters:
//  CallbackDescription - CallbackDescription - Description of the alert that is called after the question is completed.
//
Procedure SuggestUserToCalculateDiscounts(CallbackDescription) Export
	
	QueryText = NStr("vi = 'Chưa tính chiết khấu (phụ thu) tự động. Tính chiết khấu (phụ thu) tự động?';
					|ru = 'Автоматические скидки (наценки) не рассчитаны. Рассчитать автоматические скидки (наценки)?';
					|en = 'Discounts/markups are not calculated. Calculate the discounts/markups?'; fa = 'Discounts/markups are not calculated. Calculate the discounts/markups?';
					|it = 'Gli sconti (markup) automatici non sono calcolati. Calcolare gli sconti (markup) automatici?';
					|pl = 'Automatyczne rabaty (marże) nie są obliczane. Oblicz automatyczne rabaty (marże)?';
					|tr = 'Otomatik indirim/zam hesaplanmadı. Otomatik indirim/zam hesaplansın mı?'");
	ShowQueryBox(
		CallbackDescription,
		QueryText,
		QuestionDialogMode.OKCancel);
	
EndProcedure


// Open the manual discount assignment form.
//
// Parameters:
//  AddressInTempStorage - String - Address of additional data in temporary storage.
//  Currency - CatalogRef.Currencies - Currency.
//  ClosingNotification1 - CallbackDescription - Notification of closure.
//  TheseArePurchases - Boolean - A sign of purchasing.
//
Procedure OpenFormForAssigningManualDiscounts(
		AddressInTempStorage,
		Currency,
		ClosingNotification1,
		TheseArePurchases = False) Export

	FormParameters = New Structure;
	FormParameters.Insert("AddressInTempStorage",             AddressInTempStorage);
	FormParameters.Insert("Currency",                                Currency);
	FormParameters.Insert("TheseArePurchases", TheseArePurchases);

	OpenForm("CommonForm.AdjustDiscountMarkup", 
		FormParameters,
		,
		,
		,
		,
		ClosingNotification1,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

// Checks whether the details required for assigning discounts are filled in.
//
// Parameters:
//   Document                    - DocumentObject - the object that checks are performed on.
//   TabularSectionName           - String - name of the table part to check.
//   TabularSectionPresentation - String - representation of the table part for informing the user.
//
// Returns:
//   Boolean - The possibility of assigning manual discounts (margins).
//
Function ItIsPossibleToAssignManualDiscountMarkUp(Document, TabularSectionName, TabularSectionPresentation) Export

	If Document[TabularSectionName].Count() = 0 Then
		
		WarningText = NStr("vi = 'Trong chứng từ chưa điền bảng %TabularSectionPresentation%. Chưa ấn định chiết khấu (phụ thu) thủ công';
							|ru = 'В документе не заполнена таблица %TabularSectionPresentation%. Ручная скидка (наценка) не может быть назначена';
							|en = 'Table %TabularSectionPresentation% is not filled in the document. You cannot assign discount/markup adjustment'; fa = 'Table %TabularSectionPresentation% is not filled in the document. You cannot assign discount/markup adjustment';
							|it = 'Nel documento non è compilata la tabella %TabularSectionPresentation%. Lo sconto (markup) manuale non può essere assegnato';
							|pl = 'Dokument zawiera niewypełnioną tablicę %TabularSectionPresentation%. Ręczna zniżka (marża) nie może być przypisana';
							|tr = 'Belgede %TabularSectionPresentation% tablosu doldurulmadı. İndirim (zam) düzeltmesi atanamaz'");
		WarningText = StrReplace(WarningText, "%TabularSectionPresentation%", TabularSectionPresentation);
		ShowMessageBox(,WarningText);
		Return False;
		
	EndIf;

	Return True;

EndFunction

// Checks whether the details required to cancel discounts are filled in.
//
// Parameters:
//   Document                    - DocumentObject - the object that checks are performed on.
//   TabularSectionName           - String - name of the table part to check.
//   TabularSectionPresentation - String - representation of the table part for informing the user.
//
// Returns:
//  Boolean - The possibility of canceling manual discounts (margins).
//
Function ItIsPossibleToCancelManualDiscountsMarkups(Document, TabularSectionName, TabularSectionPresentation) Export

	If Document[TabularSectionName].Count() = 0 Then
		
		WarningText = NStr("vi = 'Trong chứng từ chưa điền bảng %TabularSectionPresentation%. Không thể hủy bỏ chiết khấu (phụ thu) thủ công';
							|ru = 'В документе не заполнена таблица %TabularSectionPresentation%. Ручные скидки (наценки) не могут быть отменены';
							|en = 'Table %TabularSectionPresentation% is empty. Cannot clear discount/markup adjustments'; fa = 'Table %TabularSectionPresentation% is empty. Cannot clear discount/markup adjustments';
							|it = 'Nel documento non è compilata la tabella ""%TabularSectionPresentation%"".Impossibile annullare gli sconti manuali (markup)';
							|pl = 'Dokument zawiera niewypełnioną tablicę %TabularSectionPresentation%. Ręczne zniżki (marża) nie może być anulowane';
							|tr = 'Belgede %TabularSectionPresentation% tablosu doldurulmadı. İndirim (zam) düzeltmesi iptal edilemez'");
		WarningText = StrReplace(WarningText, "%TabularSectionPresentation%", TabularSectionPresentation);
		ShowMessageBox(,WarningText);
		Return False;
		
	ElsIf Document[TabularSectionName].Total("ManualDiscount") = 0 Then
		
		WarningText = NStr("vi = 'Trong chứng từ chưa điền số tiền chiết khấu thủ công trong bảng %TabularSectionPresentation%. Không thể hủy bỏ chiết khấu (phụ thu) thủ công';
							|ru = 'В документе не заполнена сумма ручной скидки в таблице %TabularSectionPresentation%. Ручные скидки (наценки) не могут быть отменены';
							|en = 'Discount adjustment amount is not filled in the %TabularSectionPresentation% table in the document. You cannot cancel discount/markup adjustments'; fa = 'Discount adjustment amount is not filled in the %TabularSectionPresentation% table in the document. You cannot cancel discount/markup adjustments';
							|it = 'Nel documento non è compilato l''importo dello sconto manuale nella tabella ""%TabularSectionPresentation%"".Impossibile annullare gli sconti manuali (markup)';
							|pl = 'Dokument nie zawiera wartości ręcznego rabatu w tabeli %TabularSectionPresentation%. Ręczne rabaty (marże) nie mogą być anulowane';
							|tr = 'Belgede %TabularSectionPresentation% tablosundaki indirim düzeltmesi tutarı doldurulmadı. İndirim (zam) düzeltmesi iptal edilemez'");
		WarningText = StrReplace(WarningText, "%TabularSectionPresentation%", TabularSectionPresentation);
		ShowMessageBox(,WarningText);
		Return False;
		
	EndIf;

	Return True;

EndFunction

// Displays a notification to the user about the end of assigning manual discounts (markups).
//
// Parameters:
//   AmountOfDiscountMarkUp - Number - The amount of the manual discount.
//   Currency             - CatalogRef.Currencies, Undefined - Discount currency.
//
Procedure NotifyAboutEndOfAssignmentOfManualDiscountsMargins(AmountOfDiscountMarkUp = 0, Currency = Undefined) Export

	If AmountOfDiscountMarkUp > 0 Then
		
		MessageText = NStr("vi = 'Đã ấn định chiết khấu thủ công %AmountOfDiscountMarkUp% %Currency%';
							|ru = 'Назначена ручная скидка %AmountOfDiscountMarkUp% %Currency%';
							|en = 'Discount adjustment %AmountOfDiscountMarkUp% %Currency% is assigned'; fa = 'Discount adjustment %AmountOfDiscountMarkUp% %Currency% is assigned';
							|it = 'È assegnato lo sconto manuale %AmountOfDiscountMarkUp% %Currency%';
							|pl = 'Przypisano ręczną zniżkę %AmountOfDiscountMarkUp% %Currency%';
							|tr = 'İndirim düzeltmesi atandı %AmountOfDiscountMarkUp% %Currency%'");
		MessageText = StrReplace(MessageText, "%AmountOfDiscountMarkUp%", AmountOfDiscountMarkUp);
		MessageText = StrReplace(MessageText, "%Currency%", Currency);
		
	ElsIf AmountOfDiscountMarkUp < 0 Then
		
		MessageText = NStr("vi = 'Đã ấn định phụ thu thủ công %AmountOfDiscountMarkUp% %Currency%';
							|ru = 'Назначена ручная наценка %AmountOfDiscountMarkUp% %Currency%';
							|en = 'Manual markup %AmountOfDiscountMarkUp% %Currency% is assigned'; fa = 'Manual markup %AmountOfDiscountMarkUp% %Currency% is assigned';
							|it = 'È assegnato il markup manuale %AmountOfDiscountMarkUp% %Currency%';
							|pl = 'Przypisano ręczną marżę %AmountOfDiscountMarkUp% %Currency%';
							|tr = 'Manuel zam atandı %AmountOfDiscountMarkUp% %Currency%'");
		MessageText = StrReplace(MessageText, "%AmountOfDiscountMarkUp%", AmountOfDiscountMarkUp);
		MessageText = StrReplace(MessageText, "%Currency%", Currency);
		
	Else
		
		MessageText = NStr("vi = 'Đã hủy chiết khấu (phụ thu) thủ công';
							|ru = 'Ручные скидки (наценки) отменены';
							|en = 'Discount/markup adjustments are cleared'; fa = 'Discount/markup adjustments are cleared';
							|it = 'Sconti manuali (markup) annullati';
							|pl = 'Ręczne rabaty (marże) anulowane';
							|tr = 'İndirim (zam) düzeltmeleri iptal edildi'");
		
	EndIf;
		
	ShowUserNotification(
		NStr("vi = 'Chiết khấu (phụ thu)';
			|ru = 'Скидки (наценки)';
			|en = 'Discounts (markups)'; fa = 'تخفیف‌ها (افزایش قیمت‌ها)';
			|it = 'Sconti (sovrapprezzo)';
			|pl = 'Rabaty (marże)';
			|tr = 'İndirimler (zamlar)'"),
		,
		MessageText,
		PictureLib.Information32);

EndProcedure // Notify the end of the assignment of the handwritten discount()




// The procedure opens a form for decoding discounts calculated for the current row of the table part.
//
// Parameters:
//  CurrentData           - LineOfATabularSection - The row for which you want to open a transcript discount.
//  Object                  - FormDataStructure, DocumentObject - The object for which you want to access form decrypt discounts.
//  Form                   - ClientApplicationForm - object form.
//  AdditionalParameters - Structure - advanced setting:
//  	* ColumnNameQuantity - String -
//
Procedure OpenAppliedDiscountsForm(CurrentData, Object, Form, AdditionalParameters = Undefined) Export
	
	If TypeOf(Object.Ref) = Type("DocumentRef.CustomerInvoiceServices") Then
		QuantityName = "Count";
	ElsIf TypeOf(AdditionalParameters) = Type("Structure")
		And AdditionalParameters.Property("ColumnNameQuantity") Then
		QuantityName = AdditionalParameters.ColumnNameQuantity; 
	Else
		QuantityName = "NumberOfPackages";
	EndIf;
	
	If CurrentData <> Undefined Then
	
		StructureCurData = New Structure;
		StructureCurData.Insert("ConnectionKey",         CurrentData.ConnectionKey);
		StructureCurData.Insert("Products",      CurrentData.Products);
		StructureCurData.Insert("Characteristic",    CurrentData.Characteristic);
		StructureCurData.Insert("ManualDiscount", CurrentData.ManualDiscount);
		StructureCurData.Insert("AmountWithoutADiscount",    CurrentData.Price * CurrentData[QuantityName]);
		
		ParametersStructure = New Structure();
		ParametersStructure.Insert("Object", Object);
		ParametersStructure.Insert("Title", NStr("vi = 'Chiết khấu (phụ thu) được áp dụng cho dòng';
												|ru = 'Примененные скидки (наценки) для строки';
												|en = 'Applied discounts (markups) for row'; fa = 'Applied discounts (markups) for row';
												|it = 'Sconti (markup) applicati per la riga';
												|pl = 'Zastosowane rabaty (marże) dla wiersza';
												|tr = 'Satıra uygulanan indirimleri (zamları) görüntüle'"));
		ParametersStructure.Insert("CurrentData", StructureCurData);
		ParametersStructure.Insert("AddressOfAppliedDiscountsInTheTemporaryStorage",          Form.AddressOfAppliedDiscountsInTheTemporaryStorage);
		ParametersStructure.Insert("DisplayInformationAboutDiscountsByLine",                True);
		ParametersStructure.Insert("DisplayInformationAboutCalculatingDiscountsByLine",          True);
		ParametersStructure.Insert("DisplayInformationAboutCalculatingDiscountsForTheDocumentAsAWhole", False);
		
		If AdditionalParameters <> Undefined And TypeOf(AdditionalParameters) = Type("Structure") Then
			For Each Parameter In AdditionalParameters Do
				ParametersStructure.Insert(Parameter.Key,Parameter.Value);
			EndDo;
		EndIf;
		
		OpenForm("CommonForm.AppliedDiscountsMarkups", ParametersStructure, Form, Form.UUID);
	
	EndIf;

EndProcedure

// Open the message form
//
// Parameters:
//  TheStructureOfTheMessages - See DiscountsMarkupsFillingServer.TheStructureOfTheMessages 
//  Form - ClientApplicationForm - object form.
//
Procedure OpenMessageForm(TheStructureOfTheMessages, Form) Export
	
	OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, Form, Form.UUID);
	
EndProcedure



#EndRegion