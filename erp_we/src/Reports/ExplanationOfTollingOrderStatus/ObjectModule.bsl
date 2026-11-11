#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.EditOptionsAllowed = False;
	
EndProcedure

#EndRegion
	
#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	ExternalDataSets = GenerateExternalDatasets(MainCircuitSettings);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);	
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);	
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
EndProcedure

#EndRegion

#Region Private

Function GenerateExternalDatasets(MainCircuitSettings)
	
	Document = DataCompositionClientServer.GetParameter(MainCircuitSettings, "Document").Value;
	Products = DataCompositionClientServer.GetParameter(MainCircuitSettings, "Products").Value;
	Characteristic = DataCompositionClientServer.GetParameter(MainCircuitSettings, "Characteristic").Value;
	ReportVariant = DataCompositionClientServer.GetParameter(MainCircuitSettings, "ReportVariant").Value;
	
	If ReportVariant = "TransferOfGoodsToBailee" Then
		
		QueryText =
		"SELECT ALLOWED
		|	DocumentTable.Ref  AS Document,
		|	GoodsTable.Count AS Count
		|FROM
		|	Document.TransferOfGoodsToBailee AS DocumentTable
		|	
		|	LEFT JOIN Document.TransferOfGoodsToBailee.Goods AS GoodsTable
		|	ON DocumentTable.Ref = GoodsTable.Ref
		|
		|WHERE
		|	GoodsTable.SalesOrder     = &OrderDocument	
		|	AND GoodsTable.Products   = &Products
		|	AND GoodsTable.Characteristic = &Characteristic
		|	AND DocumentTable.Posted";
		
	ElsIf ReportVariant = "ReceiptOfGoodsFromCustodian" Then
		
		QueryText =
		"SELECT ALLOWED
		|	DocumentTable.Ref  AS Document,
		|	GoodsTable.Count AS Count
		|FROM
		|	Document.ReceiptOfGoodsFromCustodian AS DocumentTable
		|	
		|	LEFT JOIN Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsTable
		|	ON DocumentTable.Ref = GoodsTable.Ref
		|
		|WHERE
		|	DocumentTable.Posted
		|	AND GoodsTable.ReferenceOrder   = &OrderDocument
		|	AND GoodsTable.Products   = &Products
		|	AND GoodsTable.Characteristic = &Characteristic";
	
	Else
		QueryText = 
		"SELECT
		|	UNDEFINED AS Document,
		|	0            AS Count
		|WHERE
		|	FALSE
		|";
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("OrderDocument", Document);
	Query.SetParameter("Products", Products);
	Query.SetParameter("Characteristic", Characteristic);
	
	DocumentsList = Query.Execute().Unload();
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("DocumentsList", DocumentsList);
	
	Return ExternalDataSets;

EndFunction

#EndRegion

#EndIf
