#Region Public

// Returns the structure of parameters for reflecting accumulation register entries in financial accounting.
// If any parameter is an expression of the query language, then the field descriptions in it must contain 
// the alias of the data source passed through the Data source alias parameter. If the parameter is 
// only a field name, including a dereference separated by a dot, it can be specified without an alias of the data source.
// 
// Parameters:
//  RegistrationForReflection - Boolean - Flag for getting parameters to register for accounting
// 
// Returns:
//  Structure - LongDesc:
//  * InversionOfRegisteredRecords - Boolean - Only for Balance registers. Indicates whether the register Registered Records match the rule Receipt = Credit, Expense = Debit.
//  * AllocationOfLongTermAssetsAndLiabilities - Boolean - Indicates whether register credentials are divided into short-term and long-term.
//  * DataPathOrganization - String - The path of fetching the organization value from the register data
//  * DataPathLogger - String - The path of fetching the value of the motion document from the register data
//  * DataPathConfigurationObject - String - The path of selecting the register data corresponding to the settings objects, in the context of which the accounting accounts are specified. Can be redefined in the description of the buh objects.accounting records
//  * DataPathAccountingLocation - String - The way to select the register data corresponding to the accounting locations, in the context of which the exceptions of accounting accounts are specified
//  * DataPathRecordFinID - String - The path of selecting the value of the register record ID
//  * DataPathSettingUpHouseholdOperations - String - The path of selecting the value of the business operation setting
//  * PathToDataLineOfBusiness - String - The path of selecting the activity direction value from the register data
//  * DataPathRowId - String - The path of fetching the string ID value from the register data. Can be redefined in the description of the buh objects.accounting records
//  * PathToDataVATActivity - String - The way to select the value of the VAT accounting activity from the register data
//  * PathToDataDivision - String - The path of fetching the subdivision value from the register data
//  * DataPathMaturityDate - String - The way of sampling the register data corresponding to the dates of repayment of obligations
//  * DataPathCurrency - String - The path of selecting the currency value from the register data, an empty string if the register does not keep currency records
//  * DataPathIsStorno - String - The path of selecting the attribute of the correction record of the correction document
//  * DimensionsDetails - Structure of KeyAndValue - LongDesc:
//   ** Key - String - The name of the dimension register or dimension detail if it is an analytics key
//   ** Value - See DescriptionOfDataSourceField
//  * AttributesDetails1 - Structure of KeyAndValue - LongDesc:
//   ** Key - String - Case Attribute name
//   ** Value - See DescriptionOfDataSourceField
//  * ManResources - Array of String - An array of strings with the names of all used resources that store the transaction amount in the management accounting currency. It can be redefined in the description of the buh objects.accounting. It can be empty if there is no upr. accounting in the register
//  * LocalResources - Array of String - An array of strings with the names of all used resources that store the transaction amount in the currency of regulated accounting. It can be redefined in the description of the buh objects.accounting. It can be empty if there is no regl. accounting in the register
//  * ShaftResources - Array of String - An array of strings with the names of all used resources that store the currency amount of the transaction, if currency accounting is kept in the register. It can be redefined in the description of the buh objects.accounting. It can be empty if there is no shaft. accounting in the register
//  * ResourcesQuantity - Array of String - An array of strings with the names of resources that store the number of operations. It can be empty if there is no quantitative accounting in the register
//  * DebitCondition - String - A condition in the query language for determining the debit attribute of Registering Records in negotiable registers and residual registers with complex logic
//  * ConditionCredit - String - A condition in the query language for determining the sign of credit Registered Recorded in negotiable registers and residual registers with complex logic
//  * DataSourceAlias - String - the alias of the data source used in parameters that are expressions of the query language.
//  * DataSourceAlias - String - the alias of the data source used in parameters that are expressions of the query language.
//  * AdditionalSelection - String - A condition in the query language for additional selection of register data.
//  * ContainsUnbalancedData - Boolean - A sign of the presence in the register of non-balance sheet data that cannot be filtered through the Additional Selection property, but are filtered through selections of these items of assets and liabilities. 
// 
Function ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegistrationForReflection = False) Export
	
	ReflectionParameters = New Structure();
	ReflectionParameters.Insert("DataPathOrganization", "Organization");
	ReflectionParameters.Insert("DataPathLogger", "Recorder");
	ReflectionParameters.Insert("DataSourceAlias", DefaultDataSourceAlias());
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.Insert("InversionOfRegisteredRecords", False);
	ReflectionParameters.Insert("AllocationOfLongTermAssetsAndLiabilities", False);
	ReflectionParameters.Insert("DataPathConfigurationObject", "");
	ReflectionParameters.Insert("DataPathAccountingLocation", "");
	ReflectionParameters.Insert("DataPathRecordFinID", "FinRecordID");
	ReflectionParameters.Insert("DataPathSettingUpHouseholdOperations", "BusinessTransactionSetting");
	ReflectionParameters.Insert("PathToDataLineOfBusiness", "");
	ReflectionParameters.Insert("DataPathRowId", "");
	ReflectionParameters.Insert("PathToDataVATActivity", "");
	ReflectionParameters.Insert("PathToDataDivision", "");
	ReflectionParameters.Insert("DataPathMaturityDate", "");
	ReflectionParameters.Insert("DataPathCurrency", "");
	ReflectionParameters.Insert("DataPathIsStorno", "");
	ReflectionParameters.Insert("DimensionsDetails", New Structure);
	ReflectionParameters.Insert("AttributesDetails1", New Structure);
	ReflectionParameters.Insert("ManResources", New Array());
	ReflectionParameters.Insert("LocalResources", New Array());
	ReflectionParameters.Insert("ShaftResources", New Array());
	ReflectionParameters.Insert("ResourcesQuantity", New Array());
	ReflectionParameters.Insert("DebitCondition", "");
	ReflectionParameters.Insert("ConditionCredit", "");
	ReflectionParameters.Insert("AdditionalSelection", "");
	ReflectionParameters.Insert("ContainsUnbalancedData", False);
	
	ActualBudgetingDataServer.ToSupplementParametersOfReflectionOfRegisteredRecordsInFinancialAccounting(ReflectionParameters);
	
	Return ReflectionParameters;
	
EndFunction

// Fills in the parameters for reflecting Registered Recorded movements in the fin.accounting by accumulation register metadata
//
// Parameters:
//  ReflectionParameters - See ParametersForReflectingRegisteredRecordsInFinancialAccounting
//  RegisterMetadata - MetadataObjectAccumulationRegister - Metadata of the accumulation register
//	UnavailableFields - Array - Array of field names that are not available as subconto fill sources
//
Procedure FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata, UnavailableFields = Undefined) Export
	
	For Each Dimension In RegisterMetadata.Dimensions Do
		If UnavailableFields <> Undefined And UnavailableFields.Find(Dimension.Name) <> Undefined Then
			Continue;
		EndIf;
		
		If StrStartsWith(Dimension.Name, "Delete") Then
			Continue;
		EndIf;
		
		DescriptionOfRegisterField = DescriptionOfDataSourceField(Dimension.Name, Dimension.Synonym, Dimension.Type);
		ReflectionParameters.DimensionsDetails.Insert(Dimension.Name, DescriptionOfRegisterField);
		
		If Dimension.Name = "VATActivityType" Then
			ReflectionParameters.PathToDataVATActivity = Dimension.Name;
		EndIf;
	EndDo;
	
	AddCompositionOfAnalyticsKeysToDescriptionOfMeasurements(ReflectionParameters.DimensionsDetails, RegisterMetadata);
	
	RegistrarIsAttribute = False;
	
	For Each Attribute In RegisterMetadata.Attributes Do
		If UnavailableFields <> Undefined And UnavailableFields.Find(Attribute.Name) <> Undefined Then
			Continue;
		EndIf;
		
		If StrStartsWith(Attribute.Name, "Delete")
		 Or Attribute.Type.ContainsType(Type("ValueStorage")) Then
			Continue;
		EndIf;
		
		If Attribute.Name = ReflectionParameters.DataPathLogger Then
			FieldName = "Recorder";
			FieldSynonym = RegisterMetadata.StandardAttributes.Recorder.Synonym;
			RegistrarIsAttribute = True;
		Else
			FieldName = Attribute.Name;
			FieldSynonym = Attribute.Synonym
		EndIf;
		
		DescriptionOfRegisterField = DescriptionOfDataSourceField(Attribute.Name, FieldSynonym, Attribute.Type);
		ReflectionParameters.AttributesDetails1.Insert(FieldName, DescriptionOfRegisterField);
		
		If Attribute.Name = "RowID" Then
			ReflectionParameters.DataPathRowId = Attribute.Name;
		ElsIf Attribute.Name = "ReversingEntry" Then
			ReflectionParameters.DataPathIsStorno = Attribute.Name;
		EndIf;
	EndDo;
	
	If Not RegistrarIsAttribute Then
		DescriptionOfRegisterField = DescriptionOfDataSourceField(
			RegisterMetadata.StandardAttributes.Recorder.Name,
			RegisterMetadata.StandardAttributes.Recorder.Synonym,
			RegisterMetadata.StandardAttributes.Recorder.Type);
		ReflectionParameters.AttributesDetails1.Insert("Recorder", DescriptionOfRegisterField);
	EndIf;
	
EndProcedure

// Constructor of the description of the register field - the source of ExtDimension or selection of Register Records
//
// Parameters:
//  DataPath - String - Full path to the source subconto field
//  Title - String - The header of the source field of the subconto
//  Type - TypeDescription - The type of data that is stored in the field
//
// Returns:
// 	Structure - LongDesc:
// 		* DataPath - String - Full path to the source subconto field
// 		* Title - String - The header of the source field of the subconto
// 		* Type - TypeDescription - The type of data that is stored in the field
//
Function DescriptionOfDataSourceField(DataPath = "", Title = "", Type = Undefined) Export
	
	Return New Structure(
		"DataPath, Title, Type",
		DataPath,
		Title,
		?(Type = Undefined, New TypeDescription(), Type));
	
EndFunction

// Returns the string-text of the selection of the HFC value of the item from the registers Revenue and Cost of sales and Cost of goods
//
// Parameters:
//  SourceAlias - String - alias of the data source in the request
//
// Returns:
//  String - sample text of the HFC value of the nomenclature
//
Function HFCProductSampleField(SourceAlias = Undefined) Export
	
	If SourceAlias = Undefined Then
		SourceAlias = DefaultDataSourceAlias();
	EndIf;
	
	HFCSamplingField = "CASE
	|		WHEN SourceAlias.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN SourceAlias.ItemsLocationAttributes.Products.FinancialAccountingGroup
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups AND SourceAlias.InventoryOwnerAttribute <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|			THEN ISNULL(SourceAlias.InventoryOwnerAttribute.FinancialAccountingGroup, VALUE(Catalog.InventoryAccountingGroups.EmptyRef))
	|		ELSE SourceAlias.ItemsLocationAttributes.Products.FinancialAccountingGroup
	|	END";
	
	HFCSamplingField = StrReplace(HFCSamplingField, "SourceAlias", SourceAlias);
	
	Return HFCSamplingField;
	
EndFunction

// Returns a description of primitive data types
//
// Returns:
//  TypeDescription
//
Function DescriptionOfPrimitiveTypes() Export
	
	Return New TypeDescription("String, Number, Date, Boolean, Type, Undefined, UUID");
	
EndFunction

// Recursively copies the data layout selection from the source to the receiver with the addition of a prefix and/or postfix
// to the name of the data layout field.
//
// Parameters:
//  FilterReceiver - DataCompositionFilter - the selection to which the selection elements are copied
//  FilterSource - DataCompositionFilter - the selection from which the selection elements are copied
//  Prefix - String - Symbols added to the left to the name of the data layout field
//  Postfix - String - Symbols added to the right of the data layout field name.
//
Procedure CopyDataCompositionFilter(FilterReceiver, FilterSource, Prefix = "", Postfix = "") Export
	
	For Each SourceSelectionElement In FilterSource.Items Do
		TypeOfSelectionElement = TypeOf(SourceSelectionElement);
		ReceiverSelectionElement = FilterReceiver.Items.Add(TypeOfSelectionElement);
		If TypeOfSelectionElement = Type("DataCompositionFilterItem") Then
			DataPath = String(SourceSelectionElement.LeftValue);
			If Not IsBlankString(Prefix) Or Not IsBlankString(Postfix) Then
				DataPathParts = StrSplit(DataPath, ".");
				DataPathParts[0] = Prefix + DataPathParts[0] + Postfix;
				DataPath = StrConcat(DataPathParts, ".");
			EndIf;
			FillPropertyValues(ReceiverSelectionElement, SourceSelectionElement,, "LeftValue");
			ReceiverSelectionElement.LeftValue = New DataCompositionField(DataPath);
		Else
			FillPropertyValues(ReceiverSelectionElement, SourceSelectionElement);
			CopyDataCompositionFilter(ReceiverSelectionElement, SourceSelectionElement, Prefix, Postfix);
		EndIf;
	EndDo;
	
EndProcedure

// Returns the names of the balance fields of data sources - Accumulation registers of operational accounting
// used for communication between records and the formation of correspondence.
// 
// Returns:
//  Array of String
//
Function BalancedFieldsOfDataSources() Export
	
	BalancedFields = New Array();
	BalancedFields.Add("Period");
	BalancedFields.Add("Recorder");
	BalancedFields.Add("Organization");
	BalancedFields.Add("FinRecordID");
	BalancedFields.Add("BusinessTransactionSetting");
	BalancedFields.Add("ReversingEntry");
	
	Return BalancedFields;
	
EndFunction

#EndRegion

#Region Internal

// Adds the Attributes of the measurement keys of analytics to the description of the Accumulation register
//
// Parameters:
//  DimensionsDetails - Structure of KeyAndValue - ExtDimension filling Sources:
//   * Key - String - Name of the dimension attribute-the analytics key
//   * Value - See DescriptionOfDataSourceField
//	RegisterMetadata - MetadataObjectAccumulationRegister - Metadata of the accumulation register
//
Procedure AddCompositionOfAnalyticsKeysToDescriptionOfMeasurements(DimensionsDetails, RegisterMetadata) Export
	
	TypesOfAnalyticsKeys = New Array();
	TypesOfAnalyticsKeys.Add(Type("CatalogRef.KeysForLotVendorAttributes"));
	TypesOfAnalyticsKeys.Add(Type("CatalogRef.InventoryLocationAttributeKeys"));
	TypesOfAnalyticsKeys.Add(Type("CatalogRef.DimensionKeysOfAccountingByPartners"));
	
	For Each TypeOfAnalyticsKey In TypesOfAnalyticsKeys Do
		For Each Dimension In RegisterMetadata.Dimensions Do
			If StrStartsWith(Dimension.Name, "Delete") Then
			ElsIf Dimension.Type.ContainsType(TypeOfAnalyticsKey) Then
				AnalyticsKeyMetadata = Metadata.FindByType(TypeOfAnalyticsKey);
				For Each Attribute In AnalyticsKeyMetadata.Attributes Do
					If Not StrStartsWith(Attribute.Name, "Delete") Then
						DescriptionOfAnalyticsSource = DescriptionOfDataSourceField();
						DescriptionOfAnalyticsSource.DataPath = StrTemplate("%1.%2", Dimension.Name, Attribute.Name);
						DescriptionOfAnalyticsSource.Title = StrTemplate("%1 (%2)", Attribute.Synonym, Dimension.Synonym);
						DescriptionOfAnalyticsSource.Type = Attribute.Type;
						DimensionsDetails.Insert(StrTemplate("%1_%2", Dimension.Name, Attribute.Name), DescriptionOfAnalyticsSource);
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

// Returns the structure of parameters to be Transferred to the offline calculation procedure.
// 
// Returns:
//  Structure - LongDesc:
//   * EndDate - Date - The end date of the calculations
//   * DocumentsForSettlement - Array of DocumentRef - Documents whose Registering Records need to be completed offline
//   * ThreadsCount - Number - Number of document processing sessions running simultaneously
//   * RecalculateSpeedRegisters - Boolean - A sign of the need to recalculate the Registered Records of the circulating registers
//
Function ParametersForOfflineCalculations() Export
	
	Parameters = New Structure();
	Parameters.Insert("EndDate", '00010101');
	Parameters.Insert("DocumentsForSettlement", New Array());
	Parameters.Insert("ThreadsCount", 1);
	Parameters.Insert("RecalculateSpeedRegisters", False);
	Parameters.Insert("JobKind", Catalogs.BackdateJobKinds.EmptyRef());
	
	Return Parameters;
	
EndFunction

// Performs the launch of the procedures for the completion of the Register Records of documents by registers
// 
// Parameters:
//  ExecutionParameters - See ParametersForOfflineCalculations
//
Procedure PerformOfflineCalculations(ExecutionParameters) Export
	
	CalculationsProcedures = New ValueTable();
	CalculationsProcedures.Columns.Add("MethodName", Common.StringTypeDetails(250));
	CalculationsProcedures.Columns.Add("MultiThreadedExecution", New TypeDescription("Boolean"));
	CalculationsProcedures.Columns.Add("AdditionalParameters", New TypeDescription("Structure"));
	
	If GetFunctionalOption("NewOnlineARAPAccounting") And ExchangePlans.MasterNode() = Undefined
		And ValueIsFilled(ExecutionParameters.JobKind) Then
		BackdateJobQueue.CompleteTasksInNonOperationalQueueBasedOnListOfDocuments(
			ExecutionParameters.DocumentsForSettlement, ExecutionParameters.JobKind);
	Else
		CalculationProcedure_ = CalculationsProcedures.Add();
		CalculationProcedure_.MethodName = "CalculateDocumentAmountsInAccountingCurrencies";
		CalculationProcedure_.MultiThreadedExecution = True;
		CalculationProcedure_.AdditionalParameters.Insert("RecalculateSpeedRegisters", ExecutionParameters.RecalculateSpeedRegisters);
	EndIf;
	
	CalculationProcedure_ = CalculationsProcedures.Add();
	CalculationProcedure_.MethodName = "ToFormRegisterRecordsForVna";
	CalculationProcedure_.MultiThreadedExecution = False;
	
	CalculationProcedure_ = CalculationsProcedures.Add();
	CalculationProcedure_.MethodName = "ReflectDocumentsInVATAccounting";
	CalculationProcedure_.MultiThreadedExecution = True;
	
	For Each CalculationProcedure_ In CalculationsProcedures Do
		PerformOfflineCalculation(ExecutionParameters, CalculationProcedure_);
	EndDo;
	
EndProcedure

// Returns a condition string in the query language based on the selection description passed as a selection
// of data layout, structure, matching, array, or fixed array.
// The selection elements transferred in the structure or compliance are added in the condition by "And".
// The selection elements passed in an array or a fixed array are added to the condition by "OR".
// 
// Parameters:
//  Filterdata_ - DataCompositionFilter, Array of Structure, Structure, Map - LongDesc:
//  	* Key - String - The path to the data on which the selection is superimposed
//  	* Value - Arbitrary - The value of superimposed selection
//  QueryOptions - Structure - query parameters to which selection values that cannot be described in the query language will be added
//  SourceAlias - String - alias of the data source in the request
//
// Returns:
//  String - the text of the selection criteria in the query language, enclosed in brackets
//
Function DataSelectionConditionString(Filterdata_, QueryOptions = Undefined, SourceAlias = Undefined) Export
	
	TypeOfDataSelection = TypeOf(Filterdata_);
	EncloseInBrackets = False;
	
	ThisIsLogicalMultiplication = TypeOfDataSelection = Type("Structure")
		Or TypeOfDataSelection = Type("Map")
		Or TypeOfDataSelection = Type("DataCompositionFilter")
		Or (TypeOfDataSelection = Type("DataCompositionFilterItemGroup")
		And Filterdata_.GroupType = DataCompositionFilterItemsGroupType.AndGroup);
	
	ThisIsLogicalAddition = TypeOfDataSelection = Type("Array")
		Or TypeOfDataSelection = Type("FixedArray")
		Or (TypeOfDataSelection = Type("DataCompositionFilterItemGroup")
		And Filterdata_.GroupType = DataCompositionFilterItemsGroupType.OrGroup);
	
	IsFilterItem = TypeOfDataSelection = Type("KeyAndValue")
		Or TypeOfDataSelection = Type("DataCompositionFilterItem");
	
	If ThisIsLogicalMultiplication Then
		If TypeOfDataSelection = Type("Structure")
		 Or TypeOfDataSelection = Type("Map") Then
			FilterItems1 = Filterdata_;
		Else
			FilterItems1 = Filterdata_.Items;
		EndIf;
		
		LinesAnd = New Array();
		For Each FilterElement In FilterItems1 Do
			LinesAnd.Add(DataSelectionConditionString(FilterElement, QueryOptions, SourceAlias));
		EndDo;
		
		ConditionString = StrConcat(LinesAnd, " AND "); //@Query-part
		EncloseInBrackets = True;
	ElsIf ThisIsLogicalAddition Then
		If TypeOfDataSelection = Type("Array")
		 Or TypeOfDataSelection = Type("FixedArray") Then
			FilterItems1 = Filterdata_;
		Else
			FilterItems1 = Filterdata_.Items;
		EndIf;
		
		LinesOr = New Array();
		For Each FilterElement In FilterItems1 Do
			LinesOr.Add(DataSelectionConditionString(FilterElement, QueryOptions, SourceAlias));
		EndDo;
		
		ConditionString = StrConcat(LinesOr, " OR "); //@Query-part
		EncloseInBrackets = True;
	ElsIf IsFilterItem Then
		If TypeOfDataSelection = Type("KeyAndValue") Then
			DataPath = Filterdata_.Key;
			FilterValue = Filterdata_.Value;
			ThisIsInversion = False;
		Else
			DataPath = String(Filterdata_.LeftValue);
			FilterValue = Filterdata_.RightValue;
			ThisIsInversion = Filterdata_.ComparisonType = DataCompositionComparisonType.NotEqual
				Or Filterdata_.ComparisonType = DataCompositionComparisonType.NotInList;
		EndIf;
		
		ValueSelectionString = ValueSelectionString(FilterValue);
		IsParameter = StrStartsWith(ValueSelectionString, "Parameter");
		IsCollection = TypeOf(FilterValue) = Type("Array")
			Or TypeOf(FilterValue) = Type("ValueList");
		
		If IsParameter Then
			If QueryOptions <> Undefined Then
				QueryOptions.Insert(ValueSelectionString, FilterValue);
			Else
				ExclusionTexts = New Array();
				ExclusionTexts.Add(NStr("vi = 'Không thể chuyển đổi giá trị thành biểu thức truy vấn.';
										|ru = 'Значение не может быть преобразовано в выражение запроса.';
										|en = 'The value cannot be converted to a query expression.'; fa = 'The value cannot be converted to a query expression.';
										|it = 'Il valore non può essere modificato in espressione di query.';
										|pl = 'Wartość nie może być przetworzona w wyrażenie zapytania.';
										|tr = 'Değer, sorgu ifadesine dönüştürülemez.'"));
				ExclusionTexts.Add(NStr("vi = 'Cần chuyển tham số truy vấn.';
										|ru = 'Требуется передача параметров запроса.';
										|en = 'Pass the query parameters.'; fa = 'Pass the query parameters.';
										|it = 'Richiesta trasmissione dei parametri di query.';
										|pl = 'Wymagane jest przekazanie parametrów zapytania.';
										|tr = 'İstek parametrelerinin iletilmesi gerekiyor.'"));
				ExclusionTexts.Add(StrTemplate("(%1)", FilterValue));
				Raise StrConcat(ExclusionTexts, " ");
			EndIf;
		EndIf;
		
		StringParts1 = New Array();
		StringParts1.Add(?(ThisIsInversion, "NOT ", "")); //@Query-part
		StringParts1.Add(DataPathWithSourceAlias(DataPath, SourceAlias));
		StringParts1.Add(?(IsCollection, " IN (", " = ")); //@Query-part
		StringParts1.Add(?(IsParameter, "&", "")); //@Query-part
		StringParts1.Add(ValueSelectionString);
		StringParts1.Add(?(IsCollection, ")", "")); //@Query-part
		
		If ThisIsInversion And StrOccurrenceCount(DataPath, ".") > 1 Then
			StringParts1.Add(" OR "); //@Query-part
			StringParts1.Add(DataPathWithSourceAlias(DataPath, SourceAlias));
			StringParts1.Add(" IS NULL"); //@Query-part
			EncloseInBrackets = True;
		EndIf;
		
		ConditionString = StrConcat(StringParts1);
	EndIf;
	
	If EncloseInBrackets Then
		ConditionString = "(" + ConditionString + ")";
	EndIf;
	
	Return ConditionString;
	
EndFunction

// Returns the alias of the data source in the default request.
// Specifying source aliases is mandatory when selecting from temporary tables.
// 
// Returns:
// 	String - alias of the data source in the request
//
Function DefaultDataSourceAlias() Export
	
	Return "RegisterTable";
	
EndFunction

// Returns the names of the available data source fields.
// 
// Parameters:
//  DescriptionOfSourceFields - Structure of KeyAndValue - LongDesc:
//   * Key - String - The name of the register dimension, the name of the Attribute of the dimension - the analytics key, or the name of the register Attribute
//   * Value - See DescriptionOfDataSourceField
//  
// Returns:
//  Array of String - names of available data source fields
//
Function AvailableDataSourceFields(DescriptionOfSourceFields) Export
	
	AvailableFields = New Array();
	
	For Each KeyAndValue In DescriptionOfSourceFields Do
		DataPathParts = StrSplit(KeyAndValue.Value.DataPath, ".");
		SourceFieldName2 = DataPathParts[0];
		
		If AvailableFields.Find(SourceFieldName2) = Undefined Then
			AvailableFields.Add(SourceFieldName2);
		EndIf;
	EndDo;
	
	Return AvailableFields;
	
EndFunction

// Returns an array of document names that are not used when retrieving financial register data
// 
// Returns:
// 	Array of String - names of unused documents
//
Function NamesOfUnusedDocuments() Export
	
	DocumentNames = New Array();
	MetadataDocuments = Metadata.Documents;
	
	DocumentNames.Add(MetadataDocuments.OBEntry.Name);
	DocumentNames.Add(MetadataDocuments.RegisterAdjustment.Name);
	
	FinancialAccountingByBalanceSheetRegisterDataLocalization.AddUnusedDocumentsNames(DocumentNames);
	
	Return DocumentNames;
	
EndFunction

// Returns an array of names of accumulation registers, the correspondence of which always takes into account indicators
//
// Returns:
//  Array of String - names of accumulation registers
//
Function RegistersWithSelectionByIndicators() Export
	
	RegisterNames = New Array();
	RegisterNames.Add(Metadata.AccumulationRegisters.RevenueAndCOGS.Name);
	RegisterNames.Add(Metadata.AccumulationRegisters.InventoryCost.Name);
	RegisterNames.Add(Metadata.AccumulationRegisters.RegisterRecordsByExcises.Name);
	
	Return RegisterNames;
	
EndFunction

// Returns descriptions of data paths for common fields of balance registers
//
// Parameters:
//  MotionReflectionParameters - See ParametersForReflectingRegisteredRecordsInFinancialAccounting
//  SourceAlias - Undefined, String - name of the balance register table
//
// Returns:
//  Structure:
//   *Key - String - field name
//   *Value - String - the path to the field data
Function DescriptionsOfPathsToRegisterFieldData(MotionReflectionParameters, SourceAlias = Undefined) Export
		
	PathsToFieldData = New Structure;
	
	If IsBlankString(MotionReflectionParameters.PathToDataDivision) Then
		PathsToFieldData.Insert("Department", ValueSelectionString(Catalogs.BusinessStructure.EmptyRef()));
	Else
		PathsToFieldData.Insert("Department", DataPathWithSourceAlias(MotionReflectionParameters.PathToDataDivision, SourceAlias));
	EndIf;

	If IsBlankString(MotionReflectionParameters.PathToDataLineOfBusiness) Then
		PathsToFieldData.Insert("LineOfBusiness", ValueSelectionString(Catalogs.LinesOfBusiness.EmptyRef()));
	Else
		PathsToFieldData.Insert("LineOfBusiness", DataPathWithSourceAlias(MotionReflectionParameters.PathToDataLineOfBusiness, SourceAlias));
	EndIf;

	PathsToFieldData.Insert("SettingUpBusinessTransaction", DataPathWithSourceAlias(MotionReflectionParameters.DataPathSettingUpHouseholdOperations, SourceAlias));

	If IsBlankString(MotionReflectionParameters.DataPathDopSettingUpHouseholdOfOperation) Then
		PathsToFieldData.Insert("AdditionalSetupOfHouseholdOperations", PathsToFieldData.SettingUpBusinessTransaction);
	Else
		PathsToFieldData.Insert("AdditionalSetupOfHouseholdOperations", DataPathWithSourceAlias(MotionReflectionParameters.DataPathDopSettingUpHouseholdOfOperation, SourceAlias));
	EndIf;

	If IsBlankString(MotionReflectionParameters.DataPathCurrency) Then
		PathsToFieldData.Insert("Currency", ValueSelectionString(Catalogs.Currencies.EmptyRef()));
	Else
		PathsToFieldData.Insert("Currency", DataPathWithSourceAlias(MotionReflectionParameters.DataPathCurrency, SourceAlias));
	EndIf;

	If IsBlankString(MotionReflectionParameters.DataPathIsStorno) Then
		PathsToFieldData.Insert("PropsStorno", ValueSelectionString(False));
	Else
		PathsToFieldData.Insert("PropsStorno", DataPathWithSourceAlias(MotionReflectionParameters.DataPathIsStorno, SourceAlias));
	EndIf;

	PathsToFieldData.Insert("Recorder", DataPathWithSourceAlias(MotionReflectionParameters.DataPathLogger, SourceAlias));
	PathsToFieldData.Insert("Organization", DataPathWithSourceAlias(MotionReflectionParameters.DataPathOrganization, SourceAlias));
	
	If IsBlankString(MotionReflectionParameters.PathToDataVATActivity) Then
		PathsToFieldData.Insert("VATActivityType", ValueSelectionString(Enums.VATTaxationTypes.EmptyRef()));
	Else
		PathsToFieldData.Insert("VATActivityType", DataPathWithSourceAlias(MotionReflectionParameters.PathToDataVATActivity, SourceAlias));
	EndIf;
	
	Return PathsToFieldData;

EndFunction

#Region TextsOfCorrespondenceGenerationRequests

// Returns a structure for setting the parameter values for requesting financial register data.
// 
// Returns:
//  Structure:
//   * StartDate - Date - start date of the report creation
//   * EndDate - Date - end date of the report creation
//   * Recorder - DocumentRef, Array of DocumentRef - selection by document or documents
//   * Organization - CatalogRef.Companies, Array of CatalogRef.Companies - selection by organization or organizations
//   * AccountingObjectDr - ChartOfCharacteristicTypesRef.AssetLiabilityItems - selection by debit accounting object
//   * AccountingObjectCr - ChartOfCharacteristicTypesRef.AssetLiabilityItems - selection by credit accounting object
//   * TypeOfRegistrar - Array of Type - selection by collections of different types of documents
//   * AdditionalSelection - DataCompositionFilter - selection of fixed linker settings for data layout settings
//
Function ParametersForRequestingFinancialRegisterData() Export
	
	QueryOptions = New Structure();
	
	QueryOptions.Insert("StartDate", '00010101');
	QueryOptions.Insert("EndDate", '00010101');
	QueryOptions.Insert("Recorder", Undefined);
	QueryOptions.Insert("Organization", Undefined);
	QueryOptions.Insert("AccountingObjectDr", Undefined);
	QueryOptions.Insert("AccountingObjectCr", Undefined);
	QueryOptions.Insert("TypeOfRegistrar", Undefined);
	QueryOptions.Insert("AdditionalSelection", Undefined);
	
	Return QueryOptions;
	
EndFunction

// Returns the request used in generating balance register correspondence
//
// Parameters:
//  QueryOptions - Structure - initial request parameters
//  TempTablesManager - TempTablesManager
//
// Returns:
//  Query
//
Function RequestingDataFromFinancialRegisters(QueryOptions, TempTablesManager) Export
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	
	For Each KeyAndValue In QueryOptions Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	InitialTemporaryTables = New Array();
	For Each TempTable In TempTablesManager.Tables Do
		InitialTemporaryTables.Add(TempTable.FullName);
	EndDo;
	Query.SetParameter("InitialTemporaryTables", InitialTemporaryTables);
	
	Query.SetParameter("ManagementAccountingCurrency", SettingsValueCached.ManagementAccountingCurrency());
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("BusinessTransactionsWithoutAccountingInForeignCurrency", BusinessTransactionsExcludingForeignCurrency());
	Query.SetParameter("TypesOfTaxationExcludingVAT", TypesOfTaxationExcludingVAT());
	Query.SetParameter("TypesOfResidueEntryDocuments", TypesOfResidueEntryDocuments());
	Query.SetParameter("TypesOfRetailSalesDocuments", TypesOfRetailSalesDocuments());
	Query.SetParameter("TypesOfRetailReturnsDocuments", TypesOfRetailReturnsDocuments());
	Query.SetParameter("TypesOfDebtOffsetDocuments", TypesOfDebtOffsetDocuments());
	
	TypesOfRegistrarsOfServiceAccountingObjects = Common.CopyRecursive(Query.Parameters.TypesOfResidueEntryDocuments);
	CommonClientServer.SupplementArray(TypesOfRegistrarsOfServiceAccountingObjects, Query.Parameters.TypesOfRetailSalesDocuments);
	CommonClientServer.SupplementArray(TypesOfRegistrarsOfServiceAccountingObjects, Query.Parameters.TypesOfRetailReturnsDocuments);
	CommonClientServer.SupplementArray(TypesOfRegistrarsOfServiceAccountingObjects, Query.Parameters.TypesOfDebtOffsetDocuments);
	Query.SetParameter("TypesOfRegistrarsOfServiceAccountingObjects", TypesOfRegistrarsOfServiceAccountingObjects);
	Query.SetParameter("NameOfRegisterOfServiceAccountingObjects", NameOfRegisterOfServiceAccountingObjects());
	
	CorDataSources = New ValueTable();
	CorDataSources.Columns.Add("AccountingObject", New TypeDescription("ChartOfCharacteristicTypesRef.AssetLiabilityItems"));
	CorDataSources.Columns.Add("CorDataSource", Common.StringTypeDetails(150)); // name of the register corresponding to the accounting object
	CorDataSources.Columns.Add("Id", Common.StringTypeDetails(50)); // id of all registers corresponding to the accounting object
	CorDataSources.Columns.Add("CorID", Common.StringTypeDetails(50)); // id for grouping all corresponding registers
	Query.SetParameter("CorDataSources", CorDataSources);
	
	Query.SetParameter("VATAccountingObjects", New Array());
	Query.SetParameter("AccountingObjectsWithVAT", New Array());
	
	Query.SetParameter("RegistersWithoutManSum", New Array());
	Query.SetParameter("RegistersWithoutSumLocal", New Array());
	Query.SetParameter("AnalyticsSampleRegisters", New Structure());
	
	Query.SetParameter("Dr", "Dr");
	Query.SetParameter("Cr", "Cr");
	
	Query.SetParameter("ComplexTransactionsWithIndicationOfCorSources", False);
	
	Query.SetParameter("RestoreCalculationsForStorno", False);
	Query.SetParameter("RegistersOfRecoveryOfCalculationsOnStorno", RegistersOfRecoveryOfCalculationsOnStorno());
	
	RegisterNameOtherAssetsLiabilities = Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name;
	Query.SetParameter("RegisterNameOtherAssetsLiabilities", RegisterNameOtherAssetsLiabilities);
	
	Query.SetParameter("RegistersAreReplacedStornoByReverse", New Array());
	Query.SetParameter("ReverseToReverseReplacementRegisters", New Array());
	
	MoneyAmountQualifiers = Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type.NumberQualifiers;
	Query.SetParameter("LengthOfSum", MoneyAmountQualifiers.Digits);
	Query.SetParameter("SumAccuracy", MoneyAmountQualifiers.FractionDigits);
	
	Query.SetParameter("LengthOfQuantity", 15);
	Query.SetParameter("QuantityAccuracy", 3);
	
	Query.SetParameter("TableOfCorrespondenceOfRegisteredRecordsOfRegisters", "TTMovementRegistersDebitCredit");
	Query.SetParameter("TableOfDetailedRegisteredRecordsWithDebitTotals", "TTDetailedRegisteredRecordsWithDebitTotals");
	Query.SetParameter("TableOfDetailedRegisteredRecordsWithCreditTotals", "TTDetailedRegisteredRecordsWithCreditTotals");
	
	Return Query;
	
EndFunction

Procedure DestroyTemporaryTables(Query, QueriesTexts) Export
	
	InitialTemporaryTables = Query.Parameters.InitialTemporaryTables; // Array -
	
	For Each TempTable In Query.TempTablesManager.Tables Do
		TempTableName = TempTable.FullName;
		If InitialTemporaryTables.Find(TempTableName) = Undefined Then
			AddRequestToDeleteTemporaryTable(QueriesTexts, TempTableName);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region GeneralPurposeQueryTexts

Procedure ReplaceNamesOfTablesAndFieldsOfRegisteredRecords(QueryText, DrCr) Export
	
	If DrCr = "Dr" Then
		ThisIsDrCr = "ThisIsDebit";
		ThisIsCorDrCr = "ThisIsLoan";
		AccountingObjectDrCr = "AccountingObjectDr";
		AccountingObjectBalancedDrCr = "AccountingObjectCr";
		TTRegisteredRecordsDrCr = "TTDebit";
		TTMotionCorDrCr = "TTCredit";
		TTRegisteredRecordsWithDrCrTotals = "TTRegisteredRecordsWithDebitTotals";
		TTRegisterRegisteredRecordsDrCr = "TTMovementRegistersDebit";
		TTFoldedRegisteredRecordsDrCr = "TTCollapsedRegisteredRecordsDebit";
		TTMovementRegistersReverseDrCr = "TTRegisterRegisteredRecordsReverseDebit";
		TTCorMovementRegistersReverseDrCr = "TTMovementRegistersReverseCredit";
		TTCtTransactionIdsDrCr = "TTTransactionIDsCredit";
	Else
		ThisIsDrCr = "ThisIsLoan";
		ThisIsCorDrCr = "ThisIsDebit";
		AccountingObjectDrCr = "AccountingObjectCr";
		AccountingObjectBalancedDrCr = "AccountingObjectDr";
		TTRegisteredRecordsDrCr = "TTCredit";
		TTMotionCorDrCr = "TTDebit";
		TTRegisteredRecordsWithDrCrTotals = "TTRegisteredRecordsWithCreditTotals";
		TTRegisterRegisteredRecordsDrCr = "TTMovementRegistersCredit";
		TTFoldedRegisteredRecordsDrCr = "TTRolledUpMotionCredit";
		TTMovementRegistersReverseDrCr = "TTMovementRegistersReverseCredit";
		TTCorMovementRegistersReverseDrCr = "TTRegisterRegisteredRecordsReverseDebit";
		TTCtTransactionIdsDrCr = "TTTransactionIDsDebit";
	EndIf;
	
	QueryText = StrReplace(QueryText, "ThisIsDrCr", ThisIsDrCr);
	QueryText = StrReplace(QueryText, "ThisIsCorDrCr", ThisIsCorDrCr);
	QueryText = StrReplace(QueryText, "AccountingObjectDrCr", AccountingObjectDrCr);
	QueryText = StrReplace(QueryText, "AccountingObjectBalancedDrCr", AccountingObjectBalancedDrCr);
	QueryText = StrReplace(QueryText, "TTRegisteredRecordsDrCr", TTRegisteredRecordsDrCr);
	QueryText = StrReplace(QueryText, "TTMotionCorDrCr", TTMotionCorDrCr);
	QueryText = StrReplace(QueryText, "TTRegisteredRecordsWithDrCrTotals", TTRegisteredRecordsWithDrCrTotals);
	QueryText = StrReplace(QueryText, "TTRegisterRegisteredRecordsDrCr", TTRegisterRegisteredRecordsDrCr);
	QueryText = StrReplace(QueryText, "TTFoldedRegisteredRecordsDrCr", TTFoldedRegisteredRecordsDrCr);
	QueryText = StrReplace(QueryText, "TTMovementRegistersReverseDrCr", TTMovementRegistersReverseDrCr);
	QueryText = StrReplace(QueryText, "TTCorMovementRegistersReverseDrCr", TTCorMovementRegistersReverseDrCr);
	QueryText = StrReplace(QueryText, "TTCtTransactionIdsDrCr", TTCtTransactionIdsDrCr);
	
EndProcedure

Procedure AddRequestToDeleteTemporaryTable(QueriesTexts, TableName) Export
	
	If TypeOf(TableName) = Type("Array") Then
		For Each TableToDelete In TableName Do
			AddRequestToDeleteTemporaryTable(QueriesTexts, TableToDelete);
		EndDo;
	Else
		QueriesTexts.Add("
		|DROP " + TableName);
	EndIf;
	
EndProcedure

Function HasRecordsInTemporaryTable(Query, QueriesTexts, TableName) Export
	
	QueryText = "
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	&TableName AS TempTable
	|";
	
	QueryText = StrReplace(QueryText, "&TableName", TableName);
	QueriesTexts.Add(QueryText);
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	Results = Query.ExecuteBatch();
	QueriesTexts.Clear();
	
	Return Not Results[Results.UBound()].IsEmpty();
	
EndFunction

#EndRegion

#Region TextsOfRequestsToRestorePaymentsForStorno

Function RegistersOfRecoveryOfCalculationsOnStorno() Export
	
	RegisterNames = New Array();
	RegisterNames.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Name);
	RegisterNames.Add(Metadata.AccumulationRegisters.VendorsARAPAccountingByDueDates.Name);
	
	Return RegisterNames;
	
EndFunction

#EndRegion

#Region TextsOfRequestsForDistributionOfAmountsAndQuantities

Procedure AddTableOfSumRoundingErrors(QueriesTexts, PlacementTable, DistributedResource_, DistributedResource) Export
	
	QueryText = "
	|SELECT
	|	DistributionOfUnbalancedAssets.RecNo AS RecNo,
	|	DistributionOfUnbalancedAssets.ComplexRecordNumber AS ComplexRecordNumber,
	|	MAX(DistributionOfUnbalancedAssets.DistributedResource_) - SUM(DistributionOfUnbalancedAssets.DistributedResource) AS RoundingError,
	|	MAX(CASE
	|		WHEN DistributionOfUnbalancedAssets.ThereIsSumDistribution
	|			THEN DistributionOfUnbalancedAssets.DistributedResource
	|		ELSE 0
	|	END) AS MaximumDistributedResource
	|INTO TTRoundingError
	|FROM
	|	TTDistributionOfUnbalancedAssets AS DistributionOfUnbalancedAssets
	|WHERE
	|	DistributionOfUnbalancedAssets.ComplexEntry
	|	AND DistributionOfUnbalancedAssets.Currency <> VALUE(Catalog.Currencies.EmptyRef)
	|GROUP BY
	|	DistributionOfUnbalancedAssets.RecNo,
	|	DistributionOfUnbalancedAssets.ComplexRecordNumber
	|HAVING
	|	MAX(DistributionOfUnbalancedAssets.ThereIsSumDistribution) = TRUE
	|	AND MAX(DistributionOfUnbalancedAssets.DistributedResource_) <> SUM(DistributionOfUnbalancedAssets.DistributedResource)
	|INDEX BY
	|	RecNo,
	|	ComplexRecordNumber
	|";
	
	ReplaceNamesOfTablesAndAllocationResources(QueryText, PlacementTable, DistributedResource_, DistributedResource);
	ReplaceNamesOfUnbalancedDistributionFields(QueryText, DistributedResource);
	
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	RoundingErrors.RecNo AS RecNo,
	|	RoundingErrors.RoundingError AS RoundingError,
	|	MIN(DistributionOfUnbalancedAssets.LineNumber) AS LineNumber
	|INTO PlacementTable
	|FROM
	|	TTRoundingError AS RoundingErrors
	|	INNER JOIN TTDistributionOfUnbalancedAssets AS DistributionOfUnbalancedAssets
	|		ON RoundingErrors.RecNo = DistributionOfUnbalancedAssets.RecNo
	|		 AND RoundingErrors.ComplexRecordNumber = DistributionOfUnbalancedAssets.ComplexRecordNumber
	|		 AND RoundingErrors.MaximumDistributedResource = DistributionOfUnbalancedAssets.DistributedResource
	|GROUP BY
	|	RoundingErrors.RecNo,
	|	RoundingErrors.RoundingError
	|INDEX BY
	|	RecNo,
	|	LineNumber
	|";
	
	ReplaceNamesOfTablesAndAllocationResources(QueryText, PlacementTable, DistributedResource_, DistributedResource);
	ReplaceNamesOfUnbalancedDistributionFields(QueryText, DistributedResource);
	
	QueriesTexts.Add(QueryText);
	
	AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRoundingError");
	
EndProcedure

Procedure AddRoundingErrorTable(QueriesTexts, PlacementTable, DistributedResource_, DistributedResource) Export
	
	QueryText = "
	|SELECT
	|	DistributionOfUnbalancedAssets.RecNo AS RecNo,
	|	DistributionOfUnbalancedAssets.ComplexRecordNumber AS ComplexRecordNumber,
	|	MAX(DistributionOfUnbalancedAssets.DistributedResource_) - SUM(DistributionOfUnbalancedAssets.DistributedResource) AS RoundingError,
	|	MAX(DistributionOfUnbalancedAssets.DistributedResource) AS MaximumDistributedResource
	|INTO TTRoundingError
	|FROM
	|	TTDistributionOfUnbalancedAssets AS DistributionOfUnbalancedAssets
	|WHERE
	|	DistributionOfUnbalancedAssets.ThereIsQuantityDistribution
	|GROUP BY
	|	DistributionOfUnbalancedAssets.RecNo,
	|	DistributionOfUnbalancedAssets.ComplexRecordNumber
	|HAVING
	|	MAX(DistributionOfUnbalancedAssets.DistributedResource_) <> SUM(DistributionOfUnbalancedAssets.DistributedResource)
	|INDEX BY
	|	RecNo,
	|	ComplexRecordNumber
	|";
	
	ReplaceNamesOfTablesAndAllocationResources(QueryText, PlacementTable, DistributedResource_, DistributedResource);
	ReplaceNamesOfUnbalancedDistributionFields(QueryText, DistributedResource);
	
	QueriesTexts.Add(QueryText);
		
	QueryText = "
	|SELECT
	|	RoundingErrors.RecNo AS RecNo,
	|	RoundingErrors.RoundingError AS RoundingError,
	|	MIN(DistributionOfUnbalancedAssets.LineNumber) AS LineNumber
	|INTO PlacementTable
	|FROM
	|	TTRoundingError AS RoundingErrors
	|	INNER JOIN TTDistributionOfUnbalancedAssets AS DistributionOfUnbalancedAssets
	|		ON RoundingErrors.RecNo = DistributionOfUnbalancedAssets.RecNo
	|		 AND RoundingErrors.ComplexRecordNumber = DistributionOfUnbalancedAssets.ComplexRecordNumber
	|		 AND RoundingErrors.MaximumDistributedResource = DistributionOfUnbalancedAssets.DistributedResource
	|GROUP BY
	|	RoundingErrors.RecNo,
	|	RoundingErrors.RoundingError
	|INDEX BY
	|	RecNo,
	|	LineNumber
	|";
	
	ReplaceNamesOfTablesAndAllocationResources(QueryText, PlacementTable, DistributedResource_, DistributedResource);
	ReplaceNamesOfUnbalancedDistributionFields(QueryText, DistributedResource);
	
	QueriesTexts.Add(QueryText);
	
	AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRoundingError");
	
EndProcedure

Procedure AddResourceRoundingErrorTable(QueriesTexts, PlacementTable, DistributedResource_, DistributedResource) Export
	
	QueryText = "
	|SELECT
	|	DistributionByMaturityDates.RecNo AS RecNo,
	|	MAX(DistributionByMaturityDates.DistributedResource_) - SUM(DistributionByMaturityDates.DistributedResource) AS RoundingError,
	|	MAX(DistributionByMaturityDates.DistributedResource) AS MaximumDistributedResource
	|INTO TTRoundingError
	|FROM
	|	TTDistributionByMaturityDates AS DistributionByMaturityDates
	|WHERE
	|	DistributionByMaturityDates.ThereIsDistribution
	|GROUP BY
	|	DistributionByMaturityDates.RecNo
	|HAVING
	|	MAX(DistributionByMaturityDates.DistributedResource_) <> SUM(DistributionByMaturityDates.DistributedResource)
	|INDEX BY
	|	RecNo
	|";
	
	ReplaceNamesOfTablesAndAllocationResources(QueryText, PlacementTable, DistributedResource_, DistributedResource);
	
	QueriesTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	RoundingErrors.RecNo AS RecNo,
	|	RoundingErrors.RoundingError AS RoundingError,
	|	MIN(DistributionByMaturityDates.LineNumber) AS LineNumber
	|INTO PlacementTable
	|FROM
	|	TTRoundingError AS RoundingErrors
	|	INNER JOIN TTDistributionByMaturityDates AS DistributionByMaturityDates
	|		ON RoundingErrors.RecNo = DistributionByMaturityDates.RecNo
	|		 AND RoundingErrors.MaximumDistributedResource = DistributionByMaturityDates.DistributedResource
	|GROUP BY
	|	RoundingErrors.RecNo,
	|	RoundingErrors.RoundingError
	|INDEX BY
	|	RecNo,
	|	LineNumber
	|";
	
	ReplaceNamesOfTablesAndAllocationResources(QueryText, PlacementTable, DistributedResource_, DistributedResource);
	
	QueriesTexts.Add(QueryText);
	
	AddRequestToDeleteTemporaryTable(QueriesTexts, "TTRoundingError");
	
EndProcedure

Procedure ReplaceNamesOfTablesAndAllocationResources(QueryText, PlacementTable, DistributedResource_, DistributedResource) Export
	
	QueryText = StrReplace(QueryText, "PlacementTable",  PlacementTable);
	QueryText = StrReplace(QueryText, "DistributedResource_", DistributedResource_);
	QueryText = StrReplace(QueryText, "DistributedResource", DistributedResource);
	
EndProcedure

Procedure ReplaceNamesOfUnbalancedDistributionFields(QueryText, DistributedResource) Export
	
	If DistributedResource = "SumManDr"
	 Or DistributedResource = "SumCurrDr"
	 Or DistributedResource = "SumComplDr"
	 Or DistributedResource = "CountDr" Then
		QueryText = StrReplace(QueryText, "RecNo", "RecNoDr");
		QueryText = StrReplace(QueryText, "ComplexEntry", "ComplexEntryDr");
		QueryText = StrReplace(QueryText, "Currency", "CurrencyDr");
		QueryText = StrReplace(QueryText, "ThereIsSumDistribution", "ThereIsSumDistributionDr");
		QueryText = StrReplace(QueryText, "ThereIsQuantityDistribution", "ThereIsQuantityDistributionDr");
	Else
		QueryText = StrReplace(QueryText, "RecNo", "RecNoCr");
		QueryText = StrReplace(QueryText, "ComplexEntry", "ComplexEntryCr");
		QueryText = StrReplace(QueryText, "Currency", "CurrencyCr");
		QueryText = StrReplace(QueryText, "ThereIsSumDistribution", "ThereIsSumDistributionCr");
		QueryText = StrReplace(QueryText, "ThereIsQuantityDistribution", "ThereIsQuantityDistributionCr");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormationOfRequestParameters

Procedure FillInCorDataSources(QueryOptions, AccountingObjectLine_) Export
	
	If AccountingObjectLine_.CorDataSources.Count() > 0 Then
		CorDataSources = QueryOptions.CorDataSources; // ValueTable -
		SourceID_1 = HashSumOfDataSources(AccountingObjectLine_.CorDataSources, HashFunction.SHA256);
		CorSourceID = HashSumOfDataSources(AccountingObjectLine_.CorDataSources, HashFunction.SHA1);
		
		For Each CorDataSource In AccountingObjectLine_.CorDataSources Do
			NewRow = CorDataSources.Add();
			FillPropertyValues(NewRow, AccountingObjectLine_);
			NewRow.CorDataSource = CorDataSource;
			NewRow.Id = SourceID_1;
			NewRow.CorID = CorSourceID;
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInSourcesWithDueDates(QueryOptions, AccountingObjectLine_, MotionReflectionParameters) Export
	
	SourcesWithDueDates = QueryOptions.SourcesWithDueDates; // ValueTable -
	
	If QueryOptions.AllocationOfLongTermAssetsAndLiabilities
		And MotionReflectionParameters.AllocationOfLongTermAssetsAndLiabilities
		And AccountingObjectLine_.AllocationOfLongTermAssetsAndLiabilities Then
		NewRow = SourcesWithDueDates.Add();
		NewRow.DataSource = AccountingObjectLine_.DataSource;
		NewRow.AccountingObject = AccountingObjectLine_.AccountingObject;
	EndIf;
	
EndProcedure

Procedure FillInSignsOfCorrespondenceAccounting(QueryOptions, AccountingObjectLine_) Export
	
	SignsOfCorrespondenceAccounting = QueryOptions.SignsOfCorrespondenceAccounting; // ValueTable -
	
	For Each SignOfCorrespondenceAccounting In AccountingObjectLine_.SignsOfCorrespondenceAccounting Do
		NewRow = SignsOfCorrespondenceAccounting.Add();
		NewRow.AccountingObject = AccountingObjectLine_.AccountingObject;
		NewRow.CorObjectOfAccounting = SignOfCorrespondenceAccounting.AccountingObject;
		NewRow.AccountingFlag = SignOfCorrespondenceAccounting.AccountingFlag;
		NewRow.Value = SignOfCorrespondenceAccounting.Value;
	EndDo;
	
EndProcedure

Procedure FillInObjectsOfInappropriateValues(QueryOptions, AccountingObjectLine_) Export
	
	ObjectsOfImproperValues = QueryOptions.ObjectsOfImproperValues; // ValueTable -
	
	If QueryOptions.MethodOfAccountingForImproperValues <> Enums.MethodsOfNotOwnedControlledValuesAccounting.NotRecordedOnAccounts
	   And QueryOptions.MethodOfAccountingForImproperValues <> Enums.MethodsOfNotOwnedControlledValuesAccounting.EmptyRef()
	   And AccountingObjectLine_.ImproperValues Then
		NewRow = ObjectsOfImproperValues.Add();
		NewRow.AccountingObject = AccountingObjectLine_.AccountingObject;
	EndIf;
	
EndProcedure

Procedure FillInItemsBasedOnVATAccountingCriteria(QueryOptions, AccountingObjectLine_) Export
	
	VATAccountingObjects = QueryOptions.VATAccountingObjects; // Array -
	AccountingObjectsWithVAT = QueryOptions.AccountingObjectsWithVAT; // Array -
	
	If AccountingObjectLine_.Indicators.Count() = 1 Then
		If AccountingObjectLine_.Indicators[Enums.IndicatorsOfAnalyticalRegisters.VATAmount] <> Undefined Then
			VATAccountingObjects.Add(AccountingObjectLine_.AccountingObject);
		ElsIf AccountingObjectLine_.Indicators[Enums.IndicatorsOfAnalyticalRegisters.AmountIncludingVAT] <> Undefined Then
			AccountingObjectsWithVAT.Add(AccountingObjectLine_.AccountingObject);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormationOfQueryTexts

Procedure ClarifyParametersOfReflectionOfRegisteredRecorded(MotionReflectionParameters, RegisterMetadata) Export
	
	AccumulationRegisterType = Metadata.ObjectProperties.AccumulationRegisterType;
	
	If IsBlankString(MotionReflectionParameters.DebitCondition) Then
		If RegisterMetadata.RegisterType = AccumulationRegisterType.Turnovers Then
			MotionReflectionParameters.DebitCondition = "FALSE";
		ElsIf MotionReflectionParameters.InversionOfRegisteredRecords Then
			MotionReflectionParameters.DebitCondition = "&RecordType = VALUE(AccumulationRecordType.Expense)";
		Else
			MotionReflectionParameters.DebitCondition = "&RecordType = VALUE(AccumulationRecordType.Receipt)";
		EndIf;
	EndIf;
	
	If IsBlankString(MotionReflectionParameters.ConditionCredit) Then
		If RegisterMetadata.RegisterType = AccumulationRegisterType.Turnovers Then
			MotionReflectionParameters.ConditionCredit = "FALSE";
		ElsIf MotionReflectionParameters.InversionOfRegisteredRecords Then
			MotionReflectionParameters.ConditionCredit = "&RecordType = VALUE(AccumulationRecordType.Receipt)";
		Else
			MotionReflectionParameters.ConditionCredit = "&RecordType = VALUE(AccumulationRecordType.Expense)";
		EndIf;
	EndIf;
	
EndProcedure

Procedure ClarifyPropertiesOfAccountingObject(MotionReflectionParameters, AccountingObjectLine_, RegisterMetadata) Export
	
	AccumulationRegisterType = Metadata.ObjectProperties.AccumulationRegisterType;
	
	If AccountingObjectLine_.InversionOfRegisteredRecords And Not MotionReflectionParameters.InversionOfRegisteredRecords
		And RegisterMetadata.RegisterType = AccumulationRegisterType.Balance Then
		If IsBlankString(AccountingObjectLine_.DebitCondition) Then
			AccountingObjectLine_.DebitCondition = "&RecordType = VALUE(AccumulationRecordType.Expense)";
		EndIf;
		
		If IsBlankString(AccountingObjectLine_.ConditionCredit) Then
			AccountingObjectLine_.ConditionCredit = "&RecordType = VALUE(AccumulationRecordType.Receipt)";
		EndIf;
	EndIf;
	
EndProcedure

Function ResourceKeyOfAccountingObject(AccountingObjectLine_) Export
	
	AllResources = New Array();
	
	CommonClientServer.SupplementArray(AllResources, AccountingObjectLine_.ManResources.UnloadColumn("ResourceName"));
	CommonClientServer.SupplementArray(AllResources, AccountingObjectLine_.LocalResources.UnloadColumn("ResourceName"));
	CommonClientServer.SupplementArray(AllResources, AccountingObjectLine_.ShaftResources.UnloadColumn("ResourceName"));
	CommonClientServer.SupplementArray(AllResources, AccountingObjectLine_.ResourcesQuantity.UnloadColumn("ResourceName"));
	
	TMCommonUseClientServer.SortArray(AllResources);
	
	Return StrConcat(AllResources, ",");
	
EndFunction

Function SelectionFieldsBasedOnDescriptionOfAccountingObject() Export
	
	SelectionFields1 = New Array();
	
	SelectionFields1.Add("AccountingObject");
	SelectionFields1.Add("LineOfBusiness");
	SelectionFields1.Add("FinRecordID");
	SelectionFields1.Add("SettingUpBusinessTransaction");
	SelectionFields1.Add("RowID");
	SelectionFields1.Add("SumMan");
	SelectionFields1.Add("SumCompl");
	SelectionFields1.Add("SumCurr");
	SelectionFields1.Add("Count");
	SelectionFields1.Add("ThisIsDebit");
	SelectionFields1.Add("ThisIsLoan");
	SelectionFields1.Add("ThisIsReverseTransaction");
	SelectionFields1.Add("ResourceValueCondition");
	
	Return SelectionFields1;
	
EndFunction

Function RowsOfFieldSelectionsBasedOnDescriptionOfAccountingObject(AccountingObjectRows_, MotionReflectionParameters, QueryOptions, FieldList = Undefined) Export
	
	If FieldList = Undefined Then
		FieldList = StrConcat(SelectionFieldsBasedOnDescriptionOfAccountingObject(), ",");
	EndIf;
	
	FieldsOfAccountingObjectSelection = New Structure(FieldList);
	
	FieldsOfAccountingObjectSelection.AccountingObject = AccountingItemSelectionString(AccountingObjectRows_, QueryOptions);
	
	FieldsOfAccountingObjectSelection.LineOfBusiness = SelectionStringOfAccountingObjectField("PathToDataLineOfBusiness",
		AccountingObjectRows_, MotionReflectionParameters, QueryOptions, Catalogs.LinesOfBusiness.EmptyRef());
	
	FieldsOfAccountingObjectSelection.FinRecordID = SelectionStringOfAccountingObjectField("DataPathRecordFinID",
		AccountingObjectRows_, MotionReflectionParameters, QueryOptions, DocumentsPosting.IDOfUnusedFinRecord());
	
	FieldsOfAccountingObjectSelection.SettingUpBusinessTransaction = SelectionStringOfAccountingObjectField("DataPathSettingUpHouseholdOperations",
		AccountingObjectRows_, MotionReflectionParameters, QueryOptions, Catalogs.BusinessTransactionsSettings.EmptyRef());
	
	FieldsOfAccountingObjectSelection.RowID = SelectionStringOfAccountingObjectField("DataPathRowId",
		AccountingObjectRows_, MotionReflectionParameters, QueryOptions, "");
	
	ManResources = AccountingObjectRows_[0].ManResources;
	LocalResources = AccountingObjectRows_[0].LocalResources;
	ShaftResources = AccountingObjectRows_[0].ShaftResources;
	ResourcesQuantity = AccountingObjectRows_[0].ResourcesQuantity;
	
	ResourceSelectionLines = New Structure(StrConcat(NumericResourceSelectionFields(), ","));
	ResourceSelectionLines.SumMan = ResourceSelectionString(ManResources);
	ResourceSelectionLines.SumCompl = ResourceSelectionString(LocalResources);
	ResourceSelectionLines.SumCurr = ResourceSelectionString(ShaftResources);
	ResourceSelectionLines.Count = ResourceSelectionString(ResourcesQuantity);
	
	ThisIsReverseTransaction = SelectionStringForStornoAttribute(ResourceSelectionLines);
	ConditionsAreNotZero = New Array();
	
	AmountSampleTemplate = "SUM(CASE
	|		WHEN &ThisIsReverseTransaction
	|			THEN -&Resource
	|		ELSE &Resource
	|	END)";
	
	For Each KeyAndValue In ResourceSelectionLines Do
		FieldsOfAccountingObjectSelection[KeyAndValue.Key] = ResourceAmountSelectionString(
			KeyAndValue.Value, AmountSampleTemplate, ThisIsReverseTransaction, ConditionsAreNotZero);
	EndDo;
	
	If ConditionsAreNotZero.Count() = 0 Then
		ConditionsAreNotZero.Add(ValueSelectionString(False));
	EndIf;
	
	FieldsOfAccountingObjectSelection.ThisIsReverseTransaction = ThisIsReverseTransaction;
	FieldsOfAccountingObjectSelection.ResourceValueCondition = "(" + StrConcat(ConditionsAreNotZero, " OR ") + ")";
	
	ThisIsDebit = "CASE
	|		WHEN &ThisIsReverseTransaction
	|			THEN &ConditionCredit
	|		ELSE &DebitCondition
	|	END";
	
	ThisIsLoan = "CASE
	|		WHEN &ThisIsReverseTransaction
	|			THEN &DebitCondition
	|		ELSE &ConditionCredit
	|	END";
	
	DebitCondition = SelectionStringOfAccountingObjectField("DebitCondition",
		AccountingObjectRows_, MotionReflectionParameters, QueryOptions, False);
		
	ConditionCredit = SelectionStringOfAccountingObjectField("ConditionCredit",
		AccountingObjectRows_, MotionReflectionParameters, QueryOptions, False);
	
	ThisIsDebit = StrReplace(ThisIsDebit, "&ThisIsReverseTransaction", ThisIsReverseTransaction);
	ThisIsDebit = StrReplace(ThisIsDebit, "&DebitCondition", DebitCondition);
	ThisIsDebit = StrReplace(ThisIsDebit, "&ConditionCredit", ConditionCredit);
	
	ThisIsLoan = StrReplace(ThisIsLoan, "&ThisIsReverseTransaction", ThisIsReverseTransaction);
	ThisIsLoan = StrReplace(ThisIsLoan, "&DebitCondition", DebitCondition);
	ThisIsLoan = StrReplace(ThisIsLoan, "&ConditionCredit", ConditionCredit);
	
	FieldsOfAccountingObjectSelection.ThisIsDebit = ThisIsDebit;
	FieldsOfAccountingObjectSelection.ThisIsLoan = ThisIsLoan;
	
	Return FieldsOfAccountingObjectSelection;
	
EndFunction

Function AccountingItemSelectionString(AccountingObjectRows_, QueryOptions) Export
	
	If AccountingObjectRows_[0].DataSource = Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name Then
		Return ItemSelectionLineOtherAssetsLiabilities(AccountingObjectRows_, QueryOptions);
	EndIf;
	
	SelectionStrings = New Array();
	ObjectsWithoutSelection = New Array();
	
	For Each AccountingObjectLine_ In AccountingObjectRows_ Do
		Filterdata_ = AccountingObjectLine_.Filterdata_; //DataCompositionFilter -
		If Filterdata_.Items.Count() > 0 Then
			LinesWhen = New Array();
			LinesWhen.Add(Chars.Tab);
			LinesWhen.Add("WHEN"); //@Query-part
			LinesWhen.Add(DataSelectionConditionString(Filterdata_, QueryOptions));
			
			LinesAreThen = New Array();
			LinesAreThen.Add(Chars.Tab);
			LinesAreThen.Add("THEN"); //@Query-part
			LinesAreThen.Add(ValueSelectionString(AccountingObjectLine_.AccountingObject));
			
			SelectionStrings.Add(StrConcat(LinesWhen, " "));
			SelectionStrings.Add(StrConcat(LinesAreThen, " "));
		Else
			ObjectsWithoutSelection.Add(AccountingObjectLine_);
		EndIf;
	EndDo;
	
	If SelectionStrings.Count() = 0 And ObjectsWithoutSelection.Count() = 0 Then
		SelectionString = ValueSelectionString(ChartsOfCharacteristicTypes.AssetLiabilityItems.EmptyRef());
	ElsIf ObjectsWithoutSelection.Count() > 1 Then
		ExceptionLines = New Array();
		ExceptionLines.Add("vi = 'Đối với biểu ghi %1 đã mô tả nhiều hơn một đối tượng kế toán tài chính mà không chỉ ra bộ lọc chọn dữ liệu:';
							|ru = 'Для регистра %1 описано более одного объекта финансового учета без указания отбора выборки данных:';
							|en = 'For the %1 register, more than one financial accounting item is described without the dataset filter specified:';
							|it = 'Для регистра %1 описано более одного объекта финансового учета без указания отбора выборки данных:';
							|pl = 'For the %1 register, more than one financial accounting item is described without the dataset filter specified:';
							|tr = '%1 kaydı için, veri örneklerinin seçimi belirtilmeden birden fazla finansal muhasebe nesnesi tanımlandı:'");
		For Each AccountingObjectLine_ In ObjectsWithoutSelection Do
			ExceptionLines[0] = StrReplace(ExceptionLines[0], "%1", AccountingObjectLine_.DataSource);
			ExceptionLines.Add(AccountingObjectLine_.AccountingObject);
		EndDo;
		Raise StrConcat(ExceptionLines, Chars.LF);
	ElsIf SelectionStrings.Count() = 0 Then
		SelectionString = ValueSelectionString(ObjectsWithoutSelection[0].AccountingObject);
	Else
		StringsOtherwise = New Array();
		StringsOtherwise.Add(Chars.Tab);
		StringsOtherwise.Add("ELSE"); //@Query-part
		If ObjectsWithoutSelection.Count() = 0 Then
			StringsOtherwise.Add(ValueSelectionString(ChartsOfCharacteristicTypes.AssetLiabilityItems.EmptyRef()));
		Else
			StringsOtherwise.Add(ValueSelectionString(ObjectsWithoutSelection[0].AccountingObject));
		EndIf;
		
		LinesEnd = New Array();
		LinesEnd.Add(Chars.Tab);
		LinesEnd.Add("END"); //@Query-part
		
		SelectionStrings.Insert(0, "CASE"); //@Query-part
		SelectionStrings.Add(StrConcat(StringsOtherwise, " "));
		SelectionStrings.Add(StrConcat(LinesEnd, ""));
		SelectionString = StrConcat(SelectionStrings, Chars.LF);
	EndIf;
	
	Return SelectionString;
	
EndFunction

Function ItemSelectionLineOtherAssetsLiabilities(AccountingObjectRows_, QueryOptions) Export
	
	SelectionStrings = New Array();
	DataPathAccountingObject = DataPathWithSourceAlias("AssetRef");
	
	For Each AccountingObjectLine_ In AccountingObjectRows_ Do
		Filterdata_ = AccountingObjectLine_.Filterdata_; //DataCompositionFilter -
		FilterItemsCount = Filterdata_.Items.Count();
		SelectionIsBasedOnlyOnEqualityOfArticle = True;
		
		If FilterItemsCount = 1 Then
			FilterElement = Filterdata_.Items[0];
			If TypeOf(FilterElement) <> Type("DataCompositionFilterItem")
			 Or FilterElement.LeftValue <> New DataCompositionField("AssetRef")
			 Or FilterElement.ComparisonType <> DataCompositionComparisonType.Equal
			 Or FilterElement.RightValue <> AccountingObjectLine_.AccountingObject Then
				SelectionIsBasedOnlyOnEqualityOfArticle = False;
			EndIf;
		ElsIf FilterItemsCount > 1 Then
			SelectionIsBasedOnlyOnEqualityOfArticle = False;
		EndIf;
		
		If Not SelectionIsBasedOnlyOnEqualityOfArticle Then
			LinesWhen = New Array();
			LinesWhen.Add(Chars.Tab);
			LinesWhen.Add("WHEN"); //@Query-part
			LinesWhen.Add(DataSelectionConditionString(Filterdata_, QueryOptions));
			
			LinesAreThen = New Array();
			LinesAreThen.Add(Chars.Tab);
			LinesAreThen.Add("THEN"); //@Query-part
			LinesAreThen.Add(ValueSelectionString(AccountingObjectLine_.AccountingObject));
			
			SelectionStrings.Add(StrConcat(LinesWhen, " "));
			SelectionStrings.Add(StrConcat(LinesAreThen, " "));
		EndIf;
	EndDo;
	
	If SelectionStrings.Count() = 0 Then
		SelectionString = DataPathAccountingObject;
	Else
		StringsOtherwise = New Array();
		StringsOtherwise.Add(Chars.Tab);
		StringsOtherwise.Add("ELSE"); //@Query-part
		StringsOtherwise.Add(DataPathAccountingObject);
		
		LinesEnd = New Array();
		LinesEnd.Add(Chars.Tab);
		LinesEnd.Add("END"); //@Query-part
		
		SelectionStrings.Insert(0, "CASE"); //@Query-part
		SelectionStrings.Add(StrConcat(StringsOtherwise, " "));
		SelectionStrings.Add(StrConcat(LinesEnd, ""));
		SelectionString = StrConcat(SelectionStrings, Chars.LF);
	EndIf;
	
	Return SelectionString;
	
EndFunction

Function SelectionStringOfAccountingObjectField(DataPathProperty, AccountingObjectRows_,
	MotionReflectionParameters, QueryOptions, UndefinedValue) Export
	
	PathsToAccountingObjectData = New Map();
	PathToDataWithoutSelection = Undefined;
	
	For Each AccountingObjectLine_ In AccountingObjectRows_ Do
		DataPath = AccountingObjectLine_[DataPathProperty];
		If PathsToAccountingObjectData[DataPath] = Undefined Then
			PathsToAccountingObjectData.Insert(DataPath, New Array());
		EndIf;
		PathsToAccountingObjectData[DataPath].Add(AccountingObjectLine_);
		
		Filterdata_ = AccountingObjectLine_.Filterdata_; //DataCompositionFilter -
		If Filterdata_.Items.Count() = 0 Then
			PathToDataWithoutSelection = DataPath;
		EndIf;
	EndDo;
	
	SelectionStrings = New Array();
	IgnoreDefaultValue = MotionReflectionParameters.ContainsUnbalancedData
		And DataPathProperty = "DataPathRecordFinID";
	
	For Each PathToAccountingObjectData In PathsToAccountingObjectData Do
		If PathToAccountingObjectData.Key = PathToDataWithoutSelection Then
			Continue;
		ElsIf IgnoreDefaultValue Then
		ElsIf PathToDataWithoutSelection = Undefined And IsBlankString(PathToAccountingObjectData.Key) Then
			Continue;
		EndIf;
		
		GroupOfFilters = New Array();
		For Each AccountingObjectLine_ In PathToAccountingObjectData.Value Do
			GroupOfFilters.Add(AccountingObjectLine_.Filterdata_);
		EndDo;
		
		LinesWhen = New Array();
		LinesWhen.Add(Chars.Tab);
		LinesWhen.Add("WHEN"); //@Query-part
		LinesWhen.Add(DataSelectionConditionString(GroupOfFilters, QueryOptions));
		
		LinesAreThen = New Array();
		LinesAreThen.Add(Chars.Tab);
		LinesAreThen.Add("THEN"); //@Query-part
		If Not IsBlankString(PathToAccountingObjectData.Key) Then
			LinesAreThen.Add(DataPathWithSourceAlias(PathToAccountingObjectData.Key));
		ElsIf Not IsBlankString(MotionReflectionParameters[DataPathProperty]) Then
			LinesAreThen.Add(DataPathWithSourceAlias(MotionReflectionParameters[DataPathProperty]));
		Else
			LinesAreThen.Add(ValueSelectionString(UndefinedValue));
		EndIf;
		
		SelectionStrings.Add(StrConcat(LinesWhen, " "));
		SelectionStrings.Add(StrConcat(LinesAreThen, " "));
	EndDo;
	
	If SelectionStrings.Count() > 0 Then
		StringsOtherwise = New Array();
		StringsOtherwise.Add(Chars.Tab);
		StringsOtherwise.Add("ELSE"); //@Query-part
		If ValueIsFilled(PathToDataWithoutSelection) Then
			StringsOtherwise.Add(DataPathWithSourceAlias(PathToDataWithoutSelection));
		ElsIf IgnoreDefaultValue Then
			StringsOtherwise.Add(ValueSelectionString(UndefinedValue));
		ElsIf Not IsBlankString(MotionReflectionParameters[DataPathProperty]) Then
			StringsOtherwise.Add(DataPathWithSourceAlias(MotionReflectionParameters[DataPathProperty]));
		Else
			StringsOtherwise.Add(ValueSelectionString(UndefinedValue));
		EndIf;
		
		LinesEnd = New Array();
		LinesEnd.Add(Chars.Tab);
		LinesEnd.Add("END"); //@Query-part
		
		SelectionStrings.Insert(0, "CASE"); //@Query-part
		SelectionStrings.Add(StrConcat(StringsOtherwise, " "));
		SelectionStrings.Add(StrConcat(LinesEnd, ""));
		SelectionString = StrConcat(SelectionStrings, Chars.LF);
	ElsIf ValueIsFilled(PathToDataWithoutSelection) Then
		SelectionString = DataPathWithSourceAlias(PathToDataWithoutSelection);
	ElsIf Not IsBlankString(MotionReflectionParameters[DataPathProperty]) Then
		SelectionString = DataPathWithSourceAlias(MotionReflectionParameters[DataPathProperty]);
	Else
		SelectionString = ValueSelectionString(UndefinedValue);
	EndIf;
	
	Return SelectionString;
	
EndFunction

Function FieldSelectionStringWithAttributeOfAccountingInObject(DataPathProperty, AccountingAttributeProperty,
	AccountingObjectRows_, MotionReflectionParameters, QueryOptions, UndefinedValue) Export
	
	GeneralAccountingAttributeValue = Undefined;
	
	If QueryOptions.Property(AccountingAttributeProperty, GeneralAccountingAttributeValue)
		And Not Boolean(GeneralAccountingAttributeValue) Then
		Return ValueSelectionString(UndefinedValue);
	ElsIf Not Boolean(MotionReflectionParameters[AccountingAttributeProperty]) Then
		Return ValueSelectionString(UndefinedValue);
	ElsIf IsBlankString(MotionReflectionParameters[DataPathProperty]) Then
		Return ValueSelectionString(UndefinedValue);
	EndIf;
	
	SignsOfAccountingForAccountingObjects = New Map();
	AttributeForAccountingWithoutSelection = Undefined;
	
	For Each AccountingObjectLine_ In AccountingObjectRows_ Do
		AccountingFlag = Boolean(AccountingObjectLine_[AccountingAttributeProperty]);
		If SignsOfAccountingForAccountingObjects[AccountingFlag] = Undefined Then
			SignsOfAccountingForAccountingObjects.Insert(AccountingFlag, New Array());
		EndIf;
		SignsOfAccountingForAccountingObjects[AccountingFlag].Add(AccountingObjectLine_);
		
		Filterdata_ = AccountingObjectLine_.Filterdata_; //DataCompositionFilter -
		If Filterdata_.Items.Count() = 0 Then
			AttributeForAccountingWithoutSelection = AccountingFlag;
		EndIf;
	EndDo;
	
	SelectionStrings = New Array();
	
	For Each AttributeForAccountingItems In SignsOfAccountingForAccountingObjects Do
		If AttributeForAccountingItems.Key = AttributeForAccountingWithoutSelection Then
			Continue;
		EndIf;
		
		GroupOfFilters = New Array();
		For Each AccountingObjectLine_ In AttributeForAccountingItems.Value Do
			GroupOfFilters.Add(AccountingObjectLine_.Filterdata_);
		EndDo;
		
		LinesWhen = New Array();
		LinesWhen.Add(Chars.Tab);
		LinesWhen.Add("WHEN"); //@Query-part
		LinesWhen.Add(DataSelectionConditionString(GroupOfFilters, QueryOptions));
		
		LinesAreThen = New Array();
		LinesAreThen.Add(Chars.Tab);
		LinesAreThen.Add("THEN"); //@Query-part
		If AttributeForAccountingItems.Key = True Then
			LinesAreThen.Add(DataPathWithSourceAlias(MotionReflectionParameters[DataPathProperty]));
		Else
			LinesAreThen.Add(ValueSelectionString(UndefinedValue));
		EndIf;
		
		SelectionStrings.Add(StrConcat(LinesWhen, " "));
		SelectionStrings.Add(StrConcat(LinesAreThen, " "));
	EndDo;
	
	If SelectionStrings.Count() > 0 Then
		StringsOtherwise = New Array();
		StringsOtherwise.Add(Chars.Tab);
		StringsOtherwise.Add("ELSE"); //@Query-part
		If AttributeForAccountingWithoutSelection = True Then
			StringsOtherwise.Add(DataPathWithSourceAlias(MotionReflectionParameters[DataPathProperty]));
		Else
			StringsOtherwise.Add(ValueSelectionString(UndefinedValue));
		EndIf;
		
		LinesEnd = New Array();
		LinesEnd.Add(Chars.Tab);
		LinesEnd.Add("END"); //@Query-part
		
		SelectionStrings.Insert(0, "CASE"); //@Query-part
		SelectionStrings.Add(StrConcat(StringsOtherwise, " "));
		SelectionStrings.Add(StrConcat(LinesEnd, ""));
		SelectionString = StrConcat(SelectionStrings, Chars.LF);
	ElsIf AttributeForAccountingWithoutSelection = True Then
		SelectionString = DataPathWithSourceAlias(MotionReflectionParameters[DataPathProperty]);
	Else
		SelectionString = ValueSelectionString(UndefinedValue);
	EndIf;
	
	Return SelectionString;
	
EndFunction

Function SelectionStringForStornoAttribute(ResourceSelectionLines) Export
	
	ConditionStrings = New Array();
	ConditionStrings.Add("(&SumMan < 0 AND &SumCompl <= 0)");
	ConditionStrings.Add("(&SumMan <= 0 AND &SumCompl < 0)");
	
	If ResourceSelectionLines.SumCurr <> "0" Or ResourceSelectionLines.Count <> "0" Then
		ConditionStrings.Add("(&SumMan = 0 AND &SumCompl = 0 AND (&SumCurr < 0 OR &Count < 0))");
	EndIf;
	
	ConditionSelectionString = "(" + StrConcat(ConditionStrings, " OR ") + ")";
	
	For Each KeyAndValue In ResourceSelectionLines Do
		ConditionSelectionString = StrReplace(ConditionSelectionString, "&" + KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	Return ConditionSelectionString;
	
EndFunction

Function ResourceSelectionString(ResourceComposition) Export
	
	If ResourceComposition.Count() = 0 Then
		SelectionString = "0";
	Else
		DataPaths = New Array();
		
		For Each ResourceField In ResourceComposition Do
			If TypeOf(ResourceField) = Type("ValueTableRow") Then
				DataPath = DataPathWithSourceAlias(ResourceField.ResourceName);
				ZoomRatio = ResourceField.ZoomRatio;
			ElsIf ResourceField = "0" Then
				DataPath = ResourceField;
				ZoomRatio = 0;
			ElsIf StrStartsWith(ResourceField, "-") Then
				DataPath = DataPathWithSourceAlias(Mid(ResourceField, 2));
				ZoomRatio = -1;
			Else
				DataPath = DataPathWithSourceAlias(ResourceField);
				ZoomRatio = 1;
			EndIf;
			
			If ZoomRatio = 0 Then
				DataPaths.Add("0");
			Else
				DataPaths.Add(?(ZoomRatio < 0, "-", "") + DataPath);
			EndIf;
		EndDo;
		
		SelectionString = StrConcat(DataPaths, " + ");
		
		If DataPaths.Count() > 1 Then
			SelectionString = "(" + SelectionString + ")";
		EndIf;
	EndIf;
	
	Return SelectionString;
	
EndFunction

Function ResourceAmountSelectionString(ResourceSelectionString, AmountSampleTemplate, SelectionStringIsStorno, ConditionsAreNotZero) Export
	
	If ResourceSelectionString = "0" Then
		SumSelectionString = "0";
	Else
		SumSelectionString = StrReplace(AmountSampleTemplate, "&Resource", ResourceSelectionString);
		SumSelectionString = StrReplace(SumSelectionString, "&ThisIsReverseTransaction", SelectionStringIsStorno);
		ConditionsAreNotZero.Add(ResourceSelectionString + " <> 0");
	EndIf;
	
	Return SumSelectionString;
	
EndFunction

Procedure ChangeSelectionFields(QueryText, FieldsToDelete__ = Undefined, IndexFields = Undefined, PlacementTable = "") Export
	
	QuerySchema = New QuerySchema();
	QueryBatch = QuerySchema.QueryBatch[0];
	QueryBatch.SetQueryText(QueryText);
	
	If FieldsToDelete__ <> Undefined Then
		For Each FieldAlias In FieldsToDelete__ Do
			Column = QueryBatch.Columns.Find(FieldAlias);
			If Column <> Undefined Then
				ColumnIndex = QueryBatch.Columns.IndexOf(Column);
				QueryBatch.Columns.Delete(ColumnIndex);
			EndIf;
		EndDo;
	EndIf;
	
	If IndexFields <> Undefined Then
		For Each FieldAlias In IndexFields Do
			QueryBatch.Index.Add(FieldAlias);
		EndDo;
	EndIf;
	
	If Not IsBlankString(PlacementTable) Then
		QueryBatch.PlacementTable = PlacementTable;
	ElsIf Not IsBlankString(QueryBatch.PlacementTable) Then
		QueryBatch.PlacementTable = "";
	EndIf;

	QueryText = QueryBatch.GetQueryText();
	
EndProcedure

Function DataPathWithSourceAlias(DataPath, SourceAlias = Undefined) Export
	
	If SourceAlias = Undefined Then
		SourceAlias = DefaultDataSourceAlias();
	EndIf;
	
	IsConstant = DataPath = "FALSE"
		Or DataPath = "TRUE"
		Or DataPath = "UNDEFINED"
		Or StrStartsWith(DataPath, "TYPE(")
		Or StrStartsWith(DataPath, "VALUE(")
		Or StrStartsWith(DataPath, "DATETIME(");
	
	IsExpression = StrFind(DataPath, " ") > 0
		Or StrFind(DataPath, Chars.LF) > 0;
	
	IsParameter = StrStartsWith(DataPath, "&");
	
	If IsBlankString(SourceAlias)
	 Or StrStartsWith(DataPath, SourceAlias)
	 Or IsConstant
	 Or IsExpression
	 Or IsParameter Then
		Return DataPath;
	Else
		Return SourceAlias + "." + DataPath;
	EndIf;
	
EndFunction

Function DataPathWithoutSourceAlias(DataPath, SourceAlias = Undefined) Export
	
	If SourceAlias = Undefined Then
		SourceAlias = DefaultDataSourceAlias();
	EndIf;
	
	Return StrReplace(DataPath, SourceAlias + ".", "");
	
EndFunction

Function ValueSelectionString(SampleValue) Export
	
	SampleValueType = TypeOf(SampleValue);
	
	If SampleValueType = Type("Undefined") Then
		SelectionString = "UNDEFINED";
	ElsIf SampleValueType = Type("Number") Then
		SelectionString = Format(SampleValue, "NDS=.; NZ=0; NG=0");
	ElsIf SampleValueType = Type("Date") Then
		SelectionString = "DATETIME(" + Format(SampleValue, "DF=yyyy,MM,dd; DE=0001,01,01") + ")";
	ElsIf SampleValueType = Type("String") Then
		SelectionString = """" + SampleValue + """";
	ElsIf SampleValueType = Type("Boolean") Then
		SelectionString = Format(SampleValue, "BF=FALSE; BT=TRUE");
	ElsIf SampleValueType = Type("Type") Then
		SelectionString = "TYPE(" + FullTypeName(SampleValue) + ")";
	ElsIf Enums.AllRefsType().ContainsType(SampleValueType) Then
		SelectionString = "VALUE(" + FullNameOfEnumerationValue(SampleValue) + ")";
	ElsIf (Catalogs.AllRefsType().ContainsType(SampleValueType)
		Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(SampleValueType)
		Or ChartsOfAccounts.AllRefsType().ContainsType(SampleValueType))
		And (SampleValue.Predefined Or SampleValue.IsEmpty()) Then
		SelectionString = "VALUE(" + FullNameOfPredefinedValue(SampleValue) + ")";
	ElsIf Documents.AllRefsType().ContainsType(SampleValueType)
		And SampleValue.IsEmpty() Then
		SelectionString = "VALUE(" + FullNameOfPredefinedValue(SampleValue) + ")";
	ElsIf SampleValueType = Type("ValueList") Then
		SelectionString = ValueSelectionString(SampleValue.UnloadValues());
	ElsIf SampleValueType = Type("Array") Then
		ItemSelectionRows = New Array();
		For Each SelectionElement_ In SampleValue Do
			ItemSelectionString = ValueSelectionString(SelectionElement_);
			If StrStartsWith(ItemSelectionString, "Parameter") Then
				ItemSelectionRows.Clear();
				Break;
			Else
				ItemSelectionRows.Add(ItemSelectionString);
			EndIf;
		EndDo;
		If ItemSelectionRows.Count() > 0 Then
			Separator = "," + Chars.LF + Chars.Tab + Chars.Tab;
			SelectionString = StrConcat(ItemSelectionRows, Separator);
		Else
			SelectionString = "Parameter" + StrReplace(String(New UUID()), "-", "");
		EndIf;
	Else
		SelectionString = "Parameter" + StrReplace(String(New UUID()), "-", "");
	EndIf;
	
	Return SelectionString;
	
EndFunction

Function FieldValueSelectionString(SampleRowsFields) Export
	
	If SampleRowsFields.Count() = 1 Then
		For Each KeyAndValue In SampleRowsFields Do
			ValueSelectionLine = KeyAndValue.Key;
			Break;
		EndDo;
	Else
		SamplingFrequencyString = "";
		NumberOfUses = 0;
		
		For Each KeyAndValue In SampleRowsFields Do
			If KeyAndValue.Value.Count() > NumberOfUses Then
				SamplingFrequencyString = KeyAndValue.Key;
				NumberOfUses = KeyAndValue.Value.Count();
			EndIf;
		EndDo;
		
		SelectionStrings = New Array();
		
		For Each KeyAndValue In SampleRowsFields Do
			If KeyAndValue.Key = SamplingFrequencyString Then
				Continue;
			EndIf;
			
			If KeyAndValue.Value.Count() = 1 Then
				FilterValue = KeyAndValue.Value[0];
			Else
				FilterValue = KeyAndValue.Value;
			EndIf;
			
			FilterCriterion = New Structure("RepeatNumber", FilterValue);
			
			LinesWhen = New Array();
			LinesWhen.Add(Chars.Tab);
			LinesWhen.Add("WHEN"); //@Query-part
			LinesWhen.Add(DataSelectionConditionString(FilterCriterion,, "Repeater"));
			
			LinesAreThen = New Array();
			LinesAreThen.Add(Chars.Tab);
			LinesAreThen.Add("THEN"); //@Query-part
			LinesAreThen.Add(KeyAndValue.Key);
			
			SelectionStrings.Add(StrConcat(LinesWhen, " "));
			SelectionStrings.Add(StrConcat(LinesAreThen, " "));
		EndDo;
		
		StringsOtherwise = New Array();
		StringsOtherwise.Add(Chars.Tab);
		StringsOtherwise.Add("ELSE"); //@Query-part
		StringsOtherwise.Add(SamplingFrequencyString);
		
		LinesEnd = New Array();
		LinesEnd.Add(Chars.Tab);
		LinesEnd.Add("END"); //@Query-part
		
		SelectionStrings.Insert(0, "CASE"); //@Query-part
		SelectionStrings.Add(StrConcat(StringsOtherwise, " "));
		SelectionStrings.Add(StrConcat(LinesEnd, ""));
		
		ValueSelectionLine = StrConcat(SelectionStrings, Chars.LF);
	EndIf;
	
	Return ValueSelectionLine;
	
EndFunction

Function ResourceIsMissingOrMayBeEmpty(ResourceComposition) Export
	
	If ResourceComposition.Count() = 0 Then
		ResourceIsMissing = True;
		ResourceMayBeEmpty = True;
	Else
		ResourceIsMissing = False;
		ResourceMayBeEmpty = ResourceComposition[0] = "0";
	EndIf;
	
	Return ResourceIsMissing Or ResourceMayBeEmpty;
	
EndFunction

Procedure AddRepeaterToDataSource(DataSource, RepeatCount) Export
	
	SampleLines = New Array();
	SelectionTemplate1 = "
	|	SELECT
	|		&RepeatNumber AS RepeatNumber"; //@Query-part
	
	For RepeatNumber = 1 To RepeatCount Do
		SampleLines.Add(StrReplace(SelectionTemplate1, "&RepeatNumber", ValueSelectionString(RepeatNumber)));
	EndDo;
	
	Separator = "
	|	UNION ALL"; //@Query-part
	
	DataSource = DataSource + StrTemplate("
		|	,
		|	(%1) AS Repeater",
		StrConcat(SampleLines, Separator));
	
EndProcedure

Procedure AddRepeaterToDimensionFields(QueryText) Export
	
	QueryText = StrReplace(QueryText,
		"GROUP BY",
		"GROUP BY
		|	Repeater.RepeatNumber,");
	
EndProcedure

// Returns a fragment of the query text with a condition in the Period field
//
// Parameters:
//  QueryOptions - Structure - request parameters, including:
//   * StartDate - Date - Beginning of the period
//   * EndDate - Date - End of the period
//
// Returns:
//  String - A fragment of the request text
//
Function ConditionStringPeriod(QueryOptions) Export
	
	ConditionStrings = New Array();
	
	If QueryOptions.StartDate > '00010101' Then
		ConditionStrings.Add("&Period >= &StartDate");
	EndIf;
	
	If QueryOptions.EndDate > '00010101' Then
		ConditionStrings.Add("&Period <= &EndDate");
	EndIf;
	
	If ConditionStrings.Count() = 0 Then
		Return "TRUE";
	Else
		Return StrConcat(ConditionStrings, Chars.LF + Chars.Tab + "And ");
	EndIf;
	
EndFunction

// Returns a fragment of the request text with the condition in the Logger field
//
// Parameters:
//  QueryOptions - Structure - request parameters, including:
//   * Recorder - DocumentRef - link to the registrar
//
// Returns:
//  String - A fragment of the request text
//
Function ConditionStringLogger(QueryOptions) Export
	
	If TypeOf(QueryOptions.Recorder) = Type("Array") Then
		Return "&Recorder IN (&RequestParameterRegistrar)";
	ElsIf ValueIsFilled(QueryOptions.Recorder) Then
		Return "&Recorder = &RequestParameterRegistrar";
	Else
		Return "TRUE";
	EndIf;
	
EndFunction

Function OrganizationConditionLine(QueryOptions) Export
	
	If TypeOf(QueryOptions.Organization) = Type("Array") Then
		Return "&Organization IN (&RequestParameterOrganization)";
	ElsIf ValueIsFilled(QueryOptions.Organization) Then
		Return "&Organization = &RequestParameterOrganization";
	Else
		Return "TRUE";
	EndIf;
	
EndFunction

Function ConditionLineDocumentsToBeDeleted(RegisterMetadata) Export
	
	DocumentsMetadata = Metadata.Documents;
	ConditionStrings = New Array();
	
	For Each DocumentName In NamesOfUnusedDocuments() Do
		If DocumentsMetadata[DocumentName].RegisterRecords.Contains(RegisterMetadata) Then
			ConditionStrings.Add("NOT &Recorder REFS Document." + DocumentName);
		EndIf;
	EndDo;
	
	If ConditionStrings.Count() = 0 Then
		Return "TRUE";
	Else
		Return StrConcat(ConditionStrings, Chars.LF + Chars.Tab + "And ");
	EndIf;
	
EndFunction

Function StringAdditionalSelection(MotionReflectionParameters) Export
	
	If ValueIsFilled(MotionReflectionParameters.AdditionalSelection) Then
		Return MotionReflectionParameters.AdditionalSelection;
	Else
		Return "TRUE";
	EndIf;
	
EndFunction

Function ConditionStringPropsStorno() Export
	
	Return "&PropsStorno = FALSE";
	
EndFunction

Function FullTypeName(TypeValue) Export
	
	If TypeValue = Type("Date") Then
		Return "DATE";
	ElsIf TypeValue = Type("Number") Then
		Return "NUMBER";
	ElsIf TypeValue = Type("String") Then
		Return "STRING";
	Else
		MetadataObject = Metadata.FindByType(TypeValue);
		If MetadataObject <> Undefined Then
			Return MetadataObject.FullName();
		Else
			Return "BOOLEAN";
		EndIf;
	EndIf;
	
EndFunction

Function NameOfRegisterOfServiceAccountingObjects() Export
	
	Return "MovementOfServiceAccountingObjects";
	
EndFunction

#EndRegion

#Region GettingCorrespondenceAnalytics

Function FieldSelectionText(AvailableFields, ExcludedFields, FieldsToAdd = Undefined, Postfix = "", SourceAlias = Undefined) Export
	
	If FieldsToAdd = Undefined Then
		FieldsToAdd = AvailableFields;
	EndIf;
	
	FieldSelectionLines = New Array();
	
	For Each FieldName In FieldsToAdd Do
		FieldAlias = FieldName + Postfix;
		
		If ExcludedFields.Find(FieldName) <> Undefined Then
			Continue;
		ElsIf Not IsBlankString(Postfix) And ExcludedFields.Find(FieldAlias) <> Undefined Then
			Continue;
		EndIf;
		
		If FieldName = "TypeOfRegistrar" Then
			DataPath = DataPathWithSourceAlias("Recorder", SourceAlias);
			FieldSelectionLines.Add("VALUETYPE(" + DataPath+ ") AS " + FieldAlias);
		ElsIf FieldName = "BusinessTransactionSetting" Then
			DataPath = DataPathWithSourceAlias("SettingUpBusinessTransaction", SourceAlias);
			FieldSelectionLines.Add(DataPath + " AS " + FieldAlias);
		ElsIf AvailableFields.Find(FieldName) <> Undefined Then
			DataPath = DataPathWithSourceAlias(FieldName, SourceAlias);
			FieldSelectionLines.Add(DataPath + " AS " + FieldAlias);
		Else
			FieldSelectionLines.Add(ValueSelectionString(Undefined) + " AS " + FieldAlias);
		EndIf;
	EndDo;
	
	LineSplitter = "," + Chars.LF + Chars.Tab;
	
	If FieldSelectionLines.Count() > 0 Then
		FieldSelectionText = StrConcat(FieldSelectionLines, LineSplitter);
	Else
		FieldSelectionText = ValueSelectionString(Undefined);
	EndIf;
	
	Return FieldSelectionText;
	
EndFunction

Procedure FillInAnalyticsSampleLines(SelectingFields, FieldsGrouping, AvailableFields, ExcludedFields, FieldsToAdd = Undefined) Export
	
	If FieldsToAdd = Undefined Then
		FieldsToAdd = AvailableFields;
		CheckFieldsAvailability = False;
	Else
		CheckFieldsAvailability = True;
	EndIf;
	
	For Each FieldName In FieldsToAdd Do
		If ExcludedFields.Find(FieldName) <> Undefined Then
			Continue;
		ElsIf CheckFieldsAvailability And AvailableFields.Find(FieldName) = Undefined Then
			Continue;
		EndIf;
		
		DataPath = DataPathWithSourceAlias(FieldName);
		SelectingFields.Add(DataPath + " AS " + FieldName);
		FieldsGrouping.Add(DataPath);
	EndDo;
	
EndProcedure

Procedure AddSelectionOfAnalyticsToQueryText(SelectingFields, FieldsGrouping, QueryText) Export

	LineSplitter = "," + Chars.LF + Chars.Tab;
	
	If SelectingFields.Count() > 0 Then
		TextOfAnalyticsFields = StrConcat(SelectingFields, LineSplitter);
	Else
		TextOfAnalyticsFields = "//AnalyticsSelectionFields";
	EndIf;
	
	If FieldsGrouping.Count() > 0 Then
		TextOfAnalyticsGroup = StrConcat(FieldsGrouping, LineSplitter);
	Else
		TextOfAnalyticsGroup = "//AnalyticsFieldGroup";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&AnalyticsSelectionFields", TextOfAnalyticsFields);
	QueryText = StrReplace(QueryText, "&AnalyticsFieldGroup", TextOfAnalyticsGroup);
	
	If StrFind(QueryText, "&NestedTableAnalyticsFields") > 0 Then
		Separator = " AS ";
		SeparatorLength = StrLen(Separator);
		
		SelectionOfNestedTableFields = New Array();
		GroupingFieldsInNestedTable = New Array();
		
		For Each FieldSelectionString_ In SelectingFields Do
			SeparatorPosition = StrFind(FieldSelectionString_, Separator, SearchDirection.FromEnd);
			FieldAlias = Mid(FieldSelectionString_, SeparatorPosition + SeparatorLength);
			DataPath = DataPathWithSourceAlias(FieldAlias);
			SelectionOfNestedTableFields.Add(DataPath + " AS " + FieldAlias);
			GroupingFieldsInNestedTable.Add(DataPath);
		EndDo;
	
		If SelectingFields.Count() > 0 Then
			TextOfAnalyticsFields = StrConcat(SelectionOfNestedTableFields, LineSplitter);
			TextOfAnalyticsGroup = StrConcat(GroupingFieldsInNestedTable, LineSplitter);
		Else
			TextOfAnalyticsFields = "//NestedTableAnalyticsFields";
			TextOfAnalyticsGroup = "//NestedTableAnalyticsGroup";
		EndIf;
		
		QueryText = StrReplace(QueryText, "&NestedTableAnalyticsFields", TextOfAnalyticsFields);
		QueryText = StrReplace(QueryText, "&NestedTableAnalyticsGroup", TextOfAnalyticsGroup);
	EndIf;
	
EndProcedure

Procedure AddSelectionOfResourcesToQueryText(SelectionOfResources, QueryText) Export
	
	LineSplitter = "," + Chars.LF + Chars.Tab;
	
	If SelectionOfResources.Count() > 0 Then
		SourceResourceText = StrConcat(SelectionOfResources, LineSplitter);
	Else
		SourceResourceText = "//DataSourceResources";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&DataSourceResources", SourceResourceText);
	
	If StrFind(QueryText, "&EmptyDataSourceResources") > 0
	 Or StrFind(QueryText, "&ResourcesOfNestedDataSource") > 0
	 Or StrFind(QueryText, "&SumsOfResourcesOfNestedDataSource") > 0 Then
		Separator = " AS ";
		SeparatorLength = StrLen(Separator);
		
		SelectingEmptySourceResources = New Array();
		SelectionOfNestedSourceResources = New Array();
		FetchingAmountsOfNestedSourceResources = New Array();
		
		For Each ResourceSelectionString In SelectionOfResources Do
			SeparatorPosition = StrFind(ResourceSelectionString, Separator, SearchDirection.FromEnd);
			ResourceAlias = Mid(ResourceSelectionString, SeparatorPosition + SeparatorLength);
			DataPath = DataPathWithSourceAlias(ResourceAlias);
			SelectingEmptySourceResources.Add("0 AS " + ResourceAlias);
			SelectionOfNestedSourceResources.Add(DataPath + " AS " + ResourceAlias);
			FetchingAmountsOfNestedSourceResources.Add(StrTemplate("SUM(%1) AS %2", DataPath, ResourceAlias));
		EndDo;
	
		If SelectionOfResources.Count() > 0 Then
			TextOfEmptyResources = StrConcat(SelectingEmptySourceResources, LineSplitter);
			SourceResourceText = StrConcat(SelectionOfNestedSourceResources, LineSplitter);
			TextOfSourceResourceAmounts = StrConcat(FetchingAmountsOfNestedSourceResources, LineSplitter);
		Else
			TextOfEmptyResources = "//EmptyDataSourceResources";
			SourceResourceText = "//ResourcesOfNestedDataSource";
			TextOfSourceResourceAmounts = "//SumsOfResourcesOfNestedDataSource";
		EndIf;
		
		QueryText = StrReplace(QueryText, "&EmptyDataSourceResources", TextOfEmptyResources);
		QueryText = StrReplace(QueryText, "&ResourcesOfNestedDataSource", SourceResourceText);
		QueryText = StrReplace(QueryText, "&SumsOfResourcesOfNestedDataSource", TextOfSourceResourceAmounts);
	EndIf;
	
EndProcedure

#EndRegion

#Region SelectionOfCorrespondenceAccordingToSettingsOfDataCompositionSchema

Function NewDataLayoutScheme(QueryText) Export
	
	DataCompositionSchema = DataCompositionServer.EmptyCircuit();
	DataSet = DataCompositionServer.AddEmptyDataSet(DataCompositionSchema);
	DataSet.AutoFillAvailableFields = True;
	DataSet.Query = QueryText;
	
	Return DataCompositionSchema;
	
EndFunction

Function NewDataLayoutSettingsComposer(AddressOfDataCompositionSchema, DataCompositionSelectionFields, QueryOptions) Export
	
	SettingsComposer = New DataCompositionSettingsComposer();
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema));
	
	For Each ComboBox In DataCompositionSelectionFields Do
		SelectedField = SettingsComposer.Settings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedField.Field = New DataCompositionField(ComboBox.Key);
	EndDo;
	
	For Each AvailableParameter In SettingsComposer.Settings.DataParameters.AvailableParameters.Items Do
		Parameter = AvailableParameter.Parameter;
		SettingsComposer.Settings.DataParameters.SetParameterValue(Parameter, QueryOptions[String(Parameter)]);
	EndDo;
	
	DetailedRecords = SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
	DetailedRecords.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	
	Return SettingsComposer;
	
EndFunction

Procedure AddLayoutResultToTable(DataCompositionSchema, SettingsComposer, TempTablesManager, LayoutResultsTable) Export
	
	TemplateComposer = New DataCompositionTemplateComposer();
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.Settings,,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	DataCompositionProcessor = New DataCompositionProcessor();
	DataCompositionProcessor.Initialize(CompositionTemplate,,, True,, TempTablesManager);
	
	ProcessorOutputToValueTable = New DataCompositionResultValueCollectionOutputProcessor();
	LayoutResultTable = ProcessorOutputToValueTable.Output(DataCompositionProcessor, False);
	
	For Each ResultString1 In LayoutResultTable Do
		FillPropertyValues(LayoutResultsTable.Add(), ResultString1);
	EndDo;
	
EndProcedure


// Checks the presence of the used fields in the transmitted selection.
// It is possible to select top-level fields by the value of the postfix.
// 
// Parameters:
//  FilterSource - DataCompositionFilter - the selection in which the presence of the fields used is checked.
//  Postfix - String - the postfix by which the top-level fields are selected.
// 
// Returns:
//  Boolean - indicates whether the fields are in use
//
Function ThereAreElementsOfSelection(FilterSource, Postfix = "") Export
	
	ThereAreElementsOfSelection = False;
	
	For Each FilterElement In FilterSource.Items Do
		If Not FilterElement.Use Then
			Continue;
		EndIf;
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
			DataPath = String(FilterElement.LeftValue);
			FilterField = StrSplit(DataPath, ".")[0];
			
			If Not IsBlankString(Postfix) Then
				ThereAreElementsOfSelection = StrEndsWith(FilterField, Postfix);
			Else
				ThereAreElementsOfSelection = True;
			EndIf;
		Else
			ThereAreElementsOfSelection = ThereAreElementsOfSelection(FilterElement, Postfix);
		EndIf;
		
		If ThereAreElementsOfSelection Then
			Break;
		EndIf;
	EndDo;
	
	Return ThereAreElementsOfSelection;
	
EndFunction

// Adds top-level fields from the transmitted selection to the transmitted array.
// It is possible to select fields by the value of the postfix.
// Postfix is excluded from field names.
// 
// Parameters:
//  FilterFields - Array of String - the array to fill in.
//  FilterSource - DataCompositionFilter - selection, whose top-level fields are used to fill in the array.
//  Postfix - String - the postfix by which the top-level fields are selected.
//
Procedure AddSelectionElementFields(FilterFields, FilterSource, Postfix = "") Export
	
	For Each FilterElement In FilterSource.Items Do
		If Not FilterElement.Use Then
			Continue;
		EndIf;
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
			DataPath = String(FilterElement.LeftValue);
			FilterField = StrSplit(DataPath, ".")[0];
			
			If Not IsBlankString(Postfix) Then
				If StrEndsWith(FilterField, Postfix) Then
					FilterField = Mid(FilterField, 1, StrLen(FilterField) - StrLen(Postfix));
				Else
					Continue;
				EndIf;
			EndIf;
			
			If FilterFields.Find(FilterField) = Undefined Then
				FilterFields.Add(FilterField);
			EndIf;
		Else
			AddSelectionElementFields(FilterFields, FilterElement, Postfix);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region GeneratePostings

Function CheckingEqualityOfBalanceResources(MotionSampling_, AnalyticsLines_, QueryOptions, DrCr) Export
	
	If AnalyticsLines_.Count() = 0 Then
		Return False;
	EndIf;
	
	RegisterName = MotionSampling_["RegisterName" + DrCr];
	
	If RegisterName = NameOfRegisterOfServiceAccountingObjects() Then
		Return True;
	EndIf;
	
	SumMan = 0;
	SumCompl = 0;
	
	For Each AnalyticsLine_ In AnalyticsLines_ Do
		SumMan = SumMan + AnalyticsLine_.SumMan;
		SumCompl = SumCompl + AnalyticsLine_.SumCompl;
	EndDo;
	
	If QueryOptions.RegistersWithoutManSum.Find(RegisterName) <> Undefined Then
		SumOfManSMovementIsEqualToSumOfAnalyticsMan = True;
	Else
		SumOfManSMovementIsEqualToSumOfAnalyticsMan = MotionSampling_["AmountOfManMovement" + DrCr] = SumMan;
	EndIf;
	
	If QueryOptions.RegistersWithoutSumLocal.Find(RegisterName) <> Undefined Then
		AmountOfLocalTrafficIsEqualToAmountOfLocalAnalytics = True;
	Else
		AmountOfLocalTrafficIsEqualToAmountOfLocalAnalytics = MotionSampling_["AmountOfLocalTraffic" + DrCr] = SumCompl;
	EndIf;
	
	Return SumOfManSMovementIsEqualToSumOfAnalyticsMan And AmountOfLocalTrafficIsEqualToAmountOfLocalAnalytics;
	
EndFunction

Function CurrenciesOfOperationalAccounting(Organization) Export
	
	CurrenciesOfOperationalAccounting = New Structure();
	CurrenciesOfOperationalAccounting.Insert("CurrencyOfMan", SettingsValueCached.ManagementAccountingCurrency());
	CurrenciesOfOperationalAccounting.Insert("ComplCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization));
	
	Return CurrenciesOfOperationalAccounting;
	
EndFunction

Function RecalculatedResourcesOfManyAnalysts(MotionSampling_, ManyAnalysts, ParametersForGeneratingTransactions) Export
	
	DescriptionOfAmount = Common.TypeDescriptionNumber(ParametersForGeneratingTransactions.LengthOfSum, ParametersForGeneratingTransactions.SumAccuracy);
	DescriptionOfQuantity = Common.TypeDescriptionNumber(ParametersForGeneratingTransactions.LengthOfQuantity, ParametersForGeneratingTransactions.QuantityAccuracy);
	
	ResourceTable = New ValueTable();
	ResourceTable.Columns.Add("SumMan", DescriptionOfAmount);
	ResourceTable.Columns.Add("SumCompl", DescriptionOfAmount);
	ResourceTable.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	ResourceTable.Columns.Add("SumCurr", DescriptionOfAmount);
	ResourceTable.Columns.Add("Count", DescriptionOfQuantity);
	
	RecalculateBalance = MotionSampling_["ComplexEntry" + ManyAnalysts.DrCr];
	RecalculateAmounts_ = RecalculateBalance
		And MotionSampling_["Currency1" + ManyAnalysts.DrCr]
		And MotionSampling_["SumCurr" + ManyAnalysts.DrCr] <> 0;
	RecalculateQuantities = RecalculateBalance
		And MotionSampling_["Quantitative" + ManyAnalysts.DrCr]
		And MotionSampling_["Count" + ManyAnalysts.DrCr] <> 0;
	
	ManAmounts = New Array();
	AmountsCompl = New Array();
	AmountsVal = New Array();
	Quantities = New Array();
	
	For Each AnalyticsLine_ In ManyAnalysts.AnalyticsLines_ Do
		NewRow = ResourceTable.Add();
		NewRow.Currency = MotionSampling_["Currency" + ManyAnalysts.DrCr];
		
		If RecalculateBalance Then
			ManAmounts.Add(AnalyticsLine_.SumMan);
			AmountsCompl.Add(AnalyticsLine_.SumCompl);
			If RecalculateAmounts_ Then
				AmountsVal.Add(AnalyticsLine_.SumCurr);
			EndIf;
			If RecalculateQuantities Then
				Quantities.Add(AnalyticsLine_.Count);
			EndIf;
		Else
			FillPropertyValues(NewRow, AnalyticsLine_, "SumMan,SumCompl,SumCurr,Count");
		EndIf;
	EndDo;
	
	If RecalculateBalance Then
		DistributionOfAmountOfMan = CommonClientServer.DistributeAmountInProportionToCoefficients(
			MotionSampling_.SumMan, ManAmounts, ParametersForGeneratingTransactions.SumAccuracy);
		If DistributionOfAmountOfMan <> Undefined Then
			ResourceTable.LoadColumn(DistributionOfAmountOfMan, "SumMan");
		EndIf;
		
		LocalSumDistribution = CommonClientServer.DistributeAmountInProportionToCoefficients(
			MotionSampling_.SumCompl, AmountsCompl, ParametersForGeneratingTransactions.SumAccuracy);
		If LocalSumDistribution <> Undefined Then
			ResourceTable.LoadColumn(LocalSumDistribution, "SumCompl");
		EndIf;
		
		If RecalculateAmounts_ Then
			DistributionOfAmountOfShaft = CommonClientServer.DistributeAmountInProportionToCoefficients(
				MotionSampling_["SumCurr" + ManyAnalysts.DrCr], AmountsVal, ParametersForGeneratingTransactions.SumAccuracy);
			If DistributionOfAmountOfShaft <> Undefined Then
				ResourceTable.LoadColumn(DistributionOfAmountOfShaft, "SumCurr");
			EndIf;
		EndIf;
		
		If RecalculateQuantities Then
			QuantityDistribution = CommonClientServer.DistributeAmountInProportionToCoefficients(
				MotionSampling_["Count" + ManyAnalysts.DrCr], Quantities, ParametersForGeneratingTransactions.QuantityAccuracy);
			If QuantityDistribution <> Undefined Then
				ResourceTable.LoadColumn(QuantityDistribution, "Count");
			EndIf;
		EndIf;
	EndIf;
	
	Return ResourceTable;
	
EndFunction

Function DistributedResourcesOfSingleAnalytics(MotionSampling_, OneDimension, ResourcesOfManyAnalysts, ParametersForGeneratingTransactions) Export
	
	DescriptionOfAmount = Common.TypeDescriptionNumber(ParametersForGeneratingTransactions.LengthOfSum, ParametersForGeneratingTransactions.SumAccuracy);
	DescriptionOfQuantity = Common.TypeDescriptionNumber(ParametersForGeneratingTransactions.LengthOfQuantity, ParametersForGeneratingTransactions.QuantityAccuracy);
	
	ResourceTable = New ValueTable();
	ResourceTable.Columns.Add("Currency", New TypeDescription("CatalogRef.Currencies"));
	ResourceTable.Columns.Add("SumCurr", DescriptionOfAmount);
	ResourceTable.Columns.Add("Count", DescriptionOfQuantity);
	
	DistributeAmountOfShaft = MotionSampling_["Currency1" + OneDimension.DrCr]
		And MotionSampling_["SumCurr" + OneDimension.DrCr] <> 0;
	AllocateQuantity = MotionSampling_["Quantitative" + OneDimension.DrCr]
		And MotionSampling_["Count" + OneDimension.DrCr] <> 0;
	
	ManAmounts = New Array();
	AmountsCompl = New Array();
	
	AllManAmountsAreZero = True;
	AllManSumsAreNotZero = True;
	AllLocalSumsAreZero = True;
	AllLocalSumsAreNonZero = True;
	
	For Each StringOfManyResources In ResourcesOfManyAnalysts Do
		NewRow = ResourceTable.Add();
		NewRow.Currency = MotionSampling_["Currency" + OneDimension.DrCr];
		
		If DistributeAmountOfShaft Or AllocateQuantity Then
			ManAmounts.Add(StringOfManyResources.SumMan);
			AmountsCompl.Add(StringOfManyResources.SumCompl);
			If StringOfManyResources.SumMan = 0 Then
				AllManSumsAreNotZero = False;
			Else
				AllManAmountsAreZero = False;
			EndIf;
			If StringOfManyResources.SumCompl = 0 Then
				AllLocalSumsAreNonZero = False;
			Else
				AllLocalSumsAreZero = False;
			EndIf;
		EndIf;
	EndDo;
	
	If AllManSumsAreNotZero Then
		Coefficients = ManAmounts;
	ElsIf AllLocalSumsAreNonZero Then
		Coefficients = AmountsCompl;
	ElsIf Not AllManAmountsAreZero Then
		Coefficients = ManAmounts;
	ElsIf Not AllLocalSumsAreZero Then
		Coefficients = AmountsCompl;
	Else
		Return ResourceTable;
	EndIf;
	
	If DistributeAmountOfShaft Then
		DistributionOfAmountOfShaft = CommonClientServer.DistributeAmountInProportionToCoefficients(
			MotionSampling_["SumCurr" + OneDimension.DrCr], Coefficients, ParametersForGeneratingTransactions.SumAccuracy);
		If DistributionOfAmountOfShaft <> Undefined Then
			ResourceTable.LoadColumn(DistributionOfAmountOfShaft, "SumCurr");
		EndIf;
	EndIf;
	
	If AllocateQuantity Then
		QuantityDistribution = CommonClientServer.DistributeAmountInProportionToCoefficients(
			MotionSampling_["Count" + OneDimension.DrCr], Coefficients, ParametersForGeneratingTransactions.QuantityAccuracy);
		If QuantityDistribution <> Undefined Then
			ResourceTable.LoadColumn(QuantityDistribution, "Count");
		EndIf;
	EndIf;
	
	Return ResourceTable;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region ManagingOfflineCalculations

Procedure CalculateDocumentAmountsInAccountingCurrencies(EndDate, DocumentsArray, AdditionalParameters) Export
	
	If Not PrivilegedMode() Then
		SetPrivilegedMode(True);
	EndIf;
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.CalculateDocumentAmountsInAccountingCurrencies(DocumentsArray);
	
	If AdditionalParameters.RecalculateSpeedRegisters Then
		ManagementAccountingPostingServer.UpdateRegisteredRecordsOnNegotiableRegisters(DocumentsArray);
	EndIf;
	
EndProcedure
	
Procedure ToFormRegisterRecordsForVna(EndDate, DocumentsArray, AdditionalParameters) Export
	
	If Not PrivilegedMode() Then
		SetPrivilegedMode(True);
	EndIf;
	
	DeferredFARecordGeneration.PerformOperationOfOperationOnDocuments(DocumentsArray);
	FACostCalculation.PerformOperationOfOperationOnDocuments(DocumentsArray);
	ClosingExpensesFromDisposalOfFixedAssets.PerformOperationOfOperationOnDocuments(DocumentsArray);
	
EndProcedure
	
Procedure ReflectDocumentsInVATAccounting(EndDate, DocumentsArray, AdditionalParameters) Export
	
	If Not PrivilegedMode() Then
		SetPrivilegedMode(True);
	EndIf;
	
	VATCalculationPeriod = EndOfMonth(EndDate);
	VATAccountingERP.ReflectDocumentsInVATAccounting(VATCalculationPeriod, DocumentsArray);
	
EndProcedure

Procedure PerformOfflineCalculation(ExecutionParameters, CalculationProcedure_)
	
	DocumentsPerServing = 1000;
	DocumentsCount = ExecutionParameters.DocumentsForSettlement.Count();
	
	If Not CalculationProcedure_.MultiThreadedExecution Then
		ThreadsCount = 1;
	ElsIf DocumentsCount <= DocumentsPerServing Then
		ThreadsCount = 1;
	Else
		ThreadsCount = ExecutionParameters.ThreadsCount;
	EndIf;
	
	If ThreadsCount = 1 Then
		PerformOfflineCalculationWithCurFlow(ExecutionParameters, CalculationProcedure_);
	Else
		FlowControlTable = New ValueTable();
		FlowControlTable.Columns.Add("MethodName", Common.StringTypeDetails(250));
		FlowControlTable.Columns.Add("EndDate", Common.DateTypeDetails(DateFractions.DateTime));
		FlowControlTable.Columns.Add("DocumentsForSettlement", New TypeDescription("Array"));
		FlowControlTable.Columns.Add("AdditionalParameters", New TypeDescription("Structure"));
		FlowControlTable.Columns.Add("Id", New TypeDescription("UUID"));
		FlowControlTable.Columns.Add("AttemptsNumber", Common.TypeDescriptionNumber(3, 0));
		
		BatchesCount = Int(DocumentsCount / DocumentsPerServing) + 1;
		
		For PortionNumber = 1 To BatchesCount Do
			PortionOfDocuments = New Array();
			
			For DocumentNumber = 1 To DocumentsPerServing Do
				DocumentIndex = (PortionNumber - 1) * DocumentsPerServing + DocumentNumber - 1;
				If DocumentIndex < DocumentsCount Then
					PortionOfDocuments.Add(ExecutionParameters.DocumentsForSettlement[DocumentIndex]);
				Else
					Break;
				EndIf;
			EndDo;
			
			If PortionOfDocuments.Count() > 0 Then
				StreamParameters = FlowControlTable.Add();
				StreamParameters.MethodName = CalculationProcedure_.MethodName;
				StreamParameters.EndDate = ExecutionParameters.EndDate;
				StreamParameters.DocumentsForSettlement = PortionOfDocuments;
				StreamParameters.AdditionalParameters = CalculationProcedure_.AdditionalParameters;
				
				StartOfflineCalculationWithNewStream(StreamParameters);
				
				If FlowControlTable.Count() >= ThreadsCount Then
					WaitingForEndOfOfflineCalculation(FlowControlTable, False);
				EndIf;
			EndIf;
		EndDo;
		
		If FlowControlTable.Count() > 0 Then
			WaitingForEndOfOfflineCalculation(FlowControlTable, True);
		EndIf;
	EndIf;
	
EndProcedure

Procedure PerformOfflineCalculationWithCurFlow(CalculationParameters, CalculationProcedure_)
	
	CommonModule = "FinancialAccountingByBalanceSheetRegisterData";
	FullMethodName = CommonModule + "." + CalculationProcedure_.MethodName;
	
	ExecutionParameters = New Array();
	ExecutionParameters.Add(CalculationParameters.EndDate);
	ExecutionParameters.Add(CalculationParameters.DocumentsForSettlement);
	ExecutionParameters.Add(CalculationProcedure_.AdditionalParameters);
	
	Common.ExecuteConfigurationMethod(FullMethodName, ExecutionParameters);
	
EndProcedure

Procedure StartOfflineCalculationWithNewStream(StreamParameters)
	
	CommonModule = "FinancialAccountingByBalanceSheetRegisterData";
	FullMethodName = CommonModule + "." + StreamParameters.MethodName;
	
	Description = NStr("vi = 'Bổ sung các bản ghi kết chuyển chứng từ vào các biểu ghi kế toán tài chính';
						|ru = 'Доформирование движений документов в регистрах финансового учета';
						|en = 'Finalize the generation of document register records in financial accounting registers'; fa = 'Finalize the generation of document register records in financial accounting registers';
						|it = 'Доформирование движений документов в регистрах финансового учета';
						|pl = 'Finalize the generation of document register records in financial accounting registers';
						|tr = 'Finansal muhasebe kayıtlarındaki belge kayıtlarının tamamlanması'");
	
	ExecutionParameters = New Array();
	ExecutionParameters.Add(StreamParameters.EndDate);
	ExecutionParameters.Add(StreamParameters.DocumentsForSettlement);
	ExecutionParameters.Add(StreamParameters.AdditionalParameters);
	
	NewJob = BackgroundJobs.Execute(FullMethodName, ExecutionParameters,, Description);
	StreamParameters.Id = NewJob.UUID;
	StreamParameters.AttemptsNumber = StreamParameters.AttemptsNumber + 1;
	
EndProcedure

Procedure WaitingForEndOfOfflineCalculation(FlowControlTable, EndOfAllThreads)
	
	Timeout = 60;
	AttemptsNumber = 3;
	
	ActiveTasks = New Array();
	EmergencyTasks = New Array();
	CompletedTasks = New Array();
	
	For Each StreamParameters In FlowControlTable Do
		BackgroundJob = BackgroundJobs.FindByUUID(StreamParameters.Id);
		If BackgroundJob = Undefined Then
			EmergencyTasks.Add(StreamParameters.Id);
		ElsIf BackgroundJob.State = BackgroundJobState.Active Then
			ActiveTasks.Add(BackgroundJob);
		ElsIf BackgroundJob.State = BackgroundJobState.Completed Then
			CompletedTasks.Add(StreamParameters.Id);
		Else
			EmergencyTasks.Add(StreamParameters.Id);
		EndIf;
	EndDo;
	
	While (CompletedTasks.Count() = 0 Or EndOfAllThreads) And ActiveTasks.Count() > 0 Do
		ActiveTasks = BackgroundJobs.WaitForExecutionCompletion(ActiveTasks, Timeout);
		JobsCount = ActiveTasks.Count();
		
		For JobNumber = 1 To JobsCount Do
			ReverseIndex = JobsCount - JobNumber;
			BackgroundJob = ActiveTasks[ReverseIndex];
			
			If BackgroundJob.State <> BackgroundJobState.Active Then
				If BackgroundJob.State = BackgroundJobState.Completed Then
					CompletedTasks.Add(BackgroundJob.UUID);
				Else
					EmergencyTasks.Add(BackgroundJob.UUID);
				EndIf;
				ActiveTasks.Delete(ReverseIndex);
			EndIf;
		EndDo;
	EndDo;
	
	For Each Completed_Task In CompletedTasks Do
		StreamParameters = FlowControlTable.Find(Completed_Task, "Id");
		If StreamParameters <> Undefined Then
			FlowControlTable.Delete(StreamParameters);
		EndIf;
	EndDo;
	
	If EmergencyTasks.Count() > 0 Then
		MessageTexts_ = New Array();
		
		For Each EmergencyJob In EmergencyTasks Do
			StreamParameters = FlowControlTable.Find(EmergencyJob, "Id");
			
			If StreamParameters = Undefined Then
			ElsIf StreamParameters.AttemptsNumber < AttemptsNumber Then
				StartOfflineCalculationWithNewStream(StreamParameters);
			Else
				BackgroundJob = BackgroundJobs.FindByUUID(EmergencyJob);
				If BackgroundJob = Undefined Then
					MessageText = StrTemplate(NStr("vi = 'Không tìm thấy nhiệm vụ nền có tên định danh %1.';
													|ru = 'Фоновое задание с идентификатором %1 не найдено.';
													|en = 'A background job with the %1 ID is not found.'; fa = 'A background job with the %1 ID is not found.';
													|it = 'Фоновое задание с идентификатором %1 не найдено.';
													|pl = 'A background job with the %1 ID is not found.';
													|tr = '%1 kimliğine sahip arka plan işi bulunamadı.'"), EmergencyJob);
				ElsIf BackgroundJob.State = BackgroundJobState.Canceled Then
					MessageText = StrTemplate(NStr("vi = 'Người quản trị đã hủy nhiệm vụ nền có tên định danh %1.';
													|ru = 'Фоновое задание с идентификатором %1 отменено администратором.';
													|en = 'The background job with the %1 ID is canceled by the administrator.'; fa = 'The background job with the %1 ID is canceled by the administrator.';
													|it = 'Фоновое задание с идентификатором %1 отменено администратором.';
													|pl = 'The background job with the %1 ID is canceled by the administrator.';
													|tr = '%1 kimliğine sahip arka plan işi yönetici tarafından iptal edildi'"), EmergencyJob);
				ElsIf BackgroundJob.State = BackgroundJobState.Failed Then
					MessageText = StrTemplate(NStr("vi = 'Đã kết thúc bất thường nhiệm vụ nền có tên định danh %1.';
													|ru = 'Фоновое задание с идентификатором %1 завершено аварийно.';
													|en = 'The background job with the %1 ID crashed.'; fa = 'The background job with the %1 ID crashed.';
													|it = 'Фоновое задание с идентификатором %1 завершено аварийно.';
													|pl = 'The background job with the %1 ID crashed.';
													|tr = '%1 kimliğine sahip arka plan işi arızalı tamamlandı'"), EmergencyJob)
						+ Chars.LF + BriefErrorDescription(BackgroundJob.ErrorInfo);
				Else
					MessageText = StrTemplate(NStr("vi = 'Chưa thực hiện nhiệm vụ nền có tên định danh %1.';
													|ru = 'Фоновое задание с идентификатором %1 не выполнено.';
													|en = 'The background job with the %1 ID is not performed.'; fa = 'The background job with the %1 ID is not performed.';
													|it = 'Фоновое задание с идентификатором %1 не выполнено.';
													|pl = 'The background job with the %1 ID is not performed.';
													|tr = '%1 kimliğine sahip arka plan işi yürütülmedi'"), EmergencyJob);
				EndIf;
				
				MessageTexts_.Add(MessageText);
				
				If BackgroundJob = Undefined Or BackgroundJob.ErrorInfo = Undefined Then
					ErrorPresentation = MessageText;
				Else
					ErrorPresentation = StrTemplate(NStr("vi = 'Đã kết thúc bất thường nhiệm vụ nền có tên định danh %1.';
														|ru = 'Фоновое задание с идентификатором %1 завершено аварийно.';
														|en = 'The background job with the %1 ID crashed.'; fa = 'The background job with the %1 ID crashed.';
														|it = 'Фоновое задание с идентификатором %1 завершено аварийно.';
														|pl = 'The background job with the %1 ID crashed.';
														|tr = '%1 kimliğine sahip arka plan işi arızalı tamamlandı'"), EmergencyJob)
						+ Chars.LF + DetailErrorDescription(BackgroundJob.ErrorInfo);
				EndIf;
				
				WriteLogEvent(
					NStr("vi = 'Bổ sung các bản ghi kết chuyển chứng từ vào các biểu ghi kế toán tài chính';
						|ru = 'Доформирование движений документов в регистрах финансового учета';
						|en = 'Finalize the generation of document register records in financial accounting registers'; fa = 'Finalize the generation of document register records in financial accounting registers';
						|it = 'Доформирование движений документов в регистрах финансового учета';
						|pl = 'Finalize the generation of document register records in financial accounting registers';
						|tr = 'Finansal muhasebe kayıtlarındaki belge kayıtlarının tamamlanması'", Common.DefaultLanguageCode()),
					EventLogLevel.Error,,,
					ErrorPresentation);
			EndIf;
		EndDo;
		
		If MessageTexts_.Count() > 0 Then
			MessageTexts_.Insert(0, NStr("vi = 'Đã xảy ra lỗi bổ sung các bản ghi kết chuyển chứng từ vào các biểu ghi kế toán tài chính';
										|ru = 'Доформирование движений документов в регистрах финансового учета завершилось с ошибкой.';
										|en = 'Errors occurred when finalizing the generation of document register records in financial accounting registers.'; fa = 'Errors occurred when finalizing the generation of document register records in financial accounting registers.';
										|it = 'Доформирование движений документов в регистрах финансового учета завершилось с ошибкой.';
										|pl = 'Errors occurred when finalizing the generation of document register records in financial accounting registers.';
										|tr = 'Finansal muhasebe kayıtlarındaki belge kayıtlarının tamamlanması hatayla sonuçlandı.'"));
			MessageText = StrConcat(CommonClientServer.CollapseArray(MessageTexts_), Chars.LF);
			Raise MessageText;
		ElsIf CompletedTasks.Count() = 0 Or EndOfAllThreads Then
			WaitingForEndOfOfflineCalculation(FlowControlTable, EndOfAllThreads);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormationOfRequestParameters

Function HashSumOfDataSources(DataSources, TypeOfHashFunction)
	
	TableOfSources = New ValueTable();
	TableOfSources.Columns.Add("DataSource", Common.StringTypeDetails(150));
	
	For Each DataSource In DataSources Do
		NewRow = TableOfSources.Add();
		NewRow.DataSource = DataSource;
	EndDo;
	
	TableOfSources.GroupBy("DataSource");
	TableOfSources.Sort("DataSource");
	
	DataHashing = New DataHashing(TypeOfHashFunction);
	DataHashing.Append(StrConcat(TableOfSources.UnloadColumn("DataSource")));
	
	Return Base64String(DataHashing.HashSum);
	
EndFunction

#EndRegion

#Region FormationOfQueryTexts

Function NumericResourceSelectionFields()
	
	SelectionFields1 = New Array();
	
	SelectionFields1.Add("SumMan");
	SelectionFields1.Add("SumCompl");
	SelectionFields1.Add("SumCurr");
	SelectionFields1.Add("Count");
	
	Return SelectionFields1;
	
EndFunction

Function FullNameOfEnumerationValue(EnumerationValue)
	
	MetadataObject = EnumerationValue.Metadata();
	
	If EnumerationValue.IsEmpty() Then
		EnumValueName = "EmptyRef";
	Else
		ValueIndex = Enums[MetadataObject.Name].IndexOf(EnumerationValue);
		EnumValueName = MetadataObject.EnumValues[ValueIndex].Name;
	EndIf;
	
	Return MetadataObject.FullName() + "." + EnumValueName;
	
EndFunction

Function FullNameOfPredefinedValue(PredefinedValue)
	
	MetadataObject = PredefinedValue.Metadata();
	
	If PredefinedValue.IsEmpty() Then
		EnumValueName = "EmptyRef";
	Else
		EnumValueName = PredefinedValue.PredefinedDataName;
	EndIf;
	
	Return MetadataObject.FullName() + "." + EnumValueName;
	
EndFunction

Function TypesOfResidueEntryDocuments()
	
	DocumentTypes = New Array();
	
	DocumentTypes.Add(Type("DocumentRef.OBEntryARAP"));
	DocumentTypes.Add(Type("DocumentRef.OBEntryCash"));
	DocumentTypes.Add(Type("DocumentRef.OBEntrySalesForPastPeriods"));
	DocumentTypes.Add(Type("DocumentRef.OBEntryFinancialInstruments"));
	DocumentTypes.Add(Type("DocumentRef.OBEntryOtherExpenses"));
	DocumentTypes.Add(Type("DocumentRef.OBEntryOtherAssetsAndLiabilities"));
	DocumentTypes.Add(Type("DocumentRef.OBEntryAcquiringContractARAP"));
	DocumentTypes.Add(Type("DocumentRef.OBEntryARAPAdvanceHolders"));
	DocumentTypes.Add(Type("DocumentRef.OBEntryGoods"));
	
	DocumentTypes.Add(Type("DocumentRef.OBEntryOfLeaseSettlements"));
	DocumentTypes.Add(Type("DocumentRef.EntryOfCapitalAssetsBalance2_4"));
	DocumentTypes.Add(Type("DocumentRef.EnterRentalInvestmentBalance"));
	DocumentTypes.Add(Type("DocumentRef.OBEntrySubAssetsAndComponentsOfDepreciation"));
	
	DocumentTypes.Add(Type("DocumentRef.WIPOpeningBalancesByProductionLots"));
	
	FinancialAccountingByBalanceSheetRegisterDataLocalization.AddTypesOfBalanceEntryDocuments(DocumentTypes);
	
	Return DocumentTypes;
	
EndFunction

Function TypesOfRetailSalesDocuments()
	
	DocumentTypes = New Array();
	
	DocumentTypes.Add(Type("DocumentRef.RetailSalesReport"));
	DocumentTypes.Add(Type("DocumentRef.GiftCertificateSale"));
	
	Return DocumentTypes;
	
EndFunction

Function TypesOfRetailReturnsDocuments()
	
	DocumentTypes = New Array();
	
	DocumentTypes.Add(Type("DocumentRef.RetailReturnsReport"));
	DocumentTypes.Add(Type("DocumentRef.ReturnOfGiftCards"));
	
	Return DocumentTypes;
	
EndFunction

Function TypesOfDebtOffsetDocuments()
	
	DocumentTypes = New Array();
	
	DocumentTypes.Add(Type("DocumentRef.ARAPSettlement"));
	
	Return DocumentTypes;
	
EndFunction

Function BusinessTransactionsExcludingForeignCurrency()
	
	ExcludingCurrency = New Array();
	
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesForLeaseProfit);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesForLeaseLoss);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesForDepositsExchangeGain);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesForDepositsExchangeLoss);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeLoss);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesForIssuedBorrowingsExchangeGain);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesForIssuedBorrowingsExchangeLoss);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesCustomersExchangeGain);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesCustomersExchangeLoss);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesForLoansAndBorrowingsExchangeGain);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesForLoansAndBorrowingsExchangeLoss);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesVendorsExchangeGain);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesVendorsExchangeLoss);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesLossAllowanceExchangeGain);
	ExcludingCurrency.Add(Catalogs.BusinessTransactionsSettings.ExchangeDifferencesLossAllowanceExchangeLoss);
	
	Return ExcludingCurrency;
	
EndFunction

Function TypesOfTaxationExcludingVAT()
	
	Excluding_VAT = New Array();
	
	Excluding_VAT.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
	Excluding_VAT.Add(Enums.VATTaxationTypes.SaleIsSubjectToUTII);
	
	Return Excluding_VAT;
	
EndFunction

#EndRegion

#EndRegion