
#Region Public

#Region ArticleSelectionAndAnalytics

// Handles a change to the article, is called in the corresponding event handler of the element.
//
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	Item - FormField - The element of choice article.
// 	IdOfTSLine - Number - The Cur line number of the TS.
//
Procedure AssetRefOnChange(Form, Item, IdOfTSLine = 0) Export
	
	ArticleSelectionParameters = ItemSelectionOptions(Form, Item);
	
	RowID = Undefined;
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	If FormTable <> Undefined Then
		RowID = FormTable.CurrentRow;
	EndIf;
	
	Data = DataAlongWay(Form, ArticleSelectionParameters.DataPath, RowID);
	
	If TypeOf(Data) = Type("FormDataCollection") Then
		// Edit the "whole" table.
		// In all rows of the table, set the value of the article.
		RowsIDs = New Array;
		AssetRef = Data[IdOfTSLine][ArticleSelectionParameters.AssetRef];
		For Each TableRow In Data Do
			TableRow[ArticleSelectionParameters.AssetRef] = AssetRef;
			FillInArticleDetails(Form, TableRow, ArticleSelectionParameters);
			RowsIDs.Add(TableRow.GetID());
		EndDo;
	ElsIf TypeOf(Data) = Type("FormDataCollectionItem") Then
		FillInArticleDetails(Form, Data, ArticleSelectionParameters);
		RowsIDs = Data.GetID();
	Else
		FillInArticleDetails(Form, Data, ArticleSelectionParameters);
		RowsIDs = Undefined;
	EndIf;
	SetPropertiesOfAnalyticsElements(Form, ArticleSelectionParameters);
	GLAccountSettingsClientServer.WhenChangingArticle(
		Form, ArticleSelectionParameters.DataPath, ArticleSelectionParameters.ArticleType, RowsIDs);
EndProcedure

// Handles changes to the expense analysis, called in the corresponding element event handler.
//
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	Item - FormField - The element of choice article.
//
Procedure DimensionOfExpensesOnChange(Form, Item) Export
	
	ArticleSelectionParameters = ItemSelectionOptions(Form, Item);
	
	RowID = Undefined;
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	If FormTable <> Undefined Then
		RowID = FormTable.CurrentRow;
	EndIf;
	
	Data = DataAlongWay(Form, ArticleSelectionParameters.DataPath, RowID);
	If TypeOf(Data) = Type("FormDataCollection") Then
		// Edit the "whole" table.
		// In all rows of the table, set the value of the article.
		DimensionOfExpenses = Data[0][ArticleSelectionParameters.DimensionOfExpenses];
		For Each TableRow In Data Do
			TableRow[ArticleSelectionParameters.DimensionOfExpenses] = DimensionOfExpenses;
		EndDo;
	EndIf;
	
EndProcedure

// Handles a change to the analysts of income is called in the corresponding event handler of the element.
//
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	Item - FormField - The element of choice article.
//
Procedure DimensionOfRevenueOnChange(Form, Item) Export
	
	ArticleSelectionParameters = ItemSelectionOptions(Form, Item);
	
	RowID = Undefined;
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	If FormTable <> Undefined Then
		RowID = FormTable.CurrentRow;
	EndIf;
	
	Data = DataAlongWay(Form, ArticleSelectionParameters.DataPath, RowID);
	If TypeOf(Data) = Type("FormDataCollection") Then
		// Edit the "whole" table.
		// In all rows of the table, set the value of the article.
		DimensionOfRevenue = Data[0][ArticleSelectionParameters.DimensionOfRevenue];
		For Each TableRow In Data Do
			TableRow[ArticleSelectionParameters.DimensionOfRevenue] = DimensionOfRevenue;
		EndDo;
	EndIf;
	
EndProcedure

// Handles changes to the asset/liability analysis, called in the corresponding element event handler.
//
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	Item - FormField - The element of choice article.
//
Procedure AssetsLiabilitiesDimensionOnChange(Form, Item) Export
	
	ArticleSelectionParameters = ItemSelectionOptions(Form, Item);
	
	RowID = Undefined;
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	If FormTable <> Undefined Then
		RowID = FormTable.CurrentRow;
	EndIf;
	
	Data = DataAlongWay(Form, ArticleSelectionParameters.DataPath, RowID);
	If TypeOf(Data) = Type("FormDataCollection") Then
		// Edit the "whole" table.
		// In all rows of the table, set the value of the article.
		AssetsLiabilitiesDimension = Data[0][ArticleSelectionParameters.AssetsLiabilitiesDimension];
		For Each TableRow In Data Do
			TableRow[ArticleSelectionParameters.AssetsLiabilitiesDimension] = AssetsLiabilitiesDimension;
		EndDo;
	EndIf;
	
EndProcedure

// Initializes the value of articles in a new row of the table with the default values.
//
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	NewRow - FormDataCollectionItem, LineOfATabularSection - New row in the table.
// 	PathToTableData - String - The path to the form table data, such as " Object.Goods".
// 
Procedure WhenAddingRowToTable(Form, NewRow, PathToTableData) Export
	
	ArticleSelectionAndAnalyticsData = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ArticleSelectionAndAnalytics");

	For Each Parameters In ArticleSelectionAndAnalyticsData.ChoiceParametersArray Do
		If Parameters.DataPath = PathToTableData Then
			InitializeArticleAndAnalystValues(NewRow, Parameters);
			FillInArticleDetails(Form, NewRow, Parameters);
			SetPropertiesOfAnalyticsElements(Form, Parameters);
			RowID = NewRow.GetID();
			GLAccountSettingsClientServer.WhenChangingArticle(
				Form, Parameters.DataPath, Parameters.ArticleType, RowID);
		EndIf;
	EndDo;
	
EndProcedure

// Clears the article and Analytics in the table row if they are not available in the PM row.
//
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	String - FormDataCollectionItem - Table row.
// 	PathToTableData - String - The path to the form table data, such as " Object.Goods".
//
Procedure WhenChangingArticleAvailabilityDetailsInLine(Form, String, PathToTableData) Export
	
	ArticleSelectionAndAnalyticsData = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ArticleSelectionAndAnalytics");

	For Each Parameters In ArticleSelectionAndAnalyticsData.ChoiceParametersArray Do
		If Parameters.DataPath = PathToTableData Then
			LineAvailability = True;
			For Each KeyAndValue In Parameters.ArticleAvailabilityCriteriaInLines Do
				If TypeOf(KeyAndValue.Value) = Type("Array")
					And KeyAndValue.Value.Find(String[KeyAndValue.Key]) = Undefined Then
					LineAvailability = False;
				ElsIf TypeOf(KeyAndValue.Value) = Type("ValueList")
					And KeyAndValue.Value.FindByValue(String[KeyAndValue.Key]) = Undefined Then
					LineAvailability = False;	
				ElsIf String[KeyAndValue.Key] <> KeyAndValue.Value Then
					LineAvailability = False;
				EndIf; 
				If Not LineAvailability Then
					Break;
				EndIf;
			EndDo;
			If Not LineAvailability And ValueIsFilled(String[Parameters.AssetRef]) Then
				String[Parameters.AssetRef] = Parameters.DefaultValue;
				FillInArticleDetails(Form, String, Parameters);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Complements the structure of the actions of the batch processing mechanism of the table part with the action of filling in the article and cost analytics by nomenclature.
// 
// Parameters:
// 	StructureOfActions - Structure - structure of actions
// 	FormOrParameters - ClientApplicationForm, Structure, Array - When calling from a Form, the Form Of the object is passed. Cached article and analyst selection parameters are obtained From THE Form. 
// 	                                                          When called from the object - parameters for selecting articles and analytics (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//                                                                      .
// 	BusinessOperation - EnumRef.BusinessTransactions - Business operation of the document
// 	Organization - CatalogRef.Companies - Organization of the document
// 	Department - CatalogRef.BusinessStructure - Document division
// 	DataPath - String - The data path of the article and analysis. The default value is " Object.Goods".
// 	ExpenseItem - String - Name of the expense item details. The default value is "expense Item".
//
Procedure InsertActionFillInItemCostAnalysisOfProducts(StructureOfActions, FormOrParameters, BusinessOperation, Organization, Department, DataPath = "Object.Goods", ExpenseItem = "ExpenseItem") Export
	
	If TypeOf(FormOrParameters) = Type("ClientApplicationForm") Then
		DataSelectArticles = TMCommonUseClientServer.GetEngineDataFromFormCache(FormOrParameters, "ArticleSelectionAndAnalytics");
		ChoiceParametersArray = DataSelectArticles.ChoiceParametersArray;
		ActionInForm = True;
	Else
		If TypeOf(FormOrParameters) = Type("Array") Then
			ChoiceParametersArray = FormOrParameters;
		Else
			ChoiceParametersArray = CommonClientServer.ValueInArray(FormOrParameters);
		EndIf;
		ActionInForm = False;
	EndIf;
	
	ChoiceParameters = Undefined;
	For Each Parameters In ChoiceParametersArray Do
		If Parameters.DataPath = DataPath And Parameters.AssetRef = ExpenseItem Then
			ChoiceParameters = Parameters;
		EndIf;
	EndDo;
	
	If ChoiceParameters = Undefined Then
		Return;
	EndIf;
	
	AdditionalColumns = New Array();
	If ActionInForm Then
		GetAdditionalColumnsForActionInForm(AdditionalColumns, ChoiceParameters);
	EndIf;
	
	ActionParameters = New Structure;
	ActionParameters.Insert("Organization",                    Organization);
	ActionParameters.Insert("Department",                  Department);
	ActionParameters.Insert("BusinessOperation",          BusinessOperation);
	ActionParameters.Insert("ExpenseItem",                 ChoiceParameters.AssetRef);
	ActionParameters.Insert("DimensionOfExpenses",              ChoiceParameters.DimensionOfExpenses);
	
	ActionParameters.Insert("ActionInForm",                 ActionInForm);
	ActionParameters.Insert("ItemsAndDimensionsSelectionParameters", ChoiceParameters);
	ActionParameters.Insert("AdditionalColumns",          AdditionalColumns);
	
	StructureOfActions.Insert("FillInItemCostAnalysisOfProductRange", ActionParameters);
	If ActionInForm Then
		// After filling in the articles, it is necessary to fill in the accounting accounts setting and update its presentation, because it depends on the type of the selected article
		GLAccountSettingsClientServer.InsertActionFillInDefaultAccountingAccountsSetting(StructureOfActions, FormOrParameters, DataPath);
	EndIf;
EndProcedure

// Complements the structure of the actions of the batch processing mechanism of the table part with the action of clearing the item and cost analytics ON change of the nomenclature.
// 
// Parameters:
// 	StructureOfActions - Structure - structure of actions
// 	FormOrParameters - ClientApplicationForm, Structure, Array - When calling from a Form, the Form Of the object is passed. Cached article and analyst selection parameters are obtained From THE Form. 
// 	                                                          When called from the object - parameters for selecting articles and analytics (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//                                                                      .
// 	DataPath - String - The data path of the article and analysis. The default value is " Object.Goods".
// 	ExpenseItem - String - Name of the expense item details. The default value is "expense Item".
//
Procedure InsertActionClearItemAndExpenseAnalytics(StructureOfActions, FormOrParameters, DataPath = "Object.Goods", ExpenseItem = "ExpenseItem") Export
	
	If TypeOf(FormOrParameters) = Type("ClientApplicationForm") Then
		DataSelectArticles = TMCommonUseClientServer.GetEngineDataFromFormCache(FormOrParameters, "ArticleSelectionAndAnalytics");
		ChoiceParametersArray = DataSelectArticles.ChoiceParametersArray;
		ActionInForm = True;
	Else
		If TypeOf(FormOrParameters) = Type("Array") Then
			ChoiceParametersArray = FormOrParameters;
		Else
			ChoiceParametersArray = CommonClientServer.ValueInArray(FormOrParameters);
		EndIf;
		ActionInForm = False;
	EndIf;
	
	ChoiceParameters = Undefined;
	For Each Parameters In ChoiceParametersArray Do
		If Parameters.DataPath = DataPath And Parameters.AssetRef = ExpenseItem Then
			ChoiceParameters = Parameters;
		EndIf;
	EndDo;
	
	If ChoiceParameters = Undefined Then
		Return;
	EndIf;
	
	AdditionalColumns = New Array();
	If ActionInForm Then
		GetAdditionalColumnsForActionInForm(AdditionalColumns, ChoiceParameters);
	EndIf;
	
	ActionParameters = New Structure;
	ActionParameters.Insert("ExpenseItem",                 ChoiceParameters.AssetRef);
	ActionParameters.Insert("DimensionOfExpenses",              ChoiceParameters.DimensionOfExpenses);
	
	ActionParameters.Insert("ActionInForm",                 ActionInForm);
	ActionParameters.Insert("ItemsAndDimensionsSelectionParameters", ChoiceParameters);
	ActionParameters.Insert("AdditionalColumns",          AdditionalColumns);
	
	StructureOfActions.Insert("ClearExpenseAnalytics_", ActionParameters);
	If ActionInForm Then
		// After clearing the articles, you need to update the account settings view, because it depends on the type of the selected article
		GLAccountSettingsClientServer.InsertActionFillPresentationAccountSettingsAccounting(StructureOfActions, FormOrParameters, DataPath);
	EndIf;
EndProcedure

// Complements the structure of the actions of the batch processing mechanism of the table part with the action of initializing Attributes after adding a line.
// 
// Parameters:
// 	StructureOfActions - Structure - structure of actions
// 	FormOrParameters - ClientApplicationForm, Structure, Array - When calling from a Form, the Form Of the object is passed. Cached article and analyst selection parameters are obtained From THE Form. 
// 	                                                          When called from the object - parameters for selecting articles and analytics (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//                                                                      .
// 	DataPath - String - The data path of the article and analysis. The default value is " Object.Goods".
//
Procedure InsertActionInitializeArticleAndAnalyticsAfterAddingLine(StructureOfActions, FormOrParameters, DataPath = "Object.Goods") Export
	
	If TypeOf(FormOrParameters) = Type("ClientApplicationForm") Then
		DataSelectArticles = TMCommonUseClientServer.GetEngineDataFromFormCache(FormOrParameters, "ArticleSelectionAndAnalytics");
		ChoiceParametersArray = DataSelectArticles.ChoiceParametersArray;
		ActionInForm = True;
	Else
		If TypeOf(FormOrParameters) = Type("Array") Then
			ChoiceParametersArray = FormOrParameters;
		Else
			ChoiceParametersArray = CommonClientServer.ValueInArray(FormOrParameters);
		EndIf;
		ActionInForm = False;
	EndIf;
	
	TabularSectionColumns = New Array;
	ArrayOfSelectionParametersForAction = New Array;
	For Each ChoiceParameters In ChoiceParametersArray Do
		
		If ChoiceParameters.DataPath <> DataPath Then
			Continue;
		EndIf;
		
		ArrayOfSelectionParametersForAction.Add(ChoiceParameters);
		
		TabularSectionColumns.Add(ChoiceParameters.AssetRef);
		If ChoiceParameters.ChoosingExpenseItem Then
			TabularSectionColumns.Add(ChoiceParameters.DimensionOfExpenses);
		EndIf;
		If ChoiceParameters.ChoosingIncomeItem Then
			TabularSectionColumns.Add(ChoiceParameters.DimensionOfRevenue);
		EndIf;
		If ChoiceParameters.SelectingItemOfAssetsLiabilities Then
			TabularSectionColumns.Add(ChoiceParameters.AssetsLiabilitiesDimension);
		EndIf;
		
		If ActionInForm Then
			GetAdditionalColumnsForActionInForm(TabularSectionColumns, ChoiceParameters);
		EndIf;
		
	EndDo;
	
	ActionParameters = New Structure;
	
	ActionParameters.Insert("ActionInForm",                        ActionInForm);
	ActionParameters.Insert("TabularSectionColumns",                 TabularSectionColumns);
	ActionParameters.Insert("ArrayOfArticleAndAnalyticsSelectionParameters", ArrayOfSelectionParametersForAction);
	
	StructureOfActions.Insert("InitializeArticleAndAnalyticsAfterAddingLine", ActionParameters);
	If ActionInForm Then
		// After the articles are initialized, it is necessary to fill in the accounting accounts setting and update its presentation, because it depends on the type of the selected article
		GLAccountSettingsClientServer.InsertActionFillInDefaultAccountingAccountsSetting(StructureOfActions, FormOrParameters, DataPath);
	EndIf;
EndProcedure

// Handles programmatic changes to the article and asset/liability analysis, and is called in the corresponding element event handler.
//
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	DataPath - String - The data path of the article and a dimension of the form, for example "Object.Goods".
//
Procedure ArticleAnalyticsOfIncomeExpensesInCaseOfChanges(Form, DataPath) Export
	
	DataSelectArticles = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ArticleSelectionAndAnalytics");
	
	If DataSelectArticles = Undefined Then
		Return;
	EndIf;
	
	For Each ArticleSelectionParameters In DataSelectArticles.ChoiceParametersArray Do
		If ArticleSelectionParameters.DataPath = DataPath Then
			RowID = Undefined;
			
			For Each NameOfArticleElement In ArticleSelectionParameters.FormItems.AssetRef Do
				FormTable = TMCommonUseClientServer.ElementShapeTable(Form.Items[NameOfArticleElement]);
				If FormTable <> Undefined Then
					RowID = FormTable.CurrentRow;
					Break;
				EndIf;
			EndDo;
			
			Data = DataAlongWay(Form, ArticleSelectionParameters.DataPath, RowID);
			
			If TypeOf(Data) = Type("FormDataCollection") Then
				// Edit the "whole" table.
				For Each TableRow In Data Do
					FillInArticleDetails(Form, TableRow, ArticleSelectionParameters);
				EndDo;
			ElsIf TypeOf(Data) = Type("FormDataCollectionItem") Then
				FillInArticleDetails(Form, Data, ArticleSelectionParameters);
			Else
				FillInArticleDetails(Form, Data, ArticleSelectionParameters);
			EndIf;
			
			SetPropertiesOfAnalyticsElements(Form, ArticleSelectionParameters);
			Break;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region ArticleSelectionAndAnalytics

Function ItemSelectionOptions(Form, Item) Export
	
	DataSelectArticles = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "ArticleSelectionAndAnalytics");
	ParameterIndex_ = Undefined;
	If Not DataSelectArticles.MatchingSelectionParametersToFormElements.Property(Item.Name, ParameterIndex_) Then
		Raise NStr("vi = 'Mục đã gửi không phải là mục để chọn và phân tích bài viết.';
					|ru = 'Переданный элемент не является элементом выбора статьи и аналитики';
					|en = 'The transferred item is not the item of line selection and analytics'; fa = 'The transferred item is not the item of line selection and analytics';
					|it = 'Elemento trasmesso non è un elemento di scelta della voce e dell''analitica';
					|pl = 'Przekazany element nie jest elementem wyboru artykułów i analityki';
					|tr = 'Transfer edilen öğe, kalem ve boyut seçim öğesi değil'");
	EndIf;
	ChoiceParametersArray = DataSelectArticles.ChoiceParametersArray; // Array -
	Return ChoiceParametersArray.Get(ParameterIndex_);
	
EndFunction

// Initialize the value of the article and the analyst.
// 
// Parameters:
//  Data - FormDataCollectionItem, LineOfATabularSection - Data
//  Parameters - See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Procedure InitializeArticleAndAnalystValues(Data, Val Parameters) Export
	
	SetDefaultValue = False;
	AssetRef = Data[Parameters.AssetRef];
	
	If Parameters.DefaultValue = Undefined Then
		If Parameters.ChoosingExpenseItem Then
			Parameters.DefaultValue = PredefinedValue("ChartOfCharacteristicTypes.ExpenseItems.EmptyRef");
		ElsIf Parameters.ChoosingIncomeItem Then
			Parameters.DefaultValue = PredefinedValue("ChartOfCharacteristicTypes.IncomeItems.EmptyRef");
		ElsIf Parameters.SelectingItemOfAssetsLiabilities Then
			Parameters.DefaultValue = PredefinedValue("ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef");
		EndIf;
	EndIf;
	
	If AssetRef = Undefined Then
		SetDefaultValue = True;
	EndIf;
	
	If Parameters.AvailabilityByOperation <> Undefined 
			And Not Parameters.AvailabilityByOperation 
			And AssetRef <> Parameters.DefaultValue Then
		SetDefaultValue = True;
	EndIf;
	
	// Let's check the compliance of the selected article with the parameters of the selection of expenses, the selection of income, the selection of assets and assets.
	If Not SetDefaultValue
		 And Not Parameters.ChoosingExpenseItem
		 And TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.ExpenseItems") Then
		SetDefaultValue = True;
	EndIf;
	
	If Not SetDefaultValue
		 And Not Parameters.ChoosingIncomeItem
		 And TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.IncomeItems") Then
		SetDefaultValue = True;
	EndIf;
	
	If Not SetDefaultValue
		 And Not Parameters.SelectingItemOfAssetsLiabilities
		 And TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		SetDefaultValue = True;
	EndIf;
	
	If SetDefaultValue Then
		Data[Parameters.AssetRef] = Parameters.DefaultValue;
	EndIf;
	
	// Let's clean up irrelevant analytics
	ClearExpenseAnalytics      = False;
	ClearRevenueAnalytics       = False;
	ClearOtherAssetAnalytics = False;
	If TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.ExpenseItems") Then
		ClearRevenueAnalytics       = True;
		ClearOtherAssetAnalytics = True;
		If Not ValueIsFilled(AssetRef) Then
			ClearExpenseAnalytics   = True;
		EndIf;
	ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.IncomeItems") Then
		ClearExpenseAnalytics      = True;
		ClearOtherAssetAnalytics = True;
		If Not ValueIsFilled(AssetRef) Then
			ClearRevenueAnalytics   = True;
		EndIf;
	ElsIf TypeOf(AssetRef) = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		ClearExpenseAnalytics      = True;
		ClearRevenueAnalytics       = True;
		If Not ValueIsFilled(AssetRef) Then
			ClearOtherAssetAnalytics   = True;
		EndIf;
	EndIf;
	
	If SetDefaultValue Then
		Data[Parameters.AssetRef] = Parameters.DefaultValue;
		If Parameters.ChoosingExpenseItem 
			 And Parameters.DimensionOfExpenses <> "" Then
			Data[Parameters.DimensionOfExpenses] = Undefined;
		EndIf;
		If Parameters.ChoosingIncomeItem
			 And Parameters.DimensionOfRevenue <> "" Then
			Data[Parameters.DimensionOfRevenue] = Undefined;
		EndIf;
		If Parameters.SelectingItemOfAssetsLiabilities
			 And Parameters.AssetsLiabilitiesDimension <> "" Then
			Data[Parameters.AssetsLiabilitiesDimension] = Undefined;
		EndIf;
	EndIf;
	
	If ClearExpenseAnalytics
		 And Parameters.DimensionOfExpenses <> "" Then
		Data[Parameters.DimensionOfExpenses] = Undefined;
	EndIf;
	If ClearRevenueAnalytics
		 And Parameters.DimensionOfRevenue <> "" Then
		Data[Parameters.DimensionOfRevenue] = Undefined;
	EndIf;
	If ClearOtherAssetAnalytics
		 And Parameters.AssetsLiabilitiesDimension <> ""Then
		Data[Parameters.AssetsLiabilitiesDimension] = Undefined;
	EndIf;
	
EndProcedure

// Data on the way.
// 
// Parameters:
//  FormObject1 - ClientApplicationForm - The shape of the object
//  DataPath - String - 
//  RowID - Undefined, Arbitrary - row ID
// 
// Returns:
//  Undefined, FormDataCollectionItem, ClientApplicationForm - Data Along The Way
//
Function DataAlongWay(FormObject1, Val DataPath, Val RowID = Undefined) Export
	
	DataPathParts = StrSplit(DataPath, ".", False);
	If TypeOf(FormObject1) <> Type("ClientApplicationForm") 
		And DataPathParts[0] = "Object" Then
		DataPathParts.Delete(0);
	EndIf;
	
	If DataPathParts.Count() > 1 Then
		Data = FormObject1[DataPathParts[0]][DataPathParts[1]];
		If RowID <> Undefined And TypeOf(Data) = Type("FormDataCollection") Then
			Data = Data.FindByID(RowID);
			If DataPathParts.Count() = 3 Then
				Data = Data[DataPathParts[2]];
			EndIf;
		EndIf;
	ElsIf DataPathParts.Count() = 1 
		And TypeOf(FormObject1[DataPathParts[0]]) = Type("FormDataCollection") Then
		If RowID <> Undefined Then
			Data = FormObject1[DataPathParts[0]].FindByID(RowID);
		Else
			Data = FormObject1[DataPathParts[0]];
		EndIf;
	ElsIf DataPathParts.Count() = 1 Then
		Data = FormObject1[DataPathParts[0]];
	Else
		Data = FormObject1;
	EndIf;
	
	Return Data;
	
EndFunction

// Returns the default Analytics
// 
// Parameters:
// 	ArticleDetails_1 - Structure - LongDesc:
// * WithoutDimension - Boolean -
// * DimensionOfExpensesOrderImplementation - Boolean -
// * ControlDimensionFilling - Boolean -
// * ValueType - TypeDescription -
// 	Data - ClientApplicationForm, FormDataStructure - Contains:
// 	  * Ref - DocumentRef - 
// Returns:
// 	DocumentRef.CustomerInvoice, Arbitrary - default analytics
Function GetDefaultAnalytics(ArticleDetails_1, Data) Export
	
	Types = ArticleDetails_1.ValueType.Types();

	Types = IncomeAndExpensesServerCall.DeleteTypesFromArrayToDelete(Types);	
	TypeDescription = New TypeDescription(Types);
	Dimension = TypeDescription.AdjustValue();
	
	If ArticleDetails_1.ValueType = New TypeDescription("CatalogRef.Warehouses")
		And CommonClientServer.HasAttributeOrObjectProperty(Data, "Warehouse") Then
		
		If ValueIsFilled(Data.Warehouse) Then
			IsFolder = GeneralPurposeTMServerCall.ObjectAttributeValue(Data.Warehouse, "IsFolder");
			If Not IsFolder Then
				Dimension = Data.Warehouse;
			EndIf;
		EndIf
		
	ElsIf ArticleDetails_1.ValueType = New TypeDescription("DocumentRef.PurchaseOrder")
		And CommonClientServer.HasAttributeOrObjectProperty(Data, "PurchaseOrder") Then
		
		Dimension = Data.PurchaseOrder;
		
	ElsIf ArticleDetails_1.ValueType = New TypeDescription("DocumentRef.VendorInvoice")
		And CommonClientServer.HasAttributeOrObjectProperty(Data, "Ref")
		And TypeOf(Data.Ref) = Type("DocumentRef.VendorInvoice") Then
		
		Dimension = Data.Ref;
		
	ElsIf ArticleDetails_1.ValueType = New TypeDescription("CatalogRef.Partners")
		And CommonClientServer.HasAttributeOrObjectProperty(Data, "Partner") Then
		
		Dimension = Data.Partner;	
		
	ElsIf ArticleDetails_1.ValueType = New TypeDescription("CatalogRef.Companies")
		And CommonClientServer.HasAttributeOrObjectProperty(Data, "Organization")Then
		
		Dimension = Data.Organization;
		
	ElsIf ArticleDetails_1.ValueType = New TypeDescription("CatalogRef.BusinessStructure")
	   And CommonClientServer.HasAttributeOrObjectProperty(Data, "Department") Then
	   
		Dimension = Data.Department;
		
	ElsIf ArticleDetails_1.ValueType = New TypeDescription("CatalogRef.Persons") Then
		
		If CommonClientServer.HasAttributeOrObjectProperty(Data, "AdvanceHolder") Then
			Dimension = Data.AdvanceHolder;
		ElsIf CommonClientServer.HasAttributeOrObjectProperty(Data, "Individual") Then
			Dimension = Data.Individual;
		EndIf;
	
	ElsIf ArticleDetails_1.ValueType = New TypeDescription("CatalogRef.CashAccounts")
		And CommonClientServer.HasAttributeOrObjectProperty(Data, "CashAccount")  Then
		
		Dimension = Data.CashAccount;
		
	ElsIf ArticleDetails_1.Property("DimensionOfExpensesOrderImplementation")
	 		And ArticleDetails_1.DimensionOfExpensesOrderImplementation Then
		Dimension =  PredefinedValue("Document.CustomerInvoice.EmptyRef");
		
	EndIf;
	
	Return Dimension;
	
EndFunction

// Fills in the article details
// 
// Parameters:
// 	Form - ClientApplicationForm - 
// 	Data - FormDataCollectionItem, LineOfATabularSection, ClientApplicationForm, Undefined -
// 	ChoiceParameters - See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Procedure FillInArticleDetails(Form, Data, Val ChoiceParameters) Export
	
	AssetRef = Data[ChoiceParameters.AssetRef];
	
	If TypeOf(Data) = Type("FormDataCollectionItem") Then
		DataForServiceDetails = Data;
	Else
		DataForServiceDetails = Form;
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
		DataForServiceDetails[ChoiceParameters.ArticleType] = ArticleType;
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(Form, "Object") Then
		Object = Form.Object;
	Else
		Object = Form;
	EndIf;
	
	ArticleDetails_1 = IncomeAndExpensesServerCallCached.ArticleDetailsValues(AssetRef);
	ArticleValueType = TypeOf(AssetRef);
	
	If ChoiceParameters.ChoosingExpenseItem And ArticleValueType = Type("ChartOfCharacteristicTypesRef.ExpenseItems") Then
		If ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesRequired_ <> "" Then
			DataForServiceDetails[ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesRequired_] = ArticleDetails_1.ControlDimensionFilling;
		EndIf;
		If ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation <> "" Then
			DataForServiceDetails[ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation] = ArticleDetails_1.DimensionOfExpensesOrderImplementation;
		EndIf; 
		
		If Not ArticleDetails_1.ValueType.ContainsType(TypeOf(Data[ChoiceParameters.DimensionOfExpenses])) Then
			Data[ChoiceParameters.DimensionOfExpenses] = Undefined;	
		EndIf;
		
		If Not ValueIsFilled(Data[ChoiceParameters.DimensionOfExpenses]) Then
			Data[ChoiceParameters.DimensionOfExpenses] = 
				GetDefaultAnalytics(ArticleDetails_1, Object);
		EndIf;
		If Not ValueIsFilled(Data[ChoiceParameters.DimensionOfExpenses]) And TypeOf(Object) <> TypeOf(Data) Then
			Data[ChoiceParameters.DimensionOfExpenses] = 
				GetDefaultAnalytics(ArticleDetails_1, Data);
		EndIf;
	EndIf;
	
	If ChoiceParameters.ChoosingIncomeItem And ArticleValueType = Type("ChartOfCharacteristicTypesRef.IncomeItems") Then
		If ChoiceParameters.DimensionOfRevenue <> "" Then
			DataForServiceDetails[ChoiceParameters.CacheOfIncomeItemDetails.DimensionOfRevenueRequired_] = ArticleDetails_1.ControlDimensionFilling;
		EndIf;
		
		If Not ArticleDetails_1.ValueType.ContainsType(TypeOf(Data[ChoiceParameters.DimensionOfRevenue])) Then
			Data[ChoiceParameters.DimensionOfRevenue] = Undefined;	
		EndIf;
		
		If Not ValueIsFilled(Data[ChoiceParameters.DimensionOfRevenue]) Then
			Data[ChoiceParameters.DimensionOfRevenue] = 
				GetDefaultAnalytics(ArticleDetails_1, Object);
		EndIf;
		If Not ValueIsFilled(Data[ChoiceParameters.DimensionOfRevenue]) And TypeOf(Object) <> TypeOf(Data) Then
			Data[ChoiceParameters.DimensionOfRevenue] = 
				GetDefaultAnalytics(ArticleDetails_1, Data);
		EndIf;
	EndIf;
	
	If ChoiceParameters.SelectingItemOfAssetsLiabilities And ArticleValueType = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems") Then
		If ChoiceParameters.AssetsLiabilitiesDimension <> "" Then
			DataForServiceDetails[ChoiceParameters.CacheOfDetailsOfItemOfAssetsLiabilities.AssetsLiabilitiesDimensionNotUsed] = ArticleDetails_1.WithoutDimension;
		EndIf;   
		
		If Not ArticleDetails_1.ValueType.ContainsType(TypeOf(Data[ChoiceParameters.AssetsLiabilitiesDimension])) Then
			Data[ChoiceParameters.AssetsLiabilitiesDimension] = Undefined;	
		EndIf;
		
		If Not ValueIsFilled(Data[ChoiceParameters.AssetsLiabilitiesDimension]) Then
			Data[ChoiceParameters.AssetsLiabilitiesDimension] = 
				GetDefaultAnalytics(ArticleDetails_1, Object);
		EndIf;
		If Not ValueIsFilled(Data[ChoiceParameters.AssetsLiabilitiesDimension]) And TypeOf(Object) <> TypeOf(Data) Then
			Data[ChoiceParameters.AssetsLiabilitiesDimension] = 
				GetDefaultAnalytics(ArticleDetails_1, Data);
		EndIf;
	EndIf;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	Form - ClientApplicationForm - 
// 	ChoiceParameters - Structure -
Procedure SetPropertiesOfAnalyticsElements(Form, Val ChoiceParameters) Export
	
	FormItems = Form.Items;

	Data = DataAlongWay(Form, ChoiceParameters.DataPath);
	DataForServiceDetails = Undefined;
	If TypeOf(Data) = Type("FormDataCollection") Then
		// Editing the table in the "No partitioning" mode
		If Data.Count() > 0 Then
			Data = Data[0];
			DataForServiceDetails = Data;
		Else
			Data = Undefined;
			DataForServiceDetails = Undefined;
		EndIf;
	ElsIf TypeOf(Data) = Type("FormDataCollectionItem") Then
		DataForServiceDetails = Data;
	Else
		DataForServiceDetails = Form;
	EndIf;
	
	If Data <> Undefined Then
		ArticleFilledIn = ValueIsFilled(Data[ChoiceParameters.AssetRef]);
		ArticleType = TypeOf(Data[ChoiceParameters.AssetRef]);
	Else
		ArticleFilledIn = False;
		ArticleType = TypeOf(ChoiceParameters.DefaultValue);
	EndIf;
	
	IndexOf = 0;
	For Each TagName In ChoiceParameters.FormItems.DimensionOfExpenses Do
		ArticleElement = FormItems[ChoiceParameters.FormItems.AssetRef[IndexOf]];
		AnalyticsElement = FormItems[TagName];
		AnalyticsElement.Visible = ArticleElement.Visible;
		FormTable = TMCommonUseClientServer.ElementShapeTable(AnalyticsElement);
		If FormTable = Undefined Then
			AnalyticsElement.Visible = ArticleElement.Visible And ArticleType = Type("ChartOfCharacteristicTypesRef.ExpenseItems");
			AnalyticsElement.TypeRestriction = New TypeDescription;
			AnalyticsElement.Enabled = ArticleFilledIn;
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
	IndexOf = 0;
	For Each TagName In ChoiceParameters.FormItems.DimensionOfRevenue Do
		ArticleElement = FormItems[ChoiceParameters.FormItems.AssetRef[IndexOf]];
		AnalyticsElement = FormItems[TagName];
		AnalyticsElement.Visible = ArticleElement.Visible;
		FormTable = TMCommonUseClientServer.ElementShapeTable(AnalyticsElement);
		If FormTable = Undefined Then
			AnalyticsElement.Visible = ArticleElement.Visible And ArticleType = Type("ChartOfCharacteristicTypesRef.IncomeItems");
			AnalyticsElement.Enabled = ArticleFilledIn;
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
	IndexOf = 0;
	For Each TagName In ChoiceParameters.FormItems.AssetsLiabilitiesDimension Do
		ArticleElement = FormItems[ChoiceParameters.FormItems.AssetRef[IndexOf]];
		AnalyticsElement = FormItems[TagName];
		AnalyticsElement.Visible = ArticleElement.Visible;
		FormTable = TMCommonUseClientServer.ElementShapeTable(AnalyticsElement);
		If FormTable = Undefined Then
			AnalyticsElement.Visible = ArticleElement.Visible And ArticleType = Type("ChartOfCharacteristicTypesRef.AssetLiabilityItems");
			AnalyticsElement.Enabled = ArticleFilledIn 
				And Not DataForServiceDetails[ChoiceParameters.CacheOfDetailsOfItemOfAssetsLiabilities.AssetsLiabilitiesDimensionNotUsed];
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure GetAdditionalColumnsForActionInForm(AdditionalColumns, ChoiceParameters)
	
	If ChoiceParameters.ArticleType <> "" Then
		AdditionalColumns.Add(ChoiceParameters.ArticleType);
	EndIf;
	If ChoiceParameters.ChoosingExpenseItem And ChoiceParameters.DimensionOfExpenses <> "" Then
		AdditionalColumns.Add(ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesRequired_);
		AdditionalColumns.Add(ChoiceParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation);
	EndIf;
	If ChoiceParameters.ChoosingIncomeItem And ChoiceParameters.DimensionOfRevenue <> "" Then
		AdditionalColumns.Add(ChoiceParameters.CacheOfIncomeItemDetails.DimensionOfRevenueRequired_);
	EndIf;
	If ChoiceParameters.SelectingItemOfAssetsLiabilities And ChoiceParameters.AssetsLiabilitiesDimension <> "" Then
		AdditionalColumns.Add(ChoiceParameters.CacheOfDetailsOfItemOfAssetsLiabilities.AssetsLiabilitiesDimensionNotUsed);
	EndIf;
	
EndProcedure

#EndRegion