#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// Called when composing the report result.
//
// Parameters:
// 	ResultDocument - SpreadsheetDocument
// 	DetailsData - DataCompositionDetailsData
// 	StandardProcessing - Boolean
//
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	QueryText = DataCompositionSchema.DataSets.PriceList.Query;
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(QueryText, TablesNames);
	
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemPricesCrossSectionOfTheLatest.Package",
			"ItemPricesCrossSectionOfTheLatest.Products"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextSecondPackingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"KitComponentsPricesByKit.Package",
			"KitComponentsPricesByKit.Products"));
	
	QueryText = InformationRegisters.ProductRestrictions.SubstituteConnection(
		QueryText,
		"SubstituteGoodsRestriction",
		"WarehouseStockBalance.Products,WarehouseStockBalance.Characteristic,WarehouseStockBalance.Warehouse");
	
	QueryText = StrReplace(QueryText,
		"&SetsAreDisplayed",
		?(ReportDisplaysProductSets(SettingsComposer),
			"True",
			"False"));
	
	DataCompositionSchema.DataSets.PriceList.Query = QueryText;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	ProductRangeServer.EnableSelectionByVSKDAssortment(SettingsComposer);
	
	ComposerDataParameters = SettingsComposer.GetSettings().DataParameters;
	
	// Checking to open a contextual version of the report without selections:
	// such a report may slow down the program,
	// so in this case, a selection based on an empty price type is added.
	VariantKey = Undefined;
	CompositionSettings = SettingsComposer.GetSettings();
	
	If SettingsComposer.Settings.AdditionalProperties.Property("VariantKey", VariantKey)
		And VariantKey = "PriceListContext"
		And CompositionSettings.Filter.Items.Count() = 0 Then
		
		DataCompositionClientServer.AddFilter(
			CompositionSettings,
			New DataCompositionField("PriceKind"),
			Catalogs.TypesOfPrices.EmptyRef(),
			DataCompositionComparisonType.Equal);
		
		SettingsComposer.LoadSettings(CompositionSettings);
		
	EndIf;
	
	ImageSizeParameter = ComposerDataParameters.Items.Find("ImageSize_");
	If ImageSizeParameter <> Undefined Then
		SizeStructure =  SetSizeOfImages(ImageSizeParameter.Value);
		OutputImage = ImageSizeParameter.Use;
	Else
		OutputImage = False;
	EndIf;
	
	ConfigureImageOutput(OutputImage);
	
	If OutputImage Then
		
		StandardProcessing = False;
		
		TemplateComposer = New DataCompositionTemplateComposer;
		Template = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings(), DetailsData);	
		
		CompositionProcessor = New DataCompositionProcessor;
		CompositionProcessor.Initialize(Template, , DetailsData, True);
		
		OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
		OutputProcessor.SetDocument(ResultDocument);
		OutputProcessor.Output(CompositionProcessor);
		
		//Correction of the result document
		NumberOfColumns = ResultDocument.TableWidth;
		CntOfRws = ResultDocument.TableHeight;
		
		For Qty = 1 To NumberOfColumns Do
			
			For Page1 = 1 To CntOfRws Do
				
				CurCell = ResultDocument.Area(Page1, Qty);
				If CurCell.Details = Undefined Then
					Continue;
				EndIf;
				
				DecryptionFields = DetailsData.Items[CurCell.Details].GetFields();
				
				If DecryptionFields.Count() > 0 Then
					
					CurDecryptionField = DecryptionFields[0].Value;
					
					If TypeOf(CurDecryptionField) = Type("CatalogRef.ProductsAttachedFiles") 
						And ValueIsFilled(CurDecryptionField) Then
						
						Drawing = FilesOperations.FileBinaryData(CurDecryptionField);
						If Drawing <> Undefined Then
							
							CurCell.RowHeight = SizeStructure.RowHeight;
							CurCell.ColumnWidth = SizeStructure.ColumnWidth;
							
							Rice = ResultDocument.Drawings.Add(SpreadsheetDocumentDrawingType.Picture);
							Rice.PictureSize = PictureSize.Proportionally;
							Rice.Picture = New Picture(Drawing);
							Rice.Place(CurCell);
							
						EndIf;
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
// 	Form - ClientApplicationForm - report form.
// 	VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
// 	Settings - Structure - see the return value of the Clientserver report.Get a setup report for silence().
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.OnLoadVariantAtServer = True;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
// 	Form - ClientApplicationForm - report form.
// 	NewDCSettings - DataCompositionSettings - settings to upload to the settings Builder.
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	Report = Form.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
// 	Form - ClientApplicationForm - report form.
// 	NewDCSettings - DataCompositionSettings - settings to upload to the settings Builder.
//
Procedure OnLoadVariantAtServer(Form, NewDCSettings) Export
	
	VariantKey = Undefined;
	If SettingsComposer.Settings.AdditionalProperties.Property("VariantKey", VariantKey)
		And VariantKey = "PriceListContext" Then
		
		Form.ReportSettings.SelectAndEditOptionsWithoutSavingAllowed = False;
		Form.ReportSettings.EditOptionsAllowed = False;
		
		Form.Items.AllSettings.Visible = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private
	
Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseSeveralPriceTypes") Then
		
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(
			FormSettingsComposer,
			"PriceKind");
		
	EndIf;
	
EndProcedure

Function ReportDisplaysProductSets(Var_SettingsComposer)
	
	SetsAreDisplayed = False;
	SearchValue = New DataCompositionField("SetOfProducts");
	
	For Each Group In DataCompositionClientServer.GetGroupings(Var_SettingsComposer.GetSettings()) Do
		
		If Not Group.Value.Use Then
			Continue;
		EndIf;
			
		GroupFields = Group.Value.GroupFields; // DataCompositionGroupFields
		For Each Item In GroupFields.Items Do
			
			If Item.Use
				And Item.Field = SearchValue Then
				
				SetsAreDisplayed = True;
				Break;
				
			EndIf;
			
		EndDo;
		
		If SetsAreDisplayed Then
			Break;
		EndIf;
		
	EndDo;
	
	Return SetsAreDisplayed;
	
EndFunction

//defines the possible sizes for report images
Function SetSizeOfImages(ImageSize_)
	
	RowHeight = 60;
	ColumnWidth = 20;
	
	If ImageSize_ = Enums.PictureSize.Small Then
		
		RowHeight = 40;
		ColumnWidth = 13;
		
	ElsIf ImageSize_ = Enums.PictureSize.Average_1 Then
		
		RowHeight = 60;
		ColumnWidth = 20;
		
	ElsIf ImageSize_ = Enums.PictureSize.Big Then
		
		RowHeight = 120;
		ColumnWidth = 40;
		
	EndIf;
	
	Structure = New Structure;
	Structure.Insert("RowHeight", RowHeight);
	Structure.Insert("ColumnWidth", ColumnWidth);
	
	Return Structure;
	
EndFunction

Procedure ConfigureImageOutput(OutputImage)
	
	AvailableConfigurationLayoutFields = SettingsComposer.Settings.SelectionAvailableFields.Items;
	
	AvailableLayoutFieldsForProductSettings = AvailableConfigurationLayoutFields.Find("Products");
	If AvailableLayoutFieldsForProductSettings <> Undefined Then
		
		SettingsStructure =  SettingsComposer.Settings.Structure;
		For Indus = 0 To SettingsStructure.Count() - 1 Do
			
			ElStructures = SettingsStructure.Get(Indus);
			If TypeOf(ElStructures) = Type("DataCompositionTable") Then
				
				DataCompositionTable = ElStructures;
				For Each Page1 In DataCompositionTable.Rows Do
					
					DataLayoutTableRowStructure = Page1.Structure;
					ProcessDataLayoutTable(OutputImage, DataLayoutTableRowStructure);
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ProcessDataLayoutTable(Val OutputImage, DataLayoutTableRowStructure)
	
	For IndRow = 0 To DataLayoutTableRowStructure.Count() - 1 Do
		
		RowTab = DataLayoutTableRowStructure.Get(IndRow);
		If TypeOf(RowTab) = Type("DataCompositionTableGroup") Then
			
			StructureSelectionElements = DataLayoutTableRowStructure.Get(IndRow).Selection.Items;
			For IndEl = 0 To StructureSelectionElements.Count() - 1 Do
				
				It_ = StructureSelectionElements.Get(IndEl);
				If TypeOf(It_) = Type("DataCompositionSelectedField")
					And It_.Field = New DataCompositionField("Products.PicturesFile") Then
					
					It_.Use = OutputImage;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		DataLayoutTableRowStructure = RowTab.Structure;
		ProcessDataLayoutTable(OutputImage, DataLayoutTableRowStructure);
		
	EndDo;
	
EndProcedure

#EndRegion

#EndIf