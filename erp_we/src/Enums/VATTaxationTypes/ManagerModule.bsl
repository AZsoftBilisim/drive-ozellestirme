#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Causes the value passed to the enumeration to two: Prediabetes or Procaineamide
//
// Parameters:
//  VATTaxation	 - EnumRef.VATTaxationTypes 
// 
// Returns:
//  EnumRef.VATTaxationTypes 
//
Function WithOrWithoutVAT(VATTaxation) Export
	
	If VATTaxation = PreferentialVATTaxationOnSTS Then
		Return VATTaxation;
	ElsIf TypesWithVAT().Find(VATTaxation) <> Undefined Then
		Return Enums.VATTaxationTypes.SaleIsSubjectToVAT;
	ElsIf TypesWithoutVAT().Find(VATTaxation) <> Undefined Then
		Return Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	Else
		
		//Determined by the distribution
		//Commissioning
		//Taxagentponds
		//Reversible Taxing
		ExceptionText = NStr("vi = 'Loại thuế GTGT không được hỗ trợ %VATTaxations%';
							|ru = 'Неподдерживаемый тип налогообложения НДС %VATTaxations%';
							|en = 'Unsupported VAT taxation type %VATTaxations%'; fa = 'Unsupported VAT taxation type %VATTaxations%';
							|it = 'Tipo di IVA non supportato %VATTaxations%';
							|pl = 'Nieobsługiwany rodzaj opodatkowania VAT %VATTaxations%';
							|tr = 'Desteklenmeyen KDV vergilendirmesi türü %VATTaxations%'");
		ExceptionText = StrReplace(ExceptionText, "%VATTaxations%", VATTaxation);
		
		Raise ExceptionText;
		
	EndIf;
	
EndFunction

// Returns an array of VAT tax types that include VAT accounting
// 
// Returns:
//  Array 
//
Function TypesWithVAT() Export
	
	Array = New Array;
	Array.Add(ByActualUsage);
	Array.Add(ExportSale);
	Array.Add(SaleIsSubjectToVAT);
	Array.Add(ExportOfCommoditiesServicesWorks);
	Array.Add(ExportOfNonResourceGoods);
	Array.Add(SubjectToVATAtCustomer);
	Array.Add(ProductionWithLongCycle);
	Array.Add(ExportSalesOfWorkServices);
	Array.Add(SalesAreSubjectToVATInEEU);
	Array.Add(SubjectToVATFromPriceDifference);
	Array.Add(SpaceActivity);
	Array.Add(PreferentialVATTaxationOnSTS);
	
	Return Array;
	
EndFunction

// Returns an array of VAT tax types that do not include VAT accounting
// 
// Returns:
//  Array 
//
Function TypesWithoutVAT() Export
	
	Array = New Array;
	Array.Add(SaleIsNotSubjectToVAT);
	
	Return Array;
	
EndFunction

// Gets a representation of the enumeration value
//
// Parameters:
//  Value - EnumRef.VATTaxationTypes 
//  LanguageCode - String - optional
// 
// Returns:
//  String 
//
Function RepresentationInLanguage(Value, LanguageCode = Undefined) Export
	
	Presentation = "";
	
	If Value = Enums.VATTaxationTypes.SaleIsSubjectToVAT Then
		Presentation = NStr("vi = 'Chịu thuế GTGT';
							|ru = 'Облагается НДС';
							|en = 'Subject to VAT'; fa = 'مشمول مالیات بر ارزش افزوده';
							|it = 'Soggetto ad IVA';
							|pl = 'Podlega VAT';
							|tr = 'Yurtiçi KDV oranları'", LanguageCode);
	ElsIf Value = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
		Presentation = NStr("vi = 'Không chịu thuế GTGT';
							|ru = 'Не облагается НДС';
							|en = 'Not subject to VAT'; fa = 'مشمول مالیات بر ارزش افزوده نیست';
							|it = 'Non soggetto ad IVA';
							|pl = 'Nie podlega VAT';
							|tr = 'KDV''den muaf'", LanguageCode);
	ElsIf Value = Enums.VATTaxationTypes.SaleIsSubjectToUTII Then
		Presentation = NStr("vi = 'Chịu thuế môn bài';
							|ru = 'Облагается ЕНВД';
							|en = 'Subject to UTII'; fa = 'مشمول UTII';
							|it = 'Soggetto a Imposta unica sul reddito imputato';
							|pl = 'Podlega jednolitemu podatkowi od dochodu przy specjalnych rodzajach działalności';
							|tr = 'EGTV''ye tabi'", LanguageCode);
	ElsIf Value = Enums.VATTaxationTypes.ExportSale Then
		Presentation = NStr("vi = 'Xuất khẩu';
							|ru = 'Экспорт';
							|en = 'Export'; fa = 'خروج اطلاعات';
							|it = 'Esportazione';
							|pl = 'Eksport';
							|tr = 'İhracat'", LanguageCode);
	ElsIf Value = Enums.VATTaxationTypes.ExportOfNonResourceGoods Then
		Presentation = NStr("vi = 'Xuất khẩu hàng hóa thô';
							|ru = 'Экспорт несырьевых товаров';
							|en = 'Export of non-resource goods'; fa = 'صادرات کالاهای غیرمنابع';
							|it = 'Esportazione dei beni non primari';
							|pl = 'Eksport towarów niesurowcowych';
							|tr = 'Emtia dışı ürün ihracatı'", LanguageCode);
	ElsIf Value = Enums.VATTaxationTypes.ExportOfCommoditiesServicesWorks Then
		Presentation = NStr("vi = 'Xuất khẩu hàng hóa thô, dịch vụ (công việc)';
							|ru = 'Экспорт сырьевых товаров, услуг (работ)';
							|en = 'Export of commodities, services (works)'; fa = 'صادرات کالاهای اساسی، خدمات (کارها)';
							|it = 'Esportazione delle materie prime, servizi (lavori)';
							|pl = 'Eksport towarów surowcowych, usług (prac)';
							|tr = 'Hammadde, hizmet (iş) ihracatı'", LanguageCode);
	ElsIf Value = Enums.VATTaxationTypes.FixedAssetsCommissioning Then
		Presentation = NStr("vi = 'Đưa tài sản cố định vào sử dụng';
							|ru = 'Ввод ОС в эксплуатацию';
							|en = 'Fixed assets commissioning'; fa = 'Fixed assets commissioning';
							|it = 'Messa del Capitale Fisso in esercizio';
							|pl = 'Wprowadzanie środków trwałych w eksploatacji';
							|tr = 'SV kullanıma transferi'", LanguageCode);
	EndIf;
	
	Return Presentation;
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ChoiceParameters = New Structure("Sales, Purchases, SeparateAccounting", True, True, True);
	FillPropertyValues(ChoiceParameters, Parameters);
	
	StandardProcessing = False;
	ChoiceData = New ValueList();
	AvailableTypesOfTaxation = VATAccountingERPClientServer.ApplicableTypesOfVATTaxation(
		ChoiceParameters.Sales,
		ChoiceParameters.Purchases,
		ChoiceParameters.SeparateAccounting);
		
	For Each Item In AvailableTypesOfTaxation Do
		ChoiceData.Add(Item.Value, Item.Presentation);
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
