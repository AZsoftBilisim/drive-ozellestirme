////////////////////////////////////////////////////////////////////////////////
// The module "Activity Directionsclientserver" contains procedures
// related to the interactive work of the user in the forms of documents.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region FillType

// Fills in the "activity Direction" details in the line according to the destination data or the passed parameter
//
// Parameters:
//  CurrentRow		 - Structure - data of the processed string.
//  StructureOfActions	 - Structure - describes actions, where the Key is the name of the action,
//  														   The value - Structure - activity settings.
//  CachedValues - Structure - saved values of parameters used during processing.
//  ActionParameters    - Structure, Undefined - parameters for performing this action
//
Procedure FillInDirectionOfActivity(
			CurrentRow, StructureOfActions, CachedValues, ActionParameters = Undefined) Export

	Var LineOfBusiness;

	If ValueIsFilled(CurrentRow.Purpose) Then

		PropertiesPurpose = CachedValues.AssignmentProperties.Get(CurrentRow.Purpose);

		If PropertiesPurpose = Undefined Then

			ExceptionText = 
				NStr("vi = 'Cố gắng điền các chi tiết theo đích được chỉ định trên máy khách.';
					|ru = 'Попытка заполнение реквизита по данным указанного назначение на клиенте.';
					|en = 'Try to fill in attribute according to data of specified assignment on the client.'; fa = 'Try to fill in attribute according to data of specified assignment on the client.';
					|it = 'Il tentativo di compilazione del requisito in base ai dati dell''assegnazione indicata sul client.';
					|pl = 'Próba wypełnienia atrybutu wg danych podanego przeznaczenia na kliencie.';
					|tr = 'İstemcide belirtilen atamaya göre öznitelikleri doldurma girişimi.'");

			Raise ExceptionText;

		Else

			LineOfBusiness = PropertiesPurpose.LineOfBusiness;

		EndIf;

	ElsIf ActionParameters <> Undefined Then

		LineOfBusiness = ActionParameters.LineOfBusiness;

	EndIf;

	CurrentRow.LineOfBusiness = LineOfBusiness;

EndProcedure

#EndRegion

#Region EventHandlersForElementsInTablePartsOfDocumentForm

// Outdated. It is necessary to use the destination client.The goods are separate from the change
// In the tabular part of the document form, it updates the assignment by flag Separately.
// 
// Parameters:
//  Form - ClientApplicationForm - shape.
//  CurrentRow - FormDataCollectionItem - The line where you want to update the assignment.
Procedure GoodsWithAssignmentOnChange(Form, CurrentRow) Export
	
	AssignmentsClient.GoodsWithAssignmentOnChange(Form, CurrentRow, True);
	
EndProcedure

#EndRegion

#EndRegion