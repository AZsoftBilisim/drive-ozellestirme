
#Region Public

#Region ArticleSelectionAndAnalytics

// Returns the structure of article and Analytics selection parameters 
//
// Returns:
// 	Structure - The selection parameters:
// 		* DataPath - String - Path to the object where the article is stored.
// 		                         For example, " Object "(if the article is the object's details) or " Object.Products" (if the article is a detail of the table part).
// 		* AssetRef - String - The name of the article's props. For example, "Expense articles"
// 		* DefaultValue - Undefined -
// 							  - ChartOfCharacteristicTypesRef.ExpenseItems -
// 							  - ChartOfCharacteristicTypesRef.IncomeItems -
// 							  - ChartOfCharacteristicTypesRef.AssetLiabilityItems - A link to an element of the appropriate type (including an empty link).
// 		* AvailabilityByOperation - Boolean, Undefined - Indicates whether the article selection is available for the current business operation of the document.
// 		                                   If False, the article selection and analysis elements are hidden on the form.
// 		                                   If the value is Undefined, the mechanism does not control the availability of the article. The problem is solved on the document side. 
// 		* HideArticleThatIsUnavailableDueToOperation - Boolean - If True, the fields are hidden. If False, they are made unavailable. The default value is True.
// 		* RequiredFilling - Boolean - If True, the blank mark is set and the filling is checked.
// 		                                      If False, then the blank mark is not set and the fill check is not performed.
// 		
// 		* ChoosingExpenseItem - Boolean - Determines whether an expense Item can be selected as the value. The default value is False.
// 		* DimensionOfExpenses - String - The name of the expense analytics prop (the type of prop).Article of expenses).
// 		* SelectionOfExpenditureItems - Structure - Structure of parameters for additional selection of expenditure items:
//			** Key - String - Name of the selection parameter
//			** Value - Arbitrary - The value of the selection parameter.
// 		
// 		* ChoosingIncomeItem - Boolean - Determines whether an item of revenue can be selected as the value. The default value is False.
// 		* DimensionOfRevenue - String - The name of the revenue analytics prop (the type of prop).Income articles).
// 		
// 		* SelectingItemOfAssetsLiabilities - Boolean - Determines whether an asset/liability Item can be selected as the value. The default value is False.
// 		* AssetsLiabilitiesDimension - String - The name of the asset/liability analytics props (the type of props).Articles of activespassives).
// 		
// 		* FormItems - Structure - structure with keys:
// 			** AssetRef - Array of String - Names of elements in the form for selecting an article (for Example, Productsstatistics, expense Statesreferences)
// 			** DimensionOfExpenses - Array of String - Names of the form elements for selecting the expense item analysis.
// 			** DimensionOfRevenue - Array of String - Names of form elements for selecting revenue item Analytics.
// 			** AssetsLiabilitiesDimension - Array of String - Names of form elements for selecting the asset/liability item analysis.
// 		
// 		* ArticleType - String - The name of the service details of the form in which the numeric value of the article type is stored.
// 		                               The props can take values:
// 		                                0 - The article has an Undefined value;
// 		                                1 - if the article has a type of plan, a characteristiclink.Articles of expenditure;
// 		                                2 - if the article has a type of plan, a characteristiclink.Income statesreferences;
// 		                                3 - if the article has a type of plan, a characteristiclink.Articles of Asset arrays.
// 		
// 		* ArticleAvailabilityCriteriaInLines - Structure - Additional conditions for the availability of the article in the rows of the table. If there are several conditions, then availability is determined by "And":
// 			** Key - String - Name of the table detail that determines the availability of the article.
//			** Value - Boolean -
//			- AnyRef -
//			- Array of Arbitrary -
//			- ValueList of Arbitrary - The value of the requisite for which the article selection is available.
//		* ConditionsForMandatoryAnalyticsInRows - Structure
// 		* HideInaccessibleArticlesInRows - Boolean - If True, then articles and Analytics that are not available in the lines are hidden.
// 		                                               If False, then the cells are set to only View. The default value is False.
// 
Function ArticleSelectionAndAnalyticsOptions() Export
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("DataPath", "");
	ChoiceParameters.Insert("AssetRef",      "");
	ChoiceParameters.Insert("DefaultValue",   Undefined);
	
	ChoiceParameters.Insert("AvailabilityByOperation", True);
	ChoiceParameters.Insert("HideArticleThatIsUnavailableDueToOperation", True);
	ChoiceParameters.Insert("RequiredFilling", True);
	
	ChoiceParameters.Insert("ChoosingExpenseItem", False);
	ChoiceParameters.Insert("DimensionOfExpenses",   "");
	ChoiceParameters.Insert("SelectionOfExpenditureItems", New Structure());
	ChoiceParameters.SelectionOfExpenditureItems.Insert("BusinessOperation");
	ChoiceParameters.SelectionOfExpenditureItems.Insert("CostAllocationOption");
	
	ChoiceParameters.Insert("ChoosingIncomeItem", False);
	ChoiceParameters.Insert("DimensionOfRevenue",   "");
	
	ChoiceParameters.Insert("SelectingItemOfAssetsLiabilities", False);
	ChoiceParameters.Insert("AssetsLiabilitiesDimension",   "");
	
	ChoiceParameters.Insert("ArticleType",     "");
	
	FormItems = New Structure;
	FormItems.Insert("AssetRef",                   New Array());
	FormItems.Insert("DimensionOfExpenses",        New Array());
	FormItems.Insert("DimensionOfRevenue",         New Array());
	FormItems.Insert("AssetsLiabilitiesDimension", New Array());
	ChoiceParameters.Insert("FormItems", FormItems);
	
	ChoiceParameters.Insert("ArticleAvailabilityCriteriaInLines", New Structure);
	ChoiceParameters.Insert("ConditionsForMandatoryAnalyticsInRows", New Structure);
	ChoiceParameters.Insert("HideInaccessibleArticlesInRows", False);
	
	Return ChoiceParameters;
	
EndFunction

// Initializes empty article values with the default value.
// Called in the corresponding event handler for the object.
//
// Parameters:
// 	Object - DocumentObject - Object
// 	ChoiceParameters - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
// 					- See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Procedure Filling(Object, Val ChoiceParameters) Export
	
	If TypeOf(ChoiceParameters) = Type("Array") Then
		ChoiceParametersArray = ChoiceParameters;
	Else
		ChoiceParametersArray = CommonClientServer.ValueInArray(ChoiceParameters);
	EndIf;
	
	InitializeArticleAndAnalystValues_(Object, ChoiceParametersArray);
	
EndProcedure

// Initializes empty article values with the default value.
// Called in the corresponding event handler for the object.
//
// Parameters:
// 	Object - DocumentObject - Object
// 	ChoiceParameters - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
// 					- See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Procedure BeforeWrite(Object, Val ChoiceParameters) Export
	
	If TypeOf(ChoiceParameters) = Type("Array") Then
		ChoiceParametersArray = ChoiceParameters;
	Else
		ChoiceParametersArray = CommonClientServer.ValueInArray(ChoiceParameters);
	EndIf;
	
	InitializeArticleAndAnalystValues_(Object, ChoiceParametersArray);
	
EndProcedure

// Checks the completion of articles and Analytics in the object.
// Called in the corresponding event handler for the object.
//
// Parameters:
// 	Object - DocumentObject - Object
// 	Cancel - Boolean - Write failure flag.
// 	CheckedAttributes - Array of String  - Array of object details to check.
// 	ChoiceParameters - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
// 					- See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes, Val ChoiceParameters) Export
	
	If TypeOf(ChoiceParameters) = Type("Array") Then
		ChoiceParametersArray = ChoiceParameters;
	Else
		ChoiceParametersArray = CommonClientServer.ValueInArray(ChoiceParameters);
	EndIf;
	
	NotCheckedAttributeArray = New Array; // Array of String
	
	For Each ChoiceParameters In ChoiceParametersArray Do
		
		DataPathParts = StrSplit(ChoiceParameters.DataPath, ".");
		If DataPathParts.Count() > 1 Then
			ThisIsTable = True;
			TableName = DataPathParts[1];
		ElsIf DataPathParts.Count() = 1
			And Not DataPathParts[0] = ""
			And TypeOf(Object) = Type("Structure")
			And TypeOf(Object[ChoiceParameters.DataPath]) = Type("ValueTable") Then
			
			ThisIsTable = True;
			TableName = ChoiceParameters.DataPath;
			
		Else
			ThisIsTable = False;
			TableName = "";
		EndIf;
		
		PathPrefix = ?(ValueIsFilled(TableName), TableName + ".", "");
		
		AvailabilityByOperation = True;
		If ChoiceParameters.AvailabilityByOperation <> Undefined And Not ChoiceParameters.AvailabilityByOperation Then
			AvailabilityByOperation = False;
			NotCheckedAttributeArray.Add(PathPrefix + ChoiceParameters.AssetRef);
		EndIf;
		
		If Not ChoiceParameters.RequiredFilling Then
			NotCheckedAttributeArray.Add(PathPrefix + ChoiceParameters.AssetRef);
		EndIf;
		
		AdditionalParameters = ?(ChoiceParameters.Property("AdditionalParameters"),
									ChoiceParameters.AdditionalParameters,
									Undefined);
		
		If ThisIsTable
			And ValueIsFilled(ChoiceParameters.ArticleAvailabilityCriteriaInLines) Then
			
			NotCheckedAttributeArray.Add(PathPrefix + ChoiceParameters.AssetRef);
			
			DataKey = TMCommonUse.DataKeyForMessageToUser(Object);
			
			If TypeOf(Object[TableName]) = Type("ValueTable") Then
				DataPath				= "";
				PresentationOfTS			= AdditionalParameters.PresentationOfTS;
				AttributeRepresentation	= AdditionalParameters.DetailsPresentations[ChoiceParameters.AssetRef];
			Else
				ObjectMetadata	= Object.Metadata();
				TabularSection		= ObjectMetadata.TabularSections.Find(TableName);
				Attribute			= TabularSection.Attributes.Find(ChoiceParameters.AssetRef);
				
				DataPath				= "Object";
				PresentationOfTS			= TabularSection.Synonym;
				AttributeRepresentation	= Attribute.Synonym;
			EndIf;
			
			For Each String In Object[TableName] Do // LineOfATabularSection
				LineAvailability = AvailabilityByOperation;
				For Each KeyAndValue In ChoiceParameters.ArticleAvailabilityCriteriaInLines Do
					If TypeOf(KeyAndValue.Value) = Type("Array") Then
						If KeyAndValue.Value.Find(String[KeyAndValue.Key]) = Undefined Then
							LineAvailability = False;
						EndIf;
					ElsIf TypeOf(KeyAndValue.Value) = Type("ValueList") Then
						If KeyAndValue.Value.FindByValue(String[KeyAndValue.Key]) = Undefined Then
							LineAvailability = False;
						EndIf;
					ElsIf String[KeyAndValue.Key] <> KeyAndValue.Value Then
						LineAvailability = False;
					EndIf;
					If Not LineAvailability Then
						Break;
					EndIf;
				EndDo;
				If LineAvailability
					And Not ValueIsFilled(String[ChoiceParameters.AssetRef]) Then
					
					Field = CommonClientServer.PathToTabularSection(TableName, String.LineNumber, ChoiceParameters.AssetRef);
					MessageTemplate = NStr("vi = 'Chưa điền trường ""%1"" trong hàng %2 của danh sách ""%3""';
											|ru = 'Не заполнено поле ""%1"" в строке %2 списка ""%3""';
											|en = '""%1"" in line %2 of list ""%3"" is required'; fa = '""%1"" in line %2 of list ""%3"" is required';
											|it = 'Не заполнено поле ""%1"" в строке %2 списка ""%3""';
											|pl = 'Nie zostało wypełnione pole ""%1"" w wierszu %2 listy ""%3""';
											|tr = '""%3"" listesinin %2 satırındaki ""%1"" alanı doldurulmadı'");
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
						MessageTemplate,
						AttributeRepresentation,
						Format(String.LineNumber, "NG=;"),
						PresentationOfTS);
					
					Common.MessageToUser(
						MessageText,
						DataKey,
						Field,
						DataPath,
						Cancel);
					
				EndIf;
			EndDo;
		EndIf;
		
		If ValueIsFilled(ChoiceParameters.DimensionOfExpenses)
			And CheckedAttributes.Find(PathPrefix + ChoiceParameters.DimensionOfExpenses) <> Undefined Then
			
			Attributes = ChoiceParameters.AssetRef + "," + ChoiceParameters.DimensionOfExpenses;
			
			If ThisIsTable Then
				Attributes = New Structure(TableName, Attributes);
			EndIf;
			
			ChartsOfCharacteristicTypes.ExpenseItems.CheckAnalystCompletion(
				Object,
				Attributes,
				NotCheckedAttributeArray,
				Cancel,
				AdditionalParameters);
			
		EndIf;
		
		If ValueIsFilled(ChoiceParameters.DimensionOfRevenue)
			And CheckedAttributes.Find(PathPrefix + ChoiceParameters.DimensionOfRevenue) <> Undefined Then
			
			Attributes = ChoiceParameters.AssetRef + "," + ChoiceParameters.DimensionOfRevenue;
			
			If ThisIsTable Then
				Attributes = New Structure(TableName, Attributes);
			EndIf;
			
			ChartsOfCharacteristicTypes.IncomeItems.CheckAnalystCompletion(
				Object,
				Attributes,
				NotCheckedAttributeArray,
				Cancel,
				AdditionalParameters);
			
		EndIf;
		
		If ValueIsFilled(ChoiceParameters.AssetsLiabilitiesDimension)
			And CheckedAttributes.Find(PathPrefix + ChoiceParameters.AssetsLiabilitiesDimension) <> Undefined Then
			
			NotCheckedAttributeArray.Add(PathPrefix + ChoiceParameters.AssetsLiabilitiesDimension);
			
		EndIf;
		
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

// Configures the object form for selecting articles and Analytics when creating a form on the server.
// Called in the corresponding event handler of the form.
//
// Parameters:
// 	Form - ClientApplicationForm - object form:
// 		* Object - DocumentObject - form object
// 	ChoiceParameters - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
// 					- See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Procedure OnCreateAtServer(Form, Val ChoiceParameters) Export
	
	DataSelectArticlesAndAnalytics = DataSelectArticlesAndAnalytics(Form, ChoiceParameters);
	
	#Region SettingConditionalAppearance
	ConditionalAppearance = Form.ConditionalAppearance;
	For Each Parameters In DataSelectArticlesAndAnalytics.ChoiceParametersArray Do
		
		DataPathParts = StrSplit(Parameters.DataPath, ".");
		If DataPathParts.Count() = 1
			And Parameters.DataPath <> ""
			And TypeOf(Form[Parameters.DataPath]) = Type("FormDataCollection") Then
			PathToServiceDetails = Parameters.DataPath;
		ElsIf DataPathParts.Count() = 1 Then
			PathToServiceDetails = "";
		Else
			PathToServiceDetails = Parameters.DataPath;
		EndIf;
		
		#Region AvailabilityInTableRowsByCondition
		If ValueIsFilled(Parameters.ArticleAvailabilityCriteriaInLines) Then
			
			AppearanceItem = ConditionalAppearance.Items.Add();
			For Each TagName In Parameters.FormItems.AssetRef Do
				ItemField = AppearanceItem.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(TagName);
			EndDo;
			
			If Parameters.ChoosingExpenseItem And ValueIsFilled(Parameters.FormItems.DimensionOfExpenses) Then
				For Each TagName In Parameters.FormItems.DimensionOfExpenses Do
					ItemField = AppearanceItem.Fields.Items.Add();
					ItemField.Field = New DataCompositionField(TagName);
				EndDo;
			EndIf;
			
			If Parameters.ChoosingIncomeItem And ValueIsFilled(Parameters.FormItems.DimensionOfExpenses) Then
				For Each TagName In Parameters.FormItems.DimensionOfRevenue Do
					ItemField = AppearanceItem.Fields.Items.Add();
					ItemField.Field = New DataCompositionField(TagName);
				EndDo;
			EndIf;
			
			If Parameters.SelectingItemOfAssetsLiabilities And ValueIsFilled(Parameters.FormItems.AssetsLiabilitiesDimension) Then
				For Each TagName In Parameters.FormItems.AssetsLiabilitiesDimension Do
					ItemField = AppearanceItem.Fields.Items.Add();
					ItemField.Field = New DataCompositionField(TagName);
				EndDo;
			EndIf;
			
			Group = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
			Group.GroupType =  DataCompositionFilterItemsGroupType.OrGroup;
			For Each FieldAndValue In Parameters.ArticleAvailabilityCriteriaInLines Do
				ItemFilter = Group.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = DataCompositionField(Parameters.DataPath, FieldAndValue.Key);
				
				If TypeOf(FieldAndValue.Value) = Type("Array") Then
					FilterValue = New ValueList();
					FilterValue.LoadValues(FieldAndValue.Value);
					LayoutComparisonView = DataCompositionComparisonType.NotInList;
				ElsIf TypeOf(FieldAndValue.Value) = Type("ValueList") Then
					FilterValue = FieldAndValue.Value;
					LayoutComparisonView = DataCompositionComparisonType.NotInList;
				Else
					FilterValue = FieldAndValue.Value;
					LayoutComparisonView = DataCompositionComparisonType.NotEqual; 
				EndIf;
				ItemFilter.ComparisonType = LayoutComparisonView;
				ItemFilter.RightValue = FilterValue;
			EndDo;
			
			If Parameters.HideInaccessibleArticlesInRows Then
				AppearanceItem.Appearance.SetParameterValue("Visible", False);
			Else
				AppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
			EndIf;
			AppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
			
		EndIf;
		#EndRegion
		
		If ValueIsFilled(Parameters.FormItems.DimensionOfExpenses) Then
			
			#Region MarkIncomplete
			AppearanceItem = ConditionalAppearance.Items.Add();
			For Each TagName In Parameters.FormItems.DimensionOfExpenses Do
				ItemField = AppearanceItem.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(TagName);
			EndDo;
			
			ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = DataCompositionField(PathToServiceDetails, Parameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesRequired_);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
			ItemFilter.RightValue = True;
			
			AppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
			
			///////////////////////
			AppearanceItem = ConditionalAppearance.Items.Add();
			For Each TagName In Parameters.FormItems.DimensionOfExpenses Do
				ItemField = AppearanceItem.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(TagName);
			EndDo;
			
			ListOfConditions = Parameters.ConditionsForMandatoryAnalyticsInRows;
			If ListOfConditions.Count() <> 0 Then
				For Each StructureItem In ListOfConditions Do
					ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
					ItemFilter.LeftValue = DataCompositionField(PathToServiceDetails, StructureItem.Key);
					ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
					ItemFilter.RightValue = StructureItem.Value;
				EndDo;
			Else
				ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = DataCompositionField(PathToServiceDetails, Parameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesRequired_);
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = True;
			EndIf;
			
			ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = DataCompositionField(Parameters.DataPath, Parameters.DimensionOfExpenses);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			AppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
			#EndRegion
			
			#Region Visible
			If ValueIsFilled(Parameters.ArticleType) Then
				
				AppearanceItem = ConditionalAppearance.Items.Add();
				For Each TagName In Parameters.FormItems.DimensionOfExpenses Do
					ItemField = AppearanceItem.Fields.Items.Add();
					ItemField.Field = New DataCompositionField(TagName);
				EndDo;
				
				ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = DataCompositionField(PathToServiceDetails, Parameters.ArticleType);
				ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
				ItemFilter.RightValue = 1;
				
				AppearanceItem.Appearance.SetParameterValue("Visible", False);
				
			EndIf;
			#EndRegion
			
			#Region ReadOnly
			Item = ConditionalAppearance.Items.Add();
			
			For Each TagName In Parameters.FormItems.DimensionOfExpenses Do
				ItemField = Item.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(TagName);
			EndDo;
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = DataCompositionField(Parameters.DataPath, Parameters.AssetRef);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = DataCompositionField(Parameters.DataPath, Parameters.DimensionOfExpenses);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			For Each FieldAndValue In Parameters.ArticleAvailabilityCriteriaInLines Do
				ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = DataCompositionField(Parameters.DataPath, FieldAndValue.Key);
				
				If TypeOf(FieldAndValue.Value) = Type("Array") Then
					FilterValue = New ValueList();
					FilterValue.LoadValues(FieldAndValue.Value);
					LayoutComparisonView = DataCompositionComparisonType.InList;
				ElsIf TypeOf(FieldAndValue.Value) = Type("ValueList") Then
					FilterValue = FieldAndValue.Value;
					LayoutComparisonView = DataCompositionComparisonType.InList;
				Else
					FilterValue = FieldAndValue.Value;
					LayoutComparisonView = DataCompositionComparisonType.Equal; 
				EndIf;
				ItemFilter.ComparisonType = LayoutComparisonView;
				ItemFilter.RightValue = FilterValue;
			EndDo;
			
			If ValueIsFilled(Parameters.ArticleType) Then
				ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = DataCompositionField(PathToServiceDetails, Parameters.ArticleType);
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = 1;
			EndIf;
			
			Item.Appearance.SetParameterValue("MarkIncomplete", False);
			Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
			Item.Appearance.SetParameterValue("Text", NStr("vi = '<hãy chọn dạng chi phí>';
															|ru = '<выберите статью расходов>';
															|en = '<select an expense item>'; fa = '<select an expense item>';
															|it = '<selezionare la voce delle spese>';
															|pl = '<wybierz pozycję wydatków>';
															|tr = '<maliyet kalemini seçin>'"));
			Item.Appearance.SetParameterValue("ReadOnly", True);
			#EndRegion

		EndIf;
		
		If ValueIsFilled(Parameters.FormItems.DimensionOfRevenue) Then 
			
			#Region MarkIncomplete
			AppearanceItem = ConditionalAppearance.Items.Add();
			For Each TagName In Parameters.FormItems.DimensionOfRevenue Do
				ItemField = AppearanceItem.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(TagName);
			EndDo;
			ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = DataCompositionField(PathToServiceDetails, Parameters.CacheOfIncomeItemDetails.DimensionOfRevenueRequired_);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
			ItemFilter.RightValue = True;
			
			AppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
			
			AppearanceItem = ConditionalAppearance.Items.Add();
			For Each TagName In Parameters.FormItems.DimensionOfRevenue Do
				ItemField = AppearanceItem.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(TagName);
			EndDo;
			
			ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = DataCompositionField(PathToServiceDetails, Parameters.CacheOfIncomeItemDetails.DimensionOfRevenueRequired_);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;
			
			ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = DataCompositionField(Parameters.DataPath, Parameters.DimensionOfRevenue);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			AppearanceItem.Appearance.SetParameterValue("MarkIncomplete", True);
			#EndRegion
			
			#Region Visible
			If ValueIsFilled(Parameters.ArticleType) Then
				AppearanceItem = ConditionalAppearance.Items.Add();
				For Each TagName In Parameters.FormItems.DimensionOfRevenue Do
					ItemField = AppearanceItem.Fields.Items.Add();
					ItemField.Field = New DataCompositionField(TagName);
				EndDo;
				
				ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = DataCompositionField(PathToServiceDetails, Parameters.ArticleType);
				ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
				ItemFilter.RightValue = 2;
				
				AppearanceItem.Appearance.SetParameterValue("Visible", False);
			EndIf;
			#EndRegion
		
			#Region ReadOnly
			Item = ConditionalAppearance.Items.Add();
			
			For Each TagName In Parameters.FormItems.DimensionOfRevenue Do
				ItemField = Item.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(TagName);
			EndDo;
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = DataCompositionField(Parameters.DataPath, Parameters.AssetRef);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = DataCompositionField(Parameters.DataPath, Parameters.DimensionOfRevenue);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			For Each FieldAndValue In Parameters.ArticleAvailabilityCriteriaInLines Do
				ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = DataCompositionField(Parameters.DataPath, FieldAndValue.Key);
				
				If TypeOf(FieldAndValue.Value) = Type("Array") Then
					FilterValue = New ValueList();
					FilterValue.LoadValues(FieldAndValue.Value);
					LayoutComparisonView = DataCompositionComparisonType.InList;
				ElsIf TypeOf(FieldAndValue.Value) = Type("ValueList") Then
					FilterValue = FieldAndValue.Value;
					LayoutComparisonView = DataCompositionComparisonType.InList;
				Else
					FilterValue = FieldAndValue.Value;
					LayoutComparisonView = DataCompositionComparisonType.Equal; 
				EndIf;
				ItemFilter.ComparisonType = LayoutComparisonView;
				ItemFilter.RightValue = FilterValue;
			EndDo;
			
			If ValueIsFilled(Parameters.ArticleType) Then
				ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = DataCompositionField(PathToServiceDetails, Parameters.ArticleType);
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = 2;
			EndIf;
			
			Item.Appearance.SetParameterValue("MarkIncomplete", False);
			Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
			Item.Appearance.SetParameterValue("Text", NStr("vi = '<chọn dạng thu nhập>';
															|ru = '<выберите статью доходов>';
															|en = '<choose an income item>'; fa = '<choose an income item>';
															|it = '<selezionare la voce delle entrate>';
															|pl = '<wybierz artykuł dochodów>';
															|tr = '<gelir öğesini seç>'"));
			Item.Appearance.SetParameterValue("ReadOnly", True);
			#EndRegion
		
		EndIf;
		
		If ValueIsFilled(Parameters.FormItems.AssetsLiabilitiesDimension) Then

			#Region CheckNotUsed
			AppearanceItem = ConditionalAppearance.Items.Add();
			For Each TagName In Parameters.FormItems.AssetsLiabilitiesDimension Do
				ItemField = AppearanceItem.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(TagName);
			EndDo;
			
			ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = DataCompositionField(PathToServiceDetails, Parameters.CacheOfDetailsOfItemOfAssetsLiabilities.AssetsLiabilitiesDimensionNotUsed);
			ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
			ItemFilter.RightValue = True;
			
			AppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
			AppearanceItem.Appearance.SetParameterValue("MarkIncomplete", False);
			AppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
			AppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Không sử dụng ';
																	|ru = 'Не используется';
																	|en = 'Not used'; fa = 'استفاده نمی‌شود';
																	|it = 'Non viene utilizzato';
																	|pl = 'Nie używane';
																	|tr = 'Kullanılmıyor'"));
			#EndRegion
			
			#Region Visible
			If ValueIsFilled(Parameters.ArticleType) Then
				
				AppearanceItem = ConditionalAppearance.Items.Add();
				For Each TagName In Parameters.FormItems.AssetsLiabilitiesDimension Do
					ItemField = AppearanceItem.Fields.Items.Add();
					ItemField.Field = New DataCompositionField(TagName);
				EndDo;
				
				ItemFilter = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = DataCompositionField(PathToServiceDetails, Parameters.ArticleType);
				ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
				ItemFilter.RightValue = 3;
				
				AppearanceItem.Appearance.SetParameterValue("Visible", False);
			EndIf;
			#EndRegion
			
			#Region ReadOnly
			Item = ConditionalAppearance.Items.Add();
			
			For Each TagName In Parameters.FormItems.AssetsLiabilitiesDimension Do
				ItemField = Item.Fields.Items.Add();
				ItemField.Field = New DataCompositionField(TagName);
			EndDo;
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = DataCompositionField(Parameters.DataPath, Parameters.AssetRef);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
			ItemFilter.LeftValue = DataCompositionField(Parameters.DataPath, Parameters.AssetsLiabilitiesDimension);
			ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
			
			For Each FieldAndValue In Parameters.ArticleAvailabilityCriteriaInLines Do
				ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = DataCompositionField(Parameters.DataPath, FieldAndValue.Key);
				
				If TypeOf(FieldAndValue.Value) = Type("Array") Then
					FilterValue = New ValueList();
					FilterValue.LoadValues(FieldAndValue.Value);
					LayoutComparisonView = DataCompositionComparisonType.InList;
				ElsIf TypeOf(FieldAndValue.Value) = Type("ValueList") Then
					FilterValue = FieldAndValue.Value;
					LayoutComparisonView = DataCompositionComparisonType.InList;
				Else
					FilterValue = FieldAndValue.Value;
					LayoutComparisonView = DataCompositionComparisonType.Equal; 
				EndIf;
				ItemFilter.ComparisonType = LayoutComparisonView;
				ItemFilter.RightValue = FilterValue;
			EndDo;
			
			If ValueIsFilled(Parameters.ArticleType) Then
				ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
				ItemFilter.LeftValue = DataCompositionField(PathToServiceDetails, Parameters.ArticleType);
				ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
				ItemFilter.RightValue = 3;
			EndIf;
			
			Item.Appearance.SetParameterValue("MarkIncomplete", False);
			Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
			Item.Appearance.SetParameterValue("Text", NStr("vi = '<chọn dạng tài sản/nguồn vốn>';
															|ru = '<выберите статью активов/пассивов>';
															|en = '<choose an assets/liabilities item>'; fa = '<choose an assets/liabilities item>';
															|it = '<selezionare la voce attività / passività>';
															|pl = '<wybierz artykuł aktywów/pasywów>';
															|tr = '<varlık/yükümlülük kalemini seç>'"));
			Item.Appearance.SetParameterValue("ReadOnly", True);
			#EndRegion
		EndIf; 
	EndDo;
	#EndRegion
	
	If CommonClientServer.HasAttributeOrObjectProperty(Form, "Object")
		 And CommonClientServer.HasAttributeOrObjectProperty(Form.Object, "Ref")
		 And ValueIsFilled(Form.Object.Ref) Then
		Return;
	EndIf;
	
	TMCommonUse.SaveEngineDataToFormCache(Form, "ArticleSelectionAndAnalytics", DataSelectArticlesAndAnalytics);
	
	UpdateArticleDetails(Form, DataSelectArticlesAndAnalytics.ChoiceParametersArray);
	SetPropertiesOfArticleElements(Form, DataSelectArticlesAndAnalytics.ChoiceParametersArray);
	ConnectAnalystWithArticles(Form, DataSelectArticlesAndAnalytics.ChoiceParametersArray);
	For Each ChoiceParameters In DataSelectArticlesAndAnalytics.ChoiceParametersArray Do
		IncomeAndExpensesClientServer.SetPropertiesOfAnalyticsElements(Form, ChoiceParameters);
	EndDo
	
EndProcedure

// Configures the object form for selecting articles and Analytics when reading the object on the server.
// Called in the corresponding event handler of the form.
//
// Parameters:
// 	Form - ClientApplicationForm - object form
// 	ChoiceParameters - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
// 					- See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Procedure OnReadAtServer(Form, Val ChoiceParameters) Export
	
	DataSelectArticlesAndAnalytics = DataSelectArticlesAndAnalytics(Form, ChoiceParameters);
	TMCommonUse.SaveEngineDataToFormCache(Form, "ArticleSelectionAndAnalytics", DataSelectArticlesAndAnalytics);
	
	UpdateArticleDetails(Form, DataSelectArticlesAndAnalytics.ChoiceParametersArray);
	SetPropertiesOfArticleElements(Form, DataSelectArticlesAndAnalytics.ChoiceParametersArray);
	ConnectAnalystWithArticles(Form, DataSelectArticlesAndAnalytics.ChoiceParametersArray);
	For Each ChoiceParameters In DataSelectArticlesAndAnalytics.ChoiceParametersArray Do
		IncomeAndExpensesClientServer.SetPropertiesOfAnalyticsElements(Form, ChoiceParameters);
	EndDo;
	
EndProcedure

// Updates the service details for selecting articles and Analytics after recording on the server.
// Called in the corresponding event handler of the form.
//
// Parameters:
// 	Form - ClientApplicationForm - object form
//
Procedure AfterWriteAtServer(Form) Export
	
	DataSelectArticlesAndAnalytics = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ArticleSelectionAndAnalytics");
	UpdateArticleDetails(Form, DataSelectArticlesAndAnalytics.ChoiceParametersArray);
	
EndProcedure

// Updates the service details for selecting articles and Analytics 
// Called when it is necessary (for example after conversion of the object into the requisite shape).
// 
// Parameters:
// 	Form - ClientApplicationForm - object form
//
Procedure UpdateServiceDetails(Form) Export
	
	DataSelectArticlesAndAnalytics = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ArticleSelectionAndAnalytics");
	UpdateArticleDetails(Form, DataSelectArticlesAndAnalytics.ChoiceParametersArray);	
	
EndProcedure

// Checks whether the selected articles and Analytics match the passed selection parameters.
// Configures the form for the new selection parameters.
//
// Parameters:
// 	Form - ClientApplicationForm - object form
// 	ChoiceParameters - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
// 					- See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Procedure WhenChangingArticleSelectionParameters(Form, Val ChoiceParameters) Export
	
	DataSelectArticlesAndAnalytics = DataSelectArticlesAndAnalytics(Form, ChoiceParameters);
	TMCommonUse.SaveEngineDataToFormCache(Form, "ArticleSelectionAndAnalytics", DataSelectArticlesAndAnalytics);
	
	InitializeArticleAndAnalystValues_(Form, DataSelectArticlesAndAnalytics.ChoiceParametersArray);
	
	UpdateArticleDetails(Form, DataSelectArticlesAndAnalytics.ChoiceParametersArray);
	SetPropertiesOfArticleElements(Form, DataSelectArticlesAndAnalytics.ChoiceParametersArray);
	ConnectAnalystWithArticles(Form, DataSelectArticlesAndAnalytics.ChoiceParametersArray);
	For Each ChoiceParameters In DataSelectArticlesAndAnalytics.ChoiceParametersArray Do
		IncomeAndExpensesClientServer.SetPropertiesOfAnalyticsElements(Form, ChoiceParameters);
	EndDo
	
EndProcedure

// Fills in the tabular part of the line article and analysis of expenses write-off items for statistics.
// Called from the Batch processing mechanism of the table part.
// 
// Parameters:
// 	CurrentRow - Structure - Line data.
// 	Product - Reference referenceslink.Products - The Products for which you need to fill out the item and the cost analysis.
// 	ActionParameters - Structure - the parameters of the action. (See IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts)
//
Procedure FillInArticleAndAnalysisOfProductLineExpenses(CurrentRow, ActionParameters) Export
	
	If ValueIsFilled(CurrentRow[ActionParameters.ExpenseItem]) Then
		Return;
	EndIf;
	
	Products = CurrentRow.Products;
	CharacteristicIsSpecified = CommonClientServer.HasAttributeOrObjectProperty(CurrentRow, "Characteristic")
								And ValueIsFilled(CurrentRow.Characteristic);
	
	ArticleAndAnalytics = 
		DefaultExpenseAnalyticsItem(
			ActionParameters.BusinessOperation,
			ActionParameters.Organization,
			ActionParameters.Department,
			Products,
			?(CharacteristicIsSpecified, CurrentRow.Characteristic, Undefined));
	
	If ArticleAndAnalytics.Next() Then
		CurrentRow[ActionParameters.ExpenseItem]     = ArticleAndAnalytics.ExpenseItem;
		CurrentRow[ActionParameters.DimensionOfExpenses]  = ArticleAndAnalytics.DimensionOfExpenses;
	EndIf;
	
	If ActionParameters.ActionInForm Then
		FillInDetailsOfArticleInTableRow(CurrentRow, ActionParameters.ItemsAndDimensionsSelectionParameters);
	EndIf;
	
EndProcedure

// Fills in the tabular part of the line article and analysis of expenses write-off items for statistics.
// Called from the mechanism of batch processing of rows of table parts.
// 
// Parameters:
// 	CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString.CurrentRow
// 	ActionParameters - Structure - the parameters of the action. (See IncomeAndExpensesClientServer.InsertActionFillInItemCostAnalysisOfProducts)
// 	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure FillInArticleAndAnalyticsOfItemExpensesInBatches(CurrentRow, ActionParameters, CachedValues) Export
	
	If ValueIsFilled(CurrentRow[ActionParameters.ExpenseItem]) Then
		Return;
	EndIf;
	
	ArticleAndAnalytics = 
		ItemAnalyticsOfExpensesByDefaultInBatches(CachedValues);
	
	If ArticleAndAnalytics <> Undefined Then
		CurrentRow[ActionParameters.ExpenseItem]     = ArticleAndAnalytics.ExpenseItem;
		CurrentRow[ActionParameters.DimensionOfExpenses]  = ArticleAndAnalytics.DimensionOfExpenses;
	EndIf;
	
	If ActionParameters.ActionInForm Then
		FillInDetailsOfArticleInRowOfTableInBatches(CurrentRow, ActionParameters.ItemsAndDimensionsSelectionParameters, CachedValues);
	EndIf;
	
EndProcedure

// Clears the item and expense analytics in the tabular part of the line.
// Called from the Batch processing mechanism of the table part.
// 
// Parameters:
// 	CurrentRow - Structure - This line.
// 	ActionParameters - Structure - the parameters of the action. (See IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics)
//
Procedure ClearExpenseAnalytics_(CurrentRow, ActionParameters) Export
	
	ItemsAndDimensionsSelectionParameters = ActionParameters.ItemsAndDimensionsSelectionParameters;
	
	If ValueIsFilled(CurrentRow[ActionParameters.ExpenseItem]) Then
		CurrentRow[ActionParameters.ExpenseItem] = ItemsAndDimensionsSelectionParameters.DefaultValue;
	EndIf;
	If ValueIsFilled(CurrentRow[ActionParameters.DimensionOfExpenses]) Then
		CurrentRow[ActionParameters.DimensionOfExpenses] = Undefined;
	EndIf;
	
	If ActionParameters.ActionInForm Then
		FillInDetailsOfArticleInTableRow(CurrentRow, ActionParameters.ItemsAndDimensionsSelectionParameters);
	EndIf;
	
EndProcedure

// Clears the item and expense analytics in the row of the tabular part. Called from the mechanism of batch processing of rows
// of table parts.
// 
// Parameters:
// 	CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString.CurrentRow
// 	ActionParameters - Structure - the parameters of the action. (See IncomeAndExpensesClientServer.InsertActionClearItemAndExpenseAnalytics)
// 	CachedData - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure ClearExpenseAnalyticsItemInBatches(CurrentRow, ActionParameters, CachedData) Export
	
	ItemsAndDimensionsSelectionParameters = ActionParameters.ItemsAndDimensionsSelectionParameters;
	
	If ValueIsFilled(CurrentRow[ActionParameters.ExpenseItem]) Then
		CurrentRow[ActionParameters.ExpenseItem] = ItemsAndDimensionsSelectionParameters.DefaultValue;
	EndIf;
	If ValueIsFilled(CurrentRow[ActionParameters.DimensionOfExpenses]) Then
		CurrentRow[ActionParameters.DimensionOfExpenses] = Undefined;
	EndIf;
	
	If ActionParameters.ActionInForm Then
		FillInDetailsOfArticleInRowOfTableInBatches(CurrentRow, ActionParameters.ItemsAndDimensionsSelectionParameters, CachedData);
	EndIf;
	
EndProcedure

// Initializes the string after adding it.
// Called from the Batch processing mechanism of the table part.
// 
// Parameters:
// 	CurrentRow - Structure - This line.
// 	ActionParameters - Structure - the parameters of the action. (See IncomeAndExpensesClientServer.InsertActionInitializeArticleAndAnalyticsAfterAddingLine)
//
Procedure InitializeArticleAndAnalyticsAfterAddingLine(CurrentRow, ActionParameters) Export
	
	For Each ChoiceParameters In ActionParameters.ArrayOfArticleAndAnalyticsSelectionParameters Do
		
		IncomeAndExpensesClientServer.InitializeArticleAndAnalystValues(CurrentRow, ChoiceParameters);
		
		If ActionParameters.ActionInForm Then
			FillInDetailsOfArticleInTableRow(CurrentRow, ChoiceParameters);
		EndIf;
		
	EndDo;
	
EndProcedure

// Initializes the row of the table part after adding it. Called from the batch processing mechanism of the table part.
// 
// Parameters:
// 	CurrentRow - See BatchProcessingOfTablePartServer.ProcessTSString.CurrentRow
// 	ActionParameters - Structure - the parameters of the action. (See IncomeAndExpensesClientServer.InsertActionInitializeArticleAndAnalyticsAfterAddingLine)
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure InitializeArticleAndAnalyticsAfterAddingLineInBatches(CurrentRow, ActionParameters, CachedValues) Export
	
	For Each ChoiceParameters In ActionParameters.ArrayOfArticleAndAnalyticsSelectionParameters Do
		
		IncomeAndExpensesClientServer.InitializeArticleAndAnalystValues(CurrentRow, ChoiceParameters);
		
		If ActionParameters.ActionInForm Then
			FillInDetailsOfArticleInRowOfTableInBatches(CurrentRow, ChoiceParameters, CachedValues);
		EndIf;
		
	EndDo;
	
EndProcedure

// Adds a query to the query package to get the data needed to fill in the expense analytics
// item when processing rows in the table part. Returns the last items and expense analytics used in the documents.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddQueryTextToItemCostAnalyticsByDefault(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInItemCostAnalysisOfProductRange",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		CharacteristicIsUsed = BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Characteristic", CachedValues);
		
		IsFileInfobase = Common.FileInfobase();
		
		If Not IsFileInfobase Then

			QueryText = "SELECT
			|	Goods.IdOfTTRow AS IdOfTTRow,
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	OtherExpenses.ItemsLocationAttributes,
			|	MAX(OtherExpenses.Period) AS Period
			|INTO CostAnalyticsItemTTIsIntermediateByDefault
			|FROM
			|	AccumulationRegister.OtherExpenses AS OtherExpenses
			|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
			|			ON OtherExpenses.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
			|		INNER JOIN TTDataSource AS Goods
			|			ON InventoryLocationAttributeKeys.Products = Goods.Products
			|				AND InventoryLocationAttributeKeys.Characteristic = Goods.Characteristic
			|				AND OtherExpenses.Organization = &Company_ExpenseAnalytics
			|				AND OtherExpenses.Department = &Division_AnalyticsOfExpenses
			|				AND OtherExpenses.BusinessOperation = &BusinessTransaction_ExpenseAnalytics
			|WHERE
			|	TRUE IN
			|			(SELECT TOP 1
			|				TRUE
			|			FROM
			|				InformationRegister.ItemsLocationAttributes AS Filter
			|			WHERE
			|				(Filter.Products,
			|				Filter.Characteristic,
			|				OtherExpenses.ItemsLocationAttributes,
			|				OtherExpenses.Organization,
			|				OtherExpenses.Department,
			|				OtherExpenses.BusinessOperation,
			|				TRUE) IN
			|					(SELECT
			|						Goods.Products,
			|						Goods.Characteristic,
			|						Filter.DimensionKey,
			|						&Company_ExpenseAnalytics,
			|						&Division_AnalyticsOfExpenses,
			|						&BusinessTransaction_ExpenseAnalytics,
			|						Goods.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|					FROM
			|						TTDataSource AS Goods)
			|			
			|			UNION ALL
			|			
			|			SELECT TOP 1
			|				TRUE
			|			FROM
			|				InformationRegister.ItemsLocationAttributes AS Filter
			|			WHERE
			|				(Filter.Products,
			|				TRUE,
			|				OtherExpenses.ItemsLocationAttributes,
			|				OtherExpenses.Organization,
			|				OtherExpenses.Department,
			|				OtherExpenses.BusinessOperation,
			|				TRUE) IN
			|					(SELECT
			|						Goods.Products,
			|						TRUE,
			|						Filter.DimensionKey,
			|						&Company_ExpenseAnalytics,
			|						&Division_AnalyticsOfExpenses,
			|						&BusinessTransaction_ExpenseAnalytics,
			|						Goods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|					FROM
			|						TTDataSource AS Goods))
			|
			|GROUP BY
			|	OtherExpenses.ItemsLocationAttributes,
			|	Goods.Products,
			|	Goods.Characteristic,
			|	Goods.IdOfTTRow";

			If Not CharacteristicIsUsed Then
				QueryText = StrReplace(QueryText, "Goods.Characteristic,", "TRUE,");
				QueryText = StrReplace(QueryText, "Goods.Characteristic AS Characteristic,", "TRUE AS Characteristic,");
				QueryText = StrReplace(QueryText, "Filter.Characteristic,", "TRUE,");
				QueryText = StrReplace(QueryText, "Goods.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)", "TRUE");
				QueryText = StrReplace(QueryText, "Goods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)", "TRUE");
			EndIf;

			QueryDetails.QueriesTexts.Add(QueryText, "CostAnalyticsItemTTIsIntermediateByDefault");

			QueryText = "SELECT
			|	Goods.IdOfTTRow AS IdOfTTRow,
			|	ISNULL(OtherExpenses.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) AS ExpenseItem,
			|	ISNULL(OtherExpenses.DimensionOfExpenses, UNDEFINED) AS DimensionOfExpenses,
			|	OtherExpenses.Period AS Period
			|FROM 
			|	TTDataSource AS Goods
			|	LEFT JOIN CostAnalyticsItemTTIsIntermediateByDefault AS ExpenseItems
			|		ON Goods.IdOfTTRow = ExpenseItems.IdOfTTRow
			|	LEFT JOIN AccumulationRegister.OtherExpenses AS OtherExpenses
			|		ON OtherExpenses.ItemsLocationAttributes = ExpenseItems.ItemsLocationAttributes
			|			AND OtherExpenses.Organization = &Company_ExpenseAnalytics
			|			AND OtherExpenses.Department = &Division_AnalyticsOfExpenses
			|			AND OtherExpenses.BusinessOperation = &BusinessTransaction_ExpenseAnalytics
			|			AND OtherExpenses.Period = ExpenseItems.Period
			|";

			If Not CharacteristicIsUsed Then
				QueryText = StrReplace(QueryText, "Goods.Characteristic,", "TRUE,");
				QueryText = StrReplace(QueryText, "Goods.Characteristic AS Characteristic,", "TRUE AS Characteristic,");
				QueryText = StrReplace(QueryText, "Filter.Characteristic,", "TRUE,");
				QueryText = StrReplace(QueryText, "Goods.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)", "TRUE");
				QueryText = StrReplace(QueryText, "Goods.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)", "TRUE");
			EndIf;
			
			QueryDetails.QueriesTexts.Add(QueryText, "DefaultExpenseAnalyticsItem");
			
		Else
			
			//Getting data about the time of the last selected item analytics
			QueryText = "SELECT
			|	Goods.IdOfTTRow AS IdOfTTRow,
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	MAX(OtherExpenses.Period) AS Period
			|INTO DateOfLastAnalyticsOfItemOnTT
			|FROM
			|	TTDataSource AS Goods
			|		INNER JOIN InformationRegister.ItemsLocationAttributes AS AnalystTable
			|		ON (AnalystTable.Products = Goods.Products)
			|			AND (AnalystTable.Characteristic = Goods.Characteristic)
			|		INNER JOIN AccumulationRegister.OtherExpenses AS OtherExpenses
			|		ON (AnalystTable.DimensionKey = OtherExpenses.ItemsLocationAttributes)
			|			AND (OtherExpenses.Organization = &Company_ExpenseAnalytics)
			|			AND (OtherExpenses.Department = &Division_AnalyticsOfExpenses)
			|			AND (OtherExpenses.BusinessOperation = &BusinessTransaction_ExpenseAnalytics)
			|
			|GROUP BY
			|	Goods.IdOfTTRow,
			|	Goods.Products,
			|	Goods.Characteristic";

			If Not CharacteristicIsUsed Then
				QueryText = StrReplace(QueryText, "Goods.Characteristic AS Characteristic,", "TRUE AS Characteristic,");
				QueryText = StrReplace(QueryText, "Goods.Characteristic,", "TRUE,");
				QueryText = StrReplace(QueryText, "AnalystTable.Characteristic = Goods.Characteristic", "TRUE");
			EndIf;

			QueryDetails.QueriesTexts.Add(QueryText, "DateOfLastAnalyticsOfItemOnTT");

			//Getting data about the last selected item analytics
			QueryText = "SELECT
			|	Goods.IdOfTTRow AS IdOfTTRow,
			|	Goods.Products AS Products,
			|	Goods.Characteristic AS Characteristic,
			|	Goods.Period AS Period,
			|	MAX(OtherExpenses.ItemsLocationAttributes) AS ItemsLocationAttributes
			|INTO TTLatestAnalytics
			|FROM
			|	DateOfLastAnalyticsOfItemOnTT AS Goods
			|		INNER JOIN InformationRegister.ItemsLocationAttributes AS AnalystTable
			|		ON (AnalystTable.Products = Goods.Products)
			|			AND (AnalystTable.Characteristic = Goods.Characteristic)
			|		INNER JOIN AccumulationRegister.OtherExpenses AS OtherExpenses
			|		ON (AnalystTable.DimensionKey = OtherExpenses.ItemsLocationAttributes)
			|			AND (OtherExpenses.Organization = &Company_ExpenseAnalytics)
			|			AND (OtherExpenses.Department = &Division_AnalyticsOfExpenses)
			|			AND (OtherExpenses.BusinessOperation = &BusinessTransaction_ExpenseAnalytics)
			|			AND (OtherExpenses.Period = Goods.Period)
			|
			|GROUP BY
			|	Goods.IdOfTTRow,
			|	Goods.Products,
			|	Goods.Characteristic,
			|	Goods.Period";

			If Not CharacteristicIsUsed Then
				QueryText = StrReplace(QueryText, "Goods.Characteristic AS Characteristic,", "TRUE AS Characteristic,");
				QueryText = StrReplace(QueryText, "Goods.Characteristic,", "TRUE,");
				QueryText = StrReplace(QueryText, "AnalystTable.Characteristic = Goods.Characteristic", "TRUE");
			EndIf;
			
			QueryDetails.QueriesTexts.Add(QueryText, "TTLatestAnalytics");
			
			//Data on the last item of expenditure and cost analysis for the selected item and characteristic
			QueryText = "SELECT DISTINCT
			|	Goods.IdOfTTRow AS IdOfTTRow,
			|	ISNULL(OtherExpenses.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) AS ExpenseItem,
			|	ISNULL(OtherExpenses.DimensionOfExpenses, UNDEFINED) AS DimensionOfExpenses
			|FROM
			|	TTDataSource AS Goods
			|		LEFT JOIN TTLatestAnalytics AS LastDimension
			|		ON Goods.IdOfTTRow = LastDimension.IdOfTTRow
			|		LEFT JOIN AccumulationRegister.OtherExpenses AS OtherExpenses
			|		ON (OtherExpenses.Period = LastDimension.Period)
			|			AND (OtherExpenses.ItemsLocationAttributes = LastDimension.ItemsLocationAttributes)
			|			AND (OtherExpenses.Organization = &Company_ExpenseAnalytics)
			|			AND (OtherExpenses.Department = &Division_AnalyticsOfExpenses)
			|			AND (OtherExpenses.BusinessOperation = &BusinessTransaction_ExpenseAnalytics)";
			
			QueryDetails.QueriesTexts.Add(QueryText, "DefaultExpenseAnalyticsItem");
			
		EndIf;

		QueryDetails.QueryOptions.Insert("Company_ExpenseAnalytics", ActionParameters.Organization);
		QueryDetails.QueryOptions.Insert("Division_AnalyticsOfExpenses", ActionParameters.Department);
		QueryDetails.QueryOptions.Insert("BusinessTransaction_ExpenseAnalytics", ActionParameters.BusinessOperation);
		QueryDetails.PrivilegedMode = True;
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the Attributes for
// the expense/income item when processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddQueryTextToArticleDetails(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"ClearExpenseAnalytics_,InitializeArticleAndAnalyticsAfterAddingLine,FillInItemCostAnalysisOfProductRange",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
				
		If ActionParameters.Property("ItemsAndDimensionsSelectionParameters") Then
			ArticleField = ActionParameters.ItemsAndDimensionsSelectionParameters.AssetRef;
		Else
			ArticleField = ActionParameters.ArrayOfArticleAndAnalyticsSelectionParameters[0].AssetRef;
		EndIf;
		
		QueryText = 
			"SELECT ALLOWED
			|	TTDataSource.IdOfTTRow AS IdOfTTRow,
			|	ChartOfCharacteristicTypesExpenseItems.ValueType AS ValueType,
			|	ChartOfCharacteristicTypesExpenseItems.ControlDimensionFilling AS ControlDimensionFilling,
			|	ChartOfCharacteristicTypesExpenseItems.DimensionOfExpensesOrderImplementation AS DimensionOfExpensesOrderImplementation,
			|	UNDEFINED AS WithoutDimension
			|FROM
			|	TTDataSource AS TTDataSource
			|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ChartOfCharacteristicTypesExpenseItems
			|		ON (&ValueOfArticlesAndAnalytics = ChartOfCharacteristicTypesExpenseItems.Ref)
			|		AND VALUETYPE(&ValueOfArticlesAndAnalytics) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
			|
			|UNION ALL
			|
			|SELECT
			|	TTDataSource.IdOfTTRow,
			|	ChartOfCharacteristicTypesIncomeItems.ValueType,
			|	ChartOfCharacteristicTypesIncomeItems.ControlDimensionFilling,
			|	UNDEFINED,
			|	UNDEFINED
			|FROM
			|	TTDataSource AS TTDataSource
			|		LEFT JOIN ChartOfCharacteristicTypes.IncomeItems AS ChartOfCharacteristicTypesIncomeItems
			|		ON (&ValueOfArticlesAndAnalytics = ChartOfCharacteristicTypesIncomeItems.Ref)
			|		AND VALUETYPE(&ValueOfArticlesAndAnalytics) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
			|
			|UNION ALL
			|
			|SELECT
			|	TTDataSource.IdOfTTRow,
			|	ChartOfCharacteristicTypesAssetLiabilityItems.ValueType,
			|	UNDEFINED,
			|	UNDEFINED,
			|	ChartOfCharacteristicTypesAssetLiabilityItems.WithoutDimension
			|FROM
			|	TTDataSource AS TTDataSource
			|		LEFT JOIN ChartOfCharacteristicTypes.AssetLiabilityItems AS ChartOfCharacteristicTypesAssetLiabilityItems
			|		ON (&ValueOfArticlesAndAnalytics = ChartOfCharacteristicTypesAssetLiabilityItems.Ref)
			|		AND VALUETYPE(&ValueOfArticlesAndAnalytics) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)";
		
		QueryText = StrReplace(QueryText, "&ValueOfArticlesAndAnalytics", "TTDataSource." + ArticleField); //@Query-part-2
		QueryDetails.QueriesTexts.Add(QueryText, "ArticleDetailsValues");
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the Tax Account Acceptance field
// when processing rows in the table part.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartServer.ProcessTSStrings.StructureOfActions
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
Procedure AddAcceptedToQueryTextAttribute(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ExpenseItemField;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"FillInAttributeAcceptedByCNU",
			StructureOfActions,
			CachedValues,
			ExpenseItemField) Then
				
		If IsBlankString(ExpenseItemField) Then
			ExpenseItemField = "ExpenseItem";
		EndIf;
		
		QueryText = "SELECT ALLOWED
						|	TTDataSource.IdOfTTRow AS IdOfTTRow,
						|	ISNULL(ExpenseItems.EnteredInTaxAccounting, FALSE) AS EnteredInTaxAccounting
						|FROM TTDataSource AS TTDataSource
						|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
						|		ON ExpenseItems.Ref = DataSource.ExpenseItem
						|";
		
		QueryText = StrReplace(QueryText, "DataSource.ExpenseItem", "TTDataSource." + ExpenseItemField);
		QueryDetails.QueriesTexts.Add(QueryText, "AttributeIsAcceptedByCNU");
		
	EndIf;
	
EndProcedure

// The function retrieves the last item and expense analysis used in documents.
//
// Parameters:
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//
// Returns:
//	ValueTableRow - Article and cost analysis.
//
Function ItemAnalyticsOfExpensesByDefaultInBatches(CachedValues) Export
	
	SetPrivilegedMode(True);
	
	DataForProcessing = BatchProcessingOfTablePartServer.DataForStringProcessing(
							"DefaultExpenseAnalyticsItem", CachedValues); 
	If Not DataForProcessing = Undefined
		And DataForProcessing.Count() Then
			Return DataForProcessing[0];
	EndIf;
	Return Undefined;
	
EndFunction

// Removes types with the prefix "delete" from the array of types
// 
// Parameters:
//  ObjectTypes_ - Array of Type - Object Types
// 
// Returns:
//  Array of Type - Current types 
Function DeleteTypesFromArrayToDelete(ObjectTypes_) Export
	If ObjectTypes_.Count() > 1 Then
		TypesToDelete = New Array;
		For Each Type In ObjectTypes_ Do
			If TMCommonUse.ObjectToDelete(Type) Then 
				TypesToDelete.Add(Type);
			EndIf;
		EndDo;
		Return CommonClientServer.ArraysDifference(ObjectTypes_, TypesToDelete);
	Else
		Return ObjectTypes_;
	EndIf;
EndFunction 

#EndRegion

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.OtherIncome);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.OtherExpenses);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.RevenueAndCOGS);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.RevenueServicesAndAssets);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.OtherExpenses);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.RevenueAndCOGS);
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.RevenueServicesAndAssets);
		
	EndIf;
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.OtherIncome);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.OtherExpenses);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.RevenueServicesAndAssets);
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.RevenueAndCOGS);
	EndIf;
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map of String - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.AccumulationRegisters.OtherIncome;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			BatchAccountingServer.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.OtherExpenses;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			BatchAccountingServer.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.RevenueAndCOGS;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then 
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			BatchAccountingServer.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.RevenueServicesAndAssets;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			BatchAccountingServer.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of financial documents.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "OtherIncome");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "OtherExpenses");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "RevenueAndCOGS");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "RevenueServicesAndAssets");
		
EndProcedure

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map of String - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("ChangesTableOtherIncome", 
		AccumulationRegisters.OtherIncome.RequestTextMonitoringBanDate(Query));
	MatchingQueryTexts.Insert("ChangesTableOtherExpenses", 
		AccumulationRegisters.OtherExpenses.RequestTextMonitoringBanDate(Query));
	MatchingQueryTexts.Insert("ChangesTableRevenueServicesAndAssets", 
		AccumulationRegisters.RevenueServicesAndAssets.RequestTextMonitoringBanDate(Query));
	
	Return MatchingQueryTexts;
	
EndFunction

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList of String - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
EndProcedure

// Supplements the texts of the request for the document with texts reflecting the sale of goods, works, services, and other assets.
// The operation generates movements based on the other hand register.
// 
// Parameters:
// 	Query - Query - Request for document reflection.
// 	QueryTexts - ValueList of String - List of document reflection request texts.
// 	Registers - Undefined, Structure, String - List of registers to reflect.
// 	TextOtherRevenueByDocument - String - The text of the request to receive document data.
// 	     The request should return a selection with the following fields
// 	     fetchingresultsquery:
// 	     * Period - Date - date when the operation was reflected.
// 	     * Ref - DocumentRef - The document that registers the operation.
// 	     * Organization - CatalogRef.Companies - The organization in which the acquisition is reflected.
// 	     * Partner - CatalogRef.Partners - Partner.
// 	     * Counterparty - CatalogRef.Counterparties - partner's counterparty.
// 	     * Contract - CatalogRef.CounterpartyContracts, CatalogRef.IntercompanyContracts, CatalogRef.LoanAndDepositContracts - Contract for the acquisition of valuables.
// 	     * Department - CatalogRef.BusinessStructure - The division on whose behalf the acquisition document is registered.
// 	     * Individual - CatalogRef.Persons - the natural person of the document.
//    	 * LineOfBusiness - CatalogRef.LinesOfBusiness - the direction of the operation.
//       * BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	     * IncomeItem - ChartOfCharacteristicTypesRef.IncomeItems - The item of expenditure on which the acquired values are written off.
// 	     * DimensionOfRevenue - Characteristic.IncomeItems - Cost reflection analytics.
// 	     * Count - Number - quantity of goods, services.
// 	     * RevenueExcludingVATManag - Number - revenue excluding VAT for goods and services.
// 	     * RevenueExcludingVATLocal - Number - revenue excluding VAT for goods and services.
// 	     * VATManag - Number - the amount of vat in the Man's currency.
// 	     * VATLocal - Number - the amount of vat in the Local currency.
// 	     * VATRate - CatalogRef.VATRates - VAT rate.
// 	     * VATTaxation - EnumRef.VATTaxationTypes - VAT taxation of the acquisition document.
// 	     * ARAPCurrency - CatalogRef.Currencies - The currency of mutual settlements.
// 	     * AmountARAP - Number - the amount of settlements.
Procedure ReflectOtherRevenue(Query, QueryTexts, Registers, TextOtherRevenueByDocument) Export

#Region RevenueServicesAndAssets

	Query.SetParameter("UseAccountingOfOtherIncomeExpensesInLocalAccounting", GetFunctionalOption("UseAccountingOfOtherIncomeExpensesInLocalAccounting"));
	
	QueryTextRevenueServicesAndAssets = 
	"SELECT
	|	RevenueServicesAndAssets.Period AS Period,
	|	RevenueServicesAndAssets.Organization AS Organization,
	|	RevenueServicesAndAssets.AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	RevenueServicesAndAssets.Partner AS Partner,
	|	RevenueServicesAndAssets.Counterparty AS Counterparty,
	|	RevenueServicesAndAssets.Contract AS Contract,
	|	RevenueServicesAndAssets.Department AS Department,
	|	RevenueServicesAndAssets.Individual AS Individual,
	|	CASE
	|		WHEN ISNULL(LB.IncomeAccounting, FALSE) THEN
	|			RevenueServicesAndAssets.LineOfBusiness
	|		ELSE
	|			UNDEFINED
	|	END AS LineOfBusiness,
	|	RevenueServicesAndAssets.BusinessOperation AS BusinessOperation,
	|	RevenueServicesAndAssets.IncomeItem AS IncomeItem,
	|	RevenueServicesAndAssets.DimensionOfRevenue AS DimensionOfRevenue,
	|	RevenueServicesAndAssets.Count AS Count,
	|	RevenueServicesAndAssets.RevenueExcludingVATManag AS RevenueExcludingVATManag,
	|	RevenueServicesAndAssets.RevenueExcludingVATLocal AS RevenueExcludingVATLocal,
	|	RevenueServicesAndAssets.VATManag AS VATManag,
	|	RevenueServicesAndAssets.VATLocal AS VATLocal,
	|	RevenueServicesAndAssets.RevenueAmountPD AS RevenueAmountPD,
	|	CASE
	|		WHEN RevenueServicesAndAssets.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE RevenueServicesAndAssets.VATTaxation
	|	END AS VATTaxation,
	|	RevenueServicesAndAssets.ARAPCurrency AS ARAPCurrency,
	|	RevenueServicesAndAssets.AmountARAP AS AmountARAP,
	|	RevenueServicesAndAssets.ARAPObject AS ARAPObject,
	|	RevenueServicesAndAssets.FinRecordID AS FinRecordID,
	|	RevenueServicesAndAssets.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	#RevenueServicesAndAssets AS RevenueServicesAndAssets
	|		LEFT JOIN Catalog.LinesOfBusiness AS LB
	|		ON RevenueServicesAndAssets.LineOfBusiness = LB.Ref
	|";
	
#EndRegion
	
	ReflectionTemplateTexts = New Structure();
	If DocumentsPosting.RequiresTableForRegisteredRecords("RevenueServicesAndAssets", Registers) Then
		ReflectionTemplateTexts.Insert("RevenueServicesAndAssets", QueryTextRevenueServicesAndAssets);
	EndIf;
	TextsOfDocumentDataRequests = New Structure("RevenueServicesAndAssets", TextOtherRevenueByDocument);
	DocumentsPosting.AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests);

EndProcedure

#EndRegion

// Returns the currency of management accounting
// If the currency passed as the parameter is already filled in, it returns it.
// If the currency is not passed as a parameter or an empty one is passed,
// the currency of the UU. If the UU currency is not filled in, it returns an empty link to the currency.
//
// Parameters:
//	Currency - CatalogRef.Currencies - The currency to fill in.
//
// Returns:
//	CatalogRef.Currencies - currency of management accounting.
//
Function GetCurrencyOfManagementAccounting(Val Currency = Undefined) Export
	
	If Not ValueIsFilled(Currency) Then
		Return Constants.ManagementAccountingCurrency.Get();
	Else
		Return Currency;
	EndIf;
	
EndFunction

// Returns the counterparty from the foundation document
//
// Parameters:
//  DocumentBasis - DocumentRef - the document for which you need to get a counterparty.
//
// Returns:
//	CatalogRef.Counterparties - Link to the counterparty.
//
Function GetCounterpartyFromBase(DocumentBasis) Export

	If Not ValueIsFilled(DocumentBasis) Then
		Return Undefined;
	EndIf; 
	
	BasisType = TypeOf(DocumentBasis);
	
	Counterparty = Undefined;
	
	If BasisType = Type("DocumentRef.BankAccountIssue") Then
		AttributesValues = Common.ObjectAttributesValues(DocumentBasis, "Counterparty,BusinessOperation,BankAccountBeneficiary");
		If AttributesValues.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
			Counterparty = AttributesValues.BankAccountBeneficiary.Owner;
		Else
			Counterparty = AttributesValues.Counterparty;
		EndIf; 

	ElsIf BasisType = Type("DocumentRef.CashVoucher") Then
		AttributesValues = Common.ObjectAttributesValues(DocumentBasis, "Counterparty,BusinessOperation,CashAccountRecipient");

		If AttributesValues.BusinessOperation = Enums.BusinessTransactions.CashPaymentToAnotherCompany Then
			Counterparty = AttributesValues.CashAccountRecipient.Owner;
		Else
			Counterparty = AttributesValues.Counterparty;
		EndIf; 
		
	ElsIf BasisType = Type("DocumentRef.CashAccountReceiptNote") Then
		Counterparty = Common.ObjectAttributeValue(DocumentBasis, "Counterparty");
		
	ElsIf BasisType = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		Counterparty = Common.ObjectAttributeValue(DocumentBasis, "Counterparty");
		
	ElsIf BasisType = Type("DocumentRef.ReturnOfGoodsToVendor") Then
		Counterparty = Common.ObjectAttributeValue(DocumentBasis, "Counterparty");
		
	ElsIf BasisType = Type("DocumentRef.PaymentCardTransaction") Then
		Counterparty = Common.ObjectAttributeValue(DocumentBasis, "Counterparty");
		
	ElsIf BasisType = Type("DocumentRef.BankAccountReceiptNote") Then
		Counterparty = Common.ObjectAttributeValue(DocumentBasis, "Counterparty");
		
	ElsIf BasisType = Type("DocumentRef.SaleAdjustment") Then
		Counterparty = Common.ObjectAttributeValue(DocumentBasis, "Counterparty");
		
	ElsIf BasisType = Type("DocumentRef.PurchaseAdjustment") Then
		Counterparty = Common.ObjectAttributeValue(DocumentBasis, "Counterparty");
		
	ElsIf BasisType = Type("DocumentRef.ARAPAdjustment") Then
		Counterparty = Common.ObjectAttributeValue(DocumentBasis, "Counterparty");
		
	ElsIf BasisType = Type("DocumentRef.SourceDocument") Then
		Counterparty = Common.ObjectAttributeValue(DocumentBasis, "Counterparty");

	ElsIf BasisType = Type("DocumentRef.ExpenseReport") Then
		// There is no way to uniquely identify the counterparty, because the information is stored in the tabular part.
		
	ElsIf BasisType = Type("DocumentRef.ARAPSettlement") Then
		// There is no way to uniquely identify the counterparty, because the information is stored in the tabular part.
		
	EndIf;

	Return Counterparty;
	
EndFunction

#Region ProceduresForDistributionOfIncomeAndExpensesOnBasisOfDistribution

// The procedure distributes expenses for the cost of goods 
// based on the calculated distribution base.
//
// Parameters:
//	DocumentObject - DocumentObject - a document that reflects expenses allocated to the cost of goods.
//	StructureAdditionalProperties - Structure - Additional Document Properties:
//		* TablesForRegisteredRecords - Structure - Tables For Movements:
//			** ExpensesTable - ValueTable - table with columns:
//				*** LineNumber - Number - the line number table
//	RegisterRecords - RegisterRecordsCollection - sets of register entries.
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure DistributeCostOfGoodsOnBasisOf(DocumentObject, StructureAdditionalProperties, RegisterRecords, Cancel) Export

	ExpensesTable = StructureAdditionalProperties.TablesForRegisteredRecords.ExpensesTable;
	DatabaseQueryResult = StructureAdditionalProperties.TablesForRegisteredRecords.DatabaseQueryResult;

	If Cancel Or ExpensesTable.Count() = 0 Or DatabaseQueryResult.IsEmpty() Then
		Return;
	EndIf;

	SetOfRecordsCostOfGoods = RegisterRecords.InventoryCost;
	SetOfRecordsCostOfGoods.Write = True;

	RecordCounter  = 0;
	FilterStructure1 = New Structure("BaseIndex_");

	// Selection of rows of the distribution database by the analytics index.
	SamplingByIndex = DatabaseQueryResult.Select(QueryResultIteration.ByGroups);
	While SamplingByIndex.Next() Do
		
		FilterStructure1.BaseIndex_ = SamplingByIndex.BaseIndex_;

		// We get an array of expenses that have the same analytics index corresponding to the current sample of the distribution base.
		// These costs will be distributed on the same distribution basis.
		ArrayOfExpenses = ExpensesTable.FindRows(FilterStructure1);
		If ArrayOfExpenses.Count() = 0 Then
			Continue;
		EndIf;
		
		Selection = SamplingByIndex.Select(QueryResultIteration.ByGroups);
		
		If SamplingByIndex.Base = 0 Then
			
			Selection.Next();
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không có cơ sở để phân bổ chi phí theo quy tắc %1 cho chỉ số %2. Hãy chỉ ra quy tắc khác hoặc xóa dòng khỏi chứng từ.';
					|ru = 'Отсутствует база для распределения расходов по правилу %1 для аналитики %2. Укажите другое правило или удалите строку из документа.';
					|en = 'No base for expense allocation according to rule %1 for dimension %2. Specify another rule or remove the line from the document.'; fa = 'No base for expense allocation according to rule %1 for dimension %2. Specify another rule or remove the line from the document.';
					|it = 'Base per la distribuzione delle spese in base alla regola %1 dell''analitica %2 assente. Indicare un''altra regola o eliminare la riga dal documento.';
					|pl = 'Brak bazy do podziału rozchodów wg reguły %1 dla analityki %2. Wskaż inną regułę lub usuń wiersz z dokumentu.';
					|tr = '%2 boyutu için %1 kuralına göre gider tahsisat tabanı yoktur. Farklı bir kural belirle veya satırı belgeden kaldır.'"),
				Selection.AllocatedAccordingToRule,
				Selection.DimensionOfExpenses);
			CommonClientServer.MessageToUser(
				Text,
				DocumentObject,
				"Expenses[" + (ArrayOfExpenses[0].LineNumber - 1) + "].AllocatedAccordingToRule",
				,
				Cancel);
			
			Continue;
			
		EndIf;

		For Each ExpenseLine_ In ArrayOfExpenses Do
		
			AmountForAllocation = ExpenseLine_.Sum;
			AmountWithoutNDSKDISTRIBUTION = ExpenseLine_.AmountExcludingVAT;
			LocalSumToDistribution = ExpenseLine_.SumCompl;
			DatabaseOfEverything = SamplingByIndex.Base;
		
			// Selection of rows of the distribution base by the index of the distribution base
			Selection.Reset();
			While Selection.Next() Do

				If DatabaseOfEverything <> 0 Then
					Cost = Round(AmountForAllocation * Selection.Base / DatabaseOfEverything, 2, 1);
					CostExcludingVAT = Round(AmountWithoutNDSKDISTRIBUTION * Selection.Base / DatabaseOfEverything, 2, 1);
					LocalCost = Round(LocalSumToDistribution * Selection.Base / DatabaseOfEverything, 2, 1);
				Else
					Cost = 0;
					CostExcludingVAT = 0;
					LocalCost = 0;
				EndIf;

				AmountForAllocation = AmountForAllocation - Cost;
				AmountWithoutNDSKDISTRIBUTION = AmountWithoutNDSKDISTRIBUTION - CostExcludingVAT;
				LocalSumToDistribution = LocalSumToDistribution - LocalCost;
				DatabaseOfEverything = DatabaseOfEverything - Selection.Base;

				RecordCounter = RecordCounter + 1;
				NewRecord = SetOfRecordsCostOfGoods.Add();
				FillPropertyValues(NewRecord, ExpenseLine_);
				NewRecord.ItemsLocationAttributes = Selection.ItemsLocationAttributes;
				NewRecord.Count = 0;
				NewRecord.InventoryOwnerAttribute = Selection.InventoryOwnerAttribute;
				NewRecord.Organization = Selection.Organization;
				NewRecord.AddExpensesForGoods = Cost;
				NewRecord.AdditionalExpensesExcludingVAT = CostExcludingVAT;
				NewRecord.LocalCost = LocalCost;

				If RecordCounter > 1000 Then

					RecordCounter = 0;
					SetOfRecordsCostOfGoods.Write(False);

				EndIf;
			EndDo;
		EndDo;
	EndDo;

	If RecordCounter > 0 Then
		SetOfRecordsCostOfGoods.Write(False);
	EndIf;

	SetOfRecordsCostOfGoods.Write = False;

EndProcedure // Distribute the costs of the cost of the goods in the warehouse()

#EndRegion

#Region ObtainingTableOfDistributionOfCostsForCostOfGoodsForFormationOfDocumentReceiptOfAdditionalCostsDuringExchangeWithBP20

// The function generates a table with data on the distribution of expenses for the cost of goods.
//
// Parameters:
//	DocumentRef - DocumentRef - a document that reflects expenses allocated to the cost of goods.
//
// Returns:
//	ValueTable - Cost allocation table.
//
Function ExpenseAllocationOnInventoryCosts(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization
	|FROM
	|	Document.VendorInvoiceServicesAndAssets AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|");
	Query.SetParameter("Ref", DocumentRef);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	QueryText = QueryTextTTExpenseTable()
		+ QueryTextTableOfDistributionMethods()
		+ QueryTextTableDocuments()
		+ QueryTextTableUninvoicedReceipts()
		+ QueryTextTableAllocationBases()
		+ QueryTextTableOfExpenses()
	;
	
	Query.Text = QueryText;
	Query.SetParameter("StartDate", BegOfMonth(Attributes.Period));
	Query.SetParameter("EndDate", EndOfDay(Attributes.Period));
	Query.SetParameter("Organization", Attributes.Organization);
	Query.TempTablesManager = New TempTablesManager();
	
	ResultsArray = Query.ExecuteBatch();
	
	// Array of results[0] - temporary table of "VTTABLES"
	// Array of results[1] - temporary table of "Table of distribution"
	// Array of results[2] - temporary table of "documents tables"
	// Array of results[3] - temporary table of "Goods availability"
	// Array of results[4] - temporary table of "Goods availability tables".
	DatabaseQueryResult = ResultsArray[5];
	ExpensesTable = ResultsArray[6].Unload();
	
	// Let's form a cost allocation table.
	CostAllocationTable = New ValueTable;
	Columns = CostAllocationTable.Columns;
	Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Columns.Add("Count", Common.TypeDescriptionNumber(15,3));
	Columns.Add("GoodsCost", TMCommonUse.MoneyFieldTypeDescription());
	Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription());
	Columns.Add("VATAmount", TMCommonUse.MoneyFieldTypeDescription());
	
	TypesArray = New Array;
	TypesArray.Add(Type("DocumentRef.VendorInvoice"));
	TypesArray.Add(Type("DocumentRef.CustomerInvoiceIntercompany"));
	TypesArray.Add(Type("DocumentRef.AssemblyFromComponents"));
	Columns.Add("DocumentInflow", New TypeDescription(TypesArray));
	
	If Not ExpensesTable.Count() = 0
	 And Not DatabaseQueryResult.IsEmpty() Then
	
		FilterStructure1 = New Structure("BaseIndex_");
	
		// Selection of rows of the distribution database by the analytics index.
		SamplingByIndex = DatabaseQueryResult.Select(QueryResultIteration.ByGroups);
		While SamplingByIndex.Next() Do
			
			FilterStructure1.BaseIndex_ = SamplingByIndex.BaseIndex_;

			// We get an array of expenses that have the same analytics index corresponding to the current sample of the distribution base.
			// These costs will be distributed on the same distribution basis.
			ArrayOfExpenses = ExpensesTable.FindRows(FilterStructure1);
			If ArrayOfExpenses.Count() = 0 Then
				Continue;
			EndIf;
			
			Selection = SamplingByIndex.Select(QueryResultIteration.ByGroups);
			
			If SamplingByIndex.Base = 0 Then
				Continue;
			EndIf;

			For Each ExpenseLine_ In ArrayOfExpenses Do
			
				AmountForAllocation = ExpenseLine_.Sum;
				AmountOfNDSKDISTRIBUTION = ExpenseLine_.VATAmount;
				DatabaseOfEverything = SamplingByIndex.Base;
			
				// Selection of rows of the distribution base by the index of the distribution base
				Selection.Reset();
				While Selection.Next() Do

					If DatabaseOfEverything <> 0 Then
						Sum = Round(AmountForAllocation * Selection.Base / DatabaseOfEverything, 2, 1); 
						VATAmount = Round(AmountOfNDSKDISTRIBUTION * Selection.Base / DatabaseOfEverything, 2, 1) ;
					Else
						Sum = 0;
						VATAmount = 0;
					EndIf;

					AmountForAllocation = AmountForAllocation - Sum;
					AmountOfNDSKDISTRIBUTION = AmountOfNDSKDISTRIBUTION - VATAmount;
					DatabaseOfEverything = DatabaseOfEverything - Selection.Base;
					
					NewRow = CostAllocationTable.Add();
					FillPropertyValues(NewRow, Selection);
					NewRow.Sum = Sum;
					NewRow.VATAmount = VATAmount;

				EndDo;
			EndDo;
		EndDo;
		
	EndIf;
	
	Return CostAllocationTable; 
	
EndFunction

#EndRegion

#Region ProceduresAndFunctionsOfFormationOfRegisteredRecordsOnAccountingOfIncomeAndExpenses

// Generates the text of the request to add the table "Tablereflectiondocumentsregulation".
//
// Parameters:
// 	ThereAreTTLotsOfOtherExpenses - Boolean - Indication of the presence of a temporary table;
// 	PeriodName - String - the period name of the "Period" parameter in the received request must be set in the method
// 		of the document manager module "Fill in Initialization parameters". The default is "Period".
//
// Returns:
// 	String - Query text
Function AddRequestTextToTableReflectionOfDocumentsInLocalAccounting(ThereAreTTLotsOfOtherExpenses = True, PeriodName = "Period") Export
	
	QueryTemplate = "
	|SELECT DISTINCT
	|	&RedefinedDocumentPeriodName AS Period,
	|	Rows.CompanyRecipient AS Organization,
	|	BEGINOFPERIOD(Rows.Period, DAY) AS DateRecord
	|FROM
	|	&RedefinedTableName AS Rows
	|WHERE
	|	Rows.CompanyRecipient <> Rows.Organization";
	
	QueryTexts = New Array;
	QueryTexts.Add(StrReplace(QueryTemplate, "&RedefinedTableName", "TTOtherExpenses_"));
	If ThereAreTTLotsOfOtherExpenses Then
		QueryTexts.Add(StrReplace(QueryTemplate, "&RedefinedTableName", "TTLotsOfOtherExpenses"));
		
		QueryText =
		"SELECT DISTINCT
		|	&RedefinedDocumentPeriodName AS Period,
		|	Rows.Organization AS Organization,
		|	BEGINOFPERIOD(LinesOffline.Period, DAY) AS DateRecord
		|FROM
		|	TTLotsOfOtherExpenses AS Rows
		|		INNER JOIN AccumulationRegister.ItemisedExpensesLots AS LinesOffline
		|			ON LinesOffline.Recorder = &Ref
		|				AND LinesOffline.Period <> Rows.Period
		|				AND LinesOffline.LotCalculation";
		QueryTexts.Add(QueryText);
	EndIf;
	
	QueryText = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin(True));
	QueryText = StrReplace(QueryText, "&RedefinedDocumentPeriodName", "&" + PeriodName);
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region HandlersForMonthClosingStages

#Region DeferredExpensesAllocation

// Adds a stage to the table of monthly closing stages.
// The elements in this table are second-level elements in the stage tree in the month closing form.
// 
// Parameters:
// 	StepsTable - (See DataProcessors.MonthEndClosingOperations.FillInDescriptionOfClosingStagesOfMonth)
// 	CurrentParent - String - group ID.
Procedure AddStage_DeferredExpensesAllocation(StepsTable,CurrentParent) Export
	NewRow = MonthEndTransactionsServer.AddStageToTable(StepsTable, CurrentParent,
		Catalogs.MonthEndClosingOperations.DeferredExpensesAllocation,
		True, True, True);
		
	NewRow.MultilingualName = "vi = 'Phân bổ chi phí trả trước';
								|ru = 'Распределение расходов будущих периодов';
								|en = 'Deferred expense allocation';
								|it = 'Ripartizione spese dei riscontri attivi';
								|pl = 'Podział wydatków przyszłych okresów';
								|tr = 'Ertelenmiş giderler tahsisi'"; // @NStr-1
	NewRow.PerformedManually = True;
	NewRow.TextExecute = NStr("vi = 'Phân bổ';
								|ru = 'Распределить';
								|en = 'Allocate'; fa = 'تسهیم';
								|it = 'Ripartire';
								|pl = 'Allocate';
								|tr = 'Dağıt'");
	NewRow.ActionUse = MonthEndTransactionsServer.ActionDescription_ServerProcedure(
		"IncomeAndExpensesServer.Use_AllocationOfFutureExpenses");
	NewRow.ActionExecute  = MonthEndTransactionsServer.ActionDescription_OpenForm(
		Metadata.Documents.DeferredExpensesAllocation.Forms.DocumentsListForm.FullName());
EndProcedure

Procedure Use_AllocationOfFutureExpenses(HandlerParameters) Export
	
	MonthEndTransactionsServer.IncreaseAmountOfProcessedDataForMeasurement(HandlerParameters, 1);
	
	If Not GetFunctionalOption("UseAccountingOfOtherIncomeExpenses") Then
		
		MonthEndTransactionsServer.SetStateDisabled(
			HandlerParameters,
			NStr("vi = 'Không hạch toán thu nhập và chi phí khác';
				|ru = 'Учет прочих доходов и расходов не ведется';
				|en = 'Accounting of income and expenses is not kept'; fa = 'Accounting of income and expenses is not kept';
				|it = 'La contabilizzazione di altri ricavi e costi non viene effettuata';
				|pl = 'Ewidencja innych dochodów i rozchodów nie jest prowadzona';
				|tr = 'Diğer gelir ve giderlerin muhasebesi tutulmuyor'", Common.DefaultLanguageCode()));
			
		Return;
		
	EndIf;
	
	Query = New Query;
	MonthEndTransactionsServer.InitializeRequest(Query, HandlerParameters);
	
	QueryText = 
		"SELECT
		|	Data.Organization AS Organization,
		|	Data.Department AS Department,
		|	Data.LineOfBusiness AS LineOfBusiness,
		|	Data.ExpenseItem AS ExpenseItem,
		|	Data.DimensionOfExpenses AS DimensionOfExpenses,
		|	Data.SumBalance + Data.SumReceipt - Data.SumExpense AS Sum,
		|	Data.SumManBalance + Data.SumManReceipt - Data.SumManExpense AS SumMan,
		|	Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense AS SumCompl,
		|	Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense 
		|		- (Data.PermanentDifferenceBalance + Data.PermanentDifferenceReceipt - Data.PermanentDifferenceExpense) 
		|		- (Data.CostTDBalance + Data.CostTDReceipt - Data.CostTDExpense) AS AmountFA,
		|	Data.PermanentDifferenceBalance + Data.PermanentDifferenceReceipt - Data.PermanentDifferenceExpense AS PermanentDifference,
		|	Data.CostTDBalance + Data.CostTDReceipt - Data.CostTDExpense AS CostTD,
		|	Data.WithoutManAmounts AS WithoutManAmounts,
		|	Data.NoLocalAmounts AS NoLocalAmounts,
		|	Data.WithoutSumsTa AS WithoutSumsTa
		|INTO TTUnallocatedRBP_Preliminary
		|FROM
		|	(SELECT
		|		Data.Organization AS Organization,
		|		Data.Department AS Department,
		|		Data.ExpenseItem AS ExpenseItem,
		|		Data.DimensionOfExpenses AS DimensionOfExpenses,
		|		Data.LineOfBusiness AS LineOfBusiness,
		|		SUM(Data.SumReceipt) AS SumReceipt,
		|		SUM(Data.SumManReceipt) AS SumManReceipt,
		|		SUM(Data.SumComplReceipt) AS SumComplReceipt,
		|		SUM(Data.PermanentDifferenceReceipt) AS PermanentDifferenceReceipt,
		|		SUM(Data.CostTDReceipt) AS CostTDReceipt,
		|		SUM(Data.SumExpense) AS SumExpense,
		|		SUM(Data.SumManExpense) AS SumManExpense,
		|		SUM(Data.SumComplExpense) AS SumComplExpense,
		|		SUM(Data.PermanentDifferenceExpense) AS PermanentDifferenceExpense,
		|		SUM(Data.CostTDExpense) AS CostTDExpense,
		|		SUM(Data.SumBalance) AS SumBalance,
		|		SUM(Data.SumManBalance) AS SumManBalance,
		|		SUM(Data.SumComplBalance) AS SumComplBalance,
		|		SUM(Data.PermanentDifferenceBalance) AS PermanentDifferenceBalance,
		|		SUM(Data.CostTDBalance) AS CostTDBalance,
		|		MAX(Data.WithoutManAmounts) AS WithoutManAmounts,
		|		MAX(Data.NoLocalAmounts) AS NoLocalAmounts,
		|		MAX(Data.WithoutSumsTa) AS WithoutSumsTa
		|	FROM
		|		&RBPSources AS Data
		|	
		|	GROUP BY
		|		Data.Organization,
		|		Data.Department,
		|		Data.ExpenseItem,
		|		Data.DimensionOfExpenses,
		|		Data.LineOfBusiness) AS Data
		|WHERE
		|	(Data.SumBalance + Data.SumReceipt - Data.SumExpense <> 0
		|			OR Data.SumManBalance + Data.SumManReceipt - Data.SumManExpense <> 0
		|			OR Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense <> 0
		|			OR Data.SumComplBalance + Data.SumComplReceipt - Data.SumComplExpense 
		|				- (Data.PermanentDifferenceBalance + Data.PermanentDifferenceReceipt - Data.PermanentDifferenceExpense) 
		|				- (Data.CostTDBalance + Data.CostTDReceipt - Data.CostTDExpense) <> 0
		|			OR Data.WithoutManAmounts
		|			OR Data.NoLocalAmounts
		|			OR Data.WithoutSumsTa)
		|INDEX BY
		|	ExpenseItem,
		|	DimensionOfExpenses,
		|	Department,
		|	LineOfBusiness,
		|	Organization;
		|	
		|SELECT
		|	Data.Organization AS Organization,
		|	Data.Department AS Department,
		|	Data.LineOfBusiness AS LineOfBusiness,
		|	Data.ExpenseItem AS ExpenseItem,
		|	Data.DimensionOfExpenses AS DimensionOfExpenses,
		|	Data.Sum AS Sum,
		|	Data.SumMan AS SumMan,
		|	Data.SumCompl AS SumCompl,
		|	Data.AmountFA AS AmountFA,
		|	Data.PermanentDifference AS PermanentDifference,
		|	Data.CostTD AS CostTD,
		|	Data.WithoutManAmounts AS WithoutManAmounts,
		|	Data.NoLocalAmounts AS NoLocalAmounts,
		|	Data.WithoutSumsTa AS WithoutSumsTa
		|INTO TTUnallocatedRBP
		|FROM TTUnallocatedRBP_Preliminary AS Data
		|LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfMan
		|	ON DistributionOfMan.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DistributionOfMan.ExpenseItem = Data.ExpenseItem
		|	AND DistributionOfMan.Posted
		|	AND DistributionOfMan.ManagementAccounting
		|	AND DistributionOfMan.AmountEntryOptionMan = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
		|	AND DistributionOfMan.Organization = Data.Organization
		|	AND DistributionOfMan.Department = Data.Department
		|	AND DistributionOfMan.DimensionOfExpenses = Data.DimensionOfExpenses
		|	AND DistributionOfMan.LineOfBusiness = Data.LineOfBusiness
		|LEFT JOIN Document.DeferredExpensesAllocation AS DistributionOfLocal
		|	ON DistributionOfLocal.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND DistributionOfLocal.ExpenseItem = Data.ExpenseItem
		|	AND DistributionOfLocal.Posted
		|	AND DistributionOfLocal.LocalAccounting
		|	AND DistributionOfLocal.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
		|	AND DistributionOfLocal.Organization = Data.Organization
		|	AND DistributionOfLocal.Department = Data.Department
		|	AND DistributionOfLocal.DimensionOfExpenses = Data.DimensionOfExpenses
		|	AND DistributionOfLocal.LineOfBusiness = Data.LineOfBusiness
		|LEFT JOIN Document.DeferredExpensesAllocation AS TADistribution
		|	ON TADistribution.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
		|	AND TADistribution.ExpenseItem = Data.ExpenseItem
		|	AND TADistribution.Posted
		|	AND TADistribution.TaxAccounting
		|	AND TADistribution.AmountEntryOptionLocal = VALUE(Enum.OptionsOfDEAmountSpecification.DeterminedAutomatically)
		|	AND TADistribution.Organization = Data.Organization
		|	AND TADistribution.Department = Data.Department
		|	AND TADistribution.DimensionOfExpenses = Data.DimensionOfExpenses
		|	AND TADistribution.LineOfBusiness = Data.LineOfBusiness
		|WHERE
		|	(Data.Sum <> 0 OR Data.SumMan <> 0 OR Data.WithoutManAmounts) AND DistributionOfMan.Ref IS NULL
		|	OR (Data.SumCompl <> 0 OR Data.NoLocalAmounts) AND DistributionOfLocal.Ref IS NULL
		|	OR (Data.AmountFA <> 0 OR Data.WithoutSumsTa) AND TADistribution.Ref IS NULL
		|";
	
	QueryText = StrReplace(QueryText, "&RBPSources", "("+Documents.DeferredExpensesAllocation.RequestTextCostsForDistributionSources()+")"); //@Query-part
	QueryText = StrReplace(QueryText, "&ByAllCompanies", "FALSE"); //@Query-part
	QueryText = StrReplace(QueryText, "&ByAllBusinessUnits", "TRUE"); //@Query-part
	QueryText = StrReplace(QueryText, "&Department", "VALUE(Catalog.BusinessStructure.EmptyRef)"); //@Query-part
	QueryText = StrReplace(QueryText, "Organization = &Organization", "Organization IN (&CompanyArray)"); //@Query-part
	
	Query.Text = QueryText;
	
	Query.Execute();
		
	TemporaryTableSizes = MonthEndTransactionsServer.TemporaryTableSizes(Query, HandlerParameters);
	
	If TemporaryTableSizes.TTUnallocatedRBP = 0 Then
		
		MonthEndTransactionsServer.NoNeedToSetState(
			HandlerParameters,
			NStr("vi = 'Không có cuộc cách mạng mở nào bằng các khoản mục chi phí với tùy chọn Phân bổ ""Đối với chi phí trả trước""';
				|ru = 'Нет незакрытых оборотов по статьям расходов с вариантом распределения ""На расходы будущих периодов""';
				|en = 'No unclosed turnovers for expense item with the ""To deferred expenses"" allocation option'; fa = 'No unclosed turnovers for expense item with the ""To deferred expenses"" allocation option';
				|it = 'Non ci sono dei movimenti non chiusi per le voci di spesa con variante di allocazione ""Secondo le spese dei periodi futuri""';
				|pl = 'Brak niezamkniętych obrotów wg pozycji rozchodów z opcją podziału ""На расходы будущих периодов""';
				|tr = '“Ertelenmiş giderler için” dağıtım seçeneği ile gider kalemlerine göre kapatılmamış cirolar bulunmamaktadır'", Common.DefaultLanguageCode()));
	 
	EndIf;
	
EndProcedure

// System health checks related to the stage.

Procedure DescriptionOfAudits_AllocationOfFutureExpenses(TableOfChecks) Export
	
	// Expenses of future periods.
	VerificationDescription = MonthEndTransactionsServer.AddDescriptionOfNewCheck(TableOfChecks,
		"UnallocatedDeferredExpenses",
		Catalogs.MonthEndClosingOperations.DeferredExpensesAllocation,
		Enums.TimeOfStartingMonthEndClosingOperationCheck.BeforeAndAfterCalculation,
		"IncomeAndExpensesServer.VerificationOfUnallocatedDeferredExpenses",
		Enums.AccountingIssueSeverity.Warning);
	
	MonthEndTransactionsServer.FillInPresentationOfNewCheck(VerificationDescription,
		NStr("vi = 'Chi phí trả trước chưa phân bổ';
			|ru = 'Нераспределенные расходы будущих периодов';
			|en = 'Unallocated deferred expenses'; fa = 'Unallocated deferred expenses';
			|it = 'Spese non allocate dei periodi futuri';
			|pl = 'Nieprzydzielone rozchody przyszłych okresów';
			|tr = 'Dağıtılmayan ertelenmiş giderler'", Common.DefaultLanguageCode()),
		NStr("vi = 'Đã phát hiện có chi phí chưa được phân bổ theo các dạng LCTT với phương án phân bổ ""Đối với chi phí trả trước"".';
			|ru = 'Обнаружены нераспределенные расходы по статьям с вариантом распределения ""На расходы будущих периодов"".';
			|en = 'Unallocated expenses of items with the ""To deferred expenses"" allocation option are detected.'; fa = 'Unallocated expenses of items with the ""To deferred expenses"" allocation option are detected.';
			|it = 'Sono state rilevate spese non distribuite per voci con variante di distribuzione ""Per le spese dei periodi successivi"".';
			|pl = 'Wykryto nieprzydzielone rozchody według pozycji z wariantem przydzielenia ""Na rozchody przyszłych okresów"".';
			|tr = '""Ertelenmiş giderler için"" dağıtım seçeneğine sahip kalemler için dağıtılmayan giderler bulundu.'", Common.DefaultLanguageCode()));
	
EndProcedure

Procedure VerificationOfUnallocatedDeferredExpenses(CheckParameters) Export
	
	If Not MonthEndTransactionsServer.VerificationIsPerformedByMonthClosingMechanism(CheckParameters) Then
		Return;
	EndIf;
		
	FieldList = New ValueList;
	FieldList.Add("Organization", 			NStr("vi = 'Doanh nghiệp';
													|ru = 'Организация';
													|en = 'Company'; fa = 'Company';
													|it = 'Azienda';
													|pl = 'Organizacja';
													|tr = 'İş yeri'", Common.DefaultLanguageCode()));
	FieldList.Add("Department", 			NStr("vi = 'Bộ phận';
												|ru = 'Подразделение';
												|en = 'Business unit'; fa = 'Business unit';
												|it = 'Reparto';
												|pl = 'Dział';
												|tr = 'Departman'", Common.DefaultLanguageCode()));
	FieldList.Add("ExpenseItem", 			NStr("vi = 'Dạng chi phí';
													|ru = 'Статья расходов';
													|en = 'Expense item'; fa = 'قلم هزینه';
													|it = 'Voce di spese';
													|pl = 'Rodzaj kosztu';
													|tr = 'Gider kalemi'", Common.DefaultLanguageCode()));
	FieldList.Add("DimensionOfExpenses", 		NStr("vi = 'Đối tượng phân tích chi phí';
														|ru = 'Аналитика расходов';
														|en = 'Expense dimension'; fa = 'بُعد هزینه';
														|it = 'Analitica delle uscite';
														|pl = 'Analityka kosztów';
														|tr = 'Gider boyutu'", Common.DefaultLanguageCode()));
	FieldList.Add("LineOfBusiness", NStr("vi = 'Lĩnh vực hoạt động';
										|ru = 'Направление деятельности';
										|en = 'Line of business'; fa = 'خط کسب‌وکار';
										|it = 'Settore di attività';
										|pl = 'Rodzaj działalności';
										|tr = 'İş kolu'", Common.DefaultLanguageCode()));
	FieldList.Add("Sum",		 			NStr("vi = 'Số tiền (gồm thuế GTGT)';
													|ru = 'Сумма (с НДС)';
													|en = 'Amount (including VAT)'; fa = 'مبلغ (با VAT)';
													|it = 'Importo (IVA inclusa)';
													|pl = 'Wartość (z VAT)';
													|tr = 'Tutar (KDV dahil)'", Common.DefaultLanguageCode()));
	FieldList.Add("SumMan",		 		NStr("vi = 'Số tiền (chưa ThGTGT)';
												|ru = 'Сумма (без НДС)';
												|en = 'Amount (excluding VAT)'; fa = 'مبلغ (بدون مالیات بر ارزش افزوده)';
												|it = 'Importo (senza IVA)';
												|pl = 'Wartość (bez VAT)';
												|tr = 'Tutar (KDV hariç)'", Common.DefaultLanguageCode()));
	FieldList.Add("SumCompl",		 		NStr("vi = 'Số tiền (KTDN)';
													|ru = 'Сумма (БУ)';
													|en = 'Amount (LA)'; fa = 'مبلغ (محلی)';
													|it = 'Importo (Contabilità)';
													|pl = 'Wartość (EK)';
													|tr = 'Tutar (AC)'", Common.DefaultLanguageCode()));
	FieldList.Add("AmountFA",		 			NStr("vi = 'Số tiền (KTTh)';
														|ru = 'Сумма (НУ)';
														|en = 'TA amount'; fa = 'مبلغ حسابداری مالیاتی';
														|it = 'Importo (Registro Fiscale)';
														|pl = 'Wartość (EP)';
														|tr = 'Tutar (VM)'", Common.DefaultLanguageCode()));
	FieldList.Add("PermanentDifference",		NStr("vi = 'Số tiền (CLVV)';
													|ru = 'Сумма (ПР)';
													|en = 'Amount (PD)'; fa = 'مبلغ (تفاوت دائم)';
													|it = 'Importo (differenza costante)';
													|pl = 'Wartość (różnica trwała)';
													|tr = 'Tutar (Kalıcı fark)'", Common.DefaultLanguageCode()));
	FieldList.Add("CostTD",		NStr("vi = 'Số tiền (CLTT)';
										|ru = 'Сумма (ВР)';
										|en = 'Amount (TD)'; fa = 'مبلغ (تفاوت موقت)';
										|it = 'Importo (differenza temporanea)';
										|pl = 'Wartość (różnica przejściowa)';
										|tr = 'Tutar (Geçici fark)'", Common.DefaultLanguageCode()));
	FieldList.Add("WithoutManAmounts",		 		NStr("vi = 'Số tiền tự động (KTQT)';
															|ru = 'Автосумма (УУ)';
															|en = 'Autosum (MA)'; fa = 'Autosum (MA)';
															|it = 'Importo automatico (CG)';
															|pl = 'Autosuma (EZ)';
															|tr = 'Otomatik tutar (Yönetim Muhasebesi)'", Common.DefaultLanguageCode()));
	FieldList.Add("NoLocalAmounts",		 		NStr("vi = 'Số tiền tự động (KTDN)';
														|ru = 'Автосумма (БУ)';
														|en = 'Autosum (LA)'; fa = 'Autosum (LA)';
														|it = 'Importo automatico (Cont)';
														|pl = 'Autosuma (EK)';
														|tr = 'Otomatik tutar (AC)'", Common.DefaultLanguageCode()));
	FieldList.Add("WithoutSumsTa",		 		NStr("vi = 'Số tiền tự động (KTTh)';
														|ru = 'Автосумма (НУ)';
														|en = 'Autosum (TA)'; fa = 'Autosum (TA)';
														|it = 'Importo automatico (CF)';
														|pl = 'Autosuma (EP)';
														|tr = 'Otomatik tutar (VM)'", Common.DefaultLanguageCode()));
	RegistrationParameters = MonthEndTransactionsServer.InitializeRegistrationAndVerificationParameters(
		"TTUnallocatedRBP",
		NStr("vi = 'Trong kỳ %2 đang có chi phí trả trước chưa phân bổ theo doanh nghiệp ""%1""';
			|ru = 'В периоде %2 имеются нераспределенные расходы будущих периодов по организации ""%1""';
			|en = 'There are unallocated deferred expenses for %1 company in the %2 period.'; fa = 'There are unallocated deferred expenses for %1 company in the %2 period.';
			|it = 'Nel periodo %2 vi sono uscite non distribuite dei periodi successivi per l''azienda ""%1""';
			|pl = 'Okres %2 zawiera nieprzydzielone rozchody przyszłych okresów według firmy ""%1""';
			|tr = '%2 döneminde ""%1"" iş yeri için dağıtılmayan ertelenmiş giderler mevcut'", Common.DefaultLanguageCode()),
		FieldList);
	
	MonthEndTransactionsServer.RegisterValidationIssues(
		CheckParameters,
		RegistrationParameters);
	
EndProcedure

#EndRegion

#Region GettingArticleSelectionData

// Parameters:
//  ChoiceData 
//  Parameters - Structure:
//  	* SearchString - String -
//  StandardProcessing - Boolean
//
Procedure ProcessingOfObtainingDataOnSelectionOfMainItemOfAssetsLiabilities(ChoiceData, Parameters, StandardProcessing) Export
	
	Query = New Query;
	
	RequestProperties = PropertiesOfRequestForObtainingDataForSelectingItemsOfAssetsLiabilities(Parameters);
	
	Query.Text = RequestProperties.QueryText;
	For Each QueryParameter In RequestProperties.QueryOptions Do
		Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
	EndDo;
		
	If Parameters.Property("AddExpenseItems") And Parameters.AddExpenseItems Then
		
		RequestProperties = PropertiesOfRequestToGetDataForSelectingExpenditureItems(Parameters);
		Query.Text = Query.Text + "
			|
			|UNION ALL
			|
			|" + RequestProperties.QueryText;
			
		For Each QueryParameter In RequestProperties.QueryOptions Do
			Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
		EndDo;
	EndIf;
	
	If Parameters.Property("AddIncomeItems") And Parameters.AddIncomeItems Then
		
		RequestProperties = PropertiesOfRequestToGetDataForSelectingIncomeItems(Parameters);
		Query.Text = Query.Text + "
			|
			|UNION ALL
			|
			|" + RequestProperties.QueryText;
			
		For Each QueryParameter In RequestProperties.QueryOptions Do
			Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
		EndDo;
	EndIf;
	
	Query.Text = Query.Text + "
	|
	|ORDER BY
	|	Description
	|";
	
	Query.SetParameter("SearchString", Parameters.SearchString + "%");

	ChoiceData = New ValueList;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		SelectionDataValue = New Structure();
		SelectionDataValue.Insert("Value", Selection.Ref);
		SelectionDataValue.Insert("DeletionMark", Selection.DeletionMark);
		
		Presentation = TrimAll(Selection.Presentation) + " (" + TrimAll(Selection.Code) + ")";
		
		ChoiceData.Add(SelectionDataValue, Presentation);
		
	EndDo;
	
	StandardProcessing = False;
	
EndProcedure

// Parameters:
//  ChoiceData 
//  Parameters - Structure:
//  	* SearchString - String -
//  	* ChoiceFoldersAndItems - FoldersAndItemsUse -
//  StandardProcessing - Boolean
//
Procedure ProcessingReceiptOfSelectionDataForExpenseItem(ChoiceData, Parameters, StandardProcessing) Export
	ChartsOfCharacteristicTypes.ExpenseItems.ProcessingSelectionParameters(Parameters);
	If Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Items And ValueIsFilled(Parameters.SearchString) Then
		
		Query = New Query;
		
		RequestProperties = PropertiesOfRequestToGetDataForSelectingExpenditureItems(Parameters);
		
		Query.Text = RequestProperties.QueryText;
		For Each QueryParameter In RequestProperties.QueryOptions Do
			Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
		EndDo;
		
		If Parameters.Property("AddItemsOfAssetsLiabilities") 
				And Parameters.AddItemsOfAssetsLiabilities 
				And GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
			
			RequestProperties = PropertiesOfRequestForObtainingDataForSelectingItemsOfAssetsLiabilities(Parameters);
			Query.Text = Query.Text + "
				|
				|UNION ALL
				|
				|" + RequestProperties.QueryText;
				
			For Each QueryParameter In RequestProperties.QueryOptions Do
				Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
			EndDo;
		EndIf;
		
		If Parameters.Property("AddIncomeItems") And Parameters.AddIncomeItems Then
		
			RequestProperties = PropertiesOfRequestToGetDataForSelectingIncomeItems(Parameters);
			Query.Text = Query.Text + "
				|
				|UNION ALL
				|
				|" + RequestProperties.QueryText;
				
			For Each QueryParameter In RequestProperties.QueryOptions Do
				Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
			EndDo;
			
		EndIf;
		
		Query.Text = Query.Text + "
		|
		|ORDER BY
		|	Description
		|";
		
		Query.SetParameter("SearchString", Parameters.SearchString + "%");
		
		ChoiceData = New ValueList;
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			SelectionDataValue = New Structure();
			SelectionDataValue.Insert("Value", Selection.Ref);
			SelectionDataValue.Insert("DeletionMark", Selection.DeletionMark);
			
			Presentation = TrimAll(Selection.Presentation) + " (" + TrimAll(Selection.Code) + ")";
			
			ChoiceData.Add(SelectionDataValue, Presentation);
		EndDo;
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

// Parameters:
//  ChoiceData 
//  Parameters - Structure:
//  	* SearchString - String -
//  StandardProcessing - Boolean
//
Procedure ProcessingReceiptOfSelectionDataForIncomeItem(ChoiceData, Parameters, StandardProcessing) Export
	
	If Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Items And ValueIsFilled(Parameters.SearchString) Then
		
		Query = New Query;
		
		RequestProperties = PropertiesOfRequestToGetDataForSelectingIncomeItems(Parameters);
		
		Query.Text = RequestProperties.QueryText;
		For Each QueryParameter In RequestProperties.QueryOptions Do
			Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
		EndDo;
		
		If Parameters.Property("AddItemsOfAssetsLiabilities") 
				And Parameters.AddItemsOfAssetsLiabilities
				And GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities") Then
			
			RequestProperties = PropertiesOfRequestForObtainingDataForSelectingItemsOfAssetsLiabilities(Parameters);
			Query.Text = Query.Text + "
				|
				|UNION ALL
				|
				|" + RequestProperties.QueryText;
				
			For Each QueryParameter In RequestProperties.QueryOptions Do
				Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
			EndDo;
		EndIf;
		
		If Parameters.Property("AddExpenseItems") And Parameters.AddExpenseItems Then
			
			RequestProperties = PropertiesOfRequestToGetDataForSelectingExpenditureItems(Parameters);
			Query.Text = Query.Text + "
				|
				|UNION ALL
				|
				|" + RequestProperties.QueryText;
				
			For Each QueryParameter In RequestProperties.QueryOptions Do
				Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
			EndDo;
		EndIf;
		
		Query.Text = Query.Text + "
		|
		|ORDER BY
		|	Description
		|";
		
		Query.SetParameter("SearchString", Parameters.SearchString + "%");
		
		ChoiceData = New ValueList;
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			SelectionDataValue = New Structure();
			SelectionDataValue.Insert("Value", Selection.Ref);
			SelectionDataValue.Insert("DeletionMark", Selection.DeletionMark);
			
			Presentation = TrimAll(Selection.Presentation) + " (" + TrimAll(Selection.Code) + ")";
			
			ChoiceData.Add(SelectionDataValue, Presentation);
		EndDo;
		
		StandardProcessing = False;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

#Region ArticleSelectionAndAnalytics

// Parameters:
//  Form - ClientApplicationForm - Form:
// * Object - DocumentObject - 
// 	ChoiceParameters - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
// 					- See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
// 
// Returns:
//  Structure - Data Select Articles And Analytics:
// * ChoiceParametersArray - FixedArray of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions - 
// * MatchingSelectionParametersToFormElements - Structure - 
//
Function DataSelectArticlesAndAnalytics(Form, ChoiceParameters)
	
	If TypeOf(ChoiceParameters) = Type("Array") Then
		ChoiceParametersArray = ChoiceParameters;
	Else
		ChoiceParametersArray = CommonClientServer.ValueInArray(ChoiceParameters);
	EndIf;
	
	MatchingSelectionParametersToFormElements = New Structure;
	IndexOf = 0;
	For Each ChoiceParameters In ChoiceParametersArray Do
		For Each TagName In ChoiceParameters.FormItems.AssetRef Do
			MatchingSelectionParametersToFormElements.Insert(TagName, IndexOf);
		EndDo;
		For Each TagName In ChoiceParameters.FormItems.DimensionOfExpenses Do
			MatchingSelectionParametersToFormElements.Insert(TagName, IndexOf);
		EndDo;
		For Each TagName In ChoiceParameters.FormItems.DimensionOfRevenue Do
			MatchingSelectionParametersToFormElements.Insert(TagName, IndexOf);
		EndDo;
		For Each TagName In ChoiceParameters.FormItems.AssetsLiabilitiesDimension Do
			MatchingSelectionParametersToFormElements.Insert(TagName, IndexOf);
		EndDo;
		If ChoiceParameters.DefaultValue = Undefined Then
			If ChoiceParameters.ChoosingExpenseItem Then
				ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
			ElsIf ChoiceParameters.ChoosingIncomeItem Then
				ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.IncomeItems.EmptyRef();
			ElsIf ChoiceParameters.SelectingItemOfAssetsLiabilities Then
				ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.AssetLiabilityItems.EmptyRef();
			EndIf;
		EndIf;
		
		If ValueIsFilled(ChoiceParameters.ChoosingExpenseItem) And ChoiceParameters.DimensionOfExpenses <> "" Then
			ChoiceParameters.Insert("CacheOfDetailsOfExpenseItem", New Structure());
			ChoiceParameters.CacheOfDetailsOfExpenseItem.Insert("DimensionOfExpensesRequired_", ChoiceParameters.DimensionOfExpenses + "Required_");
			ChoiceParameters.CacheOfDetailsOfExpenseItem.Insert("DimensionOfExpensesOrderImplementation", ChoiceParameters.DimensionOfExpenses + "OrderImplementation");
		EndIf;
		If ValueIsFilled(ChoiceParameters.ChoosingIncomeItem) And ChoiceParameters.DimensionOfRevenue <> "" Then
			ChoiceParameters.Insert("CacheOfIncomeItemDetails", New Structure());
			ChoiceParameters.CacheOfIncomeItemDetails.Insert("DimensionOfRevenueRequired_", ChoiceParameters.DimensionOfRevenue + "Required_");
		EndIf;
		If ValueIsFilled(ChoiceParameters.SelectingItemOfAssetsLiabilities) And ChoiceParameters.AssetsLiabilitiesDimension <> ""  Then
			ChoiceParameters.Insert("CacheOfDetailsOfItemOfAssetsLiabilities", New Structure());
			ChoiceParameters.CacheOfDetailsOfItemOfAssetsLiabilities.Insert("AssetsLiabilitiesDimensionNotUsed", ChoiceParameters.AssetsLiabilitiesDimension + "NotUsed");
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
	CheckArticleAndAnalyticsSelectionOptions(Form, ChoiceParametersArray);
	
	DataSelectArticlesAndAnalytics = New Structure();
	DataSelectArticlesAndAnalytics.Insert("ChoiceParametersArray", New FixedArray(ChoiceParametersArray));
	DataSelectArticlesAndAnalytics.Insert("MatchingSelectionParametersToFormElements", MatchingSelectionParametersToFormElements);
	
	Return DataSelectArticlesAndAnalytics;
	
EndFunction

// Parameters:
// 	Form - ClientApplicationForm - object form:
// 		* Object - DocumentObject - form object
// 	ChoiceParametersArray - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
//
Procedure CheckArticleAndAnalyticsSelectionOptions(Form, ChoiceParametersArray)
	
	If Not Common.DebugMode() Then
		Return;
	EndIf;
	
	Errors = Undefined;
	
	For Each ChoiceParameters In ChoiceParametersArray Do
		
		If Find(ChoiceParameters.DataPath, "Object.") > 0 Then
			SearchTSName = StrReplace(ChoiceParameters.DataPath, "Object.", "");
			SearchByTS = True;
			TabularSection = Form.Object[SearchTSName]; // TabularSection - 
			ListOfTSColumns = TabularSection.Unload().Columns;
		ElsIf ChoiceParameters.DataPath = "Object" Then
			SearchByTS = False;
		Else
			Break; // Calling from the internal article selection and analytics form
		EndIf;
		
		If Not SearchByTS And ValueIsFilled(ChoiceParameters.ArticleAvailabilityCriteriaInLines) Then
			
			MessageTemplate = NStr("vi = 'Dạng thu nhập và chi phí nằm ở phần đầu chứng từ. Không thể sử dụng tham số ""%1"".';
									|ru = 'Статья располагается в шапке документа. Использование параметра ""%1"" не допускается.';
									|en = 'The item is located at the document header. The parameter ''%1'' cannot be used.'; fa = 'The item is located at the document header. The parameter ''%1'' cannot be used.';
									|it = 'Le voci sono posizionate nell''intestazione del documento. L''utilizzo del parametro ""%1"" non è previsto.';
									|pl = 'Pozycja znajduje się w nagłówku dokumentu. Używanie parametru ""%1"" nie jest dopuszczalne.';
									|tr = 'Kalem, belgenin üst bilgisinde bulunur. ""%1"" parametresinin kullanımına izin verilmiyor.'");
			ErrorMessage = StrTemplate(MessageTemplate, "ArticleAvailabilityCriteriaInLines");
			CommonClientServer.AddUserError(
					Errors,
					"",
					ErrorMessage,
					"");
		EndIf;
		
		ArrayOfVerifiedDetails = New Array(); // Array of String
		ArrayOfVerifiedDetails.Add(ChoiceParameters["AssetRef"]);
		If ChoiceParameters.ChoosingExpenseItem Then
			ArrayOfVerifiedDetails.Add(ChoiceParameters["DimensionOfExpenses"]);
		EndIf;
		
		If ChoiceParameters.ChoosingIncomeItem Then
			ArrayOfVerifiedDetails.Add(ChoiceParameters["DimensionOfRevenue"]);
		EndIf;
		
		If ChoiceParameters.SelectingItemOfAssetsLiabilities Then
			ArrayOfVerifiedDetails.Add(ChoiceParameters["AssetsLiabilitiesDimension"]);
		EndIf;
		
		If ChoiceParameters.ChoosingExpenseItem And ValueIsFilled(ChoiceParameters.DimensionOfExpenses) Then
			ArrayOfVerifiedDetails.Add(ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesRequired_);
			ArrayOfVerifiedDetails.Add(ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation);
		EndIf;

		If ChoiceParameters.ChoosingIncomeItem And ValueIsFilled(ChoiceParameters.DimensionOfRevenue) Then
			ArrayOfVerifiedDetails.Add(ChoiceParameters.CacheOfIncomeItemDetails.DimensionOfRevenueRequired_);
		EndIf;
		
		If ChoiceParameters.SelectingItemOfAssetsLiabilities And ValueIsFilled(ChoiceParameters.AssetsLiabilitiesDimension) Then
			ArrayOfVerifiedDetails.Add(ChoiceParameters.CacheOfDetailsOfItemOfAssetsLiabilities.AssetsLiabilitiesDimensionNotUsed);
		EndIf;
		
		If ChoiceParameters.SelectingItemOfAssetsLiabilities + ChoiceParameters.ChoosingIncomeItem + ChoiceParameters.ChoosingExpenseItem > 1 Then
			If Not ValueIsFilled(ChoiceParameters.ArticleType) Then 
				
				MessageTemplate = NStr("vi = 'Chưa chỉ ra giá trị tham số ""%1"" trong tham số chọn dạng và đối tượng phân tích.';
										|ru = 'Не указано значение параметра ""%1"" в параметрах выбора статей и аналитик .';
										|en = 'The value of the parameter ""%1"" in parameters of item selection and analytics is not specified.'; fa = 'The value of the parameter ""%1"" in parameters of item selection and analytics is not specified.';
										|it = 'Il valore del parametro ""%1"" nei parametri di selezione delle voci e delle analitiche non è indicato.';
										|pl = 'Nie określono wartości parametru ""%1"" w parametrach wyboru artykułów i analityki.';
										|tr = 'Kalem ve boyut seçimi seçeneklerinde ""%1"" parametresinin değeri belirtilmedi.'");

				ErrorMessage = StrTemplate(MessageTemplate, "ArticleType");
				CommonClientServer.AddUserError(
						Errors,
						"",
						ErrorMessage
						,
						"");
			Else
				ArrayOfVerifiedDetails.Add(ChoiceParameters["ArticleType"]);
			EndIf;
		EndIf;
		
		For Each AttributeToCheck In ArrayOfVerifiedDetails Do
				If SearchByTS And Not ThereIsWHColumn(ListOfTSColumns, AttributeToCheck) Then
					CommonClientServer.AddUserError(
							Errors,
							"",
							StrTemplate(NStr("vi = 'Thiếu mục tin %1 trong %2 của mẫu đối tượng.';
											|ru = 'Отсутствует реквизит %1 в %2 формы объекта.';
											|en = 'No attribute %1 in %2 of the item form.'; fa = 'No attribute %1 in %2 of the item form.';
											|it = 'Manca il requisito %1 in %2 del modulo dell''oggetto.';
											|pl = 'Brak rekwizytu %1 w %2 formularzu obiektu.';
											|tr = '%2 nesne formunda %1 özniteliği eksik.'"), 
										AttributeToCheck, 
										?(SearchByTS, StrTemplate(NStr("vi = 'phần bảng %1';
																		|ru = 'табличной части %1';
																		|en = 'table %1'; fa = 'table %1';
																		|it = 'parte tabellare %1';
																		|pl = 'części tabelarycznej %1';
																		|tr = '%1 tablo bölümünde'"), SearchTSName), NStr("vi = 'danh sách mục tin';
																												|ru = 'списке реквизитов';
																												|en = 'list of attributes'; fa = 'list of attributes';
																												|it = 'elenco dei requisiti';
																												|pl = 'liście rekwizytów';
																												|tr = 'öznitelik listesinde'"))),
							"");
				EndIf;
				
				If Not SearchByTS 
					And Not (CommonClientServer.HasAttributeOrObjectProperty(Form.Object, AttributeToCheck)
							Or CommonClientServer.HasAttributeOrObjectProperty(Form, AttributeToCheck)) Then
					CommonClientServer.AddUserError(
							Errors,
							"",
							StrTemplate(NStr("vi = 'Thiếu mục tin %1 trong %2 của mẫu đối tượng.';
											|ru = 'Отсутствует реквизит %1 в %2 формы объекта.';
											|en = 'No attribute %1 in %2 of the item form.'; fa = 'No attribute %1 in %2 of the item form.';
											|it = 'Manca il requisito %1 in %2 del modulo dell''oggetto.';
											|pl = 'Brak rekwizytu %1 w %2 formularzu obiektu.';
											|tr = '%2 nesne formunda %1 özniteliği eksik.'"), 
										AttributeToCheck, 
										?(SearchByTS, StrTemplate(NStr("vi = 'phần bảng %1';
																		|ru = 'табличной части %1';
																		|en = 'table %1'; fa = 'table %1';
																		|it = 'parte tabellare %1';
																		|pl = 'części tabelarycznej %1';
																		|tr = '%1 tablo bölümünde'"), SearchTSName), NStr("vi = 'danh sách mục tin';
																												|ru = 'списке реквизитов';
																												|en = 'list of attributes'; fa = 'list of attributes';
																												|it = 'elenco dei requisiti';
																												|pl = 'liście rekwizytów';
																												|tr = 'öznitelik listesinde'"))),
							"");
				EndIf;
		EndDo;
		
		For Each FormItem In ChoiceParameters.FormItems Do
			For Each TagName In FormItem.Value Do 
			
				If Not CommonClientServer.HasAttributeOrObjectProperty(Form.Items, TagName) Then
					CommonClientServer.AddUserError(
							Errors,
							"",
							StrTemplate(NStr("vi = 'Thiếu kiểm soát %1 trên biểu mẫu.';
											|ru = 'Отсутствует элемент управления %1 на форме.';
											|en = 'No management item %1 on the form.'; fa = 'No management item %1 on the form.';
											|it = 'Manca l''elemento di controllo %1 nel modulo.';
											|pl = 'Brak elementu zarządzania %1 na formularzu.';
											|tr = '%1 formunda öğe yönetimi eksik.'"), TagName),
							"");
					
				Else
					FormControl_ = Form.Items[TagName];
					
					ArticleDataPath = ChoiceParameters.DataPath + "." + ChoiceParameters[FormItem.Key]; 
					ArticleDataPathCurLine = "CurrentData." + ChoiceParameters[FormItem.Key];
					
					If Not StrFind(FormControl_.DataPath, ArticleDataPath)
						And Not StrFind(FormControl_.DataPath, ArticleDataPathCurLine) Then 
						CommonClientServer.AddUserError(
							Errors,
							"",
							StrTemplate(
							NStr("vi = 'Đường dẫn đến dữ liệu cho phần tử biểu mẫu %1 không chính xác: %2,%3 dự kiến.';
								|ru = 'Путь к данным элемента формы %1 указан некорректно: %2, ожидается %3.';
								|en = 'The path to the data in the item of the form %1 is not correct: %2, expected %3.'; fa = 'The path to the data in the item of the form %1 is not correct: %2, expected %3.';
								|it = 'Il percorso verso questi elementi del modulo %1 non è indicato correttamente: %2, previsto %3.';
								|pl = 'Ścieżka do danych elementu formularza %1 została podana niepoprawnie:%2, oczekuje się %3.';
								|tr = '%1 form öğesinin veri yolu yanlış: %2, beklenen %3.'"),
								FormItem.Key,
								FormControl_.DataPath,
								ArticleDataPath),
							"");
						
					EndIf;
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors);
	
	If Not Errors = Undefined Then
		ExceptionText = NStr("vi = 'Lỗi được tìm thấy trong khi kiểm tra các tùy chọn dạng và chỉ số';
							|ru = 'Найдены ошибки при проверке параметров выбора статей и аналитик';
							|en = 'Errors are found during checking parameters of item and analytics selection'; fa = 'Errors are found during checking parameters of item and analytics selection';
							|it = 'Sono stati trovati alcuni errori durante la verifica dei parametri di selezione delle voci e delle analitiche';
							|pl = 'Znaleziono błędy podczas weryfikacji parametrów wyboru artykułów i analityki';
							|tr = 'Kalem ve boyut seçim parametrelerini doğrularken bulunan hatalar'");
		Raise ExceptionText;
	EndIf;
	
EndProcedure

Procedure UpdateArticleDetails(Form, Val ChoiceParametersArray)
	
	For Each Parameters In ChoiceParametersArray Do
		
		DataPathParts = StrSplit(Parameters.DataPath, ".", False);
		If DataPathParts.Count() = 2 Then
			Data = Form[DataPathParts[0]][DataPathParts[1]];
			ThisIsTable = True;
		ElsIf DataPathParts.Count() = 1 
			And TypeOf(Form[DataPathParts[0]]) = Type("FormDataCollection") Then
			Data = Form[DataPathParts[0]];
			ThisIsTable = True;
		Else
			Data = Form;
			ThisIsTable = False;
		EndIf;
		
		If ThisIsTable Then
			FillInDetailsOfArticleInTable(Data, Parameters);
		Else
			FillInDetailsOfArticleInObject(Data, Parameters);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInDetailsOfArticleInObject(Data, Val ChoiceParameters)
	
	If ValueIsFilled(ChoiceParameters.DataPath) Then 
		AssetRef = Data[ChoiceParameters.DataPath][ChoiceParameters.AssetRef];
	Else
		AssetRef = Data[ChoiceParameters.AssetRef];
	EndIf;
	
	If ChoiceParameters.ArticleType <> "" Then
		ArticleType = 0;
		If TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.ExpenseItems") Then
			ArticleType = 1;
		ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.IncomeItems") Then
			ArticleType = 2;
		ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
			ArticleType = 3;
		EndIf;
		Data[ChoiceParameters.ArticleType] = ArticleType;
	EndIf;
	
	ArticleDetails_1 = IncomeAndExpensesServerCallCached.ArticleDetailsValues(AssetRef);
	
	If ChoiceParameters.ChoosingExpenseItem And ChoiceParameters.DimensionOfExpenses <> "" Then
		Data[ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesRequired_] = ArticleDetails_1.ControlDimensionFilling;
		Data[ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation] = ArticleDetails_1.DimensionOfExpensesOrderImplementation;
	EndIf;
	
	If ChoiceParameters.ChoosingIncomeItem And ChoiceParameters.DimensionOfRevenue <> "" Then
		Data[ChoiceParameters.CacheOfIncomeItemDetails.DimensionOfRevenueRequired_] = ArticleDetails_1.ControlDimensionFilling;
	EndIf;
	
	If ChoiceParameters.SelectingItemOfAssetsLiabilities And ChoiceParameters.AssetsLiabilitiesDimension <> "" Then
		Data[ChoiceParameters.CacheOfDetailsOfItemOfAssetsLiabilities.AssetsLiabilitiesDimensionNotUsed] = ArticleDetails_1.WithoutDimension;
	EndIf;
	
EndProcedure

Procedure FillInDetailsOfArticleInTable(DataTable, Val ChoiceParameters)
	
	SetPrivilegedMode(True);
	Query = New Query;
	Query.Text =
	"SELECT
	|	*
	|INTO DataTable
	|FROM
	|	&DataTable AS DataTable
	|;
	|
	|SELECT
	|	DataTable.LineNumber AS LineNumber,
	|	CASE
	|		WHEN VALUETYPE(&ArticleField) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN 1
	|		WHEN VALUETYPE(&ArticleField) = TYPE(ChartOfCharacteristicTypes.IncomeItems)
	|			THEN 2
	|		WHEN VALUETYPE(&ArticleField) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN 3
	|		ELSE 0
	|	END AS ArticleType,
	|	ISNULL(ExpenseItems.ControlDimensionFilling, FALSE) AS DimensionOfExpensesRequired_,
	|	ISNULL(ExpenseItems.DimensionOfExpensesOrderImplementation, FALSE)  AS DimensionOfExpensesOrderImplementation,
	|	ISNULL(IncomeItems.ControlDimensionFilling, FALSE)  AS DimensionOfRevenueRequired_,
	|	ISNULL(AssetLiabilityItems.WithoutDimension, FALSE)               AS AssetsLiabilitiesDimensionNotUsed
	|FROM
	|	DataTable AS DataTable
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		&ArticleField = ExpenseItems.Ref
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.IncomeItems AS IncomeItems
	|	ON
	|		&ArticleField = IncomeItems.Ref
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
	|	ON
	|		&ArticleField = AssetLiabilityItems.Ref
	|";
	
	Query.Text = StrReplace(Query.Text, "&ArticleField", "DataTable." + ChoiceParameters.AssetRef);
	
	Query.SetParameter("DataTable", DataTable.Unload());
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		TableRow = DataTable[Selection.LineNumber-1];
		If ChoiceParameters.ArticleType <> "" Then
			TableRow[ChoiceParameters.ArticleType] = Selection.ArticleType;
		EndIf;
		If ChoiceParameters.ChoosingExpenseItem And ChoiceParameters.DimensionOfExpenses <> "" Then
			TableRow[ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesRequired_] = Selection.DimensionOfExpensesRequired_;
			TableRow[ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation] = Selection.DimensionOfExpensesOrderImplementation;
		EndIf;
		If ChoiceParameters.ChoosingIncomeItem And ChoiceParameters.DimensionOfRevenue <> "" Then
			TableRow[ChoiceParameters.CacheOfIncomeItemDetails.DimensionOfRevenueRequired_] = Selection.DimensionOfRevenueRequired_;
		EndIf;
		If ChoiceParameters.SelectingItemOfAssetsLiabilities And ChoiceParameters.AssetsLiabilitiesDimension <> "" Then
			TableRow[ChoiceParameters.CacheOfDetailsOfItemOfAssetsLiabilities.AssetsLiabilitiesDimensionNotUsed] = Selection.AssetsLiabilitiesDimensionNotUsed;
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInDetailsOfArticleInTableRow(String, Val ChoiceParameters)
	
	AssetRef = String[ChoiceParameters.AssetRef];
	
	If ChoiceParameters.ArticleType <> "" Then
		ArticleType = 0;
		If TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.ExpenseItems") Then
			ArticleType = 1;
		ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.IncomeItems") Then
			ArticleType = 2;
		ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
			ArticleType = 3;
		EndIf;
		String[ChoiceParameters.ArticleType] = ArticleType;
	EndIf;
	
	ArticleDetails_1 = IncomeAndExpensesServerCallCached.ArticleDetailsValues(AssetRef);
	
	If ChoiceParameters.ChoosingExpenseItem And ChoiceParameters.DimensionOfExpenses <> "" Then
		String[ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesRequired_] = ArticleDetails_1.ControlDimensionFilling;
		String[ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation] = ArticleDetails_1.DimensionOfExpensesOrderImplementation;
	EndIf;
	
	If ChoiceParameters.ChoosingIncomeItem And ChoiceParameters.DimensionOfRevenue <> "" Then
		String[ChoiceParameters.CacheOfIncomeItemDetails.DimensionOfRevenueRequired_] = ArticleDetails_1.ControlDimensionFilling;
	EndIf;
	
	If ChoiceParameters.SelectingItemOfAssetsLiabilities And ChoiceParameters.AssetsLiabilitiesDimension <> "" Then
		String[ChoiceParameters.CacheOfDetailsOfItemOfAssetsLiabilities.AssetsLiabilitiesDimensionNotUsed] = ArticleDetails_1.WithoutDimension;
	EndIf;
	
EndProcedure

Procedure FillInDetailsOfArticleInRowOfTableInBatches(String, Val ChoiceParameters, CachedData)
	
	AssetRef = String[ChoiceParameters.AssetRef];
	
	If ChoiceParameters.ArticleType <> "" Then
		ArticleType = 0;
		If TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.ExpenseItems") Then
			ArticleType = 1;
		ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.IncomeItems") Then
			ArticleType = 2;
		ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
			ArticleType = 3;
		EndIf;
		String[ChoiceParameters.ArticleType] = ArticleType;
	EndIf;
	
	ArticleDetails_1 = New Structure;
	ArticleDetails_1.Insert("ValueType", New TypeDescription("Undefined"));
	ArticleDetails_1.Insert("ControlDimensionFilling", False);
	ArticleDetails_1.Insert("DimensionOfExpensesOrderImplementation",  False);
	ArticleDetails_1.Insert("WithoutDimension", False);
	
	If ValueIsFilled(AssetRef) Then
		If AssetRef = ChoiceParameters.DefaultValue Then
			ArticleDetails_1 = IncomeAndExpensesServerCallCached.ArticleDetailsValues(AssetRef);
		Else
			DataForProcessing = BatchProcessingOfTablePartServer.DataForStringProcessing("ArticleDetailsValues", CachedData);
			If Not DataForProcessing = Undefined Then
				FillPropertyValues(ArticleDetails_1, DataForProcessing[0]);
			EndIf;
		EndIf;
	EndIf;
	
	If ChoiceParameters.ChoosingExpenseItem And ChoiceParameters.DimensionOfExpenses <> "" Then
		String[ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesRequired_] = ArticleDetails_1.ControlDimensionFilling;
		String[ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation] = ArticleDetails_1.DimensionOfExpensesOrderImplementation;
	EndIf;
	
	If ChoiceParameters.ChoosingIncomeItem And ChoiceParameters.DimensionOfRevenue <> "" Then
		String[ChoiceParameters.CacheOfIncomeItemDetails.DimensionOfRevenueRequired_] = ArticleDetails_1.ControlDimensionFilling;
	EndIf;
	
	If ChoiceParameters.SelectingItemOfAssetsLiabilities And ChoiceParameters.AssetsLiabilitiesDimension <> "" Then
		String[ChoiceParameters.CacheOfDetailsOfItemOfAssetsLiabilities.AssetsLiabilitiesDimensionNotUsed] = ArticleDetails_1.WithoutDimension;
	EndIf;
	
EndProcedure

Procedure InitializeArticleAndAnalystValues_(Object, ChoiceParametersArray)
	
	For Each Parameters In ChoiceParametersArray Do
		
		Data = IncomeAndExpensesClientServer.DataAlongWay(Object, Parameters.DataPath);
		ThisIsTable = (StrFind(Parameters.DataPath, ".") <> 0) Or TypeOf(Data) = Type("FormDataCollection");

		If ThisIsTable Then
			For Each TableRow In Data Do
				IncomeAndExpensesClientServer.InitializeArticleAndAnalystValues(TableRow, Parameters);
			EndDo;
		Else
			IncomeAndExpensesClientServer.InitializeArticleAndAnalystValues(Data, Parameters);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure SetPropertiesOfArticleElements(Form, Val ChoiceParametersArray)

	FormItems = Form.Items;
	For Each Parameters In ChoiceParametersArray Do
			
		AddExpenseItemsParameter =        New ChoiceParameter("AddExpenseItems", Parameters.ChoosingExpenseItem);
		AddIncomeItemsParameter =         New ChoiceParameter("AddIncomeItems", Parameters.ChoosingIncomeItem);
		ParameterAddItemsOfAssetsLiabilities = New ChoiceParameter("AddItemsOfAssetsLiabilities", Parameters.SelectingItemOfAssetsLiabilities);
		
		For Each TagName In Parameters.FormItems.AssetRef Do
			
			FormItem = FormItems[TagName]; // FormField -
			
			FormItem.ChooseType = False;
			
			If Parameters.AvailabilityByOperation <> Undefined Then
				FormItem.Visible = True;
				FormItem.Enabled = True;
				If Parameters.HideArticleThatIsUnavailableDueToOperation Then
					FormItem.Visible = Parameters.AvailabilityByOperation;
				Else
					FormItem.Enabled = Parameters.AvailabilityByOperation;
				EndIf;
			EndIf;
			
			// The selection parameters
			NewSelectionOptions = New Array;
			ArticleItemSelectionOptions = FormItem.ChoiceParameters; // FixedArray of ChoiceParameter
			For Each CurrentParameter In ArticleItemSelectionOptions Do
				If CurrentParameter.Name <> AddExpenseItemsParameter.Name
					 And CurrentParameter.Name <> AddIncomeItemsParameter.Name
					 And CurrentParameter.Name <> ParameterAddItemsOfAssetsLiabilities.Name Then
					NewSelectionOptions.Add(CurrentParameter);
				EndIf;
			EndDo;
			NewSelectionOptions.Add(AddExpenseItemsParameter);
			NewSelectionOptions.Add(AddIncomeItemsParameter);
			NewSelectionOptions.Add(ParameterAddItemsOfAssetsLiabilities);
			
			If Parameters.ChoosingExpenseItem Then
				For Each Filter In Parameters.SelectionOfExpenditureItems Do
					If ValueIsFilled(Filter.Value) Then
						NewSelectionOptions.Add(New ChoiceParameter("Filter." + Filter.Key, Filter.Value));
					EndIf;
				EndDo;
			EndIf;
			
			FormItem.ChoiceParameters = New FixedArray(NewSelectionOptions);
			
			If Not Parameters.RequiredFilling Then
				FormItem.AutoMarkIncomplete = False;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure ConnectAnalystWithArticles(Form, Val ChoiceParametersArray)
	
	FormItems = Form.Items;
	For Each ChoiceParameters In ChoiceParametersArray Do
		
		Data = IncomeAndExpensesClientServer.DataAlongWay(Form, ChoiceParameters.DataPath); 
		
		DataInHeader = False;
		If TypeOf(Data) = Type("FormDataStructure") Then
			DataInHeader = True;
		EndIf;
		
		FullPathToArticleInHeader = ChoiceParameters.DataPath + "." + ChoiceParameters.AssetRef;
		
		For Each TagName In ChoiceParameters.FormItems.DimensionOfExpenses Do
			AnalyticsElement = FormItems[TagName];
			ElementShapeTable = TMCommonUseClientServer.ElementShapeTable(AnalyticsElement);
			If DataInHeader Then
				FullArticlePath = FullPathToArticleInHeader;
			ElsIf ElementShapeTable = Undefined Then
				FullArticlePath = StrReplace(AnalyticsElement.DataPath, ChoiceParameters.DimensionOfExpenses, ChoiceParameters.AssetRef);
			Else
				FullArticlePath = StrTemplate("Items.%1.CurrentData.%2", ElementShapeTable.Name, ChoiceParameters.AssetRef);
			EndIf;
			SetPropertiesOfAnalyticsElement(AnalyticsElement, FullArticlePath);
		EndDo;
		For Each TagName In ChoiceParameters.FormItems.DimensionOfRevenue Do
			AnalyticsElement = FormItems[TagName];
			ElementShapeTable = TMCommonUseClientServer.ElementShapeTable(AnalyticsElement);
			If DataInHeader Then
				FullArticlePath = FullPathToArticleInHeader;
			ElsIf ElementShapeTable = Undefined Then
				FullArticlePath = StrReplace(AnalyticsElement.DataPath, ChoiceParameters.DimensionOfRevenue, ChoiceParameters.AssetRef);
			Else
				FullArticlePath = StrTemplate("Items.%1.CurrentData.%2", ElementShapeTable.Name, ChoiceParameters.AssetRef);
			EndIf;
			SetPropertiesOfAnalyticsElement(AnalyticsElement, FullArticlePath);
		EndDo;
		For Each TagName In ChoiceParameters.FormItems.AssetsLiabilitiesDimension Do
			AnalyticsElement = FormItems[TagName];
			ElementShapeTable = TMCommonUseClientServer.ElementShapeTable(AnalyticsElement);
			If DataInHeader Then
				FullArticlePath = FullPathToArticleInHeader;
			ElsIf ElementShapeTable = Undefined Then
				FullArticlePath = StrReplace(AnalyticsElement.DataPath, ChoiceParameters.AssetsLiabilitiesDimension, ChoiceParameters.AssetRef);
			Else
				FullArticlePath = StrTemplate("Items.%1.CurrentData.%2", ElementShapeTable.Name, ChoiceParameters.AssetRef);
			EndIf;
			SetPropertiesOfAnalyticsElement(AnalyticsElement, FullArticlePath);
			AnalyticsElement.MarkIncomplete = False;
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure SetPropertiesOfAnalyticsElement(AnalyticsElement, FullArticlePath)
	
	AnalyticsElement.TypeLink = New TypeLink(FullArticlePath);
	
	ArrayOfSelectParameterRelationships = New Array;
	ArrayOfSelectParameterRelationships.Add(New ChoiceParameterLink("Filter.Owner", FullArticlePath, LinkedValueChangeMode.DontChange));
	AnalyticsElement.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	AnalyticsElement.AutoMarkIncomplete = False;
	AnalyticsElement.ChooseType = False;
	AnalyticsElement.DropListButton = False;
	AnalyticsElement.ChoiceButton = True;
	AnalyticsElement.ChoiceButtonRepresentation = ChoiceButtonRepresentation.ShowInInputField;
	
EndProcedure

Function ThereIsWHColumn(ListOfTSColumns, ColumnName)
	
	Return Not ListOfTSColumns.Find(ColumnName) = Undefined;
	
EndFunction

// The function retrieves the last item and expense analysis used in documents.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business transaction specified in the document.
//	Organization - CatalogRef.Companies - the organization specified in the document.
//	Department - CatalogRef.BusinessStructure - the division specified in the document.
//	Products - CatalogRef.Products - the item to fill in the item and expense analysis for.
//	Characteristic - CatalogRef.ItemsCharacteristics, Undefined - the item to fill in the item and expense analysis for.
//
// Returns:
//	QueryResultSelection - Article and cost analysis.
//
Function DefaultExpenseAnalyticsItem(BusinessOperation, Organization, Department, Products, Characteristic = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 1
	|	OtherExpenses.ExpenseItem AS ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|WHERE
	|	TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.ItemsLocationAttributes AS Filter
	|			WHERE
	|				Filter.Products = &Products
	|				AND &Characteristic
	|				AND OtherExpenses.ItemsLocationAttributes = Filter.DimensionKey
	|				AND OtherExpenses.Organization = &Organization
	|				AND OtherExpenses.Department = &Department
	|				AND OtherExpenses.BusinessOperation = &BusinessOperation)
	|
	|ORDER BY
	|	OtherExpenses.Period DESC");
	
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Department", Department);
	Query.SetParameter("Products", Products);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
	If ValueIsFilled(Characteristic) Then
		Query.Text = StrReplace(Query.Text, "&Characteristic", "Filter.Characteristic = &Characteristic");
		Query.SetParameter("Characteristic", Characteristic);
	Else
		Query.SetParameter("Characteristic", True);
	EndIf;
	
	Return Query.Execute().Select();
	
EndFunction

Function DataCompositionField(DataPath, FieldName)
	
	If DataPath = "" Then
		Return New DataCompositionField(FieldName);
	Else
		Return New DataCompositionField(DataPath + "." + FieldName);
	EndIf;
	
EndFunction

#EndRegion

#Region ObtainingTableOfDistributionOfCostsForCostOfGoodsForFormationOfDocumentReceiptOfAdditionalCostsDuringExchangeWithBP20

// This function generates the query text for the temporary expense table.
//
// Returns:
//	String - Query text
//
Function QueryTextTTExpenseTable()
	
	QueryText = "
	|SELECT
	|	MAX(GoodsTable.LineNumber) AS LineNumber,
	|	GoodsTable.ExpenseItem.CostAllocationRuleLocal.BaseOfAllocationByLots AS AllocatedAccordingToRule,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	SUM(GoodsTable.Sum) AS Sum,
	|	SUM(GoodsTable.VATAmount) AS VATAmount
	|
	|INTO TTExpenseTable
	|FROM
	|	Document.VendorInvoice.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|
	|GROUP BY
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	MAX(TableExpenses.LineNumber) AS LineNumber,
	|	TableExpenses.ExpenseItem.CostAllocationRuleLocal.BaseOfAllocationByLots AS AllocatedAccordingToRule,
	|	TableExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	SUM(TableExpenses.Sum) AS Sum,
	|	SUM(TableExpenses.VATAmount) AS VATAmount
	|FROM
	|	Document.VendorInvoiceServicesAndAssets.Expenses AS TableExpenses
	|WHERE
	|	TableExpenses.Ref = &Ref
	|	AND TableExpenses.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|
	|GROUP BY
	|	TableExpenses.ExpenseItem,
	|	TableExpenses.DimensionOfExpenses
	|
	|;
	|////////////////////////////////////////////////////////////////////////
	|";
	
	Return QueryText;
	
EndFunction // The text of the request for the Table of expenses()

// The function generates the query text for the table of distribution methods.
//
// Returns:
//	String - Query text
//
Function QueryTextTableOfDistributionMethods()
	
	QueryText = "
	|SELECT
	|	TableExpenses.AllocatedAccordingToRule AS AllocatedAccordingToRule,
	|	TableExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	CASE
	|		WHEN VALUETYPE(TableExpenses.DimensionOfExpenses) = TYPE(Document.PurchaseOrder)
	|			THEN TableExpenses.DimensionOfExpenses
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END AS PurchaseOrder,
	|	CASE WHEN TableExpenses.DimensionOfExpenses = VALUE(Document.PurchaseOrder.EmptyRef)
	|		OR TableExpenses.DimensionOfExpenses = VALUE(Document.TransferOrder.EmptyRef)
	|		OR TableExpenses.DimensionOfExpenses = VALUE(Document.VendorInvoice.EmptyRef)
	|		OR TableExpenses.DimensionOfExpenses = VALUE(Document.InventoryTransfer.EmptyRef)
	|		OR TableExpenses.DimensionOfExpenses = VALUE(Document.CustomerInvoiceIntercompany.EmptyRef)
	|		OR TableExpenses.DimensionOfExpenses = VALUE(Catalog.Warehouses.EmptyRef)
	|		OR TableExpenses.DimensionOfExpenses = VALUE(Catalog.Products.EmptyRef)
	|	THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END AS DimensionFilledIn,
	|	MAX(TableExpenses.LineNumber) AS BaseIndex_
	|	
	|INTO TableOfDistributionMethods
	|FROM
	|	TTExpenseTable AS TableExpenses
	|
	|GROUP BY
	|	TableExpenses.AllocatedAccordingToRule,
	|	TableExpenses.DimensionOfExpenses,
	|	CASE
	|		WHEN VALUETYPE(TableExpenses.DimensionOfExpenses) = TYPE(Document.PurchaseOrder)
	|			THEN TableExpenses.DimensionOfExpenses
	|		ELSE VALUE(Document.PurchaseOrder.EmptyRef)
	|	END,
	|	CASE WHEN TableExpenses.DimensionOfExpenses = VALUE(Document.PurchaseOrder.EmptyRef)
	|		OR TableExpenses.DimensionOfExpenses = VALUE(Document.TransferOrder.EmptyRef)
	|		OR TableExpenses.DimensionOfExpenses = VALUE(Document.VendorInvoice.EmptyRef)
	|		OR TableExpenses.DimensionOfExpenses = VALUE(Document.InventoryTransfer.EmptyRef)
	|		OR TableExpenses.DimensionOfExpenses = VALUE(Document.CustomerInvoiceIntercompany.EmptyRef)
	|		OR TableExpenses.DimensionOfExpenses = VALUE(Catalog.Warehouses.EmptyRef)
	|		OR TableExpenses.DimensionOfExpenses = VALUE(Catalog.Products.EmptyRef)
	|	THEN
	|		FALSE
	|	ELSE
	|		TRUE
	|	END
	|
	|INDEX BY
	|	DimensionOfExpenses,
	|	PurchaseOrder
	|;
	|///////////////////////////////////////////////////////////////////////////
	|";
	
	Return QueryText;
	
EndFunction // The text of the query of the Distribution method()

// This function generates the query text for the document table.
//
// Returns:
//	String - Query text
//
Function QueryTextTableDocuments()
	
	QueryText = "
	|// Receipt of goods based on specific purchase documents or orders to suppliers.
	|SELECT DISTINCT
	|	DocumentData.Ref AS Ref,
	|	TableOfDistributionMethods.PurchaseOrder AS PurchaseOrder,
	|	TableOfDistributionMethods.BaseIndex_ AS BaseIndex_
	|
	|INTO DocumentsTable
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|
	|	INNER JOIN
	|		Document.VendorInvoice.Goods AS GoodsTable
	|	ON
	|		DocumentData.Ref = GoodsTable.Ref
	|
	|	INNER JOIN
	|		TableOfDistributionMethods AS TableOfDistributionMethods
	|	ON
	|		TableOfDistributionMethods.DimensionFilledIn
	|		AND (DocumentData.Ref = TableOfDistributionMethods.DimensionOfExpenses
	|       	OR GoodsTable.PurchaseOrder = TableOfDistributionMethods.DimensionOfExpenses)
	|
	|UNION ALL
	|
	|// Purchases of goods under any purchase documents.
	|SELECT DISTINCT
	|	DocumentData.Ref AS Ref,
	|	TableOfDistributionMethods.PurchaseOrder AS PurchaseOrder,
	|	TableOfDistributionMethods.BaseIndex_ AS BaseIndex_
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|
	|	INNER JOIN
	|		Document.VendorInvoice.Goods AS GoodsTable
	|	ON
	|		DocumentData.Ref = GoodsTable.Ref
	|
	|	INNER JOIN
	|		TableOfDistributionMethods AS TableOfDistributionMethods
	|	ON
	|		TableOfDistributionMethods.DimensionOfExpenses = VALUE(Document.VendorInvoice.EmptyRef)
	|		OR TableOfDistributionMethods.DimensionOfExpenses = VALUE(Document.PurchaseOrder.EmptyRef)
	|WHERE
	|	DocumentData.Date BETWEEN &StartDate AND &EndDate
	|	AND (GoodsTable.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef) 
	|		AND TableOfDistributionMethods.DimensionOfExpenses = VALUE(Document.PurchaseOrder.EmptyRef)
	|		OR TableOfDistributionMethods.DimensionOfExpenses = VALUE(Document.VendorInvoice.EmptyRef)
	|	)
	|
	|UNION ALL
	|
	|// Transfers of goods between organizations.
	|SELECT DISTINCT
	|	DocumentData.Ref AS Ref,
	|	VALUE(Document.PurchaseOrder.EmptyRef) AS PurchaseOrder,
	|	TableOfDistributionMethods.BaseIndex_ AS BaseIndex_
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentData
	|
	|	INNER JOIN
	|		TableOfDistributionMethods AS TableOfDistributionMethods
	|	ON
	|		DocumentData.Ref = TableOfDistributionMethods.DimensionOfExpenses
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentData.Ref AS Ref,
	|	VALUE(Document.PurchaseOrder.EmptyRef) AS PurchaseOrder,
	|	TableOfDistributionMethods.BaseIndex_ AS BaseIndex_
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentData
	|
	|	INNER JOIN
	|		TableOfDistributionMethods AS TableOfDistributionMethods
	|	ON
	|		TableOfDistributionMethods.DimensionOfExpenses = VALUE(Document.CustomerInvoiceIntercompany.EmptyRef)
	|WHERE
	|	DocumentData.Date BETWEEN &StartDate AND &EndDate
	|
	|
	|UNION ALL
	|
	|// Assembly (disassembly) of goods.
	|SELECT DISTINCT
	|	DocumentData.Ref AS Ref,
	|	VALUE(Document.PurchaseOrder.EmptyRef) AS PurchaseOrder,
	|	TableOfDistributionMethods.BaseIndex_ AS BaseIndex_
	|FROM
	|	Document.AssemblyFromComponents AS DocumentData
	|
	|	INNER JOIN
	|		TableOfDistributionMethods AS TableOfDistributionMethods
	|	ON
	|		DocumentData.Ref = TableOfDistributionMethods.DimensionOfExpenses
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentData.Ref AS Ref,
	|	VALUE(Document.PurchaseOrder.EmptyRef) AS PurchaseOrder,
	|	TableOfDistributionMethods.BaseIndex_ AS BaseIndex_
	|FROM
	|	Document.AssemblyFromComponents AS DocumentData
	|
	|	INNER JOIN
	|		TableOfDistributionMethods AS TableOfDistributionMethods
	|	ON
	|		TableOfDistributionMethods.DimensionOfExpenses = VALUE(Document.AssemblyFromComponents.EmptyRef)
	|WHERE
	|	DocumentData.Date BETWEEN &StartDate AND &EndDate
	|
	|INDEX BY
	|	Ref,
	|	PurchaseOrder
	|;
	|///////////////////////////////////////////////////////////////////////////////////	
	|";
	
	Return QueryText;
	
EndFunction // The text of the Request for Documents()

// Returns a template for the request text for receiving data on product receipts.
//
// Parameters:
//   FilterTable - String - table for data selection
//   ConnectionConditions1 - String - conditions for joining tables of the first join request.
//   FirstQuery - Boolean - flag of the first request.
//
// Returns:
//   String - request template to use in the future to obtain data on product receipts.
//
Function ProductReceiptRequestTextTemplate(FilterTable, ConnectionConditions1, FirstQuery)
	QueryText = "
	|SELECT
	|	T.BaseIndex_ AS BaseIndex_,
	|	CostAccounting_.ItemsLocationAttributes.Products AS Products,
	|	CostAccounting_.ItemsLocationAttributes.WarehouseArea AS Warehouse,
	|	CostAccounting_.Period AS Period,
	|	CostAccounting_.Recorder AS DocumentInflow,
	|	VALUE(Document.PurchaseOrder.EmptyRef) AS PurchaseOrder,
	|	SUM(CostAccounting_.Count) AS Count,
	|	SUM(CostAccounting_.LocalCost) AS Cost
	|INTO TTReceiptOfGoods
	|FROM
	|	&FilterTable AS T
	|		INNER JOIN AccumulationRegister.InventoryCost AS CostAccounting_
	|		ON (&ConnectionConditions1)
	|WHERE
	|	CostAccounting_.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND CostAccounting_.Active
	|	AND CostAccounting_.Organization = &Organization
	|	AND CostAccounting_.AccountingSection IN (VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock), VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
	|	AND NOT VALUETYPE(CostAccounting_.Recorder) = TYPE(Document.VendorInvoice)
	// In both cases of using this request template, the order to the supplier must be the same as in the selection table.
	// Based on this, we add the condition that if the data fits the rest of the conditions, there is an empty link in the selection table to the requester.
	|	AND T.PurchaseOrder = VALUE(Document.PurchaseOrder.EmptyRef)
	|
	|GROUP BY
	|	T.BaseIndex_,
	|	CostAccounting_.ItemsLocationAttributes.Products,
	|	CostAccounting_.ItemsLocationAttributes.WarehouseArea,
	|	CostAccounting_.Period,
	|	CostAccounting_.Recorder
	|
	|HAVING
	|	SUM(CostAccounting_.Count) > 0
	|	AND SUM(CostAccounting_.LocalCost) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	T.BaseIndex_,
	|	CostAccounting_.ItemsLocationAttributes.Products,
	|	CostAccounting_.ItemsLocationAttributes.WarehouseArea,
	|	CostAccounting_.Period,
	|	CostAccounting_.Recorder,
	|	PurchaseOfGoodsServicesGoods.PurchaseOrder,
	|	SUM(CostAccounting_.Count),
	|	SUM(CostAccounting_.LocalCost)
	|FROM
	|	&FilterTable AS T
	|		INNER JOIN AccumulationRegister.InventoryCost AS CostAccounting_
	|		ON (&ConnectionConditions1)
	|		INNER JOIN Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|		ON (CostAccounting_.Recorder = PurchaseOfGoodsServicesGoods.Ref)
	|			AND (CostAccounting_.RowID = PurchaseOfGoodsServicesGoods.RowID)
	|			AND (T.PurchaseOrder = PurchaseOfGoodsServicesGoods.PurchaseOrder
	|				OR T.PurchaseOrder = VALUE(Document.PurchaseOrder.EmptyRef))
	|WHERE
	|	CostAccounting_.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND CostAccounting_.Active
	|	AND CostAccounting_.Organization = &Organization
	|	AND CostAccounting_.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	AND VALUETYPE(CostAccounting_.Recorder) = TYPE(Document.VendorInvoice)
	|
	|GROUP BY
	|	T.BaseIndex_,
	|	CostAccounting_.ItemsLocationAttributes.Products,
	|	CostAccounting_.ItemsLocationAttributes.WarehouseArea,
	|	CostAccounting_.Period,
	|	CostAccounting_.Recorder,
	|	PurchaseOfGoodsServicesGoods.PurchaseOrder
	|
	|HAVING
	|	SUM(CostAccounting_.Count) > 0
	|	AND SUM(CostAccounting_.LocalCost) > 0
	|
	|UNION ALL
	|
	|SELECT
	|	T.BaseIndex_,
	|	CostAccounting_.ItemsLocationAttributes.Products,
	|	CostAccounting_.ItemsLocationAttributes.WarehouseArea,
	|	CostAccounting_.Period,
	|	CostAccounting_.Recorder,
	|	VendorInvoiceInventoryKinds.PurchaseOrder,
	|	SUM(CostAccounting_.Count),
	|	SUM(CostAccounting_.LocalCost)
	|FROM
	|	&FilterTable AS T
	|		INNER JOIN AccumulationRegister.InventoryCost AS CostAccounting_
	|		ON (&ConnectionConditions1)
	|		INNER JOIN Document.VendorInvoice.InventoryKinds AS VendorInvoiceInventoryKinds
	|		ON (CostAccounting_.Recorder = VendorInvoiceInventoryKinds.Ref)
	|			AND (CostAccounting_.RowID = VendorInvoiceInventoryKinds.RowID)
	|			AND (T.PurchaseOrder = VendorInvoiceInventoryKinds.PurchaseOrder
	|				OR T.PurchaseOrder = VALUE(Document.PurchaseOrder.EmptyRef))
	|WHERE
	|	CostAccounting_.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND CostAccounting_.Active
	|	AND CostAccounting_.Organization = &Organization
	|	AND CostAccounting_.AccountingSection IN (
	|		VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries),
	|		 VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors))
	|	AND VALUETYPE(CostAccounting_.Recorder) = TYPE(Document.VendorInvoice)
	|
	|GROUP BY
	|	T.BaseIndex_,
	|	CostAccounting_.ItemsLocationAttributes.Products,
	|	CostAccounting_.ItemsLocationAttributes.WarehouseArea,
	|	CostAccounting_.Period,
	|	CostAccounting_.Recorder,
	|	VendorInvoiceInventoryKinds.PurchaseOrder
	|
	|HAVING
	|	SUM(CostAccounting_.Count) > 0
	|	AND SUM(CostAccounting_.LocalCost) > 0
	|";
	
	QueryText = StrReplace(QueryText, "&FilterTable", FilterTable); //@Query-part
	QueryText = StrReplace(QueryText, "&ConnectionConditions1", ConnectionConditions1); //@Query-part
	
	If Not FirstQuery Then
		QueryText = StrReplace(QueryText, "INTO TTReceiptOfGoods", ""); //@Query-part
	EndIf;
	Return QueryText;
	
EndFunction

// This function generates the query text for the product receipt table.
//
// Returns:
//	String - Query text
//
Function QueryTextTableUninvoicedReceipts()
	
	QueriesTexts = New Array();
	// The first set of requests to the Access document (Registrar) and the order to the supplier must be the same as in the selection table.
	FilterTable = "DocumentsTable"; //@Query-part
	ConnectionConditions1 = "CostAccounting_.Recorder = T.Ref"; //@Query-part
	QueriesTexts.Add(ProductReceiptRequestTextTemplate(FilterTable, ConnectionConditions1, True));
	
	// The second set of requests period is defined, only the order to the supplier must be the same as in the selection table.
	FilterTable = "TableOfDistributionMethods"; //@Query-part
	ConnectionConditions1 = "
		|	CostAccounting_.Period BETWEEN &StartDate AND &EndDate
		|	AND (T.DimensionOfExpenses = CostAccounting_.ItemsLocationAttributes.WarehouseArea
		|		OR T.DimensionOfExpenses = CostAccounting_.ItemsLocationAttributes.Products
		|		OR T.DimensionOfExpenses = VALUE(Catalog.Warehouses.EmptyRef)
		|		OR T.DimensionOfExpenses = VALUE(Catalog.Products.EmptyRef))"; //@Query-part
	QueriesTexts.Add(ProductReceiptRequestTextTemplate(FilterTable, ConnectionConditions1, False));
	
	QueryText = StrConcat(QueriesTexts, Common.UnionAllText()) + "; ";
	
	QueryText = QueryText + "
	|SELECT
	|	T.BaseIndex_ AS BaseIndex_,
	|	T.Products AS Products,
	|	T.DocumentInflow AS DocumentInflow,
	|	SUM(T.Count) AS Count,
	|	SUM(T.Cost) AS Cost
	|
	|INTO TableOfReceiptOfGoods
	|FROM
	|	TTReceiptOfGoods AS T
	|
	|GROUP BY
	|	T.BaseIndex_,
	|	T.Products,
	|	T.DocumentInflow
	|
	|INDEX BY
	|	BaseIndex_
	|;
	|///////////////////////////////////////////////////////////////////////////////////
	|";
	
	Return QueryText;
	
EndFunction // The text of the Request for the Availability of Goods()

// This function generates the query text for the distribution database table.
//
// Returns:
//	String - Query text
//
Function QueryTextTableAllocationBases()
	
	QueryText = "
	|SELECT
	|	TableOfDistributionMethods.BaseIndex_ AS BaseIndex_,
	|	TableOfReceiptOfGoods.Products AS Products,
	|	TableOfReceiptOfGoods.DocumentInflow AS DocumentInflow,
	|	TableOfReceiptOfGoods.DocumentInflow.Date AS Date,
	|	TableOfReceiptOfGoods.Count AS Count,
	|	TableOfReceiptOfGoods.Cost AS GoodsCost,
	|	
	|	CASE WHEN TableOfDistributionMethods.AllocatedAccordingToRule
	|		= VALUE(Enum.TypesOfCostAllocatingBase.GoodsQuantity)
	|	THEN
	|		ISNULL(TableOfReceiptOfGoods.Count, 0)
	|	ELSE
	|		ISNULL(TableOfReceiptOfGoods.Cost, 0)
	|	END AS Base
	|
	|FROM
	|	TableOfDistributionMethods AS TableOfDistributionMethods
	|
	|	LEFT JOIN
	|		TableOfReceiptOfGoods AS TableOfReceiptOfGoods
	|	ON
	|		TableOfDistributionMethods.BaseIndex_ = TableOfReceiptOfGoods.BaseIndex_
    |ORDER BY
    |	BaseIndex_,
    |	Date,
    |	DocumentInflow,
    |	Products
    |AUTOORDER
	|TOTALS
	|	SUM(Base)
	|BY
	|	BaseIndex_
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	Return QueryText;
	
EndFunction // The text of the query of the Distribution Database()

// This function generates the query text for the distribution expense table.
//
// Returns:
//	String - Query text
//
Function QueryTextTableOfExpenses()
	
	QueryText = "
	|SELECT
	|	TableOfDistributionMethods.BaseIndex_ AS BaseIndex_,
	|	SUM(TableExpenses.Sum) AS Sum,
	|	SUM(TableExpenses.VATAmount) AS VATAmount
	|FROM
	|	TTExpenseTable AS TableExpenses
	|
	|	INNER JOIN 
	|		TableOfDistributionMethods AS TableOfDistributionMethods
	|	ON
	|		TableExpenses.AllocatedAccordingToRule = TableOfDistributionMethods.AllocatedAccordingToRule
	|		AND TableExpenses.DimensionOfExpenses = TableOfDistributionMethods.DimensionOfExpenses
	|
	|GROUP BY
	|	TableOfDistributionMethods.BaseIndex_
	|
	|ORDER BY
	|	BaseIndex_
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	Return QueryText;
	
EndFunction // The text of the query is a table of inputs()

#EndRegion

#Region GettingArticleSelectionData

Function PropertiesOfRequestForObtainingDataForSelectingItemsOfAssetsLiabilities(Parameters)
	
	QueryText = 
	"SELECT
	|	AssetLiabilityItems.Ref,
	|	AssetLiabilityItems.Code,
	|	AssetLiabilityItems.Description,
	|	PRESENTATION(AssetLiabilityItems.Ref) AS Presentation,
	|	AssetLiabilityItems.DeletionMark
	|FROM
	|	ChartOfCharacteristicTypes.AssetLiabilityItems AS AssetLiabilityItems
	|WHERE
	|	&SelectionByPurposeOfArticles
	|	AND (AssetLiabilityItems.Description LIKE &SearchString
	|		OR AssetLiabilityItems.DescriptionLanguage1 LIKE &SearchString
	|		OR AssetLiabilityItems.DescriptionLanguage2 LIKE &SearchString)
	|	AND AssetLiabilityItems.IsFolder IN (&LimitingGroupsAndElements)
	|";
	
	QueryOptions = New Structure;
	QueryOptions.Insert("OtherAssetsAndLiabilitiesRecords", Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
	
	If Parameters.Property("FinancialAccountingObjects") Then
		ArticlesKinds = Undefined;
		If Parameters.Filter.Property("Kind", ArticlesKinds) And ValueIsFilled(ArticlesKinds) Then
			SelectionByPurposeOfArticles = "
			|	AssetLiabilityItems.Kind IN (&ArticlesKinds)";
			QueryOptions.Insert("ArticlesKinds", ArticlesKinds);
		Else
			SelectionByPurposeOfArticles = "
			|	AssetLiabilityItems.Kind <> VALUE(Enum.AssetAndLiabilityItemKinds.EmptyRef)";
		EndIf;
		
		AccountingDataTypes = Undefined;
		If Parameters.Filter.Property("TypeOfAccountingData", AccountingDataTypes) And ValueIsFilled(AccountingDataTypes) Then
			SelectionByPurposeOfArticles = "
			|	AND AssetLiabilityItems.TypeOfAccountingData IN (&AccountingDataTypes)";
			QueryOptions.Insert("AccountingDataTypes", AccountingDataTypes);
		EndIf;
		
		LedgerAccountsInEntrySettings = False;
		If Parameters.Filter.Property("LedgerAccountsInEntrySettings", LedgerAccountsInEntrySettings) Then
			SelectionByPurposeOfArticles = SelectionByPurposeOfArticles + "
			|	AND " + ?(LedgerAccountsInEntrySettings, "", "NOT ") + "AssetLiabilityItems.LedgerAccountsInEntrySettings";
		EndIf;
		
		NotOwnedControlledValues = False;
		If Parameters.Filter.Property("NotOwnedControlledValues", NotOwnedControlledValues) Then
			SelectionByPurposeOfArticles = SelectionByPurposeOfArticles + "
			|	AND " + ?(NotOwnedControlledValues, "", "NOT ") + "AssetLiabilityItems.NotOwnedControlledValues";
		EndIf;
		
		ThereIsDataSource = False;
		If Parameters.Property("ThereIsDataSource", ThereIsDataSource) Then
			SelectionByPurposeOfArticles = SelectionByPurposeOfArticles + "
			|	AND " + ?(ThereIsDataSource, "NOT ", "") + "AssetLiabilityItems.DataSource = """"";
		EndIf;
		
		FinancialAccounting_Settings = Undefined;
		If Parameters.Property("FinancialAccounting_Settings", FinancialAccounting_Settings)
			And TypeOf(FinancialAccounting_Settings) = Type("Structure") Then
			If Not FinancialAccounting_Settings.RevenueAccountingWithVAT
			 Or Not FinancialAccounting_Settings.RevenueAccountingExcludingVAT
			 Or Not FinancialAccounting_Settings.FormationOfCorrespondence Then
				RowsOfExcludedValues = New Array();
				LineSplitter = "," + Chars.LF + Chars.Tab;
				
				If Not FinancialAccounting_Settings.FormationOfCorrespondence Then
					RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.RetailCustomerAccountsReceivables)");
					RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ARAPSettlements)");
				EndIf;
				
				If Not FinancialAccounting_Settings.RevenueAccountingExcludingVAT Then
					RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.SalesRevenue)");
					RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.RevenueServicesAndAssets)");
				EndIf;
				
				If Not FinancialAccounting_Settings.RevenueAccountingWithVAT Then
					RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.RevenueFromSalesWithVAT)");
					RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OtherRevenueWithVAT)");
					RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.VATFromSales)");
					RowsOfExcludedValues.Add("VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.NDSSOfOtherSales)");
				EndIf;
				
				SelectionByPurposeOfArticles = SelectionByPurposeOfArticles + "
				|	AND NOT AssetLiabilityItems.Ref IN (
				|	" + StrConcat(RowsOfExcludedValues, LineSplitter) + ")";
			EndIf;
			
			If Not FinancialAccounting_Settings.AccountingForImproperValues Then
				SelectionByPurposeOfArticles = SelectionByPurposeOfArticles + "
				|	AND NOT AssetLiabilityItems.NotOwnedControlledValues";
			EndIf;
		EndIf;
	Else
		SelectionByPurposeOfArticles = "
		|	(AssetLiabilityItems.AssetLiability <> VALUE(Enum.KindsOfBalanceSheetStatementItems.EmptyRef)
		|		OR AssetLiabilityItems.DataSource = &OtherAssetsAndLiabilitiesRecords)";
		
		AssetLiability = Undefined;
		If Parameters.Filter.Property("AssetLiability", AssetLiability) And ValueIsFilled(AssetLiability) Then
			SelectionByPurposeOfArticles = SelectionByPurposeOfArticles + "
			|	AND AssetLiabilityItems.AssetLiability IN (&AssetLiability)";
			QueryOptions.Insert("AssetLiability", AssetLiability);
		EndIf;
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SelectionByPurposeOfArticles", SelectionByPurposeOfArticles);
	
	LimitingGroupsAndElements = New Array; // Array of Boolean
	If Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Folders Then
		LimitingGroupsAndElements.Add(True);
	ElsIf Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Items Then
		LimitingGroupsAndElements.Add(False);
	Else
		LimitingGroupsAndElements.Add(True);
		LimitingGroupsAndElements.Add(False);
	EndIf;
	QueryOptions.Insert("LimitingGroupsAndElements", LimitingGroupsAndElements);
	
	Result = New Structure;
	Result.Insert("QueryText",     QueryText);
	Result.Insert("QueryOptions", QueryOptions);
	
	Return Result;
	
EndFunction

Function PropertiesOfRequestToGetDataForSelectingExpenditureItems(Parameters)
	QueryText =
	"SELECT
	|	ExpenseItems.Ref,
	|	ExpenseItems.Code,
	|	ExpenseItems.Description,
	|	PRESENTATION(ExpenseItems.Ref) AS Presentation,
	|	ExpenseItems.DeletionMark
	|FROM
	|	ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|WHERE
	|	(ExpenseItems.Description LIKE &SearchString
	|		OR ExpenseItems.DescriptionLanguage1 LIKE &SearchString
	|		OR ExpenseItems.DescriptionLanguage2 LIKE &SearchString
	|		OR ExpenseItems.Code LIKE &SearchString)
	|	AND NOT ExpenseItems.Ref IN (&BlockedArticles)
	|	AND (NOT ExpenseItems.RestrictUsageInBusinessTransactions
	|		OR &ForAll_BusinessTransactions
	|		OR ExpenseItems.Ref IN (
	|			SELECT
	|				AvailableTransactions.Ref
	|			FROM
	|				ChartOfCharacteristicTypes.ExpenseItems.AvailableBusinessTransactions AS AvailableTransactions
	|			WHERE
	|			AvailableTransactions.BusinessOperation = &BusinessOperation
	|		)
	|	 )
	|	AND ExpenseItems.CostAllocationOptionLocal <> VALUE(Enum.CostAllocationOptions.OnOtherAssets)
	|	AND (ExpenseItems.CostAllocationOptionManag IN (&CostAllocationOptionManag)
	|		OR &ForAllDistributionOptions
	|		OR &SelectDistributionOptionsForOr)
	|	AND (ExpenseItems.CostAllocationOptionLocal IN (&CostAllocationOptionLocal)
	|		OR &ForAllDistributionOptions
	|		OR &SelectDistributionOptionsForOr)
	|	AND (ExpenseItems.CostAllocationOptionTax IN (&CostAllocationOptionTax)
	|		OR ExpenseItems.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.EmptyRef)
	|		OR &ForAllDistributionOptions
	|		OR &SelectDistributionOptionsForOr)
	|	AND (&SelectDistributionOptionsForOr
	|		AND (ExpenseItems.CostAllocationOptionManag IN (&CostAllocationOptionManag)
	|			OR ExpenseItems.CostAllocationOptionLocal IN (&CostAllocationOptionLocal)
	|			OR ExpenseItems.CostAllocationOptionTax IN (&CostAllocationOptionTax))
	|		OR NOT &SelectDistributionOptionsForOr)
	|	AND (ExpenseItems.ActivityTypeForTaxAccountingOfCosts IN (&ActivityTypeForTaxAccountingOfCosts)
	|		OR &ForAllTypesOfActivitiesForTaxExpenseAccounting)
	|	AND (ExpenseItems.ProductionCostType IN (&ProductionCostType)
	|		OR &ForAllTypesOfCosts)
	|	AND (ExpenseItems.LoanAndDepositContracts OR &ExcludingLoanAndDepositAgreements)
	|	AND (ExpenseItems.ExpensesOnAssets = &ExpensesOnAssets OR &ExpensesOnAssets = UNDEFINED)
	|	AND (ExpenseItems.IntangibleAssetsAndRDExpenses = &IntangibleAssetsAndRDExpenses OR &IntangibleAssetsAndRDExpenses = UNDEFINED)
	|	AND (ExpenseItems.ResearchAndDevelopmentExpenses = &ResearchAndDevelopmentExpenses OR &ResearchAndDevelopmentExpenses = UNDEFINED)
	|	AND (ExpenseItems.RMOrderExpenses = &RMOrderExpenses OR &RMOrderExpenses = UNDEFINED)
	|	AND (&RepairCosts = TRUE AND (ExpenseItems.ExpensesOnAssets OR ExpenseItems.RMOrderExpenses)
	|		OR &RepairCosts = UNDEFINED)
	|";
	
	QueryOptions = New Structure;
	
	BusinessOperation = Undefined;
	If Parameters.Filter.Property("BusinessOperation") Then
		BusinessOperation = Parameters.Filter.BusinessOperation;
	EndIf;
	QueryOptions.Insert("BusinessOperation", BusinessOperation);
	QueryOptions.Insert("ForAll_BusinessTransactions",    BusinessOperation = Undefined);
	
	CostAllocationOption = Undefined;
	SelectDistributionOptionsForOr = False;
	ForAllDistributionOptions = True;
	If Parameters.Filter.Property("CostAllocationOption") Then
		CostAllocationOption = Parameters.Filter.CostAllocationOption;
		QueryOptions.Insert("CostAllocationOptionManag", CostAllocationOption);
		QueryOptions.Insert("CostAllocationOptionLocal", CostAllocationOption);
		QueryOptions.Insert("CostAllocationOptionTax", CostAllocationOption);
		ForAllDistributionOptions = False;
	EndIf;
	If Parameters.Filter.Property("CostAllocationOptionManag") Then
		QueryOptions.Insert("CostAllocationOptionManag", Parameters.Filter.CostAllocationOptionManag);
		SelectDistributionOptionsForOr = True;
		ForAllDistributionOptions = False;
	EndIf;
	If Parameters.Filter.Property("CostAllocationOptionLocal") Then
		QueryOptions.Insert("CostAllocationOptionLocal", Parameters.Filter.CostAllocationOptionLocal);
		SelectDistributionOptionsForOr = True;
		ForAllDistributionOptions = False;
	EndIf;
	If Parameters.Filter.Property("CostAllocationOptionTax") Then
		QueryOptions.Insert("CostAllocationOptionTax", Parameters.Filter.CostAllocationOptionTax);
		SelectDistributionOptionsForOr = True;
		ForAllDistributionOptions = False;
	EndIf;
	If Not QueryOptions.Property("CostAllocationOptionManag") Then
		QueryOptions.Insert("CostAllocationOptionManag", Undefined);
	EndIf;
	If Not QueryOptions.Property("CostAllocationOptionLocal") Then
		QueryOptions.Insert("CostAllocationOptionLocal", Undefined);
	EndIf;
	If Not QueryOptions.Property("CostAllocationOptionTax") Then
		QueryOptions.Insert("CostAllocationOptionTax", Undefined);
	EndIf;
	If Parameters.Filter.Property("CostSharingOptionOr") Then
		CostAllocationOption = Parameters.Filter.CostSharingOptionOr;
		QueryOptions.Insert("CostAllocationOptionManag", CostAllocationOption);
		QueryOptions.Insert("CostAllocationOptionLocal", CostAllocationOption);
		QueryOptions.Insert("CostAllocationOptionTax", CostAllocationOption);
		SelectDistributionOptionsForOr = True;
	EndIf;
	QueryOptions.Insert("ForAllDistributionOptions", ForAllDistributionOptions);
	QueryOptions.Insert("SelectDistributionOptionsForOr", SelectDistributionOptionsForOr);
	
	ActivityTypeForTaxAccountingOfCosts = Undefined;
	If Parameters.Filter.Property("ActivityTypeForTaxAccountingOfCosts") Then
		ActivityTypeForTaxAccountingOfCosts = Parameters.Filter.ActivityTypeForTaxAccountingOfCosts;
	EndIf;
	QueryOptions.Insert("ActivityTypeForTaxAccountingOfCosts", ActivityTypeForTaxAccountingOfCosts);
	QueryOptions.Insert("ForAllTypesOfActivitiesForTaxExpenseAccounting", ActivityTypeForTaxAccountingOfCosts = Undefined);
	
	LoanAndDepositContracts = Undefined;
	If Parameters.Filter.Property("LoanAndDepositContracts") Then
		LoanAndDepositContracts = Parameters.Filter.LoanAndDepositContracts;
	EndIf;
	QueryOptions.Insert("ExcludingLoanAndDepositAgreements", LoanAndDepositContracts = Undefined);
	
	ExpensesOnAssets = Undefined;
	If Parameters.Filter.Property("ExpensesOnAssets") Then
		ExpensesOnAssets = Parameters.Filter.ExpensesOnAssets;
	EndIf;
	QueryOptions.Insert("ExpensesOnAssets", ExpensesOnAssets);
	
	IntangibleAssetsAndRDExpenses = Undefined;
	If Parameters.Filter.Property("IntangibleAssetsAndRDExpenses") Then
		IntangibleAssetsAndRDExpenses = Parameters.Filter.IntangibleAssetsAndRDExpenses;
	EndIf;
	QueryOptions.Insert("IntangibleAssetsAndRDExpenses", IntangibleAssetsAndRDExpenses);
	
	ResearchAndDevelopmentExpenses = Undefined;
	If Parameters.Filter.Property("ResearchAndDevelopmentExpenses") Then
		ResearchAndDevelopmentExpenses = Parameters.Filter.ResearchAndDevelopmentExpenses;
	EndIf;
	QueryOptions.Insert("ResearchAndDevelopmentExpenses", ResearchAndDevelopmentExpenses);
	
	RMOrderExpenses = Undefined;
	If Parameters.Filter.Property("RMOrderExpenses") Then
		RMOrderExpenses = Parameters.Filter.RMOrderExpenses;
	EndIf;
	QueryOptions.Insert("RMOrderExpenses", RMOrderExpenses);
	
	RepairCosts = Undefined;
	If Parameters.Filter.Property("RepairCosts") Then
		RepairCosts = Parameters.Filter.RepairCosts;
	EndIf;
	QueryOptions.Insert("RepairCosts", RepairCosts);
	
	QueryOptions.Insert("BlockedArticles", ChartsOfCharacteristicTypes.ExpenseItems.BlockedExpenditureItems());
	
	ProductionCostType = Undefined;
	If Parameters.Filter.Property("ProductionCostType") Then
		ProductionCostType = Parameters.Filter.ProductionCostType;
	EndIf;
	QueryOptions.Insert("ProductionCostType", ProductionCostType);
	QueryOptions.Insert("ForAllTypesOfCosts", ProductionCostType = Undefined);
	
	Result = New Structure;
	Result.Insert("QueryText",     QueryText);
	Result.Insert("QueryOptions", QueryOptions);
	
	Return Result;
	
EndFunction

Function PropertiesOfRequestToGetDataForSelectingIncomeItems(Parameters)
	
	QueryText =
	"SELECT
	|	IncomeItems.Ref AS Ref,
	|	IncomeItems.Code AS Code,
	|	IncomeItems.Description AS Description,
	|	PRESENTATION(IncomeItems.Ref) AS Presentation,
	|	IncomeItems.DeletionMark AS DeletionMark
	|FROM
	|	ChartOfCharacteristicTypes.IncomeItems AS IncomeItems
	|WHERE
	|	(IncomeItems.Description LIKE &SearchString
	|		OR IncomeItems.DescriptionLanguage1 LIKE &SearchString
	|		OR IncomeItems.DescriptionLanguage2 LIKE &SearchString)
	|	AND NOT IncomeItems.IsFolder
	|	AND NOT IncomeItems.Ref IN (&BlockedArticles)
	|	AND (IncomeItems.LoanAndDepositContracts OR &ExcludingLoanAndDepositAgreements)
	|";
	
	QueryOptions = New Structure;
	QueryOptions.Insert("BlockedArticles", ChartsOfCharacteristicTypes.IncomeItems.BlockedRevenueItems());
	
	LoanAndDepositContracts = Undefined;
	If Parameters.Filter.Property("LoanAndDepositContracts") Then
		LoanAndDepositContracts = Parameters.Filter.LoanAndDepositContracts;
	EndIf;
	QueryOptions.Insert("ExcludingLoanAndDepositAgreements", LoanAndDepositContracts = Undefined);
	
	Result = New Structure;
	Result.Insert("QueryText",     QueryText);
	Result.Insert("QueryOptions", QueryOptions);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
