#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	ResultDocument.Clear();
	LinkSegment = SettingsComposer.FixedSettings.AdditionalProperties.Segment; // CatalogRef.PartnersSegments, CatalogRef.ProductSegments
	MethodOfSegmentFormation = Common.ObjectAttributeValue(LinkSegment, "GenerationMethod");
	ParametersForDynamicFormation = Undefined;
	
	SegmentDCSDetails = Common.ObjectAttributesValues(
		LinkSegment,
		"DataCompositionSchema,StorageOfDataCompositionSettings,DCSTemplateName");
		
	SegmentSettings = SegmentDCSDetails.StorageOfDataCompositionSettings.Get();
		
	If IsBlankString(SegmentDCSDetails.DCSTemplateName) Then
		
		DCS = SegmentDCSDetails.DataCompositionSchema.Get();
		
	Else
		
		SKD_OfTemplate = SegmentsServer.GetDescriptionAndLayoutDiagramOfDataByTemplateName(LinkSegment, SegmentDCSDetails.DCSTemplateName);
		DCS = SKD_OfTemplate.DataCompositionSchema;
		
	EndIf;
	
	If SegmentSettings = Undefined Then
		SegmentSettings = DCS.DefaultSettings; // DataCompositionSettings 
	EndIf;
	
	If MethodOfSegmentFormation <>
		Enums.SegmentGenerationMethods.GenerateDynamically Then
		
		If DCS.DataSets.Find("SegmentList") <> Undefined Then
			
			ListSet = DCS.DataSets.Find("SegmentList");
			
			// replace the list request with a case reference
			If TypeOf(LinkSegment) = Type("CatalogRef.ProductSegments") Then
				ListSet.Query = 
				"SELECT
				|	SegmentProducts.Products AS ListItem,
				|	SegmentProducts.Characteristic AS ElementCharacteristics,
				|	SegmentProducts.Segment
				|FROM
				|	InformationRegister.SegmentProducts AS SegmentProducts";
			Else
				ListSet.Query =
				"SELECT
				|	SegmentPartners.Partner AS ListItem,
				|	SegmentPartners.Segment
				|FROM
				|	InformationRegister.SegmentPartners AS SegmentPartners";
			EndIf; //replace the list request with a case reference
			
			// delete the selection corresponding to the old query
			FilterItems1 = SegmentSettings.Filter.Items;
			FilterItems1.Clear();
			
			// add selection by segment
			DataCompositionClientServer.AddFilter(
			SegmentSettings, New DataCompositionField("Segment"), LinkSegment);
			
			// enable autofill of fields
			DCS.DataSets.SegmentList.AutoFillAvailableFields = True;
			
		EndIf;
		
	Else
		
		If DCS.DataSets.Find("DisplaySegment") <> Undefined And DCS.DataSets.Find("SegmentGeneration") <> Undefined Then
			
			TemplateComposer = New DataCompositionTemplateComposer;
			CompositionTemplate = TemplateComposer.Execute(
			DCS,
			SegmentSettings);
			
			ParametersForDynamicFormation = CompositionTemplate.ParameterValues;
			
			SubqueriesSegmentOutput = StringFunctionsClientServer.SplitStringIntoSubstringsArray(DCS.DataSets.DisplaySegment.Query,";");
			If SubqueriesSegmentOutput.Count() < 2 Then
				Return ;
			EndIf;
			
			QueryTextSegmentGeneration = CompositionTemplate.DataSets.SegmentGeneration.Query;
			SubqueriesSegmentFormation = StringFunctionsClientServer.SplitStringIntoSubstringsArray(QueryTextSegmentGeneration,";");
			If SubqueriesSegmentFormation.Count() > 1 Then
				
				RequestForChanges = SubqueriesSegmentFormation[SubqueriesSegmentFormation.Count() - 1];
				FoundItemFROM = StrFind(RequestForChanges,"FROM");
				If FoundItemFROM <> 0 Then
					RequestForChanges = Left(RequestForChanges,FoundItemFROM - 1) + "  INTO SegmentContent
					|  " + Right(RequestForChanges,StrLen(RequestForChanges) - FoundItemFROM + 1);
				EndIf;
				
				QueryTextSegmentGeneration = "";
				For Indus = 0 To SubqueriesSegmentFormation.Count() - 2 Do
				
					QueryTextSegmentGeneration = QueryTextSegmentGeneration 
					                                   + SubqueriesSegmentFormation[Indus] 
					                                   + Chars.LF + ";";
				
				EndDo;
				QueryTextSegmentGeneration = QueryTextSegmentGeneration + RequestForChanges;
				
			Else
				
				FoundItemFROM = StrFind(QueryTextSegmentGeneration,"FROM");
				TextEmptyCharacteristic = "";
				If Not GetFunctionalOption("UseItemVariants") Then
					TextEmptyCharacteristic = ", VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic
					|";
				EndIf;
					
				If FoundItemFROM <> 0 Then
					QueryTextSegmentGeneration = Left(QueryTextSegmentGeneration,FoundItemFROM - 1) + TextEmptyCharacteristic + "  INTO SegmentContent
					|  " + Right(QueryTextSegmentGeneration,StrLen(QueryTextSegmentGeneration) - FoundItemFROM + 1);
					
				EndIf;
				
			EndIf;
			
			DCS.DataSets.DisplaySegment.Query = QueryTextSegmentGeneration + Chars.LF + ";" + Chars.LF;
			For Indus = 1 To SubqueriesSegmentOutput.Count() - 1 Do
				
				DCS.DataSets.DisplaySegment.Query = DCS.DataSets.DisplaySegment.Query + SubqueriesSegmentOutput[Indus] 
				                                        + ?(Indus = SubqueriesSegmentOutput.Count() - 1,"",Chars.LF + ";");
				
			EndDo;
			
			DCS.DataSets.DisplaySegment.AutoFillAvailableFields = True;
			
		EndIf;
		
	EndIf;
	
	If DCS.DataSets.Find("DisplaySegment") <> Undefined Then 
		
		SettingsSource_ = SegmentSettings;
		ReceiverSettings = DCS.SettingVariants.DisplaySegment.Settings;
		
		DataCompositionClientServer.CopyElements(ReceiverSettings.DataParameters, SettingsSource_.DataParameters);
		DataCompositionClientServer.CopyElements(ReceiverSettings.Filter, SettingsSource_.Filter);
		
		SetSegmentFormation = DCS.DataSets.Find("SegmentGeneration");
		If SetSegmentFormation <> Undefined Then
			DCS.DataSets.Delete(SetSegmentFormation);
		EndIf;
		
		Settings = ReceiverSettings;
		
		SettingsComposerAuxiliary = New DataCompositionSettingsComposer;
		SettingsComposerAuxiliary.Initialize(New DataCompositionAvailableSettingsSource(DCS));
		SettingsComposerAuxiliary.LoadSettings(Settings);
		SettingsComposerAuxiliary.Refresh();
		
		Settings = SettingsComposerAuxiliary.Settings;
		
		If MethodOfSegmentFormation <>
			Enums.SegmentGenerationMethods.GenerateDynamically Then
			
			DataCompositionClientServer.AddFilter(
			Settings, New DataCompositionField("Segment"), LinkSegment);
			
		EndIf;
		
	Else
		
		Settings = DCS.DefaultSettings;
		
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(
		DCS,
		Settings,
		DetailsData);
	
	If ParametersForDynamicFormation <> Undefined Then
		CommonClientServer.SupplementTable(ParametersForDynamicFormation, CompositionTemplate.ParameterValues);
	EndIf;
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.BeginOutput();
	OutputProcessor.Output(DataCompositionProcessor, True);
	OutputProcessor.EndOutput();
	
EndProcedure

#EndRegion

#EndIf
