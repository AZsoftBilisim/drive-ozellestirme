#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = ReportsCommands.Add();
	ReportCommand.Manager = Metadata.Reports.SupplySchemeGoods.FullName();
	ReportCommand.Presentation = NStr("vi = 'Hàng hóa không có sơ đồ đảm bảo';
										|ru = 'Товары без схемы обеспечения';
										|en = 'Goods without supply scheme'; fa = 'کالای بدون طرح تأمین';
										|it = 'Merci senza uno schema di approvvigionamento';
										|pl = 'Wiersze pozycji bez schematu zaopatrzenia';
										|tr = 'Arz şeması olmayan ürünler'");
	ReportCommand.VisibilityInForms = "ListForm";
	ReportCommand.MultipleChoice = False;
	ReportCommand.Importance = "Ordinary";
	ReportCommand.VariantKey = "ProductsWithoutSecuritySchemeContext";
	
EndProcedure

// Returns the number of products for which the specified security scheme is used.
// 
// Parameters:
//  SupplyScheme - CatalogRef.SupplySchemes - Link to the security scheme.
// Returns:
//  Number - The number of uses of the scheme.
Function NumberOfUses(SupplyScheme) Export
	
	If Not ValueIsFilled(SupplyScheme) Then
		Return 0;
	EndIf;
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	COUNT(*) AS NumberOfUses
	|FROM
	|	Catalog.Products AS Table
	|WHERE
	|	Table.SupplyScheme = &Ref
	|	AND NOT Table.DeletionMark";
	Query.SetParameter("Ref", SupplyScheme);
	Selection = Query.Execute().Select();
	
	NumberOfUses = 0;
	If Selection.Next() Then
		NumberOfUses = Selection.NumberOfUses;
	EndIf;
	
	Return NumberOfUses;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	If FormType = "ObjectForm" Then
		StandardProcessing = False;
		Parameters.Insert("Source", "SupplyScheme");
		SelectedForm = Metadata.DataProcessors.SettingOfProcurementStrategies.Forms.Form;
	EndIf;
EndProcedure

#EndRegion

