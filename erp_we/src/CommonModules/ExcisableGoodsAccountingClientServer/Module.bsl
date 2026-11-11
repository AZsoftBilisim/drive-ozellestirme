
#Region Internal

// Gets the text of the field header is subject to excise duty
//
// Parameters:
//  NumberOfExcisableItems - Number
//
// Returns:
//  String
//
Function FieldHeaderIsSubjectToExciseDuty(NumberOfExcisableItems) Export
	
	TitleText = NStr("vi = 'Hàng hóa chịu thuế TTĐB (%1) do doanh nghiệp sản xuất và chịu thuế TTĐB';
					|ru = 'Подакцизный товар (%1) произведен организацией и облагается акцизом';
					|en = 'Excisable goods (%1) are produced by the company and are subject to excise'; fa = 'Excisable goods (%1) are produced by the company and are subject to excise';
					|it = 'Excisable goods (%1) are produced by the company and are subject to excise';
					|pl = 'Excisable goods (%1) are produced by the company and are subject to excise';
					|tr = 'Tüketim vergisine tabi ürün (%1) iş yeri tarafından üretilir ve tüketim vergisine tabidir'");
	
	AmountInWordsParameters = NStr("vi = 'mặt hàng, mặt hàng, mặt hàng, mặt hàng, , , , , 0';
									|ru = 'позиция, позиции, позиций, ж, , , , , 0';
									|en = 'position,positions,,,0'; fa = 'position,positions,,,0';
									|it = 'position,positions,,,0';
									|pl = 'position,positions,,,0';
									|tr = 'pozisyon, pozisyon, pozisyon, ж, , , , , 0'");
	RegistrationParametersAreOnlyNumber = NStr("vi = ', , , mặt hàng, , , , , 0';
												|ru = ', , , ж, , , , , 0';
												|en = ', , , , , , 0'; fa = ', , , , , , 0';
												|it = ', , , , , , 0';
												|pl = ', , , , , , 0';
												|tr = ', , , ж, , , , , 0'");
	NumberOfExcisableItemsInWords = StrReplace(
		NumberInWords(NumberOfExcisableItems, , AmountInWordsParameters),
		TrimR(NumberInWords(NumberOfExcisableItems, , RegistrationParametersAreOnlyNumber)),
		Format(NumberOfExcisableItems, "NZ=0; NG=;"));
	
	TitleText = StrTemplate(TitleText, NumberOfExcisableItemsInWords);
	
	Return TitleText;
	
EndFunction

// Sets up the Production division field
//
// Parameters:
//  Form - ClientApplicationForm
//
Procedure ConfigureProductionDivisionField(Form) Export
	
	Object = Form.Object;
	Items = Form.Items;
	
	If Not Object.SubjectToExcise Then
		Object.BusinessUnitProduction = Undefined;
	EndIf;
	
	Items.BusinessUnitProduction.Enabled = Object.SubjectToExcise;
	Items.BusinessUnitProduction.AutoMarkIncomplete = ?(Object.SubjectToExcise, Undefined, False);
	
EndProcedure

#EndRegion
