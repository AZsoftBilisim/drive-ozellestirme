////////////////////////////////////////////////////////////////
// The "Client Assignments" module contains procedures and functions for 
// working with appointments on the client.
//
////////////////////////////////////////////////////////////////

#Region Public

#Region FillType

// Fills in the service Attribute "Type of assignment" in the line according to the data of the specified assignment
//
// Parameters:
//  CurrentRow        - Structure - data of the processed string.
//  CachedValues - Structure - saved values of parameters used during processing.
//  FillParameters  - See AssignmentsClientServer.FillParameters
//
Procedure FillInDestinationType(CurrentRow, CachedValues, FillParameters = Undefined) Export
	
	AssignmentType = Undefined;
	
	If ValueIsFilled(CurrentRow.Purpose) Then
		
		PropertiesPurpose = CachedValues.AssignmentProperties.Get(CurrentRow.Purpose);
		
		If PropertiesPurpose = Undefined Then 
		
			ExceptionText = 
				NStr("vi = 'Thử điền mục tin hệ thống theo dữ liệu của mục đích đã chỉ định trên client.';
					|ru = 'Попытка заполнения служебного реквизита по данным указанного назначение на клиенте.';
					|en = 'Try to fill in internal attribute according to the data of the specified assignment on the client.'; fa = 'Try to fill in internal attribute according to the data of the specified assignment on the client.';
					|it = 'Попытка заполнения служебного реквизита по данным указанного назначение на клиенте.';
					|pl = 'Try to fill in internal attribute according to the data of the specified assignment on the client.';
					|tr = 'İstemcide belirtilen atamanın verilerine göre hizmet gereksinimini doldurma girişimi.'");
					
			Raise ExceptionText;
				
		Else
			AssignmentType = PropertiesPurpose.AssignmentType;
		EndIf;
		
	EndIf;
	
	CurrentRow.AssignmentType = AssignmentType;
	
	If ValueIsFilled(FillParameters)
	   And CurrentRow.AssignmentType = FillParameters.AssignmentType Then
		
		CurrentRow[FillParameters.NameOfFieldToFillIn] = ?(ValueIsFilled(FillParameters.TSFieldName),
																	CurrentRow[FillParameters.TSFieldName],
																	FillParameters.Simple);
		
	EndIf;
	
EndProcedure

// Fills in the assignment in the line over the order in the invoice for several orders, based on the default assignment
// Parameters:
//  Form - ClientApplicationForm - the form of the document
//  TableRow - FormDataCollectionItem - the row of the table part in the form of a document
&AtClient
Procedure AfterSpecifyingOrderInLine(Form, TableRow) Export
EndProcedure

#EndRegion

#Region EventHandlersForElementsInTablePartsOfDocumentForm

// In the tabular part of the document form, it updates the assignment by flag Separately.
// 
// Parameters:
//  Form - ClientApplicationForm - shape.
//  CurrentRow - FormDataCollectionItem - The line where you want to update the assignment.
//  IsOutdated - Boolean - for compatibility with the direction of the client's activity.The goods are separate from the change
Procedure GoodsWithAssignmentOnChange(Form, CurrentRow, IsOutdated = False) Export
	
	If IsOutdated Then
		DocumentProcessingProcedure = Form.FormMetadata;
		DefaultAssignment = Form.LineOfBusinessCachedValues.DefaultAssignment;
	Else
		DocumentProcessingProcedure = Form.AssignmentsCachedValues.DocumentProcessingProcedure;
		DefaultAssignment = Form.AssignmentsCachedValues.DefaultAssignment;
	EndIf;
	
	Utilities = DocumentProcessingProcedure.Utilities;
	Set = CurrentRow[Utilities.PropsNameIsSeparate];
	CurrentRow.Purpose = ?(Set,
		DefaultAssignment,
		PredefinedValue("Catalog.Assignments.EmptyRef"));
	
EndProcedure

#EndRegion

#EndRegion