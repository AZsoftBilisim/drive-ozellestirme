
#Region Public

#Region FormingAndCleaningProcedures

// Prepares the data structure of the SKD and settings based on the template and segment data.
//
// Parameters:
//  LinkSegment            - CatalogRef.ProductSegments, CatalogRef.PartnersSegments - segment whose
//      SKD and settings are obtained.
//  DCSTemplateName            - String - name of the SKD template
//  DCSAddress                 - String - address of the storage where the SKD is located.
//  DCSSettingsAddress         - String - address of the storage where the SKD settings are located.
//  UUID - UUID - ID of the form that the procedure is being called from.
//
// Returns:
//   Structure   -  it consists of the following fields
//       SCD Template Name - String - name of the SCD template
//       The presentation of the SCD template is a string - a custom representation of the SCD template.
//       ADDRESSSKD - String - the address of the storage in which the SKD is located.
//       Addressconstructionskd - String - the address of the storage in which the settings of the SKD are located.
//
Function ApplyChangesToDataLayoutScheme(LinkSegment, DCSTemplateName, DCSAddress, DCSSettingsAddress, UUID) Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("DCSTemplateName", DCSTemplateName);
	ReturnValue.Insert("PresentationOfTheSKDTemplate",NStr("vi = 'Tùy ý';
															|ru = 'Произвольный';
															|en = 'Arbitrary'; fa = 'دلخواه';
															|it = 'Libero';
															|pl = 'Arbitrary';
															|tr = 'İsteğe bağlı'"));
	ReturnValue.Insert("DCSAddress", "");
	ReturnValue.Insert("DCSSettingsAddress","");
	
	If ValueIsFilled(DCSTemplateName) Then
		
		SchemeAndSettings = SegmentsServer.GetDescriptionAndLayoutDiagramOfDataByTemplateName(LinkSegment, DCSTemplateName);
		// If the data layout scheme from the layout <> is obtained from the data layout scheme editor.
		If SegmentsServer.GetXML(SchemeAndSettings.DataCompositionSchema) <> SegmentsServer.GetXML(GetFromTempStorage(DCSAddress)) Then
			
			ReturnValue.DCSTemplateName  = "";
			ReturnValue.DCSAddress = DCSAddress;
			
		Else
			
			ReturnValue.PresentationOfTheSKDTemplate = SchemeAndSettings.LongDesc;
			
		EndIf;
		
		// The resulting settings can be equal to the default settings of the scheme.
		SettingsComposer = New DataCompositionSettingsComposer;
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemeAndSettings.DataCompositionSchema));
		SettingsComposer.LoadSettings(SchemeAndSettings.DataCompositionSchema.DefaultSettings);
		SettingsComposer.Refresh();
		If SegmentsServer.GetXML(SettingsComposer.GetSettings()) <> SegmentsServer.GetXML(GetFromTempStorage(DCSSettingsAddress)) Then
			ReturnValue.DCSSettingsAddress = DCSSettingsAddress;
		EndIf;
		
	Else
		
		ReturnValue.DCSAddress = DCSAddress;
		
		Schema = GetFromTempStorage(DCSAddress);
		StorageOfDataCompositionSchema = New ValueStorage(Schema);
		
		SettingsComposer = New DataCompositionSettingsComposer;
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(Schema));
		SettingsComposer.LoadSettings(Schema.DefaultSettings);
		SettingsComposer.Refresh();
		
		If SegmentsServer.GetXML(SettingsComposer.GetSettings()) <> SegmentsServer.GetXML(GetFromTempStorage(DCSSettingsAddress)) Then
			ReturnValue.DCSSettingsAddress = DCSSettingsAddress;
		EndIf;
	
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Gets the addresses of the SKD and settings according to the transmitted data.
//
// Parameters:
//  LinkSegment            - CatalogRef.ProductSegments, CatalogRef.PartnersSegments - segment whose
//      SKD and settings are obtained.
//  DCSTemplateName            - String - name of the SKD template
//  DCSAddress                 - String - address of the storage where the SKD is located.
//  DCSSettingsAddress         - String - address of the storage where the SKD settings are located.
//  UUID   - UUID - ID of the form that the procedure is being called from.
//
// Returns:
//   Structure   -  it consists of the following fields
//       Schematics of the data is a string - the address of the SKD template.
//       The configuration of the data components is a string - the address of the SKD settings.
//
Function GetAddressesOfDataLayoutSchemeInTemporaryStorage(LinkSegment,
	                                                            DCSTemplateName,
	                                                            DCSAddress,
	                                                            DCSSettingsAddress,
	                                                            UUID) Export
	
	Addresses = New Structure("DataCompositionSchema, DataCompositionSettings");
	
	// Schema
	If ValueIsFilled(DCSTemplateName) And IsBlankString(DCSAddress) Then
		SchemeAndSettings = SegmentsServer.GetDescriptionAndLayoutDiagramOfDataByTemplateName(LinkSegment, DCSTemplateName);
		DataCompositionSchema = SchemeAndSettings.DataCompositionSchema;
		Addresses.DataCompositionSchema = PutToTempStorage(DataCompositionSchema,UUID)
	Else
		Addresses.DataCompositionSchema = DCSAddress;
	EndIf;

	// Settings
	If Not IsBlankString(DCSSettingsAddress) Then
		Addresses.DataCompositionSettings = DCSSettingsAddress;
	EndIf;
	
	Return Addresses;
	
EndFunction

// Fills the data register with objects that are included in the segment.
//
// Parameters:
//   LinkSegment - CatalogRef.PartnersSegments, CatalogRef.ProductSegments - the segment
//       that contains the elements that are received.
//
Procedure Generate(LinkSegment) Export

	PD = PrivilegedMode();
	If Not PD Then
		SetPrivilegedMode(True);
	EndIf;

	ItemsList = SegmentsServer.ListOfDCSElements(LinkSegment);
	IncludeFeatures =
		ItemsList.Columns.Find("ElementCharacteristics") <> Undefined;

	If TypeOf(LinkSegment) = Type("CatalogRef.ProductSegments") Then
		RecordSet = InformationRegisters.SegmentProducts.CreateRecordSet();
		RecordSet.Filter.Segment.Set(LinkSegment);
		For Each Item In ItemsList Do
			If Not ValueIsFilled(Item.ListItem) Then
				Continue;
			EndIf;
			Record = RecordSet.Add();
			Record.Segment = LinkSegment;
			Record.Products = Item.ListItem;
			If IncludeFeatures Then
				Record.Characteristic = Item.ElementCharacteristics;
			EndIf;
		EndDo;
	Else
		RecordSet = InformationRegisters.SegmentPartners.CreateRecordSet();
		RecordSet.Filter.Segment.Set(LinkSegment);
		For Each Item In ItemsList Do
			If Not ValueIsFilled(Item.ListItem) Then
				Continue;
			EndIf;
			Record = RecordSet.Add();
			Record.Segment = LinkSegment;
			Record.Partner = Item.ListItem;
		EndDo;
	EndIf;

	RecordSet.Write();

	If Not PD Then
		SetPrivilegedMode(False);
	EndIf;

EndProcedure

// Deletes records related to the segment from the information register
//
// Parameters:
//   LinkSegment - CatalogRef.PartnersSegments, CatalogRef.ProductSegments - the segment
//       that contains the elements that are received.
//
Procedure Clear(LinkSegment) Export

	SegmentSet = ?(
		TypeOf(LinkSegment) = Type("CatalogRef.ProductSegments"),
		InformationRegisters.SegmentProducts.CreateRecordSet(),
		InformationRegisters.SegmentPartners.CreateRecordSet());
	SegmentSet.Filter.Segment.Set(LinkSegment);
	SegmentSet.Write();

EndProcedure

#EndRegion

#Region ElementSetProcessingFunctions

// Returns a list of values containing the elements included in the segment,
// taking into account the way the segment is formed.
//
// Parameters:
//   LinkSegment - CatalogRef.PartnersSegments, CatalogRef.ProductSegments - the segment
//       that contains the elements that are received.
//
// Returns:
//   ValueList - the list of elements included in the segment.
//
Function ValueList(LinkSegment) Export

	List = New ValueList;
	List.LoadValues(SegmentsServer.ValueTable(LinkSegment).UnloadColumn(0));
	
	Return List;

EndFunction

#EndRegion

#EndRegion
