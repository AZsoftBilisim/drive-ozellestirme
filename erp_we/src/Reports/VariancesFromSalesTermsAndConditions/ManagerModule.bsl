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
	DeviationTree.Columns.Add("IsRecordsSet");
	DeviationTree.Columns.Add("SetPrice");
	DeviationTree.Columns.Add("Parameter");
	DeviationTree.Columns.Add("ParameterDeviation");
	
	Return DeviationTree
	
EndFunction

// Adds deviations in the header of the document into an array of deviations from the terms and conditions of sale
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

// Adds deviations by discounts/margins of the document to the array of deviations from the terms of sale.
//
// Parameters:
// 		LineNumber         - Number - Line number with the error
// 		DiscountMarkup       - String - Discount with deviation
// 		ParameterDeviation - String - Text with an error
// 		ArrayOfDeviations    - Array of Structure - an array of deviations:
// 			* LineNumber         - Number
// 			* DiscountMarkup       - String
// 			* ParameterDeviation - String
//
Procedure AddDiscountMarkUpDeviationToArrayOfDeviations(LineNumber, DiscountMarkup, ParameterDeviation, ArrayOfDeviations) Export
	
	StructureOfDeviations = New Structure();
	StructureOfDeviations.Insert("LineNumber",   LineNumber);
	StructureOfDeviations.Insert("DiscountMarkup", DiscountMarkup);
	StructureOfDeviations.Insert("ParameterDeviation", ParameterDeviation);
	
	ArrayOfDeviations.Add(StructureOfDeviations);
	
EndProcedure

// Adds deviations from the table part of the document to the tree of deviations from sales conditions.
//
// Parameters:
// 		LineNumber         - Number - Line number with the error
// 		Parameter            - String - Name of the parameter to reject
// 		ParameterDeviation - String - Text with an error
// 		DeviationTree    - See InitializeRejectionTree
// 		IsRecordsSet            - Boolean
// 		SetPrice          - Number
//
Procedure AddRowDeviationToDeviationTree(LineNumber, Parameter, ParameterDeviation, DeviationTree, IsRecordsSet = False, SetPrice = 0) Export
	FoundRow  = DeviationTree.Rows.Find(LineNumber,"LineNumber");
	If FoundRow = Undefined Then
		DeviationLine             = DeviationTree.Rows.Add();
		DeviationLine.LineNumber = LineNumber;
		DeviationLine.IsRecordsSet    = IsRecordsSet;
		DeviationLine.SetPrice  = SetPrice;
		NestedRejectionString    = DeviationLine.Rows.Add();
	Else
		NestedRejectionString = FoundRow.Rows.Add();
	EndIf;
	NestedRejectionString.LineNumber         = LineNumber;
	NestedRejectionString.IsRecordsSet            = IsRecordsSet;
	NestedRejectionString.SetPrice          = SetPrice;
	NestedRejectionString.Parameter            = Parameter;
	NestedRejectionString.ParameterDeviation = ParameterDeviation;
EndProcedure

// StandardSubsystems.ReportsOptions

// Placement settings in the report panel.
//	The first parameter is passed "as is" from the report Variantdetermined.Set up report variants ().
//       Can be used to get the settings of a variant of this report using the report Variantsfunction.Description of the variant().
//
// Parameters:
//  Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//  DescriptionOfReport - ValueTreeRow - The settings of this report
//       that have already been generated using the Report Options function.The description of the report() and ready to be changed.
//       See "Properties for changing" procedures variationreferences.Set up Report Variants().
//
// Description:
//   See ReportsOptionsOverridable.CustomizeReportsOptions
//
// Auxiliary methods:
//	Setting the variant = Report variationsreferences.Description of the variant (Settings, Report settings, "<Variant Name>");
//	Report variationsreferences.Set the output mode of the Report panel(Settings, Report settings, True/False);
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
//	End of examples.
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
//  ThereAreVariances		 - Boolean - indicates a deviation.
//
Procedure OutputReportHeader(ReportTable, ThereAreVariances) Export
	
	Template = GetTemplate("Template");
	If ThereAreVariances Then
		Area = Template.GetArea("Title");
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
	TitleStructure = New Structure("Title", NStr("vi = 'Đặt tương ứng với điều kiện bán hàng';
												|ru = 'Соответствие условиям продаж';
												|en = 'Compliance with sales terms and conditions'; fa = 'Compliance with sales terms and conditions';
												|it = 'Conformità con le condizioni di vendita';
												|pl = 'Zgodność z warunkami sprzedaży';
												|tr = 'Satış koşullarına uygunluk'"));
	Area.Parameters.Fill(TitleStructure);
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
//  DocumentSales			 - DocumentObject - document being checked
//  DeviationTreeGoods	 - See InitializeRejectionTree
//  ReportTable			 - SpreadsheetDocument - Table document of the report.
//
Procedure DisplayAllProductsForSale(Val DocumentSales, DeviationTreeGoods, ReportTable) Export
	
	UseManualDiscounts = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	ThisIsConvention = TypeOf(DocumentSales) = Type("CatalogRef.TermsOfSale");
	
	TableName        = Common.TableNameByRef(DocumentSales.Ref);
	TSName             = SalesServer.GetNameOfTablePart(TableName);
	
	Template = GetTemplate("Template");
	
	Area = Template.GetArea("RejectionHeader");
	TitleStructure = New Structure("Title", NStr("vi = 'Đặt tương ứng hàng hóa với điều kiện bán hàng';
												|ru = 'Соответствие товаров условиям продаж';
												|en = 'Compliance of goods with sales terms and conditions'; fa = 'Compliance of goods with sales terms and conditions';
												|it = 'Conformità della merce con le condizioni di vendita';
												|pl = 'Zgodność towarów z warunkami sprzedaży';
												|tr = 'Malların satış koşullarına uygunluğu'"));
	Area.Parameters.Fill(TitleStructure);
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
	HeaderArea.Parameters.Currency = DocumentSales.Currency;
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
	Query.SetParameter("ProductsArray", DocumentSales[TSName].UnloadColumn("Products"));
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
		
		LineProducts_ = DocumentSales[TSName].Get(Deviation.LineNumber-1);
		Area.Parameters.Fill(LineProducts_);
		
		If Deviation.IsRecordsSet Then
			Area.Parameters.Fill(New Structure("Price", Deviation.SetPrice));
		EndIf;
		
		If Deviation.IsRecordsSet Then
			ProductPresentation = ProductsClientServer.ProductPresentation(
				LineProducts_.ProductsInSet,
				LineProducts_.ItemVariantOfSet);
		Else
			ProductPresentation = ProductsClientServer.ProductPresentation(
				LineProducts_.Products,
				LineProducts_.Characteristic);
		EndIf;
		Area.Parameters.OwnGoods = ProductPresentation;
		
		If TSName = "Services" Or Not ValueIsFilled(LineProducts_.Package) Then 
			FoundRows = TableOfUnits.FindRows(New Structure("Products", LineProducts_.Products));
			If FoundRows.Count() > 0 Then
				Area.Parameters.Package = FoundRows.Get(0).UnitOfMeasure;
			EndIf;
		EndIf;
		If Not ValueIsFilled(LineProducts_.PriceKind) Then 
			Area.Parameters.PriceKind = NStr("vi = 'tùy ý';
											|ru = 'произвольный';
											|en = 'Arbitrary'; fa = 'دلخواه';
											|it = 'libero';
											|pl = 'Arbitrary';
											|tr = 'isteğe bağlı'");
		EndIf;
		
		RowArea.BackColor = BackColor;
		
		For Each RowWithDeviation In Deviation.Rows Do
			Try
				ParameterName = NameLineArea + RowWithDeviation.Parameter;
				ParameterArea = Area.Areas[ParameterName];// SpreadsheetDocumentRange
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

// Displays the deviation of the discounts/markups
//
// Parameters:
//  ArrayOfDeviations  - See AddDiscountMarkUpDeviationToArrayOfDeviations.ArrayOfDeviations
//  ReportTable	  - SpreadsheetDocument - Table document of the report.
//
Procedure DisplayDeviationsDiscountsMargins(ArrayOfDeviations, ReportTable) Export
	
	Template = GetTemplate("Template");
	
	Area = Template.GetArea("RejectionHeader");
	TitleStructure = New Structure("Title", NStr("vi = 'Đặt tương ứng chiết khấu/phụ thu với điều kiện bán hàng';
												|ru = 'Соответствие скидок/наценок условиям продаж';
												|en = 'Compliance of discounts/markups with sales terms and conditions'; fa = 'Compliance of discounts/markups with sales terms and conditions';
												|it = 'Conformità di sconti / ricariche con condizioni di vendita';
												|pl = 'Zgodność rabatów/marż z warunkami sprzedaży';
												|tr = 'İndirimlerin/ek ücretlerin satış koşullarına uygunluğu'"));
	Area.Parameters.Fill(TitleStructure);
	ReportTable.Put(Area);
	ReportTable.StartRowGroup();

	Area = Template.GetArea("DiscountAgreementHeader");
	ReportTable.Put(Area);
	
	Area = Template.GetArea("DiscountAgreementLine");
	AreaDeviation = Template.GetArea("TableRowDeviation");
	
	EvenString = False;
	
	For Each Deviation In ArrayOfDeviations Do
		If EvenString Then
			BackColor = StyleColors.FieldAlternativeBackColor;
		Else
			BackColor = StyleColors.FieldBackColor;
		EndIf;
		
		AreaLineDeviation = AreaDeviation.Areas.TableRowDeviation_; // SpreadsheetDocumentRange
		AreaLineDeviation.BackColor = BackColor;
		
		DiscountArea_ = Area.Areas.DiscountAgreementsLine; // SpreadsheetDocumentRange
		DiscountArea_.BackColor = BackColor;
		
		If Deviation.LineNumber > 0 Then
			Area.Parameters.Fill(Deviation);
			ReportTable.Put(Area);
		EndIf;
		AreaDeviation.Parameters.Fill(Deviation);
		ReportTable.Put(AreaDeviation);
		EvenString = Not EvenString;
	EndDo; 
	
	Area = Template.GetArea("TableRowLast");
	ReportTable.Put(Area);
	
	ReportTable.EndRowGroup();
EndProcedure

// Displays deviations by price group
//
// Parameters:
//  DocumentSales			 - CatalogObject - the element being checked
//  DeviationTree		 - See InitializeRejectionTree
//  ReportTable			 - SpreadsheetDocument - Table document of the report.
//
Procedure DisplayComplianceOfProductPriceGroupsWithSalesConditions(Val DocumentSales, DeviationTree, ReportTable) Export
	
	Template = GetTemplate("Template");
	
	UseManualDiscounts = GetFunctionalOption("UseLimitsForDiscountAdjustmentsInSalesByTermsOfSales");
	If UseManualDiscounts Then
		HeaderArea = Template.GetArea("PriceGroupsHeader");
		RegionName = "PriceGroupsLine";
		NameLineArea = "PriceGroupsRow";
	Else
		HeaderArea = Template.GetArea("PriceGroupsWithoutDiscountHeader");
		RegionName = "LinePriceGroupsWithoutDiscount";
		NameLineArea = "PriceGroupsLineWithoutDiscount";
	EndIf;
	
	Area = Template.GetArea("RejectionHeader");
	TitleStructure = New Structure("Title", NStr("vi = 'Đặt tương ứng nhóm giá với điều kiện bán hàng';
												|ru = 'Соответствие ценовых групп условиям продаж';
												|en = 'Compliance of price groups with sales terms and conditions'; fa = 'Compliance of price groups with sales terms and conditions';
												|it = 'Conformità dei gruppi di prezzi con condizioni di vendita';
												|pl = 'Zgodność grup cenowych z warunkami sprzedaży';
												|tr = 'Fiyat grubunun satış koşullarına uygunluğu'"));
	Area.Parameters.Fill(TitleStructure);
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
		
		LineProducts_ = DocumentSales.PriceGroups.Get(Deviation.LineNumber-1);
		Area.Parameters.Fill(LineProducts_);
		
		If Not ValueIsFilled(LineProducts_.PricesKind) Then 
			Area.Parameters.PricesKind = NStr("vi = 'tùy ý';
												|ru = 'произвольный';
												|en = 'Arbitrary'; fa = 'دلخواه';
												|it = 'libero';
												|pl = 'Arbitrary';
												|tr = 'isteğe bağlı'");
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
//  DocumentSales			 - DocumentObject - document being checked
//  DeviationTree		 - See InitializeRejectionTree
//  ReportTable			 - SpreadsheetDocument - Table document of the report.
//
Procedure DisplayAllStagesOfPaymentAndSales(Val DocumentSales, DeviationTree, ReportTable) Export
	
	Template = GetTemplate("Template");
	
	PackageDepositIsRequired = DocumentSales.PackageDepositIsRequired;
	ThisIsConvention    = TypeOf(DocumentSales) = Type("CatalogRef.TermsOfSale");
	
	If ThisIsConvention Then
		If PackageDepositIsRequired Then
			HeaderArea = Template.GetArea("ChartHeaderWithTara");
			RegionName = "LineGraphWithTara";
			NameLineArea = "ChartRowWithTara";
		Else
			HeaderArea = Template.GetArea("ChartHeader");
			RegionName = "LineGraph";
			NameLineArea = "GraphLine";
		EndIf;
	Else
		If PackageDepositIsRequired Then
			HeaderArea = Template.GetArea("HeaderOfPaymentStagesWithPackaging");
			RegionName = "LineOfPaymentStagesWithPackaging";
			NameLineArea = "PaymentStagesLineWithContainer";
		Else
			HeaderArea = Template.GetArea("PaymentStagesHeader");
			RegionName = "LineOfPaymentStages";
			NameLineArea = "PaymentStagesLine";
		EndIf;
	EndIf;
	
	Area = Template.GetArea("RejectionHeader");
	TitleStructure = New Structure("Title", NStr("vi = 'Đặt tương ứng giai đoạn thanh toán với điều kiện bán hàng';
												|ru = 'Соответствие этапов оплаты условиям продаж';
												|en = 'Compliance of payment milestones with sales terms and conditions'; fa = 'Compliance of payment milestones with sales terms and conditions';
												|it = 'Conformità delle fasi di pagamento alle condizioni di vendita';
												|pl = 'Zgodność etapów płatności z warunkami sprzedaży';
												|tr = 'Ödeme aşamalırının satış koşullarına uygunluğu'"));
	Area.Parameters.Fill(TitleStructure);
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
		
		LineProducts_ = DocumentSales.PaymentScheduleSteps.Get(Deviation.LineNumber-1);
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
// 	ValueTableRow
Function AddReportCommand(ReportsCommands) Export

	If AccessRight("View", Metadata.Reports.VariancesFromSalesTermsAndConditions) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Manager = Metadata.Reports.VariancesFromSalesTermsAndConditions.FullName();
		ReportCommand.Presentation = NStr("vi = 'Chênh lệch so với các điều kiện bán hàng';
											|ru = 'Отклонения от условий продаж';
											|en = 'Variances from sales terms and conditions'; fa = 'انحراف از شرایط و ضوابط فروش';
											|it = 'Deviazioni dalle condizioni di vendita';
											|pl = 'Odchylenia od warunków sprzedaż';
											|tr = 'Satış koşullarından sapma'");
		
		ReportCommand.WriteMode = "Write";
		ReportCommand.MultipleChoice = False;
		ReportCommand.Importance = "Ordinary";
		
		Return ReportCommand;
		
	EndIf;

	Return Undefined;

EndFunction

#EndRegion

#EndRegion

#EndIf