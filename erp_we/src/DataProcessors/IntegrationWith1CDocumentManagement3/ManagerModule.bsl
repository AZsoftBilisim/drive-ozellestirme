#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Searches for objects UP to by details, saving the result to temporary storage
//
// Parameters:
//   ObjectType - String - the type of object to search for
//   SearchAttributes - Structure - description of search details
//   AddressInTempStorage - String - the parameter in which the address of the search results is placed
//   NumberOfResults - Number - number of search results
//   LimitNumberOfResults - Number - the maximum number of selected objects, if it is exceeded
//
Procedure PerformSearchByBankingDetails(ObjectType, SearchAttributes, AddressInTempStorage,
		NumberOfResults, LimitNumberOfResults) Export
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	ListOfConditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	LimitNumberOfResults = IntegrationWith1CDocumentManagementCore.MaximumNumberOfSelectedObjects(
		ObjectType);
	ListOfConditions.limit = LimitNumberOfResults;
	SelectedFields = ListOfConditions.columnSet; // XDTOList
	
	SetOfColumns = New Array;
	If IntegrationWith1CDocumentManagement3.IsDocumentBefore3(ObjectType) Then
		SetOfColumns.Add("documentType");
		SetOfColumns.Add("regNumber");
		SetOfColumns.Add("regDate");
		SetOfColumns.Add("sum");
		SetOfColumns.Add("organization");
		SetOfColumns.Add("correspondent");
		SetOfColumns.Add("folder");
		
	ElsIf ObjectType = "DMCorrespondent" Then
		SetOfColumns.Add("inn");
		SetOfColumns.Add("kpp");
		SetOfColumns.Add("legalPrivatePerson");
		
	ElsIf ObjectType = "DMMeeting" Then
		SetOfColumns.Add("type");
		SetOfColumns.Add("startDate");
		SetOfColumns.Add("endDate");
		
	EndIf;
	
	Presentation = "";
	For Each SearchDetails In SearchAttributes Do
		AttributeName = SearchDetails.Key;
		ConditionDetails = SearchDetails.Value;
		AddDetailsToConditionsList(
			Proxy,
			AttributeName,
			ConditionDetails,
			ListOfConditions,
			Presentation);
	EndDo;
	
	// Add the remaining columns to the selection requirement.
	For Each AttributeName In SetOfColumns Do
		SelectedFields.Add(AttributeName);
	EndDo;
	
	If Presentation = "" Then
		Presentation = NStr("vi = 'Chưa đặt điều kiện.';
							|ru = 'Условия не заданы.';
							|en = 'Conditions are not specified.'; fa = 'Conditions are not specified.';
							|it = 'Condizioni non indicate.';
							|pl = 'Warunki nie są zadane.';
							|tr = 'Şartlar belirlenmedi.'");
	Else
		Presentation = Presentation + ".";
	EndIf;
	
	ListOfXDTOObjects = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		ObjectType,
		ListOfConditions);
	
	FoundObjects = New Array;
	For Each XDTODataObject In ListOfXDTOObjects.items Do
		FoundObject = New Structure;
		FoundObjects.Add(FoundObject);
		FoundObject.Insert("name", XDTODataObject.object.name);
		FoundObject.Insert("ID", XDTODataObject.object.objectID.ID);
		FoundObject.Insert("navigationRef", XDTODataObject.object.objectID.navigationRef);
		For Each ColumnDetails In SetOfColumns Do
			AttributeName = ColumnDetails;
			PropertyValue = XDTODataObject.object.Get(AttributeName);
			If TypeOf(PropertyValue) = Type("XDTODataObject") Then
				// The reference type is UP to.
				FoundObject.Insert(AttributeName, PropertyValue.name);
				FoundObject.Insert(AttributeName + "ID", PropertyValue.objectID.ID);
			Else
				// Primitive type.
				FoundObject.Insert(AttributeName, PropertyValue);
			EndIf;
		EndDo;
	EndDo;
	
	// Early versions BEFORE do not support tooManyObjects.
	If IntegrationWith1CDocumentManagementCore.PropertySet(ListOfXDTOObjects, "tooManyObjects")
			And ListOfXDTOObjects.tooManyObjects = True Then
		Presentation = Presentation
			+ " " + NStr("vi = 'Kéo thả mục tin bất kỳ vào đây để làm rõ điều kiện.';
						|ru = 'Перетащите сюда любой реквизит, чтобы уточнить условия.';
						|en = 'Drag an attribute here to refine the criteria.'; fa = 'Drag an attribute here to refine the criteria.';
						|it = 'Trascinare qui qualsiasi attributo per indicare le condizioni.';
						|pl = 'Przenieś tutaj dowolny atrybut, aby uściślić warunki.';
						|tr = 'Şartları netleştirmek için herhangi bir özniteliği buraya sürükleyip bırakın.'");
	Else
		LimitNumberOfResults = 0;
	EndIf;
	
	Result = New Structure;
	Result.Insert("FoundObjects", FoundObjects);
	Result.Insert("SetOfColumns", SetOfColumns);
	Result.Insert("PresentationOfSearchTerms", Presentation);
	
	AddressInTempStorage = PutToTempStorage(Result, New UUID);
	
	NumberOfResults = FoundObjects.Count();
	
EndProcedure

// The standard print handler for the BSP Print Management subsystem.
//
// Parameters:
//   ObjectsArray  - Array of AnyRef - references to the objects that you want to print.
//   PrintParameters - Structure - additional print settings.
//   PrintFormsCollection - ValueTable - generated tabular documents.
//   PrintObjects - ValueList of AnyRef - The value is a reference to the object, the Presentation is the name of the area
//     in which the object was displayed.
//   OutputParameters - Structure - additional parameters of generated table documents.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If IntegrationWith1CDocumentManagementCoreCached.IsBackgroundJob()
			And PrintParameters.Property("IntegrationWith1CWorkflow_ParametersOfOperation") Then
		IntegrationWith1CDocumentManagementCore.ConnectAndGetServiceVersionInBackground(
			PrintParameters.IntegrationWith1CWorkflow_ParametersOfOperation);
	EndIf;
	
	ModulePrintManager = Common.CommonModule("PrintManagement");
	
	For Each PrintForm In PrintFormsCollection Do
		ModulePrintManager.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintForm.TemplateName,
			PrintForm.TemplateSynonym,
			GetPrintFormBefore(ObjectsArray, PrintForm.TemplateName, ModulePrintManager));
	EndDo;
	
EndProcedure

// Returns the specified printed form as a tabular document UP to for the passed array of items.
//
// Parameters:
//   ObjectsArray - AnyRef, Array of AnyRef - IP objects.
//   PrintCommand - String - an XDTO enumeration of the DMPrintCommand type.
//   ModulePrintManager - CommonModule - a common print management module.
//   ClearDetails - Boolean - it is required to remove all decryption parameters from the table document.
//
// Returns:
//   SpreadsheetDocument - printed Form BEFORE.
//
Function GetPrintFormBefore(ObjectsArray, PrintCommand, ModulePrintManager = Undefined,
		ClearDetails = True) Export
	
	If TypeOf(ObjectsArray) = Type("Array") Then
		ArrayOfItems = ObjectsArray;
	Else
		// The only link.
		ArrayOfItems = CommonClientServer.ValueInArray(ObjectsArray);
	EndIf;
	
	If ModulePrintManager = Undefined Then
		Template = DataProcessors.IntegrationWith1CDocumentManagement3.GetTemplate("PF_MXL_PrintFormBefore");
	Else
		Template = ModulePrintManager.PrintFormTemplate(
			"DataProcessor.IntegrationWith1CDocumentManagement3.PF_MXL_PrintFormBefore");
	EndIf;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	Query = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMGetPrintedFormRequest");
	Query.printedFormFileType = "MXL";
	Query.printCommand = PrintCommand;
	
	FirstDocument = True;
	For Each SubjectOf In ArrayOfItems Do
		// Let's check the existence of a linked object.
		LinkedObjectBefore = IntegrationWith1CDocumentManagementCoreServerCall.ObjectDataUpToExternalObject(
			SubjectOf);
		If LinkedObjectBefore = Undefined Then
			If Not FirstDocument Then
				SpreadsheetDocument.PutHorizontalPageBreak();
			EndIf;
			FirstDocument = False;
			SectionHeader = Template.GetArea("Header");
			SectionHeader.Parameters.SubjectOf = String(SubjectOf);
			If PrintCommand = "ApprovalSheet" Or PrintCommand = "ApprovalSheetWithHistory" Then
				SectionHeader.Parameters.Title = NStr("vi = 'Tờ thống nhất';
														|ru = 'Лист согласования';
														|en = 'Approval sheet '; fa = 'برگه تأیید';
														|it = 'Foglio di omologazione';
														|pl = 'Arkusz uzgodnienia';
														|tr = 'Anlaşma listesi'");
				SectionHeader.Parameters.Explanation = NStr("vi = 'Chưa khởi động quy trình thống nhất trong 1C:Document Management.';
															|ru = 'Согласование в 1С:Документообороте не запускалось.';
															|en = 'Coordination in 1C:Document Management was not started.'; fa = 'هماهنگی در 1C:Document Management آغاز نشد.';
															|it = 'L''omologazione non è stata avviata in 1C:Document Management.';
															|pl = 'Uzgodnienie w 1C:Document Management nie było uruchamiane.';
															|tr = '1C:Document Management''de anlaşma başlatılmadı.'");
			ElsIf PrintCommand = "ProtocolOfDisagreements" Then
				SectionHeader.Parameters.Title = NStr("vi = 'Biên bản chênh lệch';
														|ru = 'Протокол разногласий';
														|en = 'Protocol of disagreements'; fa = 'صورت‌جلسه اختلافات';
														|it = 'Протокол разногласий';
														|pl = 'Protocol of disagreements';
														|tr = 'Anlaşmazlık protokolü'");
				SectionHeader.Parameters.Explanation = NStr("vi = 'Chưa khởi động quy trình thống nhất trong 1C:Document Management.';
															|ru = 'Согласование в 1С:Документообороте не запускалось.';
															|en = 'Coordination in 1C:Document Management was not started.'; fa = 'هماهنگی در 1C:Document Management آغاز نشد.';
															|it = 'L''omologazione non è stata avviata in 1C:Document Management.';
															|pl = 'Uzgodnienie w 1C:Document Management nie było uruchamiane.';
															|tr = '1C:Document Management''de anlaşma başlatılmadı.'");
			ElsIf PrintCommand = "ExaminationSheet" Then
				SectionHeader.Parameters.Title = NStr("vi = 'Trang tham khảo';
														|ru = 'Лист ознакомления';
														|en = 'Preview sheet'; fa = 'برگه پیش‌نمایش';
														|it = 'Лист ознакомления';
														|pl = 'Preview sheet';
														|tr = 'İnceleme sayfası'");
				SectionHeader.Parameters.Explanation = NStr("vi = 'Chưa khởi động quy trình tham khảo trong 1C:Document Management.';
															|ru = 'Ознакомление в 1С:Документообороте не запускалось.';
															|en = 'Preview in 1C:Document Management was not started.'; fa = 'Preview in 1C:Document Management was not started.';
															|it = 'Ознакомление в 1С:Документообороте не запускалось.';
															|pl = 'Preview in 1C:Document Management was not started.';
															|tr = '1C:Document Management kapsamında inceleme başlatılmadı.'");
			EndIf;
			SpreadsheetDocument.Put(SectionHeader);
		Else
			Query.objects.Add(
				IntegrationWith1CDocumentManagementCore.CreateObjectID(
					Proxy,
					LinkedObjectBefore.ID,
					LinkedObjectBefore.type));
		EndIf;
	EndDo;
	
	If Query.objects.Count() = 0 Then
		Return SpreadsheetDocument;
	EndIf;
	
	Response = IntegrationWith1CDocumentManagementCore.ExecuteQuery(Proxy, Query);
	IntegrationWith1CDocumentManagementCore.CheckWebServiceRefund(Proxy, Response);
	
	If ModulePrintManager = Undefined Then
		
		Return Response.printedForm;
		
	Else
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		PrintFormBefore = ModulePrintManager.SpreadsheetDocumentByBinaryData(Response.printedForm);
		
		If ClearDetails Then
			For String = 1 To PrintFormBefore.TableHeight Do
				For Column = 1 To PrintFormBefore.TableWidth Do
					Area = PrintFormBefore.Area(String, Column);
					If ValueIsFilled(Area.Details) Then
						Area.Details = Undefined;
					EndIf;
				EndDo;
			EndDo;
		EndIf;
		
		SpreadsheetDocument.Put(PrintFormBefore);
		
		Return SpreadsheetDocument;
		
	EndIf;
	
EndFunction

#EndRegion

#Region Private

// Adds the search details to the list of XDTO conditions, forming a condition representation in parallel
//
// Parameters:
//   Proxy - WSProxy - an object for connecting to Document Management web services.
//   AttributeName - String - the name of the search details.
//   Description of conditions - Structure - description of search conditions.
//   ListOfConditions - XDTODataObject - A XDTO object of type DMObjectListQuery, replenished list of conditions.
//   Presentation - String - the updated representation of the condition.
//
Procedure AddDetailsToConditionsList(Proxy, AttributeName, ConditionDetails, ListOfConditions, Presentation)
	
	If Presentation = "" Then
		Presentation = Presentation + ConditionDetails.Presentation;
	Else
		Presentation = Presentation + "; " + Lower(ConditionDetails.Presentation);
	EndIf;
	
	If ConditionDetails.Property("ConditionPresentation") And ValueIsFilled(ConditionDetails.ConditionPresentation) Then
		Presentation = Presentation + ": " + ConditionDetails.ConditionPresentation;
	Else
		Presentation = Presentation + ": "
			+ ?(TypeOf(ConditionDetails.Value) = Type("Date"),
				Format(ConditionDetails.Value, "DLF=D"),
				ConditionDetails.Value);
	EndIf;
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = AttributeName;
	If ConditionDetails.ComparisonOperator = "<=" And TypeOf(ConditionDetails.Value) = Type("Date") Then
		Condition.value = EndOfDay(ConditionDetails.Value);
	Else
		If ConditionDetails.Property("ValueID") And ValueIsFilled(ConditionDetails.ValueID) Then
			AttributeValue = IntegrationWith1CDocumentManagementCore.CreateObjectID(
				Proxy,
				ConditionDetails.ValueID,
				ConditionDetails.ValueType);
			Condition.value = AttributeValue;
		Else // Primitive type.
			Condition.value = ConditionDetails.Value;
		EndIf;
	EndIf;
	
	If ConditionDetails.ComparisonOperator = "=" And TypeOf(ConditionDetails.Value) = Type("Date") Then
		Condition.comparisonOperator = ">=";
	Else
		Condition.comparisonOperator = ConditionDetails.ComparisonOperator;
	EndIf;
	
	Conditions = ListOfConditions.conditions; // XDTOList
	Conditions.Add(Condition);
	
	If ConditionDetails.Property("ComparisonOperator2") And ValueIsFilled(ConditionDetails.ComparisonOperator2) Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = AttributeName;
		If ConditionDetails.ComparisonOperator2 = "<=" And TypeOf(ConditionDetails.Value2) = Type("Date") Then
			Condition.value = EndOfDay(ConditionDetails.Value2);
		Else
			Condition.value = ConditionDetails.Value2;
		EndIf;
		Condition.comparisonOperator = ConditionDetails.ComparisonOperator2;
		Conditions.Add(Condition);
	ElsIf ConditionDetails.ComparisonOperator = "="
			And TypeOf(ConditionDetails.Value) = Type("Date")
			And AttributeName <> "anyDate" Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = AttributeName;
		Condition.value = EndOfDay(ConditionDetails.Value);
		Condition.comparisonOperator = "<=";
		Conditions.Add(Condition);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf