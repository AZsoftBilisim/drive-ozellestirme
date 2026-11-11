#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	TypeOfSelectionObject = Parameters.TypeOfSelectionObject;
	SearchResults = GetFromTempStorage(Parameters.AddressInTempStorage);
	AddressInTempStorage = PutToTempStorage(Parameters.Filter, New UUID());
	
	For Each FilterElement In Parameters.Filter Do
		If FilterElement.Value.ComparisonOperator = "=" Then
			ActiveFilter.Add(FilterElement.Key, FilterElement.Value.Presentation);
		EndIf;
	EndDo;
	
	SetColumnsVisibility(SearchResults);
	
	FillInFormWithSearchResults(SearchResults.FoundObjects, SearchResults.PresentationOfSearchTerms);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PresentationOfSearchTermsDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PresentationOfSearchTermsDrag(Item, DragParameters, StandardProcessing, String, Field)
	
	If TypeOf(DragParameters.Value) <> Type("Structure") Then
		Return;
	EndIf;
	
	AttributeDetails = DragParameters.Value;
	If AttributeDetails.Property("Name") And AttributeDetails.Property("Value") Then
		StandardProcessing = False;
		RefineSearch(AttributeDetails);
	EndIf;
	
EndProcedure

&AtClient
Procedure PresentationOfSearchTermsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ChangeSearchTerms();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFoundObjects

&AtClient
Procedure FoundObjectsSelection(Item, RowSelected, Field, StandardProcessing)
	
	SelectCurrentRow();
	
EndProcedure

&AtClient
Procedure FoundObjectsDragStart(Item, DragParameters, Perform)
	
	AttributeDetails = New Structure;
	AttributeName = Item.CurrentItem.Name;
	AttributeDetails.Insert("Name", AttributeName);
	AttributeDetails.Insert("Presentation", Item.CurrentItem.Title);
	AttributeDetails.Insert("Value", Item.CurrentData[AttributeName]);
	If Find("documentType, organization, correspondent, folder, type", AttributeName) <> 0 Then
		// reference type BEFORE
		AttributeDetails.Insert("ValueID", Item.CurrentData[Item.CurrentItem.Name + "ID"]);
		If AttributeName = "documentType" Then
			AttributeDetails.Insert("ValueType", "DMDocumentType");
		ElsIf AttributeName = "organization" Then
			AttributeDetails.Insert("ValueType", "DMOrganization");
		ElsIf AttributeName = "correspondent" Then
			AttributeDetails.Insert("ValueType", "DMCorrespondent");
		ElsIf AttributeName = "folder" Then
			AttributeDetails.Insert("ValueType", "DMDocumentFolder");
		ElsIf AttributeName = "type" Then
			AttributeDetails.Insert("ValueType", "DMMeetingType");
		EndIf;
	EndIf;
	DragParameters.Value = AttributeDetails;
	Perform = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	SelectCurrentRow();
	
EndProcedure

&AtClient
Procedure ChangeConditions(Command)
	
	ChangeSearchTerms();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectCurrentRow()
	
	CurrentData = Items.FoundObjects.CurrentData;
	If CurrentData <> Undefined Then
		Result = New Structure;
		Result.Insert("AttributeID", CurrentData.ID);
		Result.Insert("AttributeType", TypeOfSelectionObject);
		Result.Insert("AttributePresentation", CurrentData.name);
		Result.Insert("DocumentTypeAttributeID", CurrentData.documentTypeID);
		Result.Insert("AttributeNavigationLink", CurrentData.navigationRef);
		AddResult(Result, CurrentData);
		Close(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddResult(Result, CurrentData)
	
	If TypeOfSelectionObject = "DMCorrespondent" Then
		Result.Insert("legalPrivatePersonID", CurrentData.legalPrivatePersonID);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RefineSearch(AttributeDetails)
	
	FilterStructure1 = GetFromTempStorage(AddressInTempStorage);
	ConditionDetails = New Structure;
	If AttributeDetails.Property("ValueID") Then
		ConditionDetails.Insert("ValueID", AttributeDetails.ValueID);
		ConditionDetails.Insert("ValueType", AttributeDetails.ValueType);
	EndIf;
	If AttributeDetails.Name = "name" Then
		ConditionDetails.Insert("ComparisonOperator", "LIKE");
		ConditionDetails.Insert("Value", "%" + AttributeDetails.Value + "%");
		ConditionDetails.Insert("ConditionPresentation", StrTemplate(NStr("vi = 'có chứa ""%1""';
																			|ru = 'содержит ""%1""';
																			|en = 'contains ""%1""'; fa = 'contains ""%1""';
																			|it = 'contiene ""%1""';
																			|pl = 'zawiera ""%1""';
																			|tr = '""%1"" içeriyor'"),
			AttributeDetails.Value));
	Else
		ConditionDetails.Insert("ComparisonOperator", "=");
		ConditionDetails.Insert("Value", AttributeDetails.Value);
	EndIf;
	ConditionDetails.Insert("Presentation", AttributeDetails.Presentation);
	FilterStructure1.Insert(AttributeDetails.Name, ConditionDetails);
	
	NumberOfResults = 0;
	LimitNumberOfResults = 0;
	DataProcessors.IntegrationWith1CDocumentManagement3.PerformSearchByBankingDetails(
		TypeOfSelectionObject,
		FilterStructure1,
		AddressInTempStorage,
		NumberOfResults,
		LimitNumberOfResults);
	
	SearchResults = GetFromTempStorage(AddressInTempStorage);
	AddressInTempStorage = PutToTempStorage(FilterStructure1, New UUID());
	
	ActiveFilter.Add(AttributeDetails.Name, AttributeDetails.Presentation);
	
	SetColumnsVisibility(SearchResults);
	
	FillInFormWithSearchResults(SearchResults.FoundObjects, SearchResults.PresentationOfSearchTerms);
	
EndProcedure

&AtServer
Procedure FillInFormWithSearchResults(ResultsArray, Presentation)
	
	PresentationOfSearchTerms.Clear();
	PresentationOfSearchTerms.Add().Presentation = Presentation;
	
	FoundObjects.Clear();
	For Each SearchResult In ResultsArray Do
		
		FoundObject = FoundObjects.Add();
		FillPropertyValues(FoundObject, SearchResult);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ChangeSearchTerms()
	
	FilterStructure1 = GetFromTempStorage(AddressInTempStorage);
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfSelectionObject", TypeOfSelectionObject);
	FormParameters.Insert("Filter", FilterStructure1);
	FormParameters.Insert("SearchImmediately", False);
	
	ThisIsAdvancedSearch = False;
	For Each SearchDetails In FilterStructure1 Do
		AttributeName = SearchDetails.Key;
		ConditionDetails = SearchDetails.Value;
		If Find("correspondent, organization, documentType, folder,
				|name, sum, regNumber, anyDate, inn, kpp,
				|type, startDate, endDate", AttributeName) = 0 Then
			ThisIsAdvancedSearch = True;
			Break;
			
		ElsIf AttributeName = "name" And ConditionDetails.ComparisonOperator <> "LIKE" Then
			ThisIsAdvancedSearch = True;
			Break;
			
		ElsIf AttributeName = "anyDate" And ConditionDetails.ComparisonOperator <> ">=" Then
			ThisIsAdvancedSearch = True;
			Break;
			
		ElsIf Find("regNumber, inn, kpp", AttributeName) <> 0 And ConditionDetails.ComparisonOperator <> "=" Then
			ThisIsAdvancedSearch = True;
			Break;
			
		EndIf;
	EndDo;
	
	If ThisIsAdvancedSearch Then
		Close();
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.SelectingObjectBySearchExtended", FormParameters,,,,,
			CallbackDescriptionOnClose,FormWindowOpeningMode.LockWholeInterface);
	Else
		Close();
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.SelectingObjectBySearch", FormParameters,,,,,
			CallbackDescriptionOnClose,FormWindowOpeningMode.LockWholeInterface);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetColumnsVisibility(SearchResults)
	
	// Hide the elements that are not received by the request.
	For Each Item In Items Do
		If TypeOf(Item) = Type("FormField") And Item.Parent = Items.FoundObjects Then
			If Item.Name = "name"
					Or (SearchResults.SetOfColumns.Find(Item.Name) <> Undefined
						And ActiveFilter.FindByValue(Item.Name) = Undefined) Then
				Item.Visible = True;
			Else
				Item.Visible = False;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion