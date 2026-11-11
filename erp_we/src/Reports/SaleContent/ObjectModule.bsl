#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ListOfNamesOfTabularPartsOfDocuments = New ValueList;
	ListOfNamesOfTabularPartsOfDocuments.Add("SalesOrder.Goods",            NStr("vi = 'Trong đơn hàng';
																				|ru = 'В заказах';
																				|en = 'In orders'; fa = 'در سفارش‌ها';
																				|it = 'Negli ordini';
																				|pl = 'W zamówieniach';
																				|tr = 'Siparişlerde'"));
	ListOfNamesOfTabularPartsOfDocuments.Add("CustomerInvoiceServices.Services",     NStr("vi = 'Trong các biên bảni công việc được thực hiện';
																							|ru = 'В актах выполненных работ';
																							|en = 'In Customer invoice —Services'; fa = 'In Customer invoice —Services';
																							|it = 'Nei verbali di consegna dei lavori';
																							|pl = 'A protokołach wykonanych prac';
																							|tr = 'Tamamlanan işlerin raporlarında'"));
	ListOfNamesOfTabularPartsOfDocuments.Add("CustomerInvoice.Goods",  NStr("vi = 'Doanh thu';
																			|ru = 'В реализациях';
																			|en = 'In sales'; fa = 'In sales';
																			|it = 'Nelle vendite';
																			|pl = 'W realizacjach';
																			|tr = 'Satışlarda'"));
	ListOfNamesOfTabularPartsOfDocuments.Add("ReturnOfGoodsFromCustomer.Goods", NStr("vi = 'Đổi lại';
																					|ru = 'В возвратах';
																					|en = 'In returns'; fa = 'In returns';
																					|it = 'Nei resi';
																					|pl = 'W zwrotach';
																					|tr = 'İadelerde'"));
	ListOfNamesOfTabularPartsOfDocuments.Add("MaterialProviderOrder2_5.ManufacturedProduct", NStr("vi = 'Trong đơn hàng';
																									|ru = 'В заказах';
																									|en = 'In orders'; fa = 'در سفارش‌ها';
																									|it = 'Negli ordini';
																									|pl = 'W zamówieniach';
																									|tr = 'Siparişlerde'"));
	ListOfNamesOfTabularPartsOfDocuments.Add("ReportToMaterialProvider2_5.ManufacturedProduct", NStr("vi = 'Trong báo cáo';
																									|ru = 'В отчетах';
																									|en = 'In reports'; fa = 'In reports';
																									|it = 'Nei report';
																									|pl = 'W raportach';
																									|tr = 'Raporlarda'"));
	ListOfNamesOfTabularPartsOfDocuments.Add("GoodsShipmentFromStorage.Goods", NStr("vi = 'Trong các chuyển giao';
																					|ru = 'В передачах';
																					|en = 'In transfers'; fa = 'In transfers';
																					|it = 'Nei trasferimenti';
																					|pl = 'W przekazaniach';
																					|tr = 'Sevkiyatlarda'"));
	CRMLocalization.CompleteListOfDocumentsFormingSalesReport(ListOfNamesOfTabularPartsOfDocuments);
	
	QueryText = QueryTextForListOfTablePartNames(ListOfNamesOfTabularPartsOfDocuments);
	
	ReportSettings   = SettingsComposer.GetSettings();
	TemplateComposer = New DataCompositionTemplateComposer;
	
	DataCompositionSchema.DataSets.SaleContent.Query = QueryText;
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , , True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm             - ClientApplicationForm - report form.
//   Cancel                - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		ThisForm.ParametersForm.Filter.Insert("SalesOpportunity", Parameters.CommandParameter);
	EndIf;
	
EndProcedure

Function QueryTextForListOfTablePartNames(ListOfNamesOfTabularPartsOfDocuments)
	
	QueryText = "";
	
	ThisIsFirstJoinRequest = True;
	
	For Each ListItem In ListOfNamesOfTabularPartsOfDocuments Do
		
		Substrings = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ListItem.Value, "."); 
		If Substrings.Count() = 2 Then
			DocumentName = Substrings[0];
		Else
			Continue;
		EndIf;
		
		If Not AccessRight("Read", Metadata.Documents[DocumentName]) Then
			Continue;
		EndIf;
			
		QueryTextByDocument = "";
		TableName             = "Document." + ListItem.Value;
		
		QueryTextByDocument = "
		|SELECT ALLOWED
		|&StringPresentation              AS DocumentType_1,
		|DocumentProducts.Ref         AS Ref,
		|DocumentProducts.Products   AS Products,
		|DocumentProducts.Characteristic AS Characteristic,
		|DocumentProducts.Count     AS Count
		|FROM
		|	&TableName AS DocumentProducts
		|WHERE 
		|	
		|	DocumentProducts.Ref.Posted = TRUE
		|{WHERE
		|	DocumentProducts.Ref.SalesOpportunity.* AS SalesOpportunity}";
		
		QueryTextByDocument = StrReplace(QueryTextByDocument, "&TableName",            TableName);
		QueryTextByDocument = StrReplace(QueryTextByDocument, "&StringPresentation", """" + ListItem.Presentation + """");
		
		If Not ThisIsFirstJoinRequest Then
			
			QueryTextByDocument = StrReplace(QueryTextByDocument, "ALLOWED", "");
			
			QueryTextByDocument = "
			|
			|UNION ALL
			|" + QueryTextByDocument; 
			
		EndIf;
		
		QueryText = QueryText + QueryTextByDocument;
		
		ThisIsFirstJoinRequest = False;
		
	EndDo;
	
	If QueryText = "" Then
		Raise NStr("vi = 'Đối với người sử dụng hiện tại, không có chứng từ hợp lệ mà theo đó xác định thành phần bán hàng';
					|ru = 'Для текущего пользователя нет доступных документов по которым определяется состав продажи';
					|en = 'For the current user, there are no documents to determine the sale content'; fa = 'For the current user, there are no documents to determine the sale content';
					|it = 'Для текущего пользователя нет доступных документов по которым определяется состав продажи';
					|pl = 'For the current user, there are no documents to determine the sale content';
					|tr = 'Mevcut kullanıcı için satış içeriğinin tanımlandığı mevcut bir belge yoktur'");
	EndIf;
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf