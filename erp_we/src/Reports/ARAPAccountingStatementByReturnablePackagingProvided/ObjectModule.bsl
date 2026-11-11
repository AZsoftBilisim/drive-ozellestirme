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
	Settings.Events.OnCreateAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
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
		
		ThisForm.ParametersForm.PurposeUseKey = Parameters.CommandParameter;
		Parameters.PurposeUseKey = Parameters.CommandParameter;
		
		LoggerParameter = GetDocumentsForSettlementsWithSuppliers(Parameters.CommandParameter);
		
		ThisForm.ParametersForm.Filter.Insert("DocumentTransfers_", LoggerParameter);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function GetDocumentsForSettlementsWithSuppliers(Document)
	
	Query = New Query("
		|SELECT ALLOWED DISTINCT
		|	Goods.DocumentSalesOfGoodsAndServices AS  DocumentSalesOfGoodsAndServices
		|FROM
		|	Document.ReturnOfGoodsFromCustomer.Goods AS Goods
		|WHERE
		|	Goods.Ref IN (&Document)
		|UNION ALL
		|SELECT DISTINCT
		|	Goods.DocumentSalesOfGoodsAndServices AS  DocumentSalesOfGoodsAndServices
		|FROM
		|	Document.ReturnablePackagingRedemptionByCustomer.Goods AS Goods
		|WHERE
		|	Goods.Ref IN (&Document)
		|UNION ALL
		|SELECT DISTINCT
		|	CustomerInvoice.Ref AS  DocumentSalesOfGoodsAndServices
		|FROM
		|	Document.CustomerInvoice AS CustomerInvoice
		|WHERE
		|	Goods.Ref IN (&Document)
		|");
		
	If TypeOf(Document) <> Type("ValueList") Then
		DocumentsList = New ValueList();
		DocumentsList.Add(Document);
	Else
		DocumentsList = Document;
	EndIf;
		
	Query.SetParameter("Document", DocumentsList);
	DocumentsArray = Query.Execute().Unload().UnloadColumn("DocumentSalesOfGoodsAndServices");
	FilterList = New ValueList();
	FilterList.LoadValues(DocumentsArray);
	Return FilterList;
	
EndFunction

#EndRegion

#EndIf