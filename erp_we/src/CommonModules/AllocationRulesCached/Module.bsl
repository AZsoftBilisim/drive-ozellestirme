
#Region Public

// Calls the distribution database manager module function, which returns the name of the data layout scheme
// for the passed distribution database.
// Parameters:
//	AllocationBase - EnumRef.TypesOfCostAllocatingBase, 
//						Enum of the link.Directiondistribution to divisions - distribution base.
// Returns:
// 	String - the name of the corresponding. schemes of the rules of the distribution of the server call.Name of the Distribution Database()
Function NameOfDistributionBaseSchema(AllocationBase) Export
	
	Return AllocationRulesServerCall.NameOfDistributionBaseSchema(AllocationBase);
	
EndFunction

// Returns the layout diagram of the distribution database.
// Parameters:
//	SchemaName - String - name of the distribution database data layout scheme.
//	AllocationBase - EnumRef.TypesOfCostAllocatingBase, 
//						Enum of the link.Directiondistribution to divisions - distribution base.
// Returns:
//	DataCompositionSchema - layout diagram of the distribution base.
Function DistributionBaseDiagram(SchemaName, AllocationBase) Export
	
	ObjectManager = Common.ObjectManagerByRef(AllocationBase);
	Return ObjectManager.GetTemplate(SchemaName);
	
EndFunction

// Returns the layout of the data layout based on the passed data layout settings.
// Parameters:
//	SchemaName - String - name of the distribution database data layout scheme.
//	AllocationBase - EnumRef.TypesOfCostAllocatingBase, 
//						Enum of the link.Directiondistribution to divisions - distribution base.
//	XMLDataLayoutSettings - String - data layout settings in XML format.
//
// Returns:
//	DataCompositionTemplate - layout layout of data by layout settings.
Function DataCompositionTemplate(SchemaName, AllocationBase, XMLDataLayoutSettings) Export
	
	XMLReader = New XMLReader();
	XMLReader.SetString(XMLDataLayoutSettings);
	DataCompositionSettings = XDTOSerializer.ReadXML(XMLReader);
	
	DataCompositionSchema = AllocationRulesCached.DistributionBaseDiagram(SchemaName, AllocationBase);
	TemplateComposer = New DataCompositionTemplateComposer;
	Return TemplateComposer.Execute(DataCompositionSchema, DataCompositionSettings);
		
EndFunction

#EndRegion
