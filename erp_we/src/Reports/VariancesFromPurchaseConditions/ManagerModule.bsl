#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes the deviation tree for generating the report
//
// Returns:
// 		ValueTree - Tree of Worship - Initialized tree of values:
// 		* LineNumber - Number - Line number
// 		* Parameter - String - parameter name
// 		* ParameterDeviation - String - Text with an error
//
Function InitializeRejectionTree() Export
	
	DeviationTree = New ValueTree();
	DeviationTree.Columns.Add("LineNumber");
	DeviationTree.Columns.Add("Parameter");
	DeviationTree.Columns.Add("ParameterDeviation");
	
	Return DeviationTree
	
EndFunction

// Adds deviations from the document header to the array of deviations from the purchase conditions
//
// Parameters:
// 		NameOfHeaderParameter        - String - Name of the parameter to reject
// 		HeaderParameterDeviation - String - Text with an error
// 		ArrayOfDeviations         - Array - An array of disabilities.
//
Procedure AddHeaderDeviationToArrayOfDeviations(NameOfHeaderParameter, HeaderParameterDeviation, ArrayOfDeviations) Export
	
	StructureOfDeviations = New Structure();
	StructureOfDeviations.Insert("NameOfHeaderParameter", NameOfHeaderParameter);
	StructureOfDeviations.Insert("HeaderParameterDeviation", HeaderParameterDeviation);
	
	ArrayOfDeviations.Add(StructureOfDeviations);
EndProcedure

// Adds deviations from the table part of the document to the tree of deviations from the purchase conditions.
//
// Parameters:
// 		LineNumber          - Number - Line number with the error
// 		Parameter             - String - Name of the parameter to reject
// 		ParameterDeviation  - String - Text with an error
// 		DeviationTree     - See InitializeRejectionTree
//
Procedure AddRowDeviationToDeviationTree(LineNumber, Parameter, ParameterDeviation, DeviationTree) Export
	FoundRow  = DeviationTree.Rows.Find(LineNumber,"LineNumber");
	If FoundRow = Undefined Then
		DeviationLine             = DeviationTree.Rows.Add();
		DeviationLine.LineNumber = LineNumber;
		NestedRejectionString    = DeviationLine.Rows.Add();
	Else
		NestedRejectionString = FoundRow.Rows.Add();
	EndIf;
	NestedRejectionString.LineNumber         = LineNumber;
	NestedRejectionString.Parameter            = Parameter;
	NestedRejectionString.ParameterDeviation = ParameterDeviation;
EndProcedure

// Placement settings in the report panel.
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//       It can be used to get settings for a variant of this report using the Variationreports function.Obisnuieste().
//   DescriptionOfReport - ValueTreeRow - The settings of this report that have already been generated and are ready to be changed.
//       See ReportsOptions.DescriptionOfReport.
//
// Description:
//   See ReportsOptionsOverridable.CustomizeReportsOptions.
//
// Auxiliary methods:
//	Setting the variant = Report variationsreferences.Description of the variant (Settings, Report settings, "<Variant Name>");
//	Report variationsreferences.Set the output mode of the Report panel (Settings, Report settings, True/False);
//
// Examples:
//
//  1. Setting the description of the option.
//	Option Setups = Report variationsreferences.Description of the variant (Settings, Report settings, "<Variant Name>");
//	Option settings.Description = NStr("ru = '<Description>'");
//
//  2. Disabling the report option.
//	Option Setups = Report variationsreferences.Description of the variant (Settings, Report settings, "<Variant Name>");
//	Option settings.Enabled = False;
//
Procedure CustomizeReportOptions(Settings, DescriptionOfReport) Export
	
	// Disabling contextual options
	TMReportOptionsOverridable.DisableReport(DescriptionOfReport);
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#Region DataOutput

// Displays the report title
//
// Parameters:
//  ReportTable		 - SpreadsheetDocument - table document of the report
//  ThereAreVariances		 - Boolean - the sign of deviation
//  NoAgreementSpecified	 - Boolean - indicates whether the agreement exists.
//
Procedure OutputReportHeader(ReportTable, ThereAreVariances, NoAgreementSpecified) Export
	
	Template = GetTemplate("Template");
	If ThereAreVariances Then
		Area = Template.GetArea("Title");
	ElsIf NoAgreementSpecified Then
		Area = Template.GetArea("HeaderWithoutAgreement");
	Else
		Area = Template.GetArea("TitleWithoutDeviation");
	EndIf;
	ReportTable.Put(Area);
	
EndProcedure

// Displays deviations in the header area
//
// Parameters:
//  ArrayOfDeviations - Array - an array of deviations
//  ReportTable	 - SpreadsheetDocument - Table document of the report.
//
Procedure DisplayDeviationsInHeaderArea(ArrayOfDeviations, ReportTable) Export
	Template = GetTemplate("Template");
	Area = Template.GetArea("RejectionHeader");
	Area.Parameters.Title = NStr("vi = 'Đặt tương ứng với điều kiện mua hàng';
								|ru = 'Соответствие условиям закупок';
								|en = 'Compliance with purchasing conditions'; fa = 'Compliance with purchasing conditions';
								|it = 'Conformità con le condizioni di acquisto';
								|pl = 'Zgodność z warunkami zakupów';
								|tr = 'Satın alma koşullarına uygunluk'");
	ReportTable.Put(Area);
	
	Area = Template.GetArea("HeaderRejection");
	ReportTable.StartRowGroup();
	For Each Deviation In ArrayOfDeviations Do
		Area.Parameters.Fill(Deviation);
		ReportTable.Put(Area);
	EndDo; 
	ReportTable.EndRowGroup();
EndProcedure

// Displays deviations for items of the document
//
// Parameters:
//  DocumentPurchases			 - DocumentObject - document being checked
//  DeviationTreeGoods	 - See InitializeRejectionTree
//  ReportTable			 - SpreadsheetDocument - Table document of the report.
//
Procedure OutputAllItemsInPurchaseDocument(Val DocumentPurchases, DeviationTreeGoods, ReportTable) Export
	
	ThisIsPurchaseOrder = TypeOf(DocumentPurchases) = Type("DocumentRef.PurchaseRequest");
	ThisIsConvention = TypeOf(DocumentPurchases) = Type("CatalogRef.TermsOfPurchaseFromVendors");
	UseManualDiscounts = Not ThisIsPurchaseOrder And GetFunctionalOption("UseDiscountAdjustmentsInPurchases");
	
	TableName        = Common.TableNameByRef(DocumentPurchases.Ref);
	TSName             = SalesServer.GetNameOfTablePart(TableName);
	
	Template = GetTemplate("Template");
	Area = Template.GetArea("RejectionHeader");
	Area.Parameters.Title = NStr("vi = 'Đặt tương ứng hàng hóa với điều kiện mua hàng';
								|ru = 'Соответствие товаров условиям закупок';
								|en = 'Compliance of goods with purchasing conditions'; fa = 'Compliance of goods with purchasing conditions';
								|it = 'Conformità della merce con le condizioni di acquisto';
								|pl = 'Zgodność towarów z warunkami zakupów';
								|tr = 'Malların satın alma koşullarına uygunluğu'");
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	
	If Not ThisIsConvention Then 
		If UseManualDiscounts Then
			HeaderArea = Template.GetArea("TableHeaderWithDiscount");
			RegionName = "TableRowWithDiscount";
			NameLineArea = "TableRowWithDiscount_";
		Else
			HeaderArea = Template.GetArea("TableHeaderWithoutDiscount");
			RegionName = "TableRowWithoutDiscount";
			NameLineArea = "TableRowWithoutDiscount_";
		EndIf;
	Else 
		HeaderArea = Template.GetArea("ProductsAgreementHeader");
		RegionName = "LineProductsAgreement";
		NameLineArea = "ProductsLineAgreement";
	EndIf;
	HeaderArea.Parameters.Currency = DocumentPurchases.Currency;
	ReportTable.Put(HeaderArea);
	
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	Products.Ref AS Products,
	|	Products.UnitOfMeasure AS UnitOfMeasure
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	Products.Ref IN(&ProductsArray)
	|
	|GROUP BY
	|	Products.Ref,
	|	Products.UnitOfMeasure";
	Query.SetParameter("ProductsArray", DocumentPurchases.Goods.UnloadColumn("Products"));
	TableOfUnits = Query.Execute().Unload();
	
	AreaDeviation       = Template.GetArea("TableRowDeviation");
	LineAreaDeviation = AreaDeviation.Areas.TableRowDeviation_; // SpreadsheetDocumentRange
	
	EvenString = False;
	
	For Each Deviation In DeviationTreeGoods.Rows Do
		Area = Template.GetArea(RegionName);
		RowArea = Area.Areas[NameLineArea]; // SpreadsheetDocumentRange
		
		If EvenString Then
			BackColor = StyleColors.FieldAlternativeBackColor;
		Else
			BackColor = StyleColors.FieldBackColor;
		EndIf;
		
		TSPurchaseDocument = DocumentPurchases[TSName]; // TabularSection
		LineProducts_ = TSPurchaseDocument.Get(Deviation.LineNumber-1);
		Area.Parameters.Fill(LineProducts_);
		
		ProductPresentation = ProductsClientServer.ProductPresentation(
			LineProducts_.Products,
			LineProducts_.Characteristic);
		Area.Parameters.OwnGoods = ProductPresentation;
		
		If Not ValueIsFilled(LineProducts_.Package) Then 
			FoundRows = TableOfUnits.FindRows(New Structure("Products", LineProducts_.Products));
			If FoundRows.Count() > 0 Then
				Area.Parameters.Package = FoundRows.Get(0).UnitOfMeasure;
			EndIf;
		Else
			Area.Parameters.Count = LineProducts_.NumberOfPackages;
		EndIf;
		
		RowArea.BackColor = BackColor;
		
		For Each RowWithDeviation In Deviation.Rows Do
			Try
				ParameterName = NameLineArea + RowWithDeviation.Parameter;
				ParameterArea = Area.Areas[ParameterName]; // SpreadsheetDocumentRange
				ParameterArea.TextColor = StyleColors.NegativeTextColor;
			Except
				Continue;
			EndTry;
		EndDo;
		ReportTable.Put(Area);
		
		ReportTable.StartRowGroup();
		For Each RowWithDeviation In Deviation.Rows Do
			LineAreaDeviation.BackColor = BackColor;
			AreaDeviation.Parameters.Fill(RowWithDeviation);
			ReportTable.Put(AreaDeviation);
		EndDo;
		ReportTable.EndRowGroup();
		
		EvenString = Not EvenString;
	EndDo;
	
	Area = Template.GetArea("TableRowLast");
	ReportTable.Put(Area);
	
	ReportTable.EndRowGroup();
EndProcedure

// Displays deviations in the stage of payment document
//
// Parameters:
//  DocumentPurchases			 - DocumentObject - document being checked
//  DeviationTree		 - See InitializeRejectionTree
//  ReportTable			 - SpreadsheetDocument - Table document of the report.
//
Procedure DisplayAllStagesOfPaymentForPurchaseDocument(Val DocumentPurchases, DeviationTree, ReportTable) Export
	
	Template = GetTemplate("Template");
	
	PackageDepositIsRequired = DocumentPurchases.PackageDepositIsRequired;
	
	If PackageDepositIsRequired Then
		HeaderArea = Template.GetArea("HeaderOfPaymentStagesWithPackaging");
		RegionName = "LineOfPaymentStagesWithPackaging";
		NameLineArea = "PaymentStagesLineWithContainer";
	Else
		HeaderArea = Template.GetArea("PaymentStagesHeader");
		RegionName = "LineOfPaymentStages";
		NameLineArea = "PaymentStagesLine";
	EndIf;
	
	Area = Template.GetArea("RejectionHeader");
	Area.Parameters.Title = NStr("vi = 'Đặt tương ứng nhóm giá với điều kiện mua hàng';
								|ru = 'Соответствие этапов оплаты условиям закупок';
								|en = 'Payment milestones compliance with purchasing conditions'; fa = 'Payment milestones compliance with purchasing conditions';
								|it = 'Conformità delle fasi di pagamento con i le condizioni di acquisto';
								|pl = 'Zgodność etapów z warunkami zakupów';
								|tr = 'Ödeme aşamalarının satın alma koşullarına uygunluğu'");
	ReportTable.Put(Area);
	
	ReportTable.StartRowGroup();
	ReportTable.Put(HeaderArea);
	
	AreaDeviation       = Template.GetArea("TableRowDeviation");
	LineAreaDeviation = AreaDeviation.Areas.TableRowDeviation_; // SpreadsheetDocumentRange
	
	EvenString = False;
	
	For Each Deviation In DeviationTree.Rows Do
		Area = Template.GetArea(RegionName);
		RowArea = Area.Areas[NameLineArea]; // SpreadsheetDocumentRange
		
		If EvenString Then
			BackColor = StyleColors.FieldAlternativeBackColor;
		Else
			BackColor = StyleColors.FieldBackColor;
		EndIf;
		
		LineProducts_ = DocumentPurchases.PaymentScheduleSteps.Get(Deviation.LineNumber-1);
		Area.Parameters.Fill(LineProducts_);
		
		RowArea.BackColor = BackColor;
		
		For Each RowWithDeviation In Deviation.Rows Do
			Try
				ParameterName = NameLineArea + RowWithDeviation.Parameter;
				ParameterArea = Area.Areas[ParameterName]; // SpreadsheetDocumentRange
				ParameterArea.TextColor = StyleColors.NegativeTextColor;
			Except
				Continue;
			EndTry;
		EndDo;
		ReportTable.Put(Area);
		
		ReportTable.StartRowGroup();
		For Each RowWithDeviation In Deviation.Rows Do
			LineAreaDeviation.BackColor = BackColor;
			AreaDeviation.Parameters.Fill(RowWithDeviation);
			ReportTable.Put(AreaDeviation);
		EndDo;
		ReportTable.EndRowGroup();
		
		EvenString = Not EvenString;
	EndDo;
	
	Area = Template.GetArea("TableRowLast");
	ReportTable.Put(Area);
	
	ReportTable.EndRowGroup();
EndProcedure

#EndRegion

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
// Returns:
//   ValueTableRow - new report command.
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.VariancesFromPurchaseConditions) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.VariancesFromPurchaseConditions.FullName();
		ReportCommand.Presentation = NStr("vi = 'Chênh lệch so với các điều kiện mua hàng';
											|ru = 'Отклонения от условий закупок';
											|en = 'Variance from purchase conditions'; fa = 'انحراف از شرایط خرید';
											|it = 'Deviazioni dalle condizioni degli acquisti';
											|pl = 'Odchylenia od warunków zakupów';
											|tr = 'Satın alma koşullarından sapmalar'");
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#EndRegion

#EndIf