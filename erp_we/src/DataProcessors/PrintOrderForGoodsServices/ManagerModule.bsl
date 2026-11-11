#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	SynonymForCustomerSOrderTemplate = NStr("vi = 'Đơn hàng của khách';
											|ru = 'Заказ клиента';
											|en = 'Sales order'; fa = 'سفارش فروش';
											|it = 'Ordine del cliente';
											|pl = 'Zamówienie klienta';
											|tr = 'Satış siparişi'");
	If CommonClientServer.StructureProperty(PrintParameters, "UseSynonymForKit", False) Then
		SynonymForCustomerSOrderTemplate = PrintParameters.SynonymForTemplateForKit;
	EndIf;
	
	StructureOfTypes = TMCommonUse.MatchingArraysByObjectType(ObjectsArray);
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SalesOrder") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"SalesOrder",
			SynonymForCustomerSOrderTemplate,
			GeneratePrintedCustomerOrderForm(StructureOfTypes, PrintObjects, PrintParameters, OutputParameters.LanguageCode),,
			"DataProcessor.PrintOrderForGoodsServices.PF_MXL_SalesOrder");
		
		PrintFormDetails = PrintFormsCollection.Find(Upper("SalesOrder"), "UpperCaseName");
		If PrintFormDetails <> Undefined Then
			PrintFormDetails.OutputInOtherLanguagesAvailable = True;
		EndIf;
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CustomerOrderWithoutDiscounts") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CustomerOrderWithoutDiscounts",
			SynonymForCustomerSOrderTemplate,
			GeneratePrintedCustomerOrderForm(StructureOfTypes, PrintObjects, PrintParameters, OutputParameters.LanguageCode),,
			"DataProcessor.PrintOrderForGoodsServices.PF_MXL_SalesOrder");
		
		PrintFormDetails = PrintFormsCollection.Find(Upper("CustomerOrderWithoutDiscounts"), "UpperCaseName");
		If PrintFormDetails <> Undefined Then
			PrintFormDetails.OutputInOtherLanguagesAvailable = True;
		EndIf;
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PurchaseOrder") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"PurchaseOrder",
			NStr("vi = 'Đơn hàng đặt nhà cung cấp';
				|ru = 'Заказ поставщику';
				|en = 'Purchase order'; fa = 'سفارش خرید';
				|it = 'Ordine al fornitore';
				|pl = 'Zamówienie do dostawcy';
				|tr = 'Satın alma siparişi'"),
			CreatePrintedOrderFormForSupplier(StructureOfTypes, PrintObjects, PrintParameters, OutputParameters.LanguageCode),,
			"DataProcessor.PrintOrderForGoodsServices.PF_MXL_PurchaseOrder");
		
		PrintFormDetails = PrintFormsCollection.Find(Upper("PurchaseOrder"), "UpperCaseName");
		If PrintFormDetails <> Undefined Then
			PrintFormDetails.OutputInOtherLanguagesAvailable = True;
		EndIf;
		
	EndIf;
	
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "OrderToGiverOnRawMaterials") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"OrderToGiverOnRawMaterials",
			NStr("vi = 'Đơn hàng của người đặt gia công nguyên vật liệu';
				|ru = 'Заказ давальцу на сырье и материалы';
				|en = 'Material provider order for raw and consumable materials'; fa = 'Material provider order for raw and consumable materials';
				|it = 'Ordine al committente di materie prime e i materiali';
				|pl = 'Zamówienie właścicielowi surowców na materiały';
				|tr = 'Sağlayıcıya hammadde ve malzeme siparişi'"),
			CreatePrintedOrderFormForGiver2_5ForRawMaterials(StructureOfTypes, PrintObjects, PrintParameters, OutputParameters.LanguageCode),,
			"Document.MaterialProviderOrder2_5.PF_MXL_MaterialProviderOrder");
		
		PrintFormDetails = PrintFormsCollection.Find(Upper("OrderToGiverOnRawMaterials"), "UpperCaseName");
		If PrintFormDetails <> Undefined Then
			PrintFormDetails.OutputInOtherLanguagesAvailable = True;
		EndIf;
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "OrderingGiverForServices") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"OrderingGiverForServices",
			NStr("vi = 'Đơn hàng của người đặt gia công dịch vụ xuất xưởng sản phẩm';
				|ru = 'Заказ давальца на услуги по выпуску продукции';
				|en = 'Subcontracting sales order for product release services'; fa = 'Subcontracting sales order for product release services';
				|it = 'Ordine del committente per servizi di emissione prodotti';
				|pl = 'Zamówienie właścicielowi surowców na usługi dotyczące wypuszczenia produkcji';
				|tr = 'Ürün üretim hizmetleri için sağlayıcı siparişi'"),
			CreatePrintedFormOfGiverS2_5OrderForServices(StructureOfTypes, PrintObjects, PrintParameters, OutputParameters.LanguageCode),,
			"Document.MaterialProviderOrder2_5.PF_MXL_MaterialProviderOrder");
		
		PrintFormDetails = PrintFormsCollection.Find(Upper("OrderingGiverForServices"), "UpperCaseName");
		If PrintFormDetails <> Undefined Then
			PrintFormDetails.OutputInOtherLanguagesAvailable = True;
		EndIf;
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ProcessorSOrderForRawMaterials2_5") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ProcessorSOrderForRawMaterials2_5",
			NStr("vi = 'Đơn đặt hàng gia công nguyên liệu';
				|ru = 'Заказ переработчика на сырье и материалы';
				|en = 'Subcontract order for raw and consumable materials'; fa = 'Subcontract order for raw and consumable materials';
				|it = 'Ordine del subfornitore per le materie prime e i materiali';
				|pl = 'Zamówienie od przetwórcy na materiały';
				|tr = 'Fason üreticinin hammadde ve malzeme siparişi'"),
			CreatePrintedFormOfProcessorSOrderForRawMaterials2_5(StructureOfTypes, PrintObjects, PrintParameters, OutputParameters.LanguageCode),,
			"Document.SubcontractOrder2_5.PF_MXL_SubcontractOrder2_5");
		
		PrintFormDetails = PrintFormsCollection.Find(Upper("ProcessorSOrderForRawMaterials2_5"), "UpperCaseName");
		If PrintFormDetails <> Undefined Then
			PrintFormDetails.OutputInOtherLanguagesAvailable = True;
		EndIf;
		
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SubcontractServicesOrder2_5") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"SubcontractServicesOrder2_5",
			NStr("vi = 'Đặt hàng cho gia công cho các dịch vụ sản xuất';
				|ru = 'Заказ переработчику на услуги по выпуску продукции';
				|en = 'Subcontracting purchase order for product release services'; fa = 'Subcontracting purchase order for product release services';
				|it = 'Ordine al subfornitore per i servizi di emissione prodotti';
				|pl = 'Zamów procesor dla usług produkcyjnych';
				|tr = 'Üretim hizmetleri için verilen fason satın siparişi'"),
			CreatePrintedOrderFormForProcessorForServices2_5(StructureOfTypes, PrintObjects, PrintParameters, OutputParameters.LanguageCode),,
			"Document.SubcontractOrder2_5.PF_MXL_SubcontractServicesOrder2_5");
		
		PrintFormDetails = PrintFormsCollection.Find(Upper("SubcontractServicesOrder2_5"), "UpperCaseName");
		If PrintFormDetails <> Undefined Then
			PrintFormDetails.OutputInOtherLanguagesAvailable = True;
		EndIf;
		
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, StructureOfTypes, PrintFormsCollection);
	
EndProcedure

Function GeneratePrintedCustomerOrderForm(StructureOfTypes, PrintObjects, PrintParameters, LanguageCode = Undefined) Export
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	SpreadsheetDocument.FitToPage			= True;
	SpreadsheetDocument.PageOrientation	= PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName	= "PRINT_OPTIONS_SalesOrder";
	
	DocumentTypeNumber = 0;
	
	For Each ObjectsStructure In StructureOfTypes Do
			
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		
		// Data for an array of objects
		DataForPrint = ObjectManager.GetDataForPrintedOrderFormForGoodsServices(
			ObjectsStructure.Value,
			PrintParameters,
			LanguageCode);
		
		// Generated personal document
		FillInTabularDocumentOfOrderForGoodsServices(
			SpreadsheetDocument,
			DataForPrint,
			PrintObjects,
			"DataProcessor.PrintOrderForGoodsServices.PF_MXL_SalesOrder",
			LanguageCode);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function CreatePrintedOrderFormForSupplier(StructureOfTypes, PrintObjects, PrintParameters, LanguageCode = Undefined) Export
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	SpreadsheetDocument.FitToPage			= True;
	SpreadsheetDocument.PageOrientation	= PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName	= "PRINT_OPTIONS_PurchaseOrder";
	
	DocumentTypeNumber = 0;
	
	For Each ObjectsStructure In StructureOfTypes Do
			
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		
		// Data for an array of objects
		DataForPrint = ObjectManager.GetDataForPrintedOrderFormForGoodsServices(
			ObjectsStructure.Value,
			PrintParameters,
			LanguageCode);
		
		// Generated personal document                    
		FillInTabularDocumentOfOrderForGoodsServices(
			SpreadsheetDocument,
			DataForPrint,
			PrintObjects,
			"DataProcessor.PrintOrderForGoodsServices.PF_MXL_PurchaseOrder",
			LanguageCode);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction


Function CreatePrintedOrderFormForGiver2_5ForRawMaterials(StructureOfTypes, PrintObjects, PrintParameters, LanguageCode = Undefined) Export
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	SpreadsheetDocument.FitToPage			= True;
	SpreadsheetDocument.PageOrientation	= PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName	= "PRINT_OPTIONS_OrderGiver2_5ForRawMaterials";
	
	DocumentTypeNumber = 0;
	
	For Each ObjectsStructure In StructureOfTypes Do
			
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		
		// Data for an array of objects
		DataForPrint = ObjectManager.GetDataForPrintedOrderFormForRawMaterials(
			ObjectsStructure.Value,
			PrintParameters,
			LanguageCode);
		
		// Generated personal document
		FillInTabularDocumentOfOrderForGoodsServices(
			SpreadsheetDocument,
			DataForPrint,
			PrintObjects,
			"Document.MaterialProviderOrder2_5.PF_MXL_MaterialProviderOrder",
			LanguageCode);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function CreatePrintedFormOfGiverS2_5OrderForServices(StructureOfTypes, PrintObjects, PrintParameters, LanguageCode = Undefined) Export
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	SpreadsheetDocument.FitToPage			= True;
	SpreadsheetDocument.PageOrientation	= PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName	= "PRINT_OPTIONS_OrderingGiver2_5ForServices";
	
	DocumentTypeNumber = 0;
	
	For Each ObjectsStructure In StructureOfTypes Do
			
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		
		// Data for an array of objects
		DataForPrint = ObjectManager.GetDataForPrintedServiceOrderForm(
			ObjectsStructure.Value,
			PrintParameters,
			LanguageCode);
		
		// Generated personal document
		FillInTabularDocumentOfOrderForGoodsServices(
			SpreadsheetDocument,
			DataForPrint,
			PrintObjects,
			"Document.MaterialProviderOrder2_5.PF_MXL_MaterialProviderOrder",
			LanguageCode);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction


Function CreatePrintedFormOfProcessorSOrderForRawMaterials2_5(StructureOfTypes, PrintObjects, PrintParameters, LanguageCode = Undefined) Export
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	SpreadsheetDocument.FitToPage			= True;
	SpreadsheetDocument.PageOrientation	= PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName	= "PRINT_OPTIONS_ProcessorSOrderForRawMaterials2_5";
	
	DocumentTypeNumber = 0;
	
	For Each ObjectsStructure In StructureOfTypes Do
			
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		
		// Data for an array of objects
		DataForPrint = ObjectManager.GetDataForPrintedOrderFormForRawMaterials(
			ObjectsStructure.Value,
			PrintParameters,
			LanguageCode);
		
		// Generated personal document
		FillInTabularDocumentOfOrderForGoodsServices(
			SpreadsheetDocument,
			DataForPrint,
			PrintObjects,
			"Document.SubcontractOrder2_5.PF_MXL_SubcontractOrder2_5",
			LanguageCode);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function CreatePrintedOrderFormForProcessorForServices2_5(StructureOfTypes, PrintObjects, PrintParameters, LanguageCode = Undefined) Export
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	SpreadsheetDocument.FitToPage			= True;
	SpreadsheetDocument.PageOrientation	= PageOrientation.Portrait;
	SpreadsheetDocument.PrintParametersName	= "PRINT_OPTIONS_SubcontractServicesOrder2_5";
	
	DocumentTypeNumber = 0;
	
	For Each ObjectsStructure In StructureOfTypes Do
			
		DocumentTypeNumber = DocumentTypeNumber + 1;
		If DocumentTypeNumber > 1 Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		ObjectManager = Common.ObjectManagerByFullName(ObjectsStructure.Key);
		
		// Data for an array of objects
		DataForPrint = ObjectManager.GetDataForPrintedServiceOrderForm(
			ObjectsStructure.Value,
			PrintParameters,
			LanguageCode);
		
		// Generated personal document
		FillInTabularDocumentOfOrderForGoodsServices(
			SpreadsheetDocument,
			DataForPrint,
			PrintObjects,
			"Document.SubcontractOrder2_5.PF_MXL_SubcontractServicesOrder2_5",
			LanguageCode);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#Region PrintingOrderToPartnerFromPartnerForGoodsWorksOrServices

// Parameters:
//	SpreadsheetDocument           - SpreadsheetDocument -
//	DataForPrint             - Structure - It contains data on the document header, payment stages, and tabular part:
//		* HeaderResults          - QueryResult -
//		* ResultsByPaymentStages   - QueryResult -
//		* ResultForTabularPart - QueryResult -
//	PrintObjects               - See PrintManagementOverridable.OnPrint.PrintObjects
//	TemplateName                   - String -
//	LanguageCode                    - String, Undefined -
//
Procedure FillInTabularDocumentOfOrderForGoodsServices(SpreadsheetDocument, DataForPrint, PrintObjects, TemplateName, LanguageCode)
	
	ErrorPatternProducts	= NStr("vi = 'Trong chứng từ %1 không có hàng hóa. Không cần in %2';
									|ru = 'В документе %1 отсутствуют товары. Печать %2 не требуется';
									|en = 'Goods are missing in document %1. Printing of %2 is not required'; fa = 'Goods are missing in document %1. Printing of %2 is not required';
									|it = 'Il documento %1 non contiene le merci. Nessuna stampa %2 richiesta';
									|pl = 'W dokumencie %1 nie ma towarów. Wydruk %2 nie jest wymagany';
									|tr = 'Belge %1''de mal bulunmamaktadır. %2 yazdırılması gerekli değildir'");
	
	PrintData	= DataForPrint.HeaderResults.Select();
	PaymentSteps		= DataForPrint.ResultsByPaymentStages.Unload();
	Goods			= DataForPrint.ResultForTabularPart.Unload();
	
	FirstDocument	= True;
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = Not IsBlankString(NameOfCodeColumn);
	
	PFFillingParameters = New Structure;
	PFFillingParameters.Insert("ErrorPatternProducts", ErrorPatternProducts);
	PFFillingParameters.Insert("NameOfCodeColumn", NameOfCodeColumn);
	PFFillingParameters.Insert("PresentationOfCodesColumn", PresentationOfCodesColumn);
	PFFillingParameters.Insert("OutputCodes", OutputCodes);
	PFFillingParameters.Insert("PrintData", PrintData);
	PFFillingParameters.Insert("PaymentSteps", PaymentSteps);
	PFFillingParameters.Insert("Goods", Goods);
	
	While PrintData.Next() Do
		
		Template = PrintManagement.PrintFormTemplate(TemplateName, LanguageCode);
		
		PFFillingParameters.Insert("Template", Template);
		
		// code separation has been performed for compatibility with manually edited user Templates in versions up to 2.5.10
		If Not Template.Areas.Find("Template_2_5_10") = Undefined Then
			                                               // adapted for translation
			FillInTabularDocumentOfOrderForGoodsServicesAdaptedForTranslation(SpreadsheetDocument, PFFillingParameters, PrintObjects, FirstDocument, LanguageCode);
			
		Else
			                                               // not adapted
			FillInTabularDocumentOfOrderForGoodsServicesBefore_2_5_10(SpreadsheetDocument, PFFillingParameters, PrintObjects, FirstDocument, LanguageCode);
			
		EndIf;
		
	EndDo;
	
EndProcedure


Procedure FillInTabularDocumentOfOrderForGoodsServicesAdaptedForTranslation(SpreadsheetDocument, PFFillingParameters, PrintObjects, FirstDocument, LanguageCode)
	
	ErrorPatternProducts = PFFillingParameters.ErrorPatternProducts;
	Template = PFFillingParameters.Template;
	NameOfCodeColumn = PFFillingParameters.NameOfCodeColumn;
	OutputCodes = PFFillingParameters.OutputCodes;
	PrintData = PFFillingParameters.PrintData;
	PaymentSteps = PFFillingParameters.PaymentSteps;
	Goods = PFFillingParameters.Goods;
	
	TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
	
	GoodsTable = Goods.FindRows(TheStructureOfTheSearch);
	
	If GoodsTable.Count() = 0 Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		ErrorPatternProducts,
		PrintData.Ref,
		PrintData.PresentationInError);
		
		Common.MessageToUser(ErrorText, PrintData.Ref);
		Return;
		
	EndIf;
	
	PaymentStagesTable = PaymentSteps.FindRows(TheStructureOfTheSearch);
	
	If FirstDocument Then
		FirstDocument = False;
	Else
		SpreadsheetDocument.PutHorizontalPageBreak();
	EndIf;
	
	RowNumberStart = SpreadsheetDocument.TableHeight + 1;
	
	ThereAreMargins = False;
	ThereAreDiscounts  = False;
	
	If PrintData.UseAutoDiscounts Then
		
		For Each RowOfGoods In Goods Do
			If RowOfGoods.DiscountAmount>0 Then
				ThereAreDiscounts = True;
				Break;
			EndIf;
		EndDo;
		
		For Each RowOfGoods In Goods Do
			If RowOfGoods.DiscountAmount<0 Then
				ThereAreMargins = True;
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
	DisplayPriceType = False;
	For Each LineProducts_ In GoodsTable Do
		
		If ValueIsFilled(LineProducts_.TypeOfContractorSPrice) Then
			DisplayPriceType = True;
			Break;
		EndIf;
		
	EndDo;
	
	DiscountsSettingUp = New Structure;
	DiscountsSettingUp.Insert("ThereAreDiscounts", ThereAreMargins Or ThereAreDiscounts);
	DiscountsSettingUp.Insert("ThereIsDiscount", ThereAreDiscounts);
	DiscountsSettingUp.Insert("ThereIsMarkUp", ThereAreMargins);
	ThereAreDiscounts = ThereAreMargins Or ThereAreDiscounts;
	
	ShowVAT	= PrintData.ShowNDSInRows And PrintData.ConsiderVAT;
	
#Region DefiningAreaHeaderNames
	
	ThereIsAdditionalParameter		= ThereAreDiscounts Or ShowVAT;
	DoubleDOPParameter	= ThereAreDiscounts And ShowVAT;
	
	ColumnAreas = ColumnAreaNames(DoubleDOPParameter, ThereIsAdditionalParameter);
	
	ProductColumnArea = Template.Area(ColumnAreas.OwnGoods);
	
	If Not OutputCodes Then
		
		If DoubleDOPParameter Then
			ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.35;
		ElsIf ThereIsAdditionalParameter Then
			ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.2;
		Else
			ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.14;
		EndIf;
		
	EndIf;
	
	StringAreas = NamesOfLineAreas(DiscountsSettingUp, DisplayPriceType, ShowVAT);
	
#EndRegion
	
#Region TemplateAreas
	
	// AREAS OF THE "PRODUCTS" TABLE
	StructureAreaOfHeaderCodes = New Structure("Code, SKU");
	
	HeaderNumberArea = Template.GetArea(StringAreas.TableHeader + "|LineNumber");
	StructureAreaOfHeaderCodes.Code = Template.GetArea(StringAreas.TableHeader + "|ColumnCode");
	StructureAreaOfHeaderCodes.SKU = Template.GetArea(StringAreas.TableHeader + "|ColumnArticle");
	HeaderCodeArea = ?(OutputCodes, StructureAreaOfHeaderCodes[NameOfCodeColumn], Undefined);
	
	HeaderArea_1 = Template.GetArea(StringAreas.TableHeader + "|" + ColumnAreas.OwnGoods);
	HeaderDataArea_ = Template.GetArea(StringAreas.TableHeader + "|" + ColumnAreas.Data);
	
	LineNumberAreaStandard = Template.GetArea(StringAreas.TableRow + "|LineNumber");
	ScopeOfStringCodesStandard  = Template.GetArea(StringAreas.TableRow + "|ColumnCode");
	ProductAreaRowsStandard  = Template.GetArea(StringAreas.TableRow + "|" + ColumnAreas.OwnGoods);
	DataAreaOfStringIsStandard = Template.GetArea(StringAreas.TableRow + "|" + ColumnAreas.Data);
	
	UseSets = False;
	If Goods.Columns.Find("IsRecordsSet") <> Undefined Then
		UseSets = True;
		LineNumberAreaSet         = Template.GetArea(StringAreas.TableRow + "|LineNumber");
		LineNumberAreaComponents = Template.GetArea(StringAreas.TableRow + "|LineNumber");
		StringCodeAreaSet          = Template.GetArea(StringAreas.TableRow + "|ColumnCode");
		StringCodeAreaComponents  = Template.GetArea(StringAreas.TableRow + "|ColumnCode");
		ProductAreaRowsSet          = Template.GetArea(StringAreas.TableRow + "|" + ColumnAreas.OwnGoods);
		ProductAreaRowsComponents  = Template.GetArea(StringAreas.TableRow + "|" + ColumnAreas.OwnGoods);
		RowDataAreaSet         = Template.GetArea(StringAreas.TableRow + "|" + ColumnAreas.Data);
		RowDataAreaComponents = Template.GetArea(StringAreas.TableRow + "|" + ColumnAreas.Data);
	EndIf;
	
	BasementRoomArea	= Template.GetArea(StringAreas.TableFooter + "|LineNumber");
	BasementCodeArea		= Template.GetArea(StringAreas.TableFooter + "|ColumnCode");
	BasementStorageArea		= Template.GetArea(StringAreas.TableFooter + "|" + ColumnAreas.OwnGoods);
	BasementDataArea	= Template.GetArea(StringAreas.TableFooter + "|" + ColumnAreas.Data);
	
	If Not PrintData.Type = "SubcontractServicesOrder" Then
		
		VATNumberArea = Template.GetArea("VATTableBasement|LineNumber");
		ScopeOfVATCodes = Template.GetArea("VATTableBasement|ColumnArticle");
		
		AreaVATData = Template.GetArea("VATTableBasement|VATData");
		AreaOfVATDataIsCalculatedByTaxAgent = Template.GetArea("BasementOfVATTableIsCalculatedByTaxAgent|VATData");
		AreaDataWithoutVAT = Template.GetArea("BasementTableVATWithoutVAT|VATData");
		AreaVCHNDSData = Template.GetArea("BasementOfVTCHNDSTable|VATData");
		
	EndIf;
	
	RegionAmountInWords = Template.GetArea("AmountInWords");
	
#EndRegion
	
#Region HeaderOutput
	
	// Header - Header
	If PrintData.Type = "OrderingGiverForServices" Then
		
		TemplateArea = Template.GetArea("TitleGiverSOrderForServices");
		
	ElsIf  PrintData.Type = "OrderToGiverOnRawMaterials" Then
		
		TemplateArea = Template.GetArea("HeadingOrderToGiverForRawMaterials");
		
	Else
		
		TemplateArea = Template.GetArea("Title");
		
	EndIf;
	
	PrintFormGeneration.PrintLogoInTabularDocument(Template, TemplateArea, "TitleLogo", PrintData.Organization);
	
	HeaderDataStructure_1 = New Structure;
	HeaderDataStructure_1.Insert("DocumentNumber", ObjectsPrefixesClientServer.NumberForPrinting(PrintData.Number));
	HeaderDataStructure_1.Insert("DocumentDate", Format(PrintData.Date, StrTemplate("L=%1;DLF=DD", LanguageCode)));
	
	TemplateArea.Parameters.Fill(HeaderDataStructure_1);
	
	BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
	SpreadsheetDocument,
	Template,
	TemplateArea,
	PrintData.Ref);
	
	SpreadsheetDocument.Put(TemplateArea);
	
	// THE PERFORMER 'S HAT
	
	TemplateArea = Template.GetArea("Performer");
	SetParameter(TemplateArea, "ArtistPresentation", OrganizationDescription(PrintData, "Performer", LanguageCode));
	SpreadsheetDocument.Put(TemplateArea);
	
	// CUSTOMER HEADER
	
	TemplateArea = Template.GetArea("Customer_");
	SetParameter(TemplateArea, "CustomerPresentation_0", OrganizationDescription(PrintData, "Customer_", LanguageCode));
	SpreadsheetDocument.Put(TemplateArea);
	
	// THE HEADER IS THE SHIPPER
	
	If ValueIsFilled(PrintData.Shipper) Then
		TemplateArea = Template.GetArea("Shipper");
		SetParameter(TemplateArea, "ShipperPresentation", OrganizationDescription(PrintData, "Shipper", LanguageCode));
		SpreadsheetDocument.Put(TemplateArea);
	EndIf;
	
	// THE HEADER IS THE CONSIGNEE
	
	If ValueIsFilled(PrintData.GoodsRecipient) Then
		TemplateArea = Template.GetArea("GoodsRecipient");
		SetParameter(TemplateArea, "PresentationOfConsignee", OrganizationDescription(PrintData, "GoodsRecipient", LanguageCode));
		SpreadsheetDocument.Put(TemplateArea);
	EndIf;
	
	// HEADER - DELIVERY ADDRESS
	
	If ValueIsFilled(PrintData.DeliveryAddress) Then
		TemplateArea = Template.GetArea("DeliveryAddress");
		SetParameter(TemplateArea, "DeliveryAddress", PrintData.DeliveryAddress);
		SpreadsheetDocument.Put(TemplateArea);
	EndIf;
	
#EndRegion
	
#Region OutputOfProductsTable
	
	// THE PRODUCTS - LINES TABLE
	
	OutputValidationArray = New Array;
	OutputValidationArray.Add(HeaderNumberArea);
	OutputValidationArray.Add(BasementRoomArea);
	If ShowVAT Then
		OutputValidationArray.Add(VATNumberArea);
	EndIf;
	OutputValidationArray.Add(RegionAmountInWords);
	
	Sum			= 0;
	VATAmount		= 0;
	TotalOfDiscounts		= 0;
	TotalWithoutDiscounts	= 0;
	
	LineNumber = 0;
	
	BlankData = SetsServer.BlankData();
	HeaderOutput = 0;
	
	ComplianceWithVATRates = New Map;
	
	For Each LineProducts_ In GoodsTable Do
		
		If SetsServer.UseSetArea(LineProducts_, UseSets) Then
			StringCodeArea   = StringCodeAreaSet;
			LineNumberArea  = LineNumberAreaSet;
			RowDataArea  = RowDataAreaSet;
			ProductAreaRows   = ProductAreaRowsSet;
		ElsIf SetsServer.UseScope(LineProducts_, UseSets) Then
			StringCodeArea   = StringCodeAreaComponents;
			LineNumberArea  = LineNumberAreaComponents;
			RowDataArea  = RowDataAreaComponents;
			ProductAreaRows   = ProductAreaRowsComponents;
		Else
			StringCodeArea   = ScopeOfStringCodesStandard;
			LineNumberArea  = LineNumberAreaStandard;
			RowDataArea  = DataAreaOfStringIsStandard;
			ProductAreaRows   = ProductAreaRowsStandard;
		EndIf;
		
		If SetsServer.DisplayOnlyTitle(LineProducts_, UseSets) Then
			SetParameter(LineNumberArea, "LineNumber", Undefined);
		Else
			LineNumber = LineNumber + 1;
			SetParameter(LineNumberArea, "LineNumber", LineNumber);
		EndIf;
		
		If LineNumber = 0 And HeaderOutput <> 2 Then
			HeaderOutput = 1;
		EndIf;
		
		OutputValidationArray.Add(LineNumberArea);
		
		If SpreadsheetDocument.CheckPut(OutputValidationArray) Then
			
			If (LineNumber = 1 And HeaderOutput = 0) Or (LineNumber = 0 And HeaderOutput = 1) Then
				
				HeaderOutput = 2;
				
				OutputHeader(SpreadsheetDocument, HeaderNumberArea, HeaderCodeArea, HeaderArea_1, HeaderDataArea_, OutputCodes);
				OutputValidationArray.Delete(0);
				
			EndIf;
			
		Else
			
			SpreadsheetDocument.PutHorizontalPageBreak();
			OutputHeader(SpreadsheetDocument, HeaderNumberArea, HeaderCodeArea, HeaderArea_1, HeaderDataArea_, OutputCodes);
			
		EndIf;
		
		OutputValidationArray.Delete(OutputValidationArray.UBound());
		
		SetParameter(LineNumberArea, "LineNumber", LineNumber);
		SpreadsheetDocument.Put(LineNumberArea);
		
		If OutputCodes Then
			
			ColumnName = NameOfCodeColumn;
			If PrintData.Type = "PurchaseOrderBySupplierData" Then
				If ColumnName = "Code" Then
					ColumnName = "ArtistCode";
				ElsIf ColumnName = "SKU" Then
					ColumnName = "ArtistSArticle";
				Else
					ColumnName = "Assignee"
				EndIf;
			EndIf;
			
			SetParameter(StringCodeArea, "SKU", LineProducts_[ColumnName]);
			SpreadsheetDocument.Join(StringCodeArea);
			
		EndIf;
		
		If PrintData.Type = "PurchaseOrderBySupplierData" Then
			
			PresentationOfProductsForPrinting = LineProducts_.NameOfContractorSProductList;
			
		Else
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.ReturnContainers = LineProducts_.ThisIsReusablePackage;				
			AdditionalParametersForGettingNameToPrint.Content = LineProducts_.Content;				
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			PresentationOfProductsForPrinting = ProductsClientServer.PresentationOfProductsForPrinting(
			LineProducts_.DescriptionFull,
			LineProducts_.Characteristic,
			,
			,
			AdditionalParametersForGettingNameToPrint);
			
		EndIf;
		
		PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(LineProducts_, UseSets);
		SetParameter(ProductAreaRows, "OwnGoods", PrefixAndPostfix.Prefix + PresentationOfProductsForPrinting + PrefixAndPostfix.Postfix);
		
		If DisplayPriceType Then
			SetParameter(ProductAreaRows, "TypeOfContractorSPrice", LineProducts_.TypeOfContractorSPrice);
		EndIf;
		
		SpreadsheetDocument.Join(ProductAreaRows);
		RowDataArea.Parameters.Fill(LineProducts_);
		
		If ThereAreDiscounts Then
			SetParameter(RowDataArea, "AmountWithoutADiscount", LineProducts_.AmountWithoutADiscount);
			SetParameter(RowDataArea, "DiscountAmount", ?(DiscountsSettingUp.ThereIsMarkUp And Not DiscountsSettingUp.ThereIsDiscount, - LineProducts_.DiscountAmount, LineProducts_.DiscountAmount));
		EndIf;
		
		If SetsServer.DisplayOnlyTitle(LineProducts_, UseSets) Then
			RowDataArea.Parameters.Fill(BlankData);
		Else
			RowDataArea.Parameters.Fill(LineProducts_);
		EndIf;
		
		If PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
			SetParameter(RowDataArea, "VATRate", Template.Areas.TextOfVATIsCalculatedByTaxTemplate.Text);
		EndIf;
		
		SpreadsheetDocument.Join(RowDataArea);
		
		If Not SetsServer.UseScope(LineProducts_, UseSets) Then
			Sum    = Sum    + LineProducts_.Sum;
			VATAmount = VATAmount + LineProducts_.VATAmount;
			
			If ThereAreDiscounts Then
				TotalOfDiscounts    = TotalOfDiscounts    + LineProducts_.DiscountAmount;
				TotalWithoutDiscounts = TotalWithoutDiscounts + LineProducts_.AmountWithoutADiscount;
			EndIf;
			
			If PrintData.ConsiderVAT Then
				
				AmountOfVATAtRate = ComplianceWithVATRates[LineProducts_.VATRate];
				
				If AmountOfVATAtRate = Undefined Then
					AmountOfVATAtRate = 0;
				EndIf;
				
				If PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
					ComplianceWithVATRates.Insert(PredefinedValue("Catalog.VATRates.EXCLUDINGVAT"), AmountOfVATAtRate + LineProducts_.VATAmount);
				Else
					ComplianceWithVATRates.Insert(LineProducts_.VATRate, AmountOfVATAtRate + LineProducts_.VATAmount);
				EndIf;
				
			EndIf;
		EndIf;
		
	EndDo;
	
	// TABLE PRODUCTS - BASEMENT
	
	SpreadsheetDocument.Put(BasementRoomArea);
	
	If OutputCodes Then
		SpreadsheetDocument.Join(BasementCodeArea);
	EndIf;
	
	SpreadsheetDocument.Join(BasementStorageArea);
	
	If ThereAreDiscounts Then
		SetParameter(BasementDataArea, "TotalOfDiscounts", ?(DiscountsSettingUp.ThereIsMarkUp And Not DiscountsSettingUp.ThereIsDiscount, -TotalOfDiscounts, TotalOfDiscounts));
		SetParameter(BasementDataArea, "TotalWithoutDiscounts", TotalWithoutDiscounts);
	EndIf;
	
	SetParameter(BasementDataArea, "Total", PrintFormGeneration.SumFormat(Sum,,,,LanguageCode));
	SpreadsheetDocument.Join(BasementDataArea);
	
	// TABLE PRODUCTS - TOTAL VAT
	If Not PrintData.Type = "SubcontractServicesOrder" Then
		
		If Not PrintData.ConsiderVAT Or PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
			
			SpreadsheetDocument.Put(VATNumberArea);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(ScopeOfVATCodes);
			EndIf;
			
			If PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
				
				VATDataArea = AreaOfVATDataIsCalculatedByTaxAgent;
				
			Else
				
				VATDataArea = AreaDataWithoutVAT;
				
			EndIf;
			SetParameter(VATDataArea, "TotalVAT", "-");
			
			SpreadsheetDocument.Join(VATDataArea);
			
		Else
			
			For Each CurVATRate In ComplianceWithVATRates Do
				
				SpreadsheetDocument.Put(VATNumberArea);
				
				If OutputCodes Then
					
					SpreadsheetDocument.Join(ScopeOfVATCodes);
					
				EndIf;
				
				VATDataArea = ?(PrintData.PriceIncludesVAT, AreaVCHNDSData, AreaVATData);
				
				SetParameter(VATDataArea, "NameOfVATRate", CurVATRate.Key);
				SetParameter(VATDataArea, "TotalVAT", PrintFormGeneration.SumFormat(CurVATRate.Value, , "-",,LanguageCode));
				SpreadsheetDocument.Join(VATDataArea);
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
#EndRegion
	
#Region BasementOutput
	
	// BASEMENT - AMOUNT IN WORDS
	
	AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
	
	SetParameter(RegionAmountInWords, "RowsCount", LineNumber);
	SetParameter(RegionAmountInWords, "TotalAmount__", PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency, LanguageCode));
	SetParameter(RegionAmountInWords, "AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(
	AmountToBeRegistered, PrintData.Currency,, LanguageCode));
	
	SpreadsheetDocument.Put(RegionAmountInWords);
	
	// BASEMENT - STAGES OF THE PAYMENT SCHEDULE
	
	If PaymentStagesTable.Count() > 1 Then
		
		TableHeaderArea_ = Template.GetArea("HeaderOfPaymentStagesTable");
		TableBasementArea_ = Template.GetArea("TotalPaymentStages");
		
		OutputValidationArray.Clear();
		OutputValidationArray.Add(TableHeaderArea_);
		OutputValidationArray.Add(TableBasementArea_);
		
		AreaOfTableRowIsAdvanceToCollateral = Template.GetArea("TableRowStagesOfPaymentAdvancePaymentBeforeCollateral");
		TableRowAreaPrepaymentBeforeShipment = Template.GetArea("TableRowPaymentStagesPrepaymentBeforeShipment");
		AreaOfCreditTableRowAfterShipment = Template.GetArea("TableRowStagesOfPaymentCreditAfterShipment");
		RowAreaOfCreditShiftTable = Template.GetArea("TableRowStagesOfPaymentCreditShift");
		TableRowAreaOptionNotFound = Template.GetArea("RowOfPaymentStagesTableOptionNotFound");
		
		AreaOfTableRowIsAdvanceToProvisionOfTare = Template.GetArea("TableRowStagesOfPaymentAdvancePaymentBeforeSecuringContainer");
		AreaOfTableRowIsPrepaymentBeforeShipmentTare = Template.GetArea("TableRowPaymentStagesPrepaymentBeforeShipmentTare");
		AreaOfCreditTableRowAfterShipmentIsTare = Template.GetArea("TableRowStagesOfPaymentCreditAfterShipmentTare");
		AreaOfTableRowCreditShiftTare = Template.GetArea("TableRowStagesOfPaymentCreditShiftTare");
		TableRowAreaContainerOptionWasNotFound = Template.GetArea("RowOfPaymentStagesTableContainerOptionWasNotFound");
		
		StageNumber = 1;
		VATTextTemplate = Template.Areas.VATTextTemplate.Text;
		NDSVTCHTextTemplate = Template.Areas.NDSVTCHTextTemplate.Text;
		VATTextWithoutTaxTemplate = Template.Areas.VATTextWithoutTaxTemplate.Text;
		For Each CurStage In PaymentStagesTable Do
			
			RowParameters = NewStageLineParameters();
			FillPropertyValues(RowParameters, CurStage);
			RowParameters.LineNumber = StageNumber;
			
			If Not RowParameters.ThisIsDepositForPackage Then
				
				VATText = "";
				
				If ComplianceWithVATRates.Count() > 0 Then
					
					For Each CurVATRate In ComplianceWithVATRates Do
						
						If CurVATRate.Value <> 0 Then
							
							VATText = VATText + ?(IsBlankString(VATText), NDSVTCHTextTemplate, ", " + VATTextTemplate);
							VATText = StrReplace(VATText, "[NameOfVATRate]", CurVATRate.Key);
							VATText = StrReplace(VATText, "[VATAmount]",  Format(CurVATRate.Value / 100 * CurStage.PaymentPercentage, "NFD=2"));
							
						EndIf;
						
					EndDo;
					
				EndIf;
				
				If ValueIsFilled(VATText) Then
					RowParameters.VATText = VATText;
				Else
					RowParameters.VATText = VATTextWithoutTaxTemplate;
				EndIf;
				
				If RowParameters.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision") Then
					
					TableRowArea = AreaOfTableRowIsAdvanceToCollateral;
					
				ElsIf RowParameters.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment") Then
					
					TableRowArea = TableRowAreaPrepaymentBeforeShipment;
					
				ElsIf RowParameters.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditPlanned") Then
					
					TableRowArea = AreaOfCreditTableRowAfterShipment;
					
				ElsIf RowParameters.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment") Then
					
					TableRowArea = RowAreaOfCreditShiftTable;
					
				Else
					
					TableRowArea = TableRowAreaOptionNotFound;
					
				EndIf;
				
			Else
				
				If RowParameters.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision") Then
					
					TableRowArea = AreaOfTableRowIsAdvanceToProvisionOfTare;
					
				ElsIf RowParameters.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment") Then
					
					TableRowArea = AreaOfTableRowIsPrepaymentBeforeShipmentTare;
					
				ElsIf RowParameters.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditPlanned") Then
					
					TableRowArea = AreaOfCreditTableRowAfterShipmentIsTare;
					
				ElsIf RowParameters.PaymentOption = PredefinedValue("Enum.CustomerPaymentControlOptions.CreditAfterShipment") Then
					
					TableRowArea = AreaOfTableRowCreditShiftTare;
					
				Else
					
					TableRowArea = TableRowAreaContainerOptionWasNotFound;
					
				EndIf;
				
				RowParameters.PaymentPercentage = "-";
				RowParameters.VATText = VATTextWithoutTaxTemplate;
				
			EndIf;
			
			TableRowArea.Parameters.Fill(RowParameters);
			
			OutputValidationArray.Add(TableRowArea);
			
			If SpreadsheetDocument.CheckPut(OutputValidationArray) Then
				
				If StageNumber=1 Then
					SpreadsheetDocument.Put(TableHeaderArea_);
					OutputValidationArray.Delete(0);
				EndIf;
				
			Else
				
				SpreadsheetDocument.PutHorizontalPageBreak();
				SpreadsheetDocument.Put(TableHeaderArea_);
				
			EndIf;
			
			OutputValidationArray.Delete(OutputValidationArray.UBound());
			
			SpreadsheetDocument.Put(TableRowArea);
			
			StageNumber = StageNumber + 1;
			
		EndDo;
		
		SpreadsheetDocument.Put(TableBasementArea_);
		
	EndIf;
	
	// BASEMENT - ADDITIONAL INFORMATION
	
	If ValueIsFilled(PrintData.AdditionalInformation) Then
		
		TemplateArea = Template.GetArea("AdditionalInformation");
		SetParameter(TemplateArea, "AdditionalInformation", PrintData.AdditionalInformation);
		SpreadsheetDocument.Put(TemplateArea);
		
	EndIf;
	
	// BASEMENT - SIGNATURES
	
	TemplateArea = Template.GetArea("BasementOfOrder");
	SetParameter(TemplateArea, "ManagerSFullName", PersonsTM.IndividualShortName(PrintData.Manager, PrintData.Date));
	SpreadsheetDocument.Put(TemplateArea);
	
#EndRegion
	
	PrintManagement.SetDocumentPrintArea(
		SpreadsheetDocument,
		RowNumberStart,
		PrintObjects,
		PrintData.Ref);
	
EndProcedure

Function NamesOfLineAreas(DiscountsSettingUp, DisplayPriceType, ShowVAT)

	ReturnStructure = New Structure(
		"TableHeader, TableRow, TableRowSet, TableRowComponents, TableFooter");
	
	If DiscountsSettingUp.ThereAreDiscounts And DisplayPriceType Then
		
		If DiscountsSettingUp.ThereIsDiscount
			And DiscountsSettingUp.ThereIsMarkUp Then
			
			ReturnStructure.TableHeader = "HeaderOfTableWithConditionWithDiscountDiscountMarkUp";
			
		ElsIf DiscountsSettingUp.ThereIsDiscount Then
			
			ReturnStructure.TableHeader = "HeaderOfTableWithConditionWithDiscountDiscount";
			
		ElsIf DiscountsSettingUp.ThereIsMarkUp Then
			
			ReturnStructure.TableHeader = "HeaderOfTableWithConditionWithDiscountMarkUp";
			
		EndIf;
		
		ReturnStructure.TableRow = "TableRowWithDiscountCondition";
		ReturnStructure.TableRowSet = "TableRowWithDiscountConditionSet";
		ReturnStructure.TableRowComponents = "TableRowWithDiscountConditionComponents";
		ReturnStructure.TableFooter = "TableBasementWithDiscountCondition";
		
	ElsIf DiscountsSettingUp.ThereAreDiscounts And ShowVAT Then
		
		If DiscountsSettingUp.ThereIsDiscount
			And DiscountsSettingUp.ThereIsMarkUp Then
			
			ReturnStructure.TableHeader = "TableHeaderWithVATWithDiscountDiscountMarkUp";
			
		ElsIf DiscountsSettingUp.ThereIsDiscount Then
			
			ReturnStructure.TableHeader = "TableHeaderWithVATWithDiscountDiscount";
			
		ElsIf DiscountsSettingUp.ThereIsMarkUp Then
			
			ReturnStructure.TableHeader = "TableHeaderWithVATWithDiscountMarkUp";
			
		EndIf;
		
		ReturnStructure.TableRow = "RowOfTableWithVATAtDiscount";
		ReturnStructure.TableRowSet = "RowOfTableWithVATAtDiscountSet";
		ReturnStructure.TableRowComponents = "RowOfTableWithVATAtDiscountComponents";
		ReturnStructure.TableFooter = "BasementTableWithVATAtDiscount";
		
	ElsIf ShowVAT Then
		
		ReturnStructure.TableHeader = "HeaderOfTableWithVAT";
		ReturnStructure.TableRow = "TableRowWithVAT";
		ReturnStructure.TableRowSet = "TableRowWithVATSet";
		ReturnStructure.TableRowComponents = "TableRowWithVATComponents";
		ReturnStructure.TableFooter = "BasementTableWithVAT";
		
	ElsIf DiscountsSettingUp.ThereAreDiscounts Then
		
		If DiscountsSettingUp.ThereIsDiscount
			And DiscountsSettingUp.ThereIsMarkUp Then
			
			ReturnStructure.TableHeader = "TableHeaderWithDiscountDiscountMarkUp";
			
		ElsIf DiscountsSettingUp.ThereIsDiscount Then
			
			ReturnStructure.TableHeader = "TableHeaderWithDiscountDiscount";
			
		ElsIf DiscountsSettingUp.ThereIsMarkUp Then
			
			ReturnStructure.TableHeader = "TableHeaderWithDiscountMarkUp";
			
		EndIf;
		
		ReturnStructure.TableRow = "TableRowWithDiscount";
		ReturnStructure.TableRowSet = "TableRowWithDiscountSet";
		ReturnStructure.TableRowComponents = "TableRowWithDiscountComponents";
		ReturnStructure.TableFooter = "BasementTablesAtDiscount";
		
	ElsIf DisplayPriceType Then
		
		ReturnStructure.TableHeader = "HeaderOfTableWithCondition";
		ReturnStructure.TableRow = "TableRowWithCondition";
		ReturnStructure.TableRowSet = "TableRowWithConditionSet";
		ReturnStructure.TableRowComponents = "TableRowWithConditionComponents";
		ReturnStructure.TableFooter = "TableBasementWithCondition";
		
	Else
		
		ReturnStructure.TableHeader = "TableHeader";
		ReturnStructure.TableRow = "TableRow";
		ReturnStructure.TableRowSet = "TableRowSet";
		ReturnStructure.TableRowComponents = "TableRowComponents";
		ReturnStructure.TableFooter = "TableFooter";
		
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

Function ColumnAreaNames(DoubleDOPParameter, ThereIsAdditionalParameter)
	
	ReturnStructure = New Structure("OwnGoods, Data");
	
	If DoubleDOPParameter Then
		ReturnStructure.OwnGoods = "ProductWithTwoParameters";
		ReturnStructure.Data = "DataWithTwoParameters";
	ElsIf ThereIsAdditionalParameter Then
		ReturnStructure.OwnGoods = "ProductWithOneParameter";
		ReturnStructure.Data = "DataWithOneParameter";
	Else
		ReturnStructure.OwnGoods = "OwnGoods";
		ReturnStructure.Data = "Data";
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

Function OrganizationDescription(PrintData, CompanyName, LanguageCode = Undefined)
	
	InformationRecords = PrintFormGeneration.InformationAboutLegalEntity(PrintData[CompanyName], PrintData.Date);
	
	If Not ValueIsFilled(LanguageCode)
		Or LanguageCode = Common.DefaultLanguageCode() Then
		
		NameOfTheItemName = "FullDescr";
		AttributeNameAddress = "LegalAddress";
		
	Else
		
		NameOfTheItemName = ?(ValueIsFilled(InformationRecords.DescriptionInternational), "DescriptionInternational", "FullDescr");
		AttributeNameAddress = ?(ValueIsFilled(InformationRecords.International_Address), "International_Address", "LegalAddress");
		
	EndIf;
	
	AttributesString = StrTemplate("%1,TIN,CRTR,%2,Phones,", NameOfTheItemName, AttributeNameAddress);
	
	Return PrintFormGeneration.OrganizationDescription(InformationRecords, AttributesString);
	
EndFunction

// outdated procedure, left for compatibility with Templates edited manually before updating to Templates with translations
//
Procedure FillInTabularDocumentOfOrderForGoodsServicesBefore_2_5_10(SpreadsheetDocument, PFFillingParameters, PrintObjects, FirstDocument, LanguageCode)
	
	ErrorPatternProducts = PFFillingParameters.ErrorPatternProducts;
	Template = PFFillingParameters.Template;
	NameOfCodeColumn = PFFillingParameters.NameOfCodeColumn;
	OutputCodes = PFFillingParameters.OutputCodes;
	PrintData = PFFillingParameters.PrintData;
	PaymentSteps = PFFillingParameters.PaymentSteps;
	Goods = PFFillingParameters.Goods;
	PresentationOfCodesColumn = PFFillingParameters.PresentationOfCodesColumn;
	
	TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
	
	GoodsTable = Goods.FindRows(TheStructureOfTheSearch);
	
	If GoodsTable.Count() = 0 Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		ErrorPatternProducts,
		PrintData.Ref,
		PrintData.PresentationInError);
		
		Common.MessageToUser(ErrorText, PrintData.Ref);
		Return;
		
	EndIf;
	
	PaymentStagesTable = PaymentSteps.FindRows(TheStructureOfTheSearch);
	
	If FirstDocument Then
		FirstDocument = False;
	Else
		SpreadsheetDocument.PutHorizontalPageBreak();
	EndIf;
	
	RowNumberStart = SpreadsheetDocument.TableHeight + 1;
	
	DisplayPriceType = False;
	For Each LineProducts_ In GoodsTable Do
		
		If ValueIsFilled(LineProducts_.TypeOfContractorSPrice) Then
			DisplayPriceType = True;
			Break;
		EndIf;
		
	EndDo;
	
	DiscountHeader	= PrintFormGeneration.YouNeedToDisplayDiscounts(GoodsTable, PrintData.UseAutoDiscounts);
	ThereAreDiscounts		= DiscountHeader.ThereAreDiscounts;
	ShowVAT	= PrintData.ShowNDSInRows And PrintData.ConsiderVAT;
	
#Region DefiningAreaHeaderNames
	
	ThereIsAdditionalParameter		= ThereAreDiscounts Or DisplayPriceType Or ShowVAT;
	DoubleDOPParameter	= (ThereAreDiscounts And DisplayPriceType) Or (ThereAreDiscounts And ShowVAT);
	
	If DoubleDOPParameter Then
		ColumnsPostfix = "WithTwoParameters";
	ElsIf ThereIsAdditionalParameter Then
		ColumnsPostfix = "WithOneParameter";
	Else
		ColumnsPostfix = "";
	EndIf;
	
	ColumnAreas = ColumnAreaNames(DoubleDOPParameter, ThereIsAdditionalParameter);
	
	ProductColumnArea = Template.Area(ColumnAreas.OwnGoods);
	
	If Not OutputCodes Then
		
		If DoubleDOPParameter Then
			ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.35;
		ElsIf ThereIsAdditionalParameter Then
			ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.2;
		Else
			ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.14;
		EndIf;
		
	EndIf;
	
	StringAreas = NamesOfAreasLinesUpTo_2_5_10(ThereAreDiscounts, DisplayPriceType, ShowVAT);
	
#EndRegion
	
#Region TemplateAreas
	
	// AREAS OF THE "PRODUCTS" TABLE
	
	HeaderNumberArea		= Template.GetArea(StringAreas.TableHeader + "|LineNumber");
	HeaderCodeArea		= Template.GetArea(StringAreas.TableHeader + "|ColumnOfCodes");
	HeaderArea_1		= Template.GetArea(StringAreas.TableHeader + "|" + ColumnAreas.OwnGoods);
	HeaderDataArea_		= Template.GetArea(StringAreas.TableHeader + "|" + ColumnAreas.Data);
	
	LineNumberAreaStandard = Template.GetArea(StringAreas.TableRow + "|LineNumber");
	ScopeOfStringCodesStandard  = Template.GetArea(StringAreas.TableRow + "|ColumnOfCodes");
	ProductAreaRowsStandard  = Template.GetArea(StringAreas.TableRow + "|" + ColumnAreas.OwnGoods);
	DataAreaOfStringIsStandard = Template.GetArea(StringAreas.TableRow + "|" + ColumnAreas.Data);
	
	UseSets = False;
	If Goods.Columns.Find("IsRecordsSet") <> Undefined Then
		UseSets = True;
		LineNumberAreaSet         = Template.GetArea(StringAreas.TableRow + "|LineNumber");
		LineNumberAreaComponents = Template.GetArea(StringAreas.TableRow + "|LineNumber");
		StringCodeAreaSet          = Template.GetArea(StringAreas.TableRow + "|ColumnOfCodes");
		StringCodeAreaComponents  = Template.GetArea(StringAreas.TableRow + "|ColumnOfCodes");
		ProductAreaRowsSet          = Template.GetArea(StringAreas.TableRow + "|" + ColumnAreas.OwnGoods);
		ProductAreaRowsComponents  = Template.GetArea(StringAreas.TableRow + "|" + ColumnAreas.OwnGoods);
		RowDataAreaSet         = Template.GetArea(StringAreas.TableRow + "|" + ColumnAreas.Data);
		RowDataAreaComponents = Template.GetArea(StringAreas.TableRow + "|" + ColumnAreas.Data);
	EndIf;
	
	BasementRoomArea	= Template.GetArea(StringAreas.TableFooter + "|LineNumber");
	BasementCodeArea		= Template.GetArea(StringAreas.TableFooter + "|ColumnOfCodes");
	BasementStorageArea		= Template.GetArea(StringAreas.TableFooter + "|" + ColumnAreas.OwnGoods);
	BasementDataArea	= Template.GetArea(StringAreas.TableFooter + "|" + ColumnAreas.Data);
	
	VATNumberArea		= Template.GetArea("VATTableBasement|LineNumber");
	ScopeOfVATCodes			= Template.GetArea("VATTableBasement|ColumnOfCodes");
	ProductAreaVAT			= Template.GetArea("VATTableBasement|" + ColumnAreas.OwnGoods);
	VATDataArea		= Template.GetArea("VATTableBasement|" + ColumnAreas.Data);
	
	RegionAmountInWords = Template.GetArea("AmountInWords");
	
#EndRegion
	
#Region HeaderOutput
	
	// Header - Header
	
	TemplateArea = Template.GetArea("Title");
	PrintFormGeneration.PrintLogoInTabularDocument(Template, TemplateArea, "TitleLogo", PrintData.Organization);
	
	SetParameter(TemplateArea, "TitleText", TMCommonUseClientServer.GenerateDocumentTitle(
	PrintData,
	PrintData.PresentationOfDocument));
	
	BarcodingOfPrintForms.OutputBarcodeToTabularDocument(
	SpreadsheetDocument,
	Template,
	TemplateArea,
	PrintData.Ref);
	
	SpreadsheetDocument.Put(TemplateArea);
	
	// THE PERFORMER 'S HAT
	
	TemplateArea = Template.GetArea("Performer");
	SetParameter(TemplateArea, "ArtistPresentation", DescriptionOfOrganizationBefore_2_5_10(PrintData, "Performer"));
	SpreadsheetDocument.Put(TemplateArea);
	
	// CUSTOMER HEADER
	
	TemplateArea = Template.GetArea("Customer_");
	SetParameter(TemplateArea, "CustomerPresentation_0", DescriptionOfOrganizationBefore_2_5_10(PrintData, "Customer_"));
	SpreadsheetDocument.Put(TemplateArea);
	
	// THE HEADER IS THE SHIPPER
	
	If ValueIsFilled(PrintData.Shipper) Then
		TemplateArea = Template.GetArea("Shipper");
		SetParameter(TemplateArea, "ShipperPresentation", DescriptionOfOrganizationBefore_2_5_10(PrintData, "Shipper"));
		SpreadsheetDocument.Put(TemplateArea);
	EndIf;
	
	// THE HEADER IS THE CONSIGNEE
	
	If ValueIsFilled(PrintData.GoodsRecipient) Then
		TemplateArea = Template.GetArea("GoodsRecipient");
		SetParameter(TemplateArea, "PresentationOfConsignee", DescriptionOfOrganizationBefore_2_5_10(PrintData, "GoodsRecipient"));
		SpreadsheetDocument.Put(TemplateArea);
	EndIf;
	
	// HEADER - DELIVERY ADDRESS
	
	If ValueIsFilled(PrintData.DeliveryAddress) Then
		TemplateArea = Template.GetArea("DeliveryAddress");
		SetParameter(TemplateArea, "DeliveryAddress", PrintData.DeliveryAddress);
		SpreadsheetDocument.Put(TemplateArea);
	EndIf;
	
#EndRegion
	
#Region OutputOfProductsTable
	
	// TABLE PRODUCTS - HEADER
	
	If ThereAreDiscounts Then
		SetParameter(HeaderDataArea_, "Discount", DiscountHeader.Discount);
		SetParameter(HeaderDataArea_, "AmountWithoutADiscount", DiscountHeader.DiscountAmount);
	EndIf; 
	
	If OutputCodes Then
		SetParameter(HeaderCodeArea, "NameOfCodeColumn", PresentationOfCodesColumn);
	EndIf;
	
	// THE PRODUCTS - LINES TABLE
	
	OutputValidationArray = New Array;
	OutputValidationArray.Add(HeaderNumberArea);
	OutputValidationArray.Add(BasementRoomArea);
	If ShowVAT Then
		OutputValidationArray.Add(VATNumberArea);
	EndIf;
	OutputValidationArray.Add(RegionAmountInWords);
	
	Sum			= 0;
	VATAmount		= 0;
	TotalOfDiscounts		= 0;
	TotalWithoutDiscounts	= 0;
	
	LineNumber = 0;
	
	BlankData = SetsServer.BlankData();
	HeaderOutput = 0;
	
	ComplianceWithVATRates = New Map;
	
	For Each LineProducts_ In GoodsTable Do
		
		If SetsServer.UseSetArea(LineProducts_, UseSets) Then
			StringCodeArea   = StringCodeAreaSet;
			LineNumberArea  = LineNumberAreaSet;
			RowDataArea  = RowDataAreaSet;
			ProductAreaRows   = ProductAreaRowsSet;
		ElsIf SetsServer.UseScope(LineProducts_, UseSets) Then
			StringCodeArea   = StringCodeAreaComponents;
			LineNumberArea  = LineNumberAreaComponents;
			RowDataArea  = RowDataAreaComponents;
			ProductAreaRows   = ProductAreaRowsComponents;
		Else
			StringCodeArea   = ScopeOfStringCodesStandard;
			LineNumberArea  = LineNumberAreaStandard;
			RowDataArea  = DataAreaOfStringIsStandard;
			ProductAreaRows   = ProductAreaRowsStandard;
		EndIf;
		
		If SetsServer.DisplayOnlyTitle(LineProducts_, UseSets) Then
			SetParameter(LineNumberArea, "LineNumber", Undefined);
		Else
			LineNumber = LineNumber + 1;
			SetParameter(LineNumberArea, "LineNumber", LineNumber);
		EndIf;
		
		If LineNumber = 0 And HeaderOutput <> 2 Then
			HeaderOutput = 1;
		EndIf;
		
		OutputValidationArray.Add(LineNumberArea);
		
		If SpreadsheetDocument.CheckPut(OutputValidationArray) Then
			
			If (LineNumber = 1 And HeaderOutput = 0) Or (LineNumber = 0 And HeaderOutput = 1) Then
				
				HeaderOutput = 2;
				
				OutputHeader(SpreadsheetDocument, HeaderNumberArea, HeaderCodeArea, HeaderArea_1, HeaderDataArea_, OutputCodes);
				OutputValidationArray.Delete(0);
				
			EndIf;
			
		Else
			
			SpreadsheetDocument.PutHorizontalPageBreak();
			OutputHeader(SpreadsheetDocument, HeaderNumberArea, HeaderCodeArea, HeaderArea_1, HeaderDataArea_, OutputCodes);
			
		EndIf;
		
		OutputValidationArray.Delete(OutputValidationArray.UBound());
		
		SetParameter(LineNumberArea, "LineNumber", LineNumber);
		SpreadsheetDocument.Put(LineNumberArea);
		
		If OutputCodes Then
			
			ColumnName = NameOfCodeColumn;
			If PrintData.Type = "PurchaseOrderBySupplierData" Then
				If ColumnName = "Code" Then
					ColumnName = "ArtistCode";
				ElsIf ColumnName = "SKU" Then
					ColumnName = "ArtistSArticle";
				Else
					ColumnName = "Assignee"
				EndIf;
			EndIf;
			
			SetParameter(StringCodeArea, "SKU", LineProducts_[ColumnName]);
			SpreadsheetDocument.Join(StringCodeArea);
			
		EndIf;
		
		If PrintData.Type = "PurchaseOrderBySupplierData" Then
			
			PresentationOfProductsForPrinting = LineProducts_.NameOfContractorSProductList;
			
		Else
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.ReturnContainers = LineProducts_.ThisIsReusablePackage;				
			AdditionalParametersForGettingNameToPrint.Content = LineProducts_.Content;				
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			PresentationOfProductsForPrinting = ProductsClientServer.PresentationOfProductsForPrinting(
			LineProducts_.DescriptionFull,
			LineProducts_.Characteristic,
			,
			,
			AdditionalParametersForGettingNameToPrint);
			
		EndIf;
		
		PrefixAndPostfix = SetsServer.GetPrefixAndPostfix(LineProducts_, UseSets);
		SetParameter(ProductAreaRows, "OwnGoods", PrefixAndPostfix.Prefix + PresentationOfProductsForPrinting + PrefixAndPostfix.Postfix);
		
		If DisplayPriceType Then
			SetParameter(ProductAreaRows, "TypeOfContractorSPrice", LineProducts_.TypeOfContractorSPrice);
		EndIf;
		
		SpreadsheetDocument.Join(ProductAreaRows);
		RowDataArea.Parameters.Fill(LineProducts_);
		
		If DiscountHeader.ThereAreDiscounts Then
			SetParameter(RowDataArea, "DiscountAmount", ?(DiscountHeader.OnlyMarkUp, - LineProducts_.DiscountAmount, LineProducts_.DiscountAmount));
		EndIf;
		
		If SetsServer.DisplayOnlyTitle(LineProducts_, UseSets) Then
			RowDataArea.Parameters.Fill(BlankData);
		Else
			RowDataArea.Parameters.Fill(LineProducts_);
		EndIf;
		
		If PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
			SetParameter(RowDataArea, "VATRate", NStr("vi = 'Thuế GTGT trích nộp bởi đại lý thuế';
														|ru = 'НДС исчисляется налоговым агентом';
														|en = 'VAT is calculated by tax agent'; fa = 'مالیات بر ارزش افزوده توسط عامل مالیاتی محاسبه می‌شود';
														|it = 'L''IVA viene calcolata dall''agente tributario';
														|pl = 'VAT jest obliczany przez agenta podatkowego';
														|tr = 'KDV vergi memuru tarafından hesaplanır'", Common.DefaultLanguageCode()));
		EndIf;
		
		SpreadsheetDocument.Join(RowDataArea);
		
		If Not SetsServer.UseScope(LineProducts_, UseSets) Then
			Sum    = Sum    + LineProducts_.Sum;
			VATAmount = VATAmount + LineProducts_.VATAmount;
			
			If ThereAreDiscounts Then
				TotalOfDiscounts    = TotalOfDiscounts    + LineProducts_.DiscountAmount;
				TotalWithoutDiscounts = TotalWithoutDiscounts + LineProducts_.AmountWithoutADiscount;
			EndIf;
			
			If PrintData.ConsiderVAT Then
				
				AmountOfVATAtRate = ComplianceWithVATRates[LineProducts_.VATRate];
				
				If AmountOfVATAtRate = Undefined Then
					AmountOfVATAtRate = 0;
				EndIf;
				
				If PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
					ComplianceWithVATRates.Insert(PredefinedValue("Catalog.VATRates.EXCLUDINGVAT"), AmountOfVATAtRate + LineProducts_.VATAmount);
				Else
					ComplianceWithVATRates.Insert(LineProducts_.VATRate, AmountOfVATAtRate + LineProducts_.VATAmount);
				EndIf;
				
			EndIf;
		EndIf;
		
	EndDo;
	
	// TABLE PRODUCTS - BASEMENT
	
	SpreadsheetDocument.Put(BasementRoomArea);
	
	If OutputCodes Then
		SpreadsheetDocument.Join(BasementCodeArea);
	EndIf;
	
	SpreadsheetDocument.Join(BasementStorageArea);
	
	If ThereAreDiscounts Then
		SetParameter(BasementDataArea, "TotalOfDiscounts", ?(DiscountHeader.OnlyMarkUp, -TotalOfDiscounts, TotalOfDiscounts));
		SetParameter(BasementDataArea, "TotalWithoutDiscounts", TotalWithoutDiscounts);
	EndIf;
	
	SetParameter(BasementDataArea, "Total", PrintFormGeneration.SumFormat(Sum));
	SpreadsheetDocument.Join(BasementDataArea);
	
	// TABLE PRODUCTS - TOTAL VAT
	
	If Not PrintData.ConsiderVAT Or PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
		
		SpreadsheetDocument.Put(VATNumberArea);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(ScopeOfVATCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductAreaVAT);
		
		If PrintData.OperationIsSubjectToBuyerSPersonalIncomeTax Then
			SetParameter(VATDataArea, "VAT", NStr("vi = 'Thuế GTGT trích nộp bởi đại lý thuế';
													|ru = 'НДС исчисляется налоговым агентом';
													|en = 'VAT is calculated by tax agent'; fa = 'مالیات بر ارزش افزوده توسط عامل مالیاتی محاسبه می‌شود';
													|it = 'L''IVA viene calcolata dall''agente tributario';
													|pl = 'VAT jest obliczany przez agenta podatkowego';
													|tr = 'KDV vergi memuru tarafından hesaplanır'", Common.DefaultLanguageCode()));
		Else
			SetParameter(VATDataArea, "VAT", NStr("vi = 'Không gồm thuế (GTGT)';
													|ru = 'Без налога (НДС)';
													|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
													|it = 'senza imposta (IVA)';
													|pl = 'bez podatku (VAT)';
													|tr = 'Vergisiz (KDV)'", Common.DefaultLanguageCode()));
		EndIf;
		SetParameter(VATDataArea, "TotalVAT", "-");
		
		SpreadsheetDocument.Join(VATDataArea);
		
	Else
		
		For Each CurVATRate In ComplianceWithVATRates Do
			
			SpreadsheetDocument.Put(VATNumberArea);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(ScopeOfVATCodes);
			EndIf;
			
			SpreadsheetDocument.Join(ProductAreaVAT);
			
			SetParameter(VATDataArea, "VAT", PrintFormGeneration.VATRateText(CurVATRate.Key, PrintData.PriceIncludesVAT));
			SetParameter(VATDataArea, "TotalVAT", PrintFormGeneration.SumFormat(CurVATRate.Value, , "-"));
			
			SpreadsheetDocument.Join(VATDataArea);
			
		EndDo;
		
	EndIf;
	
#EndRegion
	
#Region BasementOutput
	
	// BASEMENT - AMOUNT IN WORDS
	
	AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
	ArrayOfOrderToProcessorTypes = New Array;
	ArrayOfOrderToProcessorTypes.Add(Type("DocumentRef.SubcontractOrder2_5"));
		
	If Not ArrayOfOrderToProcessorTypes.Find(TypeOf(PrintData.Ref)) = Undefined Then
		TextOfResultingLine = NStr("vi = 'Tổng số mục %1';
									|ru = 'Всего наименований %1';
									|en = 'Total items %1'; fa = 'Total items %1';
									|it = 'Totale articoli %1';
									|pl = 'Razem pozycji %1';
									|tr = 'Toplam tanım %1'", Common.DefaultLanguageCode());
	Else
		TextOfResultingLine = NStr("vi = 'Tổng số %1, thành tiền %2';
									|ru = 'Всего наименований %1, на сумму %2';
									|en = 'Total items %1 in the amount of %2'; fa = 'Total items %1 in the amount of %2';
									|it = 'Totale articoli %1, per importo di %2';
									|pl = 'Razem pozycji %1, na kwotę %2';
									|tr = 'Toplam kalem %1, tutar %2'", Common.DefaultLanguageCode());
	EndIf;
	TotalString = StringFunctionsClientServer.SubstituteParametersToString(
	TextOfResultingLine,
	LineNumber, // Count
	PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency)); // Sum
	
	SetParameter(RegionAmountInWords, "TotalString", TotalString);
	SetParameter(RegionAmountInWords, "AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(
	AmountToBeRegistered,
	PrintData.Currency));
	
	SpreadsheetDocument.Put(RegionAmountInWords);
	
	// BASEMENT - STAGES OF THE PAYMENT SCHEDULE
	
	If PaymentStagesTable.Count() > 1 Then
		
		TableHeaderArea_ = Template.GetArea("HeaderOfPaymentStagesTable");
		TableBasementArea_ = Template.GetArea("TotalPaymentStages");
		
		OutputValidationArray.Clear();
		OutputValidationArray.Add(TableHeaderArea_);
		OutputValidationArray.Add(TableBasementArea_);
		
		TableRowArea = Template.GetArea("RowOfPaymentStagesTable");
		
		StageNumber = 1;
		For Each CurStage In PaymentStagesTable Do
			
			RowParameters = NewStageLineParameters();
			FillPropertyValues(RowParameters, CurStage);
			RowParameters.LineNumber = StageNumber;
			If Not RowParameters.ThisIsDepositForPackage Then
				RowParameters.VATText = PrintFormGeneration.GenerateTextOfVATPaymentStage(
				ComplianceWithVATRates,
				CurStage.PaymentPercentage);
			Else
				RowParameters.PaymentOption = String(CurStage.PaymentOption) + " " + NStr("vi = '(ký cược bao bì)';
																							|ru = '(залог за тару)';
																							|en = '(packaging deposit)'; fa = '(packaging deposit)';
																							|it = '(deposito per imballaggio)';
																							|pl = '(kaucja za opakowania)';
																							|tr = '(depozito)'", Common.DefaultLanguageCode());
				RowParameters.PaymentPercentage = "-";
				RowParameters.VATText = NStr("vi = 'Không gồm thuế (GTGT)';
											|ru = 'Без налога (НДС)';
											|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
											|it = 'senza imposta (IVA)';
											|pl = 'bez podatku (VAT)';
											|tr = 'Vergisiz (KDV)'", Common.DefaultLanguageCode());
			EndIf;
			
			TableRowArea.Parameters.Fill(RowParameters);
			
			OutputValidationArray.Add(TableRowArea);
			
			If SpreadsheetDocument.CheckPut(OutputValidationArray) Then
				
				If StageNumber=1 Then
					SpreadsheetDocument.Put(TableHeaderArea_);
					OutputValidationArray.Delete(0);
				EndIf;
				
			Else
				
				SpreadsheetDocument.PutHorizontalPageBreak();
				SpreadsheetDocument.Put(TableHeaderArea_);
				
			EndIf;
			
			OutputValidationArray.Delete(OutputValidationArray.UBound());
			
			SpreadsheetDocument.Put(TableRowArea);
			
			StageNumber = StageNumber + 1;
			
		EndDo;
		
		SpreadsheetDocument.Put(TableBasementArea_);
		
	EndIf;
	
	// BASEMENT - ADDITIONAL INFORMATION
	
	If ValueIsFilled(PrintData.AdditionalInformation) Then
		
		TemplateArea = Template.GetArea("AdditionalInformation");
		SetParameter(TemplateArea, "AdditionalInformation", PrintData.AdditionalInformation);
		SpreadsheetDocument.Put(TemplateArea);
		
	EndIf;
	
	// BASEMENT - SIGNATURES
	
	TemplateArea = Template.GetArea("BasementOfOrder");
	SetParameter(TemplateArea, "ManagerSFullName", PersonsTM.IndividualShortName(PrintData.Manager, PrintData.Date));
	SpreadsheetDocument.Put(TemplateArea);
	
#EndRegion
	
	PrintManagement.SetDocumentPrintArea(
		SpreadsheetDocument,
		RowNumberStart,
		PrintObjects,
		PrintData.Ref);
	
EndProcedure

// outdated procedure, left for compatibility with Templates edited manually before updating to Templates with translations
//
Function NamesOfAreasLinesUpTo_2_5_10(ThereAreDiscounts, DisplayPriceType, ShowVAT)
	
	ReturnStructure = New Structure(
		"TableHeader, TableRow, TableRowSet, TableRowComponents, TableFooter");
	If ThereAreDiscounts And DisplayPriceType Then
		ReturnStructure.TableHeader = "TableHeaderWithDiscountCondition";
		ReturnStructure.TableRow = "TableRowWithDiscountCondition";
		ReturnStructure.TableRowSet = "TableRowWithDiscountConditionSet";
		ReturnStructure.TableRowComponents = "TableRowWithDiscountConditionComponents";
		ReturnStructure.TableFooter = "TableBasementWithDiscountCondition";
	ElsIf ThereAreDiscounts And ShowVAT Then
		ReturnStructure.TableHeader = "HeaderOfWithVATTableAtDiscount";
		ReturnStructure.TableRow = "RowOfTableWithVATAtDiscount";
		ReturnStructure.TableRowSet = "RowOfTableWithVATAtDiscountSet";
		ReturnStructure.TableRowComponents = "RowOfTableWithVATAtDiscountComponents";
		ReturnStructure.TableFooter = "BasementTableWithVATAtDiscount";
	ElsIf ShowVAT Then
		ReturnStructure.TableHeader = "HeaderOfTableWithVAT";
		ReturnStructure.TableRow = "TableRowWithVAT";
		ReturnStructure.TableRowSet = "TableRowWithVATSet";
		ReturnStructure.TableRowComponents = "TableRowWithVATComponents";
		ReturnStructure.TableFooter = "BasementTableWithVAT";
	ElsIf ThereAreDiscounts Then
		ReturnStructure.TableHeader = "TableHeaderWithDiscount";
		ReturnStructure.TableRow = "TableRowWithDiscount";
		ReturnStructure.TableRowSet = "TableRowWithDiscountSet";
		ReturnStructure.TableRowComponents = "TableRowWithDiscountComponents";
		ReturnStructure.TableFooter = "BasementTablesAtDiscount";
	ElsIf DisplayPriceType Then
		ReturnStructure.TableHeader = "HeaderOfTableWithCondition";
		ReturnStructure.TableRow = "TableRowWithCondition";
		ReturnStructure.TableRowSet = "TableRowWithConditionSet";
		ReturnStructure.TableRowComponents = "TableRowWithConditionComponents";
		ReturnStructure.TableFooter = "TableBasementWithCondition";
	Else
		ReturnStructure.TableHeader = "TableHeader";
		ReturnStructure.TableRow = "TableRow";
		ReturnStructure.TableRowSet = "TableRowSet";
		ReturnStructure.TableRowComponents = "TableRowComponents";
		ReturnStructure.TableFooter = "TableFooter";
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// outdated procedure, left for compatibility with Templates edited manually before updating to Templates with translations
//
Function DescriptionOfOrganizationBefore_2_5_10(PrintData, CompanyName, LanguageCode = Undefined)
	
	InformationRecords = PrintFormGeneration.InformationAboutLegalEntity(PrintData[CompanyName], PrintData.Date);
	Attributes = "FullDescr,TIN,CRTR,LegalAddress,Phones,";
	
	Return PrintFormGeneration.OrganizationDescription(InformationRecords, Attributes);
	
EndFunction

// Other

Procedure SetParameter(TemplateArea, ParameterName, ParameterValue)
	TemplateArea.Parameters.Fill(New Structure(ParameterName, ParameterValue));
EndProcedure

Procedure OutputHeader(SpreadsheetDocument, HeaderNumberArea, HeaderCodeArea, HeaderArea_1, HeaderDataArea_, OutputCodes)
	
	SpreadsheetDocument.Put(HeaderNumberArea);
	If OutputCodes Then
		SpreadsheetDocument.Join(HeaderCodeArea);
	EndIf;
	SpreadsheetDocument.Join(HeaderArea_1);
	SpreadsheetDocument.Join(HeaderDataArea_);
	
EndProcedure

Function NewStageLineParameters()
	
	StageLineStructure = New Structure;
	StageLineStructure.Insert("LineNumber", 0);
	StageLineStructure.Insert("PaymentOption", "");
	StageLineStructure.Insert("PaymentDate", '00010101');
	StageLineStructure.Insert("PaymentPercentage", 0);
	StageLineStructure.Insert("PaymentAmount", 0);
	StageLineStructure.Insert("VATText", "");
	StageLineStructure.Insert("ThisIsDepositForPackage", False);
	
	Return StageLineStructure;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
