#Region Public

#Region ArticleSelectionAndAnalytics

// Provides a selection of articles in accordance with the selection parameters.
// 
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	Item - FormField, FormFieldExtensionForATextBox - The element of choice article.
// 	StandardProcessing - Boolean - indicates standard event handling.
//
Procedure StartArticleSelection(Form, Item, StandardProcessing) Export
	
	ArticleSelectionParameters = IncomeAndExpensesClientServer.ItemSelectionOptions(Form, Item); 
	
	StandardProcessing = False;
	
	RowID = Undefined;
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	If FormTable <> Undefined Then
		RowID = FormTable.CurrentRow;
	EndIf;
	Data = IncomeAndExpensesClientServer.DataAlongWay(Form, ArticleSelectionParameters.DataPath, RowID);
	If TypeOf(Data) = Type("FormDataCollection") Then
		// Editing the table in the "No partitioning" mode
		Data = Data[0];
	EndIf;
	
	ChoiceParameters = New Array();
	For Each ChoiceParameter In Item.ChoiceParameters Do
		ChoiceParameters.Add(ChoiceParameter);
	EndDo;
	
	ChoiceParameterLinks = Item.ChoiceParameterLinks; // FixedArray of ChoiceParameterLink
	For Each ChoiceParameterLink In ChoiceParameterLinks Do
		ParameterValue = TMCommonUseClientServer.ValueOfLinkParameter(ChoiceParameterLink, Form);
		NewChoiceParameter = New ChoiceParameter(ChoiceParameterLink.Name, ParameterValue);
		ChoiceParameters.Add(NewChoiceParameter);
	EndDo;
		
	FormParameters = New Structure;
	FormParameters.Insert("AssetRef", Data[ArticleSelectionParameters.AssetRef]);
	FormParameters.Insert("ChoiceParameters", New FixedArray(ChoiceParameters));
	FormParameters.Insert("TypeRestriction", Item.TypeRestriction);
	
	OpenForm("CommonForm.SelectionFormOfItem", FormParameters, Item);
	
EndProcedure

// Provides a selection of expense Analytics according to the selection parameters.
// 
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	Item - FormField, FormFieldExtensionForATextBox - The element of choice article.
// 	StandardProcessing - Boolean - indicates standard event handling.
//
Procedure StartSelectingExpenseAnalytics(Form, Item, StandardProcessing) Export
	
	ArticleSelectionParameters = IncomeAndExpensesClientServer.ItemSelectionOptions(Form, Item);
	
	RowID = Undefined;
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	If FormTable <> Undefined Then
		RowID = FormTable.CurrentRow;
	EndIf;
	Data = IncomeAndExpensesClientServer.DataAlongWay(Form, ArticleSelectionParameters.DataPath, RowID);
	
	DataInTable = False;
	If TypeOf(Data) = Type("FormDataCollection") Then
		// Editing the table in the "No partitioning" mode
		Data = Data[0];
		DataInTable = True;
	ElsIf TypeOf(Data) = Type("FormDataCollectionItem") Then
		DataInTable = True;
	EndIf;
	
	If DataInTable Then
		DimensionOfExpensesOrderImplementation = Data[ArticleSelectionParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation];
	Else
		DimensionOfExpensesOrderImplementation = Form[ArticleSelectionParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation];
	EndIf;
	
	DimensionOfExpenses = Data[ArticleSelectionParameters.DimensionOfExpenses];
	
	If DimensionOfExpensesOrderImplementation Then
		StandardProcessing = False;
		
		SelectionValueCompany = New Structure("Organization", Undefined);
		FillPropertyValues(SelectionValueCompany, Data);
		ThereIsObjectInAttributesOfForm = CommonClientServer.HasAttributeOrObjectProperty(Form, "Object");
		If ThereIsObjectInAttributesOfForm And Not ValueIsFilled(SelectionValueCompany.Organization) Then
			FillPropertyValues(SelectionValueCompany, Form.Object);
		EndIf;
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("Organization", SelectionValueCompany.Organization);
		
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceInitialValue", DimensionOfExpenses);
		FormParameters.Insert("FilterStructure1", FilterStructure1);
		OpenForm("CommonForm.SelectExpenditureDimension", FormParameters, Item);
	EndIf;
	
	If TypeOf(DimensionOfExpenses)=Type("CatalogRef.CounterpartyContracts") Then
		StandardProcessing = False;
		FormParameters = New Structure;
		ContractTypes = New Array(); // Array of EnumRef.ContractTypes
		ContractTypes.Add(PredefinedValue("Enum.ContractTypes.TransferToTolling2_5"));
		FormParameters.Insert("ChoiceInitialValue", DimensionOfExpenses);
		FormParameters.Insert("AllowPartnerSelection", True);
		FormParameters.Insert("ContractTypes", ContractTypes);
		
		OpenForm("Catalog.CounterpartyContracts.Form.ChoiceForm", FormParameters, Item);
	EndIf;
	If TypeOf(DimensionOfExpenses) = Type("CatalogRef.ProductionLots") Then
		
		StandardProcessing = False;
		
		SelectionValueCompany = New Structure("Organization", Undefined);
		SelectionValueDate = New Structure("Date", Undefined);
		FillPropertyValues(SelectionValueCompany, Data);
		FillPropertyValues(SelectionValueDate, Data);
		ThereIsObjectInAttributesOfForm = CommonClientServer.HasAttributeOrObjectProperty(Form, "Object");
		If ThereIsObjectInAttributesOfForm And Not ValueIsFilled(SelectionValueCompany.Organization) Then
			FillPropertyValues(SelectionValueCompany, Form.Object);
		EndIf;
		
		If ThereIsObjectInAttributesOfForm And Not ValueIsFilled(SelectionValueDate.Date) Then
			FillPropertyValues(SelectionValueDate, Form.Object);
		EndIf;
		
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("Organization", SelectionValueCompany.Organization);
		FormParameters = New Structure();
		
		If ValueIsFilled(SelectionValueDate.Date) Then
			FormParameters.Insert("BeginOfPeriod",	BegOfMonth(SelectionValueDate.Date));
			FormParameters.Insert("PeriodEnding",	EndOfMonth(SelectionValueDate.Date));
		EndIf;

		FormParameters.Insert("FilterStructure1",	FilterStructure1);
		FormParameters.Insert("SingleChoice",	True);
		FormParameters.Insert("NotifyOnSelection",	True);
		FormParameters.Insert("ChangingPeriodAndOrganization", True);
		
		OpenForm("CommonForm.SelectProductionLots",
			FormParameters,
			Item, , , , ,
			FormWindowOpeningMode.LockOwnerWindow);

	EndIf;
EndProcedure

// Fills in the selection list when auto-selecting expense Analytics.
// 
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	Item - FormField, FormFieldExtensionForATextBox - The element of choice article.
// 	Text - String - Input text.
// 	ChoiceData - ValueList - Analytics selection data.
// 	Parameters - Structure, Undefined - Parameters for getting selection data.
// 	StandardProcessing - Boolean - indicates standard event handling.
//
Procedure AutoSelectionOfExpenseAnalytics(Form, Item, Text, ChoiceData, Parameters, StandardProcessing) Export
	
	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;
	
	ArticleSelectionParameters = IncomeAndExpensesClientServer.ItemSelectionOptions(Form, Item);
	
	RowID = Undefined;
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	If FormTable <> Undefined Then
		RowID = FormTable.CurrentRow;
	EndIf;
	
	Data = IncomeAndExpensesClientServer.DataAlongWay(Form, ArticleSelectionParameters.DataPath, RowID);
	DataInTable = False;
	If TypeOf(Data) = Type("FormDataCollection") Then
		// Editing the table in the "No partitioning" mode
		Data = Data[0];
		DataInTable = True;
	ElsIf TypeOf(Data) = Type("FormDataCollectionItem") Then
		DataInTable = True;
	EndIf;
	
	If DataInTable Then
		DimensionOfExpensesOrderImplementation = Data[ArticleSelectionParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation];
	Else
		DimensionOfExpensesOrderImplementation = Form[ArticleSelectionParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation];
	EndIf;
	
	If DimensionOfExpensesOrderImplementation Then
		StandardProcessing = False;
		ChoiceData = New ValueList;
		SalesServerCall.FillInExpenseAnalyticsSelectionData(ChoiceData, Text);
	EndIf;
	
EndProcedure

// Fills in the selection list when you finish entering text in the expense analysis field.
// 
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	Item - FormField, FormFieldExtensionForATextBox - The element of choice article.
// 	Text - String - Input text.
// 	ChoiceData - ValueList - Analytics selection data.
// 	Parameters - Structure, Undefined - Parameters for getting selection data.
// 	StandardProcessing - Boolean - indicates standard event handling.
//
Procedure EndOfCostAnalyticsTextEntry(Form, Item, Text, ChoiceData, Parameters, StandardProcessing) Export
	
	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;
	
	ArticleSelectionParameters = IncomeAndExpensesClientServer.ItemSelectionOptions(Form, Item);
	
	RowID = Undefined;
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	If FormTable <> Undefined Then
		RowID = FormTable.CurrentRow;
	EndIf;
	Data = IncomeAndExpensesClientServer.DataAlongWay(Form, ArticleSelectionParameters.DataPath, RowID);
	DataInTable = False;
	If TypeOf(Data) = Type("FormDataCollection") Then
		// Editing the table in the "No partitioning" mode
		Data = Data[0];
		DataInTable = True;
	ElsIf TypeOf(Data) = Type("FormDataCollectionItem") Then
		DataInTable = True;
	EndIf;
	
	If DataInTable Then
		DimensionOfExpensesOrderImplementation = Data[ArticleSelectionParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation];
	Else
		DimensionOfExpensesOrderImplementation = Form[ArticleSelectionParameters.CacheOfDetailsOfExpenseItem.DimensionOfExpensesOrderImplementation];
	EndIf;
	
	If DimensionOfExpensesOrderImplementation Then
		StandardProcessing = False;
		ChoiceData = New ValueList;
		SalesServerCall.FillInExpenseAnalyticsSelectionData(ChoiceData, Text);
	EndIf;
	
EndProcedure

// Handler for the fill in articles and Analytics command in the selected rows of the table.
// 
// Parameters:
// 	Form - ClientApplicationForm - object form.
// 	Item - FormField, FormFieldExtensionForATextBox - Article selection element to fill in the data for.
// 	SelectedRows - Array - Selected rows in the form table
// 	DescriptionOfNotificationAfterFillingIn - CallbackDescription - Descriptions of the alert that should be called after filling in the article and Analytics.
//
Procedure FillInArticleAndAnalyticsInSelectedLines(Form, Item, SelectedRows, DescriptionOfNotificationAfterFillingIn = Undefined) Export
	
	ArticleSelectionParameters = IncomeAndExpensesClientServer.ItemSelectionOptions(Form, Item);
	
	FormParameters = New Structure;
	FormParameters.Insert("AssetRef",                         Undefined);
	FormParameters.Insert("ArticleItemSelectionOptions",  Item.ChoiceParameters);
	FormParameters.Insert("DefaultValue",            ArticleSelectionParameters.DefaultValue);
	FormParameters.Insert("ChoosingExpenseItem",            ArticleSelectionParameters.ChoosingExpenseItem);
	FormParameters.Insert("ChoosingIncomeItem",             ArticleSelectionParameters.ChoosingIncomeItem);
	FormParameters.Insert("SelectingItemOfAssetsLiabilities",     ArticleSelectionParameters.SelectingItemOfAssetsLiabilities);
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("Form",                         Form);
	AdditionalParameters.Insert("RowID",           SelectedRows);
	AdditionalParameters.Insert("ArticleSelectionParameters",         ArticleSelectionParameters);
	AdditionalParameters.Insert("DescriptionOfNotificationAfterFillingIn", DescriptionOfNotificationAfterFillingIn);
	CallbackDescription = New CallbackDescription("AtEndOfArticleSelectionAndAnalytics", ThisObject, AdditionalParameters);
	
	OpenForm("CommonForm.SelectionFormOfItemAndDimension", 
		FormParameters, Form, , , , CallbackDescription);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region ArticleSelectionAndAnalytics

Procedure AtEndOfArticleSelectionAndAnalytics(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Form                 = AdditionalParameters.Form; // ClientApplicationForm
	ArticleSelectionParameters = AdditionalParameters.ArticleSelectionParameters; // See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
	If TypeOf(AdditionalParameters.RowID) = Type("Array") Then
		ArrayOfIdentifiers = AdditionalParameters.RowID;
	Else
		ArrayOfIdentifiers = CommonClientServer.ValueInArray(AdditionalParameters.RowID)
	EndIf;
	
	For Each RowID In ArrayOfIdentifiers Do
		Data = IncomeAndExpensesClientServer.DataAlongWay(Form, ArticleSelectionParameters.DataPath, RowID);
		Data[ArticleSelectionParameters.AssetRef] = Result.AssetRef;
		If ArticleSelectionParameters.ChoosingExpenseItem Then
			Data[ArticleSelectionParameters.DimensionOfExpenses] = Result.DimensionOfExpenses;
		EndIf;
		If ArticleSelectionParameters.ChoosingIncomeItem Then
			Data[ArticleSelectionParameters.DimensionOfRevenue] = Result.DimensionOfRevenue;
		EndIf;
		If ArticleSelectionParameters.SelectingItemOfAssetsLiabilities Then
			Data[ArticleSelectionParameters.AssetsLiabilitiesDimension] = Result.AssetsLiabilitiesDimension;
		EndIf;
		IncomeAndExpensesClientServer.FillInArticleDetails(Form, Data, ArticleSelectionParameters);
		IncomeAndExpensesClientServer.SetPropertiesOfAnalyticsElements(Form, ArticleSelectionParameters);
	EndDo;
	If ArticleSelectionParameters.SelectingItemOfAssetsLiabilities Then
		GLAccountSettingsClientServer.WhenChangingArticle(
			Form, ArticleSelectionParameters.DataPath, ArticleSelectionParameters.ArticleType, ArrayOfIdentifiers);
	EndIf;
	Form.Modified = True;
	
	If AdditionalParameters.DescriptionOfNotificationAfterFillingIn <> Undefined Then
		RunCallback(AdditionalParameters.DescriptionOfNotificationAfterFillingIn);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion