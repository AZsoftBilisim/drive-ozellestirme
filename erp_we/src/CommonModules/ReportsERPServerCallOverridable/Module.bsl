
////////////////////////////////////////////////////////////////////////////////
// Report Options - UP report form (server call, redefined)
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called from the reportsupclient module, which is Defined for the report "loadspecies of work Centers".
// 
// Returns:
//	Boolean - flag for using the production management subsystem version 2.2
//
Function ProductionIsUsed22() Export
	
	Return ProductionServer.ProductionIsUsed22();
	
EndFunction

// Generates parameters for decoding analogs 
//
// Parameters:
//  ActionParameters    - See ReportsERPClientOverridable.PerformDecryptionAction.ActionParameters
//  DetailsParameters - See ReportsERPClientOverridable.PerformDecryptionAction.DetailsParameters
//
// Returns:
//  See AlternativeMaterials.AnalogSelectionParameters
//
Function DecryptionParametersDecryptionOfItemOfNomenclaturePlanForAnalogues(
			ActionParameters, DetailsParameters) Export
	
	SourceType = New TypeDescription("CatalogRef.ProductionStages");
	
	AnalogSelectionParameters = AlternativeMaterials.AnalogSelectionParameters(SourceType);
	
	// GeneralParameters
	AnalogSelectionParameters.GeneralParameters.ShowBalance  = True;
	AnalogSelectionParameters.GeneralParameters.DetailsMode = True;
	
	// GoodsParameters
	FieldsStructure = AlternativeMaterials.StructureOfTableFieldsToReplaceWithAnalogues();
	FieldsStructure.AdditionalFields.Insert("Ref", SourceType);
	
	Goods = New ValueTable;
	Goods.Columns.Add("Ref",         SourceType);
	Goods.Columns.Add("LineNumber",    Common.TypeDescriptionNumber(10));
	Goods.Columns.Add("Products",   New TypeDescription("CatalogRef.Products"));
	Goods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Goods.Columns.Add("Purpose",     New TypeDescription("CatalogRef.Assignments"));
	Goods.Columns.Add("WithAssignment",    New TypeDescription("Boolean"));
	Goods.Columns.Add("Warehouse",          New TypeDescription("CatalogRef.Warehouses"));
	Goods.Columns.Add("Count",     Common.TypeDescriptionNumber(15, 3));
	
	LineProducts_ = Goods.Add();
	FillPropertyValues(LineProducts_, DetailsParameters);
	DetailsParameters.Property("Stage",    LineProducts_.Ref);
	DetailsParameters.Property("Substitutes", LineProducts_.Count);
	
	ObjectName = "Object";
	TableName = "Goods";
	FormData1 = New Structure;
	FormData1.Insert("UUID", New UUID);
	FormData1.Insert(ObjectName, New Structure);
	FormData1[ObjectName].Insert(TableName, Goods);
	
	ProductData_9 = AlternativeMaterials.GetProductData(
		FormData1, ObjectName, TableName, 1, False, FieldsStructure);
		
	FillPropertyValues(AnalogSelectionParameters.GoodsParameters, ProductData_9);
	
	// SubstitutesParameters
	ParametersTable = AnalogSelectionParameters.SubstitutesParameters.ParametersTable;
	
	TableRow = ParametersTable.Add();
	FillPropertyValues(TableRow, ActionParameters.ParameterData);
	TableRow.PermissionValidityDate = BegOfDay(CurrentSessionDate());
	TableRow.Ref                 = LineProducts_.Ref;
	DetailsParameters.Property("StageSubdivision", TableRow.Department);
	
	AnalogSelectionParameters.SubstitutesParameters.ParametersTable = 
		PutToTempStorage(ParametersTable, FormData1.UUID);
	
	Return AnalogSelectionParameters;
	
EndFunction

#EndRegion
