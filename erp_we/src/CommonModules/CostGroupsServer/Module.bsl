
#Region Public

// The function returns a representation of the cost group.
//	Parameters:
//		FieldsValues - Structure - values of fields that identify the cost group.
//	Returns:
//		String - representation of the cost group.
//
Function CostGroupPresentation(FieldsValues) Export
	
	FieldList = ListOfFieldsByCostGrouping(FieldsValues.Document, FieldsValues.GroupCosts);
	
	CostGroupFields_ = CostGroupStructure(FieldList);
	FillPropertyValues(CostGroupFields_, FieldsValues);
	GroupPresentation = "";
	
	For Each CurField In CostGroupFields_ Do
		If CurField.Key = "InternalSubcontracting" Then
			Continue;
		EndIf;
		CurPresentation = String(CurField.Value);
		
		If ValueIsFilled(CurPresentation) Then
			GroupPresentation = GroupPresentation + CurPresentation + " / ";
		EndIf;
		
	EndDo;
	
	If ValueIsFilled(GroupPresentation) Then
		GroupPresentation = Left(GroupPresentation, StrLen(GroupPresentation) - 3);
	Else
		GroupPresentation = NStr("vi = '<nhóm có giá trị trống>';
								|ru = '<группа с пустыми значениями>';
								|en = '<group with empty values>'; fa = '<group with empty values>';
								|it = '<gruppo con valori vuoti>';
								|pl = '<grupa z pustymi wartościami>';
								|tr = '<boş değerli grup>'", Common.DefaultLanguageCode());
	EndIf;
	
	Return GroupPresentation;
	
EndFunction

// The function returns a list of identifying fields corresponding to the passed cost grouping.
//	Parameters:
//		Document - DocumentRef - production batch document.
//		GroupCosts - EnumRef.CostGroupingsInTollingOrder,
//							Enum of the link.Cost groupingproduction of an order - the type of cost grouping.
//	Returns:
//		ValueList of String - a list of fields identifying the cost group.
//
Function ListOfFieldsByCostGrouping(Document, GroupCosts) Export
	
	If TypeOf(Document) = Type("DocumentRef.BackflushProduction") Then
		FieldList = Documents.BackflushProduction.ListOfCostGroupFields(GroupCosts);
	ElsIf TypeOf(Document) = Type("DocumentRef.SubcontractorReport2_5") Then
		FieldList = ProcessingByThirdPartiesClientServer.ListOfCostGroupFieldsInProcessorSReport(GroupCosts);
	ElsIf TypeOf(Document) = Type("DocumentRef.ProductionOrder2_2") Then
		FieldList = Documents.ProductionOrder2_2.ListOfCostGroupFields();
	Else
		FieldList = New ValueList;
	EndIf;
	
	Return FieldList;
	
EndFunction

#EndRegion

#Region Private

// Returns a structure containing a list of fields that identify the cost group.
//	Parameters:
//		FieldList - ValueList - a list of fields identifying the cost group.
//	Returns:
//		Structure - a structure containing a list of fields identifying the cost group.
//
Function CostGroupStructure(FieldList) Export
	
	CostGroupStructure = New Structure;
	
	For Each CurField In FieldList Do
		CostGroupStructure.Insert(CurField.Value);
	EndDo;
	
	Return CostGroupStructure;
	
EndFunction

#EndRegion