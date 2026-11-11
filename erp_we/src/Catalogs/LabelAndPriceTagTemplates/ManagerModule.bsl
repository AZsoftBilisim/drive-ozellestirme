#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" 
		And Not Parameters.Property("Key")
		And Not Parameters.Property("OpenEditor")
		And Not Parameters.Property("CopyingValue") Then
		
		SelectedForm = "WizardOfNew";
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The function retrieves the field name from the available data layout fields.
//
// Parameters:
//  FieldName  - String - field name
//
// Returns:
//   String   - The name of the field in the template.
//
Function NameOfFieldInTemplate(Val FieldName) Export
	
	FieldName = StrReplace(FieldName, ".DeletionMark", ".DeletionMark");
	FieldName = StrReplace(FieldName, ".Owner", ".Owner");
	FieldName = StrReplace(FieldName, ".Code", ".Code");
	FieldName = StrReplace(FieldName, ".Parent", ".Parent");
	FieldName = StrReplace(FieldName, ".Predefined", ".Predefined");
	FieldName = StrReplace(FieldName, ".IsFolder", ".IsFolder");
	FieldName = StrReplace(FieldName, ".Description", ".Description");
	Return FieldName;
	
EndFunction

// Returns a template for the specified destination if it is the only one in the database, otherwise it returns an empty link.
//
// Parameters:
//  Purpose - EnumRef.AssignmentsOfTemplatesOfPriceTagsAndLabels - the purpose of a template
// Returns:
//   CatalogRef.LabelAndPriceTagTemplates - The default template.
//
Function DefaultTemplate(Purpose) Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 2
	|	LabelAndPriceTagTemplates.Ref
	|FROM
	|	Catalog.LabelAndPriceTagTemplates AS LabelAndPriceTagTemplates
	|WHERE
	|	LabelAndPriceTagTemplates.Purpose = &Purpose
	|	AND NOT LabelAndPriceTagTemplates.DeletionMark";
	
	Query.SetParameter("Purpose", Purpose);
	
	Selection = Query.Execute().Select();
	
	If Selection.Count() = 1 Then
		Selection.Next();
		Return Selection.Ref;
	Else
		Return Catalogs.LabelAndPriceTagTemplates.EmptyRef();
	EndIf;
	
EndFunction

// To prepare the structure of the layout template
//
// Parameters:
//  SpreadsheetDocumentField	 - SpreadsheetDocument - Field of a tabular document
//  Purpose				 - EnumRef.AssignmentsOfTemplatesOfPriceTagsAndLabels - purpose.
// 
// Returns:
//  Structure:
//    *GS1DatabarRowCount 	- Number
//    *VerticalAlignment 	- Number
//    *AreaNameSeals 			- String
//    *VerticalQuantity 		- Number
//    *HorizontalQuantity 		- Number
//    *LabelTemplate 				- SpreadsheetDocument
//    *Zoomable 				- Boolean
//    *MonochromeFont 			- Boolean
//    *TextVisible 				- Boolean
//    *FontSize 				- Number
//    *TabularDocumentEditor 	- SpreadsheetDocument
//    *MaintainAspectRatio 			- Boolean
//    *CodeType 						- Number
//    *BarcodeType 				- EnumRef.BarcodeTypes
//    *DetailLevel 				- Number
//
Function PrepareStructureOfTemplateTemplate(SpreadsheetDocumentField, Purpose) Export
	
	StructureOfTemplateTemplate = New Structure;
	TemplateParameters       = New Map;
	ParameterCounter      = 0;
	ParameterNamePrefix  = "TemplateParameter_";
	
	If SpreadsheetDocumentField <> Undefined Then
		
		LabelTemplateArea = SpreadsheetDocumentField.GetArea(SpreadsheetDocumentField.PrintArea.Name);
		CopyPropertiesOfTableDocument(LabelTemplateArea, SpreadsheetDocumentField);
		LabelTemplateArea.PrintArea = LabelTemplateArea.Area("R1C1:"+"R"+LabelTemplateArea.TableHeight+"C"+LabelTemplateArea.TableWidth);
		
		For ColumnNumber = 1 To LabelTemplateArea.TableWidth Do
			
			For LineNumber = 1 To LabelTemplateArea.TableHeight Do
				
				Cell = LabelTemplateArea.Area(LineNumber, ColumnNumber);
				If Cell.FillType = SpreadsheetDocumentAreaFillType.Template Then
					
					ParametersArray = ParameterPositions(Cell.Text);
					
					ParametersCount = ParametersArray.Count();
					For IndexOf = 0 To ParametersCount - 1 Do
						
						Structure = ParametersArray[ParametersCount - 1 - IndexOf];
						
						ParameterName = Mid(Cell.Text, Structure.Begin + 1, Structure.End - Structure.Begin - 1);
						If StrFind(ParameterName, ParameterNamePrefix) = 0 Then
							
							LeftPart = Left(Cell.Text, Structure.Begin);
							RightPart = Right(Cell.Text, StrLen(Cell.Text) - Structure.End+1);
							
							SavedTemplateParameterName = TemplateParameters.Get(ParameterName);
							If SavedTemplateParameterName = Undefined Then
								ParameterCounter = ParameterCounter + 1;
								Cell.Text = LeftPart + (ParameterNamePrefix + ParameterCounter) + RightPart;
								TemplateParameters.Insert(ParameterName, ParameterNamePrefix + ParameterCounter);
							Else
								Cell.Text = LeftPart + (SavedTemplateParameterName) + RightPart;
							EndIf;
							
						EndIf;
						
					EndDo;
					
				ElsIf Cell.FillType = SpreadsheetDocumentAreaFillType.Parameter Then
					
					If StrFind(Cell.Parameter, ParameterNamePrefix) = 0 Then
						SavedTemplateParameterName = TemplateParameters.Get(Cell.Parameter);
						If SavedTemplateParameterName = Undefined Then
							ParameterCounter = ParameterCounter + 1;
							TemplateParameters.Insert(Cell.Parameter, ParameterNamePrefix + ParameterCounter);
							Cell.Parameter = ParameterNamePrefix + ParameterCounter;
						Else
							Cell.Parameter = SavedTemplateParameterName;
						EndIf;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
		BarcodeParameterIsRequired = TemplateParameters.Get(NameOfBarcodeParameter()) = Undefined;
		RequiresCurrencyCodeParameter = TemplateParameters.Get(NameOfCurrencyCodeParameter()) = Undefined;
		
		// We insert a barcode into the parameters
		For Each Drawing In LabelTemplateArea.Drawings Do
			If StrFind(Drawing.Name, NameOfBarcodeParameter()) = 1 Then
				If BarcodeParameterIsRequired Then
					TemplateParameters.Insert(NameOfBarcodeParameter(), ParameterNamePrefix + (ParameterCounter+1));
				EndIf;
				// Replace it with an empty picture.
				Drawing.Picture = New Picture;
			EndIf;
			If StrFind(Drawing.Name, "CurrencySign") = 1 Then
				If RequiresCurrencyCodeParameter Then
					TemplateParameters.Insert(NameOfCurrencyCodeParameter(), ParameterNamePrefix + (ParameterCounter+1));
				EndIf;
				// Replace it with an empty picture.
				Drawing.Picture = New Picture;
			EndIf;
		EndDo;
		
		QuantityPerPage = MaximumNumberPerPage(SpreadsheetDocumentField, Purpose);
		
	EndIf;
	
	Zoomable = True;
	
	If Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForStorageBins
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.ItemsBatchLabel
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.PackingListLabel Then
		CodeType = 4;  // Code128
		TemplateBarcodeType = Enums.BarcodeTypes.Code128;
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelForBarcodesPackages Then
		CodeType = 17; // GS-1 Databar Expanded Stacked
		TemplateBarcodeType = Enums.BarcodeTypes.GS1_DataBarExpandedStacked;
		Zoomable = False;
	ElsIf Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelTape
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper
	 	Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelTape
	 	Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper
	 	Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationTape
	 	Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper Then
		CodeType = 16;  // QR
		TemplateBarcodeType = Enums.BarcodeTypes.QR;
	Else
		CodeType = 1;  // EAN13
		TemplateBarcodeType = Enums.BarcodeTypes.EAN13;
	EndIf;
	
	LabelAndPriceTagTemplatesLocalization.PrepareStructureOfTemplateTemplate(
		Purpose, Zoomable, CodeType, TemplateBarcodeType);
	
	If SpreadsheetDocumentField <> Undefined Then
		StructureOfTemplateTemplate.Insert("LabelTemplate",    LabelTemplateArea);
		StructureOfTemplateTemplate.Insert("AreaNameSeals", LabelTemplateArea.PrintArea.Name);
	Else
		StructureOfTemplateTemplate.Insert("LabelTemplate");
		StructureOfTemplateTemplate.Insert("AreaNameSeals");
	EndIf;
	
	StructureOfTemplateTemplate.Insert("CodeType",                    CodeType);
	StructureOfTemplateTemplate.Insert("BarcodeType",               TemplateBarcodeType);
	StructureOfTemplateTemplate.Insert("FontSize",               12);
	StructureOfTemplateTemplate.Insert("DetailLevel",            1);
	StructureOfTemplateTemplate.Insert("MonochromeFont",           True);
	StructureOfTemplateTemplate.Insert("GS1DatabarRowCount" , 102);
	StructureOfTemplateTemplate.Insert("CanvasRotation" ,              0);
	StructureOfTemplateTemplate.Insert("Zoomable",             Zoomable);
	StructureOfTemplateTemplate.Insert("MaintainAspectRatio",         False);
	StructureOfTemplateTemplate.Insert("VerticalAlignment",   1);
	
	StructureOfTemplateTemplate.Insert("TextVisible",            True);
	StructureOfTemplateTemplate.Insert("TemplateParameters",           TemplateParameters);
	StructureOfTemplateTemplate.Insert("TabularDocumentEditor",  SpreadsheetDocumentField);
	
	If SpreadsheetDocumentField <> Undefined Then
		StructureOfTemplateTemplate.Insert("VerticalQuantity",      QuantityPerPage.Vertical);
		StructureOfTemplateTemplate.Insert("HorizontalQuantity",    QuantityPerPage.Horizontal);
	Else
		StructureOfTemplateTemplate.Insert("VerticalQuantity",      1);
		StructureOfTemplateTemplate.Insert("HorizontalQuantity",    1);
	EndIf;
	
	Return StructureOfTemplateTemplate;
	
EndFunction

// Maximum number per page.
//
// Parameters:
//  SpreadsheetDocumentField	 - SpreadsheetDocument - Field of a tabular document.
//  Purpose				 - EnumRef.AssignmentsOfTemplatesOfPriceTagsAndLabels - purpose.
// 
// Returns:
//  Structure - The maximum number horizontally and vertically.
//
Function MaximumNumberPerPage(SpreadsheetDocumentField, Purpose) Export
	
	MaxCount = New Structure("Horizontal, Vertical, LongDesc", 1, 1);
	
	If Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.GoodsPriceTag
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.AssetLabelPaper
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.SubAssetLabelPaper
		Or Purpose = Enums.AssignmentsOfTemplatesOfPriceTagsAndLabels.LabelInventoryInOperationPaper Then
	
		TemplateArea = SpreadsheetDocumentField.GetArea(SpreadsheetDocumentField.PrintArea.Name);
		
		BarcodeDrawing = TemplateArea.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
		BarcodeDrawing.Place(TemplateArea.Area("R1C1:"+"R"+Format(TemplateArea.TableHeight,"NG=0")+"C"+Format(TemplateArea.TableWidth,"NG=0")));
		
		If SpreadsheetDocumentField.PageOrientation = PageOrientation.Landscape Then
			PageHeight = SpreadsheetDocumentField.PageWidth;
			PageWidth = SpreadsheetDocumentField.PageHeight;
		Else
			PageHeight = SpreadsheetDocumentField.PageHeight;
			PageWidth = SpreadsheetDocumentField.PageWidth;
		EndIf;
		
		If Not SpreadsheetDocumentField.FitToPage Then
			If BarcodeDrawing.Width <> 0 Then
				MaxCount.Horizontal = Int((PageWidth-SpreadsheetDocumentField.LeftMargin-SpreadsheetDocumentField.RightMargin)/BarcodeDrawing.Width);
			Else
				MaxCount.Horizontal = 1;
			EndIf;
		Else
			MaxCount.Horizontal = 3;
		EndIf;
		
		If BarcodeDrawing.Height <> 0 Then
			MaxCount.Vertical = Int((PageHeight-SpreadsheetDocumentField.TopMargin-SpreadsheetDocumentField.BottomMargin)/BarcodeDrawing.Height);
		Else
			MaxCount.Vertical = 1;
		EndIf;
		
	EndIf;
	
	PageSize = PageSize(SpreadsheetDocumentField);
	
	LongDesc = NStr("vi = 'Trang%1 vừa vặn theo chiều dọc:%2, theo chiều ngang:%3';
					|ru = 'На странице %1 помещается по вертикали: %2, по горизонтали: %3';
					|en = 'On page %1 it is placed vertically: %2, horizontally: %3'; fa = 'On page %1 it is placed vertically: %2, horizontally: %3';
					|it = 'Nella pagina %1 presente in verticale: %2, in orizzontale: %3';
					|pl = 'Na stronie %1 znajduje się w pionie: %2, w poziomie: %3';
					|tr = '%1 sayfasında dikey olarak yerleştirildi: %2, yatay olarak: %3'");
	MaxCount.LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
		LongDesc,
		PageSize,
		MaxCount.Vertical,
		MaxCount.Horizontal);
	
	Return MaxCount;
	
EndFunction

#Region PrintingSamples

// Function - to Obtain samples of bar codes
//
// Returns:
// 	Array of Structure - with properties:
// 		* CodeType - Number - Type of code
// 		* Description - String - 
// 		* Sample - String - 
// 		* BarcodeType - EnumRef.BarcodeTypes - 
//
Function GetBarcodeSamples() Export
	
	Codes = New Array;
	
	CodeExample = New Structure("CodeType, Description, Sample, BarcodeType");
	CodeExample.CodeType      = 99;
	CodeExample.Description = "AutoDetect";
	CodeExample.Sample       = "4600051000057";
	CodeExample.BarcodeType = Enums.BarcodeTypes.EmptyRef();
	Codes.Add(CodeExample);
	
	CodeExample = New Structure("CodeType, Description, Sample, BarcodeType");
	CodeExample.CodeType      = 0;
	CodeExample.Description = "EAN8";
	CodeExample.Sample       = "20059217";
	CodeExample.BarcodeType = Enums.BarcodeTypes.EAN8;
	Codes.Add(CodeExample);
	
	CodeExample = New Structure("CodeType, Description, Sample, BarcodeType");
	CodeExample.CodeType      = 1;
	CodeExample.Description = "EAN13";
	CodeExample.Sample       = "4600051000057";
	CodeExample.BarcodeType = Enums.BarcodeTypes.EAN13;
	Codes.Add(CodeExample);
	
	CodeExample = New Structure("CodeType, Description, Sample, BarcodeType");
	CodeExample.CodeType      = 3;
	CodeExample.Description = "Code39";
	CodeExample.Sample       = "2PMP-468-PJM";
	CodeExample.BarcodeType = Enums.BarcodeTypes.Code39;
	Codes.Add(CodeExample);
	
	CodeExample = New Structure("CodeType, Description, Sample, BarcodeType");
	CodeExample.CodeType      = 4;
	CodeExample.Description = "Code128";
	CodeExample.Sample       = "93-0bonUM68";
	CodeExample.BarcodeType = Enums.BarcodeTypes.Code128;
	Codes.Add(CodeExample);
	
	CodeExample = New Structure("CodeType, Description, Sample, BarcodeType");
	CodeExample.CodeType      = 6;
	CodeExample.Description = "PDF417";
	CodeExample.Sample       = "22N00002V5ORQU6VW0L830Q60127006018620RJHMTLQQIIG5WIC69SNVVSSPHDMB8LL";
	CodeExample.BarcodeType = Enums.BarcodeTypes.PDF417;
	Codes.Add(CodeExample);
	
	CodeExample = New Structure("CodeType, Description, Sample, BarcodeType");
	CodeExample.CodeType      = 11;
	CodeExample.Description = "ITF14";
	CodeExample.Sample       = "17350053850252";
	CodeExample.BarcodeType = Enums.BarcodeTypes.ITF14;
	Codes.Add(CodeExample);
	
	CodeExample = New Structure("CodeType, Description, Sample, BarcodeType");
	CodeExample.CodeType      = 2;
	CodeExample.Description = "GS1-128";
	CodeExample.Sample       = "(00)100000004500000192";
	CodeExample.BarcodeType = Enums.BarcodeTypes.GS1_128;
	Codes.Add(CodeExample);
	
	CodeExample = New Structure("CodeType, Description, Sample, BarcodeType");
	CodeExample.CodeType      = 16;
	CodeExample.Description = "QR";
	CodeExample.Sample       = "www.1c.ru";
	CodeExample.BarcodeType = Enums.BarcodeTypes.QR;
	Codes.Add(CodeExample);
	
	CodeExample = New Structure("CodeType, Description, Sample, BarcodeType");
	CodeExample.CodeType      = 17;
	CodeExample.Description = "GS1 DataBar Expanded Stacked";
	CodeExample.Sample       = "(00)100000004500000192";
	CodeExample.BarcodeType = Enums.BarcodeTypes.GS1_DataBarExpandedStacked;
	Codes.Add(CodeExample);
	
	CodeExample = New Structure("CodeType, Description, Sample, BarcodeType");
	CodeExample.CodeType      = 18;
	CodeExample.Description = "DataMatrix";
	CodeExample.Sample       = "(01)04059155701764(21)kjlKzMLWJyv1j";
	CodeExample.BarcodeType = Enums.BarcodeTypes.DataMatrix;
	Codes.Add(CodeExample);
	
	CodeExample = New Structure("CodeType, Description, Sample, BarcodeType");
	CodeExample.CodeType      = 24;
	CodeExample.Description = "GS1-DataMatrix";
	CodeExample.Sample       = "(01)04059155701764(21)kjlKzMLWJyv1j";
	CodeExample.BarcodeType = Enums.BarcodeTypes.GS1_DataMatrix;
	Codes.Add(CodeExample);
	
	Return Codes;
	
EndFunction

// Get parameters for printing a sample product label
//
// Parameters:
//  ForWhat					 - CatalogRef - Purpose
//  CodeType					 - Number - Type of code
//  UUID	 - UUID - unique identifier.
// 
// Returns:
//  Structure - print options
//
Function GetParametersForPrintingSampleProductLabel(ForWhat, CodeType, UUID) Export
	
	Goods = New ValueTable;
	Goods.Columns.Add("Products",                New TypeDescription("CatalogRef.Products"));
	Goods.Columns.Add("Characteristic",              New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Goods.Columns.Add("Series",                       New TypeDescription("CatalogRef.ItemsBatches"));
	Goods.Columns.Add("Package",                    New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Goods.Columns.Add("Price",                        New TypeDescription("Number"));
	Goods.Columns.Add("PriceAdditionally",           New TypeDescription("Number"));
	Goods.Columns.Add("Barcode",                    New TypeDescription("String"));
	Goods.Columns.Add("PriceTagTemplate",               New TypeDescription("CatalogRef.LabelAndPriceTagTemplates"));
	Goods.Columns.Add("NumberOfPriceTags",          New TypeDescription("Number"));
	Goods.Columns.Add("LabelsTemplate",              New TypeDescription("CatalogRef.LabelAndPriceTagTemplates"));
	Goods.Columns.Add("LabelTemplatePrepared",  New TypeDescription("CatalogRef.LabelAndPriceTagTemplates"));
	Goods.Columns.Add("NumberOfLabels",                       New TypeDescription("Number"));
	Goods.Columns.Add("WarehouseStockBalance",                          New TypeDescription("Number"));
	Goods.Columns.Add("QuantityOfGoodsInDocument",                     New TypeDescription("Number"));
	Goods.Columns.Add("SoldByWeight",                                  New TypeDescription("Boolean"));
	Goods.Columns.Add("LastPriceChangeDate",              New TypeDescription("Date"));
	Goods.Columns.Add("LastPriceChangeDateAdditionally", New TypeDescription("Date"));
	
	NewRow = Goods.Add();
	NewRow.Products      = ForWhat;
	NewRow.Price              = 100;
	NewRow.PriceAdditionally = 100;
	NewRow.NumberOfLabels = 30;
	
	NewRow.Barcode = "";
	Codes = GetBarcodeSamples();
	For Each TSRow In Codes Do
		If TSRow.CodeType = CodeType Then
			NewRow.Barcode = TSRow.Sample;
			Break;
		EndIf;
	EndDo;
	
	MaximumCodeOfGoodsSoldByWeight = OfflinePeripheralsServerCall.MaximumCodeOfGoodsSoldByWeight();
	RuleOfExportToScales = False;
	
	PrintParameters = New Structure;
	PrintParameters.Insert("Goods", PutToTempStorage(Goods, UUID));
	PrintParameters.Insert("Organization", GetOrganizationToPrintSample());
	PrintParameters.Insert("ExchangeRule", PredefinedValue("Catalog.RulesOfExchangeWithOfflinePeripherals.EmptyRef"));
	PrintParameters.Insert("MaximumCodeOfGoodsSoldByWeight", MaximumCodeOfGoodsSoldByWeight);
	PrintParameters.Insert("RuleOfExportToScales",          RuleOfExportToScales);
	PrintParameters.Insert("PriceKind",       GetKindOfPriceToPrintSample());
	PrintParameters.Insert("Date",          CurrentSessionDate());
	PrintParameters.Insert("PriceKindAdditional", GetKindOfPriceToPrintSample());
	PrintParameters.Insert("DateAdditionally",    CurrentSessionDate());
	PrintParameters.Insert("Warehouse",                GetWarehouseToPrintSample());
	
	Return PrintParameters;
	
EndFunction

// Get parameters for printing a sample product price tag
//
// Parameters:
//  ForWhat					 - CatalogRef - Purpose
//  CodeType					 - Number - Type of code
//  UUID	 - UUID - unique identifier.
// 
// Returns:
//  Structure - print options
//
Function GetParametersForPrintingSampleProductPriceTag(ForWhat, CodeType, UUID) Export
	
	Goods = New ValueTable;
	Goods.Columns.Add("Products",                New TypeDescription("CatalogRef.Products"));
	Goods.Columns.Add("Characteristic",              New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Goods.Columns.Add("Package",                    New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Goods.Columns.Add("Price",                        New TypeDescription("Number"));
	Goods.Columns.Add("PriceAdditionally",           New TypeDescription("Number"));
	Goods.Columns.Add("Barcode",                    New TypeDescription("String"));
	Goods.Columns.Add("PriceTagTemplate",               New TypeDescription("CatalogRef.LabelAndPriceTagTemplates"));
	Goods.Columns.Add("NumberOfPriceTags",          New TypeDescription("Number"));
	Goods.Columns.Add("LabelsTemplate",              New TypeDescription("CatalogRef.LabelAndPriceTagTemplates"));
	Goods.Columns.Add("LabelTemplatePrepared",  New TypeDescription("CatalogRef.LabelAndPriceTagTemplates"));
	Goods.Columns.Add("NumberOfLabels",                       New TypeDescription("Number"));
	Goods.Columns.Add("WarehouseStockBalance",                          New TypeDescription("Number"));
	Goods.Columns.Add("QuantityOfGoodsInDocument",                     New TypeDescription("Number"));
	Goods.Columns.Add("SoldByWeight",                                  New TypeDescription("Boolean"));
	Goods.Columns.Add("LastPriceChangeDate",              New TypeDescription("Date"));
	Goods.Columns.Add("LastPriceChangeDateAdditionally", New TypeDescription("Date"));
	
	NewRow = Goods.Add();
	NewRow.Products      = ForWhat;
	NewRow.Price              = 100;
	NewRow.PriceAdditionally = 100;
	NewRow.NumberOfPriceTags = 30;
	
	NewRow.Barcode = "";
	Codes = GetBarcodeSamples();
	For Each TSRow In Codes Do
		If TSRow.CodeType = CodeType Then
			NewRow.Barcode = TSRow.Sample;
			Break;
		EndIf;
	EndDo;
	
	MaximumCodeOfGoodsSoldByWeight = OfflinePeripheralsServerCall.MaximumCodeOfGoodsSoldByWeight();
	RuleOfExportToScales = False;
	
	PrintParameters = New Structure;
	PrintParameters.Insert("Goods", PutToTempStorage(Goods, UUID));
	PrintParameters.Insert("Organization",   GetOrganizationToPrintSample());
	PrintParameters.Insert("ExchangeRule", PredefinedValue("Catalog.RulesOfExchangeWithOfflinePeripherals.EmptyRef"));
	PrintParameters.Insert("MaximumCodeOfGoodsSoldByWeight", MaximumCodeOfGoodsSoldByWeight);
	PrintParameters.Insert("RuleOfExportToScales",          RuleOfExportToScales);
	PrintParameters.Insert("PriceKind",       GetKindOfPriceToPrintSample());
	PrintParameters.Insert("Date",          CurrentSessionDate());
	PrintParameters.Insert("PriceKindAdditional", GetKindOfPriceToPrintSample());
	PrintParameters.Insert("DateAdditionally",    CurrentSessionDate());
	PrintParameters.Insert("Warehouse",                GetWarehouseToPrintSample());
	
	Return PrintParameters;
	
EndFunction

// Get parameters for printing a sample warehouse cell label
//
// Parameters:
//  ForWhat					 - CatalogRef - Purpose
//  CodeType					 - Number - Type of code
//  UUID	 - UUID - unique identifier.
// 
// Returns:
//  Structure - print options
//
Function GetParametersForPrintingSampleLabelOfWarehouseCell(ForWhat, CodeType, UUID) Export
	
	StorageBins = New ValueTable;
	StorageBins.Columns.Add("Cell", New TypeDescription("CatalogRef.StorageBins"));
	StorageBins.Columns.Add("Barcode", New TypeDescription("String"));
	
	NewRow = StorageBins.Add();
	NewRow.Cell = ForWhat;
	
	NewRow.Barcode = "";
	Codes = GetBarcodeSamples();
	For Each TSRow In Codes Do
		If TSRow.CodeType = CodeType Then
			NewRow.Barcode = TSRow.Sample;
			Break;
		EndIf;
	EndDo;
	
	PrintParameters = New Structure;
	PrintParameters.Insert("StorageBins", PutToTempStorage(StorageBins, UUID));
	PrintParameters.Insert("LabelsTemplate", Catalogs.LabelAndPriceTagTemplates.EmptyRef());
	PrintParameters.Insert("Copies", 1);
	
	Return PrintParameters;
	
EndFunction

// Get parameters for printing a sample label of an item series
//
// Parameters:
//  ForWhat					 - CatalogRef - Purpose
//  CodeType					 - Number - Type of code
//  UUID	 - UUID - unique identifier.
// 
// Returns:
//  Structure - print options
//
Function GetParametersForPrintingSampleLabelsOfProductSeries(ForWhat, CodeType, UUID) Export
	
	ItemsBatches = New ValueTable;
	ItemsBatches.Columns.Add("Series",		New TypeDescription("CatalogRef.ItemsBatches"));
	ItemsBatches.Columns.Add("Barcode",	New TypeDescription("String"));
	
	NewRow = ItemsBatches.Add();
	NewRow.Series = ForWhat;
	
	NewRow.Barcode = "";
	Codes = GetBarcodeSamples();
	For Each TSRow In Codes Do
		If TSRow.CodeType = CodeType Then
			NewRow.Barcode = TSRow.Sample;
			Break;
		EndIf;
	EndDo;
	
	PrintParameters = New Structure;
	PrintParameters.Insert("AddressInStorage", PutToTempStorage(ItemsBatches, UUID));
	PrintParameters.Insert("LabelsTemplate", Catalogs.LabelAndPriceTagTemplates.EmptyRef());
	PrintParameters.Insert("Copies", 1);
	
	Return PrintParameters;
	
EndFunction

// To obtain the parameters for printing sample labels, packing lists
//
// Parameters:
//  ForWhat					 - CatalogRef - Purpose
//  CodeType					 - Number - Type of code
//  UUID	 - UUID - unique identifier.
// 
// Returns:
//  Structure - print options
//
Function GetParametersForPrintingSampleLabelsPackingSheets(ForWhat, CodeType, UUID) Export
	
	TablePackingLists = New ValueTable;
	TablePackingLists.Columns.Add("Ref",		New TypeDescription("DocumentRef.PackingList"));
	TablePackingLists.Columns.Add("Barcode",	New TypeDescription("String"));
	
	NewRow = TablePackingLists.Add();
	NewRow.Ref = ForWhat;
	NewRow.Barcode = "";
	Codes = GetBarcodeSamples();
	For Each TSRow In Codes Do
		If TSRow.CodeType = CodeType Then
			NewRow.Barcode = TSRow.Sample;
			Break;
		EndIf;
	EndDo;
		
	PrintParameters = New Structure;
	PrintParameters.Insert("AddressInStorage", PutToTempStorage(TablePackingLists, UUID));
	PrintParameters.Insert("LabelsTemplate", Catalogs.LabelAndPriceTagTemplates.EmptyRef());
	PrintParameters.Insert("Copies", 1);	
	
	Return PrintParameters;
	
EndFunction

// Get parameters for printing a sample label for an operational object
//
// Parameters:
//  ForWhat					 - CatalogRef - Purpose
//  CodeType					 - Number - Type of code
//  UUID	 - UUID - unique identifier.
// 
// Returns:
//  Structure - print options
//
Function GetParametersForPrintingSampleLabelTMTSVOperation(ForWhat, CodeType, UUID) Export
	
	PrintData = New ValueTable;
	PrintData.Columns.Add("Lot", New TypeDescription("CatalogRef.LotsOfInventoryInOperation"));
	PrintData.Columns.Add("AssetID", New TypeDescription("String"));
	PrintData.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	PrintData.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	PrintData.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
	
	NewRow = PrintData.Add();
	NewRow.Lot = ForWhat;
	NewRow.AssetID = "0123456789";
	
	PrintParameters = New Structure;
	PrintParameters.Insert("AddressInStorage", PutToTempStorage(PrintData, UUID));
	PrintParameters.Insert("LabelsTemplate", Catalogs.LabelAndPriceTagTemplates.EmptyRef());
	PrintParameters.Insert("Copies", 1);
	
	Return PrintParameters;
	
EndFunction

// Get parameters for printing a sample label for an operational object
//
// Parameters:
//  ForWhat					 - CatalogRef - Purpose
//  CodeType					 - Number - Type of code
//  UUID	 - UUID - unique identifier.
// 
// Returns:
//  Structure - print options
//
Function GetParametersForPrintingSampleLabelOfObjectOfOperation(ForWhat, CodeType, UUID) Export
	
	PrintData = New ValueTable;
	PrintData.Columns.Add("Asset", New TypeDescription("CatalogRef.Assets"));
	PrintData.Columns.Add("Barcode",           New TypeDescription("String"));
	
	NewRow = PrintData.Add();
	NewRow.Asset = ForWhat;
	NewRow.Barcode = Common.ObjectAttributeValue(ForWhat, "AssetID");
	
	PrintParameters = New Structure;
	PrintParameters.Insert("AddressInStorage", PutToTempStorage(PrintData, UUID));
	PrintParameters.Insert("LabelsTemplate", Catalogs.LabelAndPriceTagTemplates.EmptyRef());
	PrintParameters.Insert("Copies", 1);
	
	Return PrintParameters;
	
EndFunction

// Get the parameters for printing the sample label of the node of the operation object
//
// Parameters:
//  ForWhat - CatalogRef.SubAssets - Purpose
//  CodeType	- Number - Type of code
//  UUID	- UUID - unique identifier.
// 
// Returns:
//  Structure - print options
//
Function GetParametersForPrintingSampleLabelOfNodeOfObjectOfOperation(ForWhat, CodeType, UUID) Export
	
	PrintData = New ValueTable;
	PrintData.Columns.Add("Node", New TypeDescription("CatalogRef.SubAssets"));
	PrintData.Columns.Add("Barcode", New TypeDescription("String"));
	
	NewRow = PrintData.Add();
	NewRow.Node = ForWhat;
	NewRow.Barcode = Common.ObjectAttributeValue(ForWhat, "Barcode");
	
	PrintParameters = New Structure;
	PrintParameters.Insert("AddressInStorage", PutToTempStorage(PrintData, UUID));
	PrintParameters.Insert("LabelsTemplate", Catalogs.LabelAndPriceTagTemplates.EmptyRef());
	PrintParameters.Insert("Copies", 1);
	
	Return PrintParameters;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

Function PageSize(SpreadsheetDocumentField)
	
	PageHeight = SpreadsheetDocumentField.PageHeight;
	PageWidth = SpreadsheetDocumentField.PageWidth;
	
	Description = String(PageWidth)+"x"+String(PageHeight);
	
	If PageWidth = 210 And PageHeight = 297 Then
		Description = "A4";
	ElsIf PageWidth = 148 And PageHeight = 210 Then
		Description = "A5";
	ElsIf PageWidth = 105 And PageHeight = 148 Then
		Description = "A6";
	ElsIf PageWidth = 74 And PageHeight = 105 Then
		Description = "A7";
	ElsIf PageWidth = 52 And PageHeight = 74 Then
		Description = "A8";
	ElsIf PageWidth = 37 And PageHeight = 52 Then
		Description = "A9";
	ElsIf PageWidth = 26 And PageHeight = 37 Then
		Description = "A10";
	EndIf;
	
	Return Description;
	
EndFunction

// Parameters:
// 	CellText - String - Cell text
// Returns:
// 	Array of Structure - consists of:
// 		* Begin - Number - 
// 		* End - Number - 
//
Function ParameterPositions(CellText)
	
	Array = New Array;
	
	Begin = -1;
	End  = -1;
	OpeningParenthesisCounter = 0;
	ClosingParenthesesCounter = 0;
	
	For IndexOf = 1 To StrLen(CellText) Do
		Char = Mid(CellText, IndexOf, 1);
		If Char = "[" Then
			OpeningParenthesisCounter = OpeningParenthesisCounter + 1;
			If OpeningParenthesisCounter = 1 Then
				Begin = IndexOf;
			EndIf;
		ElsIf Char = "]" Then
			ClosingParenthesesCounter = ClosingParenthesesCounter + 1;
			If ClosingParenthesesCounter = OpeningParenthesisCounter Then
				End = IndexOf;
				
				Array.Add(New Structure("Begin, End", Begin, End));
				
				Begin = -1;
				End  = -1;
				OpeningParenthesisCounter = 0;
				ClosingParenthesesCounter = 0;
				
			EndIf;
		EndIf;
	EndDo;
	
	Return Array;
	
EndFunction

Function NameOfBarcodeParameter() Export
	
	Return "Barcode";
	
EndFunction

Function NameOfCurrencyCodeParameter() Export
	
	Return "PriceKind.PriceCurrency.Code";
	
EndFunction

Procedure CopyPropertiesOfTableDocument(Receiver, Source)
	
	Receiver.FitToPage = Source.FitToPage;
	Receiver.PageHeight = Source.PageHeight;
	Receiver.PrintParametersName = Source.PrintParametersName;
	Receiver.PrinterName = Source.PrinterName;
	Receiver.PrintParametersKey = Source.PrintParametersKey;
	Receiver.Copies = Source.Copies;
	Receiver.PrintScale = Source.PrintScale;
	Receiver.PageOrientation = Source.PageOrientation;
	Receiver.TopMargin = Source.TopMargin;
	Receiver.LeftMargin = Source.LeftMargin;
	Receiver.BottomMargin = Source.BottomMargin;
	Receiver.RightMargin = Source.RightMargin;
	Receiver.Collate = Source.Collate;
	Receiver.HeaderSize = Source.HeaderSize;
	Receiver.FooterSize = Source.FooterSize;
	Receiver.PageSize = Source.PageSize;
	Receiver.PrintAccuracy = Source.PrintAccuracy;
	Receiver.BlackAndWhite = Source.BlackAndWhite;
	Receiver.PageWidth = Source.PageWidth;
	Receiver.PerPage = Source.PerPage;
	
EndProcedure

#Region PrintingSamples

Function GetOrganizationToPrintSample()
	
	Query = New Query("
	|SELECT ALLOWED TOP 1
	|	Data.Ref AS Ref
	|FROM
	|	Catalog.Companies AS Data
	|WHERE
	|	NOT Data.DeletionMark
	|	AND NOT Data.Predefined
	|	AND Data.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|");
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Catalogs.Companies.EmptyRef();
	EndIf;
	
EndFunction

Function GetKindOfPriceToPrintSample()
	
	Query = New Query("
	|SELECT ALLOWED TOP 1
	|	Data.Ref AS Ref
	|FROM
	|	Catalog.TypesOfPrices AS Data
	|WHERE
	|	NOT Data.DeletionMark
	|");
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Catalogs.TypesOfPrices.EmptyRef();
	EndIf;
	
EndFunction

Function GetWarehouseToPrintSample()
	
	Query = New Query("
	|SELECT ALLOWED TOP 1
	|	Data.Ref AS Ref
	|FROM
	|	Catalog.Warehouses AS Data
	|WHERE
	|	NOT Data.DeletionMark
	|");
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return Catalogs.Warehouses.EmptyRef();
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
