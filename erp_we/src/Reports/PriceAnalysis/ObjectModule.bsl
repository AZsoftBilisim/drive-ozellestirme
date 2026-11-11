#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	CurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Currency");
	
	If CurrencyParameter <> Undefined And Not CurrencyParameter.Use Then
		CurrencyParameter.Use = True;
		UserSettingsModified = True;
	EndIf;
	
	DocumentParameter = DataCompositionClientServer.GetParameter(SettingsComposer.FixedSettings, "Document");
	ValueOfDocumentParameter = DocumentParameter.Value;
	
	DocumentType = TypeOf(ValueOfDocumentParameter);
	
	If DocumentType = Type("ValueList") Then
		If ValueOfDocumentParameter.Count() = 0 Then
			
			DocumentParameter          = DataCompositionClientServer.GetParameter(SettingsComposer.Settings, "Document");
			ValueOfDocumentParameter = DocumentParameter.Value;
			DocumentType              = TypeOf(ValueOfDocumentParameter);
			
			If DocumentType = Type("ValueList") Then
				If ValueOfDocumentParameter.Count() = 0 Then
					OutputResultOfContextualOpeningControl(ResultDocument);
					
					Return;
				Else
					DocumentType = TypeOf(ValueOfDocumentParameter[0].Value);
					WhenComposingResultFragment(DocumentType, DataCompositionSchema, SettingsComposer, DetailsData, ResultDocument);
	
				EndIf;
			EndIf;
		Else
			DocumentType = TypeOf(ValueOfDocumentParameter[0].Value);
			WhenComposingResultFragment(DocumentType, DataCompositionSchema, SettingsComposer, DetailsData, ResultDocument);
	
		EndIf;
	EndIf;
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
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
//   ThisForm - ClientApplicationForm - Report form
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		ThisForm.ParametersForm.Filter.Insert("Document", Parameters.CommandParameter);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure WhenComposingResultFragment(DocumentType, Var_DataCompositionSchema, Var_SettingsComposer, DetailsData, ResultDocument)
	
	QueryTextReplacement = "";
	
	If DocumentType = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
		
		QueryTextReplacement = "
		|SELECT ALLOWED
		|	CommercialOfferProducts.Ref.SalesOpportunity              AS Ref,
		|	CommercialOfferProducts.Ref                     AS Document,
		|	CommercialOfferProducts.Ref.Date                AS Date,
		|	CommercialOfferProducts.Ref.Currency              AS Currency,
		|	CommercialOfferProducts.LineNumber                AS LineNumber,
		|	CommercialOfferProducts.Products               AS Products,
		|	CommercialOfferProducts.Characteristic             AS Characteristic,
		|	CommercialOfferProducts.UnitOfMeasure           AS Package,
		|	CommercialOfferProducts.Price                       AS Price,
		|	CommercialOfferProducts.Price - CommercialOfferProducts.Price *
		|	(CommercialOfferProducts.PercentRateOfAutomaticDiscountMarkup +
		|	CommercialOfferProducts.PercentRateOfManualDiscount) / 100 AS DiscountedPrice_
		|INTO PreliminaryDataOfDocuments
		|FROM
		|	Document.CommercialProposalForCustomer.Goods AS CommercialOfferProducts
		|WHERE
		|	CommercialOfferProducts.Ref.SalesOpportunity IN(&Document)
		|
		|UNION ALL
		|
		|SELECT
		|	CustomerOrderGoods.Ref.SalesOpportunity  AS Ref,
		|	CustomerOrderGoods.Ref         AS Document,
		|	CustomerOrderGoods.Ref.Date    AS Date,
		|	CustomerOrderGoods.Ref.Currency  AS Currency,
		|	CustomerOrderGoods.LineNumber    AS LineNumber,
		|	CustomerOrderGoods.Products   AS Products,
		|	CustomerOrderGoods.Characteristic AS Characteristic,
		|	CustomerOrderGoods.Package       AS Package,
		|	CustomerOrderGoods.Price           AS Price,
		|	CustomerOrderGoods.Price - CustomerOrderGoods.Price *
		|	(CustomerOrderGoods.PercentRateOfAutomaticDiscountMarkup +
		|	CustomerOrderGoods.PercentRateOfManualDiscount) / 100 AS DiscountedPrice_
		|FROM
		|	Document.SalesOrder.Goods AS CustomerOrderGoods
		|WHERE
		|	CustomerOrderGoods.Ref.SalesOpportunity IN(&Document)
		|
		|UNION
		|
		|SELECT
		|	SalesOfGoodsServicesGoods.Ref.SalesOpportunity  AS Ref,
		|	SalesOfGoodsServicesGoods.Ref         AS Document,
		|	SalesOfGoodsServicesGoods.Ref.Date    AS Date,
		|	SalesOfGoodsServicesGoods.Ref.Currency  AS Currency,
		|	SalesOfGoodsServicesGoods.LineNumber    AS LineNumber,
		|	SalesOfGoodsServicesGoods.Products   AS Products,
		|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
		|	SalesOfGoodsServicesGoods.Package       AS Package,
		|	SalesOfGoodsServicesGoods.Price           AS Price,
		|	SalesOfGoodsServicesGoods.Price - SalesOfGoodsServicesGoods.Price *
		|	(SalesOfGoodsServicesGoods.PercentRateOfAutomaticDiscountMarkup +
		|	SalesOfGoodsServicesGoods.PercentRateOfManualDiscount) / 100 AS DiscountedPrice_
		|FROM
		|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
		|WHERE
		|	SalesOfGoodsServicesGoods.Ref.SalesOpportunity IN(&Document)
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|";
		
	ElsIf DocumentType = Type("DocumentRef.SalesOrder") Then
		
		QueryTextReplacement = "
		|SELECT ALLOWED
		|	CustomerOrderGoods.Ref         AS Ref,
		|	CustomerOrderGoods.Ref         AS Document,
		|	CustomerOrderGoods.Ref.Date    AS Date,
		|	CustomerOrderGoods.Ref.Currency  AS Currency,
		|	CustomerOrderGoods.LineNumber    AS LineNumber,
		|	CustomerOrderGoods.Products   AS Products,
		|	CustomerOrderGoods.Characteristic AS Characteristic,
		|	CustomerOrderGoods.Package       AS Package,
		|	CustomerOrderGoods.Price           AS Price,
		|	CustomerOrderGoods.Price - CustomerOrderGoods.Price *
		|	(CustomerOrderGoods.PercentRateOfAutomaticDiscountMarkup +
		|	CustomerOrderGoods.PercentRateOfManualDiscount) / 100 AS DiscountedPrice_
		|INTO PreliminaryDataOfDocuments
		|FROM
		|	Document.SalesOrder.Goods AS CustomerOrderGoods
		|WHERE
		|	CustomerOrderGoods.Ref IN(&Document)
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|";
		
	ElsIf DocumentType = Type("DocumentRef.CustomerInvoice") Then
		
		QueryTextReplacement = "
		|SELECT ALLOWED
		|	SalesOfGoodsServicesGoods.Ref         AS Ref,
		|	SalesOfGoodsServicesGoods.Ref         AS Document,
		|	SalesOfGoodsServicesGoods.Ref.Date    AS Date,
		|	SalesOfGoodsServicesGoods.Ref.Currency  AS Currency,
		|	SalesOfGoodsServicesGoods.LineNumber    AS LineNumber,
		|	SalesOfGoodsServicesGoods.Products   AS Products,
		|	SalesOfGoodsServicesGoods.Characteristic AS Characteristic,
		|	SalesOfGoodsServicesGoods.Package       AS Package,
		|	SalesOfGoodsServicesGoods.Price           AS Price,
		|	SalesOfGoodsServicesGoods.Price - SalesOfGoodsServicesGoods.Price *
		|	(SalesOfGoodsServicesGoods.PercentRateOfAutomaticDiscountMarkup +
		|	SalesOfGoodsServicesGoods.PercentRateOfManualDiscount) / 100 AS DiscountedPrice_
		|INTO PreliminaryDataOfDocuments
		|FROM
		|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
		|WHERE
		|	SalesOfGoodsServicesGoods.Ref IN(&Document)
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|";
		
	ElsIf DocumentType = Type("DocumentRef.CustomerInvoiceServices") Then
		
		QueryTextReplacement = "
		|SELECT ALLOWED
		|	CustomerInvoiceServicesServices.Ref         AS Ref,
		|	CustomerInvoiceServicesServices.Ref         AS Document,
		|	CustomerInvoiceServicesServices.Ref.Date    AS Date,
		|	CustomerInvoiceServicesServices.Ref.Currency  AS Currency,
		|	CustomerInvoiceServicesServices.LineNumber    AS LineNumber,
		|	CustomerInvoiceServicesServices.Products   AS Products,
		|	CustomerInvoiceServicesServices.Characteristic AS Characteristic,
		|	VALUE (Catalog.PackagesAndUnitsOfMeasure.EmptyRef)  AS Package,
		|	CustomerInvoiceServicesServices.Price           AS Price,
		|	CustomerInvoiceServicesServices.Price - CustomerInvoiceServicesServices.Price *
		|	(CustomerInvoiceServicesServices.PercentRateOfAutomaticDiscountMarkup +
		|	CustomerInvoiceServicesServices.PercentRateOfManualDiscount) / 100 AS DiscountedPrice_
		|INTO PreliminaryDataOfDocuments
		|FROM
		|	Document.CustomerInvoiceServices.Services AS CustomerInvoiceServicesServices
		|WHERE
		|	CustomerInvoiceServicesServices.Ref IN(&Document)
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|";
		
	ElsIf DocumentType = Type("DocumentRef.PurchaseOrder") Then
		
		QueryTextReplacement = "
		|SELECT ALLOWED
		|	PurchaseOrderGoods.Ref         AS Ref,
		|	PurchaseOrderGoods.Ref         AS Document,
		|	PurchaseOrderGoods.Ref.Date    AS Date,
		|	PurchaseOrderGoods.Ref.Currency  AS Currency,
		|	PurchaseOrderGoods.LineNumber    AS LineNumber,
		|	PurchaseOrderGoods.Products   AS Products,
		|	PurchaseOrderGoods.Characteristic AS Characteristic,
		|	PurchaseOrderGoods.Package       AS Package,
		|	PurchaseOrderGoods.Price           AS Price,
		|	PurchaseOrderGoods.Price - PurchaseOrderGoods.Price *
		|	PurchaseOrderGoods.PercentRateOfManualDiscount / 100 AS DiscountedPrice_
		|INTO PreliminaryDataOfDocuments
		|FROM
		|	Document.PurchaseOrder.Goods AS PurchaseOrderGoods
		|WHERE
		|	PurchaseOrderGoods.Ref IN(&Document)
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|";
		
	ElsIf DocumentType = Type("DocumentRef.VendorInvoice") Then
		
		QueryTextReplacement = "
		|SELECT ALLOWED
		|	PurchaseOfGoodsServicesGoods.Ref         AS Ref,
		|	PurchaseOfGoodsServicesGoods.Ref         AS Document,
		|	PurchaseOfGoodsServicesGoods.Ref.Date    AS Date,
		|	PurchaseOfGoodsServicesGoods.Ref.Currency  AS Currency,
		|	PurchaseOfGoodsServicesGoods.LineNumber    AS LineNumber,
		|	PurchaseOfGoodsServicesGoods.Products   AS Products,
		|	PurchaseOfGoodsServicesGoods.Characteristic AS Characteristic,
		|	PurchaseOfGoodsServicesGoods.Package       AS Package,
		|	PurchaseOfGoodsServicesGoods.Price           AS Price,
		|	PurchaseOfGoodsServicesGoods.Price - PurchaseOfGoodsServicesGoods.Price *
		|	PurchaseOfGoodsServicesGoods.PercentRateOfManualDiscount / 100 AS DiscountedPrice_
		|INTO PreliminaryDataOfDocuments
		|FROM
		|	Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
		|WHERE
		|	PurchaseOfGoodsServicesGoods.Ref IN(&Document)
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|";
		
	ElsIf DocumentType = Type("DocumentRef.CommercialProposalForCustomer") Then
		
		QueryTextReplacement = "
		|SELECT ALLOWED
		|	CommercialOfferProducts.Ref                     AS Ref,
		|	CommercialOfferProducts.Ref                     AS Document,
		|	CommercialOfferProducts.Ref.Date                AS Date,
		|	CommercialOfferProducts.Ref.Currency              AS Currency,
		|	CommercialOfferProducts.LineNumber                AS LineNumber,
		|	CommercialOfferProducts.Products               AS Products,
		|	CommercialOfferProducts.Characteristic             AS Characteristic,
		|	CommercialOfferProducts.UnitOfMeasure           AS Package,
		|	CommercialOfferProducts.Price                       AS Price,
		|	CommercialOfferProducts.Price - CommercialOfferProducts.Price *
		|	(CommercialOfferProducts.PercentRateOfAutomaticDiscountMarkup +
		|	CommercialOfferProducts.PercentRateOfManualDiscount) / 100 AS DiscountedPrice_
		|INTO PreliminaryDataOfDocuments
		|FROM
		|	Document.CommercialProposalForCustomer.Goods AS CommercialOfferProducts
		|WHERE
		|	CommercialOfferProducts.Ref IN(&Document)
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|";
		
	EndIf;
	
	QueryText  = Var_DataCompositionSchema.DataSets.DataSet1.Query;
	ReplacementPosition = StrFind(QueryText, "%1");
	StringLength   = StrLen(QueryText);
	QueryText  = Right(QueryText, StringLength - ReplacementPosition - 1);
	QueryText  = QueryTextReplacement + QueryText;
	
	QueryText = StrReplace(QueryText,
	"&QueryTextPackagingFactor1",
	Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
	"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package",
	"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
	
	QueryText = StrReplace(QueryText,
	"&QueryTextPackagingFactor2",
	Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
	"DocumentsData.Package",
	"DocumentsData.Products"));
	
	Var_DataCompositionSchema.DataSets.DataSet1.Query = QueryText;

	// Generate a report
	ReportSettings = Var_SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(Var_DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

Procedure OutputResultOfContextualOpeningControl(ResultDocument)

	WarningTable_ = New SpreadsheetDocument;
	AreaWarning = WarningTable_.Area(1,1,1,1);
	WarningText = NStr("vi = 'Chỉ có thể lập báo cáo trong ngữ cảnh chứng từ:
		| - %1,
		| - %2,
		| - %3,
		| - %4,
		| - %5,
		| - %6,
		| - %7.';
		|ru = 'Отчет может быть сформирован только в контексте документов:
		| - %1,
		| - %2,
		| - %3,
		| - %4,
		| - %5,
		| - %6,
		| - %7.';
		|en = 'You can generate the report only in the context of the documents:
		|- %1,
		| - %2,
		| - %3,
		| - %4,
		| - %5,
		| - %6,
		| - %7.'; fa = 'You can generate the report only in the context of the documents:
		|- %1,
		| - %2,
		| - %3,
		| - %4,
		| - %5,
		| - %6,
		| - %7.';
		|it = 'Il report può essere generato solo nel contesto di documenti quali: 
		|-%1,
		|-%2,
		|-%3,
		|-%4,
		|-%5,
		|-%6,
		|-%7.';
		|pl = 'Raport może być generowany tylko w kontekście dokumentów:
		| - %1,
		| - %2,
		| - %3,
		| - %4,
		| - %5,
		| - %6,
		| - %7.';
		|tr = 'Rapor yalnızca şu belgeler bağlamında oluşturulabilir:
		| - %1,
		| - %2,
		| - %3,
		| - %4,
		| - %5,
		| - %6,
		| - %7.'");
		
	SynonymArray = New Array;
	MetadataDocuments = Metadata.Documents;
	SynonymArray.Add(MetadataDocuments.CustomerInvoiceServices.Synonym);
	SynonymArray.Add(MetadataDocuments.SalesOrder.Synonym);
	SynonymArray.Add(MetadataDocuments.PurchaseOrder.Synonym);
	SynonymArray.Add(MetadataDocuments.CommercialProposalForCustomer.Synonym);
	SynonymArray.Add(MetadataDocuments.VendorInvoice.Synonym);
	SynonymArray.Add(MetadataDocuments.CustomerInvoice.Synonym);
	SynonymArray.Add(Metadata.Catalogs.SalesOpportunitiesToCustomer.Synonym);
	
	WarningText = StringFunctionsClientServer.SubstituteParametersToStringFromArray(WarningText, SynonymArray);
	AreaWarning.Text = WarningText;
	AreaWarning.TextColor = StyleColors.NegativeTextColor;
	ResultDocument.InsertArea(AreaWarning, ResultDocument.Area(1,1,1,1), SpreadsheetDocumentShiftType.Vertical);

EndProcedure

#EndRegion 

#EndIf