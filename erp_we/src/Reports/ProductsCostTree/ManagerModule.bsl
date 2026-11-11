#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

#Region CommandsInReportsSubmenu

// Adds a report command to the list of commands.
// 
// Parameters:
//  ReportsCommands - ValueTable - Description in the report variancereferenceable.Before adding the teamreferences.Teamsreferences
//
// Returns:
// 	ValueTableRow - added command 
Function AddReportCommand(ReportsCommands) Export
	
	If AccessRight("View", Metadata.Reports.ProductsCostTree) Then
		
		ReportCommand = ReportsCommands.Add();
		
		ReportCommand.Id               = Metadata.Reports.ProductsCostTree.FullName();
		ReportCommand.Manager                    = "Report.ProductsCostTree";
		ReportCommand.Presentation               = NStr("vi = 'Cây giá thành sản phẩm';
														|ru = 'Дерево себестоимости продукции';
														|en = 'Product cost tree'; fa = 'درخت بهای محصول';
														|it = 'Diagramma ad albero del costo di produzione';
														|pl = 'Drzewo kosztów własnych produkcji';
														|tr = 'Ürün maliyet ağacı'");
		ReportCommand.MultipleChoice          = False;
		ReportCommand.Importance                    = "Ordinary";
		ReportCommand.FunctionalOptions         = "UseProductionManagement2_2";
		ReportCommand.WriteMode                 = "Post";
		
		ReportCommand.VariantKey                = "ProductionCostTreeContext";
		
		Return ReportCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// Sets advanced report settings
//
// Parameters:
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
//
Procedure CustomizeReportOptions(Settings) Export
	
	DescriptionOfReport = ReportsOptions.DescriptionOfReport(Settings, Metadata.Reports.ProductsCostTree);
	DescriptionOfReport.DefineFormSettings = True;
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "");
	OptionDetails.FunctionalOptions.Add("UseProductionManagement2_2");
	OptionDetails.FunctionalOptions.Add("UseProductionByThirdParty2_5");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích giá thành xuất xưởng, chi tiết đến chi phí chính.';
									|ru = 'Анализ себестоимости продукции, детализированной до первичных затрат.';
									|en = 'Analysis of product cost detailed up to primary costs.'; fa = 'Analysis of product cost detailed up to primary costs.';
									|it = 'Анализ себестоимости продукции, детализированной до первичных затрат.';
									|pl = 'Analiza kosztów własnych produkcji, detalizowanych do pierwotnych wydatków.';
									|tr = 'Birincil giderlere kadar ayrıntılı olarak imal edilen ürün üretim maliyetinin analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "TreeOfProductionCostsOfEnterprise");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích giá thành xuất xưởng của Tập đoàn, chi tiết đến chi phí gốc.';
									|ru = 'Анализ себестоимости продукции предприятия, детализированной до первичных затрат.';
									|en = 'Analysis of enterprise product cost detailed up to primary costs.'; fa = 'Analysis of enterprise product cost detailed up to primary costs.';
									|it = 'Анализ себестоимости продукции предприятия, детализированной до первичных затрат.';
									|pl = 'Analiza kosztów własnych produkcji przedsiębiorstwa, detalizowanych do pierwotnych wydatków.';
									|tr = 'Birincil giderlere kadar ayrıntılı olarak işletmenin imal edilen ürün üretim maliyetinin analizi.'");
	
	OptionDetails = ReportsOptions.OptionDetails(Settings, DescriptionOfReport, "TreeOfCostOfProductionOfOrganization");
	OptionDetails.LongDesc = NStr("vi = 'Phân tích giá thành xuất xưởng của doanh nghiệp chi tiết đến chi phí gốc.';
									|ru = 'Анализ себестоимости продукции организации, детализированной до первичных затрат.';
									|en = 'Analysis of company product cost detailed up to primary costs.'; fa = 'Analysis of company product cost detailed up to primary costs.';
									|it = 'Анализ себестоимости продукции организации, детализированной до первичных затрат.';
									|pl = 'Analiza kosztów własnych produkcji firmy, detalizowanych do pierwotnych wydatków.';
									|tr = 'Birincil giderlere kadar ayrıntılı olarak iş yerinin imal edilen ürün üretim maliyetinin analizi.'");
	
	TMReportOptionsOverridable.DisableReportOption(Settings, DescriptionOfReport, "ProductionCostTreeContext");
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	SetPrivilegedMode(True);
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CostPriceTree") Then
		
		SpreadsheetDocument = GeneratePrintedFormCostTree(PrintParameters);
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"CostPriceTree",
			NStr("vi = 'Cây giá vốn';
				|ru = 'Дерево себестоимости';
				|en = 'Cost tree'; fa = 'درخت بها';
				|it = 'Albero del prezzo di costo';
				|pl = 'Drzewo kosztu własnego';
				|tr = 'Maliyet ağacı'"),
			SpreadsheetDocument);
		
	EndIf;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function GeneratePrintedFormCostTree(PrintParameters)
	
	ResultOfFormation = GetFromTempStorage(PrintParameters.AddressOfTreeInRepository);
	
	DeleteFromTempStorage(PrintParameters.AddressOfTreeInRepository);
	
	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PRINT_OPTIONS_CostPriceTree";
	
	Template = Reports.ProductsCostTree.GetTemplate("CostPriceTree");
	
	ReportParameters = PrintParameters.ReportParameters;
	
	ItemizeTheCostToTheComponents = ReportParameters.ItemizeTheCostToTheComponents;
	
	If ItemizeTheCostToTheComponents Then
		RegionNameSuffix = "";
	Else
		RegionNameSuffix = "|DataWithoutDecryption";
	EndIf;
	ReportPeriod = ReportParameters.Period; //StandardPeriod
	
	TemplateArea = Template.GetArea("Title");
	TemplateArea.Parameters.TitleText = StrTemplate(
		NStr("vi = 'Cây giá vốn trong kỳ từ %1 đến %2';
			|ru = 'Дерево себестоимости за период с %1 по %2';
			|en = 'Cost tree for the period from %1 to %2'; fa = 'Cost tree for the period from %1 to %2';
			|it = 'Albero del prezzo di costo per il periodo da %1 a %2';
			|pl = 'Drzewo kosztu własnego za okres od %1 do %2';
			|tr = '%1 ile %2 arası dönem için maliyet ağacı'"),
		Format(ReportPeriod.StartDate, "DLF=D"),
		Format(ReportPeriod.EndDate, "DLF=D"));
		
	TabDocument.Put(TemplateArea);
	
	PresentationOfCostData = New Map;
	PresentationOfCostData.Insert(1, NStr("vi = 'Theo tiền tệ kế toán quản trị gồm thuế GTGT';
											|ru = 'В валюте упр. учета с НДС';
											|en = 'In management accounting currency, including VAT'; fa = 'به ارز حسابداری مدیریت، با احتساب مالیات بر ارزش افزوده';
											|it = 'In valuta della contabilità gestionale con IVA';
											|pl = 'W walucie zarz. ewidencji z VAT';
											|tr = 'KDV dahil yönetim muhasebesi para birimi cinsinden'"));
	PresentationOfCostData.Insert(2, NStr("vi = 'Theo tiền tệ kế toán quản trị không gồm thuế GTGT';
											|ru = 'В валюте упр. учета без НДС';
											|en = 'In management accounting currency, excluding VAT'; fa = 'به ارز حسابداری مدیریت، بدون مالیات بر ارزش افزوده';
											|it = 'In valuta della contabilità gestionale senza IVA';
											|pl = 'W walucie zarz. ewidencji bez VAT';
											|tr = 'KDV hariç yönetim muhasebesi para birimi cinsinden'"));
	PresentationOfCostData.Insert(3, NStr("vi = 'Theo tiền tệ kế toán quản trị';
											|ru = 'В валюте упр. учета';
											|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
											|it = 'In valuta della contabilità gestionale';
											|pl = 'W walucie ewidencji zarządczej';
											|tr = 'Yönetim muhasebesi para birimi cinsinden'"));
	PresentationOfCostData.Insert(4, NStr("vi = 'Theo tiền tệ kế toán pháp quy';
											|ru = 'В валюте регл. учета';
											|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
											|it = 'In valuta della contabilità regolamentata';
											|pl = 'W walucie ewidencji reglamentowanej';
											|tr = 'Yerel muhasebe para birimi cinsinden'"));
		
	TemplateArea = Template.GetArea("Filter");
	TemplateArea.Parameters.FilterPresentation = StrTemplate(
		NStr("vi = 'Dữ liệu theo giá vốn: %1';
			|ru = 'Данные по себестоимости: %1';
			|en = 'Cost data: %1'; fa = 'Cost data: %1';
			|it = 'Dati del prezzo di costo: %1';
			|pl = 'Dane dot. kosztów własnych: %1';
			|tr = 'Maliyete ilişkin veriler: %1'"), 
		PresentationOfCostData.Get(ReportParameters.Cost_Data));
			
	TabDocument.Put(TemplateArea);
			
	Filter = GetFromTempStorage(PrintParameters.AddressOfSelectionInRepository); //DataCompositionFilter 
	DatasetFields = Reports.ProductsCostTree.GetTemplate(
		"MainDataCompositionSchema").DataSets.IssuedProducts.Fields;
	
	For Each FilterElement In Filter.Items Do
		
		If FilterElement.Use Then
			
			NameOfDatasetField = String(FilterElement.LeftValue);
			DataSetField = DatasetFields.Find(NameOfDatasetField); //DataCompositionSchemaDataSetField
			SelectionItemView = ?(
				DataSetField = Undefined,
				NameOfDatasetField,
				DataSetField.Title);
				
			TemplateArea = Template.GetArea("Filter");
			TemplateArea.Parameters.FilterPresentation = StrTemplate(
				"%1 %2 %3",
				SelectionItemView,
				FilterElement.ComparisonType,
				FilterElement.RightValue);
			
			TabDocument.Put(TemplateArea);
			
		EndIf;
		
	EndDo;
	
	TemplateArea = Template.GetArea("TableHeader|DataWithoutDecryption");
	TabDocument.Put(TemplateArea);
	
	If ReportParameters.ItemizeTheCostToTheComponents Then
		TemplateArea = Template.GetArea("TableHeader|CostComponents");
		TabDocument.Join(TemplateArea);
	EndIf;
	
	If ReportParameters.Cost_Data = 4
	 And GetFunctionalOption("UseLocal") Then
		TemplateArea = Template.GetArea("TableHeader|TA");
		TabDocument.Join(TemplateArea);
	EndIf;
	
	If ReportParameters.Cost_Data = 4
	 And GetFunctionalOption("UseLocal")
	 And ReportParameters.DisplayPRVR Then
		TemplateArea = Template.GetArea("TableHeader|PRVR");
		TabDocument.Join(TemplateArea);
	EndIf;
	
	Level = 1;
	TabDocument.StartRowAutoGrouping();
	
	For Each String In ResultOfFormation.CostPriceTree.Rows Do
		
		OutputLineOfCostTree(TabDocument, Template, String, Level, ReportParameters);
		
	EndDo;
	
	TabDocument.EndRowAutoGrouping();
	
	TemplateArea = Template.GetArea("Footer|DataWithoutDecryption");
	TabDocument.Put(TemplateArea);
	
	If ReportParameters.ItemizeTheCostToTheComponents Then
		TemplateArea = Template.GetArea("Footer|CostComponents");
		TabDocument.Join(TemplateArea);
	EndIf;
	
	If ReportParameters.Cost_Data = 4
	 And GetFunctionalOption("UseLocal") Then
		TemplateArea = Template.GetArea("Footer|TA");
		TabDocument.Join(TemplateArea);
	EndIf;
	
	If ReportParameters.Cost_Data = 4
	 And GetFunctionalOption("UseLocal")
	 And ReportParameters.DisplayPRVR Then
		TemplateArea = Template.GetArea("Footer|PRVR");
		TabDocument.Join(TemplateArea);
	EndIf;
	
	TabDocument.FitToPage = True;
	
	If ItemizeTheCostToTheComponents Then
		TabDocument.PageOrientation = PageOrientation.Landscape;
	Else
		TabDocument.PageOrientation = PageOrientation.Portrait;
	EndIf;
	
	Return TabDocument;
	
EndFunction

Procedure OutputLineOfCostTree(TabDocument, Template, TreeRow, Val Level, ReportParameters)
	
	TemplateArea = Template.GetArea("String|DataWithoutDecryption");
	TemplateArea.Parameters.Fill(TreeRow);
	TemplateArea.Parameters.ProductsPresentation = CreateProductPresentation(
		TreeRow, 
		"Products,Characteristic,Series,Purpose,Currency");
	AreaRow = TabDocument.Put(TemplateArea, Level);
	TabDocument.Area(AreaRow.Top, 2).Indent = Level - 1;
	
	If ReportParameters.ItemizeTheCostToTheComponents Then
		TemplateArea = Template.GetArea("String|CostComponents");
		TemplateArea.Parameters.Fill(TreeRow);
		TabDocument.Join(TemplateArea);
	EndIf;
	
	If ReportParameters.Cost_Data = 4
	 And GetFunctionalOption("UseLocal") Then
		TemplateArea = Template.GetArea("String|TA");
		TemplateArea.Parameters.Fill(TreeRow);
		TabDocument.Join(TemplateArea);
	EndIf;
	
	If ReportParameters.Cost_Data = 4
	 And GetFunctionalOption("UseLocal")
	 And ReportParameters.DisplayPRVR Then
		TemplateArea = Template.GetArea("String|PRVR");
		TemplateArea.Parameters.Fill(TreeRow);
		TabDocument.Join(TemplateArea);
	EndIf;
	
	If TreeRow.Rows.Count() > 0 Then
		
		For Each String In TreeRow.Rows Do
			
			OutputLineOfCostTree(TabDocument, Template, String, Level + 1, ReportParameters);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Function CreateProductPresentation(TreeRow, PresentationFormat)
	
	PresentationFields = StrSplit(PresentationFormat, ",");
	PresentationParts = New Array;
	
	For Each Field In PresentationFields Do
		If ValueIsFilled(TreeRow[Field]) Then
			PresentationParts.Add(TreeRow[Field]);
		EndIf;
	EndDo;
	
	Return StrConcat(PresentationParts, ", ");
	
EndFunction

#EndRegion
		
#EndIf