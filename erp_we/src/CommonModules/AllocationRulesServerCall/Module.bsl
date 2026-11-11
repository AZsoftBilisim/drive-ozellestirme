
#Region Public

// Additional parameters for opening the selection settings form.
// Parameters:
//	Parameters - See AllocationRulesClient.ParametersForOpeningSelectionSettingsForm
// Returns:
//	Structure - advanced setting.
Function AdditionalSelectionSettings(Parameters) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DoNotConfigureSettings", True);
	
	ObjectManager = Common.ObjectManagerByRef(Parameters.AllocationBase);
	SchemaName = NameOfDistributionBaseSchema(Parameters.AllocationBase);
	If SchemaName = "MaterialCosts"
		Or SchemaName = "MaterialAndLaborCosts" Then
		AdditionalParameters.DoNotConfigureSettings = False;
	EndIf;
	
	Schema = ObjectManager.GetTemplate(SchemaName);
	If Not GetFunctionalOption("AnalyticalAccountingByProductsGroups") Then
		
		ProductGroupField = Schema.DataSets[0].Fields.Find("ProductsGroup"); // DataCompositionSchemaDataSetField
		If Not ProductGroupField = Undefined Then
			
			ProductGroupField.UseRestriction.Condition = True;
			ProductGroupField.AttributeUseRestriction.Condition = True;
			
		EndIf;
		
	EndIf;
	For Each FieldName In Parameters.UnavailableSelectionFields Do
		
		UnavailableField = Schema.DataSets[0].Fields.Find(FieldName); // DataCompositionSchemaDataSetField
		If Not UnavailableField = Undefined Then
			
			UnavailableField.UseRestriction.Condition = True;
			UnavailableField.AttributeUseRestriction.Condition = True;
			
		EndIf;
		
	EndDo;
	
	AdditionalParameters.Insert("AddressOfDataCompositionSchema",
		PutToTempStorage(Schema, Parameters.UUID));
	
	AdditionalParameters.Insert("AddressOfDataCompositionSettings");
	Settings = Parameters.SettingsComposer.GetSettings();
	If ValueIsFilled(Settings) Then
		AdditionalParameters.AddressOfDataCompositionSettings = PutToTempStorage(Settings,
			Parameters.UUID);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

// Calls the distribution database manager module function, which returns the name of the data layout scheme
// for the passed distribution database.
// Parameters:
//	AllocationBase - EnumRef.TypesOfCostAllocatingBase, 
//						Enum of the link.Directiondistribution to divisions - distribution base.
//	ObjectManager - EnumManager, Undefined - manager of the distribution database object.
// Returns:
//	String - the name of the distribution database schema.
Function NameOfDistributionBaseSchema(AllocationBase, ObjectManager = Undefined) Export
	
	If ObjectManager = Undefined Then
		ObjectManager = Common.ObjectManagerByRef(AllocationBase);
	EndIf;
	
	Return ObjectManager.NameOfDistributionBaseSchema(AllocationBase);
	
EndFunction

// Returns the layout diagram of the distribution database.
// Parameters:
//	AllocationBase - EnumRef.TypesOfCostAllocatingBase, 
//						Enum of the link.Directiondistribution to divisions - distribution base.
//	ObjectManager - EnumManager, Undefined - manager of the distribution database object.
// Returns:
//	DataCompositionSchema - layout diagram of the distribution base.
Function DistributionBaseDiagram(AllocationBase, ObjectManager = Undefined) Export
	
	If ObjectManager = Undefined Then
		ObjectManager = Common.ObjectManagerByRef(AllocationBase);
	EndIf;
	
	Return ObjectManager.GetTemplate(NameOfDistributionBaseSchema(AllocationBase, ObjectManager));
	
EndFunction

#Region WorkingWithSettingsComposer

// Checks whether there is a set selection in the settings linker.
// Parameters:
//	NewSettings1 - DataCompositionSettingsComposer - 
// Returns:
//	Boolean - 
Function FilterIs_Specified(NewSettings1) Export
	
	FilterIs_Specified = False;
	ComposerSettings = NewSettings1.GetSettings();
	For Each FilterElement In ComposerSettings.Filter.Items Do
		If FilterElement.Use Then
			
			FilterIs_Specified = True;
			Break;
			
		EndIf;
	EndDo;
	
	Return FilterIs_Specified;
	
EndFunction

#EndRegion

#EndRegion