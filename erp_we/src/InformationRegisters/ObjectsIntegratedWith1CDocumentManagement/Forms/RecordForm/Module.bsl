#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Query = New Query(
		"SELECT
		|	ObjectsIntegratedWith1CDocumentManagement.AdditionalData AS AdditionalData
		|FROM
		|	InformationRegister.ObjectsIntegratedWith1CDocumentManagement AS ObjectsIntegratedWith1CDocumentManagement
		|WHERE
		|	ObjectsIntegratedWith1CDocumentManagement.Object = &Object
		|	AND ObjectsIntegratedWith1CDocumentManagement.ObjectTypeDM = &ObjectTypeDM
		|	AND ObjectsIntegratedWith1CDocumentManagement.ObjectIDDM = &ObjectIDDM");
	Query.SetParameter("ObjectIDDM", Record.ObjectIDDM);
	Query.SetParameter("Object", Record.Object);
	Query.SetParameter("ObjectTypeDM", Record.ObjectTypeDM);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		If TypeOf(Selection.AdditionalData) = Type("ValueStorage") Then
			StructureOfData = Selection.AdditionalData.Get();
			If TypeOf(StructureOfData) = Type("Structure") Then
				RowsArray = New Array;
				For Each Item In StructureOfData Do
					RowsArray.Add(StrTemplate("%1:   %2", Item.Key, TrimAll(Item.Value)));
				EndDo;
				AdditionalData = StrConcat(RowsArray, Chars.LF);
			EndIf;
		EndIf;
		
	EndIf;
	
	Items.AdditionalData.Visible = ValueIsFilled(AdditionalData);
	
EndProcedure

#EndRegion