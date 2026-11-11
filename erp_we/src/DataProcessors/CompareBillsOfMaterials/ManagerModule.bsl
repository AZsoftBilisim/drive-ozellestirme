#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Performs a comparison of several resource specifications.
//
// Parameters:
//  BOMList	 - ValueList	 - list of compared specifications.
//  ProductAndMaterialComparisonMode - Number - Product and material comparison mode, possible values:
//                                                                                    0 - in storage units
//                                                                                    1 - in units of specifications
// 
// Returns:
//  Structure - the structure of the comparison result.
//
Function PerformComparisonOfSpecifications(BOMList, ProductAndMaterialComparisonMode) Export
	
	ComparisonData_ = New Structure;
	ComparisonData_.Insert("StageList",    New ValueList);
	ComparisonData_.Insert("ComparisonData_", New Map);
	
	GetSpecificationData(ComparisonData_, BOMList, ProductAndMaterialComparisonMode);
	
	NoteDifferences(ComparisonData_, BOMList.Count());
	
	Return ComparisonData_;
	
EndFunction


// Configures the layout for the specification comparison report.
//
// Parameters:
//  ComparisonResult	 - SpreadsheetDocument - to display the comparison result.
//  ThereAreDifferences			 - Boolean			 - flag for differences.
//
Procedure CompleteReportOutput(ComparisonResult, ThereAreDifferences) Export
	
	If ThereAreDifferences Then
		Return;
	EndIf;
	
	ReportTemplate = DataProcessors.CompareBillsOfMaterials.GetTemplate("Template");
	
	AreaStringNoDifferences = ReportTemplate.GetArea("LineNoDifferences");
	
	ComparisonResult.Put(AreaStringNoDifferences);
	
EndProcedure

// Outputs the comparison result to a table document.
//
// Parameters:
//  ComparisonResult		 - SpreadsheetDocument - to display the comparison result.
//  BOMList		 - ValueList	 - list of compared specifications.
//  ShowOnlyDifferences	 - Boolean			 - if True, only differences are output.
//  ComparisonData_			 - Structure		 - the result of the comparison, where:
//   * ComparisonData_		 - Map of KeyAndValue -
//   * StageList			 - ValueList of String - 
//  ReportHeader			 - String			 - Report header.
//  OrderLine			 - Number			 - Order line, if the comparison contains a production order.
// 
// Returns:
//  Boolean - True if there are differences.
//
Function OutputReport(
		ComparisonResult, 
		BOMList, 
		ShowOnlyDifferences, 
		ComparisonData_, 
		ReportHeader = Undefined, 
		OrderLine = Undefined) Export
	
	ReportTemplate = DataProcessors.CompareBillsOfMaterials.GetTemplate("Template");
	
	// Report header
	If ReportHeader = Undefined Then
		ReportHeader = NStr("vi = 'So sánh bảng kê chi tiết các nguồn lực sản xuất';
							|ru = 'Сравнение спецификаций';
							|en = 'Compare bills of materials'; fa = 'مقایسه فهرست‌های مواد';
							|it = 'Confronto delle specifiche';
							|pl = 'Porównanie specyfikacji';
							|tr = 'Ürün reçetesi karşılaştırması'");
	EndIf;
	HeaderArea_ = ReportTemplate.GetArea("Title");
	HeaderArea_.Parameters.ReportHeader = ReportHeader;
	ComparisonResult.Put(HeaderArea_);
	
	If OrderLine <> Undefined Then
		
		If ShowOnlyDifferences Then
			ThereAreDifferences = False;
			For Each Data_Stage In ComparisonData_.StageList Do
				
				StageComparisonData = ComparisonData_.ComparisonData_.Get(Data_Stage.Value);
				
				If StageComparisonData.BOMList.Count() <> BOMList.Count() 
					Or StageComparisonData.PropertiesTable.Find(True, "ThereAreDifferences") <> Undefined 
					Or StageComparisonData.ProductTable_.Find(True, "ThereAreDifferences") <> Undefined 
					Or StageComparisonData.WasteTable.Find(True, "ThereAreDifferences") <> Undefined 
					Or StageComparisonData.TableOfIncomingProducts_.Find(True, "ThereAreDifferences") <> Undefined 
					Or StageComparisonData.TableOfMaterials.Find(True, "ThereAreDifferences") <> Undefined
					Or StageComparisonData.TableOfLaborCosts.Find(True, "ThereAreDifferences") <> Undefined
					Or StageComparisonData.TableTypesOfRC.Find(True, "ThereAreDifferences") <> Undefined 
					Then
					
					ThereAreDifferences = True;
					Break;
				EndIf;
			EndDo;
			If Not ThereAreDifferences Then
				Return False;
			EndIf; 
		EndIf;
		
		AreaOrderLine = ReportTemplate.GetArea("OrderLine");
		AreaOrderLine.Parameters.OrderLine = OrderLine;
		ComparisonResult.Put(AreaOrderLine);
		ComparisonResult.StartRowGroup("OrderLine");
	EndIf;
	
	// The "Header" area
	AreaHeaderName = ReportTemplate.GetArea("Header|PropertyNames");
	SourceHeaderArea = ReportTemplate.GetArea("Header|SourceProperties_");
	
	// The "Stage" area
	AreaStageName = ReportTemplate.GetArea("Stage|PropertyNames");
	AreaStageSource = ReportTemplate.GetArea("Stage|SourceProperties_");
	
	// The "Group of Properties" area
	AreaPropertyGroupName = ReportTemplate.GetArea("PropertyGroup|PropertyNames");
	AreaPropertyGroupSource = ReportTemplate.GetArea("PropertyGroup|SourceProperties_");
	
	// The "Properties of the building" area
	PropertyAreaStringName = ReportTemplate.GetArea("StringProperties|PropertyNames");
	PropertyAreaStringSource = ReportTemplate.GetArea("StringProperties|SourceProperties_");
	
	//////////////////////////////////////
	// REPORT OUTPUT
	
	// We output the details of the specifications
	DataComparisonStructure = ComparisonData_.ComparisonData_.Get(KeyDetailsOfSpecifications());
	If DataComparisonStructure <> Undefined
		And ValueIsFilled(DataComparisonStructure.AttributesTable) Then
		
		If (ShowOnlyDifferences And DataComparisonStructure.AttributesTable.Find(True, "ThereAreDifferences") <> Undefined
			Or Not ShowOnlyDifferences) Then
			
			AreaHeaderName.Parameters.Title = NStr("vi = 'Mục tin';
													|ru = 'Реквизиты';
													|en = 'Attributes'; fa = 'ویژگی‌ها';
													|it = 'Requisiti';
													|pl = 'Attributes';
													|tr = 'Öznitelikler'");
			ComparisonResult.Put(AreaHeaderName);
			For Each AlCollections In BOMList Do
				SourceHeaderArea.Parameters.SourceName         = AlCollections.Presentation;
				SourceHeaderArea.Parameters.DecryptionOfSource = AlCollections.Value;
				ComparisonResult.Join(SourceHeaderArea);
			EndDo;
			
			ListProperties_(DataComparisonStructure.AttributesTable, 
									PropertyAreaStringName,
									PropertyAreaStringSource,
									ComparisonResult,
									BOMList,
									ShowOnlyDifferences);
			
		EndIf;
		
	EndIf;
	
	// Output the destination parameters
	DataComparisonStructure = ComparisonData_.ComparisonData_.Get(KeyDetailsOfSpecifications());
	If DataComparisonStructure <> Undefined
		And ValueIsFilled(DataComparisonStructure.DestinationParameterTable) Then
		
		If (ShowOnlyDifferences And DataComparisonStructure.DestinationParameterTable.Find(True, "ThereAreDifferences") <> Undefined
			Or Not ShowOnlyDifferences) Then
			
			AreaHeaderName.Parameters.Title = NStr("vi = 'Tham số mục đích';
													|ru = 'Параметры назначения';
													|en = 'Assignment parameters'; fa = 'پارامترهای تخصیص';
													|it = 'Parametri di assegnazione';
													|pl = 'Parametry przeznaczenia';
													|tr = 'Atama parametreleri'");
			ComparisonResult.Put(AreaHeaderName);
			For Each AlCollections In BOMList Do
				SourceHeaderArea.Parameters.SourceName         = AlCollections.Presentation;
				SourceHeaderArea.Parameters.DecryptionOfSource = AlCollections.Value;
				ComparisonResult.Join(SourceHeaderArea);
			EndDo;
			
			ListProperties_(DataComparisonStructure.DestinationParameterTable,
									PropertyAreaStringName,
									PropertyAreaStringSource,
									ComparisonResult,
									BOMList,
									ShowOnlyDifferences);
			
		EndIf;
		
	EndIf;
	
	ThereAreDifferences = False;
	StageHeaderIsDisplayed = False;
	
	// We output the data of the stages
	For Each Data_Stage In ComparisonData_.StageList Do
		
		StageComparisonData = ComparisonData_.ComparisonData_.Get(Data_Stage.Value);
		
		// The stage does not need to be output if:
		// - you only need to show the differences
		// - all specifications have a stage
		// - there is no difference in properties.
		If ShowOnlyDifferences 
			And StageComparisonData.BOMList.Count() = BOMList.Count()
			And StageComparisonData.PropertiesTable.Find(True, "ThereAreDifferences") = Undefined
			And StageComparisonData.ProductTable_.Find(True, "ThereAreDifferences") = Undefined
			And StageComparisonData.WasteTable.Find(True, "ThereAreDifferences") = Undefined
			And StageComparisonData.TableOfIncomingProducts_.Find(True, "ThereAreDifferences") = Undefined
			And StageComparisonData.TableOfMaterials.Find(True, "ThereAreDifferences") = Undefined
			And StageComparisonData.TableOfLaborCosts.Find(True, "ThereAreDifferences") = Undefined
			And StageComparisonData.TableTypesOfRC.Find(True, "ThereAreDifferences") = Undefined
			And StageComparisonData.TransactionTable.Find(True, "ThereAreDifferences") = Undefined
			Then
			
			Continue;
			
		EndIf;
		
		If Not StageHeaderIsDisplayed Then
			// Output the header of the "Stages" section of the report
			AreaHeaderName.Parameters.Title = NStr("vi = 'Công đoạn';
													|ru = 'Этапы';
													|en = 'Stages'; fa = 'مراحل';
													|it = 'Fasi';
													|pl = 'Stages';
													|tr = 'Aşamalar'");
			ComparisonResult.Put(AreaHeaderName);
			For Each AlCollections In BOMList Do
				SourceHeaderArea.Parameters.SourceName         = AlCollections.Presentation;
				SourceHeaderArea.Parameters.DecryptionOfSource = AlCollections.Value;
				ComparisonResult.Join(SourceHeaderArea);
			EndDo;
			
			StageHeaderIsDisplayed = True;
		EndIf; 
		
		ThereAreDifferences = True;
		
		// Stage
		AreaStageName.Parameters.Stage = Data_Stage.Presentation;
		ComparisonResult.Put(AreaStageName, 2, "Stage");
		For Each AlCollections In BOMList Do
			SourceArea_1 = ComparisonResult.Join(AreaStageSource);
			
			If StageComparisonData.BOMList.Find(AlCollections.Value) = Undefined Then
				SourceArea_1.TextColor = StyleColors.SpecialTextColor;
				SourceArea_1.Text = NStr("vi = '<Không có>';
										|ru = '<Отсутствует>';
										|en = '<missing>'; fa = '<missing>';
										|it = '<mancante>';
										|pl = '<missing>';
										|tr = '<Yok>'");
			EndIf;
		EndDo;
		SourceArea_1.RightBorder = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
		
		If StageComparisonData.BOMList.Count() < 2 Then
			// We do not output properties if only one specification has this stage
			Continue;
		EndIf; 
		
		ComparisonResult.StartRowGroup("Stage");
		
		OutputGroupOfProperties(NStr("vi = 'Thuộc tính';
									|ru = 'Свойства';
									|en = 'Properties'; fa = 'خاصیت‌ها';
									|it = 'Proprietà';
									|pl = 'Properties';
									|tr = 'Özellikler'"),
							StageComparisonData.PropertiesTable, 
							AreaPropertyGroupName, 
							AreaPropertyGroupSource, 
							PropertyAreaStringName, 
							PropertyAreaStringSource,
							ComparisonResult,
							BOMList,
							ShowOnlyDifferences);
		
		OutputGroupOfProperties(Metadata.Catalogs.BillsOfMaterials.TabularSections.ManufacturedProducts.Synonym,
							StageComparisonData.ProductTable_, 
							AreaPropertyGroupName, 
							AreaPropertyGroupSource, 
							PropertyAreaStringName, 
							PropertyAreaStringSource,
							ComparisonResult,
							BOMList,
							ShowOnlyDifferences);
							
		OutputGroupOfProperties(Metadata.Catalogs.BillsOfMaterials.TabularSections.RecyclableWaste.Synonym,
							StageComparisonData.WasteTable, 
							AreaPropertyGroupName, 
							AreaPropertyGroupSource, 
							PropertyAreaStringName, 
							PropertyAreaStringSource,
							ComparisonResult,
							BOMList,
							ShowOnlyDifferences);
			
		OutputGroupOfProperties(NStr("vi = 'Sản phẩm tháo rời';
									|ru = 'Разбираемые изделия';
									|en = 'Products for recycling'; fa = 'Products for recycling';
									|it = 'Prodotti in fase di smontaggio';
									|pl = 'Rozbierane produkty';
									|tr = 'Sökülen nihai ürünler'"),
							StageComparisonData.TableOfIncomingProducts_, 
							AreaPropertyGroupName, 
							AreaPropertyGroupSource, 
							PropertyAreaStringName, 
							PropertyAreaStringSource,
							ComparisonResult,
							BOMList,
							ShowOnlyDifferences);
		
		OutputGroupOfProperties(Metadata.Catalogs.BillsOfMaterials.TabularSections.MaterialsAndServices.Synonym,
							StageComparisonData.TableOfMaterials, 
							AreaPropertyGroupName, 
							AreaPropertyGroupSource, 
							PropertyAreaStringName, 
							PropertyAreaStringSource,
							ComparisonResult,
							BOMList,
							ShowOnlyDifferences);
		
		OutputGroupOfProperties(Metadata.Catalogs.BillsOfMaterials.TabularSections.LaborCosts.Synonym,
							StageComparisonData.TableOfLaborCosts,
							AreaPropertyGroupName,
							AreaPropertyGroupSource,
							PropertyAreaStringName,
							PropertyAreaStringSource,
							ComparisonResult,
							BOMList,
							ShowOnlyDifferences);
		OutputGroupOfProperties(NStr("vi = 'Dạng nguồn lực sản xuất';
									|ru = 'Виды рабочих центров';
									|en = 'Work center types'; fa = 'انواع مرکز کاری';
									|it = 'Tipi di centri operativi';
									|pl = 'Rodzaj centrów wykonania pracy';
									|tr = 'İş merkezi türleri'"),
							StageComparisonData.TableTypesOfRC,
							AreaPropertyGroupName,
							AreaPropertyGroupSource,
							PropertyAreaStringName,
							PropertyAreaStringSource,
							ComparisonResult,
							BOMList,
							ShowOnlyDifferences);
							
		OutputGroupOfProperties(NStr("vi = 'Giao dịch';
									|ru = 'Операции';
									|en = 'Operations'; fa = 'عملیات';
									|it = 'Operazioni';
									|pl = 'Operations';
									|tr = 'İşlemler'"),
							StageComparisonData.TransactionTable,
							AreaPropertyGroupName,
							AreaPropertyGroupSource,
							PropertyAreaStringName,
							PropertyAreaStringSource,
							ComparisonResult,
							BOMList,
							ShowOnlyDifferences);
		ComparisonResult.EndRowGroup();
	EndDo; 
	
	If OrderLine <> Undefined Then
		ComparisonResult.EndRowGroup();
	EndIf;
	
	Return ThereAreDifferences;
	
EndFunction

#EndRegion

#Region Private

Procedure NoteDifferences(ComparisonData_, NumberOfSources)
	
	For Each ElStageComparisonData In ComparisonData_.ComparisonData_ Do
		
		StageComparisonData = ElStageComparisonData.Value;
		
		For Each DataProperty In StageComparisonData.AttributesTable Do
			For Each elValue1 In DataProperty.Values Do
				For Each elValue2 In DataProperty.Values Do
					If elValue1.Value <> elValue2.Value Then
						DataProperty.ThereAreDifferences = True;
						Break;
					EndIf;
				EndDo;
				If DataProperty.ThereAreDifferences Then
					Break;
				EndIf;
			EndDo;
		EndDo;
		
		For Each DataProperty In StageComparisonData.PropertiesTable Do
			For Each elValue1 In DataProperty.Values Do
				For Each elValue2 In DataProperty.Values Do
					If elValue1.Value <> elValue2.Value Then
						DataProperty.ThereAreDifferences = True;
						Break;
					EndIf;
				EndDo;
				If DataProperty.ThereAreDifferences Then
					Break;
				EndIf;
			EndDo;
		EndDo;
		
		For Each DataProperty In StageComparisonData.TableOfMaterials Do
			If DataProperty.Values.Count() <> NumberOfSources Then
				DataProperty.ThereAreDifferences = True;
				Continue;
			EndIf;
			
			For Each elValue1 In DataProperty.Values Do
				For Each elValue2 In DataProperty.Values Do
					If elValue1.Value <> elValue2.Value Then
						DataProperty.ThereAreDifferences = True;
						Break;
					EndIf;
				EndDo;
				If DataProperty.ThereAreDifferences Then
					Break;
				EndIf;
			EndDo;
		EndDo;
		
		For Each DataProperty In StageComparisonData.TableOfIncomingProducts_ Do
			If DataProperty.Values.Count() <> NumberOfSources Then
				DataProperty.ThereAreDifferences = True;
				Continue;
			EndIf;
			
			For Each elValue1 In DataProperty.Values Do
				For Each elValue2 In DataProperty.Values Do
					If elValue1.Value <> elValue2.Value Then
						DataProperty.ThereAreDifferences = True;
						Break;
					EndIf;
				EndDo;
				If DataProperty.ThereAreDifferences Then
					Break;
				EndIf;
			EndDo;
		EndDo;
		
		For Each DataProperty In StageComparisonData.ProductTable_ Do
			If DataProperty.Values.Count() <> NumberOfSources Then
				DataProperty.ThereAreDifferences = True;
				Continue;
			EndIf;
			
			For Each elValue1 In DataProperty.Values Do
				For Each elValue2 In DataProperty.Values Do
					If elValue1.Value <> elValue2.Value Then
						DataProperty.ThereAreDifferences = True;
						Break;
					EndIf;
				EndDo;
				If DataProperty.ThereAreDifferences Then
					Break;
				EndIf;
			EndDo;
		EndDo;
		
		For Each DataProperty In StageComparisonData.WasteTable Do
			If DataProperty.Values.Count() <> NumberOfSources Then
				DataProperty.ThereAreDifferences = True;
				Continue;
			EndIf;
			
			For Each elValue1 In DataProperty.Values Do
				For Each elValue2 In DataProperty.Values Do
					If elValue1.Value <> elValue2.Value Then
						DataProperty.ThereAreDifferences = True;
						Break;
					EndIf;
				EndDo;
				If DataProperty.ThereAreDifferences Then
					Break;
				EndIf;
			EndDo;
		EndDo;
		
		For Each DataProperty In StageComparisonData.TableOfLaborCosts Do
			If DataProperty.Values.Count() <> NumberOfSources Then
				DataProperty.ThereAreDifferences = True;
				Continue;
			EndIf;
			
			For Each elValue1 In DataProperty.Values Do
				For Each elValue2 In DataProperty.Values Do
					If elValue1.Value <> elValue2.Value Then
						DataProperty.ThereAreDifferences = True;
						Break;
					EndIf;
				EndDo;
				If DataProperty.ThereAreDifferences Then
					Break;
				EndIf;
			EndDo;
		EndDo;
		For Each DataProperty In StageComparisonData.TableTypesOfRC Do
			If DataProperty.Values.Count() <> NumberOfSources Then
				DataProperty.ThereAreDifferences = True;
				Continue;
			EndIf;
			
			For Each elValue1 In DataProperty.Values Do
				For Each elValue2 In DataProperty.Values Do
					If elValue1.Value <> elValue2.Value Then
						DataProperty.ThereAreDifferences = True;
						Break;
					EndIf;
				EndDo;
				If DataProperty.ThereAreDifferences Then
					Break;
				EndIf;
			EndDo;
		EndDo;
		
		For Each DataProperty In StageComparisonData.TransactionTable Do
			If DataProperty.Values.Count() <> NumberOfSources Then
				DataProperty.ThereAreDifferences = True;
				Continue;
			EndIf;
			
			For Each elValue1 In DataProperty.Values Do
				For Each elValue2 In DataProperty.Values Do
					If elValue1.Value <> elValue2.Value Then
						DataProperty.ThereAreDifferences = True;
						Break;
					EndIf;
				EndDo;
				If DataProperty.ThereAreDifferences Then
					Break;
				EndIf;
			EndDo;
		EndDo;
		
		For Each DataProperty In StageComparisonData.DestinationParameterTable Do
			For Each elValue1 In DataProperty.Values Do
				For Each elValue2 In DataProperty.Values Do
					ValueStructure1 = elValue1.Value; // See ProductDataManagementClientServer.SpecificationAssignmentParameterValueStructure
					ValueStructure2 = elValue2.Value; // See ProductDataManagementClientServer.SpecificationAssignmentParameterValueStructure
					If Not ValueIsFilled(ValueStructure1) And Not ValueIsFilled(ValueStructure2) Then
						Continue;
					ElsIf ValueIsFilled(elValue1.Value) And ValueIsFilled(elValue2.Value) Then
						If ValueStructure1.Condition <> ValueStructure2.Condition Then
							DataProperty.ThereAreDifferencesInConditions = True;
						EndIf;
						If (ValueStructure1.Condition.List And ValueStructure2.Condition.List)
								And CommonClientServer.ValueListsAreEqual(
										ValueStructure1.Value,
										ValueStructure2.Value) Then
							DataProperty.ThereAreDifferencesInValues = True;
						ElsIf (ValueStructure1.Condition.Interval And ValueStructure2.Condition.Interval)
								And (ValueStructure1.Value1 <> ValueStructure2.Value1
									Or ValueStructure1.Value2 <> ValueStructure2.Value2) Then
							DataProperty.ThereAreDifferencesInValues = True;
						ElsIf ValueStructure1.Value <> ValueStructure2.Value Then
							DataProperty.ThereAreDifferencesInValues = True;
						EndIf;
					Else
						DataProperty.ThereAreDifferencesInConditions  = True;
						DataProperty.ThereAreDifferencesInValues = True;
					EndIf;
				EndDo;
				If DataProperty.ThereAreDifferencesInConditions Or DataProperty.ThereAreDifferencesInValues Then
					DataProperty.ThereAreDifferences = True;
				EndIf;
				If DataProperty.ThereAreDifferencesInConditions And DataProperty.ThereAreDifferencesInValues Then
					Break;
				EndIf;
			EndDo;
			For Each elValue In DataProperty.Values Do
				ValueStructure = elValue.Value; // See ProductDataManagementClientServer.SpecificationAssignmentParameterValueStructure
				If ValueStructure = Undefined Then
					Continue;
				EndIf;
				ValuePresentation = RepresentationOfValueOfDestinationParameter(ValueStructure);
				If DataProperty.ThereAreDifferencesInConditions Then
					PresentationsArray = New Array;
					PresentationsArray.Add(StrTemplate(NStr("vi = 'Điều kiện: %1';
															|ru = 'Условие: %1';
															|en = 'Condition: %1'; fa = 'Condition: %1';
															|it = 'Condizione: %1';
															|pl = 'Warunek: %1';
															|tr = 'Koşul: %1'"), ValueStructure.Condition.Presentation));
					If Not ValueStructure.Condition.Fullness Then
						PresentationsArray.Add(StrTemplate(NStr("vi = 'Giá trị: %1';
																|ru = 'Значение: %1';
																|en = 'Value: %1'; fa = 'Value: %1';
																|it = 'Valore: %1';
																|pl = 'Wartość: %1';
																|tr = 'Değer: %1'"), ValuePresentation));
					EndIf;
					ValuePresentation = StrConcat(PresentationsArray, Chars.LF);
				EndIf;
				DataProperty.Values[elValue.Key] = ValuePresentation;
			EndDo;
		EndDo;
		
	EndDo;
	
EndProcedure

Function DataForComparisonConstructor()
	
	AttributesTable = New ValueTable;
	AttributesTable.Columns.Add("Property",    New TypeDescription("String"));
	AttributesTable.Columns.Add("Values",    New TypeDescription("Structure"));
	AttributesTable.Columns.Add("ThereAreDifferences", New TypeDescription("Boolean"));
	
	PropertiesTable = New ValueTable;
	PropertiesTable.Columns.Add("Property",    New TypeDescription("String"));
	PropertiesTable.Columns.Add("Values",    New TypeDescription("Structure"));
	PropertiesTable.Columns.Add("ThereAreDifferences", New TypeDescription("Boolean"));
	
	TableOfMaterials = New ValueTable;
	TableOfMaterials.Columns.Add("Property",         New TypeDescription("String"));
	TableOfMaterials.Columns.Add("Products",     New TypeDescription("CatalogRef.Products"));
	TableOfMaterials.Columns.Add("Characteristic",   New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfMaterials.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	TableOfMaterials.Columns.Add("Values",         New TypeDescription("Structure"));
	TableOfMaterials.Columns.Add("ThereAreDifferences",      New TypeDescription("Boolean"));
	
	TableOfIncomingProducts_ = New ValueTable;
	TableOfIncomingProducts_.Columns.Add("Property",         New TypeDescription("String"));
	TableOfIncomingProducts_.Columns.Add("ProductKind",  New TypeDescription("CatalogRef.ItemKinds"));
	TableOfIncomingProducts_.Columns.Add("Products",     New TypeDescription("CatalogRef.Products"));
	TableOfIncomingProducts_.Columns.Add("Characteristic",   New TypeDescription("CatalogRef.ItemsCharacteristics"));
	TableOfIncomingProducts_.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	TableOfIncomingProducts_.Columns.Add("Values",         New TypeDescription("Structure"));
	TableOfIncomingProducts_.Columns.Add("ThereAreDifferences",      New TypeDescription("Boolean"));
	
	ProductTable_ = New ValueTable;
	ProductTable_.Columns.Add("Property",         New TypeDescription("String"));
	ProductTable_.Columns.Add("ProductKind",  New TypeDescription("CatalogRef.ItemKinds"));
	ProductTable_.Columns.Add("Products",     New TypeDescription("CatalogRef.Products"));
	ProductTable_.Columns.Add("Characteristic",   New TypeDescription("CatalogRef.ItemsCharacteristics"));
	ProductTable_.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	ProductTable_.Columns.Add("Values",         New TypeDescription("Structure"));
	ProductTable_.Columns.Add("ThereAreDifferences",      New TypeDescription("Boolean"));
	
	WasteTable = New ValueTable;
	WasteTable.Columns.Add("Property",         New TypeDescription("String"));
	WasteTable.Columns.Add("Products",     New TypeDescription("CatalogRef.Products"));
	WasteTable.Columns.Add("Characteristic",   New TypeDescription("CatalogRef.ItemsCharacteristics"));
	WasteTable.Columns.Add("UnitOfMeasure", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	WasteTable.Columns.Add("Values",         New TypeDescription("Structure"));
	WasteTable.Columns.Add("ThereAreDifferences",      New TypeDescription("Boolean"));
	
	TableOfLaborCosts = New ValueTable;
	TableOfLaborCosts.Columns.Add("Property",    New TypeDescription("String"));
	TableOfLaborCosts.Columns.Add("WorkKind",    New TypeDescription("CatalogRef.EmployeeWorkKinds"));
	TableOfLaborCosts.Columns.Add("Values",    New TypeDescription("Structure"));
	TableOfLaborCosts.Columns.Add("ThereAreDifferences", New TypeDescription("Boolean"));
	TableTypesOfRC = New ValueTable;
	TableTypesOfRC.Columns.Add("Property",          New TypeDescription("String"));
	TableTypesOfRC.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	TableTypesOfRC.Columns.Add("Values",          New TypeDescription("Structure"));
	TableTypesOfRC.Columns.Add("ThereAreDifferences",       New TypeDescription("Boolean"));
	
	TransactionTable = New ValueTable;
	TransactionTable.Columns.Add("Property",              New TypeDescription("String"));
	TransactionTable.Columns.Add("OperationPresentation", New TypeDescription("String"));
	TransactionTable.Columns.Add("Values",              New TypeDescription("Structure"));
	TransactionTable.Columns.Add("ThereAreDifferences",           New TypeDescription("Boolean"));
	
	DestinationParameterTable = New ValueTable;
	DestinationParameterTable.Columns.Add("Property",            New TypeDescription("String"));
	DestinationParameterTable.Columns.Add("Values",            New TypeDescription("Structure"));
	DestinationParameterTable.Columns.Add("ThereAreDifferences",         New TypeDescription("Boolean"));
	DestinationParameterTable.Columns.Add("ThereAreDifferencesInConditions",  New TypeDescription("Boolean"));
	DestinationParameterTable.Columns.Add("ThereAreDifferencesInValues", New TypeDescription("Boolean"));
	ComparisonData_ = New Structure;
	ComparisonData_.Insert("BOMList",          New Array);
	ComparisonData_.Insert("AttributesTable",           AttributesTable);
	ComparisonData_.Insert("PropertiesTable",              PropertiesTable);
	ComparisonData_.Insert("TableOfMaterials",           TableOfMaterials);
	ComparisonData_.Insert("TableOfIncomingProducts_",      TableOfIncomingProducts_);
	ComparisonData_.Insert("ProductTable_",              ProductTable_);
	ComparisonData_.Insert("WasteTable",              WasteTable);
	ComparisonData_.Insert("TableOfLaborCosts",          TableOfLaborCosts);
	ComparisonData_.Insert("TableTypesOfRC",               TableTypesOfRC);
	ComparisonData_.Insert("TransactionTable",             TransactionTable);
	ComparisonData_.Insert("DestinationParameterTable", DestinationParameterTable);
	Return ComparisonData_;
	
EndFunction

Function AddAttribute(PropertyName, Value, AttributesTable, ValueField)
	
	FoundRows = AttributesTable.FindRows(New Structure("Property", PropertyName));
	If FoundRows.Count() = 0 Then
		PropertyRow = AttributesTable.Add();
		PropertyRow.Property = PropertyName;
		PropertyRow.Values = New Structure;
	Else
		PropertyRow = FoundRows[0];
	EndIf;
	
	PropertyRow.Values.Insert(ValueField, Value);
	
	Return PropertyRow;
	
EndFunction

Procedure AddSpecificationDetails(Attributes, AttributesTable, ValueField)
	
	If GetFunctionalOption("UseProductionManagement2_2") Then
		
		AddAttribute(NStr("vi = 'Kiểu';
							|ru = 'Тип';
							|en = 'Type'; fa = 'نوع';
							|it = 'Tipo';
							|pl = 'Type';
							|tr = 'Tür'"), Attributes.ProductionProcessType, AttributesTable, ValueField);
		
		If Attributes.ProductionIssueByCustomPortions Then
			AddAttribute(NStr("vi = 'Xuất xưởng';
								|ru = 'Выпуск';
								|en = 'Release'; fa = 'آزادسازی';
								|it = 'Produzione';
								|pl = 'Release';
								|tr = 'İmal edilen ürünler'"), NStr("vi = 'với số lượng tùy ý';
														|ru = 'в произвольном количестве';
														|en = 'in any amount'; fa = 'به هر مقدار';
														|it = 'in quantità desiderata';
														|pl = 'w dowolnej ilości';
														|tr = 'serbest miktarda'"), AttributesTable, ValueField);
		Else
			AddAttribute(NStr("vi = 'Xuất xưởng';
								|ru = 'Выпуск';
								|en = 'Release'; fa = 'آزادسازی';
								|it = 'Produzione';
								|pl = 'Release';
								|tr = 'İmal edilen ürünler'"), NStr("vi = 'trong nhiều đợt';
														|ru = 'кратными партиями';
														|en = 'multiple lots'; fa = 'چندین بچ';
														|it = 'con i lotti multipli';
														|pl = 'krotnymi partiami';
														|tr = 'çoklu lotlar'"), AttributesTable, ValueField);
		EndIf;
		
		AddAttribute(NStr("vi = 'Lô tối ưu';
							|ru = 'Оптимальная партия';
							|en = 'Economic lot'; fa = 'Economic lot';
							|it = 'Lotto ottimale';
							|pl = 'Optymalna parita';
							|tr = 'Optimum lot'"), Attributes.EconomicReleaseLot, AttributesTable, ValueField);
		AddAttribute(NStr("vi = 'Lô tối thiểu';
							|ru = 'Минимальная партия';
							|en = 'Minimum lot'; fa = 'حداقل لات';
							|it = 'Lotto minimo';
							|pl = 'Minimalna partia';
							|tr = 'Minimum lot'"), Attributes.MinimumReleaseLot, AttributesTable, ValueField);
		
		AddAttribute(NStr("vi = 'Thời lượng có hạn';
							|ru = 'Ограничен срок пролеживания';
							|en = 'Queue period is limited'; fa = 'Queue period is limited';
							|it = 'Il periodo di stallo è limitato';
							|pl = 'Ograniczony okres odleżenia';
							|tr = 'Sınırlı kalış süresi'"), Attributes.ProductQueuePeriodIsLimited, AttributesTable, ValueField);
		
		If Attributes.ProductQueuePeriodIsLimited Then
			AddAttribute(NStr("vi = 'Thời lượng tối đa';
								|ru = 'Максимальный срок пролеживания';
								|en = 'Maximum queue period'; fa = 'Maximum queue period';
								|it = 'Il periodo minimo di stallo';
								|pl = 'Maksymalny okres odleżenia';
								|tr = 'Maksimum kalış süresi'"), Attributes.MaximumPeriodOfProductQueue, AttributesTable, ValueField);
		Else
			AddAttribute(NStr("vi = 'Thời lượng tối đa';
								|ru = 'Максимальный срок пролеживания';
								|en = 'Maximum queue period'; fa = 'Maximum queue period';
								|it = 'Il periodo minimo di stallo';
								|pl = 'Maksymalny okres odleżenia';
								|tr = 'Maksimum kalış süresi'"), 0, AttributesTable, ValueField);
		EndIf;
		
		AddAttribute(NStr("vi = 'Bộ phận chịu trách nhiệm';
							|ru = 'Ответственное подразделение';
							|en = 'Responsible business unit'; fa = 'واحد تجاری مسئول';
							|it = 'Reparto responsabile';
							|pl = 'Odpowiedzialny dział';
							|tr = 'Sorumlu departman'"), Attributes.ResponsibleBusinessUnit, AttributesTable, ValueField);
		
	EndIf;
	
	AddAttribute(NStr("vi = 'Bắt đầu có hiệu lực';
						|ru = 'Начало действия';
						|en = 'Valid from'; fa = 'معتبر از';
						|it = 'Inizio delle azioni';
						|pl = 'Początek działania';
						|tr = 'Eylem başlangıcı'"), Format(Attributes.ValidOnDate, "DF=dd.MM.yyyy;"), AttributesTable, ValueField);
	AddAttribute(NStr("vi = 'Kết thúc hiệu lực';
						|ru = 'Конец действия';
						|en = 'Expires'; fa = 'منقضی می‌شود';
						|it = 'Fine validità';
						|pl = 'Koniec ważności';
						|tr = 'Eylem sonu'"), Format(Attributes.ValidToDate, "DF=dd.MM.yyyy;"), AttributesTable, ValueField);
	
EndProcedure
Procedure AddSpecificationAssignmentParameters(AssignmentParameters, DestinationParameterValues, DestinationParameterTable, ValueField)
	
	TheStructureOfTheSearch = New Structure("ParameterKind,Attribute");
	
	For Each Parameter In AssignmentParameters Do
		
		If Not ValueIsFilled(Parameter.Presentation) Then
			Parameter.Presentation = ProductDataManagement.PresentationOfDestinationParameter(Parameter.ParameterKind, Parameter.Attribute, False);
		EndIf;
		
		FillPropertyValues(TheStructureOfTheSearch, Parameter);
		FoundValues = DestinationParameterValues.FindRows(TheStructureOfTheSearch);
		
		ValueStructure = Undefined;
		If ValueIsFilled(FoundValues) Then
			
			ValueStructure = FoundValues[0].ValueStructure; // See ProductDataManagementClientServer.SpecificationAssignmentParameterValueStructure
			
		EndIf;
		
		AddAttribute(Parameter.Presentation, ValueStructure, DestinationParameterTable, ValueField);
		
	EndDo;
	
EndProcedure
Function AddProperty(PropertyName, Value, PropertiesTable, ValueField)
	
	FoundRows = PropertiesTable.FindRows(New Structure("Property", PropertyName));
	If FoundRows.Count() = 0 Then
		PropertyRow = PropertiesTable.Add();
		PropertyRow.Property = PropertyName;
		PropertyRow.Values = New Structure;
	Else
		PropertyRow = FoundRows[0];
	EndIf;
	
	PropertyRow.Values.Insert(ValueField, Value);
	
	Return PropertyRow;
	
EndFunction

// Adds stage properties to the property table
// 
// Parameters:
// 	Data_Stage - CatalogSelection.ProductionStages - stage data
// 	PropertiesTable - ValueTable - property sheet
// 	ValueField - String - value field
//
Procedure AddStageProperties(Data_Stage, PropertiesTable, ValueField)
	
	If Data_Stage.StageKey = MissingStageKey() Then
		Return;
	EndIf;
	
	// Properties
	AddProperty(NStr("vi = 'Công đoạn số';
					|ru = 'N этапа';
					|en = 'Stage No.'; fa = 'شماره مرحله';
					|it = 'N della fase';
					|pl = 'Nr etapu';
					|tr = 'Aşama sırası'"),       Data_Stage.StageNumber,                 PropertiesTable, ValueField);
	AddProperty(NStr("vi = 'Số công đoạn tiếp theo';
					|ru = 'N след. этапа';
					|en = 'Next stage No.'; fa = 'شماره مرحله بعدی';
					|it = 'N della fase successiva';
					|pl = 'Nr następnego etapu';
					|tr = 'Sıradaki aşama sırası'"), Data_Stage.NextStageNo,       PropertiesTable, ValueField);
	AddProperty(NStr("vi = 'Bộ phận';
					|ru = 'Подразделение';
					|en = 'Business unit'; fa = 'Business unit';
					|it = 'Reparto';
					|pl = 'Business unit';
					|tr = 'Departman'"), Data_Stage.DepartmentPresentation, PropertiesTable, ValueField);
	AddProperty(NStr("vi = 'Đồng thời sản xuất số lượng đơn vị / lô';
					|ru = 'Одновременно производимое количество единиц/партий изделий';
					|en = 'Quantity of product units/lots produced simultaneously'; fa = 'مقدار واحدها/بچ‌های محصول تولیدشده به طور همزمان';
					|it = 'Unità di prodotti/lotti di produzione prodotti contemporaneamente';
					|pl = 'Produkowana jednocześnie ilość jednostek/partii wyrobów';
					|tr = 'Eş zamanlı olarak üretilen nihai ürünün birim/lot sayısı'"), Data_Stage.QuantityOfProductUnitsLotsProducedSimultaneously, PropertiesTable, ValueField);
	
	If GetFunctionalOption("UseRouteSheets") Then
		AddProperty(NStr("vi = 'Sơ đồ quy trình';
						|ru = 'Маршрутная карта';
						|en = 'Route sheet'; fa = 'برگه مسیر';
						|it = 'Scheda di lavorazione';
						|pl = 'Karta technologiczna';
						|tr = 'Rota'"), Data_Stage.RouteSheetPresentation, PropertiesTable, ValueField);
	EndIf;
	
	AddProperty(NStr("vi = 'Lập kế hoạch làm việc của dạng nguồn lực sản xuất';
					|ru = 'Планировать работу видов рабочих центров';
					|en = 'Plan operations of work center types'; fa = 'برنامه‌ریزی عملیات انواع مرکز کاری';
					|it = 'Pianificare il lavoro dei tipi di centri di lavoro';
					|pl = 'Planuj pracę rodzajów centrów pracy';
					|tr = 'İş merkezi türlerinin çalışmasını planla'"), Data_Stage.PlanOperationsOfWorkCenterTypes, PropertiesTable, ValueField);
	If Data_Stage.PlanOperationsOfWorkCenterTypes Then
		AddProperty(NStr("vi = 'Bộ đệm sơ bộ';
						|ru = 'Предварительный буфер';
						|en = 'Preliminary buffer'; fa = 'بافر مقدماتی';
						|it = 'Buffer iniziale';
						|pl = 'Bufor wstępny';
						|tr = 'Ön tampon zaman'"), 
						String(Data_Stage.PreliminaryBuffer) + " (" + Data_Stage.UnitOfMeasureOfPreliminaryBuffer + ")", 
						PropertiesTable, 
						ValueField);
						
		AddProperty(NStr("vi = 'Kết thúc bộ đệm';
						|ru = 'Завершающий буфер';
						|en = 'Follow-up buffer'; fa = 'بافر پسین';
						|it = 'Buffer finale';
						|pl = 'Bufor końcowy';
						|tr = 'Sonraki tampon zaman'"), 
						String(Data_Stage.FollowUpBuffer) + " (" + Data_Stage.UnitOfMeasureOfFollowUpBuffer + ")",
						PropertiesTable, 
						ValueField);
						
		AddProperty(NStr("vi = 'Liên tục';
						|ru = 'Непрерывный';
						|en = 'Continuous'; fa = 'پیوسته';
						|it = 'Continuo';
						|pl = 'Continuous';
						|tr = 'Sürekli'"), 
						Format(Data_Stage.Continuous_, NStr("vi = 'БЛ=Không; БИ=Có';
															|ru = 'БЛ=Нет; БИ=Да';
															|en = 'BF=No; BT=Yes'; fa = 'BF=خیر; BT=بله';
															|it = 'БЛ=No; БИ=Si';
															|pl = 'BF=Nie; BT=Tak';
															|tr = 'BF=Hayır; BT=Evet'")),
						PropertiesTable, 
						ValueField);
	Else
		AddProperty(NStr("vi = 'Thời lượng công đoạn';
						|ru = 'Длительность этапа';
						|en = 'Stage duration'; fa = 'مدت مرحله';
						|it = 'Durata della fase';
						|pl = 'Długość etapu';
						|tr = 'Aşama süresi'"), 
						String(Data_Stage.StageDuration) + " (" + Enums.TimeMeasureUnits.Day + ")",
						PropertiesTable,
						ValueField);
	EndIf; 
	
	AddProperty(NStr("vi = 'Mô tả';
					|ru = 'Описание';
					|en = 'Details'; fa = 'جزئیات';
					|it = 'Descrizione';
					|pl = 'Details';
					|tr = 'Ayrıntılar'"), Data_Stage.LongDesc, PropertiesTable, ValueField);
	
EndProcedure


Procedure AddProductData(CollectionOfTSStrings, TSData, ValueField)
	
	For Each AlCollections In CollectionOfTSStrings Do
		FoundRows = TSData.FindRows(New Structure("ProductKind,Products,Characteristic, UnitOfMeasure",
					AlCollections.ProductKind,
					AlCollections.Products,
					AlCollections.Characteristic,
					AlCollections.UnitOfMeasure));
		If FoundRows.Count() = 0 Then
			TSRow = TSData.Add();
			TSRow.ProductKind  = AlCollections.ProductKind;
			TSRow.Products     = AlCollections.Products;
			TSRow.Characteristic   = AlCollections.Characteristic;
			TSRow.UnitOfMeasure = AlCollections.UnitOfMeasure;
			TSRow.Property = AlCollections.ProductKindPresentation
				+ ?(ValueIsFilled(AlCollections.ProductsPresentation), "," + AlCollections.ProductsPresentation, "")
				+ ?(ValueIsFilled(AlCollections.CharacteristicPresentation), "," + AlCollections.CharacteristicPresentation, "")
				+ ", " + AlCollections.Ed;
			TSRow.Values = New Structure;
		Else
			TSRow = FoundRows[0];
		EndIf;
		
		TSRow.Values.Insert(ValueField, String(AlCollections.NumberOfPackages));
	EndDo;
	
EndProcedure

Procedure AddProductData_(CollectionOfTSStrings, TSData, ValueField)
	
	For Each AlCollections In CollectionOfTSStrings Do
		FoundRows = TSData.FindRows(New Structure("Products, Characteristic, UnitOfMeasure",
																AlCollections.Products,
																AlCollections.Characteristic,
																AlCollections.UnitOfMeasure));
		If FoundRows.Count() = 0 Then
			TSRow = TSData.Add();
			TSRow.Products     = AlCollections.Products;
			TSRow.Characteristic   = AlCollections.Characteristic;
			TSRow.UnitOfMeasure = AlCollections.UnitOfMeasure;
			TSRow.Property = AlCollections.ProductsPresentation 
								+ ?(ValueIsFilled(AlCollections.CharacteristicPresentation), "," + AlCollections.CharacteristicPresentation, "")
								+ ", " + AlCollections.Ed;
			TSRow.Values = New Structure;
		Else
			TSRow = FoundRows[0];
		EndIf;
		
		TSRow.Values.Insert(ValueField, String(AlCollections.NumberOfPackages));
	EndDo;
	
EndProcedure

Procedure AddDataOnLaborCosts(CollectionOfTSStrings, TSData, ValueField)
	
	For Each AlCollections In CollectionOfTSStrings Do
		
		FoundRows = TSData.FindRows(New Structure("WorkKind", AlCollections.WorkKind));
		If FoundRows.Count() = 0 Then
			TSRow = TSData.Add();
			TSRow.WorkKind = AlCollections.WorkKind;
			TSRow.Property = AlCollections.WorkKindPresentation;
			TSRow.Values = New Structure;
		Else
			TSRow = FoundRows[0];
		EndIf;
		
		TSRow.Values.Insert(ValueField, Format(AlCollections.Count, "NZ=; NG="));
	EndDo;
	
EndProcedure

Procedure AddDataByRCType(CollectionOfTSStrings, TSData, ValueField)
	
	For Each AlCollections In CollectionOfTSStrings Do
		FoundRows = TSData.FindRows(New Structure("WorkCenterType", AlCollections.WorkCenterType));
		If FoundRows.Count() = 0 Then
			TSRow = TSData.Add();
			TSRow.WorkCenterType  = AlCollections.WorkCenterType;
			TSRow.Property = AlCollections.WorkCenterTypePresentation;
			TSRow.Values = New Structure;
		Else
			TSRow = FoundRows[0];
		EndIf;
		
		TSRow.Values.Insert(ValueField, String(AlCollections.OperationTime) + " (" + AlCollections.UnitOfMeasure + ")");
	EndDo;
	
EndProcedure

Procedure AddTransactionData(CollectionOfTSStrings, TSData, ValueField)

	For Each AlCollections In CollectionOfTSStrings Do
		FoundRows = TSData.FindRows(New Structure("OperationPresentation", AlCollections.OperationPresentation));
		If FoundRows.Count() = 0 Then
			TSRow = TSData.Add();
			TSRow.OperationPresentation  = AlCollections.OperationPresentation;
			TSRow.Property = AlCollections.OperationPresentation;
			TSRow.Values = New Structure;
		Else
			TSRow = FoundRows[0];
		EndIf;
		
		ValueStrings_ = New Array;
		ValueStrings_.Add("Qty-vo: "+Format(AlCollections.Count, "NZ=; NG=")
			+ ?(ValueIsFilled(AlCollections.UnitOfMeasurePresentation), " (" + AlCollections.UnitOfMeasurePresentation + ")", ""));
		ValueStrings_.Add("Time: "+Format(AlCollections.TimePerPiece, "NZ=; NG=")
			+ ?(ValueIsFilled(AlCollections.TimePerPieceUnitOfMeasurePresentation), " (" + AlCollections.TimePerPieceUnitOfMeasurePresentation + ")", ""));
		If ValueIsFilled(AlCollections.WorkCenterPresentation) Then
			ValueStrings_.Add("RC: "+AlCollections.WorkCenterPresentation
				+ ?(ValueIsFilled(AlCollections.SetupSettingsPresentation), " (" + AlCollections.SetupSettingsPresentation + ")", ""));
		EndIf;
		TSRow.Values.Insert(ValueField, StrConcat(ValueStrings_, "; "));
		
	EndDo;

EndProcedure

Procedure GetSpecificationData(ComparisonData_, BOMList, ProductAndMaterialComparisonMode)
	
	// We will get the data
	Query = New Query(
	"SELECT
	|	StageList.Owner AS Owner,
	|	MAX(StageList.Ref) AS Ref
	|INTO TTListOfFirstStagesOfSpecifications
	|FROM
	|	Catalog.ProductionStages AS StageList
	|WHERE
	|	StageList.Owner IN(&BOMList)
	|	AND NOT StageList.DeletionMark
	|	AND (StageList.StageNumber = 1)
	|
	|GROUP BY
	|	StageList.Owner
	|
	|INDEX BY
	|	Owner
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Attributes.Ref AS BillOfMaterials,
	|	Attributes.ProductionProcessType AS ProductionProcessType,
	|	Attributes.ProductionIssueByCustomPortions AS ProductionIssueByCustomPortions,
	|	Attributes.EconomicReleaseLot AS EconomicReleaseLot,
	|	Attributes.MinimumReleaseLot AS MinimumReleaseLot,
	|	Attributes.ProductQueuePeriodIsLimited AS ProductQueuePeriodIsLimited,
	|	Attributes.MaximumPeriodOfProductQueue AS MaximumPeriodOfProductQueue,
	|	Attributes.ResponsibleBusinessUnit AS ResponsibleBusinessUnit,
	|	Attributes.ValidOnDate AS ValidOnDate,
	|	Attributes.ValidToDate AS ValidToDate
	|FROM
	|	Catalog.BillsOfMaterials AS Attributes
	|WHERE
	|	Attributes.Ref IN(&BOMList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Attributes.Ref AS BillOfMaterials,
	|	Attributes.MultiStageProductionProcess AS Multistage,
	|	Attributes.Presentation AS BillOfMaterialsPresentation,
	|	ISNULL(Stages.Description, &MissingStageKey) AS StageKey,
	|	ISNULL(Stages.StageNumber, 0) AS StageNumber,
	|	ISNULL(Stages.NextStageNo, 0) AS NextStageNo,
	|	ISNULL(Stages.Department.Presentation, """") AS DepartmentPresentation,
	|	ISNULL(Stages.RouteSheet.Presentation, """") AS RouteSheetPresentation,
	|	Stages.QuantityOfProductUnitsLotsProducedSimultaneously AS QuantityOfProductUnitsLotsProducedSimultaneously,
	|	Stages.PlanOperationsOfWorkCenterTypes AS PlanOperationsOfWorkCenterTypes,
	|	Stages.StageDuration AS StageDuration,
	|	Stages.PreliminaryBuffer AS PreliminaryBuffer,
	|	Stages.FollowUpBuffer AS FollowUpBuffer,
	|	Stages.UnitOfMeasureOfPreliminaryBuffer AS UnitOfMeasureOfPreliminaryBuffer,
	|	Stages.UnitOfMeasureOfFollowUpBuffer AS UnitOfMeasureOfFollowUpBuffer,
	|	Stages.Continuous_ AS Continuous_,
	|	Stages.LongDesc AS LongDesc
	|FROM
	|	Catalog.BillsOfMaterials AS Attributes
	|
	|		LEFT JOIN Catalog.ProductionStages AS Stages
	|		ON Attributes.Ref = Stages.Owner
	|WHERE
	|	Attributes.Ref IN(&BOMList)
	|	AND ISNULL(NOT Stages.DeletionMark, TRUE)
	|
	|ORDER BY
	|	StageNumber,
	|	NextStageNo
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TSData.Ref AS BillOfMaterials,
	|	ISNULL(TSData.Stage.Description, &MissingStageKey) AS StageKey,
	|	TSData.ProductKind AS ProductKind,
	|	TSData.Products AS Products,
	|	TSData.Characteristic AS Characteristic,
	|	&UnitOfMeasure1 AS UnitOfMeasure,
	|	&UnitOfMeasurePresentation1 AS Ed,
	|	SUM(TSData.NumberOfPackages * ISNULL(&QueryTextPackagingFactor1, 1)) AS NumberOfPackages,
	|	ISNULL(TSData.ProductKind.Presentation, """") AS ProductKindPresentation,
	|	ISNULL(TSData.Products.Presentation, """") AS ProductsPresentation,
	|	ISNULL(TSData.Characteristic.Presentation, """") AS CharacteristicPresentation
	|FROM
	|	Catalog.BillsOfMaterials.ManufacturedProducts AS TSData
	|WHERE
	|	TSData.Ref IN(&BOMList)
	|
	|GROUP BY
	|	TSData.Ref,
	|	TSData.Stage,
	|	TSData.ProductKind,
	|	TSData.Products,
	|	TSData.Characteristic,
	|	&UnitOfMeasure1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TSData.Ref AS BillOfMaterials,
	|	ISNULL(TSData.Stage.Description, &MissingStageKey) AS StageKey,
	|	TSData.Products AS Products,
	|	TSData.Characteristic AS Characteristic,
	|	&UnitOfMeasure1 AS UnitOfMeasure,
	|	&UnitOfMeasurePresentation1 AS Ed,
	|	SUM(TSData.NumberOfPackages * ISNULL(&QueryTextPackagingFactor1, 1)) AS NumberOfPackages,
	|	ISNULL(TSData.Products.Presentation, """") AS ProductsPresentation,
	|	ISNULL(TSData.Characteristic.Presentation, """") AS CharacteristicPresentation
	|FROM
	|	Catalog.BillsOfMaterials.RecyclableWaste AS TSData
	|WHERE
	|	TSData.Ref IN(&BOMList)
	|
	|GROUP BY
	|	TSData.Ref,
	|	TSData.Stage,
	|	TSData.Products,
	|	TSData.Characteristic,
	|	&UnitOfMeasure1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TSData.Ref AS BillOfMaterials,
	|	ISNULL(ListOfFirstStages.Ref.Description, """") AS StageKey,
	|	TSData.MainProductProductKind AS ProductKind,
	|	TSData.MainProductProducts AS Products,
	|	TSData.MainProductCharacteristic AS Characteristic,
	|	&UnitOfMeasure2 AS UnitOfMeasure,
	|	&UnitOfMeasurePresentation2 AS Ed,
	|	TSData.MainProductNumberOfPackages * ISNULL(&QueryTextPackagingFactor2, 1) AS NumberOfPackages,
	|	ISNULL(TSData.MainProductProductKind.Presentation, """") AS ProductKindPresentation,
	|	ISNULL(TSData.MainProductProducts.Presentation, """") AS ProductsPresentation,
	|	ISNULL(TSData.MainProductCharacteristic.Presentation, """") AS CharacteristicPresentation
	|FROM
	|	Catalog.BillsOfMaterials AS TSData
	|		LEFT JOIN TTListOfFirstStagesOfSpecifications AS ListOfFirstStages
	|		ON TSData.Ref = ListOfFirstStages.Owner
	|WHERE
	|	TSData.Ref IN(&BOMList)
	|	AND TSData.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TSData.Ref AS BillOfMaterials,
	|	ISNULL(TSData.Stage.Description, &MissingStageKey) AS StageKey,
	|	TSData.Products AS Products,
	|	ISNULL(TSData.Products.Presentation, """") AS ProductsPresentation,
	|	TSData.Characteristic AS Characteristic,
	|	ISNULL(TSData.Characteristic.Presentation, """") AS CharacteristicPresentation,
	|	&UnitOfMeasure1 AS UnitOfMeasure,
	|	&UnitOfMeasurePresentation1 AS Ed,
	|	SUM(TSData.NumberOfPackages * ISNULL(&QueryTextPackagingFactor1, 1)) AS NumberOfPackages
	|FROM
	|	Catalog.BillsOfMaterials.MaterialsAndServices AS TSData
	|WHERE
	|	TSData.Ref IN(&BOMList)
	|
	|GROUP BY
	|	TSData.Ref,
	|	TSData.Stage,
	|	TSData.Products,
	|	TSData.Characteristic,
	|	&UnitOfMeasure1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TSData.Ref AS BillOfMaterials,
	|	ISNULL(TSData.Stage.Description, &MissingStageKey) AS StageKey,
	|	TSData.WorkKind AS WorkKind,
	|	ISNULL(TSData.WorkKind.Presentation, """") AS WorkKindPresentation,
	|	TSData.Count AS Count,
	|	TSData.ProductCostElement AS ProductCostElement,
	|	TSData.WorkAssignment AS WorkAssignment
	|FROM
	|	Catalog.BillsOfMaterials.LaborCosts AS TSData
	|WHERE
	|	TSData.Ref IN(&BOMList)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Stages.Owner AS BillOfMaterials,
	|	Stages.Description AS StageKey,
	|	TSData.WorkCenterType AS WorkCenterType,
	|	ISNULL(TSData.WorkCenterType.Presentation, """") AS WorkCenterTypePresentation,
	|	CASE
	|		WHEN TSData.WorkCenterType.ParallelLoad
	|				AND TSData.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|				AND NOT TSData.WorkCenterType.SetupSettingsAreUsed
	|			THEN TSData.WorkCenterType.OperationTime
	|		WHEN TSData.WorkCenterType.ParallelLoad
	|				AND TSData.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|				AND TSData.WorkCenterType.SetupSettingsAreUsed
	|			THEN TSData.SetupSettings.OperationTime
	|		ELSE TSData.OperationTime
	|	END AS OperationTime,
	|	CASE
	|		WHEN TSData.WorkCenterType.ParallelLoad
	|				AND TSData.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|				AND NOT TSData.WorkCenterType.SetupSettingsAreUsed
	|			THEN TSData.WorkCenterType.UnitOfMeasure
	|		WHEN TSData.WorkCenterType.ParallelLoad
	|				AND TSData.WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
	|				AND TSData.WorkCenterType.SetupSettingsAreUsed
	|			THEN TSData.SetupSettings.UnitOfMeasure
	|		ELSE TSData.UnitOfMeasure
	|	END AS UnitOfMeasure
	|FROM
	|	Catalog.ProductionStages AS Stages
	|		INNER JOIN Catalog.ProductionStages.WorkCenterTypes AS TSData
	|		ON (TSData.Ref = Stages.Ref)
	|WHERE
	|	NOT Stages.DeletionMark
	|	AND Stages.Owner IN(&BOMList)
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Operations.BillOfMaterials AS BillOfMaterials,
	|	CAST(Operations.Owner AS Catalog.ProductionStages).Description AS StageKey,
	|
	|	ISNULL(Operations.Presentation, """")                   AS OperationPresentation,
	|	Operations.Count                                      AS Count,
	|	ISNULL(Operations.UnitOfMeasure.Presentation, """")  AS UnitOfMeasurePresentation,
	|	Operations.TimePerPiece                                    AS TimePerPiece,
	|	PRESENTATION(Operations.TimePerPieceUnitOfMeasure)                AS TimePerPieceUnitOfMeasurePresentation,
	|	ISNULL(Operations.WorkCenter.Presentation, """")      AS WorkCenterPresentation,
	|	ISNULL(Operations.SetupSettings.Presentation, """")    AS SetupSettingsPresentation
	|
	|FROM
	|	Catalog.ManufacturingOperations AS Operations
	|
	|WHERE
	|	&StoreOperationsInBillsOfMaterials
	|	AND NOT Operations.DeletionMark
	|	AND Operations.BillOfMaterials IN(&BOMList)
	|
	|ORDER BY
	|	StageKey,
	|	Operations.OperationNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ParameterKind  AS ParameterKind,
	|	Table.Attribute      AS Attribute,
	|	Table.Priority     AS Priority,
	|	PRESENTATION("""")   AS Presentation
	|FROM
	|	InformationRegister.BOMAssignmentParameters AS Table
	|
	|ORDER BY
	|	Priority DESC
	|
	|");
	
	If ProductAndMaterialComparisonMode = 0 Then // in storage units
		
		Query.Text = StrReplace(Query.Text,
									"&QueryTextPackagingFactor1",
									Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
										"TSData.Package",
										"TSData.Products"));
		
		Query.Text = StrReplace(Query.Text,
									"&QueryTextPackagingFactor2",
									Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
										"TSData.MainProductPackage",
										"TSData.MainProductProducts"));
		
		Query.Text = StrReplace(Query.Text, "&UnitOfMeasure1", "TSData.Products.UnitOfMeasure");
		Query.Text = StrReplace(Query.Text, "&UnitOfMeasure2", "TSData.MainProductProducts.UnitOfMeasure");
		
		Query.Text = StrReplace(
						Query.Text,
						"&UnitOfMeasurePresentation1",
						"ISNULL(TSData.Products.UnitOfMeasure.Presentation, """")");
		
		Query.Text = StrReplace(
						Query.Text,
						"&UnitOfMeasurePresentation2",
						"ISNULL(TSData.MainProductProducts.UnitOfMeasure.Presentation, """")");
		
	Else // in units of specifications
		
		Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1", 1);
		Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2", 1);
		
		Query.Text = StrReplace(Query.Text, "&UnitOfMeasure1", "TSData.Package");
		Query.Text = StrReplace(Query.Text, "&UnitOfMeasure2", "TSData.MainProductProducts.UnitOfMeasure");
		
		Query.Text = StrReplace(
						Query.Text,
						"&UnitOfMeasurePresentation1",
						"	CASE
						|		WHEN TSData.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
						|			THEN ISNULL(TSData.Package.Presentation, """")
						|		ELSE ISNULL(TSData.Products.UnitOfMeasure.Presentation, """")
						|	END");
		
		Query.Text = StrReplace(
						Query.Text,
						"&UnitOfMeasurePresentation2",
						"	CASE
						|		WHEN TSData.MainProductPackage <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
						|			THEN ISNULL(TSData.MainProductPackage.Presentation, """")
						|		ELSE ISNULL(TSData.MainProductProducts.UnitOfMeasure.Presentation, """")
						|	END");
		
	EndIf;
	
	Query.SetParameter("BOMList", BOMList);
	Query.SetParameter("StoreOperationsInBillsOfMaterials", GetFunctionalOption("StoreOperationsInBillsOfMaterials"));
	Query.SetParameter("MissingStageKey", MissingStageKey());
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	// details of specifications
	
	SelectingBankingDetails_ = Result[1].Select();
	
	DetailsComparisonData = DataForComparisonConstructor();
	
	While SelectingBankingDetails_.Next() Do
		
		ObjectOfComparison = SelectingBankingDetails_.BillOfMaterials;
		
		ValueField = "Value" + Format(BOMList.IndexOf(BOMList.FindByValue(ObjectOfComparison)), "NG=");
		
		AddSpecificationDetails(SelectingBankingDetails_, DetailsComparisonData.AttributesTable, ValueField);
		
	EndDo;
	
	ComparisonData_.ComparisonData_.Insert(KeyDetailsOfSpecifications(), DetailsComparisonData);
	
	// properties of stages
	
	TableOfOutputProducts   = Result[3].Unload();
	TableOfReturnableWaste = Result[4].Unload();
	TableOfIncomingProducts_   = Result[5].Unload();
	TableOfMaterials        = Result[6].Unload();
	TableOfLaborCosts       = Result[7].Unload();
	TableTypesOfRC            = Result[8].Unload();
	TransactionTable          = Result[9].Unload();
	SelectionOfStages = Result[2].Select();
	While SelectionOfStages.Next() Do
		
		ObjectOfComparison = SelectionOfStages.BillOfMaterials;
		
		StageKey = SelectionOfStages.StageKey;
		ValueField = "Value" + Format(BOMList.IndexOf(BOMList.FindByValue(ObjectOfComparison)), "NG=");
		
		StageString = ComparisonData_.StageList.FindByValue(StageKey);
		
		If StageString = Undefined Then
			
			PresentationStage = String(SelectionOfStages.StageKey)
				+ ?(SelectionOfStages.StageKey = MissingStageKey(), ""," (" + SelectionOfStages.BillOfMaterialsPresentation + ")");
			
			ComparisonData_.StageList.Add(StageKey, PresentationStage);
			
			StageComparisonData = DataForComparisonConstructor();
			
			ComparisonData_.ComparisonData_.Insert(StageKey, StageComparisonData);
			
			StageComparisonData.BOMList = New Array;
			
		Else
			
			StageComparisonData = ComparisonData_.ComparisonData_.Get(StageKey);
			
		EndIf; 
		
		StageComparisonData.BOMList.Add(ObjectOfComparison);
		
		AddStageProperties(SelectionOfStages, StageComparisonData.PropertiesTable, ValueField);
		
		If SelectionOfStages.Multistage Then
			DataSearchStructure_ = New Structure("BillOfMaterials, StageKey", SelectionOfStages.BillOfMaterials, SelectionOfStages.StageKey);
		Else
			DataSearchStructure_ = New Structure("BillOfMaterials", SelectionOfStages.BillOfMaterials);
		EndIf;
		
		// ManufacturedProducts
		TSData = TableOfOutputProducts.FindRows(DataSearchStructure_);
		AddProductData(TSData, StageComparisonData.ProductTable_, ValueField);
		
		// RecyclableWaste
		TSData = TableOfReturnableWaste.FindRows(DataSearchStructure_);
		AddProductData_(TSData, StageComparisonData.WasteTable, ValueField);
		
		// IncomingProducts
		TSData = TableOfIncomingProducts_.FindRows(DataSearchStructure_);
		AddProductData(TSData, StageComparisonData.TableOfIncomingProducts_, ValueField);
		
		// MaterialsAndServices
		TSData = TableOfMaterials.FindRows(DataSearchStructure_);
		AddProductData_(TSData, StageComparisonData.TableOfMaterials, ValueField);
		
		// LaborCosts
		TSData = TableOfLaborCosts.FindRows(DataSearchStructure_);
		AddDataOnLaborCosts(TSData, StageComparisonData.TableOfLaborCosts, ValueField);
		
		// WorkCenterTypes
		TSData = TableTypesOfRC.FindRows(DataSearchStructure_);
		AddDataByRCType(TSData, StageComparisonData.TableTypesOfRC, ValueField);
		
		// Operations
		TSData = TransactionTable.FindRows(DataSearchStructure_);
		AddTransactionData(TSData, StageComparisonData.TransactionTable, ValueField);
		
	EndDo;
	
	// destination parameters
	If GetFunctionalOption("UseBOMAssignmentParameters") Then
	
		AssignmentParameters          = Result[10].Unload();
		DestinationParameterValues = Catalogs.BillsOfMaterials.ValuesOfBOMAssignmentParameters(BOMList.UnloadValues());
		
		For IndexOf = 0 To BOMList.Count() - 1 Do
			
			ValueField = "Value" + Format(IndexOf, "NG=");
			
			AddSpecificationAssignmentParameters(
				AssignmentParameters,
				DestinationParameterValues.Get(BOMList[IndexOf].Value),
				DetailsComparisonData.DestinationParameterTable,
				ValueField);
			
		EndDo;
	
	EndIf;
	
EndProcedure

Procedure ListProperties_(PropertiesTable, PropertyAreaStringName, PropertyAreaStringSource, ComparisonResult, BOMList, ShowOnlyDifferences)
	
	For Each DataProperty In PropertiesTable Do
		If ShowOnlyDifferences And Not DataProperty.ThereAreDifferences Then
			Continue;
		EndIf; 
		
		PropertyAreaStringName.Parameters.Property = DataProperty.Property;
		SourceArea_1 = ComparisonResult.Put(PropertyAreaStringName);
		If Not ShowOnlyDifferences And DataProperty.ThereAreDifferences Then
			SourceArea_1.TextColor = StyleColors.SpecialTextColor;
		EndIf; 
		
		For Each AlCollections In BOMList Do
			NameOfValueField = "Value" + Format(BOMList.IndexOf(AlCollections), "NG="); 
			
			If DataProperty.Values.Property(NameOfValueField) Then
				PropertyAreaStringSource.Parameters.SourceValue_ = DataProperty.Values[NameOfValueField];
			Else
				PropertyAreaStringSource.Parameters.SourceValue_ = "";
			EndIf;
			SourceArea_1 = ComparisonResult.Join(PropertyAreaStringSource);
			If Not ShowOnlyDifferences And DataProperty.ThereAreDifferences Then
				SourceArea_1.TextColor = StyleColors.SpecialTextColor;
			EndIf; 
		EndDo;
		
	EndDo; 
	
EndProcedure

Procedure OutputGroupOfProperties(TheGroupName, PropertiesTable, AreaPropertyGroupName, AreaPropertyGroupSource, PropertyAreaStringName, PropertyAreaStringSource, ComparisonResult, BOMList, ShowOnlyDifferences)
	
	If PropertiesTable.Count() = 0 Then
		Return;
	EndIf;
	
	If ShowOnlyDifferences And PropertiesTable.Find(True, "ThereAreDifferences") = Undefined Then
		Return;
	EndIf; 
	
	AreaPropertyGroupName.Parameters.TheGroupName = TheGroupName;
	ComparisonResult.Put(AreaPropertyGroupName);
	For Each AlCollections In BOMList Do
		SourceArea_1 = ComparisonResult.Join(AreaPropertyGroupSource);
	EndDo;
	SourceArea_1.RightBorder = New Line(SpreadsheetDocumentCellLineType.Solid, 1);
	
	ComparisonResult.StartRowGroup(TheGroupName);
	
	ListProperties_(PropertiesTable,
							PropertyAreaStringName,
							PropertyAreaStringSource,
							ComparisonResult,
							BOMList,
							ShowOnlyDifferences);
	
	ComparisonResult.EndRowGroup();
	
EndProcedure

Function RepresentationOfValueOfDestinationParameter(ValueStructure)
	
	Result = "";
	
	If ValueStructure.Condition.List Then
		If ValueStructure.Value.Count() > 2 Then
			Result = StrTemplate(NStr("vi = '%1; %2 (+ hơn nữa %3)';
										|ru = '%1; %2 (+ еще %3)';
										|en = '%1;%2 (and %3)'; fa = '%1;%2 (and %3)';
										|it = '%1; %2 (+ ancora %3)';
										|pl = '%1; %2 (+ jeszcze %3)';
										|tr = '%1; %2 (+ %3 daha)'"),
				ValueStructure.Value[0],
				ValueStructure.Value[1],
				ValueStructure.Value.Count() - 2);
		Else
			Result = StrConcat(ValueStructure.Value.UnloadValues(), "; ");
		EndIf;
	ElsIf ValueStructure.Condition.Interval Then
		Value1 = ValueStructure.Value1;
		Value2 = ValueStructure.Value2;
		If TypeOf(Value1) = Type("Date") Then
			Value1 = ?(Value1 = BegOfDay(Value1), Format(Value1, "DF=dd.MM.yyyy;"), Value1);
			Value2 = ?(Value2 = BegOfDay(Value2), Format(Value2, "DF=dd.MM.yyyy;"), Value2);
		EndIf;
		Result = StrTemplate(NStr("vi = 'từ %1 đến %2';
									|ru = 'с %1 по %2';
									|en = 'from %1 to %2'; fa = 'from %1 to %2';
									|it = 'da %1 fino a %2';
									|pl = 'od %1 do %2';
									|tr = '%1 ile %2 arası'"), Value1, Value2);
	Else
		Value = ValueStructure.Value;
		If TypeOf(Value) = Type("Date") Then
			Result = ?(Value = BegOfDay(Value), Format(Value, "DF=dd.MM.yyyy;"), Value);
		Else
			Result = Value;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

Function MissingStageKey()
	
	Return NStr("vi = '<không có công đoạn>';
				|ru = '<этап отсутствует>';
				|en = '<stage is missing>'; fa = '<stage is missing>';
				|it = '<fase assente>';
				|pl = '<brak etapu>';
				|tr = '<aşama yok>'");
	
EndFunction

Function KeyDetailsOfSpecifications()
	
	Return "19af7da2-0bd4-4d7f-b5fa-a9897b2edf77";
	
EndFunction

#EndRegion

#EndIf
